%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 六月 2017 16:39
%%%-------------------------------------------------------------------
-module(robot_data).
-author("laijichang").
-include("robot.hrl").

%% API
-export([
    set_robot_account/1,
    get_robot_account/0,
    set_role_info/1,
    get_role_info/0,
    set_robot_type/1,
    get_robot_type/0
]).

-export([
    set_role_id/1,
    get_role_id/0,
    set_map_id/1,
    get_map_id/0,
    set_now_pos/1,
    get_now_pos/0,
    set_camp_id/1,
    get_camp_id/0,
    set_actor_ids/1,
    get_actor_ids/0,
    set_actor/2,
    get_actor/1,
    del_actor/1
]).

-export([
    set_activity/1,
    get_activity/0,
    set_missions/1,
    get_missions/0,
    set_level/1,
    get_level/0
]).

%% fight 相关
-export([
    set_fight_condition/1,
    get_fight_condition/0,
    set_enemy/1,
    get_enemy/0,
    erase_enemy/0,
    set_skills/1,
    get_skills/0,
    set_fight_skills/1,
    get_fight_skills/0,
    set_move_times/1,
    get_move_times/0,
    set_last_skill_time/1,
    get_last_skill_time/0
]).

set_robot_account(Name) ->
    erlang:put({?MODULE, robot_account}, Name).
get_robot_account() ->
    erlang:get({?MODULE, robot_account}).

set_role_info(#r_role_client{}=Client) ->
    erlang:put({?MODULE, role_info}, Client).
get_role_info() ->
    erlang:get({?MODULE, role_info}).

set_robot_type(RobotType)->
    erlang:put({?MODULE, robot_type}, RobotType).
get_robot_type()->
    erlang:get({?MODULE, robot_type}).


set_role_id(RoleID) ->
    erlang:put({?MODULE, role_id}, RoleID).
get_role_id() ->
    erlang:get({?MODULE, role_id}).

set_map_id(MapID) ->
    erlang:put({?MODULE,map_id}, MapID),
    map_base_data:init(MapID).
get_map_id() ->
    erlang:get({?MODULE, map_id}).

set_now_pos(Pos) ->
    erlang:put({?MODULE, now_pos}, Pos).
get_now_pos() ->
    erlang:get({?MODULE, now_pos}).

set_camp_id(CampID) ->
    erlang:put({?MODULE, camp_id}, CampID).
get_camp_id() ->
    erlang:get({?MODULE, camp_id}).

set_actor_ids(ActorsIDs) ->
    erlang:put({?MODULE, actor_ids}, ActorsIDs).
get_actor_ids() ->
    case erlang:get({?MODULE, actor_ids}) of
        List when erlang:is_list(List) -> List;
        _ -> []
    end.

set_actor(ActorID, MapInfo) ->
    erlang:put({?MODULE, actor, ActorID}, MapInfo).
get_actor(ActorID) ->
    erlang:get({?MODULE, actor, ActorID}).
del_actor(ActorID) ->
    erlang:erase({?MODULE, actor, ActorID}).

set_activity(List) ->
    erlang:put({?MODULE, activity}, List).
get_activity() ->
    case erlang:get({?MODULE, activity}) of
        [_|_] = List  -> List;
        _ -> []
    end.

set_missions(List) ->
    erlang:put({?MODULE, missions}, List).
get_missions() ->
    case erlang:get({?MODULE, missions}) of
        [_|_] = List  -> List;
        _ -> []
    end.

set_level(Level) ->
    erlang:put({?MODULE, level}, Level).
get_level() ->
    erlang:get({?MODULE, level}).

set_fight_condition(Condition) ->
    erlang:put({?MODULE, fight_condition}, Condition).
get_fight_condition() ->
    erlang:get({?MODULE, fight_condition}).

set_enemy(Actor) ->
    erlang:put({?MODULE, enemy}, Actor).
get_enemy() ->
    case erlang:get({?MODULE, enemy}) of
        ActorID when erlang:is_integer(ActorID)  -> ActorID;
        _ -> 0
    end.
erase_enemy() ->
    erlang:erase({?MODULE, enemy}).

set_skills(Skills) ->
    erlang:put({?MODULE, skills}, Skills).
get_skills() ->
    erlang:get({?MODULE, skills}).

set_fight_skills(Info) ->
    erlang:put({?MODULE, fight_skills}, Info).
get_fight_skills() ->
    erlang:get({?MODULE, fight_skills}).

set_move_times(Times) ->
    erlang:put({?MODULE, move_times}, Times).
get_move_times() ->
    case erlang:get({?MODULE, move_times}) of
        Times when erlang:is_integer(Times) -> Times;
        _ -> 0
    end.

set_last_skill_time(Time) ->
    erlang:put({?MODULE, last_skill_time}, Time).
get_last_skill_time() ->
    case erlang:get({?MODULE, last_skill_time}) of
        Time when erlang:is_integer(Time) -> Time;
        _ -> 0
    end.