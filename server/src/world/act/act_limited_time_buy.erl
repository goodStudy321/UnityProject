%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十二月 2018 15:05
%%%-------------------------------------------------------------------
-module(act_limited_time_buy).
-author("WZP").
-include("global.hrl").
-include("act.hrl").
-include("role.hrl").
-include("letter.hrl").
-include("proto/act_limited_time_buy.hrl").
-include("proto/mod_role_act_limitedtime_buy.hrl").
%% API
-export([
    init/2,
    handle/1,
    end_time/0,
    zero/0,
    terminate/0
]).

-export([
    buy/4,
    random_big_reward_i/2,
    init_role_data/2,
    get_buy_data/1,
    vip_up/2,
    gm_set_round/1,
    get_max_round/0
]).


gm_set_round_i(NewRound) ->
    {Round, _Times, MixLogs, BigReward} = world_data:get_act_limitedtime_buy(),
    AllList = ets:tab2list(?ETS_ACT_LIMITEDTIME_BUY),
    AccNum = clean_buy_times(AllList),
    [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
    [_, X, Times|_] = GConfig#c_global.list,
    NewLogs = case random_big_reward(AccNum, AllList, X, Times) of
                  {BigRewardRole, BigRewardName} ->
                      Reward = send_big_reward(BigRewardRole, Round),
                      {RoundLetter, _} = get_letter_info(),
                      RoundLetter2 = RoundLetter#r_letter_info{text_string = [BigRewardName]},
                      common_letter:send_letter(?GM_MAIL_ID, RoundLetter2),
                      [#p_limitedtime_buy{name = BigRewardName, time = time_tool:now(), type = 1, reward = Reward}];
                  _ ->
                      []
              end,
    AllLogs = add_logs(NewLogs, MixLogs),
    world_data:set_act_limitedtime_buy({NewRound, Times, AllLogs, NewLogs ++ BigReward}),
    ?ERROR_MSG("--------gm_set_round-----------------------~w", [NewRound]),
    BcLevel = get_min_level(),
    Condition = #r_broadcast_condition{min_level = BcLevel},
    common_broadcast:bc_record_to_world_by_condition(#m_act_limitedtime_buy_info_i_toc{buy_num = Times, log = NewLogs}, Condition),
    common_broadcast:bc_record_to_world_by_condition(#m_act_limitedtime_buy_round_toc{stage = NewRound}, Condition),
    ok.

gm_set_round(Round) ->
    world_act_server:info({mod, ?MODULE, {gm, Round}}).



init(StartTime, Now) ->
    DiffDate = time_tool:diff_date(Now, StartTime),
    MaxRound = get_max_round(),
    NewRound = ?IF((DiffDate + 1) rem MaxRound =:= 0, MaxRound, (DiffDate + 1) rem MaxRound),
    [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
    [_, _, Times|_] = GConfig#c_global.list,
    lib_tool:init_ets(?ETS_ACT_LIMITEDTIME_BUY, #r_act_limitedtime_buy.role_id),
    world_data:set_act_limitedtime_buy({NewRound, Times, [], []}),
    ?ERROR_MSG("--------init-----------------------~w", [NewRound]),
    %%{奖励轮 ， 剩余 ， 日志 ，混合日志大奖日志}
    common_broadcast:bc_role_info_to_world({mod, mod_role_act_limitedtime_buy, online_info}),
    [#c_act{min_level = MinLevel}] = lib_config:find(cfg_act, ?ACT_LIMITED_TIME_BUY),
    NewRoundLetter1 = #r_letter_info{
        days = 1,
        template_id = ?LETTER_TEMPLATE_LIMITED_TIME_BUY_START_I,
        condition = #r_gm_condition{min_level = MinLevel}
    },
    NewRoundLetter2 = #r_letter_info{
        days = 1,
        template_id = ?LETTER_TEMPLATE_LIMITED_TIME_BUY_START,
        condition = #r_gm_condition{min_level = MinLevel}
    },
    set_letter_info({NewRoundLetter1, NewRoundLetter2}),
    set_min_level(MinLevel).

end_time() ->
    zero(),   %%  活动结束再 59秒   不过 0 点  强行触发
    ets:delete(?ETS_ACT_LIMITEDTIME_BUY),
    ok.


terminate() ->
    AllList = ets:tab2list(?ETS_ACT_LIMITEDTIME_BUY),
    AccNum = clean_buy_times(AllList),
    [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
    [_, X, Times|_] = GConfig#c_global.list,
    {Round, Times, _MixLogs, _BigReward} = world_data:get_act_limitedtime_buy(),
    case random_big_reward(AccNum, AllList, X, Times) of
        {BigRewardRole, BigRewardName} ->
            _Reward = send_big_reward(BigRewardRole, Round),
            {RoundLetter, _} = get_letter_info(),
            RoundLetter2 = RoundLetter#r_letter_info{text_string = [BigRewardName]},
            common_letter:send_letter(?GM_MAIL_ID, RoundLetter2);
        _ ->
            ok
    end,
    ?ERROR_MSG("--------terminate-----------------------~w", [terminate]),
    ok.

zero() ->
    {Round, _Times, MixLogs, BigReward} = world_data:get_act_limitedtime_buy(),
    case lib_config:find(cfg_act_limitedtime_buy, Round + 1) of
        [] ->
            NewRound = 1;
        _ ->
            NewRound = Round + 1
    end,
    AllList = ets:tab2list(?ETS_ACT_LIMITEDTIME_BUY),
    AccNum = clean_buy_times(AllList),
    [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
    [_, X, Times|_] = GConfig#c_global.list,
    NewLogs = case random_big_reward(AccNum, AllList, X, Times) of
                  {BigRewardRole, BigRewardName} ->
                      Reward = send_big_reward(BigRewardRole, Round),
                      {RoundLetter, _} = get_letter_info(),
                      RoundLetter2 = RoundLetter#r_letter_info{text_string = [BigRewardName]},
                      common_letter:send_letter(?GM_MAIL_ID, RoundLetter2),
                      [#p_limitedtime_buy{name = BigRewardName, time = time_tool:now(), type = 1, reward = Reward}];
                  _ ->
                      []
              end,
    AllLogs = add_logs(NewLogs, MixLogs),
    world_data:set_act_limitedtime_buy({NewRound, Times, AllLogs, NewLogs ++ BigReward}),
    ?ERROR_MSG("--------zero-----------------------~w", [zero]),
    ?ERROR_MSG("--------Round-----------------------~w", [Round]),
    ?ERROR_MSG("--------NewRound-----------------------~w", [NewRound]),
    BcLevel = get_min_level(),
    Condition = #r_broadcast_condition{min_level = BcLevel},
    common_broadcast:bc_record_to_world_by_condition(#m_act_limitedtime_buy_info_i_toc{buy_num = Times, log = NewLogs}, Condition),
    common_broadcast:bc_record_to_world_by_condition(#m_act_limitedtime_buy_round_toc{stage = NewRound}, Condition),
    ok.



buy(RoleID, Logs, Times, RoleName) ->
    world_act_server:call({mod, act_limited_time_buy, {buy, RoleID, Logs, Times, RoleName}}).

vip_up(RoleID, AddTimes) ->
    world_act_server:call({mod, act_limited_time_buy, {vip_up, RoleID, AddTimes}}).

init_role_data(RoleID, AddTimes) ->
    world_act_server:call({mod, act_limited_time_buy, {init_role_data, RoleID, AddTimes}}).

handle({buy, RoleID, Logs, Times, RoleName}) ->
    do_buy(RoleID, Logs, Times, RoleName);
handle({gm, Round}) ->
    gm_set_round_i(Round);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

do_buy(RoleID, Logs, Times, RoleName) ->
    case catch check_can_buy(RoleID, Logs, Times, RoleName) of
        {ok, NewBuyNum} ->
            {ok, NewBuyNum};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_buy(RoleID, NewLogs, Times, RoleName) ->
    Data = case get_buy_data(RoleID) of
               [] ->
                   #r_act_limitedtime_buy{role_id = RoleID, name = RoleName};
               [Res] ->
                   Res
           end,
    Data2 = Data#r_act_limitedtime_buy{buy_times = Data#r_act_limitedtime_buy.buy_times + Times, name = RoleName},
    {Round, Num, MixLogs, BigRewardLogs} = world_data:get_act_limitedtime_buy(),
    NewNum = Num - Times,
    ?IF(NewNum < 0, ?THROW_ERR(?ERROR_ACT_LIMITEDTIME_BUY_001), ok),   %%一次购买只能买一轮产品   简化check_can_buy操作
    set_buy_data(Data2),
    {NewLogs2, BigRewardLogs3} = check_can_buy(Num, NewNum, BigRewardLogs, NewLogs, Round),
    NewLogs3 = add_logs(NewLogs2, MixLogs),
    {NewNum2, NewBuyNum} = case NewNum =:= 0 of
                               true ->
                                   [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
                                   [_, _, AllTimes|_] = GConfig#c_global.list,
                                   {AllTimes, 0};
                               _ ->
                                   {NewNum, Data2#r_act_limitedtime_buy.buy_times}
                           end,
    world_data:set_act_limitedtime_buy({Round, NewNum2, NewLogs3, BigRewardLogs3}),
    BcLevel = get_min_level(),
    Condition = #r_broadcast_condition{min_level = BcLevel},
    common_broadcast:bc_record_to_world_by_condition(#m_act_limitedtime_buy_info_i_toc{buy_num = NewNum2, log = NewLogs2}, Condition),
    {ok, NewBuyNum}.

check_can_buy(Num, Num, BigRewardLogs, NewLogs, _Round) ->
    {NewLogs, BigRewardLogs};
check_can_buy(StartNum, EndNum, BigRewardLogs, NewLogs, Round) ->
    case StartNum - 1 =:= 0 of
        true ->
            AllList = ets:tab2list(?ETS_ACT_LIMITEDTIME_BUY),
            AccNum = clean_buy_times(AllList),
            [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
            [_, X, Times|_] = GConfig#c_global.list,
            {NewLogs2, BigRewardLogs3} = case random_big_reward(AccNum, AllList, X, Times) of
                                             {BigRewardRole, BigRewardName} ->
                                                 Reward = send_big_reward(BigRewardRole, Round),
                                                 {RoundLetter, _} = get_letter_info(),
                                                 RoundLetter2 = RoundLetter#r_letter_info{text_string = [BigRewardName]},
                                                 common_letter:send_letter(?GM_MAIL_ID, RoundLetter2),
                                                 RewardName = case lib_config:find(cfg_item, Reward) of
                                                                  [ItemConfig] ->
                                                                      ItemConfig#c_item.name;
                                                                  _ ->
                                                                      ""
                                                              end,
                                                 common_broadcast:send_world_common_notice(?NOTICE_LIMITED_BUY, [BigRewardName, RewardName]),
                                                 BigRewardLogs2 = [#p_limitedtime_buy{name = BigRewardName, time = time_tool:now(), type = 1, reward = Reward}|BigRewardLogs],
                                                 {[#p_limitedtime_buy{name = BigRewardName, time = time_tool:now(), type = 1, reward = Reward}|NewLogs], BigRewardLogs2};
                                             _ ->
                                                 {NewLogs, BigRewardLogs}
                                         end;
        _ ->
            NewLogs2 = NewLogs,
            BigRewardLogs3 = BigRewardLogs
    end,
    check_can_buy(StartNum - 1, EndNum, BigRewardLogs3, NewLogs2, Round).


%%发终结大奖
send_big_reward(BigRewardRole, Round) ->
    [RoundConfig] = lib_config:find(cfg_act_limitedtime_buy, Round),
    case  common_config:is_merge() of
        true->
            [Type, Num, Bind]=  RoundConfig#c_act_limitedtime_buy.merge_big_reward;
        _->
            [Type, Num, Bind]=  RoundConfig#c_act_limitedtime_buy.big_reward
    end,
    GoodsList = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)}],
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_LIMITED_TIME_BUY_SEND_REWARD,
        action = ?ITEM_GAIN_LIMITEDTIME_BUY_BIG_REWARD,
        goods_list = GoodsList},
    common_letter:send_letter(BigRewardRole, LetterInfo),
    Type.


%%购买库存达到（＜）X，按云购库存总份数的概率开奖，即本期可能没有得奖玩家  |  购买库存达到（≥）X，从已购买的云购库存份数中开奖，即必从购买者中开出一名得奖
random_big_reward(AccNum, List, X, AllNum) ->
    AccNum2 = case AccNum >= X of
                  true ->
                      AccNum;
                  _ ->
                      AllNum
              end,
    RandomNum = lib_tool:random(AccNum2),
    random_big_reward_i(RandomNum, List).

random_big_reward_i(_RandomNum, []) ->
    people;
random_big_reward_i(RandomNum, [#r_act_limitedtime_buy{role_id = RoleID, buy_times = Val, name = Name}|T]) ->
    case RandomNum =< Val andalso Val =/= 0 of
        true ->
            {RoleID, Name};
        _ ->
            random_big_reward_i(RandomNum - Val, T)
    end.

set_letter_info(Record) ->
    erlang:put({?MODULE, letter_info}, Record).
get_letter_info() ->
    erlang:get({?MODULE, letter_info}).

set_min_level(MinLevel) ->
    erlang:put({?MODULE, min_level}, MinLevel).
get_min_level() ->
    case erlang:get({?MODULE, min_level}) of
        Level when erlang:is_integer(Level) -> Level;
        _ -> 0
    end.


clean_buy_times(List) ->
    clean_buy_times(List, 0, []).

clean_buy_times([], AccNum, Roles) ->
    common_broadcast:bc_record_to_roles(Roles, #m_act_limitedtime_buy_toc{num = 0}),
    AccNum;
clean_buy_times([#r_act_limitedtime_buy{buy_times = BuyTimes, role_id = RoleID} = Data|T], AccNum, Roles) ->
    set_buy_data(Data#r_act_limitedtime_buy{buy_times = 0}),
    case BuyTimes > 0 of
        true ->
            clean_buy_times(T, AccNum + BuyTimes, [RoleID|Roles]);
        _ ->
            clean_buy_times(T, AccNum, Roles)
    end.


set_buy_data(Data) ->
    ets:insert(?ETS_ACT_LIMITEDTIME_BUY, Data).

get_buy_data(RoleID) ->
    ets:lookup(?ETS_ACT_LIMITEDTIME_BUY, RoleID).


get_max_round() ->
    get_max_round(1).
get_max_round(Round) ->
    case lib_config:find(cfg_act_limitedtime_buy, Round) of
        [] ->
            Round - 1;
        _ ->
            get_max_round(Round + 1)
    end.

add_logs(NewLogs, OldLogs) ->
    AddLength = erlang:length(NewLogs),
    ALLLength = erlang:length(OldLogs),
    case AddLength + ALLLength > ?ACT_LIMITED_TIME_BUY_LOG of
        true ->
            NewLogs ++ delete_log(AddLength + ALLLength - ?ACT_LIMITED_TIME_BUY_LOG, OldLogs);
        _ ->
            NewLogs ++ OldLogs
    end.

delete_log(Num, Logs) when Num > 0 ->
    Logs2 = lists:droplast(Logs),
    delete_log(Num - 1, Logs2);
delete_log(_Num, Logs) ->
    Logs.
