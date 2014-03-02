# get the .JPG extensions and rename them in .jpg
#
LISTJPG=`ls -l |grep jpeg|tail -n 1|awk {'print $9'}`
if [ $LISTJPG ]
then
        for i in *.jpeg
        do
                NEWNAME=`ls |grep "$i"|cut -d "." -f1`
                mv "$i" "$NEWNAME.jpg"
                echo "changing JPG to jpg for $i"
        done
fi

