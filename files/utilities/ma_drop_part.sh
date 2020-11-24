#!/bin/bash

#crontab
export MASTER_DATA_DIRECTORY=/data/master/gpseg-1
source /usr/local/greenplum-db/greenplum_path.sh
source /usr/local/greenplum-cc-web/gpcc_path.sh


PGM_ID=ma_drop_part_`date '+%Y%m%d'`
MEDW_NO=`echo $0 | sed 's/\./ /g' |awk '{print $1}'`
MEDW_HOME=/data/utilities
LOGDIR=${MEDW_HOME}/log
LOGFILE=$LOGDIR/${PGM_ID}.log


START_TM1=`date "+%H:%M:%S"`
echo "$0: START TIME : " $START_TM1

###### script start
#source ${MEDW_HOME}/shell/env.sh

echo $MEDW_NO"| start " `date`  > ${LOGDIR}/${PGM_ID}.sql.log 2>&1

#======= change drop_part

CHKCNT_R=2
#CHKCNT_R=`psql -U etl_user -AXtc "select count(1) from tb_add_part tb join pg_partitions pg on lower(tb.schema_nm) = pg.schemaname and lower(tb.tb_nm) = pg.tablename where replace(pg.partitionname,'p','') < replace((current_date - tb.keeping_term::interval)::date,'-','') and pg.schemaname <> 'eesstg';"`

SQL="select 'alter table ' || pg.schemaname || '.' || pg.tablename || ' drop partition ' || pg.partitionname || ';' 
       from dba.tb_add_part tb join pg_partitions pg on lower(tb.schema_nm) = pg.schemaname
                                                and lower(tb.tb_nm) = pg.tablename 
	  where to_date(replace(pg.partitionname,'p',''), 'yyyymmdd') < to_date(to_char((current_date - tb.keeping_term::interval), 'yyyymmdd'), 'yyyymmdd')
	    and lower(tb.tb_nm) not in ( select distinct relname
                                       from pg_locks as pl, pg_class as pc
									  where pl.relation = pc.oid 
									    and mode like '%Lock%' )"

while [ $CHKCNT_R -gt 0 ]; do

#   psql -U etl_user -AXtc "${SQL} and schemaname = 'xxxxdb';"                                    | psql -U etl_user -e >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1
#   psql -U int_user -AXtc "${SQL} and schemaname = 'xxxxdb' and tb.table_owner = 'int_user';"     | psql -U int_user -e >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1
#   psql -U int_user -AXtc "${SQL} and schemaname = 'xxxxdb' and tb.table_owner = 'spec_app_user'" | psql -U spec_app_user -e >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1
#   psql -U etl_user -AXtc "${SQL} and schemaname = 'xxxxdb';"                                      | psql -U etl_user -e >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1

   psql -h 192.28.5.71 -d prod -U gpadmin -AXtc "${SQL};"   | psql -h 192.28.5.71 -d prod -U gpadmin -e >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1

#   CHKCNT_R=`psql -U etl_user -AXtc "select count(1) from tb_add_part tb join pg_partitions pg on lower(tb.schema_nm) = pg.schemaname and lower(tb.tb_nm) = pg.tablename where replace(pg.partitionname,'p','') < replace((current_date - tb.keeping_term::interval)::date,'-','') and pg.schemaname <> 'eesstg';"`
   CHKCNT_R=`expr $CHKCNT_R - 1`
   if [ $CHKCNT_R -eq 0 ]; then
      break
   fi

   sleep 600
done

wait
###### script end

echo $MEDW_NO"| end " `date`  >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1


END_TM1=`date "+%H:%M:%S"`
echo $MEDW_NO"|"$START_TM1"|"$END_TM1  > $LOGFILE
echo "$0: End TIME : "$END_TM1

################################# DASHBOARD LOG START #################################
#DASHBOARD_LOGFILE=/data/utilities/dashboard/log/agent_jobs_status.log
#DASHBOARD_JOBNAME='DROP Partitions'
#DASHBOARD_LOGDATE=`date +%Y-%m-%d`
#DASHBOARD_LOGTIME=`date "+%H:%M:%S"`
#echo $DASHBOARD_JOBNAME"|"$DASHBOARD_LOGDATE"|"$DASHBOARD_LOGTIME >> $DASHBOARD_LOGFILE
################################## DASHBOARD LOG END ##################################
