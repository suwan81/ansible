#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

i=0
while [ $i -lt $2 ]
do
date '+%Y-%m-%d %H:%M:%S'
psql -c " select a.rsqname, a.rsqcountlimit as cntlimit, a.rsqcountvalue as cntvalue, a.rsqwaiters as wait, a.rsqholders as run, a.rsqcostlimit as costlimit, a.rsqcostvalue as costvalue, a.rsqmemorylimit as memlimit, a.rsqmemoryvalue as memvalue, b.rsqignorecostlimit as ignorecostlimit, b.rsqovercommit as overcommit, now() as ctime  from gp_toolkit.gp_resqueue_status a, pg_resqueue b where a.rsqname =b.rsqname order by 1;"
sleep $1
i=`expr $i + 1`
#echo $i
done
