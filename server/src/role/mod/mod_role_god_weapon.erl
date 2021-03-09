%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 七月 2017 12:26
%%%-------------------------------------------------------------------
-module(mod_role_god_weapon).
-author("laijichang").
-author("laijichang").
-include("role.hrl").
-include("rank.hrl").
-include("proto/mod_role_god_weapon.hrl").
-include("proto/mod_role_item.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    handle/2
]).

-export([
    add_exp/4,
    add_soul/3,
    add_skin/3,
    function_open/2
]).

-export([
    get_base_skins/1,
    get_god_weapon_level/1
]).

init(#r_role{role_id = RoleID, role_god_weapon = undefined} = State) ->
    RoleGodWeapon = #r_role_god_weapon{role_id = RoleID},
    State#r_role{role_god_weapon = RoleGodWeapon};
init(State) ->
    State.

calc(State) ->
    #r_role{role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{level = Level, skin_list = SkinList, soul_list = SoulList} = RoleGodWeapon,
    SkinAttr = calc_id_list(SkinList),
    CalcAttr2 = calc_level(Level),
    {CalcAttr3, AddRate} = role_misc:get_pellet_attr(cfg_god_weapon_soul, SoulList),
    RateAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([CalcAttr2, CalcAttr3]), AddRate),
    AllAttr = common_misc:sum_calc_attr([RateAttr, SkinAttr]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_GOD_WEAPON, AllAttr).

calc_id_list(SkinList) ->
    lists:foldl(
        fun(#p_kv{id = ID}, Acc) ->
            [Config] = lib_config:find(cfg_god_weapon_skin, ID),
            #c_god_weapon_skin{
                add_attack = AddAttack,
                add_arp = AddArp,
                add_double = AddDouble,
                add_double_rate = AddDoubleRate} = Config,
            Attr =
            #actor_cal_attr{
                attack = {AddAttack, 0},
                arp = {AddArp, 0},
                double = {AddDouble, 0},
                double_rate = {AddDoubleRate, 0}
            },
            common_misc:sum_calc_attr2(Attr, Acc)
        end, #actor_cal_attr{}, SkinList).

calc_level(Level) when Level > 0 ->
    [#c_god_weapon_level{
        add_attack = AddAttack,
        add_arp = AddArp,
        add_hit_rate = AddHitRate,
        add_double = AddDouble,
        add_double_anti = AddDoubleAnti,
        add_double_rate = AddDoubleRate
    }] = lib_config:find(cfg_god_weapon_level, Level),
    #actor_cal_attr{
        attack = {AddAttack, 0},
        arp = {AddArp, 0},
        hit_rate = {AddHitRate, 0},
        double = {AddDouble, 0},
        double_anti = {AddDoubleAnti, 0},
        double_rate = {AddDoubleRate, 0}
    };
calc_level(_Level) ->
    #actor_cal_attr{}.

online(State) ->
    #r_role{role_id = RoleID, role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList
    } = RoleGodWeapon,
    DataRecord = #m_god_weapon_info_toc{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList},
    common_misc:unicast(RoleID, DataRecord),
    State.

%% 功能开启
function_open(ID, State) ->
    #r_role{role_id = RoleID, role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{level = Level, skin_list = SkinList} = RoleGodWeapon,
    case lists:keymember(ID, #p_kv.id, SkinList) of
        false ->
            Skin = #p_kv{id = ID, val = 0},
            SkinList2 = [Skin|SkinList],
            Level2 = ?IF(Level > 0, Level, 1),
            RoleGodWeapon2 = RoleGodWeapon#r_role_god_weapon{level = Level2, cur_id = ID, skin_list = SkinList2},
            State2 = State#r_role{role_god_weapon = RoleGodWeapon2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_GOD_WEAPON_STEP, ID),
            case Level =/= Level2 of
                true ->
                    State4 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, Level2, State3)), ?POWER_UPDATE_GOD_WEAPON_LEVEL, Level2),
                    common_misc:unicast(RoleID, #m_god_weapon_level_toc{new_level = Level2});
                _ ->
                    State4 = State3
            end,
            common_misc:unicast(RoleID, #m_god_weapon_change_toc{cur_id = ID}),
            common_misc:unicast(RoleID, #m_god_weapon_skin_toc{skin = Skin}),
            ?TRY_CATCH(role_misc:log_role_nurture(State4)),
            State5 = mod_role_achievement:god_weapon_level_up(Level2, State4),
            State6 = mod_role_confine:god_weapon_level_up(Level2,State5),
            State7 = mod_role_day_target:god_weapon_level_up(State6),
            mod_role_skin:update_skin(State7, true);
        _ ->
            State
    end.

%% 升级
add_exp(AddExp, TypeID, Num, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_god_weapon = RoleGodWeapon} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #r_role_god_weapon{exp = Exp, level = Level} = RoleGodWeapon,
    case lib_config:find(cfg_god_weapon_level, Level + 1) of
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_GOD_WEAPON_LEVEL_001)
    end,
    {NewLevel, NewExp} = role_misc:get_new_level_exp(cfg_god_weapon_level, #c_god_weapon_level.exp, Level, Exp + AddExp),
    RoleGodWeapon2 = RoleGodWeapon#r_role_god_weapon{level = NewLevel, exp = NewExp},
    common_misc:unicast(RoleID, #m_god_weapon_level_toc{new_level = NewLevel, new_exp = NewExp}),
    State2 = State#r_role{role_god_weapon = RoleGodWeapon2},
    Log = #log_role_god_weapon{
        role_id = RoleID,
        item_id = TypeID,
        item_num = Num,
        old_level = Level,
        new_level = NewLevel,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log),
    case Level =/= NewLevel of
        true ->
            role_misc:level_broadcast(Level, NewLevel, ?NOTICE_GOD_WEAPON_LEVEL_UP, State),
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            State3 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, NewLevel, State2)), ?POWER_UPDATE_GOD_WEAPON_LEVEL, NewLevel),
            State4 = mod_role_achievement:god_weapon_level_up(NewLevel, State3),
            State5 = mod_role_confine:god_weapon_level_up(NewLevel,State4),
            mod_role_day_target:god_weapon_level_up(State5);
        _ ->
            State2
    end.

%% 魂
add_soul(TypeID, AddNum, State) ->
    #r_role{role_id = RoleID, role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{soul_list = SoulList} = RoleGodWeapon,
    case lists:keyfind(TypeID, #p_kv.id, SoulList) of
        #p_kv{} = Soul ->
            ok;
        _ ->
            Soul = #p_kv{id = TypeID, val = 0}
    end,
    #p_kv{val = UseNum} = Soul,
    [#c_pellet{max_num = MaxNum}] = lib_config:find(cfg_god_weapon_soul, TypeID),
    NewUseNum = ?IF(role_misc:pellet_max_num(UseNum + AddNum, MaxNum, State), ?THROW_ERR(?ERROR_ITEM_USE_005), UseNum + AddNum),
    role_misc:pellet_broadcast(?NOTICE_GOD_WEAPON_PELLET, TypeID, State),
    Soul2 = Soul#p_kv{val = NewUseNum},
    SoulList2 = lists:keystore(TypeID, #p_kv.id, SoulList, Soul2),
    RoleGodWeapon2 = RoleGodWeapon#r_role_god_weapon{soul_list = SoulList2},
    common_misc:unicast(RoleID, #m_god_weapon_soul_toc{soul = Soul2}),
    State2 = State#r_role{role_god_weapon = RoleGodWeapon2},
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_GOD_WEAPON_SOUL, TypeID).

%% 使用皮肤
add_skin(GodWeaponID, AddNum, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}, role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{skin_list = SkinList} = RoleGodWeapon,
    case lib_config:find(cfg_god_weapon_skin, GodWeaponID) of
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_ITEM_USE_008)
    end,
    {IsNew, IsStar, Skin, SkinList2} = add_skin2(GodWeaponID, AddNum, SkinList, []),
    RoleGodWeapon2 = RoleGodWeapon#r_role_god_weapon{skin_list = SkinList2},
    State2 = State#r_role{role_god_weapon = RoleGodWeapon2},
    common_misc:unicast(RoleID, #m_god_weapon_skin_toc{skin = Skin}),
    if
        IsNew ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            [#c_god_weapon_base{name = Name, broadcast_id = BroadcastID}] = lib_config:find(cfg_god_weapon_base, ?GET_BASE_ID(Skin#p_kv.id)),
            ?IF(BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, [RoleName, Name]), ok);
        IsStar ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            [#c_god_weapon_base{name = Name}] = lib_config:find(cfg_god_weapon_base, ?GET_BASE_ID(Skin#p_kv.id)),
            StringList = [RoleName, Name, lib_tool:to_list(get_god_weapon_star(Skin#p_kv.id))],
            common_broadcast:send_world_common_notice(?NOTICE_WING_SKIN_UP, StringList);
        true ->
            ok
    end,
    State3 = ?IF(IsNew, mod_role_skin:update_couple_skin(?DB_ROLE_GOD_WEAPON_P, ?GET_BASE_ID(Skin#p_kv.id), State2), State2),
    mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_GOD_WEAPON_SKIN, GodWeaponID).

add_skin2(GodWeaponID, AddNum, [], Acc) ->
    Skin = #p_kv{id = GodWeaponID, val = 0},
    {_, Skin2} = add_skin3(Skin, AddNum - 1, false),
    {true, false, Skin2, [Skin2|Acc]};
add_skin2(GodWeaponID, AddNum, [Skin|R], Acc) ->
    #p_kv{id = ID} = Skin,
    case ?GET_SKIN_TYPE(ID) =:= ?GET_SKIN_TYPE(GodWeaponID) of
        true -> %% 看看能不能升级
            NewID = ID + 1,
            case lib_config:find(cfg_god_weapon_skin, NewID) of
                [_Config] ->
                    {IsStar, NewSkin} = add_skin3(Skin, AddNum, false),
                    {false, IsStar, NewSkin, [NewSkin|R] ++ Acc};
                _ ->
                    ?THROW_ERR(?ERROR_GOD_WEAPON_SKIN_001)
            end;
        _ ->
            add_skin2(GodWeaponID, AddNum, R, [Skin|Acc])
    end.

add_skin3(Skin, 0, AccFlag) ->
    {AccFlag, Skin};
add_skin3(Skin, AddNum, AccFlag) ->
    #p_kv{id = ID, val = Num} = Skin,
    NewID = ID + 1,
    case lib_config:find(cfg_god_weapon_skin, NewID) of
        [_NextConfig] ->
            [#c_god_weapon_skin{item_num = NeedNum}] = lib_config:find(cfg_god_weapon_skin, ID),
            Num2 = Num + 1,
            {AccFlag2, NewSkin} = ?IF(Num2 >= NeedNum, {true, #p_kv{id = NewID, val = 0}}, {false, Skin#p_kv{val = Num2}}),
            add_skin3(NewSkin, AddNum - 1, AccFlag2);
        _ ->
            {AccFlag, Skin}
    end.

handle({#m_god_weapon_change_tos{cur_id = GodWeaponID}, RoleID, _PID}, State) ->
    do_change(RoleID, GodWeaponID, State).

do_change(RoleID, GodWeaponID, State) ->
    case catch check_can_change(GodWeaponID, State) of
        {ok, State2} ->
            State3 = mod_role_fashion:unload_weapon(State2),
            State4 = mod_role_skin:update_skin(State3, false),
            common_misc:unicast(RoleID, #m_god_weapon_change_toc{cur_id = GodWeaponID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_god_weapon_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(GodWeaponID, State) ->
    #r_role{role_attr = #r_role_attr{skin_list = AllSkinList}, role_god_weapon = RoleGodWeapon} = State,
    #r_role_god_weapon{skin_list = SkinList} = RoleGodWeapon,
    ?IF(lists:member(GodWeaponID, AllSkinList), ?THROW_ERR(?ERROR_GOD_WEAPON_CHANGE_001), ok),
    ?IF(lists:keymember(GodWeaponID, #p_kv.id, SkinList), ok, ?THROW_ERR(?ERROR_GOD_WEAPON_CHANGE_002)),
    RoleGodWeapon2 = RoleGodWeapon#r_role_god_weapon{cur_id = GodWeaponID},
    {ok, State#r_role{role_god_weapon = RoleGodWeapon2}}.

do_level_skill(OldLevel, NewLevel, State) ->
    OldSkills = get_level_skill(OldLevel),
    NewSkills = get_level_skill(NewLevel),
    case OldSkills =/= NewSkills of
        true ->
            role_misc:skill_broadcast(NewSkills -- OldSkills, ?NOTICE_GOD_WEAPON_SKILL_OPEN, State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_GOD, NewSkills, State);
        _ ->
            State
    end.

%% 获取法宝等级对应的技能
get_level_skill(0) ->
    [];
get_level_skill(Level) ->
    [#c_god_weapon_level{skill_list = SkillList}] = lib_config:find(cfg_god_weapon_level, Level),
    SkillList.

get_god_weapon_star(GodWeaponID) ->
    case lib_config:find(cfg_god_weapon_skin, GodWeaponID) of
        [#c_god_weapon_skin{star = Star}] ->
            Star;
        _ ->
            0
    end.

get_base_skins(undefined) ->
    [];
get_base_skins(RoleGodWeapon) ->
    #r_role_god_weapon{skin_list = SkinList} = RoleGodWeapon,
    [?GET_BASE_ID(SurfaceID) || #p_kv{id = SurfaceID} <- SkinList].

get_god_weapon_level(State) ->
    #r_role{role_god_weapon = #r_role_god_weapon{level = Level}} = State,
    Level.