%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     玩家资产信息
%%% @end
%%% Created : 04. 七月 2017 20:44
%%%-------------------------------------------------------------------
-module(mod_role_asset).
-author("laijichang").
-include("role.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_role_asset.hrl").

%% API
-export([
    init/1,
    pre_enter/1,
    day_reset/1
]).

-export([
    do/2
]).

-export([
    add_asset_by_type/3,
    get_asset_by_type/2,
    check_asset_by_type/4
]).

-export([
    use_silver_item/3,
    use_gold_item/3,
    use_bind_gold_item/3,
    use_glory_item/3,
    use_bind_gold/2,
    use_gold/2
]).

-export([
    gm_set_gold/3,
    gm_set_silver/2
]).

init(#r_role{role_id = RoleID, role_asset = undefined} = State) ->
    State#r_role{role_asset = #r_role_asset{role_id = RoleID}};
init(State) ->
    State.


day_reset(#r_role{role_asset = RoleAsset} = State) ->
    RoleAsset2 = RoleAsset#r_role_asset{day_use_gold = 0},
    State#r_role{role_asset = RoleAsset2}.

pre_enter(State) ->
    #r_role{role_id = RoleID, role_asset = RoleAsset} = State,
    #r_role_asset{
        silver = Silver,
        gold = Gold,
        bind_gold = BindGold,
        score_list = ScoreList
    } = RoleAsset,
    DataRecord = #m_role_asset_info_toc{
        silver = Silver,
        gold = Gold,
        bind_gold = BindGold,
        score_list = ScoreList
    },
    common_misc:unicast(RoleID, DataRecord),
    State.

add_asset_by_type(AssetType, Num, Action) ->
    if
        AssetType =:= ?ASSET_SILVER ->
            {add_silver, Action, Num};
        AssetType =:= ?ASSET_GOLD ->
            {add_gold, Action, Num, 0};
        AssetType =:= ?ASSET_BIND_GOLD ->
            {add_gold, Action, 0, Num};
        true ->
            {add_score, Action, AssetType, Num}
    end.


get_asset_by_type(AssetType, State) ->
    #r_role{role_asset = RoleAsset} = State,
    #r_role_asset{gold = Gold, bind_gold = BindGold, silver = Silver, score_list = ScoreList} = RoleAsset,
    if
        AssetType =:= ?CONSUME_SILVER ->
            Silver;
        AssetType =:= ?CONSUME_UNBIND_GOLD ->
            Gold;
        AssetType =:= ?CONSUME_ANY_GOLD ->
            Gold + BindGold;
        AssetType =:= ?CONSUME_BIND_GOLD ->
            BindGold;
        true ->
            case lists:keyfind(AssetType, #p_dkv.id, ScoreList) of
                #p_dkv{val = Val} -> Val;
                _ -> 0
            end
    end.

check_asset_by_type(AssetType, AssetValue, Action, State) ->
    if
        AssetType =:= ?CONSUME_SILVER ->
            check_silver(AssetValue, State),
            [{reduce_silver, Action, AssetValue}];
        AssetType =:= ?CONSUME_UNBIND_GOLD ->
            check_unbind_gold(AssetValue, State),
            [{reduce_unbind_gold, Action, AssetValue}];
        AssetType =:= ?CONSUME_ANY_GOLD ->
            check_gold(AssetValue, State),
            [{reduce_gold, Action, AssetValue}];
        AssetType =:= ?CONSUME_BIND_GOLD ->
            check_bind_gold(AssetValue, State),
            [{reduce_bind_gold, Action, AssetValue}];
        true ->
            check_score(AssetType, AssetValue, State),
            [{reduce_score, Action, AssetType, AssetValue}]
    end.

%% 银两
check_silver(SilverNum, State) ->
    #r_role{role_asset = RoleAsset} = State,
    ?IF(RoleAsset#r_role_asset.silver >= SilverNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_SILVER)).

%% 不绑定元宝
check_unbind_gold(GoldNum, State) ->
    #r_role{role_asset = RoleAsset} = State,
    ?IF(RoleAsset#r_role_asset.gold >= GoldNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_UNBIND_GOLD)).

%% 优先绑定元宝
check_gold(GoldNum, State) ->
    #r_role{role_asset = RoleAsset} = State,
    ?IF(RoleAsset#r_role_asset.bind_gold + RoleAsset#r_role_asset.gold >= GoldNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_GOLD)).

%% 只能绑定元宝
check_bind_gold(GoldNum, State) ->
    #r_role{role_asset = RoleAsset} = State,
    ?IF(RoleAsset#r_role_asset.bind_gold >= GoldNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_BIND_GOLD)).

%% 检查积分
check_score(Key, NeedValue, State) ->
    #r_role{role_asset = RoleAsset} = State,
    case lists:keyfind(Key, #p_dkv.id, RoleAsset#r_role_asset.score_list) of
        #p_dkv{val = Value} when Value >= NeedValue ->
            ok;
        _ ->
            if
                Key =:= ?CONSUME_GLORY ->
                    ?THROW_ERR(?ERROR_COMMON_GLORY_NOT_ENOUGH);
                Key =:= ?CONSUME_TREASURE_SCORE ->
                    ?THROW_ERR(?ERROR_COMMON_TREASURE_SCORE_NOT_ENOUGH);
                Key =:= ?CONSUME_FORGE_SOUL ->
                    ?THROW_ERR(?ERROR_COMMON_FORGE_SOUL_NOT_ENOUGH);
                Key =:= ?CONSUME_WAR_GOD_SCORE ->
                    ?THROW_ERR(?ERROR_COMMON_WAR_GOD_SCORE_NOT_ENOUGH);
                Key =:= ?CONSUME_HUNT_TREASURE_SCORE ->
                    ?THROW_ERR(?ERROR_COMMON_HUNT_TREASURE_SCORE_NOT_ENOUGH);
                Key =:= ?CONSUME_FAMILY_CON ->
                    ?THROW_ERR(?ERROR_COMMON_FAMILY_CON_NOT_ENOUGH);
                true ->
                    ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_SCORE)
            end
    end.

do([], State) ->
    State;
do(Doings, #r_role{role_id = RoleID} = State) ->
    {State4, ChangeList, Logs, PFLogs} =
    lists:foldl( fun(Doing, {StateAcc, ChangeAcc, LogsAcc, PFLogsAcc}) ->
        case Doing of
            {add_silver, Action, AddSilver} when AddSilver > 0 ->
                {State2, AddList, RemainSilver} = add_silver(StateAcc, AddSilver),
                Log = get_silver_log(State2, Action, AddSilver, RemainSilver),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc};
            {add_gold, _Action, 0, 0} ->
                {StateAcc, ChangeAcc, LogsAcc, PFLogsAcc};
            {add_gold, Action, AddGold, AddBindGold} when AddGold >= 0 andalso AddBindGold >= 0 ->
                {State2, AddList, RemainGold, RemainBindGold} = add_gold(StateAcc, AddGold, AddBindGold),
                Log = get_gold_log(State2, Action, AddGold, AddBindGold, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, Action, PFLogsAcc),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc2};
            {_Reduce, _Action, 0} ->
                {StateAcc, ChangeAcc, LogsAcc, PFLogsAcc};
            {reduce_unbind_gold, Action, ReduceGold} when ReduceGold > 0 -> %% 一定要扣除不绑定元宝
                {State2, AddList, RemainGold, RemainBindGold} = reduce_unbind_gold(StateAcc, ReduceGold),
                Log = get_gold_log(State2, Action, ReduceGold, 0, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, Action, PFLogsAcc),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc2};
            {reduce_gold, Action, ReduceGold} when ReduceGold > 0 ->    %% 任意元宝
                {State2, AddList, UseGold, UseBindGold, RemainGold, RemainBindGold} = reduce_gold(StateAcc, ReduceGold),
                Log = get_gold_log(State2, Action, UseGold, UseBindGold, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, Action, PFLogsAcc),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc2};
            {reduce_bind_gold, Action, ReduceBindGold} when ReduceBindGold > 0 ->    %% 只能绑定元宝
                {State2, AddList, RemainGold, RemainBindGold} = reduce_bind_gold(StateAcc, ReduceBindGold),
                Log = get_gold_log(State2, Action, 0, ReduceBindGold, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, Action, PFLogsAcc),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc2};
            {buy_item_reduce_unbind_gold, Action, ShopType, TypeID, Num, UseGold} when UseGold > 0 -> %% 购买道具扣除不绑定元宝时的特殊分支处理
                {State2, AddList, RemainGold, RemainBindGold} = reduce_unbind_gold(StateAcc, UseGold),
                Log = get_gold_log(State2, Action, UseGold, 0, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, {Action, TypeID, Num}, PFLogsAcc),
                ShopLog = mod_role_shop:get_shop_log(?CONSUME_UNBIND_GOLD, UseGold, 0, ShopType, TypeID, Num, State2),
                {State2, AddList ++ ChangeAcc, [ShopLog, Log|LogsAcc], PFLogsAcc2};
            {buy_item_reduce_any_gold, Action, ShopType, TypeID, Num, ReduceGold} when ReduceGold > 0 -> %% 购买道具扣除任意元宝时的特殊分支处理
                {State2, AddList, UseGold, UseBindGold, RemainGold, RemainBindGold} = reduce_gold(StateAcc, ReduceGold),
                Log = get_gold_log(State2, Action, UseGold, UseBindGold, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, {Action, TypeID, Num}, PFLogsAcc),
                ShopLog = mod_role_shop:get_shop_log(?CONSUME_ANY_GOLD, UseGold, UseBindGold, ShopType, TypeID, Num, State2),
                {State2, AddList ++ ChangeAcc, [ShopLog, Log|LogsAcc], PFLogsAcc2};
            {buy_item_reduce_bind_gold, Action, ShopType, TypeID, Num, ReduceBindGold} when ReduceBindGold > 0 -> %% 购买道具扣除任意元宝时的特殊分支处理
                {State2, AddList, RemainGold, RemainBindGold} = reduce_bind_gold(StateAcc, ReduceBindGold),
                Log = get_gold_log(State2, Action, 0, ReduceBindGold, RemainGold, RemainBindGold),
                PFLogsAcc2 = get_pf_gold_log(State2, StateAcc, {Action, TypeID, Num}, PFLogsAcc),
                ShopLog = mod_role_shop:get_shop_log(?CONSUME_BIND_GOLD, 0, ReduceBindGold, ShopType, TypeID, Num, State2),
                {State2, AddList ++ ChangeAcc, [ShopLog, Log|LogsAcc], PFLogsAcc2};
            {reduce_silver, Action, ReduceSilver} when ReduceSilver >= 0 ->
                {State2, AddList, RemainSilver} = reduce_silver(StateAcc, ReduceSilver),
                Log = get_silver_log(State2, Action, ReduceSilver, RemainSilver),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc};
            {_Type, _Action, _Key, 0} ->
                {StateAcc, ChangeAcc, LogsAcc, PFLogsAcc};
            {add_score, Action, Key, Value} when Value > 0 ->
                {State2, AddList, RemainScore} = add_score(StateAcc, Key, Value),
                Log = get_score_log(State2, Action, Key, Value, RemainScore),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc};
            {reduce_score, Action, Key, Value} when Value > 0 ->
                {State2, AddList, RemainScore} = reduce_score(StateAcc, Key, Value),
                Log = get_score_log(State2, Action, Key, Value, RemainScore),
                {State2, AddList ++ ChangeAcc, [Log|LogsAcc], PFLogsAcc};
            _ ->
                ?ERROR_MSG("mod_role_bag:doing unkonw type,RoleID:~w,Doing:~w", [RoleID, Doing]),
                ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
        end end, {State, [], [], []}, Doings),
    ?IF(ChangeList =/= [], common_misc:unicast(RoleID, #m_role_asset_change_toc{change_list = lists:reverse(ChangeList)}), ok),
    State5 = do_trigger(Logs, PFLogs, Doings, State4),
    State5.

do_trigger(Logs, PFLogs, Doings, State) ->
    FuncList = [
        fun(StateAcc) -> asset_change(Logs, StateAcc) end,
        fun(StateAcc) -> mod_role_warning:add_asset_doings(Doings, StateAcc) end
    ],
    State2 = role_server:execute_state_fun(FuncList, State),
    FuncList2 =
    [
        fun() -> mod_role_dict:add_background_logs(lists:reverse(Logs)) end,
        fun() -> mod_role_dict:add_pf_logs(lists:reverse(PFLogs)) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList2],
    State2.

asset_change([], State) ->
    State;
asset_change([Log|R], State) ->
    case Log of
        #log_gold{action = Action, gold = Gold, bind_gold = BindGold} -> %% 元宝行为日志
            if
                ?IS_USE_GOLD_ACTION(Action) andalso Gold > 0 ->
                    StateAcc = hook_role:role_use_gold(Gold, Action, State),
                    StateAcc2 = ?IF(BindGold > 0, hook_role:role_use_bind_gold(BindGold, StateAcc), StateAcc),
                    asset_change(R, StateAcc2);
                ?IS_USE_GOLD_ACTION(Action) andalso BindGold > 0 ->
                    StateAcc = hook_role:role_use_bind_gold(BindGold, State),
                    asset_change(R, StateAcc);
                true ->
                    asset_change(R, State)
            end;
        #log_silver{action = Action, silver = Silver} ->
            if
                ?IS_GAIN_SILVER_ACTION(Action) ->
                    StateAcc = hook_role:role_add_silver(Silver, State),
                    asset_change(R, StateAcc);
                true ->
                    asset_change(R, State)
            end;
        _ ->
            asset_change(R, State)
    end.


%% 增加银两
add_silver(#r_role{role_asset = RoleAsset} = State, AddSilverT) ->
    AddSilver = mod_role_addict:get_addict_num(AddSilverT, State),
    #r_role_asset{silver = Silver} = RoleAsset,
    Silver2 = Silver + AddSilver,
    RoleAsset2 = RoleAsset#r_role_asset{silver = Silver2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_SILVER, Silver, Silver2, []),
    {State2, ChangeList, Silver2}.

%% 增加元宝
add_gold(#r_role{role_asset = RoleAsset} = State, AddGoldT, AddBindGoldT) ->
    AddGold = mod_role_addict:get_addict_num(AddGoldT, State),
    AddBindGold = mod_role_addict:get_addict_num(AddBindGoldT, State),
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    Gold2 = Gold + AddGold,
    BindGold2 = BindGold + AddBindGold,
    RoleAsset2 = RoleAsset#r_role_asset{gold = Gold2, bind_gold = BindGold2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_GOLD, Gold, Gold2, []),
    ChangeList2 = get_change_list(?ASSET_BIND_GOLD, BindGold, BindGold2, ChangeList),
    {State2, ChangeList2, Gold2, BindGold2}.

%% 扣除银两
reduce_silver(#r_role{role_asset = RoleAsset} = State, ReduceSilver) ->
    #r_role_asset{silver = Silver} = RoleAsset,
    ?IF(Silver >= ReduceSilver, ok, erlang:throw(gold_not_enough)),
    Silver2 = Silver - ReduceSilver,
    RoleAsset2 = RoleAsset#r_role_asset{silver = Silver2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_SILVER, Silver, Silver2, []),
    {State2, ChangeList, Silver2}.

%% 扣除不绑定元宝
reduce_unbind_gold(#r_role{role_asset = RoleAsset} = State, ReduceGold) ->
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    ?IF(Gold >= ReduceGold, ok, erlang:throw(gold_not_enough)),
    Gold2 = Gold - ReduceGold,
    RoleAsset2 = RoleAsset#r_role_asset{gold = Gold2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_GOLD, Gold, Gold2, []),
    {State2, ChangeList, Gold2, BindGold}.

%% 优先绑定元宝
reduce_gold(#r_role{role_asset = RoleAsset} = State, ReduceGold) ->
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    ?IF(Gold + BindGold >= ReduceGold, ok, erlang:throw(gold_not_enough)),
    BindGold2 = erlang:max(0, BindGold - ReduceGold),
    Gold2 = ?IF(BindGold2 > 0, Gold, Gold + BindGold - ReduceGold),
    RoleAsset2 = RoleAsset#r_role_asset{gold = Gold2, bind_gold = BindGold2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_GOLD, Gold, Gold2, []),
    ChangeList2 = get_change_list(?ASSET_BIND_GOLD, BindGold, BindGold2, ChangeList),
    {State2, ChangeList2, Gold - Gold2, BindGold - BindGold2, Gold2, BindGold2}.

%% 扣除绑定元宝
reduce_bind_gold(#r_role{role_asset = RoleAsset} = State, ReduceGold) ->
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    ?IF(BindGold >= ReduceGold, ok, erlang:throw(gold_not_enough)),
    BindGold2 = BindGold - ReduceGold,
    RoleAsset2 = RoleAsset#r_role_asset{bind_gold = BindGold2},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(?ASSET_BIND_GOLD, BindGold, BindGold2, []),
    {State2, ChangeList, Gold, BindGold2}.


add_score(#r_role{role_asset = RoleAsset} = State, Key, AddValueT) ->
    AddValue = mod_role_addict:get_addict_num(AddValueT, State),
    #r_role_asset{score_list = ScoreList} = RoleAsset,
    case lists:keytake(Key, #p_dkv.id, ScoreList) of
        {value, KV, RemainList} ->
            ok;
        _ ->
            KV = #p_dkv{id = Key, val = 0},
            RemainList = ScoreList
    end,
    #p_dkv{val = Value} = KV,
    Value2 = Value + AddValue,
    KV2 = KV#p_dkv{val = Value2},
    RoleAsset2 = RoleAsset#r_role_asset{score_list = [KV2|RemainList]},
    State2 = State#r_role{role_asset = RoleAsset2},
    ChangeList = get_change_list(Key, Value, Value2, []),
    {State2, ChangeList, Value2}.

reduce_score(#r_role{role_asset = RoleAsset} = State, Key, ReduceValue) ->
    #r_role_asset{score_list = ScoreList} = RoleAsset,
    case lists:keytake(Key, #p_dkv.id, ScoreList) of
        {value, KV, RemainList} ->
            #p_dkv{val = Value} = KV,
            Value2 = Value - ReduceValue,
            ?IF(Value2 >= 0, ok, erlang:throw(score_not_enough)),
            KV2 = KV#p_dkv{val = Value2},
            RoleAsset2 = RoleAsset#r_role_asset{score_list = [KV2|RemainList]},
            State2 = State#r_role{role_asset = RoleAsset2},
            ChangeList = get_change_list(Key, Value, Value2, []),
            {State2, ChangeList, Value2};
        _ ->
            erlang:throw(score_not_found)
    end.

get_change_list(Key, OldValue, NewValue, ChangeAcc) ->
    case OldValue =/= NewValue of
        true ->
            [#p_dkv{id = Key, val = NewValue}|ChangeAcc];
        _ ->
            ChangeAcc
    end.

%% 获取银两日志
get_silver_log(State, Action, Silver, RemainSilver) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID}} = State,
    #log_silver{
        role_id = RoleID,
        action = Action,
        silver = Silver,
        remain_silver = RemainSilver,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

%% 获取元宝日志
get_gold_log(State, Action, Gold, BindGold, RemainGold, RemainBindGold) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID}} = State,
    #log_gold{
        role_id = RoleID,
        action = Action,
        gold = Gold,
        bind_gold = BindGold,
        remain_gold = RemainGold,
        remain_bind_gold = RemainBindGold,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

%% 获取积分日志
get_score_log(State, Action, Key, Score, RemainScore) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID}} = State,
    #log_score{
        role_id = RoleID,
        action = Action,
        score_key = Key,
        score = Score,
        remain_score = RemainScore,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

%% 获取平台需要的积分日志
get_pf_gold_log(State2, State, Args, PFLogs) ->
    case ?TRY_CATCH(mod_role_pf:get_pf_gold_log(State2, State, Args)) of
        #r_junhai_log{} = PFLog ->
            [PFLog|PFLogs];
        _ ->
            PFLogs
    end.


use_silver_item(EffectArgs, Num, State) ->
    Doings = [{add_silver, ?ASSET_SILVER_ADD_FROM_ITEM, Num * lib_tool:to_integer(EffectArgs)}],
    do(Doings, State).

use_gold_item(EffectArgs, Num, State) ->
    Doings = [{add_gold, ?ASSET_GOLD_ADD_FROM_ITEM, Num * lib_tool:to_integer(EffectArgs), 0}],
    do(Doings, State).

use_bind_gold_item(EffectArgs, Num, State) ->
    Doings = [{add_gold, ?ASSET_GOLD_ADD_FROM_ITEM, 0, Num * lib_tool:to_integer(EffectArgs)}],
    do(Doings, State).

use_glory_item(EffectArgs, Num, State) ->
    Doings = [{add_score, ?ASSET_GLORY_ADD_FROM_ITEM, ?ASSET_GLORY, Num * lib_tool:to_integer(EffectArgs)}],
    do(Doings, State).



use_gold(State, Num) ->
    #r_role{role_asset = RoleAsset} = State,
    Num2 = Num + RoleAsset#r_role_asset.day_use_gold,
    RoleAsset2 = RoleAsset#r_role_asset{day_use_gold = Num2},
    State2 = State#r_role{role_asset = RoleAsset2},
    Times = (RoleAsset#r_role_asset.day_use_gold + RoleAsset#r_role_asset.day_use_bind_gold) div 300,
    Times2 = (Num2 + RoleAsset#r_role_asset.day_use_bind_gold) div 300,
    Times3 = Times2 - Times,
    ?IF(Times3 > 0, do_daily_liveness(State2, Times3), State2).

do_daily_liveness(State, Times) when Times > 0 ->
    State2 = mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_YUANBAO),
    do_daily_liveness(State2, Times - 1);
do_daily_liveness(State, _Times) ->
    State.

use_bind_gold(State, Num) ->
    #r_role{role_asset = RoleAsset} = State,
    Num2 = Num + RoleAsset#r_role_asset.day_use_bind_gold + RoleAsset#r_role_asset.day_use_gold,
    RoleAsset2 = RoleAsset#r_role_asset{day_use_bind_gold = Num2},
    State2 = State#r_role{role_asset = RoleAsset2},
    Times = (RoleAsset#r_role_asset.day_use_gold + RoleAsset#r_role_asset.day_use_bind_gold) div 300,
    Times2 = (Num2 + RoleAsset#r_role_asset.day_use_gold) div 300,
    Times3 = Times2 - Times,
    ?IF(Times3 > 0, do_daily_liveness(State2, Times3), State2).




gm_set_gold(NewGold, NewBindGold, State) ->
    #r_role{role_id = RoleID, role_asset = RoleAsset} = State,
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    RoleAsset2 = RoleAsset#r_role_asset{gold = NewGold, bind_gold = NewBindGold},
    ChangeList = get_change_list(?ASSET_GOLD, Gold, NewGold, []),
    ChangeList2 = get_change_list(?ASSET_BIND_GOLD, BindGold, NewBindGold, ChangeList),
    common_misc:unicast(RoleID, #m_role_asset_change_toc{change_list = ChangeList2}),
    State#r_role{role_asset = RoleAsset2}.

gm_set_silver(NewSilver, State) ->
    #r_role{role_id = RoleID, role_asset = RoleAsset} = State,
    #r_role_asset{silver = Silver} = RoleAsset,
    RoleAsset2 = RoleAsset#r_role_asset{silver = NewSilver},
    ChangeList = get_change_list(?ASSET_SILVER, Silver, NewSilver, []),
    common_misc:unicast(RoleID, #m_role_asset_change_toc{change_list = ChangeList}),
    State#r_role{role_asset = RoleAsset2}.