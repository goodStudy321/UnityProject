%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2017 10:09
%%%-------------------------------------------------------------------
-module(rank_data).
-author("laijichang").

%% API
-export([
    has_rank/1,
    set_rank_min/1
]).

has_rank(Min) ->
    get_rank_min() =:= Min.

set_rank_min(Min) ->
    erlang:put({?MODULE, rank_min}, Min).
get_rank_min() ->
    erlang:get({?MODULE, rank_min}).
