%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 九月 2019 9:20
%%%-------------------------------------------------------------------
-module(hook_cycle_act).
-author("WZP").
-include("proto/mod_role_cycle_act_extra.hrl").
-include("cycle_act.hrl").
-include("global.hrl").

%% API
-export([
    init_cycle_act/1,
    hour_change/2,
    zero/1,
    terminate/1,
    add_egg_log/2,
    get_config_num/1,
    cycle_act_end/1

]).

init_cycle_act(CycleAct) ->
    #r_cycle_act{id = ID} = CycleAct,
    case ID of
        ?CYCLE_ACT_RED_PACKET ->
            act_red_packet:zero();
        _ ->
            ok
    end,
    ok.

hour_change(Now, ID) ->
    case ID of
        ?CYCLE_ACT_RED_PACKET ->
            act_red_packet:hour_change(Now);
        _ ->
            ok
    end.

zero(ID) ->
    case ID of
        ?CYCLE_ACT_TRENCH_CEREMONY ->
            act_trench_ceremony:zero();
        ?CYCLE_ACT_RED_PACKET ->
            act_red_packet:zero();
        _ ->
            ok
    end.


terminate(ID) ->
    ID.


add_egg_log(RareLogs, NormalLogs) ->
    #r_cycle_act{level = Level} = world_cycle_act_server:get_act(?CYCLE_ACT_EGG),
    DataRecord = #m_cycle_egg_update_toc{a_log = NormalLogs, b_log = RareLogs},
    common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = Level}),
    {RareLogs2, NormalLogs2} = world_data:get_egg_log(),
    RareLogs3 = lib_tool:add_logs(RareLogs2, RareLogs, 5),
    NormalLogs3 = lib_tool:add_logs(NormalLogs2, NormalLogs, 30),
    world_data:set_egg_log({RareLogs3, NormalLogs3}).

get_config_num(ID) ->
    Week = lib_tool:ceil(common_config:get_open_days() / 7),
    WorldLevel = world_data:get_world_level(),
    ConfigList = [ConfigID || {_, #c_cycle_config{world_level = [MinLevel, MaxLevel|_], week = ConfigWeek, id = ConfigID, cycle_act = CycleID}} <- cfg_cycle_config:list(),
                  WorldLevel >= MinLevel, MaxLevel >= WorldLevel, lists:member(Week, ConfigWeek), ID =:= CycleID],
    case ConfigList =:= [] of
        true ->
            ConfigList2 = [ConfigID || {_, #c_cycle_config{world_level = [MinLevel, MaxLevel|_], week = ConfigWeek, id = ConfigID, cycle_act = CycleID}} <- cfg_cycle_config:list(),
                           WorldLevel >= MinLevel, MaxLevel >= WorldLevel, lists:member(999, ConfigWeek), ID =:= CycleID],
            case ConfigList2 of
                [ConfigNum|_] ->
                    ConfigNum;
                _ ->
                    ?ERROR_MSG("----------------111111---------------~w", [ID]),
                    1
            end;
        _ ->
            [ConfigNum|_] = ConfigList,
            ConfigNum
    end.

cycle_act_end(#r_cycle_act{id = ID}) ->
    case ID of
        ?CYCLE_ACT_TRENCH_CEREMONY ->
            act_trench_ceremony:trench_ceremony_end();
        ?CYCLE_ACT_COUPLE ->
            act_couple:cycle_act_end();
        _ ->
            ok
    end.



