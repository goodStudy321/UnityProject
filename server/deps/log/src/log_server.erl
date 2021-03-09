%%%-------------------------------------------------------------------
%%% @doc 用于写系统运行时日志
%%%
%%% @end
%%% Created : 28 Jun 2010 by QingliangCn <>
%%%-------------------------------------------------------------------
-module(log_server).

-behaviour(gen_server).

%% API
-export([
    start/0,
    start_link/0
]).

-export([
    notify/1,
    set_callback/2,
    get_callback/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).


-record(state, {fd,criticalfd,errorfd}).

%%--------------------------------------------------------------------
%% 宏定义
%%--------------------------------------------------------------------

%% 堵塞消息的上限值
-define(MAX_PENDING_MSG, 100000).
-define(CRITICAL_LEVEL, 1).
-define(ERROR_LEVEL, 2).
-define(WARNING_LEVEL, 3).
start() ->
    {ok, _} = supervisor:start_child(log_sup, {?MODULE, {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, [?MODULE]}).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec notify(Event) -> {event, Event} | ignore when
      Event :: {Type, pid(), Chars},
      Type :: critical | error | warning | emulator | info | error_report | info_report | info_msg,
      Chars :: {pid(), string(), list(), term(), term()} | {pid(), term(), term()}.
%% @doc 写日志
notify(Event) ->
    case erlang:whereis(?MODULE) of
        undefined ->
            %%可能需要打印出来？
            ignore;
        PID ->
            erlang:send(PID,{event,Event})
    end.
-spec set_callback(LogLevel, MFAs) -> {set_callback, {LogLevel, MFAs}} when
      LogLevel :: integer(),
      MFAs :: [{atom(), atom(), [term()]}].
%% @doc 设置1-3级别的回调执行，会在每次写日志时执行回调函数
set_callback(LogLevel,MFAs) ->
    erlang:send(?MODULE,{set_callback, {LogLevel,MFAs}}).

-spec get_callback() -> [{pos_integer(), false | [{atom(), atom(), [term()]}]}].
%% @doc 获取所有级别日志的回调
get_callback() ->
    [begin {LogLevel, lib_sys:d(?MODULE,{cbfun,LogLevel})} end || LogLevel <-[?CRITICAL_LEVEL,?ERROR_LEVEL,?WARNING_LEVEL]].

%%%===================================================================
init([]) ->
    FileBaseName = log_misc:get_log_basename(),
    BaseDir  = log_misc:get_log_dir(),
    IsMf = true,
    set_params({BaseDir, FileBaseName, IsMf}),
    {File,CriticalFile,ErrorFile} = log_misc:get_log_file(BaseDir,FileBaseName, IsMf),
    trucate_file_at_next_day(),
    {ok, #state{fd=File,criticalfd=CriticalFile,errorfd=ErrorFile}}.


%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info({set_callback, {LogLevel,MFAs}}, State) ->
    set_cbfun(LogLevel,MFAs),
    {noreply, State};
handle_info({event, Event}, State) ->
    {_, Len} = erlang:process_info(erlang:self(), message_queue_len),
    case Len > ?MAX_PENDING_MSG of
        true ->
            do_notify_abnormal(Len),
            do_flush_message(Len);
        false ->
            write_event(State,{erlang:localtime(), Event})
    end,
    {noreply, State};
handle_info(truncate_file, State) ->
    {BaseDir, FileBaseName, IsMf} = get_params(),
    {File,CriticalFile,ErrorFile} = log_misc:get_log_file(BaseDir,FileBaseName, IsMf),
    try
        trucate_file_at_next_day()
    catch
        Type:Error -> io:format("log_server trucate_file_at_next_day error (~p): ~p~n", [Type, Error])
    end,
    {noreply, State#state{fd=File,criticalfd=CriticalFile,errorfd=ErrorFile}};
handle_info(Info, State) ->
    log_entry:warning_msg( node(), ?MODULE,?LINE,"~tunknown msg:~w", [Info]),
    {noreply, State}.


%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% Internal Functions
%%--------------------------------------------------------------------
do_flush_message(0) ->
    ok;
do_flush_message(N) ->
    receive 
        _R ->
            ok
    after 0 ->
            ok
    end,
    do_flush_message(N-1).

do_notify_abnormal(_Len) ->
    %log_entry:error_msg( node(), ?MODULE,?LINE,"log_server service queue too large :~p~n", [Len]),
    %%这里应该发邮件活其他.
    ok.

do_write(Fd, Time, Type, HeaderFmt, HeaderArgs, Format, Args) ->
    {{Y,Mo,D},{H,Mi,S}} = Time,
    Head = io_lib:format("~s==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ==="++HeaderFmt,
        [Type,Y, Mo, D, H, Mi, S] ++ HeaderArgs),
    file:write_file(Fd, Head, [append, delayed_write]),
    try
        M = unicode:characters_to_binary(io_lib:format(Format, Args)),
        file:write_file(Fd, M, [append, delayed_write]),
        ok
    catch E:Error ->
        io:format("log error ~p ~p ~p ~p", [E, Error, Format, Args])
    end,
    file:write_file(Fd, ["\n"], [append, delayed_write]),
    ok.

% Copied from erlang_logger_file_h.erl
write_event(State, {Time, {critical, _GL, {_Pid,HeaderFmt,HeaderArgs,Format,Args}}}) ->
    [L] = io_lib:format("~s", ["CRITI: "]),
    do_write(State#state.fd, Time, L, HeaderFmt, HeaderArgs, Format, Args),
    do_write(State#state.criticalfd, Time, L, HeaderFmt, HeaderArgs, Format, Args),
    [begin catch erlang:apply(M,F,A) end || {M,F,A} <- get_cbfun(?CRITICAL_LEVEL) ],
    ok;
write_event(State, {Time, {error, _GL, {_Pid,HeaderFmt,HeaderArgs,Format,Args}}}) ->
    [L] = io_lib:format("~s", ["ERROR: "]),
    do_write(State#state.fd, Time, L, HeaderFmt, HeaderArgs, Format, Args),
    do_write(State#state.errorfd, Time, L, HeaderFmt, HeaderArgs, Format, Args),
    [begin catch erlang:apply(M,F,A) end || {M,F,A} <- get_cbfun(?ERROR_LEVEL) ],
    ok;
write_event(State, {Time, {warning, _GL, {_Pid,HeaderFmt,HeaderArgs,Format,Args}}}) ->
    [L] = io_lib:format("~s", ["WARNI: "]),
    do_write(State#state.fd, Time, L, HeaderFmt, HeaderArgs, Format, Args),
    [begin catch erlang:apply(M,F,A) end || {M,F,A} <- get_cbfun(?WARNING_LEVEL) ],
    ok;

write_event(State, {Time, {emulator, _GL, Chars}}) ->
    T = write_time(Time),
    case catch io_lib:format(Chars, []) of
	S when is_list(S) ->
	    file:write_file(State#state.fd, io_lib:format(T ++ S, []), [append, delayed_write]);
	_ ->
	    file:write_file(State#state.fd, io_lib:format(T ++ "EMULATOR: ~p ~n", [Chars]), [append, delayed_write])
    end;


write_event(State, {Time, {info, _GL, {Pid, Info, _}}}) ->
    T = write_time(Time),
    file:write_file(State#state.fd, io_lib:format(T ++ add_node("~p~n",Pid), [Info]), [append, delayed_write]);


write_event(State, {Time, {error_report, _GL, {Pid, std_error, Rep}}}) ->
    T = write_time(Time),
    S = format_report(Rep),
    file:write_file(State#state.fd, io_lib:format(T ++ S ++ add_node("", Pid), []), [append, delayed_write]),
    file:write_file(State#state.errorfd, io_lib:format(T ++ S ++ add_node("", Pid), []), [append, delayed_write]);



write_event(State, {Time, {info_report, _GL, {Pid, std_info, Rep}}}) ->
    T = write_time(Time, "INFO_REPORT"),
    S = format_report(Rep),
    file:write_file(State#state.fd, io_lib:format(T ++ S ++ add_node("", Pid), []), [append, delayed_write]);


write_event(State, {Time, {info_msg, _GL, {_Pid,HeaderFmt,HeaderArgs,Format,Args}}}) ->
    [L] = io_lib:format("~s", ["INFO_MSG"]),
    do_write(State#state.fd, Time, L, HeaderFmt, HeaderArgs, Format, Args);

write_event(State, {Time, {info_msg, _GL, {Pid, Format, Args}}}) ->
    T = write_time(Time, "INFO_MSG"),
    S = io_lib:format(Format, Args),
    Data = [T, "\n", S, add_node("", Pid)],
    file:write_file(State#state.fd, Data, [append, delayed_write]);

write_event(State, {Time, {error, _GL, {Pid, Format, Args}}}) ->
    T = write_time(Time, "ERROR"),
    S = io_lib:format(Format, Args),
    Data = [T, "\n", S, add_node("", Pid)],
    file:write_file(State#state.fd, Data, [append, delayed_write]),
    file:write_file(State#state.errorfd, Data, [append, delayed_write]);

write_event(_State, {_Time, {info_report, _GL, {_Pid, progress, _Term}}}) ->
%%    T = write_time(Time, "INFO REPORT"),
%%    Data = [T, "\n", io_lib:format("~p", [Term]), add_node("", Pid)],
%%    file:write_file(State#state.fd, Data, [append, delayed_write]);
    ignore;

write_event(State, {Time, {debug, _GL, {_Pid,HeaderFmt,HeaderArgs,Format,Args}}}) ->
    [L] = io_lib:format("~s", ["DEBUG"]),
    do_write(State#state.fd, Time, L, HeaderFmt, HeaderArgs, Format, Args);

write_event(State, Msg) ->
    S = io_lib:format("log receive unknown msg ~p~n", [Msg]),
    file:write_file(State#state.fd, S, [append, delayed_write]),
    file:write_file(State#state.errorfd, S, [append, delayed_write]).

format_report(Rep) when is_list(Rep) ->
    case string_p(Rep) of
	true ->
	    io_lib:format("~s~n",[Rep]);
	_ ->
	    format_rep(Rep)
    end;
format_report(Rep) ->
    io_lib:format("~p~n",[Rep]).

format_rep([{Tag,Data}|Rep]) ->
    io_lib:format("    ~p: ~p~n",[Tag,Data]) ++ format_rep(Rep);


format_rep([Other|Rep]) ->
    io_lib:format("    ~p~n",[Other]) ++ format_rep(Rep);


format_rep(_) ->
    [].

add_node(X, Pid) when node(Pid) /= node() ->
    lists:concat([X,"** at node ",node(Pid)," **~n"]);
add_node(X, _) ->
    X.

string_p([]) ->
    false;
string_p(Term) ->
    string_p1(Term).

string_p1([H|T]) when is_integer(H), H >= $\s, H < 255 ->
    string_p1(T);
string_p1([$\n|T]) -> string_p1(T);
string_p1([$\r|T]) -> string_p1(T);
string_p1([$\t|T]) -> string_p1(T);
string_p1([$\v|T]) -> string_p1(T);
string_p1([$\b|T]) -> string_p1(T);
string_p1([$\f|T]) -> string_p1(T);
string_p1([$\e|T]) -> string_p1(T);
string_p1([H|T]) when is_list(H) ->
    case string_p1(H) of
	true -> string_p1(T);
	_    -> false
    end;
string_p1([]) -> true;
string_p1(_) ->  false.

write_time(Time) -> write_time(Time, "ERROR REPORT").

write_time({{Y,Mo,D},{H,Mi,S}}, Type) ->
    io_lib:format("~n=~s==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
		  [Type, Y, Mo, D, H, Mi, S]).

%% @doc 通知服务器在下一个整点刷新日志文件
trucate_file_at_next_day() ->
    {{_, _, _Day}, {H, I, S}} = erlang:localtime(),
    Time = (23-H) * 3600 + ((59 - I) * 60 + (59 - S) + 2) * 1000,
    erlang:send_after(Time, self(), truncate_file).


%%
set_params({BaseDir, FileBaseName, IsMf}) ->
    erlang:put(params, {BaseDir, FileBaseName, IsMf}),
    ok.
get_params() ->
    erlang:get(params).
set_cbfun(LogLevel,MFAs) ->
    erlang:put({cbfun,LogLevel},MFAs).
get_cbfun(LogLevel) ->
    case erlang:get({cbfun,LogLevel}) of
        [_|_]=MFAs ->MFAs;
        _ ->[]
    end.
