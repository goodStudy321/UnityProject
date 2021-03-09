%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2019 10:25
%%%-------------------------------------------------------------------
-module(mod_role_money_tree).
-author("WZP").
-include("role.hrl").
-include("vip.hrl").
-include("proto/mod_role_money_tree.hrl").
%% API
-export([
    function_open/1,
    online/1,
    handle/2,
    day_reset/1
]).


function_open(#r_role{role_money_tree = undefined, role_id = RoleID} = State) ->
    Info = #r_role_money_tree{role_id = RoleID},
    online(State#r_role{role_money_tree = Info});
function_open(State) ->
    State.


online(#r_role{role_money_tree = undefined} = State) ->
    State;
online(#r_role{role_money_tree = RoleMoneyTree, role_id = RoleID} = State) ->
    Logs = world_data:get_money_tree(),
    common_misc:unicast(RoleID, #m_money_tree_toc{times = RoleMoneyTree#r_role_money_tree.times, log = lists:reverse(RoleMoneyTree#r_role_money_tree.log),
                                                  other_log = lists:reverse(Logs)}),
    State.

day_reset(#r_role{role_money_tree = undefined} = State) ->
    State;
day_reset(#r_role{role_money_tree = RoleMoneyTree} = State) ->
    RoleMoneyTree2 = RoleMoneyTree#r_role_money_tree{times = 0},
    State2 = State#r_role{role_money_tree = RoleMoneyTree2},
    online(State2).

handle({#m_money_tree_i_tos{}, RoleID, _PID}, State) ->
    do_money_tree(RoleID, State).


do_money_tree(RoleID, State) ->
    case catch check_can_do(State) of
        {ok, State2, AssetDoing, Log, Money, Rate} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_money_tree_i_toc{money = Money, log = Log, rate = Rate}),
            hook_role:money_tree(State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_money_tree_i_toc{err_code = ErrCode}),
            State
    end.

check_can_do(#r_role{role_money_tree = RoleMoneyTree, role_vip = RoleVip, role_attr = RoleAttr} = State) ->
    [VipConfig] = lib_config:find(cfg_vip_level, RoleVip#r_role_vip.level),
    ?IF(VipConfig#c_vip_level.money_tree_times > RoleMoneyTree#r_role_money_tree.times, ok, ?THROW_ERR(?ERROR_MONEY_TREE_I_001)),
    NewTimes = RoleMoneyTree#r_role_money_tree.times + 1,
    [Config] = lib_config:find(cfg_money_tree, NewTimes),
    [_, NeedGold|_] = Config#c_money_tree.need,
    [_, Silver|_] = Config#c_money_tree.reward,
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_MONEY_TREE, State),
    DrawList = [{RateConfig#c_money_tree_rate.weight, RateConfig#c_money_tree_rate.rate} || {_, RateConfig} <- cfg_money_tree_rate:list()],
    Rate = lib_tool:get_weight_output(DrawList),
    Money = Silver * Rate,
    case Rate > 1 of
        true ->
            world_log_statistics_server:info({money_tree_log, #p_money_tree_log{type = 1, name = RoleAttr#r_role_attr.role_name, rate = Rate, money = Money}});
        _ ->
            ok
    end,
    AssetDoing2 = [{add_silver, ?ASSET_GOLD_ADD_FROM_MONEY_TREE, Money}|AssetDoing],
    Log = #p_money_tree_log{type = 2, rate = Rate, money = Money},
    Logs = lib_tool:add_log(RoleMoneyTree#r_role_money_tree.log, Log, 30),
    RoleMoneyTree2 = RoleMoneyTree#r_role_money_tree{times = NewTimes, log = Logs},
    {ok, State#r_role{role_money_tree = RoleMoneyTree2}, AssetDoing2, Log, Money, Rate}.







