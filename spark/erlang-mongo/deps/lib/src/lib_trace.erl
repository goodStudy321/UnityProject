%%%-------------------------------------------------------------------
%%% @doc
%%%     代码跟踪：进程/模块/函数/返回值监视
%%% @end
%%%-------------------------------------------------------------------
-module(lib_trace).

-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([
         i/0,
         watch/1,
         watch/2,
         watch/3,
         watch/4,
         watch/5,
         watch_return/2,
         watch_return/3,
         watch_return/4,
         watch_return/5,
         unwatch/0,
         unwatch/1,
         unwatch/2,
         unwatch_all/0
        ]).


-define(DEFAULT_WATCH_MAX_FREQUENCY, 100).  %% watch 默认最大允许的频率
-define(DEFAULT_WATCH_MAX_LINES, 1000).     %% watch 默认最大允许的行数, 0表示不限制


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc mtrace状态
-spec i() -> ok.
i() ->
    case whereis(mtrace) of
        undefined ->
            io:format("mtrace is not running.~n", []);
        TPid ->
            {_,GLPid} = process_info(TPid, group_leader),
            Node = node(GLPid),
            io:format("mtrace running by ~w.~n", [Node])
    end,
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc 监视函数调用
-spec watch(atom() | pid()) -> {ok, pid()} | error.
watch(M) when is_atom(M) ->
    watch(all, M, '_', '_');
watch(PID) when is_pid(PID) orelse PID=:=all orelse PID=:=new orelse PID=:=existing ->
    watch(PID, '_', '_', '_').
%% @doc 监视函数调用
-spec watch(atom() | pid(), function() | atom()) -> {ok, pid()} | error.
watch(M, F) when is_atom(M) ->
    watch(all, M, F, '_');
watch(PID, M) when is_pid(PID) orelse PID=:=all orelse PID=:=new orelse PID=:=existing ->
    watch(PID, M, '_', '_').
%% @doc 监视函数调用
-spec watch(term(), term(), term()) -> {ok, pid()} | error.
watch(M, F, A) when is_atom(M) ->
    watch(all, M, F, A);
watch(PID, M, F) when is_pid(PID) orelse PID=:=all orelse PID=:=new orelse PID=:=existing ->
    watch(PID, M, F, '_').
%% @doc 监视函数调用
-spec watch(term(), term(), term(), term()) -> {ok, pid()} | error.
watch(PID, M, F, A) when is_number(A) orelse A=:='_' ->
    watch(PID, M, F, A, dbg:fun2ms(fun(_) -> message(caller()) end));
watch(PID, M, F, MatchSpec) ->
    watch(PID, M, F, '_', MatchSpec).
%% @doc 监视函数调用
-spec watch(term(), term(), term(), term(), term()) -> {ok, pid()} | error.
watch(PID, M, F, Arity, MatchSpec) ->
    case catch setup(PID) of
        {ok,_} = R ->
            erlang:trace_pattern({M,F,Arity}, MatchSpec, [local]),
            R;
        _ ->
            error
    end.

%% @doc 监视函数调用以及其返回值
-spec watch_return(term(), term()) -> {ok, pid()} | error.
watch_return(M, F) when is_atom(M) ->
    watch(all, M, F, '_', dbg:fun2ms(fun(_) -> message(caller()), return_trace(), exception_trace() end)).
%% @doc 监视函数调用以及其返回值
-spec watch_return(term(), term(), term()) -> {ok, pid()} | error.
watch_return(PID, M, F) when is_pid(PID) orelse PID=:=all orelse PID=:=new orelse PID=:=existing ->
    watch(PID, M, F, '_', dbg:fun2ms(fun(_) -> message(caller()), return_trace(), exception_trace() end));
watch_return(M, F, A) when is_atom(M) ->
    watch(all, M, F, A, dbg:fun2ms(fun(_) -> message(caller()), return_trace(), exception_trace() end)).
%% @doc 监视函数调用以及其返回值
-spec watch_return(term(), term(), term(), term()) -> {ok, pid()} | error.
watch_return(PID, M, F, A) ->
    watch(PID, M, F, A, dbg:fun2ms(fun(_) -> message(caller()), return_trace(), exception_trace() end)).
%% @doc 监视函数调用以及其返回值
-spec watch_return(term(), term(), term(), term(), term()) -> {ok, pid()} | error.
watch_return(PID, M, F, A, S) ->
    watch(PID, M, F, A, S).

setup(PidSpec) ->
    case whereis(mtrace) of
        TPid when is_pid(TPid) ->
            ok;
        _->
            {ok,TPid} = start_tracer(PidSpec, ?DEFAULT_WATCH_MAX_FREQUENCY, ?DEFAULT_WATCH_MAX_LINES)
    end,
    %% 检查当前是否有别的终端在 trace
    {group_leader,GL} = erlang:process_info(self(), group_leader),
    case erlang:process_info(TPid, group_leader) of
        {group_leader,GL} ->
            next;
        {group_leader, OtherGL} ->
            OtherNode = node(OtherGL),
            io:format(OtherGL, "INFO: node ~s is trying to watch.~n", [node(GL)]),
            io:format("ERROR: node ~s is watching.~nYou may use unwatch_all() to stop all current watch.~n", [node(OtherGL)]),
            throw({error,in_use,OtherNode});
        _ ->
            throw({error,no_tracer})
    end,
    {ok,TPid}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc 关闭本终端的watch
-spec unwatch() -> ignore | term().
unwatch() ->
    case catch check_unwatch(false) of
        ok ->
            clear();
        _ ->
            ignore
    end.

%% @doc 强制关闭所有终端(!)的watch
-spec unwatch_all() -> ignore | term().
unwatch_all() ->
    case catch check_unwatch(true) of
        ok ->
            clear();
        _ ->
            ignore
    end.

check_unwatch(IsForced) ->
    %% 检查当前是否有别的终端在 trace
    case whereis(mtrace) of
        TPid when is_pid(TPid) ->
            {group_leader,GL} = erlang:process_info(self(), group_leader),
            case erlang:process_info(TPid, group_leader) of
                {group_leader,OtherGL} when OtherGL=/=GL, IsForced ->
                    io:format(OtherGL, "WARNING: node ~s is stopping all watch.~n", [node(GL)]),
                    io:format("WARNING: stopping watch on node ~s.~n", [node(OtherGL)]),
                    ok;
                {group_leader,OtherGL} when OtherGL=/=GL ->
                    io:format(OtherGL, "INFO: node ~s wants to stop all watch.~n", [node(GL)]),
                    io:format("ERROR: node ~s is watching.~nYou may use unwatch_all() to stop all current watch.~n", [node(OtherGL)]),
                    throw(failed);
                _ ->
                    ignore
            end,
            ok;
        _ ->
            ignore
    end.

%% @doc 关闭指定Mod的watch
-spec unwatch(atom()) -> ignore | term().
unwatch(M) ->
    case catch check_unwatch(true) of
        ok ->
            clear(M);
        _ ->
            ignore
    end.
%% @doc 关闭指定Mod指定Func的watch
-spec unwatch(atom(), function()) -> ignore | term().
unwatch(M, F) ->
    case catch check_unwatch(true) of
        ok ->
            clear(M, F);
        _ ->
            ignore
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear() ->
    case whereis(mtrace) of
        TPid when is_pid(TPid) ->
            erlang:trace(all, false, [all]),
            erlang:trace_pattern({'_','_','_'}, false, [local,meta,call_count,call_time]),
            erlang:trace_pattern({'_','_','_'}, false, []),
            kill(mtrace);
        _ ->
            ignore
    end.

clear(Mod) ->
    erlang:trace_pattern({Mod,'_','_'}, false, [local,meta,call_count,call_time]),
    erlang:trace_pattern({Mod,'_','_'}, false, []),
    ok.

clear(Mod, Func) ->
    erlang:trace_pattern({Mod,Func,'_'}, false, [local,meta,call_count,call_time]),
    erlang:trace_pattern({Mod,Func,'_'}, false, []),
    ok.

kill(Name) ->
    This = self(),
    case whereis(Name) of
        undefined ->
            ok;
        This ->
            ignore;
        Pid ->
            unlink(Pid),
            exit(Pid, kill),
            wait_for_death(Pid)
    end.

wait_for_death(Pid) ->
    case is_process_alive(Pid) of
        true ->
            timer:sleep(10),
            wait_for_death(Pid);
        false ->
            ok
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc tracer for remsh with auto-stop
%% MaxFreq  := max frequency auto stop, line-per-second
%%         MaxLines := max lines auto stop
start_tracer(PidSpec, MaxFreq, MaxLines) ->
    {_,GLPid} = process_info(self(), group_leader),
    TPid = erlang:spawn_opt(fun() -> tracer(GLPid, MaxFreq, MaxLines) end, [link,{priority,max}]),
    case catch erlang:trace(PidSpec, true, [call,{tracer,TPid}]) of
        Int when is_integer(Int) ->
            if  MaxFreq>0, MaxLines>0 -> io:format("starting watch...~nNOTE: auto stop at ~w LPS or ~w lines~n", [MaxFreq,MaxLines]);
                MaxFreq>0 -> io:format("starting watch...~nNOTE: auto stop at ~w LPS", [MaxFreq]);
                MaxLines>0 -> io:format("starting watch...~nNOTE: auto stop at ~w lines~n", [MaxLines]);
                true -> io:format("starting watch...~nWARNING: MaxLPS and MaxLines NOT SET~n", [])
            end,
            ok;
        _ ->
            io:format("ERROR: mtrace failed to start.~n", []),
            kill(mtrace)
    end,
    {ok,TPid}.

tracer(GLPid, MaxFreq, MaxLines) ->
    erlang:process_flag(trap_exit, true),
    true = erlang:register(mtrace, self()),
    link(GLPid),
    catch tracer_loop(GLPid, MaxFreq, MaxLines),
    io:format(GLPid, "watch terminated~n", []),
    ok.

tracer_loop(GLPid, MaxFreq, MaxLines) ->
    receive
        {'EXIT',GLPid,_} ->
            clear(),
            throw(exit);
        stop ->
            clear(),
            throw(exit);
        Msg ->
            trace_msg(GLPid, MaxFreq, MaxLines, Msg)
    end,
    tracer_loop(GLPid, MaxFreq, MaxLines).

trace_msg(GLPid, MaxFreq, MaxLines, Msg) ->
    case catch check_freq_and_lines(os:timestamp(), MaxFreq, MaxLines) of
        ok ->
            io:format(GLPid, "~s~n", [format_trace(Msg)]);
        _ ->
            ignore
    end.

check_freq_and_lines(Now, MaxFreq, MaxLines) ->
    case erlang:get(last_line) of
        {Now,C1} ->
            case C1=:=MaxFreq-1 of
                true when MaxFreq>0 ->
                    io:format("WARNING: max frequency ~w reached, auto stop watch...~n", [MaxFreq]),
                    erlang:put(last_line, {Now,C1+1}),
                    unwatch_all(),
                    throw(stop_freq),
                    ok;
                _ when C1>=MaxFreq, MaxFreq>0 ->
                    throw(stop_freq);
                _ ->
                    ignore
            end;
        _ ->
            C1 = 0,
            ignore
    end,
    erlang:put(last_line, {Now,C1+1}),
    case erlang:get(line_count) of
        C2 when is_number(C2) ->
            case C2=:=MaxLines-1 of
                true when MaxLines>0 ->
                    io:format("WARNING: max lines ~w reached, auto stop watch...~n", [MaxLines]),
                    erlang:put(line_count, C2+1),
                    unwatch_all(),
                    throw(stop_line),
                    ok;
                _ when C2>=MaxLines, MaxLines>0 ->
                    throw(stop_line);
                _ ->
                    ignore
            end;
        _ ->
            C2 = 0
    end,
    erlang:put(line_count, C2+1),
    ok.

format_trace({trace,From,call,{Mod,Func,Args}}) ->
    {{Y,Mo,D},{H,Mi,S}} = erlang:localtime(),
    io_lib:format("===Call=======[~p_~p_~p ~2.. w:~2.. w:~2.. w]==[~w]==[~w:~w/~w] Args=~w",[Y,Mo,D,H,Mi,S,From,Mod,Func,length(Args),Args]);
format_trace({trace,From,call,{Mod,Func,Args},Ext}) ->
    {{Y,Mo,D},{H,Mi,S}} = erlang:localtime(),
    io_lib:format("===Call=======[~p_~p_~p ~2.. w:~2.. w:~2.. w]==[~w]==[~w:~w/~w] Args=~w  @~w",[Y,Mo,D,H,Mi,S,From,Mod,Func,length(Args),Args,Ext]);
format_trace({trace,From,return_from,{Mod,Func,Arity},ReturnValue}) ->
    {{Y,Mo,D},{H,Mi,S}} = erlang:localtime(),
    io_lib:format("===Return=====[~p_~p_~p ~2.. w:~2.. w:~2.. w]==[~w]==[~w:~w/~w] Value=~w",[Y,Mo,D,H,Mi,S,From,Mod,Func,Arity,ReturnValue]);
format_trace({trace,From,exception_from,{Mod,Func,Arity},Exception}) ->
    {{Y,Mo,D},{H,Mi,S}} = erlang:localtime(),
    io_lib:format("===Exception!=[~p_~p_~p ~2.. w:~2.. w:~2.. w]==[~w]==[~w:~w/~w] Value=~w",[Y,Mo,D,H,Mi,S,From,Mod,Func,Arity,Exception]);
format_trace(M) ->
    io_lib:format("~w",[M]).


