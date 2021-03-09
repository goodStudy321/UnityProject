%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 六月 2018 10:51
%%%-------------------------------------------------------------------
-module(mod_role_act_firstrecharge).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("proto/mod_role_act_firstrecharge.hrl").

%% API
-export([
    init/1,
    online/1,
    zero/1,
    handle/2
]).

-export([
    do_recharge/2,
    is_first_pay/1
]).



init(#r_role{role_id = RoleID, role_act_firstrecharge = undefined} = State) ->
    FirstRecharge = #r_role_act_firstrecharge{role_id = RoleID},
    State#r_role{role_act_firstrecharge = FirstRecharge};
init(State) ->
    State.

online(#r_role{role_id = RoleID, role_act_firstrecharge = FirstRecharge} = State) ->
    #r_role_act_firstrecharge{pay_time = PayTime, reward_list = RewardList} = FirstRecharge,
    common_misc:unicast(RoleID, #m_act_firstrecharge_toc{pay_time = PayTime, reward_list = RewardList}),
    State.

zero(State) ->
    online(State).

handle({#m_act_firstrecharge_reward_tos{reward_day = RewardDay}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, RewardDay, State).

do_recharge(#r_role{role_id = RoleID, role_act_firstrecharge = FirstRecharge} = State, RechargeNum) ->
    [{_, Config}|_] = cfg_act_firstrecharge:list(),
    #r_role_act_firstrecharge{pay_time = PayTime, reward_list = RewardList} = FirstRecharge,
    case Config#c_act_firstrecharge.quota =< RechargeNum andalso PayTime =:= 0 of
        true ->
            Now = time_tool:now(),
            FirstRecharge2 = FirstRecharge#r_role_act_firstrecharge{pay_time = Now},
            common_misc:unicast(RoleID, #m_act_firstrecharge_toc{pay_time = Now, reward_list = RewardList}),
            State2 = State#r_role{role_act_firstrecharge = FirstRecharge2},
            common_broadcast:send_world_common_notice(?NOTICE_FIRST_RECHARGE, [mod_role_data:get_role_name(State2)]),
            hook_role:role_first_recharge(State2);
        _ ->
            State
    end.

is_first_pay(State) ->
    #r_role{role_act_firstrecharge = FirstRecharge} = State,
    FirstRecharge#r_role_act_firstrecharge.pay_time > 0.


do_get_reward(RoleID, RewardDay, State) ->
    case catch check_can_get(RewardDay, State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_act_firstrecharge_reward_toc{reward_day = RewardDay}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_firstrecharge_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(RewardDay, #r_role{role_act_firstrecharge = FirstRecharge} = State) ->
    #r_role_act_firstrecharge{pay_time = PayTime, reward_list = RewardList} = FirstRecharge,
    ?IF(lists:member(RewardDay, RewardList), ?THROW_ERR(?ERROR_ACT_FIRSTRECHARGE_REWARD_001), ok),
    ?IF(PayTime > 0, ok, ?THROW_ERR(?ERROR_ACT_FIRSTRECHARGE_REWARD_002)),
    ?IF((time_tool:diff_date(time_tool:now(), PayTime) + 1 ) >= RewardDay, ok, ?THROW_ERR(?ERROR_ACT_FIRSTRECHARGE_REWARD_002)),
    Config =
        case lib_config:find(cfg_act_firstrecharge, RewardDay) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_ACT_FIRSTRECHARGE_REWARD_003)
        end,
    FirstRecharge2 = FirstRecharge#r_role_act_firstrecharge{reward_list = [RewardDay|RewardList]},
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(Config#c_act_firstrecharge.reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_FIRSTREECHARGE, GoodsList}],
    State2 = State#r_role{role_act_firstrecharge = FirstRecharge2},
    {ok, BagDoings, State2}.























