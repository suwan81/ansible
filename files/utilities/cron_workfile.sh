#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <interval seconds> <repeate count> "
    echo "Example for run : `basename $0` 2 5 "
    exit
fi

/data/utilities/workfile_check.sh $1 $2 >> /data/utilities/statlog/workfile.`/bin/date '+%Y%m%d'`.txt &
