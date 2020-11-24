#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

########################################## SMDW ####################################################
#
ssh smdw '. ~/.bash_profile; find /data/utilities/backup/* -mtime +90 -exec rm -rf '{}' \;'
#
####################################################################################################

########################################## SDW1 ####################################################
#
# ssh sdw1 '. ~/.bash_profile; find /data/utilities/backup/* -mtime +90 -exec rm -rf '{}' \;'
#
####################################################################################################
