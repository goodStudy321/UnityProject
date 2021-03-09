%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2017 19:49
%%%-------------------------------------------------------------------
-module(rank_misc).
-author("laijichang").
-include("rank.hrl").
-include("global.hrl").

%% API
-export([
    cmp/1,
    get_rank/1,
    rank_insert_elements/2,
    do_log/0
]).

cmp([]) ->
    true;
cmp([{Element1, Element2}|List]) ->
    case Element1 =:= Element2 of
        true ->
            cmp(List);
        _ ->
            Element1 < Element2
    end.

get_rank(RankID) ->
    case ets:lookup(?DB_RANK_P, RankID) of
        [#r_rank{ranks = Ranks}] ->
            Ranks;
        _ ->
            []
    end.

rank_insert_elements(RankID, RankItems) when erlang:is_list(RankItems) ->
    case trans_to_r_rank(RankID, RankItems) of
        List when erlang:is_list(List) ->
            pname_server:send(rank_server, {rank_insert_elements, RankID, List});
        Error ->
            ?ERROR_MSG("rank logic : rank_id - ~w , rank_data - ~w, error: ~w", [RankID, RankItems, Error])
    end;
rank_insert_elements(RankID, RankItem) ->
    rank_insert_elements(RankID, [RankItem]).

trans_to_r_rank(RankID, RankItems) ->
    case lists:keyfind(RankID, #c_rank_config.rank_id, ?RANK_LIST) of
        #c_rank_config{mod = Mod} ->
            case erlang:function_exported(Mod, trans_to_r_rank, 1) of
                true ->
                    case Mod:trans_to_r_rank(RankItems) of
                        List when erlang:is_list(List) ->
                            List;
                        Error ->
                            ?ERROR_MSG("rank logic : rank_id - ~w , rank_data - ~w, error: ~w", [RankID, RankItems, Error])
                    end;
                Error ->
                    ?ERROR_MSG("rank logic : rank_id - ~w , rank_data - ~w, error: ~w", [RankID, RankItems, Error])
            end;
        Error ->
            ?ERROR_MSG("rank logic : rank_id - ~w , rank_data - ~w, error: ~w", [RankID, RankItems, Error])
    end.

do_log() ->
    lists:foreach(
        fun(#c_rank_config{rank_id = RankID, mod = Mod}) ->
            Ranks = get_rank(RankID),
            case erlang:function_exported(Mod, trans_to_log, 2) of
                true ->
                    Logs = Mod:trans_to_log(Ranks, []),
                    background_misc:log(Logs);
                _ ->
                    ok
            end
        end, ?RANK_LIST).


