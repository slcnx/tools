#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
port=443

rm -f /root/ss/$port-tmp1 /root/ss/$port-tmp2
for i in /root/sslog/${port}*; do tcpdump -r  $i | grep -Po '(\d+\.){3}\d+' | sort -u >> /root/ss/$port-tmp1; done
sort -u /root/ss/$port-tmp1 > /root/ss/$port-tmp2
sort -u /root/ss/$port-tmp2 /root/ss/$port-ip-access.log  > /root/ss/$port-ip-access.log

whole_name=`ls -lth /root/sslog/$port* | grep -v '^total' |awk '{print $NF}' | head -n 1`
find /root/sslog/ -mindepth 1 -name "$port*" -not -wholename "$whole_name" -delete

rm -f /root/ss/$port-tmp1 /root/ss/$port-tmp2
