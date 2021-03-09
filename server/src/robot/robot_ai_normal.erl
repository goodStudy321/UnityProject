%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_ai_normal).
-include("global.hrl").
-include("activity.hrl").
-include("proto/world_activity_server.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_solo.hrl").

%% 条件节点
-export([
    activity_condition/1,
    map_condition/1,
    solo_match/0
]).

%% 行为节点
-export([
    enter_map/1
]).

%% 活动是否开启
activity_condition(ActivityID) ->
    ActivityList = robot_data:get_activity(),
    case lists:keyfind(ActivityID, #p_activity.id, ActivityList) of
        #p_activity{status = ?STATUS_OPEN} ->
            true;
        _ ->
            false
    end.

%% 不在这张地图
map_condition(MapID) ->
    NowMapID = robot_data:get_map_id(),
    if
        ?IS_MAP_SUMMIT_TOWER(MapID) ->
            not ?IS_MAP_SUMMIT_TOWER(NowMapID);
        true ->
            NowMapID =/= MapID
    end.

enter_map(MapID) ->
    case MapID of
        ?MAP_DEMON_BOSS ->
            robot_client:send_data(#m_pre_enter_tos{map_id = MapID, extra_id = 1});
        _ ->
            robot_client:send_data(#m_pre_enter_tos{map_id = MapID})
    end.

solo_match() ->
    robot_client:send_data(#m_solo_match_tos{type = 1}).
