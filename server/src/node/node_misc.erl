%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     全节点调用
%%% @end
%%% Created : 22. 二月 2019 9:50
%%%-------------------------------------------------------------------
-module(node_misc).
-author("laijichang").
-include("node.hrl").

%% API
%% 全节点通用API
-export([
    is_cross_node_id/1,
    is_game_node_id/1,
    is_center_node_id/1,

    get_node_id/0,
    get_node_id_by_agent_server_id/2,
    get_node_id_by_role_id/1,
    get_agent_server_id_by_node_id/1,
    get_node_name_by_node_id/1,

    is_cross_node_key/1,
    is_center_node_key/1,

    get_node_key/0,
    get_node_key_by_agent_server_id/2,
    get_node_key_by_role_id/1,
    get_center_node_key/0
]).

%% game节点调用
-export([
    game_get_cross_node_key/0,
    game_send_mfa_to_cross/1,
    game_send_mfa_to_center/1,
    game_get_cross_node/0,
    game_get_cross_node/2
]).

%% cross节点调用
-export([
    cross_send_mfa_to_all_game_node/1,
    cross_send_mfa_by_role_id/2
]).

%% center节点调用
-export([
    center_send_mfa_to_all_game_node/1,
    center_send_server_info_to_all_game_node/2
]).

%% cross、center节点调用
-export([
    send_mfa_to_game_node_by_node_id/2
]).

is_cross_node_id(NodeID) ->
    {_AgentID, ServerID} = get_agent_server_id_by_node_id(NodeID),
    common_config:is_cross_server_id(ServerID).

is_game_node_id(NodeID) ->
    {_AgentID, ServerID} = get_agent_server_id_by_node_id(NodeID),
    common_config:is_game_server_id(ServerID).

is_center_node_id(NodeID) ->
    {_AgentID, ServerID} = get_agent_server_id_by_node_id(NodeID),
    common_config:is_center_id(ServerID).

%% node_id | int
get_node_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    get_node_id_by_agent_server_id(AgentID, ServerID).

get_node_id_by_agent_server_id(AgentID, ServerID) ->
    (AgentID * ?MAX_SERVER_ID) + ServerID.

get_node_id_by_role_id(RoleID) ->
    {AgentID, ServerID} = common_id:get_agent_server_id(RoleID),
    case node_data:get_merge_server(AgentID, ServerID) of
        #r_merge_server{merge_server_id = MergeServerID} ->
            get_node_id_by_agent_server_id(AgentID, MergeServerID);
        _ ->
            RoleID div ?MAX_ROLE_NUM
    end.

get_agent_server_id_by_node_id(NodeID) ->
    {NodeID div ?MAX_SERVER_ID, NodeID rem ?MAX_SERVER_ID}.

get_node_name_by_node_id(NodeID) ->
    case node_base:get_key_node(NodeID) of
        [#r_key_node{node_name = NodeName}] ->
            NodeName;
        _ ->
            undefined
    end.

%% 是否跨服key
is_cross_node_key(NodeKey) ->
    is_cross_node_id(lib_tool:to_integer(NodeKey)).

is_center_node_key(NodeKey) ->
    is_center_node_id(lib_tool:to_integer(NodeKey)).

%% node_key | atom
get_node_key() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    get_node_key_by_agent_server_id(AgentID, ServerID).

get_node_key_by_agent_server_id(AgentID, ServerID) ->
    lib_tool:to_atom(get_node_id_by_agent_server_id(AgentID, ServerID)).

get_node_key_by_role_id(RoleID) ->
    lib_tool:to_atom(get_node_id_by_role_id(RoleID)).

get_center_node_key() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_center_server_id(),
    get_node_key_by_agent_server_id(AgentID, ServerID).
%%%===================================================================
%%% game 节点调用 start
%%%===================================================================
game_get_cross_node_key() ->
    AgentID = common_config:get_agent_id(),
    CrossID = global_data:get_cross_server_id(),
    get_node_key_by_agent_server_id(AgentID, CrossID).

%% {M, F, A}
game_send_mfa_to_cross(MFA) ->
    node_msg_manager:send_node(game_get_cross_node(), {mfa, MFA}).

game_send_mfa_to_center(MFA) ->
    node_msg_manager:send_node(common_config:get_center_node(), {mfa, MFA}).

game_get_cross_node() ->
    ServerID = global_data:get_cross_server_id(),
    IP = global_data:get_cross_server_ip(),
    game_get_cross_node(ServerID, IP).
game_get_cross_node(ServerID, IP) ->
    lib_tool:to_atom(lists:concat([common_config:get_game_code(), "_", "cross", "_", ServerID, "@", IP])).
%%%===================================================================
%%% game 节点调用 end
%%%===================================================================


%%%===================================================================
%%% cross 节点调用 start
%%%===================================================================
%% {M, F, A}
cross_send_mfa_to_all_game_node(MFA) ->
    node_msg_manager:send_all_game_node({mfa, MFA}).

cross_send_mfa_by_role_id(RoleID, MFA) ->
    Node = get_node_name_by_node_id(get_node_id_by_role_id(RoleID)),
    node_msg_manager:send_node(Node, {mfa, MFA}).
%%%===================================================================
%%% cross 节点调用 end
%%%===================================================================



%%%===================================================================
%%% cross 节点调用 start
%%%===================================================================
%% {M, F, A}
center_send_mfa_to_all_game_node(MFA) ->
    node_msg_manager:send_all_game_node({mfa, MFA}).

center_send_server_info_to_all_game_node(Server, Msg) ->
    node_msg_manager:send_all_game_node({info, Server, Msg}).
%%%===================================================================
%%% cross 节点调用 end
%%%===================================================================

send_mfa_to_game_node_by_node_id(NodeID, MFA) ->
    Node = get_node_name_by_node_id(NodeID),
    node_msg_manager:send_node(Node, {mfa, MFA}).