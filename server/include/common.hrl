%%%-------------------------------------------------------------------
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 四月 2017 0:45
%%%-------------------------------------------------------------------
-ifndef(COMMON_HRL).
-define(COMMON_HRL, common_hrl).

%% 程序日志记录宏
-define(DEBUG(Format, Args),
    log_entry:debug_msg(node(), ?MODULE, ?LINE,Format, Args)).
-define(DEBUG(D), ?DEBUG(D, [])).

-define(INFO_MSG(Format, Args),
    log_entry:info_msg(node(), ?MODULE, ?LINE,Format, Args)).
-define(INFO_MSG(D), ?INFO_MSG(D, [])).

-define(WARNING_MSG(Format, Args),
    log_entry:warning_msg( node(), ?MODULE, ?LINE,Format, Args)).
-define(WARNING_MSG(D), ?WARNING_MSG(D, [])).

-define(ERROR_MSG(Format, Args),
    log_entry:error_msg( node(), ?MODULE, ?LINE,Format, Args)).
-define(ERROR_MSG(D), ?ERROR_MSG(D, [])).

-define(CRITICAL_MSG(Format, Args),
    log_entry:critical_msg( node(), ?MODULE, ?LINE,Format, Args)).
-define(CRITICAL_MSG(D), ?CRITICAL_MSG(D, [])).

-define(SYSTEM_LOG(Format, Args), erlang:send(log_mgr_server, {system_log, erlang:localtime(), Format, Args})).
-define(SYSTEM_LOG(Format), erlang:send(log_mgr_server, {system_log, erlang:localtime(), Format, []})).

-define(LXG(Parameter), ?INFO_MSG("*******=======******|| ~p = ~w ",   [??Parameter, Parameter])).

-define(TRY_CATCH(Expression,Tip,ErrReason),
    try
        Expression
    catch
        _:ErrReason ->
            ?ERROR_MSG("~ts: Reason=~w~n,Stacktrace=~p", [Tip,ErrReason,erlang:get_stacktrace()])
    end).
-define(TRY_CATCH(Expression,ErrReason),
    try
        Expression
    catch
        _:ErrReason ->
            ?ERROR_MSG("Reason=~w~n,Stacktrace=~p", [ErrReason,erlang:get_stacktrace()])
    end).
-define(TRY_CATCH(Expression), ?TRY_CATCH(Expression,ErrReason)).


-define(CATCH(Fun,Pass),
    case catch Fun of
        Pass->Pass;
        Error->?ERROR_MSG("-----Error:~w",[Error])
    end).

-define(CATCH(Fun,Pass,Error),
    case catch Fun of
        Pass->Pass;
        Error->?ERROR_MSG("-----Error:~w",[Error])
    end).


-define(DO_HANDLE_INFO(Info,State),
    try
        do_handle(Info)
    catch _:Reason ->
        ?ERROR_MSG("Info:~w~n,State=~w~n, Reason: ~w~n, strace:~p", [Info,State, Reason, erlang:get_stacktrace()]) ,
        error
    end).

-define(DO_HANDLE_CAST(Info,State),
    try
        do_handle(Info)
    catch _:Reason ->
        ?ERROR_MSG("Info:~w~n,State=~w~n, Reason: ~w~n, strace:~p", [Info,State, Reason, erlang:get_stacktrace()]),
        error
    end).

-define(DO_HANDLE_CALL(Request,State),
    try
        case Request of
            {tl,Time,Request2}->
                case time_tool:now_os()*1000 > Time of
                    true->
                        {error,call_timeout};
                    false->
                        do_handle(Request2)
                end;
            _->
                do_handle(Request)
        end
    catch _:Reason ->
        ?ERROR_MSG("Request:~w~n,State=~w~n, Reason: ~w~n, strace:~p", [Request,State, Reason, erlang:get_stacktrace()]),
        error
    end).

%% 数据库相关宏定义
-define(MYSQL_USER, "ranger").
-define(MYSQL_PASSWORD, "ranger666666").
-define(GAME_DB_NAME, "ranger").
-define(ADMIN_DB_NAME, "admin").
-define(CENTRAL_DB_NAME, "central").
-define(DB_CONNECTIONS, 10).

-define(TIME_ZERO, zeroclock).
-define(HOUR_CHANGE, hour_change).

-define(CALL_TIMETOUT, 4000).
-define(THROW_ERR(ErrCode),erlang:throw({error,ErrCode})).
-define(THROW_ERR(ErrCode,Reason),erlang:throw({error,ErrCode,Reason})).

-define(NODE_TYPE_GAME, game).      %% 游戏服节点
-define(NODE_TYPE_CROSS, cross).    %% 跨服节点
-define(NODE_TYPE_CENTER, center).  %% 中央节点

-define(NONE, none).

-ifndef(IF).
-define(IF(C, T, F), (case (C) of true -> (T); false -> (F) end)).
-endif.

-define(CONFIG_FIND(ConfigName, Key), (ConfigName:find(Key))).

-endif.




