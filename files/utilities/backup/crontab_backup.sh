#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

crontab -l > /data/utilities/backup/crontab_backup.${DATE}

######################################## SMDW ########################################################
#
scp /data/utilities/backup/crontab_backup.${DATE} smdw:/data/utilities/backup/
#
######################################################################################################

######################################## SDW1 ########################################################
#
#scp /data/utilities/backup/crontab_backup.${current_date} smdw:/data/utilities/backup/
#
######################################################################################################

rm /data/utilities/backup/crontab_backup.${DATE}
