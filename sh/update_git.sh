#!/bin/bash
# 推送本地代码至git

TOKEN='fQVLNiTXbAHGdc0EYQdXJYSMxYg0AQt2k+33oJyvpls='  #webhook token
ARGS=$1

echo "args:1 ${ARGS}"
if [ $ARGS == "1" ]; then
	FROM_VERSION="local_1";
	TO_VERSION="trunk";
elif [ $ARGS == "ol_ios_v7" ]; then
	FROM_VERSION="local_67";
	TO_VERSION="ios_release_1";
elif [ $ARGS == "ol_and_v11" ]; then
	FROM_VERSION="local_51";
	TO_VERSION="and_v11";
elif [ $ARGS == "ol_and_v12" ]; then
    FROM_VERSION="local_52";
    TO_VERSION="and_v12";
elif [ $ARGS == "ol_and_v13" ]; then
    FROM_VERSION="local_53";
    TO_VERSION="and_v13";
elif [ $ARGS == "ol_ios_v13" ]; then
    FROM_VERSION="local_63";
    TO_VERSION="ios_v13";
elif [ $ARGS == "ol_and_v10" ]; then
	FROM_VERSION="local_50";
	TO_VERSION="and_v10";
fi
FROM_DIR="/data/ranger_${FROM_VERSION}/server/";
TO_DIR="/data/release/${TO_VERSION}/";
cd $TO_DIR
git fetch --all
git reset --hard origin/master
git rm -rf $TO_DIR/{config,ebin,script}
cp -rf ${FROM_DIR}/{config,ebin,mgectl,script,user_default.beam,server_version.txt} $TO_DIR 
mkdir -p ${TO_DIR}/setting/
git add .
git commit -m "daily public commit code"
git push -u origin master


#1. gitlab 的webhook不稳定，所以直接在这里调api (add by andychen)
echo `curl -s -H "x-gitlab-event:Push Hook" -H "x-gitlab-token:${TOKEN}" -XPOST http://api.phantom-u3d001.com/index/index/webhook?repo_name=${TO_VERSION} | iconv -f UTF-8 -t gbk`
echo `curl -s -H "x-gitlab-event:Push Hook" -H "x-gitlab-token:${TOKEN}" -XPOST http://test.api.phantom-u3d001.com/index/index/webhook?repo_name=${TO_VERSION} | iconv -f UTF-8 -t gbk`

#2. 游戏物理服务器上的仓库用webhook来通知更新，但是内网开发环境用不了webhook，所以用cp代码来做内网开发环境代码的更新 (add by andychen)
REPO_DIR=/var/git.shenlongyx.com/${TO_VERSION}
mkdir -p ${REPO_DIR}
cp -rf ${TO_DIR}. ${REPO_DIR}
