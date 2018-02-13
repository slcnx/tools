#!/bin/bash
# 
# Date: 2018/1/30
#

trap 'exit' INT
mysql_user='root'
mysql_host='localhost'

grant_database='vsftpd'
grant_user='vsftpd'
grant_host='127.0.0.1'
grant_password='vsftpd'

yum -y -d 0 -e 0 install vsftpd mariadb-server mariadb-devel pam-devel
# ---------------------- complie pam_mysql.so for vsftpd-----------------------
yum -y -d 0 -e 0 groupinstall "Development Tools" "Server Platform Development"
until [ -f /usr/lib64/security/pam_mysql.so ]; do
    [ -f pam_mysql-0.7RC1.tar.gz ] || wget http://prdownloads.sourceforge.net/pam-mysql/pam_mysql-0.7RC1.tar.gz
    [ -d pam_mysql-0.7RC1 ] || tar xf pam_mysql-0.7RC1.tar.gz
    cd pam_mysql-0.7RC1/
    ./configure --with-mysql=/usr --with-pam=/usr --with-pam-mods-dir=/usr/lib64/security 
    make 
    make install
done
ls /usr/lib64/security/pam_mysql.so
sleep 2

# configure mariadb 
cat > /etc/my.cnf << EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
skip_name_resolve = ON
innodb_file_per_table = ON
log_bin=mysql-bin
[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d
EOF
# start mariadb service
systemctl restart mariadb.service


# configure env
if ! mysql -u$mysql_user -h$mysql_host  -D ${grant_database} -e 'SHOW TABLES' &> /dev/null; then
    mysql -u$mysql_user -h$mysql_host  -e "CREATE DATABASE ${grant_database};" \
    && mysql -u$mysql_user -h$mysql_host  -e "GRANT ALL ON ${grant_database}.* TO '${grant_database}'@'$grant_host' IDENTIFIED BY '${grant_password}';" \
    && mysql -u$mysql_user -h$mysql_host  -e "CREATE TABLE ${grant_database}.users(id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(60) NOT NULL, password CHAR(48) NOT NULL, UNIQUE KEY(name));"
fi  

# create user
while true; do
	echo -e 'Start create users, until input "\033[1;31mquit\033[0m"'
	read -p "Enter a username: " username
	[ -z "$username" ] && continue
	[ "$username" == "quit" -o "$password" == "quit" ] && break
	read -p "Enter a password: " password
	[ -z "$username" ] && continue
	[ "$username" == "quit" -o "$password" == "quit" ] && break
	mysql -u$mysql_user -h$mysql_host  -e "INSERT INTO ${grant_database}.users(name,password) VALUES (\"$username\",PASSWORD(\"$password\"));" && users[${#users[@]}]=$username
done

# pam configure file
cat > /etc/pam.d/vsftpd.vusers << EOF
auth required /usr/lib64/security/pam_mysql.so user=${grant_user} passwd=${grant_password} host=${grant_host} db=${grant_database} table=users usercolumn=name passwdcolumn=password crypt=2
account required /usr/lib64/security/pam_mysql.so user=${grant_user} passwd=${grant_password} host=${grant_host} db=${grant_database}  table=users usercolumn=name passwdcolumn=password crypt=2
EOF

# vsftpd.conf add virtual user 
[ -f /etc/vsftpd/vsftpd.conf.bak ] ||  cp /etc/vsftpd/vsftpd.conf{,.bak}
sed -i 's/\(pam_service_name=\).*/\1vsftpd.vusers/' /etc/vsftpd/vsftpd.conf
grep -q 'guest_enable=TRUE' /etc/vsftpd/vsftpd.conf \
&& grep -q 'guest_username=vuser' /etc/vsftpd/vsftpd.conf || cat >> /etc/vsftpd/vsftpd.conf << EOF
guest_enable=TRUE
guest_username=vuser
EOF

# 准备虚拟用户的家目录
dir='/zz'
[ -d $dir ] || mkdir -p $dir 
id vuser &> /dev/null && usermod -d ${dir}/vuser vuser &> /dev/null || useradd -d ${dir}/vuser vuser &> /dev/null

# 要求：1. 家目录没有写权限；2. 所有用户均有其它用户有rx权限
chmod 555 ${dir}/vuser &> /dev/null

# 准备一个公共可下载目录
[ -d ${dir}/vuser/pub ] || mkdir  -p ${dir}/vuser/pub

systemctl restart vsftpd.service

# 准备一个文件，登陆tom, jerry尝试下载，删除，上传等操作
# cp /etc/fstab /zz/vuser/pub/
# lftp tom@172.16.0.6:/pub> get fstab 
# 713 bytes transferred
# lftp tom@172.16.0.6:/pub> rm fstab 
# rm: Access failed: 550 Permission denied. (fstab)
# lftp tom@172.16.0.6:/pub> put issue
# put: Access failed: 550 Permission denied. (issue)
# ...
# 结果，只能下载(默认权限)，不能上传，不能删除；

# -------------- 配置 虚拟用户可分配权限 -------------- 
share_dir='/etc/vsftpd/vusers_config'
echo -e "vuser configure dir : \033[1;31m$share_dir\033[0m"
[ -d $share_dir ] || install -d $share_dir
grep -q "user_config_dir"  /etc/vsftpd/vsftpd.conf || echo "user_config_dir=$share_dir" >>  /etc/vsftpd/vsftpd.conf
 
# --------------配置上传、删除权限 -------------- 
install -d -o vuser -g vuser ${dir}/vuser/upload

while true; do
	echo -e 'configure exist user,  until input "\033[1;31mquit\033[0m"'
	read -p 'Enter a username: ' user
	[ "$user" == "quit" ] && break
	[ -f ${share_dir}/$user ] && users[${#users[@]}]=$user || continue
done

for i in ${users[@]}; do
echo "configure $i user permission....., Please input YES or NO, default is NO"
read -p 'download? ' d
[ "$d" = "YES" ] && permission[${#permission[@]}]='download'
[ "$d" != "YES" ] && d=NO
read -p 'upload? ' u
[ "$u" = "YES" ] && permission[${#permission[@]}]='upload'
[ "$u" != "YES" ] && u=NO
read -p 'mkdir? ' m
[ "$m" = "YES" ] && permission[${#permission[@]}]='mkdir'
[ "$m" != "YES" ] && m=NO
read -p 'writeable? ' w
[ "$w" = "YES" ] && permission[${#permission[@]}]='write'
[ "$w" != "YES" ] && w=NO
echo "-------------- 给${i}配置${permission[@]} --------------"
cat > $share_dir/${i} << EOF
anonymous_enable=$d
anon_upload_enable=$u
anon_mkdir_write_enable=$m
anon_other_write_enable=$w
anon_umask=022
EOF
[ $? -eq 0 ] && echo "OK"
done
 # 注释：anon_umask必须设置其它用户可读，否则创建的目录下的所有文件不可见;
