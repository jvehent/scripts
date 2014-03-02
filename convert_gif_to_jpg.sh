# get the .JPG extensions and rename them in .jpg
#
LISTGIF=`ls -l |grep gif|tail -n 1|awk {'print $9'}`
if [ $LISTGIF ]
then
        for i in *.gif
        do
                echo "convert $i to jpg"
		convert $i $i.jpg
		rm $i
        done
fi

