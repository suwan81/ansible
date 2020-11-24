#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <interval seconds> <repeate count> "
    echo "Example for run : `basename $0` 2 5 "
    exit
fi
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

SLEEP=20
TCNT=3

for ((j=0;j<$TCNT;j++))
do
    ssh mdw "/data/utilities/mem_info.sh"
    for ((i=1;i<=$SEG_COUNT;i++))
    do
        ssh sdw${i}  "/data/utilities/mem_info.sh"
    done

    sleep $SLEEP
done
