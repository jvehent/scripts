#!/bin/bash
# Get current swap usage for all running processes
# NOTE: MUST BE RUN AS ROOT (checks /proc/)
# Erik Ljungstrom 27/05/2011
# Modified by Mikko Rantalainen 2012-08-09
# Modified by Brandon Johnson 2013-07-30
# Pipe the output to "sort -nk3" to get sorted output
# set PID to echo full command path, mysql procs only showed "mysql", which was useless on services with multiple daemons running.
# Also added MB/GB feature for the purposes of using this tool with grep -e "MB" -e "GB"

SUM=0
OVERALL=0
for DIR in `find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"`
do
    PID=`echo $DIR | cut -d / -f 3`
    PROGNAME=`ps -p $PID -o cmd --no-headers`
    for SWAP in `grep Swap $DIR/smaps 2>/dev/null | awk '{ print $2 }'`
    do
        let SUM=$SUM+$SWAP
    done

    if (( $SUM > 1048576 )); then
        echo "PID=$PID swapped $[$SUM/1048576] MB ($PROGNAME)"
    elif (( $SUM > 1042 )); then
        echo "PID=$PID swapped $[$SUM/1024] MB ($PROGNAME)"
    elif (( $SUM > 0 )); then
        echo "PID=$PID swapped $SUM KB ($PROGNAME)"
    fi
    let OVERALL=$OVERALL+$SUM
    SUM=0
done
echo "Overall swap used: $[$OVERALL/1048576] (GB), $[$OVERALL/1024] (MB), $OVERALL KB"
