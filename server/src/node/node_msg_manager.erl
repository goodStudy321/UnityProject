%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     节点间异步消息管理
%%% @end
%%% Created : 26. 六月 2017 10:23
%%%-------------------------------------------------------------------
-module(node_msg_manager).
-author("laijichang").
-behaviour(gen_server).
-include("node.hrl").

%% API
-export([
    node_up/1,
    node_down/1
]).

-export([
    start/0,
    start_link/0,
    info/1
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    send_all_msg/2,
    send_msg_by_node/3,
    send_all/1,
    send_all_game_node/1,
    send_node/2
]).

-export([
    get_local_hash_pname/1,
    get_remote_hash_pname/1
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

node_up(Node) ->
    info({nodeup, Node}).

node_down(Node) ->
    info({nodedown, Node}).

info(Info) ->
    pname_server:send(?MODULE, Info).

%% 发送给当前连接的节点
send_all(Info) ->
    info({send_all, Info}).

%% 发送给当前连接的game节点
send_all_game_node(Info) ->
    info({send_all_game_node, Info}).

%% 发送给指定节点
send_node(Node, Info) ->
    info({send_node, Node, Info}).

%% 给所有节点的指定进程发送消息
send_all_msg(Mod, Msg) ->
    send_all({info, Mod, Msg}).

%% 给特定节点的进程发送消息
send_msg_by_node(Node, Server, Msg) ->
    send_node(Node, {info, Server, Msg}).

%% 本地发送消息时获取的PName
get_local_hash_pname(RemoteNode) ->
    case erlang:get({?MODULE, local_hash_pname, RemoteNode}) of
        undefined ->
            case common_config:is_game_node() of
                true ->
                    Index = 1;
                _ ->
                    Index = erlang:phash(RemoteNode, ?MSG_WORKER_NUM)
            end,
            PName = get_worker_name(Index),
            erlang:put({?MODULE, local_hash_pname, RemoteNode}, PName),
            PName;
        PName ->
            PName
    end.

%% 发送消息到远端时获取的PName
get_remote_hash_pname(RemoteNode) ->
    case erlang:get({?MODULE, remote_hash_pname, RemoteNode}) of
        undefined ->
            case common_config:is_game_node(RemoteNode) of
                true ->
                    Index = 1;
                _ ->
                    Index = erlang:phash(erlang:node(), ?MSG_WORKER_NUM)
            end,
            PName = get_worker_name(Index),
            erlang:put({?MODULE, remote_hash_pname, RemoteNode}, PName),
            PName;
        PName ->
            PName
    end.

get_worker_name(Index) ->
    lib_tool:to_atom(lists:concat(["node_msg_worker_", Index])).

%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    WorkerNum = ?IF(common_config:is_game_node(), 1, ?MSG_WORKER_NUM),
    PIDList =
        [ begin
              PName = get_worker_name(Index),
              {ok, PID} = node_msg_worker:start_link(PName),
              PID
          end || Index <- lists:seq(1, WorkerNum)],
    set_all_workers(PIDList),
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
do_handle({send_all, Info}) ->
    do_send_all(Info);
do_handle({send_all_game_node, Info}) ->
    do_send_all_game_node(Info);
do_handle({send_node, Node, Info}) ->
    do_send_node_msg(Node, Info);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_node_up(Node) ->
    PName = get_local_hash_pname(Node),
    node_msg_worker:info(PName, {nodeup, Node}).

do_node_down(Node) ->
    PName = get_local_hash_pname(Node),
    node_msg_worker:info(PName, {nodedown, Node}).

do_send_all(Info) ->
    [ node_msg_worker:info(Worker, {send_all, Info}) || Worker <- get_all_workers()].

do_send_all_game_node(Info) ->
    [ node_msg_worker:info(Worker, {send_all_game_node, Info}) || Worker <- get_all_workers()].

do_send_node_msg(Node, Info) ->
    PName = get_local_hash_pname(Node),
    node_msg_worker:info(PName, {send_node, Node, Info}).
%%%===================================================================
%%% dict
%%%===================================================================

set_all_workers(PIDList) ->
    erlang:put({?MODULE, all_workers}, PIDList).
get_all_workers() ->
    erlang:get({?MODULE, all_workers}).