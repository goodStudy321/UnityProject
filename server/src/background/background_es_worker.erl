%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 5. 十月 2018 16:51
%%%-------------------------------------------------------------------
-module(background_es_worker).
-author("laijichang").
-include("global.hrl").


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
    init_keys/2,
    mongo_pid/2,
    log/2
]).

start_link(Index, PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [Index], []).

init_keys(PName, Keys) ->
    pname_server:send(PName, {init_keys, Keys}).

mongo_pid(PName, MongoPID) ->
    pname_server:send(PName, {mongo_pid, MongoPID}).

log(PName, Log) ->
    pname_server:send(PName, {log, Log}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([Index]) ->
    erlang:process_flag(trap_exit, true),
    erlang:send_after(lib_tool:random(0, ?BACKGROUND_ES_LOOP_TIME), erlang:self(), loop),
    set_loop_logs([]),
    IsReplaceWorker = ?IS_REPLACE_WORKER(Index),
    set_is_replace_worker(IsReplaceWorker),
    [begin
         PName = lib_tool:to_atom(lists:concat(["background_es_sub_worker_", Index, "_", SubIndex])),
         {ok, PID} = background_es_sub_worker:start_link(IsReplaceWorker, PName),
         set_sub_worker_pid(SubIndex, PID),
         ok
     end || SubIndex <- lists:seq(1, ?BACKGROUND_SUB_WORKER)],
    set_log_sub_index(1),
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
do_handle({log, Log}) ->
    add_loop_log(Log);
do_handle(loop) ->
    erlang:send_after(lib_tool:random(0, ?BACKGROUND_ES_LOOP_TIME), erlang:self(), loop),
    do_loop();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("unknow Info:~w", [Info]).

do_loop() ->
    LoopLogs = get_loop_logs(),
    {LoopLogs2, Remain} = lib_tool:split(?BACKGROUND_LOG_NUM, LoopLogs),
    background_es_sub_worker:send_req(get_sub_worker_pid(update_log_sub_index()), LoopLogs2),
    set_loop_logs(Remain).

%%%===================================================================
%%% 数据操作
%%%===================================================================
add_loop_log(Log) ->
    #r_background_log_p{log_id = LogID, key = Key} = Log,
    Logs = get_loop_logs(),
    case is_replace_worker() of
        true -> %% 要替换的日志，先check一下。
            case lists:keytake(Key, #r_background_log_p.key, Logs) of
                {value, #r_background_log_p{log_id = OldLogID}, Logs2} ->
                    case LogID > OldLogID of
                        true ->
                            Logs3 = lists:keysort(#r_background_log_p.id, [Log|Logs2]),
                            set_loop_logs(Logs3);
                        _ ->
                            ok
                    end;
                _ ->
                    set_loop_logs([Log|Logs])
            end;
        _ ->
            set_loop_logs([Log|Logs])
    end.
set_loop_logs(Logs) ->
    erlang:put({?MODULE, loop_logs}, Logs).
get_loop_logs() ->
    erlang:get({?MODULE, loop_logs}).

is_replace_worker() ->
    get_is_replace_worker() =:= true.
get_is_replace_worker() ->
    erlang:get({?MODULE, is_replace_worker}).
set_is_replace_worker(Bool) ->
    erlang:put({?MODULE, is_replace_worker}, Bool).

update_log_sub_index() ->
    Index = get_log_sub_index(),
    case Index of
        ?BACKGROUND_SUB_WORKER ->
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