%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十二月 2018 20:02
%%%-------------------------------------------------------------------
-module(mod_role_bg_act).
-author("WZP").
-include("proto/mod_role_bg_act.hrl").
-include("role.hrl").
-include("bg_act.hrl").
-include("role_extra.hrl").
%% API
-export([
    pre_online/1,
    handle/2,
    day_reset/1,
    pay/2,
    consume/3,
    level_up/3
]).

-export([
    is_bg_act_open/2,
    is_bg_act_open_i/2
]).


handle(consume_rank_update, State) ->
    case is_bg_act_open_i(?BG_ACT_CONSUME_RANK, State) of
        false ->
            State;
        BgInfo ->
            mod_role_bg_summer:consume_rank_update(State, BgInfo)
    end;
handle({bg_act_bc, ID, IsInit}, State) ->
    bg_act_open(State, ID, IsInit);
handle({bg_act_init, ID}, State) ->
    BgAct = world_bg_act_server:get_bg_act(ID),
    init_bg_act_after_check(State, BgAct);
handle({config_list_change, ID, IsBc, AddConfigList, DelConfigList, UpdateConfigList}, State) ->
    bg_act_config_list_change(State, ID, IsBc, AddConfigList, DelConfigList, UpdateConfigList);
handle({#m_bg_act_reward_tos{id = ID, entry = Entry}, RoleID, _PID}, State) ->
    do_act_acc_pay_reward(RoleID, ID, Entry, State).



pre_online(#r_role{role_id = RoleID} = State) ->
    BgActList = world_bg_act_server:get_open_bg_act_front(State),
    State2 = lists:foldl(
        fun(#r_bg_act{id = ID, edit_time = Time} = Info, StateAcc) ->
            NeedInit = not check_edit_time(ID, Time, StateAcc),
            if
                NeedInit ->
                    init_bg_act(StateAcc, Info);
                true ->%%上线更新Role活动信息
                    case ID of
                        ?BG_ACT_REGRESSION ->
                            StateAcc2 = mod_role_bg_act_feast:trigger(StateAcc, ?BG_LOGIN, 0, false),
                            #r_role_attr{last_offline_time = Time1} = StateAcc2#r_role.role_attr,
                            #r_role_private_attr{last_login_time = Time2} = StateAcc2#r_role.role_private_attr,
                            mod_role_bg_act_feast:trigger(StateAcc2, ?BG_REGRESSION, Time2 - Time1, false);
                        ?BG_ACT_FEAST_ENTRY ->
                            mod_role_bg_act_feast:act_entry_day_reset(StateAcc);
                        ?BG_ACT_RECHARGE_REWARD ->
                            mod_role_bg_summer:day_reset_recharge(StateAcc);
                        _ ->
                            StateAcc
                    end
            end
        end, State, BgActList),
    {PBgActList, State3} = get_p_bg_act_or_bc_info(BgActList, State2),
    ?IF(PBgActList =/= [], common_misc:unicast(RoleID, #m_bg_act_update_toc{act_list = PBgActList}), ok),
    State3.

check_edit_time(ID, Time, State) ->
    case ID of
        ?BG_ACT_FEAST_ENTRY ->
            #r_role{role_act_feast = RoleActFeast} = State,
            RoleActFeast#r_role_act_feast.entry_time =:= Time;
        ?BG_ACT_ACC_PAY ->
            #r_role{role_act_feast = RoleActFeast} = State,
            RoleActFeast#r_role_act_feast.pay_time =:= Time;
        ?BG_ACT_REGRESSION ->
            #r_role{role_act_feast = RoleActFeast} = State,
            RoleActFeast#r_role_act_feast.regression_time =:= Time;
        ?BG_ACT_ACC_CONSUME ->
            #r_role{role_act_feast = RoleActFeast} = State,
            RoleActFeast#r_role_act_feast.consume_time =:= Time;
        ?BG_ACT_RECHARGE ->
            #r_role{role_act_feast = RoleActFeast} = State,
            RoleActFeast#r_role_act_feast.recharge_reward_time =:= Time;
        ?BG_ACT_STORE ->
            #r_role{role_bg_act_store = RoleActStore} = State,
            RoleActStore#r_role_bg_store.store_time =:= Time;
        ?BG_ACT_TREVI_FOUNTAIN ->
            #r_role{role_trevi_fountain = RoleTF} = State,
            RoleTF#r_role_trevi_fountain.edit_time =:= Time;
        ?BG_ACT_ALCHEMY ->
            #r_role{role_bg_alchemy = RoleAlchemy} = State,
            RoleAlchemy#r_role_bg_alchemy.edit_time =:= Time;
        ?BG_ACT_RECHARGE_TURNTABLE ->
            #r_role{role_bg_turntable = RoleTurnTable} = State,
            RoleTurnTable#r_role_bg_turntable.edit_time_b =:= Time;
        ?BG_ACT_ACTIVE_TURNTABLE ->
            #r_role{role_bg_turntable = RoleTurnTable} = State,
            RoleTurnTable#r_role_bg_turntable.edit_time_a =:= Time;
        ?BG_ACT_TREASURE_TROVE ->
            #r_role{role_bg_tt = RoleTreasureTrove} = State,
            RoleTreasureTrove#r_role_bg_tt.tta_edit_time =:= Time;
        ?BG_ACT_SECRET_TERRITORY ->
            #r_role{role_bg_tt = RoleTreasureTrove} = State,
            RoleTreasureTrove#r_role_bg_tt.ttb_edit_time =:= Time;
        ?BG_ACT_ST_STORE ->
            #r_role{role_bg_tt = RoleTreasureTrove} = State,
            RoleTreasureTrove#r_role_bg_tt.ttc_edit_time =:= Time;
        ?BG_ACT_RECHARGE_REWARD ->
            SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
            SummerExtra#r_summer_extra.recharge_edit_time =:= Time;
        ?BG_ACT_CONSUME_RANK ->
            BgSummer = mod_role_extra:get_data(?EXTRA_KEY_BG_SUMMER, #r_bg_summer{}, State),
            BgSummer#r_bg_summer.rank_edit_time =:= Time;
        ?BG_ACT_RECHARGE_PACKET ->
            #r_role_bg_recharge_package{edit_time = EditTime} = mod_role_extra:get_data(?EXTRA_KEY_BG_WEEK_TWO, #r_role_bg_recharge_package{}, State),
            EditTime =:= Time;
        _ ->
            false
    end.

%% 此处更新信息会发送
day_reset(State) ->
    BgActList = world_bg_act_server:get_open_bg_act_back(State),
    lists:foldl(
        fun(#r_bg_act{id = ID}, StateAcc) ->
            case ID of
                ?BG_ACT_FEAST_ENTRY ->
                    %% mod_role_bg_act_feast:act_entry_day_reset(StateAcc);
                    erlang:send_after(1000, erlang:self(), {mod_role_bg_act_feast, act_entry_day_reset,[]}),
                    StateAcc;
                ?BG_ACT_RECHARGE_REWARD ->
%%                    mod_role_bg_summer:day_reset_recharge(StateAcc, BgInfo);
                    erlang:send_after(1000, erlang:self(), {mod_role_bg_summer, day_reset_recharge, []}),
                    StateAcc;
                _ ->
                    StateAcc
            end
        end, State, BgActList).


pay(PayGold, State) ->
    BgActList = world_bg_act_server:get_open_bg_act_back(State),
    lists:foldl(
        fun(Info, StateAcc) ->
            pay2(PayGold, Info, StateAcc)
        end, State, BgActList).

pay2(PayGold, Info, StateAcc) ->
    #r_bg_act{id = ID} = Info,
    case ID of
        ?BG_ACT_ACC_PAY ->
            mod_role_bg_act_feast:act_acc_pay_add(PayGold, StateAcc);
        ?BG_ACT_REGRESSION ->
            mod_role_bg_act_feast:trigger(StateAcc, ?BG_RECHARGE, PayGold, true);
        ?BG_ACT_RECHARGE ->
            mod_role_bg_act_feast:recharge(StateAcc);
        ?BG_ACT_RECHARGE_TURNTABLE ->
            mod_role_bg_turntable:recharge(StateAcc, PayGold);
        ?BG_ACT_RECHARGE_REWARD ->
            mod_role_bg_summer:pay(StateAcc, PayGold);
        ?BG_ACT_RECHARGE_PACKET ->
            mod_role_bg_extra:pay(StateAcc, Info, PayGold);
        _ ->
            StateAcc
    end.


consume(ConsumeGold, Action, State) ->
    BgActList = world_bg_act_server:get_open_bg_act_back(State),
    lists:foldl(
        fun(#r_bg_act{id = ID} = RBgInfo, StateAcc) ->
            case ID of
                ?BG_ACT_ACC_CONSUME ->
                    mod_role_bg_act_feast:act_acc_consume_add(ConsumeGold, StateAcc);
                ?BG_ACT_CONSUME_RANK ->
                    ?IF(Action =/= ?ASSET_GOLD_REDUCE_FROM_LUCKY_CAT, mod_role_bg_summer:consume(ConsumeGold, RBgInfo, StateAcc), StateAcc);
                _ ->
                    StateAcc
            end
        end, State, BgActList).

%%后台活动进程开启活动广播玩家
bg_act_open(#r_role{role_id = RoleID, role_attr = RoleAttr} = State, ID, IsInit) ->
    Info = world_bg_act_server:get_bg_act(ID),
    State2 = ?IF(IsInit, init_bg_act_after_check(State, Info), State),
    {PBgActList, State3} = get_p_bg_act_or_bc_info([Info], State2),
    ?IF(Info#r_bg_act.min_level =< RoleAttr#r_role_attr.level andalso PBgActList =/= [], common_misc:unicast(RoleID, #m_bg_act_update_toc{act_list = PBgActList}), ok),
    State3.


%%后台活动变更
bg_act_config_list_change(#r_role{role_attr = RoleAttr} = State, ID, IsBc, AddConfigList, DelConfigList, UpdateConfigList) ->
    #r_bg_act{min_level = MinLevel, edit_time = EditTime} = world_bg_act_server:get_bg_act(ID),
    case RoleAttr#r_role.role_act_level >= MinLevel of
        false ->
            State;
        _ ->
            case check_edit_time(ID, EditTime, State) of
                false ->
                    case ID of
                        ?BG_ACT_FEAST_ENTRY ->
                            mod_role_bg_act_feast:entry_config_list_change(State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList);
                        ?BG_ACT_ACC_PAY ->
                            mod_role_bg_act_feast:acc_pay_config_list_change(State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList);
                        ?BG_ACT_ACC_CONSUME ->
                            mod_role_bg_act_feast:acc_consume_config_list_change(State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList);
                        ?BG_ACT_REGRESSION ->
                            mod_role_bg_act_feast:regression_config_list_change(State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList);
%%                      ?BG_ACT_RECHARGE ->
%%                            mod_role_bg_act_feast:recharge_config_list_change(State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList);
%%                      ?BG_ACT_DOUBLE_EXP->
%%                          mod_role_bg_act_feast:init_doule(State);
%%                      ?BG_ACT_DOUBLE_COPY->
%%                          mod_role_bg_act_feast:init_feast_entry(State);
%%                      ?BG_ACT_BOSS_DROP->
%%                          mod_role_bg_act_feast:init_feast_entry(State);
                        _ ->
                            State
                    end;
                _ ->
                    State
            end
    end.


%%初始化活动信息
init_bg_act_after_check(State, #r_bg_act{id = ID, edit_time = EditTime} = BgAct) ->
    case check_edit_time(ID, EditTime, State) of
        false ->
            init_bg_act(State, BgAct);
        _ ->
            State
    end.

init_bg_act(State, #r_bg_act{id = ID, config_list = ConfigList, edit_time = EditTime, config = Config, start_date = StartDate}) ->
    case ID of
        ?BG_ACT_FEAST_ENTRY ->
            mod_role_bg_act_feast:init_feast_entry(State, ConfigList, EditTime, StartDate);
        ?BG_ACT_ACC_PAY ->
            mod_role_bg_act_feast:init_acc_pay(State, ConfigList, EditTime);
        ?BG_ACT_REGRESSION ->
            mod_role_bg_act_feast:init_feast_regression(State, ConfigList, EditTime);
        ?BG_ACT_ACC_CONSUME ->
            mod_role_bg_act_feast:init_acc_consume(State, ConfigList, EditTime);
        ?BG_ACT_RECHARGE ->
            mod_role_bg_act_feast:init_feast_recharge(State, EditTime);
        ?BG_ACT_STORE ->
            mod_role_bg_act_store:init_store(State, ConfigList, EditTime);
        ?BG_ACT_MISSION ->
            mod_role_bg_act_mission:init_mission(State, Config, EditTime);
        ?BG_ACT_TREVI_FOUNTAIN ->
            mod_role_trevi_fountain:init_trevi_fountain(State, ConfigList, EditTime);
        ?BG_ACT_ALCHEMY ->
            mod_role_bg_alchemy:init_alchemy(State, Config, EditTime);
        ?BG_ACT_RECHARGE_TURNTABLE ->
            mod_role_bg_turntable:init_recharge_turntable(State, ConfigList, EditTime);
        ?BG_ACT_ACTIVE_TURNTABLE ->
            mod_role_bg_turntable:init_active_turntable(State, ConfigList, EditTime);
        ?BG_ACT_TREASURE_TROVE ->
            mod_role_bg_treasure_trove:init_tta(State, EditTime);
        ?BG_ACT_SECRET_TERRITORY ->
            mod_role_bg_treasure_trove:init_ttb(State, EditTime);
        ?BG_ACT_ST_STORE ->
            mod_role_bg_treasure_trove:init_ttc(State, EditTime);
        ?BG_ACT_RECHARGE_REWARD ->
            mod_role_bg_summer:init_recharge(State, EditTime, ConfigList);
        ?BG_ACT_CONSUME_RANK ->
            mod_role_bg_summer:init_rank(State, EditTime);
        ?BG_ACT_RECHARGE_PACKET ->
            mod_role_bg_extra:init_recharge_package(State, EditTime, ConfigList);
        _ ->
            State
    end.


%%活动是否开启
is_bg_act_open(ID, State) ->
    #r_bg_act{min_level = MinLevel, status = Status} = world_bg_act_server:get_bg_act(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            Status =:= ?BG_ACT_STATUS_TWO
    end.

is_bg_act_open_i(ID, State) ->
    #r_bg_act{min_level = MinLevel, status = Status} = BgAct = world_bg_act_server:get_bg_act(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            case Status =:= ?BG_ACT_STATUS_TWO of
                true ->
                    BgAct;
                _ ->
                    false
            end
    end.


%%拿活动登录信息 或 直接发送  %%过滤不可视
get_p_bg_act_or_bc_info(List, State) ->
    get_p_bg_act_or_bc_info(List, [], State).

get_p_bg_act_or_bc_info([], List, State) ->
    {List, State};
get_p_bg_act_or_bc_info([#r_bg_act{id = ID, is_visible = IsVisible} = Info|T], List, State) ->
    case ?INT2BOOL(IsVisible) of
        true ->
            case catch do_online_action(ID, Info, State) of
                ok ->
                    get_p_bg_act_or_bc_info(T, List, State);
                {ok, PBgAct2} ->
                    get_p_bg_act_or_bc_info(T, [PBgAct2|List], State);
                {new_state, State2} ->
                    get_p_bg_act_or_bc_info(T, List, State2);
                Error ->
                    ?ERROR_MSG("--------get_p_bg_act_or_bc_info---------------~w", [Error]),
                    get_p_bg_act_or_bc_info(T, List, State)
            end;
        _ ->
            get_p_bg_act_or_bc_info(T, List, State)
    end.

do_online_action(ID, Info, #r_role{role_id = RoleID} = State) ->
    case ID of
        ?BG_ACT_FEAST_ENTRY ->
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
            mod_role_bg_act_feast:get_feast_entry_online_info(State, PBgAct);
        ?BG_ACT_ACC_PAY ->
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
            mod_role_bg_act_feast:get_feast_acc_pay_online_info(State, PBgAct);
        ?BG_ACT_REGRESSION ->
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
            mod_role_bg_act_feast:get_feast_regression_online_info(State, PBgAct);
        ?BG_ACT_ACC_CONSUME ->
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
            mod_role_bg_act_feast:get_feast_acc_consume_online_info(State, PBgAct);
        ?BG_ACT_RECHARGE ->
            mod_role_bg_act_feast:feast_recharge_online_action(State, Info);
        ?BG_ACT_STORE ->
            mod_role_bg_act_store:online_action(State, Info);
        ?BG_ACT_MISSION ->
            mod_role_bg_act_mission:online_action(State, Info);
        ?BG_ACT_DOUBLE_COPY ->
            bg_common_online_info:double_copy(Info);
        ?BG_ACT_BOSS_DROP ->
            bg_common_online_info:bg_act_drop(Info, RoleID);
        ?BG_ACT_DOUBLE_EXP ->
            bg_common_online_info:double_exp(Info);
        ?BG_ACT_TREVI_FOUNTAIN ->
            mod_role_trevi_fountain:online_action(Info, State);
        ?BG_ACT_ALCHEMY ->
            mod_role_bg_alchemy:online_action(Info, State);
        ?BG_ACT_RECHARGE_TURNTABLE ->
            mod_role_bg_turntable:online_action_b(Info, State);
        ?BG_ACT_ACTIVE_TURNTABLE ->
            mod_role_bg_turntable:online_action_a(Info, State);
        ?BG_ACT_TREASURE_TROVE ->
            mod_role_bg_treasure_trove:online_action_a(Info, State);
        ?BG_ACT_ST_STORE ->
            mod_role_bg_treasure_trove:online_action_c(Info, State);
        ?BG_ACT_SECRET_TERRITORY ->
            mod_role_bg_treasure_trove:online_action_b(Info, State);
        ?BG_ACT_KING_GUARD ->
            mod_role_guard:king_guard_online(State),
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
            {ok, PBgAct#p_bg_act{entry_list = []}};
        ?BG_ACT_RECHARGE_REWARD ->
            mod_role_bg_summer:recharge_online(State, Info);
        ?BG_ACT_CONSUME_RANK ->
            mod_role_bg_summer:rank_online(State, Info);
        ?BG_ACT_ALCHEMY_ONE ->
            mod_role_bg_new_alchemy:new_alchemy_online(State#r_role.role_id, Info);
        ?BG_ACT_TIME_STORE ->
            mod_role_bg_new_alchemy:time_store_online(Info);
        ?BG_ACT_RECHARGE_PACKET ->
            mod_role_bg_extra:online_recharge_package(State, Info);
        ?BG_ACT_QINGXIN ->
            mod_role_bg_extra:online_qinxin(State, Info);
        ?BG_ACT_DOUBLE_RECHARGE ->
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
            {ok, PBgAct#p_bg_act{entry_list = []}};
        _ ->
            ok
    end.


%%等级提升
level_up(OldLevel, NewLevel, #r_role{role_id = RoleID} = State) ->
    BgActList = world_bg_act_server:get_open_bg_act_front(State),
    {BgActList2, State2} = lists:foldl(
        fun(#r_bg_act{min_level = MinLevel} = Info, {AccList, StateAcc}) ->
            case OldLevel < MinLevel andalso MinLevel =< NewLevel of
                true ->
                    StateAcc2 = init_bg_act_after_check(StateAcc, Info),
                    {[Info|AccList], StateAcc2};
                _ ->
                    {AccList, StateAcc}
            end
        end, {[], State}, BgActList),
    {PBgActList, State3} = get_p_bg_act_or_bc_info(BgActList2, State2),
    ?IF(PBgActList =/= [], common_misc:unicast(RoleID, #m_bg_act_update_toc{act_list = PBgActList}), ok),

    BgList = world_bg_act_server:get_open_bg_act_back(State3),
    #r_role{role_pay = #r_role_pay{today_pay_gold = TodayPayGold}} = State3,
    State4 =
        lists:foldl(
            fun(#r_bg_act{min_level = MinLevel} = Info, StateAcc) ->
                case OldLevel < MinLevel andalso MinLevel =< NewLevel of
                    true ->
                        pay2(TodayPayGold, Info, StateAcc);
                    _ ->
                        StateAcc
                end
            end, State3, BgList),
    State4.


%%领取活动奖励
do_act_acc_pay_reward(RoleID, ID, Entry, State) ->
    case catch check_can_get_reward(ID, Entry, State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_bg_act_reward_toc{id = ID, entry = Entry, num = -1}),
            State3;
        {num, State2, Num} ->
            common_misc:unicast(RoleID, #m_bg_act_reward_toc{id = ID, entry = Entry, num = Num}),
            State2;
        {ok, BagDoings, Num, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_bg_act_reward_toc{id = ID, entry = Entry, num = Num}),
            State3;
        {ok, State2, BagDoings, AssetDoing, Num} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            State4 = mod_role_asset:do(AssetDoing, State3),
            common_misc:unicast(RoleID, #m_bg_act_reward_toc{id = ID, entry = Entry, num = Num}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bg_act_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get_reward(ID, Entry, State) ->
    ?IF(is_bg_act_open(ID, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    case ID of
        ?BG_ACT_FEAST_ENTRY ->
            mod_role_bg_act_feast:check_act_entry_reward(State, Entry);
        ?BG_ACT_ACC_PAY ->
            mod_role_bg_act_feast:check_acc_pay_reward(State, Entry);
        ?BG_ACT_ACC_CONSUME ->
            mod_role_bg_act_feast:check_acc_consume_reward(State, Entry);
        ?BG_ACT_REGRESSION ->
            mod_role_bg_act_feast:check_regression_reward(State, Entry);
        ?BG_ACT_RECHARGE ->
            mod_role_bg_act_feast:check_recharge_reward(State);
        ?BG_ACT_STORE ->
            mod_role_bg_act_store:check_can_get_reward(State, Entry);
        ?BG_ACT_MISSION ->
            mod_role_bg_act_mission:check_can_get_reward(State, Entry);
        ?BG_ACT_TREVI_FOUNTAIN ->
            mod_role_trevi_fountain:check_can_get_reward(State, Entry);
        ?BG_ACT_RECHARGE_TURNTABLE ->
            mod_role_bg_turntable:check_can_get_reward_b(State, Entry);
        ?BG_ACT_ACTIVE_TURNTABLE ->
            mod_role_bg_turntable:check_can_get_reward_a(State, Entry);
        ?BG_ACT_RECHARGE_REWARD ->
            mod_role_bg_summer:check_can_get_reward(State, Entry);
        ?BG_ACT_ST_STORE ->
            mod_role_bg_treasure_trove:check_can_buy(State, Entry);
        ?BG_ACT_TIME_STORE ->
            mod_role_bg_new_alchemy:check_can_buy(State, Entry);
        ?BG_ACT_RECHARGE_PACKET ->
            mod_role_bg_extra:check_can_get_a(State, Entry);
        ?BG_ACT_QINGXIN ->
            mod_role_bg_extra:check_can_get_b(State);
        _ ->
            {error, ?ERROR_COMMON_ACT_NO_START}
    end.







