%%%-------------------------------------------------------------------
%%% @doc
%%%     通用系统信息获取（进程、ets、mnesia内存/节点状态/进程状态等）
%%% @end
%%%-------------------------------------------------------------------
-module(lib_sys).

%%
%% Exported Functions
%%
-export([
    i/0
]).
-export([
    info/1,
    info/2
]).

-export([
    m/1,
    mlength/1,
    d/1,
    d/2,
    dlength/1,
    dlength/2,
    dict/1
]).

-export([
    is_alive/1,
    sleep/1,
    gc/2,
    gc/1,
    gc_nodes/1,
    get_backtrace/0,
    get_backtrace/1,
    get_stacktrace/0,
    get_stacktrace/1
]).


-export([
    all_process_info/0,
    process_abn/1,
    process_abn/2,
    get_all_port_stat/0,
    get_socket_stat_summary/1,
    format_memory/2
]).


-export([
    get_total_mnesia_memory/0,
    get_mnesia_table_memory/0,
    get_mnesia_table_memory/1,
    get_memory_pids/1
]).

-export([
    get_memory/0,
    get_memory/1,
    get_heap/0,
    get_heap/1,
    get_ets_memory/0,
    get_ets_memory/1
]).

-export([
    atom_info/0,
    all_atoms/0]).

%%
%% API Functions
%%

%% @doc 系统基本信息
-spec i() -> ok.
i() ->
    SchedID = erlang:system_info(scheduler_id),
    SchedNum = erlang:system_info(schedulers),
    ProcCount = erlang:system_info(process_count),
    ProcLimit = erlang:system_info(process_limit),
    ProcMemUsed = erlang:memory(processes_used),
    ProcMemAlloc = erlang:memory(processes),
    MemTot = erlang:memory(total),
    Nodes = [node() | nodes()],
    io:format("****** ----------------------- Summary ----------------------------~n~n"),
    io:format("~40s : ~p ~n", ["Node Number", erlang:length(Nodes)]),
    io:format("~40s : ~p ~n", ["Processes Number", erlang:length(erlang:processes())]),
    io:format("~40s : ~p ~n", ["Scheduler id:", SchedID]),
    io:format("~40s : ~p ~n", ["Num scheduler:", SchedNum]),
    io:format("~40s : ~p ~n", ["Process count:", ProcCount]),
    io:format("~40s : ~p ~n", ["Process limit:", ProcLimit]),
    io:format("~40s : ~p MB ~n", ["Memory used by erlang processes:", format_memory(ProcMemUsed, mb)]),
    io:format("~40s : ~p MB ~n", ["Memory allocated by erlang processes:", format_memory(ProcMemAlloc, mb)]),
    io:format("~40s : ~p MB ~n", ["The total amount of memory allocated::", format_memory(MemTot, mb)]),
    io:format("~n****** ----------------------- Summary ----------------------------~n~n"),
    io:format("****** ----------------------- Memory ----------------------------~n~n"),
    lists:foreach(
        fun(Node) ->
            io:format("~40s ~s : ~p MB~n", ["Node Total Memory", Node, format_memory(rpc:call(Node, erlang, memory, [total]), mb)])
        end, Nodes),
    [begin
         io:format("~40s ~s : ~p MB ~n", ["Node Total Mnesia Memory", Node, format_memory(rpc:call(Node, lib_sys, get_total_mnesia_memory, []), mb)])
     end || Node <- Nodes],
    io:format("~n"),
    io:format("****** ----------------------- Memory ----------------------------~n~n"),
    ok.

%% @doc process_info/1
-spec info(pid() | atom()) -> [{atom(), term()}].
info(PID) when erlang:is_pid(PID)->
    info(PID,all);
info(PName) when erlang:is_atom(PName) ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID)->
            info(PID,all);
        _ ->undefined
    end;
info(_Other) ->
    undefined.

%% @doc process_info/2
-spec info(pid() | atom(), atom()) -> [{atom(), term()}] | undefined | term().
info(PID,Key) when erlang:is_pid(PID)->
    case Key of
        all->Args = [PID];
        _ -> Args = [PID, Key]
    end,
    Info = rpc:block_call(node(PID), erlang, process_info, Args),
    case is_list(Key) orelse Key=:=all of
        true -> Info;
        _ ->erlang:element(2, Info)
    end;
info(PName,Key) when erlang:is_atom(PName) ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID)->
            info(PID,Key);
        _ ->undefined
    end;
info(_Other,_Key)->
    undefined.

%% @doc process_info/2 messages
-spec m(pid() | atom()) -> undefined | term().
m(PName)->
    info(PName,messages).

%% @doc process_info/2 message_queue_len
-spec mlength(pid() | atom()) -> undefined | term().
mlength(PName)->
    info(PName,message_queue_len).

%% @doc process_info/2 dictionary
-spec d(pid() | atom()) -> undefined | term().
d(PName)->
    info(PName,dictionary).

%% @doc length of dictionary
-spec dlength(pid() | atom()) -> integer() | false.
dlength(PName)->
    case d(PName) of
        {_K,Val}-> length( Val );
        _ -> false
    end.

%% @doc key in dictionary
-spec d(pid() | atom(), term()) -> term() | false.
d(PName,Key)->
    DictVal = d(PName),
    case lists:keyfind(Key, 1, DictVal) of
        false-> false;
        Val-> element(2, Val)
    end.

%% @doc length of key in dictionary
-spec dlength(pid() | atom(), term()) -> integer() | false | string().
dlength(PName,Key)->
    case d(PName,Key) of
        false->
            false;
        {_K,Val} when is_list(Val) ->
            length(Val);
        {_K,_Val}  ->
            "Value is not list!!"
    end.

%% @doc 将某进程的进程字典写到文件中
-spec dict(pid() | atom()) -> ok | {error, term()}.
dict(PName) ->
    FileName =  lists:concat(["/tmp/", lib_tool:to_list(PName),"dictionary", ".txt"]),
    file:write_file(FileName, io_lib:format("~p", [erlang:process_info(whereis(PName),dictionary)]), [write]).

%% @doc 进程是否存活
-spec is_alive(pid() | atom()) -> true | false.
is_alive(PID) when erlang:is_pid(PID) ->
    rpc:call(node(PID) , erlang, is_process_alive, [PID]);
is_alive(PName) when erlang:is_atom(PName) ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID)->
            is_process_alive(PID);
        _ -> false
    end;
is_alive(_Other) ->
    false.

%% @doc 查看当前进程当前的stacktrace
-spec get_stacktrace() -> tuple() | undefined.
get_stacktrace()->
    get_stacktrace(erlang:self()).

%% @doc 查看指定进程当前的stacktrace
-spec get_stacktrace(pid() | atom()) -> tuple() | undefined .
get_stacktrace(PID) when erlang:is_pid(PID) ->
    case erlang:process_info(PID, current_stacktrace) of
        {current_stacktrace, [_|Stacktrace]} ->
            {current_stacktrace, Stacktrace};
        Err -> Err
    end;
get_stacktrace(PName) when erlang:is_atom(PName) ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID) ->
            get_stacktrace(PID);
        _ -> undefined
    end;
get_stacktrace(_Other)->
    undefined.

%% @doc 查看当前进程stacktrace
-spec get_backtrace() -> [{atom(), atom(), integer()}] | undefined.
get_backtrace() ->
    get_backtrace(erlang:self()).

%% @doc 查看指定进程stacktrace
-spec get_backtrace(pid() | atom()) -> [{atom(), atom(), integer()}] | undefined.
get_backtrace(PID) when erlang:is_list(PID)  ->
    ?MODULE:get_backtrace(erlang:list_to_pid(PID));
get_backtrace(PID) when erlang:is_pid(PID)  ->
    {_, BT} = erlang:process_info(PID, backtrace),
    case re:run(BT, "([0-9a-z_]+:[0-9a-z_]+/[0-9])", [global]) of
        {match, Captured} ->
            get_backtrace2(BT, Captured);
        nomatch ->
            []
    end;
get_backtrace(PName) when erlang:is_atom(PName)  ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID)->
            get_backtrace(PID);
        _ ->undefined
    end;
get_backtrace(_Other) ->
    undefined.

get_backtrace2(BT, Captured) ->
    CaptureList =
        lists:foldl(
            fun(CaptureData, Acc) ->
                case CaptureData of
                    {Begin, Len} ->ok;
                    [_, {Begin, Len}] -> ok;
                    _ ->Begin = Len = 0
                end,
                if Begin =:= 0 andalso Len =:= 0 ->
                    Acc;
                    true ->
                        <<_:Begin/binary, R:Len/binary, _/binary>> = BT,
                        [M, F, A] = string:tokens(lib_tool:to_list(R), ":/"),
                        [{lib_tool:to_atom(M), lib_tool:to_atom(F), lib_tool:to_integer(A)}|Acc]
                end
            end, [], Captured),
    [_|T] = lists:reverse(CaptureList),
    T.

%% @doc 打印节点所有进程的关键process_info
-spec all_process_info() -> ok.
all_process_info() ->
    lists:foreach(
        fun(P)->
            io:format("~p~p~p ~p~n",[P, erlang:process_info(P,registered_name),
                erlang:process_info(P, current_function),
                erlang:process_info(P, message_queue_len)])
        end, erlang:processes()),
    ok.

%% @doc 打印消息队列长度不小于MsgLen的所有进程关键process_info
-spec process_abn(integer()) -> ok.
process_abn(MsgLen) ->
    L = lists:foldl(fun(P,Acc) ->
        {message_queue_len,Len} = erlang:process_info(P, message_queue_len),
        case Len >= MsgLen of
            true ->
                {current_function,Fun} = erlang:process_info(P, current_function),
                case erlang:process_info(P, registered_name) of
                    {registered_name,PName} ->ignore;
                    _ -> PName = undefined
                end,
                {reductions,Red} = erlang:process_info(P, reductions),
                {total_heap_size,THeap} = erlang:process_info(P, total_heap_size),
                {heap_size,Heap} = erlang:process_info(P, heap_size),
                {current_stacktrace,Stack} = erlang:process_info(P,current_stacktrace),
                [{PName, P,Fun,Len,Red,THeap,Heap,Stack}|Acc];
            _ ->Acc
        end end,[], erlang:processes()),
    [begin
         io:format("~-30s ~-20w ~-32w Len:~-5w Red:~-8w THeap:~-8w Heap:~-8w Stack:~-8w~n",[PName, P,Fun,Len,Red,THeap,Heap,Stack])
     end || {PName, P,Fun,Len,Red,THeap,Heap,Stack} <- lists:reverse(lists:keysort(4,L))],
    ok.
%% @doc 打印进程所占内存不小于AbnSise的所有进程关键process_info
-spec process_abn(memory, integer()) -> ok | ignore.
process_abn(memory,AbnSise) when AbnSise < 1024 * 100 ->
    ignore;
process_abn(memory,AbnSise) ->
    L = lists:foldl(fun(P,Acc) ->
        {memory,Size} = erlang:process_info(P, memory),
        case Size >= AbnSise of
            true ->
                {current_function,Fun} = erlang:process_info(P, current_function),
                case erlang:process_info(P, registered_name) of
                    {registered_name,PName} ->ignore;
                    _ -> PName = undefined
                end,
                {reductions,Red} = erlang:process_info(P, reductions),
                {total_heap_size,THeap} = erlang:process_info(P, total_heap_size),
                {heap_size,Heap} = erlang:process_info(P, heap_size),
                {stack_size,Stack} = erlang:process_info(P, stack_size),
                [{PName, P,Fun,Size,Red,THeap,Heap,Stack}|Acc];
            _ ->Acc
        end end,[], erlang:processes()),
    [begin
         io:format("~-30s ~-20w ~-32w Size:~-20w Red:~-8w THeap:~-8w Heap:~-8w Stack:~-8w~n",[PName, P,Fun,Size,Red,THeap,Heap,Stack])
     end || {PName, P,Fun,Size,Red,THeap,Heap,Stack} <- lists:reverse(lists:keysort(4,L))],
    ok.

%% @doc ports统计
-spec get_all_port_stat() -> {[{atom(), integer()}], integer()}.
get_all_port_stat() ->
    get_socket_stat_summary(erlang:ports()).

%% @doc ports统计
-spec get_socket_stat_summary([port()]) -> {[{atom(), integer()}], integer()}.
get_socket_stat_summary(Sockets) ->
    lists:foldl(
        fun(S, {Summary, Num}) ->
            case inet:getstat(S) of
                {ok,[{recv_oct,RecvOct},{recv_cnt,RecvCnt},{recv_max,RecvMax},
                    {recv_avg,RecvAvg},{recv_dvi,RecvDvi}, {send_oct,SendOct},
                    {send_cnt,SendCnt},{send_max,SendMax},{send_avg,SendAvg},
                    {send_pend,SendPend}]} ->
                    [{recv_oct,OldRecvOct}, {recv_cnt,OldRecvCnt},{recv_max,OldRecvMax},
                        {recv_avg,OldRecvAvg},{recv_dvi,OldRecvDvi}, {send_oct,OldSendOct},
                        {send_cnt,OldSendCnt}, {send_max,OldSendMax},{send_avg,OldSendAvg},
                        {send_pend,OldSendPend}] = Summary,
                    NewSendMax = erlang:max(SendMax, OldSendMax),
                    NewRecvMax = erlang:max(RecvMax, OldRecvMax),
                    NewSummary = [{recv_oct,OldRecvOct+RecvOct},
                        {recv_cnt,OldRecvCnt+RecvCnt}, {recv_max,NewRecvMax}, {recv_avg,OldRecvAvg+RecvAvg},
                        {recv_dvi,OldRecvDvi+RecvDvi}, {send_oct,OldSendOct+SendOct}, {send_cnt,OldSendCnt+SendCnt},
                        {send_max,NewSendMax}, {send_avg,OldSendAvg+SendAvg}, {send_pend,OldSendPend+SendPend}],
                    {NewSummary, Num+1};
                _ ->
                    {Summary, Num}
            end
        end, {[{recv_oct,0},{recv_cnt,0},{recv_max,0},{recv_avg,0},{recv_dvi,0},
            {send_oct,0},{send_cnt,0}, {send_max,0},{send_avg,0},{send_pend,0}], 0}, Sockets).

%% @doc 获得本节点的Mnesia所占用的内存
-spec get_total_mnesia_memory() -> integer().
get_total_mnesia_memory() ->
    case mnesia:system_info(is_running) of
        no -> 0;
        _ ->
            lists:foldl(
                fun(T, Acc) ->
                    case mnesia:table_info(T, storage_type) of
                        disc_only_copies ->Acc;
                        _ ->
                            Acc + mnesia:table_info(T, memory) * 8
                    end
                end, 0, mnesia:system_info(local_tables))
    end.

%% @doc 打印本节点的各个Table所占用的内存
-spec get_mnesia_table_memory() -> ok.
get_mnesia_table_memory() ->
    io:format("****** ----------------------- Mnesia Memory ----------------------------~n~n"),
    [begin
         case mnesia:table_info(T, storage_type) of
             disc_only_copies ->
                 ignore;
             _ ->
                 get_mnesia_table_memory(T)
         end
     end || T <- mnesia:system_info(local_tables)],
    io:format("~n****** ----------------------- Node Memory ----------------------------~n~n"),
    ok.

%% @doc 打印本节点的指定Table所占用的内存
-spec get_mnesia_table_memory(atom()) -> ok.
get_mnesia_table_memory(T) ->
    io:format("~40s : ~p ~n", [T, format_memory(mnesia:table_info(T, memory), mb)]),
    ok.

%%%%%%%%%######system relative######%%%%%%%%%
format_memory(M, kb) ->
    M / 1024;
format_memory(M, mb) ->
    M / 1024 / 1024;
format_memory(M, gb) ->
    M / 1024 / 1024 / 1024;
format_memory(M, _) ->
    M.

%% @doc sleep
-spec sleep(integer()) -> true.
sleep(Msec) ->
    receive
    after Msec ->
        true
    end.

%% @doc 获取节点内所有占用内存大于Memory的进程PID列表
-spec get_memory_pids(integer()) -> [pid()].
get_memory_pids(Memory) ->
    PList = erlang:processes(),
    lists:filter(
        fun(T) ->
            case erlang:process_info(T, memory) of
                {_, VV} ->
                    if VV >  Memory -> true;
                        true -> false
                    end;
                _ -> true
            end
        end, PList ).

%% @doc gc（增加时间间隔判断）
-spec gc(integer(), integer()) -> integer() | ignore | undefined.
gc(Now, Interval) ->
    case erlang:get(last_gc_time) of
        undefined ->
            erlang:put(last_gc_time, Now);
        LastTime ->
            case Now - LastTime > Interval of
                true ->
                    erlang:garbage_collect(),
                    erlang:put(last_gc_time, Now);
                false ->
                    ignore
            end
    end.
%% @doc 当前节点内内存占用超过Memory的进程进行gc
-spec gc(integer()) -> ok.
gc(Memory) ->
    lists:foreach(
        fun(PID) ->
            erlang:garbage_collect(PID)
        end, get_memory_pids(Memory)),
    ok.

%% @doc 节点集群内存占用超过Memory的进程进行gc
-spec gc_nodes(integer()) -> ok.
gc_nodes(Memory) ->
    lists:foreach(
        fun(Node) ->
            lists:foreach(
                fun(PID) ->
                    rpc:call(Node, erlang, garbage_collect, [PID])
                end, rpc:call(Node, mlib_sys, get_memory_pids, [Memory]))
        end, [node() | nodes()]),
    ok.

get_process_info_and_large_than_value(InfoName, Value) ->
    PList = erlang:processes(),
    ZList = lists:filter(
        fun(T) ->
            case erlang:process_info(T, InfoName) of
                {InfoName, VV} ->
                    if VV >  Value -> true;
                        true -> false
                    end;
                _ -> true
            end
        end, PList ),
    ZZList = lists:map(
        fun(T) -> {T, erlang:process_info(T, InfoName), erlang:process_info(T, registered_name)}
        end, ZList ),
    [ length(PList), InfoName, Value, length(ZZList), ZZList ].

%% @doc 打印占用内存超过一定值的进程信息
-spec get_memory() -> ok.
get_memory() ->
    io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
        get_process_info_and_large_than_value(memory, 1048576) ),
    ok.
%% @doc 打印占用内存超过一定值的进程信息
-spec get_memory(integer()) -> ok.
get_memory(Value) ->
    io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
        get_process_info_and_large_than_value(memory, Value) ),
    ok.
%% @doc 打印占用heap_size超过一定值的进程信息
-spec get_heap() -> ok.
get_heap() ->
    io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
        get_process_info_and_large_than_value(heap_size, 1048576) ),
    ok.
%% @doc 打印占用heap_size超过一定值的进程信息
-spec get_heap(integer()) -> ok.
get_heap(Value) ->
    io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
        get_process_info_and_large_than_value(heap_size, Value) ),
    ok.

%% @doc 取ETS表内存占用, 降序
-spec get_ets_memory() -> {integer(),[{term(),integer()}]}.
get_ets_memory() ->
    get_ets_memory(byte).
%% @doc 取ETS表内存占用, 降序
-spec get_ets_memory(atom() | integer()) -> {integer(),[{term(),integer()}]}.
get_ets_memory(byte) ->
    get_ets_memory(1);
get_ets_memory(megabyte) ->
    get_ets_memory(1024*1024);
get_ets_memory(gigabyte) ->
    get_ets_memory(1024*1024*1024);
get_ets_memory(Div) ->
    {L,All} = lists:foldl(fun(T,{AccL,AccS}) ->
        TSize = ets:info(T, memory)*8/Div,
        {[{T,TSize}|AccL],TSize+AccS}
        end,{[],0},ets:all()),
    {All,lists:reverse(lists:keysort(2, L))}.

%% @doc 检查ATOM表使用情况
%% @returns {Count,Limit}
-spec atom_info() -> {Count,Limit} | undefined when
            Count :: pos_integer(),
            Limit :: pos_integer().
atom_info() ->
    CD = erlang:system_info(info),
    case binary:match(CD, <<"index_table:atom_tab">>) of
        {P1,_} ->
            <<_:P1/bytes,B1/binary>> = CD,
            case binary:match(B1, <<"\n=">>) of
                {P2,_} ->
                    B2 = binary:part(B1, 0, P2);
                _ ->
                    B2 = B1
            end,
            [_|TL] = string:tokens(binary:bin_to_list(B2), "\n"),
            atom_info(TL, undefined, undefined);
        _ ->
            undefined
    end.
atom_info([("entries: "++Ent)|L], _, Limit) ->
    Entries = lib_tool:to_integer(Ent),
    atom_info(L, Entries, Limit);
atom_info([("limit: "++Lim)|L], Entries, _) ->
    Limit = lib_tool:to_integer(Lim),
    atom_info(L, Entries, Limit);
atom_info([_|L], Entries, Limit) ->
    atom_info(L, Entries, Limit);
atom_info(_, Entries, Limit) when Entries=/=undefined, Limit=/=undefined ->
    {Entries,Limit};
atom_info([], _, _) ->
    undefined.


all_atoms() ->
    atoms_starting_at(0,[]).

atoms_starting_at(N,List) ->
    try atom_by_number(N) of
        Atom ->
            atoms_starting_at(N + 1,[Atom|List])
    catch
        error:badarg ->
            List
    end.

atom_by_number(N) ->
    binary_to_term(<<131,75,N:24>>).
