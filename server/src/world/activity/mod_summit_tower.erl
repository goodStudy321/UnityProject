%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2018 10:36
%%%-------------------------------------------------------------------
-module(mod_summit_tower).
-author("laijichang").
-include("activity.hrl").
-include("summit_tower.hrl").
-include("global.hrl").
-include("proto/mod_role_summit_tower.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    i/0,
    init/0,
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    handle/1
]).

%% 地图调用
-export([
    role_enter_map/3,
    role_leave_map/3,
    add_score/3
]).

%% 角色调用
-export([
    role_pre_enter/1,
    role_get_summit_tower/1
]).

-export([
    is_activity_open/0,
    get_activity/0,
    get_tower_list/0,
    get_role_summit/1
]).

i() ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, i).

init() ->
    lib_tool:init_ets(?ETS_ROLE_SUMMIT, #r_role_summit.role_id),
    ok.

activity_prepare() ->
    cancel_time_ref(),
    close_all_maps(),
    ets:delete_all_objects(?ETS_ROLE_SUMMIT),
    erase_all_ctrl(),
    set_ranks([]).

activity_start() ->
    [ start_map(MapID, 1)|| MapID <- get_tower_list()].

activity_end() ->
    Ranks = get_ranks(),
    PassRoles = [ RoleID || #r_role_summit{role_id = RoleID, is_end = IsEnd} <- get_all_role_summit(), IsEnd],
    LastTime = get_activity_last_time(),
    DataRecord = #m_summit_tower_rank_toc{ranks = Ranks, use_time = LastTime},
    [begin
         [mod_map_summit_tower:activity_end(MapID, ExtraID, PassRoles, DataRecord) || #r_summit_extra{extra_id = ExtraID} <- SummitList]
     end || #r_summit_ctrl{map_id = MapID, summit_extra_list = SummitList} <- get_all_ctrl()],
    Mod = get_activity_mod(),
    TimeRef = Mod:info_mod_by_time(?ONE_MINUTE * 1000, ?MODULE, close_all_maps),
    cancel_time_ref(),
    set_time_ref(TimeRef),
    do_rank_reward(Ranks).


handle(Info) ->
    do_handle(Info).

role_enter_map(RoleID, MapID, ExtraID) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {role_enter_map, RoleID, MapID, ExtraID}).

role_leave_map(RoleID, MapID, ExtraID) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {role_leave_map, RoleID, MapID, ExtraID}).

add_score(MapID, RoleID, AddScore) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {add_score, MapID, RoleID, AddScore}).

role_pre_enter(RoleID) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_pre_enter, RoleID}).

role_get_summit_tower(RoleID) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_get_summit_tower, RoleID}).

start_map(MapID, ExtraID) ->
    ServerID = common_config:get_server_id(),
    {ok, _MapPID} = map_sup:start_map(MapID, ExtraID, ServerID),
    #r_summit_ctrl{summit_extra_list = SummitList} = SummitCtrl = get_summit_ctrl(MapID),
    SummitExtra = #r_summit_extra{extra_id = ExtraID, num = 0},
    SummitCtrl2 = SummitCtrl#r_summit_ctrl{cur_extra_id = ExtraID, summit_extra_list = [SummitExtra|SummitList]},
    set_summit_ctrl(MapID, SummitCtrl2).

close_all_maps() ->
    [begin
         [pname_server:send(map_misc:get_map_pname(MapID, ExtraID), {map_shutdwon, shutdown}) || #r_summit_extra{extra_id = ExtraID} <- SummitList],
         set_summit_ctrl(MapID, SummitCtrl#r_summit_ctrl{cur_extra_id = 0, summit_extra_list = []})
     end || #r_summit_ctrl{map_id = MapID, summit_extra_list = SummitList} = SummitCtrl <- get_all_ctrl()].

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle(i) ->
    do_i();
do_handle(close_all_maps) ->
    close_all_maps();
do_handle({role_enter_map, RoleID, MapID, ExtraID}) ->
    do_role_enter_map(RoleID, MapID, ExtraID);
do_handle({role_leave_map, RoleID, MapID, ExtraID}) ->
    do_role_leave_map(RoleID, MapID, ExtraID);
do_handle({add_score, MapID, RoleID, AddScore}) ->
    ?IF(is_activity_open(), do_add_score(MapID, RoleID, AddScore), ok);
do_handle({role_pre_enter, RoleID}) ->
    do_role_pre_enter(RoleID);
do_handle({role_get_summit_tower, RoleID}) ->
    get_role_summit(RoleID);
do_handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).

do_i() ->
    {get_ranks(), get_all_ctrl()}.

do_role_enter_map(RoleID, _MapID, _ExtraID) ->
    [#r_role_summit{score = Score}] = get_role_summit(RoleID),
    Ranks = get_ranks(),
    case lists:keyfind(RoleID, #p_summit_tower_rank.role_id, Ranks) of
        #p_summit_tower_rank{rank = Rank} ->
            ok;
        _ ->
            Rank = 0
    end,
    common_misc:unicast(RoleID, #m_summit_tower_info_toc{score = Score, rank = Rank}).


do_role_leave_map(RoleID, MapID, ExtraID) ->
    #r_summit_ctrl{summit_extra_list = SummitList} = SummitCtrl = get_summit_ctrl(MapID),
    #r_summit_extra{num = OldNum} = SummitExtra = lists:keyfind(ExtraID, #r_summit_extra.extra_id, SummitList),
    SummitExtra2 = SummitExtra#r_summit_extra{num = OldNum - 1},
    SummitList2 = lists:keyreplace(ExtraID, #r_summit_extra.extra_id, SummitList, SummitExtra2),
    SummitCtrl2 = SummitCtrl#r_summit_ctrl{summit_extra_list = SummitList2},
    set_summit_ctrl(MapID, SummitCtrl2),
    [RoleSummit] = get_role_summit(RoleID),
    set_role_summit(RoleSummit#r_role_summit{extra_id = 0}).

do_add_score(FromMapID, RoleID, AddScore) ->
    [#r_role_summit{map_id = MapID, score = Score} = RoleSummit] = get_role_summit(RoleID),
    case FromMapID =:= MapID of
        true ->
            [#c_summit_tower{need_score = NeedScore, exp_rate = ExpRate, add_item = AddItem}] = lib_config:find(cfg_summit_tower, MapID),
            Score2 = erlang:min(Score + AddScore, NeedScore),
            RoleSummit2 = RoleSummit#r_role_summit{score = Score2},
            ScoreUpdate = #p_kv{id = ?SUMMIT_TOWER_SCORE, val = Score2},
            common_misc:unicast(RoleID, #m_summit_tower_update_toc{update = ScoreUpdate}),
            case Score2 >= NeedScore of
                true -> %% 可以给奖励了
                    GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_item_reward(AddItem)],
                    role_misc:give_goods(RoleID, ?ITEM_GAIN_SUMMIT_TOWER_REWARD, GoodsList),
                    mod_role_level:add_level_exp(RoleID, ExpRate, ?EXP_ADD_FROM_SUMMIT_TOWER),
                    case MapID =:= ?MAP_LAST_SUMMIT_TOWER of
                        true ->
                            mod_role_summit_tower:summit_tower_finish(RoleID),
                            RoleSummit3 = RoleSummit2#r_role_summit{is_end = true};
                        _ ->
                            MapID2 = MapID + 1,
                            mod_role_summit_tower:next_summit_tower(RoleID, MapID2),
                            RoleSummit3 = RoleSummit2#r_role_summit{map_id = MapID2, extra_id = 0, score = 0}
                    end,
                    set_role_summit(RoleSummit3);
                _ ->
                    RoleSummit3 = RoleSummit2,
                    set_role_summit(RoleSummit2)
            end,
            do_update_rank(RoleSummit3);
        _ ->
            ok
    end.

%% 这里可能会更新RoleSummit
do_update_rank(RoleSummit) ->
    #r_role_summit{role_id = RoleID, score = Score, map_id = MapID, is_end = IsEnd, is_rank_reward = IsRankReward} = RoleSummit,
    UseTime =
        case IsEnd of
            true ->
                #r_activity{start_time = StartTime} = get_activity(),
                time_tool:now() - StartTime;
            _ ->
                get_activity_last_time()
        end,
    Rank = #p_summit_tower_rank{
        role_id = RoleID,
        floor = ?GET_SUMMIT_TOWER_FLOOR(MapID),
        score = Score,
        use_time = UseTime},
    Ranks = get_ranks(),
    RanksT = lists:keysort(#p_summit_tower_rank.role_id, lists:keystore(RoleID, #p_summit_tower_rank.role_id, Ranks, Rank)),
    Ranks2 = lists:sort(fun(Rank1, Rank2) -> cmp_rank(Rank1, Rank2) end,  RanksT),
    Ranks3 = lists:sublist(Ranks2, ?SUMMIT_TOWER_RANK_NUM),
    {_AllNum, Ranks4} =
        lists:foldl(
            fun(#p_summit_tower_rank{role_id = SortRoleID} = SortRank, {NumAcc, Acc}) ->
                Acc2 = [SortRank#p_summit_tower_rank{rank = NumAcc, role_name = common_role_data:get_role_name(SortRoleID)}|Acc],
                {NumAcc + 1, Acc2}
            end, {1, []}, Ranks3),
    Ranks5 = lists:reverse(Ranks4),
    set_ranks(Ranks5),
    ?IF(IsEnd, common_misc:unicast(RoleID, #m_summit_tower_rank_toc{ranks = Ranks4, use_time = UseTime}), ok),
    ?IF(IsEnd andalso not IsRankReward, do_role_rank_reward(RoleSummit, Ranks4), ok),
    RankUpdateList = get_update_roles(Ranks, Ranks5, []),
    [ begin
          case lists:keyfind(UpdateRoleID, #p_summit_tower_rank.role_id, Ranks5) of
              #p_summit_tower_rank{rank = UpdateRank} ->
                  ok;
              _ ->
                  UpdateRank = 0
          end,
          common_misc:unicast(UpdateRoleID, #m_summit_tower_update_toc{update = #p_kv{id = ?SUMMIT_TOWER_RANK, val = UpdateRank}})
      end|| UpdateRoleID <- lib_tool:list_filter_repeat(RankUpdateList)].

get_update_roles([], [], Acc) ->
    Acc;
get_update_roles([], Ranks, Acc) ->
    [ RoleID|| #p_summit_tower_rank{role_id = RoleID} <- Ranks] ++ Acc;
get_update_roles([Rank1|R1], [Rank2|R2], Acc) ->
    #p_summit_tower_rank{role_id = RoleID1} = Rank1,
    #p_summit_tower_rank{role_id = RoleID2} = Rank2,
    case RoleID1 =:= RoleID2 of
        true ->
            Acc2 = Acc;
        _ ->
            Acc2 = [RoleID1, RoleID2] ++ Acc
    end,
    get_update_roles(R1, R2, Acc2).

cmp_rank(Rank1, Rank2) ->
    #p_summit_tower_rank{floor = Floor1, score = Score1, use_time = UseTime1} = Rank1,
    #p_summit_tower_rank{floor = Floor2, score = Score2, use_time = UseTime2} = Rank2,
    case Floor1 =:= Floor2 of
        true ->
            case Score1 =:= Score2 of
                true ->
                    UseTime2 =:= 0 orelse (UseTime1 =/= 0 andalso UseTime1 < UseTime2);
                _ ->
                    Score1 > Score2
            end;
        _ ->
            Floor1 > Floor2
    end.

do_rank_reward(Ranks) ->
    [ begin
          [RoleSummit] = get_role_summit(RoleID),
          do_role_rank_reward2(RoleSummit, Rank)
      end || #p_summit_tower_rank{role_id = RoleID, rank = Rank} <- Ranks].

do_role_rank_reward(RoleSummit, Ranks) ->
    #r_role_summit{role_id = RoleID} = RoleSummit,
    case lists:keyfind(RoleID, #p_summit_tower_rank.role_id, Ranks) of
        #p_summit_tower_rank{rank = Rank} ->
            do_role_rank_reward2(RoleSummit, Rank);
        _ ->
            ok
    end.

do_role_rank_reward2(RoleSummit, Rank) ->
    #r_role_summit{role_id = RoleID, is_rank_reward = IsRankReward, is_end = IsEnd} = RoleSummit,
    case not IsRankReward andalso IsEnd andalso lib_config:find(cfg_summit_tower_rank, Rank) of
        [#c_summit_tower_rank{add_item = AddItem}] ->
            GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_item_reward(AddItem)],
            role_misc:give_goods(RoleID, ?ITEM_GAIN_SUMMIT_TOWER_RANK, GoodsList),
            set_role_summit(RoleSummit#r_role_summit{is_rank_reward = true});
        _ ->
            ok
    end.

do_role_pre_enter(RoleID) ->
    case catch check_role_pre_enter(RoleID) of
        {ok, MapID, ExtraID} ->
            {ok, MapID, ExtraID, common_config:get_server_id()};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_role_pre_enter(RoleID) ->
    case get_role_summit(RoleID) of
        [#r_role_summit{map_id = MapID, is_end = IsEnd, extra_id = ExtraID} = RoleSummit] ->
            ?IF(IsEnd, ?THROW_ERR(?ERROR_PRE_ENTER_023), ok),
            case ExtraID > 0 of
                true ->
                    {ok, MapID, ExtraID};
                _ ->
                    {ok, ExtraID2} = check_role_pre_enter2(RoleSummit),
                    {ok, MapID, ExtraID2}
            end;
        _ ->
            MapID = ?MAP_FIRST_SUMMIT_TOWER,
            RoleSummit = #r_role_summit{role_id = RoleID, map_id = MapID, score = 0},
            {ok, ExtraID} = check_role_pre_enter2(RoleSummit),
            {ok, MapID, ExtraID}
    end.

check_role_pre_enter2(RoleSummit) ->
    #r_role_summit{map_id = MapID} = RoleSummit,
    #r_summit_ctrl{cur_extra_id = CurExtraID, summit_extra_list = SummitList} = SummitCtrl = get_summit_ctrl(MapID),
    RoleSummit2 = RoleSummit#r_role_summit{extra_id = CurExtraID},
    #r_summit_extra{num = OldNum} = SummitExtra = lists:keyfind(CurExtraID, #r_summit_extra.extra_id, SummitList),
    Num = OldNum + 1,
    SummitExtra2 = SummitExtra#r_summit_extra{num = Num},
    SummitList2 = lists:keyreplace(CurExtraID, #r_summit_extra.extra_id, SummitList, SummitExtra2),
    SummitCtrl2 = SummitCtrl#r_summit_ctrl{summit_extra_list = SummitList2},
    set_role_summit(RoleSummit2),
    set_summit_ctrl(MapID, SummitCtrl2),
    ?IF(Num >= ?NORMAL_SUMMIT_MAX_NUM, do_change_normal_extra(SummitCtrl2), ok),
    {ok, CurExtraID}.

%% 普通层数改变extra_id
do_change_normal_extra(SummitCtrl) ->
    #r_summit_ctrl{map_id = MapID, summit_extra_list = SummitList} = SummitCtrl,
    [#r_summit_extra{extra_id = ExtraID, num = NowNum}|_] = lists:keysort(#r_summit_extra.num, SummitList),
    case NowNum >= ?NORMAL_SUMMIT_MAX_NUM of
        true ->
            NewExtraID = lists:max([ ID|| #r_summit_extra{extra_id = ID} <- SummitList]) + 1,
            start_map(MapID, NewExtraID);
        _ ->
            SummitCtrl2 = SummitCtrl#r_summit_ctrl{cur_extra_id = ExtraID},
            set_summit_ctrl(MapID, SummitCtrl2)
    end.
%%%===================================================================
%%% dict
%%%===================================================================
is_activity_open() ->
    #r_activity{status = Status} = get_activity(),
    Status =:= ?STATUS_OPEN.

get_activity_last_time() ->
    [#c_activity{last_time = LastTime}] = lib_config:find(cfg_activity, ?ACTIVITY_SUMMIT_TOWER),
    LastTime.

get_activity_mod() ->
    activity_misc:get_activity_mod(?ACTIVITY_SUMMIT_TOWER).

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_SUMMIT_TOWER).

get_tower_list() ->
    lists:seq(?MAP_FIRST_SUMMIT_TOWER, ?MAP_LAST_SUMMIT_TOWER).

get_summit_ctrl(MapID) ->
    case erlang:get({?MODULE, summit_ctrl, MapID}) of
        #r_summit_ctrl{} = SummitCtrl ->
            SummitCtrl;
        _ ->
            #r_summit_ctrl{map_id = MapID}
    end.
set_summit_ctrl(MapID, SummitCtrl) ->
    erlang:put({?MODULE, summit_ctrl, MapID}, SummitCtrl).
erase_all_ctrl() ->
    [ erlang:erase({?MODULE, summit_ctrl, MapID}) || MapID <- get_tower_list()].
get_all_ctrl() ->
    [ get_summit_ctrl(MapID) || MapID <- get_tower_list()].

get_role_summit(RoleID) ->
    ets:lookup(?ETS_ROLE_SUMMIT, RoleID).
set_role_summit(RoleSummit) ->
    ets:insert(?ETS_ROLE_SUMMIT, RoleSummit).
get_all_role_summit() ->
    ets:tab2list(?ETS_ROLE_SUMMIT).

set_ranks(List) ->
    erlang:put({?MODULE, ranks}, List).
get_ranks() ->
    erlang:get({?MODULE, ranks}).

cancel_time_ref() ->
    case erlang:erase({?MODULE, time_ref}) of
        TimeRef when erlang:is_reference(TimeRef) ->
            erlang:cancel_timer(TimeRef);
        _ ->
            ok
    end.
set_time_ref(TimeRef) ->
    erlang:put({?MODULE, time_ref}, TimeRef).
