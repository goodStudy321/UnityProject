-module(cfg_server).
-include("config.hrl").
-export([find/1]).
?CFG_H

%%%===================================================================
%%% game节点启动 start
%%%===================================================================
%% game节点启动对应的监控树
?C({game, sups}, [log_sup, db_sup, node_sup, map_sup, world_sup, gateway_sup, web_sup, role_sup])

?C({game, pre_stops}, [role_sup, map_sup, world_sup, node_sup])

%%game节点先启动其他server依赖的项
?C({game, pre_starts}, [
log,
{time_tool, start_server, [gate, gateway_sup, [1000]]},
{time_tool, start_server, [db, db_sup, [5000]]},
{time_tool, start_server, [map, map_sup, [100, 1000]]},
{time_tool, start_server, [role, server_sup, [0, hour_change, 1000]]},
{time_tool, start_server, [world, server_sup, [0, hour_change, 1000]]},
{time_tool, start_server, [node, server_sup, [5000]]},
{time_tool, start_server, [common, server_sup, [0, 1000, 3000]]},
db])

%% A -> A:start()
%% {A, B, C} -> MFA
%% game节点启动
?C({game, starts}, [
node_base,
node_msg_manager,
pname_server,

node_interchange_server,
map_branch_manager,
{ibrowse_sup, start_link, []},

login_server,
world_offline_event_server,
world_letter_server,
world_broadcast_server,
world_friend_server,
world_online_server,
world_mining_server,
world_activity_server,
family_server,
world_boss_server,
world_offline_solo_server, %% 机器人名字，组队进程需要
world_team_server,
world_act_server,
world_bg_act_server,
world_robot_server,
world_pay_server,
world_notice_server,
rank_server,
marry_server,
world_log_statistics_server,
world_pay_back_server,
world_chat_history_server,
family_escort_server,
world_auction_server,

background_log_server,
junhai_log_server,
game_topology_server,
world_cycle_act_server,
game_universe_server,

web,

gateway_tcp_client_sup,
gateway_networking
])

%%%===================================================================
%%% game节点启动 end
%%%===================================================================


%%%===================================================================
%%% 中央服点启动 start
%%%===================================================================
?C({center, sups}, [log_sup, db_sup, node_sup, world_sup, web_sup])

?C({center, pre_starts}, [
log,
{time_tool, start_server, [db, db_sup, [5000]]},
{time_tool, start_server, [node, server_sup, [5000]]},
{time_tool, start_server, [common, server_sup, [0, 1000]]},
{time_tool, start_server, [world, server_sup, [0, 1000]]},
db])

?C({center, starts}, [
node_base,
node_msg_manager,
pname_server,

node_interchange_server,
center_addict_server,
center_create_server,
center_topology_server,
center_universe_server,
center_cycle_act_server,

{ibrowse_sup, start_link, []},
web
])
%%%===================================================================
%%% 中央服点启动 end
%%%===================================================================


%%%===================================================================
%%% 跨服节点启动 start
%%%===================================================================
?C({cross, sups}, [log_sup, db_sup, node_sup, map_sup, world_sup, web_sup])
?C({cross, pre_stops}, [map_sup, world_sup, node_sup])

?C({cross, pre_starts}, [
log,
{time_tool, start_server, [db, db_sup, [5000]]},
{time_tool, start_server, [map, map_sup, [100, 1000]]},
{time_tool, start_server, [node, server_sup, [5000]]},
{time_tool, start_server, [common, server_sup, [0, 1000]]},
{time_tool, start_server, [world, server_sup, [0, 1000]]},
db])

?C({cross, starts}, [
node_base,
node_msg_manager,
pname_server,

node_interchange_server,

cross_role_data_server,

map_branch_manager,
background_log_server,
world_boss_server,
cross_activity_server,
family_escort_cross_server,

{ibrowse_sup, start_link, []},
web
])
%%%===================================================================
%%% 跨服节点启动 end
%%%===================================================================

?CFG_E.
