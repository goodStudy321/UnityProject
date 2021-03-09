%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 六月 2017 9:48
%%%-------------------------------------------------------------------
-module(mod_collection_map).
-author("laijichang").
-include("collection.hrl").
-include("world_boss.hrl").
-include("proto/mod_map_collection.hrl").
-include("proto/mod_role_family_as.hrl").
-include("proto/mod_map_marry.hrl").

%% API
-export([
    collection_enter_map/1
]).

-export([
    collect_start/2,
    collect_stop/1,
    stop_role_collect/1
]).

-export([
    born_collections/1,
    add_marry_collect_times/2,
    del_marry_collect_times/2
]).

collection_enter_map(Collection) ->
    #r_collection{
        collect_id = ID,
        collect_name = Name,
        born_pos = RecordPos,
        type_id = TypeID
    } = Collection,
    [#c_collection{broadcast_missions = Missions}] = lib_config:find(cfg_collection, TypeID),
    MapInfo = #r_map_actor{
        actor_id = ID,
        actor_type = ?ACTOR_TYPE_COLLECTION,
        actor_name = Name,
        pos = map_misc:pos_encode(RecordPos),
        hp = 1,
        max_hp = 1,
        camp_id = ?DEFAULT_CAMP_ROLE,
        collection_extra = #p_map_collection{type_id = TypeID, broadcast_missions = Missions}},
    mod_map_collection:collection_enter_map(MapInfo).


%%%===================================================================
%%% from map start
%%%===================================================================
collect_start(RoleID, CollectID) ->
    case catch check_can_start(RoleID, CollectID) of
        {ok, NewCollection, CollectTime} ->
            mod_collection_data:set_collection_data(CollectID, NewCollection),
            mod_collection_data:set_role_collection(RoleID, CollectID),
            mod_collection_data:add_loop_list(CollectID),
            common_misc:unicast(RoleID, #m_collect_start_toc{collect_id = CollectID, collect_time = CollectTime});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_collect_start_toc{err_code = ErrCode,collect_id = CollectID})
    end.

check_can_start(RoleID, CollectID) ->
    case mod_collection_data:get_collection_data(CollectID) of
        #r_collection{type_id = TypeID, role_list = RoleList} = Collection ->
            case lists:keymember(RoleID, #r_collect_role.role_id, RoleList) of
                true -> ?THROW_ERR(?ERROR_COLLECT_START_002);
                _ -> ok
            end,
            MapID = map_common_dict:get_map_id(),
            #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
            CollectRole =
                if
                    ?IS_FAMILY_AS_CL(TypeID) ->
                        ASRoleList = mod_map_ets:get_family_as_collect_roles(),
                        ?IF(lists:member(RoleID, ASRoleList), ?THROW_ERR(?ERROR_FAMILY_AS_CL_001), ok),
                        #r_collect_role{role_id = RoleID};
                    ?IS_MAP_MARRY_FEAST(MapID) ->
                        check_marry_collect(RoleID, TypeID),
                        #r_collect_role{role_id = RoleID};
                    SubType =:= ?SUB_TYPE_MYTHICAL_BOSS ->
                        ReduceRate = check_mythical_collect(RoleID, TypeID, MapID),
                        #r_collect_role{role_id = RoleID, reduce_rate = ReduceRate};
                    SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
                        #r_collect_role{role_id = RoleID, reduce_rate = common_misc:get_global_int(?GLOBAL_ANCIENTS_REDUCE_RATE)};
                    true ->
                        #r_collect_role{role_id = RoleID}
                end,
            ?IF(mod_collection_data:get_role_collection(RoleID) =:= undefined, ok, ?THROW_ERR(?ERROR_COLLECT_START_002)),
            [#c_collection{collect_time = CollectTime, dis = Dis, collect_share = CollectShare}] = lib_config:find(cfg_collection, TypeID),
            #r_pos{mx = X1, my = Y1} = mod_map_ets:get_actor_pos(RoleID),
            #r_pos{mx = X2, my = Y2} = mod_map_ets:get_actor_pos(CollectID),
            ?IF(map_misc:get_dis(X1, Y1, X2, Y2) >= Dis + 100, ?THROW_ERR(?ERROR_COLLECT_START_004), ok),
            ?IF(RoleList =/= [] andalso not ?IS_COLLECT_IS_SHARE(CollectShare), ?THROW_ERR(?ERROR_COLLECT_START_003), ok),
            EndTime = time_tool:now_ms() + CollectTime,
            CollectRole2 = CollectRole#r_collect_role{role_id = RoleID, end_time = EndTime},
            RoleList2 = lists:keysort(#r_collect_role.end_time, [CollectRole2|RoleList]),
            Collection2 = Collection#r_collection{role_list = RoleList2},
            {ok, Collection2, CollectTime};
        _ ->
            {error, ?ERROR_COLLECT_START_001}
    end.

check_marry_collect(RoleID, TypeID) ->
    [HeatTypeID, _BornNum] = common_misc:get_global_list(?GLOBAL_MARRY_HEAT_COLLECT),
    #r_marry_collect{
        taste_times = TasteTimes,
        heat_collect_times = HeatTimes,
        heat_max_times = MaxTimes} = mod_map_ets:get_marry_role_collect(RoleID),
    IsTaste = marry_misc:is_taste_collection(TypeID),
    if
        IsTaste ->
            MaxTasteTimes = common_misc:get_global_int(?GLOBAL_MARRY_TASTE),
            ?IF(TasteTimes >= MaxTasteTimes, ?THROW_ERR(?ERROR_COLLECT_START_005), ok);
        HeatTypeID =:= TypeID ->
            ?IF(MaxTimes - HeatTimes > 0, ok, ?THROW_ERR(?ERROR_COLLECT_START_005));
        true ->
            ok
    end.

check_mythical_collect(RoleID, TypeID, MapID) ->
    #r_map_role{
        mythical_collect = CollectTimes,
        mythical_collect2 = Collect2Times
    } = mod_map_ets:get_map_role(RoleID),
    #c_mythical_refresh{collect_type_id = CollectTypeID} = world_boss_server:get_mythical_config(MapID),
    case CollectTypeID =:= TypeID of
        true ->
            [_UseTimes, ReduceHpRate|_] = common_misc:get_global_list(?GLOBAL_MYTHICAL_COLLECT),
            ?IF(CollectTimes > 0, ReduceHpRate, ?THROW_ERR(?ERROR_COLLECT_START_005));
        _ ->
            [_UseTimes, ReduceHpRate|_] = common_misc:get_global_list(?GLOBAL_MYTHICAL_COLLECT2),
            ?IF(Collect2Times > 0, ReduceHpRate, ?THROW_ERR(?ERROR_COLLECT_START_005))
    end.

collect_stop(RoleID) ->
    case catch stop_role_collect(RoleID) of
        not_found ->
            common_misc:unicast(RoleID, #m_collect_stop_toc{err_code = ?ERROR_COLLECT_START_001});
        _ ->
            ok
    end.

%% 可能会被map调用
stop_role_collect(RoleID) ->
    CollectID = mod_collection_data:get_role_collection(RoleID),
    case mod_collection_data:get_collection_data(CollectID) of
        #r_collection{role_list = RoleList} = Collection ->
            RoleList2 = lists:keydelete(RoleID, #r_collect_role.role_id, RoleList),
            Collection2 = Collection#r_collection{role_list = RoleList2},
            mod_collection_data:set_collection_data(CollectID, Collection2),
            mod_collection_data:del_role_collection(RoleID),
            common_misc:unicast(RoleID, #m_collect_stop_toc{collect_id = CollectID});
        _ ->
            not_found
    end.

born_collections(Collections) ->
    [ mod_collection:init_collection(Collection) || Collection <- Collections].

add_marry_collect_times(RoleList, AddTimes) ->
    [ begin
          #r_marry_collect{heat_collect_times = HeatTimes, heat_max_times = MaxTimes} = MarryCollect = mod_map_ets:get_marry_role_collect(RoleID),
          MaxTimes2 = MaxTimes + AddTimes,
          mod_map_ets:set_marry_role_collect(RoleID, MarryCollect#r_marry_collect{heat_max_times = MaxTimes2}),
          common_misc:unicast(RoleID, #m_marry_map_collect_toc{remain_times = MaxTimes2 - HeatTimes})
      end|| RoleID <- RoleList].

del_marry_collect_times(RoleList, DelTimes) ->
    [ begin
          #r_marry_collect{heat_collect_times = HeatTimes, heat_max_times = MaxTimes} = MarryCollect = mod_map_ets:get_marry_role_collect(RoleID),
          MaxTimes2 = MaxTimes - DelTimes,
          HeatTimes2 = erlang:max(HeatTimes - DelTimes, 0),
          mod_map_ets:set_marry_role_collect(RoleID, MarryCollect#r_marry_collect{heat_max_times = MaxTimes2, heat_collect_times = HeatTimes2}),
          common_misc:unicast(RoleID, #m_marry_map_collect_toc{remain_times = MaxTimes2 - HeatTimes2})
      end|| RoleID <- RoleList].
%%%===================================================================
%%% from map stop
%%%===================================================================


