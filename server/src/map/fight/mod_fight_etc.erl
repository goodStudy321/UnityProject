%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 14:58
%%%-------------------------------------------------------------------
-module(mod_fight_etc).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    get_formula_rate/2,
    get_formula_value/2,
    get_rate_value/1,
    check_can_attack_buffs/1
]).

%% A/A+B的万分比值
get_formula_rate(0, _B) ->
    0;
get_formula_rate(A, B) ->
    get_formula_value(A, B) * ?RATE_10000.

%% A/A+B的具体值
get_formula_value(0, _B) ->
    0;
get_formula_value(A, B) ->
    A / (A + B).

get_rate_value(Value) ->
    Value / ?RATE_10000.

check_can_attack_buffs(BuffStatus) ->
    case ?IS_BUFF_DIZZY(BuffStatus) of
        true ->
            false;
        _ ->
            true
    end.
