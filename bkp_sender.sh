#! /bin/bash

#-------configuration----------------------------------#

# root password for mysql and ciphered file
ROOTPWD='toto'

# working directory
WORKDIR=/root
# where to store the files before create the archive
BKPFILE=backup-`hostname`-`date +%Y%m%d`
BKPPATH=$WORKDIR/$BKPFILE

# path of the archive (not inside BKPPATH)
TARFILE=backup-`hostname`-`date +%Y%m%d`.tar.bz
TARPATH=$WORKDIR/backup-`hostname`-`date +%Y%m%d`.tar.bz

# path of the backup private key
PRIVKEY=backupprivate.key
PRIVKEYPATH=$WORKDIR/$PRIVKEY
PUBKEY=backuppublic.key
PUBKEYPATH=$WORKDIR/$PUBKEY

# signature file
SIGNFILE=$TARFILE.ciphered.sign
SIGNPATH=$WORKDIR/$TARFILE.ciphered.sign

# list the files to include in the archive
LISTFILETOARCHIVE='/etc/postfix /etc/bind /etc/apache2 /etc/vsftpd.conf'

# list the files to exclude from the archive
EXCLUDE='*.zip *.tar*'

# path to openldap config file
LDAPCONFIG='/etc/ldap/slapd.conf'

# archive destination (for scp)
SCPPORT=22
SCPUSER=root
SCPHOST=toto.example.net
SCPPATH=/data/backup/
SSHVERIFYCOMMAND="openssl dgst -sha512 -verify $SCPPATH/$PUBKEY -signature $SCPPATH/$SIGNFILE $SCPPATH/$TARFILE.ciphered"
#------------------------------------------------------#


if [[ $UID != 0 ]]
then
	echo "You need to be root to launch the backup"
	exit -1
fi

# create backup directories
mkdir $BKPPATH
mkdir $BKPPATH/mysql
mkdir $BKPPATH/files
mkdir $BKPPATH/ldap

# backup mysql with one file per database
for i in `mysqlshow --user=root --password=$ROOTPWD |cut -d \| -f 2|grep -v "^+"|grep -v "^  "`
do
	mysqldump -u root --password=$ROOTPWD $i > $BKPPATH/mysql/$i.sql.dump
	if [ $? != 0 ]
	then
		echo "BACKUP SCRIPT ERROR : mysqldump" | mail -s 'BACKUP ERROR REPORT' root
		exit 1
	fi
done

# sync the file to the backup directory
EXCLUDELIST=`for i in $EXCLUDE; do echo -n "--exclude=$i "; done`
for i in $LISTFILETOARCHIVE
do
	rsync -auv $i $BKPPATH/files/ $EXCLUDELIST
	if [ $? != 0 ]
	then
		echo "BACKUP SCRIPT ERROR : rsync" | mail -s 'BACKUP ERROR REPORT' root
		exit 1
	fi
done

# backup openldap in ldif file
slapcat -f $LDAPCONFIG > $BKPPATH/ldap/openldap.ldif.dump
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : slapcat" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi

#create tar archive
tar -cjvf $TARPATH $BKPPATH/files
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : tar" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi

# cipher the archive
openssl aes-256-ecb -e -a -salt -in $TARPATH -out $TARPATH.ciphered -pass pass:$ROOTPWD
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : openssl cipher" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi

# sign the archive (create the private key if not exists)
if [ ! -f $PRIVKEYPATH ]
then
	openssl genrsa -out $PRIVKEYPATH 2048
	openssl rsa -in $PRIVKEYPATH -pubout -out $PUBKEYPATH
	scp -P $SCPPORT $PUBKEYPATH root@$SCPHOST:$SCPPATH
fi
openssl dgst -sha512 -sign $PRIVKEYPATH $TARPATH.ciphered > $SIGNPATH
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : openssl signature" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi

# transfer ciphered archive using scp
scp -P $SCPPORT $TARPATH.ciphered $SCPUSER@$SCPHOST:$SCPPATH
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : scp $TARPATH.ciphered" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi
scp -P $SCPPORT $SIGNPATH $SCPUSER@$SCPHOST:$SCPPATH
if [ $? != 0 ]
then
	echo "BACKUP SCRIPT ERROR : scp $SIGNPATH" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
fi

# launch remote command to verify the signature
VERIFYRESULT=`ssh -p $SCPPORT $SCPUSER@$SCPHOST $SSHVERIFYCOMMAND`

if [ "$VERIFYRESULT" != "Verified OK" ]
then
	echo "BACKUP SCRIPT ERROR : signature verification" | mail -s 'BACKUP ERROR REPORT' root
	exit 1
else
	echo "$VERIFYRESULT - backup file $TARFILE.ciphered has been successfully transfered to $SCPHOST:$SCPPATH and signature has been verified" | mail -s 'BACKUP SUCCESS REPORT' root
	exit 1
fi

