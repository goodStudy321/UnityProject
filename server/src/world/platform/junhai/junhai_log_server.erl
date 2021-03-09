%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 三月 2018 14:51
%%%-------------------------------------------------------------------
-module(junhai_log_server).
-author("laijichang").
-include("global.hrl").
-include("platform.hrl").

%% API
-export([
    start/0,
    start_link/0,
    log/1
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

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

log(Log) ->
    pname_server:send(?MODULE, {log, Log}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    world_data:init_junhai_gold_log_id(),
    [begin
         PName = get_worker_name(Index),
         {ok, _PID} = junhai_log_worker:start_link(Index, PName),
         ok
     end || Index <- lists:seq(1, ?JUNHAI_WORKER_NUM)],
    ?TRY_CATCH(do_init_keys(0)),
    erlang:send_after(?JUNHAI_LOG_LOOP_SEC * ?SECOND_MS, erlang:self(), loop_logs),
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
    db:sync_all(?DB_JUNHAI_LOG_P),
    db:flush(?DB_JUNHAI_LOG_P),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({log, Log}) ->
    do_log(Log);
do_handle(loop_logs) ->
    erlang:send_after(?JUNHAI_LOG_LOOP_SEC * ?SECOND_MS, erlang:self(), loop_logs),
    do_init_keys(?JUNHAI_LOG_LOOP_SEC);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("Unkow Info: ~w", [Info]).

%% 查看一下数据库残留的keys
do_init_keys(Interval) ->
    case ets:match_object(?DB_JUNHAI_LOG_P, '_', ?JUNHAI_LOG_LOOP_NUM) of
        {AllList, _Con} ->
            Now = time_tool:now(),
            AllLogs = filter_logs(AllList, Now, Interval, []),
            AllLen = erlang:length(AllLogs),
            do_init_keys2(AllLogs, AllLen div ?JUNHAI_WORKER_NUM, 1);
        _ ->
            ok
    end.

filter_logs([], _Now, _Interval, Acc) ->
    Acc;
filter_logs([Log|R], Now, Interval, Acc) ->
    #r_junhai_log{time = LogTime} = Log,
    case Now - LogTime >= Interval of
        true ->
            filter_logs(R, Now, Interval, [Log|Acc]);
        _ ->
            filter_logs(R, Now, Interval, Acc)
    end.

do_init_keys2([], _Num, _Index) ->
    ok;
do_init_keys2(AllLogs, 0, Index) ->
    junhai_log_worker:init_logs(get_worker_name(Index), AllLogs);
do_init_keys2(AllLogs, _Len, ?JUNHAI_WORKER_NUM) ->
    junhai_log_worker:init_logs(get_worker_name(?JUNHAI_WORKER_NUM), AllLogs);
do_init_keys2(AllLogs, Len, Index) ->
    {AllLogs2, Remain} = lib_tool:split(Len, AllLogs),
    junhai_log_worker:init_logs(get_worker_name(Index), AllLogs2),
    do_init_keys2(Remain, Len, Index + 1).

%% 日志来拉！！
do_log(LogList) when erlang:is_list(LogList) ->
    Now = time_tool:now(),
    [begin
         LogID = world_data:update_junhai_gold_log_id(),
         PName = get_worker_name(erlang:phash(LogID, ?JUNHAI_WORKER_NUM)),
         Log2 = Log#r_junhai_log{id = LogID, time = Now},
         junhai_log_worker:log(PName, Log2)
     end || Log <- LogList];
do_log(Log) ->
    do_log([Log]).

%%%===================================================================
%%% 数据操作
%%%===================================================================
get_worker_name(Index) ->
    case erlang:get({?MODULE, worker_name, Index}) of
        undefined ->
            PName = lib_tool:to_atom(lists:concat(["junhai_log_worker_", Index])),
            erlang:put({?MODULE, worker_name, Index}, PName),
            PName;
        PName ->
            PName
    end.