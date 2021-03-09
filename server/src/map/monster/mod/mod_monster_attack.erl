%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 9:54
%%%-------------------------------------------------------------------
-module(mod_monster_attack).
-author("laijichang").
-include("monster.hrl").
-include("world_boss.hrl").

-export([
    reduce_hp/4
]).

%% API
-export([
    active_find_enemies/3,
    update_enemy_lists/3,
    add_enemy/3,
    get_enemy/1,
    sort_enemies/1
]).


reduce_hp(MonsterID, ReduceSrc, ReduceHP, _RemainHp) ->
    #r_reduce_src{actor_id = ActorID} = ReduceSrc,
    case MonsterID =:= ActorID of %% 自己造成的伤害
        true ->
            ok;
        _ ->
            #r_monster{owner = Owner} = MonsterData = mod_monster_data:get_monster_data(MonsterID),
            #c_monster{rarity = Rarity, fight_type = FightType, silver_drop = SilverDrop} = monster_misc:get_monster_config(MonsterData#r_monster.type_id),
            case FightType of
                ?FIGHT_TYPE_PATROL ->
                    ok;
                _ ->
                    MonsterData2 = add_enemy(MonsterData, ActorID, ReduceHP),
                    MonsterData3 = ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, mod_monster_world_boss:reduce_hp(MonsterData2, ReduceSrc, ReduceHP), MonsterData2),
                    MonsterData4 = ?IF(Owner =:= undefined, first_attack(MonsterData3, ReduceSrc), MonsterData3),
                    MonsterData5 = add_attack_list(MonsterData4, Rarity, ReduceHP, ReduceSrc),
                    change_data_by_attack(MonsterID, MonsterData5, Rarity),
                    ?IF(?IS_SILVER(SilverDrop), mod_monster_silver:add_silver(MonsterData4, SilverDrop, ReduceHP), ok)
            end
    end.

%% 更新敌人信息
add_enemy(MonsterData, ActorID, ReduceHP) ->
    #r_monster{first_enemies = FirstList, second_enemies = SecondList} = MonsterData,
    case lists:keyfind(ActorID, #r_monster_enemy.actor_id, FirstList) of
        #r_monster_enemy{total_hurt = OldTotalHurt} = Enemy ->
            Enemy2 = Enemy#r_monster_enemy{total_hurt = OldTotalHurt + ReduceHP, last_att_time = time_tool:now()},
            FirstList2 = lists:keyreplace(ActorID, #r_monster_enemy.actor_id, FirstList, Enemy2),
            SecondList2 = SecondList;
        _ ->
            SecondList2 = lists:keydelete(ActorID, #r_monster_enemy.actor_id, SecondList),
            FirstList2 = [#r_monster_enemy{actor_id = ActorID, total_hurt = ReduceHP, last_att_time = time_tool:now()}|FirstList]
    end,
    MonsterData#r_monster{first_enemies = mod_monster_attack:sort_enemies(FirstList2), second_enemies = SecondList2}.

%% 首刀玩家记录
first_attack(MonsterData, ReduceSrc) ->
    #r_reduce_src{actor_id = ActorID, actor_type = ActorType} = ReduceSrc,
    case ActorType =:= ?ACTOR_TYPE_ROLE of
        true ->
            Owner = #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = ActorID},
            MonsterData#r_monster{owner = Owner};
        _ ->
            MonsterData
    end.

%% 部分场景的怪物，用来记录谁攻击过
add_attack_list(MonsterData, Rarity, ReduceHP, ReduceSrc) ->
    MapID = map_common_dict:get_map_id(),
    IsMarry = ?IS_MAP_MARRY_FEAST(MapID),
    #r_reduce_src{actor_id = ActorID, actor_type = ActorType} = ReduceSrc,
    if
        ActorType =:= ?ACTOR_TYPE_ROLE ->
            #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
            if
                IsMarry -> %% 婚宴地图
                    #r_monster{attack_list = AttackList} = MonsterData,
                    case lists:keymember(ActorID, #r_monster_attack.src_id, AttackList) of
                        true ->
                            MonsterData;
                        _ ->
                            AttackList2 = [#r_monster_attack{src_id = ActorID, src_type = ActorType}|AttackList],
                            MonsterData#r_monster{attack_list = AttackList2}
                    end;
                SubType =:= ?SUB_TYPE_MYTHICAL_BOSS andalso (Rarity =:= ?MONSTER_RARITY_NORMAL orelse Rarity =:= ?MONSTER_RARITY_ELITE) -> %% 神兽岛
                    add_mythical_attack_list(ActorID, ActorType, ReduceHP, MonsterData);
                true ->
                    MonsterData
            end;
        true ->
            MonsterData
    end.

add_mythical_attack_list(ActorID, ActorType, ReduceHP, MonsterData) ->
    #r_monster{attack_list = AttackList} = MonsterData,
    Now = time_tool:now(),
    AttackList2 =
        case lists:keytake(ActorID, #r_monster_attack.src_id, AttackList) of
            {value, #r_monster_attack{attack_hp = AttackHp} = MonsterAttack, AttackListT} ->
                MonsterAttack2 = MonsterAttack#r_monster_attack{last_attack_time = Now, attack_hp = AttackHp + ReduceHP},
                [MonsterAttack2|AttackListT];
            _ ->
                MonsterAttack =
                    #r_monster_attack{
                        src_id = ActorID,
                        src_type = ActorType,
                        last_attack_time = Now,
                        attack_hp = ReduceHP},
                [MonsterAttack|AttackList]
        end,
    MonsterData#r_monster{attack_list = AttackList2}.

change_data_by_attack(MonsterID, MonsterData, Rarity) ->
    #r_monster{
        state = State,
        fight_args = FightArgs,
        next_counter = NextCounter,
        attacked_counter = AttackedCounter} = MonsterData,
    case State of
        ?MONSTER_STATE_RETURN -> %% 回归状态，不改变
            mod_monster_data:set_monster_data(MonsterID, MonsterData);
        _ ->
            IsImmortal = map_monster_server:is_immortal_map(),
            if
                IsImmortal -> %% 塔防副本收到攻击不改变状态
                    mod_monster_data:set_monster_data(MonsterID, MonsterData);
                Rarity =:= ?MONSTER_RARITY_BOSS orelse Rarity =:= ?MONSTER_RARITY_WORLD_BOSS -> %% Boss怪，不会受击;
                    mod_monster_map:monster_stop(MonsterID),
                    MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_FIGHT, patrol_pos = undefined, walk_path=[]},
                    mod_monster_data:set_monster_data(MonsterID, MonsterData2);
                true -> %% 普通怪，非攻击准备状态，是会受击延迟counter
                    NowCounter = mod_monster_data:get_loop_counter(),
                    case FightArgs =/= [] orelse AttackedCounter >= NowCounter of
                        true ->
                            MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_FIGHT},
                            mod_monster_data:set_monster_data(MonsterID, MonsterData2);
                        _ ->
                            mod_monster_map:monster_stop(MonsterID),
                            NextCounter2 = NowCounter + ?ATTACK_COUNTER,
                            MonsterData2 = MonsterData#r_monster{
                                state = ?MONSTER_STATE_FIGHT,
                                patrol_pos = undefined,
                                walk_path=[],
                                next_counter = NextCounter2,
                                attacked_counter = NextCounter2},
                            mod_monster_data:del_counter_monster(MonsterID, NextCounter),
                            mod_monster_data:add_counter_monster(MonsterID, NextCounter2),
                            mod_monster_data:set_monster_data(MonsterID, MonsterData2)
                    end
            end
    end.


%% 对于主动怪来说:二级列表就是他范围以内的都是二级里面的
%% 如果你主动攻击他,那么你就到一级仇恨列表里面
%% 如果你主动攻击后,过了一定时间没有攻击,那么又会跑到二级列表里面,
active_find_enemies(MonsterID, MonsterData, MonsterConfig) ->
    #c_monster{rarity = Rarity, guard_radius = GuardRadiusMs, active_radius = ActiveRadius} = MonsterConfig,
    #r_monster{camp_id = CampID} = MonsterData,
    GuardRadius = erlang:min(GuardRadiusMs, ActiveRadius) div ?TILE_SIZE,
    RecordPos = mod_map_ets:get_actor_pos(MonsterID),
    Slices = mod_map_slice:get_9slices_by_pos(RecordPos),
    SliceRoleList = mod_map_slice:get_roleids_by_slices(Slices),
    MonsterList = mod_map_slice:get_monster_ids_by_slices(Slices),
    HatredList = mod_monster_data:get_hatred_id_list(),
    HatredList2 = HatredList -- (HatredList -- MonsterList),
    case find_hatred_enemy(HatredList2, RecordPos, CampID, GuardRadius) of
        #r_monster_enemy{} = Enemy ->
            Enemy;
        _ ->
            ActorList = ?IF(?IS_MAP_TD(map_common_dict:get_map_id()), MonsterList ++ SliceRoleList, SliceRoleList ++ MonsterList),
            find_normal_enemy(ActorList, RecordPos, CampID, Rarity, GuardRadius)
    end.

%% 先寻找距离最近的嘲讽怪
find_hatred_enemy([], _RecordPos, _CampID, _GuardRadius) ->
    undefined;
find_hatred_enemy(HatredList, RecordPos, CampID, GuardRadius) ->
    DisList =
        lists:foldl(
            fun(ActorID, Acc) ->
                case mod_map_ets:get_actor_mapinfo(ActorID) of
                    #r_map_actor{status = Status, pos = IntPos, camp_id = EnemyCampID} ->
                        ActorPos = map_misc:pos_decode(IntPos),
                        case Status =/= ?MAP_STATUS_DEAD andalso EnemyCampID =/= CampID andalso
                            monster_misc:judge_in_distance(RecordPos, ActorPos, GuardRadius) of
                            true ->
                                [{map_misc:get_dis(ActorPos, RecordPos), ActorID}|Acc];
                            _ ->
                                Acc
                        end;
                    _ ->
                        Acc
                end
            end, [], HatredList),
    case lists:keysort(1, DisList) of
        [{_Dis, ActorID}|_] ->
            #r_monster_enemy{actor_id = ActorID, is_hatred = true};
        _ ->
            undefined
    end.


%% 找普通怪
find_normal_enemy([], _RecordPos, _CampID, _Rarity, _GuardRadius) ->
    undefined;
find_normal_enemy([ActorID|R], RecordPos, CampID, Rarity, GuardRadius) ->
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{buff_status = BuffStatus, status = Status, pos = IntPos, camp_id = EnemyCampID} ->
            case Status =/= ?MAP_STATUS_DEAD andalso not (?IS_BUFF_LIMIT_ATTACK_MONSTER(BuffStatus) andalso Rarity =:= ?MONSTER_RARITY_WORLD_BOSS)
                andalso EnemyCampID =/= CampID andalso
                monster_misc:judge_in_distance(RecordPos, map_misc:pos_decode(IntPos), GuardRadius) of
                true ->
                    #r_monster_enemy{actor_id = ActorID};
                false ->
                    find_normal_enemy(R, RecordPos, CampID, Rarity, GuardRadius)
            end;
        _ ->
            find_normal_enemy(R, RecordPos, CampID, Rarity, GuardRadius)
    end.

%%更新怪物仇恨列表
update_enemy_lists(MonsterData, MonsterPos, GuardRadius) ->
    MonsterData2 = update_first_enemy_list(MonsterData, GuardRadius, MonsterPos),
    update_second_enemy_list(MonsterData2, GuardRadius, MonsterPos).

update_first_enemy_list(MonsterData, GuardRadius, MonsterPos) ->
    #r_monster{owner = Owner, first_enemies = FirstList, second_enemies = SecondList} = MonsterData,
    OwnerEnemies = get_owner_enemies(Owner, GuardRadius, MonsterPos),
    case FirstList of
        [_|_] ->
            {NewFirstList, NewSecondList} =
                lists:foldl(
                    fun(#r_monster_enemy{actor_id  = ActorID, is_hatred = IsHatred} = Info, {Acc, Acc2}) ->
                        case check_normal_enemy(ActorID, GuardRadius, MonsterPos) of
                            false ->
                                {Acc, Acc2};
                            true ->
                                Now =  time_tool:now(),
                                LastAttackTime =  Info#r_monster_enemy.last_att_time,
                                case Now - LastAttackTime > 10 andalso (not IsHatred) of
                                    true ->
                                        NewAcc2 = [Info|Acc2],
                                        {Acc, NewAcc2};
                                    false ->
                                        {[Info|Acc], Acc2}
                                end
                        end
                    end, {[], SecondList}, FirstList),
            MonsterData#r_monster{first_enemies = OwnerEnemies ++ lists:reverse(NewFirstList), second_enemies = lists:reverse(NewSecondList)};
        _ ->
            MonsterData#r_monster{first_enemies = OwnerEnemies}
    end.
update_second_enemy_list(MonsterData, GuardRadius, MonsterPos)->
    SecondList =  MonsterData#r_monster.second_enemies,
    case SecondList of
        [_|_] ->
            NewList =
                lists:foldl(
                    fun(#r_monster_enemy{actor_id  = ActorID} = Info, Acc) ->
                        case check_normal_enemy(ActorID, GuardRadius, MonsterPos) of
                            false ->
                                Acc;
                            true ->
                                [Info|Acc]
                        end
                    end, [], SecondList),
            MonsterData#r_monster{second_enemies = lists:reverse(NewList)};
        _ ->
            MonsterData
    end.
check_normal_enemy(ActorID, Radius, MonsterPos) ->
    monster_misc:judge_in_distance(MonsterPos, mod_map_ets:get_actor_pos(ActorID), Radius) andalso
        check_enemy_can_attack(mod_map_ets:get_actor_mapinfo(ActorID)).

check_enemy_can_attack(#r_map_actor{status = Status}) ->
    not (Status =:= ?MAP_STATUS_DEAD);
check_enemy_can_attack(_) ->
    false.

get_owner_enemies(Owner, GuardRadius, MonsterPos) ->
    case Owner of
        #r_hurt_owner{world_boss_owner = #p_world_boss_owner{owner_id = ActorID}} ->
            case check_normal_enemy(ActorID, GuardRadius, MonsterPos) of
                true ->
                    [#r_monster_enemy{actor_id = ActorID}];
                _ ->
                    []
            end;
        _ ->
            []
    end.

get_enemy(MonsterInfo)->
    #r_monster{
        first_enemies = FirstEnemies,
        second_enemies = SecondEnemies} = MonsterInfo,
    get_enemy2([FirstEnemies, SecondEnemies]).

get_enemy2([]) ->
    0;
get_enemy2([Enemies|T]) ->
    case Enemies of
        [] ->
            get_enemy2(T);
        [Actor|_] ->
            Actor
    end.

sort_enemies(Enemies) ->
    lists:sort(
        fun(A, B) ->
            #r_monster_enemy{total_hurt = TotalHurt1, is_hatred = IsHatred1} = A,
            #r_monster_enemy{total_hurt = TotalHurt2, is_hatred = IsHatred2} = B,
            if
                IsHatred1 ->
                    true;
                IsHatred2 ->
                    false;
                true ->
                    TotalHurt1 >= TotalHurt2
            end
        end, Enemies).