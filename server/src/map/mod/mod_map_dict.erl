%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     dict
%%% @end
%%% Created : 05. 五月 2017 15:17
%%%-------------------------------------------------------------------
-module(mod_map_dict).
-author("laijichang").
-include("global.hrl").

%% API

%% map_server
-export([
    set_is_map_process/1,
    get_is_map_process/0,
    set_sub_type/1,
    get_sub_type/0,
    set_is_wild_map/1,
    get_is_wild_map/0,
    set_map_params/1,
    get_map_params/0,
    set_msg_num/1,
    get_msg_num/0,
    set_monster_pid/1,
    get_monster_pid/0,
    set_collection_pid/1,
    get_collection_pid/0,
    set_trap_pid/1,
    get_trap_pid/0,
    set_robot_pid/1,
    get_robot_pid/0,
    set_msg_server_pid/1,
    get_msg_server_pid/0
]).

%% slice
-export([
    set_slice_width/1,
    get_slice_width/0,
    set_slice_height/1,
    get_slice_height/0
]).

%% actor

%% fight
-export([
    set_fight_attr/2,
    get_fight_attr/1,
    erase_fight_attr/1,
    set_fight_mfa_list/1,
    get_fight_mfa_list/0,
    add_fight_bc/1,
    set_fight_bc_list/1,
    get_fight_bc_list/0,

    get_role_last_drain/1,
    set_role_last_drain/2,
    erase_role_last_drain/1
]).

%%%===================================================================
%%% map 基础信息
%%%===================================================================
set_is_map_process(Bool) ->
    erlang:put({?MODULE, is_map_process}, Bool).
get_is_map_process() ->
    erlang:get({?MODULE, is_map_process}).

set_sub_type(SubType) ->
    erlang:put({?MODULE, sub_type}, SubType).
get_sub_type() ->
    erlang:get({?MODULE, sub_type}).

set_is_wild_map(Bool) ->
    erlang:put({?MODULE, is_wild_map}, Bool).
get_is_wild_map() ->
    erlang:get({?MODULE, is_wild_map}).


set_map_params(Params) ->
    erlang:put({?MODULE, map_params}, Params).
get_map_params() ->
    erlang:get({?MODULE, map_params}).

set_msg_num(Num) ->
    erlang:put({?MODULE, msg_server_num}, Num).
get_msg_num() ->
    erlang:get({?MODULE, msg_server_num}).

set_monster_pid(PID) ->
    erlang:put({?MODULE, monster_server}, PID).
get_monster_pid() ->
    erlang:get({?MODULE, monster_server}).

set_collection_pid(PID) ->
    erlang:put({?MODULE, collection_pid}, PID).
get_collection_pid() ->
    erlang:get({?MODULE, collection_pid}).

set_trap_pid(PID) ->
    erlang:put({?MODULE, trap_pid}, PID).
get_trap_pid() ->
    erlang:get({?MODULE, trap_pid}).

set_robot_pid(PID) ->
    erlang:put({?MODULE, robot_pid}, PID).
get_robot_pid() ->
    erlang:get({?MODULE, robot_pid}).

set_msg_server_pid(PIDList) ->
    erlang:put({?MODULE, msg_server_pid}, PIDList).
get_msg_server_pid() ->
    erlang:get({?MODULE, msg_server_pid}).
%%%===================================================================
%%% map 基础信息 end
%%%===================================================================


%%%===================================================================
%%% map slice start
%%%===================================================================
set_slice_width(Width) ->
    erlang:put({?MODULE, slice_width}, Width).
get_slice_width() ->
    erlang:get({?MODULE, slice_width}).

set_slice_height(Height) ->
    erlang:put({?MODULE, slice_height}, Height).
get_slice_height() ->
    erlang:get({?MODULE, slice_height}).
%%%===================================================================
%%% map slice end
%%%===================================================================


%%%===================================================================
%%% map actor start
%%%===================================================================

%%%===================================================================
%%% map actor end
%%%===================================================================



%%%===================================================================
%%% map fight start
%%%===================================================================
set_fight_attr(ActorID, FightAttr) ->
    erlang:put({?MODULE, actor_fight_attr, ActorID}, FightAttr).
get_fight_attr(ActorID) ->
    erlang:get({?MODULE, actor_fight_attr, ActorID}).
erase_fight_attr(ActorID) ->
    erlang:erase({?MODULE, actor_fight_attr, ActorID}).

set_fight_mfa_list(List) ->
    erlang:put({?MODULE, fight_mfa_list}, List).
get_fight_mfa_list() ->
    erlang:get({?MODULE, fight_mfa_list}).

add_fight_bc(ResultList) ->
    set_fight_bc_list(ResultList ++ get_fight_bc_list()).
set_fight_bc_list(List) ->
    erlang:put({?MODULE, fight_bc_list}, List).
get_fight_bc_list() ->
    erlang:get({?MODULE, fight_bc_list}).

get_role_last_drain(SrcID) ->
    erlang:get({?MODULE, role_last_drain, SrcID}).
set_role_last_drain(SrcID, NowMs) ->
    erlang:put({?MODULE, role_last_drain, SrcID}, NowMs).
erase_role_last_drain(SrcID) ->
    erlang:erase({?MODULE, role_last_drain, SrcID}).
%%%===================================================================
%%% map fight end
%%%===================================================================