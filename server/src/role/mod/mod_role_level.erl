%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     升级相关
%%% @end
%%% Created : 12. 六月 2017 10:59
%%%-------------------------------------------------------------------
-module(mod_role_level).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_level.hrl").

%% API
-export([
    add_exp/3,
    add_level_exp/3,
    monster_dead_add_exp/2,
    gm_set_level/2
]).

-export([
    calc/1,
    handle/2,
    loop/2
]).

-export([
    get_level_attr/1,
    do_add_level_exp/4,
    do_add_level_exp2/5,
    do_add_exp/3,
    do_monster_dead_add_exp/2,
    reduce_exp/2,
    add_exp_or_level/3
]).

-export([
    get_activity_level_exp/1,
    get_activity_level_exp/2
]).

add_exp(RoleID, AddExp, Action) when AddExp > 0 ->
    case common_config:is_cross_node() of
        true -> %% 跨服进程调用
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, add_exp, [RoleID, AddExp, Action]});
        _ ->
            case role_misc:is_online(RoleID) of
                true ->
                    role_misc:info_role(RoleID, {mod, ?MODULE, {add_exp, AddExp, Action}});
                _ ->
                    world_offline_event_server:add_event(RoleID, {?MODULE, add_exp, [RoleID, AddExp, Action]})
            end
    end;
add_exp(_RoleID, _AddExp, _Action) ->
    ok.

add_level_exp(RoleID, ExpRate, Action) when ExpRate > 0 ->
    case common_config:is_cross_node() of
        true -> %% 跨服进程调用
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, add_level_exp, [RoleID, ExpRate, Action]});
        _ ->
            case role_misc:is_online(RoleID) of
                true ->
                    role_misc:info_role(RoleID, {mod, ?MODULE, {add_level_exp, ExpRate, Action}});
                _ ->
                    world_offline_event_server:add_event(RoleID, {?MODULE, add_level_exp, [RoleID, ExpRate, Action]})
            end
    end;
add_level_exp(_RoleID, _AddExp, _Action) ->
    ok.

monster_dead_add_exp(RoleID, AddExp) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {monster_dead_add_exp, AddExp}}).

calc(State) ->
    CalcAttr = get_level_attr(State),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_LEVEL, CalcAttr).

handle({add_exp, AddExp, Action}, State) ->
    do_add_exp(State, AddExp, Action);
handle({add_level_exp, ExpRate, Action}, State) ->
    do_add_level_exp(ExpRate, 1, Action, State);
handle({monster_dead_add_exp, AddExp}, State) ->
    do_monster_dead_add_exp(State, AddExp).

loop(_Now, State) ->
    Counter = mod_role_dict:get_recover_counter(),
    case Counter of
        10 -> %% 每10秒恢复生命
            mod_role_dict:set_recover_counter(1),
            #r_role{role_id = RoleID, role_map = #r_role_map{hp = Hp}, role_fight = RoleFight} = State,
            #actor_fight_attr{max_hp = MaxHp} = RoleFight#r_role_fight.fight_attr,
            case Hp < MaxHp of
                true ->
                    AbsHp = mod_role_dict:get_recover_hp_abs(),
                    RateAddHp =
                        lists:foldl(
                            fun({HpRate, MaxRecoverHp}, Acc) ->
                                erlang:min(MaxHp * HpRate/?RATE_10000, MaxRecoverHp) + Acc
                            end, 0, mod_role_dict:get_recover_hp_rate()),
                    RecoverHp = lib_tool:ceil(AbsHp + RateAddHp),
                    mod_map_role:role_buff_heal(mod_role_dict:get_map_pid(), RoleID, RecoverHp, ?BUFF_ADD_HP, 0);
                _ ->
                    ok
            end;
        _ ->
            mod_role_dict:set_recover_counter(Counter + 1)
    end,
    State.


get_level_attr(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{sex = Sex, level = Level} = RoleAttr,
    [Config] = lib_config:find(cfg_level, {Sex, Level}),
    #c_level{
        hp = Hp,
        attack = Attack,
        defence = Defence,
        arp = Arp,
        move_speed = MoveSpeed,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleAnti,
        double_multi = DoubleM,
        hurt_rate = HurtR,
        hurt_derate = HurtD,
        hp_recover = HpRecover,
        war_spirit_time = WarSpiritTime
    } = Config,
        #actor_cal_attr{
            move_speed = {MoveSpeed, 0},
            max_hp = {Hp, 0},
            attack = {Attack, 0},
            defence = {Defence, 0},
            arp = {Arp, 0},
            hit_rate = {HitRate, 0},
            miss = {Miss, 0},
            double = {Double, 0},
            double_anti = {DoubleAnti, 0},
            double_multi = {DoubleM, 0},
            hurt_rate = HurtR,
            hurt_derate = HurtD,
            hp_recover = {HpRecover, 0},
            war_spirit_time = {WarSpiritTime, 0}
        }.

gm_set_level(Level, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{level = OldLevel} = RoleAttr,
    Now = time_tool:now(),
    RoleAttr2 = RoleAttr#r_role_attr{level = Level, exp = 0},
    PrivateAttr2 = PrivateAttr#r_role_private_attr{last_level_time = Now},
    State2 = State#r_role{role_attr = RoleAttr2, role_private_attr = PrivateAttr2},
    State3 = mod_role_fight:calc_attr_and_update(do_update_level_calc(State2), ?POWER_UPDATE_LEVEL_UP, Level),
    common_misc:unicast(RoleID, #m_role_level_toc{level = Level}),
    common_misc:unicast(RoleID, #m_role_attr_change_toc{kv_list = [#p_dkv{id = ?ATTR_LAST_LEVEL_TIME, val = Now}]}),
    State4 = hook_role:level_up(State3, OldLevel, Level),
    ?TRY_CATCH(log_role_level(0, OldLevel, Level, ?EXP_ADD_FROM_GM, State)),
    State4.

do_update_level_calc(State) ->
    List = [mod_role_level, mod_role_rune, mod_role_world_level, mod_role_family, mod_role_marry, mod_role_skill],
    lists:foldl(fun(Mod, State2) -> Mod:calc(State2) end, State, List).


%% 怪物死亡增加经验
do_monster_dead_add_exp(State, AddExp) ->
    #r_role{role_fight = #r_role_fight{fight_attr = #actor_fight_attr{monster_exp_add = ExpAdd}}} = State,
    ExpMulti = mod_role_copy:get_copy_exp_multi(State),
    AddExp2 = lib_tool:ceil(ExpMulti * AddExp * (1 + (ExpAdd / ?RATE_10000))),
    do_add_exp(State, AddExp2, ?EXP_ADD_FROM_KILL_MONSTER).

do_add_level_exp(Rate, Multi, Action, State) ->
    do_add_level_exp2(mod_role_data:get_role_level(State), Rate, Multi, Action, State).
do_add_level_exp2(Level, Rate, Multi, Action, State) ->
    BaseExp = get_activity_level_exp(Level),
    AddExp = lib_tool:ceil(Multi * BaseExp * Rate/?RATE_10000),
    do_add_exp(State, AddExp, Action).

do_add_exp(State, AddExpT, Action) -> %% T 增加经验通用函数
    AddExp = mod_role_addict:get_addict_num(AddExpT, State),
    do_add_exp2(State, AddExp, Action).

do_add_exp2(State, AddExp, Action) when AddExp > 0 ->
    IsMonsterAdd = Action =:= ?EXP_ADD_FROM_KILL_MONSTER,
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{sex = Sex, level = Level, exp = Exp} = RoleAttr,
    {NewLevel, NewExp} = do_add_exp3(Sex, Level, Exp, AddExp),
    NewExp2 = lib_tool:ceil(NewExp),
    RoleAttr2 = RoleAttr#r_role_attr{level = NewLevel, exp = NewExp2},
    common_misc:unicast(RoleID, #m_role_level_toc{level = NewLevel, exp = NewExp2, is_monster_add = IsMonsterAdd}),
    case Level =/= NewLevel of
        true ->
            Now = time_tool:now(),
            PrivateAttr2 = PrivateAttr#r_role_private_attr{last_level_time = Now},
            State2 = State#r_role{role_attr = RoleAttr2, role_private_attr = PrivateAttr2},
            State3 = mod_role_fight:calc_attr_and_update(do_update_level_calc(State2), ?POWER_UPDATE_LEVEL_UP, NewLevel),
            State4 = hook_role:level_up(State3, Level, NewLevel),
            ?TRY_CATCH(log_role_level(AddExp, Level, NewLevel, Action, State)),
            common_misc:unicast(RoleID, #m_role_attr_change_toc{kv_list = [#p_dkv{id = ?ATTR_LAST_LEVEL_TIME, val = Now}]});
        _ ->
            State4 = State#r_role{role_attr = RoleAttr2}
    end,
    State5 = ?IF(IsMonsterAdd orelse Action =:= ?EXP_ADD_FROM_MARRY_COUNTER, mod_role_map_panel:add_exp(AddExp, State4), State4),
    State5;
do_add_exp2(State, _AddExp, _IsMonsterAdd) ->
    State.

do_add_exp3(Sex, Level, Exp, AddExp) ->
    case lib_config:find(cfg_level, {Sex, Level + 1}) of
        [_Config] -> %% 有下一个等级
            case lib_config:find(cfg_level, {Sex, Level}) of
                [#c_level{need_exp = NeedExp}] ->
                    NewExp = Exp + AddExp,
                    case NewExp >= NeedExp of
                        true ->
                            do_add_exp3(Sex, Level + 1, lib_tool:floor(NewExp - NeedExp), 0);
                        _ ->
                            {Level, NewExp}
                    end;
                _ ->
                    {Level, Exp + AddExp}
            end;
        _ ->
            {Level, Exp + AddExp}
    end.

%%  T 要么加经验要么加等级（加一整级的经验）
add_exp_or_level(State, EffectArgs, Action) ->  %% Action 是 ?EXP_ADD_FROM_ITEM_USE
    [LevelLimitString, AddExpString] = string:tokens(EffectArgs,","),
    LevelLimit = lib_tool:to_integer(LevelLimitString),
    AddExp = lib_tool:to_integer(AddExpString),
    RoleLevel = mod_role_data:get_role_level(State),
    DirectLevelUp = RoleLevel =< LevelLimit,
    ?IF(DirectLevelUp, do_add_a_whole_level_exp(State, Action), do_add_exp(State, AddExp, Action)).

do_add_a_whole_level_exp(State, Action) ->  %%  T 加上这级的完整经验
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{sex  = Sex, level = Level} = RoleAttr,
    [#c_level{need_exp = AddLevelExp}] = lib_config:find(cfg_level, {Sex, Level}),
    do_add_exp(State, AddLevelExp, Action).

reduce_exp(ReduceExp, State) when ReduceExp > 0 ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{level = Level, exp = Exp} = RoleAttr,
    Exp2 = Exp - ReduceExp,
    common_misc:unicast(RoleID, #m_role_level_toc{level = Level, exp = Exp2, is_monster_add = false}),
    RoleAttr2 = RoleAttr#r_role_attr{exp = Exp2},
    State#r_role{role_attr = RoleAttr2};
reduce_exp(_Exp, State) ->
    State.

get_activity_level_exp(Level) ->
    get_activity_level_exp(Level, ?RATE_10000).

get_activity_level_exp(Level, Rate) when erlang:is_integer(Level) andalso Level > 0->
    [#c_role_level{base_exp = BaseExp}] = lib_config:find(cfg_role_level, Level),
    lib_tool:ceil(BaseExp * Rate/?RATE_10000);
get_activity_level_exp(Level, _Rate) ->
    ?ERROR_MSG("调用等级经验接口出错, Level:~w", [Level]),
    0.

log_role_level(AddExp, OldLevel, NewLevel, Action, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_map = #r_role_map{map_id = MapID}} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    Log =
        #log_role_level{
            role_id = RoleID,
            add_exp = AddExp,
            old_level = OldLevel,
            new_level = NewLevel,
            action = Action,
            map_id = MapID,
            channel_id = ChannelID,
            game_channel_id = GameChannelID
        },
    mod_role_dict:add_background_logs(Log).
