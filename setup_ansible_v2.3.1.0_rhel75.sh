#!/bin/bash

path=/data/staging
ver=rhel75

rpm -ivh $path/$ver/python2-pyasn1-0.1.9-7.el7.noarch.rpm
rpm -ivh $path/$ver/python-ipaddress-1.0.16-2.el7.noarch.rpm
rpm -ivh $path/$ver/sshpass-1.06-2.el7.x86_64.rpm
rpm -ivh $path/$ver/libyaml-0.1.4-11.el7_0.x86_64.rpm
rpm -ivh $path/$ver/PyYAML-3.10-11.el7.x86_64.rpm
rpm -ivh $path/$ver/libtommath-0.42.0-6.el7.x86_64.rpm
rpm -ivh $path/$ver/libtomcrypt-1.17-26.el7.x86_64.rpm
rpm -ivh $path/$ver/python2-crypto-2.6.1-16.el7.x86_64.rpm
rpm -ivh $path/$ver/python-keyczar-0.71c-2.el7.noarch.rpm
rpm -ivh $path/$ver/python-backports-1.0-8.el7.x86_64.rpm
rpm -ivh $path/$ver/python-backports-ssl_match_hostname-3.5.0.1-1.el7.noarch.rpm
rpm -ivh $path/$ver/python-setuptools-0.9.8-7.el7.noarch.rpm
rpm -ivh $path/$ver/python2-httplib2-0.18.1-3.el7.noarch.rpm
rpm -ivh $path/$ver/python-babel-0.9.6-8.el7.noarch.rpm
rpm -ivh $path/$ver/python-ply-3.4-11.el7.noarch.rpm
rpm -ivh $path/$ver/python-pycparser-2.14-1.el7.noarch.rpm
rpm -ivh $path/$ver/python-cffi-1.6.0-5.el7.x86_64.rpm
rpm -ivh $path/$ver/python-markupsafe-0.11-10.el7.x86_64.rpm
rpm -ivh $path/$ver/python-jinja2-2.7.2-4.el7.noarch.rpm
rpm -ivh $path/$ver/python-idna-2.4-1.el7.noarch.rpm
rpm -ivh $path/$ver/python-enum34-1.0.4-1.el7.noarch.rpm
rpm -ivh $path/$ver/python2-cryptography-1.7.2-2.el7.x86_64.rpm
rpm -ivh $path/$ver/python-paramiko-2.1.1-9.el7.noarch.rpm
rpm -ivh $path/rpms/ansible-2.3.1.0-1.el7.noarch.rpm
