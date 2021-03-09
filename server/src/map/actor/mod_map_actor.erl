%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_map_actor).
-include("global.hrl").
-include("battle.hrl").
-include("proto/mod_map_actor.hrl").
-include("proto/mod_map_role_move.hrl").
-author("laijichang").

%% 这里方法调用后，会回调actor模块下的接口（如果存在对应接口的话）
-export([
    enter_map/3,
    multi_enter_map/2,
    leave_map/2,
    move_point/2,
    stick_move/4,
    move/4,
    move_stop/1,

    add_hp/2,
    add_hp/3,
    reduce_hp/3,
    reduce_hp/4,

    dead_ack/2,
    map_change_pos/5
]).

-export([
    buff_heal/4,
    buff_reduce_hp/5,
    update_status/2,
    update_buff_status/2,
    update_fight_attr/2,
    update_move_speed/2,
    update_camp_id/2,
    update_name/2,
    update_buffs/4,
    update_shield/2,
    update_fight_effect/2,
    fight_effect_active/3
]).

%% API
-export([
    broadcast_hp/3
]).

%%%===================================================================
%%% map actor start
%%%===================================================================
%% 进入地图
enter_map(MapInfo, Attr, ExtraArgs) ->
    #r_map_actor{actor_id = ActorID, actor_type = ActorType, pos = Pos} = MapInfo,
    RecordPos = map_misc:pos_decode(Pos),
    #r_pos{mx = Mx, my = My, tx = Tx, ty = Ty} = RecordPos,
    case map_base_data:is_exist(Tx, Ty) of
        true ->
            ok;
        _ ->
            ?ERROR_MSG("Pos: ~w", [{map_misc:get_offset_meter(Mx, My), RecordPos, MapInfo}]),
            erlang:throw({error, pos_error})
    end,
    Slice = mod_map_slice:get_slice_by_pos(RecordPos),
    %% 下面的每一步MapInfo都可能会变化，慎重！！
    reg_actor(ActorID, ActorType, RecordPos, MapInfo, Attr, Slice),
    execute_mod(ActorType, enter_map, {ActorID, RecordPos, ExtraArgs}),
    broadcast_actor_enter(ActorID, Slice, ExtraArgs),
    mod_map_slice:slice_leave(Slice, ActorID, ActorType),
    mod_map_slice:slice_join(Slice, ActorID, ActorType),
    ok.

%% 角色不能调用该接口
multi_enter_map(MapInfoList, ExtraArgs) ->
    {ok, SliceActors, Slices, ActorIDList} = multi_enter_map2(MapInfoList, ExtraArgs, [], [], []),
    Roles = map_misc:get_enter_bc_roles(Slices, ExtraArgs),
    DataRecord = #m_map_slice_enter_toc{actors = [map_misc:make_p_map_actor(mod_map_ets:get_actor_mapinfo(ActorID)) || ActorID <- ActorIDList]},
    broadcast_slice_enter(Roles, DataRecord),
    [begin
         mod_map_slice:slice_leave(Slice, ActorID, ActorType),
         mod_map_slice:slice_join(Slice, ActorID, ActorType)
     end || {Slice, ActorID, ActorType} <- SliceActors],
    ok.

multi_enter_map2([], _ExtraArgs, SliceActors, Slices, ActorIDList) ->
    {ok, SliceActors, Slices, ActorIDList};
multi_enter_map2([{MapInfo, Attr}|R], ExtraArgs, SliceActors, Slices, ActorIDList) ->
    #r_map_actor{actor_id = ActorID, actor_type = ActorType, pos = Pos} = MapInfo,
    RecordPos = map_misc:pos_decode(Pos),
    #r_pos{tx = Tx, ty = Ty} = RecordPos,
    case map_base_data:is_exist(Tx, Ty) of
        true ->
            Slice = mod_map_slice:get_slice_by_pos(RecordPos),
            %% 下面的每一步MapInfo都可能会变化，慎重！！
            reg_actor(ActorID, ActorType, RecordPos, MapInfo, Attr, Slice),
            execute_mod(ActorType, enter_map, {ActorID, RecordPos, ExtraArgs}),
            SliceActors2 = [{Slice, ActorID, ActorType}|SliceActors],
            Slices2 = lib_tool:list_filter_repeat(mod_map_ets:get_9slices(Slice) ++ Slices),
            ActorIDList2 = [ActorID|ActorIDList],
            multi_enter_map2(R, ExtraArgs, SliceActors2, Slices2, ActorIDList2);
        _ ->
            ?ERROR_MSG("Pos: ~w", [{RecordPos, MapInfo}]),
            multi_enter_map2(R, ExtraArgs, SliceActors, Slices, ActorIDList)
    end.

%% 离开地图
leave_map(ActorID, ExtraArgs) ->
    #r_map_actor{actor_type = ActorType} = MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    RecordPos = mod_map_ets:get_actor_pos(ActorID),
    Slice = mod_map_slice:get_slice_by_pos(RecordPos),
    mod_map_slice:slice_leave(Slice, ActorID, ActorType),
    execute_mod(ActorType, leave_map, {MapActor, ExtraArgs}),
    broadcast_actor_leave(ActorID, Slice),
    dereg_actor(ActorID, ActorType),
    ok.

%% Actor准备移动至某个目标点
move_point(ActorID, IntPos) ->
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    Pos = mod_map_ets:get_actor_pos(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{target_pos = IntPos}),
    AllSlice = mod_map_slice:get_9slices_by_pos(Pos),
    RoleIDList = mod_map_slice:get_roleids_by_slices(AllSlice),
    map_server:send_msg_by_roleids(RoleIDList, #m_move_point_toc{actor_id = ActorID, point = IntPos}).

%% 移动广播
stick_move(ActorID, ActorType, RecordPos, IntPos) ->
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    Pos = mod_map_ets:get_actor_pos(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{target_pos = IntPos}),
    AllSlice = mod_map_slice:get_9slices_by_pos(Pos),
    RoleIDList = mod_map_slice:get_roleids_by_slices(AllSlice),
    map_server:send_msg_by_roleids(RoleIDList, #m_stick_move_toc{actor_id = ActorID, pos = IntPos}),
    move(ActorID, ActorType, RecordPos, IntPos).

move(ActorID, ActorType, RecordPos, IntPos) ->
    NewSlice = mod_map_slice:get_slice_by_pos(RecordPos),
    case mod_map_ets:get_actor_slice(ActorID) of
        undefined ->
            mod_map_ets:set_actor_slice(ActorID, NewSlice),
            mod_map_slice:slice_join(NewSlice, ActorID, ActorType),
            reg_actor_pos(ActorID, ActorType, RecordPos, IntPos);
        OldSlice ->
            if
                NewSlice =/= OldSlice ->
                    %% 在这里通知客户端actor的变化:哪些离开了、哪些进入了
                    do_slice_change_notify(ActorID, ActorType, RecordPos, IntPos),
                    mod_map_ets:set_actor_slice(ActorID, NewSlice),
                    mod_map_slice:slice_join(NewSlice, ActorID, ActorType),
                    mod_map_slice:slice_leave(OldSlice, ActorID, ActorType);
                true ->
                    ignore
            end,
            reg_actor_pos(ActorID, ActorType, RecordPos, IntPos)
    end.

move_stop(ActorID) ->
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    OldPos = mod_map_ets:get_actor_pos(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{target_pos = 0}),
    AllSlice = mod_map_slice:get_9slices_by_pos(OldPos),
    RoleIDList = mod_map_slice:get_roleids_by_slices(AllSlice),
    map_server:send_msg_by_roleids(RoleIDList, #m_move_stop_toc{actor_id = ActorID, pos = MapInfo#r_map_actor.pos}),
    ok.

%% 进入地图需要注册的数据
reg_actor(ActorID, ActorType, RecordPos, MapInfo, Attr, Slice) ->
    mod_map_ets:set_actor_mapinfo(MapInfo),
    mod_map_ets:set_actor_slice(ActorID, Slice),
    mod_map_dict:set_fight_attr(ActorID, Attr),
    reg_actor_pos(ActorID, ActorType, RecordPos, MapInfo#r_map_actor.pos).

%% actor退出地图时要清理一些数据
dereg_actor(ActorID, ActorType) ->
    dereg_actor_pos(ActorID, ActorType),
    mod_map_ets:del_actor_slice(ActorID),
    mod_map_ets:del_actor_mapinfo(ActorID),
    mod_map_dict:erase_fight_attr(ActorID),
    mod_map_dict:erase_role_last_drain(ActorID).

%% 注册actor -> pos && tile -> actors
reg_actor_pos(ActorID, ActorType, RecordPos, IntPos) ->
    %% 先清理旧数据
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{} = MapInfo ->
            dereg_actor_pos(ActorID, ActorType),
            mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{pos = IntPos}),
            mod_map_ets:set_actor_pos(ActorID, RecordPos),
            mod_map_tile:ref_tile_pos(ActorID, ActorType, RecordPos);
        _ ->
            ?ERROR_MSG("Actor Map info not found:~w", [{ActorID, ActorType}])
    end.

%% 解注册
dereg_actor_pos(ActorID, ActorType) ->
    case mod_map_ets:get_actor_pos(ActorID) of
        undefined ->
            ignore;
        OldPos ->
            mod_map_ets:del_actor_pos(ActorID),
            mod_map_tile:deref_tile_pos(ActorID, ActorType, OldPos)
    end.

broadcast_actor_enter(ActorID, Slice, ExtraArgs) ->
    Roles = map_misc:get_enter_bc_roles(mod_map_ets:get_9slices(Slice), ExtraArgs),
    DataRecord = #m_map_slice_enter_toc{actors = [map_misc:make_p_map_actor(mod_map_ets:get_actor_mapinfo(ActorID))]},
    broadcast_slice_enter(Roles, DataRecord).

broadcast_actor_leave(ActorID, Slice) ->
    Roles = mod_map_slice:get_roleids_by_slices(mod_map_ets:get_9slices(Slice)),
    DataRecord = #m_map_slice_enter_toc{del_actors = [ActorID]},
    broadcast_slice_enter(Roles, DataRecord).

do_slice_change_notify(ActorID, ActorType, Pos, IntPos) ->
    OldPos = mod_map_ets:get_actor_pos(ActorID),
    AllSliceOld = mod_map_slice:get_9slices_by_pos(OldPos),
    AllSliceNew = mod_map_slice:get_9slices_by_pos(Pos),
    NewSlices = AllSliceNew -- AllSliceOld,
    DelSlices = AllSliceOld -- AllSliceNew,
    %% 通知DelSlices 里面的人删除掉我
    DelRoleList = mod_map_slice:get_roleids_by_slices(DelSlices),
    DelRecord = #m_map_slice_enter_toc{del_actors = [ActorID]},
    broadcast_slice_enter(DelRoleList, DelRecord),

    %% 通知NewSlices 里面的人我来了
    NewRoleList = mod_map_slice:get_roleids_by_slices(NewSlices),
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    NewRecord = #m_map_slice_enter_toc{actors = [map_misc:make_p_map_actor(MapInfo#r_map_actor{pos = IntPos})]},
    broadcast_slice_enter(NewRoleList, NewRecord),
    execute_mod(ActorType, enter_slice, {ActorID, DelSlices, NewSlices}),
    ok.

%% 所有单位攻防：fight_attack_toc 添加血量计算
%% 所有单位buff血量改变：m_buff_change_hp_toc
%% 所有单位血量改变：m_actor_info_change_toc（升级血量改变，其他导致的属性变化）
%% 注意下hp要不要更新
add_hp(ActorID, AddHp) ->
    add_hp(ActorID, AddHp, true).
add_hp(ActorID, AddHp, IsBroadcast) when AddHp > 0 ->
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    #r_map_actor{actor_type = ActorType, hp = CurHp, max_hp = MaxHp, status = Status} = MapInfo,
    if
        Status =:= ?MAP_STATUS_DEAD ->
            ok;
        true ->
            RemainHp = erlang:min(CurHp + AddHp, MaxHp),
            case RemainHp =/= CurHp of
                true ->
                    ?IF(IsBroadcast, broadcast_hp(ActorID, RemainHp, MaxHp), ok),
                    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{hp = RemainHp}),
                    execute_mod(ActorType, add_hp, {ActorID, RemainHp}),
                    heal;
                _ ->
                    ok
            end
    end;
add_hp(_, _, _) ->
    ok.

reduce_hp(SrcID, DestID, ReduceHp) ->
    reduce_hp(SrcID, DestID, ReduceHp, true).

reduce_hp(SrcID, DestID, ReduceHp, IsBroadcast) when ReduceHp > 0 ->
    DestMapInfo = mod_map_ets:get_actor_mapinfo(DestID),
    #r_map_actor{
        actor_type = DestType,
        hp = CurHp,
        shield = CurShield,
        max_hp = MaxHp,
        status = Status,
        reduce_hp_times = ReduceHpTimes,
        prop_effects = PropEffects,
        buff_status = BuffStatus,
        role_extra = RoleExtra} = DestMapInfo,
    IsDestRole = DestType =:= ?ACTOR_TYPE_ROLE,
    if
        Status =:= ?MAP_STATUS_DEAD -> %% 处于死亡状态或者无敌状态直接ok
            ok;
        ?IS_BUFF_LIMIT_UNBEATABLE(BuffStatus) ->
            ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, CurHp, MaxHp), ok);
        true ->
            case mod_map_ets:get_actor_mapinfo(SrcID) of
                #r_map_actor{actor_type = SrcType, actor_name = SrcName} = SrcMapInfo -> %% 发起者在地图才正常扣血
                    {IsReduceHp, IsShieldRemove, ReduceHp2, Shield} = get_shield_reduce(ReduceHp, CurShield),
                    ?IF(IsShieldRemove, execute_mod(DestType, shield_remove, {DestID}), ok),
                    DestMapInfo2 = DestMapInfo#r_map_actor{shield = Shield},
                    if
                        IsReduceHp ->
                            ReduceSrc = get_real_reduce_src(SrcID, SrcType, SrcMapInfo),
                            {ReduceHpTimes2, ReduceHp3} = is_reduce_hurt(PropEffects, ReduceHpTimes, ReduceHp2),
                            RemainHp = CurHp - ReduceHp3,
                            {RemainHp2, ReduceHp4} = ?IF(RemainHp > 0, {RemainHp, ReduceHp3}, {0, CurHp}),
                            if
                                RemainHp2 =< 0 ->
                                    case ?IS_BUFF_UNDEAD(BuffStatus) orelse is_fresh_role(DestType, RoleExtra) orelse is_prop_effect(?MAP_PROP_EFFECT_UNDEAD, PropEffects) of %% 不死buff
                                        true ->
                                            mod_map_ets:set_actor_mapinfo(DestMapInfo2#r_map_actor{reduce_hp_times = ReduceHpTimes2}),
                                            ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, CurHp, MaxHp), ok);
                                        {true, PropEffect, PropEffects2} -> %% 触发生效
                                            ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, CurHp, MaxHp), ok),
                                            mod_map_ets:set_actor_mapinfo(DestMapInfo2#r_map_actor{reduce_hp_times = ReduceHpTimes2, prop_effects = PropEffects2}),
                                            ?IF(IsDestRole, mod_role_skill:map_prop_effect(DestID, PropEffect), ok);
                                        _ ->
                                            ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, RemainHp2, MaxHp), ok),
                                            mod_map_ets:set_actor_mapinfo(DestMapInfo2#r_map_actor{reduce_hp_times = ReduceHpTimes2, hp = RemainHp2}),
                                            execute_mod(DestType, reduce_hp, {DestID, ReduceSrc, ReduceHp4, RemainHp2}),
                                            execute_mod(DestType, dead, {DestID, ReduceSrc, SrcName}),
                                            reduce
                                    end;
                                true ->
                                    ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, RemainHp2, MaxHp), ok),
                                    mod_map_ets:set_actor_mapinfo(DestMapInfo2#r_map_actor{reduce_hp_times = ReduceHpTimes2, hp = RemainHp2}),
                                    execute_mod(DestType, reduce_hp, {DestID, ReduceSrc, ReduceHp4, RemainHp2}),
                                    reduce
                            end;
                        true ->
                            ?IF(IsBroadcast orelse IsDestRole, broadcast_hp(DestID, CurHp, MaxHp), ok),
                            mod_map_ets:set_actor_mapinfo(DestMapInfo2)
                    end;
                _ ->
                    ok
            end
    end;
reduce_hp(_SrcID, _DestID, _ReduceHp, _IsBroadcast) ->
    ok.

get_shield_reduce(ReduceHp, CurShield) ->
    if
        CurShield =< 0 ->
            {true, false, ReduceHp, 0};
        CurShield > ReduceHp ->
            {false, false, 0, CurShield - ReduceHp};
        CurShield =:= ReduceHp ->
            {false, true, 0, 0};
        true ->
            {true, true, ReduceHp - CurShield, 0}
    end.

get_real_reduce_src(SrcID, ?ACTOR_TYPE_ROLE, SrcMapInfo) ->
    #r_map_actor{actor_name = ActorName, role_extra = #p_map_role{team_id = TeamID, level = Level, family_id = FamilyID}} = SrcMapInfo,
    #r_reduce_src{actor_id = SrcID, actor_name = ActorName, actor_level = Level, actor_type = ?ACTOR_TYPE_ROLE, team_id = TeamID, family_id = FamilyID};
get_real_reduce_src(_SrcID, ?ACTOR_TYPE_TRAP, SrcMapInfo) ->
    #p_map_trap{owner_id = OwnerID, owner_type = OwnerType} = SrcMapInfo#r_map_actor.trap_extra,
    case OwnerType =:= ?ACTOR_TYPE_ROLE andalso mod_map_ets:get_actor_mapinfo(OwnerID) of
        #r_map_actor{} = MapInfo ->
            get_real_reduce_src(OwnerID, OwnerType, MapInfo);
        _ ->
            #r_reduce_src{actor_id = OwnerID, actor_type = OwnerType}
    end;
get_real_reduce_src(SrcID, SrcType, SrcMapInfo) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcType, actor_name = SrcMapInfo#r_map_actor.actor_name}.

dead_ack(ActorID, DeadArgs) ->
    #r_map_actor{actor_type = ActorType, pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{hp = 0, status = ?MAP_STATUS_DEAD}),
    ChangeList = [#p_dkv{id = ?MAP_ATTR_STATUS, val = ?MAP_STATUS_DEAD}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord),
    execute_mod(ActorType, dead_ack, {ActorID, DeadArgs}).

map_change_pos(ActorID, RecordPos, IntPos, MoveType, JumpID) ->
    #r_map_actor{actor_type = ActorType, pos = OldIntPos} = mod_map_ets:get_actor_mapinfo(ActorID),
    move(ActorID, ActorType, RecordPos, IntPos),
    AllSliceOld = mod_map_slice:get_9slices_by_pos(map_misc:pos_decode(OldIntPos)),
    AllSliceNew = mod_map_slice:get_9slices_by_pos(RecordPos),
    AllSlices = lib_tool:list_filter_repeat(AllSliceOld ++ AllSliceNew),
    DataRecord = #m_map_change_pos_toc{actor_id = ActorID, src_pos = OldIntPos, dest_pos = IntPos, type = MoveType, jump_id = JumpID},
    map_server:send_msg_by_roleids(mod_map_slice:get_roleids_by_slices(AllSlices), DataRecord),
    execute_mod(ActorType, deal_map_change_pos, {ActorID, RecordPos}).

%%%===================================================================
%%% map actor end
%%%===================================================================


%%%===================================================================
%%% actor api start
%%%===================================================================
buff_heal(ActorID, AddHp, BuffType, BuffID) ->
    #actor_fight_attr{hp_heal_rate = HpHealRate} = mod_map_dict:get_fight_attr(ActorID),
    AddHp2 = lib_tool:ceil(AddHp * (1 + HpHealRate/?RATE_10000)),
    DataRecord = #m_buff_change_hp_toc{actor_id = ActorID, type = BuffType, val = AddHp2, buff_id = BuffID},
    map_server:broadcast_by_actors([ActorID], DataRecord),
    mod_map_actor:add_hp(ActorID, AddHp2, false).

buff_reduce_hp(ActorID, FromActorID, ReduceHp, BuffType, BuffID) ->
    #actor_fight_attr{
        min_reduce_rate = MinReduceRate,
        max_reduce_rate = MaxReduceRate,
        max_hp = MaxHp
    } = FightAttr = mod_map_dict:get_fight_attr(ActorID),
    case mod_map_ets:get_actor_mapinfo(FromActorID) of
        #r_map_actor{actor_type = FromActorType} = FromActorMapInfo->
            ActorMapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
            case mod_map_battle:is_battle_monster(ActorMapInfo) of
                true -> %% 聚灵牌特殊处理
                    ReduceHp = ?BATTLE_MONSTER_REDUCE_HP,
                    reduce_hp(FromActorID, ActorID, ReduceHp, false);
                _ ->
                    ReduceHp2 = mod_fight_effect:get_real_reduce(ReduceHp, MinReduceRate, MaxReduceRate, MaxHp, false, FromActorID, FromActorType),
                    FiveElementsMulti = mod_fight_effect:get_five_elements_multi(mod_map_dict:get_fight_attr(FromActorID), FightAttr),
                    {_, _, _, Suppress} = mod_fight_effect:get_monster_and_suppress(FromActorType, FromActorMapInfo, ActorMapInfo#r_map_actor.actor_type, ActorMapInfo),
                    ReduceHp3 = lib_tool:ceil(ReduceHp2 * FiveElementsMulti * Suppress),
                    DataRecord = #m_buff_change_hp_toc{actor_id = ActorID, type = BuffType, val = ReduceHp3, buff_id = BuffID},
                    map_server:broadcast_by_actors([ActorID], DataRecord),
                    reduce_hp(FromActorID, ActorID, ReduceHp3, false)
            end;
        _ ->
            ok
    end.

update_status(ActorID, Status) ->
    #r_map_actor{pos = IntPos, status = OldStatus} = MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    case OldStatus =/= Status of
        true ->
            mod_map_ets:set_actor_mapinfo(MapActor#r_map_actor{status = Status}),
            ChangeList = [#p_dkv{id = ?MAP_ATTR_STATUS, val = Status}],
            DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = ChangeList},
            map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord);
        _ ->
            ok
    end.

%% 更新buff_state
update_buff_status(ActorID, BuffStatus) ->
    #r_map_actor{buff_status = OldStatus} = MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    case BuffStatus =/= OldStatus of
        true ->
            mod_map_ets:set_actor_mapinfo(MapActor#r_map_actor{buff_status = BuffStatus});
        _ ->
            ok
    end.

%% 更新战斗属性(可能会更新到血量、移动速度)
update_fight_attr(ActorID, FightAttr) ->
    mod_map_dict:set_fight_attr(ActorID, FightAttr),
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{actor_type = ActorType, pos = IntPos, hp = OldHp, max_hp = OldMaxHp, move_speed = OldMoveSpeed} = MapInfo ->
            #r_map_actor{hp = OldHp, max_hp = OldMaxHp} = MapInfo,
            #actor_fight_attr{move_speed = MoveSpeed, max_hp = MaxHp} = FightAttr,
            case OldMaxHp =/= MaxHp of
                true ->
                    Hp = lib_tool:ceil(OldHp * MaxHp / OldMaxHp),
                    MapInfo2 = MapInfo#r_map_actor{hp = Hp, max_hp = MaxHp},
                    mod_map_ets:set_actor_mapinfo(MapInfo2),
                    broadcast_hp(ActorID, Hp, MaxHp),
                    execute_mod(ActorType, hp_change, {ActorID, Hp});
                _ ->
                    MapInfo2 = MapInfo
            end,
            case MoveSpeed =/= OldMoveSpeed of
                true ->
                    MapInfo3 = MapInfo2#r_map_actor{move_speed = MoveSpeed},
                    mod_map_ets:set_actor_mapinfo(MapInfo3),
                    ChangeList = [#p_dkv{id = ?MAP_ATTR_MOVE_SPEED, val = MoveSpeed}],
                    DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = ChangeList},
                    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

update_move_speed(ActorID, MoveSpeed) ->
    #r_map_actor{pos = IntPos, move_speed = OldMoveSpeed} = MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    case MoveSpeed =/= OldMoveSpeed of
        true ->
            mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{move_speed = MoveSpeed}),
            ChangeList = [#p_dkv{id = ?MAP_ATTR_MOVE_SPEED, val = MoveSpeed}],
            DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = ChangeList},
            map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord);
        _ ->
            ok
    end.

update_camp_id(ActorID, CampID) ->
    #r_map_actor{pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{camp_id = CampID}),
    ChangeList = [#p_dkv{id = ?MAP_ATTR_CAMP_ID, val = CampID}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

%% 更新名字
update_name(ActorID, RoleName) ->
    #r_map_actor{pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{actor_name = RoleName}),
    ChangeList = [#p_ks{id = ?MAP_ATTR_NAME, str = RoleName}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, ks_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

update_buffs(ActorID, Buffs, UpdateIDList, DelIDList) ->
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        undefined ->
            ?ERROR_MSG("test:~w", [{ActorID, Buffs, UpdateIDList, DelIDList}]);
        _ ->
            ok
    end,
    #r_map_actor{pos = IntPos} = MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapActor#r_map_actor{buffs = Buffs}),
    Changes1 = ?IF(UpdateIDList =/= [], [#p_kvl{id = ?MAP_ATTR_BUFF_UPDATE, list = UpdateIDList}], []),
    Changes2 = ?IF(DelIDList =/= [], [#p_kvl{id = ?MAP_ATTR_BUFF_DEL, list = DelIDList}|Changes1], Changes1),
    DataRecord = #m_map_actor_attr_change_toc{actor_id = ActorID, kl_list = Changes2},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

update_shield(ActorID, Shield) ->
    MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{shield = Shield}).

update_fight_effect(ActorID, FightEffects) ->
    MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    mod_map_ets:set_actor_mapinfo(MapActor#r_map_actor{fight_effects = FightEffects}).

%% actor的fight_effect数据更新
fight_effect_active(ActorID, ActiveIDs, DestActorIDs) ->
    ActiveIDs2 = lib_tool:list_filter_repeat(ActiveIDs),
    #r_map_actor{actor_type = ActorType, fight_effects = FightEffects} = MapActor = mod_map_ets:get_actor_mapinfo(ActorID),
    NowMs = time_tool:now_ms(),
    {AddBuffIDs, FightEffects2} = fight_effect_active2(FightEffects, ActiveIDs2, NowMs, [], []),
    mod_map_ets:set_actor_mapinfo(MapActor#r_map_actor{fight_effects = FightEffects2}),
    case AddBuffIDs =/= [] of
        true ->
            FightAttr = mod_map_dict:get_fight_attr(ActorID),
            DestFightAttr =
                case DestActorIDs of
                    [DestActorID|_] ->
                        mod_map_dict:get_fight_attr(DestActorID);
                    _ ->
                        FightAttr
                end,
            mod_fight_effect:add_buffs(ActorID, ActorType, FightAttr, DestFightAttr, ActorID, AddBuffIDs),
            ?IF(ActorType =:= ?ACTOR_TYPE_ROLE, mod_role_skill_seal:update_active_ids(ActorID, ActiveIDs2), ok);
        _ ->
            ok
    end.

fight_effect_active2([], _ActiveIDs, _NowMs, AddBuffIDs, FightEffect) ->
    {AddBuffIDs, FightEffect};
fight_effect_active2([{Type, List}|R], ActiveIDs, NowMs, AddBuffIDAcc, FightEffect) ->
    {AddBuffIDs, List2} = fight_effect_active3(List, ActiveIDs, NowMs, [], []),
    FightEffect2 = [{Type, List2}|FightEffect],
    fight_effect_active2(R, ActiveIDs, NowMs, AddBuffIDs ++ AddBuffIDAcc, FightEffect2).


fight_effect_active3([], _ActiveIDs, _NowMs, AddBuffIDs, FightEffect) ->
    {AddBuffIDs, FightEffect};
fight_effect_active3([FightEffect|R], ActiveIDs, NowMs, AddBuffIDs, FightEffects) ->
    #r_fight_effect{id = ID, self_buffs = SelfAddBuffs, cd = CD} = FightEffect,
    case lists:member(ID, ActiveIDs) of
        true ->
            FightEffect2 = FightEffect#r_fight_effect{time = CD + NowMs},
            AddBuffIDs2 = SelfAddBuffs ++ AddBuffIDs,
            FightEffects2 = [FightEffect2|FightEffects],
            fight_effect_active3(R, ActiveIDs, NowMs, AddBuffIDs2, FightEffects2);
        _ ->
            fight_effect_active3(R, ActiveIDs, NowMs, AddBuffIDs, [FightEffect|FightEffects])
    end.

%%%===================================================================
%%% actor api end
%%%===================================================================

%% 只接受参数为1的接口
execute_mod(ActorType, F, Args) ->
    Mod = get_mod_by_type(ActorType),
    case erlang:function_exported(Mod, F, 1) of
        true -> erlang:apply(Mod, F, [Args]);
        _ -> ok
    end.

get_mod_by_type(?ACTOR_TYPE_ROLE) ->
    mod_map_role;
get_mod_by_type(?ACTOR_TYPE_MONSTER) ->
    mod_map_monster;
get_mod_by_type(?ACTOR_TYPE_COLLECTION) ->
    mod_map_collection;
get_mod_by_type(?ACTOR_TYPE_TRAP) ->
    mod_map_trap;
get_mod_by_type(?ACTOR_TYPE_DROP) ->
    mod_map_drop;
get_mod_by_type(?ACTOR_TYPE_ROBOT) ->
    mod_map_robot.

broadcast_hp(ActorID, RemainHp, MaxHp) ->
    #r_map_actor{pos = IntPos} = mod_map_ets:get_actor_mapinfo(ActorID),
    DataRecord = #m_actor_info_change_toc{actor_id = ActorID, hp = RemainHp, max_hp = MaxHp},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

broadcast_slice_enter(_Roles, #m_map_slice_enter_toc{actors = [], del_actors = []}) ->
    ok;
broadcast_slice_enter(Roles, DataRecord) ->
    map_server:send_msg_by_roleids(Roles, DataRecord).

is_reduce_hurt([], ReduceHpTimes, ReduceHp) ->
    {ReduceHpTimes, ReduceHp};
is_reduce_hurt([#r_map_prop_effect{id = ID, rate = ReduceRate}|R], ReduceHpTimes, ReduceHp) ->
    case ID of
        ?MAP_PROP_FIVE_REDUCE ->
            ?IF(ReduceHpTimes >= 5, {0, lib_tool:ceil(ReduceHp * (1 - ReduceRate/?RATE_10000))}, {ReduceHpTimes + 1, ReduceHp});
        _ ->
            is_reduce_hurt(R, ReduceHpTimes, ReduceHp)
    end.


is_prop_effect(ID, PropEffects) ->
    is_prop_effect2(ID, PropEffects, []).

is_prop_effect2(_ID, [], _Acc) ->
    false;
is_prop_effect2(ID, [PropEffect|R], Acc) ->
    #r_map_prop_effect{
        skill_sub_type = SkillSubType,
        id = PropID,
        rate = Rate,
        end_time_ms = EndTimeMs,
        last_time = LastTime,
        cd = CD,
        next_time_ms = NextTimeMs
    } = PropEffect,
    case ID =:= PropID of
        true ->
            NowMs = time_tool:now_ms(),
            #r_map_prop_effect{
                rate = Rate,
                end_time_ms = EndTimeMs,
                last_time = LastTime,
                cd = CD,
                next_time_ms = NextTimeMs
            } = PropEffect,
            IsRateActive = is_rate_active(SkillSubType, Rate),
            case NowMs < EndTimeMs andalso IsRateActive of
                true -> %% 生效中
                    true;
                _ ->
                    case NowMs >= NextTimeMs andalso common_misc:is_active(Rate) of
                        true -> %% 生效
                            PropEffect2 = PropEffect#r_map_prop_effect{end_time_ms = NowMs + LastTime, next_time_ms = NowMs + CD},
                            {true, PropEffect2, [PropEffect2|R] ++ Acc};
                        _ ->
                            is_prop_effect2(ID, R, [PropEffect|Acc])
                    end
            end;
        _ ->
            is_prop_effect2(ID, R, [PropEffect|Acc])
    end.

is_rate_active(11010, Rate) -> %% 致命守护判定
    common_misc:is_active(Rate);
is_rate_active(_SkillSubType, _Rate) ->
    true.

is_fresh_role(?ACTOR_TYPE_ROLE, #p_map_role{level = Level}) when Level =< ?FRESH_LEVEL ->
    true;
is_fresh_role(_ActorType, _RoleExtra) ->
    false.