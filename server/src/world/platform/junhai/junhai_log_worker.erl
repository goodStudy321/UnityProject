%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 九月 2017 16:51
%%%-------------------------------------------------------------------
-module(junhai_log_worker).
-author("laijichang").
-include("global.hrl").
-include("platform.hrl").

%% API
-export([
    start_link/2
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([
    init_logs/2,
    log/2,
    add_fail_logs/2
]).

start_link(Index, PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [Index], []).

init_logs(PName, Logs) ->
    pname_server:send(PName, {init_logs, Logs}).

log(PName, Log) ->
    pname_server:send(PName, {log, Log}).

add_fail_logs(PID, Logs) ->
    erlang:send(PID, {add_fail_logs, Logs}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([Index]) ->
    erlang:process_flag(trap_exit, true),
    erlang:send_after(lib_tool:random(0, ?JUNHAI_LOG_LOOP_TIME), erlang:self(), loop),
    ParentPID = erlang:self(),
    [begin
         PName = lib_tool:to_atom(lists:concat(["junhai_log_sub_worker_", Index, "_", SubIndex])),
         {ok, PID} = junhai_log_sub_worker:start_link(ParentPID, PName),
         set_sub_worker_pid(SubIndex, PID),
         ok
     end || SubIndex <- lists:seq(1, ?JUNHAI_SUB_WORKER_NUM)],
    set_log_sub_index(1),
    set_loop_logs([]),
    set_fail_list([]),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({init_logs, Logs}) ->
    add_loop_log(Logs);
do_handle({log, Log}) ->
    do_log(Log);
do_handle({add_fail_logs, Logs}) ->
    do_fail_logs(Logs);
do_handle(loop) ->
    erlang:send_after(?JUNHAI_LOG_LOOP_TIME, erlang:self(), loop),
    do_loop();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("unknow Info:~w", [Info]).

do_log(Log) ->
    ets:insert(?DB_JUNHAI_LOG_P, Log),
    add_loop_log([Log]).

do_loop() ->
    LoopLogs = get_loop_logs(),
    {LoopLogs2, Remain} = lib_tool:split(?JUNHAI_LOG_NUM, LoopLogs),
    junhai_log_sub_worker:send_req(get_sub_worker_pid(update_log_sub_index()), LoopLogs2),
    set_loop_logs(Remain),
    {_Hour, _Min, Sec} = erlang:time(),
    ?IF(Sec =:= 0, set_fail_list([]), ok).

%%%===================================================================
%%% 数据操作
%%%===================================================================
%% 超过3次就不再重传，但是不删除
do_fail_logs(Logs) ->
    FailList = get_fail_list(),
    {Logs2, FailList2}  = do_fail_logs2(Logs, [], FailList),
    add_loop_log(Logs2),
    set_fail_list(FailList2).

do_fail_logs2([], LogsAcc, FailAcc) ->
    {LogsAcc, FailAcc};
do_fail_logs2([Log|R], LogsAcc, FailAcc) ->
    #r_junhai_log{id = ID} = Log,
    case lists:keyfind(ID, #p_kv.id, FailAcc) of
        #p_kv{val = Times} = KV ->
            KV2 = KV#p_kv{val = Times + 1};
        _ ->
            KV2 = #p_kv{id = ID, val = 1}
    end,
    LogsAcc2 = ?IF(KV2#p_kv.val >= 3, LogsAcc, [Log|LogsAcc]),
    FailAcc2 = lists:keystore(ID, #p_kv.id, FailAcc, KV2),
    do_fail_logs2(R, LogsAcc2, FailAcc2).

add_loop_log(AddLogs) ->
    Logs = get_loop_logs(),
    set_loop_logs(AddLogs ++ Logs).
set_loop_logs(Logs) ->
    erlang:put({?MODULE, loop_logs}, Logs).
get_loop_logs() ->
    erlang:get({?MODULE, loop_logs}).

set_fail_list(FailList) ->
    erlang:put({?MODULE, fail_list}, FailList).
get_fail_list() ->
    erlang:get({?MODULE, fail_list}).


update_log_sub_index() ->
    Index = get_log_sub_index(),
    case Index of
        ?JUNHAI_SUB_WORKER_NUM ->
            set_log_sub_index(1);
        _ ->
            set_log_sub_index(Index + 1)
    end,
    Index.
get_log_sub_index() ->
    erlang:get({?MODULE, log_sub_index}).
set_log_sub_index(Index) ->
    erlang:put({?MODULE, log_sub_index}, Index).

set_sub_worker_pid(SubIndex, PName) ->
    erlang:put({?MODULE, sub_worker_pid, SubIndex}, PName).
get_sub_worker_pid(SubIndex) ->
    erlang:get({?MODULE, sub_worker_pid, SubIndex}).