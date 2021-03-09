%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2017 16:50
%%%-------------------------------------------------------------------
-module(mod_map_ets).
-author("laijichang").
-include("global.hrl").
-include("team.hrl").

%% API
-export([
    map_init/2,
    common_init/2,
    get_ets/1
]).

%% slice
-export([
    set_9slices/2,
    get_9slices/1,
    set_slice_roles/2,
    get_slice_roles/1,
    set_slice_monsters/2,
    get_slice_monsters/1,
    set_slice_collections/2,
    get_slice_collections/1,
    set_slice_traps/2,
    get_slice_traps/1,
    set_slice_drops/2,
    get_slice_drops/1,
    set_slice_robots/2,
    get_slice_robots/1,
    set_robot_enemies/2,
    del_robot_enemies/1,
    get_robot_enemies/1
]).

%% tile
-export([
    set_tile_actors/3,
    get_tile_actors/2
]).

%% actor
-export([
    set_actor_mapinfo/1,
    get_actor_mapinfo/1,
    del_actor_mapinfo/1,
    get_all_actor/0,

    set_actor_slice/2,
    get_actor_slice/1,
    del_actor_slice/1,
    set_actor_pos/2,
    get_actor_pos/1,
    del_actor_pos/1
]).

%% others
-export([
    set_in_map_roles/1,
    get_in_map_roles/0,

    set_pid2role/2,
    get_pid2role/1,
    del_pid2role/1,

    get_role_gpid/1,
    get_role_pid/1,
    set_map_role/2,
    get_map_role/1,
    erase_map_role/1,

    set_family_as_collect_roles/1,
    get_family_as_collect_roles/0,
    set_marry_role_collect/2,
    get_marry_role_collect/1,

    add_team_role/2,
    del_team_role/2,
    set_team_roles/2,
    get_team_roles/1
]).

map_init(MapID, ExtraID) ->
    [ begin
          EtsName = lib_tool:to_atom(lists:concat(["ets_map_", MapID, "_", ExtraID, "_", TabKey])),
          ets:new(EtsName, [named_table, set, public, {read_concurrency, true}, {keypos, Key}])
      end|| {TabKey, Key} <- ?ETS_LIST].

common_init(MapID, ExtraID) ->
    [ begin
          EtsName = lib_tool:to_atom(lists:concat(["ets_map_", MapID, "_", ExtraID, "_", TabKey])),
          set_ets(TabKey, EtsName)
      end|| {TabKey, _Key} <- ?ETS_LIST].

%%%===================================================================
%%% map slice start
%%%===================================================================
set_9slices(Slice, Slices) ->
    set_slice_data(Slice, Slices).
get_9slices(Slice) ->
    case get_slice_data(Slice) of
        [#r_map_kv{val = Slices}] -> Slices;
        _ -> []
    end.

set_slice_roles(Slice, Roles) ->
    case Roles of
        []-> del_misc_data({?MODULE, slice_roles, Slice});
        _-> set_misc_data({?MODULE, slice_roles, Slice}, Roles)
    end.
get_slice_roles(Slice) ->
    case get_misc_data({?MODULE, slice_roles, Slice}) of
        [#r_map_kv{val = Roles}] -> Roles;
        _ -> []
    end.

set_slice_monsters(Slice, Monsters) ->
    case Monsters of
        []-> del_misc_data({?MODULE, slice_monsters, Slice});
        _-> set_misc_data({?MODULE, slice_monsters, Slice}, Monsters)
    end.
get_slice_monsters(Slice) ->
    case get_misc_data({?MODULE, slice_monsters, Slice}) of
        [#r_map_kv{val = Monsters}] -> Monsters;
        _ -> []
    end.

set_slice_collections(Slice, Collections) ->
    case Collections of
        []-> del_misc_data({?MODULE, slice_collections, Slice});
        _-> set_misc_data({?MODULE, slice_collections, Slice}, Collections)
    end.
get_slice_collections(Slice) ->
    case get_misc_data({?MODULE, slice_collections, Slice}) of
        [#r_map_kv{val = Collections}] -> Collections;
        _ -> []
    end.

set_slice_traps(Slice, Traps) ->
    case Traps of
        []-> del_misc_data({?MODULE, slice_traps, Slice});
        _-> set_misc_data({?MODULE, slice_traps, Slice}, Traps)
    end.
get_slice_traps(Slice) ->
    case get_misc_data({?MODULE, slice_traps, Slice}) of
        [#r_map_kv{val = Traps}] -> Traps;
        _ -> []
    end.

set_slice_drops(Slice, Drops) ->
    case Drops of
        []-> del_misc_data({?MODULE, slice_drops, Slice});
        _-> set_misc_data({?MODULE, slice_drops, Slice}, Drops)
    end.
get_slice_drops(Slice) ->
    case get_misc_data({?MODULE, slice_drops, Slice}) of
        [#r_map_kv{val = Drops}] -> Drops;
        _ -> []
    end.

set_slice_robots(Slice, Robots) ->
    case Robots of
        []-> del_misc_data({?MODULE, slice_robots, Slice});
        _-> set_misc_data({?MODULE, slice_robots, Slice}, Robots)
    end.
get_slice_robots(Slice) ->
    case get_misc_data({?MODULE, slice_robots, Slice}) of
        [#r_map_kv{val = Robots}] -> Robots;
        _ -> []
    end.

get_robot_enemies(SrcID) ->
    case get_misc_data({?MODULE, robot_enemies, SrcID}) of
        [#r_map_kv{val = Enemies}] -> Enemies;
        _ -> []
    end.
set_robot_enemies(RoleID, Enemies) ->
    set_misc_data({?MODULE, robot_enemies, RoleID}, Enemies).
del_robot_enemies(RoleID) ->
    del_misc_data({?MODULE, robot_enemies, RoleID}).

%%%===================================================================
%%% map slice end
%%%===================================================================


%%%===================================================================
%%% map tile start
%%%===================================================================
set_tile_actors(Tx, Ty, Actors)->
    case Actors of
        []-> del_misc_data({?MODULE, tile, Tx, Ty});
        _-> set_misc_data({?MODULE, tile, Tx, Ty}, Actors)
    end.

get_tile_actors(Tx, Ty) ->
    case get_misc_data({?MODULE, tile, Tx, Ty}) of
        [#r_map_kv{val = Actors}] -> Actors;
        _ -> []
    end.
%%%===================================================================
%%% map tile end
%%%===================================================================


%%%===================================================================
%%% map actor start
%%%===================================================================
set_actor_mapinfo(MapInfo) ->
    set_actor_data(MapInfo).
get_actor_mapinfo(ActorID) ->
    case get_actor_data(ActorID) of
        [#r_map_actor{}= MapInfo] -> MapInfo;
        _ -> undefined
    end.
del_actor_mapinfo(ActorID) ->
    del_actor_data(ActorID).
get_all_actor() ->
    ets:tab2list(get_ets(?ACTORS_KEY)).


set_actor_slice(ActorID, Slice) ->
    set_misc_data({?MODULE, actor_slice, ActorID}, Slice).
get_actor_slice(ActorID) ->
    case get_misc_data({?MODULE, actor_slice, ActorID}) of
        [#r_map_kv{val = Slice}] -> Slice;
        _ -> undefined
    end.
del_actor_slice(ActorID) ->
    del_misc_data({?MODULE, actor_slice, ActorID}).

set_actor_pos(ActorID, Pos) ->
    set_misc_data({?MODULE, actor_pos, ActorID}, Pos).
get_actor_pos(ActorID) ->
    case get_misc_data({?MODULE, actor_pos, ActorID}) of
        [#r_map_kv{val = ActorPos}] -> ActorPos;
        _ -> undefined
    end.
del_actor_pos(ActorID) ->
    del_misc_data({?MODULE, actor_pos, ActorID}).
%%%===================================================================
%%% map actor end
%%%===================================================================


%%%===================================================================
%%% map role start
%%%===================================================================
set_in_map_roles(RoleIDList) ->
    set_misc_data({?MODULE, in_map_roles}, RoleIDList).
get_in_map_roles() ->
    case get_misc_data({?MODULE, in_map_roles}) of
        [#r_map_kv{val = List}] -> List;
        _ -> []
    end.

set_pid2role(PID, RoleID)->
    set_misc_data({?MODULE, pid2roleid, PID}, RoleID).
get_pid2role(PID)->
    case get_misc_data({?MODULE, pid2roleid, PID}) of
        [#r_map_kv{val = RoleID}] -> RoleID;
        _ -> undefined
    end.
del_pid2role(PID)->
    del_misc_data({?MODULE, pid2roleid, PID}).

get_role_gpid(RoleID) ->
    #r_map_role{gateway_pid = GatewayPID} = get_map_role(RoleID),
    GatewayPID.

get_role_pid(RoleID) ->
    #r_map_role{role_pid = RolePID} = get_map_role(RoleID),
    RolePID.

set_map_role(RoleID, MapRole) ->
    set_misc_data({?MODULE, map_role, RoleID}, MapRole).
get_map_role(RoleID) ->
    case get_misc_data({?MODULE, map_role, RoleID}) of
        [#r_map_kv{val = Val}] -> Val;
        _ -> #r_map_role{role_id = RoleID}
    end.
erase_map_role(RoleID) ->
    del_misc_data({?MODULE, map_role, RoleID}).

%% collection进程会写
set_family_as_collect_roles(Roles) ->
    set_misc_data({?MODULE, family_as_collect_roles}, Roles).
get_family_as_collect_roles() ->
    case get_misc_data({?MODULE, family_as_collect_roles}) of
        [#r_map_kv{val = List}] -> List;
        _ -> []
    end.

%% collection进程会写
set_marry_role_collect(RoleID, RoleCollect) ->
    set_misc_data({?MODULE, marry_role_collect, RoleID}, RoleCollect).
get_marry_role_collect(RoleID) ->
    case get_misc_data({?MODULE, marry_role_collect, RoleID}) of
        [#r_map_kv{val = Val}] -> Val;
        _ -> #r_marry_collect{role_id = RoleID}
    end.


add_team_role(TeamID, RoleID) when ?HAS_TEAM(TeamID) ->
    RoleList = get_team_roles(TeamID),
    case lists:member(RoleID, RoleList) of
        true ->
            ok;
        _ ->
            set_team_roles(TeamID, [RoleID|RoleList])
    end;
add_team_role(_TeamID, _RoleID) ->
    ok.

del_team_role(TeamID, RoleID) when ?HAS_TEAM(TeamID) ->
    RoleList = get_team_roles(TeamID),
    RoleList2 = lists:delete(RoleID, RoleList),
    case RoleList2 =/= [] of
        true ->
            set_team_roles(TeamID, RoleList2);
        _ ->
            del_misc_data({?MODULE, team_roles, TeamID})
    end;
del_team_role(_TeamID, _RoleID) ->
    ok.

set_team_roles(TeamID, RoleList) ->
    set_misc_data({?MODULE, team_roles, TeamID}, RoleList).
get_team_roles(TeamID) ->
    case get_misc_data({?MODULE, team_roles, TeamID}) of
        [#r_map_kv{val = Val}] -> Val;
        _ -> []
    end.

%%%===================================================================
%%% map role end
%%%===================================================================


%%%===================================================================
%%% ets
%%%===================================================================
set_ets(TabKey, Name) ->
    erlang:put({?MODULE, ets, TabKey}, Name).
get_ets(TabKey) ->
    erlang:get({?MODULE, ets, TabKey}).

get_ets_data(TabKey, Key) ->
    ets:lookup(get_ets(TabKey), Key).
set_ets_data(TabKey, Val) ->
    ets:insert(get_ets(TabKey), Val).
del_ets_data(TabKey, Key) ->
    ets:delete(get_ets(TabKey), Key).

set_slice_data(Key, Val) ->
    set_ets_data(?SLICES_KEY, #r_map_kv{key = Key, val = Val}).
get_slice_data(Key) ->
    get_ets_data(?SLICES_KEY, Key).

%% actor_ets
set_actor_data(Val) ->
    set_ets_data(?ACTORS_KEY, Val).
get_actor_data(Key) ->
    get_ets_data(?ACTORS_KEY, Key).
del_actor_data(Key) ->
    del_ets_data(?ACTORS_KEY, Key).

%% misc_ets
set_misc_data(Key, Val) ->
    set_ets_data(?MISC_KEY, #r_map_kv{key = Key, val = Val}).
get_misc_data(Key) ->
    get_ets_data(?MISC_KEY, Key).
del_misc_data(Key) ->
    del_ets_data(?MISC_KEY, Key).