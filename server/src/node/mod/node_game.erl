-module(node_game).
-include("node.hrl").
-include("common_records.hrl").
-include("proto/mod_role_node.hrl").

-export([
    init/0,
    terminate/1,
    node_up/1,
    node_down/1,
    do_handle/1
]).

%%-------------------init/terminate---------------
init() ->
    time_tool:reg(node, [5000]),
    node_base:subscription().

terminate(_Reason) ->
    time_tool:dereg(node, [5000]),
    ok.

node_up(Node) ->
    FunList = [
        fun() -> do_node_status(Node, true) end,
        fun() -> game_universe_server:node_up(Node) end,
        fun() -> act_couple:node_up(Node) end
    ],
    [ ?TRY_CATCH(Func()) || Func <- FunList].

node_down(Node) ->
    do_node_status(Node, false).

do_handle({loop_msec, _NowMs}) ->
    update_node();
do_handle(Info) ->
    ?ERROR_MSG("unknown info: ~p", [Info]).

do_node_status(Node, IsConnected) ->
    case common_config:is_cross_node(Node) of
        true ->
            DataRecord = #m_cross_status_toc{is_connected = IsConnected, next_match_time = global_data:get_cross_next_match_time()},
            common_broadcast:bc_record_to_world(DataRecord),
            ?IF(IsConnected =:= false, common_broadcast:bc_role_info_to_world({mod, mod_role_map, cross_disconnect}), ok);
        _ ->
            ok
    end.

update_node() ->
    Nodes = node_base:get_all_node(),
    {ConnectNodes, DelNodes} = update_node2(Nodes, get_connect_nodes(), [], []),
    [ begin
          node_base:del_node(OldNode),
          net_kernel:disconnect(OldNode)
      end|| OldNode <- DelNodes],
    Node = erlang:node(),
    case ConnectNodes =/= [] of
        true ->
            AgentID = common_config:get_agent_id(),
            ServerID = common_config:get_server_id(),
            IP = common_config:get_server_ip(),
            PublicIP = common_config:get_server_public_ip(),
            NodeInfo = get_connect_node_info(Node, AgentID, ServerID, IP, PublicIP),
            [ begin
                  case rpc:call(ConnectNodeName, node_base, register, [NodeInfo]) of
                      ok ->
                          node_base:node_up(ConnectNode);
                      Error ->
                          ?INFO_MSG("connect Node :~w, Error: ~w", [ConnectNode, Error])
                  end
              end || #r_connect_node{node_name = ConnectNodeName} = ConnectNode <- ConnectNodes];
        _ ->
            ok
    end.

update_node2([], ConfigNodes, ConnectAcc, DelAcc) ->
    {ConfigNodes ++ ConnectAcc, DelAcc};
update_node2([ConnectNode|R], ConfigNodes, ConnectAcc, DelAcc) ->
    #r_connect_node{node_name = NodeName} = ConnectNode,
    case lists:keytake(NodeName, #r_connect_node.node_name, ConfigNodes) of
        {value, #r_connect_node{}, ConfigNodes2} ->
            update_node2(R, ConfigNodes2, ConnectAcc, DelAcc);
        _ ->
            DelAcc2 = [NodeName|DelAcc],
            update_node2(R, ConfigNodes, ConnectAcc, DelAcc2)
    end.

get_connect_nodes() ->
    AgentID = common_config:get_agent_id(),
    CrossServerID = global_data:get_cross_server_id(),
    ConnectNodes1 =
        case common_config:is_cross_server_id(CrossServerID) of
            true ->
                CrossIP = global_data:get_cross_server_ip(),
                CrossNode = node_misc:game_get_cross_node(CrossServerID, CrossIP),
                [get_connect_node_info(CrossNode, AgentID, CrossServerID, CrossIP, CrossIP)];
            _ ->
                []
        end,
    CenterID = common_config:get_center_server_id(),
    CenterIP = common_config:get_center_ip(),
    CenterNode = common_config:get_center_node(CenterID, CenterIP),
    [get_connect_node_info(CenterNode, AgentID, CenterID, CenterIP, CenterIP)|ConnectNodes1].

get_connect_node_info(Node, AgentID, ServerID, IP, PublicIP) ->
    #r_connect_node{
        node_name = Node,
        node_id = node_misc:get_node_id_by_agent_server_id(AgentID, ServerID),
        ip = IP,
        public_ip = PublicIP
    }.
