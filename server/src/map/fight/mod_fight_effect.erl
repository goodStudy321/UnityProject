%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2017 17:39
%%%-------------------------------------------------------------------
-module(mod_fight_effect).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_role_fight.hrl").
-include("trap.hrl").
-include("monster.hrl").
-include("battle.hrl").

%% API
-export([
    enemy_effect/3,
    self_effect/3
]).

-export([
    rebound/3,
    add_buffs/6,
    add_buffs2/3
]).

-export([
    get_real_reduce/7,
    get_five_elements_multi/2,
    get_monster_and_suppress/4
]).

enemy_effect(SrcFight, DestFight, #r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_NORMAL_HIT, value = Value}) ->
    case SrcFight#actor_fight.actor_id =/= DestFight#actor_fight.actor_id of
        true ->
            {ResultList, AddMFA} = attack(SrcFight, DestFight, SkillID, SkillType, Value),
            mod_map_dict:add_fight_bc(ResultList),
            [add_mfa_list(MFA) || MFA <- AddMFA];
        _ ->
            ok
    end;
enemy_effect(SrcFight, DestFight, #r_skill_effect{effect_type = ?EFFECT_TYPE_CATCH}) ->
    #actor_fight{map_info = SrcMapInfo} = SrcFight,
    #actor_fight{actor_id = DestID, actor_type = DestType, map_info = DestMapInfo} = DestFight,
    #r_pos{mx = Mx1, my = My1} = SrcPos = map_misc:pos_decode(SrcMapInfo#r_map_actor.pos),
    #r_pos{mx = Mx2, my = My2, mdir = _DestMDir} = DestPos = map_misc:pos_decode(DestMapInfo#r_map_actor.pos),
    Len = lib_tool:random(50, 99),
    OldLen = (Mx2 - Mx1) * (Mx2 - Mx1) + (My2 - My1) * (My2 - My1),
    case can_catch(DestType, DestMapInfo) andalso OldLen > (Len * Len) of
        true ->
            MDir = map_misc:get_direction(DestPos, SrcPos),
            RDir = MDir * math:pi() / 180,
            AddX = lib_tool:ceil(Len * math:sin(RDir)),
            AddY = lib_tool:ceil(Len * math:cos(RDir)),
            DestMx = Mx1 - AddX, DestMy = My1 - AddY,
            case map_base_data:is_exist(DestMx div ?TILE_SIZE, DestMy div ?TILE_SIZE) of
                true ->
                    DestPos2 = map_misc:get_pos_by_meter(DestMx, DestMy, MDir);
                _ ->
                    DestPos2 = map_misc:get_pos_by_meter(Mx1, My1, MDir)
            end,
            MFA = {mod_map_actor, map_change_pos, [DestID, DestPos2, map_misc:pos_encode(DestPos2), ?ACTOR_MOVE_CATCH, 0]},
            add_mfa_list(MFA);
        _ ->
            ok
    end;
enemy_effect(SrcFight, DestFight, #r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = BuffList}) ->
    #actor_fight{actor_id = SrcID, attr = SrcFightAttr} = SrcFight,
    #actor_fight{actor_id = DestID, actor_type = DestType, attr = DestFightAttr} = DestFight,
    add_buffs(DestID, DestType, DestFightAttr, SrcFightAttr, SrcID, BuffList);
enemy_effect(SrcFight, DestFight, #r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_PET_HIT, value = Value}) ->
    {ResultList, AddMFA} = pet_attack(SrcFight, DestFight, SkillID, SkillType, Value),
    mod_map_dict:add_fight_bc(ResultList),
    [add_mfa_list(MFA) || MFA <- AddMFA];
enemy_effect(SrcFight, DestFight, #r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_MAGIC_WEAPON_HIT, value = Value}) ->
    {ResultList, AddMFA} = magic_weapon_attack(SrcFight, DestFight, SkillID, SkillType, Value),
    mod_map_dict:add_fight_bc(ResultList),
    [add_mfa_list(MFA) || MFA <- AddMFA].


self_effect(SrcFight, #r_skill_effect{effect_type = ?EFFECT_TYPE_BUFF, value = BuffList}, _EnemyIDList) -> %% 给自己加buff
    #actor_fight{actor_id = ActorID, actor_type = ActorType, attr = ActorFightAttr} = SrcFight,
    add_buffs(ActorID, ActorType, ActorFightAttr, ActorFightAttr, ActorID, BuffList);
self_effect(SrcFight, #r_skill_effect{effect_type = ?EFFECT_TYPE_SUMMON_TRAP, value = TrapTypeID}, _EnemyIDList) -> %% 召唤陷阱
    #actor_fight{actor_id = ActorID, actor_type = ActorType, skill_pos = SkillPos, attr = FightAttr, map_info = MapInfo} = SrcFight,
    #r_map_actor{pk_mode = PKMode, camp_id = CampID} = MapInfo,
    OwnerLevel = get_actor_level(MapInfo),
    TrapArgs = #trap_args{
        type_id = TrapTypeID,
        owner_id = ActorID,
        owner_type = ActorType,
        owner_level = OwnerLevel,
        fight_attr = FightAttr,
        pos = map_misc:pos_decode(SkillPos),
        pk_mode = PKMode,
        camp_id = CampID
    },
    mod_map_trap:summon_trap(TrapArgs);
self_effect(SrcFight, #r_skill_effect{effect_type = ?EFFECT_TYPE_HIT_AGAIN, value = SkillID, args = {HitNum, HitValue, PropEffects}}, EnemyIDList) -> %% 再攻击一次
    #actor_fight{actor_id = ActorID, actor_type = ActorType, skill_pos = SkillPos} = SrcFight,
    FightArgs = #fight_args{
        src_id = ActorID,
        src_type = ActorType,
        skill_id = SkillID,
        skill_pos = SkillPos,
        dest_id_list = lists:sublist(EnemyIDList, HitNum),
        enemy_effect_list = [#r_skill_effect{skill_id = SkillID, effect_type = ?EFFECT_TYPE_NORMAL_HIT, value = HitValue}],
        prop_effect_list = PropEffects
    },
    add_mfa_list({pname_server, send, [erlang:self(), {func, fun() -> mod_fight:fight(FightArgs) end}]}).

attack(SrcFight, DestFight, SkillID, SkillType, Value) ->
    {SrcAttr2, DestAttr2, AddValue} = prop_effects(SrcFight, DestFight, SkillID, SkillType),
    attack2(SrcFight, DestFight, SrcAttr2, DestAttr2, SkillID, SkillType, Value + AddValue).

attack2(SrcFight, DestFight, SrcAttr, DestAttr, SkillID, SkillType, Value) ->
    attack2(SrcFight, DestFight, SrcAttr, DestAttr, SkillID, SkillType, Value, false).
attack2(SrcFight, DestFight, SrcAttr, DestAttr, SkillID, SkillType, Value, IsPet) ->
    #actor_fight{actor_id = SrcID, actor_type = SrcActorType, map_info = SrcMapInfo} = SrcFight,
    #actor_fight{actor_id = DestID, actor_type = DestActorType, map_info = DestMapInfo} = DestFight,
    #actor_fight_attr{
        attack = Attack,
        hit_rate = HitRate,
        double = Double,
        double_rate = DoubleRate,
        double_multi = DoubleMulti,
        dizzy_rate = DizzyRate,
        drain = Drain,
        double_damage_rate = DoubleDamageRate,
        prop_effects = SrcPropEffects,
        block_defy = BlockDefy
    } = SrcAttr,
    #actor_fight_attr{
        max_hp = MaxHp,
        miss = Miss,
        double_anti = DoubleAnti,
        double_anti_rate = DoubleAntiRate,
        miss_rate = MissRate,
        rebound = Rebound,
        min_reduce_rate = MinReduceRate,
        max_reduce_rate = MaxReduceRate,
        double_miss_rate = DoubleMissRate,
        block_rate = BlockRate,
        prop_effects = PropEffects
    } = DestAttr,
    case mod_map_battle:is_battle_monster(DestActorType, DestMapInfo) of
        true ->
            ReduceHp = ?BATTLE_MONSTER_REDUCE_HP,
            AddMFA = [{mod_map_actor, reduce_hp, [SrcID, DestID, ReduceHp, false]}],
            {[#p_result{actor_id = DestID, result_type = ?SET_RESULT_REDUCE_HP(0), value = ReduceHp, show_value = ReduceHp}], AddMFA};
        _ ->
            ResultType = 0,
            %% 一阶暴击率=（暴击战力-敌方坚韧战力）/攻击战力（暴击战力≥敌方坚韧战力时）
            FirstDoubleRate = ?IF(Attack =:= 0, 0, (Double * ?POWER_DOUBLE - DoubleAnti * ?POWER_DOUBLE_ANTI) / (Attack * ?POWER_ATTACK)),
            %% 最终暴击率=一阶暴击率+二阶暴击率-暴击抵抗
            FinalDoubleRate = FirstDoubleRate + DoubleRate - DoubleAntiRate,
            %% 一阶闪避率=（闪避战力-敌方命中战力）/(生命战力+闪避战力）（闪避战力≥敌方命中战力时）
            FirstMissRate = (Miss * ?POWER_MISS - HitRate * ?POWER_HIT_RATE) / (MaxHp * ?POWER_HP + Miss * ?POWER_MISS),
            %% 最终闪避率=一阶闪避率+二阶闪避率
            FinalMissRate = FirstMissRate + MissRate,
            %% 对抗属性处理
            AllRate = FinalDoubleRate + FinalMissRate,
            {FinalDoubleRate2, FinalMissRate2, NormalRate} =
                case AllRate =< ?RATE_10000 of
                    true ->
                        {FinalDoubleRate, FinalMissRate, ?RATE_10000 - AllRate};
                    _ ->
                        DoubleRateAcc = erlang:max(0, lib_tool:ceil(?RATE_10000 * FinalDoubleRate / AllRate)),
                        {DoubleRateAcc, ?RATE_10000 - DoubleRateAcc, 0}
                end,
            Result = lib_tool:get_weight_output([{lib_tool:to_integer(FinalDoubleRate2), double},
                {lib_tool:to_integer(FinalMissRate2), miss},
                {lib_tool:to_integer(NormalRate), normal}]),
            #r_map_actor{shield = DestShield} = DestMapInfo,
            %% 2次闪避
            Result2 = ?IF(Result =:= miss, Result, ?IF(common_misc:is_active(DoubleMissRate), miss, Result)),
            if
                Result2 =:= miss -> %% 闪避
                    ResultList = [#p_result{actor_id = DestID, result_type = ?SET_RESULT_MISS(ResultType)}],
                    AddMFA = ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE, [{mod_role_skill, attack_result, [DestID, ?ATTACK_RESULT_MISS]}], []),
                    {ResultList, AddMFA};
                Result2 =:= double -> %% 暴击
                    IsBlock = common_misc:is_active(BlockRate - BlockDefy),
                    ResultType2 = ?SET_RESULT_REDUCE_HP(ResultType),
                    case lists:keyfind(?PROP_TYPE_DOUBLE_DIZZY_ROLE, #actor_prop_effect.type, SrcPropEffects) of
                        #actor_prop_effect{rate = Rate} ->
                            DizzyMFA = ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE andalso common_misc:is_active(Rate),
                                [{role_misc, add_buff, [DestID, #buff_args{buff_id = ?BUFF_DOUBLE_DIZZY, from_actor_id = SrcID}]}], []);
                        _ ->
                            DizzyMFA = []
                    end,
                    SrcDoubleMFA = ?IF(SrcActorType =:= ?ACTOR_TYPE_ROLE, [{mod_role_skill, role_double, [SrcID]}], []),
                    ResultType3 = ?SET_RESULT_DOUBLE(ResultType2),
                    ResultType4 = ?IF(DestShield > 0, ?SET_RESULT_SHIELD(ResultType3), ResultType3),
                    ResultType5 = ?IF(IsBlock, ?SET_RESULT_BLOCK(ResultType4), ResultType4),

                    AttackReduceHp = attack3(SrcAttr, DestAttr, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo, FinalDoubleRate, IsBlock, SkillType),
                    MaxHpFightEffects = get_fight_effect_by_type(?FIGHT_EFFECT_MAX_HP, SrcMapInfo#r_map_actor.fight_effects),
                    ReduceHp = AttackReduceHp + get_max_hp_fight_effect(MaxHpFightEffects, SkillID, DestActorType, MaxHp, 0),

                    RealReduceHp = get_real_reduce(ReduceHp, MinReduceRate, MaxReduceRate, MaxHp, IsPet, SrcID, SrcActorType),
                    %% 显示的数值
                    ReduceHp2 = erlang:max(1, lib_tool:ceil(ReduceHp * (DoubleMulti / ?RATE_10000 + ?DOUBLE_BASE_RATE) * (Value / ?RATE_10000))),
                    ReduceHp3 = reduce_hp_once_effect(PropEffects, ReduceHp2 / MaxHp, ReduceHp2),
                    %% 真实伤害 暴击后才计算
                    RealReduceHp2 = erlang:max(1, lib_tool:ceil(RealReduceHp * (DoubleMulti / ?RATE_10000 + ?DOUBLE_BASE_RATE) * (Value / ?RATE_10000))),
                    RealReduceHp3 = reduce_hp_once_effect(PropEffects, RealReduceHp2 / MaxHp, RealReduceHp2),

                    DizzyRateMFA = get_dizzy_rate_mfa(SrcID, DizzyRate, DestActorType, DestID),

                    ResultList = [#p_result{actor_id = DestID, result_type = ResultType5, value = RealReduceHp3, show_value = ReduceHp3}],
                    %% 2次伤害，再加飘字 不计算暴击伤害
                    {DoubleRealReduceHp2, DoubleResultList} = get_double_damage(DestID, MinReduceRate, MaxReduceRate, MaxHp, IsPet, DoubleDamageRate, ReduceHp, SrcID,SrcActorType),

                    RealReduceHp4 = RealReduceHp3 + DoubleRealReduceHp2,
                    ReboundMFA = get_rebound_mfa(RealReduceHp4, Rebound, SrcMapInfo, DestID),
                    %% 攻击结果额外触发效果
                    FightEffectMFA = get_fight_effects(SrcMapInfo, DestMapInfo, SrcAttr, DestAttr, SkillID, true, IsBlock, RealReduceHp4),
                    DrainMFA = get_drain_effect(SrcID, Attack, Drain),
                    AddMFA = DrainMFA ++ FightEffectMFA ++ [{mod_map_actor, reduce_hp, [SrcID, DestID, RealReduceHp4, false]}] ++ DizzyMFA ++ SrcDoubleMFA ++ DizzyRateMFA ++ ReboundMFA,
                    {ResultList ++ DoubleResultList, AddMFA};
                true -> %% 正常攻击
                    IsBlock = common_misc:is_active(BlockRate - BlockDefy),
                    ResultType2 = ?SET_RESULT_REDUCE_HP(ResultType),
                    ResultType3 = ?IF(DestShield > 0, ?SET_RESULT_SHIELD(ResultType2), ResultType2),
                    ResultType4 = ?IF(IsBlock, ?SET_RESULT_BLOCK(ResultType3), ResultType3),

                    AttackReduceHp = attack3(SrcAttr, DestAttr, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo, FinalDoubleRate, IsBlock, SkillType),
                    MaxHpFightEffects = get_fight_effect_by_type(?FIGHT_EFFECT_MAX_HP, SrcMapInfo#r_map_actor.fight_effects),
                    ReduceHp = AttackReduceHp + get_max_hp_fight_effect(MaxHpFightEffects, SkillID, DestActorType, MaxHp, 0),

                    ReduceHp2 = erlang:max(1, lib_tool:ceil(ReduceHp * (Value / ?RATE_10000))),
                    %% 特殊效果减伤
                    ReduceHp3 = reduce_hp_once_effect(PropEffects, ReduceHp2 / MaxHp, ReduceHp2),

                    DizzyRateMFA = get_dizzy_rate_mfa(SrcID, DizzyRate, DestActorType, DestID),
                    RealReduceHp = get_real_reduce(ReduceHp3, MinReduceRate, MaxReduceRate, MaxHp, IsPet, SrcID, SrcActorType),
                    ResultList = [#p_result{actor_id = DestID, result_type = ResultType4, value = RealReduceHp, show_value = ReduceHp3}],
                    %% 2次伤害，再加飘字
                    {DoubleRealReduceHp2, DoubleResultList} = get_double_damage(DestID, MinReduceRate, MaxReduceRate, MaxHp, IsPet, DoubleDamageRate, ReduceHp2, SrcID,SrcActorType),
                    RealReduceHp2 = RealReduceHp + DoubleRealReduceHp2,
                    ReboundMFA = get_rebound_mfa(RealReduceHp2, Rebound, SrcMapInfo, DestID),
                    %% 攻击结果额外触发效果
                    FightEffectMFA = get_fight_effects(SrcMapInfo, DestMapInfo, SrcAttr, DestAttr, SkillID, false, IsBlock, RealReduceHp2),
                    DrainMFA = get_drain_effect(SrcID, Attack, Drain),
                    AddMFA = DrainMFA ++ FightEffectMFA ++ [{mod_map_actor, reduce_hp, [SrcID, DestID, RealReduceHp2, false]}] ++ ReboundMFA ++ DizzyRateMFA,
                    {ResultList ++ DoubleResultList, AddMFA}
            end
    end.

attack3(SrcAttr, DestAttr, SrcActorType, SrcMapInfo, DestActorType, DestMapInfo, FinalDoubleRate, IsBlock, SkillType) ->
    #actor_fight_attr{
        attack = Attack,
        arp = Arp,
        hit_rate = HitRate,
        double = Double,
        hurt_rate = HurtRate,
        skill_hurt = SkillHurt,
        role_hurt_add = RoleHurtAdd,
        boss_hurt_add = BossHurtAdd,
        monster_hurt_add = MonsterHurtAdd,
        imprison_hurt_add = ImprisonAdd,
        silent_hurt_add = SilentHurtAdd,
        poison_hurt_add = PoisonHurtAdd,
        burn_hurt_add = BurnHurtAdd,
        dizzy_hurt_add = DizzyHurtAdd,
        slow_hurt_add = SlowHurtAdd,
        block_pass = BlockPass
    } = SrcAttr,
    #actor_fight_attr{
        max_hp = MaxHp,
        defence = Defence,
        miss = Miss,
        double_anti = DoubleAnti,
        hurt_derate = HurtDeRate,
        armor = Armor,
        skill_hurt_anti = SkillHurtAnti,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_reduce = BossHurtReduce,
        poison_hurt_reduce = PoisonHurtReduce,
        burn_hurt_reduce = BurnHurtReduce,
        slow_hurt_reduce = SlowHurtReduce,
        block_reduce = BlockReduce
    } = DestAttr,
    SrcActorType2 = get_real_src_type(SrcActorType, SrcMapInfo),

    {IsSrcBoss, IsDestMonster, IsDestBoss, Suppress} = get_monster_and_suppress(SrcActorType, SrcMapInfo, DestActorType, DestMapInfo),
    RoleHurtAdd2 = ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE, mod_fight_etc:get_rate_value(RoleHurtAdd), 0),
    RoleHurtReduce2 = ?IF(SrcActorType2 =:= ?ACTOR_TYPE_ROLE, mod_fight_etc:get_rate_value(RoleHurtReduce), 0),
    MonsterHurtAdd2 = ?IF(IsDestMonster, mod_fight_etc:get_rate_value(MonsterHurtAdd), 0),
    BossHurtAdd2 = ?IF(IsDestBoss, mod_fight_etc:get_rate_value(BossHurtAdd), 0),
    StatusHurtAdd = get_status_add(ImprisonAdd, SilentHurtAdd, PoisonHurtAdd, BurnHurtAdd, DizzyHurtAdd, SlowHurtAdd, DestMapInfo),
    StatusHurtReduce = get_status_reduce(PoisonHurtReduce, BurnHurtReduce, SlowHurtReduce, SrcMapInfo),
    BossHurtReduce2 = ?IF(IsSrcBoss, mod_fight_etc:get_rate_value(BossHurtReduce), 0),
    %% 非普攻技能 MAX(0.5,(1+攻击方技能伤害加深-防御方技能伤害减免))
    FinalSkillMulti = ?IF(SkillType =:= ?SKILL_ATTACK, 1, erlang:max(0.5, (1 + (SkillHurt - SkillHurtAnti)/?RATE_10000))),
    %% 基础加深值1 = 破甲战力-敌方防御战力（破甲战力≥敌方防御战力时）
    BaseHurtRate1 = erlang:max(0, Arp * ?POWER_ARP - Defence * ?POWER_DEFENCE),
    %% 基础加深值2 = 命中战力-敌方闪避战力（命中战力≥敌方闪避战力时）
    BaseHurtRate2 = erlang:max(0, HitRate * ?POWER_HIT_RATE - Miss * ?POWER_HIT_RATE),
    %% 基础免伤值1 = 防御战力-敌方破甲战力（防御战力＞敌方破甲战力时）
    BaseDeRate1 = erlang:max(0, Defence * ?POWER_DEFENCE - Arp * ?POWER_ARP),
    %% 基础免伤值2 = 坚韧战力-敌方暴击战力（坚韧战力＞敌方暴击战力时）
    BaseDeRate2 = erlang:max(0, DoubleAnti * ?POWER_DOUBLE_ANTI - Double * ?POWER_DOUBLE),
    %% 最终护甲值 = 护甲+（-最终暴击率）（最终暴击率＜0时）
    FinalArmor = ?IF(FinalDoubleRate < 0, (Armor - FinalDoubleRate) / ?RATE_10000, 0),
    %% 基础加深率 =（基础加深值1+基础加深值2）/攻击战力
    BaseHurtRate = ?IF(Attack > 0, (BaseHurtRate1 + BaseHurtRate2) / (Attack * ?POWER_ATTACK), 0),
    %% 基础免伤率 =（基础免伤值1+基础免伤值2）/[生命战力+基础免伤值1+基础免伤值2]
    BaseDeRate = (BaseDeRate1 + BaseDeRate2) / (MaxHp * ?POWER_HP + BaseDeRate1 + BaseDeRate2),
    %% 格挡免伤率 = 格挡的前提下, max(0, 格挡穿透 - 格挡减伤)
    BlockDeRate = ?IF(IsBlock, erlang:max(0, (BlockPass - BlockReduce)/?RATE_10000), 0),
    %% 五行伤害加成
    FiveElementsMulti = get_five_elements_multi(SrcAttr, DestAttr),

    %% 伤害 = 实际攻击力*MAX(0.5,(1+攻击方伤害加深-防御方伤害减免+状态加伤-状态减伤)) * MAX(0.5,(1+攻击方PVP伤害加深-防御方PVP伤害减免))*
    %% （1+对boss伤害增加+对怪物伤害加深)* * (1-Boss减伤-状态减伤) * (1+基础加深率) * (1-基础免伤率)
    %% （1-最终护甲值/(1+最终护甲值))* (1-格挡减伤）* 压制相关系数 * 五行伤害加成 * 技能额外加成
    %% 浮动伤害 = 普攻伤害 * [0.9, 1.1]
    Attack * erlang:max(0.5, (1 + HurtRate/?RATE_10000 - HurtDeRate/?RATE_10000+StatusHurtAdd-StatusHurtReduce)) * erlang:max(0.5, (1 + RoleHurtAdd2 - RoleHurtReduce2)) *
        (1 + BossHurtAdd2 + MonsterHurtAdd2) *  (1- BossHurtReduce2) * (1 + BaseHurtRate) * (1 - BaseDeRate)
        * (1 - FinalArmor / (1 + FinalArmor)) * (1 - BlockDeRate) * (1 - BlockDeRate)
        * Suppress * FiveElementsMulti * FinalSkillMulti * (lib_tool:random(9000, 11000) / ?RATE_10000).

%% 特殊效果减伤
reduce_hp_once_effect([], _ReduceRate, ReduceHp) ->
    ReduceHp;
reduce_hp_once_effect([PropEffect|R], ReduceRate, ReduceHp) ->
    #actor_prop_effect{
        type = Type,
        hp_rate = HpRate,
        rate = Rate,
        add_props = AddProps
    } = PropEffect,
    case Type =:= ?PROP_TYPE_REDUCE_HP_ONCE andalso ReduceRate >= (HpRate / ?RATE_10000) andalso common_misc:is_active(Rate) of
        true ->
            ReduceHp2 =
            case lists:keyfind(?ATTR_HURT_DERATE, #p_kv.id, AddProps) of
                #p_kv{val = DeRate} ->
                    erlang:max(1, lib_tool:ceil(ReduceHp * (1 - DeRate / ?RATE_10000)));
                _ ->
                    ReduceHp
            end,
            reduce_hp_once_effect(R, ReduceRate, ReduceHp2);
        _ ->
            reduce_hp_once_effect(R, ReduceRate, ReduceHp)
    end.

add_buffs(ActorID, ActorType, _SrcFightAttr, DestFightAttr, FromActorID, AddBuffIDs) ->
    BuffArgsList = common_buff:get_add_buffs(AddBuffIDs, FromActorID, DestFightAttr),
    add_buffs2(ActorID, ActorType, BuffArgsList).

add_buffs2(ActorID, ActorType, BuffArgsList) ->
    if
        ActorType =:= ?ACTOR_TYPE_ROLE ->
            role_misc:add_buff(ActorID, BuffArgsList);
        ActorType =:= ?ACTOR_TYPE_MONSTER ->
            mod_map_monster:add_buff(ActorID, BuffArgsList);
        ActorType =:= ?ACTOR_TYPE_ROBOT ->
            mod_map_robot:add_buff(ActorID, BuffArgsList);
        true ->
            ok
    end.

can_catch(?ACTOR_TYPE_MONSTER, #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}}) ->
    #c_monster{rarity = Rarity} = monster_misc:get_monster_config(TypeID),
    Rarity =< ?MONSTER_RARITY_NORMAL;
can_catch(_ActorType, _MapInfo) ->
    true.

pet_attack(SrcFight, DestFight, SkillID, SkillType, Value) ->
    {SrcAttr2, DestAttr2, AddValue} = prop_effects(SrcFight, DestFight, SkillID, SkillType),
    SrcAttr3 = common_misc:to_pet_attr(SrcAttr2),
    attack2(SrcFight, DestFight, SrcAttr3, DestAttr2, SkillID, SkillType, Value + AddValue, true).

magic_weapon_attack(SrcFight, DestFight, SkillID, SkillType, Value) ->
    {SrcAttr2, DestAttr2, AddValue} = prop_effects(SrcFight, DestFight, SkillID, SkillType),
    SrcAttr3 = common_misc:to_pet_attr(SrcAttr2),
    attack2(SrcFight, DestFight, SrcAttr3, DestAttr2, SkillID, SkillType, Value + AddValue, true).

rebound(FromID, DestID, ReduceHp) ->
    Result = [#p_result{actor_id = DestID, result_type = ?SET_RESULT_REDUCE_HP(0), value = ReduceHp, show_value = ReduceHp}],
    DataRecord = #m_fight_attack_toc{src_id = FromID, effect_list = Result},
    map_server:broadcast_by_actors([FromID, DestID], DataRecord),
    mod_map_actor:reduce_hp(FromID, DestID, ReduceHp, false).

prop_effects(SrcFight, DestFight, SkillID, SkillType) ->
    #actor_fight{map_info = SrcMapInfo, attr = SrcAttr} = SrcFight,
    #actor_fight{map_info = DestMapInfo, attr = DestAttr} = DestFight,
    SrcPropEffects = SrcAttr#actor_fight_attr.prop_effects,
    DestPropEffects = DestAttr#actor_fight_attr.prop_effects,
    #r_map_actor{hp = SrcHp, actor_type = FromActorType, max_hp = SrcMaxHp} = SrcMapInfo,
    #r_map_actor{hp = DestHp, max_hp = DestMaxHp} = DestMapInfo,
    SrcHpRate = SrcHp / SrcMaxHp * ?RATE_10000,
    DestHpRate = DestHp / DestMaxHp * ?RATE_10000,
    {SrcAttr2, AddValue} = prop_effects2(SrcPropEffects, SrcHpRate, DestHpRate, ?GET_SKILL_FUN(SkillID), SkillType, false, SrcAttr, 0),
    {DestAttr2, _AddValue} = prop_effects2(DestPropEffects, DestHpRate, SrcHpRate, ?GET_SKILL_FUN(SkillID), SkillType, FromActorType =:= ?ACTOR_TYPE_ROLE, DestAttr, 0),
    {SrcAttr2, DestAttr2, AddValue}.

prop_effects2([], _SrcHpRate, _DestHpRate, _SkillFun, _SkillType, _IsFromRole, FightAttr, AddValue) ->
    {FightAttr, AddValue};
prop_effects2([PropEffect|R], SrcHpRate, DestHpRate, SkillFun, SkillType, IsFromRole, FightAttr, AddValue) ->
    #actor_prop_effect{
        type = Type,
        hp_rate = NeedHpRate,
        rate = Rate,
        add_props = AddProps} = PropEffect,
    case Type =:= ?PROP_TYPE_ADD_ROLE_ATTACK of
        true ->
            AddValue2 = ?IF(SkillType =:= ?SKILL_ATTACK, AddValue + Rate, AddValue),
            prop_effects2(R, SrcHpRate, DestHpRate, SkillFun, SkillType, IsFromRole, FightAttr, AddValue2);
        _ ->
            %% 查看血量条件是否满足
            IsHp =
            if
                Type =:= ?PROP_TYPE_SELF_HP_BELOW ->
                    SrcHpRate =< NeedHpRate;
                Type =:= ?PROP_TYPE_SELF_HP_UP ->
                    SrcHpRate >= NeedHpRate;
                true ->
                    DestHpRate =< NeedHpRate
            end,
            case IsHp andalso is_prop_fun_match(SkillFun, Type, IsFromRole) andalso common_misc:is_active(Rate) of
                true ->
                    FightAttr2 = common_misc:get_fight_attr_by_kv(FightAttr, AddProps),
                    prop_effects2(R, SrcHpRate, DestHpRate, SkillFun, SkillType, IsFromRole, FightAttr2, AddValue);
                _ ->
                    prop_effects2(R, SrcHpRate, DestHpRate, SkillFun, SkillType, IsFromRole, FightAttr, AddValue)
            end
    end.

is_prop_fun_match(SkillFun, Type, IsFromRole) ->
    if
        Type =:= ?PROP_TYPE_NORMAL_HIT orelse Type =:= ?PROP_TYPE_SELF_HP_BELOW orelse Type =:= ?PROP_TYPE_SELF_HP_UP ->
            true;
        Type =:= ?PROP_TYPE_PET_HIT andalso SkillFun =:= ?SKILL_FUN_PET ->
            true;
        Type =:= ?PROP_TYPE_MAGIC_WEAPON_HIT andalso SkillFun =:= ?SKILL_FUN_MAGIC ->
            true;
        Type =:= ?PROP_TYPE_CONFINE_HIT andalso SkillFun =:= ?SKILL_FUN_WAR_SPIRIT ->
            true;
        Type =:= ?PROP_TYPE_NORMAL_BE_ATTACKED andalso IsFromRole ->
            true;
        true ->
            false
    end.

add_mfa_list({_M, _F, _Args} = MFA) ->
    List = mod_map_dict:get_fight_mfa_list(),
    List2 = add_mfa_list2(MFA, List, []),
    mod_map_dict:set_fight_mfa_list(List2);
add_mfa_list(_) ->
    ignore.

add_mfa_list2(MFA, [], Acc) ->
    [MFA|Acc];
add_mfa_list2({M, F, Args1}, [{M, F, Args2}|T], Acc) ->
    NewMFAList = add_mfa_list3(M, F, Args1, Args2),
    NewMFAList ++ T ++ Acc;
add_mfa_list2(MFA, [MFA2|T], Acc) ->
    add_mfa_list2(MFA, T, [MFA2|Acc]).

add_mfa_list3(mod_map_actor, reduce_hp, [SrcID, DestID, ReduceHP1], [SrcID, DestID, ReduceHP2]) ->
    [{mod_map_actor, reduce_hp, [SrcID, DestID, ReduceHP1 + ReduceHP2]}];
add_mfa_list3(mod_map_actor, fight_effect_active, [ActorID, ActiveIDS, DestActorIDs], [ActorID, ActiveIDS2, DestActorIDs2]) ->
    [{mod_map_actor, fight_effect_active, [ActorID, ActiveIDS ++ ActiveIDS2, DestActorIDs ++ DestActorIDs2]}];
add_mfa_list3(M, F, Args1, Args2) ->
    [{M, F, Args1}, {M, F, Args2}].

get_real_src_type(?ACTOR_TYPE_TRAP, SrcMapInfo) ->
    #p_map_trap{owner_type = OwnerType} = SrcMapInfo#r_map_actor.trap_extra,
    OwnerType;
get_real_src_type(ActorType, _SrcMapInfo) ->
    ActorType.

get_rebound_mfa(ReduceHp, Rebound, SrcMapInfo, ReboundFromID) ->
    #r_map_actor{actor_type = SrcActorType, actor_id = SrcID, buff_status = BuffStatus} = SrcMapInfo,
    case Rebound > 0 andalso not ?IS_BUFF_LIMIT_UNBEATABLE(BuffStatus) andalso lists:member(SrcActorType, [?ACTOR_TYPE_ROLE, ?ACTOR_TYPE_ROBOT, ?ACTOR_TYPE_MONSTER]) of
        true -> %%
            ReboundReduceHp = lib_tool:ceil(Rebound * ReduceHp / ?RATE_10000),
            MFA = ?IF(ReduceHp > 0, [{mod_fight_effect, rebound, [ReboundFromID, SrcID, ReboundReduceHp]}], []),
            MFA;
        _ ->
            []
    end.

%% 返回 {IsSrcBoss, IsDestMonster, IsDestBoss, Suppress}
get_monster_and_suppress(SrcActorType, SrcMapInfo, DestActorType, DestMapInfo) ->
    if
        SrcActorType =:= ?ACTOR_TYPE_MONSTER ->
            #p_map_monster{type_id = TypeID} = SrcMapInfo#r_map_actor.monster_extra,
            #c_monster{rarity = Rarity, level_suppress = LevelSuppress, power_suppress = PowerSuppress} = monster_misc:get_monster_config(TypeID),
            IsSrcBoss = Rarity =/= ?MONSTER_RARITY_NORMAL andalso Rarity =/= ?MONSTER_RARITY_ELITE,
            case DestActorType of
                ?ACTOR_TYPE_ROLE ->  %% 查看是不是对角色有伤害额外加成
                    %% 怪物对玩家实际伤害=怪物原伤害*(1+erlang:max(0, (怪物压制战力-玩家战力))*战力压制系数)* (1+MAX(0,(怪物压制等级-玩家等级))*等级压制系数)
                    #r_map_actor{role_extra = #p_map_role{level = RoleLevel, power = RolePower}} = DestMapInfo,
                    PowerArgs =
                    case PowerSuppress of
                        [NeedPower, PowerRate] when NeedPower > RolePower ->
                            1 + erlang:max(0, (NeedPower - RolePower) * PowerRate / ?RATE_10000000);
                        _ ->
                            1
                    end,
                    LevelArgs =
                    case LevelSuppress of
                        [NeedLevel, LevelRate] when NeedLevel > RoleLevel ->
                            1 + erlang:max(0, (NeedLevel - RoleLevel) * LevelRate / ?RATE_1000000);
                        _ ->
                            1
                    end,
                    {IsSrcBoss, false, false, PowerArgs * LevelArgs};
                _ ->
                    {IsDestMonster, IsDestBoss} = is_monster_and_boss(DestActorType, DestMapInfo),
                    {IsSrcBoss, IsDestMonster, IsDestBoss, 1}
            end;
        DestActorType =:= ?ACTOR_TYPE_MONSTER ->
            #p_map_monster{type_id = TypeID} = DestMapInfo#r_map_actor.monster_extra,
            #c_monster{rarity = Rarity, level_suppress = LevelSuppress, power_suppress = PowerSuppress} = monster_misc:get_monster_config(TypeID),
            IsDestBoss = Rarity =/= ?MONSTER_RARITY_NORMAL andalso Rarity =/= ?MONSTER_RARITY_ELITE,
            case SrcActorType =:= ?ACTOR_TYPE_ROLE of %% 查看是不是角色的伤害有额外削弱
                true ->
                    %% 玩家对怪物实际伤害=玩家原伤害*MAX战力(0.01,(1-max(0,(怪物压制战力-玩家战力))*战力压制系数))*MAX等级(0.01,(1-max(0,(怪物压制等级-玩家等级))*等级压制系数))
                    #r_map_actor{role_extra = #p_map_role{level = RoleLevel, power = RolePower}} = SrcMapInfo,
                    PowerArgs =
                    case PowerSuppress of
                        [NeedPower, PowerRate] when NeedPower > RolePower ->
                            erlang:max(0.01, 1 - (NeedPower - RolePower) * PowerRate / ?RATE_10000000);
                        _ ->
                            1
                    end,
                    LevelArgs =
                    case LevelSuppress of
                        [NeedLevel, LevelRate] when NeedLevel > RoleLevel ->
                            erlang:max(0.01, 1 - (NeedLevel - RoleLevel) * LevelRate / ?RATE_1000000);
                        _ ->
                            1
                    end,
                    {false, true, IsDestBoss, PowerArgs * LevelArgs};
                _ ->
                    {_IsSrcMonster, IsSrcBoss} = is_monster_and_boss(SrcActorType, SrcMapInfo),
                    {IsSrcBoss, true, IsDestBoss, 1}
            end;
        true ->
            {false, false, false, 1}
    end.

is_monster_and_boss(?ACTOR_TYPE_MONSTER, DestMapInfo) ->
    #p_map_monster{type_id = TypeID} = DestMapInfo#r_map_actor.monster_extra,
    {true, not monster_misc:is_normal_monster(TypeID)};
is_monster_and_boss(_ActorType, _MapInfo) ->
    {false, false}.

%% 各种状态类伤害加成
get_status_add(ImprisonAdd, SilentHurtAdd, PoisonHurtAdd, BurnHurtAdd, DizzyHurtAdd, SlowHurtAdd, DestMapInfo) ->
    #r_map_actor{buff_status = BuffStatus} = DestMapInfo,
    IsDizzy = ?IS_BUFF_DIZZY(BuffStatus),
    IsImprison = ?IS_BUFF_IMPRISON(BuffStatus),
    IsSilent = ?IS_BUFF_LIMIT_SKILL_ATTACK(BuffStatus),
    IsSlow = ?IS_BUFF_SLOW(BuffStatus),
    ImprisonAdd2 = ?IF(IsDizzy orelse IsImprison, ImprisonAdd / ?RATE_10000, 0),
    SilentHurtAdd2 = ?IF(IsDizzy orelse IsSilent, SilentHurtAdd / ?RATE_10000, 0),
    PoisonHurtAdd2 = ?IF(?IS_BUFF_POISON(BuffStatus), PoisonHurtAdd / ?RATE_10000, 0),
    BurnHurtAdd2 = ?IF(?IS_BUFF_BURN(BuffStatus), BurnHurtAdd / ?RATE_10000, 0),
    DizzyHurtAdd2 = ?IF(IsDizzy, DizzyHurtAdd/?RATE_10000, 0),
    SlowHurtAdd2 = ?IF(IsSlow, SlowHurtAdd/?RATE_10000, 0),
    lists:max([DizzyHurtAdd2, ImprisonAdd2, SilentHurtAdd2, PoisonHurtAdd2, BurnHurtAdd2, SlowHurtAdd2]).

%% 各种状态减伤
get_status_reduce(PoisonHurtReduce, BurnHurtReduce, SlowHurtReduce, SrcMapInfo) ->
    #r_map_actor{buff_status = BuffStatus} = SrcMapInfo,
    PoisonHurtReduce2 = ?IF(?IS_BUFF_POISON(BuffStatus), PoisonHurtReduce/?RATE_10000, 0),
    BurnHurtReduce2 = ?IF(?IS_BUFF_BURN(BuffStatus), BurnHurtReduce/?RATE_10000, 0),
    SlowHurtReduce2 = ?IF(?IS_BUFF_SLOW(BuffStatus), SlowHurtReduce/?RATE_10000, 0),
    lists:max([PoisonHurtReduce2, BurnHurtReduce2, SlowHurtReduce2]).

get_dizzy_rate_mfa(SrcID, DizzyRate, DestActorType, DestID) ->
    case common_misc:is_active(DizzyRate) of
        true ->
            BuffArgs = #buff_args{buff_id = ?BUFF_DIZZY_RATE, from_actor_id = SrcID},
            if
                DestActorType =:= ?ACTOR_TYPE_ROLE ->
                    [{role_misc, add_buff, [DestID, BuffArgs]}];
                DestActorType =:= ?ACTOR_TYPE_MONSTER ->
                    [{mod_map_monster, add_buff, [DestID, BuffArgs]}];
                DestActorType =:= ?ACTOR_TYPE_ROBOT ->
                    [{mod_map_robot, add_buff, [DestID, BuffArgs]}];
                true ->
                    []
            end;
        _ ->
            []
    end.

get_fight_effects(SrcMapInfo, DestMapInfo, SrcFightAttr, DestFightAttr, SkillID, IsDouble, IsBlock, ReduceHp) ->
    NowMs = time_tool:now_ms(),
    #r_map_actor{hp = Hp, max_hp = MaxHp, actor_id = SrcActorID, actor_type = SrcActorType, fight_effects = SrcFightEffects} = SrcMapInfo,
    #r_map_actor{actor_id = DestActorID, actor_type = DestActorType, buff_status = DestBuffStatus, fight_effects = DestFightEffects} = DestMapInfo,
    HpRate = lib_tool:ceil(?RATE_10000 * Hp/MaxHp),

    SrcEffects = get_fight_effect_by_type(?FIGHT_EFFECT_ATTACK, SrcFightEffects),
    {SrcBuffIDs, SrcEnemyBuffIDs, SrcActiveIDs} = get_src_fight_effects(SrcEffects, NowMs, SkillID, HpRate, DestBuffStatus, IsDouble, DestActorType, [], [], []),
    DestEffects = get_fight_effect_by_type(?FIGHT_EFFECT_BE_ATTACKED, DestFightEffects),
    {DestEnemyBuffIDs, DestActiveIDs} = get_dest_fight_effects(DestEffects, NowMs, ReduceHp, DestBuffStatus, DestFightAttr, IsDouble, IsBlock, SrcActorType, [], []),
    add_buffs(DestActorID, DestActorType, DestFightAttr, SrcFightAttr, SrcActorID, SrcEnemyBuffIDs),
    add_buffs(SrcActorID, SrcActorType, SrcFightAttr, SrcFightAttr, SrcActorID, SrcBuffIDs),
    add_buffs(SrcActorID, SrcActorType, SrcFightAttr, DestFightAttr, DestActorID, DestEnemyBuffIDs),

    ReboundEffects = get_fight_effect_by_type(?FIGHT_EFFECT_REBOUND, DestFightEffects),
    {DestActiveIDs2, MFA3} = get_rebound_fight_effect(ReboundEffects, NowMs, ReduceHp, SrcMapInfo, DestActorID, DestActiveIDs, []),
    do_be_attacked_buff(SrcMapInfo, DestMapInfo, DestFightAttr),
    MFA1 = ?IF(SrcActiveIDs =/= [], [{mod_map_actor, fight_effect_active, [SrcActorID, SrcActiveIDs, [DestActorID]]}], []),
    MFA2 = ?IF(DestActiveIDs2 =/= [], [{mod_map_actor, fight_effect_active, [DestActorID, DestActiveIDs2, [SrcActorID]]}], []),
    MFA3 ++ MFA1 ++ MFA2.


%% 攻击发起者触发的buff
get_src_fight_effects([], _NowMs, _HpRate, _SkillID, _DestBuffStatus, _IsDouble, _DestActorType, SrcBuffIDs, EnemyBuffIDs, ActiveIDs) ->
    {SrcBuffIDs, EnemyBuffIDs, ActiveIDs};
get_src_fight_effects([FightEffect|R], NowMs, SkillID, HpRate, DestBuffStatus, IsDouble, DestActorType, SrcBuffIDs, EnemyBuffIDs, ActiveIDs) ->
    #r_fight_effect{
        id = ID,
        rate = Rate,
        condition = Condition,
        enemy_buffs = EnemyBuffs,
        self_buffs = SelfBuffs,
        time = Time} = FightEffect,
    case NowMs >= Time andalso common_misc:is_active(Rate) of
        true -> %% 先检测类型、时间、概率
            {SrcBuffIDs2, EnemyBuffIDs2, ActiveIDs2} =
                case Condition of
                    [?FIGHT_EFFECT_ATTACK_POISON] -> %% 击中中毒敌人
                        ?IF(?IS_BUFF_POISON(DestBuffStatus), {SelfBuffs ++ SrcBuffIDs, EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    [?FIGHT_EFFECT_ATTACK_BURN] ->  %% 击中燃烧敌人
                        ?IF(?IS_BUFF_BURN(DestBuffStatus), {SelfBuffs ++ SrcBuffIDs,EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    [?FIGHT_EFFECT_DOUBLE] -> %% 暴击
                        ?IF(IsDouble, {SelfBuffs ++ SrcBuffIDs,EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    [?FIGHT_EFFECT_ROLE_DOUBLE] -> %% 对玩家暴击
                        ?IF(IsDouble andalso DestActorType =:= ?ACTOR_TYPE_ROLE, {SelfBuffs ++ SrcBuffIDs,EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    [?FIGHT_EFFECT_RELEASE_SKILL|SkillIDList] -> %% 释放技能
                        ?IF(lists:member(?GET_SKILL_TYPE_ID(SkillID), SkillIDList), {SelfBuffs ++ SrcBuffIDs, EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    [?FIGHT_EFFECT_HIT_ENEMY] -> %% 命中敌人
                        {SelfBuffs ++ SrcBuffIDs, EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]};
                    [?FIGHT_EFFECT_HP_BELOW, NeedHpRate] ->
                        ?IF(HpRate =< NeedHpRate, {SelfBuffs ++ SrcBuffIDs, EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {SrcBuffIDs, EnemyBuffIDs, ActiveIDs});
                    _ -> %% 其他情况都默认触发
                        {SelfBuffs ++ SrcBuffIDs, EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}
                end,
            get_src_fight_effects(R, NowMs, SkillID, HpRate, DestBuffStatus, IsDouble, DestActorType, SrcBuffIDs2, EnemyBuffIDs2, ActiveIDs2);
        _ ->
            get_src_fight_effects(R, NowMs, SkillID, HpRate, DestBuffStatus, IsDouble, DestActorType, SrcBuffIDs, EnemyBuffIDs, ActiveIDs)
    end.

%% 受击者触发的buff
get_dest_fight_effects([], _NowMs, _ReduceHp, _DestBuffStatus, _DestFight, _IsDouble, _IsBlock, _SrcActorType, EnemyBuffIDs, ActiveIDs) ->
    {EnemyBuffIDs, ActiveIDs};
get_dest_fight_effects([FightEffect|R], NowMs, ReduceHp, DestBuffStatus, DestFight, IsDouble, IsBlock, SrcActorType, EnemyBuffIDs, ActiveIDs) ->
    #r_fight_effect{
        id = ID,
        rate = Rate,
        condition = Condition,
        enemy_buffs = EnemyBuffs,
        time = Time} = FightEffect,
    case NowMs >= Time andalso common_misc:is_active(Rate) of
        true -> %% 先检测类型、时间、概率
            {EnemyBuffIDs2, ActiveIDs2} =
            case Condition of
                [?FIGHT_EFFECT_BE_ATTACKED_HP_RATE, NeedHpRate] -> %% 受到的单次伤害超过生命上限15%
                    ?IF((?RATE_10000 * ReduceHp / DestFight#actor_fight_attr.max_hp) >= NeedHpRate, {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                [?FIGHT_EFFECT_BE_ROLE_DOUBLE] -> %% 受到玩家暴击
                    ?IF(IsDouble andalso SrcActorType =:= ?ACTOR_TYPE_ROLE, {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                [?FIGHT_EFFECT_BLOCK_RATE] -> %% 格挡
                    ?IF(IsBlock, {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                [?FIGHT_EFFECT_BLOCK_ROLE] -> %% 格挡玩家
                    ?IF(IsBlock andalso SrcActorType =:= ?ACTOR_TYPE_ROLE, {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                [?FIGHT_EFFECT_BLOCK_MONSTER] -> %% 格挡怪物
                    ?IF(IsBlock andalso SrcActorType =:= ?ACTOR_TYPE_MONSTER, {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                [?FIGHT_EFFECT_DIZZY_BE_ATTACKED] -> %% 自身眩晕时触发
                    ?IF(?IS_BUFF_DIZZY(DestBuffStatus), {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}, {EnemyBuffIDs, ActiveIDs});
                _ -> %% 其他情况都默认触发
                    {EnemyBuffs ++ EnemyBuffIDs, [ID|ActiveIDs]}
            end,
            get_dest_fight_effects(R, NowMs, ReduceHp, DestBuffStatus, DestFight, IsDouble, IsBlock, SrcActorType, EnemyBuffIDs2, ActiveIDs2);
        _ ->
            get_dest_fight_effects(R, NowMs, ReduceHp, DestBuffStatus, DestFight, IsDouble, IsBlock, SrcActorType, EnemyBuffIDs, ActiveIDs)
    end.

%% 查看触发的反击效果
get_rebound_fight_effect([], _NowMs, _ReduceHp, _SrcMapInfo, _DestActorID, ActiveIDs, MFAAcc) ->
    {ActiveIDs, MFAAcc};
get_rebound_fight_effect([FightEffect|R], NowMs, ReduceHp, SrcMapInfo, DestActorID, ActiveIDs, MFAAcc) ->
    #r_fight_effect{
        id = ID,
        rate = Rate,
        time = Time,
        args = Args} = FightEffect,
    case NowMs >= Time andalso common_misc:is_active(Rate) of
        true -> %% 先检测类型、时间、概率
            MFAAcc2 =
            case Args of
                [Rebound] ->
                    get_rebound_mfa(ReduceHp, Rebound, SrcMapInfo, DestActorID) ++ MFAAcc;
                _ ->
                    MFAAcc
            end,
            get_rebound_fight_effect(R, NowMs, ReduceHp, SrcMapInfo, DestActorID, [ID|ActiveIDs], MFAAcc2);
        _ ->
            get_rebound_fight_effect(R, NowMs, ReduceHp, SrcMapInfo, DestActorID, ActiveIDs, MFAAcc)
    end.

%% 最大生命效果扣除
get_max_hp_fight_effect([], _SkillID, _DestActorType, DestMaxHp, Rate) ->
    lib_tool:ceil(DestMaxHp * Rate);
get_max_hp_fight_effect([FightEffect|R], SkillID, DestActorType, DestMaxHp, Rate) ->
    #r_fight_effect{
        condition = Condition
    } = FightEffect,
    Rate2 =
    case Condition of
        [?FIGHT_EFFECT_ROLE_MAX_HP_REDUCE, MaxHpRate|SkillList] ->
            ?IF(DestActorType =:= ?ACTOR_TYPE_ROLE andalso lists:member(SkillID, SkillList), Rate + MaxHpRate, Rate);
        _ ->
            Rate
    end,
    get_max_hp_fight_effect(R, SkillID, DestActorType, DestMaxHp, Rate2).

%% 收到攻击触发buff
do_be_attacked_buff(SrcMapInfo, DestMapInfo, DestFightAttr) ->
    #r_map_actor{
        actor_id = DestActorID,
        buff_status = BuffStatus, buffs = Buffs} = DestMapInfo,
    case ?IS_BUFF_BE_ATTACKED_BUFF(BuffStatus) of
        true ->
            #r_map_actor{
                actor_id = SrcActorID,
                actor_type = SrcActorType} = SrcMapInfo,
            AddBuffIDs = get_be_attacked_buff(Buffs, []),
            BuffArgsList = common_buff:get_add_buffs(AddBuffIDs, DestActorID, DestFightAttr),
            add_buffs2(SrcActorID, SrcActorType, BuffArgsList);
        _ ->
            []
    end.

get_be_attacked_buff([], BuffIDAcc) ->
    BuffIDAcc;
get_be_attacked_buff([BuffID|R], BuffIDAcc) ->
    [#c_buff{value = ValueArgs}] = lib_config:find(cfg_buff, BuffID),
    BuffIDAcc2 = lib_tool:string_to_integer_list(ValueArgs) ++ BuffIDAcc,
    get_be_attacked_buff(R, BuffIDAcc2).

%% 吸血效果
get_drain_effect(SrcID, Attack, Drain) ->
    case Drain > 0 of
        true ->
            NowMs = time_tool:now_ms(),
            IsDrain =
            case mod_map_dict:get_role_last_drain(SrcID) of
                LastTime when erlang:is_integer(LastTime) ->
                    %% 间隔必须超过500Ms
                    NowMs - LastTime >= 500;
                _ ->
                    true
            end,
            case IsDrain of
                true ->
                    mod_map_dict:set_role_last_drain(SrcID, NowMs),
                    AddHp = lib_tool:ceil(Attack * Drain / ?RATE_10000),
                    [{mod_map_actor, buff_heal, [SrcID, AddHp, ?BUFF_ADD_HP, 0]}];
                _ ->
                    []
            end;
        _ ->
            []
    end.

%% 扣血在部分情况下是有上下限
get_real_reduce(ReduceHp, 0, 0, _MaxHp, _IsPet, SrcID, SrcActorType) ->
    case mod_map_dict:get_sub_type() =:= ?SUB_TYPE_FAMILY_BOSS andalso SrcActorType =:= ?ACTOR_TYPE_ROLE of
        true ->
            mod_map_family_god_beast:do_hurt(ReduceHp, SrcID),
            0;
        _ ->
            ReduceHp
    end;
get_real_reduce(ReduceHp, 0, ?RATE_10000, _MaxHp, _IsPet, SrcID, SrcActorType) ->
    case mod_map_dict:get_sub_type() =:= ?SUB_TYPE_FAMILY_BOSS andalso SrcActorType =:= ?ACTOR_TYPE_ROLE of
        true ->
            mod_map_family_god_beast:do_hurt(ReduceHp, SrcID),
            0;
        _ ->
            ReduceHp
    end;
get_real_reduce(ReduceHp, MinReduceRate, MaxReduceRate, Hp, IsPet, SrcID, SrcActorType) ->
    %% 宠物攻击不取下限
    MinHp = ?IF(IsPet, 0, Hp * MinReduceRate / ?RATE_10000),
    MaxHp = Hp * MaxReduceRate / ?RATE_10000,
    ReduceHp2 =
    if
        ReduceHp < MinHp -> %% 取下限
            lib_tool:random(-100, 100) + lib_tool:ceil(MinHp);
        ReduceHp > MaxHp -> %% 取上限
            lib_tool:random(-100, 100) + lib_tool:ceil(MaxHp);
        true ->
            ReduceHp
    end,
    SubType = mod_map_dict:get_sub_type(),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_1 orelse SubType =:= ?SUB_TYPE_DEMON_BOSS -> %% 世界boss/魔域boss 要根据当前房间人数扣除血量
            RoleNum = erlang:length(mod_map_ets:get_in_map_roles()),
            ?IF(RoleNum > 0, lib_tool:ceil(ReduceHp2 / RoleNum), ReduceHp2);
        SubType =:= ?SUB_TYPE_FAMILY_BOSS andalso SrcActorType =:= ?ACTOR_TYPE_ROLE ->
            mod_map_family_god_beast:do_hurt(ReduceHp, SrcID),
            0;
        true ->
            ReduceHp2
    end.

get_actor_level(#r_map_actor{actor_type = ActorType} = MapActor) ->
    case ActorType of
        ?ACTOR_TYPE_ROLE ->
            MapActor#r_map_actor.role_extra#p_map_role.level;
        ?ACTOR_TYPE_MONSTER ->
            MapActor#r_map_actor.monster_extra#p_map_monster.level;
        ?ACTOR_TYPE_TRAP ->
            MapActor#r_map_actor.trap_extra#p_map_trap.owner_level;
        _ ->
            0
    end.

%% 2次伤害
get_double_damage(DestID, MinReduceRate, MaxReduceRate, MaxHp, IsPet, DoubleDamageRate, ReduceHp, SrcID,SrcActorType) ->
    case common_misc:is_active(DoubleDamageRate) of
        true ->
            RealReduceHp = lib_tool:ceil(get_real_reduce(ReduceHp, MinReduceRate, MaxReduceRate, MaxHp, IsPet, SrcID,SrcActorType)),
            ResultList = [#p_result{actor_id = DestID, result_type = ?SET_RESULT_REDUCE_HP(0), value = RealReduceHp, show_value = lib_tool:ceil(ReduceHp)}],
            {RealReduceHp, ResultList};
        _ ->
            {0, []}
    end.

%% 获取五行伤害加成
get_five_elements_multi(undefined, _DestAttr) ->
    1;
get_five_elements_multi(SrcAttr, DestAttr) ->
    case mod_map_dict:get_sub_type()  of
        ?SUB_TYPE_FIVE_ELEMENTS ->
            #actor_fight_attr{
                metal = Metal,
                wood = Wood,
                water = Water,
                fire = Fire,
                earth = Earth
            } = SrcAttr,
            #actor_fight_attr{
                metal_anti = MetalA,
                wood_anti = WoodA,
                water_anti = WaterA,
                fire_anti = FireA,
                earth_anti = EarthA
            } = DestAttr,
            Attack = Metal + Wood + Water + Fire + Earth,
            Defence = MetalA + WoodA + WaterA + FireA + EarthA,
            ?IF(Defence > 0, erlang:min(1.5, erlang:max(0.3, (Attack + 1000)/(Defence + 1000))), 1.5);
        _ ->
            1
    end.

get_fight_effect_by_type(Type, FightEffects) ->
    case lists:keyfind(Type, 1, FightEffects) of
        {Type, List} ->
            List;
        _ ->
            []
    end.