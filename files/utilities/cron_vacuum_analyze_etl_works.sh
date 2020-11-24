#!/bin/bash

export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

ECHO="/bin/echo"
LOGFILE="/data/utilities/log/cron_vacuum_analyze_etl_works`date '+%Y-%m-%d'`.log"

$ECHO "  etl.works TABLE VACUUM ANALYZE started at " > $LOGFILE
$DATE >> $LOGFILE 

VCOMMAND="VACUUM ANALYZE"
#XCOMMAND="SELECT COUNT(*) FROM"
psql -tc "select '$VCOMMAND' || ' etl.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'etl' and a.relkind='r' and relname= 'works'" $PGDATABASE | psql -a $PGDATABASE  >> $LOGFILE
#psql -tc "select '$XCOMMAND' || ' etl.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'etl' and a.relkind='r' and relname= 'works'" $PGDATABASE | psql -a $PGDATABASE  >> $LOGFILE

$ECHO "..............................." >> $LOGFILE 
$ECHO "  etl.works TABLE VACUUM ANALYZE Completed at" >> $LOGFILE
$DATE >> $LOGFILE 


################################# DASHBOARD LOG START #################################
DASHBOARD_LOGFILE=/data/utilities/dashboard/log/agent_jobs_status.log
DASHBOARD_JOBNAME='etl.works Table Vacuum Analyze'
DASHBOARD_LOGDATE=`date +%Y-%m-%d`
DASHBOARD_LOGTIME=`date "+%H:%M:%S"`
echo $DASHBOARD_JOBNAME"|"$DASHBOARD_LOGDATE"|"$DASHBOARD_LOGTIME >> $DASHBOARD_LOGFILE
################################## DASHBOARD LOG END ##################################
