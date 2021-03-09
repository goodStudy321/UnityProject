%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 十一月 2018 10:02
%%%-------------------------------------------------------------------
-module(mod_role_log_statistics).
-author("laijichang").
-include("role.hrl").
-include("copy.hrl").
-include("log_statistics.hrl").

%% API
-export([
    role_pre_enter/1,
    copy_finish/2
]).

-export([
    log_ring_mission/1,
    log_offline_solo/1,
    log_world_boss_tired/2,
    log_family_escort/1,
    log_family_rob/1,
    log_family_task/1
]).

-export([
    get_family_task_level/0
]).

role_pre_enter(State) ->
    #r_role{role_id = RoleID, role_map = #r_role_map{map_id = MapID}} = State,
    if
        ?IS_MAP_BATTLE(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_BATTLE, 1, 0);
        ?IS_MAP_SOLO(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_SOLO, 1, 0);
        ?IS_MAP_FAMILY_TD(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_TD, 1, 0);
        ?IS_MAP_ANSWER(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_ANSWER, 1, 0);
        ?IS_MAP_FAMILY_AS(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_ANSWER, 1, 0);
        ?IS_MAP_FAMILY_BOSS(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_BOSS, 1, 0);
        MapID =:= ?MAP_FIRST_SUMMIT_TOWER ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_SUMMIT_TOWER, 1, 0);
        ?IS_MAP_FAMILY_BT(MapID) ->
            world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_BATTLE, 1, 0);
        true ->
            [#c_map_base{map_type = MapType, sub_type = SubType}] = lib_config:find(cfg_map_base, MapID),
            if
                MapType =:= ?MAP_TYPE_COPY ->
                    {LogType, AddTimes, AddSubTimes} = get_copy_args(MapID, ?TIMES_TYPE_ENTER),
                    ?IF(LogType > 0, world_log_statistics_server:log_add_times(RoleID, LogType, AddTimes, AddSubTimes), ok);
                SubType =:= ?SUB_TYPE_WORLD_BOSS_2 ->
                    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_WORLD_BOSS_2, 1, 0);
                SubType =:= ?SUB_TYPE_WORLD_BOSS_4 ->
                    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_WORLD_BOSS_4, 1, 0);
                SubType =:= ?LOG_STAT_MYTHICAL_BOSS ->
                    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_MYTHICAL_BOSS, 1, 0);
                SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
                    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_ANCIENTS_BOSS, 1, 0);
                true ->
                    ok
            end
    end.

get_copy_args(CopyID, TimesType) ->
    [#c_copy{times_type = CopyTimesType, copy_type = CopyType}] = lib_config:find(cfg_copy, CopyID),
    LogType =
        if
            CopyType =:= ?COPY_EXP ->
                ?LOG_STAT_COPY_EXP;
            CopyType =:= ?COPY_SILVER ->
                ?LOG_STAT_COPY_SILVER;
            CopyType =:= ?COPY_EQUIP ->
                ?LOG_STAT_COPY_EQUIP;
            CopyType =:= ?COPY_TOWER ->
                ?LOG_STAT_COPY_TOWER;
            CopyType =:= ?COPY_WORLD_BOSS ->
                ?LOG_STAT_COPY_WORLD_BOSS;
            CopyType =:= ?COPY_SINGLE_TD ->
                ?LOG_STAT_COPY_SINGLE_TD;
            CopyType =:= ?COPY_IMMORTAL ->
                ?LOG_STAT_COPY_IMMORTAL;
            true ->
                0
        end,
    AddSubTimes = ?IF(CopyTimesType =:= TimesType, 1, 0),
    {LogType, 1, AddSubTimes}.

copy_finish(MapID, State) ->
    #r_role{role_id = RoleID} = State,
    {LogType, _AddTimes, AddSubTimes} = get_copy_args(MapID, ?TIMES_TYPE_SUCC),
    ?IF(LogType > 0 andalso AddSubTimes > 0, world_log_statistics_server:log_add_times(RoleID, LogType, 0, AddSubTimes), ok).

log_ring_mission(State) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_RING_MISSION, 1, 1).

log_offline_solo(State) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_OFFLINE_SOLO, 1, 1).

log_world_boss_tired(State, AddTimes) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_WORLD_BOSS_1, AddTimes, AddTimes).

log_family_escort(State) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_ESCORT, 1, 1).

log_family_rob(State) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_ROB, 1, 1).

log_family_task(State) ->
    #r_role{role_id = RoleID} = State,
    world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_FAMILY_MISSION, 1, 1).

get_family_task_level() ->
    mod_role_function:get_function_level(?FUNCTION_FAMILY_MISSION, 110).

