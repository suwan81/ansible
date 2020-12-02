#!/bin/bash

sou_path=/root/gpdb-src

tar xf $sou_path/binary.tar -C /usr/sbin/
tar xf $sou_path/gppython.tar -C /usr/local/
ln -s /usr/local/gppython-4.2.2.0 /usr/local/gppython
ln -s /lib64/libreadline.so.6 /lib64/libreadline.so.5
