%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 一月 2018 20:03
%%%-------------------------------------------------------------------
-module(mod_role_vip).
-author("laijichang").
-include("role.hrl").
-include("vip.hrl").
-include("copy.hrl").
-include("family.hrl").
-include("red_packet.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_vip.hrl").

%% API
-export([
    init/1,
    calc/1,
    day_reset/1,
    zero/1,
    online/1,
    loop_min/2,
    handle/2
]).

-export([
    gm_set_vip/2,
    gm_vip_expire/1,
    gm_add_exp/2
]).

-export([
    use_gold/2,
    use_vip_item/2,
    add_vip_experience/3,
    get_vip_level/1,
    get_vip_level_by_role_vip/1,
    get_vip_stone_num/1,
    get_vip_seal_num/1,
    get_pet_exp_rate/1,
    get_vip_buy_times/2,
    get_vip_copy_times/2,
    get_vip_enter_times/2,
    get_vip_titles/1,
    get_bless_add_times/1,
    get_vip_first_boss_times/1,
    get_add_cave_times/1,
    get_world_boss_merge_times/1,
    get_copy_exp_merge_times/1,
    get_money_tree_times/1,
    get_illusion_buy_times/1,
    is_transfer_free/1,
    is_resource_retrieve/1,
    is_boss_first_free/1,
    is_boss_item_half/1,
    send_red_packet/2,
    v4_reward/1,
    get_box_max_num/1,
    family_box_update/2,
    add_vip_exp/2
]).

init(#r_role{role_id = RoleID, role_vip = undefined} = State) ->
    %% 1天v4提醒时间
    RoleVip = #r_role_vip{role_id = RoleID, v4_remind_time = time_tool:now() + 1 * ?ONE_DAY},
    State#r_role{role_vip = RoleVip};
init(State) ->
    State.

calc(State) ->
    case is_expire(State) of
        true ->
            State;
        _ ->
            #r_role_vip{level = Level} = State#r_role.role_vip,
            [#c_vip_level{add_props = AddProps, monster_exp_add = MonsterExpAdd}] = lib_config:find(cfg_vip_level, Level),
            CalcAttr = common_misc:get_attr_by_kv([#p_kv{id = ?ATTR_MONSTER_EXP, val = MonsterExpAdd}|common_misc:get_string_props(AddProps)]),
            mod_role_fight:get_state_by_kv(State, ?CALC_KEY_VIP, CalcAttr)
    end.

day_reset(State) ->
    add_exp(State, ?CONFIG_EXP(?LOGIN_ADD_EXP), ?LOG_VIP_LOGIN, 0).

zero(State) ->
    online(State).

online(State) ->
    {IsChange, State2} = do_expire(time_tool:now(), State),
    do_notice_info(State2, IsChange),
    State2.

do_notice_info(State) ->
    do_notice_info(State, false).
do_notice_info(State, IsRemind) ->
    #r_role{role_id = RoleID, role_vip = RoleVip} = State,
    #r_role_vip{
        expire_time = ExpireTime,
        level = Level,
        exp = Exp,
        gift_list = GiftList,
        first_buy_list = FirstBuyList,
        day_gift_time = DayGiftTime,
        is_vip_experience = IsVipExperience,
        v4_remind_time = V4RemindTime} = RoleVip,
    NowDate = time_tool:now(),
    DataRecord = #m_vip_info_toc{
        expire_time = ExpireTime,
        level = Level,
        exp = ?FRONT_EXP(Exp),
        gift_list = GiftList,
        first_buy_list = FirstBuyList,
        day_gift_status = not time_tool:is_same_date(DayGiftTime, NowDate),
        is_vip_experience = IsVipExperience,
        is_remind = IsRemind,
        v4_remind_time = V4RemindTime},
    common_misc:unicast(RoleID, DataRecord),
    ok.

loop_min(Now, State) ->
    {IsChange, State2} = do_expire(Now, State),
    ?IF(IsChange, do_notice_info(State2, IsChange), ok),
    State2.

do_expire(Now, State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{expire_time = ExpireTime} = RoleVip,
    if
        ExpireTime =:= 0 -> %% 已经过期了
            {false, State};
        Now >= ExpireTime -> %% 现在正好过期
            RoleVip2 = RoleVip#r_role_vip{level = 0, expire_time = 0},
            State2 = State#r_role{role_vip = RoleVip2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_VIP_EXPIRE, 0),
            {true, hook_role:role_vip_expire(State3)};
        true ->
            {false, State}
    end.

add_exp(State, 0, _Action, _SubAction) ->
    State;
add_exp(State, AddExp, Action, SubAction) ->
    #r_role{role_id = RoleID, role_vip = RoleVip} = State,
    #r_role_vip{level = Level, exp = Exp} = RoleVip,
    case (not is_expire(State)) of
        true ->
            {Level2, Exp2} = add_exp2(Level, Exp, AddExp),
            ChangeList = ?IF(?FRONT_EXP(Exp) =:= ?FRONT_EXP(Exp2), [], [#p_kv{id = ?CHANGE_EXP, val = ?FRONT_EXP(Exp2)}]),
            IsLevelUp = Level =/= Level2,
            ChangeList2 = ?IF(IsLevelUp, [#p_kv{id = ?CHANGE_LEVEL, val = Level2}|ChangeList], ChangeList),
            ?IF(ChangeList2 =/= [], common_misc:unicast(RoleID, #m_vip_info_change_toc{kv_list = ChangeList2}), ok),
            RoleVip2 = RoleVip#r_role_vip{level = Level2, exp = Exp2},
            log_vip_exp(Action, SubAction, AddExp, Exp2, Level, Level2, State),
            case IsLevelUp of
                true ->
                    RoleVip3 = RoleVip2#r_role_vip{day_gift_time = 0},%VIP等级提升重置日礼包时间！注意这里原来是week_gift_time
                    State2 = State#r_role{role_vip = RoleVip3},
                    State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_VIP_ON, Level2),
                    State4 = hook_role:role_vip_level_up(Level, Level2, State3),
                    online(State4);
                _ ->
                    State#r_role{role_vip = RoleVip2}
            end;
        _ ->
            case Action =:= ?LOG_VIP_CONSUME of
                true ->
                    {Level2, Exp2} = add_exp2(Level, Exp, AddExp),
                    ChangeList = ?IF(?FRONT_EXP(Exp) =:= ?FRONT_EXP(Exp2), [], [#p_kv{id = ?CHANGE_EXP, val = ?FRONT_EXP(Exp2)}]),
                    ?IF(ChangeList =/= [], common_misc:unicast(RoleID, #m_vip_info_change_toc{kv_list = ChangeList}), ok),
                    %% 过期的时候，只增加经验，不修改等级
                    RoleVip2 = RoleVip#r_role_vip{exp = Exp2},
                    log_vip_exp(Action, SubAction, AddExp, Exp2, Level, Level2, State),
                    State#r_role{role_vip = RoleVip2};
                _ ->
                    State
            end
    end.

send_red_packet(#r_role{role_id = RoleID} = State, VipInvestLevel) ->
    Num = case VipInvestLevel of
              4 -> ?RED_PACKET_FAMILY_VIP_FOUR;
              5 -> ?RED_PACKET_FAMILY_VIP_FIVE;
              6 -> ?RED_PACKET_FAMILY_VIP_SIX;
              7 -> ?RED_PACKET_FAMILY_VIP_SEVEN;
              8 -> ?RED_PACKET_FAMILY_VIP_EIGHT;
              9 -> ?RED_PACKET_FAMILY_VIP_NINE;
              _ ->
                  false
          end,
    ?IF(Num =:= false, ok, mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, Num)),
    State.

v4_reward(State) ->
    case mod_role_extra:get_data(?EXTRA_KEY_IS_V4_REWARD, false, State) of
        true ->
            State;
        _ ->
            [{_ID, TypeID}] = lib_config:list(cfg_direct_v4),
            GoodsList = [#p_goods{type_id = TypeID, num = 1}],
            State2 = mod_role_extra:set_data(?EXTRA_KEY_IS_V4_REWARD, true, State),
            role_misc:create_goods(State2, ?ITEM_GAIN_DIRECT_V4, GoodsList)
    end.

add_exp2(Level, Exp, AddExp) ->
    case lib_config:find(cfg_vip_level, Level + 1) of
        [#c_vip_level{exp = NeedExp}] ->
            Exp2 = Exp + AddExp,
            case Exp2 >= ?CONFIG_EXP(NeedExp) of
                true ->
                    add_exp2(Level + 1, Exp2, 0);
                _ ->
                    {Level, Exp2}
            end;
        _ ->
            {Level, Exp}
    end.

gm_set_vip(Level, State) ->
    #r_role{role_vip = RoleVip} = State,
    [#c_vip_level{exp = VipExp}] = lib_config:find(cfg_vip_level, Level),
    RoleVip2 = RoleVip#r_role_vip{level = Level, exp = ?CONFIG_EXP(VipExp), is_vip_experience = false, expire_time = time_tool:now() + 180 * ?ONE_DAY, day_gift_time = 0},
    State2 = State#r_role{role_vip = RoleVip2},
    State3 = online(State2),
    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_VIP_ON, Level),
    hook_role:role_vip_level_up(RoleVip#r_role_vip.level, Level, State4).

gm_vip_expire(State) ->
    #r_role{role_vip = RoleVip} = State,
    Now = time_tool:now(),
    RoleVip2 = RoleVip#r_role_vip{expire_time = Now},
    State2 = State#r_role{role_vip = RoleVip2},
    loop_min(Now, State2).

gm_add_exp(State, AddExp) ->
    add_exp(State, AddExp, 0, 0).


use_gold(Gold, State) ->
    add_exp(State, Gold, ?LOG_VIP_CONSUME, 0).

use_vip_item(TypeID, State) ->
    #r_role{role_id = RoleID} = State,
    [#c_vip_buy{name = VipName} = Config] = lib_config:find(cfg_vip_buy, TypeID),
    {ok, BagDoings, AddExp, IsOldExpire, ExpireTime2, IsVipExperience, State2} = get_buy_vip_args(Config, State),
    State3 = mod_role_bag:do(BagDoings, State2),
    State4 = add_exp(State3, AddExp, ?LOG_VIP_CARD, TypeID),
    common_misc:unicast(RoleID, #m_vip_buy_toc{expire_time = ExpireTime2, first_buy = TypeID, is_vip_experience = IsVipExperience, type = 2}),
    do_notice_info(State4),
    common_broadcast:send_world_common_notice(?NOTICE_VIP_ACTIVATE, [mod_role_data:get_role_name(State), VipName]),  %% T  添加VIP卡使用公告
    ?IF(IsOldExpire, mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_VIP_ON, 0), State4).

add_vip_experience(TypeID, AddMin, State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{level = VipLevel, exp = Exp, expire_time = ExpireTime, first_buy_list = FirstBuyList} = RoleVip,
    IsExpire = is_expire(State),
    ExpireTime2 = ?IF(IsExpire, AddMin * ?ONE_MINUTE + time_tool:now(), AddMin * ?ONE_MINUTE + ExpireTime),
    FirstBuyList2 = [TypeID|lists:delete(TypeID, FirstBuyList)],
    RoleVip2 =
    case VipLevel > 1 orelse (VipLevel =:= 1 andalso Exp > 0) of
        true ->
            RoleVip#r_role_vip{expire_time = ExpireTime2, first_buy_list = FirstBuyList2};
        _ ->
            RoleVip#r_role_vip{level = 1, expire_time = ExpireTime2, is_vip_experience = true, first_buy_list = FirstBuyList2}
    end,
    State2 = State#r_role{role_vip = RoleVip2},

    do_notice_info(State2),
    case IsExpire of
        true ->
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_VIP_ON, 0),
            hook_role:role_vip_level_up(VipLevel, RoleVip2#r_role_vip.level, State3);
        _ ->
            State2
    end.

add_vip_exp(AddExp, State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{expire_time = ExpireTime} = RoleVip,
    VipLevel = get_vip_level(State),
    ?IF(VipLevel =:= 0, ?THROW_ERR(?ERROR_VIP_GIFT_GET_001), ok),
    ?IF(ExpireTime =:= 0, ?THROW_ERR(?POWER_UPDATE_VIP_EXPIRE), ok),
    add_exp(State, ?CONFIG_EXP(AddExp), ?LOG_VIP_EXP_CARD, 0).

%% 获取VIP等级
get_vip_level(State) ->
    case is_expire(State) of
        true ->
            0;
        _ ->
            State#r_role.role_vip#r_role_vip.level
    end.

get_vip_level_by_role_vip(RoleVIP) ->
    #r_role_vip{level = VIPLevel, expire_time = ExpireTime} = RoleVIP,
    case time_tool:now() > ExpireTime of
        true ->
            0;
        _ ->
            VIPLevel
    end.

%% VIP额外加的孔数
get_vip_stone_num(State) ->
    get_config_by_key(State, #c_vip_level.equip_stone_num, 0).

%% VIP额外加的纹印孔数
get_vip_seal_num(State) ->
    get_config_by_key(State, #c_vip_level.equip_seal_num, 0).

%% 宠物吞噬装备额外加成
get_pet_exp_rate(State) ->
    get_config_by_key(State, #c_vip_level.pet_exp_add, 0).

%% 副本购买次数增加
get_vip_buy_times(CopyType, State) ->
    if
        CopyType =:= ?COPY_EXP ->
            get_config_by_key(State, #c_vip_level.copy_exp_times, 0);
        CopyType =:= ?COPY_SILVER ->
            get_config_by_key(State, #c_vip_level.copy_silver_times, 0);
        CopyType =:= ?COPY_SINGLE_TD ->
            get_config_by_key(State, #c_vip_level.copy_pet_times, 0);
        CopyType =:= ?COPY_IMMORTAL ->
            get_config_by_key(State, #c_vip_level.copy_immortal_times, 0);
        CopyType =:= ?COPY_FORGE_SOUL ->
            get_config_by_key(State, #c_vip_level.copy_forge_soul, 0);
        true ->
            0
    end.

%% 副本进入次数
get_vip_copy_times(CopyType, State) ->
    if
        CopyType =:= ?COPY_WORLD_BOSS ->
            get_config_by_key(State, #c_vip_level.vip_boss, 0);
        true ->
            0
    end.

%% 部分地图进入次数增加
get_vip_enter_times(SubType, State) ->
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_4 ->
            get_config_by_key(State, #c_vip_level.world_boss_times, 0);
        SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
            get_config_by_key(State, #c_vip_level.ancient_enter_times, 0);
        true ->
            0
    end.

get_vip_titles(State) ->
    VipLevel = get_vip_level(State),
    case VipLevel > 0 of
        true ->
            TitleList =
            [begin
                 [#c_vip_level{title = TitleID}] = lib_config:find(cfg_vip_level, Index),
                 ?IF(TitleID > 0, TitleID, [])
             end || Index <- lists:seq(1, VipLevel)],
            lib_tool:list_filter_repeat(lists:flatten(TitleList));
        _ ->
            []
    end.

get_bless_add_times(State) ->
    get_config_by_key(State, #c_vip_level.add_bless_times, 0).

get_vip_first_boss_times(State) ->
    get_config_by_key(State, #c_vip_level.first_boss_buy, 0).

get_add_cave_times(State) ->
    get_config_by_key(State, #c_vip_level.cave_times, 0).

get_world_boss_merge_times(State) ->
    get_config_by_key(State, #c_vip_level.world_boss_merge_times, 1).

get_copy_exp_merge_times(State) ->
    get_config_by_key(State, #c_vip_level.copy_exp_merge_times, 1).

get_money_tree_times(State) ->
    get_config_by_key(State, #c_vip_level.money_tree_times, 0).

get_illusion_buy_times(State) ->
    get_config_by_key(State, #c_vip_level.illusion_buy_times, 0).

%% 是否可以免费传送
is_transfer_free(State) ->
    case is_expire(State) of
        true ->
            false;
        _ ->
            [#c_vip_level{is_transfer_free = IsFree}] = lib_config:find(cfg_vip_level, get_vip_level(State)),
            ?IS_TRANSFER_FREE(IsFree)
    end.

is_resource_retrieve(State) ->
    case is_expire(State) of
        true ->
            false;
        _ ->
            [#c_vip_level{is_resource_retrieve = IsResource}] = lib_config:find(cfg_vip_level, get_vip_level(State)),
            IsResource > 0
    end.

is_boss_first_free(State) ->
    case is_expire(State) of
        true ->
            false;
        _ ->
            [#c_vip_level{is_boss_first_free = IsFirstFree}] = lib_config:find(cfg_vip_level, get_vip_level(State)),
            IsFirstFree > 0
    end.

is_boss_item_half(State) ->
    case is_expire(State) of
        true ->
            false;
        _ ->
            [#c_vip_level{is_boss_item_half = IsHalf}] = lib_config:find(cfg_vip_level, get_vip_level(State)),
            IsHalf > 0
    end.

handle({#m_vip_buy_tos{id = ID}, RoleID, _PID}, State) ->
    do_vip_buy(RoleID, State, ID);
handle({#m_vip_gift_get_tos{level = Level}, RoleID, _PID}, State) ->
    do_vip_gift_get(RoleID, Level, State);
handle({#m_vip_day_gift_tos{}, RoleID, _PID}, State) ->
    do_vip_day_gift(RoleID, State);
handle({#m_vip_direct_v4_tos{}, RoleID, _PID}, State) ->
    do_vip_direct_v4(RoleID, State).

%% 购买VIP卡
do_vip_buy(RoleID, State, ID) ->
    case catch check_can_buy(ID, State) of
        {ok, AssetDoings, BagDoings, AddExp, IsOldExpire, ExpireTime, IsVipExperience, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = mod_role_bag:do(BagDoings, State3),
            State5 = add_exp(State4, AddExp, ?LOG_VIP_CARD, ID),
            [#c_vip_buy{name = VipName}] = lib_config:find(cfg_vip_buy, ID),
            common_broadcast:send_world_common_notice(?NOTICE_VIP_ACTIVATE, [mod_role_data:get_role_name(State), VipName]),  %% T  添加VIP卡使用公告
            common_misc:unicast(RoleID, #m_vip_buy_toc{expire_time = ExpireTime, first_buy = ID, is_vip_experience = IsVipExperience, type = 1}),
            do_notice_info(State5),
            ?IF(IsOldExpire, mod_role_fight:calc_attr_and_update(calc(State5), ?POWER_UPDATE_VIP_ON, get_vip_level(State5)), State5);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_buy_toc{err_code = ErrCode}),
            State
    end.

check_can_buy(ID, State) ->
    case lib_config:find(cfg_vip_buy, ID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_VIP_BUY_001)
    end,
    #c_vip_buy{shop_id = ShopID} = Config,
    [#c_shop{asset_type = AssetType, asset_value = AssetValue}] = lib_config:find(cfg_shop, ShopID),
    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, AssetValue, ?ASSET_GOLD_REDUCE_FROM_VIP_BUY, State),
    {ok, BagDoings, AddExp2, IsOldExpire, ExpireTime2, IsVipExperience, State2} = get_buy_vip_args(Config, State),
    {ok, AssetDoings, BagDoings, AddExp2, IsOldExpire, ExpireTime2, IsVipExperience, State2}.

get_buy_vip_args(Config, State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{expire_time = ExpireTime, first_buy_list = FirstBuyList} = RoleVip,
    #c_vip_buy{
        id = ID,
        first_add_exp = AddExp,
        add_days = AddDays,
        first_gift_list = FirstConfigString,
        gift_list = ConfigString} = Config,
    {AddExp2, ConfigString2} =
    case lists:member(ID, FirstBuyList) of
        true ->
            {1, ConfigString};
        _ ->
            {?CONFIG_EXP(AddExp), FirstConfigString}
    end,
    IsExpire = is_expire(State),
    Time = ?IF(IsExpire, time_tool:now(), ExpireTime),
    ExpireTime2 = Time + AddDays * ?ONE_DAY,
    IsVipExperience = false,
    RoleVip2 = RoleVip#r_role_vip{is_vip_experience = IsVipExperience, expire_time = ExpireTime2, first_buy_list = [ID|lists:delete(ID, FirstBuyList)]},
    BagDoings = get_vip_bag_doing(ConfigString2, ?ITEM_GAIN_VIP_GIFT, State),
    State2 = State#r_role{role_vip = RoleVip2},
    {ok, BagDoings, AddExp2, IsExpire, ExpireTime2, IsVipExperience, State2}.

%% 领取VIP礼物
do_vip_gift_get(RoleID, Level, State) ->
    case catch check_gift_get(Level, State) of
        {ok, AssetDoings, BagDoings, GiftList, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = mod_role_bag:do(BagDoings, State3),
            common_misc:unicast(RoleID, #m_vip_gift_get_toc{gift_list = GiftList}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_gift_get_toc{err_code = ErrCode}),
            State
    end.

check_gift_get(Level, State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{level = VipLevel, gift_list = GiftList} = RoleVip,
    ?IF(VipLevel >= Level andalso Level > 0, ok, ?THROW_ERR(?ERROR_VIP_GIFT_GET_001)),
    ?IF(lists:member(Level, GiftList), ?THROW_ERR(?ERROR_VIP_GIFT_GET_002), ok),
    [#c_vip_level{gift_list = ConfigString, gift_gold = GiftGold}] = lib_config:find(cfg_vip_level, Level),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, GiftGold, ?ASSET_GOLD_REDUCE_FROM_VIP_GIFT_BUY, State),
    BagDoings = get_vip_bag_doing(ConfigString, ?ITEM_GAIN_VIP_GIFT, State),
    GiftList2 = [Level|GiftList],
    RoleVip2 = RoleVip#r_role_vip{gift_list = GiftList2},
    State2 = State#r_role{role_vip = RoleVip2},
    {ok, AssetDoings, BagDoings, GiftList2, State2}.

do_vip_day_gift(RoleID, State) ->%vip日奖励
    case catch check_day_gift(State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_vip_day_gift_toc{}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_day_gift_toc{err_code = ErrCode}),
            State
    end.

check_day_gift(State) ->   %检查是否可以领取VIP日奖励
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{level = Level, day_gift_time = DayGiftTime} = RoleVip,
    ?IF(Level > 0, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL)),
    Now = time_tool:now(),
    ?IF(time_tool:is_same_date(DayGiftTime, Now), ?THROW_ERR(?ERROR_VIP_DAY_GIFT_001), ok),
    [#c_vip_level{day_gift_list = ConfigString}] = lib_config:find(cfg_vip_level, Level),
    BagDoings = get_vip_bag_doing(ConfigString, ?ITEM_GAIN_VIP_DAY_GIFT, State),
    RoleVip2 = RoleVip#r_role_vip{day_gift_time = time_tool:now()},
    State2 = State#r_role{role_vip = RoleVip2},
    {ok, BagDoings, State2}.

%% vip直升V4
do_vip_direct_v4(RoleID, State) ->
    case catch check_direct_v4(State) of
        {ok, AssetDoings, AddExp, State2} ->
            common_misc:unicast(RoleID, #m_vip_direct_v4_toc{}),
            State3 = mod_role_asset:do(AssetDoings, State2),
            add_exp(State3, AddExp, ?LOG_VIP_CARD, 0);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_direct_v4_toc{err_code = ErrCode}),
            State
    end.

check_direct_v4(State) ->
    #r_role{role_vip = RoleVip} = State,
    #r_role_vip{
        exp = NowExp,
        expire_time = ExpireTime,
        first_buy_list = FirstBuyList} = RoleVip,
    [#c_vip_level{exp = V4Exp}] = lib_config:find(cfg_vip_level, 4),
    ?IF(NowExp >= ?CONFIG_EXP(V4Exp), ?THROW_ERR(?ERROR_VIP_DIRECT_V4_001), ok),
    Now = time_tool:now(),
    ConfigList = lib_config:list(cfg_vip_buy),
    [{BuyID, BuyConfig}|ConfigList2] = lists:reverse(lists:keysort(1, ConfigList)),
    #c_vip_buy{
        shop_id = ShopID,
        first_add_exp = AddExp,
        add_days = AddDays} = BuyConfig,
    [#c_shop{asset_type = AssetType, asset_value = AssetValue}] = lib_config:find(cfg_shop, ShopID),
    {OldAddExp, OldAddDays, OldAssetValue} = check_direct_v4_i(ConfigList2, FirstBuyList),
    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, AssetValue - OldAssetValue, ?ASSET_GOLD_REDUCE_FROM_VIP_DIRECT_V4, State),
    AddTime = (AddDays - OldAddDays) * ?ONE_DAY,
    ExpireTime2 = ?IF(Now >= ExpireTime, Now + AddTime, ExpireTime + AddTime),
    RoleVip2 = RoleVip#r_role_vip{is_vip_experience = false, expire_time = ExpireTime2, first_buy_list = [BuyID|lists:delete(BuyID, FirstBuyList)]},
    State2 = State#r_role{role_vip = RoleVip2},
    {ok, AssetDoings, ?CONFIG_EXP((AddExp - OldAddExp)), State2}.

check_direct_v4_i([], _FirstBuyList) ->
    {0, 0, 0};
check_direct_v4_i([{OldID, OldConfig}|R], FirstBuyList) ->
    case lists:member(OldID, FirstBuyList) of
        true ->
            #c_vip_buy{
                shop_id = ShopID,
                first_add_exp = OldAddExp,
                add_days = OldAddDays} = OldConfig,
            [#c_shop{asset_value = AssetValue}] = lib_config:find(cfg_shop, ShopID),
            {OldAddExp, OldAddDays, AssetValue};
        _ ->
            check_direct_v4_i(R, FirstBuyList)
    end.

is_expire(State) ->
    time_tool:now() > State#r_role.role_vip#r_role_vip.expire_time.

get_config_by_key(State, Index, Default) ->
    Level = get_vip_level(State),
    case lib_config:find(cfg_vip_level, Level) of
        [Config] ->
            erlang:element(Index, Config);
        _ ->
            Default
    end.

get_vip_bag_doing(ConfigString, Action, State) ->
    ConfigList = common_misc:get_item_reward(ConfigString),
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- ConfigList],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    [{create, Action, GoodsList}].

log_vip_exp(Action, SubAction, AddExp, NowExp, OldLevel, NewLevel, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, level = RoleLevel, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    Log =
        #log_role_vip{
            role_id = RoleID,
            action_type = Action,
            sub_action_type = SubAction,
            add_exp = AddExp,
            now_exp = NowExp,
            old_vip_level = OldLevel,
            new_vip_level = NewLevel,
            role_level = RoleLevel,
            channel_id = ChannelID,
            game_channel_id = GameChannelID},
    mod_role_dict:add_background_logs(Log).


get_box_max_num(RoleID) ->
    VipLevel = common_role_data:get_role_vip_level(RoleID),
    [Config] = lib_config:find(cfg_vip_level, VipLevel),
    Config#c_vip_level.family_box_num.
%%    case VipLevel =:= 0 of
%%        true ->
%%            40;
%%        _ ->
%%            [Config] = lib_config:find(cfg_vip_level, VipLevel),
%%            Config#c_vip_level.family_box_num
%%    end.



family_box_update(Level, #r_role{role_id = RoleID, role_attr = RoleAttr}) ->
    case ?HAS_FAMILY(RoleAttr#r_role_attr.family_id) of
        true ->
%%            BoxNum = case Level =:= 0 of
%%                         true ->
%%                             40;
%%                         _ ->
%%                             [Config] = lib_config:find(cfg_vip_level, Level),
%%                             BoxNum =  Config#c_vip_level.family_box_num
%%                     end,
            [Config] = lib_config:find(cfg_vip_level, Level),
            BoxNum = Config#c_vip_level.family_box_num,
            mod_family_box:update_box_num(RoleID, RoleAttr#r_role_attr.family_id, BoxNum);
        _ ->
            ok
    end.









