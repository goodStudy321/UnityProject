%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 十月 2018 10:35
%%%-------------------------------------------------------------------
-module(robot_ai_mission).
-author("laijichang").
-include("global.hrl").
-include("mission.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_mission.hrl").
-include("proto/mod_role_gm.hrl").
-include("proto/copy_single.hrl").
-include("proto/mod_map_collection.hrl").

-define(ROBOT_MISSION_ENTER_MAP, 1).    %% 进入地图
-define(ROBOT_MISSION_MOVE, 2).         %% 移动
-define(ROBOT_MISSION_FIGHT, 3).        %% 战斗
-define(ROBOT_MISSION_TRIGGER, 4).      %% 完成任务
-define(ROBOT_MISSION_COLLECT, 5).      %% 采集

-define(ROBOT_MISSION_ACCEPT, 99).      %% 接受任务
-define(ROBOT_MISSION_COMPLETE, 100).   %% 完成任务

-define(ROBOT_MISSION_LEVEL_UP, 200).   %% 等级不足，升级

%% API
-export([
    mission_do/0
]).

-export([
    accept_mission/1,
    complete_mission/1,
    update_mission/2,
    listen_update/2
]).

mission_do() ->
    case catch get_mission_do() of
        {?ROBOT_MISSION_ENTER_MAP, MapID} ->
            robot_client:send_data(#m_pre_enter_tos{map_id = MapID}),
            true;
        {?ROBOT_MISSION_MOVE, Mx, My} ->
            robot_ai_move:mission_move(Mx, My),
            true;
        ?ROBOT_MISSION_FIGHT ->
            false;
        {?ROBOT_MISSION_TRIGGER, Type, Value} ->
            robot_client:send_data(#m_mission_trigger_tos{type = Type, val = Value}),
            true;
        {?ROBOT_MISSION_COLLECT, CollectID} ->
            robot_client:send_data(#m_collect_start_tos{collect_id = CollectID}),
            true;
        {?ROBOT_MISSION_ACCEPT, MissionID} ->
            robot_client:send_data(#m_mission_accept_tos{mission_id = MissionID}),
            true;
        {?ROBOT_MISSION_COMPLETE, MissionID} ->
            robot_client:send_data(#m_mission_complete_tos{mission_id = MissionID}),
            true;
        {?ROBOT_MISSION_LEVEL_UP, NewLevel} ->
            robot_client:send_data(#m_role_gm_tos{type = "role_set_level", args = lib_tool:to_list(NewLevel)}),
            true;
        false ->
            false;
        Error ->
            ?ERROR_MSG("unknow return : ~w", [Error]),
            false
    end.

get_mission_do() ->
    Mission = get_main_mission(),
    ?INFO_MSG("Mission:~w", [Mission]),
    case Mission of
        #p_mission{mission_id = MissionID, status = ?MISSION_STATUS_ACCEPT} ->
            do_accept_mission(MissionID);
        #p_mission{mission_id = MissionID, status = ?MISSION_STATUS_DOING} ->
            do_doing_mission(MissionID);
        #p_mission{mission_id = MissionID, status = ?MISSION_STATUS_REWARD} ->
            {?ROBOT_MISSION_COMPLETE, MissionID};
        _ ->
            false
    end.

%% 接受任务
do_accept_mission(MissionID) ->
    [#c_mission_excel{min_level = MinLevel}] = lib_config:find(cfg_mission_excel, MissionID),
    case robot_data:get_level() >= MinLevel of
        true ->
            erlang:throw({?ROBOT_MISSION_ACCEPT, MissionID});
        _ ->
            erlang:throw({?ROBOT_MISSION_LEVEL_UP, MinLevel})
    end.

%% 做任务
do_doing_mission(MissionID) ->
    [Config] = lib_config:find(cfg_mission_excel, MissionID),
    #c_mission_excel{listener_type = ListenerType, listener_value = Value} = Config,
    Value2 = lists:flatten([[ lib_tool:to_integer(Item) || Item <- string:tokens(String, ",")]|| String <- string:tokens(Value, "|")]),
    if
        ListenerType =:= ?MISSION_KILL_MONSTER ->
            do_kill_monster(MissionID, Value2);
        ListenerType =:= ?MISSION_SPEAK ->
            do_speak(Value2);
        ListenerType =:= ?MISSION_COLLECT ->
            do_collect(Value2);
        ListenerType =:= ?MISSION_MOVE ->
            do_move(Value2);
        ListenerType =:= ?MISSION_RATE ->
            [TypeID, MapID, NeedValue|_] = Value2,
            Value3 = [TypeID, MapID, NeedValue],
            do_kill_monster(MissionID, Value3);
        ListenerType =:= ?MISSION_FRONT ->
            do_front(Value2);
        true ->
            false
    end.

%% 准备
do_kill_monster(MissionID, Value) ->
    case Value of
        [TypeID, MapID, _Num] ->
            check_map_id(MapID),
            #r_pos{mx = Mx, my = My} = get_monster_pos(MapID, TypeID),
            check_pos(Mx, My),
            ?ROBOT_MISSION_FIGHT;
        [TypeID, MapID, Num, Mx, My] ->
            Pos = map_misc:get_pos_by_map_offset_pos(MapID, Mx, My),
            do_kill_monster2(MissionID, MapID, Pos, [{TypeID, Num}]);
        [TypeID, MapID, Num, TypeID2, _MapID, Num2] ->
            Pos = robot_data:get_now_pos(),
            do_kill_monster2(MissionID, MapID, map_misc:pos_decode(Pos), [{TypeID, Num}, {TypeID2, Num2}]);
        [TypeID, MapID, Num, TypeID2, _MapID, Num2, TypeID3, _MapID, Num3] ->
            Pos = robot_data:get_now_pos(),
            do_kill_monster2(MissionID, MapID, map_misc:pos_decode(Pos), [{TypeID, Num}, {TypeID2, Num2}, {TypeID3, Num3}])
    end.

do_kill_monster2(MissionID, MapID, RecordPos, SummonList) ->
    check_map_id(MapID),
    case map_misc:is_copy_front(MapID) andalso get_summon_flag(MissionID) =:= undefined of
        true ->
            ?INFO_MSG("summon:~w", [SummonList]),
            [
                [
                    begin
                        Summon = #p_single_summon{actor_id = TypeID * 100 + Index, type_id = TypeID, pos = map_misc:pos_encode(RecordPos)},
                        DataRecord = #m_single_summon_tos{monster = Summon},
                        robot_client:send_data(DataRecord)
                    end || Index <- lists:seq(1, Num)
                ]
                || {TypeID, Num} <- SummonList],
            set_summon_flag(MissionID);
        _ ->
            ok
    end,
    check_pos_by_record(RecordPos, 300),
    false.

%% 进流程树
do_front(Value) ->
    [FrontID, MapID|_] = Value,
    check_map_id(MapID),
    erlang:throw({?ROBOT_MISSION_TRIGGER, ?MISSION_FRONT, FrontID}).

do_speak(Value) ->
    [NpcID, MapID|_] = Value,
    check_map_id(MapID),
    [[Mx, _, My]] = lib_config:find(cfg_npc, NpcID),
    #r_pos{mx = Mx2, my = My2} = map_misc:get_pos_by_map_offset_pos(MapID, Mx, My),
    check_pos(Mx2, My2, 200),
    erlang:throw({?ROBOT_MISSION_TRIGGER, ?MISSION_SPEAK, NpcID}).

do_collect(Value) ->
    [TypeID, MapID|_] = Value,
    check_map_id(MapID),
    check_pos_by_record(get_collection_pos(MapID, TypeID), 200),
    CollectID = get_around_collect_id(TypeID),
    erlang:throw({?ROBOT_MISSION_COLLECT, CollectID}).

do_move(Value) ->
    [Mx, My, MapID] = Value,
    check_map_id(MapID),
    check_pos_by_record(map_misc:get_pos_by_map_offset_pos(MapID, Mx, My), 200),
    erlang:throw({?ROBOT_MISSION_TRIGGER, ?MISSION_MOVE, erlang:abs(Mx)}).

check_map_id(MapID) ->
    ?IF(robot_data:get_map_id() =:= MapID, ok, erlang:throw({?ROBOT_MISSION_ENTER_MAP, MapID})).

check_pos_by_record(Pos, Dis) ->
    #r_pos{mx = Mx, my = My} = Pos,
    check_pos(Mx, My, Dis).

check_pos(Mx, My) ->
    check_pos(Mx, My, 500).
check_pos(Mx, My, Dis) ->
    IntPos = robot_data:get_now_pos(),
    #r_pos{mx = NowMx, my = NowMy} = map_misc:pos_decode(IntPos),
    case map_misc:get_dis(NowMx, NowMy, Mx, My) =< Dis of
        true ->
            ok;
        _ ->
            erlang:throw({?ROBOT_MISSION_MOVE, Mx, My})
    end.

get_main_mission() ->
    Missions = robot_data:get_missions(),
    get_main_mission2(Missions).

get_main_mission2([]) ->
    erlang:throw(false);
get_main_mission2([#p_mission{mission_id = ID} = Mission|R]) ->
    [#c_mission{type = MissionType}] = lib_config:find(cfg_mission, ID),
    ?IF(MissionType =:= ?MISSION_TYPE_MAIN, Mission, get_main_mission2(R)).

accept_mission(MissionID) ->
    MissionList = robot_data:get_missions(),
    case lists:keytake(MissionID, #p_mission.mission_id, MissionList) of
        {value, #p_mission{} = Mission, MissionList2} ->
            MissionList3 = [Mission#p_mission{status = ?MISSION_STATUS_DOING}|MissionList2],
            robot_data:set_missions(MissionList3);
        _ ->
            ok
    end.

complete_mission(MissionID) ->
    MissionList = robot_data:get_missions(),
    MissionList2 = lists:keydelete(MissionID, #p_mission.mission_id, MissionList),
    robot_data:set_missions(MissionList2).

update_mission(DelList, UpdateList) ->
    MissionList = robot_data:get_missions(),
    MissionList2 =
        lists:foldl(
            fun(DelMissionID, Acc1) ->
                lists:keydelete(DelMissionID, #p_mission.mission_id, Acc1)
            end, MissionList, DelList),
    MissionList3 =
        lists:foldl(
            fun(Update, Acc2) ->
                lists:keystore(Update#p_mission.mission_id, #p_mission.mission_id, Acc2, Update)
            end, MissionList2, UpdateList),
    robot_data:set_missions(MissionList3).

listen_update(MissionID, Listens) ->
    MissionList = robot_data:get_missions(),
    case lists:keytake(MissionID, #p_mission.mission_id, MissionList) of
        {value, #p_mission{} = Mission, MissionList2} ->
            Mission2 = Mission#p_mission{listen = Listens},
            Mission3 = ?IF(check_is_finish(MissionID, Listens), Mission2#p_mission{status = ?MISSION_STATUS_REWARD}, Mission2),
            robot_data:set_missions([Mission3|MissionList2]);
        _ ->
            ok
    end.

check_is_finish(MissionID, Listens) ->
    [#c_mission{listeners = Configs}] = lib_config:find(cfg_mission, MissionID),
    check_is_finish2(Configs, Listens).

check_is_finish2([], _Listens) ->
    true;
check_is_finish2([{Type, Val, Num, _Rate}|R], Listens) ->
    case check_is_finish3(Type, Val, Num, Listens, []) of
        {ok, Listens2} ->
            check_is_finish2(R, Listens2);
        _ ->
            false
    end.

check_is_finish3(_Type, _Val, _Num, [], _Acc) ->
    false;
check_is_finish3(Type, Val, Num, [Listen|R], Acc)->
    #p_listen{type = NowType, val = NowVal, num = NowNum} = Listen,
    case Type =:= NowType andalso NowVal =:= Val of
        true ->
            case Num =:= NowNum of
                true ->
                    {ok, R ++ Acc};
                _ ->
                    false
            end;
        _ ->
            check_is_finish3(Type, Val, Num, R, Acc)
    end.

get_monster_pos(MapID, TypeID) ->
    [#c_map_base{seqs = Seqs}] = lib_config:find(cfg_map_base, MapID),
    get_monster_pos2(Seqs, MapID, TypeID).

get_monster_pos2([], MapID, TypeID) ->
    ?ERROR_MSG("地图里找不到该怪物ID:~w", [{MapID, TypeID}]);
get_monster_pos2([SeqID|R], MapID, TypeID) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [#c_map_seq{monster_type_id = TypeID, min_point = MinPoint, max_point = MaxPoint}] ->
            map_misc:get_map_seq_born_pos(MapID, MinPoint, MaxPoint);
        _ ->
            get_monster_pos2(R, MapID, TypeID)
    end.

get_collection_pos(MapID, TypeID) ->
    [#c_map_base{seqs = Seqs}] = lib_config:find(cfg_map_base, MapID),
    get_collection_pos2(Seqs, MapID, TypeID).

get_collection_pos2([], MapID, TypeID) ->
    ?ERROR_MSG("地图里找不到该采集物ID:~w", [{MapID, TypeID}]);
get_collection_pos2([SeqID|R], MapID, TypeID) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [#c_map_seq{collection_type_id = TypeID, min_point = MinPoint, max_point = MaxPoint}] ->
            map_misc:get_map_seq_born_pos(MapID, MinPoint, MaxPoint);
        _ ->
            get_collection_pos2(R, MapID, TypeID)
    end.

get_around_collect_id(TypeID) ->
    ActorIDs = robot_data:get_actor_ids(),
    get_around_collect_id(ActorIDs, TypeID).

get_around_collect_id([], _TypeID) ->
    erlang:throw(false);
get_around_collect_id([ActorID|R], TypeID) ->
    #p_map_actor{actor_id = ActorID, actor_type = ActorType, collection_extra = CollectionExtra} = robot_data:get_actor(ActorID),
    case ActorType =:= ?ACTOR_TYPE_COLLECTION andalso TypeID =:= CollectionExtra#p_map_collection.type_id of
        true ->
            ActorID;
        _ ->
            get_around_collect_id(R, TypeID)
    end.

get_summon_flag(MissionID) ->
    erlang:get({?MODULE, summon_flag, MissionID}).

set_summon_flag(MissionID) ->
    erlang:put({?MODULE, summon_flag, MissionID}, true).