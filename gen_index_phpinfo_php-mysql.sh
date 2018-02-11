#!/bin/bash
# Date: 2018/2/11
#
dir="$1"
dir=${dir%/}

get_ip() {
	local iface=$1
	ifconfig $1 | awk 'NR==2{print $2}'
}
cp_index() {
	local file=$1
	if [ ! -f ${dir}/$file ]; then
		echo "<h1>Web service on $ip</h1>" > ${dir}/$file
	fi
}
cp_phpinfo() {
	local file=$1
	if [ ! -f ${dir}/phpinfo.php ]; then
	echo "<html>
	<title>test page</title>
	<body>
		<h1>$ip</h1>
		<?php
			phpinfo();
		?>
	</body>
</html>" > ${dir}/$file
fi
}
cp_php-mysql() {
local file=$1
while true; do
	if [ ! -f ${dir}/$file ]; then
		read -p "Enter your mysql host: " mysql_host
		[ "$mysql_host" == "n" ] && break
		echo "$mysql_host" | egrep '(\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>\.?){4}' || continue
		read -p "Enter your mysql user: " mysql_user
		[ "$mysql_user" == "n" ] && break
		[ -z "$mysql_user" ] && continue
		read -p "Enter your mysql pass: " mysql_pass
		[ "$mysql_pass" == "n" ] && break

		echo "<?php
	\$conn = mysql_connect('$mysql_host','$mysql_user','$mysql_pass');
	if (\$conn)
		echo \"connect $mysql_host success\";
	else
		echo \"connect $mysql_host failure\";
?>" > ${dir}/$file && break
else
	break
fi
done
}
main() {
	local file=$1
	[ $# -ne 1 ] && return 1
	case $file in
	index.html)
		cp_index $file
		;;
	phpinfo.php)
		cp_phpinfo $file
		;;
	php-mysql.php)
		cp_php-mysql $file
		;;
	esac
}

# ---------------- pre config -----------------------------------------------------------------------------
[ $# -lt 1 ] && echo "Usage: $(basename $0) /PATH/TO/SOMEDIR" && exit 1	
[ -d $dir ] || mkdir -p $dir
rpm -q net-tools &> /dev/null || yum -d 0 -e 0 -y install net-tools
ifaces=$(ifconfig | awk -F: '/^[^[:space:]]/ && !/lo/{print $1}')
echo ${ifaces[@]}
read -p 'select a iface ' iface
! echo "${ifaces[@]}" | grep -q "$iface" &&  echo "No such interface" && exit 2
ip=$(get_ip $iface)
echo "current ip is : $ip"

# ---------------- copy file -------------------------------------------------------------------------------
files=("index.html" "phpinfo.php" "php-mysql.php")

# ------------------ ture files -----------------
for i in 0 1 2; do
	read -p "copy ${files[$i]}? " opt 
	[[ "$opt" =~ [yY] ]] && myfiles[${#myfiles[@]}]=${files[$i]}
done

# ----------------- copy files -----------------
for i in ${myfiles[@]}; do
	main $i
	[ $? -ne 0 ] && echo "error" && exit 
done
