%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     es子工作进程，用来发起http连接
%%% @end
%%% Created : 5. 十月 2018 16:51
%%%-------------------------------------------------------------------
-module(background_log_sub_worker).
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
    send_sql/2
]).

start_link(ParentPID, PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [ParentPID], []).

send_sql(_PName, []) ->
    ok;
send_sql(PName, Logs) ->
    pname_server:send(PName, {send_sql, Logs}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([ParentPID]) ->
    erlang:process_flag(trap_exit, true),
    set_parent_pid(ParentPID),
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
do_handle({send_sql, Logs}) ->
    do_send_sql(Logs);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("unknow Info:~w", [Info]).

do_send_sql(Logs) ->
    {SuccKeys, FailLogs} = do_send_sql2(Logs, [], []),
    db:delete_many(?DB_BACKGROUND_LOG_P, SuccKeys),
    background_log_worker:add_fail_logs(get_parent_pid(), FailLogs).

do_send_sql2([], SuccKeys, FailLogs) ->
    {SuccKeys, FailLogs};
do_send_sql2([Log|R], SuccKeys, FailLogs) ->
    #r_background_log_p{
        id = ID,
        log_id = LogID,
        time = Time,
        agent_id = AgentID,
        server_id = ServerID,
        info = Info
    } = Log,
    RecordName = erlang:element(1, Info),
    FieldValues = lib_tool:to_list(erlang:delete_element(1, Info)),
    #c_background_log{
        fields = Fields,
        backgrounds = BackGrounds
    } = lists:keyfind(RecordName, #c_background_log.record_name, ?BACKGROUND_LIST),
    TableBin = lib_tool:to_binary(RecordName),
    KeysBin = get_key_bins([id, time, agent_id, server_id] ++ Fields, []),
    ValuesBin = get_value_bins([LogID, Time, AgentID, ServerID] ++ FieldValues, []),
    Cmd = <<"REPLACE INTO ", TableBin/binary,
        " (", KeysBin/binary, ") VALUES ",
        " (", ValuesBin/binary, ")">>,
    ResultList = write_sql(BackGrounds, Cmd, []),
    case not lists:member(false, ResultList) of
        true ->
            do_send_sql2(R, [ID|SuccKeys], FailLogs);
        _ ->
            do_send_sql2(R, SuccKeys, [Log|FailLogs])
    end.

get_key_bins([], BinsAcc) ->
    BinsAcc;
get_key_bins([T | R], []) ->
    Bin = lib_tool:to_binary(T),
    BinsAcc = <<Bin/binary>>,
    get_key_bins(R, BinsAcc);
get_key_bins([T | R], BinsAcc) ->
    Bin = lib_tool:to_binary(T),
    BinsAcc2 = <<Bin/binary, ",", BinsAcc/binary>>,
    get_key_bins(R, BinsAcc2).

get_value_bins([], BinsAcc) ->
    BinsAcc;
get_value_bins([T | R], []) ->
    Bin = esql_quote:encode(T),
    BinsAcc = <<Bin/binary>>,
    get_value_bins(R, BinsAcc);
get_value_bins([T | R], BinsAcc) ->
    Bin = esql_quote:encode(T),
    BinsAcc2 = <<Bin/binary, ",", BinsAcc/binary>>,
    get_value_bins(R, BinsAcc2).

write_sql([], _Cmd, ResultAcc) ->
    ResultAcc;
write_sql([BackGround | R], Cmd, ResultAcc) ->
    Ret = emysql:execute(BackGround, Cmd),
    Result = db_lib:return(Ret, BackGround, Cmd) =:= ok,
    write_sql(R, Cmd, [Result | ResultAcc]).

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_parent_pid(PID) ->
    erlang:put({?MODULE, parent_pid}, PID).
get_parent_pid() ->
    erlang:get({?MODULE, parent_pid}).