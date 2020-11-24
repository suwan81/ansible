#! /bin/bash

source /usr/local/greenplum-db/greenplum_path.sh
source /home/gpadmin/.bash_profile

GPDBVER=`su - gpadmin -c "psql -AXtc 'select * from version();'" | awk '{print $5}' | cut -d "." -f 1`
GPCCWEBCHK=`ls -dl /usr/local/greenplum-cc* | grep -v ">" | awk '{print $9}' | cut -d "-" -f 3 | head -n 1`
GPCCVER=`ls -al /usr/local/greenplum-cc-web | awk '{print $11}' | cut -d "-" -f 4 | cut -d "." -f 1`

echo "1. hostname"
hostname

echo ""
echo "2. date"
su - gpadmin -c "gpssh -f /home/gpadmin/gpconfigs/hostfile_gpdb date"

echo ""
echo "3. ntpd"
su - gpadmin -c "gpssh -f /home/gpadmin/gpconfigs/hostfile_gpdb /sbin/service ntpd status | egrep 'is running|Active'"

echo ""
echo "4. gpstate"
su - gpadmin -c "/usr/local/greenplum-db/bin/gpstate"

echo ""
echo "5. gpcc"
if [ "${GPCCWEBCHK}" != "web" ]; then
	su - gpadmin -c "/usr/local/greenplum-cc/bin/gpcc status"
else
	if [ ${GPCCVER} -le 3 ]; then
		su - gpadmin -c "/usr/local/greenplum-cc-web/bin/gpcmdr --status"
	elif [ ${GPCCVER} -ge 4 ]; then
		su - gpadmin -c "/usr/local/greenplum-cc-web/bin/gpcc status"
	else
		echo "GPCC not installed"
	fi
fi

echo ""
echo "6. pxf"
if [ ${GPDBVER} -eq 6 ]; then
	su - gpadmin -c "/usr/local/greenplum-db/pxf/bin/pxf cluster status"
else
	if [ ${GPDBVER} -eq 5 ]; then
		su - gpadmin -c "gpssh -f /home/gpadmin/gpconfigs/hostfile_gpdb /usr/local/greenplum-db/pxf/bin/pxf status |grep running"
	else
		echo "PXF not initialized"
	fi
fi


echo ""
echo "7. session"
if [ ${GPDBVER} -eq 6 ]; then
	su - gpadmin -c "psql -c 'select waiting_reason, now()-query_start as running_time, rsgname, usename, client_addr, waiting, pid, sess_id, state from pg_stat_activity  where state <> '\''idle'\''  and pid <> pg_backend_pid() order by 6, 2 desc;'"
else
	su - gpadmin -c "psql -c 'select now()-query_start, datname, usename, client_addr, waiting, procpid, sess_id from pg_stat_activity  where current_query not like '\''%IDLE%'\'' order by 5, 1 desc;'"
fi

echo ""
echo "8. lock table"
if [ ${GPDBVER} -eq 6 ]; then
	su - gpadmin -c "psql -c 'SELECT distinct w.locktype,w.relation::regclass AS relation, w.mode,w.pid AS waiting_pid,other.pid AS running_pid FROM pg_catalog.pg_locks AS w JOIN pg_catalog.pg_stat_activity AS w_stm ON (w_stm.pid = w.pid) JOIN pg_catalog.pg_locks AS other ON ((w.DATABASE = other.DATABASE AND w.relation  = other.relation) OR w.transactionid = other.transactionid) JOIN pg_catalog.pg_stat_activity AS other_stm ON (other_stm.pid = other.pid) WHERE NOT w.granted AND w.pid <> other.pid;'"
else
	su - gpadmin -c "psql -c 'SELECT distinct w.locktype,w.relation::regclass AS relation, w.mode,w.pid AS waiting_pid,other.pid AS running_pid FROM pg_catalog.pg_locks AS w JOIN pg_catalog.pg_stat_activity AS w_stm ON (w_stm.procpid = w.pid) JOIN pg_catalog.pg_locks AS other ON ((w.DATABASE = other.DATABASE AND w.relation  = other.relation) OR w.transactionid = other.transactionid) JOIN pg_catalog.pg_stat_activity AS other_stm ON (other_stm.procpid = other.pid) WHERE NOT w.granted AND w.pid <> other.pid ;'"
fi

echo ""
echo "9. data usage"
su - gpadmin -c "gpssh -f /home/gpadmin/gpconfigs/hostfile_gpdb df -h | grep data"

echo ""
echo "10. db size"
su - gpadmin -c "psql -c 'select coalesce(datname, '\''Total'\'') database_name, sum(round(pg_database_size(datname)/1024.0/1024/1024, 1)) db_size_gb from pg_database group by rollup(datname);'"

echo ""
echo "11. db age"
su - gpadmin -c "psql -c 'WITH cluster AS (
        SELECT gp_segment_id, datname, age(datfrozenxid) age FROM pg_database
        UNION ALL
        SELECT gp_segment_id, datname, age(datfrozenxid) age FROM gp_dist_random('\''pg_database'\'')
)
SELECT  gp_segment_id
      , datname
      , age
      , (2^31-1 - current_setting('\''xid_stop_limit'\'')::int - current_setting('\''xid_warn_limit'\'')::int) as current_warn_age
      , (2^31-1 - current_setting('\''xid_stop_limit'\'')::int) as current_stop_age
      , CASE
            WHEN age < (2^31-1 - current_setting('\''xid_stop_limit'\'')::int - current_setting('\''xid_warn_limit'\'')::int) * 0.7 THEN '\''BELOW WARN LIMIT'\''
            WHEN ((2^31-1 - current_setting('\''xid_stop_limit'\'')::int - current_setting('\''xid_warn_limit'\'')::int) * 0.7 < age) AND (age < (2^31-1 - current_setting('\''xid_stop_limit'\'')::int - current_setting('\''xid_warn_limit'\'')::int)) THEN '\''NEEDED VACUUM FREEZE and BELOW WARN LIMIT'\''
            WHEN  ((2^31-1 - current_setting('\''xid_stop_limit'\'')::int - current_setting('\''xid_warn_limit'\'')::int) < age) AND (age <  (2^31-1 - current_setting('\''xid_stop_limit'\'')::int)) THEN '\''OVER WARN LIMIT and UNDER STOP LIMIT'\''
            WHEN age > (2^31-1 - current_setting('\''xid_stop_limit'\'')::int ) THEN '\''OVER STOP LIMIT'\''
            WHEN age < 0 THEN '\''OVER WRAPAROUND'\''
        END
FROM cluster
ORDER BY age desc, datname, gp_segment_id
limit 10;'"
