-module(esql_quote).

-export([encode/1]).
%% @doc Encode a value so that it can be included safely in a MySQL query.
-spec encode(term()) -> binary() | {error, term()}.

encode(null)  ->
    <<"null">>;
encode(undefined)  ->
    <<"null">>;
encode(true) ->
    <<"1">>;
encode(false) ->
    <<"0">>;
encode(Val) when is_atom(Val) ->
    encode(atom_to_list(Val));
encode(Val) when is_list(Val) ->
    quote(Val);
encode(Val) when is_binary(Val) ->
    quote(Val);
encode(Val) when is_integer(Val) ->
    list_to_binary(integer_to_list(Val));
encode(Val) when is_float(Val) ->
    iolist_to_binary(io_lib:format("~w", [Val]));
encode({datetime, Val}) ->
    encode(Val);
encode({date, Val}) ->
    encode(Val);
encode({time, Val}) ->
    encode(Val);
encode({{Year, Month, Day}, {Hour, Minute, Second}}) ->
    Res = io_lib:format("'~4.4.0w-~2.2.0w-~2.2.0w ~2.2.0w:~2.2.0w:~2.2.0w'",
                        [Year, Month, Day, Hour, Minute, Second]),
    list_to_binary(lists:flatten(Res));
encode({Time1, Time2, Time3}) ->
    Res = two_digits([Time1, Time2, Time3]),
    list_to_binary(lists:flatten(Res));
encode(Val) ->
    {error, {unrecognized_value, Val}}.

%% @private
two_digits(Nums) when is_list(Nums) ->
    [two_digits(Num) || Num <- Nums];
two_digits(Num) ->
    [Str] = io_lib:format("~b", [Num]),
    case length(Str) of
        1 -> [$0 | Str];
        _ -> Str
    end.


%% @doc Quote a string or binary value so that it can be included safely in a
%% MySQL query. For the quoting, a binary is converted to a list and back.
%% For this, it's necessary to know the encoding of the binary.
%% @spec quote(x()) -> x()
%%       x() = list() | binary()
%% @end
%% hd/11,12
quote(String) when is_list(String) ->
    String1 = [39 | lists:reverse([39 | quote_loop(String)])],
    erlang:list_to_binary(String1);  %% 39 is $'
quote(Binary) when is_binary(Binary) ->
    String = erlang:binary_to_list(Binary),
    quote(String).

%% @doc  Make MySQL-safe backslash escapes before 10, 13, \, 26, 34, 39.
%% @spec quote_loop(list()) -> list()
%% @private
%% @end
%% hd/11,12
quote_loop(List) ->
    quote_loop(List, []).

quote_loop([], Acc) ->
    Acc;

quote_loop([0 | Rest], Acc) ->
    quote_loop(Rest, [$0, $\\ | Acc]);

quote_loop([8 | Rest], Acc) ->
    quote_loop(Rest, [$b, $\\ | Acc]);

quote_loop([9 | Rest], Acc) ->
    quote_loop(Rest, [$t, $\\ | Acc]);

quote_loop([10 | Rest], Acc) ->
    quote_loop(Rest, [$n, $\\ | Acc]);

quote_loop([13 | Rest], Acc) ->
    quote_loop(Rest, [$r, $\\ | Acc]);

quote_loop([$\\ | Rest], Acc) ->
    quote_loop(Rest, [$\\ , $\\ | Acc]);

quote_loop([39 | Rest], Acc) -> %% 39 is $'
    quote_loop(Rest, [39, $\\ | Acc]); %% 39 is $'

quote_loop([34 | Rest], Acc) -> %% 34 is $"
    quote_loop(Rest, [34, $\\ | Acc]); %% 34 is $"

quote_loop([26 | Rest], Acc) ->
    quote_loop(Rest, [$Z, $\\ | Acc]);

quote_loop([C | Rest], Acc) ->
    quote_loop(Rest, [C | Acc]).

