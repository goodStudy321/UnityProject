#!/bin/bash
ARGS=$1
echo "args:1 ${ARGS}"
if [ $ARGS == "大熊" ]; then
	IP="127.0.0.1";
	SERVER_DIR="/mnt/daxiong_share/";
	SERVER_ID=101;
elif [ $ARGS == "昭齐" ]; then
	IP="127.0.0.1";
	SERVER_DIR="/mnt/zhaoqi_share/";
	SERVER_ID=102;
elif [ $ARGS == "陈萍" ]; then
	IP="127.0.0.1";
	SERVER_DIR="/mnt/chenping_share/";
	SERVER_ID=103;
fi

cd $SERVER_DIR
make all
ret=`echo $?`
echo "ret: ${ret}"
if [ ${ret} -ne 0 ]; then
	echo "compile fail";
	exit 1
fi

echo $IP
echo $SERVER_ID
sh mgectl "update_server" $IP $SERVER_ID
