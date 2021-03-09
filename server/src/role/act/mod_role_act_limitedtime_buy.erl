%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十二月 2018 15:34
%%%-------------------------------------------------------------------
-module(mod_role_act_limitedtime_buy).
-author("WZP").

-include("role.hrl").
-include("act.hrl").
-include("role_extra.hrl").
-include("vip.hrl").
-include("proto/act_limited_time_buy.hrl").
-include("proto/mod_role_act_limitedtime_buy.hrl").
%% API

-export([
    online/1,
    handle/2,
    system_open_info/1
]).



system_open_info(State) ->
    online(State).


online(#r_role{role_id = RoleID} = State) ->
    case mod_role_act:is_act_open(?ACT_LIMITED_TIME_BUY, State) of
        true ->
            {Times, Num, MixLogs, BigReward} = world_data:get_act_limitedtime_buy(),
            case act_limited_time_buy:get_buy_data(RoleID) of
                [] ->
                    MyTimes = 0;
                [#r_act_limitedtime_buy{buy_times = BuyTimes}] ->
                    MyTimes = BuyTimes
            end,
            common_misc:unicast(RoleID, #m_act_limitedtime_buy_info_toc{stage = Times, logs = MixLogs, big_reward_logs = BigReward, buy_num = Num, times = MyTimes});
        _ ->
            ok
    end,
    State.



handle(online_info, State) ->
    online(State);
handle({#m_act_limitedtime_buy_tos{times = Times}, RoleID, _PID}, State) ->
    do_act_limitedtime_buy(RoleID, State, Times).



do_act_limitedtime_buy(RoleID, State, Times) ->
    case catch check_can_buy(State, RoleID, Times) of
        {ok, BagDoings, AssetDoing, State2, BuyNum, Log} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoings, State3),
            common_misc:unicast(RoleID, #m_act_limitedtime_buy_toc{num = BuyNum}),
            mod_role_dict:add_background_logs(Log),
            hook_role:limitedtime_buy(State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_limitedtime_buy_toc{err_code = ErrCode}),
            State
    end.



check_can_buy(#r_role{role_attr = RoleAttr} = State, RoleID, Times) ->
    ?IF(mod_role_act:is_act_open(?ACT_LIMITED_TIME_BUY, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    [GConfig] = lib_config:find(cfg_global, ?GLOBAL_LIMITEDTIME_BUY),
    [Price, _DayAllTimes, _Times, Price2|_] = GConfig#c_global.list,
    ?IF(Times > 10, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    Price3 = ?IF(Times =:= 1, Price, Price2),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Price3, ?ASSET_GOLD_REDUCE_FROM_LIMITEDTIME_BUY, State),
    {GoodsList, Logs} = get_reward(Times, RoleAttr#r_role_attr.role_name),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_LIMITEDTIME_BUY, GoodsList}],
    case act_limited_time_buy:buy(RoleID, Logs, Times, RoleAttr#r_role_attr.role_name) of
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode);
        {ok, BuyNum} ->
            LogBackGround = get_log(State, Price),
            {ok, BagDoings, AssetDoing, State, BuyNum, LogBackGround}
    end.

get_reward(Times, RoleName) ->
    {Round, _, _, _} = world_data:get_act_limitedtime_buy(),
    [Config] = lib_config:find(cfg_act_limitedtime_buy, Round),
    case common_config:is_merge() of
        true ->
            Reward = lib_tool:string_to_intlist(Config#c_act_limitedtime_buy.merge_reward);
        _ ->
            Reward = lib_tool:string_to_intlist(Config#c_act_limitedtime_buy.reward)
    end,
    Reward2 = [{Weight, {ItemId, ItemNum, ItemBind, ItemIsLog}} || {ItemId, ItemNum, ItemBind, _, Weight, ItemIsLog} <- Reward],
    get_reward(Times, Reward2, RoleName, [], []).

get_reward(Times, Reward2, RoleName, GoodsList, Logs) when Times > 0 ->
    {Id, Num, Bind, IsLog} = lib_tool:get_weight_output(Reward2),
    NewLogs = case ?INT2BOOL(IsLog) of
                  true ->
                      [#p_limitedtime_buy{reward = Id, type = 2, name = RoleName, time = time_tool:now()}|Logs];
                  _ ->
                      Logs
              end,
    get_reward(Times - 1, Reward2, RoleName, [#p_goods{type_id = Id, num = Num, bind = ?IS_BIND(Bind)}|GoodsList], NewLogs);
get_reward(_Times, _Reward2, _RoleName, GoodsList, Logs) ->
    {GoodsList, Logs}.

get_log(#r_role{role_id = RoleID, role_attr = RoleAttr}, Price) ->
    #log_role_gear{
        role_id = RoleID,
        game_channel_id = RoleAttr#r_role_attr.game_channel_id,
        channel_id = RoleAttr#r_role_attr.channel_id,
        type = ?LOG_GEAR_LIMITED_TIME_BUY,
        gear = Price
    }.