%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 秘境探索（挖矿）
%%% @end
%%% Created : 29. 七月 2019 11:44
%%%-------------------------------------------------------------------
-module(mod_mining).
-author("huangxiangrui").

%% API
-export([
    activity_prepare/0,
    activity_start/0,
    activity_end/0
]).



%% @doc 准备阶段
activity_prepare() ->
    world_mining_server:send_activity_prepare().


%% @doc 开启活动
activity_start() ->
    world_mining_server:send_activity_start().


%% @doc 结束活动
activity_end() ->
    world_mining_server:send_activity_end().


