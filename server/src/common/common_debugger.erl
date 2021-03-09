%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 五月 2017 16:46
%%%-------------------------------------------------------------------
-module(common_debugger).
-include("proto/gateway.hrl").

-include("global.hrl").

%% 只有工具类中才允许这么用
-compile(export_all).

%% API
-export([
    dbg_start/1,
    start_concurrency_profile/0,
    stop_concurrency_profile/0,
    get_receiver_fun/0,
    get_all_map_node/0,
    get_all_map_pid/0,
    get_all_role/0,
    get_dyn_pid_memory/0,
    get_role_socket_stat/1,
    start_client_trace/1,
    start_client_trace/3,
    start_process_trace/3,
    do_client_tracer/2,

    i/0,
    print_dict/1,

    watch/2,
    watch/1,
    unwatch/2,
    unwatch/1,
    unwatch/0,
    try_tcpdump/3
]).

-export([pids/0]).


-compile({no_auto_import,[process_info/1]}).
-compile({no_auto_import,[process_info/2]}).

%% @doc watch all calls to Module:Func
watch(M, F) ->
    R = ensure_watch(),
    dbg:tpl(M, F, []),
    R.
%% @doc watch all calls with Module
watch(M) ->
    R = ensure_watch(),
    dbg:tpl(M, []),
    R.

ensure_watch() ->
    case whereis(dbg) of
        undefined->
            {ok,DBG,_} = smart_dbg_tracer(),
            dbg:p(all,[call]),
            DBG;
        DBG ->
            ok
    end,
    {ok,DBG}.



%% @doc cancel watch
unwatch() ->
    dbg:stop_clear().
unwatch(M) ->
    dbg:ctpl(M).
unwatch(M, F) ->
    dbg:ctpl(M, F).

dbg_start(Module) ->
    dbg:tracer(),
    dbg:p(all, [call]),
    dbg:tpl(Module, [{'_', [], [{return_trace}]}]).

%% @doc dbg tracer for remsh with auto-stop
smart_dbg_tracer() ->
    dbg:stop_clear(),
    {_,GL_PID} = lib_sys:info(self(),group_leader),
    {ok,TPid} = dbg:tracer(process,{fun(M, T) ->
        Now = time_tool:now(),
        case Now-T>1 of
            true ->
                io:format("------------------------------------------------~n->  ~s~n", [format_trace(M)]);
            false ->
                io:format("->  ~s~n", [format_trace(M)])
        end,
        Now
                                    end,0}),
    CFun = fun(L) ->
        erlang:process_flag(trap_exit, true),
        link(GL_PID),
        link(TPid),
        receive
            {'EXIT',GL_PID,_} ->
                dbg:stop_clear();
            {'EXIT',TPid,Reason} ->
                exit(Reason);
            _ ->
                ignore
        end,
        L(L)
           end,
    ControllerPid = spawn(fun() -> CFun(CFun) end),
    {ok,TPid,ControllerPid}.


format_trace({trace,From,call,{Mod,Func,Args}}) ->
    io_lib:format("~w  ~w:~w  ~w",[From,Mod,Func,Args]);
format_trace(M) ->
    io_lib:format("~w",[M]).


%% @doc 系统基本信息
i() ->
    lib_sys:i(),

    Nodes = [node() | nodes()],

    io:format("****** ----------------------- Main Server Memory ----------------------------~n~n"),

    [begin
         io:format("~40s ~s : ~p MB ~n", ["Node Role Process Memory", Node, rpc:call(Node, common_debugger,get_all_role_process_memory, [])])
     end || Node <- Nodes],
    [begin
         io:format("~40s ~s : ~p MB ~n", ["Node Map Process Memory", Node, rpc:call(Node, common_debugger,get_all_map_process_memory, [])])
     end || Node <- Nodes],
    io:format("~n"),
    io:format("****** ----------------------- Main Server Memory ----------------------------~n~n"),

    ok.



get_all_map_process_memory() ->
    get_memory_by_type("map_").

%% 获得所有角色进程占用的内存
get_all_role_process_memory() ->
    get_memory_by_type("role_").

get_memory_by_type(Prefix) ->
    format_memory(
        lists:foldl(
            fun(Name, Acc) ->
                case string:str(lib_tool:to_list(Name), Prefix) > 0 of
                    true ->
                        case erlang:whereis(Name) of
                            undefined ->
                                Acc;
                            PID ->
                                {memory, M} = erlang:process_info(PID, memory),
                                M+Acc
                        end;
                    false ->
                        Acc
                end
            end, 0, erlang:registered()), mb).

format_memory(M, kb) ->
    M / 1024;
format_memory(M, mb) ->
    M / 1024 / 1024;
format_memory(M, gb) ->
    M / 1024 / 1024 / 1024;
format_memory(M, _) ->
    M.

get_all_role() ->
    lists:foldl(
        fun(Name, Acc) ->
            case string:tokens(lib_tool:to_list(Name), "role_") of
                [Value|_] ->
                    case catch lib_tool:to_integer(Value) of
                        RoleID when erlang:is_integer(RoleID) ->
                            [RoleID|Acc];
                        _ ->
                            Acc
                    end;
                _ ->
                    Acc
            end
        end, [], erlang:registered()).

process_kick(MsgLen) ->
    lists:foldl(fun(P,Acc) ->
        case erlang:process_info(P, registered_name) of
            {registered_name,PName}  ->
                PNameStr = atom_to_list(PName),
                case catch list_to_integer(PNameStr) of
                    PNameInt when erlang:is_integer(PNameInt) andalso  PNameInt  > 1000000000 ->
                        {message_queue_len,Len} = erlang:process_info(P, message_queue_len),
                        case   Len >= MsgLen of
                            true ->
                                RoleID =  (PNameInt div 10) * 10,
                                role_misc:kick_role(RoleID,?ERROR_SYSTEM_ERROR_006),
                                io:format("RoleID:~-8w PName:~p, Len:~p~n",[RoleID,PName,Len]),
                                [RoleID|Acc];
                            _ ->  Acc
                        end;
                    _ ->Acc
                end;
            _ ->Acc
        end end ,[], erlang:processes()).


get_role_socket_stat(RoleID) ->
    PName = lib_tool:list_to_atom(lib_tool:to_list(RoleID)),
    case erlang:whereis(PName) of
        undefined ->
            undefined;
        PID ->
            {links, [Port]} = erlang:process_info(PID, links),
            inet:getstat(Port)
    end.


%% 获取一个尾递归无限接受消息的函数
get_receiver_fun() ->
    fun() -> do_receive() end.

do_receive() ->
    receive
        Any -> io:format("~p~n", [Any])
    end,
    do_receive().


start_client_trace(RoleID) ->
    start_client_trace(RoleID, undefined, 100).

start_client_trace(RoleID, Filter, Num) ->
    start_process_trace(RoleID, Filter, Num).

start_process_trace(RoleID, Filter, Num) when Num>0 ->
    GatewayPName = gateway_misc:get_role_gpname(RoleID),
    case erlang:whereis(GatewayPName) of
        undefined ->
            case Num rem 10 of
                0 ->
                     io:format(". ");
                _ ->
                    ignore
            end,
            timer:sleep(100),
            start_process_trace(RoleID, Filter, Num-1);
        PID ->
            catch start_process_trace2(RoleID, PID, GatewayPName, Filter)
    end;
start_process_trace(RoleID, Filter,_Num) ->
    io:format("please login in time:~w, Filter:~w",[RoleID, Filter]).

start_process_trace2(RoleID, PID, GatewayPName, Filter) ->
    TracerName = tracer_name(GatewayPName),
    ?IF( erlang:node(PID) =:= erlang:node(), ok, erlang:throw({error, bad_node})),
    case whereis(TracerName) of
        undefined -> ok;
        OldPid ->
            case erlang:is_process_alive(OldPid) of
                true ->
                    erlang:unregister(TracerName),
                    OldPid ! stop;
                _ ->
                    ok
            end
    end,
    Tracer =
        erlang:spawn(
            fun() ->
                erlang:monitor(process, PID),
                process_flag(trap_exit, true),
                erlang:register(TracerName, self()),
                do_client_tracer(RoleID, Filter)
            end),
    erlang:trace(PID, false, ['receive']),
    erlang:trace(PID, true, ['receive', {tracer, Tracer}]),
    {ok, PID}.

tracer_name(ProcessName) ->
    lib_tool:list_to_atom(lists:concat(["tracer_", lib_tool:to_list(ProcessName)])).


do_client_tracer(RoleID, Filter) ->
    receive
        {trace, _Pid, 'receive', {inet_async, _ClientSocket, _Ref, {ok, Data}}} ->
            {Record, _} = gateway_packet:unpack(Data),
            print_record(RoleID, Record, Filter),
            do_client_tracer(RoleID, Filter);
        {trace, _Pid, 'receive', {message, Record}} ->
            print_record(RoleID, Record, Filter),
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive',{inet_reply,  _,  _ }} ->
            ignore,
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive',{loop_sec,  _ }} ->
            ignore,
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive',timeout} ->
            ignore,
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive',{binary, Bin}} ->
            print_record(RoleID, gateway_packet:robot_unpack(Bin), Filter),
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive',{binary_limited, _RecordName, Bin}} ->
            print_record(RoleID, gateway_packet:robot_unpack(Bin), Filter),
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive', {binary_filter, Condition, Bin}}  ->
            #r_role_attr{level = RoleLevel} = common_role_data:get_role_attr(RoleID),
            case gateway_misc:is_fit_condition2(Condition, RoleID, RoleLevel,undefined) of
                true ->
                    ok;
                _ ->
                    io:format("broadcast_filter:")
            end,
            catch print_record(RoleID, gateway_packet:robot_unpack(Bin), Filter),
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive', {binary_passive,Bin}}  ->
            catch print_record(RoleID, gateway_packet:robot_unpack(Bin), Filter),
            do_client_tracer(RoleID, Filter);
        {trace,_Pid,'receive', _Any}  ->
            do_client_tracer(RoleID, Filter);
        stop ->
            case get({trace_roleid,RoleID}) of
                undefined ->ignore;
                List ->
                    case List of
                        [_ | _] ->
                            TraceFile =lists:concat(["/data/logs/trace_roleid_",RoleID,".log"]),
                            file:write_file(TraceFile, lists:reverse(List), [append]);
                        _ ->ignore
                    end,
                    erase({trace_roleid,RoleID})
            end,
            stop;
        {'DOWN', _, process, _, _} ->
            case get({trace_roleid,RoleID}) of
                undefined ->ignore;
                List ->
                    case List of
                        [_ | _] ->
                            TraceFile =lists:concat(["/data/logs/trace_roleid_",RoleID,".log"]),
                            file:write_file(TraceFile, lists:reverse(List), [append]);
                        _ ->ignore
                    end,
                    erase({trace_roleid,RoleID})
            end,
            start_process_trace(RoleID, Filter, 200);
        _Any ->
            io:format("unknow:::~w~n",[_Any]),
            do_client_tracer(RoleID, Filter)
    end.

stop_client_trace(RoleID) when is_number(RoleID) ->
    case erlang:whereis(gateway_misc:get_role_gpname(RoleID)) of
        GPid when is_pid(GPid) ->
            erlang:trace(GPid, false, [all]);
        _ ->
            ignore
    end,
    TracerName = tracer_name(RoleID),
    case erlang:whereis(TracerName) of
        undefined ->
            ignore;
        Pid ->
            erlang:unregister(TracerName),
            Pid ! stop
    end.

print_record(RoleID, Data, Filter) ->
    RecName = (catch erlang:element(1, Data)),
    NowMs = time_tool:now_ms(),
    Sec = NowMs div 1000,
    Ms = NowMs rem 1000,
    TimeStr = time_tool:timestamp_to_datetime_str(Sec),
    Data1 = lists:flatten(io_lib:format("===Role=[~w]==Bytes=[~5.. w]==[~s:~w] Rec=~w\n", [RoleID, byte_size(term_to_binary(Data)), TimeStr, Ms, Data])),
    case lib_config:find(common, trace_roleids) of
        [RoleIDs] -> next;
        _ -> RoleIDs = []
    end,
    case lib_config:find(common, trace_role_filter) of
        [FilterMsgs] ->
            next;
        _ ->
            FilterMsgs = []
    end,
    TraceFlag = lists:member(RoleID,RoleIDs),
    FilterFlag = lists:member(RecName, FilterMsgs),
    case is_filter(Filter, RecName) of
        false ->
            case TraceFlag of
                true ->
                    case FilterFlag of
                        false ->
                            case get({trace_roleid,RoleID}) of
                                undefined ->
%%                                     ?INFO_MSG("追踪玩家信息3RoleID:~w",[RoleID]),
                                    put({trace_roleid,RoleID},[Data1]);
                                List ->
%%                                     ?INFO_MSG("追踪玩家信息4RoleID:~w",[RoleID]),
                                    List1 = [Data1|List],
                                    case erlang:length(List1) > 25 of
                                        true ->
%%                                             ?INFO_MSG("追踪玩家信息RoleID:~w",[RoleID]),
                                            TraceFile =lists:concat(["/data/logs/trace_roleid_",RoleID,".log"]),
                                            file:write_file(TraceFile, lists:reverse(List1), [append]),
                                            put({trace_roleid,RoleID},[]);
                                        _ ->
%%                                             ?INFO_MSG("追踪玩家信息6RoleID:~w",[RoleID]),
                                            put({trace_roleid,RoleID},List1)
                                    end
                            end;
                        _ ->
                            ignore
                    end,
                    ok;
                _ ->
                    io:format("time=~s:~w~nRec=~p\n", [TimeStr, Ms, Data])
            end;
        _ ->
            ignore
    end.

is_filter(Filter,RecName) ->
    if
        Filter =:= undefined ->
            false;
        RecName =:= m_system_hb_tos ->
            case Filter(RecName) of
                true ->
                    false;
                _ ->
                    true
            end;
        true ->
            case Filter(RecName) of
                true ->
                    false;
                _ ->
                    true
            end
    end.



start_concurrency_profile() ->
    {{Year, Month, Day}, {Hour, Min, Sec}} = erlang:localtime(),
    GameCode = common_config:get_game_code(),
    File = io_lib:format("/data/logs/~s_concurrency_~w~w~w_~w~w~w", [GameCode,Year, Month, Day, Hour, Min, Sec]),
    percept:profile(File, [procs, ports, exclusive]).

stop_concurrency_profile() ->
    percept:stop_profile().

%% @doc 获得所有我们自定义的PID列表
pids() ->
    lists:zf(
        fun(PID) ->
            ProcessInfo =  lib_sys:info(PID) ,
            CurrentFunction = current_function(ProcessInfo),
            InitialCall = initial_call(ProcessInfo),
            RegisteredName = registered_name(ProcessInfo),
            Ancestor = ancestor(ProcessInfo),
            filter_pid(PID, CurrentFunction, InitialCall, RegisteredName, Ancestor)
        end,
        processes()).

current_function(ProcessInfo) ->
    {value, {_, {CurrentFunction, _,_}}} =
        lists:keysearch(current_function, 1, ProcessInfo),
    atom_to_list(CurrentFunction).

initial_call(ProcessInfo) ->
    {value, {_, {InitialCall, _,_}}} =
        lists:keysearch(initial_call, 1, ProcessInfo),
    atom_to_list(InitialCall).

registered_name(ProcessInfo) ->
    case lists:keysearch(registered_name, 1, ProcessInfo) of
        {value, {_, Name}} when is_atom(Name) -> atom_to_list(Name);
        _ -> ""
    end.

ancestor(ProcessInfo) ->
    {value, {_, Dictionary}} = lists:keysearch(dictionary, 1, ProcessInfo),
    case lists:keysearch('$ancestors', 1, Dictionary) of
        {value, {_, [Ancestor|_T]}} when is_atom(Ancestor) ->
            atom_to_list(Ancestor);
        _ ->
            ""
    end.

filter_pid(PID, "map" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "db" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "gateway" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "world" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "chat" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "mgeeb" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "role" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "common_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "mod_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "hook_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "copy_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, "mnesia" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, PID};

filter_pid(PID, _CurrentFunction, "map" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "copy" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "mgeeb" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "chat" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "db" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "world" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "gateway" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "common_" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "mod_" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "hook_" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "b" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, "mnesia" ++ _, _RegisteredName, _Ancestor) ->
    {true, PID};


filter_pid(PID, _CurrentFunction, _InitialCall, "map"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "mgeea"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "mgeeb"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "chat"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "mgeed"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "world"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "gateway"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "common_"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "mod_"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "hook_"++_, _Ancestor) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, "mnesia"++_, _Ancestor) ->
    {true, PID};


filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "map"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "mgeea"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "mgeeb"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "chat"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "db"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "world"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "gateway"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "mod_"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "hook_"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "common_"++_) ->
    {true, PID};
filter_pid(PID, _CurrentFunction, _InitialCall, _RegisteredName, "mnesia"++_) ->
    {true, PID};


filter_pid(_PID, _CurrentFunction, _InitialCall, _RegisteredName, _Ancestor) ->
    false.

get_all_map_node() ->
    lists:foldl(
        fun(Node,AL) ->
            case erlang:atom_to_list(Node) of
                "map" ++ _ ->
                    [Node|AL];
                _ ->
                    AL
            end
        end,[],[node()|nodes()]).

get_all_map_pid() ->
    List = lists:map(fun(RegisteredName) -> lib_tool:to_list(RegisteredName) end, erlang:registered()),
    lists:foldl(
        fun("mgee_map" ++ _ = Name, AL) ->
            [Name|AL];
            ("map_" ++ _ = Name, AL) ->
                [Name|AL];
            (_, AL) ->
                AL
        end,[], List).

get_dyn_pid_memory() ->
    spawn(fun() -> etop:start([{output, text}, {interval, 1}, {lines, 20}, {sort, memory}]) end).

print_dict(PName) ->
    FileName =  lists:concat([common_config:get_mge_root(), lib_tool:to_list(PName),"dictionary", ".txt"]),
    file:write_file(FileName, io_lib:format("~p", [erlang:process_info(whereis(PName),dictionary)]), [write]).


pid(RegName) when erlang:is_list(RegName) ->
    pname:pid(RegName).


g_proc_info(RoleID) ->
    PName = gateway_misc:get_role_gpname(RoleID),
    case erlang:whereis(PName) of
        undefined ->
            io:format("Role gateway process down! role offline",[]);
        Pid ->
            DictVal = lib_sys:d(Pid),
            List = [ip, g, socket, state, account_name,
                role_id, fcm, online_time,
                last_check_biansu_time,
                last_hb_time, map_pname, pack_num],
            Fun = fun(Key) ->
                case lists:keyfind(Key, 1, DictVal) of
                    false->
                        {Key, undefined};
                    Val->
                        Val
                end
                  end,
            Info = [Fun(K)||K<-List],
            io:format("role tcp_client Info :~n~p\n",[Info])
    end.

try_tcpdump(AccountName, Socket, Time) when AccountName=:=<<"">> ->
    erlang:spawn( ?MODULE, try_tcpdump_start, [AccountName, Socket, Time]);
try_tcpdump(_AccountName, _GatewayPName, _Socket) ->
    undefined.


try_tcpdump_start(AccountName, Socket, _Time) ->
    case Socket of
        {{A,B,C,D}, Port} -> ok;
        _ -> {ok, {{A,B,C,D}, Port}} = inet:peername(Socket)
    end,
    STR = fun(T)-> lib_tool:to_list(T) end,
    IPStrPort = "host " ++ STR(A) ++ "." ++ STR(B) ++ "." ++ STR(C) ++ "." ++ STR(D) ++ " and port " ++ STR(Port),
    TcpDumpStr = "tcpdump -vv -x -nn -s0 -U -w /tmp/dump_" ++ lib_tool:to_list(AccountName) ++ ".txt  ",
    Command = TcpDumpStr ++ IPStrPort,
    TmpP = erlang:spawn(fun()->  os:cmd(Command) end),
    ?ERROR_MSG("~w run:~s~n", [TmpP, Command]),
    PSCommand = "ps uax | grep \'tcpdump\'",
    receive
    after 1000 ->
        ?ERROR_MSG("~n=========================tcpdump=============================~n~s~n", [catch os:cmd(PSCommand)])
    end.
%% 算了，懒人直接打印出来手动停止，有空再改
%% 超过一定时间后kill掉它
%% receive
%%     _Any ->
%%         try_tcpdump_stop();
%%     after Time*1000 ->
%%         try_tcpdump_stop()
%% end.

%% 把"#Port<0.iiiii>" 或者 iiiii转成port，技术调试用的
to_port(Port) when erlang:is_port(Port) ->
    Port;
to_port(PortID) when erlang:is_integer(PortID) ->
    <<131,98,A,B,C,D>> = erlang:term_to_binary(PortID),
    <<131,Other/binary>> = erlang:term_to_binary(node()),
    FinalBin = << <<131,102>>/binary, Other/binary, <<A,B,C,D>>/binary, <<2>>/binary >>,
    Socket = erlang:binary_to_term(FinalBin),
    Socket;
to_port(List0) ->
    List = lib_tool:to_list(List0),
        "#Port<0." ++ I = List, %% #Port<0.xxxxx>
    I2 = string:strip(I, right, $>),
    Index = lib_tool:to_integer(I2),
    to_port(Index).
