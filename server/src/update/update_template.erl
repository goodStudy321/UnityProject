%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_template).
-author("laijichang").
-include("db.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

%% List = [{DBName, Fun}|....]

%% 游戏节点数据更新
update_game() ->
    List = [

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