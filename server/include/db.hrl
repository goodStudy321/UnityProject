%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2017 17:17
%%%-------------------------------------------------------------------
-ifndef(DB_HRL).
-define(DB_HRL, db_hrl).
-include("map.hrl").
-include("fight.hrl").

%% @doc 数据库表和访问方式定义
%% tab              := 表名
%% node             := node节点 game or map
%% class            := {role, r_role里的第几位}方便初始化与结束时读写数据库
%% ets_opts         := ets表参数，必须是public
%% sql_opts         := keyformat key值对应的类型，int, {varbinary, N} 默认为int
%%                     cooldown 看db_server(可选，默认是不删除冷数据，时间为s)
%%                     period 对key进行管理，默认是链表，另一个是有序平衡二叉树
%% active_time      := XXs之前的数据，先加载到内存表
-record(c_tab, {tab, node, class, ets_opts, sql_opts, active_time}).
-define(ETS_DEFAULT, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, 2}]).
-define(SQL_DEFAULT, [{keyformat, int}, {cooldown, 24 * 3600}]).
-define(SQL_NOT_COOLDOWN, [{keyformat, int}] ++ ?SQL_INIT_ALL).
-define(SQL_INIT_ALL, [{init_type, all}]).

%% 注意表的key值都是第2位，别搞错了。。
%%%===================================================================
%%% role 相关数据 start
%%%===================================================================

%% role_server里state对应的字段
-record(r_role, {role_id, role_attr, role_private_attr, role_asset, role_pay, calc_list = [], buff_attr, hp_attr = #actor_cal_attr{},
                 seal_all_level = 0,
                 prop_effects = [], prop_rates = [], skill_prop_attr, skill_power_list = [],
                 role_fight, role_bag, role_map, role_map_panel, role_mission, role_discount_pay, role_warning, role_equip_collect, role_act_luckycat, role_act_firstpay, role_act_treasure_chest,
                 role_skill, role_copy, role_equip, role_function, role_letter, role_grow, role_mount, role_magic_weapon, role_pet, role_daily_liveness,
                 role_god_weapon, role_wing, role_fashion, role_buff, role_shop, role_rune, role_world_boss, role_vip, role_title, role_addict, role_chapter, role_marry,
                 role_relive, role_extra, role_treasure, role_month_card, role_invest, role_achievement, role_god_book, role_seven_day, role_act_online, role_act_sign,
                 role_act_level, role_act_family, role_act_feast, role_act_dayrecharge, role_act_accrecharge, role_act_firstrecharge, role_market, role_guard, role_clword, role_red_packet,
                 role_act_zeropanicbuy, role_act_lucky_token, role_levelpanicbuy, role_immortal_soul, role_act_hunt_boss, role_confine, role_day_target, role_bless, role_mythical_equip, role_bg_act_store,
                 role_bg_act_mission, role_handbook, role_week_card, role_trevi_fountain, role_throne, role_second_act, role_hunt_treasure, role_boss_reward, role_act_otf, role_bg_alchemy, role_suit,
                 role_bg_turntable, role_daily_buy, role_nature, role_act_store, role_bg_tt, role_pellet_medicine, role_new_alchemy, role_money_tree, role_bg_extra, role_day_box, role_choose, role_it,
                 role_cycle_act_extra, role_cycle_act_misc, role_act_esoterica, role_cycle_mission, role_cycle_act_couple, role_act_welfare_recharge, role_permanent_privilege, role_act_first_deposit}).
%% 基础的角色数据
-define(DB_ROLE_ATTR_P, db_role_attr_p).
-record(r_role_attr, {role_id = 0, role_name = "", account_name = "", uid = "", sex = 0, level = 0, exp = 0,
                      team_id = 0, category = 0, family_id = 0, family_name = "", server_id = 0, channel_id = 0, game_channel_id = 0,
                      skin_list = [], power = 0, max_power = 0, last_offline_time = 0, ornament_list = []}).

-define(DB_ROLE_PRIVATE_ATTR_P, db_role_private_attr_p).
-record(r_role_private_attr, {role_id, status = 0, reset_time = 0, family_skills = [], family_day_reward = false, offline_fight_time = 0,
                              guide_id_list = [], device_name = "", os_type = "", os_ver = "", net_type = "", imei = "", package_name = "", width = 0, height = 0,
                              create_time = 0, today_online_time = 0, total_online_time = 0, online_calc_time = 0, last_level_time = 0, last_login_ip = "",
                              last_login_time = 0, is_insider = false, insider_time = 0, insider_gold = 0, charm = 0}).

-define(DB_ROLE_FIGHT_P, db_role_fight_p).
-record(r_role_fight, {role_id, base_attr, fight_attr}).

%% 角色的资产信息
-define(DB_ROLE_ASSET_P, db_role_asset_p).
-record(r_role_asset, {role_id = 0, silver = 0, gold = 0, bind_gold = 0, score_list = [], day_use_gold = 0, day_use_bind_gold = 0}).

%% 角色充值相关信息
%% today_pay_gold   ---- 今日充值元宝数
%% total_pay_gold   ---- 总重置元宝数
%% total_pay_fee    ---- 总重置金额（分）
%% package_days     ---- 礼包天数
%% first_pay_list   ---- 首充
%% today_pay_list   ---- 当天充值次数[#p_kv{id = ProductID, val = Val}|...]
-define(DB_ROLE_PAY_P, db_role_pay_p).
-record(r_role_pay, {role_id, today_pay_gold = 0, total_pay_gold = 0, total_pay_fee = 0, package_time = 0, package_days = 0, first_pay_list = [], today_pay_list = []}).

%% bag_list        -- [#p_bag_content{}|_]
-define(DB_ROLE_BAG_P, db_role_bag_p).
-record(r_role_bag, {role_id = 0, bag_list = []}).

%% 角色在地图中的数据
%% hp               -- 血量
%% line_id          -- 分线ID
%% map_id           -- 地图ID
%% map_pname        -- 地图的ProcessName
%% map_pname        -- 地图的ProcessName
%% pos              -- #r_pos{} 位置信息
%% old_xxx          -- 旧的地图数据
%% pk_mode          -- pk模式
%% pk_value         -- pk值
%% value_time       -- 一点pk值减少的时间
%% dead_time        -- 死亡时间
%% normal_relive_list -- 正常复活的冷却
%% lock             -- lock为0时跨越地图无特别限制  否则根据map.hrl查看相应限制
-define(DB_ROLE_MAP_P, db_role_map_p).
-record(r_role_map, {role_id, hp = 0, server_id = 0, map_id = 0, extra_id = 0, map_pname = "", pos, old_server_id = 0, old_map_id = 0, old_extra_id = 1, old_map_pname = "", old_pos = 0,
                     camp_id = ?DEFAULT_CAMP_ROLE, pk_mode = 1, pk_value = 0, value_time = 0, dead_time = 0, relive_list = [], enter_list = [], lock = ?MAP_NO_LOCK}).
-record(r_map_relive, {map_id, map_pid, relive_times = 0, time = 0}).

%% 角色面板记录数据
-define(DB_ROLE_MAP_PANEL_P, db_role_map_panel_p).
-record(r_role_map_panel, {role_id, panel_list = []}).
-record(r_map_panel, {map_id, map_pid, enter_time = 0, exp = 0, goods_list = []}).

%% 任务结构
%% doing_list       -- 正在进行的列表
%% done_list        -- 已经完成的任务
-define(DB_ROLE_MISSION_P, db_role_mission_p).
-record(r_role_mission, {role_id = 0, doing_list = [], done_list = []}).

%% r_mission_doing
%% id               -- id
%% type             -- 任务类型 1为主线 2为支线 3以上为循环类
%% status           -- 任务状态 1为可接取 2为已接取，进行中 3为可领奖
-record(r_mission_doing, {id, type, status, listens = []}).
-record(r_mission_listen, {type, val, need_num, num, rate}). %%

%% r_mission_done
%% type             -- 任务类型 1为主线 2为支线 3以上为循环类
%% times            -- 完成次数（仅日常类用到）
%% mission_list     -- id_list
%% last_mission     -- 最后一个任务
-record(r_mission_done, {type, times, mission_list = [], last_mission = 0}).

%% 特惠礼包信息
%% cur_pay_id       -- 当前准备充值的id
%% today_discounts  -- 当天的折扣列表[#r_discount_pay{}|...]
%% today_daily_gifts-- 当天每日礼包列表[#r_daily_gift{}|....]
%% finish_ids       -- 完成的ID
%% condition_list   -- 触发的礼包列表[#p_kv{key = ID, val = 触发时间}|....]
%% event_list       --  [#r_event{type = 类型, trigger_list = 触发的id列表}|....]

-define(DB_ROLE_DISCOUNT_PAY_P, db_role_discount_pay_p).
-record(r_role_discount_pay, {role_id, cur_pay_id = 0, today_discounts = [], today_daily_gifts = [], finish_ids = [], condition_list = [], event_list = []}).
-record(r_discount_pay, {id, buy_num, end_time}).
-record(r_daily_gift, {id, is_reward = false}).
-record(r_event, {type, trigger_list = []}).


%% 角色技能信息
%% all_list=[#r_function_skill{}|..] key参考role.hrl
%% attack_list              -- 主动释放技能[#p_skill{}]
%% passive_list             -- [#p_kl{}|...]
%% seal_passive_list        -- [#p_kl{id = Type, list = [#r_skill_seal{}|....]}|....]
-define(DB_ROLE_SKILL_P, db_role_skill_p).
-record(r_role_skill, {role_id = 0, attack_list = [], passive_list = [], seal_passive_list = []}).
-record(r_skill_seal, {seal_id = 0, time = 0}).

%% 角色副本相关数据
%% tower_id             ---- 爬塔副本ID
%% tower_reward_list    ---- 爬塔副本奖励领取列表
%% exp_finish_times     ---- 新手经验副本完成次数
%% exp_enter_times      ---- 新手经验副本可以进入的次数
%% exp_merge_times      ---- 经验副本合并次数
%% copy_list            ---- [#r_role_copy_item{}|...]
%% cur_five_elements    ---- int32 当前完成的关卡数
%% unlock_floor         ---- int32 当前解锁的大层数
%% last_add_time        ---- 时间戳 上次增加幻力/天机勾玉时间
%% illusion             ---- 幻力(这个值是放大了10000倍的)
%% nat_intensify_min    ---- 天机勾玉累积时间(min)
%% max_universe         ---- 太虚通天塔，当前挑战完成的最大层数
%% universe_use_time    ---- 太虚通天塔，最大层用的时间
-define(DB_ROLE_COPY_P, db_role_copy_p).
-record(r_role_copy, {role_id = 0, tower_id = 0, tower_reward_list = [], exp_finish_times = 0, exp_enter_times = 0, exp_merge_times = 1,
                      exp_now_merge_times = 1, copy_list = [], cur_five_elements = 0, unlock_floor = 1, last_add_time = 0, illusion = 0,
                      buy_illusion_times = 0, nat_intensify = 0, max_universe = 0, universe_use_time = 0}).


%% clean_times      ---- 当前扫荡次数
%% star_list [#p_kv{}]
-record(r_role_copy_item, {copy_type = 0, enter_times = 0, buy_times = 0, item_add_times = 0, can_enter_time = 0, clean_times = 0, star_list = []}).

%% cd_list -- [#p_kv{id = BossID, val = Time}|...]
-record(r_five_element_cd, {copy_id = 0, cd_list = []}).

%% 角色装备数据
%% equip_list       -- [#p_equip{}|...]
-define(DB_ROLE_EQUIP_P, db_role_equip_p).
-record(r_role_equip, {role_id = 0, free_concise_times = 0, equip_list = []}).

%% 角色装备收集数据
%%[#p_equip_collect{id, suit_num, is_skill_active,ids} | _]
-define(DB_ROLE_EQUIP_COLLECT_P, db_role_equip_collect_p).
-record(r_role_equip_collect, {role_id = 0, list = []}).

%% 角色信箱数据
%% receive_box收件箱
%% id           ---- 自增ID
%% letter_state ---- 当前信件的状态
%% send_time    ---- 发送时间
%% end_time     ---- 结束时间
%% template_id  ---- 模板ID=0
%% condition    ---- r_gm_condition
%% goods_list   ---- 道具列表
%% title_string ---- title里的string参数
%% title_number ---- title里的number参数
%% text_string  ---- text里的string参数
%% text_number  ---- text里的number参数
-define(DB_ROLE_LETTER_P, db_role_letter_p).
-record(r_role_letter, {role_id, counter = 1, receive_box = [], gm_id_list = []}).
-record(r_letter, {id, letter_state, send_time = 0, end_time = 0, template_id = 0, condition, action, goods_list = [], title_string = [], text_string = []}).
-record(r_gm_condition, {id, min_level = 0, max_level = 1000, min_create_time = 0, max_create_time = 0, last_offline_time = 0, game_channel_id_list = []}).

%% 角色功能开启
%% id_list      ---- [int32|....]
-define(DB_ROLE_FUNCTION_P, db_role_function_p).
-record(r_role_function, {role_id, id_list = [], reward_list = [], got_dabao_reward = false}).

%% 坐骑系统
%% mount_id         ---- 坐骑ID
%% cur_id           ---- 当前使用的皮肤id
%% status           ---- 当前坐骑状态
%% exp              ---- 当前坐骑进阶精华
%% skin_list        ---- 坐骑皮肤数据 p_mount_skin
-define(DB_ROLE_MOUNT_P, db_role_mount_p).
-record(r_role_mount, {role_id, exp = 0, mount_id = 0, cur_id = 0, status = 0, skin_list = [], quality_list = [], surface_list = []}).

%% 法宝系统
%% level            ---- 法宝等级 跟灵气值没有关系
%% exp              ---- 灵气值
%% cur_id           ---- 当前装备的法宝ID
%% skin_list        ---- 法宝的p_kv列表
%% soul_list        ---- 魂石使用列表
-define(DB_ROLE_MAGIC_WEAPON_P, db_role_magic_weapon_p).
-record(r_role_magic_weapon, {role_id, cur_id = 0, level = 0, exp = 0, skin_list = [], soul_list = []}).

%% 宠物系统
%% exp              ---- 当前经验
%% step_exp         ---- 进阶精华
%% pet_id           ---- [PetID|....]
%% pet_spirits      ---- 宠物精魄[#p_kv{}|...]
%% skin_list        ---- 皮肤列表
-define(DB_ROLE_PET_P, db_role_pet_p).
-record(r_role_pet, {role_id, exp = 0, step_exp = 0, cur_id = 0, pet_id = 0, pet_spirits = [], surface_list = []}).

%% 神兵系统
-define(DB_ROLE_GOD_WEAPON_P, db_role_god_weapon_p).
-record(r_role_god_weapon, {role_id, cur_id = 0, level = 0, exp = 0, skin_list = [], soul_list = []}).

%% 翅膀系统
-define(DB_ROLE_WING_P, db_role_wing_p).
-record(r_role_wing, {role_id, cur_id = 0, level = 0, exp = 0, skin_list = [], soul_list = []}).

%% 角色时装功能
%% is_fashion_first
%% cur_id_list  ---- 当前外观列表
%% fashion_list ---- 时装列表 [#p_fashion_time{}|....]
%% essence_list ---- 精华列表 [#p_fashion{}|....]
%% suit_id_list ---- 套装ID列表 [#p_fashion_suit{}|....]
-define(DB_ROLE_FASHION_P, db_role_fashion_p).
-record(r_role_fashion, {role_id, is_fashion_first = false, cur_id_list = [], fashion_list = [], essence_list = [], suit_list = []}).

%% 角色buff列表
%% buffs        ---- 增益buffs
%% debuffs      ---- debuffs
-define(DB_ROLE_BUFF_P, db_role_buff_p).
-record(r_role_buff, {role_id, buff_status = 0, buffs = [], debuffs = []}).

%% 角色商城
-define(DB_ROLE_SHOP_P, db_role_shop_p).
-record(r_role_shop, {role_id, buy_limit = []}).

%% 角色守护
%% big_guard =:= 0 为开启
-define(DB_ROLE_GUARD_P, db_role_guard_p).
-record(r_role_guard, {role_id, guard = undefined, big_guard = undefined, king_guard_buy = 0}).


%% 角色集字有礼
-define(DB_ROLE_CLWORD_P, db_role_clword_p).
-record(r_role_clword, {role_id, list = [], start_date = 0}).

%% 角色符文
%% exp          ---- 符文经验 升级
%% piece        ---- 符文碎片 兑换
%% essence      ---- 符文精粹 合成
%% runes        ---- 镶嵌符文
%% bag_runes    ---- 背包符文
-define(DB_ROLE_RUNE_P, db_role_rune_p).
-record(r_role_rune, {role_id, rune_id = 1, exp = 0, piece = 0, essence = 0, load_runes = [], bag_runes = []}).

%% 角色世界boss
%% times                    ---- 类型为1的疲劳次数
%% item_add_times           ---- 类型为1的疲劳次数
%% buy_times                ---- 购买次数
%% resume_times             ---- 当天恢复的次数
%% resume_time              ---- 可以恢复的时间
%% hp_recover_time          ---- 血量恢复时间
%% cave_times               ---- 当天已经进入的次数
%% cave_assist_times        ---- 当天协助的次数
%% quit_time                ---- 幽冥地界退出时间
%% mythical_times           ---- 神兽岛次数
%% mythical_item_times      ---- 神兽岛道具使用次数
%% mythical_collect_times   ---- 神兽岛龙灵水晶已经采集的次数
%% mythical_collect2_times  ---- 神兽岛凤血水晶已经采集的次数
%% collect_open_list        ---- 开启的宝箱个数
%% care_list                ---- 关注列表
%% max_type_id              ---- 世界boss最大击杀TypeID
%% is_guide                 ---- 是否指引过
%% hp_recover_list = [{map_id,num}|...]  ---- boss血量恢复次数
%% is_merge                 ---- 当前是否合并
%% merge_list               ---- [#p_kv{}|...]世界boss次数合并
-define(DB_ROLE_WORLD_BOSS_P, db_role_world_boss_p).
-record(r_role_world_boss, {role_id, times = 0, buy_times = 0, resume_times = 0, resume_time = 0, hp_recover_time = 0,
                            cave_times = 0, cave_assist_times = 0,
                            quit_time = 0,
                            mythical_times = 0, mythical_item_times = 0, mythical_collect_times = 0,
                            mythical_collect2_times = 0, collect_open_list = [], care_list = [], auto_care_id = 0, max_type_id = 0, is_guide = 0,
                            hp_recover_list = [], merge_times = 1, merge_list = []}).

%% 角色VIP
%% expire_time      ---- 过期时间
%% level            ---- VIP等级
%% exp              ---- 当前成长值
%% first_buy_list   ---- 是否初次购买
%% week_gift_time   ---- 周福利  -----10.16取消 改为日福利
%% day_gift_time    ---- 日福利
%% gift_list        ---- 领取的
-define(DB_ROLE_VIP_P, db_role_vip_p).
-record(r_role_vip, {role_id, expire_time = 0, level = 0, exp = 0, is_vip_experience = false, first_buy_list = [], day_gift_time = 0, gift_list = [],
                     v4_remind_time = 0}).

%% 角色称号
%% cur_title        ---- 当前佩戴称号
%% titles           ---- 拥有的称号[#p_kv{}|...] id:称号ID val:过期时间 0表示永不过期
-define(DB_ROLE_TITLE_P, db_role_title_p).
-record(r_role_title, {role_id, cur_title = 0, titles = []}).

%% 转生相关内容
%% relive_level     ---- 转生等级
%% progress         ---- 当前阶段
%% destiny_id       ---- 天命觉醒ID
%% talent_points    ---- 天赋点数
%% talent_skills    ---- 天赋技能
-define(DB_ROLE_RELIVE_P, db_role_relive_p).
-record(r_role_relive, {role_id, relive_level = 0, progress = 0, destiny_id = 0, talent_points = 0, talent_skills = []}).

%% 角色零碎数据
%% data = [{Key, Value}|.......]
-define(DB_ROLE_EXTRA_P, db_role_extra_p).
-record(r_role_extra, {role_id, data = []}).

%% 角色寻宝数据
-define(DB_ROLE_TREASURE_P, db_role_treasure_p).
-record(r_role_treasure, {role_id, equip_times = 0, equip_weight = 0, equip_logs = [], rune_free_time = 0, rune_single_times = 0, rune_times = 0,
                          summit_times = 0, summit_weight = 0, summit_logs = [], unlimited_times = 0, unlimited_weight = 0, unlimited_logs = []}).

%% 角色月卡 && 投资计划数据
%% login_days           ---- 月卡天数
%% invest_gold          ---- 当前投资的档次
%% invest_reward_list   ---- [#p_kv{}] id = 等级, val = 领取的档次
%% is_month_card_reward ---- 月卡奖励是否领取
%% month_card_days      ---- 月卡剩余奖励天数
%% is_vip_invest_reward ---- vip投资奖励是否能领取
%% vip_invest_level     ---- vip投资的档次
%% vip_invest_days      ---- vip投资剩余天数
%% is_vip_first_add     ---- 首次触发vipX可以免费投资一次喔
%% summit_invest_gold   ---- 化神投资元宝
%% summit_reward_list   ---- 化神投资奖励列表
-define(DB_ROLE_INVEST_P, db_role_invest_p).
-record(r_role_invest, {role_id, invest_gold = 0, invest_reward_list = [], is_month_card_reward = false, is_principal_reward = true, month_card_days = 0,
                        is_vip_invest_reward = false, vip_invest_level = 0, vip_invest_days = 0, is_vip_first_add = false, summit_invest_gold = 0, summit_reward_list = []}).

%% 角色成就数据
%% conditions  ---- [p_kv|...]
%% reward_list ---- [int32|...]
-define(DB_ROLE_ACHIEVEMENT_P, db_role_achievement_p).
-record(r_role_achievement, {role_id, conditions = [], reward_list = []}).

%% 角色天书数据
%% doing_list       ---- [#p_kvl{}|...]
%% reward_list      ---- [int32]
%% type_reward_list ---- [int32]
-define(DB_ROLE_GOD_BOOK_P, db_role_god_book_p).
-record(r_role_god_book, {role_id, doing_list = [], reward_list = [], type_reward_list = []}).

%% 角色日常活跃度数据
-define(DB_ROLE_DAILY_LIVENESS_P, db_role_daily_liveness_p).
%% liveness_list ----  完成活跃列表
%% liveness_list ----  领取奖励列表
-record(r_role_daily_liveness, {role_id, liveness = 0, liveness_list = [], got_reward = []}).

-define(DB_ROLE_SEVEN_DAY_P, db_role_seven_day_p).
-record(r_role_seven_day, {role_id, info = [], is_bc = true}).
-define(DB_ROLE_ACT_ONLINE_P, db_role_act_online_p).
-record(r_role_act_online, {role_id, reward = [], online_time = 0, open_time = 0}).

%%double_time 以内的时间为双倍时间
%%-define(DB_ROLE_FAIRY_P, db_role_fairy_p).
%%-record(r_role_fairy, {role_id, fairy = 0, times = 0, double_time = 0}).

-define(DB_ROLE_ACT_DAYRECHARGE_P, db_role_act_dayrecharge_p).
-record(r_role_act_dayrecharge, {role_id, recharge = 0, day_reward = [], count_reward = [], have_count = 0, count_recharge = 0, recharge_day = 1}).

-define(DB_ROLE_ACT_ACCRECHARGE_P, db_role_act_accrecharge_p).
-record(r_role_act_accrecharge, {role_id, start_time = 0, status = 2, recharge = 0, reward = []}).

-define(DB_ROLE_ACT_FIRSTRECHARGE_P, db_role_act_firstrecharge_p).
-record(r_role_act_firstrecharge, {role_id, pay_time = 0, reward_list = []}).


-define(DB_ROLE_ACT_ZEROPANICBUY_P, db_role_act_zeropanicbuy_p).
-record(r_role_act_zeropanicbuy, {role_id, buy_list = [], end_time = 0}).

-define(DB_ROLE_ACT_LUCKY_TOKEN_P, db_role_act_lucky_token_p).
-record(r_role_act_lucky_token, {role_id, remain_num = 0, level = 1, big_reward = 0, open_time = 0}).
%%招财猫
%% times 抽奖次数
-define(DB_ROLE_ACT_LUCKYCAT_P, db_role_act_lukcy_cat_p).
-record(r_role_act_lukcycat, {role_id, times = 0, open_time = 0}).

%%欢乐宝箱
-define(DB_ROLE_ACT_TREASURE_CHEST_P, db_role_act_treasure_chest_p).
-record(r_role_act_treasure_chest, {role_id, accrecharge = 0, reward = [], config_num = 0, open_time = 0}).

%%首充倍送
-define(DB_ROLE_ACT_FIRSTPAY_P, db_role_act_firstpay_p).
-record(r_role_act_firstpay, {role_id, goods_list = [], open_time = 0}).


%% 福利累充
%% reward_list [#p_kv{id = 充值金额, val = 是否领取} | ....]
-define(DB_ROLE_ACT_WELFARE_RECHARGE_P, db_role_act_welfare_recharge_p).
-record(r_role_act_welfare_recharge, {role_id, acc_recharge = 0, reward_list = [], open_time = 0}).

%% 特权卡
%% pay_card_list [#p_kv{recharge = 充值金额, is_buy, } | ....]
%% reward [#p_kv{recharge = 充值金额, is_reward, } | ....]
-define(DB_ROLE_PERMANENT_PRIVILEGE_P, db_role_role_permanent_privilege_p).
-record(r_role_permanent_privilege, {role_id, pay_card_list = [], reward = []}).

%% 首充改版
-define(DB_ROLE_ACT_FIRST_DEPOSIT_P, db_role_act_first_deposit_p).
-record(r_role_act_first_deposit, {role_id, pay_time = 0, acc_recharge = 0, reward = []}).

-define(DB_ROLE_LEVELPANICBUY_P, db_role_levelpanicbuy_p).
-record(r_role_levelpanicbuy, {role_id, buy_list = []}).

%% 每日限时购买
%% buy_list     ---- [#p_kv{}|...]
%% finish_ids   ---- [ID|...]
-define(DB_ROLE_DAILY_BUY_P, db_role_daily_buy_p).
-record(r_role_daily_buy, {role_id, buy_list = [], finish_ids = []}).

-define(DB_ROLE_IMMORTAL_SOUL_P, db_role_immortal_soul_p).
-record(r_role_immortal_soul, {role_id, use_list = [], bag_list = [], reserve_bag_list = [], auto_bd_type = 0, dust = 0, stone = 0}).

%%  war_spirit_change - 切换战灵时间戳 10CD时间防止刷战灵技能
%% lock_info [#p_war_armor_lock{war_spirit_id, #p_war_armor_lock_info{}}|]
-define(DB_ROLE_CONFINE_P, db_role_confine_p).
-record(r_role_confine, {role_id, mission_list = [], confine,
                         war_spirit = 0, war_spirit_list = [], war_spirit_change = 0, refine_all_exp = 0, bag_id = 1, bag_list = [], war_god_list = [], war_god_pieces = [], confine_reward = [], lock_info = []}).


-define(DB_ROLE_ACT_HUNT_BOSS_P, db_role_act_hunt_boss_p).
-record(r_role_act_hunt_boss, {role_id, start_date = 0, hunt_boss_score = 0, reward_list = []}).


%% is_sign              ---- 今天是否签到
%% sign_times           ---- 当前签到次数
%% times_reward_list    ---- 已经领取的总次数奖励
%% 角色签到数据
-define(DB_ROLE_ACT_SIGN_P, db_role_act_sign_p).
-record(r_role_act_sign, {role_id, is_sign = false, sign_times = -1, times_reward_list = []}).

%% 角色冲级奖励
-define(DB_ROLE_ACT_LEVEL_P, db_role_act_level_p).
-record(r_role_act_level, {role_id, reward_level_list = []}).

%% 角色仙盟活动相关
%% create_list          ---- [#p_kv{}|...]
%% battle_list          ---- [#p_kv{}|...]
-define(DB_ROLE_ACT_FAMILY_P, db_role_act_family_p).
-record(r_role_act_family, {role_id, create_condition_list = [], battle_condition}).

%% 后台角色节日数据
%% reward_list          ---- 对应活动奖励列表
%%  *_time              ---- 对应活动变化时间以此判别是否同一活动以初始化或更新
-define(DB_ROLE_ACT_FEAST_P, db_role_act_feast_p).
-record(r_role_act_feast, {role_id, regression_reward_list = [], regression_time = 0, pay_gold = 0, pay_reward_list = [], pay_time = 0, entry_list = [], entry_time = 0,
                           consume_time = 0, consume_reward_list = [], consume_gold = 0, recharge_reward = 1, recharge_reward_time = 0}).

%% 后台活动类商店
%%  store_time              ---- 对应活动变化时间以此判别是否同一活动以初始化或更新
-define(DB_ROLE_BG_STORE_P, db_role_bg_store_p).
-record(r_role_bg_store, {role_id, store_time = 0, buy_list = []}).

%% 后台活动类任务
%%  mission_time              ---- 对应活动变化时间以此判别是否同一活动以初始化或更新
%%  money                     ---- 对应活动货币
-define(DB_ROLE_BG_MISSION_P, db_role_bg_mission_p).
-record(r_role_bg_mission, {role_id, mission_time = 0, mission_list = [], reward_list = [], money = 0}).


%% 后台活动类许愿池
%%  edit_time              ---- 对应活动变化时间以此判别是否同一活动以初始化或更新
%%  integral                     ---- 对应活动货币
%%  notice                       ---- 大奖池空后前端是否提醒
-define(DB_ROLE_TREVI_FOUNTAIN_P, db_role_trevi_fountain_p).
-record(r_role_trevi_fountain, {role_id, edit_time = 0, reward = [], integral = 0, bless = 0, reward_list = [], notice = true}).

%% 后台活动类炼金术
%%  edit_time                    ---- 对应活动变化时间以此判别是否同一活动以初始化或更新
%%  lucky                        ---- 幸运值
-define(DB_ROLE_ALCHEMY_P, db_role_alchemy_p).
-record(r_role_bg_alchemy, {role_id, edit_time = 0, lucky = 0, big_reward = 0}).

%% 后台活动类转盘
%%  a  ----   活跃转盘  b  ----  付费转盘
%%  online_time  ----   秒
%%  reward_a  ----      已得
-define(DB_ROLE_TURNTABLE_P, db_role_turntable_p).
-record(r_role_bg_turntable, {role_id, edit_time_a = 0, mission_a = [], draw_times_a = 0, reward_a = [], online_time = 0,
                              edit_time_b = 0, mission_b = [], draw_times_b = 0, recharge_num = 0}).

%% 角色实名&&防沉迷信息
%% is_auth              ---- 是否验证过
%% is_passed            ---- 是否通过
%% last_remain_min      ---- 上次提醒的分钟数
%% reduce_rate          ---- 收益衰减比例
%% is_tourist           ---- 是否进行游客模式
%% can_tourist          ---- 能否进行游客模式
%% tourist_time         ---- 开始游客模式时间
%% pay_money            ---- 本月支付
%% pay_time             ---- 本月时间

-define(DB_ROLE_ADDICT_P, db_role_addict_p).
-record(r_role_addict, {role_id, is_auth = false, is_passed = false, last_remain_min = 0, reduce_rate = 0, age = 0, is_tourist = false, can_tourist = true, tourist_time = 0,
                        pay_money = 0, pay_time = 0}).

%% chapter_list         ---- [#p_chapter{}|...]
-define(DB_ROLE_CHAPTER_P, db_role_chapter_p).
-record(r_role_chapter, {role_id, chapter_list = []}).

%% couple_id            ---- 仙侣ID
%% couple_name          ---- 情侣（仙侣）名字
%% knot_id              ---- 同心结id
%% knot_exp             ---- 同心结经验
%% marry_title_ids      ---- 仙侣称号
-define(DB_ROLE_MARRY_P, db_role_marry_p).
-record(r_role_marry, {role_id, couple_id = 0, couple_name = "", knot_id = 0, knot_exp = 0, marry_title_ids = [], act_marry_three_life = [], three_life_achieve = 0}).

%% 7日目标
%% day_target_list      ---- 当前触发的[#p_kdv{}|....]
%% reward_list          ---- 已经领取奖励的id[int32|...]
%% progress_reward_list ---- 已经领取的进度奖励[int32|...]
-define(DB_ROLE_DAY_TARGET_P, db_role_day_target_p).
-record(r_role_day_target, {role_id, day_target_list = [], reward_list = [], progress_reward_list = []}).

-define(DB_ROLE_WARNING_P, db_role_warning_p).
-record(r_role_warning, {role_id, item_action_list = [], item_gain_list = [], asset_action_list = [], asset_gain_list = [], warning_list = []}).


%% 神兽装备
%% id           ---- 自增ID
%% soul_num     ----
%% soul_list    ---- 激活的神兽列表[#p_mythical_soul|...]
%% bag_list     ---- 背包里的装备列表[#p_mythical_equip|...]
-define(DB_ROLE_MYTHICAL_EQUIP_P, db_role_mythical_equip_p).
-record(r_role_mythical_equip, {role_id, id = 1, soul_num = 0, soul_list = [], bag_list = []}).

%% 角色套装数据
%% equip_list       -- [#p_suit{}]
-define(DB_ROLE_SUIT_P, db_role_suit_p).
-record(r_role_suit, {role_id = 0, suit_list = []}).

%% 天机系统
%% quality          ---- 自动分解品质
%% goods            ---- 物品
%% aperture_id      ---- 孔部id
%% type             ---- 类型，阴阳
%% refine_id        ---- 强化等级id
%% history          ---- 使用历史
%% consume_money    ---- 强化用到的道具数量
%% book_list        ---- 拥有过的图鉴
%% nature = [#r_nature{}|_]
-define(DB_ROLE_NATURE_P, db_role_nature_p).
-record(r_nature, {aperture_id = 0, type = 0, refine_id = 0, goods = [], history = []}).
-record(r_role_nature, {role_id = 0, nature = [], quality = 0, star = 0, consume_money = 0, book_list = []}).

%% 丹药系统
%% goods_id         ---- 物品id
%% num              ---- 使用的数量
%% stop_time        ---- 限时的结束
-define(DB_PELLET_MEDICINE_P, db_pellet_medicine_p).
-record(r_pellet_medicine, {goods_id = 0, type = 0, num = 0, start_time, stop_time = 0}).
-record(r_role_pellet_medicine, {role_id = 0, pellet_medicine = []}).

%% 鉴宝活动
%% it_num           ---- 取稀有次数
%% luck             ---- 幸运值
%% limit            ---- 投入限制
-define(DB_ROLE_IT_P, db_role_it_p).
-record(r_role_it, {role_id = 0, it_num = 1, luck = 0, limit = 0, open_time = 0}).

%% 黑市鉴宝
%% use_count            ---- 使用鉴宝次数
%% consume          ---- 消费额度
%% consume_fairy    ----消费仙玉额度
%% history          ---- 历史记录
-define(DB_ROLE_CHOOSE_P, db_role_choose_p).
-record(r_role_choose_p, {role_id = 0, use_count = 0, consume = 0, consume_fairy = 0, open_time = 0, history = []}).

%% 修炼秘籍系统
%% training_grade           ---- 修炼等级
%% experience               ---- 经验
%% ordinary_grade           ---- 已经领取奖励凡等级
%% celestial_grade          ---- 已经领取奖励仙等级
%% is_activate              ---- 仙，1：激活；0：否
%% task_time                ---- 任务时间
%% task_list = [r_act_esoterica_task]      ---- 随机任务库
%% mission_list = [#r_act_esoterica_mission] -- 条件任务库
%% retrieve                 ---- 找回
%% config_num               ---- 套序号
-define(DB_ROLE_ACT_ESOTERICA_P, db_role_act_esoterica_p).
-record(r_role_act_esoterica, {role_id = 0, training_grade = 0, experience = 0, ordinary_grade = [], celestial_grade = [],
                               is_activate = 0, task_list = [], mission_list = [], retrieve = 0, open_time = 0, task_time = 0, config_num = 0}).
%% 任务结构
%% task_id                  ---- 当前系统任务id
%% is_reward                ---- 当天奖励是否领取
%% mission_id               ---- 条件任务id
%% expedite                 ---- 已完成的次数
-record(r_act_esoterica_task, {task_id = 0, is_reward = false}).
-record(r_act_esoterica_mission, {mission_id = 0, expedite = 0}).

%% 情缘活动数据
%% open_time            ---- 重置时间
%% login_reward1        ---- 一见钟情登录奖励状态1
%% login_reward2        ---- 一见钟情登录奖励状态2
%% charm                ---- 活动期间内增加的魅力值
%% propose_status_list  ---- 告别单身奖励领取状态
%% pray_times           ---- 月下情缘祈求次数，保底需要
%% pray_score           ---- 月下情缘积分
%% pray_exchange_list   ---- 月下情缘兑换列表
-define(DB_ROLE_CYCLE_ACT_COUPLE_P, db_role_cycle_act_couple_p).
-record(r_role_cycle_act_couple, {
    role_id,
    open_time = 0,
    login_reward1 = false,
    login_reward2 = false,
    charm = 0,
    propose_status_list = [],
    pray_times = 0,
    pray_score = 0,
    pray_exchange_list = []
}).
%%%===================================================================
%%% role 相关数据 end
%%%===================================================================


%%%===================================================================
%%% world 相关数据 start
%%%===================================================================
%% 账号 -> 角色表
-define(DB_ACCOUNT_ROLE_P, db_account_role_p).
-record(r_account_role, {account, role_id_list = []}).

%% role_id -> 账号表
-define(DB_ROLE_ACCOUNT_P, db_role_account_p).
-record(r_role_account, {role_id, account}).

%% name -> role_id(预留可能出现曾用名的情况)
-define(DB_ROLE_NAME_P, db_role_name_p).
-record(r_role_name, {role_name, role_id}).

%% offline event
%% event_list -> [{M, F, A}|...]
-define(DB_OFFLINE_EVENT_P, db_offline_event_p).
-record(r_role_offline_event, {role_id, event_list = []}).

%% 邮箱
-define(DB_WORLD_LETTER_P, db_world_letter_p).
-record(r_world_letter, {role_id, counter = 1, receive_box = []}).

%% 好友
%% friend_list      ---- 好友列表
%% request_list     ---- 好友申请列表
%% black_list       ---- 黑名单列表
%% chat_list        ---- 私聊列表
-define(DB_WORLD_FRIEND_P, db_world_friend_p).
-record(r_world_friend, {role_id, friend_list = [], request_list = [], black_list = [], chat_list = []}).
-record(r_friend, {role_id, friendly = 0}).

%% 仙盟
-define(DB_FAMILY_P, db_family_p).
%%
-define(DB_FAMILY_BOX_P, db_family_box_p).
-record(r_family_box, {family_id, role_box_list = []}).
-record(r_box_list, {role_id, max_num, box_list = []}).

-define(DB_FAMILY_NAME_P, db_family_name_p).
-record(r_family_name, {family_name, family_id}).

-define(DB_ROLE_FAMILY_P, db_role_family_p).
-record(r_role_family, {role_id = 0, family_id = 0, family_name = "", apply_list = []}).

%% 道庭任务
%% mission_id   ---- 任务id
%% type         ---- 0:可接,1:可请求加速,2:已请求加速,3:待领取奖励,4:放弃
%% expedite     ---- 已加速次数
%% accept_time  ---- 接任务时间
%% start_time   ---- 开始时间
%% stop_time    ---- 结束时间
%% is_help      ---- 是否请求帮助
%% attend = [roleID|...]        ---- 帮助列表
%% nonsuch_time                 ---- 极品时间(作为刷新时间用)
%% accept = [r_family_mi]       ---- 可接任务
%% under_way = [r_family_mi]    ---- 进行中任务
%% reward = [r_family_mi]       ---- 待领奖的任务
%% history = [r_family_mi]      ---- 已经完成任务
-define(DB_FAMILY_ASM_P, db_family_asm_p).
-record(r_family_mi, {mission_id = 0, type = 0, expedite = 0, accept_time = 0, start_time = 0, stop_time = 0, is_help = 0, attend = []}).
-record(r_role_family_mi, {role_id = 0, nonsuch_time = 0, accept = [], under_way = [], reward = [], history = []}).

%% 排行
-define(DB_RANK_P, db_rank_p).
-record(r_rank, {rank_id, ranks = []}).

%% 世界boss
%% type_id      ---- boss_ID
%% boss_extra   ---- 部分世界boss需要额外的数据
-define(DB_WORLD_BOSS_P, db_world_boss_p).
-record(r_world_boss, {type_id, is_remind = false, is_alive = false, next_refresh_time = 0, kill_list = [], boss_extra}).
-record(r_world_boss_kill, {kill_role_id = 0, kill_role_name = "", time = 0}).
%% 第一个boss额外数据
%% reward_time      --- 结算奖励时间
%% reward_roles     --- 结算奖励人数[RoleID|...]
%% online_roles     --- 在线人数[RoleID|...]
-record(r_first_boss, {reward_time = 0, reward_roles = [], online_roles = []}).

%% 1v1 solo
%% rank                     ---- 排名
%% score                    ---- 当前积分
%% break_time               ---- 积分更新时间
%% extra_id                 ---- 地图分线
%% is_matching              ---- 是否在匹配中
%% is_fighting              ---- 是否可以战斗
%% season_win_times         ---- 赛季胜利场次
%% enter_times              ---- 今天参与次数
%% season_enter_times       ---- 赛季参与次数
%% exp                      ---- 当天获得经验
%% combo_win                ---- 连续胜利次数
%% enter_reward_list        ---- 当天已经领取参与奖励列表
%% step_reward_list         ---- 已领取段位奖励
-define(DB_ROLE_SOLO_P, db_role_solo_p).
-record(r_role_solo, {role_id, break_time = 0, score = 0, rank = 0, extra_id = 0, is_matching = false, is_fighting = false, season_win_times = 0,
                      season_enter_times = 0, exp = 0, enter_times = 0, combo_win = 0, enter_reward_list = [], step_reward_list = []}).

%% 离线1v1 offline_solo
-define(DB_ROLE_OFFLINE_SOLO_P, db_role_offline_solo_p).
-record(r_role_offline_solo, {role_id, rank = 0, reward_rank = 0, is_reward = true, challenge_times = 10, buy_times = 0, bestir_times = 0}).

%% 离线1v1 机器人存储信息
-define(DB_ROBOT_OFFLINE_SOLO_P, db_robot_offline_solo_p).
-record(r_robot_offline_solo, {robot_id, name, sex, category, level, hp, power}).

%% 机器人相关信息
-define(DB_ROLE_ROBOT_P, db_role_robot_p).
-record(r_role_robot, {role_id, robot_id, fight_status = 1, map_id = 0, monster_type_id = 0, extra_id = 0, min_point, max_point, last_offline_time = 0, start_fight_time = 0, has_time = 0}).

%% 充值相关信息
%% pf_order_id      ---- string
-define(DB_PAY_LOG_P, db_pay_log_p).
-record(r_pay_log, {order_id, pf_order_id = 0, is_finish = true, role_id, time, product_id, total_fee}).

%% 封禁、禁言相关信息
-define(DB_ROLE_BAN_P, db_role_ban_p).
-record(r_role_ban, {role_id, ban_list = []}).
-record(r_ban, {type = 0, end_time = 0}).

%% 拍卖市场
%% type_id道具表ID
-define(DB_SELL_MARKET_P, db_sell_market_p).
-record(r_sell_market, {id, time = 0, role_id, unit_price = 0, total_price = 0, num = 0, password = "", type_id, excellent_list = []}).

%% 求购市场
-define(DB_DEMAND_MARKET_P, db_demand_market_p).
-record(r_demand_market, {id, time = 0, role_id, role_name, unit_price = 0, total_price = 0, num = 0, password = "", type_id, excellent_list = []}).


%% 用户市场数据
-define(DB_ROLE_MARKET_P, db_role_market_p).
-record(r_role_market, {role_id, prohibit_time = 0, error_times = 0, error_goods = 0, error_time = 0, last_search_time = 0, sell_grid = [], demand_grid = [], demand_bc = 0, log = []}).


%% 用户周卡数据       %%  周卡  改名基金
-define(DB_ROLE_WEEK_CARD_P, db_role_week_card_p).
-record(r_role_week_card, {role_id, card_list = []}).


%% 用户红包  role_red_packet
-define(DB_ROLE_RED_PACKET_P, db_role_red_packet_p).
-record(r_role_red_packet, {role_id, red_packet = [], red_packet_num = 0}).


%% 新护送
-define(DB_ROLE_ESCORT_P, db_role_escort_p).
%%  rob_role_id  抢夺者ID   0则无人抢夺  2-自己抢回 3-盟友抢回  其他-抢夺者ID
%%  fight战斗力
%%  fairy_type       护送战灵
%%  护送结束时间     护送战灵
%%  reward     是否可领  1-是  0-否
%%  help       0-没有请求帮助 1-发送请求帮助时间戳
-record(r_role_escort, {role_id, name = "", escort_id = 0, escort_times = 0, rob_times = 0, fairy_type = 1000, fight = 0,
                        end_time = 0, log = [], rob_role_id = 0, reward = 0, help = 0, family = 0, family_title = 1, server_name = ""}).


%% 君海日志
-define(DB_JUNHAI_LOG_P, db_junhai_log_p).
-record(r_junhai_log, {id, time, log}).

%% 用户结婚相关数据
%% couple_id            ---- 情侣ID
%% tree_end_time        ---- 婚缘树结束时间
%% tree_active_reward   ---- 激活奖励是否可以领取 true:可以领取 false:不能领取
%% tree_daily_time      ---- 上次领取姻缘树日常的时间
%% propose_id           ---- 提亲对象
%% propose_end_time     ---- 提亲结束时间
%% be_propose_list      ---- 被XXX提亲
-define(DB_MARRY_DATA_P, db_marry_data_p).
-record(r_marry_data, {role_id, couple_id = 0,
                       tree_end_time = 0, tree_active_reward = false, tree_daily_time = 0,
                       propose_id = 0, propose_type = 0, propose_end_time = 0, be_propose_list = []}).


%% 婚姻共享数据
%% share_id             ---- {RoleID1, RoleID2} RoleID1 > RoleID2
%% marry_time           ---- 结婚时间
%% feast_times          ---- 可举行婚礼的次数
%% feast_hour           ---- 婚礼什么时候举行
%% extra_guest_num      ---- 额外的宾客数
%% is_buy_join          ---- 是否购买进入
%% guest_list           ---- 邀请的宾客列表[RoleID1..RoleID2]...
%% apply_guest_list     ---- 申请的宾客列表[#r_feast_apply{}...]
-define(DB_SHARE_MARRY_P, db_share_marry_p).
-record(r_marry_share, {share_id, marry_time = 0, feast_times = 0, feast_start_time = 0, extra_guest_num = 0, is_buy_join = true, guest_list = [], apply_guest_list = []}).
%% status               ---- false表示没有拒绝，true表示已经拒绝过
-record(r_feast_apply, {role_id, is_refuse = false, times = 0}).

%% 拍卖行全局数据
%% id                   ---- 拍卖唯一ID
%% type_id              ---- 道具ID
%% num                  ---- 拍卖数据
%% excellent_list       ---- 装备的卓越属性
%% auction_time         ---- 可以竞拍的时间
%% end_time             ---- 结束竞拍的时间
%% cur_gold             ---- 当前竞拍的金额
%% auction_role_id      ---- 当前竞价的玩家
%% from_type            ---- 来源 0:玩家（默认） 1:道庭
%% from_id              ---- 来源者的ID
%% from_args            ---- 不同来源的参数不同
-define(DB_AUCTION_GOODS_P, db_auction_goods_p).
-record(r_auction_goods, {id, type_id, num, excellent_list, auction_time, end_time, cur_gold, auction_role_id = 0, from_type = 0, from_id, from_args}).

%% 拍卖行个人数据
%% auction_goods        ---- [id|....]
%% sell_logs            ---- [#r_auction_log{}|.....]
%% buy_logs             ---- [#r_auction_log{}|.....]
%% care_type_ids        ---- [id|...]
-define(DB_ROLE_AUCTION_P, db_role_auction_p).
-record(r_role_auction, {role_id, auction_goods_ids = [], sell_logs = [], buy_logs = [], care_type_ids = []}).

%% 拍卖行道庭相关数据
%% auction_goods        ---- [id|....]
%% sell_logs            ---- [#r_auction_log{}|.....]
-define(DB_FAMILY_AUCTION_P, db_family_auction_p).
-record(r_family_auction, {family_id, sell_logs = []}).
%% 日志数据
%% time                 ---- 时间
%% type_id              ---- 道具ID
%% num                  ---- 拍卖数据
%% gold                 ---- 竞拍价格
-record(r_auction_log, {time, type_id, num, gold}).

%% 用户图鉴数据
-define(DB_ROLE_HANDBOOK_P, db_role_handbook_p).
-record(r_role_handbook, {
    role_id,                        %% 用户id
    essence = 0,                    %% 精华
    handbook_maps = maps:new(),     %% 已经激活的图鉴数据key->卡片组Id, value->maps (value中的maps的key-> 卡片id, value->卡片养成表id)
    handbook_group_maps = maps:new()%% 已经激活的图鉴key->卡片组Id, value-> list: 已激活的图鉴阶段id列表
}).

%% 用户藏宝图数据
-define(DB_ROLE_HUNT_TREASURE_P, db_role_hunt_treasure_p).
-record(r_role_hunt_treasure, {role_id, end_time = 0, event_id = 0, type_id, map_id, int_pos}).

%% 聊天历史记录
%% --- 好友聊天
%% role_or_type_id     --- 角色id
%% chat_history = [{channel_type,[#p_chat_history{}]}|...]
%% --- 公共聊天
%% role_or_type_id     --- #p_chat_history.channel_type
%% chat_history = [[#p_chat_history{}]|...]
-define(DB_CHAT_HISTORY_P, db_chat_history_p).
-record(r_chat_history, {role_or_type_id, chat_history = []}).

%% 秘境探索（挖矿）
%% --- 格子信息
%% pos              ---- 坐标
%% type_id          ---- 配置表id
%% gather_num       ---- 剩余采集次数
%% renovate_time    ---- 采完格子重置时间
%% mining_role_id   ---- 在格子里的玩家 undefined || RoleID
%% gather_history   ---- 曾经采集过的玩家历史
-define(DB_MINING_LATTICE_P, db_mining_lattice_p).
-record(r_mining_lattice, {pos, type_id = 0, gather_num = 0, renovate_time = 0, mining_role_id, gather_history = []}).

%% --- 挖矿的玩家信息
%% role_id          ---- 角色id
%% role_name        ---- 角色名
%% category         ---- 职业
%% sex              ---- 性别
%% family_id        ---- 道庭id
%% power            ---- 战斗力
%% pos              ---- 坐标
%% gather_num       ---- 已经采集次数
%% gather_stop      ---- 采集结束时间
%% shift_num        ---- 移动次数
%% inspire          ---- 鼓舞次数
%% shift_history    ---- 已经探索的格子信息
%% plunder_history  ---- 掠夺历史[#p_ks{}|...]
%% goods_list       ---- 资源创库
%% r_mining_status 记录挖矿状态
-define(DB_MINING_ROLE_P, db_mining_role_p).
-record(r_mining_status, {id = 6582, stop_time = 0, status = 3}).
-record(r_mining_role, {
    role_id = 0,
    role_name = "",
    category = 0,
    sex = 0,
    family_id = 0,
    power = 0,
    pos = {0, 0},
    gather_num = 0,
    gather_stop = 0,
    shift_num = 0,
    inspire = 0,
    shift_history = [],
    plunder_history = [],
    goods_list = [],
    is_family_add = false
}).
%%%===================================================================
%%% world 相关数据 end
%%%===================================================================
-define(DB_R_BG_ACT_P, db_r_bg_act_p).
%% 活动的r结构
-record(r_bg_act, {
    id,                           %% 活动ID
    bg_id,                        %% 后台ID
    world_level = 0,              %% 活动开启时世界等级
    is_gm_set = false,           %% GM设置活动状态
    template = 0,                 %% 活动
    edit_time = 0,                %% 活动最后变更时间
    start_time = 0,               %% 开始时间
    end_time = 0,                 %% 结束时间
    start_date = 0,               %% 开始日期时间戳
    end_date = 0,                 %% 结束日期时间戳
    start_day_time = 0,           %% 每天开启时的秒数
    end_day_time = 0,             %% 每天结束的秒数
    status = 3,                   %% 状态
    is_visible = false,          %% 是否显示
    icon = 1,                     %% 图标 直传前端
    icon_name = "",               %% 图标名 直传前端
    channel_id = "",
    game_channel_id = "",
    title = "",                   %%标题
    min_level = 0,                %%等级
    explain = "",                 %%文字
    explain_i = "",               %%叹号说明
    background_img = "",
    bc_pid = [],                  %%活动状态变化时需通知PID列表
    sort = 0,
    config_list = [],             %%具体活动配置视活动而定
    config = []                   %%具体活动配置视活动而定
}).

-define(DB_R_CYCLE_ACT_P, db_r_cycle_act_p).
%% 活动的r结构
-record(r_cycle_act, {
    id,                                  %% 活动ID
    is_gm_set = false,                  %% GM设置活动状态
    open_type = 0,                       %% 活动开启方式开启方式
    level = 0,                           %% 活动开启等级
    start_time = 0,                      %% 开始时间
    end_time = 0,                        %% 结束时间
    first_day_open = false,             %% 第一天是否有开启
    config_num = 1,                      %% 配置序号（套序号）
    status = 2                           %% 状态
}).


%% Boss悬赏
-define(DB_ROLE_BOSS_REWARD_P, db_role_boss_reward_p).
-record(r_role_boss_reward, {role_id, grade = 1, kill_num = 0, got_reward = false}).

%% 用户图鉴数据
-define(DB_ROLE_THRONE_P, db_role_throne_p).
-record(r_role_throne, {
    role_id,                        %% 用户id
    throne_id = 0,                  %% 当前宝座
    cur_id = 0,                     %% 当前幻化的Id
    throne_essence = 0,             %% 宝座精华
    accum_essence = 0,              %% 宝座升级使用累加精华
    status = 0,                     %% 状态，0-隐藏，1-使用
    throne_map = maps:new(),        %% 激活的宝座maps,  key-宝座基础表id, value-#p_kv{宝座等级表id, 升级累加的精华}
    surface_map = maps:new()        %% 已激活的宝座幻化maps, key-幻化基础表id, value-#p_kv{幻化外观表id, 当前已消耗的道具}
}).

%% 第二阶段开服活动
-define(DB_ROLE_SECOND_ACT_P, db_role_second_act_p).
-record(r_role_second_act, {
    role_id,                        %% 用户id
    oss_rank_type = 0,            %% 冲榜活动类型
    rank_reward = [],               %% 榜单奖励
    rank = 0,                       %% 最终排名s
    power_reward = [],              %% 战力奖励
    panic_buy = [],                 %% 抢购
    mana = 0,                       %% 灵力
    mana_reward = [],               %% 灵力奖励表
    recharge_reward = [],           %% 累充
    task_list = [],                 %% 任务进度
    recharge = 0,                   %% 充值总额


    seven_day_invest = false,       %% 七天投资是否开启
    seven_day_list = [],             %% 七天投资是否开启
    limited_panic_buy = [],          %% 限时抢购
    trevi_fountain_bless = 0,        %% 祝福值
    trevi_fountain_score = 0,        %% 积分
    trevi_fountain_reward = [],      %% 已领奖励列表
    trevi_fountain_good_reward = [], %% 珍稀奖励
    notice = true                   %%  珍稀奖励不存提醒
}).


%% 开服仙途活动
-define(DB_ROLE_ACT_OTF_P, db_role_act_otf_p).
-record(r_role_act_otf, {role_id, reward_list = [], mission_list = [], score = 0}).


%% treasure_trove   后台宝藏
%%  open_list_one  id  =  pos   val = type , type =  掉落ID
-define(DB_ROLE_BG_TT_P, db_role_bg_tt_p).
-record(r_role_bg_tt, {role_id, open_list_one = [], choice_list_one = [], open_list_two = [], choice_list_two = [], tta_edit_time = 0, open_layer = 1,
                       buy_list = [], ttc_edit_time = 0,
                       init_power = 0, ttb_edit_time = 0, check_point = 1}).


%% treasure_trove  配置商店
-define(DB_ROLE_ACT_STORE_P, db_role_act_store_p).
-record(r_role_act_store, {role_id, buy_list = [], start_date = 0}).


%% 新炼丹炉系列
-define(DB_ROLE_NEW_ALCHEMY_P, db_role_new_alchemy_p).
-record(r_role_new_alchemy, {role_id, schedule = 0, times = 0}).

%% 新炼丹炉系列
-define(DB_ROLE_MONEY_TREE_P, db_role_money_tree_p).
-record(r_role_money_tree, {role_id, times = 0, log = []}).


%% 每周后台活动加于此处
-define(DB_ROLE_BG_EXTRA_P, db_role_bg_extra_p).
-record(r_role_bg_extra, {role_id, data = []}).

%%   act  活动初始化时间
-define(DB_ACT_INIT_TIME_P, db_act_init_time_p).
-record(r_act_init_time, {act_id, time = 0}).

%% 每日宝箱
-define(DB_ROLE_DAY_BOX_P, db_role_day_box_p).
-record(r_role_day_box, {role_id, start_time = 0, list = []}).


%% 月循环活动混合           目前只有砸蛋
%% egg_refresh              砸蛋可刷新次数
%% egg_times                历史砸蛋次数
%% egg_weight_times         刷新蛋累计 权重次数
%% open_egg_weight_times    砸蛋累计 权重次数
%% egg_list                 当前蛋列表

-define(DB_ROLE_CYCLE_ACT_EXTRA_P, db_role_cycle_act_extra).
-record(r_role_cycle_act_extra, {role_id, start_egg_time = 0, egg_refresh = 0, egg_refresh_time = 0, egg_times = 0,
                                 egg_list = [], egg_reward = [], egg_weight_times = 0, today_add_refresh_time = 0, open_egg_weight_times = 0}).

%%  cycle数据
-define(DB_ROLE_CYCLE_MISC_P, db_role_cycle_misc).
-record(r_role_cycle_misc, {role_id, data = []}).

%%  周期活动任务
-define(DB_ROLE_CYCLE_MISSION_P, db_role_cycle_mission).
-record(r_role_cycle_mission, {role_id, start_time = 0, mission_list = [], reward_list = [], money = 0}).


%%   通天宝塔
%%   times  抽奖次数
%%   layer  层数
-record(r_role_cycle_tower, {times = 0, layer = 1, pool = 1, start_time = 0}).


%% 用户祈福数据
-define(DB_ROLE_BLESS_P, db_role_bless_p).
-record(r_role_bless, {role_id, today_times = 0, times = 0, add_times = 0, power_add = 0, war_spirit_add = 0, level_add = 0, settle_time = 0}).


%%%===================================================================
%%% cross数据库 start
%%%===================================================================
-define(DB_ROLE_CROSS_DATA_P, db_role_cross_data_p).
-record(r_role_cross_data, {role_id, role_name, sex, level, category, vip_level, server_name, skin_list = [], power = 0, channel_id = 0, game_channel_id = 0,
                            family_id = 0, family_name = "", fight_attr = #actor_fight_attr{}}).
%%%===================================================================
%%% cross数据库 stop
%%%===================================================================


%%%===================================================================
%%% center数据库 start
%%%===================================================================
-define(DB_CENTER_ADDICT_P, db_center_addict_p).
%% key由{AgentID, GameChannelID, UID}组成
-record(r_center_addict, {key, is_auth = false, is_passed = false, age = 0}).

-define(DB_CENTER_CREATE_P, db_center_create_p).
%% key由{AgentID, GameChannelID, UID}组成
-record(r_center_create, {key, first_server_id}).

%% 中央服保存的游戏服的拓扑
-define(DB_GAME_TOPOLOGY_P, db_game_topology_p).
-record(r_game_topology, {node_id, cross_id, cross_ip}).

%% 中央服保存的跨服的拓扑
-define(DB_CROSS_TOPOLOGY_P, db_cross_topology_p).
-record(r_cross_topology, {node_id, power, game_node_id_list = []}).

%% 中央服保存的太虚通天塔的数据
-define(DB_COPY_UNIVERSE_P, db_copy_universe_p).
%% key
%% value
-record(r_universe, {key, value}).
%% 最快通关记录
-record(r_universe_floor, {
    copy_id,                %% 副本ID
    fast_role_id = 0,       %% 最快通关的RoleID
    fast_role_name = "",    %% 最快通关的玩家名
    fast_server_name = "",  %% 最快通关服务器名字
    use_time,               %% 最快用时
    power_role_id = 0,      %% 最低战力通关玩家RoleID
    power_role_name = "",   %% 最低战力通关玩家名字
    power_server_name = "", %% 最低战力服务器名字
    power                   %% 最低战力
}).

%% 排行榜信息
-record(r_universe_rank, {
    rank = 0,
    role_id,
    role_name = "",
    server_name = "",
    confine_id = 1000,
    copy_id = 0,
    use_time = 0,
    category = 0,
    sex = 0,
    level = 0,
    skin_list = []
}).

-define(DB_CYCLE_ACT_COUPLE_RANK_P, db_cycle_act_couple_rank_p).
%% key = {Data, Sex}
%% rank_list = [#r_charm_rank{}|...]
-record(r_cycle_act_couple_rank, {key, rank_list = []}).
-record(r_charm_rank, {
    rank = 0,
    role_id = 0,
    role_name = "",
    category = 0,
    sex = 0,
    charm = 0,
    server_name = "",
    update_time = 0
}).

%%%===================================================================
%%% center数据库 end
%%%===================================================================

%%%===================================================================
%%% all start
%%%===================================================================
%% world_data key -> value
-define(DB_WORLD_DATA_P, db_world_data_p).
-record(r_world_data, {key, val}).

-define(DB_NODE_MSG_P, db_node_msg_p).
-record(r_node_info, {node, counter = 1, seq = 1, ack = 1, send_msg_list = [], receive_msg_list = []}).
-record(r_msg_info, {counter, info, time}).

-record(r_background_log_p, {id, key, log_id, time, agent_id, server_id, info}).
-define(DB_BACKGROUND_LOG_P, db_background_log_p).
%%%===================================================================
%%% all end
%%%===================================================================



-define(TABLE_INFO, [
    %% 游戏节点独有的数据库
    #c_tab{tab = ?DB_ROLE_ATTR_P, node = game, class = {role, #r_role.role_attr}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_PRIVATE_ATTR_P, node = game, class = {role, #r_role.role_private_attr}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_FIGHT_P, node = game, class = {role, #r_role.role_fight}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ASSET_P, node = game, class = {role, #r_role.role_asset}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_PAY_P, node = game, class = {role, #r_role.role_pay}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MAP_P, node = game, class = {role, #r_role.role_map}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MAP_PANEL_P, node = game, class = {role, #r_role.role_map_panel}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MISSION_P, node = game, class = {role, #r_role.role_mission}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_WARNING_P, node = game, class = {role, #r_role.role_warning}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_DISCOUNT_PAY_P, node = game, class = {role, #r_role.role_discount_pay}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_SKILL_P, node = game, class = {role, #r_role.role_skill}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BAG_P, node = game, class = {role, #r_role.role_bag}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_EQUIP_P, node = game, class = {role, #r_role.role_equip}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_EQUIP_COLLECT_P, node = game, class = {role, #r_role.role_equip_collect}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_LETTER_P, node = game, class = {role, #r_role.role_letter}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_FUNCTION_P, node = game, class = {role, #r_role.role_function}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MOUNT_P, node = game, class = {role, #r_role.role_mount}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MAGIC_WEAPON_P, node = game, class = {role, #r_role.role_magic_weapon}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_PET_P, node = game, class = {role, #r_role.role_pet}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_GOD_WEAPON_P, node = game, class = {role, #r_role.role_god_weapon}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_WING_P, node = game, class = {role, #r_role.role_wing}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_FASHION_P, node = game, class = {role, #r_role.role_fashion}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BUFF_P, node = game, class = {role, #r_role.role_buff}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_SHOP_P, node = game, class = {role, #r_role.role_shop}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_COPY_P, node = game, class = {role, #r_role.role_copy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_RUNE_P, node = game, class = {role, #r_role.role_rune}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_WORLD_BOSS_P, node = game, class = {role, #r_role.role_world_boss}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_VIP_P, node = game, class = {role, #r_role.role_vip}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_DAILY_LIVENESS_P, node = game, class = {role, #r_role.role_daily_liveness}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_EXTRA_P, node = game, class = {role, #r_role.role_extra}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_TREASURE_P, node = game, class = {role, #r_role.role_treasure}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_INVEST_P, node = game, class = {role, #r_role.role_invest}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_WELFARE_RECHARGE_P, node = game, class = {role, #r_role.role_act_welfare_recharge}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_PERMANENT_PRIVILEGE_P, node = game, class = {role, #r_role.role_permanent_privilege}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_FIRST_DEPOSIT_P, node = game, class = {role, #r_role.role_act_first_deposit}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACHIEVEMENT_P, node = game, class = {role, #r_role.role_achievement}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_GOD_BOOK_P, node = game, class = {role, #r_role.role_god_book}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_RELIVE_P, node = game, class = {role, #r_role.role_relive}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_SIGN_P, node = game, class = {role, #r_role.role_act_sign}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_SEVEN_DAY_P, node = game, class = {role, #r_role.role_seven_day}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_LEVEL_P, node = game, class = {role, #r_role.role_act_level}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_FAMILY_P, node = game, class = {role, #r_role.role_act_family}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_FEAST_P, node = game, class = {role, #r_role.role_act_feast}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BG_STORE_P, node = game, class = {role, #r_role.role_bg_act_store}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BG_MISSION_P, node = game, class = {role, #r_role.role_bg_act_mission}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_ONLINE_P, node = game, class = {role, #r_role.role_act_online}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
%%    #c_tab{tab = ?DB_ROLE_FAIRY_P, node = game, class = {role, #r_role.role_fairy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_DAYRECHARGE_P, node = game, class = {role, #r_role.role_act_dayrecharge}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_ACCRECHARGE_P, node = game, class = {role, #r_role.role_act_accrecharge}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_DAY_BOX_P, node = game, class = {role, #r_role.role_day_box}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_FIRSTRECHARGE_P, node = game, class = {role, #r_role.role_act_firstrecharge}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},

    #c_tab{tab = ?DB_ROLE_MARKET_P, node = game, class = {role, #r_role.role_market}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_GUARD_P, node = game, class = {role, #r_role.role_guard}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_TITLE_P, node = game, class = {role, #r_role.role_title}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ADDICT_P, node = game, class = {role, #r_role.role_addict}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CHAPTER_P, node = game, class = {role, #r_role.role_chapter}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MARRY_P, node = game, class = {role, #r_role.role_marry}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_DAY_TARGET_P, node = game, class = {role, #r_role.role_day_target}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MYTHICAL_EQUIP_P, node = game, class = {role, #r_role.role_mythical_equip}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CLWORD_P, node = game, class = {role, #r_role.role_clword}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_RED_PACKET_P, node = game, class = {role, #r_role.role_red_packet}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_ZEROPANICBUY_P, node = game, class = {role, #r_role.role_act_zeropanicbuy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_LUCKY_TOKEN_P, node = game, class = {role, #r_role.role_act_lucky_token}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_LUCKYCAT_P, node = game, class = {role, #r_role.role_act_luckycat}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_TREASURE_CHEST_P, node = game, class = {role, #r_role.role_act_treasure_chest}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_FIRSTPAY_P, node = game, class = {role, #r_role.role_act_firstpay}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_LEVELPANICBUY_P, node = game, class = {role, #r_role.role_levelpanicbuy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_DAILY_BUY_P, node = game, class = {role, #r_role.role_daily_buy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_IMMORTAL_SOUL_P, node = game, class = {role, #r_role.role_immortal_soul}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_HUNT_BOSS_P, node = game, class = {role, #r_role.role_act_hunt_boss}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CONFINE_P, node = game, class = {role, #r_role.role_confine}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BLESS_P, node = game, class = {role, #r_role.role_bless}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_WEEK_CARD_P, node = game, class = {role, #r_role.role_week_card}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_HANDBOOK_P, node = game, class = {role, #r_role.role_handbook}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_TREVI_FOUNTAIN_P, node = game, class = {role, #r_role.role_trevi_fountain}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_THRONE_P, node = game, class = {role, #r_role.role_throne}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_HUNT_TREASURE_P, node = game, class = {role, #r_role.role_hunt_treasure}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_SECOND_ACT_P, node = game, class = {role, #r_role.role_second_act}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BOSS_REWARD_P, node = game, class = {role, #r_role.role_boss_reward}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_OTF_P, node = game, class = {role, #r_role.role_act_otf}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ALCHEMY_P, node = game, class = {role, #r_role.role_bg_alchemy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_TURNTABLE_P, node = game, class = {role, #r_role.role_bg_turntable}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_SUIT_P, node = game, class = {role, #r_role.role_suit}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_NATURE_P, node = game, class = {role, #r_role.role_nature}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BG_TT_P, node = game, class = {role, #r_role.role_bg_tt}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_STORE_P, node = game, class = {role, #r_role.role_act_store}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_PELLET_MEDICINE_P, node = game, class = {role, #r_role.role_pellet_medicine}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_NEW_ALCHEMY_P, node = game, class = {role, #r_role.role_new_alchemy}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_MONEY_TREE_P, node = game, class = {role, #r_role.role_money_tree}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_BG_EXTRA_P, node = game, class = {role, #r_role.role_bg_extra}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_IT_P, node = game, class = {role, #r_role.role_it}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CYCLE_ACT_EXTRA_P, node = game, class = {role, #r_role.role_cycle_act_extra}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CHOOSE_P, node = game, class = {role, #r_role.role_choose}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ACT_ESOTERICA_P, node = game, class = {role, #r_role.role_act_esoterica}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CYCLE_ACT_COUPLE_P, node = game, class = {role, #r_role.role_cycle_act_couple}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CYCLE_MISC_P, node = game, class = {role, #r_role.role_cycle_act_misc}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_CYCLE_MISSION_P, node = game, class = {role, #r_role.role_cycle_mission}, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},

    #c_tab{tab = ?DB_ACT_INIT_TIME_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ACCOUNT_ROLE_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_ROLE_ACCOUNT_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, int}, {cooldown, 3 * 24 * 3600}]},
    #c_tab{tab = ?DB_ROLE_NAME_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_OFFLINE_EVENT_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_WORLD_LETTER_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_WORLD_FRIEND_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_FAMILY_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_FAMILY_NAME_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}, {cooldown, 3 * 24 * 3600}]},
    #c_tab{tab = ?DB_ROLE_FAMILY_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_RANK_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_WORLD_BOSS_P, node = all, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROLE_SOLO_P, node = all, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROLE_OFFLINE_SOLO_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROBOT_OFFLINE_SOLO_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROLE_ROBOT_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_PAY_LOG_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROLE_BAN_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_SELL_MARKET_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_DEMAND_MARKET_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_JUNHAI_LOG_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_MARRY_DATA_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_SHARE_MARRY_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_AUCTION_GOODS_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_ROLE_AUCTION_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_FAMILY_AUCTION_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_R_BG_ACT_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_CHAT_HISTORY_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_ROLE_ESCORT_P, node = all, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_FAMILY_BOX_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_FAMILY_ASM_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_DEFAULT},
    #c_tab{tab = ?DB_MINING_LATTICE_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_MINING_ROLE_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_R_CYCLE_ACT_P, node = game, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},


    %% cross节点数据库
    #c_tab{tab = ?DB_ROLE_CROSS_DATA_P, node = cross, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},

    %% center节点数据库
    #c_tab{tab = ?DB_CENTER_ADDICT_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_CENTER_CREATE_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_GAME_TOPOLOGY_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_CROSS_TOPOLOGY_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_COPY_UNIVERSE_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},
    #c_tab{tab = ?DB_CYCLE_ACT_COUPLE_RANK_P, node = center, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}] ++ ?SQL_INIT_ALL},

    %% all 所有节点都会有
    #c_tab{tab = ?DB_WORLD_DATA_P, node = all, class = world, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN},
    #c_tab{tab = ?DB_NODE_MSG_P, node = all, class = node, ets_opts = ?ETS_DEFAULT, sql_opts = [{keyformat, {varbinary, 255}}]},
    #c_tab{tab = ?DB_BACKGROUND_LOG_P, node = all, class = node, ets_opts = ?ETS_DEFAULT, sql_opts = ?SQL_NOT_COOLDOWN}
]).

-endif.