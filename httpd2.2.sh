#!/bin/bash
#

wkdir=$PWD
yum -y groupinstall "Development Tools" 
yum -y install zlib-devel
which wget || yum -y install wget
[ -f httpd-2.2.34.tar.gz ] || wget http://mirrors.tuna.tsinghua.edu.cn/apache//httpd/httpd-2.2.34.tar.gz
for i in prefork event worker; do
	[ -d /usr/local/httpd22-$i ] && continue 
	[ -d httpd-2.2.34-$i ] || tar xf httpd-2.2.34.tar.gz 
	mv httpd-2.2.34 httpd-2.2.34-$i
	cd httpd-2.2.34-$i
	./configure --prefix=/usr/local/httpd22-$i --enable-modules=all --with-mpm=$i
	make -j 8
	make install
	sleep 5
	cd $wkdir
	rm -rf httpd-2.2.34-$i
done

ln -sv /usr/local/httpd22-worker/bin/httpd  /usr/sbin/httpd.worker
ln -sv /usr/local/httpd22-event/bin/httpd  /usr/sbin/httpd.event
ln -sv /usr/local/httpd22-prefork/bin/httpd  /usr/sbin/httpd
install ${wkdir}/httpd /etc/rc.d/init.d/httpd
cp ${wkdir}/httpd-sys /etc/sysconfig/httpd
chkconfig --add httpd

