#!/bin/bash

now=$(date +"%Y%m%d%H%M")

seg_host_prefix=$(su -l gpadmin -c "psql -Atc \"select substr(hostname,1, length(hostname) -1) from gp_segment_configuration where content = 0 and preferred_role = 'p';\"")
host_l=${#seg_host_prefix}
let host_len=$host_l+1
instance_prefix=$(su -l gpadmin -c "psql -Atc \"select split_part(substr(datadir,1, length(datadir) -1),'/',4) from gp_segment_configuration where content = 0 and preferred_role = 'p';\"")
instance_l=${#instance_prefix}
let instance_len=$instance_l+1
echo "$(su -l gpadmin -c "psql -Atc \"select hostname || '|' || address || '|' || port || '|' || datadir || '|' || dbid || '|' || content || '|' || preferred_role from gp_segment_configuration where hostname like '%$seg_host_prefix%' order by content,dbid;\"")" > /tmp/tmp_map_file
ori_map_file=/tmp/ori_map_file

#l_content=$(su -l gpadmin -c "psql -Atc \"select content from gp_segment_configuration where hostname like '%$seg_host_prefix%' order by 1 desc limit 1;\"")
p_port=$(su -l gpadmin -c "psql -Atc \"select port from gp_segment_configuration where datadir like '%gpseg0%' and preferred_role = 'p';\"")
m_port=$(su -l gpadmin -c "psql -Atc \"select port from gp_segment_configuration where datadir like '%gpseg0%' and preferred_role = 'm';\"")
instance_count=$(su -l gpadmin -c "psql -Atc \"select count(distinct port)/2 from gp_segment_configuration where hostname like '%$seg_host_prefix%';\"")
a_dbid=$(su -l gpadmin -c "psql -Atc \"select dbid from gp_segment_configuration where datadir like '%primary/gpseg0%';\"")
b_dbid=$(su -l gpadmin -c "psql -Atc \"select dbid from gp_segment_configuration where datadir like '%mirror/gpseg0%';\"")
let seg_group=($b_dbid-$a_dbid)/$instance_count
let map_ct=$seg_group*$instance_count*2

cat /tmp/tmp_map_file | tail -$map_ct > $ori_map_file

function check_dbid(){
 lt_dbid=$(su -l gpadmin -c "psql -Atc \"select dbid from gp_segment_configuration order by 1 desc limit 1;\"")
 ls_dbid=$(su -l gpadmin -c "psql -Atc \"select dbid from gp_segment_configuration where hostname like '%$seg_host_prefix%' order by 1 desc limit 1;\"")
 if [ $lt_dbid -gt $ls_dbid ];then
  let dbid_sum=$lt_dbid-$ls_dbid
 elif [ $lt_dbid -eq $ls_dbid ];then
   dbid_sum=0
 fi
}

function expand_out(){
ori_map_ct=$(cat $ori_map_file | wc -l)
check_dbid
for (( i=$ori_map_ct;i>=1;i--))
do
 let host_num=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$1}' | cut -c $host_len-)+$seg_group*$1
 db_port=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$3}')
 data_dir1=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$4}' | awk -F'/' '{print$2}')
 data_dir2=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$4}' | awk -F'/' '{print$3}')
 data_dir3=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$4}' | awk -F'/' '{print$4}' | cut -c $instance_len-)
 let content_num=$data_dir3+$seg_group*$instance_count*$1
 db_id=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$5}')
 let db_id_num=$db_id+$seg_group*$instance_count*2*$1+$dbid_sum
 p_role=$(cat $ori_map_file | tail -$i | head -1 | awk -F'|' '{print$7}')
 
 echo "$seg_host_prefix$host_num|$seg_host_prefix$host_num|$db_port|/$data_dir1/$data_dir2/$instance_prefix$content_num|$db_id_num|$content_num|$p_role"
done
}

if [ "$#" -eq 1 ];then
 if [ "$1" -ge 2 ];then
  for (( j=1;j<=$1;j++ ))
  do
   expand_out $j
  done
 else
  expand_out 1
 fi
elif [ "$#" -eq 0 ];then
 expand_out 1
fi
