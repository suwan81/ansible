#!/bin/bash

#crontab
export MASTER_DATA_DIRECTORY=/data/master/gpseg-1
source /usr/local/greenplum-db/greenplum_path.sh
source /data/.bash_profile


PGM_ID=ma_add_part_`date '+%Y%m%d'`
MEDW_NO=`echo $0 | sed 's/\./ /g' |awk '{print $1}'`
MEDW_HOME=/data/utilities
LOGDIR=${MEDW_HOME}/log
LOGFILE=$LOGDIR/${PGM_ID}.log

DATE=$1

START_TM1=`date "+%H:%M:%S"`
echo "$0: START TIME : " $START_TM1

###### script start

echo $MEDW_NO"| start " `date`  > ${LOGDIR}/${PGM_ID}.sql.log 2>&1

echo $MEDW_NO"| start " `date`  > ${LOGDIR}/${PGM_ID}.sql.log 2>&1

#ALREADY_RUNNING=`ps -ef | grep ma_add_part | grep -v grep | grep -v $$ | wc -l`

#if [ ${ALREADY_RUNNING} -ge 1 ]; then
#        echo "Already running..."  >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1
#	exit 0
#fi


#======= change add_part=(4)

if [ -z ${DATE} ]; then
	   add_part=4
else
       add_part=`psql -AXtc "select '${DATE}'::date - current_date;"`
fi


###### DAILY PARTION ADD
CHKCNT_SQL="SELECT count(1) 
	FROM (SELECT * FROM dba.tb_add_part WHERE prt_type = 'DAY' ) as tb 
		INNER JOIN generate_series(1, ${add_part}) i ON  1=1 
		LEFT OUTER JOIN pg_partitions pg on lower(tb.schema_nm) = pg.schemaname and lower(tb.tb_nm) = pg.tablename and partitiontype = 'range' and to_char(current_date + (('' || i.i) || ' day')::interval,'YYYYMMDD') = replace(partitionname,'p','') 
	WHERE pg.tablename is null;"

#CHKCNT_R=`psql -AXtc "${CHKCNT_SQL}"`
CHKCNT_R=3

SQL="SELECT 'select dba.ma_add_part(' || i.i || ', ''' || tb.schema_nm || ''',''' || tb.tb_nm || ''', ''' || mode_part || ''', ''DAY'' );' 
	FROM (SELECT * FROM dba.tb_add_part WHERE prt_type = 'DAY' ) as tb 
	        INNER JOIN generate_series(1, ${add_part}) i on 1=1 
	        LEFT OUTER JOIN pg_partitions pg ON lower(tb.schema_nm) = pg.schemaname
                                           AND lower(tb.tb_nm) = pg.tablename
					   AND partitiontype = 'range'
					   AND to_char(current_date + (('' || i.i) || ' day')::interval,'YYYYMMDD') = replace(partitionname,'p','')
		LEFT OUTER JOIN (SELECT relname,pl.mode 
				FROM pg_locks as pl, pg_class as pc 
				WHERE pl.relation = pc.oid and mode like '%Lock%' ) tt 
			ON tt.relname = tb.tb_nm where pg.tablename is null"

while [ $CHKCNT_R -gt 0 ]; do
   	psql -AXtc "${SQL};"      | psql -e      >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1

	CHKCNT=`psql -AXtc "${CHKCNT_SQL}"`
   	if [ $CHKCNT -eq 0 ]; then
      		break
   	fi
   	sleep 600
	CHKCNT_R=`expr ${CHKCNT_R} - 1`
done

###### MONTHLY PARTION ADD
CHKCNT_SQL="SELECT count(1) 
	FROM (SELECT * FROM dba.tb_add_part WHERE prt_type = 'MONTH' ) as tb 
		INNER JOIN generate_series(1, ${add_part}) i ON  1=1 
		LEFT OUTER JOIN pg_partitions pg on lower(tb.schema_nm) = pg.schemaname and lower(tb.tb_nm) = pg.tablename and partitiontype = 'range' and to_char(current_date + (('' || i.i) || ' month')::interval,'YYYYMM') = replace(partitionname,'p','') 
	WHERE pg.tablename is null;"

#CHKCNT_R=`psql -AXtc "${CHKCNT_SQL}"`
CHKCNT_R=3

SQL="SELECT 'select dba.ma_add_part(' || i.i || ', ''' || tb.schema_nm || ''',''' || tb.tb_nm || ''', ''' || mode_part || ''', ''MONTH'' );' 
	FROM (SELECT * FROM dba.tb_add_part WHERE prt_type = 'MONTH' ) as tb 
	        INNER JOIN generate_series(1, ${add_part}) i on 1=1 
	        LEFT OUTER JOIN pg_partitions pg ON lower(tb.schema_nm) = pg.schemaname
                                           AND lower(tb.tb_nm) = pg.tablename
					   AND partitiontype = 'range'
					   AND to_char(current_date + (('' || i.i) || ' month')::interval,'YYYYMM') = replace(partitionname,'p','')
		LEFT OUTER JOIN (SELECT relname,pl.mode 
				FROM pg_locks as pl, pg_class as pc 
				WHERE pl.relation = pc.oid and mode like '%Lock%' ) tt 
			ON tt.relname = tb.tb_nm where pg.tablename is null"

while [ $CHKCNT_R -gt 0 ]; do
   	psql -AXtc "${SQL};"      | psql -e      >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1

	CHKCNT=`psql -AXtc "${CHKCNT_SQL}"`
   	if [ $CHKCNT -eq 0 ]; then
      		break
   	fi
   	sleep 600
        CHKCNT_R=`expr ${CHKCNT_R} - 1`
done

wait
###### script end

echo $MEDW_NO"| end " `date`  >> ${LOGDIR}/${PGM_ID}.sql.log 2>&1


END_TM1=`date "+%H:%M:%S"`
echo $MEDW_NO"|"$START_TM1"|"$END_TM1  > $LOGFILE
echo "$0: End TIME : "$END_TM1

################################# DASHBOARD LOG START #################################
DASHBOARD_LOGFILE=/data/utilities/dashboard/log/agent_jobs_status.log
DASHBOARD_JOBNAME='ADD Partitions'
DASHBOARD_LOGDATE=`date +%Y-%m-%d`
DASHBOARD_LOGTIME=`date "+%H:%M:%S"`
echo $DASHBOARD_JOBNAME"|"$DASHBOARD_LOGDATE"|"$DASHBOARD_LOGTIME >> $DASHBOARD_LOGFILE
################################## DASHBOARD LOG END ##################################
