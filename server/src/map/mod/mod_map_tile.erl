-module(mod_map_tile).

-include("global.hrl").

%% API
-export([
    ref_tile_pos/3,
    deref_tile_pos/3,
    is_empty/2
]).
-export([
    get_empty_tile_around/2]).

ref_tile_pos(ActorID, ActorType, #r_pos{tx = Tx, ty = Ty}) ->
    ref_tile_pos(ActorID, ActorType, Tx, Ty).
ref_tile_pos(ActorID, ActorType, Tx, Ty) ->
    List = mod_map_ets:get_tile_actors(Tx, Ty),
    case lists:member({ActorType, ActorID}, List) of
        true ->
            List2 = List;
        false ->
            List2 = [{ActorType, ActorID}|List]
    end,
    mod_map_ets:set_tile_actors(Tx, Ty, List2).

deref_tile_pos(ActorID, ActorType, #r_pos{tx = Tx, ty = Ty}) ->
    deref_tile_pos(ActorID, ActorType, Tx, Ty).
deref_tile_pos(ActorID, ActorType, Tx, Ty) ->
    case mod_map_ets:get_tile_actors(Tx, Ty) of
        [] ->
            ignore;
        List ->
            New = lists:delete({ActorType, ActorID}, List),
            mod_map_ets:set_tile_actors(Tx, Ty, New)
    end.

%% @doc 在指定点周围寻找一个最近可走点
get_empty_tile_around(Tx, Ty) ->
    case is_empty(Tx,Ty) of
        true->{Tx, Ty};
        false->get_empty_tile_around2(Tx, Ty)
    end.

get_empty_tile_around2(Tx, Ty) ->
    %% 半径为10格,找不到的话则返回原点
    case mod_spiral_search:get_walkable_pos(Tx, Ty, 10) of
        {error, _} ->
            {Tx, Ty};
        {Tx2, Ty2} ->
            {Tx2, Ty2}
    end.

%% 判断格子是否为空
is_empty(Tx, Ty)->
    case mod_map_ets:get_tile_actors(Tx, Ty) of
        [_|_]->false;
        _-> map_base_data:is_exist(Tx, Ty)
    end.

