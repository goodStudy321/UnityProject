%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 六月 2017 17:21
%%%-------------------------------------------------------------------
-module(mod_map_collection).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_map_collection.hrl").

%% API
-export([
    collection_enter_map/1,
    collection_leave_map/3,
    collection_reduce_hp/3
]).

-export([
    born_collections/1,
    del_marry_collect/1,
    born_marry_collections/0,
    born_mythical_collect/1,
    role_reduce_hp/2,
    role_dead/1,
    role_leave_map/1,
    add_marry_collect_times/2,
    del_marry_collect_times/2
]).

-export([
    handle/1
]).

%% API
%% mod_map_actor回调actor模块下的接口（如果存在对应接口的话）
-export([
    leave_map/1
]).

%%%===================================================================
%%% mod_collection 调用 start
%%%===================================================================
collection_enter_map(MapInfo) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:enter_map(MapInfo, undefined, []) end).

collection_leave_map(ActorID, TypeID, IsCollect) ->
     map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:leave_map(ActorID, [TypeID, IsCollect]) end).

collection_reduce_hp(RoleID, FromActorID, ReduceHpRate) ->
    #r_map_actor{max_hp = MaxHp} = mod_map_ets:get_actor_mapinfo(RoleID),
    ReduceHp = lib_tool:ceil(MaxHp * ReduceHpRate/?RATE_10000),
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:buff_reduce_hp(RoleID, FromActorID, ReduceHp, ?BUFF_POISON, 0) end).

%%%===================================================================
%%% mod_collection 调用 end
%%%===================================================================


%%%===================================================================
%%% mod_map_actor 回调 start
%%%===================================================================
leave_map({MapActor, [TypeID, IsCollect]}) ->
    #r_map_actor{actor_id = ActorID} = MapActor,
    hook_map:collection_leave_map(ActorID, TypeID, IsCollect).

%%%===================================================================
%%% mod_map_actor 回调 end
%%%===================================================================

handle({#m_collect_start_tos{collect_id = CollectID}, RoleID, _PID}) ->
    do_collect_start(RoleID, CollectID);
handle({#m_collect_stop_tos{}, RoleID, _PID}) ->
    do_collect_stop(RoleID);
handle(Info) ->
    ?ERROR_MSG("unknow info:~w", [Info]).

do_collect_start(RoleID, CollectID) ->
    case mod_map_ets:get_actor_mapinfo(CollectID) of
        #r_map_actor{actor_type = ?ACTOR_TYPE_COLLECTION} ->
            info_collection_pid({func, fun() -> mod_collection_map:collect_start(RoleID, CollectID) end});
        _ ->
            %%前端需求错误码和采集ID一起返回
            common_misc:unicast(RoleID, #m_collect_start_toc{err_code = ?ERROR_COLLECT_START_001,collect_id = CollectID})
    end.

do_collect_stop(RoleID) ->
    info_collection_pid({func, fun() -> mod_collection_map:collect_stop(RoleID) end}).

born_collections(Collections) ->
    info_collection_pid({func, fun() -> mod_collection_map:born_collections(Collections) end}).

del_marry_collect(IndexID) ->
    info_collection_pid({func, fun() -> mod_collection:del_marry_collect(IndexID) end}).

born_marry_collections() ->
    info_collection_pid({func, fun() -> mod_collection:born_marry_collections() end}).

born_mythical_collect(Args) ->
    info_collection_pid({func, fun() -> mod_collection:born_mythical_collect(Args) end}).

role_reduce_hp(RoleID, ReduceSrc) ->
    #r_reduce_src{actor_type = SrcActorType} = ReduceSrc,
    ?IF(SrcActorType =:= ?ACTOR_TYPE_ROLE, info_collection_pid({func, fun() -> mod_collection_map:stop_role_collect(RoleID) end}), ok).

role_dead(RoleID) ->
    info_collection_pid({func, fun() -> mod_collection_map:stop_role_collect(RoleID) end}).

role_leave_map(RoleID) ->
    info_collection_pid({func, fun() -> mod_collection_map:stop_role_collect(RoleID) end}).

add_marry_collect_times(RoleList, Times) ->
    info_collection_pid({func, fun() -> mod_collection_map:add_marry_collect_times(RoleList, Times) end}).

del_marry_collect_times(RoleList, Times) ->
    info_collection_pid({func, fun() -> mod_collection_map:del_marry_collect_times(RoleList, Times) end}).

info_collection_pid(Info) ->
    pname_server:send(mod_map_dict:get_collection_pid(), Info).






