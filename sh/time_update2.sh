#!/bin/bash
## 实际机器执行的方法
## 因为可能跨机器执行，所以脚本是分开的
SERVER_DIR=$1
IS_CLEAR=$2
shift
shift
TIME=$*
cd ${SERVER_DIR}
sh mgectl stop_yes
if [ $IS_CLEAR == "是" ]; then
	echo "${SERVER}: clear data"
	mysql -uroot -p"SLsl>2017409" -e "drop database ${SERVER};create database ${SERVER}"
else
	echo "${SERVER}: don't clear data"
fi

chmod 777 mgectl
if [[ -z ${TIME} ]];
then
    ./mgectl start
else
    faketime "${TIME}" ./mgectl start
fi