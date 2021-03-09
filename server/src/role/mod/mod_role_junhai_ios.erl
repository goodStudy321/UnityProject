%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 三月 2018 12:07
%%%-------------------------------------------------------------------
-module(mod_role_junhai_ios).
-author("laijichang").
-include("role.hrl").
-include("platform.hrl").

%% API
-export([
    get_pf_pay_url/0
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

get_pf_pay_url() ->
    {ok, web_misc:get_web_url(?IOS_PAY_URL)}.

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