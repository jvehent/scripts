#!/usr/bin/env bash

# rman global, jvehent 20110822
# The script will be called by cron under the oracle user

usage(){
    echo -e "\nRMAN backup script\nusage: $0 <SID> <mode>\n"
    echo -e "\t*<SID> = target database, one of those: $DBLIST\n\t*<mode> = $BKPMODE\n"
    exit 1
}

chk_ret_code(){
    local return_code=$1
    [ $? -ne 0 ] && echo "ERROR: command exited with code $return_code" && exit $return_code
}

#-------- variables check ----------------------------------

# list of databases, pipe separated
DBLIST='^(ALP1|EMAIL|IMP)$'
BKPMODE='^(FULL|INCR)$'

# the environment variables are taken from an external file
# make sure that everything is there
[ ! -r ~/bin/oracle_script_env.sh ] && echo "ERROR: Can't read ~/bin/oracle_script_env.sh" && exit -1;

source ~/bin/oracle_script_env.sh

LOGFILE=$($MKTEMP)

[ -z $ORACLE_HOME ] && echo "Missing variable ORACLE_HOME" && exit -1;
[ -z $MAIL ] && echo "Missing variable MAIL" && exit -1;
[ -z $DATE ] && echo "Missing variable DATE" && exit -1;
[ -z $MKTEMP ] && echo "Missing variable MKTEMP" && exit -1;
[ -z $CRON_RECIPIENT ] && echo "Missing variable CRON_RECIPIENT" && exit -1;

[ $# -ne 2 ] && usage;
MODE=$2
[[ ! $MODE =~ $BKPMODE ]] && echo "ERROR: unknown backup mode $MODE" && usage;
# overwrite the env ORACLE_SID with the one from the command line
[[ ! $1 =~ $DBLIST ]] && echo "ERROR: unknown target database $SID" && usage;
export ORACLE_SID=$1

RMANBIN=$ORACLE_HOME/bin/rman
[ ! -x $RMANBIN ] && echo "Can't execute RMAN at $RMANBIN" && exit -1;

SQLPLUSBIN=$ORACLE_HOME/bin/sqlplus
[ ! -x $SQLPLUSBIN ] && echo "Can't execute SQLPLUS at $SQLPLUSBIN" && exit -1;

#------- RMAN PROCEDURE ------------------------------------------------
# 1. rotate logfile
# 2. perform a backup in incremental cumulative mode
# 3. rotate logfile
# 4. backup the archivelogs
# 5. delete the obsolete backups older than 


# build the backup command
BKPCOMMAND=""
case "$MODE" in
    FULL)
        BKPCOMMAND="BACKUP INCREMENTAL LEVEL 0 CUMULATIVE DATABASE TAG 'FULL-$(date +%A)';"
        ;;
    INCR)
        BKPCOMMAND="BACKUP INCREMENTAL LEVEL 1 CUMULATIVE DATABASE TAG 'INCR-$(date +%A)';"
        ;;
esac

# open command block, redirects all outputs to log file
(

        elapsed_start=$(date +%s)

        # log file rotation
        $SQLPLUSBIN / as sysdba << EOF
ALTER SYSTEM SWITCH LOGFILE;
EOF
        chk_ret_code $?


        # backup
        $RMANBIN target / nocatalog << EOF
$BKPCOMMAND
EOF
        chk_ret_code $?

        # log file rotation
        $SQLPLUSBIN / as sysdba << EOF
ALTER SYSTEM SWITCH LOGFILE;
EOF
        chk_ret_code $?

        # archive logs backup
        # and delete the obsolete
        $RMANBIN target / nocatalog << EOF
BACKUP ARCHIVELOG ALL NOT BACKED UP DELETE ALL INPUT TAG 'ARCH-$(date +%A)';
EOF
        chk_ret_code $?

        $RMANBIN target / nocatalog << EOF
CROSSCHECK BACKUP;
DELETE NOPROMPT OBSOLETE;
EOF
        chk_ret_code $?

        # calculate total time
        elapsed_stop=$(date +%s)
        elapsed=$((elapsed_stop - elapsed_start))
        echo "duration: $elapsed seconds"


# close command block
) > $LOGFILE


# mail a summary of the backups with the full log in attachment
#(
#    $RMANBIN target / nocatalog << EOF
#LIST BACKUP SUMMARY;
#EOF 
#)
#echo "backup finished successfully" |mail -a $LOGFILE -s "BACKUP $ORACLE_SID $MODE $(date +%A)" $CRON_RECIPIENT


exit $?
