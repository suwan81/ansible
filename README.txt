Before use ansible-playbook.sh, check the file below
1. inventory.raw
   - role, bd_ip, bd_hostname, bd_nodename(alias)
   - bd_vip, bd_vip_arping_interface, bd_vip_interface, bd_vip_gateway, bd_vip_network
2. yml/vars-common.yml
   - check ntp ip address, lines 14-24
3. templates/resolv.conf.j2
   - check the nameserver ip address
4. It is optimized for redhat 7.5 system and ansible 2.3.1.0 version.
5. Basically, the binary storage space is /data/staging. The structure of the directory is as follows.
/data/staging/
├── 6-11-1
├── 6-13-0
├── 6-14-0
├── DataSciencePython-2.0.3-gp6-rhel7_x86_64.gppkg
├── DataScienceR-2.0.2-gp6-rhel7_x86_64.gppkg
├── binary.tar
├── gpcopy-2.3.0.tar.gz
├── gppython.tar
├── greenplum-cc-web-6.3.1-gp6-rhel7-x86_64.zip
├── greenplum-cc-web-6.4.0-gp6-rhel7-x86_64.zip
├── greenplum-db-6.11.1-rhel7-x86_64.rpm
├── greenplum-db-6.13.0-rhel7-x86_64.rpm
├── greenplum-db-6.14.0-rhel7-x86_64.rpm
├── madlib-1.17.0+14-gp6-rhel7-x86_64.tar.gz
├── madlib-1.17.0+18-gp6-rhel7-x86_64.tar.gz
├── madlib-1.17.0+19-gp6-rhel7-x86_64.tar.gz
├── pljava-2.0.2-gp6-rhel7_x86_64.gppkg
├── plr-3.0.3-gp6-rhel7-x86_64.gppkg
├── rhel75
│   ├── PyYAML-3.10-11.el7.x86_64.rpm
│   ├── libtomcrypt-1.17-26.el7.x86_64.rpm
│   ├── libtommath-0.42.0-6.el7.x86_64.rpm
│   ├── libyaml-0.1.4-11.el7_0.x86_64.rpm
│   ├── python-babel-0.9.6-8.el7.noarch.rpm
│   ├── python-backports-1.0-8.el7.x86_64.rpm
│   ├── python-backports-ssl_match_hostname-3.5.0.1-1.el7.noarch.rpm
│   ├── python-cffi-1.6.0-5.el7.x86_64.rpm
│   ├── python-enum34-1.0.4-1.el7.noarch.rpm
│   ├── python-idna-2.4-1.el7.noarch.rpm
│   ├── python-ipaddress-1.0.16-2.el7.noarch.rpm
│   ├── python-jinja2-2.7.2-4.el7.noarch.rpm
│   ├── python-keyczar-0.71c-2.el7.noarch.rpm
│   ├── python-markupsafe-0.11-10.el7.x86_64.rpm
│   ├── python-paramiko-2.1.1-9.el7.noarch.rpm
│   ├── python-ply-3.4-11.el7.noarch.rpm
│   ├── python-pycparser-2.14-1.el7.noarch.rpm
│   ├── python-setuptools-0.9.8-7.el7.noarch.rpm
│   ├── python2-crypto-2.6.1-16.el7.x86_64.rpm
│   ├── python2-cryptography-1.7.2-2.el7.x86_64.rpm
│   ├── python2-httplib2-0.18.1-3.el7.noarch.rpm
│   ├── python2-pyasn1-0.1.9-7.el7.noarch.rpm
│   └── sshpass-1.06-2.el7.x86_64.rpm
└── rpms
    └── ansible-2.3.1.0-1.el7.noarch.rpm

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
