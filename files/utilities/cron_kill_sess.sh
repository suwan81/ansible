export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

date >> /data/utilities/statlog/killed_sess.${DATE} 2>&1
psql -AXtc " select 'select pg_terminate_backend('||pid||');'  from pg_stat_activity where state not like '%idle%' and  now()-query_start >= '04:00:00' ;" | psql -e >> /data/utilities/statlog/killed_sess.${DATE} 2>&1
echo >> /data/utilities/statlog/killed_sess.${DATE}
