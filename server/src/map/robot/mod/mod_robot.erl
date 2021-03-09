%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2017 10:38
%%%-------------------------------------------------------------------
-module(mod_robot).
-author("laijichang").

%% API
-include("world_robot.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    loop_ms/1
]).

-export([
    init_robot/1,
    init_robot/2,
    robot_data_change/2
]).

-export([
    reborn_robot/1,
    recal_attr/1
]).

-export([
    get_move_speed/1
]).

init_robot(RobotData) ->
    init_robot(RobotData, ?MIN_COUNTER).
init_robot(RobotData, AddCounter) ->
    #r_robot{robot_id = RobotID} = RobotData,
    NextCounter = mod_robot_data:get_loop_counter() + AddCounter,
    RobotData2 = RobotData#r_robot{
        state = ?ROBOT_STATE_BORN,
        next_counter = NextCounter},
    RobotData3 = recal_attr(RobotData2),
    mod_robot_data:set_robot_data(RobotID, RobotData3),
    mod_robot_data:add_counter_robot(RobotID, NextCounter),
    mod_robot_data:add_robot_id(RobotID),
    ok.

reborn_robot(RobotData) ->
    RobotData2 = RobotData#r_robot{
        forever_enemies = [],
        enemies = [],
        buffs = [],
        debuffs = []},
    init_robot(RobotData2, ?ROBOT_REBORN_INTERVAL * 10).

loop_ms(_NowMs) ->
    Counter = mod_robot_data:get_loop_counter(),
    RobotList = mod_robot_data:get_counter_robots(Counter),
    [ robot_work(RobotID, Counter) || RobotID <- RobotList],
    mod_robot_data:erase_counter_robots(Counter),
    mod_robot_data:set_loop_counter(Counter + 1),
    ok.

robot_work(RobotID, Counter) ->
    case mod_robot_data:get_robot_data(RobotID) of
        #r_robot{} = RobotData ->
            robot_work2(RobotData, Counter);
        _ ->
            ignore
    end.

robot_work2(RobotData, Counter) ->
    #r_robot{robot_id = RobotID, state = State} = RobotData,
    case State of
        ?ROBOT_STATE_BORN -> %% 异步发消息给map出生怪物
            mod_robot_map:robot_born(RobotData);
        ?ROBOT_STATE_GUARD -> %% 守卫状态
            {ok, AddCounter, RobotData2} = mod_robot_walk:guard(RobotData),
            robot_work3(RobotID, RobotData2, Counter, AddCounter);
        ?ROBOT_STATE_FIGHT -> %% 战斗状态
            {ok, AddCounter, RobotData2} = mod_robot_fight:fight(RobotData),
            robot_work3(RobotID, RobotData2, Counter, AddCounter)
    end.

robot_work3(RobotID, RobotData, Counter, AddCounter) ->
    %% 保证一定会循环到！！！
    AddCounter2 = erlang:max(AddCounter, 1),
    NextCounter = Counter + AddCounter2,
    RobotData2 = RobotData#r_robot{next_counter = NextCounter},
    mod_robot_data:set_robot_data(RobotID, RobotData2),
    mod_robot_data:add_counter_robot(RobotID, Counter + AddCounter2).

robot_data_change(#r_robot{robot_id = RobotID, state = OldState}, #r_robot{state = NewState}) ->
    ?IF(OldState =/= NewState, robot_state_change(RobotID, NewState), ok);
robot_data_change(_, #r_robot{robot_id = RobotID, state = NewState}) ->
    robot_state_change(RobotID, NewState).

robot_state_change(RobotID, NewState) ->
    case NewState of
        ?ROBOT_STATE_GUARD ->
            mod_map_robot:robot_update_status(RobotID, ?MAP_STATUS_NORMAL);
        ?ROBOT_STATE_FIGHT ->
            mod_map_robot:robot_update_status(RobotID, ?MAP_STATUS_FIGHT);
        _ ->
            ok
    end.

recal_attr(RobotData) ->
    #r_robot{
        base_attr = BaseAttr,
        buffs = Buffs,
        debuffs = Debuffs
    } = RobotData,
    BuffAttr = common_buff:get_cal_attr(Buffs ++ Debuffs, BaseAttr),
    Attr = common_buff:sum_attr(BaseAttr, BuffAttr),
    RobotData#r_robot{attr = Attr}.

get_move_speed(RobotData) ->
    RobotData#r_robot.attr#actor_fight_attr.move_speed.

