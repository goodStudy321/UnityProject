%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(server_main).

-include("common.hrl").

%% API
-export([
    start/0,
    stop/0,
    cmd/0
]).


-define(APPS, [sasl, asn1, crypto, public_key, ssl, server_app]).
%% 执行远程命令后返回给脚本的状态
-define(STATUS_SUCCESS, 0). %%成功
-define(STATUS_ERROR, 1). %%错误
-define(STATUS_USAGE, 2). %%打印使用方法
-define(STATUS_BAD_RPC, 3). %%执行失败

%%%===================================================================
%%% API
%%%===================================================================

%% @doc 启动app
start() ->
    ok = before_start(),
    start_applications(?APPS),
    timer:sleep(1000),
    RmStarting = io_lib:format("rm ~s", [server_misc:get_starting_flag()]),
    os:cmd(RmStarting),
    TouchSucc = io_lib:format("touch ~s", [server_misc:get_succ_flag()]),
    os:cmd(TouchSucc),
    lib_sys:gc(102400),
    erlang:set_cookie(erlang:node(), common_config:get_cookie()),
    ?SYSTEM_LOG("~ts ~n", ["启动成功"]),
    ok.

stop() ->
    print("shutdown...~n", []),
    server_app:pre_stop(),
    timer:sleep(1000),
    stop_applications(?APPS),
    print("stopping server_app...~n", []),
    print("stopped server_app ~n", []),
    timer:sleep(1000),
    init:stop().

cmd() ->
    io:setopts([{encoding, unicode}]),
    case init:get_plain_arguments() of
        [SNode|Args] ->
            %%io:format("plain arguments is:~w~n", [Args]),
            SNode1 =
            case string:tokens(SNode, "@") of
                [_Node, _Server] ->
                    SNode;
                _ ->
                    case net_kernel:longnames() of
                        true ->
                            SNode ++ "@" ++ inet_db:gethostname() ++
                                            "." ++ inet_db:res_option(domain);
                        false ->
                            SNode ++ "@" ++ inet_db:gethostname();
                        _ ->
                            SNode
                    end
            end,
            Node = erlang:list_to_atom(SNode1),
            Status =
            case rpc:call(Node, server_misc, process, [Args]) of
                {badrpc, Reason} ->
                    print("RPC failed on the node ~w: ~w~n", [Node, Reason]),
                    ?STATUS_BAD_RPC;
                ok ->
                    ?STATUS_SUCCESS;
                ErrorMsg ->
                    print("RPC failed on the node ~w: ~w~n", [Node, ErrorMsg]),
                    ?STATUS_ERROR
            end,
            halt(Status);
        _ ->
            halt(?STATUS_USAGE)
    end.
%%%===================================================================
%%% Internal functions
%%%===================================================================
before_start() ->
    application:start(inets),
    lib_config:init(), %% 初始化配置
    [LogLevel] = lib_config:find(common, log_level),
    %% 初始化日志等级
    log:set_loglevel(LogLevel),
    log_mgr_server:start_link(),
    common_misc:ensure_all_beam_loaded(),
    ok.

manage_applications(Iterate, Do, Undo, SkipError, ErrorTag, Apps) ->
    Iterate(fun(App, Acc) ->
        case Do(App) of
            ok -> [App|Acc];
            {error, {SkipError, _}} -> Acc;
            {error, Reason} ->
                lists:foreach(Undo, Acc),
                erlang:throw({error, {ErrorTag, App, Reason}})
        end
            end, [], Apps),
    ok.

%% @doc start applications
%% @throws {error, {ErrorTag, App, Reason}}
-spec start_applications([atom()]) -> ok.
start_applications(Apps) ->
    manage_applications(fun lists:foldl/3,
                        fun application:start/1,
                        fun application:stop/1,
                        already_started,
                        cannot_start_application,
                        Apps).

%% @doc stop applications
%% @throws {error, {ErrorTag, App, Reason}}
-spec stop_applications([atom()]) -> ok.
stop_applications(Apps) ->
    manage_applications(fun lists:foldr/3,
                        fun application:stop/1,
                        fun application:start/1,
                        not_started,
                        cannot_stop_application,
                        Apps).

print(Format, Args) ->
    {{Y, Mo, D}, {H, Mi, S}} = erlang:localtime(),
    io:format("==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===(~w) : " ++ Format,
              [Y, Mo, D, H, Mi, S, node()] ++ Args).