%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 六月 2017 10:02
%%%-------------------------------------------------------------------
-module(mod_monster_ai).
-author("laijichang").
-include("monster.hrl").

%% API
-export([
    stop_action/1,
    start_action/1,
    single_move/2,
    attack_lock/2
]).

stop_action(MonsterData) ->
    NowCounter = mod_monster_data:get_loop_counter(),
    #r_monster{monster_id = MonsterID, next_counter = NextCounter} = MonsterData,
    MonsterList = mod_monster_data:get_counter_monsters(NextCounter),
    MonsterList2 = lists:delete(MonsterID, MonsterList),
    case NextCounter > NowCounter of
        true ->
            mod_monster_data:set_monster_data(MonsterID, MonsterData#r_monster{next_counter = 0}),
            mod_monster_data:set_counter_monsters(NextCounter, MonsterList2);
        _ ->
            ok
    end.

start_action(MonsterData) ->
    NowCounter = mod_monster_data:get_loop_counter(),
    #r_monster{monster_id = MonsterID, next_counter = NextCounter} = MonsterData,
    case NextCounter =:= 0 of
        true ->
            NextCounter2 = NowCounter + ?MIN_COUNTER,
            MonsterData2 = MonsterData#r_monster{next_counter = NextCounter2},
            mod_monster_data:set_monster_data(MonsterID, MonsterData2),
            mod_monster_data:add_counter_monster(MonsterID, NextCounter2);
        _ ->
            ok
    end.

single_move(#r_monster{monster_id = MonsterID, type_id = TypeID} = MonsterData, Args) ->
    [#c_monster_path{path_list = ConfigPath}] = lib_config:find(cfg_monster_path, lib_tool:to_integer(Args)),
    [#r_monster_path{pos = Pos, use_time = UseTime}|_] = PathList = get_return_path_list(ConfigPath),
    #c_monster{move_speed = DefaultSpeed} = monster_misc:get_monster_config(TypeID),
    MoveSpeed = monster_misc:get_path_move_speed(mod_map_ets:get_actor_pos(MonsterID), Pos, UseTime, DefaultSpeed),
    MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_RETURN, born_pos = Pos, return_list = PathList},
    mod_map_monster:monster_update_move_speed(MonsterID, MoveSpeed),
    mod_monster_data:set_monster_data(MonsterID, MonsterData2).

get_return_path_list(PathArgs) ->
    List = string:tokens(PathArgs, ";"),
    get_return_path_list2(List, []).

get_return_path_list2([], Acc) ->
    lists:reverse(Acc);
get_return_path_list2([Args|R], Acc) ->
    [Point, MoveTime, DelayTime] = string:tokens(Args, ","),
    [RealMx, _, RealMy] = string:tokens(Point, "|"),
    Pos = map_misc:get_pos_by_offset_pos(lib_tool:to_integer(RealMx), lib_tool:to_integer(RealMy)),
    DelayCounter = erlang:max(?MIN_COUNTER, lib_tool:to_integer(DelayTime) * 10),
    Path = #r_monster_path{pos = Pos, use_time = lib_tool:to_integer(MoveTime), delay_counter = DelayCounter},
    get_return_path_list2(R, [Path|Acc]).

attack_lock(MonsterData, Args) ->
    #r_monster{monster_id = MonsterID} = MonsterData,
    ID = lib_tool:to_integer(Args),
    case ID =:= 0 of
        true ->
            case mod_map_ets:get_in_map_roles() of
                [ActorID|_] ->
                    MonsterData2 = mod_monster_attack:add_enemy(MonsterData, ActorID, 10000000);
                _ ->
                    MonsterData2 = MonsterData
            end;
        _ ->
            MonsterData2 = mod_monster_attack:add_enemy(MonsterData, ID, 10000000)
    end,
    mod_monster_data:set_monster_data(MonsterID, MonsterData2#r_monster{state = ?MONSTER_STATE_FIGHT}).



