%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_7).
-author("laijichang").
-include("db.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_pay/1
]).

%% List = [{DBName, Fun}|....]

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_PAY_P, update_role_pay}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [

    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [

    ],
    update_common:data_update(?MODULE, List),
    ok.

update_role_pay(RoleList) ->
    [ begin
          case RolePay of
              {r_role_pay, ROLE_ID, TODAY_PAY_GOLD, TOTAL_PAY_GOLD, TOTAL_PAY_FEE, PACKAGE_TIME, PACKAGE_DAYS, FIRST_PAY_LIST} ->
                  {r_role_pay, ROLE_ID, TODAY_PAY_GOLD, TOTAL_PAY_GOLD, TOTAL_PAY_FEE, PACKAGE_TIME, PACKAGE_DAYS, FIRST_PAY_LIST, []};
              _ ->
                  RolePay
          end
      end|| RolePay <- RoleList].