
use router;
CREATE TABLE if not exists `router_server`(
  `index_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '索引ID',
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  `name` varchar(15) NOT NULL DEFAULT '',
  `ip` varchar(20) NOT NULL DEFAULT '',
  `port` int(5) NOT NULL DEFAULT 0,
  `status` tinyint(2) NOT NULL DEFAULT 0,
  `is_new` boolean NOT NULL DEFAULT 0,
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `index_id` (`index_id`) USING BTREE
) DEFAULT CHARSET=utf8;

CREATE TABLE if not exists `router_title`(
  `index_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '索引ID',
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `name` varchar(15) NOT NULL DEFAULT 0,
  `begin_id` int(6) NOT NULL DEFAULT 0,
  `end_id` int(6) NOT NULL DEFAULT 0,
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `index_id` (`index_id`) USING BTREE
) DEFAULT CHARSET=utf8;

/*
agent_id是2
agent_id是1
INSERT INTO `router_title` VALUES (101, 10, '君海测试服', 1, 100, 0, 0);

INSERT INTO `router_server` VALUES (1, 1, 1, '外网测试服1', '118.89.165.224', 40001, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (2, 1, 2, '外网测试服2', '118.89.165.224', 40002, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (3, 1, 1, '本地1', '192.168.2.250', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (4, 1, 2, '本地2', '192.168.2.250', 56555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (5, 1, 3, '本地3', '192.168.2.250', 57555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (6, 1, 1, '吉昌', '192.168.2.243', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (7, 1, 1, '子鹏', '192.168.2.247', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (8, 1, 3, '测试', '', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (9, 1, 1, '版署测试服', '118.89.165.224', 40010, 1, FALSE, 0, 0);


INSERT INTO `router_title` VALUES (2, 2, '版署测试服', 1, 100, 0, 0);

INSERT INTO `router_server` VALUES (101, 10, 1, '君海测试服1', '118.89.165.224', 40010, 1, 1, 0, 0);

INSERT INTO `router_server` VALUES (12, 2, 2, '外网测试服2', '118.89.165.224', 40002, 1, FALSE, 0, 0);

INSERT INTO `router_server` VALUES (14, 2, 1, '本地1', '192.168.2.250', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (15, 2, 2, '本地2', '192.168.2.250', 56555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (16, 2, 3, '本地3', '192.168.2.250', 57555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (17, 2, 1, '吉昌', '192.168.2.243', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (18, 2, 1, '子鹏', '192.168.2.247', 55555, 1, FALSE, 0, 0);
INSERT INTO `router_server` VALUES (19, 2, 3, '测试', '', 55555, 1, FALSE, 0, 0);

INSERT INTO `router_server` VALUES (13, 2, 1, '版署测试服', '118.89.165.224', 40010, 1, FALSE, 0, 0);

*/