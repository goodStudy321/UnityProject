%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%         os->open server    开服活动第二阶
%%% @end
%%% Created : 18. 三月 2019 15:34
%%%-------------------------------------------------------------------
-module(mod_role_act_os_second).
-author("WZP").

-include("role.hrl").
-include("act_oss.hrl").
-include("act.hrl").
-include("rank.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("role_extra.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_act_os_second.hrl").
-include("proto/mod_role_act_rank.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2,
    day_reset/1,
    zero/1,
    init_data/2
]).

-export([
    gm_add_mana/2
]).



-export([
    get_second_open_act/2,
    set_second_open_act/2,
    do_task/3,
%%    rank_end/1,
%%    rank_end/2,
    kill_boss/2,
    do_recharge/2,
    role_pre_enter/3,
    wing_power_update/3,
    handbook_power_update/3,
    magic_weapon_power_update/3,
    online_trevi_fountain/1,
    online_panic_buy/1,
    online_seven/1,
    online_rank/1,
    close_notice/1,
    get_act_limited_panic_buy/2,
    set_act_limited_panic_buy/2
]).


init(#r_role{role_id = RoleID, role_second_act = undefined} = State) ->
    State2 =
    case get_second_open_act(RoleID, State) of
        #r_role_second_open_act{role_id = RoleID, second_open_act = OpenAct} ->
            case OpenAct =:= [] of
                true ->
                    SecondOpenAct = init_oss_rank(),
                    RoleSecondOpenAct = #r_role_second_open_act{role_id = State#r_role.role_id, second_open_act = SecondOpenAct},
                    set_second_open_act(RoleSecondOpenAct, State);
                _ ->
                    State
            end;
        _ ->
            State
    end,
    State3 =
        case get_act_limited_panic_buy(RoleID, State2) of
            #r_role_act_limited_panic_buy{role_id = RoleID, limited_panic_buy = LimitedPanicBuy} ->
                case LimitedPanicBuy =:= [] of
                    true ->
                        LimitedPanicBuy2 = init_panic_buy(),
                        RoleLimitedPanicBuy = #r_role_act_limited_panic_buy{role_id = State2#r_role.role_id, limited_panic_buy = LimitedPanicBuy2},
                        set_act_limited_panic_buy(RoleLimitedPanicBuy, State2);
                    _ ->
                        State2
                end;
            _ ->
                State2
        end,
%%    LimitedPanicBuy = init_panic_buy(),
    SevenList = init_seven_list(),
    RoleSecondAct = #r_role_second_act{role_id = RoleID, seven_day_list = SevenList},
    State3#r_role{role_second_act = RoleSecondAct};

init(#r_role{role_id = RoleID, role_second_act = _RoleSecondAct} = State) ->
    State2 =
    case get_second_open_act(RoleID, State) of
        #r_role_second_open_act{role_id = RoleID, second_open_act = OpenAct} ->
            case OpenAct =:= [] of
                true ->
                    SecondOpenAct = init_oss_rank(),
                    RoleSecondOpenAct = #r_role_second_open_act{role_id = State#r_role.role_id, second_open_act = SecondOpenAct},
                    set_second_open_act(RoleSecondOpenAct, State);
                _ ->
                    State
            end;
        _ ->
            State
    end,
    case get_act_limited_panic_buy(RoleID, State2) of
        #r_role_act_limited_panic_buy{role_id = RoleID, limited_panic_buy = LimitedPanicBuy} ->
            case LimitedPanicBuy =:= [] of
                true ->
                    LimitedPanicBuy2 = init_panic_buy(),
                    RoleLimitedPanicBuy = #r_role_act_limited_panic_buy{role_id = State2#r_role.role_id, limited_panic_buy = LimitedPanicBuy2},
                    set_act_limited_panic_buy(RoleLimitedPanicBuy, State2);
                _ ->
                    State2
            end;
        _ ->
            State2
    end.

init_data(StartTime, State) ->
    RoleID = State#r_role.role_id,
    LimitedPanicBuy = init_panic_buy(),
    RoleLimitedPanicBuy = #r_role_act_limited_panic_buy{role_id = RoleID, limited_panic_buy = LimitedPanicBuy, open_time = StartTime},
    State2 = set_act_limited_panic_buy(RoleLimitedPanicBuy, State),
    online_panic_buy(State2).

init_oss_rank() ->
    lists:foldl(fun(RankType, SecondOpenActListAcc) ->
        RankReward = init_rank_reward(RankType),
        PanicBuy = init_panic_buy(RankType),
        ManaReward = init_mana_reward(RankType),
        PowerReward = init_power_reward(RankType),
        RechargeReward = init_recharge_reward(RankType),
        Mana = 0,
        Rank = 0,
        Recharge = 0,
        TaskList = [{TaskID, 0, 0} || TaskID <- ?OSS_TASK_LIST],
        SecondOpenAct = #r_second_open_act{oss_rank_type = RankType, power_reward = PowerReward, rank_reward = RankReward, rank = Rank, panic_buy = PanicBuy, mana = Mana, recharge = Recharge,
            mana_reward = ManaReward, recharge_reward = RechargeReward, task_list = TaskList},
        lists:keystore(RankType, #r_second_open_act.oss_rank_type, SecondOpenActListAcc, SecondOpenAct)
                end, [], [?RANK_WING_POWER_I, ?RANK_MAGIC_WEAPON_POWER_I, ?RANK_HANDBOOK_POWER_I]).

init_power_reward(RankType) ->
    [#p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_oss_power_reward{id = ID, type = Type}} <- cfg_oss_power_reward:list(), Type =:= RankType].

init_rank_reward(RankType) ->
    [#p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_oss_rank_reward{id = ID, type = Type}} <- cfg_oss_rank_reward:list(), Type =:= RankType].

init_panic_buy(RankType) ->
    [#p_kv{id = ID, val = 0} || {_, #c_oss_panic_buy{id = ID, type = Type}} <- cfg_oss_panic_buy:list(), Type =:= RankType].


init_mana_reward(RankType) ->
    [#p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_oss_mana_reward{id = ID, type = Type}} <- cfg_oss_mana_reward:list(), Type =:= RankType].


init_recharge_reward(RankType) ->
    [#p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_oss_recharge_reward{id = ID, type = Type}} <- cfg_oss_recharge_reward:list(), Type =:= RankType].

init_panic_buy() ->
    [#p_kv{id = ID, val = 0} || {_, #c_oss_limited_panic_buy{id = ID}} <- cfg_oss_limited_panic_buy:list()].

init_seven_list() ->
    [#p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_oss_seven{id = ID}} <- cfg_oss_seven:list()].

online(State) ->
    State2 = online_rank(State),
    State3 = online_seven(State2),
    State4 = online_panic_buy(State3),
    online_trevi_fountain(State4).

online_seven(State) ->
    case mod_role_act:is_act_open(?ACT_OSS_SEVEN, State) of
        false ->
            ok;
        _ ->
            #r_role{role_id = RoleID, role_second_act = RoleSecondAct} = State,
            Open = ?IF(RoleSecondAct#r_role_second_act.seven_day_invest, 1, 0),
            common_misc:unicast(RoleID, #m_oss_seven_toc{open = Open, list = RoleSecondAct#r_role_second_act.seven_day_list})
    end,
    State.

%%online_panic_buy(State) ->
%%    [#c_act{min_level = MinLevel, game_channel_list = GameChannelList}] = world_act_server:get_act_config(?ACT_OSS_PANIC_BUY),
%%    case mod_role_data:get_role_level(State) >= MinLevel of
%%        false ->
%%            false;
%%        _ ->
%%            ID2 = case GameChannelList =:= [] of
%%                      true ->
%%                          ?ACT_OSS_PANIC_BUY;
%%                      _ ->
%%                          lib_tool:to_integer(lib_tool:to_list(?ACT_OSS_PANIC_BUY) ++ lib_tool:to_list(State#r_role.role_attr#r_role_attr.game_channel_id))
%%                  end,
%%            #r_act{status = Status} = RAct = world_act_server:get_act(ID2),
%%            case Status =:= ?ACT_STATUS_OPEN of
%%                true ->
%%                    #r_role{role_second_act = RoleSecondAct, role_id = RoleID} = State,
%%                    OpenDay = world_act_server:get_act_open_day(RAct),
%%                    List = lists:foldl(fun(Pkv, AccList) ->
%%                        [Config] = lib_config:find(cfg_oss_limited_panic_buy, Pkv#p_kv.id),
%%                        ?IF(OpenDay =:= Config#c_oss_limited_panic_buy.day, [Pkv|AccList], AccList)
%%                                       end, [], RoleSecondAct#r_role_second_act.limited_panic_buy),
%%                    ?IF(List =:= [], ok, common_misc:unicast(RoleID, #m_oss_panic_buy_toc{list = List}));
%%                _ ->
%%                    ok
%%            end
%%    end,
%%    State.


online_panic_buy(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_LIMITED_PANIC_BUY, State) of
        true ->
            RoleID = State#r_role.role_id,
            RCycleAct = world_cycle_act_server:get_act(?CYCLE_ACT_LIMITED_PANIC_BUY),
            OpenDay = get_cycle_act_open_day(RCycleAct),
            #r_role_act_limited_panic_buy{limited_panic_buy = LimitedPanicBuy} = get_act_limited_panic_buy(RoleID, State),
            List = lists:foldl(fun(Pkv, AccList) ->
                [Config] = lib_config:find(cfg_oss_limited_panic_buy, Pkv#p_kv.id),
                ?IF(OpenDay =:= Config#c_oss_limited_panic_buy.day, [Pkv|AccList], AccList)
                               end, [], LimitedPanicBuy),
            ?IF(List =:= [], ok, common_misc:unicast(RoleID, #m_oss_panic_buy_toc{list = List})),
            State;
        _ ->
            State
    end.

get_cycle_act_open_day(#r_cycle_act{start_time = StartTime}) ->
    time_tool:diff_date(time_tool:now(), StartTime) + 1;
get_cycle_act_open_day(ID) ->
    #r_cycle_act{start_time = StartTime} = world_cycle_act_server:get_act(ID),
    time_tool:diff_date(time_tool:now(), StartTime) + 1.

online_rank(State) ->
    ActivityList = get_open_rank_activity(State),
    lists:foldl(fun({_, Type, LevelEnough, IsLastDay}, StateAcc) ->
        #r_role{role_id = RoleID} = StateAcc,
        #r_role{calc_list = CalcList} = StateAcc,
        StateAcc2 =
            case Type of
                ?RANK_WING_POWER_I ->
                    case lists:keyfind(?CALC_KEY_WING, #r_calc.key, CalcList) of
                        #r_calc{power = Power} ->
                            wing_power_update(StateAcc, Power, false);
                        _ ->
                            StateAcc
                    end;
                ?RANK_MAGIC_WEAPON_POWER_I ->
                    case lists:keyfind(?CALC_KEY_MAGIC_WEAPON, #r_calc.key, CalcList) of
                        #r_calc{power = Power} ->
                            magic_weapon_power_update(StateAcc, Power, false);
                        _ ->
                            StateAcc
                    end;
                ?RANK_HANDBOOK_POWER_I ->
                    case lists:keyfind(?CALC_KEY_HANDBOOK, #r_calc.key, CalcList) of
                        #r_calc{power = Power} ->
                            handbook_power_update(StateAcc, Power, false);
                        _ ->
                            StateAcc
                    end
            end,
        RoleSecondOpenAct2 = get_second_open_act(RoleID, StateAcc2),
        #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct2,
        case lists:keyfind(Type, #r_second_open_act.oss_rank_type, SecondOpenActList) of
            #r_second_open_act{} = SecondOpenAct ->
                case LevelEnough of
                    true ->
                        case IsLastDay of
                            true ->
                                RankList = world_data:get_oss_rank(),
                                RankList2 = [#p_open_act_rank{type = Type2, rank = Rank, role_id = RoleID2, role_name = RoleName, rank_value = Power} = OpenActRank || #p_open_act_rank{type = Type2, rank = Rank, role_id = RoleID2, role_name = RoleName, rank_value = Power} = OpenActRank <- RankList, Type =:= Type2],
                                common_misc:unicast(RoleID, #m_oss_rank_toc{type = Type,
                                    is_last_day = ?IF(IsLastDay, 1, 0),
                                    power_reward = SecondOpenAct#r_second_open_act.power_reward,
                                    rank_reward = SecondOpenAct#r_second_open_act.rank_reward,
                                    rank_list = RankList2}),
                                StateAcc2;
                            _ ->
                                RankList = world_data:get_oss_rank(),
                                RankList2 = [#p_open_act_rank{type = Type2, rank = Rank, role_id = RoleID2, role_name = RoleName, rank_value = Power} = OpenActRank || #p_open_act_rank{type = Type2, rank = Rank, role_id = RoleID2, role_name = RoleName, rank_value = Power} = OpenActRank <- RankList, Type =:= Type2],
                                ManaList = [#p_kv{id = MissionID, val = MissionMana} || {MissionID, _, MissionMana} <- SecondOpenAct#r_second_open_act.task_list],
                                common_misc:unicast(RoleID, #m_oss_rank_toc{type = Type,
                                    is_last_day = ?IF(IsLastDay, 1, 0),
                                    rank_reward = SecondOpenAct#r_second_open_act.rank_reward,
                                    power_reward = SecondOpenAct#r_second_open_act.power_reward,
                                    panic_buy = SecondOpenAct#r_second_open_act.panic_buy,
                                    mana = SecondOpenAct#r_second_open_act.mana,
                                    mana_reward = SecondOpenAct#r_second_open_act.mana_reward,
                                    rank_list = RankList2,
                                    mana_list = ManaList,
                                    recharge_reward = SecondOpenAct#r_second_open_act.recharge_reward,
                                    recharge = SecondOpenAct#r_second_open_act.recharge}),
                                StateAcc2
                        end;
                    _ ->
                        StateAcc2
                end;
            _ ->
                StateAcc2
        end end, State, ActivityList).

online_trevi_fountain(#r_role{role_second_act = RoleSecondAct, role_id = RoleID} = State) ->
    case mod_role_act:is_act_open(?ACT_OSS_TREVI_FOUNTAIN, State) of
        true ->
            Reward = [begin
                          case Config#c_trevi_fountain_reward.score > RoleSecondAct#r_role_second_act.trevi_fountain_score of
                              true ->
                                  #p_kv{id = Config#c_trevi_fountain_reward.id, val = ?ACT_REWARD_CANNOT_GET};
                              _ ->
                                  case lists:member(Config#c_trevi_fountain_reward.id, RoleSecondAct#r_role_second_act.trevi_fountain_reward) of
                                      true ->
                                          #p_kv{id = Config#c_trevi_fountain_reward.id, val = ?ACT_REWARD_GOT};
                                      _ ->
                                          #p_kv{id = Config#c_trevi_fountain_reward.id, val = ?ACT_REWARD_CAN_GET}
                                  end
                          end
                      end || {_, Config} <- cfg_trevi_fountain_reward:list()],
            RareList = [{Config#c_trevi_fountain.weight, Config} || {_, Config} <- cfg_trevi_fountain:list(), Config#c_trevi_fountain.is_rare =:= 1, not lists:member(Config#c_trevi_fountain.id, RoleSecondAct#r_role_second_act.trevi_fountain_good_reward)],
            common_misc:unicast(RoleID, #m_oss_trevi_fountain_toc{score = RoleSecondAct#r_role_second_act.trevi_fountain_score, got_reward = Reward,
                bless = RoleSecondAct#r_role_second_act.trevi_fountain_bless, notice = RoleSecondAct#r_role_second_act.notice, precious_exist = RareList =/= [],
                config = common_config:get_open_days()});
        _ ->
            ok
    end,
    State.



day_reset(State) ->
    State2 = day_reset_seven(State),
    State3 = day_reset_oss_rank(State2),
    online_trevi_fountain(State3).


day_reset_seven(#r_role{role_second_act = RoleSecondAct, role_id = RoleID} = State) ->
    case mod_role_act:is_act_open(?ACT_OSS_SEVEN, State) andalso RoleSecondAct#r_role_second_act.seven_day_invest of
        true ->
            Day = world_act_server:get_act_open_day(?ACT_OSS_SEVEN),
            List = [begin
                        case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET andalso Pkv#p_kv.id =< Day of
                            true ->
                                Pkv#p_kv{val = ?ACT_REWARD_CAN_GET};
                            _ ->
                                Pkv
                        end
                    end || Pkv <- RoleSecondAct#r_role_second_act.seven_day_list],
            Open = ?IF(RoleSecondAct#r_role_second_act.seven_day_invest, 1, 0),
            common_misc:unicast(RoleID, #m_oss_seven_toc{open = Open, list = List}),
            State#r_role{role_second_act = RoleSecondAct#r_role_second_act{seven_day_list = List}};
        _ ->
            case RoleSecondAct#r_role_second_act.seven_day_invest andalso not world_act_server:is_act_open(?ACT_OSS_SEVEN) of
                true ->
                    {Gold, BindGold} = lists:foldl(fun(Pkv, {AccGold, AccBindGold}) ->
                        case Pkv#p_kv.val =/= ?ACT_REWARD_GOT of
                            true ->
                                [Config] = lib_config:find(cfg_oss_seven, Pkv#p_kv.id),
                                [AssetType, Value|_] = Config#c_oss_seven.reward,
                                ?IF(AssetType =:= ?ASSET_GOLD, {AccGold + Value, AccBindGold}, {AccGold, AccBindGold + Value});
                            _ ->
                                {AccGold, AccBindGold}
                        end
                                                   end, {0, 0}, RoleSecondAct#r_role_second_act.seven_day_list),
                    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum} || {ItemNum, ItemType} <- [{Gold, ?BAG_ASSET_GOLD}, {BindGold, ?BAG_ASSET_BIND_GOLD}], ItemNum =/= 0],
                    case GoodsList =:= [] of
                        true ->
                            ok;
                        _ ->
                            LetterInfo = #r_letter_info{
                                template_id = ?LETTER_TEMPLATE_OSS_SEVEN,
                                action = ?ITEM_GAIN_OSS_SEVEN,
                                goods_list = GoodsList},
                            common_letter:send_letter(RoleID, LetterInfo)
                    end,
                    State#r_role{role_second_act = RoleSecondAct#r_role_second_act{seven_day_invest = false}};
                _ ->
                    State
            end
    end.


day_reset_oss_rank(State) ->
    ActivityList = get_open_rank_activity(State),
    lists:foldl(fun({_, Type, LevelEnough, IsLastDay}, StateAcc) ->
        #r_role{role_id = RoleID} = StateAcc,
        RoleSecondOpenAct = get_second_open_act(RoleID, StateAcc),
        #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
        case IsLastDay of
            true ->
                case has_rank(RoleID, Type) of
                    {ok, Rank} ->
                        case lists:keyfind(Type, #r_second_open_act.oss_rank_type, SecondOpenActList) of
                            #r_second_open_act{} = SecondOpenAct ->
                                Config = get_rank_config(Rank, Type),
                                SecondOpenAct2 = SecondOpenAct#r_second_open_act{rank = Rank},
                                {value, Pkv, OtherReward} = lists:keytake(Config#c_oss_rank_reward.id, #p_kv.id, SecondOpenAct2#r_second_open_act.rank_reward),
                                RewardList2 = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|OtherReward],
                                SecondOpenAct3 = SecondOpenAct2#r_second_open_act{rank_reward = RewardList2},
                                ?IF(LevelEnough,
                                    common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = Type, type_i = ?ACT_OSS_REWARD_ONE, change_list = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}]}), ok),
                                SecondOpenActList2 = lists:keystore(Type, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct3),
                                RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                                set_second_open_act(RoleSecondOpenAct2, StateAcc);
                            _ ->
                                StateAcc
                        end;
                    _ ->
                        StateAcc
                end;
            _ ->
                StateAcc
        end
                end, State, ActivityList).

has_rank(RoleID, Type) ->
    has_rank(RoleID, Type, world_data:get_oss_rank()).
has_rank(_RoleID, _Type, []) ->
    false;
has_rank(RoleID, Type, [Info|T]) ->
    case Info#p_open_act_rank.role_id =:= RoleID andalso Info#p_open_act_rank.type =:= Type of
        true ->
            {ok, Info#p_open_act_rank.rank};
        _ ->
            has_rank(RoleID, Type, T)
    end.

zero(State) ->
    online_panic_buy(State),
    ActivityList = get_open_rank_activity(State),
    [begin
         common_misc:unicast(State#r_role.role_id, #m_oss_rank_last{type = Type})
     end || {_, Type, true, true} <- ActivityList],
    State.

%%得到开启的活动三个冲榜时间互斥     等级不足也要更新触发内容
get_open_rank_activity(State) ->
    Now = time_tool:now(),
    {WingOpen, LevelEnough1, IsLastDay1} = get_open_rank_activity_i(?ACT_OSS_WING, State, Now),
    {MagicWeaponOpen, LevelEnough2, IsLastDay2} = get_open_rank_activity_i(?ACT_OSS_MAGIC_WEAPON, State, Now),
    {HandBookOpen, LevelEnough3, IsLastDay3} = get_open_rank_activity_i(?ACT_OSS_HANDBOOK, State, Now),
    [begin
         Tuple
     end || Tuple <- [{WingOpen, ?RANK_WING_POWER_I, LevelEnough1, IsLastDay1}, {MagicWeaponOpen, ?RANK_MAGIC_WEAPON_POWER_I, LevelEnough2, IsLastDay2}, {HandBookOpen, ?RANK_HANDBOOK_POWER_I, LevelEnough3, IsLastDay3}],
        erlang:element(1, Tuple) =:= true].

get_open_rank_activity_i(ID, State, Now) ->
    [#c_act{min_level = MinLevel, game_channel_list = GameChannelList}] = world_act_server:get_act_config(ID),
    ID2 = case GameChannelList =:= [] of
              true ->
                  ID;
              _ ->
                  lib_tool:to_integer(lib_tool:to_list(ID) ++ lib_tool:to_list(State#r_role.role_attr#r_role_attr.game_channel_id))
          end,
    #r_act{end_date = EndDate, status = Status} = world_act_server:get_act(ID2),
    {Status =:= ?ACT_STATUS_OPEN, mod_role_data:get_role_level(State) >= MinLevel, time_tool:is_same_date(Now, EndDate)}.


close_notice(#r_role{role_second_act = RoleSecondAct} = State) ->
    RoleSecondAct2 = RoleSecondAct#r_role_second_act{notice = false},
    State#r_role{role_second_act = RoleSecondAct2}.


handle({#m_oss_rank_reward_tos{type = Type, type_i = TypeI, id = ID}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, Type, TypeI, ID, State);
handle({#m_oss_seven_buy_tos{}, _RoleID, _PID}, State) ->
    do_buy_seven(State);
handle({#m_oss_do_panic_buy_tos{id = ID}, _RoleID, _PID}, State) ->
    do_limited_panic_buy(State, ID);
handle({#m_oss_seven_reward_tos{id = Day}, _RoleID, _PID}, State) ->
    do_get_seven_reward(State, Day);
handle({#m_oss_trevi_fountain_reward_tos{id = ID}, _RoleID, _PID}, State) ->
    do_get_trevi_fountain_reward(State, ID);
handle({#m_oss_trevi_fountain_draw_tos{times = Times}, _RoleID, _PID}, State) ->
    do_get_trevi_fountain_draw(State, Times).



rank_to_act_type(RankType) ->
    case RankType of
        ?RANK_WING_POWER_I ->
            ?ACT_OSS_WING;
        ?RANK_MAGIC_WEAPON_POWER_I ->
            ?ACT_OSS_MAGIC_WEAPON;
        ?RANK_HANDBOOK_POWER_I ->
            ?ACT_OSS_HANDBOOK
    end.

do_get_reward(RoleID, Type, TypeI, ID, State) ->
    case get_open_rank_activity_i(rank_to_act_type(Type), State, time_tool:now()) of
        {true, true, IsLastDay} ->
            ?IF(IsLastDay andalso TypeI =/= ?ACT_OSS_REWARD_ONE, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_004), ok),
            case TypeI of
                ?ACT_OSS_REWARD_FOUR ->
                    case catch check_can_buy(State, ID, Type) of
                        {ok, State2, AssetDoing, BagDoings} ->
                            State3 = mod_role_asset:do(AssetDoing, State2),
                            State4 = mod_role_bag:do(BagDoings, State3),
                            common_misc:unicast(RoleID, #m_oss_rank_reward_toc{type = Type, type_i = TypeI, id = ID}),
                            State4;
                        {error, ErrCode} ->
                            common_misc:unicast(RoleID, #m_oss_rank_reward_toc{err_code = ErrCode}),
                            State
                    end;
                _ ->
                    case catch check_can_get_reward(State, ID, Type, TypeI) of
                        {ok, State2, BagDoings} ->
                            State3 = mod_role_bag:do(BagDoings, State2),
                            common_misc:unicast(RoleID, #m_oss_rank_reward_toc{type = Type, type_i = TypeI, id = ID}),
                            State3;
                        {error, ErrCode} ->
                            common_misc:unicast(RoleID, #m_oss_rank_reward_toc{err_code = ErrCode}),
                            State
                    end
            end;
        _ ->
            common_misc:unicast(RoleID, #m_oss_rank_reward_toc{err_code = ?ERROR_COMMON_ACT_NO_START}),
            State
    end.

check_can_buy(#r_role{role_id = RoleID} = State, ID, Type) ->
    [RewardConfig] = lib_config:find(cfg_oss_panic_buy, ID),
    ?IF(RewardConfig#c_oss_panic_buy.type =:= Type, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    RoleSecondOpenAct = get_second_open_act(RoleID, State),
    #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
    case lists:keyfind(Type, #r_second_open_act.oss_rank_type, SecondOpenActList) of
        #r_second_open_act{} = SecondOpenAct ->
            case lists:keytake(ID, #p_kv.id, SecondOpenAct#r_second_open_act.panic_buy) of
                {value, Pkv, Other} ->
                    ?IF(Pkv#p_kv.val < RewardConfig#c_oss_panic_buy.buy_times, ok, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_002)),
                    Action = get_action_by_type(Type),
                    AssetDoing = mod_role_asset:check_asset_by_type(RewardConfig#c_oss_panic_buy.asset_type, RewardConfig#c_oss_panic_buy.price, Action, State),
                    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum, bind = ?IS_BIND(ItemBind)} || {ItemType, ItemNum, ItemBind} <- lib_tool:string_to_intlist(RewardConfig#c_oss_panic_buy.reward)],
                    mod_role_bag:check_bag_empty_grid(GoodsList, State),
                    BagDoings = [{create, ?ITEM_GAIN_OSS_BUY, GoodsList}],
                    NewPanicBuy = [Pkv#p_kv{val = Pkv#p_kv.val + 1}|Other],
                    SecondOpenAct2 = SecondOpenAct#r_second_open_act{panic_buy = NewPanicBuy},
                    SecondOpenActList2 = lists:keystore(Type, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                    RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                    State2 = set_second_open_act(RoleSecondOpenAct2, State),
                    {ok, State2, AssetDoing, BagDoings};
                _ ->
                    ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.

get_action_by_type(Type) ->
    case Type of
        ?RANK_WING_POWER_I ->
            ?ASSET_GOLD_REDUCE_FROM_OSS_WING;
        ?RANK_MAGIC_WEAPON_POWER_I ->
            ?ASSET_GOLD_REDUCE_FROM_OSS_MAGIC_WEAPON;
        _ ->
            ?ASSET_GOLD_REDUCE_FROM_OSS_HANDBOOK
    end.


check_can_get_reward(#r_role{role_id = RoleID} = State, ID, Type, TypeI) ->
    RoleSecondOpenAct = get_second_open_act(RoleID, State),
    #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
    case lists:keyfind(Type, #r_second_open_act.oss_rank_type, SecondOpenActList) of
        #r_second_open_act{} = SecondOpenAct ->
            RewardConfig = get_reward_config(TypeI, ID),
            GoodsList = get_config_reward(RewardConfig),
            mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
            BagDoings = [{create, ?ITEM_GAIN_OSS_REWARD, GoodsList}],
            case check_can_get_reward_i(SecondOpenAct, ID, TypeI) of
                {ok, SecondOpenAct2} ->
                    SecondOpenActList2 = lists:keystore(Type, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                    RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                    State2 = set_second_open_act(RoleSecondOpenAct2, State),
                    {ok, State2, BagDoings};
                _ ->
                    ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.

check_can_get_reward_i(SecondAct, ID, TypeI) ->
    RewardList = case TypeI of
                     ?ACT_OSS_REWARD_ONE ->
                         SecondAct#r_second_open_act.rank_reward;
                     ?ACT_OSS_REWARD_THREE ->
                         SecondAct#r_second_open_act.mana_reward;
                     ?ACT_OSS_REWARD_TWO ->
                         SecondAct#r_second_open_act.power_reward;
                     ?ACT_OSS_REWARD_FIVE ->
                         SecondAct#r_second_open_act.recharge_reward
                 end,
    case lists:keytake(ID, #p_kv.id, RewardList) of
        false ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR);
        {value, #p_kv{} = Pkv, Other} ->
            ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_003)),
            NewActRewardList = [Pkv#p_kv{val = ?ACT_REWARD_GOT}|Other],
            SecondAct2 = case TypeI of
                                   ?ACT_OSS_REWARD_ONE ->
                                       SecondAct#r_second_open_act{rank_reward = NewActRewardList};
                                   ?ACT_OSS_REWARD_THREE ->
                                       SecondAct#r_second_open_act{mana_reward = NewActRewardList};
                                   ?ACT_OSS_REWARD_TWO ->
                                       SecondAct#r_second_open_act{power_reward = NewActRewardList};
                                   ?ACT_OSS_REWARD_FIVE ->
                                       SecondAct#r_second_open_act{recharge_reward = NewActRewardList}
                               end,

            {ok, SecondAct2}
    end.

get_config_reward(RewardConfig) ->
    Reward2 = case RewardConfig of
                  #c_oss_rank_reward{reward = Reward} ->
                      Reward;
                  #c_oss_power_reward{reward = Reward} ->
                      Reward;
                  #c_oss_mana_reward{reward = Reward} ->
                      Reward;
                  #c_oss_recharge_reward{reward = Reward} ->
                      Reward
              end,
    [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- lib_tool:string_to_intlist(Reward2)].

get_reward_config(TypeI, ID) ->
    [Config] = case TypeI of
                   ?ACT_OSS_REWARD_ONE ->
                       lib_config:find(cfg_oss_rank_reward, ID);
                   ?ACT_OSS_REWARD_TWO ->
                       lib_config:find(cfg_oss_power_reward, ID);
                   ?ACT_OSS_REWARD_THREE ->
                       lib_config:find(cfg_oss_mana_reward, ID);
                   ?ACT_OSS_REWARD_FIVE ->
                       lib_config:find(cfg_oss_recharge_reward, ID)
               end,
    Config.


%%更新战力奖励
wing_power_update(State, Power, IsBc) ->
    case get_open_rank_activity_i(?ACT_OSS_WING, State, time_tool:now()) of
        {true, true, false} ->
            #r_role{role_id = RoleID} = State,
            RoleSecondOpenAct = get_second_open_act(RoleID, State),
            #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
            case lists:keyfind(?RANK_WING_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList) of
                #r_second_open_act{} = SecondOpenAct ->
                    check_is_rank(?RANK_WING_POWER_I, SecondOpenAct, Power, RoleID),
                    {NewPowerRewardList, UpdateList} = do_power_update(SecondOpenAct#r_second_open_act.power_reward, Power),
                    SecondOpenAct2 = SecondOpenAct#r_second_open_act{power_reward = NewPowerRewardList},
                    SecondOpenActList2 = lists:keystore(?RANK_WING_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                    RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                    ?IF(UpdateList =/= [] andalso IsBc,
                        common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = ?RANK_WING_POWER_I, type_i = ?ACT_OSS_REWARD_TWO, change_list = UpdateList, mana = SecondOpenAct2#r_second_open_act.mana,
                            recharge = SecondOpenAct2#r_second_open_act.recharge}), ok),
                    set_second_open_act(RoleSecondOpenAct2, State);
                _ ->
                    State
            end;
        _ ->
            State
    end.

magic_weapon_power_update(State, Power, IsBc) ->
    case get_open_rank_activity_i(?ACT_OSS_MAGIC_WEAPON, State, time_tool:now()) of
        {true, true, false} ->
            #r_role{role_id = RoleID} = State,
            RoleSecondOpenAct = get_second_open_act(RoleID, State),
            #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
            case lists:keyfind(?RANK_MAGIC_WEAPON_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList) of
                #r_second_open_act{} = SecondOpenAct ->
                    check_is_rank(?RANK_MAGIC_WEAPON_POWER_I, SecondOpenAct, Power, RoleID),
                    {NewPowerRewardList, UpdateList} = do_power_update(SecondOpenAct#r_second_open_act.power_reward, Power),
                    SecondOpenAct2 = SecondOpenAct#r_second_open_act{power_reward = NewPowerRewardList},
                    SecondOpenActList2 = lists:keystore(?RANK_MAGIC_WEAPON_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                    RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                    ?IF(UpdateList =/= [] andalso IsBc,
                        common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = ?RANK_MAGIC_WEAPON_POWER_I, type_i = ?ACT_OSS_REWARD_TWO, change_list = UpdateList, mana = SecondOpenAct2#r_second_open_act.mana,
                            recharge = SecondOpenAct2#r_second_open_act.recharge}), ok),
                    set_second_open_act(RoleSecondOpenAct2, State);
                _ ->
                    State
            end;
        _ ->
            State
    end.

handbook_power_update(State, Power, IsBc) ->
    case get_open_rank_activity_i(?ACT_OSS_HANDBOOK, State, time_tool:now()) of
        {true, true, false} ->
            #r_role{role_id = RoleID} = State,
            RoleSecondOpenAct = get_second_open_act(RoleID, State),
            #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
            case lists:keyfind(?RANK_HANDBOOK_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList) of
                #r_second_open_act{} = SecondOpenAct ->
                    check_is_rank(?RANK_HANDBOOK_POWER_I, SecondOpenAct, Power, RoleID),
                    {NewPowerRewardList, UpdateList} = do_power_update(SecondOpenAct#r_second_open_act.power_reward, Power),
                    SecondOpenAct2 = SecondOpenAct#r_second_open_act{power_reward = NewPowerRewardList},
                    SecondOpenActList2 = lists:keystore(?RANK_HANDBOOK_POWER_I, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                    RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                    ?IF(UpdateList =/= [] andalso IsBc,
                        common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = ?RANK_HANDBOOK_POWER_I, type_i = ?ACT_OSS_REWARD_TWO, change_list = UpdateList, mana = SecondOpenAct2#r_second_open_act.mana,
                            recharge = SecondOpenAct2#r_second_open_act.recharge}), ok),
                    set_second_open_act(RoleSecondOpenAct2, State);
                _ ->
                    State
            end;
        _ ->
            State
    end.

check_is_rank(RankType, SecondAct, NewPower, RoleID) ->
    Config = get_rank_config(1, RankType),
    case enough_condition(SecondAct, Config) andalso NewPower =/= 0 of
        true ->
            mod_role_rank:update_rank(RankType, {RoleID, NewPower, time_tool:now()});
        _ ->
            ok
    end.

%%领取条件足够
enough_condition(SecondAct, Config) ->
    SecondAct#r_second_open_act.recharge >= Config#c_oss_rank_reward.arg_i.

do_power_update(PowerRewardList, Power) ->
    lists:foldl(
        fun(Pkv, {AccRewardList, UpdateList}) ->
            case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    [Config] = lib_config:find(cfg_oss_power_reward, Pkv#p_kv.id),
                    ?IF(Config#c_oss_power_reward.power > Power, {[Pkv|AccRewardList], UpdateList}, {[Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|AccRewardList], [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|UpdateList]});
                _ ->
                    {[Pkv|AccRewardList], UpdateList}
            end
        end, {[], []}, PowerRewardList).

do_task(State, TType, Times) ->
    ActivityList = get_open_rank_activity(State),
    lists:foldl(fun({_, RankType, LevelEnough, IsLastDay}, StateAcc) ->
        case IsLastDay =:= false of
            true ->
                case lib_config:find(cfg_oss_mana, {RankType, TType}) of
                    [Config] ->
                        #r_role{role_id = RoleID} = StateAcc,
                        RoleSecondOpenAct = get_second_open_act(RoleID, StateAcc),
                        #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
                        case lists:keyfind(RankType, #r_second_open_act.oss_rank_type, SecondOpenActList) of
                            #r_second_open_act{} = SecondOpenAct ->
                                case lists:keytake(TType, 1, SecondOpenAct#r_second_open_act.task_list) of
                                    {value, {_, OldTimes, OldMana}, Other} ->
                                        NewTimes = Times + OldTimes,
                                        NewTimes2 = NewTimes rem Config#c_oss_mana.arg,
                                        AddMana = NewTimes div Config#c_oss_mana.arg * Config#c_oss_mana.mana,
                                        SecondOpenAct2 = SecondOpenAct#r_second_open_act{task_list = [{TType, NewTimes2, OldMana + AddMana}|Other]},
                                        SecondOpenActList2 = lists:keystore(RankType, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
                                        RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                                        State2 = set_second_open_act(RoleSecondOpenAct2, StateAcc),
                                        case catch add_mana(State2, AddMana, RankType, LevelEnough, [#p_kv{id = TType, val = OldMana + AddMana}]) of
                                            {ok, State3} ->
                                                State3;
                                            _ ->
                                                StateAcc
                                        end;
                                    _ ->
                                        StateAcc
                                end;
                            _ ->
                                StateAcc
                        end;
                    _ ->
                        StateAcc
                end;
            _ ->
                StateAcc
        end
                end, State, ActivityList).

add_mana(State, Mana, RankType, LevelEnough, UpdateManaList) ->
    #r_role{role_id = RoleID} = State,
    RoleSecondOpenAct = get_second_open_act(RoleID, State),
    #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
    case lists:keyfind(RankType, #r_second_open_act.oss_rank_type, SecondOpenActList) of
        #r_second_open_act{} = SecondOpenAct ->
            {NewManaRewardList, UpdateList} = do_mana_update(SecondOpenAct#r_second_open_act.mana_reward, SecondOpenAct#r_second_open_act.mana + Mana),
            SecondOpenAct2 = SecondOpenAct#r_second_open_act{mana_reward = NewManaRewardList, mana = SecondOpenAct#r_second_open_act.mana + Mana},
            ?IF(LevelEnough, common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = RankType, type_i = ?ACT_OSS_REWARD_THREE, change_list = UpdateList, mana = SecondOpenAct#r_second_open_act.mana + Mana,
                recharge = SecondOpenAct2#r_second_open_act.recharge, mana_list = UpdateManaList}), ok),
            SecondOpenActList2 = lists:keystore(RankType, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct2),
            RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
            State2 = set_second_open_act(RoleSecondOpenAct2, State),
            {ok, State2};
        _ ->
            {ok, State}
    end.


do_mana_update(RewardList, NewMana) ->
    lists:foldl(
        fun(Pkv, {AccRewardList, UpdateList}) ->
            case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    [Config] = lib_config:find(cfg_oss_mana_reward, Pkv#p_kv.id),
                    ?IF(Config#c_oss_mana_reward.mana > NewMana, {[Pkv|AccRewardList], UpdateList}, {[Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|AccRewardList], [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|UpdateList]});
                _ ->
                    {[Pkv|AccRewardList], UpdateList}
            end
        end, {[], []}, RewardList).



do_recharge(State, Num) ->
    ActivityList = get_open_rank_activity(State),
    lists:foldl(fun({_, Type, LevelEnough, _IsLastDay}, StateAcc) ->
        #r_role{role_id = RoleID} = StateAcc,
        RoleSecondOpenAct = get_second_open_act(RoleID, StateAcc),
        #r_role_second_open_act{second_open_act = SecondOpenActList} = RoleSecondOpenAct,
        case lists:keyfind(Type, #r_second_open_act.oss_rank_type, SecondOpenActList) of
            #r_second_open_act{} = SecondOpenAct ->
                {ok, SecondOpenAct2, RechargeNum2} = do_acc_recharge(SecondOpenAct, RoleID, Type, Num, LevelEnough),
                [{_, Config}|_] = cfg_oss_rank_reward:list(),
                case not enough_condition(SecondOpenAct, Config) andalso enough_condition(SecondOpenAct2, Config) of
                    true ->
                        PowerKey = case Type of
                                       ?RANK_HANDBOOK_POWER_I -> ?CALC_KEY_HANDBOOK;
                                       ?RANK_MAGIC_WEAPON_POWER_I -> ?CALC_KEY_MAGIC_WEAPON;
                                       _ -> ?CALC_KEY_WING
                                   end,
                        case lists:keyfind(PowerKey, #r_calc.key, StateAcc#r_role.calc_list) of
                            false ->
                                NewPower = 0;
                            #r_calc{power = NewPower} ->
                                NewPower
                        end,
                        ?IF(NewPower =:= 0, ok, mod_role_rank:update_rank(Type, {RoleID, NewPower, time_tool:now()}));
                    _ ->
                        ok
                end,
                SecondOpenAct3 = check_rank_reward(SecondOpenAct2, RechargeNum2, Type, LevelEnough, State),
                SecondOpenActList2 = lists:keystore(Type, #r_second_open_act.oss_rank_type, SecondOpenActList, SecondOpenAct3),
                RoleSecondOpenAct2 = RoleSecondOpenAct#r_role_second_open_act{second_open_act = SecondOpenActList2},
                State2 = set_second_open_act(RoleSecondOpenAct2, State),
                do_task(State2, ?OSS_RECHARGE, Num);
            _ ->
                StateAcc
        end end, State, ActivityList).


check_rank_reward(SecondOpenAct, RechargeNum2, Type, LevelEnough, State) ->
    case SecondOpenAct#r_second_open_act.rank =:= 0 of
        true ->
            SecondOpenAct;
        _ ->
            Config = get_rank_config(SecondOpenAct#r_second_open_act.rank, Type),
            case RechargeNum2 >= Config#c_oss_rank_reward.arg_i of
                false ->
                    SecondOpenAct;
                _ ->
                    {value, Pkv, OtherPkv} = lists:keytake(Config#c_oss_rank_reward.id, #p_kv.id, SecondOpenAct#r_second_open_act.rank_reward),
                    case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                        false ->
                            SecondOpenAct;
                        _ ->
                            ?IF(LevelEnough,
                                common_misc:unicast(State#r_role.role_id,
                                    #m_oss_rank_change_toc{type = Type, type_i = ?ACT_OSS_REWARD_ONE, change_list = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}],
                                        mana = SecondOpenAct#r_second_open_act.mana, recharge = RechargeNum2}), ok),
                            RankRewardList2 = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|OtherPkv],
                            SecondOpenAct#r_second_open_act{rank_reward = RankRewardList2}
                    end
            end
    end.

get_rank_config(Rank, Type) ->
    get_rank_config_i(cfg_oss_rank_reward:list(), Rank, Type).

get_rank_config_i([], _Rank, _Type) ->
    ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR);
get_rank_config_i([{_, #c_oss_rank_reward{type = Type} = Config}|T], Rank, Type) ->
    [Min, Max] = Config#c_oss_rank_reward.rank_region,
    case Min =< Rank andalso Max >= Rank of
        true ->
            Config;
        _ ->
            get_rank_config_i(T, Rank, Type)
    end;
get_rank_config_i([_|T], Rank, Type) ->
    get_rank_config_i(T, Rank, Type).

do_acc_recharge(SecondOpenAct, RoleID, Type, Num, LevelEnough) ->
    RechargeNum2 = SecondOpenAct#r_second_open_act.recharge + Num,
    SecondOpenAct2 = SecondOpenAct#r_second_open_act{recharge = RechargeNum2},
    {NewRewardList, UpdateList} = do_acc_recharge_i(SecondOpenAct2#r_second_open_act.recharge_reward, RechargeNum2),
    case LevelEnough of
        false -> ok;
        _ ->
            common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = Type, type_i = ?ACT_OSS_REWARD_FIVE, change_list = UpdateList, mana = SecondOpenAct2#r_second_open_act.mana, recharge = RechargeNum2})
    end,
    {ok, SecondOpenAct2#r_second_open_act{recharge_reward = NewRewardList}, RechargeNum2}.



do_acc_recharge_i(RewardList, RechargeNum) ->
    lists:foldl(
        fun(Pkv, {AccRewardList, UpdateList}) ->
            case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    [Config] = lib_config:find(cfg_oss_recharge_reward, Pkv#p_kv.id),
                    case RechargeNum >= Config#c_oss_recharge_reward.quota of
                        true ->
                            Pkv2 = Pkv#p_kv{val = ?ACT_REWARD_CAN_GET},
                            {[Pkv2|AccRewardList], [Pkv2|UpdateList]};
                        _ ->
                            {[Pkv|AccRewardList], UpdateList}
                    end;
                _ ->
                    {[Pkv|AccRewardList], UpdateList}
            end
        end, {[], []}, RewardList).


%%排名结束
%%rank_end(Rank) ->
%%    erlang:send(erlang:self(), {?MODULE, rank_end, [Rank]}).
%%rank_end(Rank, RoleInfo) when erlang:is_integer(RoleInfo) ->
%%    case role_misc:is_online(RoleInfo) of
%%        true ->
%%            role_misc:info_role(RoleInfo, {?MODULE, rank_end, [Rank]});
%%        _ ->
%%            world_offline_event_server:add_event(RoleInfo, {?MODULE, rank_end, [Rank]})
%%    end;
%%rank_end(Rank, #r_role{role_id = RoleID, role_second_act = RoleSecondAct} = State) ->
%%    case get_open_rank_activity(State) of
%%        {ok, Type, LevelEnough, _} ->
%%            Config = get_rank_config(Rank, Type),
%%            RoleSecondAct2 = RoleSecondAct#r_role_second_act{rank = Rank},
%%            {value, Pkv, OtherReward} = lists:keytake(Config#c_oss_rank_reward.id, #p_kv.id, RoleSecondAct2#r_role_second_act.rank_reward),
%%            RewardList2 = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|OtherReward],
%%            RoleSecondAct3 = RoleSecondAct2#r_role_second_act{rank_reward = RewardList2},
%%            ?IF(LevelEnough,
%%                common_misc:unicast(RoleID, #m_oss_rank_change_toc{type = Type, type_i = ?ACT_OSS_REWARD_ONE, change_list = [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}],
%%                                                                   mana = RoleSecondAct3#r_role_second_act.mana,
%%                                                                   recharge = RoleSecondAct3#r_role_second_act.recharge}), ok),
%%            State#r_role{role_second_act = RoleSecondAct3};
%%        _ ->
%%            ok
%%    end.


%%任务触发
kill_boss(TypeID, State) ->
    case lib_config:find(cfg_world_boss, TypeID) of
        [#c_world_boss{type = Type}] ->
            if
                Type =:= ?BOSS_TYPE_WORLD_BOSS -> do_task(State, ?OSS_WORLD_BOSS, 1);
                Type =:= ?BOSS_TYPE_PERSONAL -> do_task(State, ?OSS_PERSON_BOSS, 1);
                Type =:= ?BOSS_TYPE_FAMILY -> do_task(State, ?OSS_HOME_BOSS, 1);
                true ->
                    State
            end;
        _ ->
            State
    end.

role_pre_enter(State, BagDoings, PreEnterMap) ->
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(PreEnterMap),
    if
        BagDoings =:= [] -> State;
        ?SUB_TYPE_WORLD_BOSS_4 =:= SubType -> do_task(State, ?OSS_YMDJ, 1);
        true ->
            State
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  GM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gm_add_mana(State, Num) ->
    ActivityList = get_open_rank_activity(State),
    lists:foldl(fun({_, RankType, LevelEnough, false}, StateAcc) ->
        {ok, State2} = add_mana(StateAcc, Num, RankType, LevelEnough, []),
        State2
                end, State, ActivityList).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  GM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  七天  抢购   许愿池 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_buy_seven(#r_role{role_id = RoleID} = State) ->
    case catch check_can_buy_seven(State) of
        {ok, State2, AssetDoing, UpdateList} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_oss_seven_buy_toc{update_list = UpdateList}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_oss_seven_buy_toc{err_code = ErrCode}),
            State
    end.

check_can_buy_seven(#r_role{role_second_act = RoleSecondAct} = State) ->
    ?IF(mod_role_act:is_act_open(?ACT_OSS_SEVEN, State), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    ?IF(RoleSecondAct#r_role_second_act.seven_day_invest, ?THROW_ERR(?ERROR_OSS_SEVEN_REWARD_001), ok),
    [Config] = lib_config:find(cfg_oss_seven, 1),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Config#c_oss_seven.price, ?ASSET_GOLD_REDUCE_FROM_OSS_SEVEN, State),
    Day = world_act_server:get_act_open_day(?ACT_OSS_SEVEN),
    {NewSevenDayList, UpdateList} = lists:foldl(
        fun(Pkv, {AccList, AccUpdateList}) ->
            case Pkv#p_kv.id > Day of
                false ->
                    Pkv2 = Pkv#p_kv{val = ?ACT_REWARD_CAN_GET},
                    {[Pkv2|AccList], [Pkv2|AccUpdateList]};
                _ ->
                    {[Pkv|AccList], AccUpdateList}
            end
        end, {[], []}, RoleSecondAct#r_role_second_act.seven_day_list),
    RoleSecondAct2 = RoleSecondAct#r_role_second_act{seven_day_invest = true, seven_day_list = NewSevenDayList},
    {ok, State#r_role{role_second_act = RoleSecondAct2}, AssetDoing, UpdateList}.


do_get_seven_reward(#r_role{role_id = RoleID} = State, Day) ->
    case catch check_get_seven_reward(State, Day) of
        {ok, State2, AssetDoing} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_oss_seven_reward_toc{id = Day}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_oss_seven_reward_toc{err_code = ErrCode}),
            State
    end.

check_get_seven_reward(#r_role{role_second_act = RoleSecondAct} = State, Day) ->
    ?IF(mod_role_act:is_act_open(?ACT_OSS_SEVEN, State), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    case lists:keytake(Day, #p_kv.id, RoleSecondAct#r_role_second_act.seven_day_list) of
        {value, Pkv, Other} ->
            ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_003)),
            [Config] = lib_config:find(cfg_oss_seven, Day),
            [AssetType, Value|_] = Config#c_oss_seven.reward,
            AssetDoing = ?IF(AssetType =:= ?ASSET_GOLD, [{add_gold, ?ASSET_GOLD_ADD_FROM_OSS_SEVEN, Value, 0}], [{add_gold, ?ASSET_GOLD_ADD_FROM_OSS_SEVEN, 0, Value}]),
            RoleSecondAct2 = RoleSecondAct#r_role_second_act{seven_day_list = [Pkv#p_kv{val = ?ACT_REWARD_GOT}|Other]},
            {ok, State#r_role{role_second_act = RoleSecondAct2}, AssetDoing};
        _ ->
            ?THROW_ERR(?ERROR_OSS_RANK_REWARD_003)
    end.


do_limited_panic_buy(#r_role{role_id = RoleID} = State, ID) ->
    case catch check_limited_panic_buy(State, ID) of
        {ok, RoleLimitedPanicBuy2, BagDoing, AssetDoing} ->
            State2 = set_act_limited_panic_buy(RoleLimitedPanicBuy2, State),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_oss_do_panic_buy_toc{id = ID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_oss_do_panic_buy_toc{err_code = ErrCode}),
            State
    end.

check_limited_panic_buy(#r_role{role_id = RoleID} = State, ID) ->
    #r_role_act_limited_panic_buy{limited_panic_buy = LimitedPanicBuy} = RoleLimitedPanicBuy = get_act_limited_panic_buy(RoleID, State),
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_LIMITED_PANIC_BUY, State), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    case lists:keytake(ID, #p_kv.id, LimitedPanicBuy) of
        {value, Pkv, Other} ->
            [Config] = lib_config:find(cfg_oss_limited_panic_buy, ID),
            ?IF(Pkv#p_kv.val < Config#c_oss_limited_panic_buy.buy_times, ok, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_002)),
            AssetDoing = mod_role_asset:check_asset_by_type(Config#c_oss_limited_panic_buy.asset_type, Config#c_oss_limited_panic_buy.price, ?ASSET_GOLD_REDUCE_FROM_OSS_LIMITED_PANIC_BUY, State),
            GoodsList = [#p_goods{type_id = ItemType, num = ItemNum, bind = ?IS_BIND(ItemBind)} || {ItemType, ItemNum, ItemBind} <- lib_tool:string_to_intlist(Config#c_oss_limited_panic_buy.reward)],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_OSS_BUY, GoodsList}],
            LimitedPanicBuy2 = [Pkv#p_kv{val = Pkv#p_kv.val + 1}|Other],
            RoleLimitedPanicBuy2 = RoleLimitedPanicBuy#r_role_act_limited_panic_buy{limited_panic_buy = LimitedPanicBuy2},
            {ok, RoleLimitedPanicBuy2, BagDoings, AssetDoing};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
    end.




do_get_trevi_fountain_reward(#r_role{role_id = RoleID} = State, ID) ->
    case catch check_get_trevi_fountain_reward(State, ID) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_oss_trevi_fountain_reward_toc{reward = #p_kv{id = ID, val = ?ACT_REWARD_GOT}}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_oss_trevi_fountain_reward_toc{err_code = ErrCode}),
            State
    end.

check_get_trevi_fountain_reward(#r_role{role_second_act = RoleSecondAct} = State, ID) ->
    ?IF(mod_role_act:is_act_open(?ACT_OSS_TREVI_FOUNTAIN, State), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    ?IF(lists:member(ID, RoleSecondAct#r_role_second_act.trevi_fountain_reward), ?THROW_ERR(?ERROR_OSS_RANK_REWARD_003), ok),
    [Config] = lib_config:find(cfg_trevi_fountain_reward, ID),
    ?IF(Config#c_trevi_fountain_reward.score > RoleSecondAct#r_role_second_act.trevi_fountain_score, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_003), ok),
    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum, bind = ?IS_BIND(ItemBind)} || {ItemType, ItemNum, ItemBind} <- lib_tool:string_to_intlist(Config#c_trevi_fountain_reward.reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_OSS_TREVI_FOUNTAIN, GoodsList}],
    RoleSecondAct2 = RoleSecondAct#r_role_second_act{trevi_fountain_reward = [ID|RoleSecondAct#r_role_second_act.trevi_fountain_reward]},
    {ok, State#r_role{role_second_act = RoleSecondAct2}, BagDoings}.


do_get_trevi_fountain_draw(#r_role{role_id = RoleID} = State, Times) ->
    case catch check_get_draw(State, Times) of
        {ok, State2, AssetDoing, BagDoing, Score, List, Bless2, PreciousExist} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = mod_role_asset:do(AssetDoing, State3),
            common_misc:unicast(RoleID, #m_oss_trevi_fountain_draw_toc{reward = List, score = Score, times = Times, bless = Bless2, precious_exist = PreciousExist}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_oss_trevi_fountain_draw_toc{err_code = ErrCode}),
            State
    end.


check_get_draw(#r_role{role_second_act = RoleSecondAct} = State, Times) ->
    ?IF(mod_role_act:is_act_open(?ACT_OSS_TREVI_FOUNTAIN, State), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    ?IF(Times =:= 1 orelse Times =:= 10, ok, ?THROW_ERR(1)),
    [Config] = lib_config:find(cfg_global, ?OSS_TREVI_FOUNTAIN_GLOBAL),
    NeedItem = Config#c_global.int,
    NeedItemNum = mod_role_bag:get_num_by_type_id(NeedItem, State),
    [{_, UnitPrice}|_] = lib_tool:string_to_intlist(Config#c_global.string, ",", ":"),
    {BagDoing2, AssetDoing2} = case NeedItemNum > 0 of
                                   false ->
                                       AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Times * UnitPrice, ?ASSET_GOLD_REDUCE_FROM_TREVI_FOUNTAIN, State),
                                       {[], AssetDoing};
                                   _ ->
                                       case Times > NeedItemNum of
                                           true ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_TREVI_FOUNTAIN, [#r_goods_decrease_info{type_id = NeedItem, num = NeedItemNum}]}],
                                               AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, (Times - NeedItemNum) * UnitPrice, ?ASSET_GOLD_REDUCE_FROM_TREVI_FOUNTAIN, State),
                                               {BagDoing, AssetDoing};
                                           _ ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_TREVI_FOUNTAIN, [#r_goods_decrease_info{type_id = NeedItem, num = Times}]}],
                                               {BagDoing, []}
                                       end
                               end,
    {GoodsList, List, Bless2, GoodReward, PreciousExist} = draw_reward_by_times(Times, RoleSecondAct#r_role_second_act.trevi_fountain_bless, RoleSecondAct#r_role_second_act.trevi_fountain_good_reward, Config),
    RoleSecondAct2 = RoleSecondAct#r_role_second_act{trevi_fountain_score = Times + RoleSecondAct#r_role_second_act.trevi_fountain_score, trevi_fountain_bless = Bless2, trevi_fountain_good_reward = GoodReward},
    mod_role_bag:check_bag_empty_grid(?BAG_ID_TREVI_FOUNTAIN, GoodsList, State),
    BagDoing3 = [{create, ?BAG_ID_TREVI_FOUNTAIN, ?ITEM_GAIN_TREVI_FOUNTAIN, GoodsList}|BagDoing2],
    {ok, State#r_role{role_second_act = RoleSecondAct2}, AssetDoing2, BagDoing3, RoleSecondAct2#r_role_second_act.trevi_fountain_score, List, Bless2, PreciousExist}.


draw_reward_by_times(Times, Bless, GoodReward, GlobalConfig) ->
    [MinValue, MaxValue, Rate] = GlobalConfig#c_global.list,
    RareList = [{Config#c_trevi_fountain.weight, Config} || {_, Config} <- cfg_trevi_fountain:list(), Config#c_trevi_fountain.is_rare =:= 1, not lists:member(Config#c_trevi_fountain.id, GoodReward),
        Config#c_trevi_fountain.open_days =:= common_config:get_open_days()],
    NormalList = [{Config#c_trevi_fountain.weight, Config#c_trevi_fountain.reward} || {_, Config} <- cfg_trevi_fountain:list(),
        Config#c_trevi_fountain.is_rare =:= 0, Config#c_trevi_fountain.open_days =:= common_config:get_open_days()],
    draw_reward_by_times(Times, RareList, NormalList, MinValue, MaxValue, Rate, GoodReward, [], [], Bless).
draw_reward_by_times(Times, RareList, _NormalList, _MinValue, _MaxValue, _Rate, GoodReward, GoodsList, AccList, Bless) when Times =< 0 ->
    {GoodsList, AccList, Bless, GoodReward, RareList =/= []};
draw_reward_by_times(Times, RareList, NormalList, MinValue, MaxValue, Rate, GoodReward, GoodsList, AccList, Bless) ->
    case check_is_rare(RareList, MinValue, MaxValue, Rate, Bless) of
        false ->
            [Type, Num, Bind] = lib_tool:get_weight_output(NormalList),
            Bless2 = Bless + 1,
            draw_reward_by_times(Times - 1, RareList, NormalList, MinValue, MaxValue, Rate, GoodReward, [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)}|GoodsList], [Type|AccList], Bless2);
        _ ->
            Config = lib_tool:get_weight_output(RareList),
            RareList2 = lists:keydelete(Config, 2, RareList),
            [Type, Num, Bind] = Config#c_trevi_fountain.reward,
            Bless2 = 0,
            draw_reward_by_times(Times - 1, RareList2, NormalList, MinValue, MaxValue, Rate, [Config#c_trevi_fountain.id|GoodReward], [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)}|GoodsList], [Type|AccList], Bless2)
    end.

check_is_rare(RareList, MinValue, MaxValue, Rate, Bless) ->
    if
        RareList =:= [] -> false;
        Bless >= MaxValue -> true;
        Bless >= MinValue -> ?IF(Rate >= lib_tool:random(10000), true, false);
        true ->
            false
    end.


%%%===================================================================
%%% 数据操作
%%%===================================================================
get_second_open_act(RoleID, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_SECOND_OPEN_ACT, [], State),
    case lists:keyfind(RoleID, #r_role_second_open_act.role_id, List) of
        #r_role_second_open_act{} = SecondOpenAct ->
            SecondOpenAct;
        _ ->
            #r_role_second_open_act{role_id = RoleID}
    end.

set_second_open_act(SecondOpenAct, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_SECOND_OPEN_ACT, [], State),
    #r_role_second_open_act{role_id = RoleID} = SecondOpenAct,
    List2 = lists:keystore(RoleID, #r_role_second_open_act.role_id, List, SecondOpenAct),
    mod_role_extra:set_data(?EXTRA_KEY_SECOND_OPEN_ACT, List2, State).

get_act_limited_panic_buy(RoleID, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_CYCLE_ACT_LIMITED_PANIC_BUY, [], State),
    case lists:keyfind(RoleID, #r_role_act_limited_panic_buy.role_id, List) of
        #r_role_act_limited_panic_buy{} = RoleLimitedPanicBuy ->
            RoleLimitedPanicBuy;
        _ ->
            #r_role_act_limited_panic_buy{role_id = RoleID}
    end.

set_act_limited_panic_buy(RoleLimitedPanicBuy, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_CYCLE_ACT_LIMITED_PANIC_BUY, [], State),
    #r_role_act_limited_panic_buy{role_id = RoleID} = RoleLimitedPanicBuy,
    List2 = lists:keystore(RoleID, #r_role_act_limited_panic_buy.role_id, List, RoleLimitedPanicBuy),
    mod_role_extra:set_data(?EXTRA_KEY_CYCLE_ACT_LIMITED_PANIC_BUY, List2, State).