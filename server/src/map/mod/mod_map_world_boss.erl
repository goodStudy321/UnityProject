%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 一月 2018 15:48
%%%-------------------------------------------------------------------
-module(mod_map_world_boss).
-author("laijichang").
-include("global.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_world_boss.hrl").

%% 世界boss进程调用
-export([
    collect_refresh/5,
    monster_refresh/4,

    first_world_boss_add_hp/2
]).


%% API
-export([
    init_first_boss/1,
    mythical_loop/1,
    monster_dead/4,
    collection_leave_map/4
]).

-export([
    handle/1,
    get_first_boss_type_id/0
]).

-export([
    i/1,
    get_mythical_info/1,
    get_ancients_info/1
]).

collect_refresh(MapID, CollectRefreshTime, CollectTypeID, CollectNum, CollectPos) ->
    map_misc:info_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, {collect_refresh, CollectRefreshTime, CollectTypeID, CollectNum, CollectPos}).

monster_refresh(MapID, MonsterRefreshTime, TypeID, RefreshArgs) ->
    map_misc:info_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, {monster_refresh, MonsterRefreshTime, TypeID, RefreshArgs}).

first_world_boss_add_hp(MapID, TypeID) ->
    map_misc:info_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, {first_world_boss_add_hp, TypeID}).

i(MapID) ->
    map_misc:call_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, i).

get_mythical_info(MapID) ->
    map_misc:call_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, get_mythical_info).

get_ancients_info(MapID) ->
    map_misc:call_mod(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), ?MODULE, get_ancients_info).

init_first_boss(MapID) ->
    set_first_boss_type_id(mod_role_world_boss:get_first_boss_by_map_id(MapID)).

mythical_loop(_Now) ->
    #r_map_world_boss{exp_counter = ExpCounter} = MapWorldBoss = get_map_world_boss(),
    ExpCounter2 = do_exp_counter_loop(ExpCounter + 1),
    set_map_world_boss(MapWorldBoss#r_map_world_boss{exp_counter = ExpCounter2}).

%% 怪物死亡回调
monster_dead(MapID, SubType, MapInfo, ExtraArgs) ->
    if
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
            monster_dead2(MapID, SubType, MapInfo, ExtraArgs);
        true ->
            ok
    end.

%% 特殊地图死亡回调
monster_dead2(MapID, SubType, MapInfo, MonsterDead) ->
    #r_monster_dead{td_index = AreaID} = MonsterDead,
    case AreaID > 0 of
        true -> %% 精英怪死亡
            #r_map_world_boss{
                monster_refresh_time = MonsterRefreshTime,
                monster_type_id = MonsterTypeID,
                monster_num = MonsterNum,
                monster_area_list = AreaList} = MapWorldBoss = get_map_world_boss(),
            #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
            case lists:keytake(AreaID, #p_kvt.id, AreaList) of
                {value, #p_kvt{val = OldVal} = KV, AreaList2} ->
                    Val = OldVal - 1,
                    KV2 = KV#p_kvt{val = OldVal - 1},
                    AreaList3 = [KV2|AreaList2],
                    MonsterNum2 = MonsterNum - 1,
                    MapWorldBoss2 = MapWorldBoss#r_map_world_boss{
                        monster_num = MonsterNum2,
                        monster_area_list = AreaList3
                    },
                    set_map_world_boss(MapWorldBoss2),
                    if
                        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS ->
                            ?IF(MonsterNum2 =:= 0, common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_MONSTER_OVER, [map_misc:get_map_name(MapID), monster_misc:get_monster_name(TypeID)]), ok),
                            map_server:send_all_gateway(get_update_record(MonsterTypeID, MonsterRefreshTime, MonsterNum2));
                        SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
                            map_server:send_all_gateway(get_update_record(TypeID, MonsterRefreshTime, Val));
                        true ->
                            ok
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

collection_leave_map(MapID, SubType, TypeID, IsCollect) ->
    if
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
            collection_leave_map2(MapID, SubType, TypeID, IsCollect);
        true ->
            ok
    end.

collection_leave_map2(MapID, SubType, TypeID, IsCollect) ->
    #r_map_world_boss{
        collect_type_id = CollectTypeID,
        collect_num = CollectNum,
        collect_refresh_time = CollectRefreshTime} = MapWorldBoss = get_map_world_boss(),
    case CollectTypeID =:= TypeID andalso IsCollect of
        true ->
            CollectNum2 = CollectNum - 1,
            MapWorldBoss2 = MapWorldBoss#r_map_world_boss{collect_num = CollectNum2},
            set_map_world_boss(MapWorldBoss2),
            map_server:send_all_gateway(get_update_record(TypeID, CollectRefreshTime, CollectNum2)),
            %% 神兽岛需要广播
            ?IF(CollectNum2 =:= 0 andalso SubType =:= ?SUB_TYPE_MYTHICAL_BOSS,
                common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_COLLECT_OVER, [map_misc:get_map_name(MapID), mod_collection:get_collection_name(TypeID)]),
                ok);
        _ ->
            ok
    end.

handle({born_boss, TypeID, Pos}) ->
    do_born_boss(TypeID, Pos);
handle({born_hidden_boss, BornTypeID, BornPos, BossNum}) ->
    do_born_hidden_boss(BornTypeID, BornPos, BossNum);
handle({change_hidden_boss_list, BossList}) ->
    do_change_hidden_boss_list(BossList);
handle({boss_dead, TypeID, NextRefreshTime}) ->
    do_boss_dead(TypeID, NextRefreshTime);
handle({collect_refresh, CollectRefreshTime, CollectTypeID, CollectNum, CollectPos}) ->
    do_collect_refresh(CollectRefreshTime, CollectTypeID, CollectNum, CollectPos);
handle({monster_refresh, MonsterRefreshTime, TypeID, RefreshArgs}) ->
    do_monster_refresh(MonsterRefreshTime, TypeID, RefreshArgs);
handle({first_world_boss_add_hp, TypeID}) ->
    do_first_world_boss_add_hp(TypeID);
handle(i) ->
    get_map_world_boss();
handle(get_mythical_info) ->
    do_get_mythical_info();
handle(get_ancients_info) ->
    do_get_ancients_info().

do_born_boss(TypeID, Pos) ->
    [Mx, My|_] = Pos,
    BornPos = map_misc:get_pos_by_offset_pos(Mx, My),
    ?IF(get_first_boss_type_id() =:= TypeID, map_server:kick_all_roles(), ok),
    MonsterData = [#r_monster{type_id = TypeID, born_pos = BornPos}],
    mod_map_monster:born_monsters(MonsterData),
    WorldBoss = #p_world_boss{
        map_id = map_common_dict:get_map_id(),
        type_id = TypeID,
        is_alive = true,
        next_refresh_time = 0},
    DataRecord = #m_world_boss_map_update_toc{map_boss = WorldBoss},
    map_server:send_all_gateway(DataRecord).

do_born_hidden_boss(BornTypeID, BornPos, BossList) ->
    {Mx, My} = BornPos,
    RecordPos = map_misc:get_pos_by_offset_pos(Mx, My),
    MonsterData = [#r_monster{type_id = BornTypeID, born_pos = RecordPos}],
    mod_map_monster:born_monsters(MonsterData),
    do_change_hidden_boss_list(BossList).

do_change_hidden_boss_list(BossList) ->
    WorldBoss = get_map_world_boss(),
    set_map_world_boss(WorldBoss#r_map_world_boss{hidden_boss_list = BossList}).

do_boss_dead(TypeID, NextRefreshTime) ->
    WorldBoss = #p_world_boss{
        map_id = map_common_dict:get_map_id(),
        type_id = TypeID,
        is_alive = false,
        next_refresh_time = NextRefreshTime},
    DataRecord = #m_world_boss_map_update_toc{map_boss = WorldBoss},
    map_server:send_all_gateway(DataRecord).

%% 采集物刷新
do_collect_refresh(CollectRefreshTime, CollectTypeID, CollectNum, CollectPos) ->
    mod_map_collection:born_mythical_collect({CollectTypeID, CollectNum, CollectPos}),
    MapWorldBoss = get_map_world_boss(),
    MapWorldBoss2 = MapWorldBoss#r_map_world_boss{collect_type_id = CollectTypeID, collect_refresh_time = CollectRefreshTime, collect_num = CollectNum},
    set_map_world_boss(MapWorldBoss2),
    map_server:send_all_gateway(get_update_record(CollectTypeID, CollectRefreshTime, CollectNum)).

%% 怪物刷新
do_monster_refresh(MonsterRefreshTime, TypeID, RefreshArgs) ->
    #r_map_world_boss{monster_area_list = AreaList} = MapWorldBoss = get_map_world_boss(),
    {MonsterDatas, AreaList2, MonsterNum} = do_monster_refresh2(string:tokens(RefreshArgs, "|"), AreaList, [], [], 1, 0),
    mod_map_monster:born_monsters(MonsterDatas),
    MapWorldBoss2 = MapWorldBoss#r_map_world_boss{
        monster_type_id = TypeID,
        monster_num = MonsterNum,
        monster_refresh_time = MonsterRefreshTime,
        monster_area_list = AreaList2},
    set_map_world_boss(MapWorldBoss2),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(map_common_dict:get_map_id()),
    if
        SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
            [ map_server:send_all_gateway(get_update_record(RefreshTypeID, MonsterRefreshTime, RefreshNum)) || #p_kvt{type = RefreshTypeID, val = RefreshNum} <- AreaList2],
            ok;
        true ->
            map_server:send_all_gateway(get_update_record(TypeID, MonsterRefreshTime, MonsterNum))
    end.

do_monster_refresh2([], _AreaList, MonsterDatas, AreaList, _IndexAcc, MonsterNum) ->
    {MonsterDatas, AreaList, MonsterNum};
do_monster_refresh2([String|R], AreaList, MonsterDataAcc, AreaAcc, Index, MonsterNumAcc) ->
    [MinPoint, MaxPoint, TypeIDString, BornNumString] = string:tokens(String, ";"),
    TypeID = lib_tool:to_integer(TypeIDString),
    {KV, AreaList2} =
        case lists:keytake(Index, #p_kvt.id, AreaList) of
            {value, KVT, AreaListT} ->
                {KVT, AreaListT};
            _ ->
                {#p_kvt{id = Index, val = 0}, AreaList}
        end,
    #p_kvt{val = NowNum} = KV,
    BornNum = lib_tool:to_integer(BornNumString),
    NeedBornNum = BornNum - NowNum,
    MonsterDataAcc2 =
        case NeedBornNum > 0 of
            true ->
                [Mx1String, My1String] = string:tokens(MinPoint, ","),
                [Mx2String, My2String] = string:tokens(MaxPoint, ","),
                Mx1 = lib_tool:to_integer(Mx1String),
                Mx2 = lib_tool:to_integer(Mx2String),
                My1 = lib_tool:to_integer(My1String),
                My2 = lib_tool:to_integer(My2String),
                {MinMx, MaxMx} = ?IF(Mx1 > Mx2, {Mx2, Mx1}, {Mx1, Mx2}),
                {MinMy, MaxMy} = ?IF(My1 > My2, {My2, My1}, {My1, My2}),
                [ #r_monster{
                    type_id = TypeID,
                    td_index = Index,
                    born_pos = map_misc:get_seq_born_pos([MinMx, MinMy], [MaxMx, MaxMy])
                }|| _BornIndex <- lists:seq(1, NeedBornNum)] ++ MonsterDataAcc;
            _ ->
                MonsterDataAcc
        end,
    do_monster_refresh2(R, AreaList2, MonsterDataAcc2, [KV#p_kvt{val = BornNum, type = TypeID}|AreaAcc], Index + 1, MonsterNumAcc + BornNum).

%% 世界boss回血
do_first_world_boss_add_hp(TypeID) ->
    [ begin
          case MonsterExtra of
              #p_map_monster{type_id = TypeID} ->
                  mod_map_actor:buff_heal(ActorID, 999999999, ?BUFF_ADD_HP, 0);
              _ ->
                  ok
          end
      end|| #r_map_actor{actor_id = ActorID, monster_extra = MonsterExtra} <- mod_map_ets:get_all_actor()].

do_get_mythical_info() ->
    #r_map_world_boss{
        collect_type_id = CollectTypeID,
        collect_num = CollectNum,
        collect_refresh_time = CollectRefreshTime,
        monster_type_id = MonsterTypeID,
        monster_num = MonsterNum,
        monster_refresh_time = MonsterRefreshTime
    } = get_map_world_boss(),
    {CollectTypeID, CollectNum, CollectRefreshTime, MonsterTypeID, MonsterNum, MonsterRefreshTime}.

do_get_ancients_info() ->
    #r_map_world_boss{
        collect_type_id = CollectTypeID,
        collect_num = CollectNum,
        collect_refresh_time = CollectRefreshTime,
        monster_type_id = MonsterTypeID,
        monster_num = MonsterNum,
        monster_area_list = MonsterAreaList,
        monster_refresh_time = MonsterRefreshTime,
        hidden_boss_list = HiddenBossList
    } = get_map_world_boss(),
    {CollectTypeID, CollectNum, CollectRefreshTime, MonsterTypeID, MonsterNum, MonsterRefreshTime, MonsterAreaList, HiddenBossList}.

do_exp_counter_loop(ExpCounter) ->
    [NeedCounter, ExpRate|_] = common_misc:get_global_list(?GLOBAL_MYTHICAL_EXP),
    case ExpCounter >= NeedCounter of
        true ->
            map_server:send_all_role({mod, mod_role_level, {add_level_exp, ExpRate, ?EXP_ADD_FROM_MYTHICAL_LOOP}}),
            0;
        _ ->
            ExpCounter
    end.
%%%===================================================================
%%% dict
%%%===================================================================
get_map_world_boss() ->
    case erlang:get({?MODULE, map_world_boss}) of
        #r_map_world_boss{} = MapWorldBoss ->
            MapWorldBoss;
        _ ->
            #r_map_world_boss{}
    end.
set_map_world_boss(MapWorldBoss) ->
    erlang:put({?MODULE, map_world_boss}, MapWorldBoss).

get_update_record(TypeID, RefreshTime, RemainNum) ->
    UpdateBoss = #p_world_boss{
        map_id = map_common_dict:get_map_id(),
        type_id = TypeID,
        is_alive = false,
        next_refresh_time = RefreshTime,
        remain_num = RemainNum
    },
    #m_world_boss_map_update_toc{map_boss = UpdateBoss}.

get_first_boss_type_id() ->
    erlang:get({?MODULE, first_boss_type_id}).
set_first_boss_type_id(TypeID) ->
    erlang:put({?MODULE, first_boss_type_id}, TypeID).