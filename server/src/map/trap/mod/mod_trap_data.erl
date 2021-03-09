%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2017 19:05
%%%-------------------------------------------------------------------
-module(mod_trap_data).
-author("laijichang").
-include("trap.hrl").

%% API
-export([
    init/1
]).

%% mod_trap
-export([
    set_loop_counter/1,
    get_loop_counter/0,

    add_counter_trap/1,
    add_counter_trap/2,
    set_counter_traps/2,
    get_counter_traps/1,
    erase_counter_traps/1,

    set_trap_id_list/1,
    get_trap_id_list/0,

    set_trap_data/2,
    get_trap_data/1,
    del_trap_data/1,

    get_new_trap_id/0
]).

%%%===================================================================
%%% API
%%%===================================================================
init(MapID) ->
    set_loop_counter(1),
    set_max_trap_id(common_id:get_trap_start_id(MapID) + 1).

get_new_trap_id()->
    NewID = get_max_trap_id(),
    set_max_trap_id(common_id:get_trap_next_id(NewID)),
    case mod_trap_data:get_trap_data(NewID) of
        #r_trap{} ->
            get_new_trap_id();
        _ ->
            NewID
    end.

%%%===================================================================
%%% mod_trap start
%%%===================================================================
set_loop_counter(Counter) ->
    erlang:put({?MODULE, loop_counter}, Counter).
get_loop_counter() ->
    erlang:get({?MODULE, loop_counter}).

add_counter_trap(TrapID) ->
    add_counter_trap(TrapID, get_loop_counter() + ?TRAP_WORK_COUNTER).
add_counter_trap(TrapID, Counter) ->
    set_counter_traps(Counter, [TrapID|get_counter_traps(Counter)]).

set_counter_traps(Counter, TrapList) ->
    erlang:put({?MODULE, counter_traps, Counter}, TrapList).
get_counter_traps(Counter) ->
    case erlang:get({?MODULE, counter_traps, Counter}) of
        [_|_] = List -> List;
        _ -> []
    end.
erase_counter_traps(Counter) ->
    erlang:erase({?MODULE, counter_traps, Counter}).

set_trap_id_list(TrapList) ->
    erlang:put({?MODULE, trap_id_list}, TrapList).
get_trap_id_list() ->
    erlang:get({?MODULE, trap_id_list}).

set_trap_data(TrapID, TrapData) ->
    erlang:put({?MODULE, trap_data, TrapID}, TrapData).
get_trap_data(TrapID) ->
    erlang:get({?MODULE, trap_data, TrapID}).
del_trap_data(TrapID) ->
    erlang:erase({?MODULE, trap_data, TrapID}).

set_max_trap_id(TrapID) ->
    erlang:put({?MODULE, max_trap_id}, TrapID).
get_max_trap_id() ->
    erlang:get({?MODULE, max_trap_id}).
%%%===================================================================
%%% mod_trap end
%%%===================================================================