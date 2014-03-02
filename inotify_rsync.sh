#!/bin/bash
# Julien Vehent - 2014

LOCALDIR="/srv/data/photos/"
REMOTEDIR="server123.example.net:/var/storage/photos/"

pfile=""
pdir=""

echo "starting inotify listener on $LOCALDIR"
# feed the inotify events into a while loop
inotifywait -mr --format '%w|%f' \
-e create -e modify $LOCALDIR \
| while read event
do
    dir=$(echo $event|cut -d '|' -f 1)
    file=$(echo $event|cut -d '|' -f 2)

    echo "NEW EVENT on file '$file' in directory '$dir'"

    # if file is currently being written, don't sync it
    fds=$(lsof "$dir$file")
    if [ "$fds" != "" ]; then
        echo "open file descriptors on file. waiting 1s."
        sleep 1
        fds=$(lsof "$dir$file")
        if [ "$fds" != "" ]; then
            echo "open file descriptions on file after wait. skipping."
            continue
        fi
    fi

    # if current event concern the same file as previous event, skip
    if [ "$file" == "$pfile" ]; then
        echo "skipping dups"
        continue
    fi

    # if rsync is currently running on the system, skip
    if [ "$(pidof rsync)" != "" ]; then
        echo "rsync is running. skipping"
        continue
    fi

    echo "calling rsync from '$LOCALDIR' to '$REMOTEDIR'"
    rsync --progress --partial -rltzu $LOCALDIR $REMOTEDIR

    pfile=$file
    pdir=$dir
done

