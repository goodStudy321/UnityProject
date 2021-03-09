%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 九月 2019 12:21
%%%-------------------------------------------------------------------
-module(mod_role_act_pay).
-author("chenqinyong").
-include("role.hrl").
-include("cycle_act.hrl").
-include("pay.hrl").
-include("activity.hrl").
-include("proto/mod_role_cycle_act.hrl").
%% API
-export([
    init/1,
    init_data/2,
    online/1,
    first_recharge/2
]).

init(#r_role{role_id = RoleID, role_act_firstpay = undefined} = State) ->
    RoleFirstPay = #r_role_act_firstpay{role_id = RoleID},
    State#r_role{role_act_firstpay = RoleFirstPay};
init(State) ->
    State.


init_data(StartTime, State) ->
    RoleFirstPay = #r_role_act_firstpay{
        role_id = State#r_role.role_id,
        goods_list = [],
        open_time = StartTime
    },
    State2 = State#r_role{role_act_firstpay = RoleFirstPay},
    online(State2).

online(State) ->
    State.

first_recharge(State, ProductID) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_CHARGE, State) of
        true ->
            #r_role{role_id = RoleID, role_act_firstpay = RoleActFirstPay} = State,
            #r_role_act_firstpay{goods_list = GoodsList0} = RoleActFirstPay,
            [_Value, _Power, _TitleID, Multiple] = common_misc:get_global_list(?GLOBAL_FIRST_CHARGE),
            Multiple2 = erlang:max(Multiple - 1, 0),
            GoodsList = common_misc:get_global_string_list(?GLOBAL_FIRST_CHARGE),
            GoodsList1 = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- GoodsList],
            case lists:member(ProductID, [34, 35, 36, 37]) of
                true ->
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_FIRST_PAY_GAIN,
                        action = ?ITEM_GAIN_FIRST_RECHARGE,
                        goods_list = GoodsList1
                    },
                    common_letter:send_letter(RoleID, LetterInfo),
                    [#c_pay{add_gold = AddGold}] = lib_config:find(cfg_pay, ProductID),
                    common_misc:unicast(RoleID, #m_cycle_update_toc{act = #p_cycle_act{id = ?CYCLE_ACT_CHARGE, val = ?CYCLE_ACT_STATUS_CLOSE}}),
                    AssetDoings = [{add_gold, ?ASSET_GOLD_ADD_FROM_PAY, AddGold * Multiple2, 0}],
                    State2 = mod_role_asset:do(AssetDoings, State),
                    RoleActFirstPay2 = RoleActFirstPay#r_role_act_firstpay{goods_list = GoodsList0 ++ GoodsList1},
                    State2#r_role{role_act_firstpay = RoleActFirstPay2};
                _ ->
                    State
            end;
        _ ->
            State
    end.
