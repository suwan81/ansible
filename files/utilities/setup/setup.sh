#!/bin/bash
## v1.0 20200904

## Env
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh
MDW_CNT=`cat ${HOSTFILE} | grep mdw | wc -l`
SDW_CNT=`cat ${HOSTFILE} | grep sdw | wc -l`

## remove dir
echo "- Remove /data/utilities to all segments"

ssh smdw rm -rf /data/utilities
ssh smdw rm -rf /home/gpadmin/utilities
ssh mdw rm -rf /home/gpadmin/utilities

for ((i=1;i<=$SDW_CNT;i++))

  do
    ssh sdw$i rm -rf /data/utilities
    ssh sdw$i rm -rf /home/gpadmin/utilities
  done

## remove current logs
echo "- Remove Current logs"
ssh mdw rm -rf /data/utilities/log/*
ssh mdw rm -rf /data/utilities/statlog/*

## make utilities dir
echo "- Make /data/utilities to all segments"

ssh smdw mkdir -p /data/utilities/backup
ssh mdw ln -s /data/utilities /home/gpadmin/utilities
ssh smdw ln -s /data/utilities /home/gpadmin/utilities
ssh smdw chown -R gpadmin:gpadmin /data/utilities
ssh smdw chown -R gpadmin:gpadmin /home/gpadmin/utilities

for ((i=1;i<=$SDW_CNT;i++))

  do 
    ssh sdw$i mkdir -p /data/utilities
    ssh sdw$i ln -s /data/utilities /home/gpadmin/utilities
    ssh sdw$i chown -R gpadmin:gpadmin /data/utilities
    ssh sdw$i chown -R gpadmin:gpadmin /home/gpadmin/utilities
  done

## scp meminfo.sh
echo "- Copy meminfo.sh to segments"

scp /data/utilities/mem_info.sh smdw:/data/utilities/
ssh smdw chown -R gpadmin:gpadmin /data/utilities/mem_info.sh

for ((i=1;i<=$SDW_CNT;i++))

  do
    scp /data/utilities/mem_info.sh sdw$i:/data/utilities/mem_info.sh
    ssh sdw$i chown -R gpadmin:gpadmin /data/utilities/mem_info.sh
  done

## Make dba schema for service monitor
echo "- Make dba schema"
psql -f /data/utilities/setup/add_dba_schema.sql

## Make crontab
echo "- Remove current crontab"
rm -rf /data/utilities/setup/crontab_bak_*
crontab -l > /data/utilities/setup/crontab_bak_${DATE}
crontab -r
echo "- Write New crontab"
crontab /data/utilities/setup/crontab.txt

echo "- SUCCESS"
