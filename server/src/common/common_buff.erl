%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 五月 2017 12:21
%%%-------------------------------------------------------------------
-module(common_buff).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    add_buff/3,
    remove_buff/3,
    loop/3,
    recal_status/1,
    get_cal_attr/2,
    sum_attr/2,
    get_add_buffs/3
]).

add_buff(AddBuffs, Buffs, Debuffs) ->
    Now = time_tool:now(),
    ImmuneBuffs = get_immune_list(Buffs ++ Debuffs, []),
    {Buffs2, Debuffs2, Change1, Change2} =
        lists:foldl(
            fun(BuffArgs, {BuffsAcc, DebuffsAcc, ChangeAcc1, ChangeAcc2}) ->
                BuffID = BuffArgs#buff_args.buff_id,
                [BuffCfg] = lib_config:find(cfg_buff, BuffID),
                #c_buff{buff_class = BuffClass, buff_attr = BuffAttr, add_rate = AddRate} = BuffCfg,
                case lists:member(BuffClass, ImmuneBuffs) orelse lib_tool:random(?RATE_10000) > AddRate of
                    true -> %% 免疫特定的buff 或者没触发到对应概率
                        {BuffsAcc, DebuffsAcc, ChangeAcc1, ChangeAcc2};
                    _ ->
                        if
                            BuffAttr =:= ?BUFF_DISPEL_BUFF ->
                                {BuffsAcc2, IsChange} = dispel_buffs(BuffCfg, BuffsAcc),
                                {BuffsAcc2, DebuffsAcc, IsChange orelse ChangeAcc1, ChangeAcc2};
                            BuffAttr =:= ?BUFF_DISPEL_DEBUFF ->
                                {DebuffsAcc2, IsChange} = dispel_buffs(BuffCfg, DebuffsAcc),
                                {BuffsAcc, DebuffsAcc2, ChangeAcc1, IsChange orelse ChangeAcc2};
                            true ->
                                add_buff2(BuffArgs, Now, BuffCfg, BuffsAcc, DebuffsAcc, ChangeAcc1, ChangeAcc2)
                        end
                end
            end, {Buffs, Debuffs, false, false}, AddBuffs),
    Buffs3 = get_buffs_by_num(Buffs2, ?MAX_BUFF_NUM),
    Debuffs3 = get_buffs_by_num(Debuffs2, ?MAX_DEBUFF_NUM),
    {IsCalc1, IsStatus1, UpdateList1, DelIDList1} = get_buff_change(Buffs, Buffs3, Change1),
    {IsCalc2, IsStatus2, UpdateList2, DelIDList2} = get_buff_change(Debuffs, Debuffs3, Change2),
    {Buffs3, Debuffs3, IsCalc1 orelse IsCalc2, IsStatus1 orelse IsStatus2, UpdateList1 ++ UpdateList2, DelIDList1 ++ DelIDList2}.

add_buff2(BuffArgs, Now, BuffCfg, Buffs, Debuffs, Change1, Change2) ->
    #c_buff{buff_type = BuffType} = BuffCfg,
    if
        ?IS_BUFF(BuffType) ->
            {ok, Buffs2, IsChange} = add_buff3(BuffArgs, Now, BuffCfg, Buffs),
            {Buffs2, Debuffs, Change1 orelse IsChange, Change2};
        ?IS_DEBUFF(BuffType) ->
            {ok, Debuffs2, IsChange} = add_buff3(BuffArgs, Now, BuffCfg, Debuffs),
            {Buffs, Debuffs2, Change1, Change2 orelse IsChange}
    end.

add_buff3(BuffArgs, Now, BuffCfg, Buffs) ->
    #buff_args{
        buff_id = BuffID,
        from_actor_id = FromActorID,
        buff_last_time = BuffLastTime,
        extra_value = ExtraValue} = BuffArgs,
    #c_buff{
        buff_class = BuffClass,
        buff_attr = BuffAttr,
        buff_exist_type = BuffExist,
        is_add_time = IsAddTime,
        cover_times = CoverTimes,
        bid_level = BidLevel,
        last_time = LastTimeT} = BuffCfg,
    %% 部分buff的时间不是读配置表，而是传值进去
    LastTime = ?IF(BuffLastTime =:= 0 orelse LastTimeT =:= 0, LastTimeT, BuffLastTime),
    case lists:keytake(BuffID, #r_buff.buff_id, Buffs) of
        {value, #r_buff{cover_times = HasTimes, end_time = OldEndTime} = Buff, RemainList} ->  %% 同ID，叠加 or 更新时
            NewEndTime = ?IF(IsAddTime > 0, OldEndTime + LastTime, Now + LastTime),
            NewEndTime2 = ?IF(LastTime =:= 0, 0, NewEndTime),
            Buff2 = ?IF(CoverTimes > HasTimes,
                Buff#r_buff{cover_times = HasTimes + 1, end_time = NewEndTime,
                    extra_value = ExtraValue, from_actor_id = FromActorID},
                Buff#r_buff{from_actor_id = FromActorID, end_time = NewEndTime2, extra_value = ExtraValue}),
            Buffs2 = [Buff2|RemainList],
            {ok, Buffs2, true};
        _ ->
            %% 永久buff
            LastTime2 = ?IF(LastTime =:= 0, 0, Now + LastTime),
            Buff = #r_buff{
                buff_id = BuffID,
                buff_class = BuffClass,
                buff_attr = BuffAttr,
                cover_times = 1,
                from_actor_id = FromActorID,
                start_time = Now,
                end_time = LastTime2,
                extra_value = ExtraValue},
            case lists:keytake(BuffClass, #r_buff.buff_class, Buffs) of
                {value, #r_buff{buff_id = DestBuffID}, RemainList} -> %% 同类型，共存 or 替换 or 忽略
                    [#c_buff{bid_level = DestBidLevel}] = lib_config:find(cfg_buff, DestBuffID),
                    if
                        ?IS_COEXIST(BuffExist) -> %% 可以共存
                            {ok, [Buff|Buffs], true};
                        BidLevel >= DestBidLevel -> %% 冲顶
                            {ok, [Buff|RemainList], true};
                        true -> %% 忽略
                            {ok, Buffs, false}
                    end;
                _ -> %% 直接加
                    {ok, [Buff|Buffs], true}
            end
    end.

remove_buff(BuffIDList, Buffs, Debuffs) ->
    {Buffs2, Debuffs2, Change1, Change2} =
        lists:foldl(
            fun(BuffID, {BuffsAcc, DebuffsAcc, ChangeAcc1, ChangeAcc2}) ->
                {BuffsAcc2, NewChangeAcc1} = remove_buff2(BuffID, BuffsAcc),
                {DebuffsAcc2, NewChangeAcc2} = remove_buff2(BuffID, DebuffsAcc),
                {BuffsAcc2, DebuffsAcc2, ChangeAcc1 orelse NewChangeAcc1, ChangeAcc2 orelse NewChangeAcc2}
            end, {Buffs, Debuffs, false, false}, BuffIDList),
    {IsCalc1, IsStatus1, UpdateList1, DelList1} = get_buff_change(Buffs, Buffs2, Change1),
    {IsCalc2, IsStatus2, UpdateList2, DelList2} = get_buff_change(Debuffs, Debuffs2, Change2),
    {Buffs2, Debuffs2, IsCalc1 orelse IsCalc2, IsStatus1 orelse IsStatus2, UpdateList1 ++ UpdateList2, DelList1 ++ DelList2}.

remove_buff2(BuffID, Buffs) ->
    case lists:keytake(BuffID, #r_buff.buff_id, Buffs) of
        {value, _Buff, Buffs2} ->
            {Buffs2, true};
        _ ->
            {Buffs, false}
    end.

%% 对比加buff前与加buff后的变化
get_buff_change(_Buffs, _Buffs2, false) ->
    {false, false, [], []};
get_buff_change(Buffs, Buffs2, _Change1) ->
    {UpdateList, DelList} = get_buffs_update(Buffs2, Buffs),
    {IsCalc1, IsStatus1} = get_buff_flag_change(UpdateList, false, false),
    {IsCalc2, IsStatus2} = get_buff_flag_change(DelList, false, false),
    DelList2 = [ BuffID || #r_buff{buff_id = BuffID} <- DelList],
    {IsCalc1 orelse IsCalc2, IsStatus1 orelse IsStatus2, UpdateList, DelList2}.

get_buffs_update(NewBuffs, OldBuffs) ->
    lists:foldl(
        fun(#r_buff{buff_id = BuffID, cover_times = CoverTimes, end_time = EndTime} = Buff, {Acc1, Acc2}) ->
            case lists:keytake(BuffID, #r_buff.buff_id, Acc2) of
                {value, #r_buff{cover_times = CoverTimes2, end_time = EndTime2}, RemainList} ->
                    case CoverTimes =/= CoverTimes2 orelse EndTime =/= EndTime2 of  %% 同ID，且CoverTimes与end_time相同，那么就不更新
                        true ->
                            {[Buff|Acc1], RemainList};
                        _ ->
                            {Acc1, RemainList}
                    end;
                false ->
                    {[Buff|Acc1], Acc2}
            end
    end, {[], OldBuffs}, NewBuffs).

get_buff_flag_change(_, true, true) ->
    {true, true};
get_buff_flag_change([], IsCalc, IsStatus) ->
    {IsCalc, IsStatus};
get_buff_flag_change([#r_buff{buff_id = BuffID}|R], IsCalc, IsStatus) ->
    [#c_buff{buff_attr = BuffAttr}] = lib_config:find(cfg_buff, BuffID),
    IsCalc2 = IsCalc orelse lists:member(BuffAttr, ?BUFF_CALC_LIST),
    IsStatus2 = IsStatus orelse lists:member(BuffAttr, ?BUFF_STATUS_LIST),
    get_buff_flag_change(R, IsCalc2, IsStatus2).

%% buff的秒循环
loop(Now, Buffs, Debuffs) ->
    {Buffs2, DelList1, EffectList1, IsCalc1, IsStatus1} = loop2(Now, Buffs),
    {DeBuffs2, DelList2, EffectList2, IsCalc2, IsStatus2} = loop2(Now, Debuffs),
    {Buffs2, DeBuffs2, EffectList1 ++ EffectList2, IsCalc1 orelse IsCalc2, IsStatus1 orelse IsStatus2, DelList1 ++ DelList2}.

loop2(Now, Buffs) ->
    lists:foldl(
        fun(Buff, {BuffAcc, DelAcc, EffectAcc, IsCalcAcc, IsStatusAcc}) ->
            #r_buff{buff_id = BuffID,
                end_time = EndTime,
                last_effect_time = LastEffectTime,
                from_actor_id = FromActorID} = Buff,
            [BuffCfg] = lib_config:find(cfg_buff, BuffID),
            #c_buff{
                buff_attr = BuffAttr,
                effect_interval = EffectInterval,
                value = ValueArgs} = BuffCfg,
            case EndTime =/= 0 andalso Now > EndTime of
                true ->
                    BuffAcc2 = BuffAcc,
                    DelAcc2 = [BuffID|DelAcc],
                    IsCalcAcc2 = IsCalcAcc orelse lists:member(BuffAttr, ?BUFF_CALC_LIST),
                    IsStatusAcc2 = IsStatusAcc orelse lists:member(BuffAttr, ?BUFF_STATUS_LIST),
                    EffectAcc2 = EffectAcc;
                _ ->
                    case get_loop_effect(Buff, BuffAttr, LastEffectTime, FromActorID, ValueArgs, Now, EffectInterval) of
                        {Buff2, Effect} ->
                            BuffAcc2 = [Buff2|BuffAcc],
                            EffectAcc2 = [Effect|EffectAcc];
                        _ ->
                            BuffAcc2 = [Buff|BuffAcc],
                            EffectAcc2 = EffectAcc
                    end,
                    DelAcc2 = DelAcc,
                    IsCalcAcc2 = IsCalcAcc,
                    IsStatusAcc2 = IsStatusAcc
            end,
            {BuffAcc2, DelAcc2, EffectAcc2, IsCalcAcc2, IsStatusAcc2}
        end, {[], [], [], false, false}, Buffs).

get_loop_effect(Buff, BuffAttr, LastEffectTime, FromActorID, ValueArgs, Now, EffectInterval) ->
    #r_buff{buff_id = BuffID, extra_value = ExtraValue} = Buff,
    if
        BuffAttr =:= ?BUFF_POISON orelse BuffAttr =:= ?BUFF_BURN ->
            case Now - LastEffectTime >= EffectInterval of
                true ->
                    {Buff#r_buff{last_effect_time = Now}, {BuffAttr, BuffID, FromActorID, lib_tool:ceil(ExtraValue * lib_tool:to_integer(ValueArgs)/?RATE_10000)}};
                _ ->
                    false
            end;
        BuffAttr =:= ?BUFF_ADD_HP orelse BuffAttr =:= ?BUFF_ATTACK_HEAL orelse BuffAttr =:= ?BUFF_LEVEL_HP_BUFF ->
            case Now - LastEffectTime >= EffectInterval of
                true ->
                    {Buff#r_buff{last_effect_time = Now}, {BuffAttr, BuffID, FromActorID, lib_tool:to_integer(ValueArgs)}};
                _ ->
                    false
            end;
        true ->
            fales
    end.

%% 这里加了，一定要在fight.hrl里的宏定义里 BUFF_STATUS_LIST 修改
recal_status(BuffList) ->
    lists:foldl(
        fun(#r_buff{buff_attr = BuffAttr}, BuffStatus) ->
            if
                BuffAttr =:= ?BUFF_IMPRISON ->
                    ?SET_BUFF_IMPRISON(BuffStatus);
                BuffAttr =:= ?BUFF_DIZZY ->
                    ?SET_BUFF_DIZZY(BuffStatus);
                BuffAttr =:= ?BUFF_LIMIT_N_A ->
                    ?SET_BUFF_LIMIT_NORMAL_ATTACK(BuffStatus);
                BuffAttr =:= ?BUFF_LIMIT_S_A ->
                    ?SET_BUFF_LIMIT_SKILL_ATTACK(BuffStatus);
                BuffAttr =:= ?BUFF_LIMIT_U_S ->
                    ?SET_BUFF_LIMIT_UNIQUE_SKILL(BuffStatus);
                BuffAttr =:= ?BUFF_LIMIT_ITEM ->
                    ?SET_BUFF_LIMIT_USE_ITEM(BuffStatus);
                BuffAttr =:= ?BUFF_LIMIT_MONSTER ->
                    ?SET_BUFF_LIMIT_ATTACK_MONSTER(BuffStatus);
                BuffAttr =:= ?BUFF_UNBEATABLE ->
                    ?SET_BUFF_LIMIT_UNBEATABLE(BuffStatus);
                BuffAttr =:= ?BUFF_POISON ->
                    ?SET_BUFF_POISON(BuffStatus);
                BuffAttr =:= ?BUFF_BURN ->
                    ?SET_BUFF_BURN(BuffStatus);
                BuffAttr =:= ?BUFF_BE_ATTACKED_BUFF ->
                    ?SET_BUFF_BE_ATTACKED_BUFF(BuffStatus);
                BuffAttr =:= ?BUFF_SLOW ->
                    ?SET_BUFF_SLOW(BuffStatus);
                true ->
                    BuffStatus
            end
        end, 0, BuffList).

%% 获取buff对应的属性值
get_cal_attr(Buffs, BaseAttr) ->
    lists:foldl(
        fun(#r_buff{buff_id = BuffID, cover_times = CoverTimes, extra_value = ExtraValue}, Acc) ->
            [BuffCfg] = lib_config:find(cfg_buff, BuffID),
            #c_buff{buff_attr = BuffAttr, value = ValueArgs} = BuffCfg,
            if
                BuffAttr =:= ?BUFF_PROP_CHANGE orelse BuffAttr =:= ?BUFF_SLOW ->
                    PropAttr = common_misc:get_attr_by_kv(common_misc:get_string_props(ValueArgs, CoverTimes)),
                    common_misc:sum_calc_attr2(Acc, PropAttr);
                BuffAttr =:= ?BUFF_STEAL_PROP ->
                    PropAttr = get_steal_prop_attr(common_misc:get_string_props(ValueArgs, CoverTimes), ExtraValue),
                    common_misc:sum_calc_attr2(Acc, PropAttr);
                BuffAttr =:= ?BUFF_LIMIT_PROP ->
                    LimitAttr = get_limit_prop(common_misc:get_string_props(ValueArgs, CoverTimes), BaseAttr),
                    common_misc:sum_calc_attr2(Acc, LimitAttr);
                true ->
                    Acc
            end
        end, #actor_cal_attr{}, Buffs).

%% 获取偷取属性
get_steal_prop_attr(PropList, #actor_fight_attr{} = FightAttr) ->
    #actor_fight_attr{
        max_hp = MaxHp,
        attack = Attack,
        defence = Defence
    } = FightAttr,
    lists:foldl(
        fun(#p_kv{id = ID, val = Val}, AttrAcc) ->
            #actor_cal_attr{
                max_hp = {MaxHpAcc, MaxHpR},
                attack = {AttackAcc, AttackR},
                defence = {DefenceAcc, DefenceR}
                } = AttrAcc,
            if
                ID =:= ?ATTR_RATE_ADD_HP ->
                    AttrAcc#actor_cal_attr{max_hp = {lib_tool:ceil(MaxHp * Val/?RATE_10000) + MaxHpAcc, MaxHpR}};
                ID =:= ?ATTR_RATE_ADD_ATTACK ->
                    AttrAcc#actor_cal_attr{attack = {lib_tool:ceil(Attack * Val/?RATE_10000) + AttackAcc, AttackR}};
                ID =:= ?ATTR_RATE_ADD_DEFENCE ->
                    AttrAcc#actor_cal_attr{defence = {lib_tool:ceil(Defence * Val/?RATE_10000) + DefenceAcc, DefenceR}};
                true ->
                    ?ERROR_MSG("steal prop unkonw ID:~w", [ID]),
                    AttrAcc
            end
        end, #actor_cal_attr{}, PropList);
get_steal_prop_attr(_PropList, FightAttr) ->
    ?ERROR_MSG("FightAttr batmatch :~w", [FightAttr]),
    #actor_cal_attr{}.

%% 获取上限属性
get_limit_prop(PropList, #actor_fight_attr{} = FightAttr) ->
    #actor_fight_attr{
        block_reduce = BlockReduce
    } = FightAttr,
    lists:foldl(
        fun(#p_kv{id = ID, val = LimitVal}, AttrAcc) ->
            #actor_cal_attr{
                block_reduce = BlockReduceAcc
            } = AttrAcc,
            if
                ID =:= ?ATTR_BLOCK_REDUCE ->
                    ?IF(BlockReduce >= LimitVal, AttrAcc, AttrAcc#actor_cal_attr{block_reduce = LimitVal - BlockReduce + BlockReduceAcc});
                true ->
                    ?ERROR_MSG("limit_prop unkonw ID:~w", [ID]),
                    AttrAcc
            end
        end, #actor_cal_attr{}, PropList).

sum_attr(FightAttr, BuffAttr) ->
    #actor_fight_attr{
        max_hp = Hp,
        attack = Att,
        defence = Def,
        arp = Arp,
        hit_rate = Hit,
        miss = Miss,
        double = Double,
        double_anti = DoubleA,
        hurt_rate = HurtRate,
        hurt_derate = HurtDerate,
        double_multi = DoubleM,
        double_rate = DoubleRate,
        double_anti_rate  = DoubleAntiR,
        miss_rate = MissRate,
        armor = Armor,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtA,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp,
        monster_exp_add = MonsterExpAdd,
        move_speed = MoveSpeed,
        role_hurt_add = RoleHurtAdd,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_add = BossHurtAdd,
        boss_hurt_reduce = BossHurtReduce,
        drain = Drain,
        rebound = Rebound,
        monster_hurt_add = MonsterHurtAdd,
        imprison_hurt_add = ImprisonHurtAdd,
        silent_hurt_add = SilentHurtAdd,
        poison_hurt_add = PoisonHurtAdd,
        burn_hurt_add = BurnHurtAdd,
        dizzy_hurt_add = DizzyHurtAdd,
        slow_hurt_add = SlowHurtAdd,
        poison_buff_add = PoisonBuffAdd,
        burn_buff_add = BurnBuffAdd,
        poison_hurt_reduce = PoisonHurtReduce,
        burn_hurt_reduce = BurnHurtReduce,
        slow_hurt_reduce = SlowHurtReduce,
        dizzy_rate = DizzyRate,
        min_reduce_rate = MinReduceRate,
        max_reduce_rate = MaxReduceRate,
        double_damage_rate = DoubleDamageRate,
        double_miss_rate = DoubleMissRate,
        metal = Metal,
        metal_anti = MetalA,
        wood = Wood,
        wood_anti = WoodA,
        water = Water,
        water_anti = WaterA,
        fire = Fire,
        fire_anti = FireA,
        earth = Earth,
        earth_anti = EarthA,
        block_rate = BlockRate,
        block_reduce = BlockReduce,
        block_defy = BlockDefy,
        block_pass = BlockPass,
        hp_heal_rate = HpHealRate
    } = FightAttr,
    #actor_cal_attr{
        move_speed = {AddMoveSpeed, AddMoveSpeedR},
        max_hp = {AddHp, AddHpR},
        attack = {AddAtt, AddAttR},
        defence = {AddDef, AddDefR},
        hit_rate = {AddHit, AddHitR},
        miss = {AddMiss, AddMissR},
        double = {AddDouble, AddDoubleR},
        double_anti = {AddDoubleA, AddDoubleAR},
        double_multi = {AddDoubleM, AddDoubleMR},
        hurt_rate = BuffHurtRate,
        hurt_derate = BuffHurtDerate,
        arp = {AddArp, AddArpR},
        monster_exp_add = {AddMonsterExp, AddMonsterExpR},
        double_rate = {AddDoubleRate, AddDoubleRateR},
        double_anti_rate  = {AddDoubleAntiR, AddDoubleAntiRR},
        miss_rate = {AddMissRate, AddMissRateR},
        armor = {AddArmor, AddArmorR},
        skill_hurt = {AddSkillHurt, AddSkillHurtR},
        skill_hurt_anti = {AddSkillHurtA, AddSkillHurtAR},
        skill_dps = {AddSkillDps, AddSkillDpsR},
        skill_ehp = {AddSkillEhp, AddSkillEhpR},
        role_hurt_add = RoleHurtAdd1,
        role_hurt_reduce = {AddRoleHurtReduce, AddRoleHurtReduceR},
        boss_hurt_add = {AddBossHurtAdd, AddBossHurtAddR},
        boss_hurt_reduce = {AddBossHurtReduce, AddBossHurtReduceR},
        drain = {AddDrain, AddDrainR},
        rebound = {AddRebound, AddReboundR},
        monster_hurt_add = {AddMonsterHurt, AddMonsterHurtR},
        imprison_hurt_add = {AddImprisonHurt, AddImprisonHurtR},
        silent_hurt_add = {AddSilentHurt, AddSilentHurtR},
        poison_hurt_add = {AddPoisonHurt, AddPoisonHurtR},
        burn_hurt_add = {AddBurnHurt, AddBurnHurtR},
        dizzy_hurt_add = DizzyHurtAdd1,
        slow_hurt_add = SlowHurtAdd1,
        poison_buff_add = PoisonBuffAdd1,
        burn_buff_add = BurnBuffAdd1,
        poison_hurt_reduce = PoisonHurtReduce1,
        burn_hurt_reduce = BurnHurtReduce1,
        slow_hurt_reduce = SlowHurtReduce1,
        dizzy_rate = {AddDizzyRate, AddDizzyRateR},
        min_reduce_rate = {AddMinReduceRate, AddMinReduceRateR},
        max_reduce_rate = {AddMaxReduceRate, AddMaxReduceRateR},
        double_damage_rate = {AddDoubleDamageRate, AddDoubleDamageRateR},
        double_miss_rate = {AddDoubleMissRate, AddDoubleMissRateR},
        metal = {AddMetal, AddMetalR},
        metal_anti = {AddMetalA, AddMetalAR},
        wood = {AddWood, AddWoodR},
        wood_anti = {AddWoodA, AddWoodAR},
        water = {AddWater, AddWaterR},
        water_anti = {AddWaterA, AddWaterAR},
        fire = {AddFire, AddFireR},
        fire_anti = {AddFireA, AddFireAR},
        earth = {AddEarth, AddEarthR},
        earth_anti = {AddEarthA, AddEarthAR},
        block_rate = AddBlockRate,
        block_reduce = AddBlockReduce,
        block_defy = AddBlockDefy,
        block_pass = AddBlockPass,
        hp_heal_rate = AddHpHealRate
    } = BuffAttr,
    #actor_fight_attr{
        move_speed = erlang:max(0, lib_tool:ceil(MoveSpeed * (?RATE_10000 + AddMoveSpeedR) / ?RATE_10000 + AddMoveSpeed)),
        max_hp = lib_tool:ceil(Hp * (?RATE_10000 + AddHpR) / ?RATE_10000 + AddHp),
        attack = lib_tool:ceil(Att * (?RATE_10000 + AddAttR) / ?RATE_10000 + AddAtt),
        defence = lib_tool:ceil(Def * (?RATE_10000 + AddDefR) / ?RATE_10000 + AddDef),
        arp = lib_tool:ceil(Arp * (?RATE_10000 + AddArpR) / ?RATE_10000 + AddArp),
        hit_rate = lib_tool:ceil(Hit * (?RATE_10000 + AddHitR) / ?RATE_10000 + AddHit),
        miss = lib_tool:ceil(Miss * (?RATE_10000 + AddMissR) / ?RATE_10000 + AddMiss),
        double = lib_tool:ceil(Double * (?RATE_10000 + AddDoubleR) / ?RATE_10000 + AddDouble),
        double_anti = lib_tool:ceil(DoubleA * (?RATE_10000 + AddDoubleAR) / ?RATE_10000 + AddDoubleA),
        double_multi = lib_tool:ceil(DoubleM * (?RATE_10000 + AddDoubleMR) / ?RATE_10000 + AddDoubleM),
        hurt_rate = lib_tool:ceil(BuffHurtRate + HurtRate),
        hurt_derate = lib_tool:ceil(BuffHurtDerate + HurtDerate),
        monster_exp_add = lib_tool:ceil(MonsterExpAdd * (?RATE_10000 + AddMonsterExpR) / ?RATE_10000 + AddMonsterExp),
        double_rate = lib_tool:ceil(DoubleRate * (?RATE_10000 + AddDoubleRate) / ?RATE_10000 + AddDoubleRateR),
        double_anti_rate  = lib_tool:ceil(DoubleAntiR * (?RATE_10000 + AddDoubleAntiR) / ?RATE_10000 + AddDoubleAntiRR),
        miss_rate = lib_tool:ceil(MissRate * (?RATE_10000 + AddMissRate) / ?RATE_10000 + AddMissRateR),
        armor = lib_tool:ceil(Armor * (?RATE_10000 + AddArmorR) / ?RATE_10000 + AddArmor),
        skill_hurt = lib_tool:ceil(SkillHurt * (?RATE_10000 + AddSkillHurtR) / ?RATE_10000 + AddSkillHurt),
        skill_hurt_anti = lib_tool:ceil(SkillHurtA * (?RATE_10000 + AddSkillHurtAR) / ?RATE_10000 + AddSkillHurtA),
        skill_dps = lib_tool:ceil(SkillDps * (?RATE_10000 + AddSkillDpsR) / ?RATE_10000 + AddSkillDps),
        skill_ehp = lib_tool:ceil(SkillEhp * (?RATE_10000 + AddSkillEhpR) / ?RATE_10000 + AddSkillEhp),
        role_hurt_add = lib_tool:ceil(RoleHurtAdd + RoleHurtAdd1),
        role_hurt_reduce = lib_tool:ceil(RoleHurtReduce * (?RATE_10000 + AddRoleHurtReduceR) / ?RATE_10000 + AddRoleHurtReduce),
        boss_hurt_add = lib_tool:ceil(BossHurtAdd * (?RATE_10000 + AddBossHurtAddR) / ?RATE_10000 + AddBossHurtAdd),
        boss_hurt_reduce = lib_tool:ceil(BossHurtReduce * (?RATE_10000 + AddBossHurtReduceR) / ?RATE_10000 + AddBossHurtReduce),
        drain = lib_tool:ceil(Drain * (?RATE_10000 + AddDrainR) / ?RATE_10000 + AddDrain),
        rebound = lib_tool:ceil(Rebound * (?RATE_10000 + AddReboundR) / ?RATE_10000 + AddRebound),
        monster_hurt_add = lib_tool:ceil(MonsterHurtAdd * (?RATE_10000 + AddMonsterHurtR) / ?RATE_10000 + AddMonsterHurt),
        imprison_hurt_add = lib_tool:ceil(ImprisonHurtAdd * (?RATE_10000 + AddImprisonHurtR) / ?RATE_10000 + AddImprisonHurt),
        silent_hurt_add = lib_tool:ceil(SilentHurtAdd * (?RATE_10000 + AddSilentHurtR) / ?RATE_10000 + AddSilentHurt),
        poison_hurt_add = lib_tool:ceil(PoisonHurtAdd * (?RATE_10000 + AddPoisonHurtR) / ?RATE_10000 + AddPoisonHurt),
        burn_hurt_add = lib_tool:ceil(BurnHurtAdd * (?RATE_10000 + AddBurnHurtR) / ?RATE_10000 + AddBurnHurt),
        dizzy_hurt_add = lib_tool:ceil(DizzyHurtAdd + DizzyHurtAdd1),
        slow_hurt_add = lib_tool:ceil(SlowHurtAdd + SlowHurtAdd1),
        poison_buff_add = lib_tool:ceil(PoisonBuffAdd + PoisonBuffAdd1),
        burn_buff_add = lib_tool:ceil(BurnBuffAdd + BurnBuffAdd1),
        poison_hurt_reduce = lib_tool:ceil(PoisonHurtReduce + PoisonHurtReduce1),
        burn_hurt_reduce = lib_tool:ceil(BurnHurtReduce + BurnHurtReduce1),
        slow_hurt_reduce = lib_tool:ceil(SlowHurtReduce + SlowHurtReduce1),
        dizzy_rate = lib_tool:ceil(DizzyRate * (?RATE_10000 + AddDizzyRateR) / ?RATE_10000 + AddDizzyRate),
        min_reduce_rate = lib_tool:ceil(MinReduceRate * (?RATE_10000 + AddMinReduceRateR) / ?RATE_10000 + AddMinReduceRate),
        max_reduce_rate = lib_tool:ceil(MaxReduceRate * (?RATE_10000 + AddMaxReduceRateR) / ?RATE_10000 + AddMaxReduceRate),
        double_damage_rate = lib_tool:ceil(DoubleDamageRate * (?RATE_10000 + AddDoubleDamageRateR) / ?RATE_10000 + AddDoubleDamageRate),
        double_miss_rate = lib_tool:ceil(DoubleMissRate * (?RATE_10000 + AddDoubleMissRateR) / ?RATE_10000 + AddDoubleMissRate),
        metal = lib_tool:ceil(Metal * (?RATE_10000 + AddMetalR) / ?RATE_10000 + AddMetal),
        metal_anti = lib_tool:ceil(MetalA * (?RATE_10000 + AddMetalAR) / ?RATE_10000 + AddMetalA),
        wood = lib_tool:ceil(Wood * (?RATE_10000 + AddWoodR) / ?RATE_10000 + AddWood),
        wood_anti = lib_tool:ceil(WoodA * (?RATE_10000 + AddWoodAR) / ?RATE_10000 + AddWoodA),
        water = lib_tool:ceil(Water * (?RATE_10000 + AddWaterR) / ?RATE_10000 + AddWater),
        water_anti = lib_tool:ceil(WaterA * (?RATE_10000 + AddWaterAR) / ?RATE_10000 + AddWaterA),
        fire = lib_tool:ceil(Fire * (?RATE_10000 + AddFireR) / ?RATE_10000 + AddFire),
        fire_anti = lib_tool:ceil(FireA * (?RATE_10000 + AddFireAR) / ?RATE_10000 + AddFireA),
        earth = lib_tool:ceil(Earth * (?RATE_10000 + AddEarthR) / ?RATE_10000 + AddEarth),
        earth_anti = lib_tool:ceil(EarthA * (?RATE_10000 + AddEarthAR) / ?RATE_10000 + AddEarthA),
        block_rate = lib_tool:ceil(BlockRate + AddBlockRate),
        block_reduce = lib_tool:ceil(BlockReduce + AddBlockReduce),
        block_defy = lib_tool:ceil(BlockDefy + AddBlockDefy),
        block_pass = lib_tool:ceil(BlockPass + AddBlockPass),
        hp_heal_rate = lib_tool:ceil(HpHealRate + AddHpHealRate)
    }.

get_immune_list([], Acc) ->
    Acc;
get_immune_list([Buff|R], Acc) ->
    #r_buff{buff_id = BuffID, buff_attr = BuffAttr} = Buff,
    case BuffAttr =:= ?BUFF_IMMUNE of
        true ->
            [#c_buff{immune_list = ImmuneList}] = lib_config:find(cfg_buff, BuffID),
            Acc2 = lib_tool:list_filter_repeat(ImmuneList ++ Acc),
            get_immune_list(R, Acc2);
        _ ->
            get_immune_list(R, Acc)
    end.

get_buffs_by_num(BuffList, MaxNum) ->
    lists:sublist(lists:keysort(#r_buff.bid_level, BuffList), MaxNum).

dispel_buffs(BuffCfg, Buffs) ->
    dispel_buffs2(BuffCfg, Buffs, [], false).

dispel_buffs2(_BuffCfg, [], BuffsAcc, IsChange) ->
    {BuffsAcc, IsChange};
dispel_buffs2(BuffCfg, [Buff|R], BuffsAcc, IsChange) ->
    #r_buff{buff_id = BuffID} = Buff,
    [#c_buff{dispel_level = DispelLevel}] = lib_config:find(cfg_buff, BuffID),
    #c_buff{dispel_level = CfgDispelLevel} = BuffCfg,
    case CfgDispelLevel >= DispelLevel of
        true ->
            dispel_buffs2(BuffCfg, R, BuffsAcc, true);
        _ ->
            dispel_buffs2(BuffCfg, R, [Buff|BuffsAcc], IsChange)
    end.

%% 有可能造成中毒、燃烧buff的话，要掉这个接口
get_add_buffs(BuffIDs, FromActorID, DestFightAttr) ->
    #actor_fight_attr{
        attack = Attack,
        poison_buff_add = PoisonBuffAdd,
        burn_buff_add = BurnBuffAdd
    } = DestFightAttr,
    lists:foldl(
        fun(BuffID, Acc) ->
            [#c_buff{buff_attr = BuffAttr}] = lib_config:find(cfg_buff, BuffID),
            BuffArgs =
                if
                    BuffAttr =:= ?BUFF_POISON -> %% 中毒根据攻击力扣血
                        #buff_args{buff_id = BuffID, from_actor_id = FromActorID, extra_value = lib_tool:ceil((1 + PoisonBuffAdd/?RATE_10000) * Attack)};
                    BuffAttr =:= ?BUFF_BURN -> %% 燃烧根据攻击力扣血
                        #buff_args{buff_id = BuffID, from_actor_id = FromActorID, extra_value = lib_tool:ceil((1 + BurnBuffAdd/?RATE_10000) * Attack)};
                    BuffAttr =:= ?BUFF_STEAL_PROP -> %% 根据对方属性加属性
                        #buff_args{buff_id = BuffID, from_actor_id = FromActorID, extra_value = DestFightAttr};
                    true ->
                        #buff_args{buff_id = BuffID, from_actor_id = FromActorID}
                end,
            [BuffArgs|Acc]
        end, [], BuffIDs).

