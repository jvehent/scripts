#! /bin/sh
RRD="entropylvl.rrd"
while [ 1 ]
do
   DATE=`date +%s`
   ENTLVL=`cat /proc/sys/kernel/random/entropy_avail`
   echo "$DATE:$ENTLVL" >> entlvl.log
   #rrdtool update $RRD N:$ENTLVL
   sleep 1
done
