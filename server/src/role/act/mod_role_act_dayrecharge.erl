%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2018 11:08
%%%-------------------------------------------------------------------
-module(mod_role_act_dayrecharge).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("red_packet.hrl").
-include("proto/mod_role_act_dayrecharge.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2,
    day_reset/1,
    zero/1
]).

-export([
    do_recharge/2,
    init_day_count_reward/0
]).


init(#r_role{role_id = RoleID, role_act_dayrecharge = undefined} = State) ->
    DayReward = init_day_reward(),
    CountReward = init_day_count_reward(),
    ActDayRecharge = #r_role_act_dayrecharge{role_id = RoleID, recharge = 0, count_recharge = 0, day_reward = DayReward, count_reward = CountReward, have_count = ?ACT_NO},
    State#r_role{role_act_dayrecharge = ActDayRecharge};
init(State) ->
    State.

online(#r_role{role_id = RoleID, role_act_dayrecharge = ActDayRecharge} = State) ->
    case mod_role_act:is_act_open(?ACT_DAYRECHARGE_ID, State) of
        true ->
            common_misc:unicast(RoleID, #m_act_dayrecharge_toc{recharge = ActDayRecharge#r_role_act_dayrecharge.recharge, day_reward = ActDayRecharge#r_role_act_dayrecharge.day_reward,
                                                               count_reward = ActDayRecharge#r_role_act_dayrecharge.count_reward, day = common_config:get_open_days()}),
            State;
        _ ->
            State
    end.

handle({#m_act_dayrecharge_count_reward_tos{day = Day}, RoleID, _PID}, State) ->
    do_get_count_reward(State, RoleID, Day);
handle({#m_act_dayrecharge_reward_tos{key = Key}, RoleID, _PID}, State) ->
    do_get_reward(State, RoleID, Key).


day_reset(#r_role{role_id = RoleID, role_act_dayrecharge = ActDayRecharge} = State) ->
    send_yesterday(ActDayRecharge#r_role_act_dayrecharge.day_reward, RoleID, ActDayRecharge#r_role_act_dayrecharge.recharge_day),
    DayReward = init_day_reward(),
    CountReward = deal_with_count_reward(ActDayRecharge#r_role_act_dayrecharge.count_reward, RoleID),
    ActDayRecharge2 = ActDayRecharge#r_role_act_dayrecharge{role_id = RoleID, recharge = 0, day_reward = DayReward, have_count = ?ACT_NO, count_reward = CountReward},
    State#r_role{role_act_dayrecharge = ActDayRecharge2}.

zero(State) ->
    online(State).

deal_with_count_reward(CountReward, RoleID) ->
    case complete_recharge(CountReward) of
        {true, GoodList} ->
            case GoodList =:= [] of
                true ->
                    ok;
                _ ->
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_DAY_RECHARGE,
                        action = ?ITEM_GAIN_ACT_DAYREECHARGE,
                        goods_list = GoodList},
                    common_letter:send_letter(RoleID, LetterInfo)
            end,
            init_day_count_reward();
        _ ->
            CountReward
    end.

send_yesterday(DayReward, RoleID, Day) ->
    case send_yesterday_i(Day, DayReward, []) of
        [] ->
            ok;
        GoodList ->
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_DAY_RECHARGE,
                action = ?ITEM_GAIN_ACT_DAYREECHARGE,
                goods_list = GoodList},
            common_letter:send_letter(RoleID, LetterInfo)
    end.

send_yesterday_i(_, [], GoodList) ->
    GoodList;
send_yesterday_i(Day, [OldReward|T], GoodList) ->
    case OldReward#p_kv.val =:= ?ACT_REWARD_CAN_GET of
        true ->
            [Config] = lib_config:find(cfg_act_dayrecharge, OldReward#p_kv.id),
            RewardList = get_reward_by_day(Config),
            RewardList2 = lib_tool:string_to_intlist(RewardList),
            GoodList2 = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- RewardList2] ++ GoodList,
            send_yesterday_i(Day, T, GoodList2);
        _ ->
            send_yesterday_i(Day, T, GoodList)
    end.



complete_recharge(CountReward) ->
    MaxConfig = get_max_count_config(),
    Info = lists:keyfind(MaxConfig#c_act_dayrecharge_count.day, #p_kv.id, CountReward),
    case Info#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            false;
        _ ->
            GoodList = lists:foldl(
                fun(#p_kv{val = Val, id = Day}, AccList) ->
                    case Val =:= ?ACT_REWARD_CAN_GET of
                        false ->
                            AccList;
                        _ ->
                            [Config] = lib_config:find(cfg_act_dayrecharge_count, Day),
                            RewardList = lib_tool:string_to_intlist(Config#c_act_dayrecharge_count.reward),
                            [#p_goods{type_id = Type, num = Num} || {Type, Num} <- RewardList] ++ AccList
                    end
                end, [],
                CountReward
            ),
            {true, GoodList}
    end.



get_max_count_config() ->
    [Config] = lib_config:find(cfg_act_dayrecharge_count, 1),
    get_max_count_config(Config).

get_max_count_config(Config) ->
    case lib_config:find(cfg_act_dayrecharge_count, Config#c_act_dayrecharge_count.day + 1) of
        [] ->
            Config;
        [NextConfig] ->
            get_max_count_config(NextConfig)
    end.


init_day_reward() ->
    List = cfg_act_dayrecharge:list(),
    lists:foldl(
        fun({_, Config}, Rewards) ->
            [#p_kv{id = Config#c_act_dayrecharge.quota, val = ?ACT_REWARD_CANNOT_GET}|Rewards]
        end, [], List).

init_day_count_reward() ->
    List = cfg_act_dayrecharge_count:list(),
    lists:foldl(
        fun({_, {_, Day, _, _}}, Rewards) ->
            [#p_kv{id = Day, val = ?ACT_REWARD_CANNOT_GET}|Rewards]
        end, [], List).

do_recharge(#r_role{role_id = RoleID, role_act_dayrecharge = ActDayRecharge} = State, RechargeNum) ->
    ActDayRecharge2 = do_recharge2(ActDayRecharge, RechargeNum, RoleID, State),
    State2 = State#r_role{role_act_dayrecharge = ActDayRecharge2},
    case world_act_server:is_act_open(?ACT_DAYRECHARGE_ID) of
        true ->
            common_misc:unicast(RoleID, #m_act_dayrecharge_toc{recharge = ActDayRecharge2#r_role_act_dayrecharge.recharge, day_reward = ActDayRecharge2#r_role_act_dayrecharge.day_reward,
                                                               count_reward = ActDayRecharge2#r_role_act_dayrecharge.count_reward, day = common_config:get_open_days()});
        _ ->
            ok
    end,
    State2.

do_recharge2(ActDayRecharge, RechargeNum, RoleID, State) ->
    NewRecharge = ActDayRecharge#r_role_act_dayrecharge.recharge + RechargeNum,
    NewDayReward = lists:foldl(
        fun(Pkv, DayReward) ->
            case Pkv#p_kv.id =< NewRecharge andalso Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    case Pkv#p_kv.id of
                        60 ->
                            mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, ?RED_PACKET_FAMILY_DAY_ACC_RECHARGE_ONE);
                        680 ->
                            mod_role_red_packet:create_red_packet(RoleID, State#r_role.role_attr#r_role_attr.role_name, ?RED_PACKET_FAMILY_DAY_ACC_RECHARGE_TWO);
                        _ ->
                            ok
                    end,
                    [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|DayReward];
                _ ->
                    [Pkv|DayReward]
            end
        end, [], ActDayRecharge#r_role_act_dayrecharge.day_reward),
    ActDayRecharge2 = ActDayRecharge#r_role_act_dayrecharge{day_reward = NewDayReward, recharge = NewRecharge, recharge_day = common_config:get_open_days()},
    case ActDayRecharge#r_role_act_dayrecharge.have_count =:= ?ACT_NO of
        true ->
            NewCountRecharge = ActDayRecharge#r_role_act_dayrecharge.count_recharge + RechargeNum,
            {CountReward, HaveCount} = get_new_count_reward(ActDayRecharge2#r_role_act_dayrecharge.count_reward, NewCountRecharge),
            ActDayRecharge2#r_role_act_dayrecharge{count_reward = CountReward, have_count = HaveCount};
        _ ->
            ActDayRecharge2
    end.

get_new_count_reward(CountReward, RechargeNum) ->
    case get_new_count_reward_i(CountReward, 1) of
        #p_kv{id = Day} ->
            [Config] = lib_config:find(cfg_act_dayrecharge_count, Day),
            case RechargeNum >= Config#c_act_dayrecharge_count.quota of
                true ->
                    {lists:keyreplace(Day, #p_kv.id, CountReward, #p_kv{id = Day, val = ?ACT_REWARD_CAN_GET}), ?ACT_YES};
                _ ->
                    {CountReward, ?ACT_NO}
            end;
        _ ->
            {CountReward, ?ACT_NO}
    end.

get_new_count_reward_i([], _Day) ->
    [];
get_new_count_reward_i(CountReward, Day) ->
    case lists:keytake(Day, #p_kv.id, CountReward) of
        {value, #p_kv{val = Val} = Pkv, Other} ->
            case Val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    Pkv;
                _ ->
                    get_new_count_reward_i(Other, Day + 1)
            end;
        _ ->
            []
    end.

do_get_reward(State, RoleID, Key) ->
    case catch check_can_get(State, Key) of
        {ok, State2} ->
            Pkv = #p_kv{id = Key, val = ?ACT_REWARD_GOT},
            common_misc:unicast(RoleID, #m_act_dayrecharge_reward_toc{reward = Pkv}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_dayrecharge_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_act_dayrecharge = ActDayRecharge} = State, Key) ->
    {NewActDayRecharge, RewardList2} = case lists:keytake(Key, #p_kv.id, ActDayRecharge#r_role_act_dayrecharge.day_reward) of
                                           {value, Pkv, OtherReward} ->
                                               ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET, ?THROW_ERR(?ERROR_ACT_DAYRECHARGE_REWARD_002), ok),
                                               ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_GOT, ?THROW_ERR(?ERROR_ACT_DAYRECHARGE_REWARD_001), ok),
                                               [Config] = lib_config:find(cfg_act_dayrecharge, Key),
                                               Reward = get_reward_by_day(Config),
                                               RewardList = lib_tool:string_to_intlist(Reward),
                                               {ActDayRecharge#r_role_act_dayrecharge{day_reward = [Pkv#p_kv{val = ?ACT_REWARD_GOT}|OtherReward]}, RewardList};
                                           _ ->
                                               ?THROW_ERR(?ERROR_ACT_DAYRECHARGE_REWARD_003)
                                       end,
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- RewardList2],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoing = [{create, ?ITEM_GAIN_ACT_DAYREECHARGE, GoodsList}],
    State2 = State#r_role{role_act_dayrecharge = NewActDayRecharge},
    State3 = mod_role_bag:do(BagDoing, State2),
    {ok, State3}.


get_reward_by_day(Config) ->
    case common_config:get_open_days() of
        1 ->
            Config#c_act_dayrecharge.reward_one;
        2 ->
            Config#c_act_dayrecharge.reward_two;
        3 ->
            Config#c_act_dayrecharge.reward_three;
        4 ->
            Config#c_act_dayrecharge.reward_four;
        5 ->
            Config#c_act_dayrecharge.reward_five;
        6 ->
            Config#c_act_dayrecharge.reward_six;
        7 ->
            Config#c_act_dayrecharge.reward_seven;
        _ ->
            Config#c_act_dayrecharge.reward
    end.



do_get_count_reward(State, RoleID, Day) ->
    case catch check_can_get_count_reward(State, Day) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_act_dayrecharge_count_reward_toc{day = Day}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_dayrecharge_count_reward_toc{err_code = ErrCode}),
            State
    end.


check_can_get_count_reward(#r_role{role_act_dayrecharge = ActDayRecharge} = State, Day) ->
    case lists:keytake(Day, #p_kv.id, ActDayRecharge#r_role_act_dayrecharge.count_reward) of
        {value, #p_kv{val = Val}, Other} ->
            ?IF(Val =:= ?ACT_REWARD_CANNOT_GET, ?THROW_ERR(?ERROR_ACT_DAYRECHARGE_REWARD_002), ok),
            ?IF(Val =:= ?ACT_REWARD_GOT, ?THROW_ERR(?ERROR_ACT_DAYRECHARGE_REWARD_001), ok),
            [Config] = lib_config:find(cfg_act_dayrecharge_count, Day),
            RewardList = lib_tool:string_to_intlist(Config#c_act_dayrecharge_count.reward),
            NewActDayRecharge = ActDayRecharge#r_role_act_dayrecharge{count_reward = [#p_kv{val = ?ACT_REWARD_GOT, id = Day}|Other]},
            GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- RewardList],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoing = [{create, ?ITEM_GAIN_ACT_DAYREECHARGE, GoodsList}],
            State2 = State#r_role{role_act_dayrecharge = NewActDayRecharge},
            State3 = mod_role_bag:do(BagDoing, State2),
            {ok, State3};
        _ ->
            {error, ?ERROR_ACT_DAYRECHARGE_REWARD_003}
    end.