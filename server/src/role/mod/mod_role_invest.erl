%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     月卡 && 投资计划
%%% @end
%%% Created : 18. 六月 2018 14:52
%%%-------------------------------------------------------------------
-module(mod_role_invest).
-author("laijichang").
-include("role.hrl").
-include("red_packet.hrl").
-include("proto/mod_role_invest.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    zero/1,
    online/1,
    handle/2
]).

-export([
    vip_level_up/1
]).

init(#r_role{role_id = RoleID, role_invest = undefined} = State) ->
    RoleInvest = #r_role_invest{role_id = RoleID},
    State#r_role{role_invest = RoleInvest};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{month_card_days = MonthCardDays, vip_invest_days = VipInvestDays} = RoleInvest,
    RoleInvest2 = ?IF(MonthCardDays > 0, RoleInvest#r_role_invest{is_month_card_reward = false}, RoleInvest),
    RoleInvest3 = ?IF(VipInvestDays > 0, RoleInvest2#r_role_invest{is_vip_invest_reward = false}, RoleInvest2),
    State#r_role{role_invest = RoleInvest3}.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_invest = RoleInvest} = State,
    #r_role_invest{
        invest_gold = InvestGold,
        invest_reward_list = InvestRewardList,
        is_month_card_reward = IsMonthCardReward,
        is_principal_reward = IsPrincipal,
        month_card_days = MonthDays,
        is_vip_invest_reward = IsVipReward,
        vip_invest_level = VipInvestLevel,
        vip_invest_days = VipInvestDays,
        summit_invest_gold = SummitInvestGold,
        summit_reward_list = SummitRewardList
    } = RoleInvest,
    case SummitInvestGold > 0 of
        true ->
            common_misc:unicast(RoleID, #m_summit_invest_gold_info_toc{summit_invest_gold = SummitInvestGold, reward_list = SummitRewardList});
        _ ->
            ?IF(InvestGold > 0 orelse common_config:is_open_7days(), common_misc:unicast(RoleID, #m_invest_gold_info_toc{invest_gold = InvestGold, reward_list = InvestRewardList}), ok)
    end,
    ?IF(MonthDays > 0 orelse (not IsPrincipal),
        common_misc:unicast(RoleID, #m_month_card_info_toc{is_reward = IsMonthCardReward, is_principal_reward = IsPrincipal, remain_days = MonthDays}),
        ok),
    ?IF(VipInvestDays > 0, common_misc:unicast(RoleID, #m_vip_invest_info_toc{is_reward = IsVipReward, reward_level = VipInvestLevel, remain_days = VipInvestDays}), ok),
    State.

handle({#m_invest_gold_buy_tos{invest_gold = Gold}, RoleID, _PID}, State) ->
    do_invest_gold(RoleID, Gold, State);
handle({#m_invest_gold_reward_tos{level = Level}, RoleID, _PID}, State) ->
    do_invest_reward(RoleID, Level, State);
handle({#m_month_card_buy_tos{}, RoleID, _PID}, State) ->
    do_buy_month_card(RoleID, State);
handle({#m_month_card_reward_tos{days = Days}, RoleID, _PID}, State) ->
    do_month_card_reward(RoleID, Days, State);
handle({#m_vip_invest_buy_tos{}, RoleID, _PID}, State) ->
    do_buy_vip_invest(RoleID, State);
handle({#m_vip_invest_reward_tos{}, RoleID, _PID}, State) ->
    do_vip_invest_reward(RoleID, State);
handle({#m_summit_invest_gold_buy_tos{summit_invest_gold = Gold}, RoleID, _PID}, State) ->
    do_summit_invest_gold(RoleID, Gold, State);
handle({#m_summit_invest_gold_reward_tos{level = Level}, RoleID, _PID}, State) ->
    do_summit_invest_reward(RoleID, Level, State).

%% 投资某一档
do_invest_gold(RoleID, Gold, State) ->
    case catch check_invest_gold(Gold, State) of
        {ok, AssetDoing, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_invest_gold_buy_toc{invest_gold = Gold}),
            common_broadcast:send_world_common_notice(?NOTICE_INVEST_GOLD, [State#r_role.role_attr#r_role_attr.role_name, lib_tool:to_list(Gold)]),
            State4 = mod_role_god_book:invest(State3),
            mod_role_dict:add_background_logs(Log),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_invest_gold_buy_toc{err_code = ErrCode}),
            State
    end.

check_invest_gold(BuyGold, #r_role{role_id = RoleID} = State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{invest_gold = InvestGold} = RoleInvest,
    [#c_global{list = GoldList, int = MaxLevel}] = lib_config:find(cfg_global, ?GLOBAL_INVEST_GOLD),
    ?IF(lists:member(BuyGold, GoldList), ok, ?THROW_ERR(?ERROR_INVEST_GOLD_BUY_001)),
    ?IF(BuyGold > InvestGold, ok, ?THROW_ERR(?ERROR_INVEST_GOLD_BUY_002)),
    ?IF(mod_role_data:get_role_level(State) > MaxLevel, ?THROW_ERR(?ERROR_INVEST_GOLD_BUY_003), ok),
    NeedGold = BuyGold - InvestGold,
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_INVEST_GOLD, State),
    RoleInvest2 = RoleInvest#r_role_invest{invest_gold = BuyGold},
    State2 = State#r_role{role_invest = RoleInvest2},
    Log = get_invest_log(BuyGold, State2),
    ?IF(lists:max(GoldList) =:= BuyGold, mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, ?RED_PACKET_FAMILY_INVEST), ok),
    {ok, AssetDoing, Log, State2}.




do_invest_reward(RoleID, Level, State) ->
    case catch check_invest_reward(Level, State) of
        {ok, AssetDoing, Reward, AddGold, State2} ->
            common_misc:unicast(RoleID, #m_invest_gold_reward_toc{reward = Reward, add_gold = AddGold}),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_invest_gold_reward_toc{err_code = ErrCode}),
            State
    end.

check_invest_reward(Level, State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{invest_gold = InvestGold, invest_reward_list = RewardList} = RoleInvest,
    ?IF(mod_role_data:get_role_level(State) >= Level, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(InvestGold > 0, ok, ?THROW_ERR(?ERROR_INVEST_GOLD_REWARD_001)),
    GoldList = common_misc:get_global_list(?GLOBAL_INVEST_GOLD),
    Index = get_invest_reward_index(InvestGold, GoldList, 1),
    RewardGoldList =
    case lib_config:find(cfg_invest_gold, Level) of
        [#c_invest_gold{gold_list = List}] ->
            List;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    case lists:keyfind(Level, #p_kv.id, RewardList) of
        #p_kv{val = RewardIndexGold} = OldReward ->
            ?IF(InvestGold > RewardIndexGold, ok, ?THROW_ERR(?ERROR_INVEST_GOLD_REWARD_002)),
            Reward = OldReward#p_kv{val = InvestGold},
            OldIndex = get_invest_reward_index(RewardIndexGold, GoldList, 1),
            OldGold = lists:nth(OldIndex, RewardGoldList),
            NewGold = lists:nth(Index, RewardGoldList),
            AddGold = NewGold - OldGold;
        _ ->
            Reward = #p_kv{id = Level, val = InvestGold},
            AddGold = lists:nth(Index, RewardGoldList)
    end,
    AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_INVEST_GOLD, 0, AddGold}],
    RewardList2 = lists:keystore(Level, #p_kv.id, RewardList, Reward),
    RoleInvest2 = RoleInvest#r_role_invest{invest_reward_list = RewardList2},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, AssetDoing, Reward, AddGold, State2}.

get_invest_reward_index(InvestGold, [Gold|R], Index) ->
    case InvestGold =:= Gold of
        true ->
            Index;
        _ ->
            get_invest_reward_index(InvestGold, R, Index + 1)
    end.

%% 购买月卡
do_buy_month_card(RoleID, State) ->
    case catch check_buy_month_card(State) of
        {ok, AssetDoing, IsReward, IsPrincipal, MonthCardDays, State2} ->
            mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, ?RED_PACKET_FAMILY_MONTH_CARD),
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_month_card_buy_toc{is_reward = IsReward, is_principal_reward = IsPrincipal, remain_days = MonthCardDays}),
            State4 = mod_role_god_book:month_card(State3),
            common_broadcast:send_world_common_notice(?NOTICE_MONTH_CARD, [State#r_role.role_attr#r_role_attr.role_name]),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_month_card_buy_toc{err_code = ErrCode}),
            State
    end.

check_buy_month_card(State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{month_card_days = Days, is_principal_reward = OldIsPrincipal} = RoleInvest,
    ?IF(Days > 0 orelse (not OldIsPrincipal), ?THROW_ERR(?ERROR_MONTH_CARD_BUY_001), ok),
    NeedGold = common_misc:get_global_int(?GLOBAL_MONTH_CARD),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_MONTH_CARD, State),
    IsReward = false,
    IsPrincipal = false,
    MonthCardDays = ?MONTH_CARD_DAY,
    RoleInvest2 = RoleInvest#r_role_invest{is_month_card_reward = IsReward, is_principal_reward = IsPrincipal, month_card_days = MonthCardDays},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, AssetDoing, IsReward, IsPrincipal, MonthCardDays, State2}.

%% 领取月卡奖励
do_month_card_reward(RoleID, Days, State) ->
    case catch check_month_card_reward(Days, State) of
        {ok, AssetDoing, IsReward, IsPrincipal, RemainDays2, AddGold, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_month_card_reward_toc{
                is_reward = IsReward,
                is_principal_reward = IsPrincipal,
                remain_days = RemainDays2,
                add_gold = AddGold}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_month_card_reward_toc{err_code = ErrCode}),
            State
    end.

check_month_card_reward(Days, State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{is_month_card_reward = OldIsReward, is_principal_reward = OldIsPrincipal, month_card_days = RemainDays} = RoleInvest,
    case Days > 0 of
        true -> %% 领取天数奖励
            ?IF(OldIsReward, ?THROW_ERR(?ERROR_MONTH_CARD_REWARD_002), ok),
            ?IF(RemainDays > 0, ok, ?THROW_ERR(?ERROR_MONTH_CARD_REWARD_001)),
            Days = ?MONTH_CARD_DAY - RemainDays + 1,
            RemainDays2 = RemainDays - 1,
            IsReward = true,
            IsPrincipal = OldIsPrincipal;
        _ -> %% 领取本金
            ?IF(OldIsPrincipal, ?THROW_ERR(?ERROR_MONTH_CARD_REWARD_002), ok),
            Days = 0,
            RemainDays2 = RemainDays,
            IsReward = OldIsReward,
            IsPrincipal = true
    end,
    case lib_config:find(cfg_month_card, Days) of
        [#c_month_card{gold = Gold}] ->
            ok;
        _ ->
            Gold = ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_MONTH_CARD, 0, Gold}],
    RoleInvest2 = RoleInvest#r_role_invest{is_month_card_reward = IsReward, is_principal_reward = IsPrincipal, month_card_days = RemainDays2},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, AssetDoing, IsReward, IsPrincipal, RemainDays2, Gold, State2}.


vip_level_up(State) ->
    #r_role{role_id = RoleID, role_invest = RoleInvest} = State,
    #r_role_invest{is_vip_first_add = IsVipFirstAdd} = RoleInvest,
    case IsVipFirstAdd of
        true ->
            State;
        _ ->
            [NeedVipLevel, _NeedGold] = common_misc:get_global_list(?GLOBAL_VIP_INVEST),
            case mod_role_vip:get_vip_level(State) >= NeedVipLevel of
                true ->
                    IsReward = false,
                    VipInvestDays = ?VIP_INVEST_DAY,
                    VipInvestLevel = get_vip_invest_level(mod_role_data:get_role_level(State)),
                    RoleInvest2 = RoleInvest#r_role_invest{
                        is_vip_first_add = true,
                        is_vip_invest_reward = IsReward,
                        vip_invest_level = VipInvestLevel,
                        vip_invest_days = VipInvestDays},
                    common_misc:unicast(RoleID, #m_vip_invest_info_toc{is_reward = IsReward, reward_level = VipInvestLevel, remain_days = VipInvestDays}),
                    State#r_role{role_invest = RoleInvest2};
                _ ->
                    State
            end
    end.


%% 购买vip投资计划
do_buy_vip_invest(RoleID, State) ->
    case catch check_buy_vip_invest(State) of
        {ok, AssetDoing, IsReward, VipInvestDays, VipInvestLevel, State2} ->
            mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, ?RED_PACKET_FAMILY_VIP_INVEST),
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_vip_invest_buy_toc{is_reward = IsReward, remain_days = VipInvestDays, reward_level = VipInvestLevel}),
            common_broadcast:send_world_common_notice(?NOTICE_VIP_INVEST, [State#r_role.role_attr#r_role_attr.role_name]),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_invest_buy_toc{err_code = ErrCode}),
            State
    end.

check_buy_vip_invest(State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{vip_invest_days = Days} = RoleInvest,
    ?IF(Days > 0, ?THROW_ERR(?ERROR_MONTH_CARD_BUY_001), ok),
    [NeedVipLevel, NeedGold] = common_misc:get_global_list(?GLOBAL_VIP_INVEST),
    ?IF(mod_role_vip:get_vip_level(State) >= NeedVipLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL)),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_VIP_INVEST, State),
    IsReward = false,
    VipInvestDays = ?VIP_INVEST_DAY,
    VipInvestLevel = get_vip_invest_level(mod_role_data:get_role_level(State)),
    RoleInvest2 = RoleInvest#r_role_invest{is_vip_invest_reward = IsReward, vip_invest_days = VipInvestDays, vip_invest_level = VipInvestLevel},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, AssetDoing, IsReward, VipInvestDays, VipInvestLevel, State2}.

%% 领取月卡奖励
do_vip_invest_reward(RoleID, State) ->
    case catch check_vip_invest_reward(State) of
        {ok, BagDoings, RemainDays2, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_vip_invest_reward_toc{is_reward = true, remain_days = RemainDays2}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_vip_invest_reward_toc{err_code = ErrCode}),
            State
    end.

check_vip_invest_reward(State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{is_vip_invest_reward = IsReward, vip_invest_level = InvestLevel, vip_invest_days = RemainDays} = RoleInvest,
    ?IF(RemainDays > 0, ok, ?THROW_ERR(?ERROR_VIP_INVEST_REWARD_001)),
    ?IF(IsReward, ?THROW_ERR(?ERROR_VIP_INVEST_REWARD_002), ok),
    Rewards =
    case lib_config:find(cfg_vip_invest, ?GET_VIP_INVEST_ID(InvestLevel, ?VIP_INVEST_DAY - RemainDays + 1)) of
        [#c_vip_invest{rewards = List}] ->
            List;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(IsBind)} || {TypeID, Num, IsBind} <- common_misc:get_item_reward(Rewards)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_VIP_INVEST, GoodsList}],
    RemainDays2 = RemainDays - 1,
    RoleInvest2 = RoleInvest#r_role_invest{is_vip_invest_reward = true, vip_invest_days = RemainDays2},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, BagDoings, RemainDays2, State2}.

get_vip_invest_level(Level) ->
    ConfigList = cfg_vip_invest:list(),
    get_vip_invest_level2(Level, ConfigList).

get_vip_invest_level2(Level, [{_ID, Config}|R]) ->
    #c_vip_invest{id = ID, min_level = MinLevel, max_level = MaxLevel} = Config,
    case MinLevel =< Level andalso Level =< MaxLevel of
        true ->
            ?GET_VIP_INVEST_LEVEL(ID);
        _ ->
            get_vip_invest_level2(Level, R)
    end.

%% 投资某一档
do_summit_invest_gold(RoleID, Gold, State) ->
    case catch check_summit_invest_gold(Gold, State) of
        {ok, AssetDoing, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_summit_invest_gold_buy_toc{summit_invest_gold = Gold}),
            mod_role_dict:add_background_logs(Log),
            State4 = mod_role_god_book:invest(State3),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_summit_invest_gold_buy_toc{err_code = ErrCode}),
            State
    end.

check_summit_invest_gold(BuyGold, State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{summit_invest_gold = SummitInvestGold} = RoleInvest,
    [#c_global{list = GoldList}] = lib_config:find(cfg_global, ?GLOBAL_SUMMIT_INVEST_GOLD),
    MaxLevel = common_misc:get_global_int(?GLOBAL_INVEST_GOLD),
    ?IF(lists:member(BuyGold, GoldList), ok, ?THROW_ERR(?ERROR_SUMMIT_INVEST_GOLD_BUY_001)),
    ?IF(BuyGold > SummitInvestGold, ok, ?THROW_ERR(?ERROR_SUMMIT_INVEST_GOLD_BUY_002)),
    ?IF(mod_role_data:get_role_level(State) >= MaxLevel, ok, ?THROW_ERR(?ERROR_SUMMIT_INVEST_GOLD_BUY_003)),
    NeedGold = BuyGold - SummitInvestGold,
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_SUMMIT_INVEST, State),
    RoleInvest2 = RoleInvest#r_role_invest{summit_invest_gold = BuyGold},
    State2 = State#r_role{role_invest = RoleInvest2},
    Log = get_summit_invest_log(BuyGold, State2),
    {ok, AssetDoing, Log, State2}.

do_summit_invest_reward(RoleID, Level, State) ->
    case catch check_summit_invest_reward(Level, State) of
        {ok, BagDoings, Reward, State2} ->
            common_misc:unicast(RoleID, #m_summit_invest_gold_reward_toc{reward = Reward}),
            State3 = mod_role_bag:do(BagDoings, State2),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_summit_invest_gold_reward_toc{err_code = ErrCode}),
            State
    end.

check_summit_invest_reward(Level, State) ->
    #r_role{role_invest = RoleInvest} = State,
    #r_role_invest{summit_invest_gold = SummitInvestGold, summit_reward_list = RewardList} = RoleInvest,
    ?IF(mod_role_data:get_role_level(State) >= Level, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(SummitInvestGold > 0, ok, ?THROW_ERR(?ERROR_SUMMIT_INVEST_GOLD_REWARD_001)),
    GoldList = common_misc:get_global_list(?GLOBAL_SUMMIT_INVEST_GOLD),
    Index = get_invest_reward_index(SummitInvestGold, GoldList, 1),
    Config =
        case lib_config:find(cfg_summit_invest, Level) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
        end,
    case lists:keyfind(Level, #p_kv.id, RewardList) of
        #p_kv{val = RewardIndexGold} = OldReward ->
            ?IF(SummitInvestGold > RewardIndexGold, ok, ?THROW_ERR(?ERROR_SUMMIT_INVEST_GOLD_REWARD_002)),
            Reward = OldReward#p_kv{val = SummitInvestGold},
            OldIndex = get_invest_reward_index(RewardIndexGold, GoldList, 1),
            GoodsIndexList = lists:seq(OldIndex + 1, Index);
        _ ->
            Reward = #p_kv{id = Level, val = SummitInvestGold},
            GoodsIndexList = lists:seq(1, Index)
    end,
    #c_summit_invest_gold{goods_1 = Goods1, goods_2 = Goods2, goods_3 = Goods3} = Config,
    GoodsList = get_goods_by_index_list(GoodsIndexList, [{1, Goods1}, {2, Goods2}, {3, Goods3}], []),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_SUMMIT_INVEST, GoodsList}],
    RewardList2 = lists:keystore(Level, #p_kv.id, RewardList, Reward),
    RoleInvest2 = RoleInvest#r_role_invest{summit_reward_list = RewardList2},
    State2 = State#r_role{role_invest = RoleInvest2},
    {ok, BagDoings, Reward, State2}.

get_goods_by_index_list([], _ConfigList, Acc) ->
    Acc;
get_goods_by_index_list([GoodsIndex|R], ConfigList, GoodsAcc) ->
    {value, {_, ConfigGoods}, ConfigList2} = lists:keytake(GoodsIndex, 1, ConfigList),
    GoodsList = [ #p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(ConfigGoods)],
    get_goods_by_index_list(R, ConfigList2, GoodsList ++ GoodsAcc).


get_invest_log(BuyGold, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{level = RoleLevel, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_role_invest{
        role_id = RoleID,
        role_level = RoleLevel,
        gold = BuyGold,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_summit_invest_log(BuyGold, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{level = RoleLevel, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_role_summit_invest{
        role_id = RoleID,
        role_level = RoleLevel,
        gold = BuyGold,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.