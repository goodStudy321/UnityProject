%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_map_monster).
-author("laijichang").
-include("monster.hrl").
-include("proto/mod_map_actor.hrl").

%% 怪物进程mod_monster_map发起的操作
-export([
    monster_enter_map/3,
    monster_dead_ack/2,
    monster_move_point/2,
    monster_move/3,
    monster_stop/1,
    monster_fight_prepare/6,
    monster_fight/1,
    monster_update_status/2,
    monster_update_buff_status/2,
    monster_update_buffs/4,
    monster_update_fight_attr/2,
    monster_update_move_speed/2,
    monster_reach_pos/2,
    monster_change_pos/3,
    monster_buff_reduce_hp/5,
    monster_buff_heal/4,
    monster_drop/1,
    monster_drop_silver/2,
    monster_world_boss_owner/2,
    owner_change_broadcast/2,

    battle_monster_dead/3,
    family_td_exp/1,
    immortal_reach_pos/1,
    broadcast_world_boss_rank/2
]).

%% mod_map_actor 回调
-export([
    enter_map/1,
    reduce_hp/1,
    dead/1,
    dead_ack/1,
    map_change_pos/1
]).

-export([
    do_update_world_boss_owner/2
]).

%% 其他API
-export([
    add_buff/2,
    all_add_buff/1,
    all_remove_buff/1,
    type_add_buff/2,
    type_remove_buff/2,
    born_monsters/1,
    born_monsters/2,
    summon_monsters/1,
    single_ai/4,
    delete_monsters/0,
    td_change_pos/1,
    immortal_delete_guard/1,
    immortal_add_buff/1,
    role_first_boss_leave/1,
    role_first_boss_dead/3,
    gm_add_monster/2,
    gm_delete_monsters/1,
    gm_delete_monster/2,
    gm_all_monster/0,
    loop_msec/0
]).
%%%===================================================================
%%% mod_monster_map 调用 start
%%%===================================================================
%% 怪物进入地图
monster_enter_map(MapInfo, Attr, Args) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:enter_map(MapInfo, Attr, Args) end).

%% 怪物死亡同步地图确认
monster_dead_ack(MonsterID, DeadArgs) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:dead_ack(MonsterID, DeadArgs) end).

%% 怪物移动至某个点
monster_move_point(MonsterID, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move_point(MonsterID, IntPos) end).

%% 怪物移动
monster_move(MonsterID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_actor:move(MonsterID, ?ACTOR_TYPE_MONSTER, RecordPos, IntPos) end).

%% 怪物停止移动
monster_stop(MonsterID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move_stop(MonsterID) end).

monster_fight_prepare(ActorID, DestID, SkillID, StepID, SrcPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_fight:fight_prepare(ActorID, ?ACTOR_TYPE_MONSTER, DestID, SkillID, StepID, SrcPos, IntPos) end).

%% 怪物发起战斗
monster_fight(Args) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_fight:fight(Args) end).

monster_update_status(MonsterID, Status) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_status(MonsterID, Status) end).

%% 更新buff status
monster_update_buff_status(MonsterID, BuffStatus) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_buff_status(MonsterID, BuffStatus) end).

monster_update_buffs(MonsterID, Buffs, UpdateList, DelList) ->
    map_misc:info(map_common_dict:get_map_pid(),
                  fun() ->
                      mod_map_actor:update_buffs(MonsterID, Buffs, UpdateList, DelList),
                      ?IF(DelList =/= [] andalso ?IS_MAP_BATTLE(map_common_dict:get_map_id()), mod_map_battle:del_buffs(MonsterID, DelList), ok)
                  end).

monster_update_fight_attr(MonsterID, Attr) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_fight_attr(MonsterID, Attr) end).

monster_update_move_speed(MonsterID, MoveSpeed) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_move_speed(MonsterID, MoveSpeed) end).

monster_reach_pos(MonsterID, RecordPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> copy_single:monster_reach(MonsterID, RecordPos) end).

monster_change_pos(MonsterID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_actor:map_change_pos(MonsterID, RecordPos, IntPos, ?ACTOR_MOVE_NORMAL, 0) end).

monster_buff_reduce_hp(MonsterID, FromActorID, ReduceHp, BuffType, BuffID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_actor:buff_reduce_hp(MonsterID, FromActorID, ReduceHp, BuffType, BuffID) end).

monster_buff_heal(MonsterID, AddHp, BuffType, BuffID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_actor:buff_heal(MonsterID, AddHp, BuffType, BuffID) end).

monster_drop(DropArgs) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_drop:born_drops(DropArgs) end).

monster_drop_silver(DropItemList, CenterPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_drop:monster_drop_silver(DropItemList, CenterPos) end).

monster_world_boss_owner(MonsterID, WorldBossOwner) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_monster:do_update_world_boss_owner(MonsterID, WorldBossOwner) end).

owner_change_broadcast(OldOwnerName, NewOwnerName) ->
    map_misc:info(map_common_dict:get_map_pid(),
                  fun() ->
                      map_server:send_all_gateway(#m_world_boss_change_owner_toc{old_owner_name = OldOwnerName, new_owner_name = NewOwnerName})
                  end).

battle_monster_dead(MonsterID, SrcID, SrcType) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() ->
        mod_map_battle:battle_monster_dead(MonsterID, SrcID, SrcType) end).

family_td_exp(AddExp) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_family_td:add_exp(AddExp) end).

immortal_reach_pos(MonsterID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> copy_immortal:immortal_reach_pos(MonsterID) end).

broadcast_world_boss_rank(MonsterID, DataRecord) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> map_server:broadcast_by_actors([MonsterID], DataRecord) end).
%%%===================================================================
%%% mod_monster_map 调用 end
%%%===================================================================


%%%===================================================================
%%% mod_map_actor 回调 start
%%%===================================================================
enter_map({MonsterID, _RecordPos, _MonsterPID}) ->
    info_monster_pid({func, fun() -> mod_monster_map:enter_map(MonsterID) end}),
    hook_map:monster_enter_map(MonsterID).

reduce_hp({MonsterID, ReduceSrc, ReduceHp, RemainHp}) ->
    hook_map:monster_reduce_hp(MonsterID, ReduceSrc, ReduceHp),
    info_monster_pid({func, fun() -> mod_monster_map:reduce_hp(MonsterID, ReduceSrc, ReduceHp, RemainHp) end}).

dead({MonsterID, ReduceSrc, _SrcName}) ->
    info_monster_pid({func, fun() -> mod_monster_map:dead(MonsterID, ReduceSrc) end}).

dead_ack({MonsterID, DeadArgs}) ->
    hook_map:monster_dead(MonsterID, DeadArgs),
    mod_map_actor:leave_map(MonsterID, []).

map_change_pos({MonsterID, RecordPos}) ->
    info_monster_pid({func, fun() -> mod_monster_map:map_change_pos(MonsterID, RecordPos) end}).

%%%===================================================================
%%% mod_map_actor 回调 end
%%%===================================================================


%%%===================================================================
%%% 内部调用 start
%%%===================================================================
%% @doc 发送归属
do_update_world_boss_owner(MonsterID, WorldBossOwner) ->
    #r_map_actor{pos = IntPos, monster_extra = MapMonster} = MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    #p_map_monster{world_boss_owner = OldWorldBossOwner} = MapMonster,
    mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{monster_extra = MapMonster#p_map_monster{world_boss_owner = WorldBossOwner}}),
    case OldWorldBossOwner of
        #p_world_boss_owner{owner_id = OldOwnerID} when WorldBossOwner =/= undefined andalso OldOwnerID =:= WorldBossOwner#p_world_boss_owner.owner_id -> %% 相同的时候，不推送协议更新
            ok;
        _ ->
            DataRecord = #m_world_boss_owner_update_toc{actor_id = MonsterID, world_boss_owner = WorldBossOwner},
            map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord)
    end.

%%%===================================================================
%%% 内部调用 start
%%%===================================================================


%%%===================================================================
%%% 其他API start
%%%===================================================================
add_buff(_MonsterID, []) ->
    ok;
add_buff(MonsterID, BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_buff:add_buff(MonsterID, BuffList) end}).

all_add_buff(BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_map:type_add_buff(0, BuffList) end}).

all_remove_buff(BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_map:type_remove_buff(0, BuffList) end}).

type_add_buff(TypeID, BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_map:type_add_buff(TypeID, BuffList) end}).

type_remove_buff(TypeID, BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_map:type_remove_buff(TypeID, BuffList) end}).

born_monsters(MonsterList) ->
    info_monster_pid({func, fun() -> mod_monster_map:born_monsters(MonsterList) end}).

born_monsters(MonsterList, HadInitAttr) ->
    info_monster_pid({func, fun() -> mod_monster_map:born_monsters(MonsterList ,HadInitAttr) end}).

summon_monsters(Monsters) ->
    info_monster_pid({func, fun() -> mod_monster_map:summon_monsters(Monsters) end}).

single_ai(RoleID, MonsterID, Type, Args) ->
    info_monster_pid({func, fun() -> mod_monster_map:single_ai(RoleID, MonsterID, Type, Args) end}).

delete_monsters() ->
    info_monster_pid({func, fun() -> mod_monster_map:delete_monsters() end}).

td_change_pos(AreaPosList2) ->
    info_monster_pid({func, fun() -> mod_monster_map:td_change_pos(AreaPosList2) end}).

immortal_delete_guard(TDIndex) ->
    info_monster_pid({func, fun() -> mod_monster_map:immortal_delete_guard(TDIndex) end}).

immortal_add_buff(BuffList) ->
    info_monster_pid({func, fun() -> mod_monster_map:immortal_add_buff(BuffList) end}).

role_first_boss_leave(RoleID) ->
    info_monster_pid({func, fun() -> mod_monster_world_boss:role_leave_map(RoleID) end}).

role_first_boss_dead(RoleID, SrcActorID, SrcActorType) ->
    info_monster_pid({func, fun() -> mod_monster_world_boss:role_dead(RoleID, SrcActorID, SrcActorType) end}).

gm_add_monster(RoleID, TypeID) ->
    RecordPos = mod_map_ets:get_actor_pos(RoleID),
    MonsterDatas = [#r_monster{type_id = TypeID, born_pos = RecordPos}],
    info_monster_pid({func, fun() -> mod_monster_map:born_monsters(MonsterDatas) end}).

gm_delete_monsters(RoleID) ->
    info_monster_pid({func, fun() -> mod_monster_map:gm_delete_monsters(RoleID) end}).

gm_delete_monster(RoleID, TypeID) ->
    info_monster_pid({func, fun() -> mod_monster_map:gm_delete_monster(RoleID, TypeID) end}).

gm_all_monster() ->
    info_monster_pid({func, fun() -> mod_monster_map:gm_all_monster() end}).

loop_msec() ->
    info_monster_pid({guide_loop_msec, time_tool:now_os_ms()}).

%%%===================================================================
%%% 其他API 回调 start
%%%===================================================================


info_monster_pid(Info) ->
    pname_server:send(mod_map_dict:get_monster_pid(), Info).
