%%%-------------------------------------------------------------------
%%% @doc
%%%     常用且通用的一些工具函数
%%% @end
%%%-------------------------------------------------------------------
-module(lib_tool).

-export([
    ip/1,
    init_ets/2,
    get_domain_ip/1,
    ip_to_str/1,
    ip2hostlong/1,
    get_intranet_address/0,
    get_all_bind_address/0,
    get_tx_ip_address/0
]).

-export([
    to_integer/1,
    to_binary/1,
    to_tuple/1,
    to_float/1,
    to_list/1,
    to_atom/1,
    list_to_atom/1,
    is_string/1,
    proplists_to_integer/2,
    float_to_str/1,
    md5/1
]).

-export([
    ceil/1,
    floor/1,
    random/1,
    random/2,
    rand_bytes/1
]).

-export([
    concat/1,
    list_element_index/2,
    combine_lists/2,
    random_element_from_list/1,
    random_elements_from_list/2,
    random_elements_from_list/3,
    random_reorder_list/1,
    has_duplicate_member/1,
    repeated_element_in_lists/2,
    list_filter_repeat/1,
    list_filter_repeat2/1,
    list_filter_repeat2/2,
    flatten_format/2,
    get_weight_output/1,
    get_list_by_weight/2,
    split/2
]).

-export([
    utf8_len/1,
    sublist_utf8/3,
    code_point_len/1,
    to_output/1,
    to_list_output/1,
    to_list_output/2,
    to_unicode/1
]).

-export([
    is_less/2,
    is_greater/2,
    is_less_or_equal/2,
    is_greater_or_equal/2
]).

-export([
    string_to_intlist/1,
    string_to_intlist/3,
    string_to_integer_list/1,
    string_to_integer_list/2
]).

-export([
    foldl/3,
    get_lists_index/3,
    add_log/3,
    add_logs/3
]).


%%%%%%%%%######IP relative######%%%%%%%%%
%% @doc Socket的IP地址字符串
-spec ip(port()) -> binary().
ip(Socket) ->
    {ok, {{Ip0, Ip1, Ip2, Ip3}, _}} = inet:peername(Socket),
    list_to_binary(integer_to_list(Ip0) ++ "." ++ integer_to_list(Ip1) ++ "." ++ integer_to_list(Ip2) ++ "." ++ integer_to_list(Ip3)).

init_ets(Name, KeyPos) ->
    ets:new(Name, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, KeyPos}]).

%% @doc 获取域名的IP
-spec get_domain_ip(atom() | string()) -> {ok, string()} | {error, term()}.
get_domain_ip(Name) ->
    case inet:gethostbyname(Name) of
        {ok, {_, _, _, _, _, [IPTuple]}} ->
            {ok, ?MODULE:ip_to_str(IPTuple)};
        {error, Error} ->
            {error, Error}
    end.

%% @doc IP(tuple) -> String
-spec ip_to_str(tuple()) -> string().
ip_to_str(IP) ->
    case IP of
        {A, B, C, D} ->
            lists:concat([A, ".", B, ".", C, ".", D]);
        {A, B, C, D, E, F, G, H} ->
            lists:concat([A, ":", B, ":", C, ":", D, ":", E, ":", F, ":", G, ":", H]);
        Str when is_list(Str) ->
            Str;
        _ ->
            []
    end.

%% @doc IPv4地址的32b编码值
%% @param IPStr := "A.B.C.D"
%% @returns IPInt(32bit): AABBCCDD
-spec ip2hostlong(string()) -> integer().
ip2hostlong(IPStr) ->
    [A, B, C, D] = string:tokens(IPStr, "."),
    (?MODULE:to_integer(A) bsl 24) + (?MODULE:to_integer(B) bsl 16) + (?MODULE:to_integer(C) bsl 8) + ?MODULE:to_integer(D).

%% @doc 获得内网IP地址, 只是适合内部的服务器
-spec get_intranet_address() -> [nonempty_string()].
get_intranet_address() ->
    Result = os:cmd("ifconfig -a | grep 'inet ' | egrep '192.168.|10.10' | awk '{print $2}' | cut -d ':' -f 2 | grep -v '^127'"),
    string:tokens(Result, "\n").

%% @doc 获得所有绑定的IP地址
-spec get_all_bind_address() -> [nonempty_string()].
get_all_bind_address() ->
    Result = os:cmd("ifconfig -a | grep 'inet ' | awk '{print $2}' | cut -d ':' -f 2 | grep -v '^127'"),
    string:tokens(Result, "\n").

%% @doc 获得腾讯环境的机器的IP地址
%% @returns IPInt(32bit): AABBCCDD
-spec get_tx_ip_address() -> integer().
get_tx_ip_address() ->
    Result = os:cmd("ifconfig -a eth1 | grep 'inet ' | awk '{print $2}' | cut -d ':' -f 2"),
    [IPStr] = string:tokens(Result, "\n"),
    ip2hostlong(IPStr).

%%%%%%%%%######data type relative######%%%%%%%%%
%% @doc convert other type to integer
%% @throws other_value
-spec to_integer(integer() | binary() | list() | float() | term()) -> integer().
to_integer(Msg) when erlang:is_integer(Msg) -> %% 是integer的情况.
    Msg;
to_integer(Msg) when erlang:is_binary(Msg) ->  % 是binary的情况.
    Msg2 = erlang:binary_to_list(Msg),
    erlang:list_to_integer(Msg2);
to_integer(Msg) when erlang:is_list(Msg) ->  % 是[]的情况.
    case catch erlang:list_to_integer(Msg) of
        Int when erlang:is_integer(Int) ->
            Int;
        _ -> %% 部分是用科学计数法
            to_integer(to_float(Msg))
    end;
to_integer(Atom) when erlang:is_atom(Atom) ->
    erlang:list_to_integer(erlang:atom_to_list(Atom));
to_integer(Msg) when erlang:is_float(Msg) ->
    erlang:round(Msg);
to_integer(_Msg) ->
    erlang:throw(other_value).

%% @doc convert other type to binary
%% @throws other_value
-spec to_binary(any()) -> binary().
to_binary(Msg) when erlang:is_binary(Msg) ->
    Msg;
to_binary(Msg) when erlang:is_atom(Msg) ->
    erlang:list_to_binary(erlang:atom_to_list(Msg));
%%atom_to_binary(Msg, utf8);
to_binary(Msg) when erlang:is_list(Msg) ->
    erlang:list_to_binary(Msg);
to_binary(Msg) when erlang:is_integer(Msg) ->
    erlang:list_to_binary(integer_to_list(Msg));
to_binary(Msg) when erlang:is_float(Msg) ->
    erlang:list_to_binary(float_to_str(Msg));
to_binary(_Msg) ->
    erlang:throw({other_value, {_Msg, lib_sys:get_stacktrace()}}).

%% @doc convert other type to tuple
-spec to_tuple(tuple() | term()) -> tuple().
to_tuple(T) when erlang:is_tuple(T) -> T;
to_tuple(T)                         -> {T}.

%% @doc convert other type to float
-spec to_float(term()) -> float().
to_float(Msg) ->
    Msg2 = to_list(Msg),
    case catch erlang:list_to_float(Msg2) of
        Float when erlang:is_float(Float) ->
            Float;
        _ ->
            erlang:list_to_float(Msg2 ++ ".0")
    end.

%% @doc convert other type to list
%% @throws other_value
-spec to_list(list() | atom() | binary() | tuple() | integer() | float() | term() | pid()) -> list().
to_list(Msg) when erlang:is_list(Msg) ->
    Msg;
to_list(Msg) when erlang:is_atom(Msg) ->
    erlang:atom_to_list(Msg);
to_list(Msg) when erlang:is_binary(Msg) ->
    erlang:binary_to_list(Msg);
to_list(Msg) when erlang:is_tuple(Msg) ->
    erlang:tuple_to_list(Msg);
to_list(Msg) when erlang:is_integer(Msg) ->
    erlang:integer_to_list(Msg);
to_list(Msg) when erlang:is_float(Msg) ->
    float_to_str(Msg);
to_list(PID) when erlang:is_pid(PID) ->
    pid_to_str(PID);
to_list(_) ->
    erlang:throw(other_value).

%% @doc convert other type to atom
%% @throws other_value
-spec to_atom(atom() | binary() | list() | integer() | term()) -> atom().
to_atom(Msg) when erlang:is_atom(Msg) ->
    Msg;
to_atom(Msg) when erlang:is_binary(Msg) ->
    ?MODULE:list_to_atom(erlang:binary_to_list(Msg));
to_atom(Msg) when erlang:is_list(Msg) ->
    ?MODULE:list_to_atom(Msg);
to_atom(Msg) when erlang:is_integer(Msg) ->
    ?MODULE:list_to_atom(erlang:integer_to_list(Msg));
to_atom(_) ->
    erlang:throw(other_value).  %%list_to_atom("").

list_to_hex(L) ->
    lists:map(fun(X) -> int_to_hex(X) end, L).

%% @doc 单个字节的16进制字符串表达
-spec int_to_hex(integer()) -> string().
int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
    $0 + N;
hex(N) when N >= 10, N < 16 ->
    $a + (N - 10).

%% @doc list_to_atom
-spec list_to_atom(list()) -> atom().
list_to_atom(List) when is_list(List) ->
    case catch (erlang:list_to_existing_atom(List)) of
        {'EXIT', _} -> erlang:list_to_atom(List);
        Atom when is_atom(Atom) -> Atom
    end.

%% @doc 是否是string
-spec is_string(term()) -> true | false.
is_string(List) ->
    case catch erlang:list_to_binary(List) of
        {'EXIT', _} ->
            false;
        _Binary ->
            true
    end.

%% @doc convert proplists to integer
-spec proplists_to_integer(term(), list()) -> integer().
proplists_to_integer(Key, List) ->
    to_integer(proplists:get_value(Key, List)).

%% @doc convert float to string: 1.5678->1.57
-spec float_to_str(integer() | float()) -> string().
float_to_str(N) when erlang:is_integer(N) ->
    integer_to_list(N) ++ ".00";
float_to_str(F) when erlang:is_float(F) ->
    [A] = io_lib:format("~.2f", [F]),
    A.

pid_to_str(PID) ->
    erlang:pid_to_list(PID).

%% @doc md5
-spec md5(term()) -> string().
md5(S) ->
    Md5_bin = erlang:md5(?MODULE:to_list(S)),
    lists:flatten(list_to_hex(binary_to_list(Md5_bin))).

%% @doc get the minimum number that is bigger than X
-spec ceil(number()) -> integer().
ceil(X) ->
    T = erlang:trunc(X),
    if X == T -> T;
        X > 0 -> T + 1;
        true -> T
    end.

%% @doc get the maximum number that is smaller than X
-spec floor(number()) -> integer().
floor(X) ->
    T = erlang:trunc(X),
    if X == T -> T;
        X > 0 -> T;
        true -> T - 1
    end.

random(Max) ->
    rand:uniform(Max).
rand_bytes(Len) ->
    crypto:rand_bytes(Len).


%% @doc get a random integer between Min and Max
-spec random(integer(), integer()) -> integer().
random(Min, Max) ->
    Min2 = Min - 1,
    random(Max - Min2) + Min2.

%% @doc 获取元素在列表中的index
-spec list_element_index(term(), list()) -> integer().
list_element_index(K, List) ->
    list_element_index(K, List, 1).
list_element_index(_, [], _) ->
    0;
list_element_index(K, [K|_], Index) ->
    Index;
list_element_index(K, [_|T], Index) ->
    list_element_index(K, T, Index + 1).

%% @doc 合并2个列表, 过滤重复的
-spec combine_lists(list(), list()) -> list().
combine_lists(L1, L2) ->
    case erlang:length(L1) > erlang:length(L2) of
        true ->
            combine_lists1(L2, L1);
        _ ->
            combine_lists1(L1, L2)
    end.
combine_lists1([], ListB) ->
    ListB;
combine_lists1([A1|TListA], ListB) ->
    case lists:member(A1, ListB) of
        true -> combine_lists1(TListA, ListB);
        _ -> combine_lists1(TListA, [A1|ListB])
    end.

%% @doc 从一个List中随机取出N个元素
%% @end
%% 0 < N =< length(List), 如果N取值无效则返回空列表
-spec random_elements_from_list(integer(), list()) -> {ok, list()} | {ok, []}.
random_elements_from_list(N, _) when N =< 0 ->
    {ok, []};
random_elements_from_list(N, List) ->
    Len = erlang:length(List),
    random_elements_from_list2(N, Len, List).
random_elements_from_list2(N, N, L) ->
    {ok, L};
random_elements_from_list2(N, Len, _) when N > Len ->
    {ok, []};
random_elements_from_list2(N, Len, List) when N + N > Len ->
    IList = pick_index(Len - N, Len, []),
    random_elements_from_list(1, Len, IList, false, List, []);
random_elements_from_list2(N, Len, List) ->
    IList = pick_index(N, Len, []),
    random_elements_from_list(1, Len, IList, true, List, []).
pick_index(0, _, A) -> lists:sort(A);
pick_index(N, Len, A) ->
    I = random(Len),
    case lists:member(I, A) of
        true ->
            pick_index(N, Len, A);
        _ ->
            pick_index(N - 1, Len, [I|A])
    end.
random_elements_from_list(I, Len, _, _, _, A) when I > Len ->
    {ok, A};
random_elements_from_list(_, _, [], true, _, A) ->
    {ok, A};
random_elements_from_list(_, _, [], false, List, A) ->
    {ok, A ++ List};
random_elements_from_list(I, Len, [I|IL], true, [E|T], A) ->
    random_elements_from_list(I + 1, Len, IL, true, T, [E|A]);
random_elements_from_list(I, Len, [I|IL], false, [_|T], A) ->
    random_elements_from_list(I + 1, Len, IL, false, T, A);
random_elements_from_list(I, Len, IL, false, [E|T], A) ->
    random_elements_from_list(I + 1, Len, IL, false, T, [E|A]);
random_elements_from_list(I, Len, IL, true, [_|T], A) ->
    random_elements_from_list(I + 1, Len, IL, true, T, A).

%% @doc 从一个List中随机取出Num个元素, CheckFunc用于过滤不合适的元素
%% @end
%%      0 < Num =< length(List), 如果Num取值无效则返回空列表
%%      CheckFunc   := fun/1->Boolean
-spec random_elements_from_list(integer(), list(), function()) -> {ok, list()} | {error, []}.
random_elements_from_list(Num, Inlist, CheckFunc) when is_function(CheckFunc) ->
    case Num =< 0 of
        true ->
            {error, []};
        false ->
            random_elements_from_list1([], Num, Inlist, CheckFunc)
    end.
random_elements_from_list1(OutList, 0, _Inlist, _Func) ->
    {ok, OutList};
random_elements_from_list1(OutList, _, [], _Func) ->
    {ok, OutList};
random_elements_from_list1(OutList, Num, Inlist, Func) ->
    Index = random(length(Inlist)),
    OutElement = lists:nth(Index, Inlist),
    case catch Func(OutElement) of
        true ->
            NewOutList = [OutElement|OutList],
            NewInList = lists:delete(OutElement, Inlist),
            NewNum = Num - 1,
            ok;
        _ ->
            NewOutList = OutList,
            NewInList = lists:delete(OutElement, Inlist),
            NewNum = Num,
            ok
    end,
    random_elements_from_list1(NewOutList, NewNum, NewInList, Func).

%% @doc 随机取一个元素
%% @throws badarg
-spec random_element_from_list([term()]) -> term().
random_element_from_list([]) ->
    throw(badarg);
random_element_from_list(Inlist) ->
    Index = random(length(Inlist)),
    lists:nth(Index, Inlist).

%% @doc 随机打乱List顺序
-spec random_reorder_list(list()) -> list().
random_reorder_list(List) ->
    List1 = [{random(10000), X} || X <- List],
    List2 = lists:keysort(1, List1),
    [E || {_, E} <- List2].

%% @doc 检查列表中是否有重复的元素
-spec has_duplicate_member(list()) -> true | false.
has_duplicate_member([]) ->
    false;
has_duplicate_member([E|L]) ->
    case lists:member(E, L) of
        true ->
            true;
        _ ->
            has_duplicate_member(L)
    end.

%% @doc 检查列表中是否存在重复元素
-spec repeated_element_in_lists(list(), list()) -> true | false.
repeated_element_in_lists(List1, List2) ->
    case erlang:length(List1) > erlang:length(List2) of
        true ->
            repeated_element_in_lists1(List2, List1);
        _ ->
            repeated_element_in_lists1(List1, List2)
    end.
repeated_element_in_lists1([], _ListB) ->
    false;
repeated_element_in_lists1(_ListA, []) ->
    false;
repeated_element_in_lists1([A1|TListA], ListB) ->
    case lists:member(A1, ListB) of
        true -> true;
        _ -> repeated_element_in_lists1(TListA, ListB)
    end.

%% @doc List去重, 顺序不乱
-spec list_filter_repeat(list()) -> list().
list_filter_repeat(List) ->
    lists:reverse(lists:foldl(fun(Elem, Acc) ->
        case lists:member(Elem, Acc) of
            true ->
                Acc;
            false ->
                [Elem|Acc]
        end end,              [], List)).

%% @doc List去重
%%      可以替换第一种实现，数据越多效率越明显; 合并过程内存开销是前面一种的1~4倍，以空间换时间，合并10万条数据比尾递归多1~2M内存使用，但是使用后内存会被gc
%%      结果是排好序的，从小到大
-spec list_filter_repeat2(list()) -> list().
list_filter_repeat2(List) ->
    gb_sets:to_list(gb_sets:from_list(List)).

%% @doc List合并去重
%%      合并List、List2，去重；前面写了尾递归方式的合并去重，无论哪种情况，效率没这个高
%%      结果是排好序的，从小到大
-spec list_filter_repeat2(list(), list()) -> list().
list_filter_repeat2(List1, List2) ->
    gb_sets:to_list(gb_sets:union(gb_sets:from_list(List1), gb_sets:from_list(List2))).

%% @doc List中的元素做字符串衔接
-spec concat(list()) -> list().
concat(List) ->
    List2 = [?MODULE:to_list(E) || E <- List],
    lists:concat(List2).

%% @doc 格式化字符串
-spec flatten_format(list(), list()) -> list().
flatten_format(LangResources, ParamList) when erlang:is_list(ParamList) ->
    lists:flatten(io_lib:format(LangResources, [?MODULE:to_list(PR) || PR <- ParamList]));
flatten_format(LangResources, Param) ->
    lists:flatten(io_lib:format(LangResources, [?MODULE:to_list(Param)])).

%%随机概率Weights=[{权重,输出}....]}
get_weight_output(Weights) ->
    {MaxWeight, WeightProps} = lists:foldl(
        fun({W, Out}, {AccMax, AccWeightProps}) ->
            WeightProp = {AccMax + 1, AccMax + W, Out},
            {AccMax + W, [WeightProp|AccWeightProps]}
        end, {0, []}, Weights),
    get_weight_output(MaxWeight, lists:reverse(WeightProps)).
%%随机概率MaxWeight,WeightProps = 总权重,[{MIN1,MAX1,输出}....]
get_weight_output(_MaxWeight, []) ->
    error;
get_weight_output(MaxWeight, WeightProps) ->
    Random = lib_tool:random(1, MaxWeight),
    get_config_list_output(Random, WeightProps).
get_config_list_output(_Value, []) ->
    error;
get_config_list_output(Value, [{Min, Max, MatchValue}|TCfgList]) ->
    case Value >= Min andalso Value =< Max of
        true -> MatchValue;
        _ ->
            get_config_list_output(Value, TCfgList)
    end.

%% @doc 根据权重、数量获取对应列表
%% 这个不是重复抽取！！！
%% WeightList -> [{Weigh, Val}|....]
get_list_by_weight(Num, WeightList) ->
    if
        Num =< 0 ->
            erlang:throw(num_error);
        Num >= erlang:length(WeightList) ->
            [Val || {_, Val} <- WeightList];
        true ->
            get_list_by_weight2(Num, WeightList, [])
    end.

get_list_by_weight2(0, _WeightList, Acc) ->
    Acc;
get_list_by_weight2(Num, WeightList, Acc) ->
    {MaxWeight, WeightList2} =
    lists:foldl(
        fun({Weight, Val}, {WeightAcc, WeighListAcc}) ->
            WeightAcc2 = WeightAcc + Weight,
            {WeightAcc2, [{WeightAcc + 1, WeightAcc2, Weight, Val}|WeighListAcc]}
        end, {0, []}, WeightList),
    Random = lib_tool:random(MaxWeight),
    %% 获取值并且返回剩余列表
    {Val, WeightList3} = get_list_by_weight3(Random, WeightList2, undefined, []),
    get_list_by_weight2(Num - 1, WeightList3, [Val|Acc]).

get_list_by_weight3(_Random, [], Acc1, Acc2) ->
    {Acc1, Acc2};
get_list_by_weight3(Random, [{Min, Max, Weigh, Val}|R], Acc1, Acc2) ->
    case Min =< Random andalso Random =< Max of
        true ->
            get_list_by_weight3(Random, R, Val, Acc2);
        _ ->
            get_list_by_weight3(Random, R, Acc1, [{Weigh, Val}|Acc2])
    end.

split(N, List) when erlang:length(List) > N ->
    lists:split(N, List);
split(_N, List) ->
    {List, []}.

%% @doc get utf8 len
-spec utf8_len(list() | binary()) -> integer().
utf8_len(List) when erlang:is_list(List) ->
    len(List, 0);
utf8_len(Binary) when erlang:is_binary(Binary) ->
    len(erlang:binary_to_list(Binary), 0).


len([], N) ->
    N;
len([A, _, _, _, _, _|T], N) when A =:= 252 orelse A =:= 253 ->
    len(T, N + 1);
len([A, _, _, _, _|T], N) when A >= 248 andalso A =< 251 ->
    len(T, N + 1);
len([A, _, _, _|T], N) when A >= 240 andalso A =< 247 ->
    len(T, N + 1);
len([A, _, _|T], N) when A >= 224 ->
    len(T, N + 1);
len([A, _|T], N) when A >= 192 ->
    len(T, N + 1);
len([_A|T], N) ->
    len(T, N + 1).

%% @doc get utf8 len(sublist)
-spec sublist_utf8(list() | binary(), integer(), integer()) -> string().
sublist_utf8(List, Start, Length) when erlang:is_list(List) ->
    sublist_utf8_2(List, Start, Start + Length - 1, 0, []);
sublist_utf8(Binary, Start, Length) when erlang:is_binary(Binary) ->
    sublist_utf8_2(erlang:binary_to_list(Binary), Start, Start + Length - 1, 0, []).

sublist_utf8_2(List, Start, End, Cur, Result) ->
    if Cur =:= End ->
        lists:reverse(Result);
        true ->
            sublist_utf8_3(List, Start, End, Cur, Result)
    end.

sublist_utf8_3([], _Start, _End, _Cur, Result) ->
    lists:reverse(Result);
sublist_utf8_3([A, A2, A3, A4, A5, A6|T], Start, End, Cur, Result) when A =:= 252 orelse A =:= 253 ->
    if Cur + 1 >= Start ->
        Result2 = [A6, A5, A4, A3, A2, A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2);
sublist_utf8_3([A, A2, A3, A4, A5|T], Start, End, Cur, Result) when A >= 248 andalso A =< 251 ->
    if Cur + 1 >= Start ->
        Result2 = [A5, A4, A3, A2, A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2);
sublist_utf8_3([A, A2, A3, A4|T], Start, End, Cur, Result) when A >= 240 andalso A =< 247 ->
    if Cur + 1 >= Start ->
        Result2 = [A4, A3, A2, A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2);
sublist_utf8_3([A, A2, A3|T], Start, End, Cur, Result) when A >= 224 ->
    if Cur + 1 >= Start ->
        Result2 = [A3, A2, A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2);
sublist_utf8_3([A, A2|T], Start, End, Cur, Result) when A >= 192 ->
    if Cur + 1 >= Start ->
        Result2 = [A2, A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2);
sublist_utf8_3([A|T], Start, End, Cur, Result) ->
    if Cur + 1 >= Start ->
        Result2 = [A|Result];
        true ->
            Result2 = Result
    end,
    sublist_utf8_2(T, Start, End, Cur + 1, Result2).

is_greater(Vsn1, Vsn2) -> compare_version(Vsn1, Vsn2) == greater.
is_less(Vsn1, Vsn2) -> compare_version(Vsn1, Vsn2) == less.
is_greater_or_equal(Vsn1, Vsn2) -> not is_less(Vsn1, Vsn2).
is_less_or_equal(Vsn1, Vsn2) -> not is_greater(Vsn1, Vsn2).

compare_version(Vsn, Vsn) ->
    equal;
compare_version(Vsn1, Vsn2) ->
    compare_version1(string:tokens(Vsn1, "."), string:tokens(Vsn2, ".")).

compare_version1([], []) ->
    equal;
compare_version1([_X], []) ->
    greater;
compare_version1([], [_X]) ->
    less;
compare_version1([X|Rest1], [X|Rest2]) ->
    compare_version1(Rest1, Rest2);
compare_version1([X1], [X2]) ->
    %% For last digit ignore everything after the "-", if any
    Y1 = lists:takewhile(fun(X) -> X /= $- end, X1),
    Y2 = lists:takewhile(fun(X) -> X /= $- end, X2),
    compare_digit(Y1, Y2);
compare_version1([X1|Rest1], [X2|Rest2]) ->
    case compare_digit(X1, X2) of
        equal -> compare_version1(Rest1, Rest2);
        Else -> Else
    end.

compare_digit(X, X) ->
    equal;
compare_digit(X1, X2) when length(X1) > length(X2) ->
    greater;
compare_digit(X1, X2) when length(X1) < length(X2) ->
    less;
compare_digit(X1, X2) ->
    case X1 > X2 of
        true -> greater;
        false -> less
    end.

%% @doc  unicode代码点长度，一个字符对应一个代码点。
-spec code_point_len(list() | binary()) -> integer().
code_point_len(List) ->
    ListBin = lib_tool:to_binary(List),
    erlang:length(unicode:characters_to_list(ListBin)).

%% 生成文件时用到
to_output(List) when erlang:is_list(List) ->
    "[" ++ to_list_output(List) ++ "]";
to_output(Tuple) when erlang:is_tuple(Tuple) ->
    "{" ++ to_list_output(erlang:tuple_to_list(Tuple)) ++ "}";
to_output(Int) when erlang:is_integer(Int) ->
    erlang:integer_to_list(Int);
to_output(Float) when erlang:is_float(Float) ->
    erlang:integer_to_list(ceil(Float));
to_output(Atom) when erlang:is_atom(Atom) ->
    erlang:atom_to_list(Atom).

to_list_output(List) ->
    to_list_output(List, ",").
to_list_output(List, Separator) ->
    to_list_output(List, Separator, []).

to_list_output([], _Separator, Acc) ->
    Acc;
to_list_output([T|R], Separator, []) ->
    Acc2 = to_output(T),
    to_list_output(R, Separator, Acc2);
to_list_output([T|R], Separator, Acc) ->
    Acc2 = Acc ++ Separator ++ to_output(T),
    to_list_output(R, Separator, Acc2).

%% 生成前端需要的Unicode
to_unicode(Bin) when erlang:is_binary(Bin) ->
    unicode:characters_to_list(Bin);
to_unicode(List) when erlang:is_list(List) ->
    to_unicode(to_binary(List)).


%% 根据";"及","拆分字符串成单个列表   "1,2,3;4,5;6" -> [{1,2,3},{4,5},{6}],  "1" -> [{1}]
string_to_intlist(SL) ->
    if SL =:= undefined ->
        [];
        true ->
            string_to_intlist(SL, ";", ",")
    end.

%% 根据Split1, Split2拆分字符串成单个列表
string_to_intlist(String, Split1, Split2) ->
    case erlang:is_list(String) of
        true ->
            NewSplit1 = to_list(Split1),
            NewSplit2 = to_list(Split2),
            SList = string:tokens(String, NewSplit1),
            F1 = fun(Item) -> {Num, _Rest} = string:to_integer(Item), Num end,
            F = fun(X, L) ->
                L1 = string:tokens(X, NewSplit2),
                L2 = [F1(I) || I <- L1],
                I2 = list_to_tuple(L2),
                [I2|L]
                end,
            lists:foldr(F, [], SList);
        _ ->
            []
    end.

string_to_integer_list(SL) ->
    if SL =:= undefined ->
        [];
        true ->
            string_to_integer_list(SL, ",")
    end.

string_to_integer_list(String, Split1) ->
    case erlang:is_list(String) of
        true ->
            IntegerList = [erlang:list_to_integer(A) || A <- string:tokens(String, Split1)],
            IntegerList;
        _ ->
            []
    end.

%% @doc 符合条件就返回的foldl
foldl(_F, {return, Accu}, _Tail) ->
    Accu;
foldl(F, Accu, [Hd|Tail]) ->
    foldl(F, F(Hd, Accu), Tail);
foldl(F, Accu, []) when is_function(F, 2) -> Accu.

%% @doc 返回索引
get_lists_index([], _H, _Index) ->
    0;
get_lists_index([H|_T], H, Index) ->
    Index;
get_lists_index([_H|T], H, Index) ->
    get_lists_index(T, H, Index + 1).


add_logs(List, [], _Length)->
    List;
add_logs(List, Logs, Length)->
    [Log|T] = Logs,
    List2 = add_log(List, Log, Length),
    add_logs(List2, T, Length).
add_log(List, Log, Length) ->
    case erlang:length(List) < Length of
        true ->
            [Log|List];
        _ ->
            [Log|lists:droplast(List)]
    end.














