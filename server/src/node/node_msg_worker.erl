%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     节点间异步消息派发
%%% @end
%%% Created : 26. 六月 2017 10:23
%%%-------------------------------------------------------------------
-module(node_msg_worker).
-author("laijichang").
-behaviour(gen_server).
-include("node.hrl").
-export([
    start_link/1,
    info/2,
    cast/3
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------

start_link(PIDName) ->
    gen_server:start_link({local, PIDName}, ?MODULE, [], []).

%% 本地调用
info(PName, Info) ->
    gen_server:cast(PName, Info).

cast(Node, PName, Info) ->
    gen_server:cast({PName, Node}, Info).
%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    set_loop_nodes([]),
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
    do_send_node(Node, Info);
do_handle({ack, _, _}) ->
    ok;
do_handle({seq, Node, MsgList}) ->
    [#r_msg_info{counter = MaxAck}|_] = lists:reverse(lists:keysort(#r_msg_info.counter, MsgList)),
    PName = node_msg_manager:get_remote_hash_pname(Node),
    cast(Node, PName, {ack, erlang:node(), MaxAck});
do_handle({send_msg, _Node, Info}) ->
    do_receive_info(Info);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_node_up(Node) ->
    add_loop_nodes(Node).

do_node_down(Node) ->
    del_loop_nodes(Node).

do_receive_info({mfa, {M, F, A}}) ->
    erlang:apply(M, F, A);
do_receive_info({info, ServerName, Msg}) ->
    erlang:send(erlang:whereis(ServerName), Msg);
do_receive_info(Info) ->
    ?ERROR_MSG("Unknow Info :~w", [Info]).

do_send_all(Info) ->
    Nodes = get_loop_nodes(),
    do_send_msg(Nodes, Info).
do_send_node(Node, Info) ->
    do_send_msg([Node], Info).

do_send_all_game_node(Info) ->
    Nodes = [ Node || Node <- get_loop_nodes(), common_config:is_game_node(Node)],
    do_send_msg(Nodes, Info).

do_send_msg([], _Info) ->
    ok;
do_send_msg([Node|R], Info) ->
    PName = node_msg_manager:get_remote_hash_pname(Node),
    ?TRY_CATCH(cast(Node, PName, {send_msg, erlang:node(), Info})),
    do_send_msg(R, Info).

%%%===================================================================
%%% dict
%%%===================================================================
add_loop_nodes(Node) ->
    set_loop_nodes([Node|lists:delete(Node, get_loop_nodes())]).
del_loop_nodes(Node) ->
    set_loop_nodes(lists:delete(Node, get_loop_nodes())).
set_loop_nodes(Nodes) ->
    erlang:put({?MODULE, loop_nodes}, Nodes).
get_loop_nodes() ->
    erlang:get({?MODULE, loop_nodes}).