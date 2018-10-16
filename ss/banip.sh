#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
function banip() {
	if [ -z "$options" ]; then
		local ip=`ss -tan | grep 'ESTAB' | egrep "107.172.67.44:${1}" | awk '{split($5,a,":");count[a[1]]++} END {for (i in count) {print i}}'`
	else
		local ip=`ss -tan | grep 'ESTAB' | egrep "107.172.67.44:${1}" | awk '{split($5,a,":");count[a[1]]++} END {for (i in count) {print i}}' | grep -E -v "$options"`
	fi
	for i in $ip; do
		iptables -vnL INPUT | grep -q $i ||  iptables -I INPUT -s $i -p tcp -m multiport --dports ${1} -j DROP
	done
}

# white list
white_file='/root/ss/white_ip_list.file'
options=$(cat $white_file | grep -v '^#' | xargs | tr ' ' '|')
# ssr port
declare -a banport_list=('8080' '443')

for i in ${banport_list[@]}; do
  banip $i
done

# clear zero iptables
sleep 3
numbers=`iptables -vnL INPUT --line | grep '^[0-9]\+[[:space:]]\+0[[:space:]]\+0[[:space:]]\+DROP' | awk '{print $1}'`
for i in $numbers; do
  iptables -D INPUT $i
done
