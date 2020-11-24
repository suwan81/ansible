#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` <interval seconds> <repeate count> "
    echo "Example for run : `basename $0` 2 5 "
    exit
fi

SLEEP=`expr $1 - 1`
TCNT=$2
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

for ((j=0;j<$TCNT;j++))
do
    echo ""
    echo $DATE_TIME"                                                              Greenplum "
        RESULT=`psql -c "select a.* from dba.sp_qq() as a  where status <> 'IDLE' and query not like '%sp_qq%';"`
    echo "${RESULT}"

        sleep $SLEEP
done
