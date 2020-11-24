#!/bin/bash

export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

ECHO="/bin/echo"
LOGFILE="/data/utilities/log/cron_vacuum_analyze_`date '+%Y-%m-%d'`.log"

$ECHO "  CATALOG TABLE VACUUM ANALYZE started at " > $LOGFILE
$DATE >> $LOGFILE 

VCOMMAND="VACUUM ANALYZE"
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $PGDATABASE | psql -a $PGDATABASE  >> $LOGFILE

$ECHO "..............................." >> $LOGFILE 
$ECHO "  CATALOG TABLE VACUUM ANALYZE Completed at" >> $LOGFILE
$DATE >> $LOGFILE 


################################# DASHBOARD LOG START #################################
DASHBOARD_LOGFILE=/data/utilities/dashboard/log/agent_jobs_status.log
DASHBOARD_JOBNAME='Catalog Table Vacuum Analyze'
DASHBOARD_LOGDATE=`date +%Y-%m-%d`
DASHBOARD_LOGTIME=`date "+%H:%M:%S"`
echo $DASHBOARD_JOBNAME"|"$DASHBOARD_LOGDATE"|"$DASHBOARD_LOGTIME >> $DASHBOARD_LOGFILE
################################## DASHBOARD LOG END #################################
