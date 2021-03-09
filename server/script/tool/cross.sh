#!/usr/bin/env bash

build_env()
{
    DIR=$1
    FROM_DIR=$2
    /bin/rm -rf /data/$DIR/
    mkdir /data/$DIR
    mkdir /data/$DIR/server
    mkdir /data/$DIR/server/setting
    if [ "$DIR" == 'ranger_cross_90001' ]; then
        echo "{id, \"local_cross_90001\"}." > /data/$DIR/server/setting/common.config
    else
        echo "{id, \"local_center_99999\"}." > /data/$DIR/server/setting/common.config
    fi
    cd /data/$DIR/server/
    /bin/ln -s /data/$FROM_DIR/server/ebin /data/$DIR/server/ebin
    /bin/ln -s /data/$FROM_DIR/server/config /data/$DIR/server/config
    /bin/ln -s /data/$FROM_DIR/server/mgectl /data/$DIR/server/mgectl
    /bin/ln -s /data/$FROM_DIR/server/script /data/$DIR/server/script
    /bin/ln -s /data/$FROM_DIR/server/server_version.txt /data/$DIR/server/server_version.txt
    /bin/ln -s /data/$FROM_DIR/server/user_default.beam /data/$DIR/server/user_default.beam
}

if [ $# -lt 1 ]; then
	ARGS="ranger_local_1"
else
	ARGS=$1
fi

build_env ranger_cross_90001 $ARGS
build_env ranger_center_99999 $ARGS