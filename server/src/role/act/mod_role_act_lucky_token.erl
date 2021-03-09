%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 九月 2019 10:28
%%%-------------------------------------------------------------------
-module(mod_role_act_lucky_token).
-author("laijichang").
-include("role.hrl").
-include("lucky_token.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_act_lucky_token.hrl").

%% API
-export([
    online/1,
    handle/2
]).

-export([
    init_data/2
]).

online(State) ->
    #r_role{role_id = RoleID, role_act_lucky_token = RoleActLuckyToken} = State,
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_LUCKY_TOKEN, State) of
        true ->
            case RoleActLuckyToken of
                #r_role_act_lucky_token{level = Level, remain_num = RemainNum, big_reward = BigReward} ->
                    common_misc:unicast(RoleID, #m_lucky_token_info_toc{level = Level, remain_num = RemainNum, big_reward = BigReward}),
                    State;
                _ ->
                    State
            end;
        _ ->
            State
    end.

init_data(StartTime, State) ->
    WorldLevel = world_data:get_world_level(),
    ConfigIndex = get_config_index(),
    RoleActLuckyToken = #r_role_act_lucky_token{
        role_id = State#r_role.role_id,
        remain_num = common_misc:get_global_int(?GLOBAL_ACT_LUCKY_TOKEN),
        level = WorldLevel,
        big_reward = get_big_reward_index(0, WorldLevel, ConfigIndex),
        open_time = StartTime
    },
    State2 = State#r_role{role_act_lucky_token = RoleActLuckyToken},
    online(State2).

handle({#m_lucky_token_pray_tos{times = Times}, RoleID, _Pid}, State) ->
    do_lucky_token_pray(RoleID, Times, State).

do_lucky_token_pray(RoleID, Times, State) ->
    case catch check_lucky_token_pray(Times, State) of
        {ok, Level, RemainNum, BigIndexID, AssetDoings, GoodsList, RewardIndexList, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = role_misc:create_goods(State3, ?ITEM_GAIN_LUCKY_TOKEN, GoodsList),
            DataRecord = #m_lucky_token_pray_toc{level = Level, remain_num = RemainNum, big_reward = BigIndexID, reward_index_list = RewardIndexList},
            common_misc:unicast(RoleID, DataRecord),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_lucky_token_pray_toc{err_code = ErrCode}),
            State
    end.

check_lucky_token_pray(Times, State) ->
    Index =
        if
            Times =:= ?LUCKY_TOKEN_TIMES_1 ->
                1;
            Times =:= ?LUCKY_TOKEN_TIMES_10 ->
                2;
            true ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    List = common_misc:get_global_string_list(?GLOBAL_ACT_LUCKY_TOKEN),
    {AssetType, AssetValue} = lists:nth(Index, List),
    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, AssetValue, ?ASSET_GOLD_REDUCE_FROM_LUCKY_TOKEN, State),
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_LUCKY_TOKEN, State), ok, ?THROW_ERR(?ERROR_LUCKY_TOKEN_PRAY_001)),
    mod_role_bag:check_bag_empty_grid(Times, State),
    #r_role{role_act_lucky_token = RoleActLuckyToken} = State,
    #r_role_act_lucky_token{level = Level, remain_num = RemainNum, big_reward = BigIndexID} = RoleActLuckyToken,
    ?IF(RemainNum >= Times, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [BigConfig] = lib_config:find(cfg_lucky_token, BigIndexID),
    ConfigIndex = get_config_index(),
    ConfigList = get_normal_config(Level, ConfigIndex, lib_config:list(cfg_lucky_token)),
    {Level2, RemainNum2, BigIndexID2, IsBigReward, GoodsList, RewardIndexList} = check_lucky_token_pray2(Times, ConfigList, Level, RemainNum, BigConfig, ConfigIndex, false, [], []),
    RemainNum3 = ?IF(IsBigReward, common_misc:get_global_int(?GLOBAL_ACT_LUCKY_TOKEN), RemainNum2),
    RoleActLuckyToken2 = RoleActLuckyToken#r_role_act_lucky_token{level = Level2, remain_num = RemainNum3, big_reward = BigIndexID2},
    State2 = State#r_role{role_act_lucky_token = RoleActLuckyToken2},
    {ok, Level2, RemainNum3, BigIndexID2, AssetDoings, GoodsList, RewardIndexList, State2}.



check_lucky_token_pray2(0, _ConfigList, Level, RemainNum, BigConfig, _ConfigIndex, IsBigReward, GoodsList, RewardIndexList) ->
    {Level, RemainNum, BigConfig#c_lucky_token.index_id, IsBigReward, GoodsList, RewardIndexList};
check_lucky_token_pray2(Times, ConfigList, Level, RemainNum, BigConfig, ConfigIndex, IsBigReward, GoodsList, RewardIndexList) ->
    Times2 = Times - 1,
    case not IsBigReward andalso RemainNum =:= 1 of
        true -> %% 最后一次，并且之前没有触发过大奖
            check_lucky_token_big(Times2, RemainNum, BigConfig, ConfigIndex, GoodsList, RewardIndexList);
        _ ->
            %% 当前抽取过大奖，就不能再抽了
            WeightList = ?IF(IsBigReward, get_weight_list(RemainNum, ConfigList), get_weight_list(RemainNum, [BigConfig|ConfigList])),
            Config = lib_tool:get_weight_output(WeightList),
            case Config =:= BigConfig of
                true ->
                    check_lucky_token_big(Times2, RemainNum, BigConfig, ConfigIndex, GoodsList, RewardIndexList);
                _ ->
                    #c_lucky_token{index_id = RewardIndexID, item_type_id = ItemTypeID, item_num = ItemNum} = Config,
                    GoodsList2 = [#p_goods{type_id = ItemTypeID, num = ItemNum}|GoodsList],
                    check_lucky_token_pray2(Times2, ConfigList, Level, RemainNum - 1, BigConfig, ConfigIndex, IsBigReward, GoodsList2, [RewardIndexID|RewardIndexList])
            end
    end.

%% 抽到大奖时的处理
check_lucky_token_big(Times2, RemainNum, BigConfig, ConfigIndex, GoodsList, RewardIndexList) ->
    AllConfigList = lib_config:list(cfg_lucky_token),
    #c_lucky_token{index_id = BigIndexID, item_type_id = ItemTypeID, item_num = ItemNum} = BigConfig,
    GoodsList2 = [#p_goods{type_id = ItemTypeID, num = ItemNum}|GoodsList],
    Level2 = world_data:get_world_level(),
    BigIndexID2 = get_big_reward_index(BigIndexID, Level2, ConfigIndex, AllConfigList),
    [BigConfig2] = lib_config:find(cfg_lucky_token, BigIndexID2),
    ConfigList2 = get_normal_config(Level2, ConfigIndex, AllConfigList),
    RemainNum2 = erlang:max(1, RemainNum - 1),
    check_lucky_token_pray2(Times2, ConfigList2, Level2, RemainNum2, BigConfig2, ConfigIndex, true, GoodsList2, [BigIndexID|RewardIndexList]).

%% 获取对应的权重
get_weight_list(RemainNum, AllList) ->
    [ begin
          #c_lucky_token{weight = WeightString} = Config,
          Weight = get_weight_list2(lib_tool:string_to_intlist(WeightString), RemainNum, 0),
          {Weight, Config}
      end|| Config <- AllList].

get_weight_list2([{Weight}], _RemainNum, _WeightAcc) ->
    Weight;
get_weight_list2([], _RemainNum, WeightAcc) ->
    WeightAcc;
get_weight_list2([{NeedNum, Weight}|R], RemainNum, WeightAcc) ->
    case RemainNum < NeedNum of
        true ->
            get_weight_list2(R, RemainNum, Weight);
        _ ->
            WeightAcc
    end.

%% 获取最新的大奖IndexID
get_big_reward_index(IndexID, Level, ConfigIndex) ->
    ConfigList = lib_config:list(cfg_lucky_token),
    get_big_reward_index(IndexID, Level, ConfigIndex, ConfigList).
get_big_reward_index(IndexID, Level, ConfigIndex, ConfigList) ->
    BigRewardList = [ Config || {_Index, #c_lucky_token{reward_type = RewardType, world_level = ConfigLevel, config_index = NeedConfigIndex} = Config} <- ConfigList,
        RewardType =:= ?LUCKY_TOKEN_BIG_REWARD andalso is_fit_level(Level, ConfigLevel), ConfigIndex =:= NeedConfigIndex],
    case BigRewardList =/= [] of
        true ->
            case lists:keymember(IndexID, #c_lucky_token.index_id, BigRewardList) of
                true ->
                    case BigRewardList of
                        [_Config] ->
                            IndexID;
                        _ ->
                            get_big_reward_index2(IndexID, BigRewardList)
                    end;
                _ ->
                    [#c_lucky_token{index_id = NewIndexID}|_] = BigRewardList,
                    NewIndexID
            end;
        _ ->
            ?ERROR_MSG("该等级与套序号未配置大奖 : ~w,~w", [Level, ConfigIndex]),
            0
    end.

get_big_reward_index2(IndexID, [#c_lucky_token{index_id = NowIndexID} = Config1, #c_lucky_token{index_id = NewIndexID} = Config2|R]) ->
    case IndexID =:= NowIndexID of
        true ->
            NewIndexID;
        _ ->
            get_big_reward_index2(IndexID, [Config2|R] ++ [Config1])
    end.

get_normal_config(Level, ConfigIndex, ConfigList) ->
    [ Config || {_Index, #c_lucky_token{reward_type = RewardType, world_level = ConfigLevel, config_index = NeedConfigIndex} = Config} <- ConfigList,
        RewardType =:= ?LUCKY_TOKEN_NORMAL andalso is_fit_level(Level, ConfigLevel), ConfigIndex =:= NeedConfigIndex].

is_fit_level(Level, ConfigLevel) ->
    [MinLevel, MaxLevel] = ConfigLevel,
    MinLevel =< Level andalso Level =< MaxLevel.

get_config_index() ->
    world_cycle_act_server:get_act_config_num(?CYCLE_ACT_LUCKY_TOKEN).