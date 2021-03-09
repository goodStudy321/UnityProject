%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 九月 2019 18:10
%%%-------------------------------------------------------------------
-module(mod_role_act_lucky_cat).
-author("chenqinyong").
-include("role.hrl").
-include("cycle_act.hrl").
-include("behavior_log.hrl").
-include("lucky_cat.hrl").
-include("proto/mod_role_act_lucky_cat.hrl").
%% API
-export([
    init/1,
    init_data/2,
    online/1,
    handle/2
]).

init(#r_role{role_id = RoleID, role_act_luckycat = undefined} = State) ->
    LuckyCat = #r_role_act_lukcycat{role_id = RoleID},
    State#r_role{role_act_luckycat = LuckyCat};
init(State) ->
    State.

init_data(StartTime, State) ->
    LuckyCat = #r_role_act_lukcycat{
        role_id = State#r_role.role_id,
        times = 0,
        open_time = StartTime
    },
    State2 = State#r_role{role_act_luckycat = LuckyCat},
    online(State2).

online(#r_role{role_id = RoleID, role_act_luckycat = LuckyCat} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_LUCKY_CAT, State) of
        true ->
            case LuckyCat of
                #r_role_act_lukcycat{role_id = RoleID, times = Times} ->
                    Logs = world_data:get_lucky_cat_logs(),
                    common_misc:unicast(RoleID, #m_luckycat_info_toc{logs = Logs, times = Times}),
                    State;
                _ ->
                    State
            end;
        _ ->
            State
    end.

handle({#m_luckycat_lottery_tos{times = Times}, RoleID, _PID}, State) ->
    do_lottery(RoleID, Times, State).

do_lottery(RoleID, Times, State) ->
    case catch check_do_lottery(Times, State) of
        {ok, AssetDoing, Rate, LogList, GoldList,AddGold, State2} ->
            world_cycle_act_server:add_luckycat_logs(LogList),
            State3 = mod_role_asset:do(AssetDoing, State2),
            AssetDoings1 = [{add_gold, ?ASSET_GOLD_ADD_FROM_LUCKY_CAT, AddGold, 0}],
            State4 = mod_role_asset:do(AssetDoings1, State3),
            common_misc:unicast(RoleID, #m_luckycat_lottery_toc{rate = Rate, gold_list = GoldList}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_luckycat_lottery_toc{err_code = ErrCode}),
            State
    end.

check_do_lottery(Times, State) ->
    #r_role{role_attr = #r_role_attr{role_name = RoleName}, role_act_luckycat = RoleActLuckyCat} = State,
    #r_role_act_lukcycat{times = Times0} = RoleActLuckyCat,
    ConfigList = lib_config:list(cfg_act_lucky_cat),
    ?IF(Times - 1 =:= Times0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ?IF(Times > erlang:length(ConfigList), ?THROW_ERR(?ERROR_LUCKYCAT_LOTTERY_001), ok),
    [#c_act_lucky_cat_info{consume_gold = ConsumeGold, rate_string = RateString}] = lib_config:find(cfg_act_lucky_cat, Times),
    RateList = lib_tool:string_to_intlist(RateString, ",", ":"),
    RateList2 = [{Weight, Rate0} || {Rate0, Weight} <- RateList],
    Rate = lib_tool:get_weight_output(RateList2),
    Rate1 = Rate/?RATE_100,
    AddGold = lib_tool:floor(ConsumeGold * (Rate1)),
    GoldList = [#p_kv{id = 2, val = AddGold}],
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, ConsumeGold, ?ASSET_GOLD_REDUCE_FROM_LUCKY_CAT, State),
    StringList = [RoleName, lib_tool:to_list(ConsumeGold), lib_tool:to_list(Rate1), lib_tool:to_list(AddGold)],
    LogList = get_world_log_list(RoleName, ConsumeGold, Rate, AddGold),
    ?IF(Rate1 =:= 2 orelse Rate1 =:= 3, common_broadcast:send_delay_world_common_notice(5, ?NOTICE_HIGH_LUCKY_CAT, StringList),
        common_broadcast:send_delay_world_common_notice(5, ?NOTICE_LOW_LUCKY_CAT, StringList)),
    RoleActLuckyCat2 = RoleActLuckyCat#r_role_act_lukcycat{times = Times},
    State2 = State#r_role{role_act_luckycat = RoleActLuckyCat2},
    {ok, AssetDoings, Rate, LogList, GoldList, AddGold, State2}.

get_world_log_list(RoleName, ConsumeGold, Rate, AddGold) ->
    [#p_luckycat_log{name = RoleName, consume_gold = ConsumeGold, rate = Rate, add_gold = lib_tool:floor(AddGold)}].