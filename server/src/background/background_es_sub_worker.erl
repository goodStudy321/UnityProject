%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     es子工作进程，用来发起http连接
%%% @end
%%% Created : 5. 十月 2018 16:51
%%%-------------------------------------------------------------------
-module(background_es_sub_worker).
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
    send_req/2
]).

start_link(IsReplaceWorker, PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [IsReplaceWorker], []).

send_req(_PName, []) ->
    ok;
send_req(PName, Logs) ->
    pname_server:send(PName, {send_req, Logs}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([IsReplaceWorker]) ->
    erlang:process_flag(trap_exit, true),
    set_is_replace_worker(IsReplaceWorker),
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
do_handle({send_req, Logs}) ->
    do_send_req(Logs);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("unknow Info:~w", [Info]).

do_send_req(Logs) ->
    Headers = get_log_headers(),
    JsonData = get_batch_json(Logs, is_replace_worker(), []),
    [Url] = lib_config:find(common, es_url),
    case catch ibrowse:send_req(Url ++ "/_bulk", Headers, put, JsonData, [], 5000) of
        {ok, _StatusCode, _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            Ret2 = proplists:get_value(<<"errors">>, Obj2),
            case Ret2 of
                false ->
                    ok;
                _ ->
                    report_error(Logs)
            end;
        Error ->
            ?ERROR_MSG("Error :~w", [Error]),
            report_error(Logs)
    end.

%% 屏蔽错误上报
report_error(_Logs) ->
    ok.
%%    LogList = [ #log_es{table_name = erlang:element(1, RecordInfo), log_id = LogID}|| #r_background_log_p{log_id = LogID, info = RecordInfo} <- Logs],
%%    background_misc:log(LogList).

get_log_headers() ->
    [{User, Password}] = lib_config:find(cfg_web, es_auth),
    [{connection, "keep-alive"}, {content_type, "application/json"}, {basic_auth, {User, Password}}].

get_key_values(RecordName, Log) ->
    #r_background_log_p{
        log_id = LogID,
        time = Time,
        agent_id = AgentID,
        server_id = ServerID,
        info = Info
    } = Log,
    FieldValues = lib_tool:to_list(erlang:delete_element(1, Info)),
    #c_background_log{fields = Fields} = lists:keyfind(RecordName, #c_background_log.record_name, ?BACKGROUND_LIST),
    AgentServer = (AgentID *  10000000) + ServerID,
    get_key_values2([id, time, agent_id, server_id, agent_server] ++ Fields, [LogID, Time, AgentID, ServerID, AgentServer] ++ FieldValues, []).

get_key_values2([], [], Acc) ->
    Acc;
get_key_values2([Key|KeyR], [Value|ValueR], Acc) ->
    Acc2 = [{Key, Value}|Acc],
    get_key_values2(KeyR, ValueR, Acc2).

get_batch_json([], _IsReplace, Acc) ->
    Acc;
get_batch_json([Log|R], IsReplace, Acc) ->
    #r_background_log_p{key = Key, info = Info} = Log,
    RecordName = erlang:element(1, Info),
    List1 =
        case IsReplace of
            true ->
                [
                    {"_type", "_doc"},
                    {"_index", RecordName},
                    {"_id", Key}
                ];
            _ ->
                [
                    {"_type", "_doc"},
                    {"_index", RecordName}
                ]
        end,
    Tab1 = lib_json:to_json({"index", List1}),
    ValueList = get_key_values(RecordName, Log),
    Tab2 = lib_json:to_json([{"_from", 1}|ValueList]),
    Acc2 = Tab1 ++ "\n" ++ Tab2 ++ "\n" ++ Acc,
    get_batch_json(R, IsReplace, Acc2).

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_is_replace_worker(Bool) ->
    erlang:put({?MODULE, is_replace_worker}, Bool).
is_replace_worker() ->
    get_is_replace_worker() =:= true.
get_is_replace_worker() ->
    erlang:get({?MODULE, is_replace_worker}).