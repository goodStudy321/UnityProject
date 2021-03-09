#!/bin/bash
## jenkins调用脚本
SERVER_ARGS=$1
IS_CLEAR=$2
shift
shift
TIME=$*
echo "args: ${SERVER_ARGS}  ${TIME} ${IS_CLEAR}"
IP="127.0.0.1"
if [ $SERVER_ARGS == "活动_1" ]; then
	SERVER="ranger_local_91"
elif [ $SERVER_ARGS == "活动_2" ]; then
	SERVER="ranger_local_92"
elif [ $SERVER_ARGS == "and_活动测试服" ]; then
	SERVER="ranger_local_94"
elif [ $SERVER_ARGS == "and_活动测试服2" ]; then
	SERVER="ranger_local_95"	
elif [ $SERVER_ARGS == "ios_活动测试服" ]; then
	SERVER="ranger_local_97"
elif [ $SERVER_ARGS == "ios_活动测试服2" ]; then
	SERVER="ranger_local_98"
elif [ $SERVER_ARGS == "外网1" ]; then
	IP="118.89.165.224"
	SERVER="ranger_local_101"	
elif [ $SERVER_ARGS == "外网2" ]; then
	IP="118.89.165.224"
	SERVER="ranger_local_102"
elif [ $SERVER_ARGS == "外网v11" ]; then
	IP="118.89.165.224"
	SERVER="ranger_local_151"
elif [ $SERVER_ARGS == "v12-test" ]; then
	IP="115.159.68.105"
	SERVER="ranger_junhaiand_69901"	
fi
SERVER_DIR=/data/${SERVER}/server/

CMD="sh /data/sh/time_update2.sh ${SERVER_DIR} ${IS_CLEAR} ${TIME}"
ssh $IP $CMD

