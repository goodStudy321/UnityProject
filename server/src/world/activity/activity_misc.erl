%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 三月 2018 17:05
%%%-------------------------------------------------------------------
-module(activity_misc).
-author("laijichang").
-include("activity.hrl").
-include("global.hrl").

%% API
-export([
    check_role_level/2
]).

-export([
    get_map_activity_mod/0,
    get_activity_mod/1
]).

check_role_level(ActivityID, RoleID) ->
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ActivityID),
    ?IF(common_role_data:get_role_level(RoleID) >= MinLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)).

%% 给地图模块调用
get_map_activity_mod() ->
    ?IF(common_config:is_cross_node(), cross_activity_server, world_activity_server).

get_activity_mod(ActivityID) ->
    ?IF(is_cross_activity_open(ActivityID), cross_activity_server, world_activity_server).

is_cross_activity_open(ActivityID) ->
    #r_activity{is_cross = IsCross} = world_activity_server:get_activity(ActivityID),
    IsCross.