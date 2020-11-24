#!/bin/bash
export MON_HOME="/data/utilities"
source ${MON_HOME}/cluster_info.sh

######################## GPDB 4 ###########################################################################################
#
#pg_dumpall -s -r > /data/utilities/backup/backup_ddl.${DATE}.sql
#
############################################################################################################################

######################## GPDB 5 ###########################################################################################
#
pg_dumpall --schema-only > /data/utilities/backup/backup_ddl.${DATE}.sql
pg_dumpall --resource-queues --resource-groups --roles-only >> /data/utilities/backup/backup_ddl.${DATE}.sql
#
############################################################################################################################

######################################## SMDW ######################################################################################
#
scp /data/utilities/backup/backup_ddl.${DATE}.sql smdw:/data/utilities/backup/backup_ddl.${DATE}.sql
#
####################################################################################################################################

######################################## SDW1 ######################################################################################
#
#scp /data/utilities/backup/backup_ddl.${DATE}.sql sdw1:/data/utilities/backup/
#
####################################################################################################################################


rm /data/utilities/backup/backup_ddl.${DATE}.sql