#!/bin/bash

# bash open_server FileName
# sh -x open_server.sh common.config
if [ $# -lt 1]; then
	echo "使用语法: bash open_server FileName"
	echo "示例 开新服 bash open_server common.config"
	exit
fi

get_value()
{   
    VALUE=`grep $1 ${Config} | grep -v "%" | awk -F"," '{print $2}' | awk -F"}" '{print $1}'| sed 's/"//g' | sed 's/ //g'`
    if [ "${VALUE}" != "" ] ; then    
        echo ${VALUE}
    else
        echo "$1 not exists"
    fi
}

FileName=$1
Config=/data/open_server/${FileName}
GameCode=`get_value game_code`
AgentCode=`get_value agent_code`
ServerID=`get_value server_id`
DestIP=`get_value server_ip`
ServerDir=/data/${GameCode}_${AgentCode}_${ServerID}/server/
SettingDir=${ServerDir}/setting
ssh $DestIP "mkdir -p ${SettingDir}"
scp -P22 ${Config} $DestIP:${SettingDir}
ssh $DestIP "cd ${SettingDir};mv ${FileName} common.config"
