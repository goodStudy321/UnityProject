%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     节点内的全局变量
%%% @end
%%% Created : 27. 二月 2019 9:33
%%%-------------------------------------------------------------------
-module(global_data).
-author("laijichang").

-export([
    init/0
]).

%% 调用时注意不要并发写的
-export([
    set_cross_server_id/1,
    get_cross_server_id/0,
    set_cross_server_ip/1,
    get_cross_server_ip/0,
    get_cross_next_match_time/0,
    set_cross_next_match_time/1
]).

-export([
    get_cycle_act_couple_rank/1,
    set_cycle_act_couple_rank/2
]).

-record(r_global_data, {key, val}).
-define(ETS_GLOBAL_DATA, ets_global_data).
-define(CROSS_SERVER_ID, cross_server_id).              %% 跨服连接ID
-define(CROSS_SERVER_IP, cross_server_ip).              %% 跨服连接IP
-define(CROSS_NEXT_MATCH_TIME, cross_next_match_time).  %% 下次跨服匹配时间

-define(CYCLE_ACT_COUPLE_RANK, cycle_act_couple_rank).  %% 魅力之王排行

init() ->
    lib_tool:init_ets(?ETS_GLOBAL_DATA, #r_global_data.key).

get_cross_server_id() ->
    get_global_data(?CROSS_SERVER_ID, 0).
set_cross_server_id(ServerID) ->
    Data = #r_global_data{key = ?CROSS_SERVER_ID, val = ServerID},
    set_global_data(Data).

get_cross_server_ip() ->
    get_global_data(?CROSS_SERVER_IP, "").
set_cross_server_ip(ServerIP) ->
    Data = #r_global_data{key = ?CROSS_SERVER_IP, val = ServerIP},
    set_global_data(Data).

get_cross_next_match_time() ->
    get_global_data(?CROSS_NEXT_MATCH_TIME, 0).
set_cross_next_match_time(NextTime) ->
    Data = #r_global_data{key = ?CROSS_NEXT_MATCH_TIME, val = NextTime},
    set_global_data(Data).

%% {Date, Sex}
get_cycle_act_couple_rank(Key) ->
    get_global_data({?CYCLE_ACT_COUPLE_RANK, Key}, []).
set_cycle_act_couple_rank(Key, List) ->
    Data = #r_global_data{key = {?CYCLE_ACT_COUPLE_RANK, Key}, val = List},
    set_global_data(Data).

get_global_data(Key) ->
    ets:lookup(?ETS_GLOBAL_DATA, Key).
get_global_data(Key, Default) ->
    case get_global_data(Key) of
        [#r_global_data{val = Val}] ->
            Val;
        _ ->
            Default
    end.
set_global_data(#r_global_data{} = Data) ->
    ets:insert(?ETS_GLOBAL_DATA, Data).