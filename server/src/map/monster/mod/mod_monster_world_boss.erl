%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     怪物进程下的world_boss模块
%%% @end
%%% Created : 18. 一月 2018 19:28
%%%-------------------------------------------------------------------
-module(mod_monster_world_boss).
-author("laijichang").
-include("monster.hrl").
-include("team.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_world_boss.hrl").

%% API
-export([
    loop/1,
    rank/2,
    reduce_hp/3,
    recover_hp/1
]).

-export([
    role_leave_map/1,
    role_dead/3
]).

-export([
    get_drop_roles/1,
    get_assist_roles/2,
    get_mythical_monster/1
]).

loop(Now) ->
    case Now rem 3 =:= 0 of
        true ->
            [begin
                 MonsterData = mod_monster_data:get_monster_data(MonsterID),
                 MonsterData2 = rank(Now, MonsterData),
                 mod_monster_data:set_monster_data(MonsterID, MonsterData2)
             end || MonsterID <- mod_monster_data:get_world_boss_id_list()];
        _ ->
            ok
    end.

rank(Now, MonsterData) ->
    #r_monster{
        monster_id = MonsterID,
        type_id = TypeID,
        owner = OldOwner,
        world_boss = WorldBoss} = MonsterData,
    RankType = get_boss_rank_type(TypeID),
    #r_monster_world_boss{role_hurt_list = RoleHurtList} = WorldBoss,
    if
        RankType =:= ?RANK_FIRST_BOSS ->
            MonsterData;
        RankType =:= ?RANK_PEACE_BOSS ->
            Owner = OldOwner,
            RoleHurtList2 = rank_peace_boss(RoleHurtList, Now, []),
            rank2(RoleHurtList2, Owner, WorldBoss, MonsterData);
        true ->
            {RoleHurtList2, Owner} = rank_boss(RoleHurtList, Now, []),
            ?IF((OldOwner =:= undefined andalso Owner#r_hurt_owner.type_args =/= undefined) orelse
                (OldOwner =/= undefined andalso OldOwner =/= Owner),
                mod_map_monster:monster_world_boss_owner(MonsterID, Owner#r_hurt_owner.world_boss_owner),
                ok),
            rank2(RoleHurtList2, Owner, WorldBoss, MonsterData)
    end.

rank2(RoleHurtList2, Owner, WorldBoss, MonsterData) ->
    RankList = get_rank_list(RoleHurtList2),
    ?IF(RankList =/= [], mod_map_monster:broadcast_world_boss_rank(MonsterData#r_monster.monster_id, #m_world_boss_rank_toc{ranks = RankList}), ok),
    WorldBoss2 = WorldBoss#r_monster_world_boss{role_hurt_list = RoleHurtList2},
    MonsterData#r_monster{owner = Owner, world_boss = WorldBoss2}.

rank_boss([], _Now, RoleHurtAcc) ->
    {RoleHurtAcc, get_owner(RoleHurtAcc)};
rank_boss([RoleHurt|R], Now, RoleHurtAcc) ->
    #r_role_hurt{last_attack_time = LastAttackTime} = RoleHurt,
    case Now - LastAttackTime >= ?WORLD_BOSS_INTERVAL of
        true ->
            rank_boss(R, Now, RoleHurtAcc);
        _ ->
            rank_boss(R, Now, [RoleHurt|RoleHurtAcc])
    end.

%%rank_normal_boss([], _Now, RoleHurtAcc, HurtList) ->
%%    {RoleHurtAcc, get_owner(HurtList)};
%%rank_normal_boss([RoleHurt|R], Now, RoleHurtAcc, HurtList) ->
%%    #r_role_hurt{
%%        role_id = RoleID,
%%        hurt_hp = HurtHp,
%%        last_attack_time = LastAttackTime,
%%        team_id = TeamID} = RoleHurt,
%%    case Now - LastAttackTime >= ?WORLD_BOSS_INTERVAL of
%%        true ->
%%            rank_normal_boss(R, Now, RoleHurtAcc, HurtList);
%%        _ ->
%%            RoleHurtAcc2 = [RoleHurt|RoleHurtAcc],
%%            HurtList2 =
%%                if
%%                    ?HAS_TEAM(TeamID) ->
%%                        case lists:keyfind(TeamID, #p_kvt.id, HurtList) of
%%                            #p_kvt{val = AllHurtHp} = Hurt ->
%%                                Hurt2 = Hurt#p_kvt{val = HurtHp + AllHurtHp},
%%                                lists:keyreplace(TeamID, #p_kvt.id, HurtList, Hurt2);
%%                            _ ->
%%                                Hurt = #p_kvt{id = TeamID, val = HurtHp, type = ?HURT_OWNER_TEAM},
%%                                [Hurt|HurtList]
%%                        end;
%%                    true ->
%%                        Hurt = #p_kvt{id = RoleID, val = HurtHp, type = ?HURT_OWNER_ROLE},
%%                        [Hurt|HurtList]
%%                end,
%%            rank_normal_boss(R, Now, RoleHurtAcc2, HurtList2)
%%    end.

rank_peace_boss([], _Now, RoleHurtAcc) ->
    RoleHurtAcc;
rank_peace_boss([RoleHurt|R], Now, RoleHurtAcc) ->
    #r_role_hurt{last_attack_time = LastAttackTime} = RoleHurt,
    case Now - LastAttackTime >= ?WORLD_BOSS_INTERVAL of
        true ->
            rank_peace_boss(R, Now, RoleHurtAcc);
        _ ->
            rank_peace_boss(R, Now, [RoleHurt|RoleHurtAcc])
    end.

reduce_hp(MonsterData, ReduceSrc, ReduceHp) ->
    #r_reduce_src{
        actor_id = ActorID,
        actor_name = ActorName,
        actor_type = ActorType,
        actor_level = ActorLevel,
        team_id = TeamID,
        family_id = FamilyID} = ReduceSrc,
    case ActorType of
        ?ACTOR_TYPE_ROLE ->
            #r_monster{monster_id = MonsterID, owner = Owner, type_id = TypeID, world_boss = WorldBoss} = MonsterData,
            RankType = get_boss_rank_type(TypeID),
            if
                RankType =:= ?RANK_FIRST_BOSS -> %% 世界boss，首刀
                    WorldBossOwner = #p_world_boss_owner{
                        owner_id = ActorID,
                        owner_name = ActorName,
                        owner_level = ActorLevel,
                        family_id = FamilyID,
                        team_id = TeamID},
                    case Owner of
                        undefined ->
                            WorldBossOwner = #p_world_boss_owner{
                                owner_id = ActorID,
                                owner_name = ActorName,
                                owner_level = ActorLevel,
                                family_id = FamilyID, team_id = TeamID},
                            Owner2 = #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = ActorID, world_boss_owner = WorldBossOwner},
                            mod_map_monster:monster_world_boss_owner(MonsterID, WorldBossOwner),
                            MonsterData#r_monster{owner = Owner2};
                        #r_hurt_owner{type_args = ActorID, world_boss_owner = OldWorldBossOwner} when OldWorldBossOwner =/= WorldBossOwner -> %% 跟旧的归属一致，更新玩家信息
                            Owner2 = #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = ActorID, world_boss_owner = WorldBossOwner},
                            mod_map_monster:monster_world_boss_owner(MonsterID, WorldBossOwner),
                            MonsterData#r_monster{owner = Owner2};
                        _ ->
                            MonsterData
                    end;
                true -> %% 其他按伤害
                    #r_monster_world_boss{role_hurt_list = RoleHurtList} = WorldBoss,
                    case lists:keyfind(ActorID, #r_role_hurt.role_id, RoleHurtList) of
                        #r_role_hurt{hurt_hp = HurtHp} = RoleHurt ->
                            RoleHurt2 = RoleHurt#r_role_hurt{
                                role_name = ActorName,
                                role_level = ActorLevel,
                                hurt_hp = HurtHp + ReduceHp,
                                last_attack_time = time_tool:now(),
                                team_id = TeamID,
                                family_id = FamilyID},
                            RoleHurtList2 = lists:keyreplace(ActorID, #r_role_hurt.role_id, RoleHurtList, RoleHurt2);
                        _ ->
                            RoleHurt = #r_role_hurt{
                                role_id = ActorID,
                                role_name = ActorName,
                                role_level = ActorLevel,
                                hurt_hp = ReduceHp,
                                last_attack_time = time_tool:now(),
                                team_id = TeamID,
                                family_id = FamilyID},
                            RoleHurtList2 = [RoleHurt|RoleHurtList]
                    end,
                    WorldBoss2 = WorldBoss#r_monster_world_boss{role_hurt_list = RoleHurtList2},
                    MonsterData#r_monster{world_boss = WorldBoss2}
            end;
        _ ->
            MonsterData
    end.

get_owner([]) ->
    #r_hurt_owner{};
get_owner(List) ->
    [                     #r_role_hurt{
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        family_id = FamilyID,
        team_id = TeamID}|_] = lists:reverse(lists:keysort(#r_role_hurt.hurt_hp, List)),
    WorldBossOwner = #p_world_boss_owner{
        owner_id = RoleID,
        owner_name = RoleName,
        owner_level = RoleLevel,
        family_id = FamilyID,
        team_id = TeamID
    },
    %% 临时方案，直接归属于个人
    #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = RoleID, world_boss_owner = WorldBossOwner}.

%% 世界boss接口 -- 角色离开地图
role_leave_map(RoleID) ->
    [begin
         MonsterData = mod_monster_data:get_monster_data(MonsterID),
         MonsterData2 = role_leave_map2(RoleID, MonsterData),
         mod_monster_data:set_monster_data(MonsterID, MonsterData2)
     end || MonsterID <- mod_monster_data:get_world_boss_id_list()].

role_leave_map2(RoleID, MonsterData) ->
    #r_monster{monster_id = MonsterID, owner = Owner} = MonsterData,
    case Owner of
        #r_hurt_owner{type_args = RoleID} ->
            mod_map_monster:monster_world_boss_owner(MonsterID, undefined),
            MonsterData#r_monster{owner = undefined};
        _ ->
            MonsterData
    end.

%% 世界boss接口 -- 角色死亡
role_dead(RoleID, SrcActorID, SrcActorType) ->
    case SrcActorType of
        ?ACTOR_TYPE_ROLE ->
            [begin
                 MonsterData = mod_monster_data:get_monster_data(MonsterID),
                 MonsterData2 = role_dead2(RoleID, SrcActorID, MonsterData),
                 mod_monster_data:set_monster_data(MonsterID, MonsterData2)
             end || MonsterID <- mod_monster_data:get_world_boss_id_list()];
        _ ->
            role_leave_map(RoleID)
    end.

role_dead2(RoleID, SrcActorID, MonsterData) ->
    #r_monster{monster_id = MonsterID, owner = Owner} = MonsterData,
    case Owner of
        #r_hurt_owner{type_args = RoleID, world_boss_owner = #p_world_boss_owner{owner_name = OldOwnerName}} ->
            case mod_map_ets:get_actor_mapinfo(SrcActorID) of
                #r_map_actor{actor_name = ActorName, role_extra = #p_map_role{level = Level, family_id = FamilyID, team_id = TeamID}} ->
                    WorldBossOwner = #p_world_boss_owner{
                        owner_id = SrcActorID,
                        owner_name = ActorName,
                        owner_level = Level,
                        family_id = FamilyID,
                        team_id = TeamID},
                    Owner2 = #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = SrcActorID, world_boss_owner = WorldBossOwner},
                    mod_map_monster:monster_world_boss_owner(MonsterID, WorldBossOwner),
                    mod_map_monster:owner_change_broadcast(OldOwnerName, ActorName),
                    MonsterData#r_monster{owner = Owner2};
                _ ->
                    role_leave_map2(RoleID, MonsterData)
            end;
        _ ->
            MonsterData
    end.

get_rank_list([]) ->
    [];
get_rank_list(RoleHurtList) ->
    NeedNum = common_misc:get_global_int(?GLOBAL_WORLD_BOSS_RANK),
    RoleHurtList2 = lists:sublist(lists:reverse(lists:keysort(#r_role_hurt.hurt_hp, RoleHurtList)), NeedNum),
    {_Rank, RankList} =
    lists:foldl(
        fun(#r_role_hurt{role_id = ActorID, role_name = ActorName, hurt_hp = HurtHp}, {RankAcc, RankListAcc}) ->
            Rank = #p_world_boss_rank{
                rank = RankAcc,
                role_id = ActorID,
                role_name = ActorName,
                damage = HurtHp
            },
            {RankAcc + 1, [Rank|RankListAcc]}
        end, {1, []}, RoleHurtList2),
    RankList.

recover_hp(MonsterData) ->
    #r_monster{
        monster_id = MonsterID,
        type_id = TypeID,
        last_attack_time = LastAttackTime,
        world_boss = WorldBoss,
        attr = FightAttr} = MonsterData,
    #r_monster_world_boss{recover_time = RecoverTime} = WorldBoss,
    NowMs = time_tool:now_ms(),
    RankType = get_boss_rank_type(TypeID),
    case RankType =/= ?RANK_FIRST_BOSS andalso NowMs >= RecoverTime andalso NowMs >= LastAttackTime + ?WORLD_BOSS_RECOVER_MS of
        true -> %% 世界boss不回血
            mod_map_monster:monster_buff_heal(MonsterID, FightAttr#actor_fight_attr.max_hp, ?BUFF_ADD_HP, 0),
            MonsterData#r_monster{world_boss = WorldBoss#r_monster_world_boss{recover_time = NowMs + ?WORLD_BOSS_RECOVER_MS, role_hurt_list = []}};
        _ ->
            MonsterData
    end.

get_drop_roles(MonsterData) ->
    #r_monster{
        owner = Owner,
        type_id = TypeID,
        world_boss = WorldBoss} = MonsterData,
    RankType = get_boss_rank_type(TypeID),
    Roles =
    if
        RankType =:= ?RANK_PEACE_BOSS ->
            #r_monster_world_boss{role_hurt_list = RoleHurtList} = WorldBoss,
            [NeedNum|_] = common_misc:get_global_list(?GLOBAL_WORLD_BOSS_RANK),
            RolesT = [RoleID || #r_role_hurt{role_id = RoleID} <- lists:sublist(lists:reverse(lists:keysort(#r_role_hurt.hurt_hp, RoleHurtList)), NeedNum)],
            RolesT2 = monster_misc:filter_other_map_roles(RolesT),
            case common_misc:get_global_int(?GLOBAL_FIRST_WORLD_BOSS) =:= TypeID of
                true -> %% 第一只和平boss有特殊处理，满足条件的不管排名都给
                    get_first_world_boss_roles(RolesT2, RoleHurtList);
                _ ->
                    RolesT2
            end;
        RankType =:= ?RANK_FIRST_BOSS ->
            case Owner of
                #r_hurt_owner{type_args = OwnerRoleID} ->
                    [OwnerRoleID];
                _ ->
                    ?ERROR_MSG("Unknow Owner: ~w", [Owner]),
                    []
            end;
        true ->
            #r_monster_world_boss{role_hurt_list = RoleHurtList} = WorldBoss,
            RolesT = [RoleID || #r_role_hurt{role_id = RoleID} <- lists:reverse(lists:keysort(#r_role_hurt.hurt_hp, RoleHurtList))],
            get_first_boss_roles(RolesT)
    end,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(map_common_dict:get_map_id()),
    if
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS ->
            lists:filter(
                fun(RoleID) ->
                    #r_map_role{mythical_times = MythicalTimes} = mod_map_ets:get_map_role(RoleID),
                    MythicalTimes > 0 end,
                Roles);
        true ->
            Roles
    end.

%% 和平boss掉落
get_first_world_boss_roles(Roles, RoleHurtList) ->
    [MinLevel, MaxLevel|_] = common_misc:get_global_list(?GLOBAL_FIRST_WORLD_BOSS),
    lists:foldl(
        fun(#r_role_hurt{role_id = RoleID}, Acc) ->
            case lists:member(RoleID, Acc) of
                true ->
                    Acc;
                _ ->
                    case mod_map_ets:get_actor_mapinfo(RoleID) of
                        #r_map_actor{role_extra = #p_map_role{level = RoleLevel}} when MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel ->
                            [RoleID|Acc];
                        _ ->
                            Acc
                    end
            end
        end, Roles, RoleHurtList).

%% 世界boss专属掉落（不能不在这个地图、不能是死亡状态）
get_first_boss_roles([]) ->
    [];
get_first_boss_roles([RoleID|R]) ->
    case mod_map_ets:get_actor_mapinfo(RoleID) of
        #r_map_actor{status = Status} when Status =/= ?MAP_STATUS_DEAD ->
            [RoleID];
        _ ->
            get_first_boss_roles(R)
    end.

get_assist_roles(MonsterData, RoleID) ->
    #r_monster{world_boss = WorldBoss} = MonsterData,
    #r_monster_world_boss{role_hurt_list = RoleHurtList} = WorldBoss,
    #r_role_hurt{family_id = FamilyID, team_id = TeamID} = lists:keyfind(RoleID, #r_role_hurt.role_id, RoleHurtList),
    RoleHurtList2 = lists:sublist(lists:reverse(lists:keysort(#r_role_hurt.hurt_hp, RoleHurtList)), 5),
    get_assist_roles2(RoleID, FamilyID, TeamID, RoleHurtList2, []).

get_assist_roles2(_RoleID, _FamilyID, _TeamID, [], AssistRoles) ->
    AssistRoles;
get_assist_roles2(RoleID, FamilyID, TeamID, [RoleHurt|R], AssistRoles) ->
    #r_role_hurt{
        role_id = AssistRoleID,
        family_id = AssistFamilyID,
        team_id = AssistTeamID
    } = RoleHurt,
    AssistRoles2 =
    case AssistRoleID =/= RoleID andalso ((FamilyID =:= AssistFamilyID andalso FamilyID > 0) orelse (TeamID =:= AssistTeamID andalso TeamID > 0)) of
        true ->
            [AssistRoleID|AssistRoles];
        _ ->
            AssistRoles
    end,
    get_assist_roles2(RoleID, FamilyID, TeamID, R, AssistRoles2).

get_mythical_monster(AttackList) ->
    AttackList2 = lists:reverse(lists:keysort(#r_monster_attack.attack_hp, AttackList)),
    Now = time_tool:now(),
    InMapRoles = mod_map_ets:get_in_map_roles(),
    get_mythical_monster2(AttackList2, Now, InMapRoles).

get_mythical_monster2([], _Now, _InMapRoles) ->
    [0];
get_mythical_monster2([#r_monster_attack{src_id = SrcID, last_attack_time = LastAttackTime}|R], Now, InMapRoles) ->
    case Now - LastAttackTime =< ?ONE_MINUTE andalso lists:member(SrcID, InMapRoles) of %% 不超过一分钟，并且在这个地图中
        true ->
            [SrcID];
        _ ->
            get_mythical_monster2(R, Now, InMapRoles)
    end.

get_boss_rank_type(TypeID) ->
    case lib_config:find(cfg_world_boss, TypeID) of
        [#c_world_boss{type = Type, is_safe = IsSafe}] ->
            if
                IsSafe > 0 ->
                    ?RANK_PEACE_BOSS;
                Type =:= ?BOSS_TYPE_WORLD_BOSS ->
                    ?RANK_FIRST_BOSS;
                true ->
                    ?RANK_NORMAL_BOSS
            end;
        _ ->
            ?RANK_NORMAL_BOSS
    end.

