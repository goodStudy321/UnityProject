#!/bin/bash

## 机器
mongo_list=("192.168.2.243" "192.168.2.244" "192.168.2.245")

## 配置端启动
conifg_start='mongod -f /data/mongodb/conf/config.conf'
for i in "${!mongo_list[@]}"; do 
    ssh -p 22 ${mongo_list[$i]} $conifg_start
done

## 单机执行命令
MongoDB='mongo 192.168.2.243:21000'
$MongoDB <<EOF
config = {
	_id : "configs",
    members : [
        {_id : 0, host : "192.168.2.243:21000" },
		{_id : 1, host : "192.168.2.244:21000" },
		{_id : 2, host : "192.168.2.245:21000" }
    ]
}
rs.initiate(config)
exit;
EOF

sleep 5

## 副本集启动
share_1='mongod -f /data/mongodb/conf/shard1.conf'
share_2='mongod -f /data/mongodb/conf/shard2.conf'
share_3='mongod -f /data/mongodb/conf/shard3.conf'

for i in "${!mongo_list[@]}"; do 
    ssh -p 22 ${mongo_list[$i]} $share_1
	ssh -p 22 ${mongo_list[$i]} $share_2
	ssh -p 22 ${mongo_list[$i]} $share_3
	sleep 5
done

## initiate
MongoDB2='mongo 192.168.2.243:27001'
$MongoDB2 <<EOF
use admin
config = {
    _id : "shard1",
     members : [
         {_id : 0, host : "192.168.2.243:27001"},
         {_id : 1, host : "192.168.2.244:27001"},
         {_id : 2, host : "192.168.2.245:27001"}
     ]
}
rs.initiate(config)
exit;
EOF

MongoDB3='mongo 192.168.2.243:27002'
$MongoDB3 <<EOF
use admin
config = {
    _id : "shard2",
     members : [
         {_id : 0, host : "192.168.2.243:27002"},
         {_id : 1, host : "192.168.2.244:27002"},
         {_id : 2, host : "192.168.2.245:27002"}
     ]
 }
rs.initiate(config);
exit;
EOF

MongoDB4='mongo 192.168.2.243:27003'
$MongoDB4 <<EOF
use admin
config = {
    _id : "shard3",
     members : [
         {_id : 0, host : "192.168.2.243:27003"},
         {_id : 1, host : "192.168.2.244:27003"},
         {_id : 2, host : "192.168.2.245:27003"}
     ]
 }
rs.initiate(config);

exit;
EOF


## 路由服务
mongo_router='mongos -f /data/mongodb/conf/mongos.conf'
for i in "${!mongo_list[@]}"; do 
	ssh -p 22 ${mongo_list[$i]} $mongo_router
done

MongoDB='mongo 192.168.2.243:20000'

$MongoDB <<EOF
use admin
sh.addShard("shard1/192.168.2.243:27001,192.168.2.244:27001,192.168.2.245:27001")
sh.addShard("shard2/192.168.2.243:27002,192.168.2.244:27002,192.168.2.245:27002")
sh.addShard("shard3/192.168.2.243:27003,192.168.2.244:27003,192.168.2.245:27003")
#查看集群状态
sh.status()

exit;
EOF
