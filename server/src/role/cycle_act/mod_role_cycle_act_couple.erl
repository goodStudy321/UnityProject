%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十月 2019 11:54
%%%-------------------------------------------------------------------
-module(mod_role_cycle_act_couple).
-author("laijichang").
-include("role.hrl").
-include("cycle_act.hrl").
-include("cycle_act_couple.hrl").
-include("proto/mod_role_cycle_act_couple.hrl").

%% API
-export([
    init_data/2
]).

-export([
    day_reset/1,
    zero/1,
    online/1,
    handle/2
]).

-export([
    marry/2
]).

init_data(StartTime, State) ->
    RoleActCouple = #r_role_cycle_act_couple{
        role_id = State#r_role.role_id,
        open_time = StartTime
    },
    State2 = State#r_role{role_cycle_act_couple = RoleActCouple},
    online(State2).

day_reset(State) ->
    #r_role{role_cycle_act_couple = RoleActCouple} = State,
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_COUPLE, State) of
        true ->
            case RoleActCouple of
                #r_role_cycle_act_couple{} ->
                    RoleActCouple2 = RoleActCouple#r_role_cycle_act_couple{login_reward1 = false, login_reward2 = false},
                    State#r_role{role_cycle_act_couple = RoleActCouple2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_cycle_act_couple = RoleActCouple} = State,
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_COUPLE, State) of
        true ->
            case RoleActCouple of
                #r_role_cycle_act_couple{} ->
                    #r_role_cycle_act_couple{
                        login_reward1 = LoginReward1,
                        login_reward2 = LoginReward2,
                        propose_status_list = ProposeStatusList,
                        pray_score = PrayScore,
                        pray_exchange_list = PrayExchangeList} = RoleActCouple,
                    DataRecord = #m_cycle_act_couple_toc{
                        login_reward1 = LoginReward1,
                        login_reward2 = LoginReward2,
                        propose_status_list = ProposeStatusList,
                        pray_score = PrayScore,
                        pray_exchange_list = PrayExchangeList,
                        pray_logs = world_data:get_cycle_act_couple_pray_logs()
                    },
                    common_misc:unicast(RoleID, DataRecord),
                    State;
                _ ->
                    State
            end;
        _ ->
            State
    end.

marry(Type, State) ->
    #r_role{role_id = RoleID, role_cycle_act_couple = RoleActCouple} = State,
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_COUPLE, State) of
        true ->
            case RoleActCouple of
                #r_role_cycle_act_couple{propose_status_list = ProposeStatusList} ->
                    case lists:keymember(Type, #p_kv.id, ProposeStatusList) of
                        true -> %% 已经出发
                            State;
                        _ ->
                            ProposeStatusList2 = [#p_kv{id = Type, val = ?CYCLE_ACT_COUPLE_PROPOSE_CAN_REWARD}|ProposeStatusList],
                            %% 3个都触发，可以触发称号奖励
                            ProposeStatusList3 = ?IF(erlang:length(ProposeStatusList2) =:= ?CYCLE_ACT_COUPLE_PROPOSE_LEN,
                                [#p_kv{id = ?CYCLE_ACT_COUPLE_PROPOSE_LEN + 1, val = ?CYCLE_ACT_COUPLE_PROPOSE_CAN_REWARD}|ProposeStatusList2],
                                ProposeStatusList2),
                            DataRecord = #m_cycle_act_couple_propose_status_toc{propose_status_list = ProposeStatusList3},
                            common_misc:unicast(RoleID, DataRecord),
                            RoleActCouple2 = RoleActCouple#r_role_cycle_act_couple{propose_status_list = ProposeStatusList3},
                            State#r_role{role_cycle_act_couple = RoleActCouple2}
                    end;
                _ ->
                    State
            end;
        _ ->
            State
    end.

handle({#m_cycle_act_couple_login_tos{type = Type}, RoleID, _PID}, State) ->
    do_login_reward(RoleID, Type, State);
handle({#m_cycle_act_couple_propose_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_propose_reward(RoleID, ID, State);
handle({#m_cycle_act_couple_pray_tos{times = Times}, RoleID, _PID}, State) ->
    do_pray(RoleID, Times, State);
handle({#m_cycle_act_couple_pray_exchange_tos{pray_score = PrayScore}, RoleID, _PID}, State) ->
    do_pray_exchange(RoleID, PrayScore, State);
handle({#m_cycle_act_couple_charm_rank_tos{type = Sex}, RoleID, _PID}, State) ->
    do_charm_rank(RoleID, Sex, State);
handle(Info, State) ->
    ?ERROR_MSG("Unkonw Info : ~w", [Info]),
    State.

%% 一见钟情登录奖励
do_login_reward(RoleID, Type, State) ->
    case catch check_login_reward(Type, State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_login_toc{type = Type}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_login_toc{err_code = ErrCode}),
            State
    end.

check_login_reward(Type, State) ->
    check_is_act_open(State),
    #r_role{role_cycle_act_couple = RoleActCouple} = State,
    #r_role_cycle_act_couple{
        login_reward1 = LoginReward1,
        login_reward2 = LoginReward2
    } = RoleActCouple,
    RoleActCouple2 =
        case Type of
            ?CYCLE_ACT_COUPLE_LOGIN_TYPE_NORMAL ->
                ?IF(LoginReward1, ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_LOGIN_001), ok),
                RoleActCouple#r_role_cycle_act_couple{login_reward1 = true};
            ?CYCLE_ACT_COUPLE_LOGIN_TYPE_COUPLE ->
                ?IF(LoginReward2, ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_LOGIN_001), ok),
                ?IF(mod_role_marry:has_couple(State), ok, ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_LOGIN_002)),
                RoleActCouple#r_role_cycle_act_couple{login_reward2 = true}
        end,
    Config = get_config_by_type_and_config_num(lib_config:list(cfg_cycle_act_couple_login), Type, #c_cycle_act_couple_login.type, #c_cycle_act_couple_login.config_num),
    #c_cycle_act_couple_login{reward = Reward} = Config,
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_CYCLE_ACT_COUPLE_LOGIN, GoodsList}],
    State2 = State#r_role{role_cycle_act_couple = RoleActCouple2},
    {ok, BagDoings, State2}.

%% 告别单身奖励
do_propose_reward(RoleID, ID, State) ->
    case catch check_propose_reward(ID, State) of
        {ok, ProposeStatus, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_propose_reward_toc{propose_status = ProposeStatus}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_propose_reward_toc{err_code = ErrCode}),
            State
    end.

check_propose_reward(ID, State) ->
    check_is_act_open(State),
    #r_role{role_cycle_act_couple = RoleActCouple} = State,
    #r_role_cycle_act_couple{propose_status_list = ProposeStatusList} = RoleActCouple,
    {KV, ProposeStatusList2} =
        case lists:keytake(ID, #p_kv.id, ProposeStatusList) of
            {value, KVT, ProposeStatusListT} ->
                {KVT, ProposeStatusListT};
            _ ->
                ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_PROPOSE_REWARD_001)
        end,
    #p_kv{val = Status} = KV,
    ?IF(Status =:= ?CYCLE_ACT_COUPLE_PROPOSE_CAN_REWARD, ok, ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_PROPOSE_REWARD_002)),
    KV2 = KV#p_kv{val = ?CYCLE_ACT_COUPLE_PROPOSE_HAS_REWARD},
    Config = get_config_by_type_and_config_num(lib_config:list(cfg_cycle_act_couple_propose), ID, #c_cycle_act_couple_propose.type, #c_cycle_act_couple_propose.config_num),
    #c_cycle_act_couple_propose{reward = Reward} = Config,
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    BagDoings = [{create, ?ITEM_GAIN_CYCLE_ACT_PROPOSE_REWARD, GoodsList}],
    ProposeStatusList3 = [KV2|ProposeStatusList2],
    RoleActCouple2 = RoleActCouple#r_role_cycle_act_couple{propose_status_list = ProposeStatusList3},
    State2 = State#r_role{role_cycle_act_couple = RoleActCouple2},
    {ok, KV2, BagDoings, State2}.

%% 月下情缘奖励抽取
do_pray(RoleID, Times, State) ->
    case catch check_pray(Times, State) of
        {ok, AssetDoings, BagDoings, RewardTypeList, PrayScore, GoodsList, PrayLogs, State2} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_pray_toc{reward_type_list = RewardTypeList, pray_score = PrayScore, goods_list = GoodsList}),
            act_couple:add_pray_logs(PrayLogs),
            mod_role_bag:do(BagDoings, mod_role_asset:do(AssetDoings, State2));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_pray_toc{err_code = ErrCode}),
            State
    end.

check_pray(Times, State) ->
    check_is_act_open(State),
    ?IF(lists:member(Times, [?CYCLE_ACT_COUPLE_PRAY_ONE, ?CYCLE_ACT_COUPLE_PRAY_TEN]), ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [NeedGold, NeedTypeID, FlowerID|_] = common_misc:get_global_list(?GLOBAL_CYCLE_ACT_COUPLE_PRAY),
    HasNum = mod_role_bag:get_num_by_type_id(NeedTypeID, State),
    {AssetDoings, BagDoings, AddFlowerGoods} =
        case HasNum >= Times of
            true ->
                {[],  [{decrease, ?ITEM_REDUCE_CYCLE_ACT_COUPLE_PRAY, [#r_goods_decrease_info{type_id = NeedTypeID, num = Times}]}], []};
            _ ->
                BagDoingsT = ?IF(HasNum > 0, [{decrease, ?ITEM_REDUCE_CYCLE_ACT_COUPLE_PRAY, [#r_goods_decrease_info{type_id = NeedTypeID, num = HasNum}]}], []),
                GoldNum = Times - HasNum,
                ConsumeGoldT = NeedGold * GoldNum,
                AssetDoingsT = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, ConsumeGoldT, ?ASSET_GOLD_REDUCE_FROM_CYCLE_ACT_COUPLE_PRAY, State),
                {AssetDoingsT, BagDoingsT, [#p_goods{type_id = FlowerID, num = GoldNum}]}
        end,
    #r_role{role_cycle_act_couple = RoleActCouple} = State,
    #r_role_cycle_act_couple{pray_times = PrayTimes, pray_score = PrayScore} = RoleActCouple,
    RoleName = mod_role_data:get_role_name(State),
    ConfigList = lib_config:list(cfg_cycle_act_couple_pray),
    #r_cycle_act{config_num = ConfigNum} = world_cycle_act_server:get_act(?CYCLE_ACT_COUPLE),
    ConfigList2 = [ Config || {_, #c_cycle_act_couple_pray{config_num = ConfigNumT} = Config} <- ConfigList, ConfigNum =:= ConfigNumT],
    [{MinTimes, MaxTimes}|_] = common_misc:get_global_string_list(?GLOBAL_CYCLE_ACT_COUPLE_PRAY),
    {PrayTimes2, PrayScore2, TypeList, PrayLogs, GoodsList} = check_pray2(Times, ConfigList2, RoleName, MinTimes, MaxTimes, PrayTimes, PrayScore, [], [], []),
    GoodsList2 = AddFlowerGoods ++ GoodsList,
    mod_role_bag:check_bag_empty_grid(GoodsList2, State),
    BagDoings2 = [{create, ?ITEM_GAIN_CYCLE_ACT_PRAY, GoodsList2}],
    RoleActCouple2 = RoleActCouple#r_role_cycle_act_couple{pray_times = PrayTimes2, pray_score = PrayScore2},
    State2 = State#r_role{role_cycle_act_couple = RoleActCouple2},
    {ok, AssetDoings, BagDoings ++ BagDoings2, TypeList, PrayScore2, GoodsList2, PrayLogs, State2}.

check_pray2(0, _ConfigList, _RoleName, _MinTimes, _MaxTimes, PrayTimes, PrayScore, TypeAcc, PrayLogsAcc, GoodsAcc) ->
    {PrayTimes, PrayScore, TypeAcc, PrayLogsAcc, GoodsAcc};
check_pray2(Times, ConfigList, RoleName, MinTimes, MaxTimes, PrayTimes, PrayScore, TypeAcc, PrayLogsAcc, GoodsAcc) ->
    Fun =
        if
            PrayTimes < MinTimes ->
                fun(ConfigType) -> ConfigType =/= ?CYCLE_ACT_COUPLE_PRAY_BIG_TYPE end;
            PrayTimes >= MaxTimes ->
                fun(ConfigType) -> ConfigType =:= ?CYCLE_ACT_COUPLE_PRAY_BIG_TYPE end;
            true ->
                fun(_ConfigType) -> true end
        end,
    WeightList = [ {Weight, Config}|| #c_cycle_act_couple_pray{type = ConfigType, weight = Weight} = Config <- ConfigList, Fun(ConfigType)],
    #c_cycle_act_couple_pray{type = Type, reward = RewardWeight} = lib_tool:get_weight_output(WeightList),
    PrayTimes2 = ?IF(Type =:= ?CYCLE_ACT_COUPLE_PRAY_BIG_TYPE, 0, PrayTimes + 1),
    PrayScore2 = PrayScore + 1,
    RewardWeight2 = [ {Weight, {TypeID, Num}} || {TypeID, Num, Weight, _} <- lib_tool:string_to_intlist(RewardWeight)],
    {RewardTypeID, RewardNum} = lib_tool:get_weight_output(RewardWeight2),
    GoodsAcc2 = [#p_goods{type_id = RewardTypeID, num = RewardNum}|GoodsAcc],
    PrayLogsAcc2 = [#p_pray_log{role_name = RoleName, reward_type = Type, type_id_list = [RewardTypeID]}|PrayLogsAcc],
    check_pray2(Times - 1, ConfigList, RoleName, MinTimes, MaxTimes, PrayTimes2, PrayScore2, [Type|TypeAcc], PrayLogsAcc2, GoodsAcc2).

%% 月下情缘奖励兑换
do_pray_exchange(RoleID, Score, State) ->
    case catch check_pray_exchange(Score, State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_pray_exchange_toc{pray_score = Score}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_act_couple_pray_exchange_toc{err_code = ErrCode}),
            State
    end.

check_pray_exchange(Score, State) ->
    check_is_act_open(State),
    #r_role{role_cycle_act_couple = RoleActCouple} = State,
    #r_role_cycle_act_couple{pray_score = PrayScore, pray_exchange_list = PrayExchangeList} = RoleActCouple,
    ?IF(lists:member(Score, PrayExchangeList), ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_PRAY_EXCHANGE_001), ok),
    ?IF(PrayScore >= Score, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    Config = get_config_by_type_and_config_num(lib_config:list(cfg_cycle_act_couple_pray_exchange), Score,
        #c_cycle_act_couple_pray_exchange.need_score, #c_cycle_act_couple_pray_exchange.config_num),
    Reward =
        case Config of
            #c_cycle_act_couple_pray_exchange{reward = RewardT} ->
                RewardT;
            _ ->
                ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_PRAY_EXCHANGE_002)
        end,
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    BagDoings = [{create, ?ITEM_GAIN_CYCLE_ACT_PRAY_EXCHANGE, GoodsList}],
    PrayExchangeList2 = [Score|PrayExchangeList],
    RoleActCouple2 = RoleActCouple#r_role_cycle_act_couple{pray_exchange_list = PrayExchangeList2},
    State2 = State#r_role{role_cycle_act_couple = RoleActCouple2},
    {ok, BagDoings, State2}.

do_charm_rank(RoleID, Sex, State) ->
    CharmList = world_data:get_cycle_act_couple_charm(),
    Date = erlang:date(),
    MyCharm =
        case lists:keyfind(RoleID, #r_cycle_act_couple_charm.role_id, CharmList) of
            #r_cycle_act_couple_charm{date = Date, charm = MyCharmT} ->
                MyCharmT;
            _ ->
                0
        end,
    PRanks =
        [ begin
              #r_charm_rank{
                  rank = Rank,
                  role_id = RankRoleID,
                  role_name = RankRoleName,
                  category = RankCategory,
                  sex = RankSex,
                  charm = RankNowCharm,
                  server_name = RankServerName
              } = CharmRank,
              #p_charm_rank{
                  rank = Rank,
                  role_id = RankRoleID,
                  role_name = RankRoleName,
                  category = RankCategory,
                  sex = RankSex,
                  charm = RankNowCharm,
                  server_name = RankServerName
              }
          end|| #r_charm_rank{} = CharmRank <- global_data:get_cycle_act_couple_rank({Date, Sex})],
    common_misc:unicast(RoleID, #m_cycle_act_couple_charm_rank_toc{ranks = PRanks, my_charm = MyCharm, type = Sex}),
    State.

check_is_act_open(State) ->
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_COUPLE, State), ok, ?THROW_ERR(?ERROR_CYCLE_ACT_COUPLE_LOGIN_003)).

get_config_by_type_and_config_num(ConfigList, Type, TypeIndex, ConfigNumIndex) ->
    #r_cycle_act{config_num = ConfigNum} = world_cycle_act_server:get_act(?CYCLE_ACT_COUPLE),
    get_config_by_type_and_config_num(ConfigList, Type, TypeIndex, ConfigNum, ConfigNumIndex).

get_config_by_type_and_config_num([], Type, _TypeIndex, ConfigNum, _ConfigNumIndex) ->
    ?ERROR_MSG("unknow Type:~w and ConfigIndex:~w", [Type, ConfigNum]),
    error;
get_config_by_type_and_config_num([{_, Config}|R], Type, TypeIndex, ConfigNum, ConfigNumIndex) ->
    ?INFO_MSG("test:~w", [{Config, ConfigNumIndex, TypeIndex}]),
    case erlang:element(ConfigNumIndex, Config) =:= ConfigNum andalso erlang:element(TypeIndex, Config) =:= Type of
        true ->
            Config;
        _ ->
            get_config_by_type_and_config_num(R, Type, TypeIndex, ConfigNum, ConfigNumIndex)
    end.