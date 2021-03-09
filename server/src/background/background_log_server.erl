%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 三月 2018 14:51
%%%-------------------------------------------------------------------
-module(background_log_server).
-author("laijichang").
-include("global.hrl").

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

-export([
    change_background_log_index/1
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

log(Log) ->
    pname_server:send(?MODULE, {log, Log}).

change_background_log_index(Name) ->
    pname_server:send(?MODULE, {change_background_log_index, Name}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    world_data:init_background_id(),
    [begin
         PName = get_worker_name(Index),
         {ok, _PID} = background_log_worker:start_link(Index, PName),
         ok
     end || Index <- lists:seq(1, ?BACKGROUND_WORKER_NUM + ?BACKGROUND_REPLACE_WORKER)],
    ESWorkerList = lists:seq(1, ?BACKGROUND_ES_WORKER_NUM) ++ lists:seq(?BACKGROUND_WORKER_NUM + 1, ?BACKGROUND_WORKER_NUM + ?BACKGROUND_ES_REPLACE_NUM),
    [begin
         ESPName = get_es_worker_name(ESIndex),
         {ok, _PID2} = background_es_worker:start_link(ESIndex, ESPName),
         ok
     end || ESIndex <- ESWorkerList],
    %% gm环境，可以不检测
    ?IF(common_config:is_gm_open(), ?TRY_CATCH(background_lib:connect(?ADMIN_POOL), Err1), background_lib:connect(?ADMIN_POOL)),
    ?TRY_CATCH(do_init_keys(0), Err2),
    erlang:send_after(?BACKGROUND_LOG_LOOP_SEC * ?SECOND_MS, erlang:self(), loop_logs),
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
    db:sync_all(?DB_BACKGROUND_LOG_P),
    db:flush(?DB_BACKGROUND_LOG_P),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({log, Log}) ->
    do_log(Log);
do_handle({modify_log, Time, Logs}) ->
    do_log2(Time, Logs);
do_handle(loop_logs) ->
    erlang:send_after(?BACKGROUND_LOG_LOOP_SEC * ?SECOND_MS, erlang:self(), loop_logs),
    do_init_keys(?BACKGROUND_LOG_LOOP_SEC);
do_handle({change_background_log_index, Name}) ->
    do_change_background_log_index(Name);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("Unkow Info: ~w", [Info]).

%% 查看一下数据库残留的keys
do_init_keys(Interval) ->
    case ets:match_object(?DB_BACKGROUND_LOG_P, '_', ?BACKGROUND_LOG_LOOP_NUM) of
        {AllList, _Con} ->
            Now = time_tool:now(),
            {AllLogs, ReplaceList} = spilt_keys(AllList, Now, Interval, [], []),
            Len = erlang:length(AllLogs),
            do_init_keys2(AllLogs, Len div ?BACKGROUND_WORKER_NUM, 1),
            [ background_log_worker:init_logs(get_worker_name(ReplaceIndex), ReplaceLogs) || {ReplaceIndex, ReplaceLogs} <- ReplaceList];
        _ ->
            ok
    end.

%% 将有顺序要求的日志分离
spilt_keys([], _Now, _Interval, AllLogs, ReplaceList) ->
    {AllLogs, ReplaceList};
spilt_keys([Log|R], Now, Interval, AllLogs, ReplaceList) ->
    #r_background_log_p{info = LogInfo, time = LogTime} = Log,
    case Now - LogTime >= Interval of
        true -> %% 特定间隔到了，看看能不能写日志
            case lists:keyfind(erlang:element(1, LogInfo), #c_background_log.record_name, ?BACKGROUND_LIST) of
                #c_background_log{worker_index = WorkerIndex} ->
                    case WorkerIndex > 0 of
                        true ->
                            case  lists:keyfind(WorkerIndex, 1, ReplaceList) of
                                {WorkerIndex, ReplaceLogs} ->
                                    ReplaceLogs2 = [Log|ReplaceLogs],
                                    ReplaceList2 = lists:keyreplace(WorkerIndex, 1, ReplaceList, {WorkerIndex, ReplaceLogs2});
                                _ ->
                                    ReplaceList2 = [{WorkerIndex, [Log]}|ReplaceList]
                            end,
                            spilt_keys(R, Now, Interval, AllLogs, ReplaceList2);
                        _ ->
                            spilt_keys(R, Now, Interval, [Log|AllLogs], ReplaceList)
                    end;
                _ ->
                    spilt_keys(R, Now, Interval, [Log|AllLogs], ReplaceList)
            end;
        _ ->
            spilt_keys(R, Now, Interval, AllLogs, ReplaceList)
    end.

do_init_keys2([], _Num, _Index) ->
    ok;
do_init_keys2(AllKeys, 0, Index) ->
    background_log_worker:init_logs(get_worker_name(Index), AllKeys);
do_init_keys2(AllKeys, _Len, ?BACKGROUND_WORKER_NUM) ->
    background_log_worker:init_logs(get_worker_name(?BACKGROUND_WORKER_NUM), AllKeys);
do_init_keys2(AllKeys, Len, Index) ->
    {AllKeys2, Remain} = lib_tool:split(Len, AllKeys),
    background_log_worker:init_logs(get_worker_name(Index), AllKeys2),
    do_init_keys2(Remain, Len, Index + 1).

%% 日志来拉！！
do_log(LogList) when erlang:is_list(LogList) ->
    Time = time_tool:now(),
    do_log2(Time, LogList);
do_log(Log) ->
    do_log([Log]).

do_log2(Time, LogList) ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    [begin
         RecordName = erlang:element(1, LogInfo),
         case get_background_log_index(RecordName) of
             {ok, Index, WorkerIndex, IsLogES} ->
                 ID = world_data:update_background_id(),
                 LogID = world_data:update_background_log_id(Index),
                 %% 部分日志是替换形式，我们必须保证其有序
                 case WorkerIndex > 0 of
                     true ->
                         WorkerIndex2 = WorkerIndex,
                         EsWorkerIndex = WorkerIndex,
                         Key = erlang:element(2, LogInfo);
                     _ ->
                         WorkerIndex2 = erlang:phash(LogID, ?BACKGROUND_WORKER_NUM),
                         EsWorkerIndex = erlang:phash(LogID, ?BACKGROUND_ES_WORKER_NUM),
                         Key = LogID
                 end,
                 PName = get_worker_name(WorkerIndex2),
                 ESPName = get_es_worker_name(EsWorkerIndex),
                 Log = #r_background_log_p{
                     id = ID,
                     key = Key,
                     log_id = LogID,
                     time = Time,
                     agent_id = AgentID,
                     server_id = ServerID,
                     info = LogInfo},
                 background_log_worker:log(PName, Log),
                 %% ES日志只存在后台
                 ?IF(IsLogES, background_es_worker:log(ESPName, Log), ok);
             _ ->
                 ?ERROR_MSG("LogInfo index not found: ~w", [LogInfo])
         end
     end || LogInfo <- LogList].

do_change_background_log_index(Name) ->
    erlang:erase({?MODULE, background_log_index, lib_tool:to_atom(Name)}),
    ok.

%%%===================================================================
%%% 数据操作
%%%===================================================================
get_worker_name(Index) ->
    case erlang:get({?MODULE, worker_name, Index}) of
        undefined ->
            PName = lib_tool:to_atom(lists:concat(["background_log_worker_", Index])),
            erlang:put({?MODULE, worker_name, Index}, PName),
            PName;
        PName ->
            PName
    end.
get_es_worker_name(Index) ->
    case erlang:get({?MODULE, es_worker_name, Index}) of
        undefined ->
            PName = lib_tool:to_atom(lists:concat(["background_es_worker_", Index])),
            erlang:put({?MODULE, es_worker_name, Index}, PName),
            PName;
        PName ->
            PName
    end.


get_background_log_index(RecordName) ->
    case erlang:get({?MODULE, background_log_index, RecordName}) of
        {Index, WorkerIndex, IsLogES} ->
            {ok, Index, WorkerIndex, IsLogES};
        _ ->
            case lists:keyfind(RecordName, #c_background_log.record_name, ?BACKGROUND_LIST) of
                #c_background_log{index = Index, worker_index = WorkerIndex, is_log_es = IsLogES} ->
                    erlang:put({?MODULE, background_log_index, RecordName}, {Index, WorkerIndex, IsLogES}),
                    {ok, Index, WorkerIndex, IsLogES};
                _ ->
                    false
            end
    end.