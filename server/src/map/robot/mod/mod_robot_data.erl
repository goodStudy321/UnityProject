%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_robot_data).
-author("laijichang").
-include("world_robot.hrl").

%% API
-export([
    init/1
]).

%% mod_robot
-export([
    set_loop_counter/1,
    get_loop_counter/0,

    add_counter_robot/2,
    del_counter_robot/2,
    set_counter_robots/2,
    get_counter_robots/1,
    erase_counter_robots/1,

    add_robot_id/1,
    del_robot_id/1,
    set_robot_id_list/1,
    get_robot_id_list/0,

    set_robot_data/2,
    get_robot_data/1,
    del_robot_data/1
]).

-export([
    del_robot_buff_list/1,
    set_robot_buff_list/1,
    get_robot_buff_list/0
]).

%%%===================================================================
%%% API
%%%===================================================================
init(_MapID) ->
    set_loop_counter(1),
    set_robot_id_list([]),
    set_robot_buff_list([]).

%%%===================================================================
%%% mod_robot start
%%%===================================================================
set_loop_counter(Counter) ->
    erlang:put({?MODULE, loop_counter}, Counter).
get_loop_counter() ->
    erlang:get({?MODULE, loop_counter}).

add_counter_robot(RobotID, Counter) ->
    set_counter_robots(Counter, [RobotID|get_counter_robots(Counter)]).
del_counter_robot(RobotID, Counter) ->
    set_counter_robots(Counter, lists:delete(RobotID, get_counter_robots(Counter))).
set_counter_robots(Counter, RobotList) ->
    erlang:put({?MODULE, counter_robots, Counter}, RobotList).
get_counter_robots(Counter) ->
    case erlang:get({?MODULE, counter_robots, Counter}) of
        [_|_] = List -> List;
        _ -> []
    end.
erase_counter_robots(Counter) ->
    erlang:erase({?MODULE, counter_robots, Counter}).

add_robot_id(RobotID) ->
    set_robot_id_list([RobotID|get_robot_id_list()]).
del_robot_id(RobotID) ->
    set_robot_id_list(lists:delete(RobotID, get_robot_id_list())).
set_robot_id_list(RobotList) ->
    erlang:put({?MODULE, robot_id_list}, RobotList).
get_robot_id_list() ->
    erlang:get({?MODULE, robot_id_list}).

set_robot_data(RobotID, RobotData) ->
    OldRobotData = erlang:put({?MODULE, robot_data, RobotID}, RobotData),
    ?TRY_CATCH(mod_robot:robot_data_change(OldRobotData, RobotData)).
get_robot_data(RobotID) ->
    erlang:get({?MODULE, robot_data, RobotID}).
del_robot_data(RobotID) ->
    erlang:erase({?MODULE, robot_data, RobotID}).
%%%===================================================================
%%% mod_robot end
%%%===================================================================


%%%===================================================================
%%% mod_robot_buff start
%%%===================================================================
del_robot_buff_list(RobotID) ->
    RobotList = get_robot_buff_list(),
    set_robot_buff_list(lists:delete(RobotID, RobotList)).
set_robot_buff_list(List) ->
    erlang:put({?MODULE, robot_buff_list}, List).
get_robot_buff_list() ->
    erlang:get({?MODULE, robot_buff_list}).

%%%===================================================================
%%% mod_robot_buff end
%%%===================================================================