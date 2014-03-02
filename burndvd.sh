#! /bin/bash
if [ $# != 1 ] 
then
        echo "usage: sh burndvd <folder>"
else
	growisofs -dvd-compat -input-charset=ISO-8859-1 -Z /dev/hdc -R -J -pad $1
fi
