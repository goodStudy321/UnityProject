%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 六月 2017 15:29
%%%-------------------------------------------------------------------
-module(mod_collection).
-author("laijichang").
-include("mission.hrl").
-include("collection.hrl").
-include("world_boss.hrl").
-include("proto/mod_map_collection.hrl").
-include("proto/mod_map_marry.hrl").

%% API
-export([
    init/1,
    loop_ms/1
]).

-export([
    init_collection/1,
    del_marry_collect/1,
    born_marry_collections/0,
    born_mythical_collect/1
]).

-export([
    get_collection_name/1
]).

init(MapID) ->
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{seqs = Seqs}] ->
            [begin
                 case lib_config:find(cfg_map_seq, SeqID) of
                     [#c_map_seq{collection_type_id = TypeID} = Seq] when TypeID > 0 ->
                         #c_map_seq{create_num = CreateNum, min_point = MinPoint, max_point = MaxPoint} = Seq,
                         [begin
                              BornPos = map_misc:get_seq_born_pos(MinPoint, MaxPoint),
                              Collection = #r_collection{
                                  seq_id = SeqID,
                                  born_pos = BornPos,
                                  type_id = TypeID},
                              case ?TRY_CATCH(init_collection(Collection)) of
                                  ok ->
                                      ok;
                                  _ ->
                                      ?ERROR_MSG("配置有误 Seq : ~w", [Seq])
                              end
                          end || _ <- lists:seq(1, CreateNum)];
                     _ ->
                         ok
                 end
             end || SeqID <- Seqs];
        _ ->
            ok
    end.

loop_ms(NowMs) ->
    IDList = mod_collection_data:get_loop_list(),
    DelIDList =
    lists:foldl(
        fun(ID, Acc) ->
            #r_collection{role_list = RoleList} = Collection = mod_collection_data:get_collection_data(ID),
            case catch try_collection_reward(RoleList, NowMs, Collection) of
                {ok, Collection2} ->
                    mod_collection_data:set_collection_data(ID, Collection2),
                    Acc;
                {empty_role, Collection2} ->
                    mod_collection_data:set_collection_data(ID, Collection2),
                    [ID|Acc];
                {delete, RemainList} ->
                    delete_collection(Collection, RemainList, true),
                    [ID|Acc];
                Error ->
                    ?ERROR_MSG("collect loop error:~w", [Error]),
                    mod_collection_data:set_collection_data(ID, Collection#r_collection{role_list = []}),
                    [ID|Acc]
            end
        end, [], IDList),
    ?IF(DelIDList =/= [], mod_collection_data:del_loop_list(DelIDList), ok).

try_collection_reward([], _NowMs, Collection) ->
    {empty_role, Collection};
try_collection_reward([Role|R], NowMs, Collection) ->
    #r_collection{
        collect_id = CollectID,
        type_id = TypeID,
        times = Times} = Collection,
    Role2 = reduce_role_hp(Role, CollectID, NowMs),
    #r_collect_role{
        role_id = RoleID,
        end_time = EndTime} = Role2,
    case NowMs >= EndTime of
        true -> %% 采集时间到
            [#c_collection{reward = Reward}] = lib_config:find(cfg_collection, TypeID),
            ?IF(Reward =/= "", do_role_reward(RoleID, Reward), ok),
            mod_collection_data:del_role_collection(RoleID),
            mod_role_mission:trigger_mission(RoleID, ?MISSION_COLLECT, TypeID, 1),
            try_collection_reward2(RoleID, TypeID),
            common_misc:unicast(RoleID, #m_collect_succ_toc{collect_id = CollectID}),
            NewTimes = Times - 1,
            case NewTimes =< 0 of
                true ->
                    {delete, R};
                _ ->
                    Collection2 = Collection#r_collection{role_list = R, times = NewTimes},
                    try_collection_reward(R, NowMs, Collection2)
            end;
        _ ->
            Collection2 = Collection#r_collection{role_list = [Role2|R]},
            {ok, Collection2}
    end.

try_collection_reward2(RoleID, TypeID) ->
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        ?IS_FAMILY_AS_CL(TypeID) ->
            RoleList = mod_map_ets:get_family_as_collect_roles(),
            mod_map_ets:set_family_as_collect_roles([RoleID|RoleList]),
            mod_role_family_as:role_collect(RoleID);
        ?IS_MAP_MARRY_FEAST(MapID) ->
            [HeatTypeID, _BornNum] = common_misc:get_global_list(?GLOBAL_MARRY_HEAT_COLLECT),
            #r_marry_collect{
                taste_times = TasteTimes,
                heat_collect_times = HeatTimes,
                heat_max_times = HeatMaxTimes} = MarryCollect = mod_map_ets:get_marry_role_collect(RoleID),
            IsTaste = marry_misc:is_taste_collection(TypeID),
            if
                IsTaste ->
                    TasteTimes2 = TasteTimes + 1,
                    common_misc:unicast(RoleID, #m_marry_map_taste_times_toc{taste_times = TasteTimes2}),
                    mod_map_ets:set_marry_role_collect(RoleID, MarryCollect#r_marry_collect{taste_times = TasteTimes2});
                HeatTypeID =:= TypeID ->
                    %% 有可能出现采集途中更新次数
                    HeatTimes2 = HeatTimes + 1,
                    common_misc:unicast(RoleID, #m_marry_map_collect_toc{remain_times = HeatMaxTimes - HeatTimes2}),
                    mod_map_ets:set_marry_role_collect(RoleID, MarryCollect#r_marry_collect{heat_collect_times = HeatTimes2});
                true ->
                    MarryCollect
            end;
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS -> %% 神兽岛采集
            mod_role_world_boss:add_mythical_collect(RoleID, MapID, TypeID);
        SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 远古遗迹采集
            #c_ancients_refresh{collect_reduce_time = ReduceTime} = world_boss_server:get_ancients_config(MapID),
            mod_role_world_boss:add_ancients_time(RoleID, ReduceTime);
        true ->
            ok
    end.

do_role_reward(RoleID, Reward) ->
    WeightList = [ {Weight, {TypeID, Num}}|| {Weight, TypeID, Num} <- lib_tool:string_to_intlist(Reward)],
    {TypeID, Num} = lib_tool:get_weight_output(WeightList),
    GoodsList = [#p_goods{type_id = TypeID, num = Num}],
    role_misc:online_give_goods(RoleID, ?ITEM_GAIN_FAMILY_ANSWER, GoodsList).

reduce_role_hp(Role, CollectID, NowMs) ->
    #r_collect_role{
        role_id = RoleID,
        reduce_rate = ReduceRate,
        next_reduce_time = NextReduceTime} = Role,
    case ReduceRate > 0 andalso NowMs >= NextReduceTime of
        true ->
            mod_map_collection:collection_reduce_hp(RoleID, CollectID, ReduceRate),
            Role#r_collect_role{next_reduce_time = NowMs + ?SECOND_MS};
        _ ->
            Role
    end.

delete_collection(Collection, RemainList) ->
    delete_collection(Collection, RemainList, false).
delete_collection(Collection, RemainList, IsCollect) ->
    #r_collection{
        collect_id = CollectID,
        type_id = TypeID,
        seq_id = SeqID} = Collection,
    mod_collection_data:del_collection_data(CollectID),
    mod_collection_data:del_collection_id(CollectID),
    mod_collection_data:del_loop_list([CollectID]),
    DataRecord = #m_collect_start_toc{err_code = ?ERROR_COLLECT_START_006, collect_id = CollectID},
    [begin
         mod_collection_data:del_role_collection(OtherRoleID),
         common_misc:unicast(OtherRoleID, DataRecord)  %% @todo
     end || #r_collect_role{role_id = OtherRoleID} <- RemainList],
    mod_map_collection:collection_leave_map(CollectID, TypeID, IsCollect),
    do_refresh(SeqID).

do_refresh(SeqID) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [#c_map_seq{collection_type_id = TypeID, refresh_interval = Refresh} = Seq] when TypeID > 0 andalso Refresh > 0 ->
            #c_map_seq{min_point = MinPoint, max_point = MaxPoint} = Seq,
            BornPos = map_misc:get_seq_born_pos(MinPoint, MaxPoint),
            MonsterData = #r_collection{
                seq_id = SeqID,
                born_pos = BornPos,
                type_id = TypeID},
            erlang:send_after(Refresh * 1000, self(), {func, fun() -> ?MODULE:init_collection(MonsterData) end});
        _ ->
            ok
    end.

init_collection(Collection) ->
    NewID = mod_collection_data:get_new_collection_id(),
    [#c_collection{name = Name, times = Times}] = lib_config:find(cfg_collection, Collection#r_collection.type_id),
    Collection2 = Collection#r_collection{
        collect_id = NewID,
        collect_name = Name,
        times = Times},
    mod_collection_data:set_collection_data(NewID, Collection2),
    mod_collection_data:add_collection_id(NewID),
    mod_collection_map:collection_enter_map(Collection2),
    ok.

del_marry_collect(IndexID) ->
    CollectionList = mod_collection_data:get_collection_id_list(),
    [ begin
          #r_collection{role_list = RoleList, index_id = IndexIDT} = Collection = mod_collection_data:get_collection_data(CollectionID),
          ?IF(IndexID =:= IndexIDT, delete_collection(Collection, RoleList), ok)
      end|| CollectionID <- CollectionList].

born_marry_collections() ->
    CollectionList = mod_collection_data:get_collection_id_list(),
    TasteList = common_misc:get_global_list(?GLOBAL_MARRY_TASTE),
    [ begin
          #r_collection{role_list = RoleList, type_id = TypeID} = Collection = mod_collection_data:get_collection_data(CollectionID),
          ?IF(lists:member(TypeID, TasteList), delete_collection(Collection, RoleList), ok)
      end|| CollectionID <- CollectionList],
    Collections =
        [#r_collection{
            type_id = lib_tool:random_element_from_list(TasteList),
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My)
        } || {Mx, My} <- common_misc:get_global_string_list(?GLOBAL_MARRY_TASTE)],
    mod_collection_map:born_collections(Collections).

born_mythical_collect({CollectTypeID, CollectNum, CollectPos}) ->
    CollectionList = mod_collection_data:get_collection_id_list(),
    [ begin
          #r_collection{role_list = RoleList, type_id = TypeID} = Collection = mod_collection_data:get_collection_data(CollectionID),
          ?IF(TypeID =:= CollectTypeID, delete_collection(Collection, RoleList), ok)
      end|| CollectionID <- CollectionList],
    PosList = lib_tool:string_to_intlist(CollectPos, ":", ","),
    {ok, PosList2} = lib_tool:random_elements_from_list(CollectNum, PosList),
    Collections =
        [#r_collection{
            type_id = CollectTypeID,
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My)
        } || {Mx, My} <- PosList2],
    mod_collection_map:born_collections(Collections).

get_collection_name(TypeID) ->
    [#c_collection{name = Name}] = lib_config:find(cfg_collection, TypeID),
    Name.