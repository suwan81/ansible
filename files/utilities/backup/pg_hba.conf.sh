#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

######################################## SMDW ########################################################
#
scp /data/master/gpseg-1/pg_hba.conf smdw:/data/utilities/backup/pg_hba.conf.${DATE}
scp /data/master/gpseg-1/pg_hba.conf smdw:/data/master/gpseg-1/pg_hba.conf
#
######################################################################################################

######################################## SDW1 ########################################################
#
#scp /data/master/gpseg-1/pg_hba.conf sdw1:/data/utilities/backup/pg_hba.conf.${DATE}
#
######################################################################################################
