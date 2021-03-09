%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_monster_data).
-author("laijichang").
-include("monster.hrl").

%% API
-export([
    init/1
]).

%% mod_monster
-export([
    set_loop_counter/1,
    get_loop_counter/0,

    add_counter_monster/2,
    del_counter_monster/2,
    set_counter_monsters/2,
    get_counter_monsters/1,
    erase_counter_monsters/1,

    add_monster_id/1,
    del_monster_id/1,
    set_monster_id_list/1,
    get_monster_id_list/0,

    add_hatred/1,
    del_hatred/1,
    set_hatred_id_list/1,
    get_hatred_id_list/0,

    add_world_boss/1,
    del_world_boss/1,
    set_world_boss_id_list/1,
    get_world_boss_id_list/0,

    set_monster_data/2,
    get_monster_data/1,
    del_monster_data/1,

    get_new_monster_id/0
]).

-export([
    del_monster_buff_list/1,
    set_monster_buff_list/1,
    get_monster_buff_list/0
]).

-export([
    set_monster_silver_list/1,
    get_monster_silver_list/0
]).

-export([
    get_seq_tiles/1,
    set_seq_tiles/2
]).
%%%===================================================================
%%% API
%%%===================================================================
init(MapID) ->
    set_loop_counter(1),
    set_max_monster_id(common_id:get_monster_start_id(MapID) + 1),
    set_monster_id_list([]),
    set_hatred_id_list([]),
    set_world_boss_id_list([]),
    set_monster_buff_list([]),
    set_monster_silver_list([]).

get_new_monster_id()->
    NewID = get_max_monster_id(),
    set_max_monster_id(common_id:get_monster_next_id(NewID)),
    case mod_monster_data:get_monster_data(NewID) of
        #r_monster{} ->
            get_new_monster_id();
        _ ->
            NewID
    end.

%%%===================================================================
%%% mod_monster start
%%%===================================================================
set_loop_counter(Counter) ->
    erlang:put({?MODULE, loop_counter}, Counter).
get_loop_counter() ->
    erlang:get({?MODULE, loop_counter}).

add_counter_monster(MonsterID, Counter) ->
    set_counter_monsters(Counter, [MonsterID|get_counter_monsters(Counter)]).
del_counter_monster(MonsterID, Counter) ->
    set_counter_monsters(Counter, lists:delete(MonsterID, get_counter_monsters(Counter))).
set_counter_monsters(Counter, MonsterList) ->
    erlang:put({?MODULE, counter_monsters, Counter}, MonsterList).
get_counter_monsters(Counter) ->
    case erlang:get({?MODULE, counter_monsters, Counter}) of
        [_|_] = List -> List;
        _ -> []
    end.
erase_counter_monsters(Counter) ->
    erlang:erase({?MODULE, counter_monsters, Counter}).

add_monster_id(MonsterID) ->
    set_monster_id_list([MonsterID|get_monster_id_list()]).
del_monster_id(MonsterID) ->
    set_monster_id_list(lists:delete(MonsterID, get_monster_id_list())).
set_monster_id_list(MonsterList) ->
    erlang:put({?MODULE, monster_id_list}, MonsterList).
get_monster_id_list() ->
    erlang:get({?MODULE, monster_id_list}).

add_hatred(MonsterID) ->
    set_hatred_id_list([MonsterID|get_hatred_id_list()]).
del_hatred(MonsterID) ->
    set_hatred_id_list(lists:delete(MonsterID, get_hatred_id_list())).
set_hatred_id_list(MonsterList) ->
    erlang:put({?MODULE, hatred_id_list}, MonsterList).
get_hatred_id_list() ->
    erlang:get({?MODULE, hatred_id_list}).

add_world_boss(MonsterID) ->
    set_world_boss_id_list([MonsterID|get_world_boss_id_list()]).
del_world_boss(MonsterID) ->
    set_world_boss_id_list(lists:delete(MonsterID, get_world_boss_id_list())).
set_world_boss_id_list(MonsterList) ->
    erlang:put({?MODULE, world_boss_id_list}, MonsterList).
get_world_boss_id_list() ->
    erlang:get({?MODULE, world_boss_id_list}).

set_monster_data(MonsterID, #r_monster{} = MonsterData) ->
    OldMonsterData = erlang:put({?MODULE, monster_data, MonsterID}, MonsterData),
    ?TRY_CATCH(mod_monster:monster_data_change(OldMonsterData, MonsterData)).
get_monster_data(MonsterID) ->
    erlang:get({?MODULE, monster_data, MonsterID}).
del_monster_data(MonsterID) ->
    erlang:erase({?MODULE, monster_data, MonsterID}).

set_max_monster_id(MonsterID) ->
    erlang:put({?MODULE, max_monster_id}, MonsterID).
get_max_monster_id() ->
    erlang:get({?MODULE, max_monster_id}).
%%%===================================================================
%%% mod_monster end
%%%===================================================================

%%%===================================================================
%%% mod_monster_buff start
%%%===================================================================
del_monster_buff_list(MonsterID) ->
    MonsterList = get_monster_buff_list(),
    set_monster_buff_list(lists:delete(MonsterID, MonsterList)).
set_monster_buff_list(List) ->
    erlang:put({?MODULE, monster_buff_list}, List).
get_monster_buff_list() ->
    erlang:get({?MODULE, monster_buff_list}).

%%%===================================================================
%%% mod_monster_buff end
%%%===================================================================

%%%===================================================================
%%% mod_monster_silver start
%%%===================================================================
set_monster_silver_list(List) ->
    erlang:put({?MODULE, monster_silver_list}, List).
get_monster_silver_list() ->
    erlang:get({?MODULE, monster_silver_list}).

%%%===================================================================
%%% mod_monster_silver end
%%%===================================================================

%%%===================================================================
%%% other start
%%%===================================================================
set_seq_tiles(Seq, Tiles) ->
    erlang:put({?MODULE, seq_tiles, Seq}, Tiles).
get_seq_tiles(Seq) ->
    erlang:get({?MODULE, seq_tiles, Seq}).
%%%===================================================================
%%% other end
%%%===================================================================
