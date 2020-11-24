#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh
i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'
#psql -c "select now()-query_start as elapsed, usename, client_addr, waiting, sess_id, now() as ctime from pg_stat_activity  where state not like 'idle%' order by 4, 1 desc;"

# ver 4,5
#psql -c " select now()-query_start, usename, client_addr, waiting, procpid, sess_id from pg_stat_activity  where current_query not like '%IDLE%' order by 4, 1 desc;"

# ver 6
psql -c "select waiting_reason, now() as ctime, now()-query_start as running_time, rsgname, usename, client_addr, waiting, pid, sess_id, state, substring(query,1,60) as query from pg_stat_activity  where state <> 'idle' and pid <> pg_backend_pid() order by 6, 2 desc;"
sleep $1
i=`expr $i + 1`
#echo $i
done
