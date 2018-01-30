#!/bin/bash
# 
# Date: 2018/1/30
#

trap 'exit' INT

yum -y install vsftpd mariadb-server mariadb-devel pam-devel
yum -y groupinstall "Development Tools" "Server Platform Development"


until [ -f /usr/lib64/security/pam_mysql.so ]; do
    [ -f pam_mysql-0.7RC1.tar.gz ] || wget http://prdownloads.sourceforge.net/pam-mysql/pam_mysql-0.7RC1.tar.gz
    [ -d pam_mysql-0.7RC1 ] || tar xf pam_mysql-0.7RC1.tar.gz
    cd pam_mysql-0.7RC1/
    ./configure --with-mysql=/usr --with-pam=/usr --with-pam-mods-dir=/usr/lib64/security 
    make 
    make install
done

until mysql -uvsftpd -h127.0.0.1 -pvsftpd -e 'SELECT now()'; do
    grep -q 'skip_name_resolve=ON' /etc/my.cnf.d/server.cnf \
    && grep -q 'innodb_file_per_table=ON' /etc/my.cnf.d/server.cnf \
    && grep -q 'log_bin=mysql-bin' /etc/my.cnf.d/server.cnf || sed -i '/\[server\]/a skip_name_resolve=ON\ninnodb_file_per_table=ON\nlog_bin=mysql-bin' /etc/my.cnf.d/server.cnf 

    systemctl restart mariadb.service

    mysql -uroot -hlocalhost  -e "CREATE DATABASE vsftpd;" \
    && mysql -uroot -hlocalhost  -e "GRANT ALL ON vsftpd.* TO 'vsftpd'@'127.0.0.1' IDENTIFIED BY 'vsftpd';" \
    && mysql -uroot -hlocalhost  -e "CREATE TABLE vsftpd.users(id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(60) NOT NULL, password CHAR(48) NOT NULL, UNIQUE KEY(name));"\
    && mysql -uroot -hlocalhost  -e "INSERT INTO vsftpd.users(name,password) VALUES ('tom',PASSWORD('magedu')),('jerry',PASSWORD('jerry'));"

done
[ -s /etc/pam.d/vsftpd.vusers ] || cat > /etc/pam.d/vsftpd.vusers << EOF
auth required /usr/lib64/security/pam_mysql.so user=vsftpd passwd=vsftpd host=127.0.0.1 db=vsftpd table=users usercolumn=name passwdcolumn=password crypt=2
account required /usr/lib64/security/pam_mysql.so user=vsftpd passwd=vsftpd host=127.0.0.1 db=vsftpd table=users usercolumn=name passwdcolumn=password crypt=2
EOF

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
id vuser && usermod -d ${dir}/vuser vuser || useradd -d ${dir}/vuser vuser

# 要求：1. 家目录没有写权限；2. 所有用户均有其它用户有rx权限
chmod 555 ${dir}/vuser

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
# 结果，只能下载，不能上传，不能删除；

# -------------- 配置 虚拟用户可分配权限 -------------- 
share_dir='/etc/vsftpd/vusers_config'
[ -d $share_dir ] || install -d $share_dir
grep -q "user_config_dir"  /etc/vsftpd/vsftpd.conf || echo "user_config_dir=$share_dir" >>  /etc/vsftpd/vsftpd.conf
 
# --------------配置上传、删除权限 -------------- 
install -d -o vuser -g vuser ${dir}/vuser/upload
read -p 'username: ' userName
[ -n "$userName" ] || exit


read -p 'download? ' d
[ "$d" != "YES" ] && d=NO
read -p 'upload? ' u
[ "$u" != "YES" ] && u=NO
read -p 'mkdir? ' m
[ "$m" != "YES" ] && m=NO
read -p 'writeable? ' w
[ "$w" != "YES" ] && w=NO

echo "-------------- 给$userName配置上传、删除权限 --------------"
cat > $share_dir/$userName << EOF
anonymous_enable=$d
anon_upload_enable=$u
anon_mkdir_write_enable=$m
anon_other_write_enable=$w
anon_umask=022
EOF
[ $? -eq 0 ] && echo "OK"

# 注释：anon_umask必须设置其它用户可读，否则创建的目录下的所有文件不可见;

