%%%-------------------------------------------------------------------
%%% @doc
%%%     通用性能测试/分析模块
%%% @end
%%%-------------------------------------------------------------------
-module(lib_profile).

-export([
    tc_begin/0,
    tc_end/0,
    scheduler_wall_time/0
]).

-export([
    spawn_trace/1,
    stop_trace/1
]).

-export([
    eprof_start/1,
    eprof_stop/0,
    fprof_start/1,
    fprof_stop/0,
    percept_start/0,
    percept_stop/0,
    process_top/1
]).

%% @doc 开始性能测试
%% wall_clock 单位是毫秒（ms, millisecond）
-spec tc_begin() -> ok.
tc_begin() ->
    erlang:statistics(wall_clock),
    erlang:statistics(runtime),
    ok.
%% @doc 结束性能测试
-spec tc_end() -> {integer(), integer()}.
tc_end() ->
    {_, Time1} = erlang:statistics(wall_clock),
    {_, Time2} = erlang:statistics(runtime),
    {Time1, Time2}.

%% @doc 调度器的耗时
-spec scheduler_wall_time() -> [{integer(), float()}].
scheduler_wall_time() ->
    erlang:system_flag(scheduler_wall_time, true),
    Ts0 = lists:sort(erlang:statistics(scheduler_wall_time)),
    timer:sleep(5000),
    Ts1 = lists:sort(erlang:statistics(scheduler_wall_time)),
    lists:map(
      fun({{I, A0, T0}, {I, A1, T1}}) ->
              {I, (A1 - A0)/(T1 - T0)}
      end, lists:zip(Ts0,Ts1)).

%% @doc 跟踪某个进程的行为并将其写到日志中
-spec spawn_trace(pid()) -> any().
spawn_trace(PID) ->
    {{Year, Month, Day}, {H, I, _}} = erlang:localtime(),
    File = lists:concat(["/tmp/tracer.", erlang:pid_to_list(PID), Year, Month, Day, H, I, ".log"]),
    io:format("begin trace to file:~p~n", [File]),
    erlang:trace(PID, true, [all]),
    trace_to_file(File).
%% @doc 停止跟踪某进程
-spec stop_trace(pid()) -> integer().
stop_trace(PID) ->
    erlang:trace(PID, false, [all]).
trace_to_file(File) ->
    receive
        Any ->
            file:write_file(File, Any, [append])
    end,
    trace_to_file(File).

%% @doc start eprof
-spec eprof_start([pid()]) -> term().
eprof_start(PIDs) ->
    eprof:start(),
    eprof:profile(PIDs).
%% @doc stop eprof
-spec eprof_stop() -> ok.
eprof_stop() ->
    eprof:stop(),
    ok.

%% @doc start fprof
-spec fprof_start([pid()]) -> term().
fprof_start(PIDs) ->
    fprof:trace([start, {file, "/tmp/fprof"}, {procs, PIDs}]).
%% @doc stop fprof
-spec fprof_stop() -> ok.
fprof_stop() ->
    fprof:stop(),
    ok.

%% @doc start percept
-spec percept_start() -> {ok, port()} | {already_started, port()}.
percept_start() ->
    {{Year, Month, Day}, {Hour, Min, Sec}} = erlang:localtime(),
    File = io_lib:format("/tmp/percept_concurrency_~w~w~w_~w~w~w", [Year, Month, Day, Hour, Min, Sec]),
    percept:profile(File, [procs, ports, exclusive]).
%% @doc stop percept
-spec percept_stop() -> ok.
percept_stop() ->
    percept:stop_profile(),
    ok.

%% @doc start etop
-spec process_top(integer()) -> pid().
process_top(Interval) ->
    spawn(fun() -> etop:start([{output, text}, {interval, Interval}, {lines, 20}, {sort, memory}]) end).

