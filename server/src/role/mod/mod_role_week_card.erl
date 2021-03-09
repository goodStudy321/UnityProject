%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 二月 2019 10:58
%%%-------------------------------------------------------------------
-module(mod_role_week_card).
-author("WZP").

%%  周卡  改名基金

-include("role.hrl").
-include("week_card.hrl").
-include("proto/mod_role_week_card.hrl").
%% API
-export([
    init/1,
    online/1,
    handle/2,
    level_up/3,
    day_reset/1
]).

-export([
    get_open_card_by_level/2,
    get_reward_config/2,
    role_first_recharge/1
]).


init(#r_role{role_week_card = undefined, role_id = RoleID, role_attr = RoleAttr} = State) ->
    List = get_open_card_by_level(0, RoleAttr#r_role_attr.level),
    RoleWeekCard = #r_role_week_card{role_id = RoleID, card_list = List},
    State#r_role{role_week_card = RoleWeekCard};
init(State) ->
    State.


%%拿初始化周卡
get_open_card_by_level(OldLevel, NewLevel) ->
    OpenServerTime = common_config:get_open_time(),
    Now = time_tool:now(),
    OpenDay = time_tool:diff_date(Now, OpenServerTime) + 1,
    lists:foldl(
        fun({_, Config}, AccList) ->
            Res = case NewLevel >= Config#c_week_card.level andalso OldLevel < Config#c_week_card.level of
                      false ->
                          false;
                      _ ->
                          case Config#c_week_card.type of
                              ?WEEK_CARD_TYPE_ONE ->
                                  case Config#c_week_card.time_type of
                                      ?WEEK_CARD_OPEN_TYPE_ONE ->
                                          [YOpen, MOpen, DOpen] = Config#c_week_card.open_time,
                                          OpenTime = time_tool:timestamp({YOpen, MOpen, DOpen}),
                                          [YEnd, MEnd, DEnd] = Config#c_week_card.end_time,
                                          EndTime = time_tool:timestamp({YEnd, MEnd, DEnd}) + ?ONE_DAY,
                                          {OpenTime =< Now andalso Now < EndTime, EndTime};
                                      _ ->
                                          EndTime = time_tool:midnight(OpenServerTime) + Config#c_week_card.end_args * ?ONE_DAY,
                                          {Config#c_week_card.start_args =< OpenDay andalso OpenDay =< Config#c_week_card.end_args, EndTime}
                                  end;
                              _ ->
                                  {true, 0}
                          end
                  end,
            case Res of
                {true, EndTime2} ->
                    NewWeekCard = #r_week_card{id = Config#c_week_card.id, open_time = 0, end_time = EndTime2, buy_times = 0, reward = []},
                    [NewWeekCard|AccList];
                _ ->
                    AccList
            end
        end, [], lib_config:list(cfg_week_card)).


%%拿初始化周卡
get_open_card_by_time(Now, Level) ->
    OpenServerTime = common_config:get_open_time(),
    OpenDay = time_tool:diff_date(Now, OpenServerTime) + 1,
    lists:foldl(
        fun({_, Config}, AccList) ->
            Res = case Level >= Config#c_week_card.level of
                      false ->
                          false;
                      _ ->
                          case Config#c_week_card.type of
                              ?WEEK_CARD_TYPE_ONE ->
                                  case Config#c_week_card.time_type of
                                      ?WEEK_CARD_OPEN_TYPE_ONE ->
                                          [YOpen, MOpen, DOpen] = Config#c_week_card.open_time,
                                          OpenTime = time_tool:timestamp({YOpen, MOpen, DOpen}),
                                          [YEnd, MEnd, DEnd] = Config#c_week_card.end_time,
                                          EndTime = time_tool:timestamp({YEnd, MEnd, DEnd}) + ?ONE_DAY,
                                          {OpenTime =:= Now, EndTime};
                                      _ ->
                                          EndTime = time_tool:midnight(OpenServerTime) + Config#c_week_card.end_args * ?ONE_DAY,
                                          {Config#c_week_card.start_args =:= OpenDay, EndTime}
                                  end;
                              _ ->
                                  false
                          end
                  end,
            case Res of
                {true, EndTime2} ->
                    NewWeekCard = #r_week_card{id = Config#c_week_card.id, open_time = 0, end_time = EndTime2, buy_times = 0, reward = []},
                    [NewWeekCard|AccList];
                _ ->
                    AccList
            end
        end, [], lib_config:list(cfg_week_card)).

online(#r_role{role_week_card = RoleWeekCard, role_id = RoleID} = State) ->
    #r_role_week_card{card_list = CardList} = RoleWeekCard,
    case CardList =:= [] of
        true ->
            ok;
        _ ->
            List = tran_to_p_week_card(CardList, []),
            common_misc:unicast(RoleID, #m_role_week_card_toc{list = List})
    end,
    State.

tran_to_p_week_card([], List) ->
    List;
tran_to_p_week_card([Card|T], List) ->
    Info = #p_week_card{id = Card#r_week_card.id, open_time = Card#r_week_card.open_time, reward = Card#r_week_card.reward, end_time = Card#r_week_card.end_time},
    tran_to_p_week_card(T, [Info|List]).



level_up(OldLevel, NewLevel, #r_role{role_week_card = RoleWeekCard, role_id = RoleID} = State) ->
    case get_open_card_by_level(OldLevel, NewLevel) of
        [] ->
            State;
        NewList ->
            RoleWeekCard2 = RoleWeekCard#r_role_week_card{card_list = NewList ++ RoleWeekCard#r_role_week_card.card_list},
            SendList = tran_to_p_week_card(NewList, []),
            common_misc:unicast(RoleID, #m_role_week_card_add_toc{list = SendList, type = ?WEEK_CARD_ADD}),
            State#r_role{role_week_card = RoleWeekCard2}
    end.


day_reset(#r_role{role_week_card = RoleWeekCard, role_id = RoleID, role_attr = RoleAttr} = State) ->
    Now = time_tool:now(),
    AllReward = lib_config:list(cfg_week_card_reward),
    {NewList, DelList} = check_card(RoleWeekCard#r_role_week_card.card_list, Now, AllReward, [], []),
    ?IF(DelList =:= [], ok, common_misc:unicast(RoleID, #m_role_week_card_del_toc{list = DelList})),
    RoleWeekCard2 = RoleWeekCard#r_role_week_card{card_list = NewList},
    case get_open_card_by_time(time_tool:midnight(Now), RoleAttr#r_role_attr.level) of
        [] ->
            RoleWeekCard3 = RoleWeekCard2;
        NewCards ->
            RoleWeekCard3 = RoleWeekCard2#r_role_week_card{card_list = NewCards ++ NewList},
            common_misc:unicast(RoleID, #m_role_week_card_add_toc{type = ?WEEK_CARD_ADD, list = tran_to_p_week_card(NewCards, [])})
    end,
    State#r_role{role_week_card = RoleWeekCard3}.

check_card([], _Now, _AllReward, List, DelList) ->
    {List, DelList};
check_card([Card|T], Now, AllReward, List, DelList) ->
    case Card#r_week_card.open_time =:= 0 of
        true ->
            [Config] = lib_config:find(cfg_week_card, Card#r_week_card.id),
            case Card#r_week_card.end_time =< Now andalso Config#c_week_card.type =:= ?WEEK_CARD_TYPE_ONE of
                true ->
                    check_card(T, Now, AllReward, List, [Card#r_week_card.id|DelList]);
                _ ->
                    check_card(T, Now, AllReward, [Card|List], DelList)
            end;
        _ ->
            AllRewardDay = [Day || {_, #c_week_card_reward{card_id = CardID, day = Day}} <- AllReward, Card#r_week_card.id =:= CardID],
            case check_get_all_reward(AllRewardDay, Card#r_week_card.reward) of
                true ->
                    [Config] = lib_config:find(cfg_week_card, Card#r_week_card.id),
                    case Config#c_week_card.type of
                        ?WEEK_CARD_TYPE_ONE ->
                            check_card(T, Now, AllReward, List, [Card#r_week_card.id|DelList]);
                        ?WEEK_CARD_TYPE_TWO ->
                            check_card(T, Now, AllReward, List, [Card#r_week_card.id|DelList]);
                        _ ->
                            if
                                Config#c_week_card.loop_times > Card#r_week_card.buy_times ->
                                    check_card(T, Now, AllReward, [Card|List], DelList);
                                true ->
                                    check_card(T, Now, AllReward, List, [Card#r_week_card.id|DelList])
                            end
                    end;
                _ ->
                    check_card(T, Now, AllReward, [Card|List], DelList)
            end
    end.

check_get_all_reward([], _GotReward) ->
    true;
check_get_all_reward([Day|T], GotReward) ->
    case lists:member(Day, GotReward) of
        false ->
            false;
        _ ->
            check_get_all_reward(T, GotReward)
    end.

role_first_recharge(State) ->
    activate_card(?WEEK_CARD_FIRST_RECHARGE, State).


activate_card(Type, #r_role{role_week_card = RoleWeekCard, role_id = RoleID} = State) ->
    case check_activate_card(Type, RoleWeekCard#r_role_week_card.card_list, [], []) of
        {_, []} ->
            State;
        {NewCardList, ActivateCards} ->
            RoleWeekCard2 = RoleWeekCard#r_role_week_card{card_list = NewCardList},
            common_misc:unicast(RoleID, #m_role_week_card_add_toc{type = ?WEEK_CARD_REPLACE, list = ActivateCards}),
            State#r_role{role_week_card = RoleWeekCard2};
        _ ->
            State
    end.

check_activate_card(_Type, [], CardList, UpdateList) ->
    {CardList, UpdateList};
check_activate_card(Type, [Card|T], CardList, UpdateList) ->
    case Card#r_week_card.open_time =:= 0 of
        false ->
            check_activate_card(Type, T, [Card|CardList], UpdateList);
        _ ->
            [Config] = lib_config:find(cfg_week_card, Card#r_week_card.id),
            case Config#c_week_card.open_type =:= Type of
                false ->
                    check_activate_card(Type, T, [Card|CardList], UpdateList);
                _ ->
                    NewCard = Card#r_week_card{open_time = time_tool:now(), end_time = 0, reward = [], buy_times = Card#r_week_card.buy_times + 1},
                    PNewCard = #p_week_card{id = NewCard#r_week_card.id, open_time = NewCard#r_week_card.open_time, reward = NewCard#r_week_card.reward, end_time = NewCard#r_week_card.end_time},
                    check_activate_card(Type, T, [NewCard|CardList], [PNewCard|UpdateList])
            end
    end.



handle({#m_role_week_card_buy_tos{id = CardID}, RoleID, _Pid}, State) ->
    do_week_card_buy(RoleID, CardID, State);
handle({#m_role_week_card_reward_tos{id = CardID, day = Day}, RoleID, _Pid}, State) ->
    do_week_card_reward(RoleID, CardID, Day, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.



do_week_card_buy(RoleID, CardID, State) ->
    case catch check_can_buy(CardID, State) of
        {ok, State2, NewWeekCard, AssetDoing,Log} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            Info = #p_week_card{id = NewWeekCard#r_week_card.id, open_time = NewWeekCard#r_week_card.open_time, reward = NewWeekCard#r_week_card.reward, end_time = NewWeekCard#r_week_card.end_time},
            common_misc:unicast(RoleID, #m_role_week_card_buy_toc{card = Info}),
            mod_role_dict:add_background_logs(Log),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_week_card_buy_toc{err_code = ErrCode}),
            State
    end.


check_can_buy(CardID, #r_role{role_week_card = RoleWeekCard} = State) ->
    case lists:keytake(CardID, #r_week_card.id, RoleWeekCard#r_role_week_card.card_list) of
        {value, Card, Other} ->
            ?IF(Card#r_week_card.open_time =:= 0, ok, ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_BUY_001)),
            [Config] = lib_config:find(cfg_week_card, CardID),
            ?IF(Config#c_week_card.open_type =:= ?WEEK_CARD_BUY, ok, ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_BUY_002)),
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Config#c_week_card.open_args, ?ASSET_GOLD_REDUCE_FROM_WEEK_DAY, State),
            NewCard = Card#r_week_card{open_time = time_tool:now(), end_time = 0, reward = [], buy_times = Card#r_week_card.buy_times + 1},
            NewRoleWeekCard = RoleWeekCard#r_role_week_card{card_list = [NewCard|Other]},
            Log = get_log(State, Config#c_week_card.open_args),
            {ok, State#r_role{role_week_card = NewRoleWeekCard}, NewCard, AssetDoing, Log};
        _ ->
            ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_BUY_004)
    end.



do_week_card_reward(RoleID, CardID, Day, State) ->
    case catch check_can_get_reward(CardID, Day, State) of
        {ok, State2, BagDoings} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_role_week_card_reward_toc{id = CardID, day = Day}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_week_card_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get_reward(CardID, Day, #r_role{role_week_card = RoleWeekCard} = State) ->
    case lists:keytake(CardID, #r_week_card.id, RoleWeekCard#r_role_week_card.card_list) of
        {value, Card, Other} ->
            ?IF(lists:member(Day, Card#r_week_card.reward), ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_REWARD_001), ok),
            ?IF(Card#r_week_card.open_time =:= 0, ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_REWARD_002), ok),
            MaxDay = time_tool:diff_date(time_tool:now(), Card#r_week_card.open_time) + 1,
            ?IF(MaxDay >= Day, ok, ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_REWARD_003)),
            RewardConfig = get_reward_config(Day, CardID),
            Reward = lib_tool:string_to_intlist(RewardConfig#c_week_card_reward.reward),
            GoodsList = [#p_goods{type_id = ItemID, num = ItemNum, bind = ?IS_BIND(Bind)} || {ItemID, ItemNum, Bind} <- Reward],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_WEEK_CARD, GoodsList}],
            NewCard = Card#r_week_card{reward = [Day|Card#r_week_card.reward]},
            NewRoleWeekCard = RoleWeekCard#r_role_week_card{card_list = [NewCard|Other]},
            {ok, State#r_role{role_week_card = NewRoleWeekCard}, BagDoings};
        _ ->
            ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_BUY_004)
    end.


%%拿奖励配置
get_reward_config(Day, Card) ->
    List = lib_config:list(cfg_week_card_reward),
    get_reward_config(Day, Card, List).

get_reward_config(_Day, _Card, []) ->
    ?THROW_ERR(?ERROR_ROLE_WEEK_CARD_REWARD_001);
get_reward_config(Day, Card, [{_, Config}|T]) ->
    case Config#c_week_card_reward.day =:= Day andalso Config#c_week_card_reward.card_id =:= Card of
        true ->
            Config;
        _ ->
            get_reward_config(Day, Card, T)
    end.

get_log(#r_role{role_id = RoleID , role_attr = RoleAttr}, Price) ->
    #log_role_gear{
        role_id = RoleID,
        game_channel_id = RoleAttr#r_role_attr.game_channel_id,
        channel_id = RoleAttr#r_role_attr.channel_id,
        type = ?LOG_GEAR_WEEK_CARD,
        gear = Price
    }.