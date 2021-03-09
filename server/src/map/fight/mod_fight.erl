%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2017 14:28
%%%-------------------------------------------------------------------
-module(mod_fight).
-author("laijichang").
-include("global.hrl").
-include("monster.hrl").
-include("proto/mod_role_fight.hrl").

%% API
-export([
    fight_prepare/7,
    fight_prepare/8,
    fight_prepare/9,
    fight/1
]).

-export([
    get_role_effect_list/2
]).

fight_prepare(ActorID, ActorType, DestID, SkillID, StepID, RecordPos, IntPos) ->
    fight_prepare(ActorID, ActorType, DestID, SkillID, StepID, RecordPos, IntPos, true).
fight_prepare(ActorID, ActorType, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos) ->
    fight_prepare(ActorID, ActorType, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos, 0).
fight_prepare(ActorID, ActorType, DestID, SkillID, StepID, RecordPos, IntPos, IsSyncPos, AddNum) ->
    case mod_map_ets:get_actor_pos(ActorID) of
        #r_pos{} = Pos ->
            {RecordPos2, IntPos2, IsSyncPos2} =
                case RecordPos =/= undefined of
                    true -> %% 有可能跟现在位置差太远，要检测
                        ?IF(too_far(Pos, RecordPos), {Pos, map_misc:pos_encode(Pos), false}, {RecordPos, IntPos, IsSyncPos});
                    _ ->
                        {Pos, map_misc:pos_encode(Pos), false}
                end,
            DataRecord = #m_fight_prepare_toc{
                skill_id = SkillID,
                dest_id = DestID,
                step_id = StepID,
                src_id = ActorID,
                src_pos = IntPos2,
                add_num = AddNum},
            map_server:broadcast_by_pos(RecordPos2, DataRecord),
            ?IF(IsSyncPos2, mod_map_actor:move(ActorID, ActorType, RecordPos2, IntPos2), ok),
            ok;

        _ ->
            ignore
    end.

fight(FightArgs) ->
    #fight_args{src_id = ActorID, src_type = ActorType} = FightArgs,
    case catch fight2(FightArgs) of
        ok ->
            ok;
        {error, ErrCode} ->
            fight_error(ActorID, ActorType, ErrCode);
        Error ->
            ?ERROR_MSG("Error:~w", [Error]),
            fight_error(ActorID, ActorType, ?ERROR_COMMON_ROLE_DATA_ERROR)
    end.

fight_error(RoleID, ?ACTOR_TYPE_ROLE, ErrCode) ->
    DataRecord = #m_fight_attack_toc{err_code = ErrCode},
    common_misc:unicast(RoleID, DataRecord);
fight_error(_RoleID, _ActorType, _ErrCode) ->
    ok.

fight2(FightArgs) ->
    #fight_args{
        src_id = SrcID,
        src_type = SrcType,
        skill_id = SkillID,
        enemy_effect_list = EnemyEffectList,
        self_effect_list = SelfEffectList,
        dest_id_list = DestList,
        skill_pos = SkillPos,
        prop_effect_list = PropEffectList} = FightArgs,
    case mod_map_dict:get_fight_attr(SrcID) of
        #actor_fight_attr{} = SFightAttr -> next;
        _ -> SFightAttr = erlang:throw(ok)
    end,
    #r_map_actor{status = Status} = SrcMapInfo = mod_map_ets:get_actor_mapinfo(SrcID),
    ?IF(Status =:= ?MAP_STATUS_DEAD, ?THROW_ERR(?ERROR_FIGHT_ATTACK_004), ok),

    init_fight_list(),
    %% 这里会检查buff的状态和阵营
    {FriendList, EnemyList} = get_effect_list(SrcMapInfo, DestList),
    EnemyIDList = [ ActorID || #actor_fight{actor_id = ActorID} <- EnemyList],
    FriendIDList = [ ActorID || #actor_fight{actor_id = ActorID} <- FriendList],

    SFightAttr2 = SFightAttr#actor_fight_attr{prop_effects = PropEffectList ++ SFightAttr#actor_fight_attr.prop_effects},
    ActorFight = #actor_fight{actor_id = SrcID, actor_type = SrcType, skill_pos = SkillPos, map_info = SrcMapInfo, attr = SFightAttr2},
    enemy_effect(ActorFight, EnemyList, EnemyEffectList),
    self_effect(ActorFight, SelfEffectList, EnemyIDList),

    MFAList = mod_map_dict:get_fight_mfa_list(),
    BCList = mod_map_dict:get_fight_bc_list(),
    ActorList = FriendIDList ++ EnemyIDList,

    R = #m_fight_attack_toc{
        skill_id = SkillID,
        src_id = SrcID,
        effect_list = lists:reverse(BCList),
        skill_pos = SkillPos},
    map_server:broadcast_by_actors([SrcID|ActorList], R),
    %% 执行结果
    [ ?TRY_CATCH(erlang:apply(M, F, A)) || {M, F, A} <- MFAList],
    ok.

enemy_effect(SrcFight, DestList, EffectList) ->
    ?TRY_CATCH([ enemy_effect2(SrcFight, DestFight, EffectList) || DestFight <- DestList]).
enemy_effect2(SrcFight, DestFight, EffectList) ->
    [ mod_fight_effect:enemy_effect(SrcFight, DestFight, Effect) || #r_skill_effect{} = Effect <- EffectList],
    ok.

self_effect(SrcFight, SelfEffectList, EnemyList) ->
    [ mod_fight_effect:self_effect(SrcFight, Effect, EnemyList) || #r_skill_effect{} = Effect <- SelfEffectList],
    ok.

init_fight_list() ->
    mod_map_dict:set_fight_mfa_list([]),
    mod_map_dict:set_fight_bc_list([]).

get_effect_list(SrcMapInfo, DestList) ->
    #r_map_actor{actor_type = SrcActorType} = SrcMapInfo,
    if
        SrcActorType =:= ?ACTOR_TYPE_ROLE ->
            get_role_effect_list(SrcMapInfo, DestList);
        SrcActorType =:= ?ACTOR_TYPE_MONSTER ->
            get_monster_effect_list(SrcMapInfo, DestList);
        SrcActorType =:= ?ACTOR_TYPE_TRAP ->
            get_trap_effect_list(SrcMapInfo, DestList);
        SrcActorType =:= ?ACTOR_TYPE_ROBOT ->
            get_role_effect_list(SrcMapInfo, DestList);
        true ->
            {[], []}
    end.

get_role_effect_list(SrcMapInfo, DestList) ->
    #r_map_actor{pos = IntPos, pk_mode = SrcPKMode} = SrcMapInfo,
    IsSafe = map_misc:is_safe_tile(IntPos),
    SrcPos = map_misc:pos_decode(IntPos),
    if
        SrcPKMode =:= ?PK_MODE_PEACE -> %% 和平模式
            get_role_peace_mode_list(SrcMapInfo, SrcPos, IsSafe, DestList, [], []);
        SrcPKMode =:= ?PK_MODE_FORCE -> %% 强制模式
            get_role_force_mode_list(SrcMapInfo, SrcPos, IsSafe, DestList, [], []);
        SrcPKMode =:= ?PK_MODE_ALL orelse SrcPKMode =:= ?PK_MODE_WORLD_BOSS -> %% 全体模式
            get_role_all_mode_list(SrcMapInfo, SrcPos, IsSafe, DestList, [], []);
        SrcPKMode =:= ?PK_MODE_CAMP ->
            get_role_camp_mode_list(SrcMapInfo, SrcPos, IsSafe, DestList, [], []);
        SrcPKMode =:= ?PK_MODE_SERVER ->
            get_role_server_mode_list(SrcMapInfo, SrcPos, IsSafe, DestList, [], [])
    end.

%% 获取怪物攻击列表
get_monster_effect_list(SrcMapInfo, DestList) ->
    #r_map_actor{pk_mode = SrcPKMode, monster_extra = #p_map_monster{type_id = TypeID}} = SrcMapInfo,
    IsWildAttack = mod_map_dict:get_is_wild_map() andalso monster_misc:is_normal_monster(TypeID),
    if
        IsWildAttack andalso SrcPKMode =:= ?PK_MODE_CAMP ->
            get_wild_camp_mode_list(SrcMapInfo, DestList, [], []);
        SrcPKMode =:= ?PK_MODE_CAMP ->
            get_camp_mode_list(SrcMapInfo, DestList, [], []);
        true ->
            get_camp_mode_list(SrcMapInfo, DestList, [], [])
    end.

get_trap_effect_list(SrcMapInfo, DestList) ->
    #r_map_actor{pos = Pos, trap_extra = #p_map_trap{owner_id = OwnerID, owner_type = OwnerType}} = SrcMapInfo,
    {FriendAcc, EnemyAcc} =
        if
            OwnerType =:= ?ACTOR_TYPE_ROLE ->
                case mod_map_ets:get_actor_mapinfo(OwnerID) of
                    #r_map_actor{} = OwnerMapInfo ->
                        get_role_effect_list(OwnerMapInfo, DestList);
                    _ -> %% 找不到主人就用和平模式。
                        get_role_peace_mode_list(SrcMapInfo, map_misc:pos_decode(Pos), map_misc:is_safe_tile(Pos), DestList, [], [])
                end;
            true ->
                get_camp_mode_list(SrcMapInfo, DestList, [], [])
        end,
    {FriendAcc, lists:keydelete(OwnerID, #actor_fight.actor_id, EnemyAcc)}.

%% 角色 & 陷阱 和平模式
get_role_peace_mode_list(_SrcMapInfo, _SrcPos, _IsSafe, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_role_peace_mode_list(SrcMapInfo, SrcPos, IsSafe, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, camp_id = SrcCampID, buff_status = BuffStatus} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{pos = IntPos, camp_id = DestCampID, actor_type = DestActorType, buff_status = DestBuffStatus, role_extra = RoleExtra} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) orelse too_far(SrcPos, map_misc:pos_decode(IntPos)) of
                true ->
                    get_role_peace_mode_list(SrcMapInfo, SrcPos, IntPos, R, FriendAcc, EnemyAcc);
                _ ->
                    IsAttackRole = ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE, RoleExtra#p_map_role.pk_value > 0 andalso not (IsSafe orelse map_misc:is_safe_tile(IntPos)), false),
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    case SrcCampID =/= DestCampID orelse IsAttackRole of
                        true ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = [ActorFight|EnemyAcc];
                        _ ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = EnemyAcc
                    end,
                    get_role_peace_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_role_peace_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc)
    end.

%% 角色 & 陷阱 强制模式
get_role_force_mode_list(_SrcMapInfo, _SrcPos, _IsSafe, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_role_force_mode_list(SrcMapInfo, SrcPos, IsSafe, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, buff_status = BuffStatus, role_extra = #p_map_role{team_id = TeamID, family_id = FamilyID}} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{pos = IntPos, actor_type = DestActorType, buff_status = DestBuffStatus, role_extra = RoleExtra} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) orelse too_far(SrcPos, map_misc:pos_decode(IntPos)) of
                true ->
                    get_role_force_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc);
                _ ->
                    case DestActorType =:= ?ACTOR_TYPE_ROLE of
                        true ->
                            #p_map_role{team_id = DestTeamID, family_id = DestFamilyID} = RoleExtra,
                            IsMember = (TeamID =:= DestTeamID andalso DestTeamID =/= 0) orelse (FamilyID =:= DestFamilyID andalso DestFamilyID =/= 0),
                            IsEnemyFilter = IsMember orelse (IsSafe orelse map_misc:is_safe_tile(IntPos)) ;
                        _ ->
                            IsEnemyFilter = false
                    end,
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    case IsEnemyFilter of
                        true ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = EnemyAcc;
                        _ ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = [ActorFight|EnemyAcc]
                    end,
                    get_role_force_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_role_force_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc)
    end.

%% 全体模式
get_role_all_mode_list(_SrcMapInfo, _SrcPos, _IsSafe, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_role_all_mode_list(SrcMapInfo, SrcPos, IsSafe, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, buff_status = BuffStatus} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{pos = IntPos, actor_type = DestActorType, buff_status = DestBuffStatus} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) orelse too_far(SrcPos, map_misc:pos_decode(IntPos))of
                true ->
                    get_role_all_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc);
                _ ->
                    IsEnemyFilter = DestActorType =:= ?ACTOR_TYPE_ROLE andalso (IsSafe orelse map_misc:is_safe_tile(IntPos)),
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    EnemyAcc2 = ?IF(IsEnemyFilter, EnemyAcc, [ActorFight|EnemyAcc]),
                    get_role_all_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc2)
            end;
        _ ->
            get_role_all_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc)
    end.

%% 获取角色阵营模式的列表
get_role_camp_mode_list(_SrcMapInfo, _SrcPos, _IsSafe, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_role_camp_mode_list(SrcMapInfo, SrcPos, IsSafe, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, camp_id = SrcCampID, buff_status = BuffStatus} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{pos = IntPos, camp_id = DestCampID, buff_status = DestBuffStatus, actor_type = DestActorType} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) orelse too_far(SrcPos, map_misc:pos_decode(IntPos)) of
                true ->
                    get_role_camp_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc);
                _ ->
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    IsEnemyFilter = DestActorType =:= ?ACTOR_TYPE_ROLE andalso (IsSafe orelse map_misc:is_safe_tile(IntPos)),
                    if
                        SrcCampID =:= DestCampID ->
                            FriendAcc2 = [ActorFight|FriendAcc],
                            EnemyAcc2 = EnemyAcc;
                        IsEnemyFilter ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = EnemyAcc;
                        true ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = [ActorFight|EnemyAcc]
                    end,
                    get_role_camp_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_role_camp_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc)
    end.

get_role_server_mode_list(_SrcMapInfo, _SrcPos, _IsSafe, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_role_server_mode_list(SrcMapInfo, SrcPos, IsSafe, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, buff_status = BuffStatus, role_extra = #p_map_role{server_id = ServerID}} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{pos = IntPos, buff_status = DestBuffStatus, actor_type = DestActorType, role_extra = DestRoleExtra} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) orelse too_far(SrcPos, map_misc:pos_decode(IntPos)) of
                true ->
                    get_role_server_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc);
                _ ->
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    case DestActorType =:= ?ACTOR_TYPE_ROLE of
                        true ->
                            #p_map_role{server_id = DestServerID} = DestRoleExtra,
                            IsEnemyFilter = (ServerID =:= DestServerID) orelse (IsSafe orelse map_misc:is_safe_tile(IntPos));
                        _ ->
                            IsEnemyFilter = false
                    end,
                    case IsEnemyFilter of
                        true ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = EnemyAcc;
                        _ ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = [ActorFight|EnemyAcc]
                    end,
                    get_role_server_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_role_server_mode_list(SrcMapInfo, SrcPos, IsSafe, R, FriendAcc, EnemyAcc)
    end.


%% 获取阵营模式的列表
get_camp_mode_list(_SrcMapInfo, [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_camp_mode_list(SrcMapInfo, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, camp_id = SrcCampID, buff_status = BuffStatus} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{camp_id = DestCampID, buff_status = DestBuffStatus, actor_type = DestActorType} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) of
                true ->
                    get_camp_mode_list(SrcMapInfo, R, FriendAcc, EnemyAcc);
                _ ->
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    case SrcCampID =:= DestCampID of
                        true ->
                            FriendAcc2 = [ActorFight|FriendAcc],
                            EnemyAcc2 = EnemyAcc;
                        _ ->
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = [ActorFight|EnemyAcc]
                    end,
                    get_camp_mode_list(SrcMapInfo, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_camp_mode_list(SrcMapInfo, R, FriendAcc, EnemyAcc)
    end.

%% 野外小怪，1秒内最多3个怪物能打玩家
get_wild_camp_mode_list(_SrcMapInfo,  [], FriendAcc, EnemyAcc) ->
    {FriendAcc, EnemyAcc};
get_wild_camp_mode_list(SrcMapInfo, [ActorID|R], FriendAcc, EnemyAcc) ->
    #r_map_actor{actor_type = SrcActorType, camp_id = SrcCampID, buff_status = BuffStatus} = SrcMapInfo,
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{actor_type = DestActorType, camp_id = DestCampID, buff_status = DestBuffStatus} = DestMapInfo ->
            case is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) of
                true ->
                    get_wild_camp_mode_list(SrcMapInfo, R, FriendAcc, EnemyAcc);
                _ ->
                    ActorFight = #actor_fight{actor_id = ActorID, actor_type = DestActorType, map_info = DestMapInfo, attr = mod_map_dict:get_fight_attr(ActorID)},
                    case SrcCampID =:= DestCampID of
                        true ->
                            FriendAcc2 = [ActorFight|FriendAcc],
                            EnemyAcc2 = EnemyAcc;
                        _ ->
                            IsFilter = ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE, is_wild_filter(ActorID), false),
                            FriendAcc2 = FriendAcc,
                            EnemyAcc2 = ?IF(IsFilter, EnemyAcc, [ActorFight|EnemyAcc])
                    end,
                    get_wild_camp_mode_list(SrcMapInfo, R, FriendAcc2, EnemyAcc2)
            end;
        _ ->
            get_wild_camp_mode_list(SrcMapInfo, R, FriendAcc, EnemyAcc)
    end.

is_wild_filter(RoleID) ->
    #r_map_role{
        attack_time = AttackTime,
        attack_times = AttackTimes} = MapRole = mod_map_ets:get_map_role(RoleID),
    Now = time_tool:now(),
    case Now =:= AttackTime of
        true ->
            case AttackTimes >= 3 of
                true ->
                    true;
                _ ->
                    mod_map_ets:set_map_role(RoleID, MapRole#r_map_role{attack_times = AttackTimes + 1}),
                    false
            end;
        _ ->
            mod_map_ets:set_map_role(RoleID, MapRole#r_map_role{attack_time = Now, attack_times = 1}),
            false
    end.


%% 攻击怪物检查
is_limit(BuffStatus, DestBuffStatus, SrcActorType, SrcMapInfo, ?ACTOR_TYPE_MONSTER, DestMapInfo) ->
    case is_limit2(DestBuffStatus) of
        true ->
            true;
        _ ->
            if
                ?IS_BUFF_LIMIT_ATTACK_MONSTER(BuffStatus) -> %% 先判断buff
                    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = DestMapInfo,
                    monster_misc:is_world_boss(TypeID);
                SrcActorType =:= ?ACTOR_TYPE_ROLE -> %% 玩家攻击怪物时不能超过一定等级
                    #r_map_actor{role_extra = #p_map_role{level = RoleLevel}} = SrcMapInfo,
                    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = DestMapInfo,
                    #c_monster{attack_limit_level = LimitLevel} = monster_misc:get_monster_config(TypeID),
                    LimitLevel > 0 andalso RoleLevel >= LimitLevel;
                true ->
                    false
            end
    end;
is_limit(_BuffStatus, DestBuffStatus, _SrcActorType, _SrcMapInfo, DestActorType, _DestMapInfo) ->
    not lists:member(DestActorType, ?ATTACK_LIST) orelse is_limit2(DestBuffStatus).

%% 通用检查
is_limit2(DestBuffStatus) ->
    ?IS_BUFF_LIMIT_UNBEATABLE(DestBuffStatus).

too_far(SrcPos, DestPos) ->
    map_misc:get_dis(SrcPos, DestPos) >= 10 * ?TILE_SIZE.