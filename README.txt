Before use ansible-playbook.sh, check the file below

1. Must modify inventory.raw file
   - role, bd_ip, bd_hostname, bd_nodename(alias)
   - bd_vip, bd_vip_arping_interface, bd_vip_interface, bd_vip_gateway, bd_vip_network
   
2. yml/vars-common.yml
   - check ntp ip address, lines 14-22
   
3. templates/resolv.conf.j2
   - check the nameserver ip address
   
4. It is optimized for redhat 7.5 system and ansible 2.3.1.0 version.

5. setup_os_base.sh is an ansible action script for server default settings.

6. Basically, the binary storage space is /data/staging. The files related to rhel75 and rpms are uploaded to staging of the upper repository.

7. To run setup_ansible_v2.3.1.0_rhel75.sh, the installation file must exist under /data/staging/rhel75.
   Save the contents of rhel75foransible.tar.gz file to the above path.

8. The GPDB version definition file must be predefined in the /data/staging or ansible-gpdb/version_check directory.
   ex) # cat /data/staging/6-13-0 or /root/ansible-gpdb/version-check/6-13-0
         greenplum-db-6.13.0-rhel7-x86_64.rpm
         greenplum-cc-web-6.4.0-gp6-rhel7-x86_64.zip
         pljava-2.0.2-gp6-rhel7_x86_64.gppkg
         plr-3.0.3-gp6-rhel7-x86_64.gppkg
         DataSciencePython-2.0.3-gp6-rhel7_x86_64.gppkg
         DataScienceR-2.0.2-gp6-rhel7_x86_64.gppkg
         madlib-1.17.0+18-gp6-rhel7-x86_64.tar.gz

** When run_playbook.sh is executed, the basic usage method is displayed.
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
