%%%-------------------------------------------------------------------
%%% @doc
%%%     json工具模块
%%% @end
%%% Created : 2015-3-2
%%%-------------------------------------------------------------------
-module(lib_json).
-record(encoder, {handler=null,utf8=false}).
-define(Q, $\").
%% IEEE 754 Float exponent bias
-define(FLOAT_BIAS, 1022).
-define(MIN_EXP, -1074).
-define(BIG_POW, 4503599627370496).

-export([
    to_json/1,
	json_list/1,
    json_binary/1,
    to_kvlist/1
]).

%% @doc 转换为json
-spec to_json(tuple() | list()) -> string().
to_json(V) -> json_encode(prepare_for_json(V)).

%% @doc json格式化，标准格式json
-spec json_list(Data) -> string() when
    Data :: KVTuple | [ KVTuple ],
    KVTuple :: {Key, term()},
    Key :: integer() | string() | atom().
json_list(Data) ->
    erlang:binary_to_list(erlang:iolist_to_binary(to_json(Data))).

%% @doc json格式化，标准json转换为binary格式
-spec json_binary(Data) -> binary() when
    Data :: KVTuple | [ KVTuple ],
    KVTuple :: {Key, term()},
    Key :: integer() | string() | atom().
json_binary(Data) ->
    erlang:iolist_to_binary(to_json(Data)).

%% @doc 转换为kvlist
-spec to_kvlist([{binary(), binary()}]) -> [{atom(), list()}].
to_kvlist(RawData) ->
  lists:map(fun({BinKey, BinVal}) ->
      Key = lib_tool:to_atom(BinKey),
      Val = lib_tool:to_list(BinVal),
      {Key, Val}
    end, RawData).

prepare_for_json(Int) when erlang:is_integer(Int) -> Int;
prepare_for_json(Float) when erlang:is_float(Float) -> Float;
prepare_for_json(Atom) when erlang:is_atom(Atom) -> Atom;
prepare_for_json(Array) when erlang:is_list(Array) ->
    %% case io_lib:printable_list(Array) of
	case char_list(Array) of
		true ->
			erlang:list_to_binary(Array);
		false ->
			list_to_json(Array, [])
	end;
prepare_for_json(Tuple) when erlang:is_tuple(Tuple) ->
	tuple_to_json(Tuple, erlang:tuple_size(Tuple), []);
prepare_for_json(V) -> V.

list_to_json([], Acc) -> lists:reverse(Acc);
list_to_json([{_Key, _Value}|_Rest] = List, Acc) -> {struct, proplist_to_json(List, Acc)};
list_to_json([H|Rest], Acc) -> list_to_json(Rest, [prepare_for_json(H)|Acc]).

proplist_to_json([], Acc) -> lists:reverse(Acc);
proplist_to_json([{Key, Value}|Rest], Acc) ->
	ValidKey    = prepare_for_json(Key),
	ValidValue  = prepare_for_json(Value),
	proplist_to_json(Rest, [{ValidKey, ValidValue}|Acc]).

tuple_to_json(_Tuple, 0, Acc) ->  {struct, [erlang:list_to_tuple(Acc)]};
tuple_to_json(Tuple, CurrPos, Acc) ->
	Ele = prepare_for_json(element(CurrPos, Tuple)),
	tuple_to_json(Tuple, CurrPos - 1, [Ele|Acc]).

char_list([C|Cs]) when erlang:is_integer(C), C >= $\000, C =< $\377 ->
    char_list(Cs);
char_list([]) -> true;
char_list(_) -> false.          %Everything else is false

json_encode(Value) ->
    json_encode(Value,#encoder{}).
json_encode(true, _State) ->
    <<"true">>;
json_encode(false, _State) ->
    <<"false">>;
json_encode(null, _State) ->
    <<"null">>;
json_encode(I, _State) when erlang:is_integer(I) ->
    erlang:integer_to_list(I);
json_encode(F, _State) when erlang:is_float(F) ->
    json_encode_float(F);
json_encode(S, State) when erlang:is_binary(S); erlang:is_atom(S) ->
    json_encode_string(S, State);
json_encode([{K, _}|_] = Props, State) when (K =/= struct andalso
    K =/= array andalso
    K =/= json) ->
    json_encode_proplist(Props, State);
json_encode({struct, Props}, State) when erlang:is_list(Props) ->
    json_encode_proplist(Props, State);
json_encode({Props}, State) when erlang:is_list(Props) ->
    json_encode_proplist(Props, State);
json_encode({}, State) ->
    json_encode_proplist([], State);
json_encode(Array, State) when erlang:is_list(Array) ->
    json_encode_array(Array, State);
json_encode({array, Array}, State) when erlang:is_list(Array) ->
    json_encode_array(Array, State);
json_encode({json, IoList}, _State) ->
    IoList;
json_encode(Bad, #encoder{handler=null}) ->
    erlang:exit({json_encode, {bad_term, Bad}}).
%% json_encode(Bad, State=#encoder{handler=Handler}) ->
%%     json_encode(Handler(Bad), State).

json_encode_array([], _State) ->
    <<"[]">>;
json_encode_array(L, State) ->
    F = fun (O, Acc) ->
        [$,, json_encode(O, State) | Acc]
    end,
    [$, | Acc1] = lists:foldl(F, "[", L),
    lists:reverse([$\] | Acc1]).

json_encode_proplist([], _State) ->
    <<"{}">>;
json_encode_proplist(Props, State) ->
    F = fun ({K, V}, Acc) ->
        KS = json_encode_string(K, State),
        VS = json_encode(V, State),
        [$,, VS, $:, KS | Acc]
    end,
    [$, | Acc1] = lists:foldl(F, "{", Props),
    lists:reverse([$\} | Acc1]).

json_encode_float(0.0) ->
    "0.0";
json_encode_float(Float) ->
    {Frac1, Exp1} = frexp_int(Float),
    [Place0 | Digits0] = digits1(Float, Exp1, Frac1),
    {Place, Digits} = transform_digits(Place0, Digits0),
    R = insert_decimal(Place, Digits),
    case Float < 0 of
        true ->
            [$- | R];
        _ ->
            R
    end.

json_encode_string(A, State) when erlang:is_atom(A) ->
    L = atom_to_list(A),
    case json_string_is_safe(L) of
        true ->
            [?Q, L, ?Q];
        false ->
            json_encode_string_unicode(xmerl_ucs:from_utf8(L), State, [?Q])
    end;
json_encode_string(B, State) when erlang:is_binary(B) ->
    case json_bin_is_safe(B) of
        true ->
            [?Q, B, ?Q];
        false ->
            case catch erlang:binary_to_term(B) of
                {'EXIT', _} ->
                    json_encode_string_unicode(xmerl_ucs:from_utf8(B), State, [?Q]);
                _ ->
                    [?Q, "", ?Q]
            end
    end;
json_encode_string(I, _State) when erlang:is_integer(I) ->
    [?Q, integer_to_list(I), ?Q];
json_encode_string(L, State) when erlang:is_list(L) ->
    case json_string_is_safe(L) of
        true ->
            [?Q, L, ?Q];
        false ->
            json_encode_string_unicode(L, State, [?Q])
    end.

json_string_is_safe([]) ->
    true;
json_string_is_safe([C | Rest]) ->
    case C of
        ?Q ->
            false;
        $\\ ->
            false;
        $\b ->
            false;
        $\f ->
            false;
        $\n ->
            false;
        $\r ->
            false;
        $\t ->
            false;
        C when C >= 0, C < $\s; C >= 16#7f, C =< 16#10FFFF ->
            false;
        C when C < 16#7f ->
            json_string_is_safe(Rest);
        _ ->
            false
    end.

json_bin_is_safe(<<>>) ->
    true;
json_bin_is_safe(<<C, Rest/binary>>) ->
    case C of
        ?Q ->
            false;
        $\\ ->
            false;
        $\b ->
            false;
        $\f ->
            false;
        $\n ->
            false;
        $\r ->
            false;
        $\t ->
            false;
        C when C >= 0, C < $\s; C >= 16#7f ->
            false;
        C when C < 16#7f ->
            json_bin_is_safe(Rest)
    end.


json_encode_string_unicode([], _State, Acc) ->
    lists:reverse([$\" | Acc]);
json_encode_string_unicode([C | Cs], State, Acc) ->
    Acc1 = case C of
               ?Q ->
                   [?Q, $\\ | Acc];
    %% Escaping solidus is only useful when trying to protect
    %% against "</script>" injection attacks which are only
    %% possible when JSON is inserted into a HTML document
    %% in-line. mochijson2 does not protect you from this, so
    %% if you do insert directly into HTML then you need to
    %% uncomment the following case or escape the output of encode.
    %%
    %% $/ ->
    %%    [$/, $\\ | Acc];
    %%
               $\\ ->
                   [$\\, $\\ | Acc];
               $\b ->
                   [$b, $\\ | Acc];
               $\f ->
                   [$f, $\\ | Acc];
               $\n ->
                   [$n, $\\ | Acc];
               $\r ->
                   [$r, $\\ | Acc];
               $\t ->
                   [$t, $\\ | Acc];
               C when C >= 0, C < $\s ->
                   [unihex(C) | Acc];
%%                C when C >= 16#7f, C =< 16#10FFFF, State#encoder.utf8 ->
%%                    [xmerl_ucs:to_utf8(C) | Acc];
               C when  C >= 16#7f, C =< 16#10FFFF, not State#encoder.utf8 ->
                   [unihex(C) | Acc];
               C when C < 16#7f ->
                   [C | Acc];
               _ ->
                   exit({json_encode, {bad_char, C}})
           end,
    json_encode_string_unicode(Cs, State, Acc1).

hexdigit(C) when C >= 0, C =< 9 ->
    C + $0;
hexdigit(C) when C =< 15 ->
    C + $a - 10.

unihex(C) when C < 16#10000 ->
    <<D3:4, D2:4, D1:4, D0:4>> = <<C:16>>,
    Digits = [hexdigit(D) || D <- [D3, D2, D1, D0]],
    [$\\, $u | Digits];
unihex(C) when C =< 16#10FFFF ->
    N = C - 16#10000,
    S1 = 16#d800 bor ((N bsr 10) band 16#3ff),
    S2 = 16#dc00 bor (N band 16#3ff),
    [unihex(S1), unihex(S2)].

frexp_int(F) ->
    case unpack(F) of
        {_Sign, 0, Frac} ->
            {Frac, ?MIN_EXP};
        {_Sign, Exp, Frac} ->
            {Frac + (1 bsl 52), Exp - 53 - ?FLOAT_BIAS}
    end.
transform_digits(Place, [0 | Rest]) ->
    transform_digits(Place, Rest);
transform_digits(Place, Digits) ->
    {Place, [$0 + D || D <- Digits]}.


insert_decimal(0, S) ->
    "0." ++ S;
insert_decimal(Place, S) when Place > 0 ->
    L = length(S),
    case Place - L of
        0 ->
            S ++ ".0";
        N when N < 0 ->
            {S0, S1} = lists:split(L + N, S),
            S0 ++ "." ++ S1;
        N when N < 6 ->
            %% More places than digits
            S ++ lists:duplicate(N, $0) ++ ".0";
        _ ->
            insert_decimal_exp(Place, S)
    end;
insert_decimal(Place, S) when Place > -6 ->
    "0." ++ lists:duplicate(abs(Place), $0) ++ S;
insert_decimal(Place, S) ->
    insert_decimal_exp(Place, S).

insert_decimal_exp(Place, S) ->
    [C | S0] = S,
    S1 = case S0 of
             [] ->
                 "0";
             _ ->
                 S0
         end,
    Exp = case Place < 0 of
              true ->
                  "e-";
              false ->
                  "e+"
          end,
    [C] ++ "." ++ S1 ++ Exp ++ integer_to_list(abs(Place - 1)).


unpack(Float) ->
    <<Sign:1, Exp:11, Frac:52>> = <<Float:64/float>>,
    {Sign, Exp, Frac}.

digits1(Float, Exp, Frac) ->
    Round = ((Frac band 1) =:= 0),
    case Exp >= 0 of
        true ->
            BExp = 1 bsl Exp,
            case (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * BExp * 2), 2, BExp, BExp,
                        Round, Round, Float);
                false ->
                    scale((Frac * BExp * 4), 4, (BExp * 2), BExp,
                        Round, Round, Float)
            end;
        false ->
            case (Exp =:= ?MIN_EXP) orelse (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * 2), 1 bsl (1 - Exp), 1, 1,
                        Round, Round, Float);
                false ->
                    scale((Frac * 4), 1 bsl (2 - Exp), 2, 1,
                        Round, Round, Float)
            end
    end.

scale(R, S, MPlus, MMinus, LowOk, HighOk, Float) ->
    Est = int_ceil(math:log10(abs(Float)) - 1.0e-10),
    %% Note that the scheme implementation uses a 326 element look-up table
    %% for int_pow(10, N) where we do not.
    case Est >= 0 of
        true ->
            fixup(R, S * int_pow(10, Est), MPlus, MMinus, Est,
                LowOk, HighOk);
        false ->
            Scale = int_pow(10, -Est),
            fixup(R * Scale, S, MPlus * Scale, MMinus * Scale, Est,
                LowOk, HighOk)
    end.

fixup(R, S, MPlus, MMinus, K, LowOk, HighOk) ->
    TooLow = case HighOk of
                 true ->
                     (R + MPlus) >= S;
                 false ->
                     (R + MPlus) > S
             end,
    case TooLow of
        true ->
            [(K + 1) | generate(R, S, MPlus, MMinus, LowOk, HighOk)];
        false ->
            [K | generate(R * 10, S, MPlus * 10, MMinus * 10, LowOk, HighOk)]
    end.

generate(R0, S, MPlus, MMinus, LowOk, HighOk) ->
    D = R0 div S,
    R = R0 rem S,
    TC1 = case LowOk of
              true ->
                  R =< MMinus;
              false ->
                  R < MMinus
          end,
    TC2 = case HighOk of
              true ->
                  (R + MPlus) >= S;
              false ->
                  (R + MPlus) > S
          end,
    case TC1 of
        false ->
            case TC2 of
                false ->
                    [D | generate(R * 10, S, MPlus * 10, MMinus * 10,
                        LowOk, HighOk)];
                true ->
                    [D + 1]
            end;
        true ->
            case TC2 of
                false ->
                    [D];
                true ->
                    case R * 2 < S of
                        true ->
                            [D];
                        false ->
                            [D + 1]
                    end
            end
    end.
int_ceil(X) ->
    T = trunc(X),
    case (X - T) of
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.
int_pow(_X, 0) ->
    1;
int_pow(X, N) when N > 0 ->
    int_pow(X, N, 1).
int_pow(X, N, R) when N < 2 ->
    R * X;
int_pow(X, N, R) ->
    int_pow(X * X, N bsr 1, case N band 1 of 1 -> R * X; 0 -> R end).



