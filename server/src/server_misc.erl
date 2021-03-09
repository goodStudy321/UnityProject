%%%----------------------------------------------------------------------
%%% @doc 此模块用于启动游戏中的应用
%%%
%%% @end
%%%----------------------------------------------------------------------
-module(server_misc).

-include("global.hrl").


-define(PRINT(Format, Args), io:format(Format, Args)).

%% API
-export([
    get_succ_flag/0,
    get_starting_flag/0]).

-export([
    load_beams/0
]).


-export([
    process/1,
    print_usage/0]).

%% ===========================
get_starting_flag()->
    MgeRoot = common_config:get_server_root(),
    io_lib:format(" ~s/starting_flag",[MgeRoot]).

get_succ_flag()->
    MgeRoot = common_config:get_server_root(),
    io_lib:format(" ~s/start_succ",[MgeRoot]).

load_beams() ->
    MgeRoot = common_config:get_server_root(),
    FileList = filelib:wildcard(MgeRoot ++ "ebin/*.beam"),
    ModuleList = [begin lib_tool:list_to_atom(filename:basename(File, ".beam")) end || File <- FileList],
    [begin
         code:ensure_loaded(Module)
     end || Module <- ModuleList],
    ok.

%% ===========================

%% @doc 获取游戏服各个节点的运行状态
-spec process([string()])->ok|error.

process(["reload_beam", Modules])->
    reload_beam(split_args(Modules));
process(["reload_config", Configs])->
    reload_config(split_args(Configs));
process(["exprs", Exprs])->
    exprs(split_args(Exprs)),
    ok;
process(["execute_cmd", Cmd]) ->
    execute_cmd(split_args(Cmd));
process(["status"|_]) ->
    status();
process(["merge_status"|_]) ->
    merge_status();
process(["get_auth_switch"|_]) ->
    get_auth_switch();
process(["verification"|_]) ->
    verification();
%% @doc 快速T人停止本节点
process(["stop_fast"|_]) ->
    %% 改动最小的处理方式
    gateway_misc:set_stop_fast(),
    server_main:stop(),
    ok;
%% @doc 将当前节点停止到lite模式
%% lite模式只会允许mgee_db app，一般用于数据库更新
process(["pre_stop"|_]) ->
    server_app:pre_stop(),
    ok;
%% @doc 停止本节点
process(["stop"|_]) ->
    server_main:stop(),
    ok;
process(["merge", JsonString]) ->
    merge_main:start_merge(JsonString),
    ok;
%% @doc 查看gate和mochiweb端口
process(["get_port"|_]) ->
    WebPort = common_config:get_web_port(),
    GatewayPort = common_config:get_gateway_port(),
    ?PRINT("mochiweb_port:~w~n", [WebPort]),
    ?PRINT("gateway_port:~w~n", [GatewayPort]),
    ok;
%% 其它接口可以删除
process(["get_game_info"|_]) ->
    %% 网关端口
    TopoNodes = common_config:get_topo_nodes(),
    [begin
         ?PRINT("gate_~w_port:~w~n",[NodeIndex, Port])
     end || {NodeIndex, _IP, Port} <- TopoNodes],
    %% mochiweb 端口
    WebPort = common_config:get_web_port(),
    ?PRINT("mochiweb_port:~w~n",[WebPort]),
    %% 在线人数
    ?PRINT("online:~w~n",[world_online_server:get_online_num()]),
    %% 注册人数
    ?PRINT("register:~w~n",[mdb:table_info(db_role_account_p, size)]),

    PList = erlang:processes(),
    AbnMsgNum = 100,
    {ProcessNum, AbnNum} =
        lists:foldl(fun(PID, {Sum, AbnNum})->
                        case erlang:process_info(PID, message_queue_len) of
                            {message_queue_len, VV} when VV=<AbnMsgNum -> {Sum+1, AbnNum};
                            _ -> {Sum+1, AbnNum+1}
                        end
                    end,{0,0}, PList),
    %% 堵消息进程数量
    ?PRINT("process_abn:~w~n",[AbnNum]),
    %% 数据库大小 单位b
    ?PRINT("mnesia_size:~w~n",[lib_sys:get_total_mnesia_memory()]),
    %% 进程数量
    ?PRINT("process_num:~w~n",[ProcessNum]), %%
    ok;
process(["get_pid"|_]) ->
    ?PRINT("~s~n", [os:getpid()]),
    ok;
process(Args)->
    ?PRINT("UNKNOW ARGS :~w",[Args]),
    error.

split_args(Args) ->
    string:tokens(Args, " ").

%% @doc 热更新beam文件
reload_beam(Modules) when is_list(Modules) ->
    reload_beam1(Modules);
reload_beam(Module)  ->
    reload_beam1([Module]).
reload_beam1([]) ->
    ok;
reload_beam1([Module|T]) ->
    Module2 = get_base_name(Module),
    case common_reloader:reload_module(erlang:list_to_atom(Module2)) of
        ok ->
            io:format("reload_beam:~p ok~n",[Module2]),
            reload_beam1(T);
        _ ->
            io:format("reload_beam:~p fail ~n",[Module2]),
            error
    end.


%% @doc 热更新配置文件
reload_config(Configs) when is_list(Configs) ->
    reload_config1(Configs);
reload_config(Config) ->
    reload_config1([Config]).
reload_config1([]) ->
    ok;
reload_config1([Config|T]) ->
    Config2 = get_base_name(Config),
    case common_reloader:reload_config(erlang:list_to_atom(Config2)) of
        ok ->
            ?INFO_MSG("reload_config:~p ok", [Config2]),
            reload_config1(T);
        _ ->
            ?INFO_MSG("reload_config:~p fail", [Config2]),
            error
    end.

%% @doc 执行外部动态命令
exprs(Exprs) ->
    Exprs2 = lists:flatten(Exprs),
    Str = "-module(exprs). -export([exprs/0]). exprs() -> " ++ Exprs2 ++ ".\n",
    {Mod, Code} = dynamic_compile:from_string(Str),
    code:load_binary(Mod, "exprs.erl", Code),
    R = Mod:exprs(),
    ?PRINT("~w\n", [R]),
    %%
    ok.

%% 执行的结果，正确情况要有ok
execute_cmd(Cmd) ->
    {Mod, Module, Args} =
        case Cmd of
            [ModT, ModuleT] ->
                {ModT, ModuleT, []};
            [ModT, ModuleT|ArgsListT] ->
                {ModT, ModuleT, ArgsListT}
        end,
    %% ArgsList里的每个元素List
    case catch erlang:apply(lib_tool:to_atom(Mod), lib_tool:to_atom(Module), Args) of
        {ok, Result} ->
            io:format("~w", [Result]),
            ok;
        ok ->
            io:format("ok"),
            ok;
        Error ->
            Error
    end.


status()->
    {InternalStatus, ProvidedStatus} = init:get_status(),
    ?PRINT("Node ~w is ~w. Status: ~w~n", [node(), InternalStatus, ProvidedStatus]).

merge_status() ->
    OpenDays = common_config:get_open_days(),
    IsMerge = common_config:is_merge(),
    CrossServerID = global_data:get_cross_server_id(),
    case OpenDays > 7 andalso IsMerge andalso CrossServerID > 0 of
        true ->
            ?PRINT("ok~n", []);
        _ ->
            ?PRINT("error OpenDays:~w, IsMerge:~w, CrossServerID:~w~n", [OpenDays, IsMerge, CrossServerID])
    end,
    ok.

get_auth_switch() ->
    Bool = ?IF(world_data:is_create_able() =:= true, ?TRUE, ?FALSE),
    ?PRINT("~w~n", [Bool]),
    ok.

verification() ->
    ?PRINT("~w_~w_~w~n", [common_config:get_agent_id(), common_config:get_server_id(), common_config:get_gateway_port()]),
    ok.

%% @doc help命令
print_usage() ->
    CmdDesc =
        [
            {"status", "get node status"},
            {"start", "start node"},
            {"stop", "stop node"},
            {"stop_to_lite", "stop to lite"} ,
            {"reload_beam", "relad beam files"},
            {"reload_config", "relad config files"},
            {"exprs","execute the express"}
        ] ,
    MaxCmdLen =
        lists:max(lists:map(
            fun({Cmd, _Desc}) ->
                erlang:length(Cmd)
            end, CmdDesc)),
    NewLine = io_lib:format("~n", []),
    FmtCmdDesc =
        lists:map(
            fun({Cmd, Desc}) ->
                ["  ", Cmd, string:chars($\s, MaxCmdLen - erlang:length(Cmd) + 2),
                    Desc, NewLine]
            end, CmdDesc),
    ?PRINT(
       "Usage: mgectl command [argus]~n"
       "~n"
       "Available commands in this node node:~n"
       "~s"
       "~n"
       "Examples:~n"
       "  mgectl start~n",
       [FmtCmdDesc]).

get_base_name(Args) ->
    Index = string:str(Args, "."),
    ?IF(Index > 0, string:substr(Args, 1, Index - 1), Args).

