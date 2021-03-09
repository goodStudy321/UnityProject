%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 三月 2018 15:05
%%%-------------------------------------------------------------------
-module(mod_role_solo).
-author("laijichang").
-include("role.hrl").
-include("activity.hrl").
-include("solo.hrl").
-include("proto/mod_role_solo.hrl").
-include("proto/mod_solo.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    online/1,
    offline/1,
    handle/2,
    level_up/1
]).

-export([
    check_role_pre_enter/2,
    is_solo_able/1
]).

-export([
    solo_end_reward/4
]).

online(State) ->
    RoleID = State#r_role.role_id,
    {#r_role_solo{
        score = Score,
        enter_times = EnterTimes,
        enter_reward_list = EnterRewardList,
        is_matching = IsMatching,
        step_reward_list = StepRewardList,
        season_win_times = SeasonWinTimes,
        season_enter_times = SeasonEnterTimes,
        exp = Exp}, {StartTime, StopTime, Season}} = mod_solo:call_role_online_solo_info(RoleID),

    DataRecord = #m_solo_role_info_toc{
        score = Score,
        step_reward_list = StepRewardList,
        season_win_times = SeasonWinTimes,
        season_enter_times = SeasonEnterTimes,
        enter_times = EnterTimes,
        enter_reward_list = EnterRewardList,
        exp = Exp,
        is_matching = IsMatching,
        stop_time = StopTime,
        season = Season, start_time = StartTime},
    common_misc:unicast(RoleID, DataRecord),
    State.

offline(State) ->
    RoleID = State#r_role.role_id,

    mod_solo:send_role_offline(RoleID),
    State.

level_up(State) ->
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_SOLO),
    Level = mod_role_data:get_role_level(State),
    case Level >= MinLevel of
        true ->
            #r_role{role_attr = #r_role_attr{role_id = RoleID}} = State,
            mod_solo:send_role_add_rank(RoleID);
        _ ->
            ok
    end.

%% @doc 地图预进
check_role_pre_enter(RoleID, MapID) ->
    case mod_solo:call_role_pre_enter(RoleID) of
        {ok, ServerID, ExtraID, CampID, RecordPos} ->
            {MapID, ExtraID, ServerID, CampID, RecordPos};
        ErrCode ->
            ?THROW_ERR(ErrCode)
    end.

is_solo_able(State) ->
    #r_role{role_id = RoleID} = State,
    mod_solo:call_role_get_is_fighting(RoleID).

solo_end_reward(RoleID, AddExp, AddHonor, GoodsList) ->
    case common_config:is_cross_node() of
        true -> %% 跨服进程调用
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, solo_end_reward, [RoleID, AddExp, AddHonor, GoodsList]});
        _ ->
            case role_misc:is_online(RoleID) of
                true ->
                    role_misc:info_role(RoleID, {mod, ?MODULE, {solo_end_reward, AddExp, AddHonor, GoodsList}});
                _ ->
                    world_offline_event_server:add_event(RoleID, {?MODULE, solo_end_reward, [RoleID, AddExp, AddHonor, GoodsList]})
            end
    end.

handle(activity_start, State) ->
    online(State);
handle({#m_solo_step_reward_tos{step = Step}, RoleID, _PID}, State) ->
    do_step_reward(RoleID, Step, State);
handle({#m_solo_enter_reward_tos{type = Type}, RoleID, _PID}, State) ->
    do_enter_reward(RoleID, Type, State);
handle({#m_solo_rank_info_tos{}, RoleID, _PID}, State) ->
    do_solo_rank(RoleID, State);
handle({#m_solo_match_tos{type = Type}, RoleID, _PID}, State) ->
    do_solo_match(RoleID, Type, State);
handle({solo_end_reward, AddExp, AddHonor, GoodsList}, State) ->
    do_solo_end_reward(AddExp, AddHonor, GoodsList, State);
handle(Info, State) ->
    ?ERROR_MSG("Info : ~w", [Info]),
    State.

%% @doc 段位奖励领取
do_step_reward(RoleID, Step, State) ->
    case mod_solo:call_role_step_reward(RoleID, Step) of
        {ok, AddHonor, RewardString} ->
            Doings = [{add_score, ?ASSET_GLORY_ADD_FROM_SOLO_DAILY_REWARD, ?ASSET_GLORY, AddHonor}],
            State2 = mod_role_asset:do(Doings, State),
            RewardGoods = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_item_reward(RewardString)],
            BagDoings = [{create, ?ITEM_GAIN_SOLO_STEP_REWARD, RewardGoods}],
            common_misc:unicast(RoleID, #m_solo_step_reward_toc{step = Step}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_solo_step_reward_toc{err_code = ErrCode}),
            State
    end.

%% @doc 进入次数奖励
do_enter_reward(RoleID, Type, State) ->
    case mod_solo:call_role_enter_reward(RoleID, Type) of
        {ok, GoodsList, EnterList} ->
            common_misc:unicast(RoleID, #m_solo_enter_reward_toc{type = Type, enter_list = EnterList}),
            role_misc:create_goods(State, ?ITEM_GAIN_SOLO_ENTER_REWARD, GoodsList);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_solo_enter_reward_toc{err_code = ErrCode}),
            State
    end.

%% @doc 匹配
do_solo_match(RoleID, Type, State) ->
    case catch check_solo_match(State) of
        ok ->
            mod_solo:send_solo_match(RoleID, Type),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_solo_match_toc{err_code = ErrCode}),
            State
    end.

check_solo_match(State) ->
    MapID = mod_role_data:get_role_map_id(State),
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), ?THROW_ERR(?ERROR_SOLO_MATCH_003), ok),
    activity_misc:check_role_level(?ACTIVITY_SOLO, State#r_role.role_id),
    ok.

%% @doc 排行
do_solo_rank(RoleID, State) ->
    #r_role{role_attr = #r_role_attr{role_name = RoleName, power = Power}} = State,
    Return = mod_solo:call_role_solo_rank_info(RoleID, RoleName, Power),
    ?LXG(Return),
    {ok, MyRank, Ranks} = Return,
    common_misc:unicast(RoleID, #m_solo_rank_info_toc{ranks = Ranks, my_rank = MyRank}),
    State.
%% @doc 奖励和经验
do_solo_end_reward(AddExp, AddHonor, GoodsList, State) ->
    {#r_role_solo{combo_win = ComboWin}, _} = mod_solo:call_role_online_solo_info(State#r_role.role_id),
    Doings = [{add_score, ?ASSET_GLORY_ADD_FROM_SOLO_END, ?ASSET_GLORY, AddHonor}],
    State2 = mod_role_asset:do(Doings, State),
    State3 = ?IF(ComboWin > 0, mod_role_achievement:solo_combo_win(ComboWin, State2), State2),
    State4 = mod_role_level:do_add_exp(State3, AddExp, ?EXP_ADD_FROM_OFFLINE_SOLO),
    role_misc:create_goods(State4, ?ITEM_GAIN_SOLO_END, GoodsList).