#!/bin/bash
# Date: 2018/6/21
# Author: liangcheng.Song
# Description: OTT 服务管理工具、查看、编辑hls配置及黑白名单配置、在入口查看token、清理占空间的内核文件
#

#使用说明
usage() {
cat << EOF
    Usage: ottsrv.sh <OPTONS .... >
        --cms    start|stop|status    manage cms. tomcat
        --hls    start|stop|status    manage hls. pull stream
        --lts    start|stop|status    lts. transcoding
        --ctc    start|stop|status    ctc. vod transcoding
        --ctl    start|stop|status    ctl. vod transcoding
        --oms    start|stop|status    oms. only vod except transcoding.
        --vcc    start|stop|status    manage vcc. virutal channel.
        --gslb   start|stop|status    manage gslb. Entrance
            example：
              ottsrv.sh     --cms start|stop|status
              ottsrv.sh     --ctc --ctl --vcc --gslb ...    start|stop|status
        
        -ar, --after-reboot           start zabbix_agentd, automount, cms, hls, mysql.
        -iogl, --install-ott-general-license
        -va, --vod-all                start oms, ctc, ctl. (ctc and ctl are used to transcoding.)
        -vak, --kvod-all              stop oms, ctc, ctl. (ctc and ctl are used to transcoding.)
        -vas, --vod-all-status        status oms, ctc, ctl. (ctc and ctl are used to transcoding.)
        -a, --all                     start all modules.
        -ak, --kall                   stop all modules.
        -as, --all-status             stop all modules.
        -chc, -cat-h-c                cat /opt/starview/cdn/hls/cfg/hls_server.conf
        -vhc, -vim-h-c                vim /opt/starview/cdn/hls/cfg/hls_server.conf
            #####################################################
            # [Server]                                          #
            # HttpConnectNum = 2500  ##1G:default 800. 5G: 4000 #
            # HttpIoServicePoolSize = 100                       #
            #####################################################
        
        -vhw, -vim-h-w              vim /opt/starview/cdn/hls/cfg/white.xml
        -elt, -en-lo-token           lookup token at gslb
        -ccf, -clean-core-file       rm -f /opt/starview/cdn/hls/bin/core*
EOF
}

#检查第一个参数是不是被管理的几个服务名
check_() {
    if [  "$1" == "--cms" -o "$1" == "--hls" -o "$1" == "--lts" -o "$1" == "--ctc" -o "$1" == "--ctl" -o "$1" == "--oms" -o "$1" == "--vcc" -o "$1" == "--gslb" ]
	then
		init=1
	else
        usage
        exit 2
    fi    
}

#管理服务
start() {
    $prog_path/startup.sh
}
stop() {
    $prog_path/shutdown.sh
}
status() {
	ps axu | grep ${prog_path%/*} | grep -v 'grep' | sed '/ottsrv/d'
}

#对单个服务进行管理
one_prog() {
    prog=$( echo "$1" | tr -d '-')
	if [ "$prog" == "cms" ]; then
    	prog_path=/opt/starview/boss/$prog/bin
	else
    	prog_path=/opt/starview/cdn/$prog/bin
	fi

    case $2 in
        start)
            if [ `status $prog | wc -l` -ne 0 ]; then 
				echo -e "\033[1;32m$prog has started\033[0m"
			else
            	start $prog
			fi
            ;;
        stop)
            if [ ! `status $prog | wc -l` -ne 0 ]; then 
				echo -e "\033[1;31m$prog has stopped\033[0m"
			else
            	stop $prog
			fi
            ;;
        restart)
            stop $prog
            start $prog
            ;;
        status)
			status $prog
            if [ ! `status $prog | wc -l` -ne 0 ]; then 
				echo -e "\033[1;31m$prog has stopped.\033[0m"
			else
				echo -e "\033[1;32m$prog has started.\033[0m"
			fi
            ;;
        *)
            usage
            exit 3
    esac
}

main() {
    check_ $1
    one_prog $1 $2
}


#根据传递不同个数的参数，管理单个、多个服务
VOD=
ALL=
VALUE=
if [ -z "$1" ]; then
	usage
	exit 5
#单个服务
elif [ $# -eq 2 ]; then
    main $1 $2
#将常用的多个服务，使用一个选项管理
elif [ $# -eq 1 ]; then
    case $1 in
        -ar|--after-reboot)
            /etc/init.d/zabbix_agentd start
            /usr/local/zabbix/script/call/mountott
            test=("--cms" "--hls")
            for i in ${test[@]}; do
                main $i start
            done
            /opt/mysql/service/stop_mysql.sh;/opt/mysql/service/start_mysql.sh
            ;;
        -va|--vod-all)
			VOD=1
			VALUE=start
            ;;
        -vak|--kvod-all)
			VOD=1
			VALUE=stop
            ;;
		-vas|--vod-all-status)
			VOD=1
			VALUE=status
            ;;
		-as|--all-status)
			ALL=1
			VALUE=status
			;;
        -a|--all)
			ALL=1
			VALUE=start
			;;
        -ak|--kall)
			ALL=0
			VALUE=stop
			;;
		-chc|-cat-h-c)
			cat /opt/starview/cdn/hls/cfg/hls_server.conf
			;;
		-vhc|-vim-h-c)
			vim /opt/starview/cdn/hls/cfg/hls_server.conf
			;;
		-vhw|-vim-h-w)
			 vim /opt/starview/cdn/hls/cfg/white.xml
			 ;;
		-elt|-en-lo-token)
			cat /opt/starview/cdn/gslb/log/$(tail /opt/starview/cdn/gslb/log/log_serialno.ini)_*.log  | fgrep token | tail
			;;
		-ccf|-clean-core-file)
		    echo "/opt/starview/cdn/hls/bin/core*"
			ls /opt/starview/cdn/hls/bin/core*
			read -p 'delete them(yes/no)? ' select_
			[ -n "$select_" ] && [ "$select_" == "yes" ] && 	rm -f /opt/starview/cdn/hls/bin/core* 
			;;
		-iogl|--install-ott-general-license)
			cd /opt/starview/tools/install/;./install.sh
			ifcfgid=`ifconfig | cut -d' ' -f1 | sort -u | xargs | cut -d' ' -f1 | tr -d ":"` && cd /opt/starview/cdn && ./get_host_info -i $ifcfgid && sz /opt/starview/cdn/host_info
			;;
        *)
            usage
            exit 4
    esac
	if [ -n "$VOD" ]; then
            test=("--oms" "--ctc" "--ctl")
            for i in ${test[@]}; do
                main $i $VALUE
            done
			echo
			echo
            for j in ${test[@]}; do
                main $j status
            done
	fi

	if [ -n "$ALL" ]; then
            test=("--cms" "--hls" "--lts" "--vcc" "--oms" "--ctc" "--ctl")
            for i in ${test[@]}; do
                main $i $VALUE
            done
			echo
			echo
            for j in ${test[@]}; do
                main $j status
            done
	fi
#多个服务管理
else
	for k in $*; do
		case $k in
		start)
			value=$k
			;;
		stop)
			value=$k
			;;
		restart)
			value=$k
			;;
		status)
			value=$k
			;;
		esac
	done
	for j in $*; do
    	if [  "$j" == "--cms" -o "$j" == "--hls" -o "$j" == "--lts" -o "$j" == "--ctc" -o "$j" == "--ctl" -o "$j" == "--oms" -o "$j" == "--vcc" -o "$j" == "--gslb" ]; then
			main $j $value
		fi
	done
fi
