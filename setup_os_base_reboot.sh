#!/bin/bash

### check current user
idck=$(id | awk '{print$1}')
if [ "$idck" != "uid=0(root)" ];then
 echo "Current user is not \"ROOT\". change user and Run again!"
 exit 0
fi

### date and path parameter
now=$(date +"%Y%m%d%H%M")
LOG_FILE="/var/log/ansible-gpdb.log"
LOG_TIME=$(date +%Y-%m-%d@%H:%M:%S)

### Convert inventory.lst from inventory.raw
function converter_inventory_raw2lst(){
 INPUT="inventory.raw"
 OUTPUT="inventory.lst"

 OUTPUT_GLOBAL="inventory.lst.global"
 OUTPUT_MDW="inventory.lst.mdw"
 OUTPUT_SMDW="inventory.lst.smdw"
 OUTPUT_SDW="inventory.lst.sdw"

 echo "[all:vars]" > $OUTPUT_GLOBAL
 echo "[gpdb-mdw]" > $OUTPUT_MDW
 echo "[gpdb-smdw]" > $OUTPUT_SMDW
 echo "[gpdb-sdw]" > $OUTPUT_SDW

 cat $INPUT | while read LINE
 do
  L2A=($(echo $LINE | tr ',' "\n"))
  role=$(echo ${L2A[0]} | awk -F'role=' '{print$2}')
  nodename=$(echo ${L2A[3]} | awk -F'bd_nodename=' '{print$2}')
  if [ "$role" == "global_vars" ];then
   for i in `seq 1 $((${#L2A[@]} -1))`
   do
    echo  "${L2A[$i]}" >> $OUTPUT_GLOBAL
   done
  elif [ "$role" == "mdw" ];then
   echo -n "$nodename " >> $OUTPUT_MDW
   for i in `seq 1 $((${#L2A[@]} -1))`
   do
    echo -n "${L2A[$i]} " >> $OUTPUT_MDW
   done
   echo "" >> $OUTPUT_MDW
  elif [ "$role" == "smdw" ];then
   echo -n "$nodename " >> $OUTPUT_SMDW
   for i in `seq 1 $((${#L2A[@]} -1))`
   do
    echo -n "${L2A[$i]} " >> $OUTPUT_SMDW
   done
   echo "" >> $OUTPUT_SMDW
  elif [ "$role" == "sdw" ];then
   echo -n "$nodename " >> $OUTPUT_SDW
   for i in `seq 1 $((${#L2A[@]} -1))`
   do
    echo -n "${L2A[$i]} " >> $OUTPUT_SDW
   done
   echo "" >> $OUTPUT_SDW
  fi
 done

 cat $OUTPUT_GLOBAL > $OUTPUT
 echo "" >> $OUTPUT
 cat $OUTPUT_MDW >> $OUTPUT
 echo "" >> $OUTPUT
 cat $OUTPUT_SMDW >> $OUTPUT
 echo "" >> $OUTPUT
 cat $OUTPUT_SDW >> $OUTPUT

 echo "========================= inventory.lst ======================="
 cat $OUTPUT
 echo "==============================================================="

 rm -f $OUTPUT_GLOBAL $OUTPUT_MDW $OUTPUT_SMDW $OUTPUT_SDW
}

echo -n "All servers will restart. Is it OK? (y/n) "
read qq

if [ "$qq" == "Y" ] || [ "$qq" == "y" ];then
 converter_inventory_raw2lst

 ### Insert Playbook Name to Log File.
 date >> ${LOG_FILE}.${LOG_TIME}
 echo "============== Playbook Name: init_os-base-setting.yml ==============" | tee -a ${LOG_FILE}.${LOG_TIME}
 ### Setting OS base on Cluster
 time ansible-playbook -i inventory.lst ./yml/init_os-base-setting.yml  --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
 date >> ${LOG_FILE}.${LOG_TIME}
fi
