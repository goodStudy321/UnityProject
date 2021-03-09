%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_ai).
-include("proto/mod_role_gm.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_role_map.hrl").

-export([
    init/0,
    loop_ms/0,
    change_map/1,
    add_executing_mod/1,
    del_executing_mod/1,
    start_loop_ms/0,
    stop_loop_ms/0
]).
-include("robot.hrl").
-include("global.hrl").

-define(IS_SEL_NODES(NodeInt), (NodeInt div 1000000 =:= 1)).
-define(IS_SEQ_NODES(NodeInt), (NodeInt div 1000000 =:= 2)).
-define(IS_ACTION(ActionInt), (NodeInt div 1000000 =:= 3 orelse NodeInt div 1000000 =:= 4)).
-define(LOOP_STATE_START, 1).
-define(LOOP_STATE_STOP, 2).

%% robot初次进入地图
%% 只有auto类型的机器人才会激活循环
init() ->
    time_tool:reg(robot, [300]),
    send_gm_order(),
    ok.

change_map(MapID) ->
    erase_executing_mods(),
    erase_ai_tree(),
    RobotType = robot_data:get_robot_type(),
    RobotAI = get_robot_ai(RobotType, MapID),
    set_ai_tree(RobotAI),
    start_loop_ms().

start_loop_ms() ->
    set_loop_state(?LOOP_STATE_START).

stop_loop_ms() ->
    set_loop_state(?LOOP_STATE_STOP).

loop_ms() ->
    case get_loop_state() =:= ?LOOP_STATE_START of %%控制是否开启循环
        true ->
            case get_executing_mods() of
                [_|_] = Mods -> %% 判断当前是否有正在执行的动作
                    [ begin
                          case erlang:function_exported(Mod, loop_ms, 0) of
                              true -> ?TRY_CATCH(Mod:loop_ms());
                              _ -> ?INFO_MSG("function not exported:~w", [Mod])
                          end
                      end || Mod <- Mods];
                _ -> %% 没有的话重新遍历下树
                    AITree = get_ai_tree(),
                    sel_action(AITree)
            end;
        _ ->
            ignore
    end,
    ok.

%% 选择节点 返回true时返回
sel_action(Int) when erlang:is_integer(Int) ->
    [Actions] = lib_config:find(cfg_robot_ai, {child_nodes, Int}),
    sel_action(Actions);
sel_action([]) ->
    false;
sel_action([Action|R]) ->
    Result =
        if
            ?IS_SEL_NODES(Action) ->
                sel_action(Action);
            ?IS_SEQ_NODES(Action) ->
                seq_action(Action);
            true ->
                execute_action(Action)
        end,
    ?IF(Result, true, sel_action(R)).

%% 顺序节点 返回false时返回
seq_action(Int) when erlang:is_integer(Int) ->
    [Actions] = lib_config:find(cfg_robot_ai, {child_nodes, Int}),
    seq_action(Actions);
seq_action([]) ->
    true;
seq_action([Action|R]) ->
    Result =
        if
            ?IS_SEL_NODES(Action) ->
                sel_action(Action);
            ?IS_SEQ_NODES(Action) ->
                seq_action(Action);
            true ->
                execute_action(Action)
        end,
    ?IF(Result, seq_action(R), Result).

%% 条件节点跟行为节点
execute_action(Action) ->
    [{M, F, A}] = lib_config:find(cfg_robot_ai, {actions, Action}),
    erlang:apply(M, F, A).


send_gm_order() ->
    robot_client:send_data(#m_role_gm_tos{type = "role_add_gold", args = "10000000;10000000"}),
    robot_client:send_data(#m_role_gm_tos{type = "role_vip", args = "4"}),
    case robot_data:get_robot_type() of
        2 ->
            robot_client:send_data(#m_role_gm_tos{type = "god", args = ""});
        3 ->
            robot_client:send_data(#m_role_gm_tos{type = "god", args = ""});
        4 ->
            robot_client:send_data(#m_role_gm_tos{type = "role_set_level", args = "300"}),
            ConfigList = [ Config || {_Key, #c_map_base{seqs = Seqs} = Config} <- cfg_map_base:list(), Seqs =/= []],
            #c_map_base{map_id = MapID, seqs = Seqs} = lib_tool:random_element_from_list(ConfigList),
            case get_enter_pos(MapID, lib_tool:random_reorder_list(Seqs)) of
                {ok, Pos} ->
                    robot_client:send_data(#m_map_change_pos_tos{dest_pos = Pos, map_id = MapID});
                _ ->
                    ok
            end;
        6 ->
            robot_client:send_data(#m_pre_enter_tos{map_id = 90001});
        7 ->
            robot_client:send_data(#m_role_gm_tos{type = "role_set_level", args = "400"});
        _ ->
            ok
    end,
%%    robot_client:send_data(#m_role_gm_tos{type = "role_function_open", args = ""}),
    ok.

get_enter_pos(_MapID, []) ->
    ok;
get_enter_pos(MapID, [SeqID|R]) ->
    [#c_map_seq{monster_type_id = MonsterTypeID, min_point = MinPoint, max_point = MaxPoint}] = lib_config:find(cfg_map_seq, SeqID),
    case MonsterTypeID > 0 of
        true ->
            BornPos = map_misc:get_map_seq_born_pos(MapID, MinPoint, MaxPoint),
            {ok, map_misc:pos_encode(BornPos)};
        _ ->
            get_enter_pos(MapID, R)
    end.

%% ================internal=================
del_executing_mod(Mod) ->
    get_executing_mods(lists:delete(Mod, get_executing_mods())).

add_executing_mod(Mod) when erlang:is_list(Mod)->
    get_executing_mods(lists:usort(Mod ++ get_executing_mods()));
add_executing_mod(Mod)->
    Mods = get_executing_mods(),
    case lists:member(Mod, Mods) of
        true -> ok;
        _ -> get_executing_mods([Mod|get_executing_mods()])
    end.

get_executing_mods() ->
    case erlang:get({?MODULE, executing_mods}) of
        List when erlang:is_list(List) -> List;
        _ -> []
    end.
get_executing_mods(Mods) ->
    erlang:put({?MODULE, executing_mods}, Mods).
erase_executing_mods() ->
    erlang:erase({?MODULE, executing_mods}).

set_ai_tree(RobotAI) ->
    erlang:put({?MODULE, ai_tree}, RobotAI).
get_ai_tree() ->
    erlang:get({?MODULE, ai_tree}).
erase_ai_tree() ->
    erlang:erase({?MODULE, ai_tree}).

set_loop_state(State) ->
    erlang:put({?MODULE, loop_state}, State).
get_loop_state() ->
    erlang:get({?MODULE, loop_state}).

get_robot_ai(RobotType, MapID) ->
    case lib_config:find(cfg_robot_ai, {robot_map, MapID}) of
        [RobotAI] ->
            RobotAI;
        _ ->
            case lib_config:find(cfg_robot_ai, {robot_type, RobotType}) of
                [RobotAI] ->
                    RobotAI;
                _ ->
                    [RobotAI] = lib_config:find(cfg_robot_ai, normal_ai),
                    RobotAI
            end
    end.