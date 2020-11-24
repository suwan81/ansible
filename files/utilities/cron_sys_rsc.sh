#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <interval seconds> <repeate count> "
    echo "Example for run : `basename $0` 2 5 "
    exit
fi

. /home/gpadmin/.bash_profile

export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

SLEEP=`expr $1 - 1`
TCNT=$2
for ((j=0;j<$TCNT;j++))
do
	values=`${MON_HOME}/run_sys_rsc.sh`
	echo "${values}"  >> /data/utilities/statlog/sys.`/bin/date '+%Y%m%d'`.txt
	sleep $SLEEP
done
