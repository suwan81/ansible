#!/bin/bash

export MON_HOME="/data/utilities"
source ${MON_HOME}/setup/cluster_info.sh

echo '#############################' ${DATE_TIME} '#############################' >> /data/utilities/statlog/df-h.${DATE}.txt

for i in `seq 1 ${SEG_COUNT}`
do
echo '['${DATE_TIME}']' >> /data/utilities/statlog/df-h.${DATE}_0.txt
echo '['sdw$i']' >> /data/utilities/statlog/df-h.${DATE}_0.txt
ssh sdw$i '. ~/.bash_profile; df -khP | grep /data' >> /data/utilities/statlog/df-h.${DATE}_0.txt
#sleep 1
done

awk 'NR%3{printf "%s ",$0;next;}1' /data/utilities/statlog/df-h.${DATE}_0.txt >> /data/utilities/statlog/df-h.${DATE}.txt
rm /data/utilities/statlog/df-h.${DATE}_0.txt
