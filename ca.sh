#!/bin/bash
#
openssl version || exit
ntpdate 0.centos.pool.ntp.org
# ---------------------------- private CA ---------------------------------
dir='/etc/pki/CA'
mkdir -p ${dir}/{certs,crl,newcerts,private}
[ -f ${dir}/private/cakey.pem ] || (umask 077; openssl genrsa -out ${dir}/private/cakey.pem 2048)
[ -f ${dir}/cacert.pem ] || openssl req -new -x509 -key ${dir}/private/cakey.pem -out ${dir}/cacert.pem -days 7300
sleep 2
[ -f $dir/index.txt ] || touch $dir/index.txt
[ -f $dir/serial ] || echo "01" > $dir/serial

read -p 'nginx or httpd or haproxy? ' prog
[ -n "$prog" ] || exit
[ "$prog" == "nginx" -o "$prog" == "httpd" -o "$prog" == "haproxy" ] || exit 
echo -e "\033[1;31mInstall $prog ssl\033[0m"
# ----------------------------- $prog ssl ----------------------------------
ssl_dir="/etc/$prog/ssl"
#
mkdir -pv $ssl_dir
[ -f $ssl_dir/$prog.key ] || (umask 077; openssl genrsa -out $ssl_dir/$prog.key 2048)
[ -f ${ssl_dir}/$prog.csr ] || openssl req -new -key ${ssl_dir}/$prog.key -out ${ssl_dir}/$prog.csr -days 365
[ -f ${ssl_dir}/$prog.crt ] || openssl ca -in ${ssl_dir}/$prog.csr -out ${ssl_dir}/$prog.crt -days 365
