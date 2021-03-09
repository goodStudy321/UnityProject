%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 16:11
%%%-------------------------------------------------------------------
-module(common_skill).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    get_skill_config/1,
    get_skill_names/1,
    get_skill_action_list/1,
    get_skill_action_list/2,
    check_skill_by_buff_status/2,
    is_role_skill_type/1
]).

-export([
    get_next_skill/1,
    get_hit_value_list/2,
    get_skill_pos/4,
    get_prop_effect_list/1
]).

get_skill_config(SkillID) ->
    case lib_config:find(cfg_skill, SkillID) of
        [Config] ->
            Config;
        _ ->
            ?ERROR_MSG("技能未配置 : ~w", [SkillID]),
            erlang:throw(config_error)
    end.

get_skill_names(SkillIDList) ->
    get_skill_names2(SkillIDList, []).

get_skill_names2([], Acc) ->
    Acc;
get_skill_names2([SkillID|R], []) ->
    #c_skill{skill_name = SkillName} = get_skill_config(SkillID),
    get_skill_names2(R, SkillName);
get_skill_names2([SkillID|R], Acc) ->
    #c_skill{skill_name = SkillName} = get_skill_config(SkillID),
    Acc2 = SkillName ++ "、" ++  Acc,
    get_skill_names2(R, Acc2).


%% 技能相关设定
%% 有伤害的第一击会触发自身、敌方buff。命中buff则是每一段都会触发
%%
get_skill_action_list(SkillID) ->
    get_skill_action_list(SkillID, 0).
get_skill_action_list(SkillID, AddValue) ->
    [Skill] = lib_config:find(cfg_skill, SkillID),
    #c_skill{
        hit_value = HitValueString,
        self_buffs = SelfBuffs,
        direct_buffs = DirectBuffs,
        summon_traps = SummonTraps,
        skill_type = SkillType} = Skill,

    HitValueList = get_hit_value_list(HitValueString, AddValue),
    EffectList = [],
%%    case SkillID =:= 1002001 of %% 拉怪效果测试
%%        true ->
%%            EffectList = [#r_skill_effect{effect_type = ?EFFECT_TYPE_CATCH}];
%%        _ ->
%%            EffectList = []
%%    end,
    SummonEffect = ?IF(SummonTraps > 0, [#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_SUMMON_TRAP, value = SummonTraps}], []),
    SelfBuffEffect = ?IF(SelfBuffs =/= [], [#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_BUFF, value = SelfBuffs}], []),
    EnemyBuffEffect = ?IF(DirectBuffs =/= [], [#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = ?EFFECT_TYPE_BUFF, value = DirectBuffs}], []),
    SelfEffects = SelfBuffEffect,
    EnemyEffects = EnemyBuffEffect ++ EffectList,
    get_skill_action_list2(SkillID, SkillType, EnemyEffects, SelfEffects, SummonEffect, HitValueList, [], 1).

get_skill_action_list2(SkillID, _SkillType, EnemyEffects, SelfEffects, SummonEffect, [], [], Num) ->
    [#r_skill_action{
        step_id = Num,
        skill_id = SkillID,
        hurt_list = [#r_skill_hurt{self_effect = SummonEffect ++ SelfEffects, enemy_effect = EnemyEffects}]
    }];
get_skill_action_list2(_SkillID, _SkillType, _EnemyEffects, _SelfEffects, _SummonEffect, [], Acc, _Num) ->
    lists:reverse(Acc);
get_skill_action_list2(SkillID, SkillType, EnemyEffects, SelfEffects, SummonEffect, [List|R], Acc, Num) ->
    {EnemyEffects2, SelfEffects2} = ?IF(Num =:= 1, {EnemyEffects, SelfEffects}, {[], []}),
    HurtList = get_skill_hurt_list(SkillID, SkillType, EnemyEffects2, SelfEffects2, SummonEffect, List, [], 1, 0),
    Action = #r_skill_action{
        step_id = Num,
        skill_id = SkillID,
        hurt_list = HurtList
    },
    get_skill_action_list2(SkillID, SkillType, EnemyEffects, SelfEffects, SummonEffect, R, [Action|Acc], Num + 1).

get_skill_hurt_list(_SkillID, _SkillType, _EnemyEffects, _SelfEffects, _SummonEffect, [], Acc, _Num, _LastDelay) ->
    lists:reverse(Acc);
get_skill_hurt_list(SkillID, SkillType, EnemyEffects, SelfEffects, SummonEffect, [{Time, HitValue}|R], Acc, Num, LastDelay) ->
    {EnemyEffects2, SelfEffects2} = ?IF(Num =:= 1, {EnemyEffects, SelfEffects}, {[], []}),
    case HitValue > 0 of
        true ->
            HitEffectType = get_hit_effect_type(SkillID),
            SkillHurt = #r_skill_hurt{
                delay = Time - LastDelay,
                enemy_effect = [#r_skill_effect{skill_id = SkillID, skill_type = SkillType, effect_type = HitEffectType, value = HitValue}|EnemyEffects2],
                self_effect = SummonEffect ++ SelfEffects2};
        _ ->
            SkillHurt = #r_skill_hurt{
                delay = Time - LastDelay,
                enemy_effect = EnemyEffects2,
                self_effect = SummonEffect ++ SelfEffects2}
    end,
    get_skill_hurt_list(SkillID, SkillType, EnemyEffects, SelfEffects, SummonEffect, R, [SkillHurt|Acc], Num + 1, Time).

get_hit_value_list(HitValueString, AddValue) ->
    ActionList = string:tokens(HitValueString, "|"),
    get_hit_value_list2(ActionList, AddValue, []).

get_hit_value_list2([], _AddValue, Acc) ->
    lists:reverse(Acc);
get_hit_value_list2([ActionString|R], AddValue, Acc) ->
    HitValueList =
        [ begin
              [Time, HitValue] = string:tokens(String, ","),
              {lib_tool:to_integer(Time), lib_tool:to_integer(HitValue) + AddValue}
          end|| String <- string:tokens(ActionString, ";")],
    get_hit_value_list2(R, AddValue, [HitValueList|Acc]).

get_next_skill(undefined) ->
    [];
get_next_skill([]) ->
    false;
get_next_skill([#r_skill_action{hurt_list = HurtList} = Action|R]) ->
    case HurtList of
        [#r_skill_hurt{} = Hurt|HurtRemain] ->
            Action2 = Action#r_skill_action{hurt_list = HurtRemain},
            {next_hurt, Action, Hurt, [Action2|R]};
        _ ->
            case R of
                [#r_skill_action{} = NextAction|_] ->
                    {next_prepare, NextAction, R};
                _ ->
                    false
            end
    end.


check_skill_by_buff_status(#p_skill{skill_id = SkillID}, BuffStatus) ->
    check_skill_by_buff_status(SkillID, BuffStatus);
check_skill_by_buff_status(SkillID, BuffStatus) when erlang:is_integer(SkillID) ->
    #c_skill{skill_type = SkillType} = SkillConfig = get_skill_config(SkillID),
    if
        SkillType =:= ?SKILL_ATTACK -> %% 普通攻击
            ?IF(?IS_BUFF_LIMIT_NORMAL_ATTACK(BuffStatus), false, {ok, SkillConfig});
        SkillType =:= ?SKILL_NORMAL -> %% 技能攻击
            ?IF(?IS_BUFF_LIMIT_SKILL_ATTACK(BuffStatus), false, {ok, SkillConfig});
        true ->
            {ok, SkillConfig}
    end.

is_role_skill_type(SkillID) ->
    SkillFun = ?GET_SKILL_FUN(SkillID),
    if
        SkillFun =:= ?SKILL_FUN_PET ->
            false;
        SkillFun =:= ?SKILL_FUN_MAGIC ->
            false;
        true ->
            true
    end.

get_skill_pos(MonsterPos, DestPos, PosType, PosOffset) ->
    #r_pos{mx = Mx1, my = My1, mdir = Mdir} = MonsterPos,
    #r_pos{mx = Mx2, my = My2} = DestPos,
    {Mx, My} = ?IF(PosType =:= 1, {Mx1, My1}, {Mx2, My2}),
    case PosOffset of
        [OffsetMx, OffsetMy] ->
            map_misc:get_pos_by_meter(Mx + OffsetMx, My + OffsetMy, Mdir);
        _ ->
            map_misc:get_pos_by_meter(Mx, My, Mdir)
    end.

get_prop_effect_list(SkillID) ->
    #c_skill{hit_prop_condition = HitPropCondition, props = PropString} = common_skill:get_skill_config(SkillID),
    case HitPropCondition of
        [Type, HpRate, Rate] ->
            [#actor_prop_effect{
                type = Type,
                hp_rate = HpRate,
                rate = Rate,
                add_props = common_misc:get_string_props(PropString)}];
        _ ->
            []
    end.


get_hit_effect_type(SkillID) ->
    SkillFun = ?GET_SKILL_FUN(SkillID),
    if
        SkillFun =:= ?SKILL_FUN_PET ->
            ?EFFECT_TYPE_PET_HIT;
        SkillFun =:= ?SKILL_FUN_MAGIC ->
            ?EFFECT_TYPE_MAGIC_WEAPON_HIT;
        true ->
            ?EFFECT_TYPE_NORMAL_HIT
    end.

