-module(common_misc).


-include("global.hrl").


%% 单播
-export([
    unicast/2,
    ensure_all_beam_loaded/0
]).

-export([
    role_name_check/1,
    word_check/1
]).

-export([
    is_active/1,
    get_item_reward/1,
    get_reward_p_goods/1,
    get_reward_p_goods/2,
    get_string_props/1,
    get_string_props/2,
    get_string_props1/1,
    get_string_props1/2,
    merge_props/1,
    get_global_int/1,
    get_global_list/1,
    get_global_string_list/1,
    get_attr_by_kv/1,
    get_attr_by_kv/2,
    get_fight_attr_by_kv/2,
    sum_attr/1,
    sum_calc_attr/1,
    sum_calc_attr2/2,
    get_calc_power/1,
    get_random_name/0
]).

-export([
    to_pet_attr/1,
    fight_attr_rate/2,
    pellet_attr/2,
    make_p_buff/1
]).

-export([
    get_log_string/1,
    to_goods_string/1,
    to_kv_string/1,
    get_bool_int/1,
    get_list_string/1
]).

-export([
    send_support_goods/2,
    is_rename_ban/1
]).

unicast(PID, DataRecord) when erlang:is_pid(PID) ->
    gateway_misc:send(PID, {message, DataRecord});
unicast(RoleID, DataRecord) ->
    case mod_role_dict:get_role_id() =:= RoleID of
        true ->
            case mod_role_dict:get_gateway_pid() of
                PID when erlang:is_pid(PID) ->
                    gateway_misc:send(PID, {message, DataRecord});
                _ ->
                    gateway_misc:send(RoleID, {message, DataRecord})
            end;
        _ ->
            case catch mod_map_ets:get_role_gpid(RoleID) of
                PID when erlang:is_pid(PID) ->
                    gateway_misc:send(PID, {message, DataRecord});
                _ ->
                    case common_config:is_cross_node() of
                        true -> %% 跨服进程单发消息时，转发
                            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, unicast, [RoleID, DataRecord]});
                        _ ->
                            gateway_misc:send(RoleID, {message, DataRecord})
                    end
            end
    end.

ensure_all_beam_loaded() ->
    RootDir = common_config:get_server_root(),
    EbinPath = RootDir ++ "ebin",
    filelib:fold_files(EbinPath, ".+\.beam$", true,
        fun(E, _Acc) ->
            code:ensure_loaded(list_to_atom(filename:basename(E, ".beam"))),
            ok
        end, ok).

role_name_check(RoleName) ->
    %% 通用敏感词检查
    word_check(RoleName),
    [?IF(string:str(RoleName, SpaceChar) > 0, ?THROW_ERR(?ERROR_COMMON_WORD_SPACE), ok)|| SpaceChar <- ?SPACE_CHAR_LIST].
%%    [?IF(string:str(RoleName, SpecialChar) > 0, ?THROW_ERR(?ERROR_COMMON_WORD_SPECIAL_CHAR), ok) || SpecialChar <- ?SEC_CHAR_LIST].

word_check(Msg) ->
    case lib_config:find(cfg_word_check, word_check) of
        [WordList] ->
            [ case catch re:run(Msg, String, [unicode]) of
                  {match, _} ->
                      ?THROW_ERR(?ERROR_COMMON_WORD_CHECK);
                  _ ->
                      ok
              end|| String <- WordList];
        _ ->
            ok
    end.

is_active(Rate) ->
    Rate >= lib_tool:random(?RATE_10000).

get_item_reward(String) ->
    [ begin
          case string:tokens(ItemString, ",") of
              [TypeID, Num] ->
                  {lib_tool:to_integer(TypeID), lib_tool:to_integer(Num)};
              [TypeID, Num, Bind] ->
                  {lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), lib_tool:to_integer(Bind)}
          end
      end || ItemString <- string:tokens(String, ";")].

get_reward_p_goods(List) ->
    get_reward_p_goods(List, 1).
get_reward_p_goods(List, Multi) ->
    get_reward_p_goods2(List, Multi, []).

get_reward_p_goods2([], _Multi, GoodsAcc) ->
    GoodsAcc;
get_reward_p_goods2([Item|R], Multi, GoodsAcc) ->
    Goods =
        case Item of
            {TypeID, Num} ->
                #p_goods{type_id = TypeID, num = Num * Multi};
            {TypeID, Num, BindInteger} ->
                #p_goods{type_id = TypeID, num = Num * Multi, bind = ?IS_BIND(BindInteger)}
        end,
    get_reward_p_goods2(R, Multi, [Goods|GoodsAcc]).

get_string_props(String) ->   %% 【通用接口函数】根据配置表中string类型得出一个list[#p_kv,......](配置表是“1,2|2,4”)
    get_string_props(String, 1).  %% 1 是个放大倍数（系数）

get_string_props("", _Multi) ->
    [];
get_string_props(String, Multi) ->
    lists:foldl(
        fun(KV, Acc) ->
            case string:tokens(KV, ",") of
                [Key, ValueString] -> [#p_kv{id = lib_tool:to_integer(Key), val = to_prop_value(ValueString) * Multi}|Acc];
                _ -> Acc
            end
        end, [], string:tokens(String, "|")).

get_string_props1(String) ->   %% 根据配置表中string类型得出一个list[#p_kv,......](配置表是“1:2|2:4”)
    get_string_props1(String, 1).  %% 1 是个放大倍数（系数）

get_string_props1("", _Multi) ->
    [];
get_string_props1(String, Multi) ->
    lists:foldl(
        fun(KV, Acc) ->
            case string:tokens(KV, ":") of
                [Key, ValueString] -> [#p_kv{id = lib_tool:to_integer(Key), val = to_prop_value(ValueString) * Multi}|Acc];
                _ -> Acc
            end
        end, [], string:tokens(String, "|")).

to_prop_value(String) ->
    case catch erlang:list_to_integer(String) of
        Int when erlang:is_integer(Int) ->
            Int;
        _ ->
            lib_tool:to_float(String)
    end.

merge_props(List) ->
    merge_props(List, []).

merge_props([], Acc) ->
    Acc;
merge_props([Prop|R], Acc) ->
    #p_kv{id = Key, val = Value} = Prop,
    case lists:keytake(Key, #p_kv.id, Acc) of
        {value, #p_kv{val = OldVal}, Acc2} ->
            Prop2 = Prop#p_kv{val = OldVal + Value},
            merge_props(R, [Prop2|Acc2]);
        _ ->
            merge_props(R, [Prop|Acc])
    end.


get_global_int(Key) ->
    [#c_global{int = Int}] = lib_config:find(cfg_global, Key),
    Int.

get_global_list(Key) ->
    [#c_global{list = List}] = lib_config:find(cfg_global, Key),
    List.

get_global_string_list(Key) when erlang:is_integer(Key) ->
    [#c_global{string = String}] = lib_config:find(cfg_global, Key),
    get_global_string_list(String);
get_global_string_list(String) ->
    lib_tool:string_to_intlist(String, ",", ":").


get_attr_by_kv(Key, Value) ->
    get_attr_by_kv([#p_kv{id = Key, val = Value}]).
get_attr_by_kv(List) ->   %% 根据List 里面的值(配的)得到新的（增量）#actor_cal_attr
    lists:foldl(
        fun(#p_kv{id = Key, val = Value}, Attr) ->
            #actor_cal_attr{
                max_hp = {Hp, HpR},
                attack = {Att, AttR},
                defence = {Def, DefR},
                arp = {Arp, ArpR},
                hit_rate = {Hit, HitR},
                miss = {Miss, MissR},
                double = {Double, DoubleR},
                double_anti = {DoubleA, DoubleAR},
                double_multi = {DoubleM, DoubleMR},
                hurt_rate = HurtRate,
                hurt_derate = HurtDeRate,
                double_rate = {DoubleRate, DoubleRateR},
                miss_rate = {MissRate, MissRateR},
                double_anti_rate = {DoubleAntiRate, DoubleAntiRateR},
                skill_hurt = {SkillHurt, SkillHurtR},
                skill_hurt_anti = {SkillHurtAnti, SkillHurtAntiR},
                monster_exp_add = {MonsterExp, MonsterExpR},
                move_speed = {MoveSpeed, MoveSpeedR},
                armor = {Armor, ArmorR},
                role_hurt_add = RoleHurtAdd,
                role_hurt_reduce = {RoleHurtReduce, RoleHurtReduceR},
                boss_hurt_add = {BossHurtAdd, BossHurtAddR},
                boss_hurt_reduce = {BossHurtReduce, BossHurtReduceR},
                drain = {Drain, DrainR},
                rebound = {Rebound, ReboundR},
                monster_hurt_add = {MonsterHurtAdd, MonsterHurtAddR},
                imprison_hurt_add = {ImprisonHurtAdd, ImprisonHurtAddR},
                silent_hurt_add = {SilentHurtAdd, SilentHurtAddR},
                poison_hurt_add = {PoisonHurtAdd, PoisonHurtAddR},
                burn_hurt_add = {BurnHurtAdd, BurnHurtAddR},
                dizzy_hurt_add = DizzyHurtAdd,
                slow_hurt_add = SlowHurtAdd,
                poison_buff_add = PoisonBuffAdd,
                burn_buff_add = BurnBuffAdd,
                poison_hurt_reduce = PoisonHurtReduce,
                burn_hurt_reduce = BurnHurtReduce,
                slow_hurt_reduce = SlowHurtReduce,
                dizzy_rate = {DizzyRate, DizzyRateR},
                double_damage_rate = {DoubleDamageRate, DoubleDamageRateR},
                double_miss_rate = {DoubleMissRate, DoubleMissRateR},
                metal = {Metal, MetalR},
                metal_anti = {MetalA, MetalAR},
                wood = {Wood, WoodR},
                wood_anti = {WoodA, WoodAR},
                water = {Water, WaterR},
                water_anti = {WaterA, WaterAR},
                fire = {Fire, FireR},
                fire_anti = {FireA, FireAR},
                earth = {Earth, EarthR},
                earth_anti = {EarthA, EarthAR},
                hp_recover = {HpRecover, HpRecoverRate},
                war_spirit_time = {WarSpiritTime, WarSpiritTimeR},
                block_rate = BlockRate,
                block_reduce = BlockReduce,
                block_defy = BlockDefy,
                block_pass = BlockPass,
                hp_heal_rate = HpHealRate
            } = Attr,
            if
                Key =:= ?ATTR_HP -> Attr#actor_cal_attr{max_hp = {Value + Hp, HpR}};
                Key =:= ?ATTR_ATTACK -> Attr#actor_cal_attr{attack = {Value + Att, AttR}};
                Key =:= ?ATTR_DEFENCE -> Attr#actor_cal_attr{defence = {Value + Def, DefR}};
                Key =:= ?ATTR_ARP -> Attr#actor_cal_attr{arp = {Value + Arp, ArpR}};
                Key =:= ?ATTR_HIT_RATE -> Attr#actor_cal_attr{hit_rate = {Value + Hit, HitR}};
                Key =:= ?ATTR_MISS -> Attr#actor_cal_attr{miss = {Value + Miss, MissR}};
                Key =:= ?ATTR_DOUBLE -> Attr#actor_cal_attr{double = {Value + Double, DoubleR}};
                Key =:= ?ATTR_DOUBLE_ANTI -> Attr#actor_cal_attr{double_anti = {Value + DoubleA, DoubleAR}};
                Key =:= ?ATTR_DOUBLE_MULTI -> Attr#actor_cal_attr{double_multi = {Value + DoubleM, DoubleMR}};
                Key =:= ?ATTR_HURT_RATE -> Attr#actor_cal_attr{hurt_rate = Value + HurtRate};
                Key =:= ?ATTR_HURT_DERATE -> Attr#actor_cal_attr{hurt_derate = Value + HurtDeRate};
                Key =:= ?ATTR_DOUBLE_RATE -> Attr#actor_cal_attr{double_rate  = {Value + DoubleRate, DoubleRateR}};
                Key =:= ?ATTR_MISS_RATE -> Attr#actor_cal_attr{miss_rate  = {Value + MissRate, MissRateR}};
                Key =:= ?ATTR_DOUBLE_ANTI_RATE -> Attr#actor_cal_attr{double_anti_rate = {Value + DoubleAntiRate, DoubleAntiRateR}};
                Key =:= ?ATTR_SKILL_HURT -> Attr#actor_cal_attr{skill_hurt = {Value + SkillHurt, SkillHurtR}};
                Key =:= ?ATTR_SKILL_HURT_ANTI -> Attr#actor_cal_attr{skill_hurt_anti = {Value + SkillHurtAnti, SkillHurtAntiR}};
                Key =:= ?ATTR_RATE_ADD_HP -> Attr#actor_cal_attr{max_hp = {Hp, Value + HpR}};
                Key =:= ?ATTR_RATE_ADD_ATTACK -> Attr#actor_cal_attr{attack = {Att, Value + AttR}};
                Key =:= ?ATTR_RATE_ADD_DEFENCE -> Attr#actor_cal_attr{defence = {Def, Value + DefR}};
                Key =:= ?ATTR_RATE_ADD_ARP -> Attr#actor_cal_attr{arp = {Arp, ArpR + Value}};
                Key =:= ?ATTR_RATE_ADD_HIT -> Attr#actor_cal_attr{hit_rate = {Hit, HitR + Value}};
                Key =:= ?ATTR_RATE_ADD_MISS -> Attr#actor_cal_attr{miss = {Miss, MissR + Value}};
                Key =:= ?ATTR_RATE_ADD_DOUBLE -> Attr#actor_cal_attr{double = {Double, DoubleR + Value}};
                Key =:= ?ATTR_RATE_ADD_DOUBLE_A -> Attr#actor_cal_attr{double_anti = {DoubleA, DoubleAR + Value}};
                Key =:= ?ATTR_MONSTER_EXP -> Attr#actor_cal_attr{monster_exp_add = {MonsterExp + Value, MonsterExpR}};
                Key =:= ?ATTR_MOVE_SPEED -> Attr#actor_cal_attr{move_speed = {MoveSpeed + Value, MoveSpeedR}};
                Key =:= ?ATTR_ARMOR -> Attr#actor_cal_attr{armor = {Armor + Value, ArmorR}};
                Key =:= ?ATTR_ROLE_HURT_REDUCE -> Attr#actor_cal_attr{role_hurt_reduce = {RoleHurtReduce + Value, RoleHurtReduceR}};
                Key =:= ?ATTR_BOSS_HURT_ADD -> Attr#actor_cal_attr{boss_hurt_add = {BossHurtAdd + Value, BossHurtAddR}};
                Key =:= ?ATTR_BOSS_HURT_REDUCE -> Attr#actor_cal_attr{boss_hurt_reduce = {BossHurtReduce + Value, BossHurtReduceR}};
                Key =:= ?ATTR_DRAIN -> Attr#actor_cal_attr{drain = {Drain + Value, DrainR}};
                Key =:= ?ATTR_REBOUND -> Attr#actor_cal_attr{rebound = {Rebound + Value, ReboundR}};
                Key =:= ?ATTR_MONSTER_HURT_ADD -> Attr#actor_cal_attr{monster_hurt_add = {MonsterHurtAdd + Value, MonsterHurtAddR}};
                Key =:= ?ATTR_MOVE_SPEED_RATE -> Attr#actor_cal_attr{move_speed = {MoveSpeed, MoveSpeedR + Value}};
                Key =:= ?ATTR_IMPRISON_HURT_ADD -> Attr#actor_cal_attr{imprison_hurt_add = {ImprisonHurtAdd + Value, ImprisonHurtAddR}};
                Key =:= ?ATTR_SILENT_HURT_ADD -> Attr#actor_cal_attr{silent_hurt_add = {SilentHurtAdd + Value, SilentHurtAddR}};
                Key =:= ?ATTR_DIZZY_RATE -> Attr#actor_cal_attr{dizzy_rate = {DizzyRate + Value, DizzyRateR}};
                Key =:= ?ATTR_LEVEL_RECOVER_HP -> Attr#actor_cal_attr{hp_recover = {HpRecover + Value, HpRecoverRate}};
                Key =:= ?ATTR_DOUBLE_DAMAGE_RATE -> Attr#actor_cal_attr{double_damage_rate = {DoubleDamageRate + Value, DoubleDamageRateR}};
                Key =:= ?ATTR_DOUBLE_MISS_RATE -> Attr#actor_cal_attr{double_miss_rate = {DoubleMissRate + Value, DoubleMissRateR}};
                Key =:= ?ATTR_POISON_HURT_ADD -> Attr#actor_cal_attr{poison_hurt_add = {PoisonHurtAdd + Value, PoisonHurtAddR}};
                Key =:= ?ATTR_BURN_HURT_ADD -> Attr#actor_cal_attr{burn_hurt_add = {BurnHurtAdd + Value, BurnHurtAddR}};
                Key =:= ?ATTR_WAR_SPIRIT_TIME -> Attr#actor_cal_attr{war_spirit_time = {WarSpiritTime + Value, WarSpiritTimeR}};
                Key =:= ?ATTR_METAL -> Attr#actor_cal_attr{metal = {Value + Metal, MetalR}};
                Key =:= ?ATTR_METAL_ANTI -> Attr#actor_cal_attr{metal_anti = {Value + MetalA, MetalAR}};
                Key =:= ?ATTR_WOOD -> Attr#actor_cal_attr{wood = {Value + Wood, WoodR}};
                Key =:= ?ATTR_WOOD_ANTI -> Attr#actor_cal_attr{wood_anti = {Value + WoodA, WoodAR}};
                Key =:= ?ATTR_WATER -> Attr#actor_cal_attr{water = {Value + Water, WaterR}};
                Key =:= ?ATTR_WATER_ANTI -> Attr#actor_cal_attr{water_anti = {Value + WaterA, WaterAR}};
                Key =:= ?ATTR_FIRE -> Attr#actor_cal_attr{fire = {Value + Fire, FireR}};
                Key =:= ?ATTR_FIRE_ANTI -> Attr#actor_cal_attr{fire_anti = {Value + FireA, FireAR}};
                Key =:= ?ATTR_EARTH -> Attr#actor_cal_attr{earth = {Value + Earth, EarthR}};
                Key =:= ?ATTR_EARTH_ANTI -> Attr#actor_cal_attr{earth_anti = {Value + EarthA, EarthAR}};
                Key =:= ?ATTR_BLOCK_RATE -> Attr#actor_cal_attr{block_rate = Value + BlockRate};
                Key =:= ?ATTR_BLOCK_REDUCE -> Attr#actor_cal_attr{block_reduce = Value + BlockReduce};
                Key =:= ?ATTR_BLOCK_DEFY -> Attr#actor_cal_attr{block_defy = Value + BlockDefy};
                Key =:= ?ATTR_BLOCK_PASS -> Attr#actor_cal_attr{block_pass = Value + BlockPass};
                Key =:= ?ATTR_HP_HEAL_RATE -> Attr#actor_cal_attr{hp_heal_rate = Value + HpHealRate};
                Key =:= ?ATTR_DIZZY_HURT_ADD -> Attr#actor_cal_attr{dizzy_hurt_add = Value + DizzyHurtAdd};
                Key =:= ?ATTR_SLOW_HURT_ADD -> Attr#actor_cal_attr{slow_hurt_add = Value + SlowHurtAdd};
                Key =:= ?ATTR_POISON_BUFF_ADD -> Attr#actor_cal_attr{poison_buff_add = Value + PoisonBuffAdd};
                Key =:= ?ATTR_BURN_BUFF_ADD -> Attr#actor_cal_attr{burn_buff_add = Value + BurnBuffAdd};
                Key =:= ?ATTR_POISON_HURT_REDUCE -> Attr#actor_cal_attr{poison_hurt_reduce = Value + PoisonHurtReduce};
                Key =:= ?ATTR_BURN_HURT_REDUCE -> Attr#actor_cal_attr{burn_hurt_reduce = Value + BurnHurtReduce};
                Key =:= ?ATTR_SLOW_HURT_REDUCE -> Attr#actor_cal_attr{slow_hurt_reduce = Value + SlowHurtReduce};
                Key =:= ?ATTR_ROLE_HURT_ADD -> Attr#actor_cal_attr{role_hurt_add = Value + RoleHurtAdd};
                true -> Attr
            end
        end, #actor_cal_attr{}, List).

get_fight_attr_by_kv(FightAttr, Props) ->
    lists:foldl(
        fun(#p_kv{id = Key, val = Value}, Attr) ->
            #actor_fight_attr{
                max_hp = Hp,
                attack = Attack,
                defence = Defence,
                arp = Arp,
                hit_rate = HitRate,
                miss = Miss,
                double = Double,
                double_anti = DoubleA,
                double_multi = DoubleM,
                hurt_rate = HurtR,
                hurt_derate = HurtD,
                double_rate = DoubleRate,
                miss_rate = MissRate,
                double_anti_rate = DoubleAntiRate,
                skill_hurt = SkillHurt,
                skill_hurt_anti = SkillHurtAnti,
                armor = Armor,
                role_hurt_add = RoleHurtAdd,
                role_hurt_reduce = RoleHurtReduce,
                boss_hurt_add = BossHurtAdd,
                boss_hurt_reduce = BossHurtReduce,
                drain = Drain,
                rebound = Rebound,
                monster_hurt_add = MonsterHurtAdd,
                move_speed = MoveSpeed,
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
                double_miss_rate = DoubleMissRate,
                double_damage_rate = DoubleDamageRate,
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
                block_pass = BlockPass
            } = Attr,
            if
                Key =:= ?ATTR_HP -> Attr#actor_fight_attr{max_hp = Value + Hp};
                Key =:= ?ATTR_ATTACK -> Attr#actor_fight_attr{attack = Value + Attack};
                Key =:= ?ATTR_DEFENCE -> Attr#actor_fight_attr{defence = Value + Defence};
                Key =:= ?ATTR_ARP -> Attr#actor_fight_attr{arp = Value + Arp};
                Key =:= ?ATTR_HIT_RATE -> Attr#actor_fight_attr{hit_rate = Value + HitRate};
                Key =:= ?ATTR_MISS -> Attr#actor_fight_attr{miss = Value + Miss};
                Key =:= ?ATTR_DOUBLE -> Attr#actor_fight_attr{double = Value + Double};
                Key =:= ?ATTR_DOUBLE_ANTI -> Attr#actor_fight_attr{double_anti = Value + DoubleA};
                Key =:= ?ATTR_DOUBLE_MULTI -> Attr#actor_fight_attr{double_multi = Value + DoubleM};
                Key =:= ?ATTR_HURT_RATE -> Attr#actor_fight_attr{hurt_rate = Value + HurtR};
                Key =:= ?ATTR_HURT_DERATE -> Attr#actor_fight_attr{hurt_derate = Value + HurtD};
                Key =:= ?ATTR_DOUBLE_RATE -> Attr#actor_fight_attr{double_rate  = Value + DoubleRate};
                Key =:= ?ATTR_MISS_RATE -> Attr#actor_fight_attr{miss_rate  = Value + MissRate};
                Key =:= ?ATTR_DOUBLE_ANTI_RATE -> Attr#actor_fight_attr{double_anti_rate = Value + DoubleAntiRate};
                Key =:= ?ATTR_SKILL_HURT -> Attr#actor_fight_attr{skill_hurt = Value + SkillHurt};
                Key =:= ?ATTR_SKILL_HURT_ANTI -> Attr#actor_fight_attr{skill_hurt_anti = Value + SkillHurtAnti};
                Key =:= ?ATTR_RATE_ADD_HP -> Attr#actor_fight_attr{max_hp = lib_tool:ceil(Hp * (Value + ?RATE_10000)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_ATTACK -> Attr#actor_fight_attr{attack = lib_tool:ceil(Attack * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_DEFENCE -> Attr#actor_fight_attr{defence = lib_tool:ceil(Defence * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_ARP -> Attr#actor_fight_attr{arp = lib_tool:ceil(Arp * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_HIT -> Attr#actor_fight_attr{hit_rate = lib_tool:ceil(HitRate * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_MISS -> Attr#actor_fight_attr{miss = lib_tool:ceil(Miss * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_DOUBLE -> Attr#actor_fight_attr{double = lib_tool:ceil(Double * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_RATE_ADD_DOUBLE_A -> Attr#actor_fight_attr{double_anti = lib_tool:ceil(DoubleA * (?RATE_10000 + Value)/?RATE_10000)};
                Key =:= ?ATTR_ARMOR -> Attr#actor_fight_attr{armor = Value + Armor};
                Key =:= ?ATTR_ROLE_HURT_REDUCE -> Attr#actor_fight_attr{role_hurt_reduce = RoleHurtReduce + Value};
                Key =:= ?ATTR_BOSS_HURT_ADD -> Attr#actor_fight_attr{boss_hurt_add = BossHurtAdd + Value};
                Key =:= ?ATTR_BOSS_HURT_REDUCE -> Attr#actor_fight_attr{boss_hurt_reduce = BossHurtReduce + Value};
                Key =:= ?ATTR_DRAIN -> Attr#actor_fight_attr{drain = Drain + Value};
                Key =:= ?ATTR_REBOUND -> Attr#actor_fight_attr{rebound = Rebound + Value};
                Key =:= ?ATTR_MONSTER_HURT_ADD -> Attr#actor_fight_attr{monster_hurt_add = MonsterHurtAdd + Value};
                Key =:= ?ATTR_MOVE_SPEED_RATE -> Attr#actor_fight_attr{move_speed = lib_tool:ceil(MoveSpeed * (Value + ?RATE_10000)/?RATE_10000)};
                Key =:= ?ATTR_IMPRISON_HURT_ADD -> Attr#actor_fight_attr{imprison_hurt_add = ImprisonHurtAdd + Value};
                Key =:= ?ATTR_SILENT_HURT_ADD -> Attr#actor_fight_attr{silent_hurt_add = SilentHurtAdd + Value};
                Key =:= ?ATTR_POISON_HURT_ADD -> Attr#actor_fight_attr{poison_hurt_add = PoisonHurtAdd + Value};
                Key =:= ?ATTR_BURN_HURT_ADD -> Attr#actor_fight_attr{poison_hurt_add = BurnHurtAdd + Value};
                Key =:= ?ATTR_DIZZY_RATE -> Attr#actor_fight_attr{dizzy_rate = DizzyRate + Value};
                Key =:= ?ATTR_DOUBLE_MISS_RATE -> Attr#actor_fight_attr{double_miss_rate = DoubleMissRate + Value};
                Key =:= ?ATTR_DOUBLE_DAMAGE_RATE -> Attr#actor_fight_attr{double_damage_rate = DoubleDamageRate + Value};
                Key =:= ?ATTR_METAL -> Attr#actor_fight_attr{metal = Value + Metal};
                Key =:= ?ATTR_METAL_ANTI -> Attr#actor_fight_attr{metal_anti = Value + MetalA};
                Key =:= ?ATTR_WOOD -> Attr#actor_fight_attr{wood = Value + Wood};
                Key =:= ?ATTR_WOOD_ANTI -> Attr#actor_fight_attr{wood_anti = Value + WoodA};
                Key =:= ?ATTR_WATER -> Attr#actor_fight_attr{water = Value + Water};
                Key =:= ?ATTR_WATER_ANTI -> Attr#actor_fight_attr{water_anti = Value + WaterA};
                Key =:= ?ATTR_FIRE -> Attr#actor_fight_attr{fire = Value + Fire};
                Key =:= ?ATTR_FIRE_ANTI -> Attr#actor_fight_attr{fire_anti = Value + FireA};
                Key =:= ?ATTR_EARTH -> Attr#actor_fight_attr{earth = Value + Earth};
                Key =:= ?ATTR_EARTH_ANTI -> Attr#actor_fight_attr{earth_anti = Value + EarthA};
                Key =:= ?ATTR_BLOCK_RATE -> Attr#actor_fight_attr{block_rate = Value + BlockRate};
                Key =:= ?ATTR_BLOCK_REDUCE -> Attr#actor_fight_attr{block_reduce = Value + BlockReduce};
                Key =:= ?ATTR_BLOCK_DEFY -> Attr#actor_fight_attr{block_defy = Value + BlockDefy};
                Key =:= ?ATTR_BLOCK_PASS -> Attr#actor_fight_attr{block_pass = Value + BlockPass};
                Key =:= ?ATTR_DIZZY_HURT_ADD -> Attr#actor_fight_attr{dizzy_hurt_add = Value + DizzyHurtAdd};
                Key =:= ?ATTR_SLOW_HURT_ADD -> Attr#actor_fight_attr{slow_hurt_add = Value + SlowHurtAdd};
                Key =:= ?ATTR_POISON_BUFF_ADD -> Attr#actor_fight_attr{poison_buff_add = Value + PoisonBuffAdd};
                Key =:= ?ATTR_BURN_BUFF_ADD -> Attr#actor_fight_attr{burn_buff_add = Value + BurnBuffAdd};
                Key =:= ?ATTR_POISON_HURT_REDUCE -> Attr#actor_fight_attr{poison_hurt_reduce = Value + PoisonHurtReduce};
                Key =:= ?ATTR_BURN_HURT_REDUCE -> Attr#actor_fight_attr{burn_hurt_reduce = Value + BurnHurtReduce};
                Key =:= ?ATTR_SLOW_HURT_REDUCE -> Attr#actor_fight_attr{slow_hurt_reduce = Value + SlowHurtReduce};
                Key =:= ?ATTR_ROLE_HURT_ADD -> Attr#actor_fight_attr{role_hurt_add = Value + RoleHurtAdd};
                true -> Attr
            end
        end, FightAttr, Props).

sum_attr(#actor_cal_attr{} = CalcAttr) ->
    scale_attr(CalcAttr);
sum_attr([]) ->
    {#actor_fight_attr{}, #actor_extra_attr{}};
sum_attr(List) ->
    scale_attr(sum_calc_attr(List)).

sum_calc_attr([]) ->
    #actor_cal_attr{};
sum_calc_attr([Attr1]) ->
    Attr1;
sum_calc_attr([Attr1, Attr2|R]) ->
    sum_calc_attr([sum_calc_attr2(Attr1, Attr2)|R]).

scale_attr(Attr) ->
    #actor_cal_attr{
        move_speed = {MoveSpeed, MoveSpeedR},
        max_hp = {Hp, HpR},
        attack = {Att, AttR},
        defence = {Def, DefR},
        arp = {Arp, ArpR},
        hit_rate = {Hit, HitR},
        miss = {Miss, MissR},
        double = {Double, DoubleR},
        double_anti = {DoubleA, DoubleAR},
        double_multi = {DoubleM, DoubleMR},
        hurt_rate = HurtRate,
        hurt_derate = HurtDeRate,
        monster_exp_add = {MonsterExpAdd, MonsterExpAddR},
        double_rate = {DoubleRate, DoubleRateR},
        double_anti_rate  = {DoubleAntiR, DoubleAntiRR},
        miss_rate = {MissRate, MissRateR},
        armor = {Armor, ArmorR},
        skill_hurt = {SkillHurt, SkillHurtR},
        skill_hurt_anti = {SkillHurtA, SkillHurtAR},
        skill_dps = {SkillDps, SkillDpsR},
        skill_ehp = {SkillEhp, SkillEhpR},
        role_hurt_add = RoleHurtAdd,
        role_hurt_reduce = {RoleHurtReduce, RoleHurtReduceR},
        boss_hurt_add = {BossHurtAdd, BossHurtAddR},
        boss_hurt_reduce = {BossHurtReduce, BossHurtReduceR},
        drain = {Drain, DrainR},
        rebound = {Rebound, ReboundR},
        monster_hurt_add = {MonsterHurtAdd, MonsterHurtAddR},
        imprison_hurt_add = {ImprisonHurtAdd, ImprisonHurtAddR},
        silent_hurt_add = {SilentHurtAdd, SilentHurtAddR},
        poison_hurt_add = {PoisonHurtAdd, PoisonHurtAddR},
        burn_hurt_add = {BurnHurtAdd, BurnHurtAddR},
        dizzy_hurt_add = DizzyHurtAdd,
        slow_hurt_add = SlowHurtAdd,
        poison_buff_add = PoisonBuffAdd,
        burn_buff_add = BurnBuffAdd,
        poison_hurt_reduce = PoisonHurtReduce,
        burn_hurt_reduce = BurnHurtReduce,
        slow_hurt_reduce = SlowHurtReduce,
        dizzy_rate = {DizzyRate, DizzyRateR},
        hp_recover = {HpRecover, HpRecoverRate},
        war_spirit_time = {WarSpiritTime, WarSpiritTimeR},
        min_reduce_rate = {MinReduceRate, MinReduceRateR},
        max_reduce_rate = {MaxReduceRate, MaxReduceRateR},
        double_damage_rate = {DoubleDamageRate, DoubleDamageRateR},
        double_miss_rate = {DoubleMissRate, DoubleMissRateR},
        metal = {Metal, MetalR},
        metal_anti = {MetalA, MetalAR},
        wood = {Wood, WoodR},
        wood_anti = {WoodA, WoodAR},
        water = {Water, WaterR},
        water_anti = {WaterA, WaterAR},
        fire = {Fire, FireR},
        fire_anti = {FireA, FireAR},
        earth = {Earth, EarthR},
        earth_anti = {EarthA, EarthAR},
        block_rate = BlockRate,
        block_reduce = BlockReduce,
        block_defy = BlockDefy,
        block_pass = BlockPass,
        hp_heal_rate = HpHealRate
    } = Attr,
    FightAttr =
        #actor_fight_attr{
            move_speed = lib_tool:ceil(MoveSpeed * (?RATE_10000 + MoveSpeedR) / ?RATE_10000),
            max_hp = lib_tool:ceil(Hp * (?RATE_10000 + HpR) / ?RATE_10000),
            attack = lib_tool:ceil(Att * (?RATE_10000 + AttR) / ?RATE_10000),
            defence = lib_tool:ceil(Def * (?RATE_10000 + DefR) / ?RATE_10000),
            arp = lib_tool:ceil(Arp * (?RATE_10000 + ArpR) / ?RATE_10000),
            hit_rate = lib_tool:ceil(Hit * (?RATE_10000 + HitR) / ?RATE_10000),
            miss = lib_tool:ceil(Miss * (?RATE_10000 + MissR) / ?RATE_10000),
            double = lib_tool:ceil(Double * (?RATE_10000 + DoubleR) / ?RATE_10000),
            double_anti = lib_tool:ceil(DoubleA * (?RATE_10000 + DoubleAR) / ?RATE_10000),
            double_multi = lib_tool:ceil(DoubleM * (?RATE_10000 + DoubleMR) / ?RATE_10000),
            hurt_rate = lib_tool:ceil(HurtRate),
            hurt_derate = lib_tool:ceil(HurtDeRate),
            monster_exp_add = lib_tool:ceil(MonsterExpAdd * (?RATE_10000 + MonsterExpAddR) / ?RATE_10000),
            double_rate = lib_tool:ceil(DoubleRate * (?RATE_10000 + DoubleRateR) / ?RATE_10000),
            double_anti_rate  = lib_tool:ceil(DoubleAntiR * (?RATE_10000 + DoubleAntiRR) / ?RATE_10000),
            miss_rate = lib_tool:ceil(MissRate * (?RATE_10000 + MissRateR) / ?RATE_10000),
            armor = lib_tool:ceil(Armor * (?RATE_10000 + ArmorR) / ?RATE_10000),
            skill_hurt = lib_tool:ceil(SkillHurt * (?RATE_10000 + SkillHurtR) / ?RATE_10000),
            skill_hurt_anti = lib_tool:ceil(SkillHurtA * (?RATE_10000 + SkillHurtAR) / ?RATE_10000),
            skill_dps = lib_tool:ceil(SkillDps * (?RATE_10000 + SkillDpsR) / ?RATE_10000),
            skill_ehp = lib_tool:ceil(SkillEhp * (?RATE_10000 + SkillEhpR) / ?RATE_10000),
            role_hurt_add = lib_tool:ceil(RoleHurtAdd),
            role_hurt_reduce = lib_tool:ceil(RoleHurtReduce * (?RATE_10000 + RoleHurtReduceR) / ?RATE_10000),
            boss_hurt_add = lib_tool:ceil(BossHurtAdd * (?RATE_10000 + BossHurtAddR) / ?RATE_10000),
            dizzy_hurt_add = lib_tool:ceil(DizzyHurtAdd),
            slow_hurt_add = lib_tool:ceil(SlowHurtAdd),
            poison_buff_add = lib_tool:ceil(PoisonBuffAdd),
            burn_buff_add = lib_tool:ceil(BurnBuffAdd),
            poison_hurt_reduce = lib_tool:ceil(PoisonHurtReduce),
            burn_hurt_reduce = lib_tool:ceil(BurnHurtReduce),
            slow_hurt_reduce = lib_tool:ceil(SlowHurtReduce),
            boss_hurt_reduce = lib_tool:ceil(BossHurtReduce * (?RATE_10000 + BossHurtReduceR) / ?RATE_10000),
            drain = lib_tool:ceil(Drain * (?RATE_10000 + DrainR) / ?RATE_10000),
            rebound = lib_tool:ceil(Rebound * (?RATE_10000 + ReboundR) / ?RATE_10000),
            monster_hurt_add = lib_tool:ceil(MonsterHurtAdd * (?RATE_10000 + MonsterHurtAddR) / ?RATE_10000),
            imprison_hurt_add = lib_tool:ceil(ImprisonHurtAdd * (?RATE_10000 + ImprisonHurtAddR) / ?RATE_10000),
            silent_hurt_add = lib_tool:ceil(SilentHurtAdd * (?RATE_10000 + SilentHurtAddR) / ?RATE_10000),
            poison_hurt_add = lib_tool:ceil(PoisonHurtAdd * (?RATE_10000 + PoisonHurtAddR) / ?RATE_10000),
            burn_hurt_add = lib_tool:ceil(BurnHurtAdd * (?RATE_10000 + BurnHurtAddR) / ?RATE_10000),
            dizzy_rate = lib_tool:ceil(DizzyRate * (?RATE_10000 + DizzyRateR) / ?RATE_10000),
            min_reduce_rate = lib_tool:ceil(MinReduceRate * (?RATE_10000 + MinReduceRateR) / ?RATE_10000),
            max_reduce_rate = lib_tool:ceil(MaxReduceRate * (?RATE_10000 + MaxReduceRateR) / ?RATE_10000),
            double_damage_rate = lib_tool:ceil(DoubleDamageRate * (?RATE_10000 + DoubleDamageRateR) / ?RATE_10000),
            double_miss_rate = lib_tool:ceil(DoubleMissRate * (?RATE_10000 + DoubleMissRateR) / ?RATE_10000),
            metal = lib_tool:ceil(Metal * (?RATE_10000 + MetalR) / ?RATE_10000),
            metal_anti = lib_tool:ceil(MetalA * (?RATE_10000 + MetalAR) / ?RATE_10000),
            wood = lib_tool:ceil(Wood * (?RATE_10000 + WoodR) / ?RATE_10000),
            wood_anti = lib_tool:ceil(WoodA * (?RATE_10000 + WoodAR) / ?RATE_10000),
            water = lib_tool:ceil(Water * (?RATE_10000 + WaterR) / ?RATE_10000),
            water_anti = lib_tool:ceil(WaterA * (?RATE_10000 + WaterAR) / ?RATE_10000),
            fire = lib_tool:ceil(Fire * (?RATE_10000 + FireR) / ?RATE_10000),
            fire_anti = lib_tool:ceil(FireA * (?RATE_10000 + FireAR) / ?RATE_10000),
            earth = lib_tool:ceil(Earth * (?RATE_10000 + EarthR) / ?RATE_10000),
            earth_anti = lib_tool:ceil(EarthA * (?RATE_10000 + EarthAR) / ?RATE_10000),
            block_rate = lib_tool:ceil(BlockRate),
            block_reduce = lib_tool:ceil(BlockReduce),
            block_defy = lib_tool:ceil(BlockDefy),
            block_pass = lib_tool:ceil(BlockPass),
            hp_heal_rate = lib_tool:ceil(HpHealRate)
        },
    ExtraAttr = #actor_extra_attr{
        hp_recover = {lib_tool:ceil(HpRecover), lib_tool:ceil(HpRecoverRate)},
        war_spirit_time = {lib_tool:ceil(WarSpiritTime), lib_tool:ceil(WarSpiritTimeR)}
    },
    {FightAttr, ExtraAttr}.


sum_calc_attr2(Attr1, Attr2) ->  % T 两种属性相加
    #actor_cal_attr{
        move_speed = {MoveSpeed1, MoveSpeedR1},
        max_hp = {Hp1, HpR1},
        attack = {Att1, AttR1},
        defence = {Def1, DefR1},
        arp = {Arp1, ArpR1},
        hit_rate = {Hit1, HitR1},
        miss = {Miss1, MissR1},
        double = {Double1, DoubleR1},
        double_anti = {DoubleA1, DoubleAR1},
        double_multi = {DoubleM1, DoubleMR1},
        hurt_rate = HurtRateList,
        hurt_derate = HurtDerateList,
        monster_exp_add = {MonsterExpAdd1, MonsterExpAddR1},
        double_rate = {DoubleRate1, DoubleRateR1},
        double_anti_rate  = {DoubleAntiR1, DoubleAntiRR1},
        miss_rate = {MissRate1, MissRateR1},
        armor = {Armor1, ArmorR1},
        skill_hurt = {SkillHurt1, SkillHurtR1},
        skill_hurt_anti = {SkillHurtA1, SkillHurtAR1},
        skill_dps = {SkillDps1, SkillDpsR1},
        skill_ehp = {SkillEhp1, SkillEhpR1},
        role_hurt_add = RoleHurtAdd1,
        role_hurt_reduce = {RoleHurtReduce1, RoleHurtReduceR1},
        boss_hurt_add = {BossHurtAdd1, BossHurtAddR1},
        boss_hurt_reduce = {BossHurtReduce1, BossHurtReduceR1},
        drain = {Drain1, DrainR1},
        rebound = {Rebound1, ReboundR1},
        monster_hurt_add = {MonsterHurtAdd1, MonsterHurtAddR1},
        imprison_hurt_add = {ImprisonHurtAdd1, ImprisonHurtAddR1},
        silent_hurt_add = {SilentHurtAdd1, SilentHurtAddR1},
        poison_hurt_add = {PoisonHurtAdd1, PoisonHurtAddR1},
        burn_hurt_add = {BurnHurtAdd1, BurnHurtAddR1},
        dizzy_hurt_add = DizzyHurtAdd1,
        slow_hurt_add = SlowHurtAdd1,
        poison_buff_add = PoisonBuffAdd1,
        burn_buff_add = BurnBuffAdd1,
        poison_hurt_reduce = PoisonHurtReduce1,
        burn_hurt_reduce = BurnHurtReduce1,
        slow_hurt_reduce = SlowHurtReduce1,
        dizzy_rate = {DizzyRate1, DizzyRateR1},
        hp_recover = {HpRecover1, HpRecoverR1},
        war_spirit_time = {WarSpiritTime1, WarSpiritTimeR1},
        min_reduce_rate = {MinReduceRate1, MinReduceRateR1},
        max_reduce_rate = {MaxReduceRate1, MaxReduceRateR1},
        double_damage_rate = {DoubleDamageRate1, DoubleDamageRateR1},
        double_miss_rate = {DoubleMissRate1, DoubleMissRateR1},
        metal = {Metal1, MetalR1},
        metal_anti = {MetalA1, MetalAR1},
        wood = {Wood1, WoodR1},
        wood_anti = {WoodA1, WoodAR1},
        water = {Water1, WaterR1},
        water_anti = {WaterA1, WaterAR1},
        fire = {Fire1, FireR1},
        fire_anti = {FireA1, FireAR1},
        earth = {Earth1, EarthR1},
        earth_anti = {EarthA1, EarthAR1},
        block_rate = BlockRate1,
        block_reduce = BlockReduce1,
        block_defy = BlockDefy1,
        block_pass = BlockPass1,
        hp_heal_rate = HpHealRate1
    } = Attr1,
    #actor_cal_attr{
        move_speed = {MoveSpeed2, MoveSpeedR2},
        max_hp = {Hp2, HpR2},
        attack = {Att2, AttR2},
        defence = {Def2, DefR2},
        arp = {Arp2, ArpR2},
        hit_rate = {Hit2, HitR2},
        miss = {Miss2, MissR2},
        double = {Double2, DoubleR2},
        double_anti = {DoubleA2, DoubleAR2},
        double_multi = {DoubleM2, DoubleMR2},
        hurt_rate = HurtRateList2,
        hurt_derate = HurtDerateList2,
        monster_exp_add = {MonsterExpAdd2, MonsterExpAddR2},
        double_rate = {DoubleRate2, DoubleRateR2},
        double_anti_rate  = {DoubleAntiR2, DoubleAntiRR2},
        miss_rate = {MissRate2, MissRateR2},
        armor = {Armor2, ArmorR2},
        skill_hurt = {SkillHurt2, SkillHurtR2},
        skill_hurt_anti = {SkillHurtA2, SkillHurtAR2},
        skill_dps = {SkillDps2, SkillDpsR2},
        skill_ehp = {SkillEhp2, SkillEhpR2},
        role_hurt_add = RoleHurtAdd2,
        role_hurt_reduce = {RoleHurtReduce2, RoleHurtReduceR2},
        boss_hurt_add = {BossHurtAdd2, BossHurtAddR2},
        boss_hurt_reduce = {BossHurtReduce2, BossHurtReduceR2},
        drain = {Drain2, DrainR2},
        rebound = {Rebound2, ReboundR2},
        monster_hurt_add = {MonsterHurtAdd2, MonsterHurtAddR2},
        imprison_hurt_add = {ImprisonHurtAdd2, ImprisonHurtAddR2},
        silent_hurt_add = {SilentHurtAdd2, SilentHurtAddR2},
        poison_hurt_add = {PoisonHurtAdd2, PoisonHurtAddR2},
        burn_hurt_add = {BurnHurtAdd2, BurnHurtAddR2},
        dizzy_hurt_add = DizzyHurtAdd2,
        slow_hurt_add = SlowHurtAdd2,
        poison_buff_add = PoisonBuffAdd2,
        burn_buff_add = BurnBuffAdd2,
        poison_hurt_reduce = PoisonHurtReduce2,
        burn_hurt_reduce = BurnHurtReduce2,
        slow_hurt_reduce = SlowHurtReduce2,
        dizzy_rate = {DizzyRate2, DizzyRateR2},
        hp_recover = {HpRecover2, HpRecoverR2},
        war_spirit_time = {WarSpiritTime2, WarSpiritTimeR2},
        min_reduce_rate = {MinReduceRate2, MinReduceRateR2},
        max_reduce_rate = {MaxReduceRate2, MaxReduceRateR2},
        double_damage_rate = {DoubleDamageRate2, DoubleDamageRateR2},
        double_miss_rate = {DoubleMissRate2, DoubleMissRateR2},
        metal = {Metal2, MetalR2},
        metal_anti = {MetalA2, MetalAR2},
        wood = {Wood2, WoodR2},
        wood_anti = {WoodA2, WoodAR2},
        water = {Water2, WaterR2},
        water_anti = {WaterA2, WaterAR2},
        fire = {Fire2, FireR2},
        fire_anti = {FireA2, FireAR2},
        earth = {Earth2, EarthR2},
        earth_anti = {EarthA2, EarthAR2},
        block_rate = BlockRate2,
        block_reduce = BlockReduce2,
        block_defy = BlockDefy2,
        block_pass = BlockPass2,
        hp_heal_rate = HpHealRate2
    } = Attr2,
    #actor_cal_attr{
        move_speed = {MoveSpeed1 + MoveSpeed2, MoveSpeedR1 + MoveSpeedR2},
        max_hp = {Hp1 + Hp2, HpR1 + HpR2},
        attack = {Att1 + Att2, AttR1 + AttR2},
        defence = {Def1 + Def2, DefR1 + DefR2},
        arp = {Arp1 + Arp2, ArpR1 + ArpR2},
        hit_rate = {Hit1 + Hit2, HitR1 + HitR2},
        miss = {Miss1 + Miss2, MissR1 + MissR2},
        double = {Double1 + Double2, DoubleR1 + DoubleR2},
        double_anti = {DoubleA1 + DoubleA2, DoubleAR1 + DoubleAR2},
        double_multi = {DoubleM1 + DoubleM2, DoubleMR1 + DoubleMR2},
        hurt_rate = HurtRateList + HurtRateList2,
        hurt_derate = HurtDerateList + HurtDerateList2,
        monster_exp_add = {MonsterExpAdd1 + MonsterExpAdd2, MonsterExpAddR1 + MonsterExpAddR2},
        double_rate = {DoubleRate1 + DoubleRate2, DoubleRateR1 + DoubleRateR2},
        double_anti_rate  = {DoubleAntiR1 + DoubleAntiR2, DoubleAntiRR1 + DoubleAntiRR2},
        miss_rate = {MissRate1 + MissRate2, MissRateR1 + MissRateR2},
        armor = {Armor1 + Armor2, ArmorR1 + ArmorR2},
        skill_hurt = {SkillHurt1 + SkillHurt2, SkillHurtR1 + SkillHurtR2},
        skill_hurt_anti = {SkillHurtA1 + SkillHurtA2, SkillHurtAR1 + SkillHurtAR2},
        skill_dps = {SkillDps1 + SkillDps2, SkillDpsR1 + SkillDpsR2},
        skill_ehp = {SkillEhp1 + SkillEhp2, SkillEhpR1 + SkillEhpR2},
        role_hurt_add = RoleHurtAdd1 + RoleHurtAdd2,
        role_hurt_reduce = {RoleHurtReduce1 + RoleHurtReduce2, RoleHurtReduceR1 + RoleHurtReduceR2},
        boss_hurt_add = {BossHurtAdd1 + BossHurtAdd2, BossHurtAddR1 + BossHurtAddR2},
        boss_hurt_reduce = {BossHurtReduce1 + BossHurtReduce2, BossHurtReduceR1 + BossHurtReduceR2},
        drain = {Drain1 + Drain2, DrainR1 + DrainR2},
        rebound = {Rebound1 + Rebound2, ReboundR1 + ReboundR2},
        monster_hurt_add = {MonsterHurtAdd1 + MonsterHurtAdd2, MonsterHurtAddR1 + MonsterHurtAddR2},
        imprison_hurt_add = {ImprisonHurtAdd1 + ImprisonHurtAdd2, ImprisonHurtAddR1 + ImprisonHurtAddR2},
        silent_hurt_add = {SilentHurtAdd1 + SilentHurtAdd2, SilentHurtAddR1 + SilentHurtAddR2},
        poison_hurt_add = {PoisonHurtAdd1 + PoisonHurtAdd2, PoisonHurtAddR1 + PoisonHurtAddR2},
        burn_hurt_add = {BurnHurtAdd1 + BurnHurtAdd2, BurnHurtAddR1 + BurnHurtAddR2},
        dizzy_hurt_add = DizzyHurtAdd1 + DizzyHurtAdd2,
        slow_hurt_add = SlowHurtAdd1 + SlowHurtAdd2,
        poison_buff_add = PoisonBuffAdd1 + PoisonBuffAdd2,
        burn_buff_add = BurnBuffAdd1 + BurnBuffAdd2,
        poison_hurt_reduce = PoisonHurtReduce1 + PoisonHurtReduce2,
        burn_hurt_reduce = BurnHurtReduce1 + BurnHurtReduce2,
        slow_hurt_reduce = SlowHurtReduce1 + SlowHurtReduce2,
        dizzy_rate = {DizzyRate1 + DizzyRate2, DizzyRateR1 + DizzyRateR2},
        min_reduce_rate = {MinReduceRate1 + MinReduceRate2, MinReduceRateR1 + MinReduceRateR2},
        max_reduce_rate = {MaxReduceRate1 + MaxReduceRate2, MaxReduceRateR1 + MaxReduceRateR2},
        double_damage_rate = {DoubleDamageRate1 + DoubleDamageRate2, DoubleDamageRateR1 + DoubleDamageRateR2},
        double_miss_rate = {DoubleMissRate1 + DoubleMissRate2, DoubleMissRateR1 + DoubleMissRateR2},
        hp_recover = {HpRecover1 + HpRecover2, HpRecoverR1 + HpRecoverR2},
        war_spirit_time = {WarSpiritTime1 + WarSpiritTime2, WarSpiritTimeR1 + WarSpiritTimeR2},
        metal = {Metal1 + Metal2, MetalR1 + MetalR2},
        metal_anti = {MetalA1 + MetalA2, MetalAR1 + MetalAR2},
        wood = {Wood1 + Wood2, WoodR1 + WoodR2},
        wood_anti = {WoodA1 + WoodA2, WoodAR1 + WoodAR2},
        water = {Water1 + Water2, WaterR1 + WaterR2},
        water_anti = {WaterA1 + WaterA2, WaterAR1 + WaterAR2},
        fire = {Fire1 + Fire2, FireR1 + FireR2},
        fire_anti = {FireA1 + FireA2, FireAR1 + FireAR2},
        earth = {Earth1 + Earth2, EarthR1 + EarthR2},
        earth_anti = {EarthA1 + EarthA2, EarthAR1 + EarthAR2},
        block_rate = BlockRate1 + BlockRate2,
        block_reduce = BlockReduce1 + BlockReduce2,
        block_defy = BlockDefy1 + BlockDefy2,
        block_pass = BlockPass1 + BlockPass2,
        hp_heal_rate = HpHealRate1 + HpHealRate2
    }.

to_pet_attr(FightAttr) ->
    #actor_fight_attr{
        move_speed = MoveSpeed,
        max_hp = Hp,
        attack = Att,
        defence = Def,
        arp = Arp,
        hit_rate = Hit,
        miss = Miss,
        double = Double,
        double_anti = DoubleA,
        double_multi = DoubleM,
        hurt_rate = HurtR,
        hurt_derate = HurtD,
        monster_exp_add = MonsterExpAdd,
        double_rate = DoubleRate,
        double_anti_rate  = DoubleAntiR,
        miss_rate = MissRate,
        armor = Armor,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtA,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_add = BossHurtAdd,
        rebound = Rebound,
        monster_hurt_add = MonsterHurtAdd,
        imprison_hurt_add = ImprisonHurtAdd,
        silent_hurt_add = SilentHurtAdd,
        dizzy_rate = DizzyRate,
        metal = Metal,
        metal_anti = MetalA,
        wood = Wood,
        wood_anti = WoodA,
        water = Water,
        water_anti = WaterA,
        fire = Fire,
        fire_anti = FireA,
        earth = Earth,
        earth_anti = EarthA
    } = FightAttr,
    #actor_fight_attr{
        move_speed = lib_tool:ceil(MoveSpeed * ?PET_ATTR_RATE),
        max_hp = lib_tool:ceil(Hp * ?PET_ATTR_RATE),
        attack = lib_tool:ceil(Att * ?PET_ATTR_RATE),
        defence = lib_tool:ceil(Def * ?PET_ATTR_RATE),
        arp = lib_tool:ceil(Arp * ?PET_ATTR_RATE),
        hit_rate = lib_tool:ceil(Hit * ?PET_ATTR_RATE),
        miss = lib_tool:ceil(Miss * ?PET_ATTR_RATE),
        double = lib_tool:ceil(Double * ?PET_ATTR_RATE),
        double_anti = lib_tool:ceil(DoubleA * ?PET_ATTR_RATE),
        double_multi = lib_tool:ceil(DoubleM * ?PET_ATTR_RATE),
        hurt_rate = lib_tool:ceil(HurtR * ?PET_ATTR_RATE),
        hurt_derate = lib_tool:ceil(HurtD * ?PET_ATTR_RATE),
        monster_exp_add = lib_tool:ceil(MonsterExpAdd * ?PET_ATTR_RATE),
        double_rate = lib_tool:ceil(DoubleRate * ?PET_ATTR_RATE),
        double_anti_rate  = lib_tool:ceil(DoubleAntiR * ?PET_ATTR_RATE),
        miss_rate = lib_tool:ceil(MissRate * ?PET_ATTR_RATE),
        armor = lib_tool:ceil(Armor * ?PET_ATTR_RATE),
        skill_hurt = lib_tool:ceil(SkillHurt * ?PET_ATTR_RATE),
        skill_hurt_anti = lib_tool:ceil(SkillHurtA * ?PET_ATTR_RATE),
        skill_dps = lib_tool:ceil(SkillDps * ?PET_ATTR_RATE),
        skill_ehp = lib_tool:ceil(SkillEhp * ?PET_ATTR_RATE),
        role_hurt_reduce = lib_tool:ceil(RoleHurtReduce * ?PET_ATTR_RATE),
        boss_hurt_add = lib_tool:ceil(BossHurtAdd * ?PET_ATTR_RATE),
        rebound = lib_tool:ceil(Rebound * ?PET_ATTR_RATE),
        monster_hurt_add = lib_tool:ceil(MonsterHurtAdd * ?PET_ATTR_RATE),
        imprison_hurt_add = lib_tool:ceil(ImprisonHurtAdd * ?PET_ATTR_RATE),
        silent_hurt_add = lib_tool:ceil(SilentHurtAdd * ?PET_ATTR_RATE),
        dizzy_rate = lib_tool:ceil(DizzyRate * ?PET_ATTR_RATE),
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
        prop_effects = []
    }.

fight_attr_rate(FightAttr, Rate) ->
    #actor_fight_attr{
        move_speed = MoveSpeed,
        max_hp = Hp,
        attack = Att,
        defence = Def,
        arp = Arp,
        hit_rate = Hit,
        miss = Miss,
        double = Double,
        double_anti = DoubleA,
        double_multi = DoubleM,
        hurt_rate = HurtRate,
        hurt_derate = HurtDeRate,
        monster_exp_add = MonsterExpAdd,
        double_rate = DoubleRate,
        double_anti_rate  = DoubleAntiR,
        miss_rate = MissRate,
        armor = Armor,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtA,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp ,
        role_hurt_add = RoleHurtAdd,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_add = BossHurtAdd,
        dizzy_hurt_add = DizzyHurtAdd,
        slow_hurt_add = SlowHurtAdd,
        poison_buff_add = PoisonBuffAdd,
        burn_buff_add = BurnBuffAdd,
        poison_hurt_reduce = PoisonHurtReduce,
        burn_hurt_reduce = BurnHurtReduce,
        slow_hurt_reduce = SlowHurtReduce,
        boss_hurt_reduce = BossHurtReduce,
        drain = Drain,
        rebound = Rebound,
        monster_hurt_add = MonsterHurtAdd,
        imprison_hurt_add = ImprisonHurtAdd,
        silent_hurt_add = SilentHurtAdd,
        poison_hurt_add = PoisonHurtAdd,
        burn_hurt_add = BurnHurtAdd,
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
    #actor_fight_attr{
        move_speed = lib_tool:ceil(MoveSpeed *  Rate/?RATE_10000),
        max_hp = lib_tool:ceil(Hp *  Rate/?RATE_10000),
        attack = lib_tool:ceil(Att *  Rate/?RATE_10000),
        defence = lib_tool:ceil(Def *  Rate/?RATE_10000),
        arp = lib_tool:ceil(Arp *  Rate/?RATE_10000),
        hit_rate = lib_tool:ceil(Hit *  Rate/?RATE_10000),
        miss = lib_tool:ceil(Miss *  Rate/?RATE_10000),
        double = lib_tool:ceil(Double *  Rate/?RATE_10000),
        double_anti = lib_tool:ceil(DoubleA *  Rate/?RATE_10000),
        double_multi = lib_tool:ceil(DoubleM *  Rate/?RATE_10000),
        hurt_rate = lib_tool:ceil(HurtRate *  Rate/?RATE_10000),
        hurt_derate = lib_tool:ceil(HurtDeRate *  Rate/?RATE_10000),
        monster_exp_add = lib_tool:ceil(MonsterExpAdd *  Rate/?RATE_10000),
        double_rate = lib_tool:ceil(DoubleRate *  Rate/?RATE_10000),
        double_anti_rate  = lib_tool:ceil(DoubleAntiR *  Rate/?RATE_10000),
        miss_rate = lib_tool:ceil(MissRate *  Rate/?RATE_10000),
        armor = lib_tool:ceil(Armor *  Rate/?RATE_10000),
        skill_hurt = lib_tool:ceil(SkillHurt *  Rate/?RATE_10000),
        skill_hurt_anti = lib_tool:ceil(SkillHurtA *  Rate/?RATE_10000),
        skill_dps = lib_tool:ceil(SkillDps *  Rate/?RATE_10000),
        skill_ehp = lib_tool:ceil(SkillEhp  *  Rate/?RATE_10000),
        role_hurt_add = lib_tool:ceil(RoleHurtAdd *  Rate/?RATE_10000),
        role_hurt_reduce = lib_tool:ceil(RoleHurtReduce *  Rate/?RATE_10000),
        boss_hurt_add = lib_tool:ceil(BossHurtAdd *  Rate/?RATE_10000),
        dizzy_hurt_add = lib_tool:ceil(DizzyHurtAdd *  Rate/?RATE_10000),
        slow_hurt_add = lib_tool:ceil(SlowHurtAdd *  Rate/?RATE_10000),
        poison_buff_add = lib_tool:ceil(PoisonBuffAdd *  Rate/?RATE_10000),
        burn_buff_add = lib_tool:ceil(BurnBuffAdd *  Rate/?RATE_10000),
        poison_hurt_reduce = lib_tool:ceil(PoisonHurtReduce *  Rate/?RATE_10000),
        burn_hurt_reduce = lib_tool:ceil(BurnHurtReduce *  Rate/?RATE_10000),
        slow_hurt_reduce = lib_tool:ceil(SlowHurtReduce *  Rate/?RATE_10000),
        boss_hurt_reduce = lib_tool:ceil(BossHurtReduce *  Rate/?RATE_10000),
        drain = lib_tool:ceil(Drain *  Rate/?RATE_10000),
        rebound = lib_tool:ceil(Rebound *  Rate/?RATE_10000),
        monster_hurt_add = lib_tool:ceil(MonsterHurtAdd *  Rate/?RATE_10000),
        imprison_hurt_add = lib_tool:ceil(ImprisonHurtAdd *  Rate/?RATE_10000),
        silent_hurt_add = lib_tool:ceil(SilentHurtAdd *  Rate/?RATE_10000),
        poison_hurt_add = lib_tool:ceil(PoisonHurtAdd *  Rate/?RATE_10000),
        burn_hurt_add = lib_tool:ceil(BurnHurtAdd *  Rate/?RATE_10000),
        dizzy_rate = lib_tool:ceil(DizzyRate *  Rate/?RATE_10000),
        min_reduce_rate = lib_tool:ceil(MinReduceRate *  Rate/?RATE_10000),
        max_reduce_rate = lib_tool:ceil(MaxReduceRate *  Rate/?RATE_10000),
        double_damage_rate = lib_tool:ceil(DoubleDamageRate *  Rate/?RATE_10000),
        double_miss_rate = lib_tool:ceil(DoubleMissRate *  Rate/?RATE_10000),
        metal = lib_tool:ceil(Metal *  Rate/?RATE_10000),
        metal_anti = lib_tool:ceil(MetalA *  Rate/?RATE_10000),
        wood = lib_tool:ceil(Wood *  Rate/?RATE_10000),
        wood_anti = lib_tool:ceil(WoodA *  Rate/?RATE_10000),
        water = lib_tool:ceil(Water *  Rate/?RATE_10000),
        water_anti = lib_tool:ceil(WaterA *  Rate/?RATE_10000),
        fire = lib_tool:ceil(Fire *  Rate/?RATE_10000),
        fire_anti = lib_tool:ceil(FireA *  Rate/?RATE_10000),
        earth = lib_tool:ceil(Earth *  Rate/?RATE_10000),
        earth_anti = lib_tool:ceil(EarthA *  Rate/?RATE_10000),
        block_rate = lib_tool:ceil(BlockRate *  Rate/?RATE_10000),
        block_reduce = lib_tool:ceil(BlockReduce *  Rate/?RATE_10000),
        block_defy = lib_tool:ceil(BlockDefy *  Rate/?RATE_10000),
        block_pass = lib_tool:ceil(BlockPass *  Rate/?RATE_10000),
        hp_heal_rate = lib_tool:ceil(HpHealRate *  Rate/?RATE_10000)
    }.

pellet_attr(Attr, AddRate) ->
    #actor_cal_attr{
        max_hp = {Hp, HpR1},
        attack = {Att, AttR1},
        defence = {Def, DefR1},
        arp = {Arp, ArpR1},
        hit_rate = {Hit, HitR1},
        miss = {Miss, MissR1},
        double = {Double, DoubleR1},
        double_anti = {DoubleA, DoubleAR1}
    } = Attr,
    Attr#actor_cal_attr{
        max_hp = {lib_tool:ceil(Hp * (1 + AddRate/?RATE_10000)), HpR1},
        attack = {lib_tool:ceil(Att * (1 + AddRate/?RATE_10000)), AttR1},
        defence = {lib_tool:ceil(Def * (1 + AddRate/?RATE_10000)), DefR1},
        arp = {lib_tool:ceil(Arp * (1 + AddRate/?RATE_10000)), ArpR1},
        hit_rate = {lib_tool:ceil(Hit * (1 + AddRate/?RATE_10000)), HitR1},
        miss = {lib_tool:ceil(Miss * (1 + AddRate/?RATE_10000)), MissR1},
        double = {lib_tool:ceil(Double * (1 + AddRate/?RATE_10000)), DoubleR1},
        double_anti = {lib_tool:ceil(DoubleA * (1 + AddRate/?RATE_10000)), DoubleAR1}
    }.

get_calc_power(Attr) ->
    #actor_cal_attr{
        max_hp = {Hp, HpR},
        attack = {Att, AttR},
        defence = {Def, DefR},
        arp = {Arp, ArpR},
        hit_rate = {Hit, HitR},
        miss = {Miss, MissR},
        double = {Double, DoubleR},
        double_anti = {DoubleA, DoubleAR}
    } = Attr,
    lib_tool:ceil(
        get_rate_value(Hp, HpR) * ?POWER_HP +
        get_rate_value(Att, AttR) * ?POWER_ATTACK +
        get_rate_value(Def, DefR) * ?POWER_DEFENCE +
        get_rate_value(Arp, ArpR) * ?POWER_ARP +
        get_rate_value(Hit, HitR) * ?POWER_HIT_RATE +
        get_rate_value(Miss, MissR) * ?POWER_MISS +
        get_rate_value(Double, DoubleR) * ?POWER_DOUBLE +
        get_rate_value(DoubleA, DoubleAR) * ?POWER_DOUBLE_ANTI
    ).

get_rate_value(Value, Rate) ->
    Value * (1 + Rate/?RATE_10000).

get_random_name() ->
    [FirstNames] = lib_config:find(cfg_names, first_names),
    [SecondNames] = lib_config:find(cfg_names, second_names),
    lib_tool:random_element_from_list(FirstNames) ++ lib_tool:random_element_from_list(SecondNames).

make_p_buff(#r_buff{} = Buff) ->
    #r_buff{
        buff_id = BuffID,
        start_time = StartTime,
        end_time = EndTime,
        cover_times = CoverTimes
    } = Buff,
    #p_buff{
        buff_id = BuffID,
        start_time = StartTime,
        end_time = EndTime,
        value = CoverTimes
    }.

get_log_string(List) ->
    get_log_string2(List, "").

get_log_string2([], Acc) ->
    Acc;
get_log_string2([String|R], "") ->
    get_log_string2(R, lib_tool:to_list(unicode:characters_to_binary(String)));
get_log_string2([String|R], Acc) ->
    Acc2 = Acc ++ "||" ++ lib_tool:to_list(unicode:characters_to_binary(String)),
    get_log_string2(R, Acc2).

to_goods_string(GoodsList) ->
    to_goods_string2(GoodsList, "").

to_goods_string2([], Acc) ->
    Acc;
to_goods_string2([Goods|R], []) ->
    #p_goods{type_id = TypeID, num = Num, bind = Bind} = Goods,
    Acc2 = lib_tool:to_list_output([TypeID, Num, ?IF(Bind, 1, 0)]),
    to_goods_string2(R, Acc2);
to_goods_string2([Goods|R], Acc) ->
    #p_goods{type_id = TypeID, num = Num, bind = Bind} = Goods,
    Acc2 = lib_tool:to_list_output([TypeID, Num, ?IF(Bind, 1, 0)]) ++ "||" ++ Acc,
    to_goods_string2(R, Acc2).

to_kv_string(KVList) ->
    to_kv_string2(KVList, "").

to_kv_string2([], Acc) ->
    Acc;
to_kv_string2([KV|R], []) ->
    #p_kv{id = Key, val = Val} = KV,
    Acc2 = lib_tool:to_list_output([Key, Val]),
    to_kv_string2(R, Acc2);
to_kv_string2([KV|R], Acc) ->
    #p_kv{id = Key, val = Val} = KV,
    Acc2 = lib_tool:to_list_output([Key, Val]) ++ "||" ++ Acc,
    to_kv_string2(R, Acc2).

get_list_string(List) ->
    get_list_string2(List, "").

get_list_string2([], Acc) ->
    Acc;
get_list_string2([Int|R], "") ->
    get_list_string2(R, lib_tool:to_list(Int));
get_list_string2([Int|R], Acc) ->
    Acc2 = Acc ++ "||" ++ lib_tool:to_list(Int),
    get_list_string2(R, Acc2).

get_bool_int(Bool) ->
    ?IF(Bool =:= true, 1, 0).

send_support_goods(RoleID, WebSupport) ->
    #r_web_support{
        goods_list = GoodsList,
        text = Text
    } = WebSupport,
    LetterInfo = #r_letter_info{
        title_string = [?SUPPORT_LETTER_TITLE],
        text_string = [Text],
        action = ?ITEM_GAIN_WEB_SUPPORT,
        goods_list = GoodsList
    },
    common_letter:send_letter(RoleID, LetterInfo).

is_rename_ban(Action) ->
    lists:member(Action, world_data:get_ban_rename_actions()).