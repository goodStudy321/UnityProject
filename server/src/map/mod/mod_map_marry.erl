%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     婚礼场景
%%% @end
%%% Created : 14. 十二月 2018 10:28
%%%-------------------------------------------------------------------
-module(mod_map_marry).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").
-include("collection.hrl").
-include("proto/mod_map_marry.hrl").
-include("proto/mod_role_marry.hrl").
-include("proto/mod_role_extra.hrl").
-include("monster.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    init/0,
    loop/1,
    handle/1,
    role_enter_map/1,
    role_leave_map/2
]).

-export([
    filter_skin_list/2,
    check_pick_drop/1,
    pick_drop/1
]).

-export([
    role_fireworks/6,
    role_wish/3,
    gm_bow_time/3
]).

-export([
    boss_dead/3
]).

init() ->
    {RoleID1, RoleID2, StartTime} = mod_map_dict:get_map_params(),
    MapFeast =
        #r_map_feast{
            owners = [RoleID1, RoleID2],
            bow_time = StartTime + ?FEAST_BOW_TIME,
            end_time = StartTime + ?FEAST_TIME
        },
    set_map_feast(MapFeast).

loop(Now) ->
    #r_map_feast{
        is_end = IsEnd,
        bow_time = BowTime,
        end_time = EndTime,
        feast_collects = FeastCollects,
        feast_monster = FeastMonster,
        exp_counter = ExpCounter,
        collect_counter = CollectCounter
    } = MapFeast = get_map_feast(),
    if
        IsEnd ->
            map_server:kick_all_roles();
        Now >= EndTime ->
            map_server:kick_all_roles(),
            map_server:delay_shutdown(),
            set_map_feast(MapFeast#r_map_feast{is_end = true});
        true ->
            RemainBowTime = BowTime - Now,
            ?IF(0 < RemainBowTime andalso RemainBowTime =< 10,
                common_broadcast:send_roles_common_notice(mod_map_ets:get_in_map_roles(), ?NOTICE_MARRY_BOW, [lib_tool:to_list(RemainBowTime)]),
                ok),
            FeastCollects2 = do_feast_collects_loop(FeastCollects, Now, []),
            FeastMonster2 = do_feast_monster_loop(FeastMonster, Now),
            ExpCounter2 = do_exp_counter_loop(ExpCounter + 1),
            CollectCounter2 = do_collect_counter_loop(CollectCounter + 1),
            MapFeast2 = MapFeast#r_map_feast{
                exp_counter = ExpCounter2,
                collect_counter = CollectCounter2,
                feast_collects = FeastCollects2,
                feast_monster = FeastMonster2},
            set_map_feast(MapFeast2)
    end.

do_feast_collects_loop([], _Now, Acc) ->
    Acc;
do_feast_collects_loop([FeastCollect|R], Now, Acc) ->
    #r_feast_collect{index_id = IndexID, end_time = EndTime, role_add_list = RoleAddList} = FeastCollect,
    case Now >= EndTime of
        true ->
            AddTimes = common_misc:get_global_int(?GLOBAL_MARRY_HEAT_COLLECT),
            mod_map_collection:del_marry_collect(IndexID),
            ?IF(RoleAddList =/= [], mod_map_collection:del_marry_collect_times(RoleAddList, AddTimes), ok),
            do_feast_collects_loop(R, Now, Acc);
        _ ->
            do_feast_collects_loop(R, Now, [FeastCollect|Acc])
    end.

do_feast_monster_loop(FeastMonster, Now) ->
    case FeastMonster of
        #r_feast_monster{end_time = EndTime} when Now < EndTime ->
            FeastMonster;
        _ ->
            undefined
    end.

do_exp_counter_loop(ExpCounter) ->
    [NeedCounter, ExpRate] = common_misc:get_global_list(?GLOBAL_MARRY_EXP),
    case ExpCounter >= NeedCounter of
        true ->
            map_server:send_all_role({mod, mod_role_level, {add_level_exp, ExpRate, ?EXP_ADD_FROM_MARRY_COUNTER}}),
            0;
        _ ->
            ExpCounter
    end.

do_collect_counter_loop(CollectCounter) ->
    NeedCounter = common_misc:get_global_int(?GLOBAL_TASTE_REFRESH),
    case CollectCounter >= NeedCounter of
        true ->
            mod_map_collection:born_marry_collections(),
            0;
        _ ->
            CollectCounter
    end.

role_fireworks(MapPID, RoleID, RoleName, ItemTypeID, ItemName, AddHeat) ->
    map_misc:info_mod(MapPID, ?MODULE, {role_fireworks, RoleID, RoleName, ItemTypeID, ItemName, AddHeat}).

role_wish(MapPID, ToRoleID, WishLog) ->
    map_misc:call_mod(MapPID, ?MODULE, {role_wish, ToRoleID, WishLog}).

boss_dead(AttackList, TypeID, Pos) ->
    map_misc:info_mod(map_common_dict:get_map_pid(), ?MODULE, {boss_dead, AttackList, TypeID, Pos}).

gm_bow_time(MapPID, RoleID, RemainTime) ->
    map_misc:info_mod(MapPID, ?MODULE, {gm_bow_time, RoleID, RemainTime}).

handle({role_fireworks, RoleID, RoleName, ItemTypeID, ItemName, AddHeat}) ->
    DataRecord = #m_marry_fireworks_toc{type_id = ItemTypeID},
    map_server:send_all_gateway(DataRecord),
    do_role_fireworks(RoleID, RoleName, ItemName, AddHeat);
handle({role_wish, ToRoleID, WishLog}) ->
    do_role_wish(ToRoleID, WishLog);
handle({boss_dead, AttackList, TypeID, Pos}) ->
    do_boss_dead(AttackList, TypeID, Pos);
handle({gm_bow_time, RoleID, RemainTime}) ->
    do_gm_bow_time(RoleID, RemainTime);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

role_enter_map(RoleID) ->
    #r_map_feast{
        owners = Owners,
        bow_time = BowTime,
        end_time = EndTime,
        wish_logs = WishLogs,
        heat = Heat,
        feast_collects = FeastCollects
    } = MapFeast = get_map_feast(),
    #r_marry_collect{
        taste_times = TasteTimes,
        heat_collect_times = HeatCollectTimes,
        heat_max_times = HeatMaxTimes} = mod_map_ets:get_marry_role_collect(RoleID),
    DataRecord =
        #m_marry_map_info_toc{
            bow_time = BowTime,
            end_time = EndTime,
            collect_time = get_collect_time(FeastCollects),
            taste_times = TasteTimes,
            heat = Heat,
            remain_times = HeatMaxTimes - HeatCollectTimes,
            pick_times = get_pick_times(RoleID),
            wish_logs = WishLogs
        },
    common_misc:unicast(RoleID, DataRecord),
    case lists:member(RoleID, Owners) of
        true ->
            #r_map_actor{role_extra = #p_map_role{skin_list = SkinList}} = mod_map_ets:get_actor_mapinfo(RoleID),
            MapPID = erlang:self(),
            map_misc:info(MapPID, {func, fun() -> mod_map_role:update_role_skin_list(erlang:self(), RoleID, SkinList) end});
        _ ->
            ok
    end,
    FeastCollects2 = do_feast_collects([RoleID], FeastCollects, []),
    set_map_feast(MapFeast#r_map_feast{feast_collects = FeastCollects2}).

%% 结婚双方过滤掉衣服，并且换上新衣服
filter_skin_list(RoleID, SkinList) ->
    #r_map_feast{owners = Owners} = get_map_feast(),
    ?IF(lists:member(RoleID, Owners), filter_skin_list2(SkinList, []), SkinList).

filter_skin_list2([], Acc) ->
    [3060600|Acc];
filter_skin_list2([SkinID|R], Acc) ->
    case mod_role_fashion:is_fashion_cloth(SkinID) of
        true ->
            [3060600|R] ++ Acc;
        _ ->
            filter_skin_list2(R, [SkinID|Acc])
    end.

role_leave_map(RoleID, SkinList) ->
    #r_map_feast{owners = Owners} = get_map_feast(),
    case lists:member(RoleID, Owners) of
        true ->
            ChangeList = [#p_kvl{id = ?ROLE_SKIN_LIST, list = SkinList}],
            DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kl_list = ChangeList},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.

check_pick_drop(RoleID) ->
    PickTimes = get_pick_times(RoleID),
    ?IF(PickTimes > 0, ok, ?THROW_ERR(?ERROR_PICK_DROP_004)).

pick_drop(RoleID) ->
    PickTimes = get_pick_times(RoleID),
    PickTimes2 = PickTimes - 1,
    set_pick_times(RoleID, PickTimes2),
    common_misc:unicast(RoleID, #m_marry_map_pick_toc{pick_times = PickTimes2}),
    [_BornNum, NeedRemain] = common_misc:get_global_list(?GLOBAL_MARRY_BOSS_DROP_ARGS),
    ?IF(erlang:length(mod_drop_data:get_drop_loop_list()) =< NeedRemain, do_born_drops(get_map_feast()), ok).

%%%===================================================================
%%% Internal Function
%%%===================================================================
do_role_fireworks(RoleID, RoleName, ItemName, AddHeat) ->
    [ConfigHeat1, _ConfigHeat2, _ConfigHeat3] = common_misc:get_global_list(?GLOBAL_MARRY_WISH),
    case AddHeat > ConfigHeat1 of
        true ->
            AddHeat2 = AddHeat - ConfigHeat1,
            do_role_fireworks2(RoleID, RoleName, ItemName, ConfigHeat1),
            do_role_fireworks(RoleID, RoleName, ItemName, AddHeat2);
        _ ->
            do_role_fireworks2(RoleID, RoleName, ItemName, AddHeat)
    end.

do_role_fireworks2(_RoleID, RoleName, ItemName, AddHeat) ->
    #r_map_feast{
        heat = Heat,
        feast_collects = FeastCollects,
        index_id = IndexID
    } = MapFeast = get_map_feast(),
    {HeatType, HeatEvent, Heat2} = get_heat_type(Heat, Heat + AddHeat),
    MapFeast2 =
        case HeatType of
            {collect, BornPosList, CollectTypeID, BornNum, Time} ->
                EndTime = time_tool:now() + Time,
                IndexID2 = IndexID + 1,
                Collections =
                    [#r_collection{
                        type_id = CollectTypeID,
                        index_id = IndexID2,
                        born_pos = copy_misc:get_pos(BornPosList)
                    } || _IndexID <- lists:seq(1, BornNum)],
                mod_map_collection:born_collections(Collections),
                FeastCollect = #r_feast_collect{
                    index_id = IndexID2,
                    end_time = EndTime,
                    role_add_list = []},
                FeastCollects2 = [FeastCollect|FeastCollects],
                FeastCollects3 = do_feast_collects(mod_map_ets:get_in_map_roles(), FeastCollects2, []),
                FeastRecord = #m_marry_map_collect_time_toc{collect_time = EndTime},
                map_server:send_all_gateway(FeastRecord),
                MapFeast#r_map_feast{index_id = IndexID2, heat = Heat2, feast_collects = FeastCollects3};
            {born_boos, BossTypeID, Mx, My, MDir} ->
                MonsterData = monster_misc:get_dynamic_monster(world_data:get_world_level(), BossTypeID),
                MonsterData2 = MonsterData#r_monster{born_pos = map_misc:get_pos_by_offset_pos(Mx, My, MDir)},
                mod_map_monster:born_monsters([MonsterData2]),
                MapFeast#r_map_feast{heat = Heat2};
            _ ->
                MapFeast#r_map_feast{heat = Heat2}
        end,
    set_map_feast(MapFeast2),
    common_broadcast:send_roles_common_notice(mod_map_ets:get_in_map_roles(), ?NOTICE_MARRY_ADD_HEAT, [RoleName, ItemName, lib_tool:to_list(AddHeat)]),
    ?IF(HeatEvent > 0, map_server:send_all_gateway(#m_marry_map_heat_status_toc{heat = HeatEvent}), ok),
    DataRecord = #m_marry_map_heat_toc{heat = Heat2},
    map_server:send_all_gateway(DataRecord),
    ok.

do_role_wish(ToRoleID, WishLog) ->
    #r_map_feast{owners = Owners, wish_logs = WishLogs} = MapFeast = get_map_feast(),
    case lists:member(ToRoleID, Owners) of
        true ->
            MaxLen = common_misc:get_global_int(?GLOBAL_MARRY_WISH),
            WishLogs2 = lists:sublist([WishLog|WishLogs], MaxLen),
            set_map_feast(MapFeast#r_map_feast{wish_logs = WishLogs2}),
            DataRecord = #m_marry_map_wish_log_toc{wish_log = WishLog},
            map_server:send_all_gateway(DataRecord),
            ok;
        _ ->
            {error, ?ERROR_MARRY_MAP_WISH_002}
    end.

do_boss_dead(AttackList, MonsterTypeID, Pos) ->
    RoleList = [ SrcID || #r_monster_attack{src_id = SrcID} <- AttackList],
    FeastState = get_map_feast(),
    PickTimes = common_misc:get_global_int(?GLOBAL_MARRY_BOSS_DROP_ARGS),
    [#c_global{list = DropIDList, int = PickTime}] = lib_config:find(cfg_global, ?GLOBAL_MARRY_BOSS_DROP_IDS),
    DropList = lists:flatten(
        [
            [
                #p_map_drop{
                    type_id = ItemTypeID,
                    num = Num,
                    bind = IsBind,
                    monster_pos = map_misc:pos_encode(Pos),
                    monster_type_id = MonsterTypeID,
                    owner_roles = RoleList}|| {ItemTypeID, Num, IsBind} <- mod_map_drop:get_drop_item_list2(DropID)]
            || DropID <- DropIDList
        ]),
    FeastMonster = #r_feast_monster{
        end_time = time_tool:now() + PickTime,
        pos = Pos,
        drop_list = DropList
    },
    FeastState2 = FeastState#r_map_feast{feast_monster = FeastMonster},
    set_map_feast(FeastState2),
    [ set_pick_times(RoleID, PickTimes)|| RoleID <- RoleList],
    DataRecord = #m_marry_map_pick_toc{pick_times = PickTimes},
    map_server:send_msg_by_roleids(RoleList, DataRecord),
    do_born_drops(FeastState2).

do_gm_bow_time(RoleID, RemainTime) ->
    MapFeast = get_map_feast(),
    set_map_feast(MapFeast#r_map_feast{bow_time = time_tool:now() + RemainTime}),
    role_enter_map(RoleID).

do_born_drops(FeastState) ->
    #r_map_feast{feast_monster = FeastMonster} = FeastState,
    case FeastMonster of
        #r_feast_monster{} ->
            [BornNum, _NeedRemain] = common_misc:get_global_list(?GLOBAL_MARRY_BOSS_DROP_ARGS),
            #r_feast_monster{
                end_time = EndTime,
                pos = Pos,
                drop_list = DropList} = FeastMonster,
            {BornDrops, DropList2} = lib_tool:split(BornNum, DropList),
            FeastMonster2  = FeastMonster#r_feast_monster{drop_list = DropList2},
            FeastState2 = FeastState#r_map_feast{feast_monster = FeastMonster2},
            set_map_feast(FeastState2),
            mod_map_drop:marry_born_drop(BornDrops, Pos, EndTime);
        _ ->
            ok
    end.

%% 增加采集次数
do_feast_collects(_RoleList, [], Acc) ->
    Acc;
do_feast_collects(RoleList, [FeastCollect|R], Acc) ->
    #r_feast_collect{role_add_list = RoleAddList} = FeastCollect,
    AddRoles = RoleList -- RoleAddList,
    AddTimes = common_misc:get_global_int(?GLOBAL_MARRY_HEAT_COLLECT),
    ?IF(AddRoles =/= [], mod_map_collection:add_marry_collect_times(RoleList, AddTimes), ok),
    RoleAddList2 = AddRoles ++ RoleAddList,
    Acc2 = [FeastCollect#r_feast_collect{role_add_list = RoleAddList2}|Acc],
    do_feast_collects(RoleList, R, Acc2).

get_heat_type(Heat, Heat2) ->
    [ConfigHeat1, ConfigHeat2, ConfigHeat3] = common_misc:get_global_list(?GLOBAL_MARRY_WISH),
    if
        Heat2 >= ConfigHeat3 ->
            [BossTypeID, Mx, My, MDir] = common_misc:get_global_list(?GLOBAL_MARRY_HEAT_BOSS),
            {{born_boos, BossTypeID, Mx, My, MDir}, ConfigHeat3, Heat2 - ConfigHeat3};
        (Heat =< ConfigHeat1 andalso ConfigHeat1 =< Heat2) ->
            [#c_global{string = String, list = [CollectTypeID, BornNum]}] = lib_config:find(cfg_global, ?GLOBAL_MARRY_HEAT_COLLECT),
            Time = common_misc:get_global_int(?GLOBAL_MARRY_HEAT_BOSS),
            BornPosList = common_misc:get_global_string_list(String),
            {{collect, BornPosList, CollectTypeID, BornNum, Time}, ConfigHeat1, Heat2};
        (Heat =< ConfigHeat2 andalso ConfigHeat2 =< Heat2) ->
            [#c_global{string = String, list = [CollectTypeID, BornNum]}] = lib_config:find(cfg_global, ?GLOBAL_MARRY_HEAT_COLLECT),
            Time = common_misc:get_global_int(?GLOBAL_MARRY_HEAT_BOSS),
            BornPosList = common_misc:get_global_string_list(String),
            {{collect, BornPosList, CollectTypeID, BornNum, Time}, ConfigHeat2, Heat2};
        true ->
            {0, 0, Heat2}
    end.

%%%===================================================================
%%% dict
%%%===================================================================
set_map_feast(MapFeast) ->
    erlang:put({?MODULE, map_feast}, MapFeast).
get_map_feast() ->
    erlang:get({?MODULE, map_feast}).

set_pick_times(RoleID, Times) ->
    erlang:put({?MODULE, pick_times, RoleID}, Times).
get_pick_times(RoleID) ->
    case erlang:get({?MODULE, pick_times, RoleID}) of
        Times when erlang:is_integer(Times) ->
            Times;
        _ ->
            0
    end.

get_collect_time([]) ->
    0;
get_collect_time(FeastCollects) ->
    EndTimeList = [ EndTime|| #r_feast_collect{end_time = EndTime} <- FeastCollects],
    lists:max(EndTimeList).