#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

psql -ec "show all" > /data/utilities/backup/backup_parameter.${DATE}

######################################## SMDW ###########################################################

scp /data/utilities/backup/backup_parameter.${DATE} smdw:/data/utilities/backup/

#########################################################################################################

######################################## SDW1 ###########################################################
#
# scp /data/utilities/backup/backup_parameter.${DATE} sdw1:/data/utilities/backup/
#
#########################################################################################################


rm /data/utilities/backup/backup_parameter.${DATE}
