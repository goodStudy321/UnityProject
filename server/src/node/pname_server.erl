%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     负责维护其他节点的进程
%%% @end
%%% Created : 20. 六月 2017 11:02
%%%-------------------------------------------------------------------
-module(pname_server).
-author("laijichang").
-behaviour(gen_server).

-include("node.hrl").

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

%% API
-export([
    start/0,
    start_link/0
]).

-export([
    send/2,
    call/2,
    call/3
]).

-export([
    pid/1,
    reg/2,
    dereg/1,
    node_up/1,
    node_down/1
]).

start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


send(PID, Msg) when erlang:is_pid(PID)->
    erlang:send(PID, Msg, [noconnect]);
send(undefined, _Msg) ->
    {error, process_undefined};
send(PID, Msg) ->
    case pid(PID) of
        ?UNDEFINED ->
            ?WARNING_MSG("PID not found : ~w", [PID]);
        _ ->
            erlang:send(pid(PID), Msg, [noconnect])
    end.

call(NameOrPID, Request) ->
    call(pid(NameOrPID), Request, ?CALL_TIMETOUT).

call(NameOrPID, Request, TimeOutMs) when is_integer(TimeOutMs) andalso TimeOutMs > 0 ->
    Res = (catch gen_server:call(pid(NameOrPID), {tl, TimeOutMs + time_tool:now_os() * 1000, Request}, TimeOutMs + 1000)),
    case Res of {'EXIT', {timeout, _}} -> ?ERROR_MSG("call [~w] info [~w] time out:[~w]", [NameOrPID, Request, Res]); _ -> ok end,
    Res;
call(NameOrPID, Request, infinity) ->
    catch gen_server:call(pid(NameOrPID), Request, infinity);
call(_NameOrPID, _Request, TimeOutMs) ->
    {error, {illegal_parameters, TimeOutMs}}.

pid(PID) when erlang:is_pid(PID) ->
    PID;
pid(PName) ->
    case erlang:whereis(PName) of
        PID when erlang:is_pid(PID) ->
            PID;
        _ ->
            case get_remote_pid(PName) of
                [#r_node_pid{pid = PID}] ->
                    PID;
                _ ->
                    undefined
            end
    end.

reg(PName, PID) ->
    info({reg, PName, PID}).

dereg(PName) ->
    info({dereg, PName}).

node_up(Node) ->
    info({nodeup, Node}).

node_down(Node) ->
    info({nodedown, Node}).

info(Info) ->
    pname_server:send(?MODULE, Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    ets:new(?ETS_REMOTE_PID, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_node_pid.pid_name}]),
    ets:new(?ETS_LOCAL_PID, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_node_pid.pid_name}]),
    do_gc(),
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

do_handle({nodeup, Node}) ->
    do_node_up(Node);
do_handle({nodedown, Node}) ->
    do_node_down(Node);
do_handle({remote_nodeup, Node, NodePIDList}) ->
    do_remote_node_up(Node, NodePIDList);
do_handle({reg, PName, PID}) ->
    do_reg(PName, PID);
do_handle({remote_reg, NodePID}) ->
    do_remote_reg(NodePID);
do_handle({dereg, PName}) ->
    do_dereg(PName);
do_handle({remote_dereg, PName}) ->
    do_remote_dereg(PName);
do_handle(gc) ->
    do_gc();
do_handle({mfa, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_node_up(Node) ->
    LocalList = ets:tab2list(?ETS_LOCAL_PID),
    node_msg_manager:send_msg_by_node(Node, ?MODULE, {remote_nodeup, erlang:node(), LocalList}).

do_node_down(Node) ->
    ets:match_delete(?ETS_REMOTE_PID, #r_node_pid{node = Node, _ = '_'}).

do_remote_node_up(Node, NodePIDList) ->
    do_node_down(Node),
    ets:insert(?ETS_REMOTE_PID, NodePIDList).

do_reg(PName, PID) ->
    NodePID = #r_node_pid{pid_name = PName, pid = PID, node = erlang:node()},
    set_local_pid(NodePID),
    node_msg_manager:send_all_msg(?MODULE, {remote_reg, NodePID}).

do_remote_reg(NodePID) ->
    set_remote_pid(NodePID).

do_dereg(PName) ->
    del_local_pid(PName),
    node_msg_manager:send_all_msg(?MODULE, {remote_dereg, PName}).

do_remote_dereg(PName) ->
    del_remote_pid(PName).

do_gc() ->
    %% 每天5点20分进行一次gc
    NextTime = time_tool:diff_next_hoursec(5, 20),
    erlang:send_after(NextTime * 1000, erlang:self(), gc),
    lib_sys:gc(102400).
%%%===================================================================
%%% data
%%%===================================================================
set_local_pid(NodePID) ->
    ets:insert(?ETS_LOCAL_PID, NodePID).
del_local_pid(PName) ->
    ets:delete(?ETS_LOCAL_PID, PName).

set_remote_pid(NodePID) ->
    ets:insert(?ETS_REMOTE_PID, NodePID).
get_remote_pid(PName) ->
    ets:lookup(?ETS_REMOTE_PID, PName).
del_remote_pid(PName) ->
    ets:delete(?ETS_REMOTE_PID, PName).
