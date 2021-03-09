%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 五月 2017 15:30
%%%-------------------------------------------------------------------
-module(mod_robot_walk).
-author("laijichang").

-include("copy.hrl").
-include("world_robot.hrl").

-export([
    guard/1
]).

-export([
    start_walk/4
]).

%% ==================== 警戒状态 =============================

guard(#r_robot{robot_id = RobotID} = RobotData)->
    case catch guard2(RobotID, RobotData) of
        {ok, AddCounter, RobotData2}->
            {ok, AddCounter, RobotData2};
        Error->
            ?ERROR_MSG("GUARD error:~w",[Error]),
            {ok, ?BLAME_COUNTER, RobotData}
    end.

guard2(RobotID, RobotData)->
    #r_robot{robot_id = RobotID} = RobotData,
    MoveSpeed = mod_robot:get_move_speed(RobotData),
    ?IF(MoveSpeed =/= 0,  ok, ?ROBOT_RETURN(?NORMAL_COUNTER, RobotData)),
    RobotData2 = mod_robot_attack:update_enemy_lists(RobotData),
    %% 部分功能，设置列必须要攻击的目标
    DestActorID =  mod_robot_attack:get_enemy(RobotData2),
    case DestActorID > 0 of
        true ->
            guard3(DestActorID, RobotData2);
        _ ->
            EnemyID = mod_robot_attack:active_find_enemies(RobotID, RobotData2),
            case erlang:is_integer(EnemyID) of
                true ->
                    guard3(EnemyID, RobotData2);
                _ ->
                    ?ROBOT_RETURN(?NORMAL_COUNTER, RobotData2)
            end
    end.

guard3(EnemyID, RobotData) ->
    #r_robot{robot_id = RobotID} = RobotData,
    RobotData2 = RobotData#r_robot{
        state = ?ROBOT_STATE_FIGHT,
        enemies = [EnemyID],
        walk_path = []},
    mod_robot_map:robot_stop(RobotID),
    ?ROBOT_RETURN(?NORMAL_COUNTER, RobotData2).

%% 机器人行走
start_walk(#r_pos{}=RobotPos, #r_pos{}=DestPos, RobotID, RobotData) ->
    #r_robot{
        walk_path = WalkPath,
        buff_status = BuffStatus,
        last_dest_pos = LastDestPos} = RobotData,
    MoveSpeed = mod_robot:get_move_speed(RobotData),
    %% 晕眩、移动加上buff判断
    ?IF(?IS_BUFF_IMPRISON(BuffStatus) orelse ?IS_BUFF_DIZZY(BuffStatus), ?ROBOT_RETURN(?NORMAL_COUNTER, RobotData), ok),
    NewWalkPath = ?IF(DestPos =:= LastDestPos , WalkPath, []),
    {AddCounter, RobotData2} =
        case NewWalkPath of
            [] ->
                second_level_walk(RobotID, RobotData, RobotPos, DestPos, MoveSpeed);
            [_|_]->
                walk_inpath(RobotID, RobotData, DestPos, MoveSpeed, WalkPath)
        end,
    ?ROBOT_RETURN(AddCounter, RobotData2);
start_walk(_RobotPos, _DestPos, _RobotID, RobotData)->
    ?ROBOT_RETURN(?NORMAL_COUNTER, RobotData).

%%按照寻路除的路径走路,如果遇到阻挡则重新寻路
walk_inpath(RobotID, RobotData, DestPos, MoveSpeed, WalkPathList) ->
    [ #r_path{corner = Corner, path = [WalkPos|WalkPosList]}=WalkPath | WalkPathRem ] = WalkPathList,
    case WalkPosList of
        [] -> NewWalkPosList = WalkPathRem;
        _ -> NewWalkPosList = [ WalkPath#r_path{corner = 0, path = WalkPosList} |WalkPathRem]
    end,
    case Corner of
        0-> ignore;
        _-> mod_map_robot:robot_move_point(RobotID, Corner)
    end,
    mod_map_robot:robot_move(RobotID, WalkPos, map_misc:pos_encode(WalkPos)),
    case NewWalkPosList of
        []->
            mod_map_robot:robot_stop(RobotID);
        _->
            ignore
    end,
    RobotData2 = RobotData#r_robot{last_dest_pos = DestPos, walk_path = NewWalkPosList},
    AddCounter = mod_walk:get_move_speed_counter(MoveSpeed, WalkPos#r_pos.dir),
    {AddCounter, RobotData2}.

%%BOSS在战斗中是直接采用高级寻路
second_level_walk(RobotID, RobotData, RobotPos, DestPos, MoveSpeed) ->
    case mod_walk:get_senior_path(RobotPos, DestPos) of
        {ok, [_|_] = WalkPath} ->
            walk_inpath(RobotID, RobotData, DestPos, MoveSpeed, WalkPath);
        _ ->
            {?BLAME_COUNTER, RobotData}
    end.