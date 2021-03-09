%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     子工作进程，用来发起http连接
%%% @end
%%% Created : 5. 十月 2018 16:51
%%%-------------------------------------------------------------------
-module(junhai_log_sub_worker).
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
    send_req/2
]).

start_link(ParentPID, PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [ParentPID], []).

send_req(_PName, []) ->
    ok;
send_req(PName, Logs) ->
    pname_server:send(PName, {send_req, Logs}).

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
do_handle({send_req, Logs}) ->
    do_send_req(Logs);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(Info) ->
    ?ERROR_MSG("unknow Info:~w", [Info]).

do_send_req(Logs) ->
    case common_pf:get_pf_agent_id() of
        ?AGENT_JUNHAI_AND ->
            do_send_junhai_req(Logs);
        ?AGENT_JUNHAI_IOS ->
            do_send_junhai_req(Logs);
        ?AGENT_GUILD -> %% 君海公会渠道
            do_send_junhai_req(Logs);
        ?AGENT_SQ ->
            do_send_sq_req(Logs);
        _ ->
            ok
    end.

%% 发送君海的平台日志
do_send_junhai_req(Logs) ->
    Key = ?IF(common_config:is_overseas(), overseas_data_url, data_url),
    [Url] = lib_config:find(cfg_junhai, Key),
    {LogIDs, LogList} =
        lists:foldl(
            fun(#r_junhai_log{id = LogID, log = Log}, {Acc1, Acc2}) ->
                {[LogID|Acc1], [Log|Acc2]}
            end, {[], []}, Logs),
    JsonData = lib_json:to_json(LogList),
    case catch ibrowse:send_req(Url, [{connection, "keep-alive"}, {content_type, "application/json"}], post, JsonData, [], 5000) of
        {ok, "200", _Headers2, Body2} when Body2 =/= [] ->
            case catch mochijson2:decode(Body2) of
                {struct, Obj2} ->
                    Ret2 = proplists:get_value(<<"ret">>, Obj2),
                    case Ret2 of
                        1 ->
                            db:delete_many(?DB_JUNHAI_LOG_P, LogIDs),
                            ok;
                        _ ->
                            report_error(Logs)
                    end;
                _ ->
                    ?ERROR_MSG("Body Error :~w", Body2),
                    report_error(Logs)
            end;
        _ ->
            ?ERROR_MSG("Error :~s", [JsonData]),
            report_error(Logs)
    end.

%% 发送神起的日志
do_send_sq_req(Logs) ->
    [Url] = lib_config:find(cfg_sq, chat_log_url),
    {LogIDs, LogList} =
        lists:foldl(
            fun(#r_junhai_log{id = LogID, log = Log}, {Acc1, Acc2}) ->
                {[LogID|Acc1], [Log|Acc2]}
            end, {[], []}, Logs),
    JsonData = lib_json:to_json({messageGroup, LogList}),
    case catch ibrowse:send_req(Url, [{connection, "keep-alive"}, {content_type, "application/json"}], post, JsonData, [], 5000) of
        {ok, "200", _Headers2, Body2} when Body2 =/= [] ->
            case catch mochijson2:decode(Body2) of
                {struct, Obj2} ->
                    State = proplists:get_value(<<"state">>, Obj2),
                    case State of
                        "1" ->
                            db:delete_many(?DB_JUNHAI_LOG_P, LogIDs),
                            ok;
                        _ ->
                            ?ERROR_MSG("Obj2: ~w", [Obj2]),
                            report_error(Logs)
                    end;
                _ ->
                    ?ERROR_MSG("Body Error :~w", Body2),
                    report_error(Logs)
            end;
        _ ->
            ?ERROR_MSG("Error :~s", [JsonData]),
            report_error(Logs)
    end.

report_error(Logs) ->
    ParentPID = get_parent_pid(),
    junhai_log_worker:add_fail_logs(ParentPID, Logs).
%%%===================================================================
%%% 数据操作
%%%===================================================================
set_parent_pid(PID) ->
    erlang:put({?MODULE, parent_pid}, PID).
get_parent_pid() ->
    erlang:get({?MODULE, parent_pid}).