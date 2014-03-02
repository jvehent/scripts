#! /bin/sh

if [ $# -lt 3 ]
then
	echo "usage: ./resize <height> <width> <quality in %> <redate>"
	echo "example: ./resize 1024 768 80 <- resize all jpeg in current folder in 1024x768 quality 100"
	echo "example: ./resize 800 600 75 redate <- resize and change name according to EXIF timestamp"
	exit 1
fi

#resize to 1024x768
#
RESIZETO1=$1
RESIZETO2=$2
QUALITY=$3

# get the .JPG extensions and rename them in .jpg
#
LISTJPG=`ls -l |grep JPG|tail -n 1|awk {'print $9'}`
if [ $LISTJPG ]
then
	for i in *.JPG
	do
		NEWNAME=`ls |grep "$i"|cut -d "." -f1`
		mv "$i" "$NEWNAME.jpg"
		echo "changing JPG to jpg for $i"
	done
fi


# is there any .jpg to process in this folder ?
#
LISTJPG=`ls -l |grep jpg|tail -n 1|awk {'print $9'}`
JOB=0

if [ $LISTJPG ]
then
	mkdir ./resized

	for i in *.jpg
	do
		echo "considering $i"

		# rename by date (if the option is chosen)
		#
		if [ $1 == "redate" ]
		then
			NEWNAME=`exiv2 -p s $i|grep timestamp|awk {'print $4$5'}|sed -e 's/://g'`.jpg
		else
			NEWNAME=$i
		fi

		# get the size written in the exif tag
		#
		RESOLUTION1=`exiv2 -p s $i |grep 'Image size'|awk {'print $4'}`
		RESOLUTION2=`exiv2 -p s $i |grep 'Image size'|awk {'print $6'}`
		if [ $RESOLUTION1 -lt $RESOLUTION2 ]
		then
			# and use it to select the way the image is resized
			#
			if [ $RESOLUTION1 -gt $RESIZETO2 ]
			then
				echo "resizing $i from $RESOLUTION1 x $RESOLUTION2 to 
$RESIZETO2 x $RESIZETO1"
				convert -resize $RESIZETO2 -quality $QUALITY "$i" "./resized/$NEWNAME"
				rm "$i"

				JOB=1
			fi
		else
			if [ $RESOLUTION1 -gt $RESIZETO1 ]
			then
				echo "resizing $i from $RESOLUTION1 x $RESOLUTION2 to 
$RESIZETO1 x $RESIZETO2"
				convert -resize $RESIZETO1 -quality $QUALITY "$i" "./resized/$NEWNAME"
				rm "$i"

				JOB=1
			fi
		fi
	done
fi


# move the content of the new folder into the current one
#
#if [ $JOB != 0 ]
#then
#	mv ./new/* .
#	rmdir ./new
#	chown www-data:adm *
#	chmod 770 *
#	echo "=== Resizing done ==="
#else
#	rmdir ./new
#	echo
#	echo " ## NOTHING TO DO.... LEAVING ## "
#	echo
#fi
