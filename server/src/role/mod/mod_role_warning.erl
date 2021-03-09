%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     预警系统
%%% @end
%%% Created : 29. 七月 2019 11:10
%%%-------------------------------------------------------------------
-module(mod_role_warning).
-author("laijichang").
-include("role.hrl").
-include("warning.hrl").

%% API
-export([
    init/1,
    day_reset/1
]).

-export([
    add_item_doings/2,
    add_asset_doings/2
]).

init(#r_role{role_id = RoleID, role_warning = undefined} = State) ->
    RoleWarning = #r_role_warning{role_id = RoleID},
    State#r_role{role_warning = RoleWarning};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_warning = RoleWaring} = State,
    RoleWaring2 = RoleWaring#r_role_warning{
        item_action_list = [],
        item_gain_list = [],
        asset_action_list = [],
        asset_gain_list = [],
        warning_list = []},
    State#r_role{role_warning = RoleWaring2}.

add_item_doings(Doings, State) ->
    #r_role{role_warning = RoleWarning} = State,
    #r_role_warning{item_action_list = ItemActionList, item_gain_list = ItemGainList, warning_list = WarningList} = RoleWarning,
    ActionGoods =
        lists:foldl(
            fun(Doing, Acc) ->
                case Doing of
                    {create, Action, GoodsList} ->
                        [{Action, GoodsList}|Acc];
                    {create, _BagID, Action, GoodsList} ->
                        [{Action, GoodsList}|Acc];
                    _ ->
                        Acc
                end
            end, [], Doings),
    {ItemActionWs, ItemGoodsWs, ItemActionList2, ItemGainList2} = add_item_doings2(ActionGoods, ItemActionList, ItemGainList),
    {ItemActionList3, ItemGainList3, WarningList2} =
        case ItemActionWs =/= [] orelse ItemGoodsWs =/= []of
            true ->
                do_item_warning(ItemActionWs, ItemGoodsWs, ItemActionList2, ItemGainList2, WarningList);
            _ ->
                {ItemActionList2, ItemGainList2, WarningList}
        end,
    RoleWarning2 = RoleWarning#r_role_warning{item_action_list = ItemActionList3, item_gain_list = ItemGainList3, warning_list = WarningList2},
    State#r_role{role_warning = RoleWarning2}.

add_item_doings2(ActionGoods, ItemActionList, ItemGainList) ->
    {ItemActionList2, ItemGainList2, ChangeActions, ChangeGoods} = add_item_doings3(ActionGoods, ItemActionList, ItemGainList, [], []),
    {ItemActionWs, ItemGoodsWs} = get_item_warnings(ChangeActions, ChangeGoods),
    {ItemActionWs, ItemGoodsWs, ItemActionList2, ItemGainList2}.

add_item_doings3([], ItemActionList, ItemGainList, ChangeActions, ChangeGoods) ->
    {ItemActionList, ItemGainList, ChangeActions, ChangeGoods};
add_item_doings3([{Action, GoodsList}|R], ItemActionList, ItemGainList, ChangeActions, ChangeGoods) ->
    {ItemActionList2, ChangeActions2} = add_action_doings(Action, 1, ItemActionList, ChangeActions),
    {ItemGainList2, ChangeGoods2} = add_item_gain_doings(GoodsList, ItemGainList, ChangeGoods),
    add_item_doings3(R, ItemActionList2, ItemGainList2, ChangeActions2, ChangeGoods2).

add_action_doings(Key, AddNum, List, ChangeList) ->
    {KV, List2} =
        case lists:keytake(Key, #p_kv.id, List) of
            {value, #p_kv{val = OldVal} = KVT, ListT} ->
                KVT2 = KVT#p_kv{val = OldVal + AddNum},
                {KVT2, [KVT2|ListT]};
            _ ->
                KVT = #p_kv{id = Key, val = AddNum},
                {KVT, [KVT|List]}
        end,
    ChangeList2 = lists:keystore(Key, #p_kv.id, ChangeList, KV),
    {List2, ChangeList2}.

add_item_gain_doings([], ItemGainList, ChangeGoods) ->
    {ItemGainList, ChangeGoods};
add_item_gain_doings([#p_goods{type_id = TypeID, num = AddNum}|R], ItemGainList, ChangeGoods) ->
    case lib_config:find(cfg_warning, {item_type_warning, TypeID}) of
        [_WarningNum] ->
            {ItemGainList2, ChangeGoods2} = add_action_doings(TypeID, AddNum, ItemGainList, ChangeGoods),
            add_item_gain_doings(R, ItemGainList2, ChangeGoods2);
        _ ->
            add_item_gain_doings(R, ItemGainList, ChangeGoods)
    end.

get_item_warnings(ChangeActions, ChangeGoods) ->
    ActionWarnings = get_item_action_warnings(ChangeActions, []),
    GoodsWarnings = get_goods_action_goods(ChangeGoods, []),
    {ActionWarnings, GoodsWarnings}.

get_item_action_warnings([], Acc) ->
    Acc;
get_item_action_warnings([#p_kv{id = ActionID, val = Val} = KV|R], Acc) ->
    WarningNum =
        case lib_config:find(cfg_warning, {item_action_warning, ActionID}) of
            [Num] ->
                Num;
            _ ->
                [DefaultNum] = lib_config:find(cfg_warning, {item_action_warning, default}),
                DefaultNum
        end,
    Acc2 = ?IF(Val >= WarningNum, [KV|Acc], Acc),
    get_item_action_warnings(R, Acc2).

get_goods_action_goods([], Acc) ->
    Acc;
get_goods_action_goods([#p_kv{id = TypeID, val = Val} = KV|R], Acc) ->
    [WarningNum] = lib_config:find(cfg_warning, {item_type_warning, TypeID}),
    Acc2 = ?IF(Val >= WarningNum, [KV|Acc], Acc),
    get_goods_action_goods(R, Acc2).

%% 道具预警
do_item_warning(ItemActionWs, ItemGoodsWs, ItemActionList, ItemGainList, WarningList) ->
    {ItemActionList2, WarningList2, Notice1} = do_item_warning2(ItemActionWs, ItemActionList, WarningList, ?WARNING_TYPE_ITEM_ACTION),
    {ItemGainList2, WarningList3, Notice2} = do_item_warning2(ItemGoodsWs, ItemGainList, WarningList2, ?WARNING_TYPE_ITEM_GAIN),
    ?WARNING_MSG("item warning : ~w", [Notice1 ++ Notice2]),
    ?TRY_CATCH(do_send_warning(Notice1 ++ Notice2)),
    {ItemActionList2, ItemGainList2, WarningList3}.


do_item_warning2(ItemActionWs, ItemActionList, WarningList, Type) ->
    lists:foldl(
        fun(#p_kv{id = ID, val = Val}, {ActionAcc, WarningAcc, NoticeAcc}) ->
            Key = {Type, ID},
            {Notice, WarningAcc2} =
                case lists:keytake(Key, #p_kv.id, WarningAcc) of
                    {value, #p_kv{val = OldVal} = OldKV, WarningListT} ->
                        OldKV2 = OldKV#p_kv{val = OldVal + Val},
                        {OldKV2, [OldKV2|WarningListT]};
                    _ ->
                        KVT = #p_kv{id = Key, val = Val},
                        {KVT, [KVT|WarningAcc]}
                end,
            ActionAcc2 = lists:keydelete(ID, #p_kv.id, ActionAcc),
            {ActionAcc2, WarningAcc2, [Notice|NoticeAcc]}
        end, {ItemActionList, WarningList, []}, ItemActionWs).

add_asset_doings(Doings, State) ->
    #r_role{role_warning = RoleWarning} = State,
    #r_role_warning{asset_gain_list = AssetGainList, warning_list = WarningList} = RoleWarning,
    Assets =
        lists:foldl(
            fun(Doing, Acc) ->
                case Doing of
                    {add_gold, _Action, AddGold, AddBindGold} -> %% 现在只检测元宝、绑元
                        List1 = ?IF(AddGold > 0, [#p_kv{id = ?ITEM_GOLD, val = AddGold}], []),
                        List2 = ?IF(AddBindGold > 0, [#p_kv{id = ?ITEM_BIND_GOLD, val = AddBindGold}], []),
                        common_misc:merge_props(List1 ++ List2 ++ Acc);
                    _ ->
                        Acc
                end
            end, [], Doings),
    {AssetGainList2, AssetWarnings} = add_asset_doings2(Assets, AssetGainList, []),
    {AssetGainList3, WarningList2} =
        case AssetWarnings =/= [] of
            true ->
                do_asset_warning(AssetWarnings, AssetGainList2, WarningList);
            _ ->
                {AssetGainList2, WarningList}
        end,
    RoleWarning2 = RoleWarning#r_role_warning{asset_gain_list = AssetGainList3, warning_list = WarningList2},
    State#r_role{role_warning = RoleWarning2}.

add_asset_doings2([], AssetGainList, ChangeAssets) ->
    AssetWarnings = get_asset_warnings(ChangeAssets, []),
    {AssetGainList, AssetWarnings};
add_asset_doings2([#p_kv{id = ID, val = Val}|R], AssetGainList, ChangeAssets) ->
    case lib_config:find(cfg_warning, {asset_type_warning, ID}) of
        [_WarningNum] ->
            {AssetGainList2, ChangeAssets2} = add_action_doings(ID, Val, AssetGainList, ChangeAssets),
            add_asset_doings2(R, AssetGainList2, ChangeAssets2);
        _ ->
            add_asset_doings2(R, AssetGainList, ChangeAssets)
    end.

get_asset_warnings([], Acc) ->
    Acc;
get_asset_warnings([#p_kv{id = ID, val = Val} = KV|R], Acc) ->
    [WarningNum] = lib_config:find(cfg_warning, {asset_type_warning, ID}),
    Acc2 = ?IF(Val >= WarningNum, [KV|Acc], Acc),
    get_asset_warnings(R, Acc2).

do_asset_warning(AssetWarnings, AssetGainList, WarningList) ->
    {AssetGainList2, WarningList2, Notice1} = do_item_warning2(AssetWarnings, AssetGainList, WarningList, ?WARNING_TYPE_ASSET_GAIN),
    ?WARNING_MSG("asset warning : ~w", [Notice1]),
    ?TRY_CATCH(do_send_warning(Notice1)),
    {AssetGainList2, WarningList2}.

do_send_warning([]) ->
    ok;
do_send_warning(NoticeList) ->
    case common_config:is_test_server() of
        true ->
            ok;
        _ ->
            ServerName = common_config:get_server_name(),
            RoleID = mod_role_dict:get_role_id(),
            [ begin
                  {Action, ID, Desc, Val} = get_warning_args(Notice),
                  erlang:spawn(fun() -> send_warning_to_web(ServerName, RoleID, Action, ID, Desc, Val) end)
              end|| Notice <- NoticeList]
    end.

get_warning_args(Notice) ->
    #p_kv{id = {Type, ID}, val = Val} = Notice,
    {Action, Desc} =
    case Type of
        ?WARNING_TYPE_ITEM_ACTION ->
            ItemAction =
                case lib_config:find(cfg_gold_log, ID) of
                    [ItemActionT] ->
                        ItemActionT;
                    _ ->
                        ""
                end,
            {?ITEM_ACTION_WARNING_LANG, ItemAction};
        ?WARNING_TYPE_ITEM_GAIN ->
            ItemName =
                case catch mod_role_item:get_item_config(ID) of
                    #c_item{name = ItemNameT} ->
                        ItemNameT;
                    _ ->
                        ""
                end,
            {?ITEM_GAIN_WARNING_LANG, ItemName};
        ?WARNING_TYPE_ASSET_GAIN ->
            {?ASSET_WARNING_LANG, ""}
    end,
    {Action, ID, Desc, Val}.

send_warning_to_web(ServerName, RoleID, Action, ID, Desc, Val) ->
    URL = web_misc:get_web_url(sms_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    [PhoneString] = lib_config:find(cfg_web, sms_phone_list),
    Body =
        [
            {phone, PhoneString},
            {t1, unicode:characters_to_binary(ServerName)},
            {t2, lib_tool:to_list(RoleID)},
            {t3, unicode:characters_to_binary(Action)},
            {t4, lib_tool:to_list(ID)},
            {t5, unicode:characters_to_binary(Desc)},
            {t6, lib_tool:to_list(Val)},
            {time, Time},
            {ticket, Ticket}
        ],
    case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 5000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                   ok;
                _ ->
                    ?ERROR_MSG("Code : ~w", [Code]),
                    ok
            end;
        Error ->
            ?ERROR_MSG("Error:~p", [Error]),
            ok
    end.