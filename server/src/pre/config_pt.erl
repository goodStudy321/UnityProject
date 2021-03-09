%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 五月 2017 17:08
%%%-------------------------------------------------------------------
-module(config_pt).
-author("laijichang").

%% API
-export([parse_transform/2]).

parse_transform(Forms, _Options) ->
    lists:reverse(lists:foldl(fun(I, Acc) ->
        form(I) ++ Acc
                              end, [], Forms)).

form({function, _L, find, 1, Cs} = I) ->
    [gen_list_function(Cs), I];
form({attribute, _L, module, _Name} = I) ->
    [{attribute, 0, export, [{list, 0}]}, I];
form(I) ->
    [I].

gen_list_function([{clause, _, _, _, [{'case', _, _, List}]}]) ->
    gen_list_function2(List);
gen_list_function(List) ->
    gen_list_function2(List).

gen_list_function2(List) ->
    R = lists:foldl(fun(I, Acc) ->
        {clause, _, [K], _, [V]} = I,
        case K of
            {var, _, _} ->
                Acc;
            _ ->
                {cons, 0, {tuple, 0, [K, V]}, Acc}
        end
                    end, {nil, 0}, lists:reverse(List)),
    {function, 0, list, 0, [{clause, 0, [], [], [R]}]}.
