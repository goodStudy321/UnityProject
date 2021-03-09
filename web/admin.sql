
-- 角色创建表
CREATE TABLE if not exists `log_role_create`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `account_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '帐号',
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `sex` tinyint NOT NULL DEFAULT 0 COMMENT '性别',
  `category` tinyint NOT NULL DEFAULT 0 COMMENT '职业',
  `imei` varchar(50) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT 'IMEI',
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色创建表';

-- 角色道具消耗表
CREATE TABLE if not exists `log_item`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `action` int(6) NOT NULL DEFAULT 0 COMMENT '行为',
  `type_id` int NOT NULL DEFAULT 0 COMMENT '道具id',
  `num` int(5) NOT NULL DEFAULT 0 COMMENT '数量',
  `bind` boolean NOT NULL DEFAULT TRUE COMMENT '是否绑定',
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE,
  KEY `time` (`time`) USING BTREE,
  KEY `action` (`action`) USING BTREE,
  KEY `type_id` (`type_id`)
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色道具消耗表';

-- 角色铜钱消耗表
CREATE TABLE if not exists `log_silver` (
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `action` int(6) NOT NULL DEFAULT 0 COMMENT '行为',
  `silver` bigint NOT NULL DEFAULT 0 COMMENT '操作铜钱',
  `remain_silver` bigint NOT NULL DEFAULT 0 COMMENT '剩余铜钱',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色铜钱消耗表';

-- 角色元宝消耗表
CREATE TABLE if not exists `log_gold`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `action` int(6) NOT NULL DEFAULT 0 COMMENT '行为',
  `gold` bigint NOT NULL DEFAULT 0 COMMENT '操作元宝',
  `bind_gold` bigint NOT NULL DEFAULT 0 COMMENT '操作绑定元宝',
  `remain_gold` bigint NOT NULL DEFAULT 0 COMMENT '剩余元宝',
  `remain_bind_gold` bigint NOT NULL DEFAULT 0 COMMENT '剩余绑定元宝',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色元宝消耗表';

-- 角色积分消耗表
CREATE TABLE if not exists `log_score`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `action` int(6) NOT NULL DEFAULT 0 COMMENT '行为',
  `score_key` int(6) NOT NULL DEFAULT 0 COMMENT '积分类型',
  `score` int NOT NULL DEFAULT 0 COMMENT '操作绑定元宝',
  `remain_score` int NOT NULL DEFAULT 0 COMMENT '剩余积分',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色积分消耗表';

-- 角色登录表
CREATE TABLE if not exists `log_role_login`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `account_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '帐号',
  `imei` varchar(50) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT 'IMEI',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8  ENGINE=MyISAM COMMENT='角色登录表';

-- 角色登出表
CREATE TABLE if not exists `log_role_logout`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
	`account_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '帐号',
	`online_time` int(10) NOT NULL DEFAULT 0 COMMENT '在线时间',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色登出表';

-- 角色状态表
CREATE TABLE if not exists `log_role_status`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `role_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '角色名',
  `uid` varchar(50) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT 'UID',
  `account_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '帐号',
  `role_level` int(4) NOT NULL DEFAULT 0 COMMENT '角色等级',
  `role_vip_level` int(4) NOT NULL DEFAULT 0 COMMENT 'VIP等级',
  `category` tinyint NOT NULL DEFAULT 0 COMMENT '职业',
  `power` int(16) NOT NULL DEFAULT 0 COMMENT '战斗力',
  `gold` int(16) NOT NULL DEFAULT 0 COMMENT '元宝',
  `create_time` int(11) NOT NULL DEFAULT 0 COMMENT '角色创建时间',
  `last_login_time` int(11) NOT NULL DEFAULT 0 COMMENT '上次登录时间',
  `last_login_ip` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '上次登录IP',
  `map_id` int(10) NOT NULL DEFAULT 0 COMMENT '地图ID',
  `is_online` boolean NOT NULL DEFAULT TRUE COMMENT '是否在线',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `role_id` (`role_id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色状态表';

-- 在线统计表
CREATE TABLE if not exists `log_online`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,

  `channel_id` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT 0 COMMENT '在线人数', -- "0|channel_id|...." 0表示全服在线 
  `online_num` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT 0 COMMENT '在线人数', -- "Num1|Num2|...."

  `year` smallint(5) NOT NULL DEFAULT 0 COMMENT '年',
  `month` tinyint(3) NOT NULL DEFAULT 0 COMMENT '月',
  `day` tinyint(3) NOT NULL DEFAULT 0 COMMENT '日',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='在线统计表';

-- 意见反馈
CREATE TABLE if not exists `log_feedback` (
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
	
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`role_name` varchar(255) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色名',
	`account_name` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '账号',
	`feedback_type` tinyint(2) DEFAULT '1' COMMENT '类型，1.建议',
	`status` tinyint(2) DEFAULT '0' COMMENT '回复状态，默认0未回复',
	`title` varchar(50) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '标题',
	`content` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '反馈内容',
	`back_content` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '回复人',
	`back_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '回复人',
	`back_time` int(11) DEFAULT NULL COMMENT '回复时间',
	
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='意见反馈表';

-- 养成功能表
CREATE TABLE if not exists `log_role_nurture`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`god_weapon_level` int(5) DEFAULT '0' COMMENT '神兵等级',
	`god_weapon_skins` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '神兵皮肤',
	`wing_level` int(5) DEFAULT '0' COMMENT '翅膀等级',
	`wing_skins` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '翅膀皮肤',
	`magic_weapon_level` int(5) DEFAULT '0' COMMENT '法宝等级',
	`magic_weapon_skins` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '法宝皮肤',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `role_id` (`role_id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='养成功能表';

-- 问卷调查表
CREATE TABLE if not exists `log_role_survey`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`survey_id` int(10) DEFAULT '0' COMMENT '问卷ID',
	`texts` varchar(2555) CHARACTER SET utf8mb4 DEFAULT '0' COMMENT '填空题内容 用||分割',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='问卷调查表';

-- 邮件日志表
CREATE TABLE if not exists `log_role_mail`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`template_id` int(10) DEFAULT '0' COMMENT '问卷ID',
	`title_strings` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '标题 用||分割',
	`text_strings` varchar(2000) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '内容 用||分割',
	`gold` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '发送元宝',
	`goods_list` varchar(2000) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '道具ID,数量,是否绑定(1绑定, 0不绑)||道具ID,数量,是否绑定(1绑定, 0不绑)..',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='邮件日志表';



-- 排行榜日志表
CREATE TABLE if not exists `log_rank`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`role_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '角色名字',
	`family_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '帮派名',
	`family_id` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '帮派ID',
    `category` tinyint NOT NULL DEFAULT 0 COMMENT '职业',
    `role_vip_level` int(4) NOT NULL DEFAULT 0 COMMENT 'VIP等级',
    `rank_type` int(5) NOT NULL DEFAULT 0 COMMENT '榜单类型',
    `rank_value` int NOT NULL DEFAULT 0 COMMENT '榜单数值',
	`role_rank` smallint NOT NULL DEFAULT 0 COMMENT '玩家排名',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='排行榜日志表';





-- 世界boss掉落日志
CREATE TABLE if not exists `log_world_boss_drop`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`boss_type_id` int(10) DEFAULT '0' COMMENT 'boss类型ID',
	`drop_goods_list` varchar(2555) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '道具ID,数量,是否绑定(1绑定, 0不绑)||道具ID,数量,是否绑定(1绑定, 0不绑)..',
	`kill_role_names` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '角色名字1||角色名字2',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='世界boss掉落日志';



-- 世界boss拾取日志
CREATE TABLE if not exists `log_world_boss_pick`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`role_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '角色名字',
	`boss_type_id` int(10) DEFAULT '0' COMMENT 'boss类型ID',
	`pick_goods_list` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '道具ID,数量,是否绑定(1绑定, 0不绑)||道具ID,数量,是否绑定(1绑定, 0不绑)..',
	
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='世界boss拾取日志';

-- 装备强化
CREATE TABLE if not exists `log_equip_refine`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`equip_id` int(10) DEFAULT '0' COMMENT '装备ID',
	`refine_level` int(10) DEFAULT '0' COMMENT '强化等级',
	`new_mastery` int(10) DEFAULT '0' COMMENT '熟练度',
	`consume_silver` int(10) DEFAULT '0' COMMENT '消耗银两',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='装备强化';

-- 宝石镶嵌
CREATE TABLE if not exists `log_equip_stone`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`equip_id` int(10) DEFAULT '0' COMMENT '装备ID',
	`action_type` int(3) DEFAULT '0' COMMENT '1为镶嵌 2为拆卸',
	`stone_index` int(3) DEFAULT '0' COMMENT '部位',
	`stone_id` int(10) DEFAULT '0' COMMENT '灵石ID',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='宝石镶嵌';

-- 聊天记录
CREATE TABLE if not exists `log_chat`(
	`id` bigint NOT NULL,
	`time` int(11) NOT NULL DEFAULT 0,
	`agent_id` int(4) NOT NULL DEFAULT 0,
	`server_id` int(6) NOT NULL DEFAULT 0,
  
	`role_id` varchar(50) CHARACTER SET utf8mb4 NOT NULL COMMENT '角色ID',
	`role_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '角色名',
	`chat_type` int(3) DEFAULT '0' COMMENT '1世界频道 2家族频道 3队伍频道 4私人频道',
	`chat_id` varchar(50) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '家族跟私人频道会有ID',
	`chat_name` varchar(255) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '根据频道不同有对应的显示 2：仙盟名  4：私聊对象的名字',
	`msg` varchar(255) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '信息',
  
	`channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
	`game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
	PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='聊天记录';

-- 商城表
CREATE TABLE if not exists `log_shop`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `type_id` int DEFAULT 0 COMMENT '购买道具id',
  `buy_num` int DEFAULT 0 COMMENT '购买数量',
  `asset_type` int DEFAULT 0 COMMENT '消耗货币类型',
  `asset_value` int DEFAULT 0 COMMENT '消耗货币',
  `asset_bind_value` int DEFAULT 0 COMMENT '消耗绑定货币',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色商品购买表';

-- 充值表
CREATE TABLE if not exists `log_role_pay`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `order_id` bigint DEFAULT 0 COMMENT '订单ID',
  `product_id` int DEFAULT 0 COMMENT '商品ID',
  `pay_fee` int DEFAULT 0 COMMENT '支付金额(分)',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色充值日志';

-- 角色等级表
CREATE TABLE if not exists `log_role_level`(
  `id` bigint NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0,
  `agent_id` int(4) NOT NULL DEFAULT 0,
  `server_id` int(6) NOT NULL DEFAULT 0,
  
  `role_id` bigint NOT NULL DEFAULT 0 COMMENT '角色id',
  `add_exp` bigint DEFAULT 0 COMMENT '增加经验',
  `old_level` int DEFAULT 0 COMMENT '旧等级',
  `new_level` int DEFAULT 0 COMMENT '新等级',
  `action` int DEFAULT 0 COMMENT '行为',
  `map_id` int DEFAULT 0 COMMENT '当前地图',
  
  `channel_id` int NOT NULL DEFAULT 0 COMMENT '渠道ID',
  `game_channel_id` int NOT NULL DEFAULT 0 COMMENT '包渠道ID',
  PRIMARY KEY `id` (`id`) USING BTREE
) DEFAULT CHARSET=utf8 ENGINE=MyISAM COMMENT='角色升级表';
