%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 法宝系统
%%% @end
%%% Created : 17. 七月 2017 12:26
%%%-------------------------------------------------------------------
-module(mod_role_magic_weapon).
-author("laijichang").
-author("laijichang").
-include("role.hrl").
-include("rank.hrl").
-include("proto/mod_role_magic_weapon.hrl").
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
    get_magic_weapon_level/1
]).

-export([
    gm_magic_weapon_skin_id/2
]).

init(#r_role{role_id = RoleID, role_magic_weapon = undefined} = State) ->
    RoleMagicWeapon = #r_role_magic_weapon{role_id = RoleID},
    State#r_role{role_magic_weapon = RoleMagicWeapon};
init(State) ->
    State.

calc(State) ->
    #r_role{role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{level = Level, skin_list = SkinList, soul_list = SoulList} = RoleMagicWeapon,
    SkinAttr = calc_id_list(SkinList), % T根据所有皮肤计算属性增量
    CalcAttr2 = calc_level(Level), % T根据级别计算属性
    {CalcAttr3, AddRate} = role_misc:get_pellet_attr(cfg_magic_weapon_soul, SoulList),
    AddRate2 = role_misc:get_skill_prop_rate(?ATTR_MAGIC_WEAPON_ADD, State),
    RateAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([CalcAttr2, CalcAttr3]), AddRate + AddRate2),
    AllAttr = common_misc:sum_calc_attr([RateAttr, SkinAttr]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_MAGIC_WEAPON, AllAttr).

calc_id_list(SkinList) -> % T 把所有皮肤的属性增量加到一起
    lists:foldl(
        fun(#p_kv{id = ID}, Acc) ->
            [Config] = lib_config:find(cfg_magic_weapon_skin, ID),
            #c_magic_weapon_skin{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp,
                add_hit_rate = AddHitRate,
                add_miss = AddMiss,
                add_double = AddDouble,
                add_double_anti = AddDoubleAnti,
                add_attack_rate = AddAttackRate,
                add_hp_rate = AddHpRate} = Config,
            Attr =
            #actor_cal_attr{
                max_hp = {AddHp, AddHpRate},
                attack = {AddAttack, AddAttackRate},
                defence = {AddDefence, 0},
                arp = {AddArp, 0},
                hit_rate = {AddHitRate, 0},
                miss = {AddMiss, 0},
                double = {AddDouble, 0},
                double_anti = {AddDoubleAnti, 0}
            },
            common_misc:sum_calc_attr2(Attr, Acc)
        end, #actor_cal_attr{}, SkinList).

calc_level(Level) when Level > 0 -> % T根据级别计算属性
    [#c_magic_weapon_level{
        add_attack = AddAttack,
        add_arp = AddArp,
        add_miss = AddMiss,
        add_hit_rate = AddHitRate
    }] = lib_config:find(cfg_magic_weapon_level, Level),
    #actor_cal_attr{
        attack = {AddAttack, 0},
        arp = {AddArp, 0},
        miss = {AddMiss, 0},
        hit_rate = {AddHitRate, 0}
    };
calc_level(_Level) ->   % T level 出现小等于0或其他异常情况
    #actor_cal_attr{}.  % T 得出一个属性全为0的值。

online(State) ->
    #r_role{role_id = RoleID, role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList
    } = RoleMagicWeapon,
    DataRecord = #m_magic_weapon_info_toc{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = SoulList},
    common_misc:unicast(RoleID, DataRecord), %上线推送法宝各种属性信息。
    State.

%% 功能开启
function_open(ID, State) ->
    #r_role{role_id = RoleID, role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{level = Level, skin_list = SkinList} = RoleMagicWeapon,
    case lists:keymember(ID, #p_kv.id, SkinList) of   % T 看看是不是包含这个皮肤道具ID
        false ->  % T 没有包含这个ID
            Skin = #p_kv{id = ID, val = 0}, % T 新的skin
            SkinList2 = [Skin|SkinList],    % T 把新的skin 放入原list中
            Level2 = ?IF(Level > 0, Level, 1), % T 法宝这里的等级是公用的，坐骑和伙伴那里是不同皮肤单独属性。
            RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{level = Level2, cur_id = ID, skin_list = SkinList2},
            State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MAGIC_WEAPON_STEP, ID),
            case Level =/= Level2 of % T 有等级就要计算皮肤等级增量
                true ->
                    % T  do_level_skill 计算技能 并推送
                    State4 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, Level2, State3)), ?POWER_UPDATE_MAGIC_WEAPON_LEVEL, Level2),
                    common_misc:unicast(RoleID, #m_magic_weapon_level_toc{new_level = Level2});
                _ ->
                    State4 = State3
            end,
            common_misc:unicast(RoleID, #m_magic_weapon_skin_toc{skin = Skin}),
            ?TRY_CATCH(role_misc:log_role_nurture(State4)),
            State5 = mod_role_achievement:magic_weapon_level_up(Level2, State4),
            State6 = mod_role_confine:magic_weapon_level_up(Level2,State5),
            State7 = mod_role_day_target:magic_weapon_level_up(State6),
            mod_role_skin:update_skin(State7);
        _ ->  % T 如果已经包含了这个ID的皮肤
            State
    end.

%% 升级  T 法宝加经验 走道具
add_exp(AddExp, TypeID, Num, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #r_role_magic_weapon{exp = Exp, level = Level} = RoleMagicWeapon,
    case lib_config:find(cfg_magic_weapon_level, Level + 1) of   % T 看看配置表中能不能升级
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_MAGIC_WEAPON_LEVEL_001)   % T 不能再继续升级
    end,
    {NewLevel, NewExp} = role_misc:get_new_level_exp(cfg_magic_weapon_level, #c_magic_weapon_level.exp, Level, Exp + AddExp),% T 根据现有的等级经验+增量算新等级
    RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{level = NewLevel, exp = NewExp}, % T 把新等级 和新的等级经验放入
    common_misc:unicast(RoleID, #m_magic_weapon_level_toc{new_level = NewLevel, new_exp = NewExp}),
    State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
    Log = #log_role_magic_weapon{  % T 新建一个日志文件
        role_id = RoleID,
        item_id = TypeID,
        item_num = Num,
        old_level = Level,
        new_level = NewLevel,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log), % T 写入后台日志
    case Level =/= NewLevel of
        true ->
            role_misc:level_broadcast(Level, NewLevel, ?NOTICE_MAGIC_WEAPON_LEVEL_UP, State),  %% T 法宝等级提升（每10级广播）
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),
            State3 = mod_role_fight:calc_attr_and_update(calc(do_level_skill(Level, NewLevel, State2)), ?POWER_UPDATE_MAGIC_WEAPON_LEVEL, NewLevel),% T 新旧等级带来的技能变换
            State4 = mod_role_achievement:magic_weapon_level_up(NewLevel, State3),  % T 成就
            State5 = mod_role_confine:magic_weapon_level_up(NewLevel, State4),      % T 任务
            mod_role_day_target:magic_weapon_level_up(State5);            % T 每日任务
        _ ->
            State2
    end.

%% 魂
add_soul(TypeID, AddNum, State) ->
    #r_role{role_id = RoleID, role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{soul_list = SoulList} = RoleMagicWeapon,
    case lists:keyfind(TypeID, #p_kv.id, SoulList) of
        #p_kv{} = Soul ->
            ok;
        _ ->
            Soul = #p_kv{id = TypeID, val = 0}
    end,
    #p_kv{val = UseNum} = Soul,
    [#c_pellet{max_num = MaxNum}] = lib_config:find(cfg_magic_weapon_soul, TypeID),
    NewUseNum = ?IF(role_misc:pellet_max_num(UseNum + AddNum, MaxNum, State), ?THROW_ERR(?ERROR_ITEM_USE_005), UseNum + AddNum),
    role_misc:pellet_broadcast(?NOTICE_MAGIC_WEAPON_PELLET, TypeID, State),
    Soul2 = Soul#p_kv{val = NewUseNum},
    SoulList2 = lists:keystore(TypeID, #p_kv.id, SoulList, Soul2),
    RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{soul_list = SoulList2},
    common_misc:unicast(RoleID, #m_magic_weapon_soul_toc{soul = Soul2}),
    State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MAGIC_WEAPON_SOUL, TypeID).

%% 使用皮肤 走道具的渠道
add_skin(MagicWeaponID, AddNum, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}, role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{level = Level, skin_list = SkinList} = RoleMagicWeapon,
    case lib_config:find(cfg_magic_weapon_skin, MagicWeaponID) of  % T 看看配置表里面是不是有这个皮肤
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_ITEM_USE_008) % T 没有该类型的皮肤的错误
    end,
    {IsNew, IsStar, Skin, SkinList2} = add_skin2(MagicWeaponID, AddNum, SkinList, []),  % T 皮肤配置表中有这类型的皮肤
    RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{skin_list = SkinList2},
    State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
    common_misc:unicast(RoleID, #m_magic_weapon_skin_toc{skin = Skin}),
    if
        IsNew ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),% T 新皮肤要记录在案
            State2T = do_magic_weapon_skin_skill(0, MagicWeaponID, Level, State2),
            State3 = mod_role_skin:update_couple_skin(?DB_ROLE_MAGIC_WEAPON_P, get_base_id(Skin#p_kv.id), State2T),
            [#c_magic_weapon_base{name = Name, broadcast_id = BroadcastID}] = lib_config:find(cfg_magic_weapon_base, get_base_id(Skin#p_kv.id)),
            ?IF(BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, [RoleName, Name]), ok); % T 新的皮肤要世界广播
        IsStar ->
            ?TRY_CATCH(role_misc:log_role_nurture(State2)),  % T 如果加了星 记录在案  并全服广播
            State3 = do_magic_weapon_skin_skill(MagicWeaponID, Skin#p_kv.id, Level, State2);
        true ->
            State3 = State2,
            State3
    end,
    mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MAGIC_WEAPON_SKIN, MagicWeaponID). % T 加上新皮肤的战力

add_skin2(MagicWeaponID, AddNum, [], Acc) ->   %% SkinList 为空了  Acc 初始为空
    Skin = #p_kv{id = MagicWeaponID, val = 0}, %T 造出一个经验为0的 pkv 结构
    {_, Skin2} = add_skin3(Skin, AddNum - 1, false),  % T 换上一个新皮肤
    {true, false, Skin2, [Skin2|Acc]};
add_skin2(MagicWeaponID, AddNum, [Skin|R], Acc) ->  %% SkinList 不为空  Acc 初始为空
    #p_kv{id = ID} = Skin,
    case get_base_id(ID) =:= get_base_id(MagicWeaponID) of %% T 看是不是同一种皮肤  就要准备进阶了
        true ->
            NewID = ID + 1,
            case lib_config:find(cfg_magic_weapon_skin, NewID) of  % T 是不是能够进阶
                [#c_magic_weapon_skin{type = StepType}] -> % T 能进阶  要看数量够不够
                    ?IF(StepType =:= ?MAGIC_WEAPON_SKIN_STEP, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                    {IsStar, NewSkin} = add_skin3(Skin, AddNum, false),
                    {false, IsStar, NewSkin, [NewSkin|R] ++ Acc};
                _ ->  % T 不能进阶
                    ?THROW_ERR(?ERROR_MAGIC_WEAPON_SKIN_001)
            end;
        _ -> % T 不是同一种皮肤  就看剩余列表里面有有没有
            add_skin2(MagicWeaponID, AddNum, R, [Skin|Acc])
    end.

add_skin3(Skin, 0, AccFlag) ->
    {AccFlag, Skin};
add_skin3(Skin, AddNum, AccFlag) ->
    #p_kv{id = ID, val = Num} = Skin, % Num 是已经消耗的进阶道具数量
    NewID = ID + 1,
    case lib_config:find(cfg_magic_weapon_skin, NewID) of
        [_NextConfig] -> % T 可以进阶
            [#c_magic_weapon_skin{item_num = NeedNum}] = lib_config:find(cfg_magic_weapon_skin, ID), % T 进阶据需要消耗的道具数item_num
            Num2 = Num + 1,
            {AccFlag2, NewSkin} = ?IF(Num2 >= NeedNum, {true, #p_kv{id = NewID, val = 0}}, {false, Skin#p_kv{val = Num2}}),
            add_skin3(NewSkin, AddNum - 1, AccFlag2);
        _ -> % T 不能再进阶啦
            {AccFlag, Skin}
    end.

handle({#m_magic_weapon_change_tos{cur_id = MagicWeaponID}, RoleID, _PID}, State) ->
    do_change(RoleID, MagicWeaponID, State);  % T 换法宝
handle({#m_magic_weapon_skin_level_tos{id = MagicWeaponID, num = Num}, RoleID, _PID}, State) ->
    do_level_up(RoleID, MagicWeaponID, Num, State).

do_change(RoleID, MagicWeaponID, State) ->
    case catch check_can_change(MagicWeaponID, State) of
        {ok, State2} ->
            State3 = mod_role_skin:update_skin(State2),
            common_misc:unicast(RoleID, #m_magic_weapon_change_toc{cur_id = MagicWeaponID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_magic_weapon_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(MagicWeaponID, State) ->
    #r_role{role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{cur_id = CurID, skin_list = SkinList} = RoleMagicWeapon,
    ?IF(MagicWeaponID =:= CurID, ?THROW_ERR(?ERROR_MAGIC_WEAPON_CHANGE_001), ok),
    ?IF(lists:keymember(MagicWeaponID, #p_kv.id, SkinList), ok, ?THROW_ERR(?ERROR_MAGIC_WEAPON_CHANGE_002)),
    RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{cur_id = MagicWeaponID},
    {ok, State#r_role{role_magic_weapon = RoleMagicWeapon2}}.

%% @doc 法宝皮肤【升级】(有的皮肤只可以升级有的皮肤只可以升阶)
do_level_up(RoleID, MagicWeaponID, Num, State) ->
    case catch check_level_up(MagicWeaponID, Num, State) of
        {ok, BagDoings, Level, NewSkin, State2} ->
            common_misc:unicast(RoleID, #m_magic_weapon_skin_level_toc{skin = NewSkin}),
            State3 = mod_role_bag:do(BagDoings, State2),
            NewID = NewSkin#p_kv.id,
            case MagicWeaponID =/= NewID of
                true -> %% 升级
                    State4 = do_magic_weapon_skin_skill(MagicWeaponID, NewSkin#p_kv.id, Level, State3),
                    mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_MAGIC_WEAPON_SKIN, NewSkin#p_kv.id);
                _ ->
                    State3
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_magic_weapon_skin_level_toc{err_code = ErrCode}),
            State
    end.

check_level_up(FrontMagicWeaponID, Num, State) ->
    #r_role{role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{level = Level, skin_list = SkinList} = RoleMagicWeapon,
    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {Skin, SkinList2} = check_level_up2(SkinList, get_base_id(FrontMagicWeaponID), []),
    #p_kv{id = MagicWeaponID, val = OldExp} = Skin,
    NextMagicWeaponID = MagicWeaponID + 1,
    case lib_config:find(cfg_magic_weapon_skin, NextMagicWeaponID) of  % T -----2------看看可不可以升级该皮肤
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_MAGIC_WEAPON_SKIN_LEVEL_001) % T 不能再升级该皮肤的错误
    end,
    [#c_magic_weapon_skin{type = Type, exp_item = ExpItem}] = lib_config:find(cfg_magic_weapon_skin, MagicWeaponID),
    ?IF(Type =:= ?MAGIC_WEAPON_SKIN_LEVEL_UP, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    #c_item{effect_args = ExpString} = mod_role_item:get_item_config(ExpItem),
    OneExp = lib_tool:to_integer(ExpString),
    SumExp = OldExp + OneExp * Num,
    {MagicWeaponID2, Exp2, RemainExp} = get_level_exp(MagicWeaponID, SumExp),
    RemainNum = RemainExp div OneExp,
    ReduceNum = erlang:max(1, Num - RemainNum),
    BagDoings = mod_role_bag:check_num_by_type_id(ExpItem, ReduceNum, ?ITEM_REDUCE_MAGIC_WEAPON_LEVEL_UP, State),
    NewSkin = Skin#p_kv{id = MagicWeaponID2, val = Exp2},
    NewSkinList = [NewSkin|SkinList2],
    RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{skin_list = NewSkinList},
    State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
    {ok, BagDoings, Level, NewSkin, State2}.

check_level_up2([], _BaseID, _Acc) ->
    ?THROW_ERR(?ERROR_ITEM_USE_008);
check_level_up2([Skin|R], BaseID, Acc) ->
    #p_kv{id = SkinID} = Skin,
    case get_base_id(SkinID) =:= BaseID of
        true ->
            {Skin, Acc ++ R};
        _ ->
            check_level_up2(R, BaseID, [Skin|Acc])
    end.

get_level_exp(MagicWeaponID, SumExp) ->
    case lib_config:find(cfg_magic_weapon_skin, MagicWeaponID) of
        [#c_magic_weapon_skin{exp_need = NeedExp}] ->
            case lib_config:find(cfg_magic_weapon_skin, MagicWeaponID + 1) of
                [#c_magic_weapon_skin{}] ->
                    ?IF(SumExp >= NeedExp, get_level_exp(MagicWeaponID + 1, SumExp - NeedExp), {MagicWeaponID, SumExp, 0});
                _ ->
                    {MagicWeaponID, 0, SumExp}
            end;
        _ ->
            {MagicWeaponID, 0, SumExp}
    end.

gm_magic_weapon_skin_id(MagicWeaponID, State) ->
    #r_role{role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_magic_weapon{level = Level, skin_list = SkinList} = RoleMagicWeapon,
    case lib_config:find(cfg_magic_weapon_skin, MagicWeaponID) of
        [#c_magic_weapon_skin{}] ->
            BaseID = get_base_id(MagicWeaponID),
            SkinList2 = [ SkinList || #p_kv{id = OldID} <- SkinList, get_base_id(OldID) =/= BaseID],
            Skin = #p_kv{id = MagicWeaponID, val = 0},
            SkinList3 = [Skin|SkinList2],
            RoleMagicWeapon2 = RoleMagicWeapon#r_role_magic_weapon{skin_list = SkinList3},
            State2 = State#r_role{role_magic_weapon = RoleMagicWeapon2},
            State3 = do_magic_weapon_skin_skill(0, MagicWeaponID, Level, State2),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MAGIC_WEAPON_SKIN, MagicWeaponID);
        _ ->
            State
    end.

%% 升级导致技能变化
do_level_skill(OldLevel, NewLevel, State) ->
    OldSkills = get_level_skill(OldLevel),
    NewSkills = get_level_skill(NewLevel),
    case OldSkills =/= NewSkills of
        true ->
            role_misc:skill_broadcast(NewSkills -- OldSkills, ?NOTICE_MAGIC_WEAPON_SKILL_OPEN, State), % T  法宝技能解锁
            SkinSkills = get_skin_skill_by_state(State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_MAGIC, SkinSkills ++ NewSkills, State); %% 新增--》法宝技能
        _ ->
            State
    end.

%% 皮肤变化导致技能改变
do_magic_weapon_skin_skill(OldID, NewID, Level, State) ->
    OldSkills = get_magic_weapon_skin_skills(OldID),
    NewSkills = get_magic_weapon_skin_skills(NewID),
    case OldSkills =/= NewSkills of
        true ->
            LevelSkills = get_level_skill(Level),
            SurfaceSkills = get_skin_skill_by_state(State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_MAGIC, SurfaceSkills ++ LevelSkills, State);
        _ ->
            State
    end.

%% 获取法宝等级对应的技能
get_level_skill(0) ->
    [];
get_level_skill(Level) ->
    [#c_magic_weapon_level{skill_list = SkillList}] = lib_config:find(cfg_magic_weapon_level, Level),
    SkillList.

get_base_id(MagicWeaponID) ->
    MagicWeaponID div 1000.


%% 法宝【皮肤】进阶带来的技能
get_magic_weapon_skin_skills(0) ->
    [];
get_magic_weapon_skin_skills(ID) ->
    [#c_magic_weapon_skin{skill_list = Skills}] = lib_config:find(cfg_magic_weapon_skin, ID),
    lists:sort(Skills).

%% 拿到法宝【所有】皮肤的技能ID
get_skin_skill_by_state(State) ->
    #r_role{role_magic_weapon = #r_role_magic_weapon{skin_list = SkinList}} = State,
    lists:sort(lists:flatten([get_magic_weapon_skin_skills(SkinID) || #p_kv{id = SkinID} <- SkinList])).

get_base_skins(undefined) ->
    [];
get_base_skins(RoleMagicWeapon) ->
    #r_role_magic_weapon{skin_list = SkinList} = RoleMagicWeapon,
    [get_base_id(SurfaceID) || #p_kv{id = SurfaceID} <- SkinList].

get_magic_weapon_level(State) ->
    #r_role{role_magic_weapon = #r_role_magic_weapon{level = Level}} = State,
    Level.