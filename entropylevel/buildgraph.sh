#! /bin/sh
RRDFILE="/data/julien/code/scripts/entropylevel/entropylvl.rrd"

rrdtool graph /data/www/pki/entropy_level.png  --start $1 --title "Entropy level on Zerhuel" \
--width 600 --vertical-label "bits available" \
--color BACK#000083 --color SHADEA#000000 --color SHADEB#000000 \
--color CANVAS#000000 --color GRID#999999 --color MGRID#666666 \
--color FONT#CCCCCC --color FRAME#333333 \
-u 4200 -l 0 -r \
TEXTALIGN:left \
DEF:average=$RRDFILE:entropylvl:AVERAGE \
LINE1:average#c5c5FF:"entropy level" \
GPRINT:average:MIN:"\tmin= %4.0lf bits" \
GPRINT:average:MAX:"\tmax= %4.0lf bits" \
GPRINT:average:AVERAGE:"\tavg= %4.0lf bits"

