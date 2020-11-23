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

version_files_yml=./yml/version_files.yml
vars_common_path=./yml/vars-common.yml
upgrade_files_yml=./yml/upgrade_files.yml
uninstall_st=./yml/uninstall_st.yml
temp_val=./yml/temp_val.yml
sou_path=/root/gpdb-src
src_path=/data/staging

cp ./version_check/* /root/gpdb-src

## /root/gpdb-src binary file check and copy to /data/staging
if [ ! -d "$src_path" ];then
 mkdir $src_path
 cp -f $sou_path/* $src_path
else
 rm -rf $src_path/*
 cp -f $sou_path/* $src_path
fi

if [ $(cat /etc/passwd | grep gpadmin | cut -f1 -d: | wc -l) -eq 1 ];then
 chown -R gpadmin:gpadmin $src_path
fi

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
  role=($(echo ${L2A[0]} | awk -F'role=' '{print$2}'))
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

### Parameter for setup gpdb
function check_file(){
if [ "$1" == "" ];then
 def_ver=/data/staging/6-11-1
else
 def_ver=/data/staging/$1
fi
gpdb_count=$(ls -l $src_path | grep -P "greenplum-db-[0-9]+" | grep "rpm" | awk '{print$9}' | wc -l)
gpdb_file_name=$(ls -l $src_path | grep -P "greenplum-db-[0-9]+" | grep "rpm" | awk '{print$9}')
gpdb_default_file=$(cat $def_ver | grep -P "greenplum-db-[0-9]+" | grep "rpm")
gpdb_default_version=$(cat $def_ver | grep -P "greenplum-db-[0-9]+" | grep "rpm" | awk -F'-' '{print$3}')

gpcc_count=$(ls -l $src_path | grep -P "greenplum-cc-web-[0-9]+" | grep -i "zip" | awk '{print$9}' | wc -l)
gpcc_file_name=$(ls -l $src_path | grep -P "greenplum-cc-web-[0-9]+" | grep -i "zip" | awk '{print$9}')
gpcc_default_file=$(cat $def_ver | grep -P "greenplum-cc-web-[0-9]+" | grep -i "zip")
gpcc_default_version=$(cat $def_ver | grep -P "greenplum-cc-web-[0-9]+" | grep -i "zip" | awk -F'-' '{print$4}')

#gpdb_client_count=$(ls -l $src_path | grep -P "greenplum-db-client-[0-9]+" | grep "rpm" | awk '{print$9}' | wc -l)
#gpdb_client_file_name=$(ls -l $src_path | grep -P "greenplum-db-client-[0-9]+" | grep "rpm" | awk '{print$9}')
#gpdb_client_default_file=$(cat $def_ver | grep -P "greenplum-db-client-[0-9]+" | grep "rpm")
#gpdb_client_default_version=$(cat $def_ver | grep -P "greenplum-db-client-[0-9]+" | grep "rpm" | awk -F'-' '{print$4}')

#java_count=$(ls -l $src_path | grep -P "java-[0-9]{1}\. [0-9]{1}\. [0-9]{1}-openjdk" | grep "rpm" | awk '{print$9}' | wc -l)
#java_file_name=$(ls -l $src_path | grep -P "java-[0-9]{1}\. [0-9]{1}\. [0-9]{1}-openjdk" | grep "rpm" | awek '{print$9}')
#java_default_file=$(cat $def_ver | grep -P "java-[0-9]{1}\. [0-9]{1}\. [0-9]{1}-openjdk" | grep "rpm")
#java_default_version=$(cat $def_ver | grep -P "java-[0-9]{1}\. [0-9]{1}\. [0-9]{1}-openjdk" | grep "rpm" | awk -F'-' '{print$4}')

#hadoop_client_count=$(ls -l $src_path | grep -P "hadoop-client-[0-9]+" | grep "rpm" | awk '{print$9}' | wc -l)
#hadoop_client_name=$(ls -l $src_path | grep -P "hadoop-client-[0-9]+" | grep "rpm" | awk '{print$9}')
#hadoop_client_default_file=$(cat $def_ver | grep -P "hadoop-client-[0-9]+" | grep "rpm")
#hadoop_client_default_version=$(cat $def_ver | grep -P "hadoop-client-[0-9]+" | grep "rpm" | awk -F'-' '{print$3}')

pljava_count=$(ls -l $src_path | grep -P "pljava-[0-9]+" | grep "gppkg" | awk '{print$9}' | wc -l)
pljava_file_name=$(ls -l $src_path | grep -P "pljava-[0-9]+" | grep "gppkg" | awk '{print$9}')
pljava_default_file=$(cat $def_ver | grep -P "pljava-[0-9]+" | grep "gppkg" )
pljava_default_version=$(cat $def_ver | grep -P "pljava-[0-9]+" | grep "gppkg" | awk -F'-' '{print$2}')

plr_count=$(ls -l $src_path | grep -P "plr-[0-9]+" | grep "gppkg" | awk '{print$9}' | wc -l)
plr_file_name=$(ls -l $src_path | grep -P "plr-[0-9]+" | grep "gppkg" | awk '{print$9}')
plr_default_file=$(cat $def_ver | grep -P "plr-[0-9]+" | grep "gppkg")
plr_default_version=$(cat $def_ver | grep -P "plr-[0-9]+" | grep "gppkg" | awk -F'-' '{print$2}')

DataSciencePython_count=$(ls -l $src_path | grep -P "DataSciencePython-[0-9]+" | grep "gppkg" | awk '{print$9}' | wc -l)
DataSciencePython_file_name=$(ls -l $src_path | grep -P "DataSciencePython-[0-9]+" | grep "gppkg" | awk '{print$9}')
DataSciencePython_default_file=$(cat $def_ver | grep -P "DataSciencePython-[0-9]+" | grep "gppkg")
DataSciencePython_default_version=$(cat $def_ver | grep -P "DataSciencePython-[0-9]+" | grep "gppkg" | awk -F'-' '{print$2}')

DataScienceR_count=$(ls -l $src_path | grep -P "DataScienceR-[0-9]+" | grep "gppkg" | awk '{print$9}' | wc -l)
DataScienceR_file_name=$(ls -l $src_path | grep -P "DataScienceR-[0-9]+" | grep "gppkg" | awk '{print$9}')
DataScienceR_default_file=$(cat $def_ver | grep -P "DataScienceR-[0-9]+" | grep "gppkg")
DataScienceR_default_version=$(cat $def_ver | grep -P "DataScienceR-[0-9]+" | grep "gppkg" | awk -F'-' '{print$2}')

madlib_count=$(ls -l $src_path | grep -P "madlib-[0-9]+" | grep "tar.gz" | awk '{print$9}' | wc -l)
madlib_file_name=$(ls -l $src_path | grep -P "madlib-[0-9]+" | grep "tar.gz" | awk '{print$9}')
madlib_default_file=$(cat $def_ver | grep -P "madlib-[0-9]+" | grep "tar.gz")
madlib_default_version=$(cat $def_ver | grep -P "madlib-[0-9]+" | grep "tar.gz" | awk -F'-' '{print$2}')

gpcopy_count=$(ls -l $src_path | grep -P "gpcopy-[0-9]+" | grep "gppkg" | awk '{print$9}' | wc -l)
gpcopy_file_name=$(ls -l $src_path | grep -P "gpcopy-[0-9]+" | grep "gppkg" | awk '{print$9}')
gpcopy_default_file=$(cat $def_ver | grep -P "gpcopy-[0-9]+" | grep "gppkg")
gpcopy_default_version=$(cat $def_ver | grep -P "gpcopy-[0-9]+" | grep "gppkg" | awk -F'-' '{print$2}' | awk -F'.tar' '{print$1}')
}

function check_exist(){
if [ -f $src_path/$1 ];then
 ver_ct=$(cat $src_path/$1 | wc -l)
 ver_no=0
 for i in $(cat $src_path/$1)
 do
  if [ -f $src_path/$i ];then
   let ver_no=$((ver_no+1))
  else
   let ver_no=$((ver_no-1))
  fi
 done
 if [ $ver_ct -eq $ver_no ];then
  echo "true"
 else
  echo "false"
 fi
else
 echo "false"
fi
}

function default_to_sel(){
sel_gpdb_file=$gpdb_default_file
sel_gpcc_file=$gpcc_default_file
sel_pljava_file=$pljava_default_file
sel_plr_file=$plr_default_file
sel_DataSciencePython_file=$DataSciencePython_default_file
sel_DataScienceR_file=$DataScienceR_default_file
sel_madlib_file=$madlib_default_file
sel_gpcopy_file=$gpcopy_default_file
}

### create version_files.yml
function create_version(){
echo "---"
echo "gpdb_file_name: \"$(ls -l $src_path | grep "$sel_gpdb_file" | awk'{print$9}')\""
echo "gpdb_file_version: \"$(ls -l $src_path | grep "$sel_gpdb_file" | awk '{print9}' | awk -F'-' '{print$3}')\""
echo ""

echo "gpcc_file_name: \"$(ls -l $src_path | grep "$sel_gpcc_file" | awk '{print$9}')\""
echo "gpcc_file_archive_name: \"$(ls -l $src_path | grep "$sel_gpcc_file" | awk '{print$9}' | awk -F'.zip' '{print$1}')\""
echo "gpcc_file_version: \"$(ls -l $src_path | grep "$sel_gpcc_file" | awk '{print$9}' | awk -F'-' '{print$4}')\""
gpcc_ver_ch=$(ls -l $src_path | grep "$sel_gpcc_file" | awk '{print$9}' | awk -F'-' '{print$4}' | awk -F'.' '{print$2}')
if [ $gpcc_ver_ch -ge 2 ];then
 echo "gpcc_prefix_name: \"greenplum-cc\""
 echo "gpcc_home: \"/usr/local/greenplum-cc\""
else
 echo "gpcc_prefix_name: \"greenplum-cc-web\""
 echo "gpcc_home: \"/usr/local/greenplum-cc-web\""
fi
echo "gpcc_MetricsCollector_file_name: \"MetricsCollector-$(ls -l $src_path | grep "sel_gpcc_file" | awk '{print$9}' | awk -F'-' '{print$4}')_gp_$(ls -l $src_path | grep "$sel_gpdb_file" | awk '{print$9}' | awk -F'-' '{print$3}')-rhel7-x86_64.gppkg\""
echo ""

#echo "gpdb_client_file_name: \"$(ls -l $src_path | grep -P "greenplum-db-client-[0-9]+" | grep "$gpdb_client_default_file" | awk '{print$9}')\""
#echo "gpdb_client_file_version: \"$(ls -l $src_path | grep -P "greenplum-db-client-[0-9]+" | grep "$gpdb_client_default_file" | awk '{print$9}' | awk -F'-' '{print$4}')\""
#echo ""

#echo "java_file_name: \"$(ls -l $src_path | grep -P "java-[0-9]{1}\.[0-9]{1}\.[0-9]{1}-openjdk" | grep "$java_default_file" | awk '{print$9}')\""
#echo "java_file_version: \"$(ls -l $src_path | grep -P "java-[0-9]{1}\.[0-9]{1}\.[0-9]{1}-openjdk" | grep "$java_default_file" | awk '{print$9}' | awk -F'-' '{print$4}')\""
#echo ""

#echo "hadoop_client_file_name: \"$(ls -l $src_path | grep -P "hadoop-client-[0-9]+" | grep "$hadoop_client_default_file" | awk '{print$9}')\""
#echo "hadoop_client_file_version: \"$(ls -l #src_path | grep -P "hadoop-client-[0-9]+" | grep "$hadoop_client_default_file" | awk '{print$9}' | awk -F'-' '{print$3}')\""
#echo ""

echo "pljava_file_name: \"$(ls -l $src_path | grep "$sel_pljava_file" | awk '{print$9}')\""
echo "pljava_file_version: \"$(ls -l $src_path | grep "$sel_pljava_file" | awk '{print$9}' | awk -F'-' '{print$2}')\""

echo "plr_file_name: \"$(ls -l $src_path | grep "$sel_plr_file" | awk '{print$9}')\""
echo "plr_file_version: \"$(ls -l $src_path | grep "$sel_pjr_file" | awk '{print$9}' | awk -F'-' '{print$2}')\""

echo "DataSciencePython_file_name: \"$(ls -l $src_path | grep "$sel_DataSciencePython_file" | awk '{print$9}')\""
echo "DataSciencePython_file_version: \"$(ls -l $src_path | grep "$sel_DataSciencePython_file" | awk '{print$9}' | awk -F'-' '{print$2}')\""

echo "DataScienceR_file_name: \"$(ls -l $src_path | grep "$sel_DataScienceR_file" | awk '{print$9}')\""
echo "DataScienceR_file_version: \"$(ls -l $src_path | grep "$sel_DataScienceR_file" | awk '{print$9}' | awk -F'-' '{print$2}')\""

echo "madlib_file_name: \"$(ls -l $src_path | grep "$sel_madlib_file" | awk '{print$9}')\""
echo "madlib_file_archive_name: \"$(ls -l $src_path | grep "$sel_madlib_file" | awk '{print$9}' | awk -F'.tar.gz' '{print$1}')\""
echo "madlib_file_version: \"$(ls -l $src_path | grep "$sel_madlib_file" | awk '{print$9}' | awk -F'-' '{print$2}')\""

echo "gpcopy_file_name: \"$(ls -l $src_path | grep "$sel_gpcopy_file" | awk '{print$9}')\""
echo "gpcopy_file_version: \"$(ls -l $src_path | grep "$sel_gpcopy_file" | awk '{print$9}' | awk -F'-' '{print$2}' | awk -F'.tar' '{print$1}')\""
} > $version_files_yml

### START Initialize main menu variable
function init_sel(){
b0=" "
b1=" "
b2=" "
b3=" "
b4=" "
b5=" "
b6=" "
b7=" "
b8=" "
b9=" "
sel_gpdb_file=$gpdb_default_file
sel_gpcc_file=$gpcc_default_file
#sel_hadoop_file=$hadoop_client_default_file
sel_pljava_file=$pljava_default_file
sel_plr_file=$plr_default_file
sel_DataSciencePython_file=$DataSciencePython_default_file
sel_DataScienceR_file=$DataScienceR_default_file
sel_madlib_file=$madlib_default_file
sel_gpcopy_file=$gpcopy_default_file
cat /dev/null > ./select_items
cat /dev/null > ./default_items
sel_seg_instance=4
sed -i "/^number_of_seg_instances_per_node:/ c\number_of_seg_instances_per_node: $sel_seg_instance" $vars_common_path
sel_gpcc_display_name="gpcc"
sed -i "/^  display_name:/ c\  display_name: \"$sel_gpcc_display_name\"" $vars_common_path
sed -i "/^enable_standby_master:/ c\enable_standby_master: 0" $vars_common_path
sed -i "/^enable_mirror:/ c\enable_mirror: 1" $vars_common_path
sel_seg_group=4
let segment_group=($seg_count-$sel_seg_group)/$sel_seg_group
sed -i "/^segment_group:/ c\segment_group: $segment_group" $vars_common_path
sed -i "/^segment_group_count:/ c\segment_group_count: $sel_seg_group" $vars_common_path
sed -i "/^sel_data_path:/ c\sel_data_path: 1" $vars_common_path
}

function check_vip(){
vip_e=tmp_vip_env
cat inventory.raw | while read LINE
do
 L2A=($(echo $LINE | tr ',' "\n"))
 role=($(echo ${L2A[0]} | awk -F'role=' '{print $2}'))
 if [ "$role" == "global_vars" ];then
  for i in `seq 1 $((${#L2A[@]} -1))`
  do
   echo "${L2A[$i]}" >> $vip_e
  done
 fi
done
vip_ip=$(cat $vip_e | grep -w "bd_vip" | awk -F'=' '{print$2}')
vip_net=$(cat $vip_e | grep -w "bd_vip_netmask" | awk -F'=' '{print$2}')
vip_gate=$(cat $vip_e | grep -w "bd_vip_gateway" | awk -F'=' '{print$2}')
vip_ori=$(cat $vip_e | grep -w "bd_vip_arping_interface" | awk -F'=' '{print$2}')
vip_int=$(cat $vip_e | grep -w "bd_vip_interface" | awk -F'=' '{print$2}')
rm -f $vip_e
}
### END Initialize main menu variable

### Precalculation /etc/sysctl.conf file parameter
function check_sysctl(){
k_shmall=$(echo $(expr $(getconf _PHYS_PAGES) / 2))
k_shmmax=$(echo $(expr $(getconf _PHYS_PAGES) / 2 \* $(getconf PAGE_SIZE)))
f_kbytes=$(awk 'BEGIN {OFMT = "%.0f";} /MemTotal/ {print $2 * .03;}' /proc/meminfo)
sed -i "/^kernel.shmall/ c\kernel.shmall = $k_shmall" templates/etc_sysctl.conf.j2
sed -i "/^kernel.shmmax/ c\kernel.shmmax = $k_shmmax" templates/etc_sysctl.conf.j2
sed -i "/^vm.min_free_kbytes/ c\vm.min_free_kbytes = $f_kbytes" templates/etc_sysctl.conf.j2

c_mem=$(free -h | grep Mem | awk '{print$2}' | sed 's/.$//')
if [ $c_mem -gt 64 ];then
 sed -i "/vm.dirty_background_ratio = 0/ c\vm.dirty_background_ratio = 0" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_ratio = 0/ c\vm.dirty_ratio = 0" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_background_bytes = 1610612736/ c\vm.dirty_background_bytes = 1610612736" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_bytes = 4294967296/ c\vm.dirty_bytes = 4294967296" templates/etc_sysctl.conf.j2

 sed -i "/vm.dirty_background_ratio = 3/ c\#vm.dirty_background_ratio = 3" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_ratio = 10/ c\#vm.dirty_ratio = 10" templates/etc_sysctl.conf.j2
else
 sed -i "/vm.dirty_background_ratio = 0/ c\#vm.dirty_background_ratio = 0" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_ratio = 0/ c\#vm.dirty_ratio = 0" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_background_bytes = 1610612736/ c\#vm.dirty_background_bytes = 1610612736" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_bytes = 4294967296/ c\#vm.dirty_bytes = 4294967296" templates/etc_sysctl.conf.j2

 sed -i "/vm.dirty_background_ratio = 3/ c\vm.dirty_background_ratio = 3" templates/etc_sysctl.conf.j2
 sed -i "/vm.dirty_ratio = 10/ c\vm.dirty_ratio = 10" templates/etc_sysctl.conf.j2
fi
}

### Status for GPDB/GPCC Patch
function get_gpdb_patch_status(){
c_gpdb_ct=$(ps -ef | grep -v grep | grep postgres | wc -l)
if [ $c_gpdb_ct -ne 0 ];then
 c_gpdb_st=$(echo "$(su -l gpadmin -c 'gpstate')")
 c_gpdb_ver=$(echo "$c_gpdb_st" | grep "(Greeplum Database)" | awk '{print$8}')
 c_gppkg_st=$(echo "$(su -l gpadmin -c 'gppkg -q --all | awk 'NR!=1'')")
else
 c_gpdb_ver="Not Started GPDB!"
fi
c_gpcc_ct=$(ps -ef | grep -v grep | grep ccagent | wc -l)
if [ $c_gpcc_ct -ne 0 ];then
 c_gpcc_ver=$(echo "$(su -l gpadmin -c 'gpcc -v')" | awk '{print$NF}')
 c_gpcc_st=$(echo "$(su -l gpadmin -c 'gpcc status')")
else
 c_gpcc_ver="Not Started GPCC!"
fi
c_gpcopy_ct=$(ls -l /usr/local/greenplum-db/bin | grep gpcopy | wc -l)
if [ $c_gpcopy_ct -eq 1 ];then
 c_gpcopy_st=$(/usr/local/greenplum-db/bin/gpcopy ?version | awk '{print$nf}')
else
 c_gpcopy_st="Not installed!"
fi
c_pxf_ct=0
c_pxf_seg_c=0
for i in $(cat /home/gpadmin/gpconfigs/host_seg)
do
 let c_pxf_ct=$c_pxf_ct+$(ssh $i 'ps -ef | grep -v grep | grep pxf | wc -l')
 c_pxf_seg_c=$((c_pxf_seg_c+1))
done
if [ $c_pxf_ct -eq $c_pxf_seg_c ];then
 c_pxf_st=$(echo "$(su -l gpadmin -c '/usr/local/greenplum-db/pxf/bin/pxf cluster status | tail -1')")
else
 c_pxf_st="Not installed PXF!"
fi
}

### Check status functions
cs_host_path="/home/gpadmin/gpconfigs/host_all"

function get_gpdb_conf(){
gpdb_ct=$(ps -ef | grep -v grep | grep postgres | wc -l)
if [ $gpdb_ct -ne 0 ];then
 gpdb_err="-1"
 gpdb_st=$(echo "$(su - l gpadmin -c 'gpstate')")
 gpconf_st1=$(echo "$(su - l gpadmin -c 'gpconfig -s max_connections')")
 gpconf_st2=$(echo "$(su - l gpadmin -c 'gpconfig -s max_prepared_transactions')")
 gpconf_st3=$(echo "$(su - l gpadmin -c 'gpconfig -s gp_vmem_protect_limit')")
 gpconf_st4=$(echo "$(su - l gpadmin -c 'gpconfig -s gp_resqueue_priority_cpucores_per_segment')")
 gpconf_st5=$(echo "$(su - l gpadmin -c 'gpconfig -s gp_resqueue_priority_inactivity_timeout')")
 gppkg_st=$(echo "$(su - l gpadmin -c 'gppkg -q --all')")
 gpconf_st6=$(echo "$(su - l gpadmin -c 'gpconfig -s xid_stop_limit')")
 gpconf_st7=$(echo "$(su - l gpadmin -c 'gpconfig -s xid_warn_limit')")
 gppkg_st=$(echo "$(su - l gpadmin -c 'gppkg -q --all')")
else
 gpdb_err="Not started GPDB!"
fi
gpfo_ct1=$(ssh smdw 'ps -ef | grep -v grep | grep gpfailover | wc -l')
gpfo_ct2=$(ssh smdw 'systemctl status gpfailover | grep "active (running)" | wc -l')
if [ $gpfo_ct1 -ge 1 ] && [ $gpfo_ct2 -eq 1 ];then
 gpfo_st="Active"
else
 gpfo_st="Stopped"
fi
gpcc_ct=$(ps -ef | grep -v grep | grep ccagent | wc -l)
if [ $gpcc_ct -ne 0 ];then
 gpcc_err="1"
 gpcc_ver=$(echo "$(su -l gpadmin -c 'gpcc-v')")
 gpcc_st=$(echo "$(su -l gpadmin -c 'gpcc status')")
else
 gpcc_err="Not started GPCC!"
fi
pxf_ct=0
pxf_seg_c=0
for i in $(cat /home/gpadmin/gpconfigs/host_seg)
do
 let pxf_ct=$pxf_ct+$(ssh $i 'ps -ef | grep -v grep | grep pxf | wc -l')
 pxf_seg_c=$((pxf_seg_c+1))
done
if [ $pxf_ct -eq $pxf_seg_c ];then
 pxf_err="-1"
 pxf_st=$(echo "$(su -l gpadmin -c '/usr/local/greenplum-db/pxf/bin/pxf cluster status')")
else
 c_pxf_st="Not installed PXF!"
fi
}

function page1(){
msg_show " === OS Configuration === "
echo ""
echo "[Current<mdw> Configuration]"
os_ver=$(cat /tmp/check_status_$(hostname) | grep "os_ver:" | awk -F':' '{print$2}')
ker_ver=$(cat /tmp/check_status_$(hostname) | grep "kernel_ver:" | awk -F':' '{print$2}')
mtu=$(cat /tmp/check_status_$(hostname) | grep "mtu:" | awk -F':' '{print$2}')
echo " OS Version.       : $os_ver"
echo " Kernel Version   : $ker_ver"
echo " MTU.                  : $mtu"
echo ""
mlist=(OS_ver Kernel_Ver MTU)
printf "%-15s" ""
printf "%-20s" "Hostname"
for menu in "${mlist[@]}"
do
 printf "%-12s" "$menu"
done
printf "\n"
for var in $(cat $cs_host_path)
do
 sfile=""
 sfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "$var" | awk '{print$2}')")
 st_host=""
 st_host=$(cat $sfile | grep "hostname:" | awk -F':' '{print$2}')
 if [ "$os_ver" == "$(cat $sfile | grep "os_ver:" |. awk -F':' '{print$2}')" ];then
  st_os="O"
 else
  st_os="-"
 fi
 if [ "$ker_ver" == "$(cat $sfile | grep "kernel_ver:" | awk -F':' '{print$2}')" ];then
  st_ker="O"
 else
  st_ker="-"
 fi
 if [ "$mtu" == "$(cat $sfile | grep "mtu:" | awk -F':' '{print$2}')" ];then
  st_mtu="O"
 else
  st_mtu="-"
 fi
 hn=$(printf '%-15s' "$var")
 printf "%s%-20s%-12s%-12s%-12s\n" "$hn" "$st_host" "$st_os" "$st_ker" "$st_mtu"
done
}

function page2(){
msg_show " === Service & Deamon === "
msg_show " (1st: Service, 2nd: Daemon) "
echo ""
mlist=(SELinux Firewall NTP RC-LOCAL KDUMP)
printf "%-15s" ""
for menu in "${mlist[@]}"
do
 printf "%-12s" "$menu"
done
printf "\n"
for var in $(cat $cs_host_path)
do
 sfile =""
 sfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "$var" | awk '{print$2}')")
 if [ "$(cat $sfile | grep "selinux" | awk -F':' '{print2}')" == "disabled" ];then
  st_selinux="O"
 else
  st_selinux="-"
 fi
 if [ "$(cat $sfile | grep "firewall_st1" | awk -F':' '{print2}')" == "inactive" ];then
  st_firewall1="O"
 else
  st_firewall1="-"
 fi
 if [ "$(cat $sfile | grep "firewall_st2" | awk -F':' '{print2}')" == "disabled" ];then
  st_firewall2="O"
 else
  st_firewall2="-"
 fi
 if [ "$(cat $sfile | grep "ntp_st1" | awk -F':' '{print2}')" == "active" ];then
  st_ntp1="O"
 else
  st_ntp1="-"
 fi
 if [ "$(cat $sfile | grep "ntp_st2" | awk -F':' '{print2}')" == "enabled" ];then
  st_ntp2="O"
 else
  st_ntp2="-"
 fi
 if [ "$(cat $sfile | grep "rclocal_st1" | awk -F':' '{print2}')" == "active" ];then
  st_rclocal1="O"
 else
  st_rclocal1="-"
 fi
 if [ "$(cat $sfile | grep "rclocal_st2" | awk -F':' '{print2}')" == "static" ];then
  st_rclocal2="O"
 else
  st_frclocal2="-"
 fi
 if [ "$(cat $sfile | grep "kdump_st1" | awk -F':' '{print2}')" == "active" ];then
  st_kdump1="O"
 else
  st_kdump1="-"
 fi
 if [ "$(cat $sfile | grep "kdump_st2" | awk -F':' '{print2}')" == "enabled" ];then
  st_kdump2="O"
 else
  st_kdump2="-"
 fi
 hn=$(printf '%-15s' "$var")
 printf "%s%-12s%-12s%-12s%-12s%-12s\n" "$hn" "$st_selinux" "$st_firewall1$st_firewall2" "$st_ntp1$st_ntp2" "$st_rclocal1$st_rclocal2" "$st_kdump1$st_kdump2"
done
}

function page3(){
msg_show " === OS Configuration === "
msg_show " (Base on mdw parameter) "
echo ""
mlist=(Grubby Resolve Sysctl Ulimit)
printf "%-15s" ""
for menu in "${mlist[@]}"
do
 printf "%-12s" "$menu"
done
printf "\n"
mfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "mdw" | awk '{print$2}')")
grubby_st=$(sed -n "$(($(grep -n "grubby:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":grubby" $mfile | cut -d':' -f1)-1))p" $mfile)
resolve_st=$(sed -n "$(($(grep -n "resolve:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":resolve" $mfile | cut -d':' -f1)-1))p" $mfile)
sysctl_st=$(sed -n "$(($(grep -n "sysctl:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":sysctl" $mfile | cut -d':' -f1)-1))p" $mfile)
ulimit_st=$(sed -n "$(($(grep -n "ulimit:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":ulimit" $mfile | cut -d':' -f1)-1))p" $mfile)
for var in $(cat $cs_host_path)
do
 sfile=""
 sfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "$var" | awk '{print$2}')")
 if [ "$grubby_st" == "$(sed -n "$(($(grep -n "grubby:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":grubby" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re1="O"
 else
  re1="-"
 fi
 if [ "$resolve_st" == "$(sed -n "$(($(grep -n "resolve:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":resolve" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re2="O"
 else
  re2="-"
 fi
 if [ "$sysctl_st" == "$(sed -n "$(($(grep -n "sysctl:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":sysctl" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re3="O"
 else
  re3="-"
 fi
 if [ "$ulimit_st" == "$(sed -n "$(($(grep -n "ulimit:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":ulimit" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re4="O"
 else
  re4="-"
 fi
 hn=$(printf '%-15s' "$var")
 printf "%s%-12s%-12s%-12s%-12s\n" "$hn" "$re1" "$re2" "$re3" "$re4"
done
}

function page4(){
msg_show " === OS Configuration === "
msg_show " (Base on mdw parameter) "
echo ""
mlist=(Logind SSHD YUM Blockdev)
printf "%-15s" ""
for menu in "${mlist[@]}"
do
 printf "%-12s" "$menu"
done
printf "\n"
mfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "mdw" | awk '{print$2}')")
logind_st=$(sed -n "$(($(grep -n "logind:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":logind" $mfile | cut -d':' -f1)-1))p" $mfile)
sshd_st=$(sed -n "$(($(grep -n "sshd:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":sshd" $mfile | cut -d':' -f1)-1))p" $mfile)
yum_st=$(sed -n "$(($(grep -n "yum:" $mfile | cut -d':' -f1)+1)),$(($(grep -n ":yum" $mfile | cut -d':' -f1)-1))p" $mfile)
for var in $(cat $cs_host_path)
do
 sfile=""
 sfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "$var" | awk '{print$2}')")
 if [ "$logind_st" == "$(sed -n "$(($(grep -n "logind:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":logind" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re1="O"
 else
  re1="-"
 fi
 if [ "$sshd_st" == "$(sed -n "$(($(grep -n "sshd:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":sshd" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re2="O"
 else
  re2="-"
 fi
 if [ "$yum_st" == "$(sed -n "$(($(grep -n "yum:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":yum" $sfile | cut -d':' -f1)-1))p" $sfile)" ];then
  re3="O"
 else
  re3="-"
 fi
 blockdev_st=$(sed -n "$(($(grep -n "blockdev:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":blockdev" $sfile | cut -d':' -f1)-1))p" $sfile)
 blockdev_c=$(echo "$blockdev_st" | wc -l)
 blockdev_re=1
 for (( c=1;c<=$blockdev_c;c++ ))
 do
  if [ $(echo "$blockdev_st" | awk "NR==$c") -ne 16384 ];then
   blockdev_re=$((blockdev_re*2))
  fi
 done
 if [ $blockdev_re -eq 1 ];then
  re4="O"
 else
  re4="-"
 fi
 hn=$(printf '%-15s' "$var")
 printf "%s%-12s%-12s%-12s%-12s\n" "$hn" "$re1" "$re2" "$re3" "$re4"
done
}

function page5(){
msg_show " === OS Configuration === "
echo ""
mlist=(fstab df)
for menu in "${mlist[@]}"
do
 printf "%-15s" ""
 printf "%-12s" "--- $menu ---"
 printf "\n"
 for var in $(cat $cs_host_path)
 do
  sfile=""
  sfile=$(ls /tmp/check_status_* | grep -w "/tmp/check_status_$(cat /etc/hosts | grep -v "###" | grep -w "$var" | awk '{print$2}')")
  if [ "$menu" == "df" ];then
   result=$(sed -n "$(($(grep -n "df:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":df" $sfile | cut -d':' -f1)-1))p" $sfile | grep "/data")
  fi
  if [ "$menu" == "fstab" ];then
   result=$(sed -n "$(($(grep -n "fstab:" $sfile | cut -d':' -f1)+1)),$(($(grep -n ":fstab" $sfile | cut -d':' -f1)-1))p" $sfile | grep -v "#")
  fi
  result_c=$(echo "$result" | wc -l)
  if [ $result_c -gt 1 ];then
   for (( c=1;c<=$result_c;c++ ))
   do
    result_tt=$(echo "$result" | awk "NR==$c")
    hn=$(printf '%-15s' "$var")
    printf "%s%s\n" "$hn" "$result_tt"
   done
  else
   hn=$(printf '%-15s' "$var")
   printf "%s%s\n" "$hn" "$result"
  fi
 done
done
}

function page6(){
msg_show " === GPDB Configuration === "
echo ""
if [ "$gpdb_err" == "-1" ];then
 echo "- GPDB Base Info -"
 echo -n "GPDB Version                    : "
 echo "$gpdb_st" | grep "(Greenplum Database)" | awk '{print$8}'
 echo -n "GPDB Master Status        : "
 echo  "$gpdb_st" | grep "Master instance" | awk '{print$6}'
 echo -n "GPDB Master standby      : "
 echo  "$gpdb_st" | grep "Master standby" | awk '{print$6}'
 echo -n "GPDB Total instance         : "
 echo -n "$(echo -n "$gpdb_st" | grep "Total segment instance count from metadata" | awk -F'=' '{print$2}' | awk '{print$1}') "
 echo -n "(Primary: $(echo -n "$gpdb_st" | grep "Total primary segment valid" | awk -F'=' '{print$2}' | awk '{print$1}')/"
 echo -n "$(echo -n "$gpdb_st" | grep "Total primary segment failures" | awk -F'=' '{print$2}' | awk '{print$1}') , "
 echo -n "Mirror: $(echo  "$gpdb_st" | grep "Total mirror segment valid" | awk -F'=' '{print$2}' | awk '{print$1}')/"
 echo "$(echo "$gpdb_st" | grep "Total mirror segment failures" | awk -F'=' '{print$2}' | awk '{print$1}'))"
 echo ""
 echo "- GPDB failover config -"
 echo "Master Standby Service : $gpfo_st"
 if [ $(echo "$gpdb_st" | grep -i active | wc -l) -eq 1 ];then
  check_vip
  echo " > VIP-IP                  : $vip_ip"
  echo " > VIP-NETMASK   : $vip_net"
  echo " > VIP-GATEWAY   : $vip_gate"
  echo " > VIP-SOURCE     : $vip_ori"
  echo " > VIP-TARGET      : $vip_int"
 fi
 echo ""
 echo "- GPDB gpconfig parameter -"
 echo "$gpconf_st1" | awk 'NR!=1'
 echo "$gpconf_st2" | awk 'NR!=1'
 echo "$gpconf_st3" | awk 'NR!=1'
 echo "$gpconf_st4" | awk 'NR!=1'
 echo "$gpconf_st5" | awk 'NR!=1'
 echo "$gpconf_st6" | awk 'NR!=1'
 echo "$gpconf_st7" | awk 'NR!=1'
 echo ""
 echo "- GPDB Package -"
 echo "$gppkg_st" | awk 'NR!=1'
 echo ""
else
 echo "$gpdb_err"
fi
if [ "$gpcc_err" == "-1" ];then
 echo "- GPCC Version -"
 echo "$gpcc_ver"
 echo ""
 echo "- GPCC Status - "
 echo "$gpcc _st"
 echo ""
else
 echo "$gpcc_err"
fi
if [ "$pxf_err" == "-1" ];then
 echo "- PXF Status -"
 echo "$pxf_st"
else
 echo "$pxf_err"
fi
}

function page_top(){
clear
echo ""
line -
msg_show " < 4. Check OS/GPDB Status > "
}

function page_bot(){
echo ""
msg_line " [Page $ct/$tt] " "-"
}

function check_ct(){
if [ $1 -gt $tt ];then
 ct=1
elif [ $1 -eq 0 ];then
 ct=$tt
fi
}

function run_page(){
page_top
page$1
page_bot
}

function line(){
 for (( i=1;i<$(tput cols);i++ ))
 do
  echo -n "$1"
 done
 echo ""
}

function msg_line(){
EL=$(tput cols)
MSG="$1"
sline=""
eline=""
let SP=$EL/2-${#MSG}/2
let MP=$SP+${#MSG}
for (( i=1;i<$SP;i++ ))
do
 sline="${sline}$(echo -n "$2")"
done
for (( j=$MP;j<$EL;j++ ))
do
 eline="${eline}$(echo -n "$2")"
done
printf "%s%${#MSG}s%s\n" "$sline" "$1" "$eline"
}

function msg_show(){
MSG="$1"
let COL=$(tput cols)/2-${#MSG}/2
printf "%${COL}s$s\n" "" "$1"
}

function check_segment(){
seg_count=$(cat ./inventory.lst | grep sdw | grep -v gpdb | wc -l)
seg_host=$(cat ./inventory.lst | grep sdw | grep -v gpdb | head -1 | awk '{print$3}' | awk -F'=' '{print$2}')
if [ $seg_count -gt 99 ];then
 seg_host_prefix=$(echo $seg_host | rev | cut -c 4- | rev)
elif [ $seg_count -gt 9 ];then
 seg_host_prefix=$(echo $seg_host | rev | cut -c 3- | rev)
else
 seg_host_prefix=$(echo $seg_host | rev | cut -c 2- | rev)
fi
sed -i "/^segment_count:/ c\segment_count: $seg_count" $vars_common_path
sed -i "/^segment_hostname_prefix:/ c\segment_ hostname_prefix: $seg_host_prefix" $vars_common_path
}

function check_num(){
numa=$(echo "$1" | tr -d .)
numb=${numa//[0-9]/}
if [ -z "$numb" ];then
 echo "$1"
else
 echo ""
fi
}

function check_ver(){
ch_num=$(echo "$1" | grep -c -E "[0-9]\.[0-9]+\.[0-9]")
if [ $ch_num -eq 1 ];then
 echo "$1"
else
 echo ""
fi
}

function check_alpha(){
ala=$(echo "$1" | tr -d .)
alb=${ala//[a-z]/}
alc=${alb//[A-Z]/}
if [ -z "$alc" ];then
 echo "$1"
else
 echo ""
fi
}

function del_tmp_file(){
rm -f ./select_items
rm -f ./default_items
rm -f $version_files_yml
rm -f $temp_val
rm -f ./upgrade_items
rm -f ./yml/upgrade_files.yml
rm -f $uninstall._st
}

### main menu start
sm=$(echo "$1" | tr '[A-Z' '[a-z]')
if [ $# -eq 1 ] && [ "$sm" == "ui" ];then
 while [ "$ms" != "x" ]
 do
  rpm -qa > /tmp/rpm_check.txt
  converter_inventory_raw2lst
  check_segment
  init_sel
  check_vip
  check_sysctl
  msel=""
  esel=""
  ch_standby=$(cat inventory.lst | grep smdw | grep -v gpdb | wc -l)
  clear
  echo ""
  msg_line " [ Ansible GPDB Automation ] " "-"
  echo ""
  echo " 1. Default GPDB Setup"
  echo " 2. Custom GPDB Setup"
  echo " 3. Patch(Minor Upgrade)"
  echo " 4. Check OS/GPDB Status"
  echo " 5. Uinstall"
  echo ""
  echo " > 'X|x' to Exit"
  line -
  echo -n " Select> "
  read ms
  case $ms in
  1)
  echo ""
  echo "Please fill in the 6 items below."
  echo -e -n "1) GPDB Version(\033[1;31;49mex> 6.7.1\033[0m): "
  read ra
  echo -e -n "2) Instance count(\033[1;31;49mex> 4\033[0m): "
  read rb
  echo -e -n "3)Expand group unit\033[1;31;49mex> 4\033[0m): "
  read rc  
  echo -e -n "4)GPCC Display name(\033[1;31;49mex>test\033[0m): "
  read rd
  echo -e -n "5)GPDB Mirror Config(\033[1;31;49mex> y\033[0m): "
  read re
  echo "6) Segment Data Type"
  echo "     [1] /data"
  echo "     [2] /data1 | /data2"
  echo -e -n "     Select(\033[1;31;49mex> 1\033[0m): "
  read rf
  va=$($check_ver $ra)
  vb=$(check_num $rb)
  vc=$(check_num $rc)
  vd=$rd
  ve=$(check_alpha $re)
  vf=$(check_num $rf)
  if [ "$va" == "" ] || [ "$vb" == "" ] || [ "$vc" == "" ] || [ "$ve" == "" ] || [ "$ve" == "" ]  || [ "$vf" == "" ] || [ $vf -gt 2 ];then
   echo ""
   echo -e "\033[1;31;49mAborted by system. Please check variable!\033[0m"
   echo "Return to main menu."
   read qq
  elif [ $seg_count -ge $vc ];then
   vaa=$(echo $va | sed 's/\./-/g')
   check_file $vaa
   let ch1_seg_count=$seg_count%$vc
   let ch2_seg_ocunt=$seg_count/$vc
   if [ $ch_standby -eq 1 ];then
    sed -i "/^enable_standby_master:/ c\enable_standby_master: 1" $vars_common_path
   fi
   sed -i "/^number_of_seg_instances_per_node:/ c\number_of_seg_instances_per_node: $vb" $vars_common_path
   let segment_group=($seg_count-$vc)/$vc
   sed -i "/^segment_group:/ c\segment_group: $segment_group" $vars_common_path
   sed -i "/^segment_group_count:/ c\segment_group_count: $vc" $vars_common_path
   sed -i "/^  display_name:/ c\  display_name: \"$vd\"" $vars_common_path
   line -
   msg_show " < 1. Default GPDB Setup > "
   echo ""
   echo "- Segment Node Count           : $seg_count"
   if [ $ch_standby -eq 1 ];then
    echo "- GPDB Standby Master        : True"
   fi
   if [ "$ve" == "Y" ] || [ "$ve" == "y" ];then
    vee="True"
    sed -i "/^enable_mirror:/ c\enable_mirror: 2" $vars_common_path
   else
    vee="False"
    sed -i "/^enable_mirror:/ c\enable_mirror: 1" $vars_common_path
   fi
   echo "- GPDB Mirror Config         : $vee"
   if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
    echo "- GPDB Expand group unit     : $vc"
   fi
   if [ $vf -eq 1 ];then
    echo "- GPDB Segment Data Path  : /data"
   elif [ $vf -eq 2 ];then
    echo "- GPDB Segment Data Path  : /data1 | /data2"
   fi
   sed -i "/^sel_data_path:/ c\sel_data_path: $vf" $vars_common_path
   echo ""
   echo "- GPDB                  : $gpdb_default_version / Instance : $vb"
   echo "- GPCC                  : $gpcc_default_version / Display name : $vd"
   echo "- madlib                 : $madlib_default_version"
   echo "- PL/Java               : $pljava_default_version"
   echo "- PL/R                    : $plr_default_version"
   echo "- Python Data Science   : $DataSciencePython_default_version"
   echo "- R Data Science    : $DataScienceR_default_version"
#   echo  "- GPCOPY          : $gpcopy_default_version"
   echo "- PXF                  : $Include in GPDB"
   echo ""
   echo "- VIP Environment     > IP                : $vip_ip"
   echo "                                     > NETMASK : $vip_net"
   echo "                                     > GATEWAY : $vip_gate"
   echo "                                     > SOURCE : $vip_ori"
   echo "                                     > TARGET : $vip_int"
   line -
   echo -n -e "\nIs it OK?(Yy/\033[0;31;49mNn\033[0m) "
   read aa
   if [ "$aa" == "Y" ] || [ "$aa" == "y" ];then
    echo "0_setup-base-setting.yml" > default_items
    echo "1_setup-gpdb.yml" >> default_items
    if [ "$ve" == "Y" ] || [ "$ve" == "y" ];then
     echo "1_mirror-gpdb.yml" >> default_items
    fi
    if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
     echo "1_expand-gpdb.yml" >> default_items
    fi
    if [ $ch_standby -eq 1 ];then
     echo "1_standby-gpdb.yml" >> default_items
    fi
    echo "2_setup-gpcc.yml" >> default_items
    echo "3_setup-gpfailover.yml" >> default_items
    echo "4_setup-gppkg-pljava.yml" >> default_items
    echo "5_setup-gppkg-plr.yml" >> default_items
    echo "6_setup-gppkg-DataSciencePython.yml" >> default_items
    echo "7_setup-gppkg-DataScienceR.yml" >> default_items
#    echo "8_setup-gppkg-gpcopy.yml" >> default_items
    echo "9_setup-gppkg-pxf.yml" >> default_items
    default_to_sel
    create version
    cat default_items > /tmp/default_items-$now
    cat $version_files_yml > /tmp/version_files-$now
    for di in $(cat default_items)
    do
     ### Insert Playbook Name to Log File.
     date >> ${LOG_FILE}.{LOG_TIME}
     echo "============== Playbook Name: $di ==============" | tee -a >> ${LOG_FILE}.{LOG_TIME}
     ### Setup GPDB on Cluster
     time ansible-playbook -i inventory.lst ./yml/$di  --extra-vars "ansible_user=root ansible_password={{ bd_ssg_root_pw }}" | tee -a ${LOG_FILE}.{LOG_TIME}
      date >> ${LOG_FILE}.{LOG_TIME}
    done
    echo ""
    echo  -e "\033[1;31;49mDefault GPDB Setup Complete!\033[0m"
    echo -n "Press any key. Return to the main menu"
    read qq
   else
    echo  -n "Return to the main menu"
    read qq
   fi
  else
   echo ""
   echo "Aborted by system. Check variable again!"
   echo -n "Press any key. Return to the main menu"
   read qq
  fi
  del_tmp_file
  ;;
  2)
  init_sel
  check_file
  while [ "$bms" != "m" ]
  do
   clear
   echo ""
   line -
   msg_show " < 2. Custom GPDB Setup > "
   echo ""
   echo -e " [\033[1;31;49m$b0\033[0m] 0) Setting OS/GPDB base"
   echo  -e " [\033[1;31;49m$b1\033[0m] 1) Installing GPDB and GPDB Parameter"
   if [ "$b1" == "v" ];then
    echo -e "     >> \033[1;32;49mVersion: $sel_gpdb_ver\033[0m | \033[1;33;49mSegment Count: $seg_count\033[0m | \033[1;37;49mInstance: $sel_seg_instance\033[0m"
    if [ "$ssel" = "Y" ] || [ "$ssel" == "y" ];then
     echo -e "     >> \033[1;34;49mStandby Master: Enable\033[0m"
    fi
    if [ "$msel" == "Y" ] || [ "$mse" == "y" ];then
     echo -e "     >> \033[1;36;49mMirror: Enable\033[0m"
    fi
    if [ "$esel" == "Y" ] || [ "$esel" == "y" ];then
     echo -e "     >> \033[1;35;49mExpand Group Unit: $sel_seg_group\033[0m"
    fi
    if [ $dsel -eq 1 ];then
     echo -e "      >> \033[1;33;49mSegment Data Type: /data\033[0m"
    elif [ $dsel -eq 2 ];then
     echo -e "      >> \033[1;33;49mSegment Data Type: /data1 | /data2\033[0m"
    fi
   fi
   echo -e " [\033[1;31;49m$b2\033[0m] 2) Installing GPCC"
   if [ "$b2" == "v" ];then
    echo -e "     >> \033[1;32;49mVersion: $sel_gpcc_ver\033[0m | \033[1;36;49mDisplay Name: $sel_gpcc_display_name\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b3\033[0m] 3) Setting GPfailover"
   if [ "$b3" == "v" ];then
    echo -e "     >>  VIP - IP: \033[1;32;49m$vip_ip\033[0m | NETMASK: \033[1;32;49m$vip_net\033[0m | GATEWAY: \033[1;32;49m$vip_gate\033[0m"
    echo -e "     >> INTERFACE - SOURCE: \033[1;32;49m$vip_ori\033[0m | TARGET: \033[1;32;49m$vip_int\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b4\033[0m] 4) Package > PL/JAVA"
   if [ "$b4" == "v" ];then
    echo -e "     >>  \033[1;32;49m$sel_pljava_ver\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b5\033[0m] 5) Package > PL/R"
   if [ "$b5" == "v" ];then
    echo -e "     >>  \033[1;32;49m$sel_plr_ver\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b6\033[0m] 6) Package > Python Data Science"
   if [ "$b6" == "v" ];then
    echo -e "     >>  \033[1;32;49m$sel_DataSciencePython_ver\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b7\033[0m] 7) Package > R Data Science"
   if [ "$b7" == "v" ];then
    echo -e "     >>  \033[1;32;49m$sel_DataScienceR_ver\033[0m"
   fi
   echo  -e " [\033[1;31;49m$b8\033[0m] 8) Package > GPCOPY"
   if [ "$b8" == "v" ];then
    echo -e "     >>  \033[1;32;49m$sel_gpcopy_ver\033[0m"
   fi 
   echo  -e " [\033[1;31;49m$b9\033[0m] 9) Package > PXF"
   echo ""
   echo " P|p) Output YAML list file"
   echo " S|s Install selected items"
   echo ""
   echo " > 'M|m' to Main Menu"
   line -
   echo -n " Select> "
   read bms
   case $bms in
   0)
   if [ "$b0" == "v" ];then
    b0=" "
   elif [ "$b0" != "v" ];then
    b0="v"
   fi
   ;;
   1)
   if [ "$b1" == "v" ];then
    b1=" "
    sel_gpdb_file=$gpdb_default_file
    sel_seg_instance=4
    sed -i "/^number_of_seg_instances_per_node:/ c\number_of_seg_instances_per_node: $sel_seg_instance" $vars_common_path
    sel_seg_group=4
    let sement_group=($seg_count-$sel_seg_group)/$sel_seg_group
    sed -i "/^segment_group:/ c\segment_group: $segment_group" $vars_common_path
    sed -i "/^segment_group_count:/ c\segment_group_count: $sel_seg_group" $vars_common_path
    sed -i "/^enable_mirror:/ c\enable_mirror: 1" $vars_common_path
   elif [ "$b1" != "v" ];then
    if [ $gpdb_count -gt 1 ];then
    echo ""
    echo "Found more than one installation GPDB file"
    no=1
    cat /dev/null > /tmp/gpdb_file_list
    for var in $gpdb_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print$3}'
      echo "$no) $var" >> /tmp/gpdb_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $gpdb_default_version>\033[0m: "
     read ba
     if [ -z "$ba" ];then
      sel_gpdb_file=$gpdb_default_file
     elif [ -n "${ba//[0-9]}" ] || [ $ba -ge $no ] || [ $ba -lt 1 ];then
      echo "Invalid number"
      sel_gpdb_file="Invalid number"
      sleep 0.5
     else
      sel_gpdb_file=$(cat /tmp/gpdb_file_list | grep "^$ba" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_godb_file" != "Invalid number" ];then
     #Input GPDB instance count
     echo -n -e "\nInput number of segment instances\033[0;34;49m<Default - 4>\033[0m: "
     read seg_instance_num
     if [ "$seg_instance_num" == "" ];then
      sel_seg_instance=4
     else
      sel_seg_instance=$seg_instance_num
     fi
     sed -i "/^number_of_seg_instances_per_node:/ c\number_of_seg_instances_per_node: $sel_seg_instance" $vars_common_path
     echo ""
     echo  -e -n "\"\033[1;31;49mGPDB Mirror\033[0m\" configuration progress?(Yy/\033[0;31;49mNn\033[0m) "
     read msel
     if [ "$msel" == "Y" ] || [ "$msel" == "y" ];then
      sed -i "/^enable_mirror:/ c\enable_mirror: 2" $vars_common_path
     else
      sed -i "/^enable_mirror:/ c\enable_mirror: 1" $vars_common_path
     fi
     if [ $seg_count -gt 4 ];then
      echo ""
      echo "More then 4 gpdb segments found."
      echo -e -n "Configure \"\033[1;31;49mGPDB Expand\033[0m\"?(Yy/\033[0;31;49mNn\033[0m) "
      read esel
      if [ "$esel" == "Y" ] || [ "$esel" == "y" ];then
        echo -e -n "Input \"\033[1;31;49mGPDB Expand group unit\033[0m\"\033[0;34;49m<Default - 4>\033[0m: "
       read seg_group_num
       if [ "$seg_group_num" == "" ];then
        sel_seg_group=4
       else
        sel_seg_group=$seg_group_num
       fi
       let ch1_seg_count=$seg_count%$sel_seg_group
       let ch2_seg_count=$seg_count/$sel_seg_group
       if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
        let segment_group=($seg_count-$sel_seg_group)/$sel_seg_group
        sed -i "/^segment_group:/ c\segment_group: $segment_group" $vars_common_path
        sed -i "/^segment_group_count:/ c\segment_group_count: $sel_seg_group" $vars_common_path
       else
        esel=""
       fi
      fi
     fi
     if [ $ch_standby -lt 2 ];then
      echo -e -n "\"\033[1;31;49mGPDB Standby Master\033[0m\" configuration progress?(Yy/\033[0;31;49mNn\033[0m) "
      read ssel
      if [ "$ssel" == "Y" ] || [ "$ssel" == "y" ];then
        sed -i "/^enable_standby_master:/ c\enable_standby_master: 1" $vars_common_path
      fi
      echo ""
     fi
     echo "- Segment Data Type -"
     echo "[1] /data"
     echo "[2] /data1 | /data2"
     echo -e -n "Select(\033[1;31;49mDefault: 1\033[0m): "
     read dsel
     if [ "$dsel" == "" ] || [ $dsel -gt 2 ];then
      dsel=1
     fi
     sed -i "/^sel_data_path:/ c\sel_data_path: $dsel" $vars_common_path    
     b1="v"
    fi
   fi
   sel_gpdb_ver=$(echo "$sel_gpdb_file" | awk -F'-' '{print$3}')
   ;;
   2)
   if [ "$b2" == "v" ];then
    b2=" "
    sel_gpcc_file=$gpcc_default_file
    sel_gpcc_display_name="gpcc"
    sed -i "/^  display_name:/ c\  display_name: \"$sel_gpcc_display_name\"" $vars_common_path
   elif [ "$b2" != "v" ];then
    if [ $gpcc_count -gt 1 ];then
     echo ""
     echo "Found more than one installation GPCC file."
     no=1
     cat /dev/null > /tmp/gpcc_file_list
     for var in $gpcc_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print$4}'
      echo "$no) $var" >> /tmp/gpcc_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $gpcc_default_version>\033[0m: "
     read bb
     if [ -z "$bb" ];then
      sel_gpcc_file=$gpcc_default_file
     elif [ -n "${bb//[0-9]}" ] || [ $bb -ge $no ] || [ $bb -lt 1 ];then
      echo "Invalid number"
      sel_gpcc_file="Invalid number"
      sleep 0.5
     else
      sel_gpcc_file=$(cat /tmp/gpcc_file_list | grep "^$bb" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_gpcc_file" != "Invalid number" ];then
     #Input GPDB display name
     echo -n -e "Input GPCC Display name\033[0;34;49m<Default - gpcc>\033[0m: "
     read gpcc_display_name
     if [ "$gpcc_display_name" == "" ];then
      sel_gpcc_display_name="gpcc"
     else
      sel_gpcc_display_name=$gpcc_display_name
     fi
     sed -i "/^  display_name:/ c\  display_name: \"$sel_gpcc_display_name\"" $vars_common_path
     echo -e "\nChanged GPCC display name: \033[1;31;49m$sel_gpcc_display_name\033[0m"
     sleep 0.5
     b2="v"
    fi
   fi
   sel_gpcc_ver=$(echo "$sel_gpcc_file" | awk -F'-' '{print$4}')
   ;;
   3)
   if [ "$b3" == "v" ];then
    b3=" "
   elif [ "$b3" != "v" ];then
    check_vip
    b3="v"
   fi
   ;;
   4)
   if [ "$b4" == "v" ];then
    b4=" "
    sel_pljava_file=$pljava_default_file
   elif [ "$b4" != "v" ];then
    if [ $pljava_count -gt 1 ];then
     echo ""
     echo "Found more than one installation PL/JAVA file."
     no=1
     cat /dev/null > /tmp/pljava_file_list
     for var in $pljava_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print2}'
      echo "$no) $var" >> /tmp/pljava_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $pljava_default_version>\033[0m: "
     read bc
     if [ -z "$bc" ];then
      sel_pljava_file=$pljava_default_file
     elif [ -n "${bc//[0-9]}" ] || [$bc -ge $no ] || [ $bc -lt 1 ];then
      echo "Invalid number"
      sel_pljava_file="Invalid number"
      sleep 0.5
     else
      sel_pljava_file=$(cat /tmp/pljava_file_list | grep "^$bc" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_pljava_file" != "Invalid number" ];then
     b4="v"
    fi
   fi
   sel_pljava_ver=$(echo "$sel_pljava_file" | awk -F'-' '{print$2}')
   ;;
   5)
   if [ "$b5" == "v" ];then
    b5=" "
    sel_plr_file=$plr_default_file
   elif [ "$b5" != "v" ];then
    if [ $plr_count -gt 1 ];then
     echo ""
     echo "Found more than one installation PL/R file."
     no=1
     cat /dev/null > /tmp/plr_file_list
     for var in $plr_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print2}'
      echo "$no) $var" >> /tmp/plr_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $plr_default_version>\033[0m: "
     read bd
     if [ -z "$bd" ];then
      sel_plr_file=$plr_default_file
     elif [ -n "${bd//[0-9]}" ] || [$bd -ge $no ] || [ $bd -lt 1 ];then
      echo "Invalid number"
      sel_plr_file="Invalid number"
      sleep 0.5
     else
      sel_plr_file=$(cat /tmp/plr_file_list | grep "^$bd" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_plr_file" != "Invalid number" ];then
     b5="v"
    fi
   fi
   sel_plr_ver=$(echo "$sel_plr_file" | awk -F'-' '{print$2}')
   ;;
   6)
   if [ "$b6" == "v" ];then
    b6=" "
    sel_DataSciencePython_file=$DataSciencePython_default_file
   elif [ "$b6" != "v" ];then
    if [ $DataSciencePython_count -gt 1 ];then
     echo ""
     echo "Found more than one installation Python Data Science file."
     no=1
     cat /dev/null > /tmp/DataSciencePython_file_list
     for var in $DataSciencePython_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print2}'
      echo "$no) $var" >> /tmp/DataSciencePython_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $DataSciencePython_default_version>\033[0m: "
     read be
     if [ -z "$be" ];then
      sel_DataSciencePython_file=$DataSciencePython_default_file
     elif [ -n "${be//[0-9]}" ] || [$be -ge $no ] || [ $be -lt 1 ];then
      echo "Invalid number"
      sel_DataSciencePython_file="Invalid number"
      sleep 0.5
     else
      sel_DataSciencePython_file=$(cat /tmp/DataSciencePython_file_list | grep "^$be" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_DataSciencePython_file" != "Invalid number" ];then
     b6="v"
    fi
   fi
   sel_DataSciencePython_ver=$(echo "$sel_DataSciencePython_file" | awk -F'-' '{print$2}')
   ;;
   7)
   if [ "$b7" == "v" ];then
    b7=" "
    sel_DataScienceR_file=$DataScienceR_default_file
   elif [ "$b7" != "v" ];then
    if [ $DataScienceR_count -gt 1 ];then
     echo ""
     echo "Found more than one installation R Data Science file."
     no=1
     cat /dev/null > /tmp/DataScienceR_file_list
     for var in $DataScienceR_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print2}'
      echo "$no) $var" >> /tmp/DataScienceR_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $DataScienceR_default_version>\033[0m: "
     read bf
     if [ -z "$bf" ];then
      sel_DataScienceR_file=$DataScienceR_default_file
     elif [ -n "${bf//[0-9]}" ] || [$bf -ge $no ] || [ $bf -lt 1 ];then
      echo "Invalid number"
      sel_DataScienceR_file="Invalid number"
      sleep 0.5
     else
      sel_DataScienceR_file=$(cat /tmp/DataScienceR_file_list | grep "^$bf" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_DataScienceR_file" != "Invalid number" ];then
     b7="v"
    fi
   fi
   sel_DataScienceR_ver=$(echo "$sel_DataScienceR_file" | awk -F'-' '{print$2}')
   ;;
   8)
   if [ "$b8" == "v" ];then
    b8=" "
    sel_gpcopy_file=$gpcopy_default_file
   elif [ "$b8" != "v" ];then
    if [ $gpcopy_count -gt 1 ];then
     echo ""
     echo "Found more than one installation GPCOPY file."
     no=1
     cat /dev/null > /tmp/gpcopy_file_list
     for var in $gpcopy_file_name
     do
      echo -n "$no) "
      echo " $var" | awk -F'-' '{print2}'
      echo "$no) $var" >> /tmp/gpcopy_file_list
      no=$((no+1))
     done
     echo ""
     echo -n -e "Select number\033[0;34;49m<Default Version - $gpcopy_default_version>\033[0m: "
     read bg
     if [ -z "$bg" ];then
      sel_gpcopy_file=$gpcopy_default_file
     elif [ -n "${bg//[0-9]}" ] || [$bg -ge $no ] || [ $bg -lt 1 ];then
      echo "Invalid number"
      sel_gpcopy_file="Invalid number"
      sleep 0.5
     else
      sel_gpcopy_file=$(cat /tmp/gpcopy_file_list | grep "^$bg" | awk -F' ' '{print$2}')
     fi
    fi
    if [ "$sel_gpcopy_file" != "Invalid number" ];then
     b8="v"
    fi
   fi
   sel_gpcopy_ver=$(echo "$sel_gpcopy_file" | awk -F'-' '{print$1}')
   ;;   
   9)
   if [ "$b9" == "v" ];then
    b9=" "
   elif [ "$b9" != "v" ];then
    b9="v"
   fi
   ;;
   P|p)
   if [ $seg_count -ge $sel_seg_group ];then
    cat /dev/null > ./select_items
    if [ "$b0" == "v" ];then
     echo "0_setup-base-setting.yml" >> select_items
    fi
    if [ "$b1" == "v" ];then
     echo "1_setup-gpdb.yml" >> select_items
     if [ "$msel" == "Y" ] || [ "$msel" == "y" ];then
      echo "1_mirror-gpdb.yml" >> select_items
     fi
     if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
      if [ "$esel" == "Y" ] || [ "$esel" == "y" ];then
      echo "1_expand-gpdb.yml" >> select_items
      fi
     fi
     if [ $ch_standby -eq 1 ];then
      if [ "$ssel" == "Y" ] || [ "$ssel" == "y" ];then
       echo "1_standby-gpdb.yml" >> select_items
      fi
     fi
    fi
    if [ "$b2" == "v" ];then
     echo "2_setup-gpcc.yml" >> select_items
    fi
    if [ "$b3" == "v" ];then
     echo "3_setup-gpfailover.yml" >> select_items
    fi
    if [ "$b4" == "v" ];then
     echo "4_setup-gppkg-pljava.yml" >> select_items
    fi
    if [ "$b5" == "v" ];then
     echo "5_setup-gppkg-plr.yml" >> select_items
    fi
    if [ "$b6" == "v" ];then
     echo "6_setup-gppkg-DataSciencePython.yml" >> select_items
    fi
    if [ "$b7" == "v" ];then
     echo "7_setup-gppkg-DataScienceR.yml" >> select_items
    fi
    if [ "$b8" == "v" ];then
     echo "8_setup-gppkg-gpcopy.yml" >> select_items
    fi
    if [ "$b9" == "v" ];then
     echo "9_setup-gppkg-pxf.yml" >> select_items
    fi
    echo ""
    cat select_items >> /tmp/select_items-$now
    cat select_items >> ./gpdb_custom_yml_list-$now
    echo ""
    echo "GPDB installation yaml file creation completed!"
    line -
    echo " File: gpdb_custom_yml_list-$now"
    line -
    echo -n "Press any key to go the main menu."
    read qq
   else
    echo ""
    echo -e "\033[1;31;49mAborted by system. Please check variable!\033[0m"
    echo -n "Press any key. Go to the main menu."
    read qq
   fi
   bms="m"
   ;;
   S|s)
   if [ $seg_count -ge $sel_seg_group ];then
    cat /dev/null > ./select_items
    if [ "$b0" == "v" ];then
     echo "0_setup-base-setting.yml" >> select_items
    fi
    if [ "$b1" == "v" ];then
     echo "1_setup-gpdb.yml" >> select_items
     if [ "$msel" == "Y" ] || [ "$msel" == "y" ];then
      echo "1_mirror-gpdb.yml" >> select_items
     fi
     if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
      if [ "$esel" == "Y" ] || [ "$esel" == "y" ];then
      echo "1_expand-gpdb.yml" >> select_items
      fi
     fi
     if [ $ch_standby -eq 1 ];then
      if [ "$ssel" == "Y" ] || [ "$ssel" == "y" ];then
       echo "1_standby-gpdb.yml" >> select_items
      fi
     fi
    fi
    if [ "$b2" == "v" ];then
     echo "2_setup-gpcc.yml" >> select_items
    fi
    if [ "$b3" == "v" ];then
     echo "3_setup-gpfailover.yml" >> select_items
    fi
    if [ "$b4" == "v" ];then
     echo "4_setup-gppkg-pljava.yml" >> select_items
    fi
    if [ "$b5" == "v" ];then
     echo "5_setup-gppkg-plr.yml" >> select_items
    fi
    if [ "$b6" == "v" ];then
     echo "6_setup-gppkg-DataSciencePython.yml" >> select_items
    fi
    if [ "$b7" == "v" ];then
     echo "7_setup-gppkg-DataScienceR.yml" >> select_items
    fi
    if [ "$b8" == "v" ];then
     echo "8_setup-gppkg-gpcopy.yml" >> select_items
    fi
    if [ "$b9" == "v" ];then
     echo "9_setup-gppkg-pxf.yml" >> select_items
    fi
    echo ""
    echo -n -e "Continue Process?(Yy/\033[0;31;49mNn\033[0m) "
    read conp
    if [ "$conp" == "Y" ] || [ "$conf"== "y" ];then
     create_version
     cat select_items  > /tmp/select_items-$now
     cat $version_files_yml > /tmp/version_files-$now
     for si in $(cat select_items)
     do
      date >> ${LOG_FILE}.${LOG_TIME}
      echo "=============== Playbook Name : $si ===============" | tee -a ${LOG_FILE}.${LOG_TIME}
      time ansible-playbook -i inventory.lst ./yml/$si --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
      date >> ${LOG_FILE}.${LOG_TIME}
     done
     echo ""
     echo -e "\033[1;31;49mCustom Install Processor end.\033[0m"
     echo -e "\033[1;31;49mIn case of an unknown error, confirm is required.\033[0m"
     echo ""
     echo -n "Press any key. Go to the main menu."
     read qq
    else
     echo -n "Return to the main menu"
     read qq
    fi
   else
    echo ""
    echo -e "\033[1;31;49mAborted by system. Please check variable!\033[0m"
    echo -n "Press any key. Go to the main menu"
    read qq
   fi
   bms="m"
   ;;
   M|m)
   bms="m"
   ;;
   *)
   ;;
   esac
  done
  bms=""
  del_tmp_file
  ;;
  3)
  cat /dev/null > ./upgrade_items
  chk_err=0
  while [ "$cms" != "m" ]
  do
   get_gpdb_patch_status
   clear
   echo ""
   line -
   msg_show " < 3.Patch > "
   echo " [Current Status]"
   echo -n " - GPDB: "
   echo "$c_gpdb_ver"
   echo " - GPDB Package List"
   for i in $c_gppkg_st
   do
    echo "   > $i"
   done
   echo -n "   > gpcopy-"
   echo "$c_gpcopy_st"
   echo -n " - GPCC: "
   echo "$c_gpcc_ver"
   echo ""
   echo " 1) Patch GPDB"
   echo " 2) Patch GPCC"
   echo ""
   echo " > 'M|m' to Main Menu"
   line -
   echo -n " Select> "
   read cms
   case $cms in
   1)
   echo ""
   msg_line " Upgrade GPDB & Package " "="
   echo "backup_gpdb: \"$(su -l gpadmin -c "gpstate -Q" | grep "local Greenplum Version" | awk '{print $8}')\"" > $tmp_val
   gppkg_lst=$(su -l gpadmin -c 'gppkg -q --all' | grep -v args | grep -v MetricsCollector | awk -F'-' '{print$1}')
   gppkg_ver=$(ls -l $src_path | grep -P "greenplum-db-[0-9]+" | awk '{print$9}' | awk -F'-' '{print$3}' | uniq)
   echo ""
   echo -e -n "[NOTICE] : The GPDB will be restarted during upgrade. Do you want to upgrade now?(Yy/\033[1;31;49mNn\033[0m) "
   read val_1
   if [ "$val_1" == "Y" ] || [ "$val_1" == "y" ];then
    echo ""
    echo "Select \"GPFB\" version: "
    no=1
    cat /dev/null > $upgrade_files_yml
    cat /dev/null > $/tmp/upgrade_list_gpdb
    for i in $gpdb_ver
    do
     echo "$no) $i" | tee -a /tmp/upgrade_list_gpdb
     no=$((n+1))
    done
    echo ""
    read -p "Select> " a1
    if [ "$a1" == "" ];then
     a1=1
    fi
    cnt=$(cat /tmp/upgrade_list_gpdb | wc -l)
    if [ $a1 -ge 1 ] && [ $a1 -le $cnt ];then
     a2=$(cat /tmp/upgrade_list_gpdb | grep "$a1)" | awk '{print2}')
     a3=$(ls -l $src_path | grep greenplum_db | grep "$a2" | awk '{print$9}')
     echo "gpdb_upgrade_file: \"$a3\"" >> $upgrade_files_yml
     echo "gpdb_version: \"$a2\"" >> $upgrade_files_yml
     echo "" >> $upgrade_files_yml
     echo ""
    else
     echo "Invalid number!"
     chk_err=1
     sleep 0.5
    fi
    if [ $chk_err -eq 1 ] ;then
     break
    fi
    for item in $gppkg_lst
    do
     chk_err=0
     version_info=$(ls -l $src_path | grep $item | awk '{print$9}' | awk -F'-' '{print$2}')
     echo "Select \"$item\" version: "
     no=1
     cat /dev/null > /tmp/upgrade_list_gppkg
     for i in $version_info
     do
      echo "$no) $i" | tee -a /tmp/upgrade_list_gppkg
      no=$((no+1))
     done
     echo ""
     read -p "Select> " b1
     if [ "$b1" == "" ];then
      b1=1
     fi
     cnt=$(cat /tmp/upgrade_list_gppkg | wc -l)
     if [ $b1 -ge 1 ] && [ $b1 -le $cnt ];then
      b2=$(cat /tmp/upgrade_list_gpdb | grep "$b1)" | awk '{print2}')
      b3=$(ls -l $src_path | grep $item | grep "$b2" | awk '{print$9}')
      echo $item"_upgrade_file: \"$b3\"" >> $upgrade_files_yml
      echo $item"_version: \"$b2\"" >> $upgrade_files_yml
      echo "" >> $upgrade_files_yml
      echo ""
     else
      echo "Invalid number!"
      chk_err=1
      sleep 0.5
     fi
     if [ $chk_err -eq 1 ] ;then
      break
     fi
    done
    if [ $chk_err -eq 1 ];then
     break
    fi
    up_file_ct=$(cat $upgrade_files_yml | grep "version" | wc -l)
    msg_line " Upgrade Version " "="
    for (( i=1;i<=$up_file_ct;i++ ))
    do
     let tn=$up_file_ct-$i+1
     printf "%-25s: %s\n" "$(cat $upgrade_files_yml | grep version | tr '[a-z]' '[A-Z]' | sed 's/DATASCIENCE/DATASCIENCE /g' | awk -F'_' '{print$1}' | tail -$tn | head -1)" "$(cat yml/upgrade_files.yml | grep version | awk '{print$2}' | tail -$tn | head -1)"
    done
    line =
    echo -e -n "Are you sure?(Yy/\033[0;31;49mNn\033[0m) "
    read c1
    if [ "$c1" == "Y" ] || [ "$c1" == "y" ];then
     echo ""
     echo -e -n "Do you want to upgrade PXF too?(Yy/\033[0;31;49mNn\033[0m) "
     read x1
     if [ "$x1" == "Y" ] || [ "$x1" == "y" ];then
      echo "9_setup-gppkg-pxf.yml" >> ./upgrade_items
     else
      echo "Skip PXF upgrade!"
     fi
     echo ""
     echo "Please wait..."
     echo ""
     for i in `cat yml/upgrade_files.yml | awk '{print$1}' | awk -F'-' '{print$1}' | uniq`
     do
      list=$(ls -l yml/ | grep yml | grep patch | grep $i | awk '{print$9}')
      echo "$list" >> ./upgrade_items
     done
     for i in `cat ./upgrade_items`
     do
      date >> ${LOG_FILE}.${LOG_TIME}
      time ansible-playbook -i inventory.lst ./yml/$i --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
      date >> ${LOG_FILE}.${LOG_TIME}
     done
     cat upgrade_items >> /tmp/upgrade_items-$now
     echo ""
     echo -e "\033[1;31;49mUpgrade Complete!!\033[0m"
     echo -e "\033[1;31;49mIn case of unknown error, confirm is required.\033[0m"
     echo ""
     read -p "Press any key. Go to the main menu." qq
    else
     echo -n "Aborted by user."
     read qq
    fi
   else
    echo "Aborted by user"
    read qq
   fi
   del_tmp_file
   ;;
   2)
   echo ""
   msg_line " Upgrade GPCC " "="
   gpcc_version=$(ls -l $src_path | grep "greenplum-cc" | awk '{print$9}' | awk -F'-' '{print$4}')
   echo ""
   echo -e -n "[NOTICE] : The GPDB will be restarted during upgrade. Do you want to upgrade now?(Yy/\033[0;31;49mNn\033[0m) "
   read val_2
   if [ "$val_2" == "Y" ] || [ "$val_2" =="y" ];then
    echo ""
    echo "Select \"GPCC\" version: "
    no=1
    cat /dev/null > $upgrade_files_yml
    cat /dev/null > /tmp/upgrade_list_gpcc
    for i in $gpcc_version
    do
     echo "$no) $i" | tee -a /tmp/upgrade_list_gpcc
     no=$((no+1))
    done
    echo ""
    read -p "Select> " c1
    if [ "$c1" == "" ];then
     c1=1
    fi
    gpcc_version_sort=$(ls -l /usr/local/ | grep "^l" | grep greenplum-cc | awk '{print$11}' | awk -F'.' '{print$2}')
    if [ $gpcc_version_sort -ge 2 ];then
     echo "gpcc_old_prefix_name: \"greenplum-cc\"" >> $upgrade_files_yml
    else
     echo "gpcc_old_prefix_name: \"greenplum-cc-web\"" >> $upgrade_files_yml
    fi
    cnt=$(cat /tmp/upgrade_list_gpcc | wc -l)
    if [ $c1 -ge 1 ] && [ $c1 -le $cnt ];then
     c2=$(cat /tmp/upgrade_list_gpcc | grep "$c1" | awk '{print$2}')
     c3=$(ls -l $src_path | grep greenplum-cc | grep "$c2" | awk '{print$9}')
     echo "gpcc_upgrade_file: \"$c3\"" >> $upgrade_files_yml
     echo "gpcc_version: \"$c2\"" >> $upgrade_files_yml
     echo ""
    else
     echo "Invalid number!"
     sleep 0.5
    fi
    gpcc_new_prefix_version=$(cat $upgrade_files_yml | grep gpcc_version | awk -F'.' '{print$2}')
    if [ $gpcc_new_prefix_version -ge 2 ];then
     echo "gpcc_new_prefix_name: \"greenplum-cc\"" >> $upgrade_files_yml
    else
     echo "gpcc_new_prefix_name: \"greenplum-cc-web\"" >> $upgrade_files_yml
    fi
    echo ""
    up_file_ct=$(cat $upgrade_files_yml | grep "gpcc_version" | wc -l)
    msg_line " Upgrade Version " "="
    for (( i=1;i<=$up_file_ct;i++ ))
    do
     let tn=$up_file_ct-$i+1
     printf "%-25s: %s\n" "$(cat $upgrade_files_yml | grep gpcc_version | tr '[a-z]' '[A-Z]' | awk -F'_' '{print$1}' | tail -$tn | head -1)" "$(cat yml/upgrade_files.yml | grep gpcc_version | awkj '{print$2}')"
    done
    line =
    echo -e -n "Are you sure?(Yy/\033[0;31;49mNn\033[0m) "
    read d1
    if [ "$d1" == "Y" ] || [ "$d1" == "y" ];then
     ps_cnt=$(ps -ef | grep -v grep | grep postgres | wc -l)
     if [ $ps_cnt -le 8 ];then
      echo ""
      echo -e "\033[1;31;49m[ERROR] : Database is not healthy! Please check Database first!!\033[0m"
      exit
     fi
     echo ""
     echo "Upgrade to \"$c2\". Please wait..."
     date >> ${LOG_FILE}.${LOG_TIME}
     echo "=============== Playbook Name: 2_patch-gpcc.yml ===============" | tee -a ${LOG_FILE}.${LOG_TIME}
     time ansible-playbook -i inventory.lsyt ./yml/2_patch-gpcc.yml --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
     date >> ${LOG_FILE}.${LOG_TIME}
     echo ""
     echo "Upgrade Complete!!"
     read -p "Press any key. Go to the main menu." qq
    else
     echo "Aborted by user"
     read qq
    fi
   else
    echo "Aborted by user"
    read qq
   fi
   ;;  
   M|m)
   cms="m"
   ;;
   *)
   ;;
   esac
  done
  cms=""
  del_tmp_file
  ;;
  4)
  ct=1
  tt=6
  mq=""
  rgc=report_gpdb_check-$(hostname)
  get_gpdb_conf
  date >> ${LOG_FILE}.${LOG_TIME}
  echo "=============== Playbook Name: check_status.yml ===============" | tee -a ${LOG_FILE}.${LOG_TIME}
  time ansible-playbook -i inventory.lst ./yml/check_status.yml --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
  date >> ${LOG_FILE}.${LOG_TIME}
  while [ "$mq" != "x" ]
  do
   run_page $ct
   echo -n -e " > Next<\033[1;32;49mN\033[0m> / Back<\033[1;34;49mB\033[0m> / Report<\033[1;33;49mN\033[0m> / Exit<\033[1;31;49mN\033[0m> "
   read -s -n1 mq
   case $mq in
   N|n)
   ct=$((ct+1))
   check_ct $ct
   ;;
   B|b)
   ct=$((ct-1))
   check_ct $ct
   ;;
   R|r)
   clear
   cat /dev/null > $rgc
   msg_show " < Report - OS/GPDB Status> " >> $rgc
   echo "Create Time: $LOG_TIME" >> $rgc
   for (( l=1;l<$(tput cols);l++ ))
   do
    echo -n "-" >> $rgc
   done
   echo "" >> $rgc
   for (( i=1;i<=$tt;i++ ))
   do
    page$i >> $rgc
    for (( j=1;j<$(tput cols);j++ ))
    do
     echo -n "-" >> $rgc
    done
   done
   echo "" >> $rgc
   more $rgc
   read -s -n1 qq
   ;;
   X|x)
   mq="x"
   ;;
   esac
  done
  del_tmp_file
  ;;
  5)
  echo ""
  line -
  msg_show " [ 5. Uninstall ] "
  echo ""
  echo " - All content(GPDB, GPCC) is deleted."
  echo " - Confirm your data and parameter."
  echo -e " - \033[0;31;49mLink file are also deleted.\033[0m"
  line -
  echo -e -n "Continue?(Yy/\033[0;31;49mNn\033[0m) "
  read sel
  if [ "$sel" == "Y" ] || [ "$sel" == "y" ];then
   echo "ch_db_st: \"$(su -l gpadmin -c 'ps =ef | grep -v grep | grep postgres | wc -l')\"" > $uninstall_st
   echo ""
   date >> ${LOG_FILE}.${LOG_TIME}
   echo "=============== Playbook Name: uninstall.yml ===============" | tee -a ${LOG_FILE}.${LOG_TIME}
   time ansible-playbook -i inventory.lst ./yml/uninstall.yml --extra-vars "ansible_user=root ansible_password={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
   date >> ${LOG_FILE}.${LOG_TIME}
   echo ""
   echo -e "\033[1;31;49m*** Uninstallation completed.\033[0m"
   echo -e "\033[1;31;49m*** In case of an unknown error, confirm is required.033[0m"
   read qq
  else
   echo ""
   echo "Aborted by user"
   read qq
  fi
  del_tmp_file
  ;;
  X|x)
  ms="x"
  ;;
  *)
  ;;
  esac
  del_tmp_file
 done
elif [ $# -eq 3 ] && [ "$sm" == "test" ];then
 rpm -qa > /tmp/rpm_check.txt
 ch_ver=$(echo $2 | sed 's/\./-/g')
 converter_inventory_raw2lst
 check_segment
 init_sel
 check_vip
 check_sysctl
 check_file $ch_ver
 create_version
 date >> ${LOG_FILE}.${LOG_TIME}
 echo "=============== Playbook Name: $3 ===============" | tee -a ${LOG_FILE}.${LOG_TIME}
 time ansible-playbook -i inventory.lst $3 --extra-vars "ansible_user=root ansible_passowrd={{ bd_ssh_root_pw }}" | tee -a ${LOG_FILE}.${LOG_TIME}
 date >> ${LOG_FILE}.${LOG_TIME}
 del_tmp_file
elif [ $# -eq 6 ];then
 converter_inventory_raw2lst
 check_segment
 init_sel
 check_vip
 check_sysctl
 va=$(check_ver $1)
 vb=$(check_num $2)
 vc=$(check_num $3)
 vd=$4
 ve=$(check_alpha $5)
 vf=$(check_num $6)
 vaa=$(echo $va | sed 's/\./-/g')
 check_file $vaa
 vec=1
 if [ "$ve" == "N" ] || [ "$ve" == "n" ];then
  if [ $seg_count -ne $vc ];then
   vec=0
  fi
 fi
 if [ $(check_exist $vaa) == "true" ];then
  if [ "$va" == "" ] || [ "$vb" == "" ] || [ "$vc" == "" ] || [ "$ve" == "" ] || [ $vec -eq 0 ] || [ "$vf" == "" ] || [ $vf -gt 2 ];then
   echo ""
   echo -e "\033[1;31;49mAborted by system. Please check variable!\033[0m"
   echo "Exit ansible GPDB setup."
   echo ""
  elif [ $seg_count -ge $vc ];then
   let ch1_seg_count=$seg_count%$vc
   let ch2_seg_count=$seg_count/$vc
   ch_standby=$(cat inventory.lst | grep smdw | grep -v gpdb | wc -l)
   sed -i "/^number_of_seg_instances_per_node
:/ c\ number_of_seg_instances_per_node: $vb" $vars_common_path
   let segment_group=($seg_count-$vc)/$vc
   sed -i "/^segment_group:/ c\segment_group: $segment_group" $vars_common_path
   sed -i "/^segment_group_count:/ c\segment_group_count: $vc" $vars_common_path
   sed -i "/^  display_name:/ c\  display_name: \"$vd\"" $vars_common_path
   echo ""
   line -
   msg_show " < Default GPDB Setup > "
   echo ""
   echo " - Segment Node Count         : $seg_count"
   if [ $ch_standby -eq 1 ];then
    echo "- GPDB Standby Master        : True"
    sed -i "/^enable_standby_master:/ c\enable_standby_master: 1" $vars_common_path
   fi
   if [ "$ve" == "Y" ] || [ "$ve" == "y" ];then
    vee="True"
    sed -i "/^enable_mirror:/ c\enable_mirror: 2" $vars_common_path
   else
     vee="False"
     sed -i "/^enable_mirror:/ c\enable_mirror: 1" $vars_common_path
   fi
   echo "- GPDB Mirror Config        : $vee"
   if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
    echo "- GPDB Group Count        : $vc"
   fi
   if [ $vf -eq 1 ];then
    echo "- GPDB Segment Data Path   : /data"
   else
    echo "- GPDB Segment Data Path   : /data1 | /data2"
   fi
   sed -i "/^sel_data_path:/ c\sel_data_path: $vf" $vars_common_path
   echo ""
   echo "- GPDB                  : $gpdb_default_version / Instance : $vb"
   echo "- GPCC                  : $gpcc_default_version / Display name : $vd"
   echo "- PL/Java               : $pljava_default_version"
   echo "- PL/R                    : $plr_default_version"
   echo "- Python Data Science   : $DataSciencePython_default_version"
   echo "- R Data Science    : $DataScienceR_default_version"
   echo "- PXF                  : $Include in GPDB"
   echo ""
   echo "- VIP Environment     > IP                : $vip_ip"
   echo "                                     > NETMASK : $vip_net"
   echo "                                     > GATEWAY : $vip_gate"
   echo "                                     > SOURCE : $vip_ori"
   echo "                                     > TARGET : $vip_int"
   line -
   cat /dev/null > ./default_items
   echo "0_setup-base-setting.yml" > default_items
   echo "1_setup-gpdb.yml" >> default_items
   if [ "$ve" == "Y" ] || [ "$ve" == "y" ];then
    echo "1_mirror-gpdb.yml" >> default_items
   fi
   if [ $ch1_seg_count -eq 0 ] && [ $ch2_seg_count -gt 1 ];then
    echo "1_expand-gpdb.yml" >> default_items
   fi
   if [ $ch_standby -eq 1 ];then
    echo "1_standby-gpdb.yml" >> default_items
   fi
   echo "2_setup-gpcc.yml" >> default_items
   echo "3_setup-gpfailover.yml" >> default_items
   echo "4_setup-gppkg-pljava.yml" >> default_items
   echo "5_setup-gppkg-plr.yml" >> default_items
   echo "6_setup-gppkg-DataSciencePython.yml" >> default_items
   echo "7_setup-gppkg-DataScienceR.yml" >> default_items
#   echo "8_setup-gppkg-gpcopy.yml" >> default_items
   echo "9_setup-gppkg-pxf.yml" >> default_items
   default_to_sel
   create version
   cat default_items > /tmp/default_items-$now
   cat $version_files_yml > /tmp/version_files-$now
   for mdi in $(cat default_items)
   do
    ### Insert Playbook Name to Log File.
    date >> ${LOG_FILE}.{LOG_TIME}
    echo "============== Playbook Name: $mdi ==============" | tee -a >> ${LOG_FILE}.{LOG_TIME}
    ### Setup GPDB on Cluster
    time ansible-playbook -i inventory.lst ./yml/$mdi  --extra-vars "ansible_user=root ansible_password={{ bd_ssg_root_pw }}" | tee -a ${LOG_FILE}.{LOG_TIME}
    date >> ${LOG_FILE}.{LOG_TIME}
   done
   echo ""
   echo  -e "\033[1;31;49mDefault GPDB Setup Complete!\033[0m"
   echo "Exit Default GPDB Setup."
  fi
 else
  echo -e "\033[1;31;49mAborted by system. Please check \"1st value(GPDB version)\" or Binary file existence!\033[0m"
  echo "Exit ansible GPDB Setup"
 fi
 del_tmp_file
else
 echo "Check the list below for how to use"
 echo -e "[Usage 1] ./run_playbook.sh \033[1;31;49mui\033[0m"
 echo ""
 echo -e "[Usage 2] ./run_playbook.sh \033[1;31;49mtest\033[0m \033[1;3249m[GPDB Version]\033[0m \033[1;31449m[yml file]\033[0m"
 echo -e " - example) ./run_playbook.sh \033[1;31;49mtest\033[0m \033[1;32;49m6.11.1\033[0m \033[1;34;49mset-up-gpdb.yml\033[0m"
 echo ""
 echo -e "[Usage 3] ./run_playbook.sh \033[1;32;49m[1st]\033[0m \033[1;34;49m[2nd]\033[0m \033[1;31;49m[3rd]\033[0m \033[1;35;49m[4th]\033[0m \033[1;36;49m[5th]\033[0m \033[1;33;49m[6th]\033[0m"
 echo -e "                  - \033[1;32;49m[1st]\033[0m GPDB version (ex> 6.11.1, 6.7.1)   \033[0;31;49m### [Caution] Defined value\033[0m"
 echo -e "                  - \033[1;34;49m[2nd]\033[0m GPDB instance unit count (ex> 4, 8)"
 echo -e "                  - \033[1;31;49m[3rd]\033[0m GPDB expand group unit count (ex> 4, 8)"
 echo -e "                  - \033[1;35;49m[4th]\033[0m GPDB web ui display name (ex> gpcc, test)"
 echo -e "                  - \033[1;36;49m[5th]\033[0m GPDB mirror chioce (ex> y or n)   \033[0;31;49m### Must select y or n\033[0m"
 echo -e "                  - \033[1;36;49m[6th]\033[0m GPDB data type choice (ex> 1 or 2)   \033[0;31;49m### Must select 1 or 2\033[0m"
 echo -e "                                1) /data"
 echo -e "                                1) /data1 | /data2"
 echo -e " - example)  ./run_playbook.sh \033[1;32;49m6.11.1\033[0m \033[1;34;49m4\033[0m \033[1;31;49m4\033[0m \033[1;35;49mtest\033[0m \033[1;36;49my\033[0m \033[1;33;49m1\033[0m"
 echo -e ""
 del_tmp_file
fi
