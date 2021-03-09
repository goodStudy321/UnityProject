%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 六月 2017 11:28
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(NODE_HRL).
-define(NODE_HRL, node_hrl).
-include("global.hrl").

-define(REG_INTERVAL, 5000).    %% 断掉重连的间隔
-define(MSG_INTERVAL, 5000).    %% MSG loop用的间隔

-define(MSG_WORKER_NUM, 20).    %% 跨服节点消息进程的数量

-define(ETS_NODE, ets_node).            %% 节点ETS
-define(ETS_KEY_NODE, ets_key_node).    %% 节点key值
-define(ETS_REMOTE_PID, ets_remote_pid).    %% 其他节点同步的PID
-define(ETS_LOCAL_PID, ets_local_pid).      %% 本地需要同步的PID
-define(ETS_MERGE_SERVER, ets_merge_server).%% 合服关系映射

-define(INTERCHANGE_CROSS_OBSERVE, 1).      %% 跨服观察

-define(ROLE_CROSS_LEVEL, 350).     %% 角色可以跨服的等级

-define(TOPOLOGY_REGION_INDEX, 10000).  %% 地域 + 版本偏移值

-define(TOPOLOGY_STATUS_INIT, 1).       %% 初始化、群发消息拉取数据
-define(TOPOLOGY_STATUS_GET_DATA, 2).   %% 获取数据阶段、超过xS 节点没有发送数据上来的，再次推送拉取消息
-define(TOPOLOGY_STATUS_MATCH, 3).      %% 所有数据准备完毕 -> 匹配
-define(TOPOLOGY_STATUS_PUSH, 4).       %% 推送

%% node_name    节点名
%% node_id      AgentID * 100000 + ServerID
%% public_ip    公网IP
-record(r_connect_node, {node_name, node_id, ip="", public_ip=""}).

%% 映射
-record(r_key_node, {node_id, node_name}).

-record(r_node_pid, {pid_name, pid, node}).

%% Key = {AgentID, ServerID} -> MergeServerID
-record(r_merge_server, {agent_server_key, merge_server_id}).

%% 中转参数
%% from_node_key    ---- 来源于哪个节点
%% to_node_key      ---- 发往特定节点
%% id               ---- 消息类型
%% to_args          ---- 对应节点处理时需要用到的参数
%% call_back_args   ---- 回调时调用的参数
%% call_back_info   ---- 对方回应的内容
-record(r_interchange_args, {
    from_node_key,
    to_node_key,
    id,
    to_args,
    call_back_args,
    call_back_info
}).

%% world_data存储
-record(r_center_topology_args, {
    last_match_time = 0,
    is_send_letter = false,
    broadcast_min_list = []
}).

%% 匹配状态
-record(r_center_topology_status, {
    status,                 %% 当前状态
    next_status_time,       %% 下一个状态时间
    game_list               %% 游戏服状态列表
}).

%% 游戏服节点信息
-record(r_game_topology_info, {
    node_id,        %% 节点ID
    public_ip,      %% 公网IP
    open_days,      %% 开服天数
    power           %% 战力
}).

%% 跨服节点信息
-record(r_cross_topology_info, {
    node_id,        %% 节点ID
    ip,             %% 内网IP
    public_ip       %% 公网IP
}).

%% 跨服服务器分组
-record(r_cross_topology_region, {
    region_id,      %% 地域ID + VersionID * 10000
    cross_list      %% 跨服节点列表
}).

%% 游戏节点分组
-record(r_game_topology_region, {
    region_id,      %% 地域ID + VersionID * 10000
    game_group_list %% [#r_game_topology_group{}|....]
}).

-record(r_game_topology_group, {
    group_id,
    match_num,      %% 几几分组
    server_num_list,%% 分组数量大小分布
    game_list       %% 游戏服节点
}).

%% ip区域结构
-record(r_ip_region, {
    ip,
    region_id
}).

-endif.
