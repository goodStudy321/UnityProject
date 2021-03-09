#!/usr/bin/env escript
##----------------------------------------------------------
## 离线撤机脚本，主要合并数据库
## QingliangCn 2011.7.10
##----------------------------------------------------------
chmod 500 /root/.erlang.cookie

## 获取agent_code和server_id
SHELL_DIR=`cd $(dirname $0)/../..; pwd`
CONFIG_LIST=`escript $SHELL_DIR/script/tool/escript_tool.es $SHELL_DIR get_common_config agent_code server_id game_code`
Array=($(tr " " " " <<< $CONFIG_LIST))
AGENT_CODE=${Array[0]}
SERVER_ID=${Array[1]}
GAME_CODE=${Array[2]}


## 根目录设置
BASE_DIR="/data/${GAME_CODE}_${AGENT_CODE}_${SERVER_ID}"
EBIN_DIR=$BASE_DIR/server/ebin
MNESIA_DIR="/data/database/mnesia/${GAME_CODE}_for_cheji_${AGENT_CODE}_${SERVER_ID}/${SERVER_TYPE}/"

mkdir -p ${MNESIA_DIR}

## 获取master_host
if [ "$#" -ge 1 ]; then
	MASTER_HOST="$1"
else
    case `uname -n` in
    arch-server)  LAN="ens32";;
    yxp-archlinux) LAN="ens33";;
    *)
         case `uname` in
               Linux)  LAN="eth0";;
               Darwin) LAN="en0";;
         esac
    esac
	MASTER_HOST=$(/sbin/ifconfig ${LAN}|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d 'addr:')
fi
/usr/local/bin/erl -name ${GAME_CODE}_${AGENT_CODE}_${SERVER_ID}_${SERVER_TYPE}@$MASTER_HOST -pa $EBIN_DIR/  -server_type $SERVER_TYPE -mnesia dir \"$MNESIA_DIR\" -server_root $BASE_DIR/server/ -s common_cheji reset_db_schema -noshell -s erlang halt

