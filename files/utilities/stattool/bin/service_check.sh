#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

DATE=`date '+%Y-%m-%d %H:%M:%S'`
LOG="/data/utilities/statlog/service_monitoring.`date '+%Y%m%d'`.txt"

psql -AXtc "select '${DATE}',count(*) from dba.service_monitoring;" >> ${LOG}
