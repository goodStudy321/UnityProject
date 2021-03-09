#!/bin/bash

## 机器列表
mongo_list=("192.168.2.243" "192.168.2.244" "192.168.2.245")

TARGET=$1
shift

config_start='mongod -f /data/mongodb/conf/config.conf'
shard1='mongod -f /data/mongodb/conf/shard1.conf'
shard2='mongod -f /data/mongodb/conf/shard2.conf'
shard3='mongod -f /data/mongodb/conf/shard3.conf'
router='mongos -f /data/mongodb/conf/mongos.conf'
start_list=($config_start $shard1 $shard2 $shard3 $router)

stop_mongod='killall mongod'
stop_mongos='killall mongos'

help()
{
	echo '使用说明'
    echo '基本语法: ${0} 功能指令 [option]'
    echo '命令模块：'
    echo 'help                      显示当前帮助内容'
    echo '-------------------------------------------------------'
    echo 'start                     开启monogo进程'
	echo 'stop                      关闭monogo进程'
}

start_mongo()
{
	for i in "${!mongo_list[@]}"; do 
		ssh -p 22 ${mongo_list[$i]} $config_start
	done
	sleep 3 
	
	for i in "${!mongo_list[@]}"; do
		ssh -p 22 ${mongo_list[$i]} $shard1
	done
	sleep 3 
	
	for i in "${!mongo_list[@]}"; do
		ssh -p 22 ${mongo_list[$i]} $shard2
	done
	sleep 3 
	
	for i in "${!mongo_list[@]}"; do
		ssh -p 22 ${mongo_list[$i]} $shard3
	done
	sleep 3 
	
	for i in "${!mongo_list[@]}"; do
		ssh -p 22 ${mongo_list[$i]} $router
	done
	sleep 3 
}

stop_mongo()
{
	for i in "${!mongo_list[@]}"; do 
		ssh -p 22 ${mongo_list[$i]} $stop_mongod
		ssh -p 22 ${mongo_list[$i]} $stop_mongos
	done
}

debug_mongo()
{
	mongo --port 20000
}

case $TARGET in
	start) start_mongo $*;;
    stop) stop_mongo $*;;
	debug) debug_mongo $*;;
    *) help $*;;
esac
