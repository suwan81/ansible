Before use ansible-playbook.sh, check the file below
1. inventory.raw
   - role, bd_ip, bd_hostname, bd_nodename(alias)
   - bd_vip, bd_vip_arping_interface, bd_vip_interface, bd_vip_gateway, bd_vip_network
2. yml/vars-common.yml
   - check ntp ip address, lines 14-24
   - When using pxf, lines 88-104
3. templates/resolv.conf.j2
   - check the nameserver ip address

[How to use]
[Usage 1] ./run_playbook.sh ui

[Usage 2] ./run_playbook.sh test [GPDB Version] [yml file]
      ex) ./run_playbook.sh test 6.11.1 test.yml

[Usage 3] ./run_playbook.sh [1st] [2nd] [3rd] [4th] [5th] [6th]
          - [1st] GPDB version (ex> 6.11.1)   ### [Caution] Defined value only
          - [2nd] GPDB instance unit count (ex> 8)
          - [3rd] GPDB expand group unit count (ex> 4)
          - [4th] GPCC web UI display name (ex> test)
          - [5th] GPDB mirror choice (ex> y or n)   ### Must select 'y' or 'n'
          - [6th] GPDB data type choice (ex> 1 or 2)   ### Must select '1' or '2'
                  1) /data
                  2) /data1 | /data2
      ex) ./run_playbook.sh 6.11.1 4 4 test y 1
