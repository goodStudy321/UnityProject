%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 九月 2019 15:36
%%%-------------------------------------------------------------------
-module(mod_role_xiaoqi_ios).
-author("laijichang").
-include("pay.hrl").
-include("platform.hrl").
-include("global.hrl").

%% API
-export([
    get_pf_pay_args/3
]).

%% 获取日志 or 上报日志
-export([
    account_login_log/0,
    create_role_log/1,
    role_login_log/1,
    pay_log/5,
    level_up_log/1,
    offline_log/1,
    get_pf_gold_log/3,
    chat_log/2
]).

get_pf_pay_args(OrderID, ProductID, _State) ->
    [#c_pay{pay_money = PayMoney, desc = Desc}] = lib_config:find(cfg_pay, ProductID),
    PayMoney2 = lib_tool:to_list(PayMoney) ++ ".00",
    {_ChannelID, GameChannelID} = mod_role_dict:get_game_chanel_id(),
    PublicKey =
        case GameChannelID of
            ?XIAOQI_IOS_GAME_CHANNEL_ID ->
                ?XIAOQI_PUBLIC_KEY;
            ?IOS_XIAOQI_MIX_GAM_CHANNEL_ID ->
                ?XIAOQI_PUBLIC_KEY2
        end,
    {ok, lib_tool:md5(lists:concat([
        "game_area=", mod_role_dict:get_server_id(),
        "&game_orderid=", OrderID,
        "&game_price=", PayMoney2,
        "&subject=", lib_tool:to_list(unicode:characters_to_binary(Desc)), "_", PayMoney2,
        PublicKey
    ]))}.

account_login_log() ->
    mod_role_junhai:account_login_log().

create_role_log(RoleAttr) ->
    mod_role_junhai:create_role_log(RoleAttr).

role_login_log(State) ->
    mod_role_junhai:role_login_log(State).

pay_log(OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr) ->
    mod_role_junhai:pay_log(OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr).

level_up_log(State) ->
    mod_role_junhai:level_up_log(State).

offline_log(State) ->
    mod_role_junhai:offline_log(State).

get_pf_gold_log(State2, State, Args) ->
    mod_role_junhai:get_pf_gold_log(State2, State, Args).

chat_log(PFChat, State) ->
    mod_role_junhai:chat_log(PFChat, State).