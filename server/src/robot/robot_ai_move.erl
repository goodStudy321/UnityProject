%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_ai_move).

-export([
    jump_condition/1,
    jump/0,
    move_condition/1,
    move/1,
    dest_move/1,
    fight_move/1,
    mission_move/2,
    loop_ms/0
]).

-include("global.hrl").
-include("robot.hrl").
-include("proto/mod_map_role_move.hrl").
-include("proto/mod_role_map.hrl").


-define(DEFAULT_HEAP_SIZE, 100).
-define(ALL_MAP, 1). %% 全地图范围内随机去点
-define(ROLE_AROUND, 2). %% 周边9 * 9范围内取

jump_condition(CD) ->
    NowPos = robot_data:get_now_pos(),
    MapID = robot_data:get_map_id(),
    #r_pos{tx = Tx, ty = Ty} = map_misc:pos_decode(NowPos),
    TxList = lists:seq(Tx - 3, Tx + 3),
    TyList = lists:seq(Ty - 3, Ty + 3),
    Now = time_tool:now(),
    case check_cd(Now, CD) of %% 加个CD时间防止来回反复跳转~~~
        true ->
            case catch check_jump_point(TxList, TyList, MapID) of
                {ok, JumpPoint} ->
                    set_last_jump_time(Now),
                    set_jump_point(JumpPoint),
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

check_cd(Now, CD) ->
    LastJumpTime = get_last_jump_time(),
    Now >= LastJumpTime + CD.

check_jump_point(TxList, TyList, MapID) ->
    lists:foreach(
        fun(Tx) ->
            lists:foreach(
                fun(Ty) ->
                    case lib_config:find(cfg_jump_point, {MapID, Tx, Ty}) of
                        [_Value] ->
                            {ok, {Tx, Ty}};
                        _ ->
                            false
                    end
                end, TyList)
        end,TxList).

jump() ->
    case get_jump_point() of
        {Tx, Ty} ->
            MapID = robot_data:get_map_id(),
            robot_client:send_data(#m_map_change_pos_tos{map_id = MapID, dest_pos = map_misc:pos_encode(map_misc:get_pos_by_tile(Tx, Ty))}),
            robot_ai:stop_loop_ms(),
            true;
        _ ->
            false
    end.


move_condition(_Type) ->
    true.

move(_Type) ->
    {Tx, Ty} = get_role_around_tx_ty(),
    move2(Tx, Ty).

dest_move(Points) ->
    {Tx, Ty} = lib_tool:random_element_from_list(Points),
    move2(Tx, Ty, 400).

fight_move(DestPos) ->
    #r_pos{tx = Tx, ty = Ty} = DestPos,
    move2(Tx, Ty, ?DEFAULT_HEAP_SIZE).

mission_move(Mx, My) ->
    case move2(?M2T(Mx), ?M2T(My), ?DEFAULT_HEAP_SIZE) of
        true ->
            true;
        _ ->
            change_pos(Mx, My)
    end.

move2(Tx, Ty) ->
    move2(Tx, Ty, ?DEFAULT_HEAP_SIZE).
move2(Tx, Ty, HeapSize) ->
    MyPos = robot_data:get_now_pos(),
    MyPos2 = map_misc:pos_decode(MyPos),
    DestPos = map_misc:get_pos_by_tile(Tx, Ty),
    case mod_astar_pathfinding:find_path(MyPos2, DestPos, HeapSize) of
        [CurPath|Paths] ->
            set_cur_path(CurPath),
            set_move_paths(Paths),
            robot_ai:add_executing_mod(?MODULE),
            true;
        _ ->
            false
    end.

change_pos(Mx, My) ->
    Pos = map_misc:get_pos_by_meter(Mx, My),
    IntPos = map_misc:pos_encode(Pos),
    robot_client:send_data(#m_map_change_pos_tos{dest_pos = IntPos, map_id = robot_data:get_map_id()}).

loop_ms() ->
    case get_cur_path() of
        #r_path{path = []} -> %% 当前无可走路径了
            walk_paths();
        #r_path{} = CurPath -> %% 继续走当前路径
            walk_cur_path(CurPath);
        _ ->
            walk_paths()
    end,
    ok.

walk_cur_path(CurPath)->
    PosList = CurPath#r_path.path,
    [Pos|Remain] = PosList,
    Pos2 = map_misc:pos_encode(Pos),
    robot_data:set_now_pos(Pos2),
    robot_client:send_data(#m_move_role_walk_tos{pos = Pos2}),
    set_cur_path(CurPath#r_path{path = Remain}).

walk_paths() ->
    Paths = get_move_paths(),
    case Paths of
        [CurPath|Remain] ->
            robot_client:send_data(#m_move_point_tos{point = CurPath#r_path.corner}),
            set_move_paths(Remain),
            walk_cur_path(CurPath);
        _ ->
            erase_cur_path(),
            erase_move_paths(),
            robot_ai:del_executing_mod(?MODULE),
            robot_client:send_data(#m_move_stop_tos{pos = robot_data:get_now_pos()})
    end.

get_role_around_tx_ty() ->
    Pos = robot_data:get_now_pos(),
    #r_pos{tx = Tx, ty = Ty} = map_misc:pos_decode(Pos),
    TxList = lists:seq(Tx - 6, Tx + 6),
    TyList = lists:seq(Ty - 6, Ty + 6),
    ExistList =
        lists:foldl(
            fun(DestTx, Acc) ->
                NewAcc =
                    lists:foldl(
                        fun(DestTy, Acc2) ->
                            ?IF(map_base_data:is_exist(DestTx, DestTy), [{DestTx, DestTy}|Acc2], Acc2)
                        end, [], TyList),
                NewAcc ++ Acc
            end, [], TxList),
    lib_tool:random_element_from_list(ExistList).

%% 当前走的路径
get_cur_path() ->
    erlang:get({?MODULE, cur_path}).
set_cur_path(Path) ->
    erlang:put({?MODULE, cur_path}, Path).
erase_cur_path() ->
    erlang:erase({?MODULE, cur_path}).

%% 需要走的整个路径
get_move_paths() ->
    erlang:get({?MODULE, paths}).
set_move_paths(Paths) ->
    erlang:put({?MODULE, paths}, Paths).
erase_move_paths() ->
    erlang:erase({?MODULE, paths}).

set_last_jump_time(Time) ->
    erlang:put({?MODULE, last_jump_time}, Time).
get_last_jump_time() ->
    case erlang:get({?MODULE, last_jump_time}) of
        Int when erlang:is_integer(Int) -> Int;
        _ -> 0
    end.

%% 设置跳转点
set_jump_point(JumpPoint) ->
    erlang:put({?MODULE, jump_point}, JumpPoint).
get_jump_point() ->
    erlang:get({?MODULE, jump_point}).
