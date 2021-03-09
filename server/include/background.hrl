%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 八月 2018 16:50
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(BACKGROUND_HRL).
-define(BACKGROUND_HRL, background_hrl).

-define(BACKGROUND_WORKER_NUM, 10).     %% 10个进程
-define(BACKGROUND_REPLACE_WORKER, 3).  %% 处理替换数据的进程（保证有序，现在有3个表是需要替换）
-define(BACKGROUND_LOG_NUM, 200).       %% 单次最多插入200条
-define(BACKGROUND_LOOP_TIME, 2000).    %% mysql 2秒写入一次
-define(BACKGROUND_ES_LOOP_TIME, 3000). %% ES 3秒写入一次

-define(BACKGROUND_LOG_LOOP_SEC, 10 * 60).   %% 10分钟循环
-define(BACKGROUND_LOG_LOOP_NUM, 1000). %% 每次循环取最近的1000条

-define(BACKGROUND_ES_WORKER_NUM, 3).   %% 3个普通数据进程
-define(BACKGROUND_ES_REPLACE_NUM, 1).  %% 处理替换数据的进程（保证有序，现在有1个表是需要替换）
-define(BACKGROUND_SUB_WORKER, 3).      %% 这个数值跟time_server循环时间与超时时间有关

-define(IS_REPLACE_WORKER(Index), (Index > ?BACKGROUND_WORKER_NUM)).

-define(ADMIN_POOL, admin_pool).        %% 游戏服连接池
-define(CENTRAL_POOL, central_pool).    %% 中央服连接池

%% 关于后台的数据，我们所有的日志，都要包括以下字段：
%% 这部分内容底层会实现，写日志时可忽略
%% id: key
%% agent_id：代理ID（例如：君海专服，九游专服、多渠道混服）
%% server_id：服务器ID
%% time : 时间

%% 关系玩家的行为日志，根据君海那边的要求，要额外加上:
%% channel_id 渠道ID
%% game_channel_id 包渠道ID

%% 玩家注册信息 帐号、uid、is_old、role_id、性别、职业、imei、ip
-record(log_role_create, {account_name, uid, is_old, role_id, sex, category, imei, ip, create_server_id, channel_id, game_channel_id}).

%% 玩家道具日志 role_id，行为，道具类型，数量，绑定，操作时间
-record(log_item, {role_id, action, type_id, num, bind, channel_id, game_channel_id}).

%% 玩家银两日志 role_id，行为，铜钱，剩余铜钱
-record(log_silver, {role_id, action, silver, remain_silver, channel_id, game_channel_id}).

%% 玩家元宝日志 role_id，行为，元宝，绑定元宝，剩余元宝，剩余绑定元宝
-record(log_gold, {role_id, action, gold, bind_gold, remain_gold, remain_bind_gold, channel_id, game_channel_id}).

%% 玩家积分 role_id，行为，类型，积分类型，操作积分，剩余积分
-record(log_score, {role_id, action, score_key, score, remain_score, channel_id, game_channel_id}).

%% 玩家登录日志
-record(log_role_login, {role_id, account_name, ip, uid, imei, role_level, channel_id, game_channel_id}).

%% 玩家登出日志
-record(log_role_logout, {role_id, account_name, online_time, channel_id, game_channel_id}).

%% 玩家状态表
-record(log_role_status, {role_id, role_name, uid, account_name, role_level, role_vip_level, relive_level, category, power, gold, bind_gold, create_time,
                          last_login_time, last_login_ip, map_id, mission_id, mission_status, is_online, is_insider, insider_time, insider_gold,
                          confine_id, channel_id, game_channel_id}).


%% 分服在线日志 帐号数、年、月、日
-record(log_online, {game_channel_id, channel_id, online_num, year, month, day}).

%% 意见反馈
-record(log_feedback, {role_id, role_name, account_name, feedback_type, status, title, content, back_content, back_name, back_time, channel_id, game_channel_id}).

%% 养成功能
-record(log_role_nurture, {role_id, god_weapon_level, god_weapon_skins, wing_level, wing_skins, magic_weapon_level, magic_weapon_skins, channel_id, game_channel_id}).

%% 问卷调查
-record(log_role_question, {role_id, vip_level, question_id, result, use_time, channel_id, game_channel_id}).

%% 邮件日志
-record(log_role_mail, {role_id, template_id, title_strings, text_strings, gold, goods_list, channel_id, game_channel_id}).

%% 世界boss掉落日志
-record(log_world_boss_drop, {boss_type_id, drop_goods_list, kill_role_names}).

%% 世界boss拾取日志
-record(log_world_boss_pick, {role_id, role_name, boss_type_id, pick_goods_list, channel_id, game_channel_id}).

%% 排行榜日志
-record(log_rank, {role_id, role_name, family_name, family_id, category, role_vip_level, rank_type, rank_value, rank_value2, role_rank}).

%% 聊天日志
-record(log_chat, {role_id, role_name, chat_type, chat_id, chat_name, msg, channel_id, game_channel_id}).

%% 商城购买日志
-record(log_shop, {role_id, shop_type, type_id, buy_num, asset_type, asset_value, asset_bind_value, channel_id, game_channel_id}).

%% 充值日志
-record(log_role_pay, {role_id, account_name, imei, order_id, pf_order_id, product_id, pay_fee, pay_gold, role_level, pay_times, uid, channel_id, game_channel_id}).

%% 等级日志
-record(log_role_level, {role_id, add_exp, old_level, new_level, action, map_id, channel_id, game_channel_id}).

%% 法宝日志
-record(log_role_magic_weapon, {role_id, item_id, item_num, old_level, new_level, channel_id, game_channel_id}).

%% 翅膀日志
-record(log_role_wing, {role_id, item_id, item_num, old_level, new_level, channel_id, game_channel_id}).

%% 神兵日志
-record(log_role_god_weapon, {role_id, item_id, item_num, old_level, new_level, channel_id, game_channel_id}).

%% 符文日志
-record(log_role_rune, {role_id, use_exp, old_level_id, new_level_id, channel_id, game_channel_id}).

%% 装备合成
-record(log_equip_compose, {role_id, goods_list, is_succ, type_id, channel_id, game_channel_id}).

%% 装备穿戴日志
-record(log_equip_load, {role_id, equip_index, load_equip_id, replace_equip_id, all_equip_stars, channel_id, game_channel_id}).

%% 装备强化日志
-record(log_equip_refine, {role_id, equip_id, equip_index, add_mastery, old_level, new_level, consume_silver, all_refine_level, channel_id, game_channel_id}).

-define(LOG_TYPE_PUNCH, 1).     %% 镶嵌
-define(LOG_TYPE_REMOVE, 2).    %% 拆卸
%% 宝石镶嵌日志
-record(log_equip_stone, {role_id, equip_id, equip_index, action_type, stone_index, stone_id, replace_stone_id, all_stone_level, channel_id, game_channel_id}).

%% 装备洗练日志
-record(log_equip_concise, {role_id, equip_id, equip_index, old_prop_list, new_prop_list, item_id, item_num, use_gold, channel_id, game_channel_id}).

%% 宠物升阶
-record(log_pet_step, {role_id, add_step_exp, item_id, item_num, old_pet_id, new_pet_id, channel_id, game_channel_id}).

%% 宠物升级
-record(log_pet_level, {role_id, add_exp, goods_list, old_level, new_level, channel_id, game_channel_id}).

%% 坐骑进阶
-record(log_mount_step, {role_id, add_step_exp, item_id, item_num, old_mount_id, new_mount_id, channel_id, game_channel_id}).

%% 仙盟日志
-record(log_family_status, {family_id, family_name, family_level, owner_role_id, member_num, family_power, family_notice}).

%% 帮派技能学习
-record(log_family_skill, {role_id, old_skill_id, new_skill_id, use_con, channel_id, game_channel_id}).

%% 帮派成员
-define(LOG_FAMILY_MEMBER_CREATE, 1).
-define(LOG_FAMILY_MEMBER_JOIN, 2).
-define(LOG_FAMILY_MEMBER_QUIT, 3).
-define(LOG_FAMILY_MEMBER_KICK, 4).
-define(LOG_FAMILY_OWNER_QUIT, 5).
-define(LOG_FAMILY_OWNER_DISMISS, 6).
-define(LOG_FAMILY_WEB_DISMISS, 7).
-define(LOG_FAMILY_ADMIN, 8).
-define(LOG_FAMILY_TRANSFORM, 9).
-record(log_family_member, {family_id, role_id1, role_id2, action_type}).

%% 帮派仓库
-define(LOG_FAMILY_DEPOT_DONATE, 1).
-define(LOG_FAMILY_DEPOT_EXCHANGE, 2).
-record(log_family_depot, {family_id, role_id, action_type, goods_list, old_score, new_score, channel_id, game_channel_id}).

%% 帮派战
-record(log_family_battle, {win_family_id, lose_family_id}).

%% 合成日志
-record(log_role_compose, {role_id, type_id, goods_list, channel_id, game_channel_id}).

%% 副本日志
-define(LOG_COPY_ENTER, 1).
-define(LOG_COPY_QUIT, 2).
-record(log_role_copy, {role_id, role_level, map_id, action_type, channel_id, game_channel_id}).

%% VIP日志
-define(LOG_VIP_CARD, 1).
-define(LOG_VIP_CONSUME, 2).
-define(LOG_VIP_LOGIN, 3).
-define(LOG_VIP_EXP_CARD, 4).
-record(log_role_vip, {role_id, action_type, sub_action_type, add_exp, now_exp, old_vip_level, new_vip_level, role_level, channel_id, game_channel_id}).

%% 寻宝日志
-define(LOG_EQUIP_TREASURE, 1).
-define(LOG_RUNE_TREASURE, 2).
-define(LOG_SUMMIT_TREASURE, 3).
-record(log_treasure, {role_id, role_level, action_type, times, use_type_id, use_num, use_gold, goods_list, channel_id, game_channel_id}).

%% 境界日志
-record(log_role_confine, {role_id, goods_list, old_confine_id, new_confine_id, channel_id, game_channel_id}).

%% 时装日志
-record(log_role_fashion, {role_id, old_fashion_id, new_fashion_id, use_type_id, use_num, channel_id, game_channel_id}).

%% 仙盟答题
-record(log_family_answer, {family_id, answer_rank, score}).

%% 论道道题
-record(log_role_answer, {role_id, answer_rank, score}).

%% 三界战场
-record(log_role_battle, {role_id, battle_rank, score, camp_id}).

%% boss疲劳日志
-record(log_boss_tired, {role_id, boss_type_id, old_value, new_value}).

%% 投资日志
-record(log_role_invest, {role_id, role_level, gold, channel_id, game_channel_id}).

%% 战力日志
-record(log_power, {role_id, old_power, new_power, action, detail, channel_id, game_channel_id}).

%% 纹印镶嵌日志
-record(log_equip_seal, {role_id, equip_id, equip_index, action_type, seal_index, seal_id, replace_seal_id, all_seal_level, channel_id, game_channel_id}).

%% 化神投资日志
-record(log_role_summit_invest, {role_id, role_level, gold, channel_id, game_channel_id}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  档位类统计   start
%%  开服累充
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(LOG_GEAR_ACC_RECHARGE, 100).        %%开服累充
-define(LOG_GEAR_ZERO_PANIC_BUY, 101).      %%零元抢购
-define(LOG_GEAR_LEVEL_PANIC_BUY, 102).     %%等级限购
-define(LOG_GEAR_WEEK_CARD, 103).           %%周卡礼盒
-define(LOG_GEAR_LIMITED_TIME_BUY, 104).    %%限时云购

%%档位类统计
-record(
log_role_gear, {role_id, type, gear, channel_id, game_channel_id}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  档位类统计   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ES日志
-record(log_es, {table_name, log_id}).

%% 角色的快照信息
-define(LOG_ROLE_SNAPSHOT_EQUIP_STARS, 1).
-define(LOG_ROLE_SNAPSHOT_EQUIP_REFINE, 2).
-define(LOG_ROLE_SNAPSHOT_STONE_LEVEL, 3).
-define(LOG_ROLE_SNAPSHOT_VIP_LEVEL, 4).
-define(LOG_ROLE_SNAPSHOT_LEVEL_VIP, 5).
-define(LOG_ROLE_SNAPSHOT_OFFLINE_SOLO, 6).
-record(log_role_snapshot, {snapshot_type, snapshot_string}).

%% 玩家改名
-record(log_role_rename, {role_id, old_name, new_name, role_level, channel_id, game_channel_id}).

%% 仙盟改名
-record(log_family_rename, {role_id, family_id, old_family_name, new_family_name}).

%% 市场流水
-define(LOG_MARKET_ON_SHELF, 1).    %% 上架
-define(LOG_MARKET_BUY, 2).         %% 购买
-define(LOG_MARKET_DOWN, 3).        %% 下架
-record(log_market, {from_role_id, market_type, action_type, market_id, goods_type_id, goods_num, sell_role_id, price, sell_time, expire_time}).

%% 功能统计
-record(log_function_statistics, {function_id, role_num, times, sub_times, function_level, function_role_num, times_string}).

%% 婚礼日志记录
-define(LOG_MARRY_PROPOSE_SUCC, 1).     %% 提亲成功
-define(LOG_MARRY_APPOINT_SUCC, 2).     %% 预约成功
-define(LOG_MARRY_START, 3).            %% 婚礼开始
-define(LOG_MARRY_END, 4).              %% 婚礼结束
-record(log_marry_status, {role_id1, role_id2, action_type, propose_type, guest_list}).

%% 同心结
-record(log_marry_knot, {role_id, item_type_id, item_num, add_exp, old_knot_id, new_knot_id, new_exp, channel_id, game_channel_id}).

%% 等级段分布
-record(log_all_level, {string}).

%% 境界分布
-record(log_all_confine, {string}).

%% 神兽装备获得
-record(log_mythical_equip_add, {role_id, equip_id, type_id, excellent_string, channel_id, game_channel_id}).

%% 神兽激活
-record(log_mythical_equip_status, {role_id, soul_id, is_active, channel_id, game_channel_id}).

%% 神兽装备替换
-record(log_mythical_equip_replace, {role_id, soul_id, load_type_id, replace_type_id, channel_id, game_channel_id}).

%% 神兽强化
-record(log_mythical_equip_refine, {role_id, soul_id, type_id, add_exp, old_level, new_level, goods_string, use_gold, channel_id, game_channel_id}).

%% 神兽装备合成
-record(log_mythical_equip_compose, {role_id, goods_string, is_succ, type_id, channel_id, game_channel_id}).

%% 中央服帐号创建日志
-record(log_account, {uid, channel_id, game_channel_id}).

%% 游戏服帐号创建日志
-record(log_admin_account, {uid, channel_id, game_channel_id}).

%% 战灵灵饰获得
-record(log_war_spirit_equip_add, {role_id, equip_id, type_id, excellent_string, channel_id, game_channel_id}).

%% 战灵灵饰装备/替换
-record(log_war_spirit_equip_replace, {role_id, war_spirit_id, load_equip_id, load_type_id, replace_equip_id, replace_type_id, channel_id, game_channel_id}).

%% 战灵灵饰强化
-record(log_war_spirit_equip_refine, {role_id, war_spirit_id, equip_id, type_id, old_level, new_level, new_exp, refine_all_exp, channel_id, game_channel_id}).

%% 战灵灵饰进阶
-record(log_war_spirit_equip_step, {role_id, war_spirit_id, equip_id, old_type_id, new_type_id, channel_id, game_channel_id}).

%% 战灵灵饰分解
-record(log_war_spirit_equip_decompose, {role_id, goods_string, add_refine_exp, refine_all_exp, channel_id, game_channel_id}).

%% 等级快照
-record(log_level_snapshot, {role_id, role_level}).

%% 战神碎片激活
-record(log_war_god_piece_active, {role_id, war_god_id, equip_id}).

%% 战神套装强化
-record(log_war_god_refine, {role_id, war_god_id, equip_id, old_refine_level, old_refine_exp, new_refine_level, new_refine_exp}).

%% 道庭宝箱个人数据  type = 1  开启宝箱   type = 2 获得宝箱   box_type -对应礼包表ID  box_from -对应道庭仓库任务 box_from_value - 对应档位怪物ID  open_item开启获得道具ID open_item_num 开启获得道具数量
-record(log_role_family_box, {role_id, type, box_type, box_from, box_from_value, open_item = 0, open_item_num = 0}).

%% 道庭宝箱道庭数据
-record(log_family_box, {family_id, role_id, box_type, box_from, box_from_value}).

%% 道庭护送
-record(log_family_escort, {role_id, type,escort_type}).

-define(ACTION_REQUEST_PRE_ENTER, 1).   %% 1 发起m_pre_enter_tos
-define(ACTION_PRE_ENTER, 2).           %% 2 切换地图返回
-define(ACTION_REQUEST_ENTER, 3).       %% 3 正式进入地图请求
-define(ACTION_ENTER, 4).               %% 4 正式进入地图返回
-define(ACTION_REQUEST_QUIT_MAP, 5).    %% 5 发起m_quit_map_tos
-define(ACTION_REQUEST_MAP_CHANGE, 6).  %% 6 发起m_map_change_pos_tos
-define(ACTION_REQUEST_SERVER_QUIT, 7). %% 7 后端踢玩家出地图

%% 进入地图日志
-record(log_map_enter, {role_id, role_level, map_id, action_type}).

%% 拍卖行ES日志
-define(ACTION_AUCTION_SELL, 1).    %% 上架
-define(ACTION_AUCTION_UNSOLD, 2).  %% 下架
-define(ACTION_AUCTION_BUY, 3).     %% 购买
-record(log_auction_exchange, {action, goods_id, from_type, from_id, type_id, num, gold, channel_id, game_channel_id}).

%% 单服日志
-record(log_auction_buy, {role_id, goods_id, auction_type, type_id, num, gold, channel_id, game_channel_id}).


%% 特惠充值日志
-record(log_discount_pay, {role_id, buy_id, package_name, goods_string, pay_money, channel_id, game_channel_id}).

%% 每日限购日志
-record(log_daily_buy, {role_id, buy_id, goods_string, asset_type, asset_value, channel_id, game_channel_id}).

%% 道庭任务日志
-record(log_family_asm, {role_id, mission_id, channel_id, game_channel_id}).

%% 玩家挖矿信息
-record(log_mining_role, {role_id, type, type_id, pos, old_pos, use_time, gather_num, shift_num, plunder_id, plunder_power, power, is_success, channel_id, game_channel_id}).

%% LogList
%% recordName,
%% world_data用的index（唯一）,
%% worker_index 是否指定发到指定的worker
%% fields record结构列表
%% [admin, central]  默认是[admin]只发到分服后台
%% normal or replace 默认是normal
-record(c_background_log, {record_name, index, worker_index = 0, fields = [], backgrounds = [?ADMIN_POOL], type = normal, is_log_es = false}).

-define(BACKGROUND_LIST, [
    #c_background_log{record_name = log_item, index = 1, fields = record_info(fields, log_item)},
    #c_background_log{record_name = log_silver, index = 2, fields = record_info(fields, log_silver)},
    #c_background_log{record_name = log_gold, index = 3, is_log_es = true, fields = record_info(fields, log_gold)},
    #c_background_log{record_name = log_score, index = 4, is_log_es = true, fields = record_info(fields, log_score)},
    #c_background_log{record_name = log_online, index = 5, is_log_es = true, fields = record_info(fields, log_online)},
    #c_background_log{record_name = log_role_create, index = 6, is_log_es = true, fields = record_info(fields, log_role_create)},
    #c_background_log{record_name = log_role_login, index = 7, is_log_es = true, fields = record_info(fields, log_role_login)},
    #c_background_log{record_name = log_role_logout, is_log_es = true, index = 8, fields = record_info(fields, log_role_logout)},
    #c_background_log{record_name = log_role_status, index = 9, worker_index = 11, is_log_es = true, fields = record_info(fields, log_role_status)},
    #c_background_log{record_name = log_feedback, index = 10, fields = record_info(fields, log_feedback)},
    #c_background_log{record_name = log_role_nurture, index = 11, worker_index = 12, fields = record_info(fields, log_role_nurture)},
    #c_background_log{record_name = log_role_question, index = 12, is_log_es = true, fields = record_info(fields, log_role_question)},
    #c_background_log{record_name = log_role_mail, index = 13, fields = record_info(fields, log_role_mail)},
    #c_background_log{record_name = log_world_boss_drop, index = 14, is_log_es = true, fields = record_info(fields, log_world_boss_drop)},
    #c_background_log{record_name = log_world_boss_pick, index = 15, fields = record_info(fields, log_world_boss_pick)},
    #c_background_log{record_name = log_rank, index = 16, fields = record_info(fields, log_rank)},
    #c_background_log{record_name = log_equip_refine, index = 17, fields = record_info(fields, log_equip_refine)},
    #c_background_log{record_name = log_equip_stone, index = 18, fields = record_info(fields, log_equip_stone)},
    #c_background_log{record_name = log_chat, index = 19, is_log_es = true, fields = record_info(fields, log_chat)},
    #c_background_log{record_name = log_shop, index = 20, is_log_es = true, fields = record_info(fields, log_shop)},
    #c_background_log{record_name = log_role_level, index = 21, is_log_es = true, fields = record_info(fields, log_role_level)},
    #c_background_log{record_name = log_role_pay, index = 22, is_log_es = true, fields = record_info(fields, log_role_pay)},
    #c_background_log{record_name = log_role_magic_weapon, index = 23, fields = record_info(fields, log_role_magic_weapon)},
    #c_background_log{record_name = log_role_wing, index = 24, fields = record_info(fields, log_role_wing)},
    #c_background_log{record_name = log_role_god_weapon, index = 25, fields = record_info(fields, log_role_god_weapon)},
    #c_background_log{record_name = log_role_rune, index = 26, fields = record_info(fields, log_role_rune)},
    #c_background_log{record_name = log_equip_compose, index = 27, fields = record_info(fields, log_equip_compose)},
    #c_background_log{record_name = log_equip_load, index = 28, fields = record_info(fields, log_equip_load)},
    #c_background_log{record_name = log_equip_concise, index = 29, fields = record_info(fields, log_equip_concise)},
    #c_background_log{record_name = log_pet_step, index = 30, fields = record_info(fields, log_pet_step)},
    #c_background_log{record_name = log_pet_level, index = 31, fields = record_info(fields, log_pet_level)},
    #c_background_log{record_name = log_mount_step, index = 32, fields = record_info(fields, log_mount_step)},
    #c_background_log{record_name = log_family_status, index = 33, worker_index = 13, fields = record_info(fields, log_family_status)},
    #c_background_log{record_name = log_family_skill, index = 34, fields = record_info(fields, log_family_skill)},
    #c_background_log{record_name = log_family_member, index = 35, fields = record_info(fields, log_family_member)},
    #c_background_log{record_name = log_family_depot, index = 36, fields = record_info(fields, log_family_depot)},
    #c_background_log{record_name = log_family_battle, index = 37, fields = record_info(fields, log_family_battle)},
    #c_background_log{record_name = log_role_compose, index = 38, fields = record_info(fields, log_role_compose)},
    #c_background_log{record_name = log_role_copy, index = 39, fields = record_info(fields, log_role_copy)},
    #c_background_log{record_name = log_role_vip, index = 40, is_log_es = true, fields = record_info(fields, log_role_vip)},
    #c_background_log{record_name = log_treasure, index = 41, is_log_es = true, fields = record_info(fields, log_treasure)},
    #c_background_log{record_name = log_role_confine, index = 42, fields = record_info(fields, log_role_confine)},
    #c_background_log{record_name = log_role_fashion, index = 43, fields = record_info(fields, log_role_fashion)},
    #c_background_log{record_name = log_family_answer, index = 44, fields = record_info(fields, log_family_answer)},
    #c_background_log{record_name = log_role_answer, index = 45, fields = record_info(fields, log_role_answer)},
    #c_background_log{record_name = log_role_battle, index = 46, fields = record_info(fields, log_role_battle)},
    #c_background_log{record_name = log_boss_tired, index = 47, fields = record_info(fields, log_boss_tired)},
    #c_background_log{record_name = log_role_invest, index = 48, is_log_es = true, fields = record_info(fields, log_role_invest)},
    #c_background_log{record_name = log_power, index = 49, fields = record_info(fields, log_power)},
    #c_background_log{record_name = log_es, index = 50, fields = record_info(fields, log_es)},
    #c_background_log{record_name = log_role_snapshot, index = 51, is_log_es = true, fields = record_info(fields, log_role_snapshot)},
    #c_background_log{record_name = log_role_rename, index = 52, fields = record_info(fields, log_role_rename)},
    #c_background_log{record_name = log_family_rename, index = 53, fields = record_info(fields, log_family_rename)},
    #c_background_log{record_name = log_market, index = 54, fields = record_info(fields, log_market)},
    #c_background_log{record_name = log_function_statistics, index = 55, is_log_es = true, fields = record_info(fields, log_function_statistics)},
    #c_background_log{record_name = log_marry_status, index = 56, fields = record_info(fields, log_marry_status)},
    #c_background_log{record_name = log_marry_knot, index = 57, fields = record_info(fields, log_marry_knot)},
    #c_background_log{record_name = log_all_level, index = 58, is_log_es = true, fields = record_info(fields, log_all_level)},
    #c_background_log{record_name = log_mythical_equip_add, index = 59, fields = record_info(fields, log_mythical_equip_add)},
    #c_background_log{record_name = log_mythical_equip_status, index = 60, fields = record_info(fields, log_mythical_equip_status)},
    #c_background_log{record_name = log_mythical_equip_replace, index = 61, fields = record_info(fields, log_mythical_equip_replace)},
    #c_background_log{record_name = log_mythical_equip_refine, index = 62, fields = record_info(fields, log_mythical_equip_refine)},
    #c_background_log{record_name = log_mythical_equip_compose, index = 63, fields = record_info(fields, log_mythical_equip_compose)},
    #c_background_log{record_name = log_account, index = 64, is_log_es = true, fields = record_info(fields, log_account)},
    #c_background_log{record_name = log_admin_account, index = 65, is_log_es = true, fields = record_info(fields, log_admin_account)},
    #c_background_log{record_name = log_war_spirit_equip_add, index = 66, fields = record_info(fields, log_war_spirit_equip_add)},
    #c_background_log{record_name = log_war_spirit_equip_replace, index = 67, fields = record_info(fields, log_war_spirit_equip_replace)},
    #c_background_log{record_name = log_war_spirit_equip_refine, index = 68, fields = record_info(fields, log_war_spirit_equip_refine)},
    #c_background_log{record_name = log_war_spirit_equip_step, index = 69, fields = record_info(fields, log_war_spirit_equip_step)},
    #c_background_log{record_name = log_war_spirit_equip_decompose, index = 70, fields = record_info(fields, log_war_spirit_equip_decompose)},
    #c_background_log{record_name = log_level_snapshot, index = 71, fields = record_info(fields, log_level_snapshot)},
    #c_background_log{record_name = log_role_gear, index = 72, is_log_es = true, fields = record_info(fields, log_role_gear)},
    #c_background_log{record_name = log_war_god_piece_active, index = 73, fields = record_info(fields, log_war_god_piece_active)},
    #c_background_log{record_name = log_war_god_refine, index = 74, fields = record_info(fields, log_war_god_refine)},
    #c_background_log{record_name = log_equip_seal, index = 75, fields = record_info(fields, log_equip_seal)},
    #c_background_log{record_name = log_role_summit_invest, index = 76, is_log_es = true, fields = record_info(fields, log_role_summit_invest)},
    #c_background_log{record_name = log_map_enter, index = 77, fields = record_info(fields, log_map_enter)},
    #c_background_log{record_name = log_auction_exchange, index = 78, is_log_es = true, fields = record_info(fields, log_auction_exchange)},
    #c_background_log{record_name = log_auction_buy, index = 79, fields = record_info(fields, log_auction_buy)},
    #c_background_log{record_name = log_role_family_box, index = 80, fields = record_info(fields, log_role_family_box)},
    #c_background_log{record_name = log_family_box, index = 81, fields = record_info(fields, log_family_box)},
    #c_background_log{record_name = log_discount_pay, index = 82, is_log_es = true, fields = record_info(fields, log_discount_pay)},
    #c_background_log{record_name = log_daily_buy, index = 83, is_log_es = true, fields = record_info(fields, log_daily_buy)},
    #c_background_log{record_name = log_family_asm, index = 84, is_log_es = true, fields = record_info(fields, log_family_asm)},
    #c_background_log{record_name = log_all_confine, index = 85, is_log_es = true, fields = record_info(fields, log_all_confine)},
    #c_background_log{record_name = log_mining_role, index = 84, is_log_es = true, fields = record_info(fields, log_mining_role)},
    #c_background_log{record_name = log_family_escort, index = 86, is_log_es = true, fields = record_info(fields, log_family_escort)}
]).

-endif.