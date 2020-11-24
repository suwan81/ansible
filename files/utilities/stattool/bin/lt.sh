#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'

# ver 6
psql -c "SELECT distinct w.locktype,w.relation::regclass AS relation, w.mode,w.pid AS waiting_pid,other.pid AS running_pid, now() as ctime FROM pg_catalog.pg_locks AS w JOIN pg_catalog.pg_stat_activity AS w_stm ON (w_stm.pid = w.pid) JOIN pg_catalog.pg_locks AS other ON ((w.DATABASE = other.DATABASE AND w.relation  = other.relation) OR w.transactionid = other.transactionid) JOIN pg_catalog.pg_stat_activity AS other_stm ON (other_stm.pid = other.pid) WHERE NOT w.granted AND w.pid <> other.pid; "

# ver4,5
#psql -c "SELECT distinct w.locktype,w.relation::regclass AS relation, w.mode,w.pid AS waiting_pid,other.pid AS other_pid FROM pg_catalog.pg_locks AS w JOIN pg_catalog.pg_stat_activity AS w_stm ON (w_stm.procpid = w.pid) JOIN pg_catalog.pg_locks AS other ON ((w.DATABASE = other.DATABASE AND w.relation  = other.relation) OR w.transactionid = other.transactionid) JOIN pg_catalog.pg_stat_activity AS other_stm ON (other_stm.procpid = other.pid) WHERE NOT w.granted AND w.pid <> other.pid;"

sleep $1
i=`expr $i + 1`
#echo $i
done
