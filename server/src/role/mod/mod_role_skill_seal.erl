%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     技能铭文效果 || 接口
%%% @end
%%% Created : 21. 五月 2019 11:28
%%%-------------------------------------------------------------------
-module(mod_role_skill_seal).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    update_active_ids/2
]).

-export([
    handle/2
]).

-export([
    add_seals/2,
    del_seals/2,
    seal_loop/3,
    modify_seals/1
]).

-export([
    update_seal_all_level/1
]).

-export([
    get_positive_effect/1,
    get_fight_effect/1,
    get_hit_again_props/2,

    do_fight_effect_change/1
]).

update_active_ids(RoleID, ActiveIDs) ->
    role_misc:info_role(RoleID, ?MODULE, {update_active_ids, ActiveIDs}).

handle({update_active_ids, ActiveIDs}, State) ->
    do_update_active_ids(ActiveIDs, State).

add_seals(SealID, State) ->
    [#c_skill_seal{
        type = SealType,
        sub_type = SubType
    }] = lib_config:find(cfg_skill_seal, SealID),
    case SealType of
        ?SEAL_TYPE_PASSIVE ->
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{seal_passive_list = PassiveList} = RoleSkill,
            SkillSealList = get_seals_by_sub_type(SubType, PassiveList),
            SkillSealList2 = add_seals2(SealID, SkillSealList, []),
            PassiveList2 = replace_seals_by_sub_type(SubType, PassiveList, SkillSealList2),
            RoleSkill2 = RoleSkill#r_role_skill{seal_passive_list = PassiveList2},
            State2 = State#r_role{role_skill = RoleSkill2},
            do_seal_change(SubType, State2);
        _ ->
            State
    end.

add_seals2(SealID, [], SkillSealAcc) ->
    [#r_skill_seal{seal_id = SealID, time = 0}|SkillSealAcc];
add_seals2(SealID, [#r_skill_seal{seal_id = DestSealID} = SkillSeal|R], SkillSealAcc) ->
    case ?GET_BASE_ID(SealID) =:= ?GET_BASE_ID(DestSealID) of
        true ->
            [SkillSeal#r_skill_seal{seal_id = SealID}|SkillSealAcc] ++ R;
        _ ->
            add_seals2(SealID, R, [SkillSeal|SkillSealAcc])
    end.

del_seals(SealID, State) ->
    [#c_skill_seal{
        type = SealType,
        sub_type = SubType
    }] = lib_config:find(cfg_skill_seal, SealID),
    case SealType of
        ?SEAL_TYPE_PASSIVE ->
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{seal_passive_list = PassiveList} = RoleSkill,
            SkillSealList = get_seals_by_sub_type(SubType, PassiveList),
            SkillSealList2 = del_seals(SealID, SkillSealList, []),
            PassiveList2 = replace_seals_by_sub_type(SubType, PassiveList, SkillSealList2),
            RoleSkill2 = RoleSkill#r_role_skill{seal_passive_list = PassiveList2},
            State2 = State#r_role{role_skill = RoleSkill2},
            do_seal_change(SubType, State2);
        _ ->
            State
    end.

del_seals(_SealID, [], SkillSealAcc) ->
    SkillSealAcc;
del_seals(SealID, [#r_skill_seal{seal_id = DestSealID} = SkillSeal|R], SkillSealAcc) ->
    case ?GET_BASE_ID(SealID) =:= ?GET_BASE_ID(DestSealID) of
        true ->
           SkillSealAcc ++ R;
        _ ->
            del_seals(SealID, R, [SkillSeal|SkillSealAcc])
    end.

seal_loop(NowMs, HpRate, State) ->
    #r_role{role_id = RoleID,
        role_fight = #r_role_fight{fight_attr = FightAttr},
        role_skill = RoleSkill} = State,
    #r_role_skill{seal_passive_list = PassiveList} = RoleSkill,
    SealList = get_seals_by_sub_type(?SEAL_PASSIVE_INTERVAL_ADD, PassiveList),
    {SealList2, SelfAddBuffs, EnemyAddBuffs} = seal_loop2(SealList, NowMs, HpRate, [], [], []),
    ?IF(SelfAddBuffs =/= [], role_misc:add_buff(RoleID, common_buff:get_add_buffs(SelfAddBuffs, RoleID, FightAttr)), ok),
    ?IF(EnemyAddBuffs =/= [], mod_map_role:role_add_enemy_buffs(mod_role_dict:get_map_pid(), RoleID, common_buff:get_add_buffs(EnemyAddBuffs, RoleID, FightAttr)), ok),
    PassiveList2 = replace_seals_by_sub_type(?SEAL_PASSIVE_INTERVAL_ADD, PassiveList, SealList2),
    RoleSkill2 = RoleSkill#r_role_skill{seal_passive_list = PassiveList2},
    State#r_role{role_skill = RoleSkill2}.

seal_loop2([], _NowMs, _HpRate, SealAcc, SelfAddBuffs, EnemyAddBuffs) ->
    {SealAcc, SelfAddBuffs, EnemyAddBuffs};
seal_loop2([Seal|R], NowMs, HpRate, SealAcc, SelfAddBuffs, EnemyAddBuffs) ->
    #r_skill_seal{seal_id = SealID, time = Time} = Seal,
    case NowMs >= Time of
        true ->
            [#c_skill_seal{
                passive_condition = PassiveCondition,
                passive_self_buffs = PassiveSelfBuffs,
                passive_enemy_buffs = PassiveEnemyBuffs,
                passive_cd = CD
            }] = lib_config:find(cfg_skill_seal, SealID),
            {IsActive, SelfAddBuffs2, EnemyAddBuffs2} =
                case PassiveCondition of
                    [?SEAL_PASSIVE_INTERVAL_BELOW_HP_RATE, NeedHpRate] ->
                        ?IF(HpRate =< NeedHpRate, {true, PassiveSelfBuffs ++ SelfAddBuffs, PassiveEnemyBuffs ++ EnemyAddBuffs},
                            {false, SelfAddBuffs, EnemyAddBuffs});
                    _ ->
                        {true, PassiveSelfBuffs ++ SelfAddBuffs, PassiveEnemyBuffs ++ EnemyAddBuffs}
                end,
            Seal2 = ?IF(IsActive, Seal#r_skill_seal{time = NowMs + CD}, Seal),
            SealAcc2 = [Seal2|SealAcc],
            seal_loop2(R, NowMs, HpRate, SealAcc2, SelfAddBuffs2, EnemyAddBuffs2);
        _ ->
            seal_loop2(R, NowMs, HpRate, [Seal|SealAcc], SelfAddBuffs, EnemyAddBuffs)
    end.


get_seals_by_sub_type(SubType, PassiveList) ->
    case lists:keyfind(SubType, #p_kvl.id, PassiveList) of
        #p_kvl{list = SealList} ->
            SealList;
        _ ->
            []
    end.

do_seal_change(SubType, State) ->
    if
        SubType =:= ?SEAL_PASSIVE_ATTACK orelse SubType =:= ?SEAL_PASSIVE_BE_ATTACKED orelse SubType =:= ?SEAL_PASSIVE_REBOUND ->
            do_fight_effect_change(State),
            State;
        true ->
            State
    end.

do_fight_effect_change(State) ->
    FightEffect = get_fight_effect(State),
    mod_map_role:update_role_fight_effect(mod_role_dict:get_map_pid(), State#r_role.role_id, FightEffect).

replace_seals_by_sub_type(SubType, PassiveList, SealSkillList) ->
    lists:keystore(SubType, #p_kvl.id, PassiveList, #p_kvl{id = SubType, list = SealSkillList}).

update_seal_all_level(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    Level1 = get_seal_all_level(AttackList, 0),
    AllLevel = Level1 + lists:sum([ get_seal_all_level(List, 0) || #p_kvl{list = List} <- PassiveList]),
    State#r_role{seal_all_level = AllLevel}.

get_seal_all_level([], Acc) ->
    Acc;
get_seal_all_level([#p_skill{seal_id_list = SealIDList}|R], Acc) ->
    case SealIDList =/= [] of
        true ->
            AddLevel =
                lists:sum( [ begin
                                 [#c_skill_seal{seal_level = SealLevel}] = lib_config:find(cfg_skill_seal, SealID),
                                 SealLevel
                             end|| SealID <- SealIDList]),
            get_seal_all_level(R, AddLevel + Acc);
        _ ->
            get_seal_all_level(R, Acc)
    end.

get_positive_effect(0) ->
    #seal_effect_args{
        prop_effects = mod_role_dict:erase_must_double_effect()
    };
get_positive_effect(SealID) ->
    [#c_skill_seal{
        rate = Rate,
        positive_self_buffs = SelfBuffs,
        positive_enemy_buffs = EnemyBuffs,
        positive_add_props = AddProps
    }] = lib_config:find(cfg_skill_seal, SealID),
    PropEffects =
        case AddProps =/= [] of
            true ->
                [#actor_prop_effect{
                    type = ?PROP_TYPE_NORMAL_HIT,
                    hp_rate = ?RATE_10000,
                    rate = Rate,
                    add_props = common_misc:get_string_props(AddProps)}];
            _ ->
                []
        end,
    PropEffects2 = mod_role_dict:erase_must_double_effect() ++ PropEffects,
    IsActive = common_misc:is_active(Rate),
    SelfBuffEffects = ?IF(SelfBuffs =/= [] andalso IsActive, [#r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = SelfBuffs}], []),
    EnemyBuffEffects = ?IF(EnemyBuffs =/= [] andalso IsActive, [#r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = EnemyBuffs}], []),
    case ?GET_SEAL_BASE_ID(SealID) =:= ?SEAL_BASE_DOUBLE of
        true -> %% 下次必定暴击
            DoubleRatePropEffect =
                [#actor_prop_effect{
                    type = ?PROP_TYPE_NORMAL_HIT,
                    hp_rate = ?RATE_10000,
                    rate = Rate,
                    add_props = [#p_kv{id = ?ATTR_DOUBLE_RATE, val = ?RATE_10000}]}],
            mod_role_dict:set_must_double_effect(DoubleRatePropEffect);
        _ ->
            ok
    end,
    #seal_effect_args{
        self_buff_effects = SelfBuffEffects,
        enemy_buff_effects = EnemyBuffEffects,
        prop_effects = PropEffects2
    }.

get_fight_effect(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{seal_passive_list = SealPassiveList} = RoleSkill,
    AttackList = get_seals_by_sub_type(?SEAL_PASSIVE_ATTACK, SealPassiveList),
    BeAttackList = get_seals_by_sub_type(?SEAL_PASSIVE_BE_ATTACKED, SealPassiveList),
    ReboundList = get_seals_by_sub_type(?SEAL_PASSIVE_REBOUND, SealPassiveList),
    sort_fight_effect(mod_role_skill:get_fight_effects(RoleSkill) ++ get_fight_effect2(ReboundList ++ AttackList ++ BeAttackList, []), []).

get_fight_effect2([], FightEffectAcc) ->
    FightEffectAcc;
get_fight_effect2([#r_skill_seal{seal_id = SealID, time = Time}|R], FightEffectAcc) ->
    [#c_skill_seal{
        rate = Rate,
        sub_type = SubType,
        passive_condition = Condition,
        passive_self_buffs = SelfBuffs,
        passive_enemy_buffs = EnemyBuffs,
        passive_cd  = CD,
        passive_args = Args
    }] = lib_config:find(cfg_skill_seal, SealID),
    FightEffect = #r_fight_effect{
        id = SealID,
        type = get_fight_effect_type(SubType),
        rate = Rate,
        condition = Condition,
        self_buffs = SelfBuffs,
        enemy_buffs = EnemyBuffs,
        args = Args,
        cd = CD,
        time = Time
    },
    get_fight_effect2(R, [FightEffect|FightEffectAcc]).

get_fight_effect_type(SubType) ->
    if
        SubType =:= ?SEAL_PASSIVE_ATTACK ->
            ?FIGHT_EFFECT_ATTACK;
        SubType =:= ?SEAL_PASSIVE_BE_ATTACKED ->
            ?FIGHT_EFFECT_BE_ATTACKED;
        SubType =:= ?SEAL_PASSIVE_REBOUND ->
            ?FIGHT_EFFECT_REBOUND
    end.

sort_fight_effect([], Acc) ->
    Acc;
sort_fight_effect([FightEffect|R], Acc) ->
    Type = FightEffect#r_fight_effect.type,
    Acc2 =
        case lists:keytake(FightEffect#r_fight_effect.type, 1, Acc) of
            {value, {Type, List}, AccT} ->
                [{Type, [FightEffect|List]}|AccT];
            _ ->
                [{Type, [FightEffect]}|Acc]
        end,
    sort_fight_effect(R, Acc2).

%% 风卷残云特殊属性加成
get_hit_again_props(SkillID, State) ->
    #c_skill{skill_type_id = SkillTypeID} = common_skill:get_skill_config(SkillID),
    case SkillTypeID =:= 1103 of
        true -> %% 风卷残云
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{seal_passive_list = PassiveList} = RoleSkill,
            SealList = get_seals_by_sub_type(?SEAL_PASSIVE_SKILL_PROP_ADD, PassiveList),
            case SealList of
                [#r_skill_seal{seal_id = SealID}|_] ->
                    [#c_skill_seal{rate = Rate, passive_args = PassiveArgs}] = lib_config:find(cfg_skill_seal, SealID),
                    case PassiveArgs of
                        [AddDouble] ->
                            [#actor_prop_effect{
                                type = ?PROP_TYPE_NORMAL_HIT,
                                hp_rate = ?RATE_10000,
                                rate = Rate,
                                add_props = [#p_kv{id = ?ATTR_DOUBLE, val = AddDouble}]}];
                        _ ->
                            []
                    end;
                _ ->
                    []
            end;
        _ ->
            []
    end.

do_update_active_ids(ActiveIDs, State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{seal_passive_list = PassiveList} = RoleSkill,
    NowMs = time_tool:now_ms(),
    {PassiveList2, OtherIDs} = do_update_active_ids2(ActiveIDs, NowMs, PassiveList, []),
    RoleSkill2 = RoleSkill#r_role_skill{seal_passive_list = PassiveList2},
    RoleSkill3 = mod_role_skill:update_fight_effect(OtherIDs, NowMs, RoleSkill2),
    State#r_role{role_skill = RoleSkill3}.

do_update_active_ids2([], _NowMs, PassiveList, OtherIDs) ->
    {PassiveList, OtherIDs};
do_update_active_ids2([ActiveID|R], NowMs, PassiveList, OtherIDs) ->
    case lib_config:find(cfg_skill_seal, ActiveID) of
        [#c_skill_seal{sub_type = SubType, passive_cd = CD}] ->
            SealList = get_seals_by_sub_type(SubType, PassiveList),
            case lists:keytake(ActiveID, #r_skill_seal.seal_id, SealList) of
                {value, #r_skill_seal{} = SkillSeal, SealList2} ->
                    SkillSeal2 = SkillSeal#r_skill_seal{time = NowMs + CD},
                    SealList3 = [SkillSeal2|SealList2],
                    PassiveList2 = replace_seals_by_sub_type(SubType, PassiveList, SealList3),
                    do_update_active_ids2(R, NowMs, PassiveList2, OtherIDs);
                _ ->
                    do_update_active_ids2(R, NowMs, PassiveList, [ActiveID|OtherIDs])
            end;
        _ ->
            do_update_active_ids2(R, NowMs, PassiveList, [ActiveID|OtherIDs])
    end.

modify_seals(RoleSkill) ->
    #r_role_skill{
        attack_list = AttackList,
        passive_list = SkillPassiveList,
        seal_passive_list = SealPassiveList} = RoleSkill,
    AllSkills = AttackList ++ lists:flatten([ SkillList || #p_kvl{list = SkillList}<- SkillPassiveList]),
    SealIDList = [ SealID|| #p_skill{seal_id = SealID} <- AllSkills, SealID > 0],
    SealSkillList = [ SealList || #p_kvl{list = SealList} <- SealPassiveList],
    SealPassiveList2 = modify_seals2(SealIDList, SealSkillList, []),
    RoleSkill#r_role_skill{seal_passive_list = SealPassiveList2}.

modify_seals2([], _SealSkillList, PassiveAcc) ->
    PassiveAcc;
modify_seals2([SealID|R], SealSkillList, PassiveAcc) ->
    case lib_config:find(cfg_skill_seal, SealID) of
        [#c_skill_seal{type = SealType, sub_type = SubType}] ->
            case SealType of
                ?SEAL_TYPE_PASSIVE ->
                    {Seal, SealSkillList2} =
                        case lists:keytake(SealID, #r_skill_seal.seal_id, SealSkillList) of
                            {value, SealT, SealSkillListT} ->
                                {SealT, SealSkillListT};
                            _ ->
                                {#r_skill_seal{seal_id = SealID}, SealSkillList}
                        end,
                    SkillAcc = get_seals_by_sub_type(SubType, PassiveAcc),
                    PassiveAcc2 = replace_seals_by_sub_type(SubType, PassiveAcc, [Seal|SkillAcc]),
                    modify_seals2(R, SealSkillList2, PassiveAcc2);
                _ ->
                    modify_seals2(R, SealSkillList, PassiveAcc)
            end;
        _ ->
            modify_seals2(R, SealSkillList, PassiveAcc)
    end.
