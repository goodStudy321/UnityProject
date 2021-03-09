%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2017 16:54
%%%-------------------------------------------------------------------
-module(monster_misc).
-author("laijichang").
-include("monster.hrl").
-include("team.hrl").

%% API
-export([
    init_base_attr/1,
    recal_attr/1,
    get_base_move_speed/1,
    get_move_speed/1,
    update_base_move_speed/2,
    judge_in_distance/3,
    get_path_move_speed/4,
    get_monster_config/1,
    get_monster_name/1,
    is_td_move/1,
    is_world_boss/1,
    is_normal_monster/1,
    get_dynamic_monster/2,
    get_monster_exp_drop/1
]).

-export([
    get_owner_roles/1,
    filter_other_map_roles/1
]).

init_base_attr(MonsterData) ->
    #r_monster{type_id = TypeID, base_attr = BaseAttr, add_props = AddProps} = MonsterData,
    #c_monster{
        move_speed = MoveSpeed,
        level = Level,
        add_exp = AddExp,
        max_hp = MaxHP,
        attack = Attack,
        defence = Def,
        arp = Arp,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleAnti,
        double_multi = DoubleM,
        hurt_rate = HurtR,
        hurt_derate = HurtD,
        min_reduce_rate = MinReduceRate,
        max_reduce_rate = MaxReduceRate,
        metal_anti = MetalA,
        wood_anti = WoodA,
        water_anti = WaterA,
        fire_anti = FireA,
        earth_anti = EarthA
    } = monster_misc:get_monster_config(TypeID),
    case BaseAttr =:= undefined of
        true ->
            BaseAttr2 =
                #actor_cal_attr{
                    move_speed = {MoveSpeed, 0},
                    max_hp = {lib_tool:ceil(MaxHP * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    attack = {lib_tool:ceil(Attack * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    defence = {lib_tool:ceil(Def * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    arp = {lib_tool:ceil(Arp * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    hit_rate = {lib_tool:ceil(HitRate * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    miss = {lib_tool:ceil(Miss * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    double = {lib_tool:ceil(Double * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    double_anti = {lib_tool:ceil(DoubleAnti * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    double_multi = {lib_tool:ceil(DoubleM * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    hurt_rate = lib_tool:ceil(HurtR * (?RATE_10000 + AddProps)/?RATE_10000),
                    hurt_derate = lib_tool:ceil(HurtD * (?RATE_10000 + AddProps)/?RATE_10000),
                    min_reduce_rate = {lib_tool:ceil(MinReduceRate * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    max_reduce_rate = {lib_tool:ceil(MaxReduceRate * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    metal_anti = {lib_tool:ceil(MetalA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    wood_anti = {lib_tool:ceil(WoodA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    water_anti = {lib_tool:ceil(WaterA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    fire_anti = {lib_tool:ceil(FireA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                    earth_anti = {lib_tool:ceil(EarthA * (?RATE_10000 + AddProps)/?RATE_10000), 0}
                },
            MonsterData#r_monster{base_attr = BaseAttr2, level = Level, add_exp = AddExp};
        _ ->
            {OldMovePeed, _OldMovePeedR} = BaseAttr#actor_cal_attr.move_speed,
            BaseAttr2 = BaseAttr#actor_cal_attr{
                min_reduce_rate = {lib_tool:ceil(MinReduceRate * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                max_reduce_rate = {lib_tool:ceil(MaxReduceRate * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                metal_anti = {lib_tool:ceil(MetalA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                wood_anti = {lib_tool:ceil(WoodA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                water_anti = {lib_tool:ceil(WaterA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                fire_anti = {lib_tool:ceil(FireA * (?RATE_10000 + AddProps)/?RATE_10000), 0},
                earth_anti = {lib_tool:ceil(EarthA * (?RATE_10000 + AddProps)/?RATE_10000), 0}
            },
            BaseAttr3 = ?IF(OldMovePeed > 0, BaseAttr2, BaseAttr2#actor_cal_attr{move_speed = {MoveSpeed, 0}}),
            MonsterData#r_monster{base_attr = BaseAttr3}
    end.

recal_attr(MonsterID) when erlang:is_integer(MonsterID) ->
    MonsterData = mod_monster_data:get_monster_data(MonsterID),
    recal_attr(MonsterData);
recal_attr(MonsterData) ->
    #r_monster{monster_id = MonsterID} = MonsterData,
    FightAttr2 = recal_fight_attr(MonsterData),
    mod_monster_data:set_monster_data(MonsterID, MonsterData#r_monster{attr = FightAttr2}),
    mod_map_monster:monster_update_fight_attr(MonsterID, FightAttr2).

recal_fight_attr(MonsterData) ->
    #r_monster{
        base_attr = BaseAttr,
        buffs = Buffs,
        debuffs = Debuffs} = MonsterData,
    {FightAttr, _ExtraAttr} = common_misc:sum_attr([BaseAttr]),
    BuffAttr = common_buff:get_cal_attr(Buffs ++ Debuffs, BaseAttr),
    common_buff:sum_attr(FightAttr, BuffAttr).

get_base_move_speed(MonsterData) ->
    {DefaultSpeed, _} = MonsterData#r_monster.base_attr#actor_cal_attr.move_speed,
    DefaultSpeed.

update_base_move_speed(MonsterData, MoveSpeed) ->
    #r_monster{monster_id = MonsterID, base_attr = BaseAttr} = MonsterData,
    #actor_cal_attr{move_speed = {_, MoveSpeedR}} = BaseAttr,
    BaseAttr2 = BaseAttr#actor_cal_attr{move_speed = {MoveSpeed, MoveSpeedR}},
    MonsterData2 = MonsterData#r_monster{base_attr = BaseAttr2},
    FightAttr = recal_fight_attr(MonsterData2),
    mod_map_monster:monster_update_move_speed(MonsterID, FightAttr#actor_fight_attr.move_speed),
    MonsterData2#r_monster{attr = FightAttr}.

get_move_speed(MonsterData) ->
    MonsterData#r_monster.attr#actor_fight_attr.move_speed.

judge_in_distance(#r_pos{tx = Tx1, ty = Ty1}, #r_pos{tx = Tx2, ty = Ty2}, Distance) ->
    %% 存在点不存在的情况
    case map_base_data:is_exist(Tx2, Ty2) of
        false ->
            false;
        _ ->
            X = abs(Tx1 - Tx2),
            Y = abs(Ty1 - Ty2),
            X =< Distance andalso Y =< Distance
    end;
judge_in_distance(_, _ , _Distance)->
    false.

get_path_move_speed(_Pos1, _Pos2, 0, DefaultSpeed) ->
    DefaultSpeed;
get_path_move_speed(#r_pos{mx = Mx1, my = My1}, #r_pos{mx = Mx2, my = My2}, UseTime, _DefaultSpeed) ->
    X = erlang:abs(Mx1 - Mx2),
    Y = erlang:abs(My1 - My2),
    lib_tool:ceil(math:sqrt(X * X + Y * Y)/UseTime).

get_monster_config(TypeID) ->
    case lib_config:find(cfg_monster, TypeID) of
        [Config] ->
            Config;
        _ ->
            ?ERROR_MSG("unknow monster TypeID: ~w", [TypeID]),
            erlang:throw(config_error)
    end.

get_monster_name(TypeID) ->
    #c_monster{monster_name = MonsterName} = get_monster_config(TypeID),
    MonsterName.

is_td_move(MonsterData) ->
    #r_monster{td_pos_list = TDPosList} = MonsterData,
    TDPosList =/= [].

is_world_boss(TypeID) ->
    #c_monster{rarity = Rarity} = get_monster_config(TypeID),
    Rarity =:= ?MONSTER_RARITY_WORLD_BOSS.

is_normal_monster(TypeID) ->
    #c_monster{rarity = Rarity} = get_monster_config(TypeID),
    Rarity =:= ?MONSTER_RARITY_NORMAL orelse Rarity =:= ?MONSTER_RARITY_ELITE.

get_dynamic_monster(Level, TypeID) ->
    case lib_config:find(cfg_dynamic_calc, TypeID) of
        [Config] ->
            #c_dynamic_calc{
                start_level = StartLevel,
                is_copy_exp = IsCopyExp,
                hp_args = HpArgs,
                life_time = LifeTime,
                attack_args = AttackArgs,
                dps_multi = DpsMulti,
                attack_time = AttackTime,
                exp_multi = ExpMulti
            } = Config,
            #c_monster{max_hp = MaxHp} = get_monster_config(TypeID),
            case Level >= StartLevel of
                true ->
                    [#c_dynamic_standard{
                        dps = Dps,
                        ehp = Ehp,
                        base_exp = BaseExp,
                        copy_exp = CopyExp
                    }] = lib_config:find(cfg_dynamic_standard, Level),
                    Exp = lib_tool:ceil(?IF(?IS_COPY_EXP_MONSTER(IsCopyExp), ExpMulti * CopyExp/100, ExpMulti * BaseExp/100)),
                    Hp = ?IF(HpArgs > 0, MaxHp, lib_tool:ceil(Dps * LifeTime/100)),
                    Attack = ?IF(AttackArgs > 0, lib_tool:ceil(Dps * AttackArgs/?RATE_100), lib_tool:ceil(Ehp * (DpsMulti/?RATE_10000) * (AttackTime/?RATE_100))),
                    Attr =
                        #actor_cal_attr{
                            max_hp = {Hp, 0},
                            attack = {Attack, 0}
                        },
                    #r_monster{type_id = TypeID, level = Level, base_attr = Attr, add_exp = Exp};
                _ -> %% base_attr = undefined会直接读配置里的数据
                    #r_monster{type_id = TypeID, base_attr = undefined}
            end;
        _ ->
            #r_monster{type_id = TypeID, base_attr = undefined}
    end.

get_monster_exp_drop(TypeID) ->
    #c_monster{add_exp = Exp, drop_id_list = DropIDList} = monster_misc:get_monster_config(TypeID),
    DropIDList2 = [ DropID|| DropID <- DropIDList, erlang:is_integer(DropID)],
    DropIDList3 = hook_monster:get_act_drop_id_list(DropIDList2),
    {Exp, lists:flatten(DropIDList3)}.

get_owner_roles(HurtOwner) ->
    RolesT =
        case HurtOwner of
            #r_hurt_owner{type = ?HURT_OWNER_ROLE, type_args = RoleID} ->
                case mod_map_ets:get_actor_mapinfo(RoleID) of
                    #r_map_actor{role_extra = #p_map_role{team_id = TeamID}} ->
                        case ?HAS_TEAM(TeamID) of
                            true ->
                                mod_map_ets:get_team_roles(TeamID);
                            _ ->
                                [RoleID]
                        end;
                    _ ->
                        []
                end;
            #r_hurt_owner{type = ?HURT_OWNER_TEAM, type_args = TeamID} ->
                mod_map_ets:get_team_roles(TeamID);
            #r_hurt_owner{type = ?HURT_OWNER_ROLES, type_args = RoleIDs} ->
                RoleIDs;
            _ ->
                []
        end,
    filter_other_map_roles(RolesT).

filter_other_map_roles(RoleList) ->
    InMapRoles = mod_map_ets:get_in_map_roles(),
    RoleList -- (RoleList -- InMapRoles).