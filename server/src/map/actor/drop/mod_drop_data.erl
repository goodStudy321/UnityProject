%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 九月 2017 10:14
%%%-------------------------------------------------------------------
-module(mod_drop_data).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    init/1,
    get_new_drop_id/0,
    add_drop_loop_list/1,
    del_drop_loop_list/1,
    set_drop_loop_list/1,
    get_drop_loop_list/0
]).

init(MapID) ->
    set_max_drop_id(common_id:get_drop_start_id(MapID) + 1),
    set_drop_loop_list([]).

get_new_drop_id()->
    NewID = get_max_drop_id(),
    set_max_drop_id(common_id:get_drop_next_id(NewID)),
    case mod_map_ets:get_actor_mapinfo(NewID) of
        #r_map_actor{} ->
            get_new_drop_id();
        _ ->
            NewID
    end.

set_max_drop_id(DropID) ->
    erlang:put({?MODULE, max_drop_id}, DropID).
get_max_drop_id() ->
    erlang:get({?MODULE, max_drop_id}).


add_drop_loop_list({DropID, EndTime}) ->
    set_drop_loop_list([{DropID, EndTime}|get_drop_loop_list()]).
del_drop_loop_list(DropID) ->
    set_drop_loop_list(lists:keydelete(DropID, 1, get_drop_loop_list())).
set_drop_loop_list(DropList) ->
    erlang:put({?MODULE, drop_id_list}, DropList).
get_drop_loop_list() ->
    erlang:get({?MODULE, drop_id_list}).
