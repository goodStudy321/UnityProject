%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     map && monster && collection && trap && drop
%%% @end
%%% Created : 02. 六月 2017 14:22
%%%-------------------------------------------------------------------
-module(map_common_dict).
-author("laijichang").

%% API
-export([
    init/4,
    get_map_id/0,
    get_map_pname/0,
    get_map_pid/0,
    get_map_extra_id/0
]).

init(MapID, MapPName, MapPID, ExtraID) ->
    set_map_id(MapID),
    set_map_pname(MapPName),
    set_map_pid(MapPID),
    set_map_extra_id(ExtraID),
    map_base_data:init(MapID),
    mod_map_ets:common_init(MapID, ExtraID),
    mod_map_slice:init().

set_map_id(MapID) ->
    erlang:put({?MODULE, map_id}, MapID).
get_map_id() ->
    erlang:get({?MODULE, map_id}).

set_map_pname(MapPName) ->
    erlang:put({?MODULE, map_pname}, MapPName).
get_map_pname() ->
    erlang:get({?MODULE, map_pname}).

set_map_pid(MapPID) ->
    erlang:put({?MODULE, map_pid}, MapPID).
get_map_pid() ->
    erlang:get({?MODULE, map_pid}).

set_map_extra_id(ExtraID) ->
    erlang:put({?MODULE, map_extra_id}, ExtraID).
get_map_extra_id() ->
    erlang:get({?MODULE, map_extra_id}).