#!/bin/bash
#

# --------------------- prepare ------------------------- 
wget https://nginx.org/download/nginx-1.12.2.tar.gz
yum -y groupinstall "Development Tools" "Server Platform Development"
yum -y install pcre-devel openssl-devel
yum -y install zlib-devel libxml2-devel libxslt-devel gd-devel perl-devel GeoIP-devel perl-ExtUtils-Embed

# --------------------- Compling installation -----------
tar xf nginx-1.12.2.tar.gz 
cd nginx-1.12.2
./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-file-aio 
 make && make install

# -------------------- provide unit file ----------------
cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

# -------------------- post script ----------------
 systemctl daemon-reload
 useradd -r nginx
 install -d -o nginx -g nginx /var/lib/nginx/tmp/client_body
 systemctl start nginx.service
 systemctl status nginx.service
