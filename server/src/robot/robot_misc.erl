%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_misc).
-include("robot.hrl").

-export([
    start/0,
    start/1,
    start/2,
    start_by_num/2,
    start_by_num/5,

    start_sec_robot/5,

    stop/0,
    stop/1,
    stop/2
]).

start() ->
    start(1).
start(Index) ->
    start(Index, 1).
start(Index, Type) ->
    ensure_start(),
    robot_manager:start_robot_by_index(Index, Type).

start_by_num(Num, Type) ->
    start_by_num(1, Num/1, 0, 0, Type).

start_by_num(SecNum, AllSec, AllCounter, StartCounter, Type) ->
    ?IF(SecNum > 0 andalso AllSec > 0, ok, erlang:throw(num_error)),
    StartArgs = #r_robot_start{
        robot_type = Type,
        sec_start_num = SecNum,
        all_sec = AllSec,
        all_robot_counter = AllCounter,
        start_counter = StartCounter
    },
    ensure_start(),
    robot_manager:start_robot_by_num(StartArgs).

start_sec_robot(SecNum, AllCounter, StartCounter, CreateMin, Type) ->
    start_by_num(SecNum, CreateMin * 60, AllCounter, StartCounter, Type).


stop() ->
    catch robot_manager:stop_robot(#r_robot_stop{stop_robot_type = 0, stop_num = 99999999999}),
    ok.

stop(Type) ->
    stop(Type, 99999999999).
stop(Type, Num) ->
    robot_manager:stop_robot(#r_robot_stop{stop_robot_type = Type, stop_num = Num}).

ensure_start() ->
    catch time_tool:start_server(robot, server_sup, [300, 1000]),
    catch robot_sup:start(),
    catch robot_manager:start().