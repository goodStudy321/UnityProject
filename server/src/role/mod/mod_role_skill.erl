%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2017 9:49
%%%-------------------------------------------------------------------
-module(mod_role_skill).
-author("laijichang").
-include("role.hrl").
-include("team.hrl").
-include("proto/mod_role_skill.hrl").
-include("proto/mod_role_fight.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    loop/2,
    handle/2
]).

-export([
    attack_result/2,
    role_double/1,
    map_prop_effect/2
]).

-export([
    skill_open/2,
    skill_fun_change/3,
    get_hit_effect/2,
    get_fight_skill/2,
    get_again_effect/2,
    war_spirit_buff/1,
    buff_trigger/2,
    get_map_prop_effects/1,
    get_skill_add_value/1,
    get_skill_add_num/1,
    get_skill_cd/2,
    get_skill_times_effect/2
]).

-export([
    gm_clear_skills/1
]).

-export([
    role_be_attacked/1,
    role_fight_status_change/0,
    add_team_buffs/1,
    member_join/2,
    hp_change_buffs/2,
    do_attack_result/2
]).

-export([
    get_fight_effects/1,
    update_fight_effect/3
]).

init(#r_role{role_id = RoleID, role_attr = RoleAttr, role_skill = undefined} = State) ->
    #r_role_attr{sex = Sex, level = Level} = RoleAttr,
    [#c_level{skill_list = SkillString}] = lib_config:find(cfg_level, {Sex, Level}),
    [FirstSkillID|_] = string:tokens(SkillString, "_"),
    RoleSkill =
        #r_role_skill{
            role_id = RoleID,
            attack_list = [#p_skill{skill_id = lib_tool:to_integer(FirstSkillID)}]
        },
    State#r_role{role_skill = RoleSkill};
init(State) ->
    State.

calc(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    State2 = mod_role_skill_seal:update_seal_all_level(State),
    List =
        lists:flatten([begin
                           #c_skill{props = PropString} = common_skill:get_skill_config(SkillID),
                           common_misc:get_string_props(PropString)
                       end || #p_skill{skill_id = SkillID} <- get_skills_by_sub_type(?SKILL_PASSIVE_PROP, PassiveList)]),
    CalcAttr = role_misc:get_attr_by_kv(List, State2),
    SkillPropList =
        lists:flatten([begin
                           #c_skill{props = PropString} = common_skill:get_skill_config(SkillID),
                           common_misc:get_string_props(PropString)
                       end || #p_skill{skill_id = SkillID} <- get_skills_by_sub_type(?SKILL_PASSIVE_ONLY_PROP, PassiveList)]),
    SkillPropAttr = role_misc:get_attr_by_kv(SkillPropList, State2),
    calc_recover_hp_rate(State2),
    AddPropEffects = get_add_prop_effects(get_skills_by_sub_type(?SKILL_PASSIVE_ADD_HIT_PROP, PassiveList)),
    PropEffects =
        [begin
             #c_skill{hit_prop_condition = [Type, HpRate, Rate], props = PropString} = common_skill:get_skill_config(SkillID),
             %% 部分技能加强8被动类型的效果
             {AddRate, AddProps} =
                 case lists:keyfind(SkillID, #p_kvs.id, AddPropEffects) of
                     #p_kvs{val = AddRateT, text = AddPropT} ->
                         {AddRateT, AddPropT};
                     _ ->
                         {0, []}
                 end,
             #actor_prop_effect{
                 type = Type,
                 hp_rate = HpRate,
                 rate = Rate + AddRate,
                 add_props = common_misc:merge_props(AddProps ++ common_misc:get_string_props(PropString))}
         end || #p_skill{skill_id = SkillID} <- get_skills_by_sub_type(?SKILL_PASSIVE_HIT_PROP, PassiveList)],
    {PropRates, PropKVList} = get_prop_rate_and_attr(get_skills_by_sub_type(?SKILL_PASSIVE_ADD_OTHER_PROP, PassiveList)),
    SkillPowerList = calc_skill_power_list(RoleSkill),
    State3 = State2#r_role{prop_effects = PropEffects},
    State4 = State3#r_role{prop_rates = common_misc:merge_props(PropRates), skill_prop_attr = SkillPropAttr, skill_power_list = SkillPowerList},
    mod_role_fight:get_state_by_kv(State4, ?CALC_KEY_SKILL_PASSIVE, common_misc:sum_calc_attr2(CalcAttr, role_misc:get_attr_by_kv(PropKVList, State4))).

calc_skill_power_list(RoleSkill) ->
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    SkillPowerList = calc_skill_power_list2(AttackList, []),
    lists:foldl(
        fun(#p_kvl{list = SkillList}, SkillPowerAcc) ->
            calc_skill_power_list2(SkillList, SkillPowerAcc)
        end, SkillPowerList, PassiveList).

calc_skill_power_list2([], SkillPowerAcc) ->
    common_misc:merge_props(SkillPowerAcc);
calc_skill_power_list2([#p_skill{skill_id = SkillID}|R], SkillPowerAcc) ->
    #c_skill{power_type = PowerType, power_val = PowerVal} = common_skill:get_skill_config(SkillID),
    case PowerType > ?SKILL_POWER_NOT of
        true ->
            calc_skill_power_list2(R, [#p_kv{id = PowerType, val = PowerVal}|SkillPowerAcc]);
        _ ->
            calc_skill_power_list2(R, SkillPowerAcc)
    end.

calc_recover_hp_rate(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    List =
        [begin
             #c_skill{props = PropString, add_buff_args = MaxRecoverHp} = common_skill:get_skill_config(SkillID),
             lists:foldl(
                 fun(KV, Acc) ->
                     case string:tokens(KV, ",") of
                         [Key, Value] ->
                             Key2 = lib_tool:to_integer(Key),
                             case lists:member(Key2, [?ATTR_LEVEL_RECOVER_HP_RATE]) of
                                 true ->
                                     [#p_kvt{id = Key2, val = lib_tool:to_integer(Value), type = MaxRecoverHp}|Acc];
                                 _ ->
                                     Acc
                             end;
                         _ -> Acc
                     end
                 end, [], string:tokens(PropString, "|"))
         end || #p_skill{skill_id = SkillID} <- get_skills_by_sub_type(?SKILL_PASSIVE_PROP, PassiveList)],
    calc_recover_hp_rate2(lists:flatten(List)).

calc_recover_hp_rate2(List) ->
    HpRateList =
        lists:foldl(
            fun(#p_kvt{id = Key, val = Val, type = MaxRecoverHp}, HpRateAcc) ->
                if
                    Key =:= ?ATTR_LEVEL_RECOVER_HP_RATE ->
                        [{Val, MaxRecoverHp}|HpRateAcc];
                    true ->
                        HpRateAcc
                end
            end, [], List),
    mod_role_dict:set_recover_hp_rate(HpRateList).

get_prop_rate_and_attr(SkillList) ->
    lists:foldl(
        fun(#p_skill{skill_id = SkillID}, {Acc1, Acc2}) ->
            #c_skill{props = PropString} = common_skill:get_skill_config(SkillID),
            get_prop_rate_and_attr(common_misc:get_string_props(PropString), Acc1, Acc2)
        end, {[], []}, SkillList).

get_prop_rate_and_attr([], PropRates, PropKVList) ->
    {PropRates, PropKVList};
get_prop_rate_and_attr([#p_kv{id = ID} = KV|R], PropRates, PropList) ->
    case lists:member(ID, ?SKILL_OTHER_PROP_LIST) of
        true ->
            get_prop_rate_and_attr(R, [KV|PropRates], PropList);
        _ ->
            get_prop_rate_and_attr(R, PropRates, [KV|PropList])
    end.

calc_prop_rate(State) ->
    List = [mod_role_pet, mod_role_wing, mod_role_magic_weapon, mod_role_mount],
    lists:foldl(fun(Mod, State2) -> Mod:calc(State2) end, State, List).

online(#r_role{role_id = RoleID, role_skill = RoleSkill} = State) ->
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    PassiveList2 = modify_passive_list(PassiveList),
    RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
    State2 = State#r_role{role_skill = RoleSkill2},
    FrontPassives = lists:flatten([Skills || #p_kvl{list = Skills} <- PassiveList2]),
    common_misc:unicast(RoleID, #m_role_skill_toc{skill_list = AttackList ++ FrontPassives}),
    update_skill_add_hurt(PassiveList2),
    update_skill_target_num(RoleID, PassiveList2),
    update_skill_cd(RoleID, PassiveList2),
    State3 = add_team_buffs(State2),
    modify_hp_buffs(State3).

loop(Now, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill, role_fight = #r_role_fight{fight_attr = FightAttr}} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    AddBuffs = get_skills_by_sub_type(?SKILL_PASSIVE_ADD_BUFF, PassiveList),
    NowMs = Now * 1000,
    HpRate = get_hp_rate(State),
    AddBuffs2 =
        lists:foldl(
            fun(#p_skill{skill_id = SkillID, time = Time} = Skill, Acc) ->
                case NowMs >= Time of
                    true ->
                        #c_skill{
                            add_buff_type = AddBuffType,
                            add_buff_args = AddBuffArgs,
                            self_buffs = Buffs} = SkillConfig = common_skill:get_skill_config(SkillID),
                        if
                            AddBuffType =:= ?ADD_BUFF_HP ->
                                IsAdd = HpRate =/= ?RATE_10000 andalso (HpRate < AddBuffArgs orelse AddBuffArgs =:= 0);
                            AddBuffType =:= ?ADD_BUFF_MONSTER_ATTACK ->
                                IsAdd = mod_role_dict:get_attack_times(?ACTOR_TYPE_MONSTER) >= AddBuffArgs;
                            true ->
                                IsAdd = true
                        end,
                        case IsAdd of
                            true ->
                                Skill2 = Skill#p_skill{time = get_skill_cd(SkillConfig, NowMs)},
                                Buffs2 = common_buff:get_add_buffs(Buffs, RoleID, FightAttr),
                                role_misc:add_buff(RoleID, Buffs2),
                                [Skill2|Acc];
                            _ ->
                                [Skill|Acc]
                        end;
                    _ ->
                        [Skill|Acc]
                end
            end, [], AddBuffs),
    State2 = State#r_role{role_skill = RoleSkill#r_role_skill{passive_list = replace_skills_by_sub_type(?SKILL_PASSIVE_ADD_BUFF, PassiveList, AddBuffs2)}},
    State3 = mod_role_skill_seal:seal_loop(NowMs, HpRate, State2),
    do_hp_attr(Now, HpRate, PassiveList, State3).

handle({attack_result, Type}, State) ->
    do_attack_result(Type, State);
handle(role_double, State) ->
    mod_role_dict:set_skill_times(0),
    State;
handle({map_prop_effect, PropEffect}, State) ->
    do_map_prop_effect(PropEffect, State);
handle({#m_skill_up_tos{skill_id = SkillID}, RoleID, _PID}, State) ->
    do_skill_up(RoleID, SkillID, State);
handle({#m_skill_seal_choose_tos{skill_id = SkillID, seal_id = SealID}, RoleID, _PID}, State) ->
    do_seal_choose(RoleID, SkillID, SealID, State);
handle({#m_skill_seal_level_tos{skill_id = SkillID, seal_id = SealID}, RoleID, _PID}, State) ->
    do_seal_level(RoleID, SkillID, SealID, State).

attack_result(RoleID, Type) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {attack_result, Type}}).

role_double(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, role_double}).

map_prop_effect(RoleID, PropEffect) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {map_prop_effect, PropEffect}}).

gm_clear_skills(State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    SkillIDList1 = [SkillID || #p_skill{skill_id = SkillID} <- AttackList],
    SkillIDList2 = lists:flatten([[SkillID || #p_skill{skill_id = SkillID} <- List] || #p_kvl{list = List} <- PassiveList]),
    common_misc:unicast(RoleID, #m_skill_update_toc{del_list = SkillIDList1 ++ SkillIDList2}),
    State2 = State#r_role{role_skill = undefined},
    online(init(State2)).

%% 外部接口调用，开启技能
skill_open(SkillID, State) ->
    State2 = do_skill_open(SkillID, State),
    hook_role:skill_open(State2, SkillID).

%% 养成功能改变，技能全部替换
%% SkillFun      -- 参考fight.hrl
%% ReplaceSkills -- SkillIDList
skill_fun_change(SkillFun, ReplaceSkills, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    {AttackList2, ReplaceSkills2, UpdateList1, DelList1} = skill_fun_change2(SkillFun, ReplaceSkills, ?SKILL_ATTACK, 0, AttackList),
    {AttackList3, ReplaceSkills3, UpdateList2, DelList2} = skill_fun_change2(SkillFun, ReplaceSkills2, ?SKILL_NORMAL, 0, AttackList2),
    {PassiveList2, _ReplaceSkills4, UpdateList3, DelList3} =
        lists:foldl(
            fun(SubType, {PassiveAcc, ReplacesAcc, UpdateAcc, DelAcc}) ->
                Skills = get_skills_by_sub_type(SubType, PassiveAcc),
                {Skills2, ReplacesAcc2, UpdateAcc2, DelAcc2} = skill_fun_change2(SkillFun, ReplacesAcc, ?SKILL_PASSIVE, SubType, Skills),
                PassiveAcc2 = replace_skills_by_sub_type(SubType, PassiveAcc, Skills2),
                {PassiveAcc2, ReplacesAcc2, UpdateAcc2 ++ UpdateAcc, DelAcc2 ++ DelAcc}
            end, {PassiveList, ReplaceSkills3, [], []}, ?SKILL_PASSIVE_LIST),
    DataRecord = #m_skill_update_toc{
        update_list = UpdateList1 ++ UpdateList2 ++ UpdateList3,
        del_list = DelList1 ++ DelList2 ++ DelList3
    },
    common_misc:unicast(RoleID, DataRecord),
    RoleSkill2 = RoleSkill#r_role_skill{attack_list = AttackList3, passive_list = PassiveList2},
    State2 = State#r_role{role_skill = RoleSkill2},
    UpdateIDList = [PassiveSkillID || #p_skill{skill_id = PassiveSkillID} <- UpdateList3],
    {IsPropChange, IsPropRateChange, IsTeamBuffChange, IsMapPropChange, IsFightEffectChange, IsSkillAddHurtChange, IsSkillTargetNumChange, IsSkillCDChange} =
        lists:foldl(
            fun(SkillID, {Acc1, Acc2, Acc3, Acc4, Acc5, Acc6, Acc7, Acc8}) ->
                #c_skill{skill_type = SkillType, sub_skill_type = SubType, power_type = PowerType} = common_skill:get_skill_config(SkillID),
                {(SkillType =:= ?SKILL_PASSIVE andalso is_prop_change_sub_type(SubType)) orelse PowerType > ?SKILL_POWER_NOT orelse Acc1,
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_OTHER_PROP) orelse Acc2,
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_TEAM_BUFF) orelse Acc3,
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_MAP_PROP_EFFECT) orelse Acc4,
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_FIGHT_BUFF) orelse Acc5,
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_HURT orelse Acc6),
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_TARGET_NUM orelse Acc7),
                    (SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_REDUCE_CD orelse Acc8)}
            end, {false, false, false, false, false, false, false, false}, UpdateIDList ++ DelList3),
    ?IF(IsMapPropChange, update_map_prop_effect(State2), ok),
    ?IF(IsFightEffectChange, mod_role_skill_seal:do_fight_effect_change(State2), ok),
    ?IF(IsSkillAddHurtChange, update_skill_add_hurt(PassiveList2), ok),
    ?IF(IsSkillTargetNumChange, update_skill_target_num(RoleID, PassiveList2), ok),
    ?IF(IsSkillCDChange, update_skill_cd(RoleID, PassiveList2), ok),
    State3 =
        case IsPropChange of
            true ->
                StateAcc = ?IF(IsPropRateChange, calc_prop_rate(calc(State2)), calc(State2)),
                mod_role_fight:calc_attr_and_update(StateAcc, ?POWER_UPDATE_PASSIVE_SKILL, SkillFun);
            _ ->
                State2
        end,
    ?IF(IsTeamBuffChange, add_team_buffs(State3), State3).


skill_fun_change2(SkillFun, ReplaceSkills, SkillType, SubType, Skills) ->
    {Skills2, DelList, DelSkills} =
        lists:foldl(
            fun(#p_skill{skill_id = SkillID} = Skill, {Acc, DelAcc, DelSkillsAcc}) ->
                #c_skill{skill_type = SkillTypeT, sub_skill_type = SubTypeT} = common_skill:get_skill_config(SkillID),
                case ?GET_SKILL_FUN(SkillID) =:= SkillFun andalso is_same_type(SkillType, SubType, SkillTypeT, SubTypeT) of
                    true ->
                        {Acc, [SkillID|DelAcc], [Skill|DelSkillsAcc]};
                    _ ->
                        {[Skill|Acc], DelAcc, DelSkillsAcc}
                end
            end, {[], [], []}, Skills),
    lists:foldl(
        fun(ReplaceID, {SkillsAcc, ReplaceAcc, UpdateAcc, DelAcc}) ->
            #c_skill{skill_type = ReplaceSkillType, sub_skill_type = ReplaceSubType} = ReplaceConfig = common_skill:get_skill_config(ReplaceID),
            case is_same_type(SkillType, SubType, ReplaceSkillType, ReplaceSubType) of
                true ->
                    {SkillsAcc2, UpdateList, AddDelList} = do_skill_open2(ReplaceID, ReplaceConfig, SkillsAcc, DelSkills, []),
                    {UpdateAcc2, DelAcc2} =
                        case lists:member(ReplaceID, DelAcc) of
                            true ->
                                {UpdateAcc, AddDelList ++ lists:delete(ReplaceID, DelAcc)};
                            _ ->
                                {UpdateList ++ UpdateAcc, AddDelList ++ DelAcc}
                        end,
                    {SkillsAcc2, ReplaceAcc, UpdateAcc2, DelAcc2};
                _ ->
                    {SkillsAcc, [ReplaceID|ReplaceAcc], UpdateAcc, DelAcc}
            end
        end, {Skills2, [], [], DelList}, ReplaceSkills).

is_same_type(SkillType, SubType, ReplaceSkillType, ReplaceSubType) ->
    if
        SkillType =:= ReplaceSkillType andalso SkillType =:= ?SKILL_PASSIVE ->
            SubType =:= ReplaceSubType;
        true ->
            SkillType =:= ReplaceSkillType
    end.

get_hit_effect(SkillID, State) ->
    #c_skill{skill_type = SkillType} = common_skill:get_skill_config(SkillID),
    case SkillType =:= ?SKILL_NORMAL orelse SkillType =:= ?SKILL_ATTACK of
        true ->
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{passive_list = PassiveList} = RoleSkill,
            NowMs = time_tool:now_ms(),
            PassiveHitBuffs = get_skills_by_sub_type(?SKILL_PASSIVE_HIT_BUFF, PassiveList),
            {PassiveHitBuffs2, EnemyBuffList, SelfBuffList} = get_hit_effect2(PassiveHitBuffs, ?GET_SKILL_FUN(SkillID), NowMs, [], [], []),
            PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_HIT_BUFF, PassiveList, PassiveHitBuffs2),
            RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
            State2 = State#r_role{role_skill = RoleSkill2},
            {[#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_BUFF, value = EnemyBuffList}],
                [#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_BUFF, value = SelfBuffList}], State2};
        _ ->
            {[], [], State}
    end.

get_hit_effect2([], _SkillFun, _NowMs, PassiveHitBuffsAcc, EnemyBuffAcc, SelfBuffAcc) ->
    {PassiveHitBuffsAcc, EnemyBuffAcc, SelfBuffAcc};
get_hit_effect2([Skill|R], SkillFun, NowMs, PassiveHitBuffsAcc, EnemyBuffAcc, SelfBuffAcc) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    case is_skill_fun_match(SkillFun, ?GET_SKILL_FUN(SkillID)) andalso NowMs > Time of
        true -> %% 同一类型的技能才能触发
            #c_skill{hit_buffs = HitBuffs, effect_type = EffectType} = common_skill:get_skill_config(SkillID),
            case HitBuffs of
                [Rate|BuffList] ->
                    case common_misc:is_active(Rate) of
                        true ->
                            Skill2 = Skill#p_skill{time = NowMs},
                            PassiveHitBuffsAcc2 = [Skill2|PassiveHitBuffsAcc],
                            {EnemyBuffAcc2, SelfBuffAcc2} = ?IF(EffectType =:= ?TARGET_TYPE_SELF,
                                {EnemyBuffAcc, BuffList ++ SelfBuffAcc}, {BuffList ++ EnemyBuffAcc, SelfBuffAcc});
                        _ ->
                            PassiveHitBuffsAcc2 = [Skill|PassiveHitBuffsAcc],
                            EnemyBuffAcc2 = EnemyBuffAcc,
                            SelfBuffAcc2 = SelfBuffAcc
                    end,
                    get_hit_effect2(R, SkillFun, NowMs, PassiveHitBuffsAcc2, EnemyBuffAcc2, SelfBuffAcc2);
                _ ->
                    get_hit_effect2(R, SkillFun, NowMs, [Skill|PassiveHitBuffsAcc], EnemyBuffAcc, SelfBuffAcc)
            end;
        _ ->
            get_hit_effect2(R, SkillFun, NowMs, [Skill|PassiveHitBuffsAcc], EnemyBuffAcc, SelfBuffAcc)
    end.

get_fight_skill(SkillID, RoleSkill) ->
    case lists:keyfind(SkillID, #p_skill.skill_id, RoleSkill#r_role_skill.attack_list) of
        #p_skill{} = Skill ->
            Skill;
        _ ->
            PassiveList = get_skills_by_sub_type(?SKILL_PASSIVE_ATTACK_AGAIN, RoleSkill#r_role_skill.passive_list),
            case lists:keyfind(SkillID, #p_skill.skill_id, PassiveList) of
                #p_skill{} = Skill -> Skill;
                _ -> ?THROW_ERR(?ERROR_FIGHT_ATTACK_001)
            end
    end.

%% 获取再次攻击效果
get_again_effect(SkillID, State) ->
    #c_skill{skill_type = SkillType} = common_skill:get_skill_config(SkillID),
    case SkillType =:= ?SKILL_NORMAL orelse SkillType =:= ?SKILL_ATTACK of
        true ->
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{passive_list = PassiveList} = RoleSkill,
            NowMs = time_tool:now_ms(),
            SkillFun = ?GET_SKILL_FUN(SkillID),
            HitAgain = get_skills_by_sub_type(?SKILL_PASSIVE_HIT_AGAIN, PassiveList),
            {HitAgain2, HitAgainEffects} = get_hit_again_effect(HitAgain, SkillFun, NowMs, State, [], []),
            PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_HIT_AGAIN, PassiveList, HitAgain2),

            case SkillFun =:= ?ACTOR_TYPE_ROLE of
                true -> %% 角色的技能才能触发
                    AttackAgain = get_skills_by_sub_type(?SKILL_PASSIVE_ATTACK_AGAIN, PassiveList),
                    {AttackAgain2, AttackSkillIDs} = get_attack_again_effect(AttackAgain, NowMs, [], []),
                    PassiveList3 = replace_skills_by_sub_type(?SKILL_PASSIVE_ATTACK_AGAIN, PassiveList2, AttackAgain2);
                _ ->
                    AttackSkillIDs = [],
                    PassiveList3 = PassiveList2
            end,

            RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList3},
            State2 = State#r_role{role_skill = RoleSkill2},
            {HitAgainEffects, AttackSkillIDs, State2};
        _ ->
            {[], [], State}
    end.

get_hit_again_effect([], _SkillFun, _NowMs, _State, HitAgainAcc, EffectAcc) ->
    {HitAgainAcc, EffectAcc};
get_hit_again_effect([Skill|R], SkillFun, NowMs, State, HitAgainAcc, EffectAcc) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    case is_skill_fun_match(SkillFun, ?GET_SKILL_FUN(SkillID)) andalso NowMs > Time of
        true -> %% 同一类型的技能才能触发
            #c_skill{hit_again_args = HitAgainArgs, skill_type = SkillType, hit_value = HitValueString} = SkillConfig = common_skill:get_skill_config(SkillID),
            case HitAgainArgs of
                [Rate, HitNum] ->
                    case common_misc:is_active(Rate) of
                        true ->
                            Skill2 = Skill#p_skill{time = get_skill_cd(SkillConfig, NowMs)},
                            HitAgainAcc2 = [Skill2|HitAgainAcc],
                            [[{_Delay, HitValue}|_]|_] = common_skill:get_hit_value_list(HitValueString, get_skill_add_value(SkillID)),
                            PropEffects = mod_role_skill_seal:get_hit_again_props(SkillID, State),
                            Effect = #r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_HIT_AGAIN, value = SkillID, args = {HitNum, HitValue, PropEffects}},
                            EffectAcc2 = [Effect|EffectAcc];
                        _ ->
                            HitAgainAcc2 = [Skill|HitAgainAcc],
                            EffectAcc2 = EffectAcc
                    end,
                    get_hit_again_effect(R, SkillFun, NowMs, State, HitAgainAcc2, EffectAcc2);
                _ ->
                    get_hit_again_effect(R, SkillFun, NowMs, State, [Skill|HitAgainAcc], EffectAcc)
            end;
        _ ->
            get_hit_again_effect(R, SkillFun, NowMs, State, [Skill|HitAgainAcc], EffectAcc)
    end.

get_attack_again_effect([], _NowMs, AgainAcc, SkillIDList) ->
    {AgainAcc, SkillIDList};
get_attack_again_effect([Skill|R], NowMs, AgainAcc, SkillIDList) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    #c_skill{hit_again_args = HitAgainArgs} = SkillConfig = common_skill:get_skill_config(SkillID),
    case NowMs > Time of
        true ->
            case HitAgainArgs of
                [Rate, _HitNum] ->
                    case common_misc:is_active(Rate) of
                        true ->
                            Skill2 = Skill#p_skill{time = get_skill_cd(SkillConfig, NowMs)},
                            AgainAcc2 = [Skill2|AgainAcc],
                            SkillIDList2 = [SkillID|SkillIDList];
                        _ ->
                            AgainAcc2 = [Skill|AgainAcc],
                            SkillIDList2 = SkillIDList
                    end,
                    get_attack_again_effect(R, NowMs, AgainAcc2, SkillIDList2);
                _ ->
                    get_attack_again_effect(R, NowMs, [Skill|AgainAcc], SkillIDList)
            end;
        _ ->
            get_attack_again_effect(R, NowMs, [Skill|AgainAcc], SkillIDList)
    end.

war_spirit_buff(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    NowMs = time_tool:now_ms(),
    WarSpiritBuffSkills = get_skills_by_sub_type(?SKILL_PASSIVE_WAR_SPIRIT_BUFF, PassiveList),
    {WarSpiritBuffSkills2, SelfEffects, EnemyEffects} = get_war_spirit_buff_effect(NowMs, WarSpiritBuffSkills, [], [], []),
    mod_role_dict:set_war_spirit_buff_effects({SelfEffects, EnemyEffects}),
    PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_WAR_SPIRIT_BUFF, PassiveList, WarSpiritBuffSkills2),
    RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
    State#r_role{role_skill = RoleSkill2}.

get_war_spirit_buff_effect(_NowMs, [], WarSpiritBuffSkills2, SelfEffects, EnemyEffects) ->
    {WarSpiritBuffSkills2, SelfEffects, EnemyEffects};
get_war_spirit_buff_effect(NowMs, [Skill|R], WarSpiritBuffSkillAcc, SelfEffects, EnemyEffects) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    case NowMs > Time of
        true ->
            Skill2 = Skill#p_skill{time = NowMs},
            #c_skill{self_buffs = SelfBuffs, direct_buffs = EnemyBuffs} = common_skill:get_skill_config(SkillID),
            SelfEffects2 = [#r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = SelfBuffs}|SelfEffects],
            EnemyEffects2 = [#r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = EnemyBuffs}|EnemyEffects],
            get_war_spirit_buff_effect(NowMs, R, [Skill2|WarSpiritBuffSkillAcc], SelfEffects2, EnemyEffects2);
        _ ->
            get_war_spirit_buff_effect(NowMs, R, [Skill|WarSpiritBuffSkillAcc], SelfEffects, EnemyEffects)
    end.

buff_trigger([], State) ->
    State;
buff_trigger(BuffList, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    BuffTriggerSkills = get_skills_by_sub_type(?SKILL_PASSIVE_BUFF_TRIGGER, PassiveList),
    case BuffTriggerSkills =/= [] of
        true ->
            NowMs = time_tool:now_ms(),
            BuffTriggerSkills2 = buff_trigger2(BuffTriggerSkills, RoleID, NowMs, BuffList, []),
            PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_BUFF_TRIGGER, PassiveList, BuffTriggerSkills2),
            RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
            State#r_role{role_skill = RoleSkill2};
        _ ->
            State
    end.

buff_trigger2([], _RoleID, _NowMs, _BuffList, Acc) ->
    Acc;
buff_trigger2([Skill|R], RoleID, NowMs, BuffList, Acc) ->
    #p_skill{skill_id = SkillID} = Skill,
    #c_skill{
        be_buff_args = BeBuffArgs,
        self_buffs = SelfBuffs,
        direct_buffs = EnemyBuffs
    } = SkillConfig = common_skill:get_skill_config(SkillID),
    Acc2 =
    case buff_trigger3(BuffList, BeBuffArgs) of
        {ok, FromActorID} ->
            ?IF(EnemyBuffs =/= [] andalso FromActorID > 0, mod_map_role:add_enemy_buff(mod_role_dict:get_map_pid(), RoleID, FromActorID, EnemyBuffs), ok),
            case SelfBuffs =/= [] of
                true ->
                    role_misc:add_buff(RoleID, [ #buff_args{buff_id = BuffID, from_actor_id = RoleID}|| BuffID <- SelfBuffs]);
                _ ->
                    ok
            end,
            CD = get_skill_cd(SkillConfig, NowMs),
            [Skill#p_skill{time = CD}|Acc];
        _ ->
            Acc
    end,
    buff_trigger2(R, RoleID, NowMs, BuffList, Acc2).

buff_trigger3([], _BeBuffArgs) ->
    false;
buff_trigger3([Buff|R], BeBuffArgs) ->
    #r_buff{
        buff_attr = BuffAttr,
        from_actor_id = FromActorID
    } = Buff,
    case BeBuffArgs of
        [?BE_BUFF_DIZZY_RATE] ->
            ?IF(BuffAttr =:= ?BUFF_DIZZY, {ok, FromActorID}, buff_trigger3(R, BeBuffArgs));
        [?BE_BUFF_DIZZY_RATE, Rate] ->
            ?IF(BuffAttr =:= ?BUFF_DIZZY andalso common_misc:is_active(Rate), {ok, FromActorID}, buff_trigger3(R, BeBuffArgs));
        _ ->
            buff_trigger3(R, BeBuffArgs)
    end.



%% 地图技能的prop_effect 多个效果只有一个生效
get_map_prop_effects(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    PropEffectSkills = get_skills_by_sub_type(?SKILL_PASSIVE_MAP_PROP_EFFECT, PassiveList),
    get_map_prop_effects2(PropEffectSkills, []).

get_map_prop_effects2([], Acc) ->
    Acc;
get_map_prop_effects2([Skill|R], Acc) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    #c_skill{
        map_prop_effect = Args,
        skill_type_id = SkillTypeID,
        cd = CD
    } = common_skill:get_skill_config(SkillID),
    Acc2 =
        case Args of
            [?MAP_PROP_EFFECT_UNDEAD, LastTime, Rate|_] ->
                PropEffect =
                    #r_map_prop_effect{
                        id = ?MAP_PROP_EFFECT_UNDEAD,
                        skill_sub_type = SkillTypeID,
                        rate = Rate,
                        end_time_ms = 0,        %% 技能生效结束时间
                        last_time = LastTime,          %% 持续时间
                        cd = CD,
                        next_time_ms = Time},
                [PropEffect|Acc];
            [?MAP_PROP_FIVE_REDUCE, ReduceRate] ->
                PropEffect =
                    #r_map_prop_effect{
                        skill_sub_type = SkillTypeID,
                        id = ?MAP_PROP_FIVE_REDUCE,
                        rate = ReduceRate,
                        end_time_ms = 0,
                        last_time = 0,
                        cd = 0,
                        next_time_ms = 0},
                [PropEffect|Acc];
            true ->
                Acc
        end,
    get_map_prop_effects2(R, Acc2).

%% 获取技能增强系数
get_skill_add_value(SkillID) when erlang:is_integer(SkillID) ->
    get_skill_add_value(common_skill:get_skill_config(SkillID));
get_skill_add_value(SkillConfig) ->
    #c_skill{skill_type_id = SkillTypeID} = SkillConfig,
    SkillAddList = mod_role_dict:get_skill_add_hurt(),
    case lists:keyfind(SkillTypeID, #r_skill_add_hurt.skill_type_id, SkillAddList) of
        #r_skill_add_hurt{rate_list = RateList} ->
            get_skill_add_value2(RateList, 0);
        _ ->
            0
    end.

get_skill_add_value2([], Acc) ->
    Acc;
get_skill_add_value2([{Rate, AddValue}|R], Acc) ->
    Acc2 = ?IF(common_misc:is_active(Rate), AddValue + Acc, Acc),
    get_skill_add_value2(R, Acc2).

get_skill_add_num(SkillID) when erlang:is_integer(SkillID) ->
    get_skill_add_num(common_skill:get_skill_config(SkillID));
get_skill_add_num(SkillConfig) ->
    #c_skill{skill_type_id = SkillTypeID} = SkillConfig,
    SkillAddNumList = mod_role_dict:get_skill_add_num(),
    case lists:keyfind(SkillTypeID, #p_kv.id, SkillAddNumList) of
        #p_kv{val = AddNum} ->
            AddNum;
        _ ->
            0
    end.

get_skill_cd(SkillID, NowMs) when erlang:is_integer(SkillID) ->
    get_skill_cd(common_skill:get_skill_config(SkillID), NowMs);
get_skill_cd(SkillConfig, NowMs) ->
    #c_skill{skill_type_id = SkillTypeID, cd = CD} = SkillConfig,
    ReduceList = mod_role_dict:get_skill_cd_reduce(),
    case lists:keyfind(SkillTypeID, #p_kv.id, ReduceList) of
        #p_kv{val = ReduceCD} ->
            NowMs + CD - ReduceCD;
        _ ->
            NowMs + CD
    end.

%% 5次
get_skill_times_effect(SkillFun, State) ->
    case SkillFun =:= ?SKILL_FUN_ROLE of
        true ->
            #r_role{role_skill = RoleSkill} = State,
            #r_role_skill{passive_list = PassiveList} = RoleSkill,
            PropEffectSkills = get_skills_by_sub_type(?SKILL_PASSIVE_MAP_PROP_EFFECT, PassiveList),
            SkillTimes = mod_role_dict:get_skill_times(),
            case SkillTimes >= 5 of
                true ->
                    mod_role_dict:set_skill_times(0),
                    case get_skill_times_effect2(PropEffectSkills) of
                        {ok, Rate} ->
                            case common_misc:is_active(Rate) of
                                true ->
                                    [#actor_prop_effect{
                                        type = ?PROP_TYPE_NORMAL_HIT,
                                        hp_rate = ?RATE_10000,
                                        rate = Rate,
                                        add_props = [#p_kv{id = ?ATTR_DOUBLE_RATE, val = Rate}]}];
                                _ ->
                                    []
                            end;
                        _ ->
                            []
                    end;
                _ ->
                    mod_role_dict:set_skill_times(SkillTimes + 1),
                    []
            end;
        _ ->
            []
    end.

get_skill_times_effect2([]) ->
    false;
get_skill_times_effect2([#p_skill{skill_id = SkillID}|R]) ->
    #c_skill{map_prop_effect = Args} = common_skill:get_skill_config(SkillID),
    case Args of
        [?MAP_PROP_FIVE_ATTACK, Rate] ->
            {ok, Rate};
        _ ->
            get_skill_times_effect2(R)
    end.

%% 玩家被攻击
role_be_attacked(?ACTOR_TYPE_MONSTER) ->
    AttackTimes = mod_role_dict:get_attack_times(?ACTOR_TYPE_MONSTER),
    mod_role_dict:set_attack_times(?ACTOR_TYPE_MONSTER, AttackTimes + 1);
role_be_attacked(_SrcActorType) ->
    ok.

%% 这个接口，是status非死亡情况下切换才回调的到
role_fight_status_change() ->
    mod_role_dict:erase_attack_times(?ACTOR_TYPE_MONSTER).

add_team_buffs(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{team_id = TeamID}} = State,
    BuffList = get_team_buffs(State),
    RoleList = ?IF(?HAS_TEAM(TeamID), team_misc:get_team_role_ids(TeamID), [RoleID]),
    [role_misc:add_buff(AddRoleID, BuffList) || AddRoleID <- RoleList],
    State.

member_join(JoinRoleID, State) ->
    role_misc:add_buff(JoinRoleID, get_team_buffs(State)),
    State.

modify_hp_buffs(State) ->
    HpRate = get_hp_rate(State),
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    HpBuffs = get_skills_by_sub_type(?SKILL_PASSIVE_HP_BUFFS, PassiveList),
    {AddBuffs, DelBuffs} = modify_hp_buffs2(HpRate, HpBuffs, [], []),
    AddBuffs2 = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- AddBuffs],
    role_misc:remove_buff(RoleID, DelBuffs),
    role_misc:add_buff(RoleID, AddBuffs2),
    State.

modify_hp_buffs2(_HpRate, [], AddBuffs, DelBuffs) ->
    {AddBuffs, DelBuffs};
modify_hp_buffs2(HpRate, [#p_skill{skill_id = SkillID}|R], AddBuffsAcc, DelBuffsAcc) ->
    #c_skill{add_buff_args = BuffArgs, self_buffs = AddBuffs} = common_skill:get_skill_config(SkillID),
    AddBuffsAcc2 = ?IF(HpRate =< BuffArgs, AddBuffs ++ AddBuffsAcc, AddBuffsAcc),
    DelBuffsAcc2 = AddBuffs ++ DelBuffsAcc,
    modify_hp_buffs2(HpRate, R, AddBuffsAcc2, DelBuffsAcc2).

hp_change_buffs(OldState, State) ->
    OldHpRate = get_hp_rate(OldState),
    NowHpRate = get_hp_rate(State),
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    HpBuffs = get_skills_by_sub_type(?SKILL_PASSIVE_HP_BUFFS, PassiveList),
    {AddBuffs, DelBuffs} = hp_change_buffs2(OldHpRate, NowHpRate, HpBuffs, [], []),
    AddBuffs2 = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- AddBuffs],
    role_misc:remove_buff(RoleID, DelBuffs),
    role_misc:add_buff(RoleID, AddBuffs2),
    State.

hp_change_buffs2(_OldHpRate, _NowHpRate, [], AddBuffs, DelBuffs) ->
    {AddBuffs, DelBuffs};
hp_change_buffs2(OldHpRate, NowHpRate, [#p_skill{skill_id = SkillID}|R], AddBuffsAcc, DelBuffsAcc) ->
    #c_skill{add_buff_args = BuffArgs, self_buffs = Buffs} = common_skill:get_skill_config(SkillID),
    if
        OldHpRate =< BuffArgs andalso BuffArgs < NowHpRate -> %% 血量高于阈值，清除
            AddBuffsAcc2 = AddBuffsAcc,
            DelBuffsAcc2 = Buffs ++ DelBuffsAcc;
        NowHpRate =< BuffArgs andalso BuffArgs < OldHpRate -> %% 血量低于阈值，满上
            AddBuffsAcc2 = Buffs ++ AddBuffsAcc,
            DelBuffsAcc2 = DelBuffsAcc;
        true ->
            AddBuffsAcc2 = AddBuffsAcc,
            DelBuffsAcc2 = DelBuffsAcc
    end,
    hp_change_buffs2(OldHpRate, NowHpRate, R, AddBuffsAcc2, DelBuffsAcc2).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_skill_up(RoleID, NextSkillID, State) ->
    case catch check_skill_up(NextSkillID, State) of
        {ok, BagDoings} ->
            State2 = mod_role_bag:do(BagDoings, State),
            State3 = do_skill_open(NextSkillID, ?SKILL_INFO_ONLINE, State2),
            common_misc:unicast(RoleID, #m_skill_up_toc{}),
            hook_role:learn_skill(State3, NextSkillID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_skill_up_toc{err_code = ErrCode}),
            State
    end.

check_skill_up(NextSkillID, State) ->
    Config =
        case lib_config:find(cfg_skill, NextSkillID) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
        end,
    #c_skill{
        skill_lv = SkillLevel,
        level_cost = LevelCost,
        learn_level = LearnLevel,
        learn_relive_level = LearnReliveLevel} = Config,
    ?IF(SkillLevel > 1, get_p_skill(NextSkillID - 1, State), ok),
    ?IF(mod_role_data:get_role_level(State) >= LearnLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(mod_role_data:get_role_relive_level(State) >= LearnReliveLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_RELIVE_LEVEL)),
    NeedItemList = lib_tool:string_to_intlist(LevelCost),
    BagDoings = mod_role_bag:check_num_by_item_list(NeedItemList, ?ITEM_REDUCE_SKILL_UP, State),
    {ok, BagDoings}.

%% 应用铭文
do_seal_choose(RoleID, SkillID, SealID, State) ->
    case catch check_seal_choose(SkillID, SealID, State) of
        {ok, OldSealID, NewSkill} ->
            common_misc:unicast(RoleID, #m_skill_update_toc{update_list = [NewSkill]}),
            common_misc:unicast(RoleID, #m_skill_seal_choose_toc{}),
            State2 = set_p_skill(NewSkill, State),
            State3 = ?IF(OldSealID > 0, mod_role_skill_seal:del_seals(OldSealID, State2), State2),
            State4 = mod_role_skill_seal:add_seals(SealID, State3),
            mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_SEAL_LEVEL_CHANGE, SealID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_skill_seal_choose_toc{err_code = ErrCode}),
            State
    end.

check_seal_choose(SkillID, SealID, State) ->
    #p_skill{seal_id = OldSealID, seal_id_list = SealIDList} = SKill = get_p_skill(SkillID, State),
    [#c_skill_seal{need_role_level = NeedRoleLevel}] = lib_config:find(cfg_skill_seal, SealID),
    ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(OldSealID =:= SealID, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    ?IF(lists:member(SealID, SealIDList), ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {ok, OldSealID, SKill#p_skill{seal_id = SealID}}.

%% 升级铭文
do_seal_level(RoleID, SkillID, SealID, State) ->
    case catch check_seal_level(SkillID, SealID, State) of
        {ok, BagDoings, IsChooseSeal, ChooseSealID, NewSkill} ->
            common_misc:unicast(RoleID, #m_skill_update_toc{update_list = [NewSkill]}),
            common_misc:unicast(RoleID, #m_skill_seal_level_toc{}),
            State2 = mod_role_bag:do(BagDoings, State),
            State3 = set_p_skill(NewSkill, State2),
            State4 = ?IF(IsChooseSeal, mod_role_skill_seal:add_seals(ChooseSealID, State3), State3),
            mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_SEAL_LEVEL_CHANGE, SealID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_skill_seal_level_toc{err_code = ErrCode}),
            State
    end.

check_seal_level(SkillID, SealID, State) ->
    #p_skill{seal_id = ChooseSealID, seal_id_list = SealIDList} = SKill = get_p_skill(SkillID, State),
    Config =
        case lists:member(SealID, SealIDList) of
            true ->
                case lib_config:find(cfg_skill_seal, SealID + 1) of
                    [ConfigT] ->
                        ConfigT;
                    _ ->
                        ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
                end;
            _ ->
                BaseID = ?GET_BASE_ID(SealID),
                [ ?THROW_ERR(?ERROR_COMMON_ROLE_DATA_ERROR) || HasSealID <- SealIDList, BaseID =:= ?GET_BASE_ID(HasSealID)],
                [ConfigT] = lib_config:find(cfg_skill_seal, SealID),
                ConfigT
    end,
    #c_skill_seal{seal_id = SealID2, need_role_level = NeedRoleLevel, need_item = ItemString} = Config,
    ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    BagDoings = get_seal_bag_doings(ItemString, ?ITEM_REDUCE_SEAL_CHOOSE, State),
    {IsChooseSeal, SealIDList2} = replace_seal_list(SealID2, SealIDList, []),
    ChooseSealID2 = ?IF(IsChooseSeal, SealID2, ChooseSealID),
    {ok, BagDoings, IsChooseSeal, ChooseSealID2, SKill#p_skill{seal_id = ChooseSealID2, seal_id_list = SealIDList2}}.

get_seal_bag_doings(ItemString, Action, State) ->
    case lib_tool:string_to_intlist(ItemString) of
        [{FirstTypeID, FirstNum}] ->
            mod_role_bag:check_num_by_type_id(FirstTypeID, FirstNum, Action, State);
        [{FirstTypeID, FirstNum}, {SecondTypeID, SecondNum}] ->
            case catch mod_role_bag:check_num_by_type_id(FirstTypeID, FirstNum, Action, State) of
                BagDoingsT when erlang:is_list(BagDoingsT) ->
                    BagDoingsT;
                _ ->
                    mod_role_bag:check_num_by_type_id(SecondTypeID, SecondNum, Action, State)
            end
    end.

get_p_skill(SkillID, State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    AllList = AttackList ++ lists:flatten([PassiveSkillList || #p_kvl{list = PassiveSkillList} <- PassiveList]),
    case lists:keyfind(SkillID, #p_skill.skill_id, AllList) of
        #p_skill{} = Skill ->
            Skill;
        _ ->
            ?THROW_ERR(?ERROR_SKILL_UP_001)
    end.

set_p_skill(NewSkill, State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    #p_skill{skill_id = SkillID} = NewSkill,
    #c_skill{skill_type = SkillType, sub_skill_type = SubType} = common_skill:get_skill_config(SkillID),
    if
        SkillType =:= ?SKILL_ATTACK orelse SkillType =:= ?SKILL_NORMAL ->
            AttackList2 = lists:keystore(SkillID, #p_skill.skill_id, AttackList, NewSkill),
            RoleSkill2 = RoleSkill#r_role_skill{attack_list = AttackList2},
            State#r_role{role_skill = RoleSkill2};
        SkillType =:= ?SKILL_PASSIVE ->
            Skills = get_skills_by_sub_type(SubType, PassiveList),
            Skills2 = lists:keystore(SkillID, #p_skill.skill_id, Skills, NewSkill),
            PassiveList2 = replace_skills_by_sub_type(SubType, PassiveList, Skills2),
            RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
            State#r_role{role_skill = RoleSkill2}
    end.

replace_seal_list(SealID, [], Acc) ->
    {false, [SealID|Acc]};
replace_seal_list(SealID, [OldSealID|R], Acc) ->
    case ?GET_BASE_ID(SealID) =:= ?GET_BASE_ID(OldSealID) of
        true ->
            SealID2 = erlang:max(SealID, OldSealID),
            {true, [SealID2|R] ++ Acc};
        _ ->
            replace_seal_list(SealID, R, [OldSealID|Acc])
    end.

do_skill_open(SkillID, State) ->
    do_skill_open(SkillID, ?SKILL_INFO_OPEN, State).
do_skill_open(SkillID, OpType, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    #c_skill{skill_type = SkillType, sub_skill_type = SubType, power_type = PowerType} = SkillConfig = common_skill:get_skill_config(SkillID),
    if
        SkillType =:= ?SKILL_ATTACK orelse SkillType =:= ?SKILL_NORMAL ->
            {AttackList2, UpdateList, DelList} = do_skill_open2(SkillID, SkillConfig, AttackList, [], []),
            PassiveList2 = PassiveList;
        SkillType =:= ?SKILL_PASSIVE ->
            AttackList2 = AttackList,
            Skills = get_skills_by_sub_type(SubType, PassiveList),
            {Skills2, UpdateList, DelList} = do_skill_open2(SkillID, SkillConfig, Skills, [], []),
            PassiveList2 = replace_skills_by_sub_type(SubType, PassiveList, Skills2);
        true ->
            UpdateList = DelList = [],
            AttackList2 = AttackList,
            PassiveList2 = PassiveList
    end,
    RoleSkill2 = RoleSkill#r_role_skill{attack_list = AttackList2, passive_list = PassiveList2},
    common_misc:unicast(RoleID, #m_skill_update_toc{op_type = OpType, update_list = UpdateList, del_list = DelList}),
    State2 = State#r_role{role_skill = RoleSkill2},
    IsPropChange = (SkillType =:= ?SKILL_PASSIVE andalso is_prop_change_sub_type(SubType)) orelse PowerType > ?SKILL_POWER_NOT,
    IsPropRateChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_OTHER_PROP,
    IsTeamBuffChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_TEAM_BUFF,
    IsMapPropChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_MAP_PROP_EFFECT,
    IsFightEffectChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_FIGHT_BUFF,
    IsSkillAddHurtChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_HURT,
    IsSkillTargetNumChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_ADD_TARGET_NUM,
    IsSkillCDChange = SkillType =:= ?SKILL_PASSIVE andalso SubType =:= ?SKILL_PASSIVE_REDUCE_CD,

    ?IF(IsMapPropChange, update_map_prop_effect(State2), ok),
    ?IF(IsFightEffectChange, mod_role_skill_seal:do_fight_effect_change(State2), ok),
    ?IF(IsSkillAddHurtChange, update_skill_add_hurt(PassiveList2), ok),
    ?IF(IsSkillTargetNumChange, update_skill_target_num(RoleID, PassiveList2), ok),
    ?IF(IsSkillCDChange, update_skill_cd(RoleID, PassiveList2), ok),
    State3 =
        case IsPropChange of
            true ->
                StateAcc = ?IF(IsPropRateChange, calc_prop_rate(calc(State2)), calc(State2)),
                mod_role_fight:calc_attr_and_update(StateAcc, ?POWER_UPDATE_PASSIVE_SKILL, SkillID);
            _ ->
                State2
        end,
    ?IF(IsTeamBuffChange, add_team_buffs(State3), State3).

do_skill_open2(SkillID, SkillConfig, [], DelSkillAcc, SkillAcc) ->
    #c_skill{skill_type_id = SkillTypeID} = SkillConfig,
    Skill = do_skill_open3(SkillID, SkillTypeID, DelSkillAcc),
    {[Skill|SkillAcc], [Skill], []};
do_skill_open2(SkillID, SkillConfig, [Skill|R] = SkillList, DelSkillAcc, SkillAcc) ->
    #c_skill{skill_type_id = SkillTypeID, skill_lv = SkillLv} = SkillConfig,
    #p_skill{skill_id = DestSkillID} = Skill,
    #c_skill{skill_type_id = DestSkillTypeID, skill_lv = DestSkillLv} = common_skill:get_skill_config(DestSkillID),
    if
        SkillTypeID =:= DestSkillTypeID andalso SkillLv =< DestSkillLv -> %% 同类型并且之前的等级比较高
            {SkillAcc ++ SkillList, [], []};
        SkillTypeID =:= DestSkillTypeID -> %% 替换 这里铭文要用最新等级的铭文
            UpdateSkill = Skill#p_skill{skill_id = SkillID},
            {[UpdateSkill|R] ++ SkillAcc, [UpdateSkill], [DestSkillID]};
        true ->
            do_skill_open2(SkillID, SkillConfig, R, DelSkillAcc, [Skill|SkillAcc])
    end.

do_skill_open3(SkillID, _SkillTypeID, []) ->
    #p_skill{skill_id = SkillID};
do_skill_open3(SkillID, SkillTypeID, [#p_skill{skill_id = DestSkillID} = Skill|R]) ->
    #c_skill{skill_type_id = ConfigSkillTypeID} = common_skill:get_skill_config(DestSkillID),
    case SkillTypeID =:= ConfigSkillTypeID of
        true ->
            Skill#p_skill{skill_id = SkillID};
        _ ->
            do_skill_open3(SkillID, SkillTypeID, R)
    end.


do_attack_result(Type, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    NowMs = time_tool:now_ms(),
    HpRate = get_hp_rate(State),
    ResultSkills = get_skills_by_sub_type(?SKILL_PASSIVE_ATTACK_RESULT, PassiveList),
    {ResultSkills2, AddBuffs} = do_attack_result2(Type, NowMs, HpRate, ResultSkills, [], []),
    AddBuffs2 = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- AddBuffs],
    PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_ATTACK_RESULT, PassiveList, ResultSkills2),
    RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
    role_misc:add_buff(RoleID, AddBuffs2),
    State#r_role{role_skill = RoleSkill2}.

do_attack_result2(_Type, _NowMs, _HpRate, [], ResultSkillsAcc, AddBuffsAcc) ->
    {ResultSkillsAcc, AddBuffsAcc};
do_attack_result2(Type, NowMs, HpRate, [Skill|R], ResultSkillsAcc, AddBuffsAcc) ->
    #p_skill{skill_id = SkillID, time = Time} = Skill,
    case NowMs >= Time of
        true ->
            #c_skill{
                attack_result_condition = [NeedType|RemainList],
                self_buffs = Buffs} = SkillConfig = common_skill:get_skill_config(SkillID),
            IsActive =
                case Type =:= NeedType of
                    true ->
                        case RemainList of
                            [NeedHpRate, Rate] ->
                                HpRate =< NeedHpRate andalso common_misc:is_active(Rate);
                            _ ->
                                true
                        end;
                    _ ->
                        false
                end,
            {Skill2, AddBuffsAcc2} = ?IF(IsActive, {Skill#p_skill{time = get_skill_cd(SkillConfig, NowMs)}, Buffs ++ AddBuffsAcc}, {Skill, AddBuffsAcc}),
            do_attack_result2(Type, NowMs, HpRate, R, [Skill2|ResultSkillsAcc], AddBuffsAcc2);
        _ ->
            do_attack_result2(Type, NowMs, HpRate, R, [Skill|ResultSkillsAcc], AddBuffsAcc)
    end.

do_map_prop_effect(PropEffect, State) ->
    #r_role{role_id = RoleID, role_skill = RoleSkill} = State,
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    PropEffectSkills = get_skills_by_sub_type(?SKILL_PASSIVE_MAP_PROP_EFFECT, PassiveList),
    #r_map_prop_effect{
        skill_sub_type = SkillSubType,
        next_time_ms = NextTimeMs} = PropEffect,
    {PropEffectSkills2, AddBuffs} = do_map_prop_effect2(SkillSubType, NextTimeMs, PropEffectSkills, []),
    AddBuffs2 = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- AddBuffs],
    PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_MAP_PROP_EFFECT, PassiveList, PropEffectSkills2),
    RoleSkill2 = RoleSkill#r_role_skill{passive_list = PassiveList2},
    role_misc:add_buff(RoleID, AddBuffs2),
    State#r_role{role_skill = RoleSkill2}.

do_map_prop_effect2(_SkillSubType, _NextTimeMs, [], Acc) ->
    {Acc, []};
do_map_prop_effect2(SkillSubType, NextTimeMs, [Skill|R], Acc) ->
    #p_skill{skill_id = SkillID} = Skill,
    #c_skill{
        sub_skill_type = SubSkillType,
        self_buffs = Buffs} = common_skill:get_skill_config(SkillID),
    case SubSkillType =:= SkillSubType of
        true ->
            Skill2 = Skill#p_skill{time = NextTimeMs},
            {[Skill2|R] ++ Acc, Buffs};
        _ ->
            do_map_prop_effect2(SkillSubType, NextTimeMs, R, [Skill|Acc])
    end.

%% 血量增加属性
do_hp_attr(Now, HpRate, PassiveList, State) ->
    if
        Now rem 5 =:= 0 -> %% 每5秒检测一次
            SkillList = get_skills_by_sub_type(?SKILL_PASSIVE_HP_RATE_PROP, PassiveList),
            case SkillList =/= [] of
                true ->
                    OldHpRate = mod_role_dict:get_old_hp_rate(),
                    case OldHpRate =/= HpRate of
                        true ->
                            mod_role_dict:set_old_hp_rate(HpRate),
                            do_hp_attr2(HpRate, SkillList, State);
                        _ ->
                            State
                    end;
                _ ->
                    State
            end;
        true ->
            State
    end.

do_hp_attr2(HpRate, SkillList, State) ->
    KVList = do_hp_attr3(SkillList, HpRate, []),
    HpAttr = common_misc:get_attr_by_kv(KVList),
    mod_role_fight:calc_attr_and_update(State#r_role{hp_attr = HpAttr}).

do_hp_attr3([], _HpRate, Acc) ->
    Acc;
do_hp_attr3([#p_skill{skill_id = SkillID}|R], HpRate, Acc) ->
    #c_skill{props = Props, skill_type_id = SkillTypeID} = common_skill:get_skill_config(SkillID),
    AddList =
        case SkillTypeID of
            1107 -> %% 概日凌云
                common_misc:get_string_props(Props, HpRate / ?RATE_10000);
            11015 ->
                ?IF(HpRate =< 5000, common_misc:get_string_props(Props), []);
            true ->
                []
        end,
    do_hp_attr3(R, HpRate, AddList ++ Acc).

update_map_prop_effect(State) ->
    #r_role{role_id = RoleID} = State,
    mod_map_role:update_map_prop_effect(mod_role_dict:get_map_pid(), RoleID, get_map_prop_effects(State)).

get_team_buffs(State) ->
    #r_role{role_id = RoleID, role_skill = #r_role_skill{passive_list = PassiveList}} = State,
    BuffList =
        [begin
             #c_skill{self_buffs = BuffList} = common_skill:get_skill_config(SkillID),
             [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- BuffList]
         end || #p_skill{skill_id = SkillID} <- get_skills_by_sub_type(?SKILL_PASSIVE_TEAM_BUFF, PassiveList)],
    lists:flatten(BuffList).

get_skills_by_sub_type(SubType, PassiveList) ->
    case lists:keyfind(SubType, #p_kvl.id, PassiveList) of
        #p_kvl{list = SkillList} ->
            SkillList;
        _ ->
            []
    end.

replace_skills_by_sub_type(SubType, PassiveList, SkillList) ->
    lists:keystore(SubType, #p_kvl.id, PassiveList, #p_kvl{id = SubType, list = SkillList}).

get_hp_rate(State) ->
    #r_role{role_map = #r_role_map{hp = Hp}, role_fight = #r_role_fight{fight_attr = #actor_fight_attr{max_hp = MaxHp}}} = State,
    lib_tool:to_integer(Hp / MaxHp * ?RATE_10000).

is_skill_fun_match(SkillFun, SkillFun2) ->
    case SkillFun =:= ?SKILL_FUN_ROLE andalso lists:member(SkillFun2, [?SKILL_FUN_ROLE, ?SKILL_FUN_MOUNT, ?SKILL_FUN_WING, ?SKILL_FUN_GOD]) of
        true ->
            true;
        _ ->
            SkillFun =:= SkillFun2
    end.

is_prop_change_sub_type(SubType) ->
    lists:member(SubType, [?SKILL_PASSIVE_PROP, ?SKILL_PASSIVE_ONLY_PROP, ?SKILL_PASSIVE_HIT_PROP, ?SKILL_PASSIVE_ADD_HIT_PROP, ?SKILL_PASSIVE_ADD_OTHER_PROP]).

get_add_prop_effects(SkillList) ->
    lists:foldl(
        fun(#p_skill{skill_id = SkillID}, Acc) ->
            #c_skill{props = PropString, add_prop_effect = [AddSkillID, AddRate]} = common_skill:get_skill_config(SkillID),
            case lists:keyfind(AddSkillID, #p_kvs.id, Acc) of
                #p_kvs{val = AddRate1, text = AddProps1} = KVS ->
                    KVS2 = KVS#p_kvs{val = AddRate1 + AddRate, text = common_misc:get_string_props(PropString) ++ AddProps1},
                    lists:keyreplace(AddSkillID, #p_kvs.id, Acc, KVS2);
                _ ->
                    [#p_kvs{id = AddSkillID, val = AddRate, text = common_misc:get_string_props(PropString)}|Acc]
            end
        end, [], SkillList).

%% 获取战斗buff触发条件
get_fight_effects(RoleSkill) ->
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    FightSkills = get_skills_by_sub_type(?SKILL_PASSIVE_FIGHT_BUFF, PassiveList),
    get_fight_effects2(FightSkills, []).

get_fight_effects2([], Acc) ->
    Acc;
get_fight_effects2([#p_skill{skill_id = SkillID, time = Time}|R], FightEffectAcc) ->
    #c_skill{
        fight_buff_condition = FightBuffCondition,
        self_buffs = SelfBuffs,
        direct_buffs = EnemyBuffs,
        cd = CD
    } = common_skill:get_skill_config(SkillID),
    case get_fight_effects3(FightBuffCondition) of
        {Type, Rate, Condition, Args} ->
            FightEffect = #r_fight_effect{
                id = SkillID,
                type = Type,
                rate = Rate,
                condition = Condition,
                self_buffs = SelfBuffs,
                enemy_buffs = EnemyBuffs,
                args = Args,
                cd = CD,
                time = Time
            },
            get_fight_effects2(R, [FightEffect|FightEffectAcc]);
        Error ->
            ?ERROR_MSG("fight effect Error: ~w", [{SkillID, Error}]),
            get_fight_effects2(R, FightEffectAcc)
    end.

get_fight_effects3(FightBuffCondition) ->
    case FightBuffCondition of
        [?SKILL_FIGHT_BUFF_ROLE_DOUBLE] ->
            {?FIGHT_EFFECT_ATTACK, ?RATE_10000, [?FIGHT_EFFECT_ROLE_DOUBLE], []};
        [?SKILL_FIGHT_BUFF_ROLE_DOUBLE, Rate] ->
            {?FIGHT_EFFECT_ATTACK, Rate, [?FIGHT_EFFECT_ROLE_DOUBLE], []};
        [?SKILL_FIGHT_BUFF_BE_ROLE_DOUBLE|_] ->
            {?FIGHT_EFFECT_BE_ATTACKED, ?RATE_10000, [?FIGHT_EFFECT_BE_ROLE_DOUBLE], []};
        [?SKILL_FIGHT_BUFF_BLOCK_RATE, Rate|_] ->
            {?FIGHT_EFFECT_BE_ATTACKED, Rate, [?FIGHT_EFFECT_BLOCK_RATE], []};
        [?SKILL_FIGHT_BUFF_ROLE_BLOCK|_] ->
            {?FIGHT_EFFECT_BE_ATTACKED, ?RATE_10000, [?FIGHT_EFFECT_BLOCK_ROLE], []};
        [?SKILL_FIGHT_BUFF_BLOCK_MONSTER|_] ->
            {?FIGHT_EFFECT_BE_ATTACKED, ?RATE_10000, [?FIGHT_EFFECT_BLOCK_MONSTER], []};
        [?SKILL_FIGHT_BUFF_SKILL_RELEASE|SkillIDList] ->
            {?FIGHT_EFFECT_ATTACK, ?RATE_10000, [?FIGHT_EFFECT_RELEASE_SKILL|SkillIDList], []};
        [?SKILL_FIGHT_HIT_ENEMY, Rate|_] ->
            {?FIGHT_EFFECT_ATTACK, Rate, [?FIGHT_EFFECT_HIT_ENEMY], []};
        [?SKILL_FIGHT_BUFF_HP_BELOW, HpRate|_] ->
            {?FIGHT_EFFECT_ATTACK, ?RATE_10000, [?FIGHT_EFFECT_HP_BELOW, HpRate], []};
        [?SKILL_FIGHT_BUFF_DIZZY_BE_ATTACKED, Rate|_] ->
            {?FIGHT_EFFECT_BE_ATTACKED, Rate, [?FIGHT_EFFECT_DIZZY_BE_ATTACKED], []};
        _ ->
            FightBuffCondition
    end.

%% 更新时间
update_fight_effect(ActiveIDs, NowMs, RoleSkill) ->
    #r_role_skill{passive_list = PassiveList} = RoleSkill,
    FightSkills = get_skills_by_sub_type(?SKILL_PASSIVE_FIGHT_BUFF, PassiveList),
    FightSkills2 = update_fight_effect2(ActiveIDs, NowMs, FightSkills),
    PassiveList2 = replace_skills_by_sub_type(?SKILL_PASSIVE_FIGHT_BUFF, PassiveList, FightSkills2),
    RoleSkill#r_role_skill{passive_list = PassiveList2}.

update_fight_effect2([], _NowMs, FightSkills) ->
    FightSkills;
update_fight_effect2([SkillID|R], NowMs, FightSkills) ->
    case common_skill:get_skill_config(SkillID) of
        #c_skill{} = SkillConfig ->
            case lists:keytake(SkillID, #p_skill.skill_id, FightSkills) of
                {value, #p_skill{} = Skill, FightSkills2} ->
                    Skill2 = Skill#p_skill{time = get_skill_cd(SkillConfig, NowMs)},
                    FightSkills3 = [Skill2|FightSkills2],
                    update_fight_effect2(R, NowMs, FightSkills3);
                _ ->
                    update_fight_effect2(R, NowMs, FightSkills)
            end;
        _ ->
            update_fight_effect2(R, NowMs, FightSkills)
    end.

%% 更新技能伤害加成
update_skill_add_hurt(PassiveList) ->
    Skills = get_skills_by_sub_type(?SKILL_PASSIVE_ADD_HURT, PassiveList),
    SkillAddHurtList = update_skill_add_hurt2(Skills, []),
    mod_role_dict:set_skill_add_hurt(SkillAddHurtList).

update_skill_add_hurt2([], Acc) ->
    Acc;
update_skill_add_hurt2([#p_skill{skill_id = SkillID}|R], Acc) ->
    #c_skill{
        add_skill_type_list = TypeList,
        add_skill_args = AddSkillArgs
    } = common_skill:get_skill_config(SkillID),
    {Rate, AddValue} =
        case AddSkillArgs of
            [RateT, AddValueT] ->
                {RateT, AddValueT};
            [AddValueT] ->
                {?RATE_10000, AddValueT};
            _ ->
                {0, 0}
        end,
    Acc2 = update_skill_add_hurt3(TypeList, Rate, AddValue, Acc),
    update_skill_add_hurt2(R, Acc2).

update_skill_add_hurt3([], _Rate, _AddValue, Acc) ->
    Acc;
update_skill_add_hurt3([SkillTypeID|R], Rate, AddValue, Acc) ->
    Acc2 =
        case lists:keytake(SkillTypeID, #r_skill_add_hurt.skill_type_id, Acc) of
            {value, AddHurt, AccT} ->
                #r_skill_add_hurt{rate_list = RateList} = AddHurt,
                AddHurt2 = AddHurt#r_skill_add_hurt{rate_list = [{Rate, AddValue}|RateList]},
                [AddHurt2|AccT];
            _ ->
                AddHurt = #r_skill_add_hurt{skill_type_id = SkillTypeID, rate_list = [{Rate, AddValue}]},
                [AddHurt|Acc]
        end,
    update_skill_add_hurt3(R, Rate, AddValue, Acc2).

%% 更新技能目标数量
update_skill_target_num(RoleID, PassiveList) ->
    SkillList = get_skills_by_sub_type(?SKILL_PASSIVE_ADD_TARGET_NUM, PassiveList),
    AddList = update_skill_target_num2(SkillList, []),
    common_misc:unicast(RoleID, #m_skill_target_add_toc{add_list = AddList}),
    mod_role_dict:set_skill_add_num(AddList),
    ok.

update_skill_target_num2([], Acc) ->
    Acc;
update_skill_target_num2([#p_skill{skill_id = SkillID}|R], Acc) ->
    #c_skill{
        add_skill_type_list = TypeList,
        add_skill_args = Args
    } = common_skill:get_skill_config(SkillID),
    AddTargetNum = get_add_skill_args(Args),
    List = [#p_kv{id = SkillTypeID, val = AddTargetNum} || SkillTypeID <- TypeList],
    update_skill_target_num2(R, List ++ Acc).

%% 更新cd时间
update_skill_cd(RoleID, PassiveList) ->
    SkillList = get_skills_by_sub_type(?SKILL_PASSIVE_REDUCE_CD, PassiveList),
    KVList = update_skill_cd2(SkillList, []),
    common_misc:unicast(RoleID, #m_skill_cd_reduce_toc{cd_list = KVList}),
    mod_role_dict:set_skill_cd_reduce(KVList).

update_skill_cd2([], Acc) ->
    Acc;
update_skill_cd2([#p_skill{skill_id = SkillID}|R], Acc) ->
    #c_skill{
        add_skill_type_list = TypeList,
        add_skill_args = Args
    } = common_skill:get_skill_config(SkillID),
    ReduceCD = get_add_skill_args(Args),
    List = [#p_kv{id = SkillTypeID, val = ReduceCD} || SkillTypeID <- TypeList],
    update_skill_target_num2(R, List ++ Acc).

get_add_skill_args(Args) ->
    case Args of
        [Value|_] ->
            Value;
        _ ->
            0
    end.

modify_passive_list(PassiveList) ->
    lists:foldl(
        fun(#p_kvl{id = OldSubType, list = SkillList}, Acc) ->
            modify_passive_list2(SkillList, OldSubType, Acc)
        end, [], PassiveList).

modify_passive_list2([], _OldSubType, Acc) ->
    Acc;
modify_passive_list2([Skill|R], OldSubType, Acc) ->
    #p_skill{skill_id = SkillID} = Skill,
    SubType =
        case common_skill:get_skill_config(SkillID) of
            #c_skill{skill_type = ?SKILL_PASSIVE, sub_skill_type = SubTypeT} ->
                SubTypeT;
            _ ->
                OldSubType
        end,
    Acc2 =
        case lists:keytake(SubType, #p_kvl.id, Acc) of
            {value, #p_kvl{list = SkillList} = KVL, AccT} ->
                KVL2 = KVL#p_kvl{list = [Skill|SkillList]},
                [KVL2|AccT];
            _ ->
                [#p_kvl{id = SubType, list = [Skill]}|Acc]
        end,
    modify_passive_list2(R, OldSubType, Acc2).