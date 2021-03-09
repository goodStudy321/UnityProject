#!/bin/bash
TARGET=$1
shift


update()
{
	cd /data/trunk/server/
	a=(
	'212.64.66.20 robot_901'
	'212.64.66.34 robot_902'
	'212.64.66.34 robot_903'
	'115.159.68.105 robot_905'
	)
	for i in "${a[@]}" ; do
		b=($i)
		IP=${b[0]}
		DEST=${b[1]}
		sh mgectl update_server local_1 $IP $DEST
	done
}

create()
{
	a=(
	'212.64.66.20 robot_901 0'
	'212.64.66.34 robot_902 1'
	'212.64.66.34 robot_903 2'
	)
	LEN=${#a[@]}
	Num=$1
	for i in "${a[@]}" ; do
		b=($i)
		IP=${b[0]}
		DEST=${b[1]}
		COUNTER=${b[2]}
		ssh $IP "cd /data/ranger_${DEST}/server/;sh mgectl exprs \"robot_misc:start_sec_robot(${Num}, ${LEN}, ${COUNTER}, 10, 200)\"" &
	done
	ssh "115.159.68.105" "sh /data/sh/get_monitor.sh ${Num}" &
}

## 收集数据用的脚本
## /usr/bin/dstat -tcmdnl 2 350 >> /data/logs/monitor/first_monitor_6.csv

stop()
{
	a=(
	'212.64.66.20 robot_901'
	'212.64.66.34 robot_902'
	'212.64.66.34 robot_903'
	)
	for i in "${a[@]}" ; do
		b=($i)
		IP=${b[0]}
		DEST=${b[1]}
		ssh $IP "cd /data/ranger_${DEST}/server/;sh mgectl exprs \"robot_misc:stop()\"" &
	done
	ssh "115.159.68.105" "ps aux | grep get_monitor |  awk '{print $2}' | xargs kill -9"
}

restart()
{
	stop
	IP="115.159.68.105"
	DEST="robot_905"
	ssh $IP "cd /data/ranger_${DEST}/server/;sh mgectl stop_yes;mysql -u ranger -pranger666666 -e \"drop database admin_$DEST;drop database ranger_$DEST; create database admin_$DEST;create database ranger_$DEST; use admin_$DEST;source /data/sh/admin.sql;\"; sh mgectl start"
}

auto()
{
	AutoArray=(1 2 3 4 5 6 7 8 9)
	for AutoNum in "${AutoArray[@]}" ; do
	   restart
	   sleep 50
	   create $AutoNum
	   sleep 750
	   ssh "115.159.68.105" "sh /data/ranger_robot_905/server/mgectl online >> /data/logs/monitor/$AutoNum.status"
	   ssh "115.159.68.105" "sh /data/ranger_robot_905/server/mgectl exprs \"lib_sys:i()\" >> /data/logs/monitor/$AutoNum.status"
	done
}

case $TARGET in
    update) update ;;
    create) create $*;;
	stop) stop $*;;
	restart) restart $*;;
	auto) auto $*;;
    *) custom_cmd $*;;
esac