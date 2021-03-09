%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 七月 2019 14:57
%%%-------------------------------------------------------------------
-module(mod_role_iqiyi_ios).
-author("laijichang").
-include("role.hrl").
-include("platform.hrl").
-include("proto/mod_role_pay.hrl").

%% API
-export([
    get_pf_pay_url/0,
    check_pay_order/2
]).

get_pf_pay_url() ->
    {ok, web_misc:get_web_url(?IQIYI_IOS_PAY_URL)}.

check_pay_order(ProductID, State) ->
    #r_role{role_pay = RolePay} = State,
    #r_role_pay{today_pay_list = TodayList} = RolePay,
    [PayList] = lib_config:find(cfg_iqiyi, limit_pay_times),
    case lists:keyfind(ProductID, 1, PayList) of
        {ProductID, ConfigTimes} ->
            case lists:keyfind(ProductID, #p_kv.id, TodayList) of
                #p_kv{val = Times} when Times >= ConfigTimes ->
                    ?THROW_ERR(?ERROR_ROLE_PAY_ORDER_003);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    ok.