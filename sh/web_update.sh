#!/bin/bash

## 默认是trunk目录
WEB_DIR=/webdata/wwwroot/web/
cd $WEB_DIR
/usr/bin/svn update

ARGS=$1
USER="www:www";

echo "args:1 ${ARGS}"
if [ $ARGS == "test" ]; then
	IP="118.89.165.224";
	DIR="/data/web/"
elif [ $ARGS == "center" ]; then
	IP="111.231.1.115";
	DIR="/webdata/wwwroot/web";
fi


## 数据库文件忽略
rsync -avpgo ${WEB_DIR} --exclude "router/application/config/database.php" --exclude ".svn" --exclude "doc" --exclude "mysql.php" ${IP}:${DIR}
ssh ${IP} chown ${USER} ${DIR}/* -R
