#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

######################################## SMDW ###############################################################
#
scp /data/master/gpseg-1/postgresql.conf smdw:/data/utilities/backup/postgresql.conf.${DATE}
scp /data/master/gpseg-1/postgresql.conf smdw:/data/master/gpseg-1/postgresql.conf
#
#############################################################################################################

######################################## SDW1 ###############################################################
#
#scp /data/master/gpseg-1/postgresql.conf sdw1:/data/utilities/backup/postgresql.conf.${DATE}
#
#############################################################################################################
