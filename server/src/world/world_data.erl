%%%----------------------------------------------------------------------
%%% @doc
%%%  K-V维护稀有数据，注意读写必须由单个进程，注意并发
%%% @end
%%%
%%%----------------------------------------------------------------------
-module(world_data).

-include("global.hrl").
-include("act.hrl").
-include("marry.hrl").
-include("node.hrl").
-include("solo.hrl").
-include("demon_boss.hrl").

-export([
    set_db_version/1,
    get_db_version/0,
    init_role_id_counter/0,
    get_role_id_counter/0,
    update_role_id_counter/0,
    init_background_id/0,
    update_background_id/0,
    update_background_log_id/1,
    init_family_id/0,
    update_family_id/0,
    init_junhai_gold_log_id/0,
    update_junhai_gold_log_id/0,
    init_solo_rank/0,
    get_solo_rank/0,
    set_solo_rank/1,
    init_solo_reset_date/0,
    get_solo_reset_date/0,
    set_solo_reset_date/1,
    get_offline_solo_robot_names/0,
    set_offline_solo_robot_names/1,
    get_boss_drop_logs/0,
    set_boss_drop_logs/1,
    get_family_week_refresh/0,
    set_family_week_refresh/1,
    set_world_level/1,
    get_world_level/0,
    get_survey_list/0,
    set_survey_list/1,
    get_equip_treasure_logs/0,
    set_equip_treasure_logs/1,
    get_lucky_cat_logs/0,
    set_lucky_cat_logs/1,
    get_first_trench_ceremony/0,
    set_first_trench_ceremony/1,
    get_summit_logs/0,
    set_summit_logs/1,
    init_act_ranks/1,
    get_act_ranks/1,
    set_act_ranks/2,
    init_sell_market_goods_id/0,
    get_sell_market_goods_new_id/0,
    init_demand_market_goods_id/0,
    get_demand_market_goods_new_id/0,
    get_double_copy/0,
    set_double_copy/1,
    is_create_able/0,
    set_create_able/1,
    get_addict_args/0,
    set_addict_args/1,
    set_family_battle_rank/1,
    get_family_battle_rank/0,
    set_family_temple/1,
    get_family_temple/0,
    init_pay_order_id/0,
    update_pay_order_id/0,
    set_ban_words/1,
    get_ban_words/0,
    set_filter_words/1,
    get_filter_words/0,
    get_notice_list/0,
    set_notice_list/1,
    set_ban_ips/1,
    get_ban_ips/0,
    set_ban_imei/1,
    get_ban_imei/0,
    get_ban_uid/0,
    set_ban_uid/1,
    set_statistics_roles/1,
    get_statistics_roles/0,
    set_role_statistics/1,
    del_role_statistics/0,
    get_role_statistics/0,
    set_junhai_gifts/1,
    get_junhai_gifts/0,
    set_marry_feast/1,
    get_marry_feast/0,
    set_act_family_hunt_boss_reward_status/1,
    get_act_family_hunt_boss_reward_status/0,
    set_act_family_hunt_boss_score/1,
    get_act_family_hunt_boss_score/0,
    set_act_personal_hunt_boss_score/1,
    get_act_personal_hunt_boss_score/0,
    get_bg_drop/0,
    set_bg_drop/1,
    get_center_topology_args/0,
    set_center_topology_args/1,
    get_pay_back_list/0,
    set_pay_back_list/1,
    get_demon_boss_ctrl/0,
    set_demon_boss_ctrl/1,
    get_drop_item_control/0,
    set_drop_item_control/1,
    get_auction_goods_id/0,
    set_auction_goods_id/1,
    get_chat_ban/0,
    set_chat_ban/1,
    get_support_info/0,
    set_support_info/1,
    get_money_tree/0,
    set_money_tree/1,
    get_mining_status/0,
    set_mining_status/1,
    init_season_count/0,
    get_season_count/0,
    set_season_count/1,
    gain_season_count/0,
    get_cross_domain_server_peg/0,
    set_cross_domain_server_peg/1,
    get_egg_log/0,
    set_egg_log/1,
    get_ban_rename_actions/0,
    set_ban_rename_actions/1
]).

-export([
    get_act_level_list/0,
    set_act_level_list/1,
    get_act_family/0,
    set_act_family/1,
    get_act_family_create_reward/0,
    set_act_family_create_reward/1,
    get_act_family_battle/0,
    set_act_family_battle/1,
    get_act_limitedtime_buy/0,
    set_act_limitedtime_buy/1,
    get_act_red_packet/0,
    set_act_red_packet/1,
    get_cycle_act_couple_charm/0,
    set_cycle_act_couple_charm/1,
    get_cycle_act_couple_pray_logs/0,
    set_cycle_act_couple_pray_logs/1,
    get_oss_rank/0,
    set_oss_rank/1,
    get_escort_id/0,
    get_escort_zeroclock/0,
    set_escort_zeroclock/1,
    get_escort_mod/0,
    set_escort_mod/1,
    get_fgb/0,
    set_fgb/1,
    get_automatic_family_key/0,
    set_automatic_family_key/1
]).

-export([
    get_data/1,
    set_data/1
]).

-define(DB_VERSION, 1000).                      %% 数据升级
-define(ROLE_ID_COUNTER_KEY, 1001).             %% RoleID全局引用计数
-define(BACKGROUND_ID, 1002).                   %% 存储用的ID
-define(FAMILY_ID_COUNTER_KEY, 1003).           %% 仙盟ID全局引用技术
-define(JUNHAI_GOLD_LOG_ID_COUNTER_KEY, 1004).  %% 君海GoldLogID
-define(SOLO_RANK_KEY, 1005).                   %% 1v1排行用到的key
-define(SOLO_RESET_KEY, 1006).                  %% 1v1重置积分时间
-define(OFFLINE_SOLO_ROBOT_NAMES, 1007).        %% 离线1v1机器人姓名列表
-define(WORLD_BOSS_DROP_LOG, 1008).             %% 世界boss拾取日志
-define(FAMILY_WEEK_UPDATE_TIME, 1009).         %% 仙盟每周数据更新时间
-define(WORLD_LEVEL, 1010).                     %% 世界等级
-define(WORLD_SURVEY, 1011).                    %% 问卷
-define(WORLD_EQUIP_TREASURE_LOGS, 1012).       %% 装备寻宝日志
-define(ACT_RANK_ID, 1013).                     %% 开服活动排行
-define(SELL_MARKET_GOODS_ID, 1015).            %% 销售市场ID全局饮用技术
-define(DEMAND_MARKET_GOODS_ID, 1016).          %% 求购市场ID全局饮用技术
-define(ACT_DOUBLE_COPY_KEY, 1017).             %% 副本双倍活动
-define(ROLE_CREATE_SWITCH, 1018).              %% 注册开关
-define(FAMILY_BATTLE_RANK, 1019).              %% 帮派战rank
-define(PAY_ORDER_ID, 1020).                    %% 充值订单号
-define(ADDICT_ARGS, 1021).                    %% 防沉迷设置
-define(FAMILY_TEMPLE, 1022).                   %% 神殿
-define(BAN_WORDS, 1023).                       %% 敏感词禁言
-define(BAN_IPS, 1024).                         %% 封禁的IP
-define(BAN_IMEI, 1025).                        %% 封禁的设备
-define(STATISTICS_ROLES, 1026).                %% 功能统计在线玩家
-define(ROLE_STATISTICS, 1027).                 %% 功能统计日志表
-define(JUNHAI_GIFTS, 1028).                    %% 君海的礼包IDList
-define(MARRY_FEAST, 1029).                     %% 婚礼预约列表
-define(FILTER_WORDS, 1030).                    %% 屏蔽词
-define(NOTICE_LIST, 1031).                     %% 公告列表
-define(BG_DROP, 1032).                         %% 后台掉落
-define(WORLD_SUMMIT_LOGS, 1033).               %% 巅峰寻宝日志
-define(CENTER_TOPOLOGY, 1034).                 %% 中央服拓扑
-define(PAY_BACK_LIST, 1035).                   %% 首充返还
-define(BAN_UID, 1036).                         %% UID
-define(DEMON_BOSS_CTRL, 1037).                 %% 魔域boss控制
-define(DROP_ITEM_CONTROL, 1038).               %% 道具掉落表
-define(AUCTION_GOODS_ID, 1039).                %% 拍卖行ID
-define(CHAT_BAN_ARGS, 1040).                   %% 聊天封禁相关参数
-define(ESCORT_ID, 1041).                       %% 抢夺ID
-define(ESCORT_ZERO_CLOCK, 1042).               %% 抢夺零点清理
-define(WEB_SUPPORT_INFO, 1043).                %% 扶持号
-define(MONEY_TREE_LOGS, 1044).                 %% 摇钱树
-define(ESCORT_MOD, 1046).                      %% 抢夺服务模块
-define(MINING_STATUS, 1045).                   %% 挖矿状态
-define(FGB_TYPE, 1047).                        %% 帮派神兽场次
-define(SOLO_SEASON_COUNT, 1048).               %% lvl赛季次数
-define(SOLO_CROSS_DOMAIN_SERVER, 1049).        %% lvl是否同步过数据到跨服
-define(AUTOMATIC_OPEN_FAMILY, 1050).           %% 自动创建仙盟开关
-define(EGG_LOG, 1051).                         %% 砸蛋日志
-define(WORLD_LUCKY_CAT_LOGS, 1052).            %% 招财猫日志
-define(WORLD_ACT_TRENCH_CEREMONY, 1053).      %% 绝版壕礼
-define(BAN_RENAME_ACTIONS, 1054).              %% 后台重命名禁止行为

-define(ACT_LEVEL_KEY, 2001).                   %% 冲级活动，等级-领取数量列表
-define(ACT_FAMILY, 2002).                      %% 仙盟相关活动用到的id
-define(ACT_FAMILY_CREATE_REWARD, 2003).        %% 开宗立派活动 id-领取数量列表
-define(ACT_FAMILY_BATTLE_KEY, 2004).           %% 仙盟争霸活动 状态以及领取列表记录
-define(ACT_LIMITED_TIME_BUY_DATA, 2005).       %% 限时云抢购{奖励轮 ， 剩余 ， 日志 ,大奖}
-define(ACT_LIMITED_TIME_BUY_REWARD_LOG, 2006). %% 限时云抢购奖励日志
-define(ACT_FAMILY_HUNT_BOSS, 2007).            %% 仙盟猎杀boss活动
-define(ACT_PERSONAL_HUNT_BOSS, 2008).          %% 个人猎杀boss活动
-define(ACT_PERSONAL_HUNT_BOSS_KEY, 2009).       %% 个人猎杀boss活动的分数
-define(ACT_FAMILY_HUNT_BOSS_KEY, 2010).         %% 仙盟猎杀boss活动的分数
-define(ACT_HUNT_BOSS_FAMILY_REWARD, 2011).     %% 仙盟猎杀boss活动奖励的领取状态
-define(ACT_OSS_RANK, 2012).                    %% 排行榜
-define(ACT_RED_PACKET, 2013).                  %% 全服红包
-define(CYCLE_ACT_COUPLE_CHARM, 2014).          %% 魅力之王--魅力值
-define(CYCLE_ACT_COUPLE_PRAY_LOGS, 2015).      %% 月下情缘--记录

%%  xxx1002、x1013 被占用，注意
-define(BACKGROUND_LOG_LAST_ID, 1002).          %% LogID
-define(ACT_RANK_LAST_ID, 1013).                %% 开服活动

set_db_version(Version) ->
    set_data(#r_world_data{key = ?DB_VERSION, val = Version}).

get_db_version() ->
    case get_data(?DB_VERSION) of
        [#r_world_data{val = Version}] ->
            Version;
        _ ->
            0
    end.

%% 初始化role_id counter
init_role_id_counter() ->
    case get_role_id_counter() of
        [#r_world_data{}] -> ok;
        _ -> set_data(#r_world_data{key = ?ROLE_ID_COUNTER_KEY, val = common_id:get_start_role_id()})
    end.

%% 用ets的update_counter
update_role_id_counter() ->
    RoleID = ets:update_counter(?DB_WORLD_DATA_P, ?ROLE_ID_COUNTER_KEY, 1),
    db:sync(?DB_WORLD_DATA_P, [?ROLE_ID_COUNTER_KEY]),
    RoleID.

init_background_id() ->
    case get_background_id() of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_background_id(common_id:get_background_start_id())
    end.

update_background_id() ->
    [#r_world_data{val = LogID}] = get_background_id(),
    NextID = common_id:get_background_next_id(LogID),
    set_background_id(NextID),
    LogID.

update_background_log_id(Index) ->
    Key = Index * 10000 + ?BACKGROUND_LOG_LAST_ID,
    LogID = get_background_log_id(Key),
    NextID = common_id:get_background_log_next_id(LogID),
    set_background_log_id(Key, NextID),
    LogID.

init_family_id() ->
    case get_family_id() of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_family_id(common_id:get_family_start_id())
    end.

update_family_id() ->
    [#r_world_data{val = FamilyID}] = get_family_id(),
    NextID = common_id:get_family_next_id(FamilyID),
    set_family_id(NextID),
    FamilyID.

init_junhai_gold_log_id() ->
    case get_junhai_gold_log_id() of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_junhai_gold_log_id(common_id:get_junhai_gold_log_start_id())
    end.

update_junhai_gold_log_id() ->
    [#r_world_data{val = GoldLogID}] = get_junhai_gold_log_id(),
    NextID = common_id:get_junhai_gold_log_next_id(GoldLogID),
    set_junhai_gold_log_id(NextID),
    GoldLogID.

%% @doc lvl建立记录排行
init_solo_rank() ->
    set_data(#r_world_data{key = ?SOLO_RANK_KEY, val = []}).
get_solo_rank() ->
    [#r_world_data{val = SoloRanks}] = get_data(?SOLO_RANK_KEY),
    SoloRanks.
set_solo_rank(Ranks) ->
    set_data(#r_world_data{key = ?SOLO_RANK_KEY, val = Ranks}).

%% @doc lvl赛季开始时间
init_solo_reset_date() ->
    case get_data(?SOLO_RESET_KEY) of
        [#r_world_data{val = Date}] when is_integer(Date) ->
            ok;
        _ -> % 周四结束赛季
            Time = time_tool:add_days(time_tool:timestamp_to_datetime(time_tool:weekday_timestamp(7, 0, 0)), ?SOLO_RESET_WEEK - 8),
            StartTime = time_tool:timestamp(Time) - (?SOLO_RESET_WEEK * 86400),
            OpenTime = common_config:get_open_time(),
            NowStartTime = ?IF(OpenTime > StartTime andalso common_config:is_game_node(), OpenTime, StartTime),
            set_data(#r_world_data{key = ?SOLO_RESET_KEY, val = NowStartTime})
    end.
get_solo_reset_date() ->
    [#r_world_data{val = Date}] = get_data(?SOLO_RESET_KEY),
    Date.
set_solo_reset_date(Date) ->
    set_data(#r_world_data{key = ?SOLO_RESET_KEY, val = Date}).

%% @doc lvl
get_offline_solo_robot_names() ->
    [#r_world_data{val = RobotNames}] = get_data(?OFFLINE_SOLO_ROBOT_NAMES),
    RobotNames.
set_offline_solo_robot_names(RobotNames) ->
    set_data(#r_world_data{key = ?OFFLINE_SOLO_ROBOT_NAMES, val = RobotNames}).

%% lvl 赛季的次数
init_season_count() ->
    case get_data(?SOLO_SEASON_COUNT) of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_data(#r_world_data{key = ?SOLO_SEASON_COUNT, val = 1})
    end.
get_season_count() ->
    [#r_world_data{val = Count}] = get_data(?SOLO_SEASON_COUNT),
    Count.
set_season_count(Count) ->
    set_data(#r_world_data{key = ?SOLO_SEASON_COUNT, val = Count}).
gain_season_count() ->
    Count = get_season_count(),
    set_season_count(Count + 1).

%% 是否同步过数据到跨服
get_cross_domain_server_peg() ->
    [#r_world_data{val = Bool}] = get_data(?SOLO_CROSS_DOMAIN_SERVER),
    Bool.
set_cross_domain_server_peg(Bool) ->
    set_data(#r_world_data{key = ?SOLO_CROSS_DOMAIN_SERVER, val = Bool}).

get_role_id_counter() ->
    get_data(?ROLE_ID_COUNTER_KEY).

get_background_id() ->
    get_data(?BACKGROUND_ID).
set_background_id(ID) ->
    set_data(#r_world_data{key = ?BACKGROUND_ID, val = ID}).

get_background_log_id(Key) ->
    case get_data(Key) of
        [#r_world_data{val = LogID}] ->
            LogID;
        _ ->
            common_id:get_background_log_start_id()
    end.
set_background_log_id(Key, ID) ->
    set_data(#r_world_data{key = Key, val = ID}).

get_family_id() ->
    get_data(?FAMILY_ID_COUNTER_KEY).
set_family_id(ID) ->
    set_data(#r_world_data{key = ?FAMILY_ID_COUNTER_KEY, val = ID}).

get_junhai_gold_log_id() ->
    get_data(?JUNHAI_GOLD_LOG_ID_COUNTER_KEY).
set_junhai_gold_log_id(ID) ->
    set_data(#r_world_data{key = ?JUNHAI_GOLD_LOG_ID_COUNTER_KEY, val = ID}).

get_act_level_list() ->
    case get_data(?ACT_LEVEL_KEY) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_act_level_list(List) ->
    set_data(#r_world_data{key = ?ACT_LEVEL_KEY, val = List}).

get_act_family() ->
    case get_data(?ACT_FAMILY) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_act_family(List) ->
    set_data(#r_world_data{key = ?ACT_FAMILY, val = List}).

get_act_family_create_reward() ->
    case get_data(?ACT_FAMILY_CREATE_REWARD) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_act_family_create_reward(List) ->
    set_data(#r_world_data{key = ?ACT_FAMILY_CREATE_REWARD, val = List}).

get_act_family_battle() ->
    case get_data(?ACT_FAMILY_BATTLE_KEY) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            #r_act_family_battle{}
    end.
set_act_family_battle(Record) ->
    set_data(#r_world_data{key = ?ACT_FAMILY_BATTLE_KEY, val = Record}).

%% {RareList, NormalList}
set_boss_drop_logs(Tuple) ->
    set_data(#r_world_data{key = ?WORLD_BOSS_DROP_LOG, val = Tuple}).

get_boss_drop_logs() ->
    case get_data(?WORLD_BOSS_DROP_LOG) of
        [#r_world_data{val = {List1, List2}}] ->
            {List1, List2};
        _ ->
            {[], []}
    end.

%%{奖励轮 ， 剩余购买次数，混合日志，大奖}
set_act_limitedtime_buy(Record) ->
    set_data(#r_world_data{key = ?ACT_LIMITED_TIME_BUY_DATA, val = Record}).

get_act_limitedtime_buy() ->
    case get_data(?ACT_LIMITED_TIME_BUY_DATA) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
            [_Price, _DayAllTimes, Times|_] = GConfig#c_global.list,
            {1, Times, [], []}
    end.

get_act_red_packet() ->
    case get_data(?ACT_RED_PACKET) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.

set_act_red_packet(List) ->
    set_data(#r_world_data{key = ?ACT_RED_PACKET, val = List}).

get_cycle_act_couple_charm() ->
    case get_data(?CYCLE_ACT_COUPLE_CHARM) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_cycle_act_couple_charm(List) ->
    set_data(#r_world_data{key = ?CYCLE_ACT_COUPLE_CHARM, val = List}).


get_cycle_act_couple_pray_logs() ->
    case get_data(?CYCLE_ACT_COUPLE_PRAY_LOGS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_cycle_act_couple_pray_logs(List) ->
    set_data(#r_world_data{key = ?CYCLE_ACT_COUPLE_PRAY_LOGS, val = List}).

get_family_week_refresh() ->
    case get_data(?FAMILY_WEEK_UPDATE_TIME) of
        [#r_world_data{val = Time}] ->
            Time;
        _ ->
            0
    end.
set_family_week_refresh(Time) ->
    set_data(#r_world_data{key = ?FAMILY_WEEK_UPDATE_TIME, val = Time}).

get_world_level() ->
    case get_data(?WORLD_LEVEL) of
        [#r_world_data{val = Level}] ->
            Level;
        _ ->
            1
    end.

set_world_level(Level) ->
    set_data(#r_world_data{key = ?WORLD_LEVEL, val = Level}).

get_survey_list() ->
    case get_data(?WORLD_SURVEY) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.


set_family_battle_rank(RankList) ->
    set_data(#r_world_data{key = ?FAMILY_BATTLE_RANK, val = RankList}).

get_family_battle_rank() ->
    case get_data(?FAMILY_BATTLE_RANK) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.


set_family_temple(List) ->
    set_data(#r_world_data{key = ?FAMILY_TEMPLE, val = List}).
get_family_temple() ->
    case get_data(?FAMILY_TEMPLE) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.


set_survey_list(List) ->
    set_data(#r_world_data{key = ?WORLD_SURVEY, val = List}).

get_equip_treasure_logs() ->
    case get_data(?WORLD_EQUIP_TREASURE_LOGS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_equip_treasure_logs(List) ->
    set_data(#r_world_data{key = ?WORLD_EQUIP_TREASURE_LOGS, val = List}).

get_lucky_cat_logs() ->
    case get_data(?WORLD_LUCKY_CAT_LOGS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_lucky_cat_logs(List) ->
    set_data(#r_world_data{key = ?WORLD_LUCKY_CAT_LOGS, val = List}).

get_first_trench_ceremony() ->
    case get_data(?WORLD_ACT_TRENCH_CEREMONY) of
        [#r_world_data{val = #r_world_trench_ceremony{} = Value}] -> %% #r_world_trench_ceremony{}
            Value;
        _ ->
            #r_world_trench_ceremony{reward_role_id = 0}
    end.
set_first_trench_ceremony(TrenchCeremony) ->
    set_data(#r_world_data{key = ?WORLD_ACT_TRENCH_CEREMONY, val = TrenchCeremony}).

get_summit_logs() ->
    case get_data(?WORLD_SUMMIT_LOGS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_summit_logs(List) ->
    set_data(#r_world_data{key = ?WORLD_SUMMIT_LOGS, val = List}).


init_act_ranks(ID) ->
    Index = ID * 10000 + ?ACT_RANK_ID,
    case get_data(Index) of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_act_ranks(ID, [])
    end.
get_act_ranks(ID) ->
    Index = ID * 10000 + ?ACT_RANK_ID,
    case get_data(Index) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_act_ranks(ID, List) ->
    Index = ID * 10000 + ?ACT_RANK_ID,
    set_data(#r_world_data{key = Index, val = List}).


init_sell_market_goods_id() ->
    case get_sell_market_goods_id() of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_sell_market_goods_id(1)
    end.

get_sell_market_goods_new_id() ->
    [#r_world_data{val = GoodsID}] = get_sell_market_goods_id(),
    NextID = GoodsID + 1,
    set_sell_market_goods_id(NextID),
    GoodsID.

get_sell_market_goods_id() ->
    get_data(?SELL_MARKET_GOODS_ID).

set_sell_market_goods_id(ID) ->
    set_data(#r_world_data{key = ?SELL_MARKET_GOODS_ID, val = ID}).


init_demand_market_goods_id() ->
    case get_demand_market_goods_id() of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_demand_market_goods_id(1)
    end.

get_demand_market_goods_new_id() ->
    [#r_world_data{val = GoodsID}] = get_demand_market_goods_id(),
    NextID = GoodsID + 1,
    set_demand_market_goods_id(NextID),
    GoodsID.

get_demand_market_goods_id() ->
    get_data(?DEMAND_MARKET_GOODS_ID).

set_demand_market_goods_id(ID) ->
    set_data(#r_world_data{key = ?DEMAND_MARKET_GOODS_ID, val = ID}).


get_double_copy() ->
    case get_data(?ACT_DOUBLE_COPY_KEY) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_double_copy(List) ->
    set_data(#r_world_data{key = ?ACT_DOUBLE_COPY_KEY, val = List}).


get_bg_drop() ->
    case get_data(?BG_DROP) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_bg_drop(List) ->
    set_data(#r_world_data{key = ?BG_DROP, val = List}).

get_center_topology_args() ->
    case get_data(?CENTER_TOPOLOGY) of
        [#r_world_data{val = Topology}] ->
            Topology;
        _ ->
            #r_center_topology_args{}
    end.
set_center_topology_args(Topology) ->
    set_data(#r_world_data{key = ?CENTER_TOPOLOGY, val = Topology}).

get_pay_back_list() ->
    case get_data(?PAY_BACK_LIST) of
        [#r_world_data{val = PayBackList}] ->
            PayBackList;
        _ ->
            []
    end.
set_pay_back_list(PayBackList) ->
    set_data(#r_world_data{key = ?PAY_BACK_LIST, val = PayBackList}).

get_oss_rank() ->
    case get_data(?ACT_OSS_RANK) of
        [#r_world_data{val = RankList}] ->
            RankList;
        _ ->
            []
    end.
set_oss_rank(RankList) ->
    set_data(#r_world_data{key = ?ACT_OSS_RANK, val = RankList}).


get_escort_id() ->
    case get_data(?ESCORT_ID) of
        [#r_world_data{val = Val}] ->
            set_escort_id(Val + 1),
            Val;
        _ ->
            set_escort_id(2),
            1
    end.
set_escort_id(ID) ->
    ID2 = ?IF(ID > 100000000, 1, ID),
    set_data(#r_world_data{key = ?ESCORT_ID, val = ID2}).

set_escort_zeroclock(Time) ->
    set_data(#r_world_data{key = ?ESCORT_ZERO_CLOCK, val = Time}).

get_escort_zeroclock() ->
    case get_data(?ESCORT_ZERO_CLOCK) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            time_tool:now()
    end.


set_escort_mod(Mod) ->
    set_data(#r_world_data{key = ?ESCORT_MOD, val = Mod}).

get_escort_mod() ->
    case get_data(?ESCORT_MOD) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            family_escort_server
    end.


set_fgb(Mod) ->
    set_data(#r_world_data{key = ?FGB_TYPE, val = Mod}).

get_fgb() ->
    case get_data(?FGB_TYPE) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            1
    end.


set_automatic_family_key(Key) ->
    set_data(#r_world_data{key = ?AUTOMATIC_OPEN_FAMILY, val = Key}).

get_automatic_family_key() ->
    case get_data(?AUTOMATIC_OPEN_FAMILY) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            false
    end.

%%  { [稀有] ， [全部]}
set_egg_log(Key) ->
    set_data(#r_world_data{key = ?EGG_LOG, val = Key}).

get_egg_log() ->
    case get_data(?EGG_LOG) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            {[], []}
    end.

%% [int32|....]
get_ban_rename_actions() ->
    case get_data(?BAN_RENAME_ACTIONS) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            []
    end.

set_ban_rename_actions(List) ->
    set_data(#r_world_data{key = ?BAN_RENAME_ACTIONS, val = List}).

is_create_able() ->
    case get_data(?ROLE_CREATE_SWITCH) of
        [#r_world_data{val = Bool}] ->
            Bool;
        _ ->
            true
    end.
set_create_able(Bool) ->
    set_data(#r_world_data{key = ?ROLE_CREATE_SWITCH, val = Bool}).

get_addict_args() ->
    case get_data(?ADDICT_ARGS) of
        [#r_world_data{val = #p_kvl{} = Val}] ->
            Val;
        _ ->
            #p_kvl{id = ?ADDICT_TYPE_NORMAL, list = [120]}
    end.
set_addict_args(Args) ->
    set_data(#r_world_data{key = ?ADDICT_ARGS, val = Args}).

init_pay_order_id() ->
    case get_data(?PAY_ORDER_ID) of
        [#r_world_data{}] ->
            ok;
        _ ->
            set_data(#r_world_data{key = ?PAY_ORDER_ID, val = common_id:get_pay_start_id()})
    end.

update_pay_order_id() ->
    [#r_world_data{val = OrderID}] = get_data(?PAY_ORDER_ID),
    NextID = common_id:get_pay_next_id(OrderID),
    set_data(#r_world_data{key = ?PAY_ORDER_ID, val = NextID}),
    OrderID.

get_ban_words() ->
    case get_data(?BAN_WORDS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_ban_words(List) ->
    set_data(#r_world_data{key = ?BAN_WORDS, val = List}).

get_filter_words() ->
    case get_data(?FILTER_WORDS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_filter_words(List) ->
    set_data(#r_world_data{key = ?FILTER_WORDS, val = List}).

get_notice_list() ->
    case get_data(?NOTICE_LIST) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_notice_list(List) ->
    set_data(#r_world_data{key = ?NOTICE_LIST, val = List}).

get_ban_ips() ->
    case get_data(?BAN_IPS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_ban_ips(List) ->
    set_data(#r_world_data{key = ?BAN_IPS, val = List}).

get_ban_imei() ->
    case get_data(?BAN_IMEI) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_ban_imei(List) ->
    set_data(#r_world_data{key = ?BAN_IMEI, val = List}).

get_ban_uid() ->
    case get_data(?BAN_UID) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_ban_uid(List) ->
    set_data(#r_world_data{key = ?BAN_UID, val = List}).


get_statistics_roles() ->
    case get_data(?STATISTICS_ROLES) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_statistics_roles(List) ->
    set_data(#r_world_data{key = ?STATISTICS_ROLES, val = List}).

get_role_statistics() ->
    case get_data(?ROLE_STATISTICS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
del_role_statistics() ->
    del_data(?ROLE_STATISTICS).
set_role_statistics(List) ->
    set_data(#r_world_data{key = ?ROLE_STATISTICS, val = List}).

get_junhai_gifts() ->
    case get_data(?JUNHAI_GIFTS) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_junhai_gifts(List) ->
    set_data(#r_world_data{key = ?JUNHAI_GIFTS, val = List}).

get_marry_feast() ->
    case get_data(?MARRY_FEAST) of
        [#r_world_data{val = Val}] ->
            Val;
        _ ->
            #r_marry_feast{date = 0}
    end.
set_marry_feast(MarryFeast) ->
    set_data(#r_world_data{key = ?MARRY_FEAST, val = MarryFeast}).

get_data(Key) ->
    ets:lookup(?DB_WORLD_DATA_P, Key).
del_data(Key) ->
    db:delete(?DB_WORLD_DATA_P, Key).
set_data(#r_world_data{} = Data) ->
    db:insert(?DB_WORLD_DATA_P, Data).

set_act_family_hunt_boss_reward_status(Record) ->
    set_data(#r_world_data{key = ?ACT_HUNT_BOSS_FAMILY_REWARD, val = Record}).

get_act_family_hunt_boss_reward_status() ->
    case get_data(?ACT_HUNT_BOSS_FAMILY_REWARD) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            [] %默认值返回是个空list，也可以当成是{key,val}里面val的初始化值
    end.

get_act_personal_hunt_boss_score() ->
    case get_data(?ACT_PERSONAL_HUNT_BOSS_KEY) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            [] %默认值返回是个空list，也可以当成是{key,val}里面val的初始化值
    end.

set_act_personal_hunt_boss_score(List) ->
    set_data(#r_world_data{key = ?ACT_PERSONAL_HUNT_BOSS_KEY, val = List}).

get_act_family_hunt_boss_score() ->
    case get_data(?ACT_FAMILY_HUNT_BOSS_KEY) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            []
    end.

set_act_family_hunt_boss_score(List) ->
    set_data(#r_world_data{key = ?ACT_FAMILY_HUNT_BOSS_KEY, val = List}).

get_demon_boss_ctrl() ->
    case get_data(?DEMON_BOSS_CTRL) of
        [#r_world_data{val = Record}] ->
            Record;
        _ ->
            #r_demon_boss_ctrl{}
    end.
set_demon_boss_ctrl(Ctrl) ->
    set_data(#r_world_data{key = ?DEMON_BOSS_CTRL, val = Ctrl}).

get_drop_item_control() ->
    case get_data(?DROP_ITEM_CONTROL) of
        [#r_world_data{val = List}] ->
            List;
        _ ->
            []
    end.
set_drop_item_control(List) ->
    set_data(#r_world_data{key = ?DROP_ITEM_CONTROL, val = List}).

get_auction_goods_id() ->
    case get_data(?AUCTION_GOODS_ID) of
        [#r_world_data{val = GoodsID}] ->
            GoodsID;
        _ ->
            common_id:get_auction_start_id()
    end.
set_auction_goods_id(ID) ->
    set_data(#r_world_data{key = ?AUCTION_GOODS_ID, val = ID}).

%% map结构
%%
get_chat_ban() ->
    case get_data(?CHAT_BAN_ARGS) of
        [#r_world_data{val = BanArgs}] ->
            BanArgs;
        _ ->
            #{}
    end.
set_chat_ban(ChatBan) ->
    set_data(#r_world_data{key = ?CHAT_BAN_ARGS, val = ChatBan}).

%% 扶持号结构
get_support_info() ->
    case get_data(?WEB_SUPPORT_INFO) of
        [#r_world_data{val = SupportInfo}] ->
            SupportInfo;
        _ ->
            []
    end.
set_support_info(SupportInfo) ->
    set_data(#r_world_data{key = ?WEB_SUPPORT_INFO, val = SupportInfo}).


%% 摇钱树日志
get_money_tree() ->
    case get_data(?MONEY_TREE_LOGS) of
        [#r_world_data{val = Logs}] ->
            Logs;
        _ ->
            []
    end.
set_money_tree(Logs) ->
    set_data(#r_world_data{key = ?MONEY_TREE_LOGS, val = Logs}).

get_mining_status() ->
    case get_data(?MINING_STATUS) of
        [#r_world_data{val = MiningStatus}] ->
            MiningStatus;
        _ ->
            #r_mining_status{}
    end.
set_mining_status(MiningStatus) ->
    set_data(#r_world_data{key = ?MINING_STATUS, val = MiningStatus}).


