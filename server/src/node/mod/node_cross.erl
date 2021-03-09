-module(node_cross).
-include("global.hrl").
-include("node.hrl").
-include("common_records.hrl").

-export([
    init/0,
    terminate/1,
    do_handle/1
]).

init() ->
    time_tool:reg(node, [5000]),
    node_base:subscription().

terminate(_Reason) ->
    time_tool:dereg(node, [5000]),
    ok.

do_handle({loop_msec, _NowMs}) ->
    update_node();
do_handle({register, _Node}) ->
    ok;
do_handle(Info) ->
    ?ERROR_MSG("unknown info: ~p", [Info]).

update_node() ->
    CenterID = common_config:get_center_server_id(),
    CenterIP = common_config:get_center_ip(),
    CenterNode = common_config:get_center_node(CenterID, CenterIP),
    case node_base:get_node(CenterNode) of
        [#r_connect_node{}] ->
            ok;
        _ ->
            AllNodes = node_base:get_all_node(),
            [ begin
                  net_kernel:disconnect(OldNode),
                  node_base:del_node(OldNode)
              end|| #r_connect_node{node_name = OldNode} <- AllNodes, common_config:is_center_node(OldNode)],
            MyNode = erlang:node(),
            AgentID = common_config:get_agent_id(),
            ServerID = common_config:get_server_id(),
            IP = common_config:get_server_ip(),
            PublicIP = common_config:get_server_public_ip(),
            NodeInfo = #r_connect_node{
                node_name = MyNode,
                node_id = node_misc:get_node_id_by_agent_server_id(AgentID, ServerID),
                ip = IP,
                public_ip = PublicIP
            },
            case rpc:call(CenterNode, node_base, register, [NodeInfo]) of
                ok ->
                    CenterNodeInfo = #r_connect_node{
                        node_name = CenterNode,
                        node_id = node_misc:get_node_id_by_agent_server_id(AgentID, CenterID),
                        ip = CenterIP,
                        public_ip = CenterIP},
                    node_base:node_up(CenterNodeInfo);
                Error ->
                    ?INFO_MSG("connect Node :~w, Error: ~w", [CenterNode, Error])
            end
    end.

