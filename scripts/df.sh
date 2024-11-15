#! /bin/bash

while :
do
    date +"%H:%M:%S"
    echo "TMP:"
    df -h /tmp
    df -i /tmp


    echo "ROOT:"
    df -h /
    df -i /
    sleep 3m

    echo ""
done
