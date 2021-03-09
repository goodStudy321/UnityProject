#!/bin/bash
install_path=/usr/local/ElasticSearch
network_host='192.168.2.250' #must fix
group=elastic
user=elastic
elasticsearch=${install_path}/elasticsearch-6.3.1
logstash=${install_path}/logstash-6.3.2


#groupadd $group
#useradd $user -g $group
#
#wget -c https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.3.1.tar.gz
#
#tar -zxvf ./elasticsearch-6.3.1.tar.gz
#
#
#mkdir -p $install_path
#mv elasticsearch-6.3.1 $install_path/elasticsearch-6.3.1
#chown -R $group:$user $elasticsearch
#
#echo "export ES_HEAP_SIZE=1g" >> /etc/profile
#echo "export PATH=\$PATH:$elasticsearch/bin" >> /etc/profile
#source /etc/profile

#启动
#cd elasticsearch-<version>
#${elasticsearch}/bin/elasticsearch

#安装elasticsearch 插件 elasticsearch-sql
${elasticsearch}/bin/elasticsearch-plugin install https://github.com/NLPchina/elasticsearch-sql/releases/download/6.3.1.0/elasticsearch-sql-6.3.1.1.zip
exit 1

#增量同步MySQL数据到 Elasticsearch
yum install gem -y
rm -rf ./logstash-6.3.2
wget -c https://artifacts.elastic.co/downloads/logstash/logstash-6.3.2.tar.gz
tar -zxvf ./logstash-6.3.2.tar.gz

mv ./logstash-6.3.2 ${install_path}
${logstash}/bin/logstash-plugin install logstash-input-jdbc
gem source -l


wget -c https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.36/mysql-connector-java-5.1.36.jar
mv ./mysql-connector-java-5.1.36.jar ${logstash}/tools

#logstash 启动
#${logstash}/bin/logstash -f ./path/jdbc.conf






#yum install java-1.8.0-openjdk* -y



#解决办法：切换root账户 vim /etc/sysctl.conf
#
#增加一行  vm.max_map_count=655360
#
#接着执行 sysctl -p
#
#切回ES账户重新启动问题解决


#2. max file descriptors [4096] for elasticsearch process is too low, increase to at least [65536]
#解决：切换到root用户，编辑limits.conf 添加类似如下内容
# vi /etc/security/limits.conf
# 添加如下内容:
# * soft nofile 65536
# * hard nofile 131072
# * soft nproc 2048
# * hard nproc 4096



exit 1;

# 主节点 配置 ==================================================================
# IP [192.168.2.250]
network.host: 0.0.0.0
http.port: 9200
http.cors.enabled: true
http.cors.allow-origin: "*"

cluster.name: phantom_game
node.name: master
node.ingest: false
node.master: true
node.data: false

discovery.zen.ping.unicast.hosts: ["192.168.2.250"] #找到master节点

# 随从节点 1 ===================================================================
# IP [192.168.2.185]
network.host: 0.0.0.0
http.port: 9200
http.cors.enabled: true
http.cors.allow-origin: "*"

cluster.name: phantom_game
node.name: andychen
node.ingest: false
node.master: false
node.data: true

discovery.zen.ping.unicast.hosts: ["192.168.2.250"]

# 随从节点 2 ===================================================================
# IP [192.168.2.243]
network.host: 0.0.0.0
http.port: 9200
http.cors.enabled: true
http.cors.allow-origin: "*"

cluster.name: phantom_game
node.name: jichan
node.ingest: false
node.master: false
node.data: true

discovery.zen.ping.unicast.hosts: ["192.168.2.250"]



#https://github.com/siddontang/go-mysql-elasticsearch/blob/master/README.md
#https://www.linuxhub.org/?p=4665
#https://juejin.im/entry/58f827d78d6d8100587591c9





