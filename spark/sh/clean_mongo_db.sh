#!/bin/bash

## 机器
mongo_list=("192.168.2.243" "192.168.2.244" "192.168.2.245")

## 副本集启动
share_1='pkill mongo;rm -rf /data/mongodb/shard1;mkdir -p /data/mongodb/shard1;mkdir -p /data/mongodb/shard1/data;mkdir -p /data/mongodb/shard1/log'
share_2='pkill mongo;rm -rf /data/mongodb/shard2;mkdir -p /data/mongodb/shard2;mkdir -p /data/mongodb/shard2/data;mkdir -p /data/mongodb/shard2/log'
share_3='pkill mongo;rm -rf /data/mongodb/shard3;mkdir -p /data/mongodb/shard3;mkdir -p /data/mongodb/shard3/data;mkdir -p /data/mongodb/shard3/log'
common='rm -rf /data/mongodb/config;mkdir -p /data/mongodb/config/data;mkdir -p /data/mongodb/config/log'

for i in "${!mongo_list[@]}"; do 
    ssh -p 22 ${mongo_list[$i]} $share_1
	ssh -p 22 ${mongo_list[$i]} $share_2
	ssh -p 22 ${mongo_list[$i]} $share_3
	ssh -p 22 ${mongo_list[$i]} $common
done

