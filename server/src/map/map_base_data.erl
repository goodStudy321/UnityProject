
-module(map_base_data).
-include("global.hrl").

-export([
    init/1
]).

-export([
    info/1,
    offset/0,
    offset/1,
    is_exist/1,
    is_exist/2,
    is_exist/3,
    map_size/0,
    get_tile/2,
    get_map_module/1,
    get_map_type/1,
    get_born_points/1,
    get_jump_point/2
]).



init(MapID)->
    Mod = get_map_module(MapID),
    erlang:put(map_module, Mod).

get_map_module()->
    erlang:get(map_module).

get_map_module(MapID) ->
    [#c_map_base{data_id = DataID}] = lib_config:find(cfg_map_base, MapID),
    lib_tool:list_to_atom(lists:concat(["map_", DataID])).

%%list()->
%%    Module = get_map_module(),
%%    lib_config:find(Module, tiles).
%%
%%list(MapID)->
%%    Module = get_map_module(MapID),
%%    lib_config:find(Module, tiles).

info()->
    Module = get_map_module(),
    lib_config:find(Module, info).

offset() ->
    Module = get_map_module(),
    lib_config:find(Module, offset).

offset(MapID) ->
    Mod = get_map_module(MapID),
    lib_config:find(Mod, offset).

is_exist(Pos) when erlang:is_integer(Pos) ->
    #r_pos{tx = Tx, ty = Ty} = map_misc:pos_decode(Pos),
    is_exist(Tx, Ty);
is_exist(#r_pos{tx = Tx, ty = Ty}) ->
    is_exist(Tx, Ty).

is_exist(Tx, Ty)->
    case get_tile(Tx, Ty) of
        undefined -> false;
        _ -> true
    end.

%% 外部接口调用
is_exist(MapID, Tx, Ty) ->
    Mod = get_map_module(MapID),
    case Mod:find({Tx, Ty}) of
        undefined -> false;
        _ -> true
    end.


info(MapID)->
    Module = get_map_module(MapID),
    lib_config:find(Module, info).

map_size()->
    [{TileX, TileY}] = info(),
    {TileX * ?TILE_SIZE, TileY * ?TILE_SIZE}.

get_tile(Tx, Ty)->
    Mod = get_map_module(),
    Mod:find({Tx, Ty}).

get_map_type(MapID) ->
    [#c_map_base{map_type = MapType}] = lib_config:find(cfg_map_base, MapID),
    MapType.

get_born_points(MapID) ->
    Module = get_map_module(MapID),
    lib_config:find(Module, born_points).

get_jump_point(MapID, JumpID) ->
    Module = get_map_module(MapID),
    [JumpPoints] = lib_config:find(Module, jump_points),
    lists:keyfind(JumpID, #c_jump_point.jump_id, JumpPoints).





