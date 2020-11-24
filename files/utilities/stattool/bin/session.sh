#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

i=0
while [ $i -lt $2 ]
do
psql -At -c "select to_char(now(), 'yyyy-mm-dd hh24:mi:ss'), count(*) t_cnt from pg_stat_activity  where state not like '%idle%' ;"
#psql -At -c " select to_char(now(), 'yyyy-mm-dd hh24:mi:ss'), count(*) t_cnt from pg_stat_activity  where current_query not like '%IDLE%' ;"
sleep $1
i=`expr $i + 1`
#echo $i
done
