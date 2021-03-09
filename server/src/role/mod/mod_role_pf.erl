%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     平台相关请求
%%% @end
%%% Created : 09. 三月 2018 11:45
%%%-------------------------------------------------------------------
-module(mod_role_pf).
-author("laijichang").
-include("role.hrl").
-include("platform.hrl").
-include("proto/role_login.hrl").

%% API
-export([
    get_pf_login_args/2
]).


-export([
    get_pf_pay_url/0,
    get_pf_pay_args/3,
    check_pay_order/2,

    account_login_log/0,
    create_role_log/1,
    role_login_log/1,
    level_up_log/1,
    offline_log/1,
    get_pf_gold_log/3,
    chat_log/2
]).

%% 非角色进程调用
-export([
    pay_log/5
]).


get_pf_login_args(AccountNameT, PFArgs) ->
    case PFArgs of
        [ChannelIDString, GameChannelIDString|_] ->
            GameChannelID = lib_tool:to_integer(GameChannelIDString),
            GameChannelID2 = get_account_game_channel_id(GameChannelID),
            {lib_tool:to_binary(lists:concat([GameChannelID2, "_", AccountNameT])), lib_tool:to_integer(ChannelIDString), GameChannelID};
        _ ->
            case common_config:is_debug() of
                true ->
                    {lib_tool:to_binary("0_" ++ AccountNameT), 0, 0};
                _ ->
                    ?THROW_ERR(?ERROR_AUTH_KEY_005)
            end
    end.

get_pf_pay_url() ->
    case execute_mod(get_pf_pay_url, []) of
        {ok, Url} ->
            Url;
        _ ->
            ""
    end.

get_pf_pay_args(OrderID, ProductID, State) ->
    case execute_mod(get_pf_pay_args, [OrderID, ProductID, State]) of
        {ok, PFArgs} ->
            PFArgs;
        _ ->
            ""
    end.

check_pay_order(ProductID, State) ->
    execute_mod(check_pay_order, [ProductID, State]).

account_login_log() ->
    execute_mod(account_login_log, []).

create_role_log(RoleAttr) ->
    execute_mod(create_role_log, [RoleAttr]).

role_login_log(State) ->
    execute_mod(role_login_log, [State]).

level_up_log(State) ->
    execute_mod(level_up_log, [State]).

offline_log(State) ->
    execute_mod(offline_log, [State]).

get_pf_gold_log(State2, State, Args) ->
    execute_mod(get_pf_gold_log, [State2, State, Args]).

chat_log(PFChat, State) ->
    execute_mod(chat_log, [PFChat, State]).

%% 非角色进程调用！！
pay_log(OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr) ->
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    execute_mod2(ChannelID, GameChannelID, pay_log, [OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr]).

execute_mod(Fun, Args) ->
    {ChannelID, GameChannelID} = mod_role_dict:get_game_chanel_id(),
    execute_mod2(ChannelID, GameChannelID, Fun, Args).

execute_mod2(ChannelID, GameChannelID, Fun, Args) ->
    Mod = common_pf:get_role_mod(ChannelID, GameChannelID),
    case erlang:function_exported(Mod, Fun, erlang:length(Args)) of
        true ->
            erlang:apply(Mod, Fun, Args);
        _ ->
            not_exist
    end.

get_account_game_channel_id(GameChannelID) ->
    case lists:keyfind(GameChannelID, 1, ?ACCOUNT_GAME_CHANNEL_ID) of
        {GameChannelID, GameChannelID2} ->
            GameChannelID2;
        _ ->
            GameChannelID
    end.