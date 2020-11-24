#!/bin/sh
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

## statlog(90 days)
find /data/utilities/statlog -mtime +90 -print -exec rm -f {} \;

## mdw pg_log (30 days)
/usr/bin/find /data*/master/gpseg-1/pg_log/pglogbak/*.csv* -mtime +30 -exec rm -rf {} \;

## segment pg_log (30 days) 
/usr/local/greenplum-db/bin/gpssh -f /data/utilities/setup/hostfile_seg -e '/bin/find /data*/*/gpseg*/pg_log/*.csv -mtime +30 -print -exec rm -f {} \;'
