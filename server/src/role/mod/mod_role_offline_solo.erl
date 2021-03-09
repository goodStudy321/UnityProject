%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     离线竞技
%%% @end
%%% Created : 12. 四月 2018 19:44
%%%-------------------------------------------------------------------
-module(mod_role_offline_solo).
-author("laijichang").
-include("role.hrl").
-include("activity.hrl").
-include("offline_solo.hrl").
-include("world_robot.hrl").
-include("proto/mod_role_offline_solo.hrl").
-include("proto/mod_map_actor.hrl").
-include("proto/mod_role_map.hrl").
-include("daily_liveness.hrl").

%% API
-export([
    online/1,
    handle/2
]).

-export([
    solo_info/1,
    solo_result/3,
    solo_result2/3
]).

-export([
    check_enter/1
]).

-export([
    get_challenger_ranks/1,
    get_challengers/1,
    get_challenger_times/1,
    gm_add_times/2
]).

solo_info(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {solo_info, RoleID}}).

solo_result(RoleID, IsWin, DestName) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, ?MODULE, {solo_result, IsWin, DestName});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, solo_result, [RoleID, IsWin, DestName]})
    end.

solo_result2(RoleID, IsWin, DestName) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, ?MODULE, {solo_result2, IsWin, DestName});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, solo_result2, [RoleID, IsWin, DestName]})
    end.

online(State) ->
    #r_role{role_id = RoleID} = State,
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{is_reward = IsReward, challenge_times = ChallengeTimes, buy_times = BuyTimes, bestir_times = BestirTimes}] ->
            DataRecord = #m_offline_solo_detail_toc{
                challenge_times = ChallengeTimes,
                buy_times = BuyTimes,
                is_reward = IsReward,
                bestir_times = BestirTimes};
        _ ->
            DataRecord = #m_offline_solo_detail_toc{
                challenge_times = ?DEFAULT_CHALLENGE_TIMES,
                buy_times = ?DEFAULT_BUY_TIMES,
                is_reward = true,
                bestir_times = 0
            }
    end,
    common_misc:unicast(RoleID, DataRecord),
    State.

check_enter(_State) ->
    case mod_role_dict:get_offline_solo() of
        #r_offline_solo_dict{robot_args = RobotArgs} = OfflineDict when RobotArgs =/= undefined ->
            mod_role_dict:set_offline_solo(OfflineDict#r_offline_solo_dict{robot_args = undefined}),
            OfflineDict;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_019)
    end.

handle({solo_info, RoleID}, State) ->
    do_solo_info(RoleID),
    State;
handle({solo_result, IsWin, DestName}, State) ->
    do_solo_result(IsWin, DestName, State);
handle({solo_result2, IsWin, DestName}, State) ->
    do_solo_result2(IsWin, DestName, State);
handle({#m_offline_solo_panel_tos{type = Type}, RoleID, _PID}, State) ->
    do_solo_panel(RoleID, Type),
    State;
handle({#m_offline_solo_info_tos{}, RoleID, _PID}, State) ->
    do_solo_info(RoleID),
    State;
handle({#m_offline_solo_challenge_tos{rank = Rank}, RoleID, _PID}, State) ->
    do_solo_challenge(RoleID, Rank, State);
handle({#m_offline_solo_mop_tos{rank = Rank}, RoleID, _PID}, State) ->
    do_solo_mop(RoleID, Rank, State);
handle({#m_offline_solo_buy_challenge_tos{buy_times = BuyTimes}, RoleID, _PID}, State) ->
    do_buy_challenge(RoleID, BuyTimes, State);
handle({#m_offline_solo_reward_tos{}, RoleID, _PID}, State) ->
    do_solo_reward(RoleID, State);
handle({#m_offline_solo_bestir_tos{}, RoleID, _PID}, State) ->
    do_solo_bestir(RoleID, State);
handle({#m_offline_solo_quit_tos{}, RoleID, _PID}, State) ->
    do_solo_quit(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("Info : ~w", [Info]),
    State.

do_solo_panel(RoleID, Type) ->
    SoloDict = mod_role_dict:get_offline_solo(),
    IsOpen = ?IF(Type =:= ?OFFLINE_SOLO_PANEL_OPEN, true, false),
    mod_role_dict:set_offline_solo(SoloDict#r_offline_solo_dict{is_panel_open = IsOpen}),
    common_misc:unicast(RoleID, #m_offline_solo_panel_toc{type = Type}).

do_solo_info(RoleID) ->
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{rank = MyRank}] ->
            ok;
        _ ->
            MyRank = 0
    end,
    Ranks = get_challenger_ranks(MyRank),
    SoloDict = mod_role_dict:get_offline_solo(),
    SoloDict2 = SoloDict#r_offline_solo_dict{rank_list = Ranks},
    mod_role_dict:set_offline_solo(SoloDict2),
    DataRecord = #m_offline_solo_info_toc{
        my_rank = MyRank,
        challengers = lists:keysort(#p_challenge.rank, get_challengers(Ranks))},
    common_misc:unicast(RoleID, DataRecord).

do_solo_challenge(RoleID, Rank, State) ->
    case catch check_solo_challenge(RoleID, Rank, State) of
        ok ->
            SoloDict = mod_role_dict:get_offline_solo(),
            case catch world_offline_solo_server:solo_challenge(RoleID, Rank) of
                {ok, BestirTimes, DestRoleID, DestBestirTimes} ->
                    RobotData = get_robot_data(DestRoleID, Rank, State),
                    mod_role_dict:set_offline_solo(SoloDict#r_offline_solo_dict{robot_args = RobotData, my_bestir_times = BestirTimes, dest_bestir_times = DestBestirTimes}),
                    ?TRY_CATCH(mod_role_log_statistics:log_offline_solo(State)),
                    State2 = mod_role_map:do_pre_enter(RoleID, ?MAP_OFFLINE_SOLO, State),
                    mod_role_resource:add_offline_solo_times(State2);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ErrCode}),
                    State
            end;
        {error, ?ERROR_OFFLINE_SOLO_CHALLENGE_001} ->
            common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ?ERROR_OFFLINE_SOLO_CHALLENGE_001}),
            do_solo_info(RoleID),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ErrCode}),
            State
    end.

check_solo_challenge(_RoleID, Rank, State) ->
    #r_offline_solo_dict{rank_list = RankList} = mod_role_dict:get_offline_solo(),
    #r_role{role_map = #r_role_map{map_id = MapID}} = State,
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), ?THROW_ERR(?ERROR_OFFLINE_SOLO_CHALLENGE_003), ok),
    ?IF(lists:member(Rank, RankList), ok, ?THROW_ERR(?ERROR_OFFLINE_SOLO_CHALLENGE_001)).


do_solo_mop(RoleID, Rank, State) ->
    case catch check_solo_mop(RoleID, Rank, State) of
        ok ->
            SoloDict = mod_role_dict:get_offline_solo(),
            case catch world_offline_solo_server:solo_challenge(RoleID, Rank) of
                {ok, BestirTimes, DestRoleID, DestBestirTimes} ->
                    mod_role_dict:set_offline_solo(SoloDict#r_offline_solo_dict{robot_args = undefined, my_bestir_times = BestirTimes, dest_bestir_times = DestBestirTimes}),
                    ?TRY_CATCH(mod_role_log_statistics:log_offline_solo(State)),
                    State2 = mod_role_resource:add_offline_solo_times(State),
                    world_offline_solo_server:solo_result2(RoleID, DestRoleID, true),
                    State2;
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ErrCode}),
                    State
            end;
        {error, ?ERROR_OFFLINE_SOLO_CHALLENGE_001} ->
            common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ?ERROR_OFFLINE_SOLO_CHALLENGE_001}),
            do_solo_info(RoleID),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_offline_solo_challenge_toc{err_code = ErrCode}),
            State
    end.

check_solo_mop(_RoleID, Rank, State) ->
    #r_offline_solo_dict{rank_list = RankList} = mod_role_dict:get_offline_solo(),
    #r_role{role_map = #r_role_map{map_id = MapID}} = State,
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), ?THROW_ERR(?ERROR_OFFLINE_SOLO_MOP_003), ok),
    ?IF(lists:member(Rank, RankList), ok, ?THROW_ERR(?ERROR_OFFLINE_SOLO_MOP_001)).


do_solo_result(IsWin, DestName, State) ->
    #r_role{role_id = RoleID} = State,
    [#r_role_offline_solo{rank = Rank, challenge_times = ChallengeTimes}] = world_offline_solo_server:get_offline_solo(RoleID),
    BaseExp = mod_role_level:get_activity_level_exp(mod_role_data:get_role_level(State)),
    [SuccHonor, FailHonor, SuccExpRate, FailExpRate] = common_misc:get_global_list(?GLOBAL_OFFLINE_SOLO),
    AddExp = lib_tool:ceil(BaseExp * ?IF(IsWin, SuccExpRate, FailExpRate) / ?RATE_10000),
    AddHonor = ?IF(IsWin, SuccHonor, FailHonor),
    AssetDoing = [{add_score, ?ASSET_GLORY_ADD_FROM_OFFLINE_CHALLENGE, ?ASSET_GLORY, AddHonor}],
    DataRecord = #m_offline_solo_challenge_toc{
        is_success = IsWin,
        new_rank = Rank,
        new_challenge_times = ChallengeTimes,
        add_exp = AddExp,
        add_honor = AddHonor,
        dest_name = DestName
    },
    common_misc:unicast(RoleID, DataRecord),
    State2 = mod_role_level:do_add_exp(State, AddExp, ?EXP_ADD_FROM_OFFLINE_SOLO),
    State3= mod_role_asset:do(AssetDoing, State2),
    hook_role:do_solo_trigger(IsWin, Rank, State3).

do_solo_result2(IsWin, DestName, State) ->
    #r_role{role_id = RoleID} = State,
    [#r_role_offline_solo{rank = Rank, challenge_times = ChallengeTimes}] = world_offline_solo_server:get_offline_solo(RoleID),
    BaseExp = mod_role_level:get_activity_level_exp(mod_role_data:get_role_level(State)),
    [SuccHonor, FailHonor, SuccExpRate, FailExpRate] = common_misc:get_global_list(?GLOBAL_OFFLINE_SOLO),
    AddExp = lib_tool:ceil(BaseExp * ?IF(IsWin, SuccExpRate, FailExpRate) / ?RATE_10000),
    AddHonor = ?IF(IsWin, SuccHonor, FailHonor),
    AssetDoing = [{add_score, ?ASSET_GLORY_ADD_FROM_OFFLINE_CHALLENGE, ?ASSET_GLORY, AddHonor}],
    DataRecord = #m_offline_solo_mop_toc{
        is_success = IsWin,
        new_rank = Rank,
        new_challenge_times = ChallengeTimes,
        add_exp = AddExp,
        add_honor = AddHonor,
        dest_name = DestName
    },
    common_misc:unicast(RoleID, DataRecord),
    State2 = mod_role_level:do_add_exp(State, AddExp, ?EXP_ADD_FROM_OFFLINE_SOLO),
    State3= mod_role_asset:do(AssetDoing, State2),
    hook_role:do_solo_trigger(IsWin, Rank, State3).

do_buy_challenge(RoleID, BuyTimes, State) ->
    case catch check_buy_challenge(RoleID, BuyTimes, State) of
        {ok, AssetDoings} ->
            case catch world_offline_solo_server:buy_challenge(RoleID, BuyTimes) of
                {ok, ChallengeTimes2, BuyTimes2} ->
                    common_misc:unicast(RoleID, #m_offline_solo_buy_challenge_toc{new_challenge_times = ChallengeTimes2, new_buy_times = BuyTimes2}),
                    mod_role_asset:do(AssetDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_offline_solo_buy_challenge_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_offline_solo_buy_challenge_toc{err_code = ErrCode}),
            State
    end.

check_buy_challenge(RoleID, BuyTimes, State) ->
    ?IF(BuyTimes > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_id = RoleID} = State,
    [#r_role_offline_solo{buy_times = RoleBuyTimes}] = world_offline_solo_server:get_offline_solo(RoleID),
    ConsumeGold = buy_times(BuyTimes, RoleBuyTimes, 0, 0),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, ConsumeGold, ?ASSET_GOLD_REDUCE_FROM_OFFLINE_SOLO, State),
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_OFFLINE_SOLO_BUY_CHALLENGE_001)
    end,
    {ok, AssetDoings}.

buy_times(0, _RoleBuyTimes, ConsumeGold, _Acc) ->
    ConsumeGold;
buy_times(BuyTimes, RoleBuyTimes, ConsumeGold, Acc) ->
    [{FistBuyGold}, {AddGold}, {LimitGold} | _] = common_misc:get_global_string_list(?GLOBAL_OFFLINE_SOLO),
    Gold = FistBuyGold + AddGold * (RoleBuyTimes + Acc),
    Gold2 = ?IF(Gold > LimitGold, LimitGold, Gold),
    ConsumeGold2 = ConsumeGold + Gold2,
    buy_times(BuyTimes - 1, RoleBuyTimes, ConsumeGold2, Acc + 1).

gm_add_times(Times, #r_role{role_id = RoleID} = State) ->
    {ok, BuyTimes2} = world_offline_solo_server:gm_set_challenge(RoleID, Times),
    common_misc:unicast(RoleID, #m_offline_solo_buy_challenge_toc{new_challenge_times = Times, new_buy_times = BuyTimes2}),
    State.

do_solo_reward(RoleID, State) ->
    case catch check_solo_reward(RoleID) of
        ok ->
            case catch world_offline_solo_server:solo_reward(RoleID) of
                {ok, RewardRank} ->
                    {AddHonor, AssetDoings} = get_rank_reward(RewardRank),
                    common_misc:unicast(RoleID, #m_offline_solo_reward_toc{is_reward = true, add_honor = AddHonor}),
                    mod_role_asset:do(AssetDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_offline_solo_reward_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_offline_solo_reward_toc{err_code = ErrCode}),
            State
    end.

check_solo_reward(RoleID) ->
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{reward_rank = RewardRank}] when RewardRank > 0 ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_OFFLINE_SOLO_REWARD_001)
    end.

do_solo_bestir(RoleID, State) ->
    case catch check_solo_bestir(RoleID, State) of
        {ok, AssetDoings} ->
            case catch world_offline_solo_server:solo_bestir(RoleID) of
                {ok, BestirTimes} ->
                    common_misc:unicast(RoleID, #m_offline_solo_bestir_toc{bestir_times = BestirTimes}),
                    mod_role_asset:do(AssetDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_offline_solo_bestir_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_offline_solo_bestir_toc{err_code = ErrCode}),
            State
    end.

check_solo_bestir(RoleID, State) ->
    Gold = common_misc:get_global_int(?GLOBAL_SOLO_BESTIR_GOLD),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, Gold, ?ASSET_GOLD_REDUCE_FROM_BESTIR, State),
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_OFFLINE_SOLO_BUY_CHALLENGE_001)
    end,
    {ok, AssetDoings}.

do_solo_quit(RoleID, State) ->
    #r_role{role_map = #r_role_map{map_id = MapID}} = State,
    case map_misc:is_copy_offline_solo(MapID) of
        true ->
            copy_offline_solo:solo_quit(mod_role_dict:get_map_pid(), RoleID);
        _ ->
            ok
    end,
    State.

get_challenger_ranks(MyRank) ->
    RankSize = world_offline_solo_server:get_offline_solo_size(),
    if
        MyRank =:= 0 -> %% 没有排名
            get_rank_list(RankSize + 1, RankSize, ?OFFLINE_SOLO_REFRESH_RANGE_2, []);
        MyRank >= RankSize -> %% 最后一名
            get_rank_list(RankSize, RankSize, ?OFFLINE_SOLO_REFRESH_RANGE_2, []);
        MyRank =< ?TEN_RANK -> %% 第一名 - 第十名
            BeforeList = lists:delete(MyRank, lists:seq(1, MyRank)),
            BeforeNum = erlang:length(BeforeList),
            MaxBeforeNum = ?OFFLINE_SOLO_REFRESH_NUM - ?OFFLINE_SOLO_WEAKER_NUM,
            case BeforeNum >= MaxBeforeNum of
                true ->
                    BeforeNum2 = MaxBeforeNum,
                    {ok, FirstList} = lib_tool:random_elements_from_list(MaxBeforeNum, BeforeList);
                _ ->
                    BeforeNum2 = BeforeNum,
                    FirstList = BeforeList
            end,
            {ok, SecondList} = lib_tool:random_elements_from_list(?OFFLINE_SOLO_REFRESH_NUM - BeforeNum2, lists:seq(MyRank + 1, MyRank + ?TEN_RANK)),
            FirstList ++ SecondList;
        MyRank > ?TEN_RANK andalso MyRank =< ?FIFTY_RANK -> %% 11名 - 50名
            get_rank_list(MyRank, RankSize, ?OFFLINE_SOLO_REFRESH_RANGE_3, []);
        true -> %% 其他排名
            get_rank_list(MyRank, RankSize, ?OFFLINE_SOLO_REFRESH_RANGE_1, [])
    end.

get_rank_list(_Rank, _RankSize, [], Acc) ->
    Acc;
get_rank_list(Rank, RankSize, [{MinRate, MaxRate}|R], Acc) ->
    MinRank = lib_tool:ceil(Rank * MinRate),
    MaxRank = lib_tool:ceil(Rank * MaxRate),
    MinRank2 =
    if
        MinRank >= RankSize ->
            ?IF(Rank + 1 > RankSize, RankSize, Rank + 1);
        MinRank =:= Rank ->
            Rank + 1;
        true ->
            MinRank
    end,
    MaxRank2 =
    if
        MaxRank >= RankSize ->
            RankSize;
        MaxRank =:= Rank ->
            Rank - 1;
        true ->
            MaxRank
    end,
    Acc2 = [lib_tool:random(MinRank2, MaxRank2)|Acc],
    get_rank_list(Rank, RankSize, R, Acc2).

get_challengers(RankList) ->
    [begin
         [#r_role_offline_solo{role_id = RoleID}] = world_offline_solo_server:get_offline_solo_by_rank(Rank),
         world_offline_solo_server:get_challenge(RoleID, Rank)
     end || Rank <- RankList].

get_rank_reward(RewardRank) ->
    List = cfg_offline_solo_reward:list(),
    get_rank_reward2(RewardRank, List).

get_rank_reward2(RewardRank, []) ->
    ?ERROR_MSG("找不到对应排名的配置 : ~w", [RewardRank]),
    {0, []};
get_rank_reward2(RewardRank, [{_, Config}|R]) ->
    #c_offline_solo_reward{
        min_rank = MinRank,
        max_rank = MaxRank,
        add_honor = AddHonor,
        add_silver = AddSilver} = Config,
    case MinRank =< RewardRank andalso RewardRank =< MaxRank of
        true ->
            {AddHonor, [{add_score, ?ASSET_GLORY_ADD_FROM_OFFLINE_SOLO, ?ASSET_GLORY, AddHonor}, {add_silver, ?ASSET_SILVER_ADD_FROM_OFFLINE_SOLO, AddSilver}]};
        _ ->
            get_rank_reward2(RewardRank, R)
    end.

get_challenger_times(RoleID) ->
    case world_offline_solo_server:get_offline_solo(RoleID) of
        [#r_role_offline_solo{challenge_times = Times}] ->
            Times;
        _ ->
            ?DEFAULT_CHALLENGE_TIMES
    end.

get_robot_data(RoleID, Rank, State) ->
    case RoleID =< ?OFFLINE_SOLO_MAX_ROBOT_NUM of
        true ->
            SkinList = [3040205, 3050000, 30200000, 3030101],
            [#r_robot_offline_solo{
                name = Name,
                sex = Sex,
                category = Category,
                level = Level,
                power = Power
            }] = world_offline_solo_server:get_robot_solo(RoleID),
            #c_robot_offline_solo{prop_range = [MinPropRate, MaxPropRate]} = world_offline_solo_server:get_robot_config(Rank, lib_config:list(cfg_robot_offline_solo)),
            Rate = lib_tool:random(MinPropRate, MaxPropRate) * ?RATE_100,
            FightAttr = State#r_role.role_fight#r_role_fight.fight_attr,
            BaseAttr = common_misc:fight_attr_rate(FightAttr, Rate),
            #r_robot{
                robot_id = RoleID,
                robot_name = Name,
                sex = Sex,
                category = Category,
                level = Level,
                skin_list = SkinList,
                power = Power,
                skill_list = copy_wave:get_robot_skill(Category),
                base_attr = BaseAttr
            };
        _ ->
            Robot = world_robot_server:get_robot_by_role_id(RoleID),
            Robot#r_robot{robot_id = RoleID}
    end.