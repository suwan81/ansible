#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

psql -c "select pg_logfile_rotate()"

JOBDATE=`date -d -1hour '+%Y-%m-%d_%H*'`
FILENAME=gpdb-${JOBDATE}
/bin/mv /data/master/gpseg-1/pg_log/${FILENAME}.csv /data/master/gpseg-1/pg_log/pglogbak 
/bin/gzip /data/master/gpseg-1/pg_log/pglogbak/${FILENAME}.csv

/usr/bin/find /data/master/gpseg-1/pg_log/pglogbak/* -mtime +14 -exec rm -rf '{}' \;
