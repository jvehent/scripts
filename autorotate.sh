#! /bin/sh
echo
echo "picture rotation in progress"
echo


# create a new folder
mkdir rotated

# get the .JPG extensions and rename them in .jpg
#
LISTJPG=`ls -l |grep JPG|tail -n 1|gawk {'print $8'}`
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
LISTJPG=`ls -l |grep jpg|tail -n 1|gawk {'print $8'}`

if [ $LISTJPG ]
then
      for i in *.jpg
      do
         ORIENTATION=`exiv2 pr -p t $i |grep Orientation|gawk {'print $4 $5'}`

         echo "$i has orientation $ORIENTATION"

         if [ "$ORIENTATION" = "left,bottom" ]
         then
            convert $i -rotate -90 rotated/$i
            exiv2 -M "set Exif.Image.Orientation Short 1" rotated/$i
         elif [ "$ORIENTATION" = "right,top" ]
         then
            convert $i -rotate 90 rotated/$i
            exiv2 -M "set Exif.Image.Orientation Short 1" rotated/$i
         else
            cp "$i" rotated/
         fi
      done
fi
