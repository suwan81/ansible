#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'

#ver 4,5,6
psql -c " SELECT pid, relname, locktype, mode from pg_locks, pg_class where relation=oid and relname not like 'pg_%' order by 3;"

sleep $1
i=`expr $i + 1`
#echo $i
done
