%%%----------------------------------------------------------------------
%%% @doc 用于启动发布过程日志
%%% @end
%%%----------------------------------------------------------------------
-module(log_mgr_server).

-behaviour(gen_server).

%% API
-export([
    start_link/0
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

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    do_handle(Info),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @doc 接收日志信息并输出到文件
do_handle({system_log, Time, Format, Args}) ->
    Head =  log_misc:get_log_header(Time),
    File = log_misc:get_mgr_log(),
    file:write_file(File, Head, [append]),
    try
        M = unicode:characters_to_binary(io_lib:format(Format, Args)),
        file:write_file(File, M, [append])
    catch _:Error ->
        io:format("log error ~p ~p ~p", [Error, Format, Args])
    end,
    ok;
do_handle(Info) ->
    erlang:send(erlang:self(), {system_log, erlang:localtime(), "~ts:~w", ["未知的消息", Info]}),
    ok.
