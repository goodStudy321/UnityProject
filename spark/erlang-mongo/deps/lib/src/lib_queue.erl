%%%-------------------------------------------------------------------
%% @doc 
%%      基于进程字典的通用队列
%% @end
%%%-------------------------------------------------------------------


-module(lib_queue).

%% API functions
-export([
         push/2,
         pop/1,
         pop/2,
         peek/1,
         peek/2,
         peek_range/2,
         peek_range/3,
         take/2,
         clear/1,
         length/1,
         is_empty/1,
         to_list/1,
         foldl/3
        ]).


%% @doc 加元素到队尾, 返回其位置
-spec push(QueueName, Data) -> Idx when
            QueueName :: term(),
            Data :: term(),
            Idx :: non_neg_integer().
push(QueueName, Data) ->
    T = get_queue_tail(QueueName),
    set_queue_element(QueueName, T, Data),
    set_queue_tail(QueueName, T+1),
    T.


%% @doc 取出队首元素
-spec pop(QueueName) -> Data | undefined when
            QueueName :: term(),
            Data :: term().
pop(QueueName) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    case H>=T of
        true ->
            undefined;
        _ when H+1=:=T ->
            Data = del_queue_element(QueueName, H),
            set_queue_head(QueueName, 0),
            set_queue_tail(QueueName, 0),
            Data;
        _ ->
            Data = del_queue_element(QueueName, H),
            set_queue_head(QueueName, H+1),
            Data
    end.

%% @doc 取出最多N个元素
-spec pop(QueueName, Count) -> {ResCount,[Data]} when
            QueueName :: term(),
            Count :: non_neg_integer(),
            ResCount :: non_neg_integer(),
            Data :: term().
pop(QueueName, Count) ->
    pop(QueueName, Count, 0, []).
pop(_, C, RC, Res) when C=<0 ->
    {RC,lists:reverse(Res)};
pop(QueueName, C, RC, AccRes) ->
    case pop(QueueName) of
        undefined ->
            pop(QueueName, 0, RC, AccRes);
        Data ->
            pop(QueueName, C-1, RC+1, [Data|AccRes])
    end.


%% @doc 查看队首元素, 但不移出队列
-spec peek(QueueName) -> Data | undefined when
            QueueName :: term(),
            Data :: term().
peek(QueueName) ->
    H = get_queue_head(QueueName),
    get_queue_element(QueueName, H).

%% @doc 查看指定位置元素, 但不移出队列
-spec peek(QueueName, Idx) -> Data | undefined when
            QueueName :: term(),
            Idx :: non_neg_integer(),
            Data :: term().
peek(QueueName, Idx) ->
    get_queue_element(QueueName, Idx).

%% @doc 查看队首的N个元素, 但不移出队列
%% @returns {Count,Ls}
peek_range(QueueName, Count) ->
    peek_range(QueueName, Count, undefined).
%% @doc 查看队首的N个元素, 但不移出队列,
%%      当 Func(Data) 返回 非true 时跳过该元素
%% @returns {Count,Ls}
peek_range(QueueName, Count, Func) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    peek_range(QueueName, H, min(T, H+Count-1), [], 0, Func).
peek_range(_, S, E, Acc, C, _) when S>E ->
    {C,lists:reverse(Acc)};
peek_range(QueueName, Idx, E, Acc, C, Func) ->
    case get_queue_element(QueueName, Idx) of
        undefined ->
            Acc2 = Acc,
            C2 = C;
        Data ->
            case (not is_function(Func)) orelse (catch Func(Data)) of
                true ->
                    Acc2 = [Data|Acc],
                    C2 = C+1;
                _ ->
                    Acc2 = Acc,
                    C2 = C
            end
    end,
    peek_range(QueueName, Idx+1, E, Acc2, C2, Func).


%% @doc 取出指定位置元素, 不会影响其他元素的位置
-spec take(QueueName, Idx) -> Data | undefined when
            QueueName :: term(),
            Idx :: non_neg_integer(),
            Data :: term().
take(QueueName, Idx) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    case H>=T orelse Idx<H orelse Idx>=T of
        true ->
            undefined;
        _ ->
            Data = del_queue_element(QueueName, Idx),
            if H=:=Idx, H+1=:=T -> set_queue_head(QueueName, 0), set_queue_tail(QueueName, 0);
               H=:=Idx -> set_queue_head(QueueName, H+1);
               true -> ignore
            end,
            if T=:=Idx, T-1=:=H -> set_queue_head(QueueName, 0), set_queue_tail(QueueName, 0);
               T=:=Idx -> set_queue_tail(QueueName, T-1);
               true -> ignore
            end,
            Data
    end.


%% @doc 删除队列全部内容
-spec clear(QueueName) -> ok when
            QueueName :: term().
clear(QueueName) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    clear(QueueName, H, T).
clear(QueueName, T, T) ->
    set_queue_head(QueueName, 0),
    set_queue_tail(QueueName, 0),
    ok;
clear(QueueName, H, T) ->
    del_queue_element(QueueName, H),
    clear(QueueName, H+1, T).


%% @doc 队列长度
-spec length(QueueName) -> Length when
            QueueName :: term(),
            Length :: non_neg_integer().
length(QueueName) ->
    get_queue_tail(QueueName) - get_queue_head(QueueName).


-spec is_empty(QueueName) -> boolean() when
            QueueName :: term().
is_empty(QueueName) ->
    ?MODULE:length(QueueName) =:= 0.


%% @doc 打包为list, 此操作不影响队列本身
-spec to_list(QueueName) -> [Data] when
            QueueName :: term(),
            Data :: term().
to_list(QueueName) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    to_list(QueueName, H, T, []).
to_list(_, H, H, Ls) ->
    Ls;
to_list(QueueName, H, T, LsAcc) ->
    Data = get_queue_element(QueueName, T-1),
    to_list(QueueName, H, T-1, [Data|LsAcc]).


%% @doc 执行foldl
-spec foldl(Fun, Acc, QueueName) -> Acc when
            Fun :: function(),
            Acc :: term(),
            QueueName :: term().
foldl(Fun, Acc, QueueName) ->
    H = get_queue_head(QueueName),
    T = get_queue_tail(QueueName),
    foldl(H, T, Fun, Acc, QueueName).
foldl(T, T, _, Acc, _) -> Acc;
foldl(H, T, Fun, Acc, QueueName) ->
    Data = get_queue_element(QueueName, H),
    Acc2 = Fun(Data, Acc),
    foldl(H+1, T, Fun, Acc2, QueueName).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_queue_head(QueueName) ->
    case erlang:get({?MODULE,head,QueueName}) of
        undefined -> 0;
        Idx -> Idx
    end.
set_queue_head(QueueName, 0) ->
    erlang:erase({?MODULE,head,QueueName});
set_queue_head(QueueName, Idx) ->
    erlang:put({?MODULE,head,QueueName}, Idx).

get_queue_tail(QueueName) ->
    case erlang:get({?MODULE,tail,QueueName}) of
        undefined -> 0;
        Idx -> Idx
    end.
set_queue_tail(QueueName, 0) ->
    erlang:erase({?MODULE,tail,QueueName});
set_queue_tail(QueueName, Idx) ->
    erlang:put({?MODULE,tail,QueueName}, Idx).

get_queue_element(QueueName, Idx) ->
    erlang:get({?MODULE,queue,QueueName,Idx}).
set_queue_element(QueueName, Idx, Data) ->
    erlang:put({?MODULE,queue,QueueName,Idx}, Data).
del_queue_element(QueueName, Idx) ->
    erlang:erase({?MODULE,queue,QueueName,Idx}).



