-module(mod_map_slice).
-include("global.hrl").

%% slice
-export([
    init/0,
    map_server_init/0
]).

-export([
    get_slices_by_actor_list/1,
    get_9slices_roleids_by_pos/1
]).

-export([
    get_roleids_by_slices/1,
    get_monster_ids_by_slices/1,
    get_roles_by_slices/1,
    get_actors_ids_by_slices/1,
    get_p_actors_by_slices/2
]).

-export([
    get_slice_by_xy/2,
    get_9slices_by_xy/2,
    get_slice_by_pos/1,
    get_9slices_by_pos/1
]).

-export([
    slice_leave/3,
    slice_join/3
]).

%% ----------------------------------------------------------------
%% 初始化每个slice对应的九宫格,避免之后的重复计算
%% ----------------------------------------------------------------
init() ->
    init_slice_size().

map_server_init() ->
    {MapWidth, MapHeight} = map_base_data:map_size(),
    {SliceWidth, SliceHeight} = init_slice_size(),
    MaxSx = MapWidth div SliceWidth,
    MaxSy = MapHeight div SliceHeight,
    %% 初始化并缓存九宫格数据
    lists:foreach(
        fun(Sx) ->
            lists:foreach(
                fun(Sy) ->
                    Slice = #r_slice{slice_x = Sx, slice_y = Sy},
                    Slices9 = get_9slices_by_slice(MaxSx, MaxSy, Slice),
                    mod_map_ets:set_9slices(Slice, Slices9)
                end, lists:seq(0, MaxSy))
        end, lists:seq(0, MaxSx)).

init_slice_size() ->
    MapID = map_common_dict:get_map_id(),
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{map_type = ?MAP_TYPE_NORMAL, map_bc_size = BcSize}] -> %% 普通野外地图
            BcSize2 = erlang:min(erlang:max(?MAP_SLICE_WIDTH, BcSize), ?WILD_MAX_SLICE),
            SliceWidth = BcSize2,
            SliceHeight = BcSize2;
        [#c_map_base{map_type = ?MAP_TYPE_COPY, map_bc_size = BcSize}] ->
            BcSize2 = erlang:max(?MAP_SLICE_WIDTH, BcSize),
            SliceWidth = BcSize2,
            SliceHeight = BcSize2;
        _ ->
            SliceWidth = ?MAP_SLICE_WIDTH,
            SliceHeight = ?MAP_SLICE_HEIGHT
    end,
    mod_map_dict:set_slice_width(SliceWidth),
    mod_map_dict:set_slice_height(SliceHeight),
    {SliceWidth, SliceHeight}.

slice_leave(Slice, ActorID, ?ACTOR_TYPE_ROLE) ->
    mod_map_ets:set_slice_roles(Slice, lists:delete(ActorID, mod_map_ets:get_slice_roles(Slice)));
slice_leave(Slice, ActorID, ?ACTOR_TYPE_MONSTER) ->
    mod_map_ets:set_slice_monsters(Slice, lists:delete(ActorID, mod_map_ets:get_slice_monsters(Slice)));
slice_leave(Slice, ActorID, ?ACTOR_TYPE_COLLECTION) ->
    mod_map_ets:set_slice_collections(Slice, lists:delete(ActorID, mod_map_ets:get_slice_collections(Slice)));
slice_leave(Slice, ActorID, ?ACTOR_TYPE_TRAP) ->
    mod_map_ets:set_slice_traps(Slice, lists:delete(ActorID, mod_map_ets:get_slice_traps(Slice)));
slice_leave(Slice, ActorID, ?ACTOR_TYPE_DROP) ->
    mod_map_ets:set_slice_drops(Slice, lists:delete(ActorID, mod_map_ets:get_slice_drops(Slice)));
slice_leave(Slice, ActorID, ?ACTOR_TYPE_ROBOT) ->
    mod_map_ets:set_slice_robots(Slice, lists:delete(ActorID, mod_map_ets:get_slice_robots(Slice))).

slice_join(Slice, ActorID, ?ACTOR_TYPE_ROLE) ->
    mod_map_ets:set_slice_roles(Slice, [ActorID|mod_map_ets:get_slice_roles(Slice)]);
slice_join(Slice, ActorID, ?ACTOR_TYPE_MONSTER) ->
    mod_map_ets:set_slice_monsters(Slice, [ActorID|mod_map_ets:get_slice_monsters(Slice)]);
slice_join(Slice, ActorID, ?ACTOR_TYPE_COLLECTION) ->
    mod_map_ets:set_slice_collections(Slice, [ActorID|mod_map_ets:get_slice_collections(Slice)]);
slice_join(Slice, ActorID, ?ACTOR_TYPE_TRAP) ->
    mod_map_ets:set_slice_traps(Slice, [ActorID|mod_map_ets:get_slice_traps(Slice)]);
slice_join(Slice, ActorID, ?ACTOR_TYPE_DROP) ->
    mod_map_ets:set_slice_drops(Slice, [ActorID|mod_map_ets:get_slice_drops(Slice)]);
slice_join(Slice, ActorID, ?ACTOR_TYPE_ROBOT) ->
    mod_map_ets:set_slice_robots(Slice, [ActorID|mod_map_ets:get_slice_robots(Slice)]).

get_slices_by_actor_list(ActorList) ->
    lists:foldl(
        fun(ActorID, Acc) ->
            case mod_map_ets:get_actor_pos(ActorID) of
                #r_pos{}=Pos ->
                    case get_9slices_by_pos(Pos) of
                        undefined ->
                            Acc;
                        Slices ->
                            lib_tool:combine_lists(Acc, Slices)
                    end;
                _ ->
                    Acc
            end
        end, [], ActorList).
%% ----------------------------------------------------------------
%% 根据格子查找对应的角色
%% ----------------------------------------------------------------
get_9slices_roleids_by_pos(Pos) ->
    get_roleids_by_slices(get_9slices_by_pos(Pos)).

get_roleids_by_slices(Slices) ->
    lists:foldl(fun(Slice, Acc) -> mod_map_ets:get_slice_roles(Slice) ++ Acc end, [], Slices).

get_monster_ids_by_slices(Slices) ->
    lists:foldl(fun(Slice, Acc) -> mod_map_ets:get_slice_monsters(Slice) ++ Acc end, [], Slices).

get_roles_by_slices(Slices) ->
    lists:foldl(
        fun(Slice, Acc1) ->
            MapInfosAcc =
                lists:foldr(
                    fun(ActorID, Acc2) ->
                        case mod_map_ets:get_actor_mapinfo(ActorID) of
                            #r_map_actor{} = MapInfo ->
                                [MapInfo|Acc2];
                            _ ->
                                ?ERROR_MSG("error mapinfo not found:~w", [ActorID]),
                                Acc2
                        end
                    end, [], mod_map_ets:get_slice_roles(Slice)),
            MapInfosAcc ++ Acc1
        end, [], Slices).

get_actors_ids_by_slices(Slices) ->
    lists:foldl(
        fun(Slice, Acc) ->
            get_slice_actors_ids(Slice) ++ Acc end
        , [], Slices).

get_slice_actors_ids(Slice) ->
    mod_map_ets:get_slice_roles(Slice) ++ mod_map_ets:get_slice_monsters(Slice) ++
        mod_map_ets:get_slice_collections(Slice) ++ mod_map_ets:get_slice_traps(Slice) ++
        mod_map_ets:get_slice_drops(Slice) ++ mod_map_ets:get_slice_robots(Slice).

get_p_actors_by_slices(RoleID, Slices) ->
    Collections = get_role_collections(RoleID, Slices),
    Drops = get_role_drops(RoleID, Slices),
    lists:foldl(
        fun(Slice, Acc1) ->
            OtherIDs = mod_map_ets:get_slice_roles(Slice) ++ mod_map_ets:get_slice_monsters(Slice) ++
                mod_map_ets:get_slice_traps(Slice) ++ mod_map_ets:get_slice_robots(Slice),
            MapInfosAcc =
                lists:foldr(
                    fun(ActorID, Acc2) ->
                        case mod_map_ets:get_actor_mapinfo(ActorID) of
                            #r_map_actor{} = MapInfo ->
                                [map_misc:make_p_map_actor(MapInfo)|Acc2];
                            _ ->
                                ?ERROR_MSG("error mapinfo not found:~w", [ActorID]),
                                Acc2
                        end
                    end, [], OtherIDs),
            MapInfosAcc ++ Acc1
        end, Drops ++ Collections, Slices).

%% 获取该玩家的场景掉落
get_role_drops(RoleID, Slices) ->
    lists:foldl(
        fun(Slice, Acc1) ->
            MapInfosAcc =
                lists:foldl(
                    fun(ActorID, Acc2) ->
                        case mod_map_ets:get_actor_mapinfo(ActorID) of
                            #r_map_actor{drop_extra = #p_map_drop{broadcast_roles = BroadcastRoles}} = MapInfo ->
                                %% 如果这个广播人群是特定的，那么要进行一个筛选
                                ?IF(BroadcastRoles =:= [] orelse lists:member(RoleID, BroadcastRoles),
                                    [map_misc:make_p_map_actor(MapInfo)|Acc2],
                                    Acc2);
                            _ ->
                                ?ERROR_MSG("error mapinfo not found:~w", [ActorID]),
                                Acc2
                        end
                    end, [], mod_map_ets:get_slice_drops(Slice)),
            MapInfosAcc ++ Acc1
        end, [], Slices).

%% 获取该玩家的采集物
get_role_collections(RoleID, Slices) ->
    #r_map_role{missions = RoleMissions} = mod_map_ets:get_map_role(RoleID),
    lists:foldl(
        fun(Slice, Acc1) ->
            MapInfosAcc =
                lists:foldl(
                    fun(ActorID, Acc2) ->
                        case mod_map_ets:get_actor_mapinfo(ActorID) of
                            #r_map_actor{collection_extra = #p_map_collection{broadcast_missions = Missions}} = MapInfo ->
                                case Missions =:= [] orelse (Missions -- RoleMissions) =:= [] of
                                    true ->
                                        [map_misc:make_p_map_actor(MapInfo)|Acc2];
                                    _ ->
                                        Acc2
                                end;
                            _ ->
                                ?ERROR_MSG("error mapinfo not found:~w", [ActorID]),
                                Acc2
                        end
                    end, [], mod_map_ets:get_slice_collections(Slice)),
            MapInfosAcc ++ Acc1
        end, [], Slices).


%% ----------------------------------------------------------------
%% 获取九宫格
%% ----------------------------------------------------------------
%%根据格子或者像素位置获得所在的slice名称
get_slice_by_xy(Tx, Ty) ->
    get_slice_by_pos(map_misc:get_pos_by_tile(Tx, Ty)).

%% 根据坐标获得九宫格 slice
get_slice_by_pos(#r_pos{mx = Mx, my = My}) ->
    Sx = Mx div mod_map_dict:get_slice_width(),
    Sy = My div mod_map_dict:get_slice_height(),
    #r_slice{slice_x = Sx, slice_y = Sy}.

%% 根据格子所在位置获得九宫格slice
get_9slices_by_xy(Tx, Ty) ->
    get_9slices_by_pos(map_misc:get_pos_by_tile(Tx, Ty)).
%% 根据米坐标获得九宫格 slice
get_9slices_by_pos(Pos) ->
    mod_map_ets:get_9slices(get_slice_by_pos(Pos)).

%% 初始化时用来计算
get_9slices_by_slice(MaxSx, MaxSy, #r_slice{slice_x = Sx, slice_y = Sy}) ->
    BeginX = get_begin_value(Sx),
    BeginY = get_begin_value(Sy),
    EndX = get_end_value(Sx, MaxSx),
    EndY = get_end_value(Sy, MaxSy),
    get_9slices_by_slice2(BeginX, BeginY, EndX, EndY).
get_9slices_by_slice2(BeginX, BeginY, EndX, EndY) ->
    lists:foldl(
        fun(TempSX, Acc) ->
            lists:foldl(
                fun(TempSY, AccSub) ->
                    Temp = #r_slice{slice_x = TempSX, slice_y = TempSY},
                    [Temp | AccSub]
                end, Acc, lists:seq(BeginY, EndY))
        end, [], lists:seq(BeginX, EndX)).

get_begin_value(Val) ->
    ?IF(Val > 0, Val - 1, 0).
get_end_value(Val, MaxVal) ->
    ?IF(Val >= MaxVal, MaxVal, Val + 1).
