/*
	先创建数据库
*/	
create database if not exists router;
Use router;

/*
	创建表
*/
CREATE TABLE IF NOT EXISTS `server` (
  `id` int(11) NOT NULL COMMENT '服务器id' KEY,
  `name` varchar(50) COMMENT '服务器名字',
  `status` varchar(50) COMMENT '服务器状态',
  `ip` varchar(50) COMMENT 'ip',
  `port` int(11) COMMENT '端口',
  `num` int(11) COMMENT '服务器人数'
) DEFAULT CHARSET=utf8 COMMENT='服务器状态表';
