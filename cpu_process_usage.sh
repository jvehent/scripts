#!/usr/bin/env bash

# calculate the cpu usage of a single process
# jvehent oct.2013

[ -z $1 ] && echo "usage: $0 <pid>"

sfile=/proc/$1/stat
if [ ! -r $sfile ]; then echo "pid $1 not found in /proc" ; exit 1; fi

proctime=$(cat $sfile|awk '{print $14}')
totaltime=$(grep '^cpu ' /proc/stat |awk '{sum=$2+$3+$4+$5+$6+$7+$8+$9+$10; print sum}')

echo "time                        ratio      cpu%"

while [ 1 ]; do
    sleep 1
    prevproctime=$proctime
    prevtotaltime=$totaltime
    proctime=$(cat $sfile|awk '{print $14}')
    totaltime=$(grep '^cpu ' /proc/stat |awk '{sum=$2+$3+$4+$5+$6+$7+$8+$9+$10; print sum}')
    ratio=$(echo "scale=2;($proctime - $prevproctime) / ($totaltime - $prevtotaltime)"|bc -l)
    echo "$(date --rfc-3339=seconds);  $ratio;      $(echo "$ratio*100"|bc -l)"
done
