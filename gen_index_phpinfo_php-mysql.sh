#!/bin/bash
#
file=0

[ -z "$1" ] && echo "Usage: $(basename $0) /PATH/TO/SOMEDIR" && exit 1	
rpm -q net-tools &> /dev/null || yum -y install net-tools
ip=$(ifconfig ens3 | awk 'NR==2{print $2}')

[ -f ${1}/index.html -a -f ${1}/phpinfo.php -a  ${1}/php-mysql.php ] && echo " all exists" && echo "
1) index.html
2) phpinfo.php
3) php-mysql.php
" &&  read -p 'remove a file ' file
[ $file -eq 1 ] && rm -f ${1}/index.html
[ $file -eq 2 ] && rm -f ${1}/phpinfo.php
[ $file -eq 3 ] && rm -f ${1}/php-mysql.php

if [ ! -f ${1}/index.html ]; then
	read -p "copy index.html to $1? " copy1
	[[ "$copy1" =~ ^[yY]$ ]] && echo "<h1>Web service on $ip</h1>" > ${1}/index.html
fi

if [ ! -f ${1}/phpinfo.php ]; then
	read -p "copy phpinfo.php to $1? " copy2
	[[ "$copy2" =~ ^[yY]$ ]] && echo "
<html>
	<title>test page</title>
	<body>
		<h1>$ip</h1>
		<?php
			phpinfo();
		?>
	</body>
	
</html>" > ${1}/phpinfo.php
fi

	while true; do
if [ ! -f ${1}/php-mysql.php ]; then
	read -p "copy php-mysql.php to $1? " copy3
		read -p "Enter your mysql host: " mysql_host
			[ "$mysql_host" == "n" ] && break
			echo "$mysql_host" | egrep '(\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>\.?){4}' || continue
		read -p "Enter your mysql user: " mysql_user
			[ "$mysql_user" == "n" ] && break
			[ -z "$mysql_user" ] && continue
		read -p "Enter your mysql pass: " mysql_pass
			[ "$mysql_pass" == "n" ] && break
	[[ "$copy3" =~ ^[yY]$ ]] && echo "
<?php
	\$conn = mysql_connect('$mysql_host','$mysql_user','$mysql_pass');
	if (\$conn)
		echo "connect $mysql_host success";
	else
		echo "connect $mysql_host failure";
?>" > ${1}/php-mysql.php && break
fi
	done
