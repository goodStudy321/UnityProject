%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 战力
%%% @end
%%% Created : 25. 五月 2017 12:34
%%%-------------------------------------------------------------------
-module(mod_role_fight).
-author("laijichang").
-include("proto/mod_role_fight.hrl").
-include("proto/mod_role_skill.hrl").
-include("proto/mod_role_wing.hrl").
-include("role.hrl").
-include("rank.hrl").

%% API
-export([
    calc_attr/1,
    calc_attr_and_update/1,
    calc_attr_and_update/3,
    get_state_by_kv/3,
    get_power/2,
    make_role_base/1,
    make_role_powers/1
]).

%% API
-export([
    online/1,
    loop/2,
    handle/2
]).

-export([
    role_be_attacked/1,
    role_enter_map/1,
    kill_role/2,
    force_change_pk_mode/2
]).

-export([
    get_dps_efficiency/1,
    clear_pk_value/1
]).



calc_attr_and_update(State) ->
    calc_attr_and_update(State, 0, 0).
calc_attr_and_update(State, Action, SubAction) ->
    #r_role{role_id = RoleID, role_fight = RoleFight, calc_list = CalcList} = State2 = calc_attr(State),
    OldBaseAttr = State#r_role.role_fight#r_role_fight.base_attr,
    OldFightAttr = State#r_role.role_fight#r_role_fight.fight_attr,
    NewBaseAttr = RoleFight#r_role_fight.base_attr,
    NewFightAttr = RoleFight#r_role_fight.fight_attr,
    #r_role_attr{power = OldPower, max_power = OldMaxPower} = State#r_role.role_attr,
    #r_role_attr{power = NewPower, max_power = MaxPower} = State2#r_role.role_attr,
    MapPID = mod_role_dict:get_map_pid(),
    ?IF(OldFightAttr =/= NewFightAttr, mod_map_role:update_role_fight(MapPID, RoleID, RoleFight#r_role_fight.fight_attr), ok),
    case OldPower =/= NewPower of
        true ->
            mod_map_role:update_role_power(MapPID, RoleID, NewPower),
            ?IF(Action =/= 0, log_power(OldPower, NewPower, Action, SubAction, State2), ok);
        _ ->
            ok
    end,
    %% 最大战力变化
    State3 =
    case OldMaxPower =/= MaxPower of
        true ->
            mod_role_rank:update_rank(?RANK_ROLE_POWER, {RoleID, MaxPower, time_tool:now()}),
            AccState = mod_role_act_rank:power_change(State2),
            AccState2 = mod_role_mission:power_trigger(AccState),
            AccState3 = mod_role_confine:up_power(MaxPower, AccState2),
            mod_role_bless:max_power_add(MaxPower, AccState3);
        _ ->
            State2
    end,
    case OldBaseAttr =/= NewBaseAttr orelse OldFightAttr#actor_fight_attr.monster_exp_add =/= NewFightAttr#actor_fight_attr.monster_exp_add
         orelse CalcList =/= State#r_role.calc_list of
        true -> %% 属性有变
            RoleBase = make_role_base(RoleFight),
            RolePowers = make_role_powers(CalcList),
            DataRecord = #m_role_base_toc{role_base = RoleBase, role_powers = RolePowers},
            common_misc:unicast(RoleID, DataRecord),
            State4 = mod_role_god_book:fight_attr_change(OldBaseAttr, NewBaseAttr, State3),
            State4;
        _ ->
            State3
    end.


%% 计算角色属性
calc_attr(State) ->
    #r_role{
        role_id = RoleID,
        role_attr = RoleAttr,
        calc_list = CalcList,
        skill_prop_attr = SkillPropAttr,
        buff_attr = BuffAttr,
        hp_attr = HpAttr,
        prop_effects = PropEffects,
        skill_power_list = SkillPowerList} = State,
    #r_role_attr{max_power = MaxPower} = RoleAttr,
    Attrs = [Attr || #r_calc{attr = Attr} <- CalcList],
    SumAttrs = common_misc:sum_calc_attr(Attrs),
    {BaseAttr, _ExtraAttr} = common_misc:sum_attr(SumAttrs),
    %% 战力计算
    Power = get_fight_power(BaseAttr, SkillPowerList),
    RoleAttr2 = ?IF(Power > MaxPower, RoleAttr#r_role_attr{power = Power, max_power = Power}, RoleAttr#r_role_attr{power = Power}),
    %% 面板属性，需要带上技能21带的属性加成以及其他功能    只加面板属性，不影响战力
    PanelList = [ PanelAttr || #r_panel_calc{attr = PanelAttr} <- mod_role_dict:get_panel_attr_list()],
    PanelAttr = common_misc:sum_calc_attr([SkillPropAttr|PanelList]),
    {BaseAttr2, ExtraAttr2} = common_misc:sum_attr(common_misc:sum_calc_attr([SumAttrs, PanelAttr])),
    #actor_extra_attr{
        hp_recover = {HpRecover, _HpRecoverRate},
        war_spirit_time = {WarSpiritTime, _WarSpiritTimeR}} = ExtraAttr2,
    mod_role_dict:set_recover_hp_abs(HpRecover),
    mod_role_dict:set_war_spirit_time(WarSpiritTime),

    FightAttr = common_buff:sum_attr(BaseAttr2, common_misc:sum_calc_attr([BuffAttr, HpAttr])),
    FightAttr2 = FightAttr#actor_fight_attr{prop_effects = PropEffects},
    RoleFight = #r_role_fight{role_id = RoleID, base_attr = BaseAttr2, fight_attr = FightAttr2},
    State#r_role{role_attr = RoleAttr2, role_fight = RoleFight}.

get_fight_power(BaseAttr, SkillPowerList) ->
    #actor_fight_attr{
        max_hp = MaxHp,
        attack = Attack,
        defence = Defence,
        arp = Arp,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleAnti,
        double_multi = DoubleMulti,
        hurt_rate = HurtRate,
        hurt_derate = HurtDeRate,
        double_rate = DoubleRate,
        miss_rate = MissRate,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtAnti
    } = BaseAttr,
    BaseSkillPower = get_skill_power_args(?SKILL_POWER_NORMAL, SkillPowerList),
    DpsSkillRate = get_skill_power_args(?SKILL_POWER_DPS_RATE, SkillPowerList),
    %% 基础输出战力=攻击战力 + 破甲战力 + 命中战力 + 暴击战力
    BaseDpsPower = Attack * ?POWER_ATTACK + Arp * ?POWER_ARP + HitRate * ?POWER_HIT_RATE + Double * ?POWER_DOUBLE,
    %% 基础生存战力=生命战力 +  防御战力 + 闪避战力 + 坚韧战力
    BaseEhpPower = MaxHp * ?POWER_HP + Defence * ?POWER_DEFENCE + Miss * ?POWER_MISS + DoubleAnti * ?POWER_DOUBLE_ANTI,

    %% 总输出战力=基础输出战力+K*min(50w,基础输出战力)*(二阶暴击率*（暴击伤害-1）+伤害加深+技能伤害增加*0.2+dps技能战力加成)
    DpsPower = BaseDpsPower + erlang:min(500000, BaseDpsPower) * ((DoubleRate / ?RATE_10000) * (DoubleMulti / ?RATE_10000 + ?DOUBLE_BASE_RATE - 1)
               + HurtRate / ?RATE_10000 + ((SkillDps + SkillHurt * 0.2) / ?RATE_10000) + (DpsSkillRate/?RATE_10000)),

    %% 总生存战力=基础生存战力+K*min(50W,基础生存战力)*(1/(1-min(0.5,二阶闪避率))+1/(1-min(0.5,二阶免伤率))+1/(1-min(0.5,技能免伤率))+1/(1-min(0.5,技能伤害减少*0.2))-4)
    EhpRate = 1/(1 - erlang:min(0.5, MissRate / ?RATE_10000))  +
                1/(1 - erlang:min(0.5, HurtDeRate / ?RATE_10000)) +
                    1/(1 - erlang:min(0.5, SkillEhp / ?RATE_10000)) +
                    1/(1 - erlang:min(0.5, (SkillHurtAnti * 0.2)/?RATE_10000)) - 4,
    EhpPower = BaseEhpPower + erlang:min(500000, BaseEhpPower) * EhpRate,

    %% 战力 = 总输出战力 + 总生存战力 + 技能固定战力加成
    lib_tool:ceil(DpsPower + EhpPower + BaseSkillPower).

get_skill_power_args(PowerType, SkillPowerList) ->
    case lists:keyfind(PowerType, #p_kv.id, SkillPowerList) of
        #p_kv{val = Val} ->
            Val;
        _ ->
            0
    end.

get_state_by_kv(State, Key, Attr) ->
    #r_role{role_id = RoleID, calc_list = CalcList} = State,
    NewPower = common_misc:get_calc_power(Attr), % T根据属性得到相应的战力
    Calc = #r_calc{key = Key, attr = Attr, power = NewPower},
    CalcList2 = lists:keystore(Key, #r_calc.key, CalcList, Calc),
    OldPower = get_power2(Key, CalcList),
    State2 = State#r_role{calc_list = CalcList2},
    update_power_rank(RoleID, Key, OldPower, NewPower, State2).

update_power_rank(RoleID, Key, OldPower, NewPower, State) ->
    case NewPower > OldPower andalso OldPower > 0 of
        true ->
            if
                Key =:= ?CALC_KEY_MOUNT ->
                    MountID = State#r_role.role_mount#r_role_mount.mount_id,
                    mod_role_rank:update_rank(?RANK_MOUNT_POWER, {RoleID, NewPower, MountID, time_tool:now()}),
                    State;
                Key =:= ?CALC_KEY_PET ->
                    #r_role_pet{pet_id = PetID} = State#r_role.role_pet,
                    mod_role_rank:update_rank(?RANK_PET_POWER, {RoleID, NewPower, PetID, time_tool:now()}),
                    State;
                Key =:= ?CALC_KEY_MAGIC_WEAPON ->
                    MagicWeaponLevel = State#r_role.role_magic_weapon#r_role_magic_weapon.level,
                    mod_role_rank:update_rank(?RANK_MAGIC_WEAPON_POWER, {RoleID, NewPower, MagicWeaponLevel, time_tool:now()}),
                    mod_role_act_os_second:magic_weapon_power_update(State, NewPower,true);
                Key =:= ?CALC_KEY_GOD_WEAPON ->
                    #r_role_god_weapon{level = GodWeaponLevel} = State#r_role.role_god_weapon,
                    mod_role_rank:update_rank(?RANK_GOD_WEAPON_POWER, {RoleID, NewPower, GodWeaponLevel, time_tool:now()}),
                    State;
                Key =:= ?CALC_KEY_WING ->
                    #r_role_wing{level = Level} = State#r_role.role_wing,
                    mod_role_rank:update_rank(?RANK_WING_POWER, {RoleID, NewPower, Level, time_tool:now()}),
                    mod_role_act_os_second:wing_power_update(State, NewPower,true);
                Key =:= ?CALC_KEY_HANDBOOK ->
                    mod_role_act_os_second:handbook_power_update(State, NewPower,true);
                Key =:= ?CALC_KEY_SUIT ->
                    mod_role_act_rank:suit_power(State);
                Key =:= ?CALC_KEY_NATURE ->
                    mod_role_act_rank:nature_power(State);
                true ->
                    State
            end;
        _ ->
            State
    end.

get_power(Key, State) when erlang:is_integer(Key) ->
    #r_role{calc_list = CalcList} = State,
    get_power2(Key, CalcList).

get_power2(Key, CalcList) ->
    case lists:keyfind(Key, #r_calc.key, CalcList) of
        #r_calc{power = PowerT} ->
            PowerT;
        _ ->
            0
    end.

make_role_base(RoleFight) ->
    #r_role_fight{base_attr = BaseAttr, fight_attr = FightAttr} = RoleFight,
    #actor_fight_attr{
        max_hp = MaxHp,
        attack = Attack,
        defence = Defence,
        arp = Arp,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleAnti,
        hurt_rate = HurtRate,
        hurt_derate = HurtDeRate,
        double_rate = DoubleRate,
        double_multi = DoubleMulti,
        miss_rate = MissRate,
        double_anti_rate = DoubleAntiRate,
        armor = Armor,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtAnti,
        move_speed = MoveSpeed,
        metal = Metal,
        wood = Wood,
        water = Water,
        fire = Fire,
        earth = Earth
    } = BaseAttr,
    #actor_fight_attr{
        monster_exp_add = MonsterExpAdd
    } = FightAttr,
    [
        #p_kdv{id = ?ATTR_ATTACK, val = Attack},
        #p_kdv{id = ?ATTR_HP, val = MaxHp},
        #p_kdv{id = ?ATTR_ARP, val = Arp},
        #p_kdv{id = ?ATTR_DEFENCE, val = Defence},
        #p_kdv{id = ?ATTR_HIT_RATE, val = HitRate},
        #p_kdv{id = ?ATTR_MISS, val = Miss},
        #p_kdv{id = ?ATTR_DOUBLE, val = Double},
        #p_kdv{id = ?ATTR_DOUBLE_ANTI, val = DoubleAnti},
        #p_kdv{id = ?ATTR_HURT_RATE, val = HurtRate},
        #p_kdv{id = ?ATTR_HURT_DERATE, val = HurtDeRate},
        #p_kdv{id = ?ATTR_DOUBLE_RATE, val = DoubleRate},
        #p_kdv{id = ?ATTR_DOUBLE_MULTI, val = DoubleMulti},
        #p_kdv{id = ?ATTR_MISS_RATE, val = MissRate},
        #p_kdv{id = ?ATTR_DOUBLE_ANTI_RATE, val = DoubleAntiRate},
        #p_kdv{id = ?ATTR_ARMOR, val = Armor},
        #p_kdv{id = ?ATTR_SKILL_HURT, val = SkillHurt},
        #p_kdv{id = ?ATTR_SKILL_HURT_ANTI, val = SkillHurtAnti},
        #p_kdv{id = ?ATTR_MOVE_SPEED, val = MoveSpeed},
        #p_kdv{id = ?ATTR_MONSTER_EXP, val = MonsterExpAdd},
        #p_kdv{id = ?ATTR_METAL, val = Metal},
        #p_kdv{id = ?ATTR_WOOD, val = Wood},
        #p_kdv{id = ?ATTR_WATER, val = Water},
        #p_kdv{id = ?ATTR_FIRE, val = Fire},
        #p_kdv{id = ?ATTR_EARTH, val = Earth}
    ].

make_role_powers(CalcList) ->
    [#p_kv{id = Key, val = Power} || #r_calc{key = Key, power = Power} <- CalcList].

online(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    notify_pk_value_time(State),
    common_misc:unicast(RoleID, #m_change_pk_mode_toc{pk_mode = RoleMap#r_role_map.pk_mode}),
    State.

loop(Now, #r_role{role_id = RoleID, role_map = RoleMap} = State) ->
    WeaponTime = mod_role_dict:get_weapon_state_time(),
    FightTime = mod_role_dict:get_fight_time(),
    #r_role_map{pk_value = PKValue} = RoleMap,
    %% ps : integer < undefined
    ?IF(Now >= WeaponTime, do_change_weapon(RoleID, ?MAP_WEAPON_STATE_NORMAL, undefined), ok),
    State2 = ?IF(Now >= FightTime, do_change_status(RoleID, ?MAP_STATUS_NORMAL, State, undefined), State),
    RoleMap2 = ?IF(PKValue > 0, do_loop_pk_value(RoleID, RoleMap), RoleMap),
    State2#r_role{role_map = RoleMap2}.

get_dps_efficiency(State) ->
    #r_role{role_fight = RoleFight} = State,
    #r_role_fight{fight_attr = FightAttr} = RoleFight,
    %% 玩家dps效率 = 玩家攻击*（1+(破甲战力+命中战力)/攻击战力）*(1+二阶伤害加深率)*
    %% (1 + ((暴击战力/攻击战力+暴击率) * (1+额外暴击伤害)))*（1+技能DSP系数+技能伤害增加*0.2）
    #actor_fight_attr{
        attack = Attack,
        hit_rate = HitRate,
        arp = Arp,
        hurt_rate = HurtRate,
        double = Double,
        double_rate = DoubleRate,
        double_multi = DoubleMulti,
        skill_dps = SkillDps,
        skill_hurt = SkillHurt
    } = FightAttr,
    ArpPower = Arp * ?POWER_ARP,
    HitRatePower = HitRate * ?POWER_HIT_RATE,
    DoublePower = Double * ?POWER_DOUBLE,
    AttackPower = Attack * ?POWER_ATTACK,
    Attack * (1 + (ArpPower + HitRatePower / AttackPower)) * (1 + HurtRate) *
    (1 + ((DoublePower / AttackPower + DoubleRate / ?RATE_10000) * (1 + DoubleMulti / ?RATE_10000))) *
        (1 + SkillDps / ?RATE_10000 + 0.2 * SkillHurt / ?RATE_10000).

clear_pk_value(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{pk_value = 0, value_time = 0},
    mod_map_role:update_role_pk_value(mod_role_dict:get_map_pid(), RoleID, 0),
    State#r_role{role_map = RoleMap2}.



handle({#m_fight_prepare_tos{} = DataIn, RoleID, _PID}, State) ->
    do_fight_prepare(RoleID, DataIn, State);
handle({#m_fight_attack_tos{} = DataIn, RoleID, _PID}, State) ->
    do_fight(RoleID, DataIn, State);
handle({#m_change_pk_mode_tos{pk_mode = PKMode}, RoleID, _PID}, State) ->
    do_change_pk_mode(RoleID, PKMode, State);
handle({kill_role, IsRed}, State) ->
    do_kill_role(IsRed, State);
handle({force_change_pk_mode, PKMode}, State) ->
    do_force_change_pk_mode(State, PKMode);
handle({war_spirit_end, WarSpiritSkill}, State) ->
    map_misc:info(mod_role_dict:get_map_pid(), {func, map_server, broadcast_by_actors, [[State#r_role.role_id], WarSpiritSkill]}),
    State;
handle(Info, State) ->
    ?ERROR_MSG("unknow info :~w", [Info]),
    State.

do_fight_prepare(RoleID, DataIn, State) ->
    #r_role{role_private_attr = PrivateAttr, role_buff = RoleBuff} = State,
    #r_role_buff{buff_status = BuffStatus} = RoleBuff,
    #r_role_private_attr{status = Status} = PrivateAttr,
    case mod_fight_etc:check_can_attack_buffs(BuffStatus) andalso Status =/= ?MAP_STATUS_DEAD of
        true -> %% 状态检测
            Now = time_tool:now(),
            #m_fight_prepare_tos{skill_id = SkillID, dest_id = DestID, step_id = StepID, src_pos = SrcPos} = DataIn,
            do_change_weapon(RoleID, ?MAP_WEAPON_STATE_SHINE, Now + ?WEAPON_CHANGE_TIME),
            RecordPos = map_misc:pos_decode(SrcPos),
            IsSyncPos = is_sync_pos(SkillID, RecordPos),
            AddNum = mod_role_skill:get_skill_add_num(SkillID),
            mod_map_role:role_fight_prepare(mod_role_dict:get_map_pid(), RoleID, DestID, SkillID, StepID, RecordPos, SrcPos, IsSyncPos, AddNum),
            %% 重头开始时清掉effect状态
            ?IF(StepID rem 100 =:= 0, mod_role_dict:set_skill_effect(?GET_SKILL_FUN(SkillID), undefined), ok);
        _ ->
            ok
    end,
    State.

is_sync_pos(SkillID, RecordPos) ->
    not lists:member(?GET_SKILL_FUN(SkillID), [?SKILL_FUN_PET, ?SKILL_FUN_MAGIC]) andalso RecordPos =/= undefined.

do_fight(RoleID, DataIn, State) ->
    #m_fight_attack_tos{
        skill_id = SkillID,
        dest_id_list = DestList,
        skill_pos = IntPos
    } = DataIn,
    NowMS = time_tool:now_ms(),
    SkillFun = ?GET_SKILL_FUN(SkillID),
    case catch check_can_fight(SkillID, SkillFun, DestList, NowMS, State) of
        {ok, State2, SkillID, DestList2, Hurt, Remain, SealEffect} ->
            mod_role_dict:set_skill_effect(SkillFun, Remain),
            mod_role_dict:set_last_attack_time(SkillFun, NowMS),
            PropEffectList = common_skill:get_prop_effect_list(SkillID),
            SkillTimesEffects = mod_role_skill:get_skill_times_effect(SkillFun, State),
            #r_skill_hurt{self_effect = SelfEffects, enemy_effect = EnemyEffects} = Hurt,
            #seal_effect_args{self_buff_effects = SealSelfBuff, enemy_buff_effects = SealEnemyBuff, prop_effects = SealProp} = SealEffect,
            case DestList2 =/= [] of
                true ->
                    {EnemyHitEffects, SelfHitEffects, State3} = mod_role_skill:get_hit_effect(SkillID, State2),
                    {HitAgainEffects, AttackAgain, State4} = mod_role_skill:get_again_effect(SkillID, State3),
                    EnemyEffects2 = SealEnemyBuff ++ EnemyHitEffects ++ EnemyEffects,
                    SelfEffects2 = SealSelfBuff ++ HitAgainEffects ++ SelfHitEffects ++ SelfEffects,
                    Now = time_tool:now(),
                    State5 = do_change_status(RoleID, ?MAP_STATUS_FIGHT, State4, Now + ?FIGHT_STATUS_CHANGE_TIME);
                _ ->
                    EnemyEffects2 = EnemyEffects,
                    SelfEffects2 = SealSelfBuff ++ SelfEffects,
                    AttackAgain = [],
                    State5 = State2
            end,
            Args = #fight_args{
                src_id = RoleID,
                src_type = ?ACTOR_TYPE_ROLE,
                skill_id = SkillID,
                skill_pos = IntPos,
                dest_id_list = DestList2,
                enemy_effect_list = EnemyEffects2,
                self_effect_list = SelfEffects2,
                friend_effect_list = [],
                prop_effect_list = SealProp ++ SkillTimesEffects ++ PropEffectList},
            MapPID = mod_role_dict:get_map_pid(),
            mod_map_role:role_fight(MapPID, Args),
            [begin
                 RecordPos = undefined,
                 IsSyncPos = is_sync_pos(AgainSkillID, RecordPos),
                 mod_map_role:role_fight_prepare(mod_role_dict:get_map_pid(), RoleID, 0, AgainSkillID, 0, undefined, 0, IsSyncPos, mod_role_skill:get_skill_add_num(AgainSkillID)),
                 EndTime = NowMS + mod_role_dict:get_war_spirit_time(),
                 mod_role_dict:set_attack_again(AgainSkillID, EndTime),
                 WarSpiritSkill = #m_war_spirit_skill_toc{role_id = RoleID, skill_id = AgainSkillID},
                 role_misc:info_role_after(EndTime - NowMS, RoleID, {mod, ?MODULE, {war_spirit_end, WarSpiritSkill}})
             end || AgainSkillID <- AttackAgain],
            State6 = ?IF(AttackAgain =/= [], mod_role_skill:war_spirit_buff(State5), State5),
            ?IF(common_skill:is_role_skill_type(SkillID), mod_role_mount:force_mount_down(State6), State6);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fight_attack_toc{err_code = ErrCode}),
            State
    end.

check_can_fight(SkillID, SkillFun, DestList, NowMS, State) ->
    #r_role{role_skill = RoleSkill, role_private_attr = PrivateAttr, role_buff = RoleBuff} = State,
    #r_role_buff{buff_status = BuffStatus} = RoleBuff,
    #r_role_private_attr{status = Status} = PrivateAttr,
    ?IF(Status =:= ?MAP_STATUS_DEAD, ?THROW_ERR(?ERROR_FIGHT_ATTACK_004), ok),
    #p_skill{seal_id = SealID} = Skill = mod_role_skill:get_fight_skill(SkillID, RoleSkill),
    ?IF(mod_role_dict:get_last_attack_time(SkillFun) =< NowMS - ?ROLE_FIGHT_COMMON_CD, ok, ?THROW_ERR(?ERROR_FIGHT_ATTACK_005)),
    case ?GET_SKILL_FUN(SkillID) =:= ?SKILL_FUN_ROLE of %% 角色技能要判断当前状态
        true ->
            case common_skill:check_skill_by_buff_status(Skill, BuffStatus) of
                {ok, _SkillConfig} -> ok;
                _ -> ?THROW_ERR(?ERROR_FIGHT_ATTACK_004)
            end,
            ?IF(mod_fight_etc:check_can_attack_buffs(BuffStatus), ok, ?THROW_ERR(?ERROR_FIGHT_ATTACK_003));
        _ ->
            ok
    end,
    DestList2 = lists:sublist(lib_tool:list_filter_repeat(DestList), ?MAX_TARGET_NUM),
    case common_skill:get_next_skill(mod_role_dict:get_skill_effect(SkillFun)) of
        {next_hurt, #r_skill_action{skill_id = SkillID}, Hurt, Remain} -> %% 之前连招的下一个伤害阶段
            {ok, State, SkillID, DestList2, Hurt, Remain, #seal_effect_args{}};
        {next_prepare, #r_skill_action{skill_id = SkillID}, Remain} -> %%
            {_, _Action2, Hurt, Remain2} = common_skill:get_next_skill(Remain),
            {ok, State, SkillID, DestList2, Hurt, Remain2, #seal_effect_args{}};
        _ ->
            {SelfBuffEffects, EnemyBuffEffects} = check_skill(SkillFun, SkillID, NowMS, Skill#p_skill.time),
            SkillConfig = common_skill:get_skill_config(SkillID),
            AddValue = mod_role_skill:get_skill_add_value(SkillConfig),
            Actions = common_skill:get_skill_action_list(SkillID, AddValue),
            {_, _Action, Hurt, Remain} = common_skill:get_next_skill(Actions),
            NextTime = mod_role_skill:get_skill_cd(SkillID, NowMS),
            Skill2 = Skill#p_skill{time = NextTime - 200},
            SkillList = lists:keyreplace(SkillID, #p_skill.skill_id, RoleSkill#r_role_skill.attack_list, Skill2),
            RoleSkill2 = RoleSkill#r_role_skill{attack_list = SkillList},
            #seal_effect_args{self_buff_effects = SealSelf, enemy_buff_effects = SealEnemy} = SealEffect = mod_role_skill_seal:get_positive_effect(SealID),
            SealEffect2 = SealEffect#seal_effect_args{self_buff_effects = SelfBuffEffects ++ SealSelf, enemy_buff_effects = EnemyBuffEffects ++ SealEnemy},
            {ok, State#r_role{role_skill = RoleSkill2}, SkillID, DestList2, Hurt, Remain, SealEffect2}
    end.

check_skill(?SKILL_FUN_WAR_SPIRIT, SkillID, NowMS, _SkillTime) ->
    EndTime = mod_role_dict:get_attack_again(SkillID),
    ?IF(mod_role_dict:get_attack_again(SkillID) =/= undefined andalso EndTime >= NowMS, ok, ?THROW_ERR(?ERROR_FIGHT_ATTACK_006)),
    {SelfBuffEffects, EnemyBuffEffects} = mod_role_dict:erase_war_spirit_buff_effects(),
    {SelfBuffEffects, EnemyBuffEffects};
check_skill(_SkillFun, _SkillID, NowMS, SkillTime) ->
    ?IF(NowMS >= SkillTime, ok, ?THROW_ERR(?ERROR_FIGHT_ATTACK_002)),
    {[], []}.


%% 更换PK模式
do_change_pk_mode(RoleID, PKMode, State) ->
    case catch check_can_change(PKMode, State) of
        {ok, State2} ->
            mod_map_role:update_role_pk_mode(mod_role_dict:get_map_pid(), RoleID, PKMode),
            common_misc:unicast(RoleID, #m_change_pk_mode_toc{pk_mode = PKMode}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_change_pk_mode_toc{err_code = ErrCode}),
            State
    end.

check_can_change(PKMode, State) ->
    #r_role{role_map = RoleMap} = State,
    #r_role_map{map_id = MapID, pk_mode = OldPKMode} = RoleMap,
    ?IF(PKMode =:= OldPKMode, ?THROW_ERR(?ERROR_CHANGE_PK_MODE_001), ok),
    [#c_map_base{pk_modes = PKModes}] = lib_config:find(cfg_map_base, MapID),
    ?IF(lists:member(PKMode, PKModes), ok, ?THROW_ERR(?ERROR_CHANGE_PK_MODE_002)),
    RoleMap2 = RoleMap#r_role_map{pk_mode = PKMode},
    State2 = State#r_role{role_map = RoleMap2},
    {ok, State2}.


role_be_attacked(#r_role{role_id = RoleID} = State) ->
    Now = time_tool:now(),
    do_change_weapon(RoleID, ?MAP_WEAPON_STATE_SHINE, Now + ?WEAPON_CHANGE_TIME),
    do_change_status(RoleID, ?MAP_STATUS_FIGHT, State, Now + ?FIGHT_STATUS_CHANGE_TIME).

role_enter_map(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{map_id = MapID, pk_mode = OldPKMode} = RoleMap,
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{default_pk_mode = DefaultPKMode}] when OldPKMode =/= DefaultPKMode andalso DefaultPKMode =/= 0 ->
            RoleMap2 = RoleMap#r_role_map{pk_mode = DefaultPKMode},
            mod_map_role:update_role_pk_mode(mod_role_dict:get_map_pid(), RoleID, DefaultPKMode),
            common_misc:unicast(RoleID, #m_change_pk_mode_toc{pk_mode = DefaultPKMode}),
            State#r_role{role_map = RoleMap2};
        _ ->
            State
    end.

kill_role(RoleID, IsRed) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {kill_role, IsRed}}).

force_change_pk_mode(RoleID, PKMode) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {force_change_pk_mode, PKMode}}).

%% 改变武器状态
do_change_weapon(RoleID, WeaponState, NextTime) ->
    mod_role_dict:set_weapon_state_time(NextTime),
    case mod_role_dict:get_weapon_state() =/= WeaponState of
        true ->
            mod_role_dict:set_weapon_state(WeaponState),
            mod_map_role:update_role_weapon_state(mod_role_dict:get_map_pid(), RoleID, WeaponState);
        _ ->
            ok
    end.

%% 改变人物状态
do_change_status(RoleID, Status, State, NextTime) ->
    mod_role_dict:set_fight_time(NextTime),
    #r_role{role_private_attr = PrivateAttr} = State,
    OldStatus = PrivateAttr#r_role_private_attr.status,
    if
        OldStatus =:= ?MAP_STATUS_DEAD -> %% 死亡状态只能通过复活或者重新上线进行改变
            State;
        OldStatus =/= Status ->
            PrivateAttr2 = PrivateAttr#r_role_private_attr{status = Status},
            State2 = State#r_role{role_private_attr = PrivateAttr2},
            mod_map_role:update_role_status(mod_role_dict:get_map_pid(), RoleID, Status),
            case OldStatus =:= ?MAP_STATUS_FIGHT of
                true ->
                    mod_role_skill:role_fight_status_change(),
                    mod_role_buff:role_fight_status_change(State2);
                _ ->
                    State2
            end;
        true ->
            State
    end.

%% pk值变化
do_loop_pk_value(RoleID, RoleMap) ->
    #r_role_map{pk_value = PKValue, value_time = ValueTime} = RoleMap,
    ValueTime2 = ValueTime - 1,
    if
        ValueTime2 > 0 ->
            RoleMap#r_role_map{value_time = ValueTime2};
        ValueTime2 =:= 0 ->
            PKValue2 = erlang:max(0, PKValue - 1),
            mod_map_role:update_role_pk_value(mod_role_dict:get_map_pid(), RoleID, PKValue2),
            RoleMap#r_role_map{pk_value = PKValue2, value_time = 0};
        true ->
            RoleMap#r_role_map{value_time = ?PK_VALUE_TIME}
    end.

%% 杀了玩家
do_kill_role(IsRed, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{pk_value = PKValue, map_id = MapID} = RoleMap,
    State2 =
    if
        ?IS_MAP_BATTLE(MapID) ->
            mod_role_achievement:add_battle_kill(State);
        ?IS_MAP_SUMMIT_TOWER(MapID) ->
            mod_role_achievement:add_summit_tower_kill(State);
        true ->
            State
    end,
    State3 = mod_role_achievement:add_kill_role(State2),
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{is_add_pk_value = ?ADD_PK_VALE}] ->
            case IsRed of
                true ->
                    mod_role_achievement:add_kill_red_role(State3);
                _ ->
                    PKValue2 = PKValue + 1,
                    RoleMap2 = RoleMap#r_role_map{pk_value = PKValue2},
                    mod_map_role:update_role_pk_value(mod_role_dict:get_map_pid(), RoleID, PKValue2),
                    State4 = State3#r_role{role_map = RoleMap2},
                    notify_pk_value_time(State4),
                    State4
            end;
        _ ->
            State3
    end.

do_force_change_pk_mode(State, PKMode) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{pk_mode = OldPKMode} = RoleMap,
    case OldPKMode =:= PKMode of
        true ->
            State;
        _ ->
            RoleMap2 = RoleMap#r_role_map{pk_mode = PKMode},
            State2 = State#r_role{role_map = RoleMap2},
            mod_map_role:update_role_pk_mode(mod_role_dict:get_map_pid(), RoleID, PKMode),
            common_misc:unicast(RoleID, #m_change_pk_mode_toc{pk_mode = PKMode}),
            State2
    end.

notify_pk_value_time(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{pk_value = PKValue, value_time = ValueTime} = RoleMap,
    AllTime = ?IF(ValueTime =:= 0, PKValue * ?PK_VALUE_TIME, (PKValue - 1) * ?PK_VALUE_TIME + ValueTime),
    ?IF(AllTime > 0, common_misc:unicast(RoleID, #m_pk_value_time_toc{pk_value_time = AllTime}), ok).

log_power(OldPower, NewPower, Action, Detail, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    Log =
    #log_power{
        role_id = RoleID,
        old_power = OldPower,
        new_power = NewPower,
        action = Action,
        detail = Detail,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

