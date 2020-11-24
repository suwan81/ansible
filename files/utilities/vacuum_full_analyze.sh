#!/bin/bash

if [ -f /home/gpadmin/.bash_profile ];then
. /home/gpadmin/.bash_profile
fi

DBNAME="tidb"
DATE="/bin/date"
ECHO="/bin/echo"
LOGFILE="/data/utilities/log/vacuum_full_analyze_`date '+%Y-%m-%d'`.log"

$ECHO "  CATALOG TABLE VACUUM ANALYZE started at " > $LOGFILE
$DATE >> $LOGFILE 

VCOMMAND="VACUUM FULL VERBOSE"
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE

VCOMMAND="ANALYZE"
psql -tc "select '$VCOMMAND' || ' pg_catalog.' || relname || ';' from pg_class a,pg_namespace b where a.relnamespace=b.oid and b.nspname= 'pg_catalog' and a.relkind='r'" $DBNAME | psql -a $DBNAME  >> $LOGFILE

reindexdb -s >> $LOGFILE
$ECHO "..............................." >> $LOGFILE 
$ECHO "  CATALOG TABLE VACUUM ANALYZE Completed at" >> $LOGFILE
$DATE >> $LOGFILE
