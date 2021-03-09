%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     actor基础
%%% @end
%%% Created : 05. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_map_role).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_map_actor.hrl").
-include("proto/mod_role_map.hrl").

%% 由role_server调用
-export([
    role_enter_map/4,
    role_dead_ack/4,
    role_relive/3,
    role_quit_map/3,
    role_get_mapinfo/2,
    role_get_pos/2,
    role_fight_prepare/9,
    role_fight/2,
    role_change_pos/6,
    role_add_hp/3,
    role_buff_reduce_hp/6,
    role_buff_heal/4,
    role_buff_heal/5,

    role_get_cheer/4,
    role_cheer/4,
    role_auto_cheer/4,
    role_pick_drop/4,
    role_copy_restart/2,
    role_first_drop/5,
    role_add_enemy_buffs/3,

    update_role_level/3,
    update_role_name/3,
    update_role_fight/3,
    update_role_status/3,
    update_role_weapon_state/3,
    update_role_skin_list/3,
    update_role_ornament_list/3,
    update_role_buffs/5,
    update_role_buff_status/3,
    update_role_missions/5,
    update_role_map_args/3,
    update_role_pk_mode/3,
    update_role_pk_value/3,
    update_role_family/4,
    update_role_family_title/3,
    update_role_power/3,
    update_role_team/3,
    update_role_camp/3,
    update_role_confine/3,
    update_role_title/3,
    update_role_shield/3,
    update_role_couple/4,
    update_relive_level/3,
    update_map_prop_effect/3,
    update_role_special_drop/3,
    update_role_item_control/3,
    update_role_fight_effect/3,

    add_enemy_buff/4
]).

%% API
%% mod_map_actor回调actor模块下的接口（如果存在对应接口的话）
-export([
    enter_map/1,
    leave_map/1,
    enter_slice/1,
    add_hp/1,
    reduce_hp/1,
    hp_change/1,
    dead/1,
    dead_ack/1,
    shield_remove/1,
    deal_map_change_pos/1
]).

%%%===================================================================
%%% role_server 调用 start
%%%===================================================================
role_enter_map(MapPName, MapInfo, Attr, Args) ->
    case map_server:is_map_process() of
        true ->
            case catch mod_map_actor:enter_map(MapInfo, Attr, Args) of
                ok ->
                    {ok, #r_map_enter{map_pid = erlang:self()}};
                Error ->
                    ?ERROR_MSG("role enter map Error:~w", [Error]),
                    Error
            end;
        _ ->
            map_misc:call(MapPName, {func, ?MODULE, role_enter_map, [MapPName, MapInfo, Attr, Args]})
    end.

role_dead_ack(MapPName, RoleID, SrcID, SrcType) ->
    case map_server:is_map_process() of
        true ->
            DeadArgs = #r_actor_dead{src_id = SrcID, src_type = SrcType},
            mod_map_actor:dead_ack(RoleID, DeadArgs);
        _ ->
            map_misc:info(MapPName, {func, ?MODULE, role_dead_ack, [MapPName, RoleID, SrcID, SrcType]})
    end.

role_relive(MapPName, RoleID, OpType) ->
    case map_server:is_map_process() of
        true ->
            do_role_relive(RoleID, OpType);
        _ ->
            map_misc:info(MapPName, {func, ?MODULE, role_relive, [MapPName, RoleID, OpType]})
    end.

role_quit_map(MapPID, RoleID, Args) ->
    case map_server:is_map_process() of
        true ->
            MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
            case catch mod_map_actor:leave_map(RoleID, Args) of
                ok ->
                    {ok, MapInfo};
                Error ->
                    Error
            end;
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_quit_map, [MapPID, RoleID, Args]})
    end.

role_get_mapinfo(MapPID, RoleID) ->
    case map_server:is_map_process() of
        true ->
            MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
            {ok, MapInfo};
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_get_mapinfo, [MapPID, RoleID]})
    end.

role_get_pos(MapPID, RoleID) ->
    case map_server:is_map_process() of
        true ->
            RecordPos = mod_map_ets:get_actor_pos(RoleID),
            {ok, RecordPos};
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_get_pos, [MapPID, RoleID]})
    end.

role_fight_prepare(MapPID, RoleID, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos, AddNum) ->
    case map_server:is_map_process() of
        true ->
            mod_fight:fight_prepare(RoleID, ?ACTOR_TYPE_ROLE, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos, AddNum);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_fight_prepare, [MapPID, RoleID, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos, AddNum]})
    end.

role_fight(MapPID, Args) ->
    case map_server:is_map_process() of
        true ->
            mod_fight:fight(Args);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_fight, [MapPID, Args]})
    end.

%% 位置变换
role_change_pos(MapPID, RoleID, RecordPos, IntPos, MoveType, JumpID) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:map_change_pos(RoleID, RecordPos, IntPos, MoveType, JumpID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_change_pos, [MapPID, RoleID, RecordPos, IntPos, MoveType, JumpID]})
    end.

%% 加血
role_add_hp(MapPID, RoleID, AddHp) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:add_hp(RoleID, AddHp);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_add_hp, [MapPID, RoleID, AddHp]})
    end.

%% buff掉血
role_buff_reduce_hp(MapPID, RoleID, FromActorID, ReduceHp, BuffType, BuffID) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:buff_reduce_hp(RoleID, FromActorID, ReduceHp, BuffType, BuffID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_buff_reduce_hp, [MapPID, RoleID, FromActorID, ReduceHp, BuffType, BuffID]})
    end.

%% 治疗
role_buff_heal(MapPID, RoleID, AddHp, BuffType) ->
    role_buff_heal(MapPID, RoleID, AddHp, BuffType, 0).
role_buff_heal(MapPID, RoleID, AddHp, BuffType, BuffID) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:buff_heal(RoleID, AddHp, BuffType, BuffID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_buff_heal, [MapPID, RoleID, AddHp, BuffType, BuffID]})
    end.

role_get_cheer(MapPID, RoleID, ID, AssetType) ->
    case map_server:is_map_process() of
        true ->
            copy_common:role_get_cheer(RoleID, ID, AssetType);
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_get_cheer, [MapPID, RoleID, ID, AssetType]})
    end.

role_cheer(MapPID, RoleID, ID, AssetType) ->
    case map_server:is_map_process() of
        true ->
            copy_common:role_cheer(RoleID, ID, AssetType);
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_cheer, [MapPID, RoleID, ID, AssetType]})
    end.

role_auto_cheer(MapPID, RoleID, SilverTimes, GoldTimes) ->
    case map_server:is_map_process() of
        true ->
            copy_common:role_auto_cheer(RoleID, SilverTimes, GoldTimes);
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_auto_cheer, [MapPID, RoleID, SilverTimes, GoldTimes]})
    end.

role_pick_drop(MapPID, RoleID, DropID, PickCondition) ->
    case map_server:is_map_process() of
        true ->
            mod_map_drop:pick_drop(RoleID, DropID, PickCondition);
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_pick_drop, [MapPID, RoleID, DropID, PickCondition]})
    end.

role_copy_restart(MapPID, RoleID) ->
    case map_server:is_map_process() of
        true ->
            copy_common:copy_restart(RoleID);
        _ ->
            map_misc:call(MapPID, {func, ?MODULE, role_copy_restart, [MapPID, RoleID]})
    end.

role_first_drop(MapPID, RoleID, MonsterTypeID, TypeIDList, MonsterPos) ->
    case map_server:is_map_process() of
        true ->
            mod_map_drop:role_first_drop(RoleID, MonsterTypeID, TypeIDList, MonsterPos);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_first_drop, [MapPID, RoleID, MonsterTypeID, TypeIDList, MonsterPos]})
    end.

%% BuffArgsList -> [#r_buff_args{}|...]
role_add_enemy_buffs(MapPID, RoleID, BuffArgsList) ->
    case map_server:is_map_process() of
        true ->
            do_role_add_enemy_buffs(RoleID, BuffArgsList);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, role_add_enemy_buffs, [MapPID, RoleID, BuffArgsList]})
    end.

update_role_level(MapPID, RoleID, Level) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_level(RoleID, Level);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_level, [MapPID, RoleID, Level]})
    end.

update_role_name(MapPID, RoleID, RoleName) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_name(RoleID, RoleName);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_name, [MapPID, RoleID, RoleName]})
    end.

update_role_fight(MapPID, RoleID, FightAttr) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_fight_attr(RoleID, FightAttr);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_fight, [MapPID, RoleID, FightAttr]})
    end.

update_role_status(MapPID, RoleID, Status) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_status(RoleID, Status);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_status, [MapPID, RoleID, Status]})
    end.

update_role_weapon_state(MapPID, RoleID, WeaponState) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_weapon_state(RoleID, WeaponState);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_weapon_state, [MapPID, RoleID, WeaponState]})
    end.

update_role_skin_list(MapPID, RoleID, SkinList) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_skin_list(RoleID, SkinList);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_skin_list, [MapPID, RoleID, SkinList]})
    end.

update_role_ornament_list(MapPID, RoleID, OrnamentList) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_ornament_list(RoleID, OrnamentList);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_ornament_list, [MapPID, RoleID, OrnamentList]})
    end.

update_role_buffs(MapPID, RoleID, Buffs, UpdateIDList, DelIDList) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_buffs(RoleID, Buffs, UpdateIDList, DelIDList);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_buffs, [MapPID, RoleID, Buffs, UpdateIDList, DelIDList]})
    end.

update_role_buff_status(MapPID, RoleID, BuffStatus) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_buff_status(RoleID, BuffStatus);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_buff_status, [MapPID, RoleID, BuffStatus]})
    end.

update_role_missions(MapPID, RoleID, NewMissions, AddMission, DelMissions) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_missions(RoleID, NewMissions, AddMission, DelMissions);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_missions, [MapPID, RoleID, NewMissions, AddMission, DelMissions]})
    end.

update_role_map_args(MapPID, RoleID, UpdateList) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_map_args(RoleID, UpdateList);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_map_args, [MapPID, RoleID, UpdateList]})
    end.

update_role_pk_mode(MapPID, RoleID, PKMode) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_pk_mode(RoleID, PKMode);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_pk_mode, [MapPID, RoleID, PKMode]})
    end.

update_role_pk_value(MapPID, RoleID, PKValue) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_pk_value(RoleID, PKValue);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_pk_value, [MapPID, RoleID, PKValue]})
    end.

update_role_family(MapPID, RoleID, FamilyID, FamilyName) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_family(RoleID, FamilyID, FamilyName);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_family, [MapPID, RoleID, FamilyID, FamilyName]})
    end.

update_role_family_title(MapPID, RoleID, TitleID) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_family_title(RoleID, TitleID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_family_title, [MapPID, RoleID, TitleID]})
    end.


update_role_power(MapPID, RoleID, Power) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_power(RoleID, Power);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_power, [MapPID, RoleID, Power]})
    end.

update_role_team(MapPID, RoleID, TeamID) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_team(RoleID, TeamID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_team, [MapPID, RoleID, TeamID]})
    end.

update_role_camp(MapPID, RoleID, CampID) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_camp_id(RoleID, CampID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_camp, [MapPID, RoleID, CampID]})
    end.

%% 更新境界
update_role_confine(MapPID, RoleID, Confine) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_confine(RoleID, Confine);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_confine, [MapPID, RoleID, Confine]})
    end.

%% 更新称号
update_role_title(MapPID, RoleID, TitleID) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_title(RoleID, TitleID);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_title, [MapPID, RoleID, TitleID]})
    end.

update_role_shield(MapPID, RoleID, Shield) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_shield(RoleID, Shield);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_shield, [MapPID, RoleID, Shield]})
    end.

update_role_couple(MapPID, RoleID, CoupleID, CoupleName) ->
    case map_server:is_map_process() of
        true ->
            do_update_role_couple(RoleID, CoupleID, CoupleName);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_couple, [MapPID, RoleID, CoupleID, CoupleName]})
    end.

update_relive_level(MapPID, RoleID, ReliveLevel) ->
    case map_server:is_map_process() of
        true ->
            do_update_relive_level(RoleID, ReliveLevel);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_relive_level, [MapPID, RoleID, ReliveLevel]})
    end.

update_map_prop_effect(MapPID, RoleID, PropEffects) ->
    case map_server:is_map_process() of
        true ->
            do_update_map_prop_effect(RoleID, PropEffects);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_map_prop_effect, [MapPID, RoleID, PropEffects]})
    end.

update_role_special_drop(MapPID, RoleID, DropList) ->
    case map_server:is_map_process() of
        true ->
            MapRole = mod_map_ets:get_map_role(RoleID),
            mod_map_ets:set_map_role(RoleID, MapRole#r_map_role{special_drops = DropList});
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_special_drop, [MapPID, RoleID, DropList]})
    end.

update_role_item_control(MapPID, RoleID, RoleItemDrops) ->
    case map_server:is_map_process() of
        true ->
            MapRole = mod_map_ets:get_map_role(RoleID),
            mod_map_ets:set_map_role(RoleID, MapRole#r_map_role{item_drops = RoleItemDrops});
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_item_control, [MapPID, RoleID, RoleItemDrops]})
    end.


update_role_fight_effect(MapPID, RoleID, FightEffect) ->
    case map_server:is_map_process() of
        true ->
            mod_map_actor:update_fight_effect(RoleID, FightEffect);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, update_role_fight_effect, [MapPID, RoleID, FightEffect]})
    end.

add_enemy_buff(MapPID, RoleID, EnemyID, EnemyBuffs) ->
    case map_server:is_map_process() of
        true ->
            do_add_enemy_buff(RoleID, EnemyID, EnemyBuffs);
        _ ->
            map_misc:info(MapPID, {func, ?MODULE, add_enemy_buff, [MapPID, RoleID, EnemyID, EnemyBuffs]})
    end.
%%%===================================================================
%%% role_server 调用 end
%%%===================================================================


%%%===================================================================
%%% mod_map_actor 回调 start
%%%===================================================================
enter_map({RoleID, RecordPos, MapRole}) ->
    #r_map_actor{role_extra = #p_map_role{team_id = TeamID}} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    #r_map_role{
        gateway_pid = RoleGPID,
        role_pid = RolePID
    } = MapRole,
    Ref = erlang:monitor(process, RolePID),
    MapRole2 = MapRole#r_map_role{ref = Ref},
    mod_map_ets:set_map_role(RoleID, MapRole2),
    map_server:reg_role(MapRole2),
    add_role_in_map(RoleID),
    DataRecord = #m_enter_map_toc{
        role_map_info = map_misc:make_p_map_actor(MapInfo),
        map_id = map_common_dict:get_map_id(),
        extra_id = map_common_dict:get_map_extra_id()},
    common_misc:unicast(RoleID, DataRecord),
    Slices = mod_map_slice:get_9slices_by_pos(RecordPos),
    enter_slice({RoleID, [], Slices}),
    gateway_misc:send(RoleGPID, {role_enter_map, erlang:self()}),
    mod_map_ets:add_team_role(TeamID, RoleID),
    hook_map:role_enter_map(RoleID),
    ok.

leave_map({MapActor, {RolePID, IsOnline, SkinList}}) ->
    #r_map_actor{actor_id = RoleID, role_extra = #p_map_role{team_id = TeamID}} = MapActor,
    RoleGPID = mod_map_ets:get_role_gpid(RoleID),
    map_server:dereg_role({RoleID, RolePID}),
    #r_map_role{ref = Ref} = mod_map_ets:get_map_role(RoleID),
    erlang:demonitor(Ref, [flush]),
    gateway_misc:send(RoleGPID, role_leave_map),
    mod_map_ets:erase_map_role(RoleID),
    del_role_in_map(RoleID),
    mod_map_ets:del_team_role(TeamID, RoleID),
    hook_map:role_leave_map(RoleID, IsOnline, SkinList).

enter_slice({RoleID, DelSlices, Slices}) ->
    MapInfos = mod_map_slice:get_p_actors_by_slices(RoleID, Slices),
    DelActors = mod_map_slice:get_actors_ids_by_slices(DelSlices),
    case MapInfos =/= [] orelse  DelActors =/= [] of
        true ->
            DataRecord = #m_map_slice_enter_toc{actors = MapInfos, del_actors = mod_map_slice:get_actors_ids_by_slices(DelSlices)},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.

add_role_in_map(RoleID) ->
    List = mod_map_ets:get_in_map_roles(),
    case lists:member(RoleID, List) of
        true ->
            ignore;
        _ ->
            mod_map_ets:set_in_map_roles([RoleID|List])
    end.
del_role_in_map(RoleID) ->
    List = mod_map_ets:get_in_map_roles(),
    mod_map_ets:set_in_map_roles(lists:delete(RoleID, List)).

reduce_hp({RoleID, ReduceSrc, ReduceHp, RemainHp}) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcActorType} = ReduceSrc,
    info_role_mod(RoleID, {role_reduce_hp, SrcID, SrcActorType, ReduceHp, RemainHp}),
    ?IF(SrcActorType =:= ?ACTOR_TYPE_ROLE, mod_role_skill:attack_result(SrcID, ?ATTACK_RESULT_ATTACK_ROLE), ok),
    hook_map:role_reduce_hp(RoleID, ReduceSrc).

add_hp({RoleID, RemainHp}) ->
    info_role_mod(RoleID, {role_add_hp, RemainHp}).

hp_change({RoleID, RemainHp}) ->
    info_role_mod(RoleID, {hp_change, RemainHp}).

dead({RoleID, ReduceSrc, SrcName}) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcType} = ReduceSrc,
    info_role_mod(RoleID, {role_dead, mod_map_ets:get_actor_pos(RoleID), SrcID, SrcType, SrcName}).

%% 角色死亡确认
dead_ack({RoleID, DeadArgs}) ->
    #r_actor_dead{src_id = SrcID, src_type = SrcType} = DeadArgs,
    #r_map_actor{role_extra = #p_map_role{pk_value = PKValue, family_title = FamilyTitle}} = DestMapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    case SrcType =:= ?ACTOR_TYPE_ROLE of
        true -> %% 杀了非红名玩家，加pk值吧。。
            mod_role_fight:kill_role(SrcID, PKValue > 0),
            ?IF(family_misc:is_owner_or_vice_owner_title(FamilyTitle), do_owner_be_killed(SrcID, DestMapInfo), ok);
        _ ->
            ok
    end,
    hook_map:role_dead(RoleID, SrcID, SrcType).

shield_remove({RoleID}) ->
    role_misc:info_role(RoleID, {mod, mod_role_buff, shield_remove}).

info_role_mod(RoleID, Info) ->
    role_misc:info_role(RoleID, {mod, mod_role_map, Info}).
%%%===================================================================
%%% mod_map_actor 回调
%%%===================================================================


%%%===================================================================
%%% 内部调用 start
%%%===================================================================
do_role_relive(RoleID, OpType) ->
    #r_map_actor{camp_id = CampID, pos = IntPos, max_hp = MaxHp, role_extra = #p_map_role{sex = Sex}} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{hp = MaxHp, status = ?MAP_STATUS_NORMAL}),
    mod_map_actor:broadcast_hp(RoleID, MaxHp, MaxHp),
    case OpType =:= ?RELIVE_TYPE_FEE orelse map_misc:is_copy_front(map_common_dict:get_map_id()) of
        true ->
            BornPos = map_misc:pos_decode(IntPos);
        _ ->
            MapID = map_common_dict:get_map_id(),
            {ok, BornPos} = map_misc:get_born_pos(#r_born_args{map_id = MapID, camp_id = CampID, sex = Sex}),
            mod_map_actor:map_change_pos(RoleID, BornPos, map_misc:pos_encode(BornPos), ?ACTOR_MOVE_NORMAL, 0)
    end,
    ChangeList = [#p_dkv{id = ?MAP_ATTR_STATUS, val = ?MAP_STATUS_NORMAL}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(BornPos, DataRecord),
    hp_change({RoleID, MaxHp}),
    hook_map:role_relive(RoleID, OpType, BornPos).

%% 更新玩家等级
do_update_role_level(RoleID, Level) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra#p_map_role{level = Level}}),
    ChangeList = [#p_dkv{id = ?ROLE_LEVEL, val = Level}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord),
    copy_common:role_level_up(RoleID).

%% 更新玩家的武器状态
do_update_role_weapon_state(RoleID, WeaPonState) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra#p_map_role{weapon_state = WeaPonState}}),
    ChangeList = [#p_dkv{id = ?ROLE_WEAPON_STATE, val = WeaPonState}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

%% 更新角色的皮肤列表
do_update_role_skin_list(RoleID, SkinList) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    SkinList2 = ?IF(?IS_MAP_MARRY_FEAST(map_common_dict:get_map_id()), mod_map_marry:filter_skin_list(RoleID, SkinList), SkinList),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra#p_map_role{skin_list = SkinList2}}),
    ChangeList = [#p_kvl{id = ?ROLE_SKIN_LIST, list = SkinList2}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kl_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

%% 更新角色的装饰列表
do_update_role_ornament_list(RoleID, OrnamentList) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra#p_map_role{ornament_list = OrnamentList}}),
    ChangeList = [#p_kvl{id = ?ROLE_ORNAMENT_LIST, list = OrnamentList}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kl_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

%% 更新玩家在场景中的任务，部分采集物，可能需要删除或者屏蔽
do_update_role_missions(RoleID, NewMissions, AddMission, DelMissions) ->
    MapRole = mod_map_ets:get_map_role(RoleID),
    mod_map_ets:set_map_role(RoleID, MapRole#r_map_role{missions = NewMissions}),
    Slices = mod_map_slice:get_9slices_by_pos(mod_map_ets:get_actor_pos(RoleID)),
    {AddList, DelList} = get_update_collections(Slices, AddMission, DelMissions),
    ?IF(AddList =/= [] orelse DelList =/= [], common_misc:unicast(RoleID, #m_map_slice_enter_toc{actors = AddList, del_actors = DelList}), ok).

do_update_role_map_args(RoleID, UpdateList) ->
    MapRole = mod_map_ets:get_map_role(RoleID),
    MapRole2 = do_update_role_map_args2(UpdateList, MapRole),
    mod_map_ets:set_map_role(RoleID, MapRole2).

do_update_role_map_args2([], MapRole) ->
    MapRole;
do_update_role_map_args2([{Index, Value}|R], MapRole) ->
    MapRole2 = erlang:setelement(Index, MapRole, Value),
    do_update_role_map_args2(R, MapRole2).

get_update_collections(Slices, AddMission, DelMissions) ->
    lists:foldl(
        fun(Slice, {AddAcc1, DelAcc1}) ->
            {AddAcc, DelAcc} =
                lists:foldl(
                    fun(CollectionID, {AddAcc2, DelAcc2}) ->
                        case mod_map_ets:get_actor_mapinfo(CollectionID) of
                            #r_map_actor{collection_extra = #p_map_collection{broadcast_missions = Missions}} = MapInfo ->
                                IsAdd  = ((AddMission -- Missions) =/= AddMission),
                                IsDel = ((DelMissions -- Missions) =/= DelMissions),
                                if
                                    IsAdd ->
                                        {[map_misc:make_p_map_actor(MapInfo)|AddAcc2], DelAcc2};
                                    IsDel ->
                                        {AddAcc2, [CollectionID|DelAcc2]};
                                    true ->
                                        {AddAcc2, DelAcc2}
                                end;
                            _ ->
                                {AddAcc2, DelAcc2}
                        end
                    end, {[], []}, mod_map_ets:get_slice_collections(Slice)),
            {AddAcc ++ AddAcc1, DelAcc ++ DelAcc1}
        end, {[], []}, Slices).

do_update_role_pk_mode(RoleID, PKMode) ->
    #r_map_actor{pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{pk_mode = PKMode}),
    ChangeList = [#p_dkv{id = ?MAP_ATTR_PK_MODE, val = PKMode}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_pk_value(RoleID, PKValue) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{pk_value = PKValue},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    ChangeList = [#p_dkv{id = ?ROLE_PK_VALUE, val = PKValue}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_family(RoleID, FamilyID, FamilyName) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{family_id = FamilyID, family_name = FamilyName},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    KvList = [#p_dkv{id = ?ROLE_FAMILY_ID, val = FamilyID}],
    KsList = [#p_ks{id = ?ROLE_FAMILY_NAME, str = FamilyName}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = KvList, ks_list = KsList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_family_title(RoleID, TitleID) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{family_title = TitleID},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    KvList = [#p_dkv{id = ?ROLE_FAMILY_TITLE, val = TitleID}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = KvList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_power(RoleID, Power) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{power = Power},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    KvList = [#p_dkv{id = ?ROLE_POWER, val = Power}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = KvList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_team(RoleID, TeamID) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    OldTeamID = RoleExtra#p_map_role.team_id,
    mod_map_ets:del_team_role(OldTeamID, RoleID),
    RoleExtra2 = RoleExtra#p_map_role{team_id = TeamID},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    mod_map_ets:add_team_role(TeamID, RoleID),
    ChangeList = [#p_dkv{id = ?ROLE_TEAM_ID, val = TeamID}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_confine(RoleID, Confine) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{confine = Confine},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    ChangeList = [#p_dkv{id = ?ROLE_CONFINE, val = Confine}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_title(RoleID, TitleID) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{title = TitleID},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    ChangeList = [#p_dkv{id = ?ROLE_TITLE_ID, val = TitleID}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = ChangeList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_role_couple(RoleID, CoupleID, CoupleName) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{couple_id = CoupleID, couple_name = CoupleName},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    KVList = [#p_dkv{id = ?ROLE_COUPLE_ID, val = CoupleID}],
    KSList = [#p_ks{id = ?ROLE_COUPLE_NAME, str = CoupleName}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = KVList, ks_list = KSList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_relive_level(RoleID, ReliveLevel) ->
    #r_map_actor{pos = IntPos, role_extra = RoleExtra} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    RoleExtra2 = RoleExtra#p_map_role{relive_level = ReliveLevel},
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{role_extra = RoleExtra2}),
    KVList = [#p_dkv{id = ?ROLE_RELIVE_LEVEL, val = ReliveLevel}],
    DataRecord = #m_map_actor_attr_change_toc{actor_id = RoleID, kv_list = KVList},
    map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord).

do_update_map_prop_effect(RoleID, PropEffects) ->
    MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{prop_effects = PropEffects}).

do_owner_be_killed(SrcID, DestMapInfo) ->
    #r_map_actor{actor_name = SrcActorName, role_extra = #p_map_role{server_name = SrcServerName}} = mod_map_ets:get_actor_mapinfo(SrcID),
    #r_map_actor{actor_name = DestActorName, role_extra = #p_map_role{server_name = DestServerName, family_name = FamilyName, family_title = FamilyTitle}} = DestMapInfo,
    case map_misc:is_cross_map(map_common_dict:get_map_id()) of
        true -> %% 跨服地图
            StringList = [SrcServerName, SrcActorName, map_misc:get_map_name(map_common_dict:get_map_id()),
                DestServerName, FamilyName, family_misc:get_title_name(FamilyTitle), DestActorName],
            common_broadcast:send_world_common_notice(?NOTICE_CROSS_FAMILY_OWNER_BE_KILLED, StringList);
        _ ->
            StringList = [SrcActorName, map_misc:get_map_name(map_common_dict:get_map_id()), FamilyName, family_misc:get_title_name(FamilyTitle), DestActorName],
            common_broadcast:send_world_common_notice(?NOTICE_FAMILY_OWNER_BE_KILLED, StringList)
    end.

do_role_add_enemy_buffs(RoleID, BuffArgsList) ->
    #r_map_actor{pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(RoleID),
    ActorIDs = mod_map_slice:get_actors_ids_by_slices(mod_map_slice:get_9slices_by_pos(map_misc:pos_decode(IntPos))),
    {_FriendList, EnemyList} = mod_fight:get_role_effect_list(MapInfo, lists:delete(RoleID, ActorIDs)),
    [ mod_fight_effect:add_buffs2(ActorID, ActorType, BuffArgsList)|| #actor_fight{actor_id = ActorID, actor_type = ActorType} <- EnemyList].

do_add_enemy_buff(RoleID, EnemyID, EnemyBuffs) ->
    case mod_map_ets:get_actor_mapinfo(EnemyID) of
        #r_map_actor{actor_id = ActorID, actor_type = ActorType} ->
            SrcFightAttr = mod_map_dict:get_fight_attr(ActorID),
            DestFightAttr = mod_map_dict:get_fight_attr(RoleID),
            mod_fight_effect:add_buffs(ActorID, ActorType, SrcFightAttr, DestFightAttr, RoleID, EnemyBuffs);
        _ ->
            ok
    end.

%%位置转移处理
deal_map_change_pos({ActorID, _RecordPos})->
    ?IF(?IS_MAP_ANSWER(map_common_dict:get_map_id()),mod_map_answer:into_circle(ActorID),ok).


%%%===================================================================
%%% 内部调用 end
%%%===================================================================
