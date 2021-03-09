%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 九月 2019 17:16
%%%-------------------------------------------------------------------
-module(mod_role_act_trench_ceremony).
-author("chenqinyong").
-include("role.hrl").
-include("cycle_act.hrl").
-include("behavior_log.hrl").
-include("global.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_act_trench_ceremony.hrl").
%% API
-export([
    init_data/2,
    online/1,
    do_recharge/2,
    handle/2,
    get_act_trench_ceremony/2,
    set_act_trench_ceremony/2
]).

init_data(StartTime, State) ->
    #r_role{role_pay = RolePay} = State,
    #r_role_pay{today_pay_gold = TodayPayGold} = RolePay,
    AccRecharge = lib_tool:to_integer(TodayPayGold/10),
    ActTrenchCeremony = #r_act_trench_ceremony{
        role_id = State#r_role.role_id,
        status = ?TRENCH_CEREMONY_NONE,
        accrecharge = AccRecharge,
        open_time = StartTime
    },
    ActTrenchCeremony2 = do_recharge2(AccRecharge, ActTrenchCeremony),
    State2 = set_act_trench_ceremony(ActTrenchCeremony2, State),
    online(State2).

online(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TRENCH_CEREMONY, State) of
        true ->
            #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
            #r_role_attr{role_name = RoleName} = RoleAttr,
            #r_act_trench_ceremony{status = Status, accrecharge = AccRecharge} = get_act_trench_ceremony(RoleID, State),
            common_misc:unicast(RoleID, #m_trench_ceremony_toc{
                                role_id = RoleID,
                                name = RoleName,
                                accrecharge = AccRecharge,
                                status = Status}),
            State;
%%            case world_data:get_first_trench_ceremony() of
%%                #r_world_trench_ceremony{reward_role_id = RewardRoleID, status = Status, accrecharge = AccRecharge2} when RewardRoleID > 0-> %%
%%                    case RewardRoleID =:= RoleID of
%%                        true -> %% 可以领奖玩家是自己
%%                            common_misc:unicast(RoleID, #m_trench_ceremony_toc{role_id = RoleID, name = RoleName, accrecharge = AccRecharge, status = Status});
%%                        _ ->
%%                            common_misc:unicast(RoleID, #m_trench_ceremony_toc{
%%                                role_id = RewardRoleID,
%%                                name = common_role_data:get_role_name(RewardRoleID),
%%                                accrecharge = AccRecharge2,
%%                                status = Status})
%%                    end;
%%                _ ->
%%                    common_misc:unicast(RoleID, #m_trench_ceremony_toc{role_id = RoleID, name = RoleName, accrecharge = AccRecharge})
%%%%            end,
%%            State;
        _ ->
            State
    end.

%% 新版-只限制单人
do_recharge(State, PayFee) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TRENCH_CEREMONY, State) of
        true ->
            #r_role{role_id = RoleID} = State,
            #r_act_trench_ceremony{status = Status, accrecharge = AccRecharge} = ActTrenchCeremony = get_act_trench_ceremony(RoleID, State),
            case Status =:= ?TRENCH_CEREMONY_NONE of
                true ->
                    ActTrenchCeremony2 = do_recharge2(AccRecharge + lib_tool:to_integer(PayFee/100), ActTrenchCeremony),
                    State2 = set_act_trench_ceremony(ActTrenchCeremony2, State),
                    online(State2);
                _ ->
                    State
            end;
        _ ->
            State
    end.

do_recharge2(AccRecharge, ActTrenchCeremony) ->
    #r_act_trench_ceremony{status = Status} = ActTrenchCeremony,
    case Status =:= ?TRENCH_CEREMONY_NONE of
        true ->
            NeedMoney = common_misc:get_global_int(?GLOBAL_ACT_TRENCH_CEREMONY),
            Status2 = ?IF(AccRecharge >= NeedMoney, ?TRENCH_CEREMONY_CAN_REWARD, Status),
            ActTrenchCeremony #r_act_trench_ceremony{status = Status2, accrecharge = AccRecharge};
        _ ->
            ActTrenchCeremony
    end.



%%do_recharge(State, PayFee) ->
%%    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TRENCH_CEREMONY, State) of
%%        true ->
%%            #r_role{role_id = RoleID} = State,
%%            #r_act_trench_ceremony{accrecharge = AccRecharge} = ActTrenchCeremony = get_act_trench_ceremony(RoleID, State),
%%            AccRecharge2 = AccRecharge + lib_tool:to_integer(PayFee/100),
%%            ActTrenchCeremony2 =  ActTrenchCeremony #r_act_trench_ceremony{accrecharge = AccRecharge2},
%%            NeedMoney = common_misc:get_global_int(?GLOBAL_ACT_TRENCH_CEREMONY),
%%            State2 = set_act_trench_ceremony(ActTrenchCeremony2, State),
%%            ?IF(AccRecharge2 >= NeedMoney, act_trench_ceremony:recharge(RoleID, AccRecharge2), ok),
%%            online(State2);
%%        _ ->
%%            State
%%    end.

handle({#m_trench_ceremony_reward_tos{}, RoleID, _PID}, State) ->
    do_reward(RoleID, State).

do_reward(RoleID, State) ->
    case catch check_do_reward(RoleID, State) of
        {ok, Status2, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_trench_ceremony_reward_toc{status = Status2}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_trench_ceremony_reward_toc{err_code = ErrCode}),
            State
    end.

check_do_reward(RoleID, State) ->
    #r_act_trench_ceremony{status = Status} = ActTrenchCeremony = get_act_trench_ceremony(RoleID, State),
    ?IF(Status =:= ?TRENCH_CEREMONY_CAN_REWARD, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    GoodsList2 = common_misc:get_global_string_list(?GLOBAL_ACT_TRENCH_CEREMONY),
    GoodsList3 = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- GoodsList2],
    mod_role_bag:check_bag_empty_grid(GoodsList3, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_TRENCH_CEREMONY, GoodsList3}],
    Status2 = ?TRENCH_CEREMONY_HAS_REWARD,
    ActTrenchCeremony2 = ActTrenchCeremony#r_act_trench_ceremony{status = Status2},
    State2 = set_act_trench_ceremony(ActTrenchCeremony2, State),
    {ok, Status2, BagDoings, State2}.

%%do_reward(RoleID, State) ->
%%    case catch check_do_reward(State) of
%%        {ok, BagDoings} ->
%%            case act_trench_ceremony:reward(RoleID) of
%%                ok ->
%%                    common_misc:unicast(RoleID, #m_trench_ceremony_reward_toc{status = ?TRENCH_CEREMONY_HAS_REWARD}),
%%                    mod_role_bag:do(BagDoings, State);
%%                {error, ErrCode} ->
%%                    common_misc:unicast(RoleID, #m_trench_ceremony_reward_toc{err_code = ErrCode}),
%%                    State
%%            end;
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_trench_ceremony_reward_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%check_do_reward(State) ->
%%    GoodsList2 = common_misc:get_global_string_list(?GLOBAL_ACT_TRENCH_CEREMONY),
%%    GoodsList3 = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- GoodsList2],
%%    mod_role_bag:check_bag_empty_grid(GoodsList3, State),
%%    BagDoings = [{create, ?ITEM_GAIN_ACT_TRENCH_CEREMONY, GoodsList3}],
%%    {ok, BagDoings}.


%%%===================================================================
%%% 数据操作
%%%===================================================================
get_act_trench_ceremony(RoleID, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_TRENCH_CEREMONY, [], State),
    case lists:keyfind(RoleID, #r_act_trench_ceremony.role_id, List) of
        #r_act_trench_ceremony{} = ActTrenchCeremony ->
            ActTrenchCeremony;
        _ ->
            #r_act_trench_ceremony{role_id = RoleID}
    end.

set_act_trench_ceremony(ActTrenchCeremony, State) ->
    List = mod_role_extra:get_data(?EXTRA_KEY_TRENCH_CEREMONY, [], State),
    #r_act_trench_ceremony{role_id = RoleID} = ActTrenchCeremony,
    List2 = lists:keystore(RoleID, #r_act_trench_ceremony.role_id, List, ActTrenchCeremony),
    mod_role_extra:set_data(?EXTRA_KEY_TRENCH_CEREMONY, List2, State).