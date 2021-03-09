%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     7日目标
%%% @end
%%% Created : 21. 十二月 2018 9:49
%%%-------------------------------------------------------------------
-module(mod_role_day_target).
-author("laijichang").
-include("act.hrl").
-include("role.hrl").
-include("copy.hrl").
-include("day_target.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_day_target.hrl").

%% API
-export([
    init/1,
    online/1,
    day_reset/1,
    zero/1,
    handle/2
]).

-export([
    gm_set_all/1,
    gm_reset_all/1
]).

-export([
    level_up/1,
    god_weapon_level_up/1,
    wing_level_up/1,
    magic_weapon_level_up/1,
    nature_refine/1,
    equip_concise_num/1,
    nature_hole_num/1,
    mount_step/1,
    pet_step/1,
    load_guard/1,
    copy_tower/1,
    copy_five_elements/1,
    daily_active/1,

    buy_shop_item/3,

    use_item/3,

    ring_mission/1,
    copy_exp/1,
    activity_answer/1,
    offline_solo/1,
    copy_team/1,
    family_escort/1,
    kill_world_boss/2,
    world_boss_owner/1,
    demon_boss/1,
    demon_boss_owner/1,
    copy_pet/1,
    copy_immortal/1,
    world_boss_time/1,
    add_copy_exp_times/1,
    family_box/2,
    suit_up/1,
    pet_star/1,
    stone_compose/1,
    skill_up/1,
    buy_world_boss_times/2,
    compose_equip/1,
    compose_jewelry/1,
    auction_buy/1,
    act_rank_buy/1,
    auction_sell/1,
    refine_nat_intensify/2,
    bless/2,

    thunder_active/1,
    thunder_step/1,

    war_spirit_armor/1,
    war_spirit_equip/1,

    nature_color/1,
    nature_refine_num/1,

    stone_level_num/1
]).

-export([
    function_open/1
]).

init(#r_role{role_id = RoleID, role_day_target = undefined} = State) ->
    RoleDayTarget = #r_role_day_target{role_id = RoleID},
    State#r_role{role_day_target = RoleDayTarget};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_day_target = RoleDayTarget} = State,
    #r_role_day_target{
        day_target_list = DayTargetList,
        reward_list = RewardList,
        progress_reward_list = ProgressList} = RoleDayTarget,
    case mod_role_act:is_act_open2(?ACT_DAY_TARGET, State) of
        true ->
            DataRecord = #m_day_target_info_toc{
                conditions = DayTargetList,
                reward_list = RewardList,
                progress_reward_list = ProgressList
            },
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end,
    State.

zero(#r_role{role_day_target = undefined} = State) ->
    State;
zero(State) ->
    online(State).

day_reset(State) ->
    update_day_target(State).

function_open(State) ->
    update_day_target(State).

update_day_target(State) ->
    #r_role{role_id = RoleID, role_day_target = RoleDayTarget, role_private_attr = RolePrivateAttr} = State,
    #r_role_private_attr{create_time = CreateTime} = RolePrivateAttr,
    #r_role_day_target{day_target_list = DayTargetList, reward_list = RewardList} = RoleDayTarget,
    case mod_role_act:is_act_open2(?ACT_DAY_TARGET, State) of
        true ->
%%            NowDay = common_config:get_open_days(),
            Now = time_tool:now(),
            DiffDays = time_tool:diff_date(Now, CreateTime) + 1,
            ConfigList = lib_config:list(cfg_seven_day_target),
            DayTargetIDs = [ NowID || #p_kdv{id = NowID} <- DayTargetList],
            UpdateDayTargets = get_update_day_target(ConfigList, DiffDays, DayTargetIDs ++ RewardList, State, []),
            DayTargetList2 = UpdateDayTargets ++ DayTargetList,
            common_misc:unicast(RoleID, #m_day_target_condition_toc{condition = DayTargetList2}),
            RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = DayTargetList2},
            State#r_role{role_day_target = RoleDayTarget2};
        _ ->
            RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = []},
            State#r_role{role_day_target = RoleDayTarget2}
    end.

get_update_day_target([], _NowDay, _HasIDs, _State, UpdateAcc) ->
    UpdateAcc;
get_update_day_target([{ID, Config}|R], NowDay, HasIDs, State, UpdateAcc) ->
    #c_seven_day_target{day = ConfigDay} = Config,
    case not lists:member(ID, HasIDs) andalso ConfigDay =< NowDay of
        true -> %% 可以新增
            DayTarget = #p_kdv{id = ID, val = 0},
            {_IsUpdate, UpdateDayTarget} = update_val3(DayTarget, Config, State),
            get_update_day_target(R, NowDay, HasIDs, State, [UpdateDayTarget|UpdateAcc]);
        _ ->
            get_update_day_target(R, NowDay, HasIDs, State, UpdateAcc)
    end.

level_up(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_ARGS_ROLE_LEVEL, false, State).

god_weapon_level_up(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_GOD_WEAPON_LEVEL, false, State).

wing_level_up(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_WING_LEVEL, false, State).

magic_weapon_level_up(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_MAGIC_WEAPON_LEVEL, false, State).

nature_refine(State) ->
    State2 = update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_NATURE_REFINE_LEVEL, false, State),
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_NATURE_REFINE, 1, State2).

equip_concise_num(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_EQUIP_CONCISE_NUM, false, State).

nature_hole_num(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_NATURE_HOLE_NUM, false, State).

mount_step(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_MOUNT_STEP, false, State).

pet_step(State) ->
    State2 = update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_PET_STEP, false, State),
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_PET_UP_STEP, 1, State2).

load_guard(State) ->
    State2 = update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_GUARD_ELF, false, State),
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_GUARD_FAIRY, false, State2).

copy_tower(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_COPY_TOWER, false, State).

copy_five_elements(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_COPY_FIVE_ELEMENTS, false, State).

daily_active(State) ->
    update_val(?DAY_TARGET_TYPE_VALUE_REACH, ?DAY_TARGET_DAILY_ACTIVE, false, State).


buy_shop_item(ShopID, Num, State) ->
    add_val(?DAY_TARGET_TYPE_SHOP_BUY, ShopID, Num, State).


use_item(TypeID, Num, State) ->
    add_val(?DAY_TARGET_TYPE_USE_ITEM, TypeID, Num, State).

ring_mission(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_MISSION_TYPE_RING, 1, State).

copy_exp(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COPY_EXP, 1, State).

activity_answer(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_ANSWER, 1, State).

offline_solo(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_OFFLINE_SOLO, 1, State).

copy_team(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COPY_TEAM, 1, State).

family_escort(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_FAMILY_ESCORT, 1, State).

kill_world_boss(TypeID, State) ->
    [#c_world_boss{type = Type}] = lib_config:find(cfg_world_boss, TypeID),
    case Type of
        ?BOSS_TYPE_WORLD_BOSS ->
            add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_WORLD_BOSS, 1, State);
        ?BOSS_TYPE_FAMILY ->
            add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_CAVE_BOSS, 1, State);
        ?BOSS_TYPE_PERSONAL ->
            add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_PERSONAL_BOSS, 1, State);
        _ ->
            State
    end.

world_boss_owner(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_WORLD_BOSS_OWNER, 1, State).

demon_boss(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_DEMON_BOSS, 1, State).

demon_boss_owner(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_DEMON_BOSS_OWNER, 1, State).

copy_pet(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COPY_PET, 1, State).

copy_immortal(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COPY_IMMORTAL, 1, State).

world_boss_time(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_WORLD_BOSS_TIME, 1, State).

add_copy_exp_times(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_ADD_COPY_EXP_TIMES, 1, State).

family_box(AddTimes, State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_FAMILY_BOX, AddTimes, State).

suit_up(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_SUIT_UP, 1, State).

pet_star(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_PET_STAR, 1, State).

stone_compose(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_STONE_COMPOSE, 1, State).

skill_up(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_SKILL_UP, 1, State).

buy_world_boss_times(BuyNum, State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_BUY_WORLD_BOSS_TIMES, BuyNum, State).

compose_equip(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COMPOSE_EQUIP, 1, State).

compose_jewelry(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_COMPOSE_JEWELRY, 1, State).

auction_buy(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_AUCTION_BUY, 1, State).

act_rank_buy(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_ACT_RANK_BUY, 1, State).

auction_sell(State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_AUCTION_SELL, 1, State).

refine_nat_intensify(AddNum, State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_REFINE_NAT_INTENSIFY, AddNum, State).

bless(AddNum, State) ->
    add_val(?DAY_TARGET_TYPE_ADD_COUNTER, ?DAY_TARGET_BLESS, AddNum, State).

thunder_active(State) ->
    update_val(?DAY_TARGET_TYPE_THUNDER_ACTIVE_NUM, 0, true, State).

thunder_step(State) ->
    update_val(?DAY_TARGET_TYPE_THUNDER_SUIT, 0, true, State).

war_spirit_armor(State) ->
    update_val(?DAY_TARGET_TYPE_WAR_SPIRIT_ARMOR, 0, true, State).

war_spirit_equip(State) ->
    update_val(?DAY_TARGET_TYPE_WAR_SPIRIT_EQUIP, 0, true, State).

nature_color(State) ->
    update_val(?DAY_TARGET_TYPE_NATURE_COLOR, 0, true, State).

nature_refine_num(State) ->
    update_val(?DAY_TARGET_TYPE_NATURE_REFINE_LEVEL, 0, true, State).

stone_level_num(State) ->
    update_val(?DAY_TARGET_TYPE_STONE_PUNCH, 0, true, State).

%% 增加次数的行为
add_val(Type, Args, Times, State) ->
    State2 = mod_role_act_esoterica:gather_esoterica_task(Args, State),
    #r_role{role_id = RoleID, role_day_target = RoleDayTarget} = State2,
    #r_role_day_target{day_target_list = DayTargetList} = RoleDayTarget,
    {UpdateAcc2, DayTargetList2} = add_val2(DayTargetList, Type, Args, Times, [], []),
    case UpdateAcc2 =/= [] of
        true ->
            common_misc:unicast(RoleID, #m_day_target_condition_toc{condition = UpdateAcc2}),
            RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = DayTargetList2},
            State2#r_role{role_day_target = RoleDayTarget2};
        _ ->
            State2
    end.

add_val2([], _Type, _Args, _Times, UpdateAcc, DayTargetAcc) ->
    {UpdateAcc, DayTargetAcc};
add_val2([#p_kdv{id = ID, val = OldVal} = DayTarget|R], Type, Args, AddTimes, UpdateAcc, DayTargetAcc) ->
    case lib_config:find(cfg_seven_day_target, ID) of
        [#c_seven_day_target{type = ConfigType, args = ConfigArgs, val = MaxTimes}] ->
            case Type =:= ConfigType andalso Args =:= ConfigArgs of
                true ->
                    case OldVal >= MaxTimes of
                        true -> %% 已经是最大次数，不用更新
                            add_val2(R, Type, Args, AddTimes, UpdateAcc, [DayTarget|DayTargetAcc]);
                        _ ->
                            DayTarget2 = DayTarget#p_kdv{val = erlang:min(MaxTimes, OldVal + AddTimes)},
                            add_val2(R, Type, Args, AddTimes, [DayTarget2|UpdateAcc], [DayTarget2|DayTargetAcc])
                    end;
                _ ->
                    add_val2(R, Type, Args, AddTimes, UpdateAcc, [DayTarget|DayTargetAcc])
            end;
        _ -> %% 兼容ID被删除的情况
            add_val2(R, Type, Args, AddTimes, UpdateAcc, DayTargetAcc)
    end.

update_val(Type, Args, IsIgnoreArgs, State) ->
    State2 = mod_role_act_esoterica:gather_esoterica_task(Args, State),
    #r_role{role_id = RoleID, role_day_target = RoleDayTarget} = State2,
    #r_role_day_target{day_target_list = DayTargetList} = RoleDayTarget,
    {UpdateAcc2, DayTargetList2} = update_val2(DayTargetList, Type, Args, IsIgnoreArgs, State, [], []),
    case UpdateAcc2 =/= [] of
        true ->
            common_misc:unicast(RoleID, #m_day_target_condition_toc{condition = UpdateAcc2}),
            RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = DayTargetList2},
            State2#r_role{role_day_target = RoleDayTarget2};
        _ ->
            State2
    end.

update_val2([], _Type, __Args, _IsIgnoreArgs, _State, UpdateAcc, DayTargetAcc) ->
    {UpdateAcc, DayTargetAcc};
update_val2([#p_kdv{id = ID} = DayTarget|R], Type, Args, IsIgnoreArgs, State, UpdateAcc, DayTargetAcc) ->
    case lib_config:find(cfg_seven_day_target, ID) of
        [#c_seven_day_target{type = ConfigType, args = ConfigArgs} = Config] ->
            case Type =:= ConfigType andalso (IsIgnoreArgs orelse Args =:= ConfigArgs) of
                true ->
                    {IsUpdate, DayTarget2} = update_val3(DayTarget, Config, State),
                    UpdateAcc2 = ?IF(IsUpdate, [DayTarget2|UpdateAcc], UpdateAcc),
                    update_val2(R, Type, Args, IsIgnoreArgs, State, UpdateAcc2, [DayTarget2|DayTargetAcc]);
                _ ->
                    update_val2(R, Type, Args, IsIgnoreArgs, State, UpdateAcc, [DayTarget|DayTargetAcc])
            end;
        _ -> %% 兼容ID被删除的情况
            update_val2(R, Type, Args, IsIgnoreArgs, State, UpdateAcc, DayTargetAcc)
    end.

update_val3(DayTarget, Config, State) ->
    #p_kdv{val = OldVal} = DayTarget,
    NewVal =
        case catch get_day_target_condition(Config, State) of
            NewValT when erlang:is_integer(NewValT) ->
                NewValT;
            Error ->
                ?ERROR_MSG("Error : ~w", [Error]),
                0
        end,
    case NewVal > OldVal of
        true ->
            {true, DayTarget#p_kdv{val = NewVal}};
        _ ->
            {false, DayTarget}
    end.

get_day_target_condition(Config, State) ->
    #c_seven_day_target{
        type = Type,
        args = Args,
        val = MaxTimes
    } = Config,
    Value =
        case Type of
            ?DAY_TARGET_TYPE_VALUE_REACH ->
                get_type_value_reach_condition(Args, State);
            ?DAY_TARGET_TYPE_THUNDER_ACTIVE_NUM ->
                mod_role_suit:get_thunder_active_num(State);
            ?DAY_TARGET_TYPE_THUNDER_SUIT ->
                mod_role_suit:get_thunder_gradation_num(Args, State);
            ?DAY_TARGET_TYPE_WAR_SPIRIT_ARMOR ->
                mod_role_confine:get_armor_orange_step_num(Args, State);
            ?DAY_TARGET_TYPE_WAR_SPIRIT_EQUIP ->
                mod_role_confine:get_equip_orange_step_num(Args, State);
            ?DAY_TARGET_TYPE_NATURE_COLOR ->
                mod_role_nature:get_color_num(Args, State);
            ?DAY_TARGET_TYPE_NATURE_REFINE_LEVEL ->
                mod_role_nature:get_refine_level_num(Args, State);
            ?DAY_TARGET_TYPE_STONE_PUNCH ->
                mod_role_equip:get_stone_level_num(Args, State);
            _ ->
                0
        end,
    erlang:min(Value, MaxTimes).

get_type_value_reach_condition(Args, State) ->
    case Args of
        ?DAY_TARGET_ARGS_ROLE_LEVEL ->
            mod_role_data:get_role_level(State);
        ?DAY_TARGET_GOD_WEAPON_LEVEL ->
            mod_role_god_weapon:get_god_weapon_level(State);
        ?DAY_TARGET_WING_LEVEL ->
            mod_role_wing:get_wing_level(State);
        ?DAY_TARGET_MAGIC_WEAPON_LEVEL ->
            mod_role_magic_weapon:get_magic_weapon_level(State);
        ?DAY_TARGET_NATURE_REFINE_LEVEL ->
            mod_role_nature:get_nature_refine_level(State);
        ?DAY_TARGET_EQUIP_CONCISE_NUM ->
            mod_role_equip:get_equip_concise_num(State);
        ?DAY_TARGET_NATURE_HOLE_NUM ->
            mod_role_nature:get_nature_hole_num(State);
        ?DAY_TARGET_MOUNT_STEP ->
            mod_role_mount:get_mount_step(State);
        ?DAY_TARGET_PET_STEP ->
            mod_role_pet:get_pet_step(State);
        ?DAY_TARGET_GUARD_ELF ->
            ?BOOL2INT(mod_role_guard:is_guard_elf_active(State));
        ?DAY_TARGET_GUARD_FAIRY ->
            ?BOOL2INT(mod_role_guard:is_guard_fairy_active(State));
        ?DAY_TARGET_COPY_TOWER ->
            ?GET_TOWER_FLOOR(mod_role_copy:get_cur_tower_id(State));
        ?DAY_TARGET_COPY_FIVE_ELEMENTS ->
            ?GET_TOWER_FLOOR(mod_role_copy:get_five_elements_big_floor(State));
        ?DAY_TARGET_DAILY_ACTIVE ->
            mod_role_daily_liveness:get_daily_liveness(State);
        _ ->
            0
    end.

gm_set_all(State) ->
    #r_role{role_id = RoleID, role_day_target = RoleDayTarget} = State,
    #r_role_day_target{day_target_list = DayTargetList} = RoleDayTarget,
    DayTargetList2 =
        [ begin
              #p_kdv{id = ID} = DayTarget,
              [#c_seven_day_target{val = Val}] = lib_config:find(cfg_seven_day_target, ID),
              DayTarget#p_kdv{val = Val}
          end|| DayTarget <- DayTargetList],
    RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = DayTargetList2},
    common_misc:unicast(RoleID, #m_day_target_condition_toc{condition = DayTargetList2}),
    State2 = State#r_role{role_day_target = RoleDayTarget2},
    State2.

gm_reset_all(State) ->
    #r_role{role_day_target = RoleDayTarget} = State,
    State2 = State#r_role{role_day_target = RoleDayTarget#r_role_day_target{day_target_list = [], reward_list = []}},
    State3 = day_reset(State2),
    online(State3).

handle({#m_day_target_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_day_target_reward(RoleID, ID, State);
handle({#m_day_target_progress_tos{progress = Progress}, RoleID, _PID}, State) ->
    do_day_target_progress(RoleID, Progress, State);
handle(Info, State) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]),
    State.



%%%===================================================================
%%% internal functions
%%%===================================================================
%% 获取单个id奖励
do_day_target_reward(RoleID, ID, State) ->
    case catch check_target_reward(ID, State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_day_target_reward_toc{id = ID}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_day_target_reward_toc{err_code = ErrCode}),
            State
    end.

check_target_reward(ID, State) ->
    #r_role{role_day_target = RoleDayTarget} = State,
    #r_role_day_target{
        day_target_list = DayTargetList,
        reward_list = RewardList} = RoleDayTarget,
    ?IF(mod_role_act:is_act_open2(?ACT_DAY_TARGET, State), ok, ?THROW_ERR(?ERROR_DAY_TARGET_REWARD_001)),
    ?IF(lists:member(ID, RewardList), ?THROW_ERR(?ERROR_DAY_TARGET_REWARD_003), ok),
    [#c_seven_day_target{
        val = NeedVal,
        reward = Reward}] = lib_config:find(cfg_seven_day_target, ID),
    DayTargetList2 =
        case lists:keytake(ID, #p_kdv.id, DayTargetList) of
            {value, #p_kdv{val = Val}, DayTargetListT} when Val >= NeedVal ->
                DayTargetListT;
            _ ->
                ?THROW_ERR(?ERROR_DAY_TARGET_REWARD_002)
        end,
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_DAY_TARGET_REWARD, GoodsList}],
    RoleDayTarget2 = RoleDayTarget#r_role_day_target{day_target_list = DayTargetList2, reward_list = [ID|RewardList]},
    State2 = State#r_role{role_day_target = RoleDayTarget2},
    {ok, BagDoings, State2}.

%% 获取进度奖励
do_day_target_progress(RoleID, Progress, State) ->
    case catch check_target_progress(Progress, State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_day_target_progress_toc{progress = Progress}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_day_target_progress_toc{err_code = ErrCode}),
            State
    end.

check_target_progress(Progress, State) ->
    #r_role{role_day_target = RoleDayTarget} = State,
    #r_role_day_target{
        reward_list = RewardList,
        progress_reward_list = ProgressList} = RoleDayTarget,
    ?IF(mod_role_act:is_act_open2(?ACT_DAY_TARGET, State), ok, ?THROW_ERR(?ERROR_DAY_TARGET_PROGRESS_001)),
    ?IF(lists:member(Progress, ProgressList), ?THROW_ERR(?ERROR_DAY_TARGET_PROGRESS_003), ok),
    [Reward] = lib_config:find(cfg_day_target_progress, Progress),
    ?IF(get_day_target_progress(RewardList) >= Progress, ok, ?THROW_ERR(?ERROR_DAY_TARGET_PROGRESS_002)),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_DAY_TARGET_PROGRESS, GoodsList}],
    RoleDayTarget2 = RoleDayTarget#r_role_day_target{progress_reward_list = [Progress|ProgressList]},
    State2 = State#r_role{role_day_target = RoleDayTarget2},
    {ok, BagDoings, State2}.



%%%===================================================================
%%% 通用
%%%===================================================================
get_day_target_progress(List) ->
    get_day_target_progress(List, 0).

get_day_target_progress([], Acc) ->
    Acc;
get_day_target_progress([ID|R], Acc) ->
    [#c_seven_day_target{add_progress = AddProgress}] = lib_config:find(cfg_seven_day_target, ID),
    get_day_target_progress(R, AddProgress + Acc).