#!/bin/sh
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

gpstate -i | awk '{print $3, $4}' | grep -i $HOST_NAME | grep -v $MASTER_NAME | sed "s/ /:/g" > /data/utilities/tmp_detele.txt

for host_dir in `cat /data/utilities/tmp_detele.txt`
   do
   hostname1=`echo $host_dir | awk -F ":" '{print $1}'`
   dir1=`echo $host_dir | awk -F ":" '{print $2}'`

   ssh ${hostname1} ". ~/.bash_profile;find ${dir1}/pg_log/*.csv -mtime +14 -exec rm -rf '{}' \;"
   #sleep 1
done

rm /data/utilities/tmp_detele.txt
