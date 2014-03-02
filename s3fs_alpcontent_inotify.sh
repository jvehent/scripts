#!/bin/sh

MONITORLIST="/directory/source/:/directory/destination/ /directory/source2/:/directory/destination2/"

for pair in $MONITORLIST; do
    # get the current path
    CONTENTPATH=$(echo $pair|cut -d ':' -f 1)
    S3FSPATH=$(echo $pair|cut -d ':' -f 2)
    CURPATH=$(pwd)

    inotifywait -mr --timefmt '%d/%m/%y %H:%M' --format '%T %w %f %e' \
    -e create -e modify -e delete $CONTENTPATH \
    | while read date time dir file event
    do
        if [[ $dir =~ /\.svn/ ]]
        then
            echo "skipping .svn change"
        else
            ELAPSED_START=$(date "+%s%N")

            FILECHANGE=${dir}${file}
            # convert absolute path to relative
            SOURCE=$(echo "$FILECHANGE" | sed 's_'$CURPATH'/__')

            DEST=$(echo $SOURCE | sed 's_'$CONTENTPATH'_'$S3FSPATH'_')
            type="null"

            case $event in
            CREATE,ISDIR)
                mkdir -p "$DEST"
                type="folder"
                ;;
            MODIFY)
                cp -f "$SOURCE" "$DEST"
                type="file"
                ;;
            DELETE,ISDIR)
                if [ -d $DEST ]; then rmdir "$DEST";fi
                type="folder"
                ;;
            DELETE)
                # delete only if destination exist
                if [ -e $DEST ]; then
                    rm -f "$DEST"
                    type="file"
                else
                    echo "$DEST doesn't exist"
                fi
                ;;
            esac

            ELAPSED_STOP=$(date "+%s%N")
            ELAPSED=$(echo "scale=2; ($ELAPSED_STOP - $ELAPSED_START)/1000000"|bc -l)
            if [ "$type" != "null" ]; then
                echo "$date-$time, $type $FILECHANGE was $event at $DEST (in $ELAPSED ms)"
            fi
        fi
    done &
done
