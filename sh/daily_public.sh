#!/bin/bash
# 获取svn 版本号
function get_svn_version() {
    SVN_REV=`svn info $* | grep '最后修改的版本:' | awk '{print $2}'`
    if [ -z $SVN_REV ]; then
        SVN_REV=`svn info $* | grep 'Last Changed Rev:*'  | awk '{print $4}'`
    fi
    if [ -z $SVN_REV ]; then
        SVN_REV="0"
    fi  
    echo $SVN_REV
}

MAIN_DIR=$(cd `dirname $0`/../; pwd)
## 默认是trunk目录
SERVER_DIR=$MAIN_DIR/trunk/server
if [ $# -lt 1 ]; then
	ARGS="1"
else
	ARGS=$1
fi
echo "args:1 ${ARGS}"

if [ $ARGS == "1" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="local_1";
elif [ $ARGS == "2" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="local_2";
elif [ $ARGS == "跨服_1" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="cross_90001";
elif [ $ARGS == "中央服" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="center_99999";
elif [ $ARGS == "活动_1" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="local_91";
elif [ $ARGS == "活动_2" ]; then
	IP="127.0.0.1";
	FROM="local_1";
	DEST="local_92";
elif [ $ARGS == "and_活动测试服" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v13/server;
	IP="127.0.0.1";
	FROM="local_53";
	DEST="local_94";
elif [ $ARGS == "and_活动测试服2" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v13/server;
	IP="127.0.0.1";
	FROM="local_53";
	DEST="local_95";
elif [ $ARGS == "ios_活动测试服" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_ios_v7/server;
	IP="127.0.0.1";
	FROM="local_67";
	DEST="local_97";
elif [ $ARGS == "ios_活动测试服2" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_ios_v7/server;
	IP="127.0.0.1";
	FROM="local_67";
	DEST="local_98";
elif [ $ARGS == "外网中央服" ]; then
	IP="118.89.165.224";
	FROM="local_1";
	DEST="center_99999";
elif [ $ARGS == "wai_1" ]; then
	IP="118.89.165.224";
	FROM="local_1"
	DEST="local_101";
elif [ $ARGS == "wai_2" ]; then
	IP="118.89.165.224";
	FROM="local_1";
	DEST="local_102";
elif [ $ARGS == "ol_and_v6" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v6/server;
	IP="127.0.0.1";
	FROM="local_56";
	DEST="local_56";
elif [ $ARGS == "wai_ol_and_v6" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v6/server;
	IP="118.89.165.224";
	FROM="local_56";
	DEST="local_156";
elif [ $ARGS == "ol_and_v7" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v7/server;
	IP="127.0.0.1";
	FROM="local_57";
	DEST="local_57";
elif [ $ARGS == "wai_ol_and_v7" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v7/server;
	IP="118.89.165.224";
	FROM="local_57";
	DEST="local_157";
elif [ $ARGS == "ol_and_v10" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v10/server;
	IP="127.0.0.1";
	FROM="local_50";
	DEST="local_50";
elif [ $ARGS == "ol_and_v11" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v11/server;
	IP="127.0.0.1";
	FROM="local_51";
	DEST="local_51";
elif [ $ARGS == "ol_and_v12" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v12/server;
	IP="127.0.0.1";
	FROM="local_52";
	DEST="local_52";
elif [ $ARGS == "ol_and_v13" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v13/server;
	IP="127.0.0.1";
	FROM="local_53";
	DEST="local_53";
elif [ $ARGS == "wai_ol_and_v10" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v10/server;
	IP="118.89.165.224";
	FROM="local_50";
	DEST="local_150";
elif [ $ARGS == "wai_ol_and_v11" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v11/server;
	IP="118.89.165.224";
	FROM="local_51";
	DEST="local_151";
elif [ $ARGS == "wai_ol_and_v12" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v12/server;
	IP="118.89.165.224";
	FROM="local_52";
	DEST="local_152";	
elif [ $ARGS == "wai_ol_and_v13" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v13/server;
	IP="118.89.165.224";
	FROM="local_53";
	DEST="local_153";
elif [ $ARGS == "ol_ios_v13" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_ios_v13/server;
	IP="127.0.0.1";
	FROM="local_63";
	DEST="local_63";	
elif [ $ARGS == "wai_ol_ios_v13" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v13/server;
	IP="118.89.165.224";
	FROM="local_53";
	DEST="local_163";	
elif [ $ARGS == "ol_ios_v7" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_ios_v7/server;
	IP="127.0.0.1";
	FROM="local_67";
	DEST="local_67";
elif [ $ARGS == "ol_and_v9" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_and_v9/server;
	IP="127.0.0.1";
	FROM="local_59";
	DEST="local_59";	
elif [ $ARGS == "wai_ol_ios_v7" ]; then
	SERVER_DIR=$MAIN_DIR/branch/ol_ios_v7/server;
	IP="118.89.165.224";
	FROM="local_67";
	DEST="local_167";
elif [ $ARGS == "pingce_1" ]; then
	IP="118.89.165.224";
	FROM="local_1";
	DEST="pingce_1";
elif [ $ARGS == "玩家测试" ]; then
	IP="115.159.68.105";
	FROM="local_1";
	DEST="junhai_31";
fi
cd $SERVER_DIR
/usr/bin/svn revert -R $SERVER_DIR
/usr/bin/svn update
NEW_SV=`get_svn_version $SERVER_DIR`
sed -i "s/-[0-9]*/-${NEW_SV}/" server_version.txt 

make all
ret=`echo $?`
echo "ret: ${ret}"
if [ ${ret} -ne 0 ]; then
	echo "compile fail";
	exit 1
fi

## 发布trunk时更新web
if [ $ARGS == "1" ]; then
	WEB_DIR=$SERVER_DIR/../web/admin/files/config/
	/usr/bin/svn revert -R $WEB_DIR
	/usr/bin/svn up $WEB_DIR
	GIT_MASTER_DIR=/data/master/files/config/
	cd $GIT_MASTER_DIR
	git reset --hard HEAD
	git pull
	cp -rf ${WEB_DIR}/* ${GIT_MASTER_DIR}
	git add .
	git commit -m "add"
	git push -u origin master
fi

cd $SERVER_DIR
svn ci server_version.txt -m "提交版本号文件"


##else
##	echo "web 目录不存在"
##fi

echo $FROM
echo $IP
echo $DEST
sh mgectl "update_server" $FROM $IP $DEST
if [ $? != 0  ]; then
	echo "$DEST 启动失败"
	exit 1
fi

## 发布trunk时更新跨服
if [ $ARGS == "1" ]; then
	sh mgectl "update_server" $FROM $IP "cross_90001"
	if [ $? != 0  ]; then
		echo "cross_90001 启动失败"
		exit 1
	fi
fi
