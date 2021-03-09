%%%-------------------------------------------------------------------
%%% @Description : 节点管理
%%%-------------------------------------------------------------------
-module(node_base).
-behaviour(gen_server).
-include("global.hrl").
-include("node.hrl").
-include("common_records.hrl").

%% export for all
-export([
    start/0,
    stop/0,
    start_link/0
]).

-export([
    is_node_connected/1
]).

%%node_base only
-export([
    register/1
]).

%%export for mod/node_*.erl
-export([
    subscription/0,
    subscription/1,
    set_cookie/2,
    node_up/1,
    node_down/1
]).

-export([
    call/1,
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
    set_node/1,
    get_all_node/0,
    get_node/1,
    del_node/1,
    get_key_node/1
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

stop() ->
    pname_server:call(?MODULE, stop).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

register(ConnectNode) ->
    call({register, ConnectNode}).


call(Request) ->
    pname_server:call(?MODULE, Request).

info(Request) ->
    pname_server:send(?MODULE, Request).

%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    ServerType = common_config:get_server_type(),
    Mod = list_to_atom("node_"++lib_tool:to_list(ServerType)),
    set_mod(Mod),
    lib_tool:init_ets(?ETS_NODE, #r_connect_node.node_name),
    lib_tool:init_ets(?ETS_KEY_NODE, #r_key_node.node_id),
    lib_tool:init_ets(?ETS_MERGE_SERVER, #r_merge_server.agent_server_key),
    Mod:init(),
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

terminate(Reason, _State) ->
    common(terminate, Reason),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

is_node_connected(Node) ->
    case get_node(Node) of
        [#r_connect_node{}] ->
            true;
        _ ->
            false
    end.
%%%-------------------------------------------------------------------
%%% internal functions
%%%-------------------------------------------------------------------
do_handle({register, ConnectNode}) ->
    node_up(ConnectNode),
    ok;
do_handle({nodeup, Node, InfoList}) -> %% 节点连接调用，由自己手动调用
    ?INFO_MSG("nodeup: ~w, InfoList: ~w", [Node, InfoList]);
do_handle({nodedown, Node, _InfoList}) ->
    ?INFO_MSG("nodedown: ~w", [Node]),
    node_down(Node);
do_handle({mfa, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    common(do_handle, Info).

common(Fun, Args) ->
    Mod = get_mod(),
    case erlang:function_exported(Mod, Fun, 1) of
        true ->
            Mod:Fun(Args);
        _ ->
            ok
    end.

subscription() ->
    subscription([{node_type, hidden}, nodedown_reason]).

subscription(Options) ->
    %%先取消再订阅，防止调用N次订阅，收到N次 nodeup 和 nodedown 消息
    net_kernel:monitor_nodes(false, Options),
    net_kernel:monitor_nodes(true, Options).

set_cookie(Node, Cookie) ->
    erlang:set_cookie(Node, Cookie).

node_up(#r_connect_node{node_name = NodeName, node_id = NodeID} = ConnectNode) ->
    set_node(ConnectNode),
    set_key_node(NodeID, NodeName),
    common_node_up(NodeName);
node_up(NodeName) when erlang:is_atom(NodeName) -> %% 兼容处理
    node_up(#r_connect_node{node_name = NodeName}).

node_down(NodeName) ->
    del_node(NodeName),
    del_key_node(NodeName),
    common_node_down(NodeName).

common_node_up(Node) ->
    case is_normal_node(Node) of
        true ->
            FunList =
                [
                    fun() -> common(node_up, Node) end,
                    fun() -> node_msg_manager:node_up(Node) end,
                    fun() -> pname_server:node_up(Node) end
                ],
            [ ?TRY_CATCH(Func()) || Func <- FunList];
        _ ->
            ok
    end.

common_node_down(Node) ->
    case is_normal_node(Node) of
        true ->
            FunList =
                [
                    fun() -> node_msg_manager:node_down(Node) end,
                    fun() -> pname_server:node_down(Node) end,
                    fun() -> common(node_down, Node) end
                ],
            [ ?TRY_CATCH(Func()) || Func <- FunList];
        _ ->
            ok
    end.

is_normal_node(Node) ->
    NodeString = lib_tool:to_list(Node),
    GameCode = common_config:get_game_code(),
    string:str(NodeString, GameCode) > 0.
%%%-------------------------------------------------------------------
%%% Data
%%%-------------------------------------------------------------------
set_node(ConnectNode) ->
    ets:insert(?ETS_NODE, ConnectNode).
get_all_node() ->
    ets:tab2list(?ETS_NODE).
get_node(Node) ->
    ets:lookup(?ETS_NODE, Node).
del_node(Node) ->
    ets:delete(?ETS_NODE, Node).

set_key_node(NodeID, NodeName) when erlang:is_integer(NodeID) ->
    NodeKey = #r_key_node{node_id = NodeID, node_name = NodeName},
    ets:insert(?ETS_KEY_NODE, NodeKey);
set_key_node(_NodeID, _NodeName) ->
    ignore.
get_key_node(Key) ->
    ets:lookup(?ETS_KEY_NODE, Key).
del_key_node(NodeName) ->
    ets:match_delete(?ETS_KEY_NODE, #r_key_node{node_name = NodeName, _ = '_'}).

set_mod(Mod) ->
    erlang:put({?MODULE, mod}, Mod).
get_mod() ->
    erlang:get({?MODULE, mod}).