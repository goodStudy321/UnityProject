%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 六月 2017 15:29
%%%-------------------------------------------------------------------
-module(mod_collection_data).
-author("laijichang").
-include("collection.hrl").

%% API
-export([
    init/1,
    get_new_collection_id/0,
    add_collection_id/1,
    del_collection_id/1,
    set_collection_id_list/1,
    get_collection_id_list/0,
    add_loop_list/1,
    del_loop_list/1,
    set_loop_list/1,
    get_loop_list/0,
    set_collection_data/2,
    get_collection_data/1,
    del_collection_data/1,
    set_role_collection/2,
    get_role_collection/1,
    del_role_collection/1
]).

init(MapID) ->
    set_loop_list([]),
    set_collection_id_list([]),
    set_max_collection_id(common_id:get_collection_start_id(MapID) + 1).

get_new_collection_id()->
    NewID = get_max_collection_id(),
    set_max_collection_id(common_id:get_collection_nex_id(NewID)),
    case mod_collection_data:get_collection_data(NewID) of
        #r_collection{} ->
            get_new_collection_id();
        _ ->
            NewID
    end.

add_collection_id(CollectionID) ->
    set_collection_id_list([CollectionID|get_collection_id_list()]).
del_collection_id(CollectionID) ->
    set_collection_id_list(lists:delete(CollectionID, get_collection_id_list())).
set_collection_id_list(CollectionList) ->
    erlang:put({?MODULE, collection_id_list}, CollectionList).
get_collection_id_list() ->
    erlang:get({?MODULE, collection_id_list}).

add_loop_list(ID) ->
    List = get_loop_list(),
    ?IF(lists:member(ID, List), ok, set_loop_list([ID|List])).
del_loop_list(IDList) ->
    set_loop_list(get_loop_list() -- IDList).
set_loop_list(List) ->
    erlang:put({?MODULE, loop_list}, List).
get_loop_list() ->
    erlang:get({?MODULE, loop_list}).

set_max_collection_id(ID) ->
    erlang:put({?MODULE, max_collection_id}, ID).
get_max_collection_id() ->
    erlang:get({?MODULE, max_collection_id}).

set_collection_data(ID, Collection) ->
    erlang:put({?MODULE, collection_data, ID}, Collection).
get_collection_data(ID) ->
    erlang:get({?MODULE, collection_data, ID}).
del_collection_data(ID) ->
    erlang:erase({?MODULE, collection_data, ID}).

set_role_collection(RoleID, ID) ->
    erlang:put({?MODULE, role_collection, RoleID}, ID).
get_role_collection(RoleID) ->
    erlang:get({?MODULE, role_collection, RoleID}).
del_role_collection(RoleID) ->
    erlang:erase({?MODULE, role_collection, RoleID}).