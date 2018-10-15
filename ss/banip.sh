#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

ip=`ss -tan | grep 'ESTAB' | egrep '107.172.67.44:443' | awk '{split($5,a,":");count[a[1]]++} END {for (i in count) {print i}}' | grep -E -v "$(cat white_ip_list.file | grep -v '^#' | xargs | tr ' ' '|')"
for i in $ip; do
  iptables -vnL INPUT | grep -q $i ||  iptables -I INPUT -s $i -p tcp -m multiport --dports 443 -j DROP
done

ip=`ss -tan | grep 'ESTAB' | egrep '107.172.67.44:8080' | awk '{split($5,a,":");count[a[1]]++} END {for (i in count) {print i}}' | grep -E -v "$(cat white_ip_list.file | grep -v '^#' | xargs | tr ' ' '|')"
for i in $ip; do
  iptables -vnL INPUT | grep -q $i ||  iptables -I INPUT -s $i -p tcp -m multiport --dports 8080 -j DROP
done
