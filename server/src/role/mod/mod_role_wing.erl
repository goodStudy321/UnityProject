%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     翅膀！！！
%%% @end
%%% Created : 15. 七月 2017 16:46
%%%-------------------------------------------------------------------
-module(mod_role_wing).
-author("laijichang").
-author("laijichang").
-include("role.hrl").
-include("rank.hrl").
-include("proto/mod_role_wing.hrl").
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
    get_wing_level/1
]).

init(#r_role{role_id = RoleID, role_wing = undefined} = State) ->
    RoleWing = #r_role_wing{role_id = RoleID},
    State#r_role{role_wing = RoleWing};
init(State) ->
    State.

calc(State) ->
    #r_role{role_wing = RoleWing} = State,
    #r_role_wing{level = Level, skin_list = SkinList, soul_list = SoulList} = RoleWing,
    SkinAttr = calc_id_list(SkinList),
    CalcAttr2 = calc_level(Level),
    {CalcAttr3, AddRate} = role_misc:get_pellet_attr(cfg_wing_soul, SoulList),
    AddRate2 = role_misc:get_skill_prop_rate(?ATTR_WING_ADD, State),
    RateAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([CalcAttr2, CalcAttr3]), AddRate + AddRate2),
    AllAttr = common_misc:sum_calc_attr([RateAttr, SkinAttr]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_WING, AllAttr).

calc_id_list(SkinList) ->
    lists:foldl(
        fun(#p_kv{id = ID}, Acc) ->
            [Config] = lib_config:find(cfg_wing_skin, ID),
            #c_wing_skin{
                add_hp_rate = AddHpRate,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp} = Config,
            Attr =
            #actor_cal_attr{
                max_hp = {0, AddHpRate},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                arp = {AddArp, 0}
            },
            common_misc:sum_calc_attr2(Attr, Acc)
        end, #actor_cal_attr{}, SkinList).

calc_level(Level) when Level > 0 ->
    [#c_wing_level{
        add_hp = AddHp,
        add_defence = AddDefence,
        add_miss = AddMiss,
        add_double_anti = AddDoubleAnti
    }] = lib_config:find(cfg_wing_level, Level),
    #actor_cal_attr{
        max_hp = {AddHp, 0},
        defence = {AddDefence, 0},
        miss = {AddMiss, 0},
        double_anti = {AddDoubleAnti, 0}
    };
calc_level(_Level) ->
    #actor_cal_attr{}.

online(State) ->
    #r_role{role_id = RoleID, role_wing = RoleWing} = State,
    #r_role_wing{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList
    } = RoleWing,
    DataRecord = #m_wing_info_toc{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList},
    common_misc:unicast(RoleID, DataRecord),
    State.

%% 功能开启
function_open(ID, State) ->
    #r_role{role_id = RoleID, role_wing = RoleWing} = State,
    #r_role_wing{level = Level, skin_list = SkinList} = RoleWing,
    case lists:keymember(ID, #p_kv.id, SkinList) of
        false ->
            Skin = #p_kv{id = ID, val = 0},
            SkinList2 = [Skin|SkinList],
            Level2 = ?IF(Level > 0, Level, 1),
            RoleWing2 = RoleWing#r_role_wing{level = Level2, cur_id = ID, skin_list = SkinList2},
            State2 = State#r_role{role_wing = RoleWing2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WING_STEP, ID),
            case Level =/= Level2 of
                true ->
                    State4 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, Level2, State3)), ?POWER_UPDATE_WING_LEVEL, Level2),
                    common_misc:unicast(RoleID, #m_wing_level_toc{new_level = Level2});
                _ ->
                    State4 = State3
            end,
            common_misc:unicast(RoleID, #m_wing_skin_toc{skin = Skin}),
            ?TRY_CATCH(role_misc:log_role_nurture(State4)),
            State5 = mod_role_achievement:wing_level_up(Level2, State4),
            State6 = mod_role_confine:wing_level_up(Level2, State5),
            State7 = mod_role_day_target:wing_level_up(State6),
            mod_role_skin:update_skin(State7);
        _ ->
            State
    end.

%% 升级
add_exp(AddExp, TypeID, Num, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_wing = RoleWing} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #r_role_wing{exp = Exp, level = Level} = RoleWing,
    case lib_config:find(cfg_wing_level, Level + 1) of
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_WING_LEVEL_001)
    end,
    {NewLevel, NewExp} = role_misc:get_new_level_exp(cfg_wing_level, #c_wing_level.exp, Level, Exp + AddExp),
    RoleWing2 = RoleWing#r_role_wing{level = NewLevel, exp = NewExp},
    common_misc:unicast(RoleID, #m_wing_level_toc{new_level = NewLevel, new_exp = NewExp}),
    State2 = State#r_role{role_wing = RoleWing2},
    Log = #log_role_wing{
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
            role_misc:level_broadcast(Level, NewLevel, ?NOTICE_WING_LEVEL_UP, State),
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            State3 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, NewLevel, State2)), ?POWER_UPDATE_WING_LEVEL, NewLevel),
            State4 = mod_role_achievement:wing_level_up(NewLevel, State3),
            State5 = mod_role_confine:wing_level_up(NewLevel, State4),
            mod_role_day_target:wing_level_up(State5);
        _ ->
            State2
    end.

%% 魂
add_soul(TypeID, AddNum, State) ->
    #r_role{role_id = RoleID, role_wing = RoleWing} = State,
    #r_role_wing{soul_list = SoulList} = RoleWing,
    case lists:keyfind(TypeID, #p_kv.id, SoulList) of
        #p_kv{} = Soul ->
            ok;
        _ ->
            Soul = #p_kv{id = TypeID, val = 0}
    end,
    #p_kv{val = UseNum} = Soul,
    [#c_pellet{max_num = MaxNum}] = lib_config:find(cfg_wing_soul, TypeID),
    NewUseNum = ?IF(role_misc:pellet_max_num(UseNum + AddNum, MaxNum, State), ?THROW_ERR(?ERROR_ITEM_USE_005), UseNum + AddNum),
    role_misc:pellet_broadcast(?NOTICE_WING_PELLET, TypeID, State),
    Soul2 = Soul#p_kv{val = NewUseNum},
    SoulList2 = lists:keystore(TypeID, #p_kv.id, SoulList, Soul2),
    RoleWing2 = RoleWing#r_role_wing{soul_list = SoulList2},
    common_misc:unicast(RoleID, #m_wing_soul_toc{soul = Soul2}),
    State2 = State#r_role{role_wing = RoleWing2},
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WING_SOUL, TypeID).

%% 使用皮肤
add_skin(WingID, AddNum, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}, role_wing = RoleWing} = State,
    #r_role_wing{skin_list = SkinList} = RoleWing,
    case lib_config:find(cfg_wing_skin, WingID) of
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_ITEM_USE_008)
    end,
    {IsNew, IsStar, Skin, SkinList2} = add_skin2(WingID, AddNum, SkinList, []),
    RoleWing2 = RoleWing#r_role_wing{skin_list = SkinList2},
    State2 = State#r_role{role_wing = RoleWing2},
    common_misc:unicast(RoleID, #m_wing_skin_toc{skin = Skin}),
    if
        IsNew ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            [#c_wing_base{name = Name, broadcast_id = BroadcastID}] = lib_config:find(cfg_wing_base, ?GET_BASE_ID(Skin#p_kv.id)),
            ?IF(BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, [RoleName, Name]), ok);
        IsStar ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            [#c_wing_base{name = Name}] = lib_config:find(cfg_wing_base, ?GET_BASE_ID(Skin#p_kv.id)),
            StringList = [RoleName, Name, lib_tool:to_list(get_wing_star(Skin#p_kv.id))],
            common_broadcast:send_world_common_notice(?NOTICE_WING_SKIN_UP, StringList);
        true ->
            ok
    end,
    State3 = ?IF(IsNew, mod_role_skin:update_couple_skin(?DB_ROLE_WING_P, ?GET_BASE_ID(Skin#p_kv.id), State2), State2),
    mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_WING_SKIN, WingID).

add_skin2(WingID, AddNum, [], Acc) ->
    Skin = #p_kv{id = WingID, val = 0},
    {_, Skin2} = add_skin3(Skin, AddNum - 1, false),
    {true, false, Skin2, [Skin2|Acc]};
add_skin2(WingID, AddNum, [Skin|R], Acc) ->
    #p_kv{id = ID} = Skin,
    case ?GET_SKIN_TYPE(ID) =:= ?GET_SKIN_TYPE(WingID) of
        true -> %% 看看能不能升级
            NewID = ID + 1,
            case lib_config:find(cfg_wing_skin, NewID) of
                [_Config] ->
                    {IsStar, NewSkin} = add_skin3(Skin, AddNum, false),
                    {false, IsStar, NewSkin, [NewSkin|R] ++ Acc};
                _ ->
                    ?THROW_ERR(?ERROR_WING_SKIN_001)
            end;
        _ ->
            add_skin2(WingID, AddNum, R, [Skin|Acc])
    end.

add_skin3(Skin, 0, AccFlag) ->
    {AccFlag, Skin};
add_skin3(Skin, AddNum, AccFlag) ->
    #p_kv{id = ID, val = Num} = Skin,
    NewID = ID + 1,
    case lib_config:find(cfg_wing_skin, NewID) of
        [_NextConfig] ->
            [#c_wing_skin{item_num = NeedNum}] = lib_config:find(cfg_wing_skin, ID),
            Num2 = Num + 1,
            {AccFlag2, NewSkin} = ?IF(Num2 >= NeedNum, {true, #p_kv{id = NewID, val = 0}}, {false, Skin#p_kv{val = Num2}}),
            add_skin3(NewSkin, AddNum - 1, AccFlag2);
        _ ->
            {AccFlag, Skin}
    end.

handle({#m_wing_change_tos{cur_id = WingID}, RoleID, _PID}, State) ->
    do_change(RoleID, WingID, State).

do_change(RoleID, WingID, State) ->
    case catch check_can_change(WingID, State) of
        {ok, State2} ->
            State3 = mod_role_skin:update_skin(State2),
            common_misc:unicast(RoleID, #m_wing_change_toc{cur_id = WingID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_wing_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(WingID, State) ->
    #r_role{role_wing = RoleWing} = State,
    #r_role_wing{cur_id = CurID, skin_list = SkinList} = RoleWing,
    ?IF(WingID =:= CurID, ?THROW_ERR(?ERROR_WING_CHANGE_001), ok),
    ?IF(lists:keymember(WingID, #p_kv.id, SkinList), ok, ?THROW_ERR(?ERROR_WING_CHANGE_002)),
    RoleWing2 = RoleWing#r_role_wing{cur_id = WingID},
    {ok, State#r_role{role_wing = RoleWing2}}.

do_level_skill(OldLevel, NewLevel, State) ->
    OldSkills = get_level_skill(OldLevel),
    NewSkills = get_level_skill(NewLevel),
    case OldSkills =/= NewSkills of
        true ->
            AddSkills = NewSkills -- OldSkills,
            role_misc:skill_broadcast(AddSkills, ?NOTICE_WING_SKILL_OPEN, State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_WING, NewSkills, State);
        _ ->
            State
    end.

%% 获取法宝等级对应的技能
get_level_skill(0) ->
    [];
get_level_skill(Level) ->
    [#c_wing_level{skill_list = SkillList}] = lib_config:find(cfg_wing_level, Level),
    SkillList.

get_wing_star(WingID) ->
    case lib_config:find(cfg_wing_skin, WingID) of
        [#c_wing_skin{star = Star}] ->
            Star;
        _ ->
            0
    end.

get_base_skins(undefined) ->
    [];
get_base_skins(RoleWing) ->
    #r_role_wing{skin_list = SkinList} = RoleWing,
    [?GET_BASE_ID(SurfaceID) || #p_kv{id = SurfaceID} <- SkinList].

get_wing_level(State) ->
    #r_role{role_wing = #r_role_wing{level = Level}} = State,
    Level.