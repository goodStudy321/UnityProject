%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2018 15:28
%%%-------------------------------------------------------------------
-module(act_clword).
-author("WZP").

-include("act.hrl").
-include("common.hrl").
-include("proto/mod_role_act_clword.hrl").
%% API
-export([
    init/0,
    handle/1
]).



init() ->
    List = cfg_act_clword:list(),
    ClWord = lists:foldl(
        fun({_, Config}, Rewards) ->
            case Config#c_act_clword.num =/= 0 andalso Config#c_act_clword.type =:= ?ACT_CLWORD_SERVER of
                true ->
                    [{Config#c_act_clword.id, Config#c_act_clword.num}|Rewards];
                _ ->
                    Rewards
            end
        end, [], List),
    set_act_clword(ClWord).



handle(clword_reword_info) ->
    do_return_info();
handle({clword_get_reword, Id}) ->
    do_get_reword(Id);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).



do_return_info() ->
    case catch check_can_return() of
        {ok, List} ->
            {ok, List};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_return() ->
    Act = world_act_server:get_act(?ACT_CLWORD_ID),
    case Act#r_act.status =:= ?ACT_STATUS_CLOSE of
        false ->
            List = get_act_clword(),
            {ok, List};
        _ ->
            ?THROW_ERR(?ERROR_ACT_CLWORD_001)
    end.

do_get_reword(Id) ->
    case catch check_can_get(Id) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_get(Id) ->
    Act = world_act_server:get_act(?ACT_CLWORD_ID),
    case Act#r_act.status =:= ?ACT_STATUS_CLOSE of
        false ->
            List = get_act_clword(),
            case lists:keytake(Id, 1, List) of
                {value, {Id, Num}, Others} ->
                    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_ACT_CLWORD_REWARD_002)),
                    set_act_clword([{Id, Num - 1}|Others]),
                    ok;
                _ ->
                    ?THROW_ERR(?ERROR_ACT_CLWORD_REWARD_003)
            end;
        _ ->
            ?THROW_ERR(?ERROR_ACT_CLWORD_001)
    end.


set_act_clword(List) ->
    erlang:put({?MODULE, act_clword}, List).
get_act_clword() ->
    case erlang:get({?MODULE, act_clword}) of
        [_|_] = List -> List;
        _ -> []
    end.









