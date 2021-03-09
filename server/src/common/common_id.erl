-module(common_id).

-include("global.hrl").

%% API
-export([
    get_start_role_id/0,
    get_monster_start_id/1,
    get_monster_next_id/1,
    get_collection_start_id/1,
    get_collection_nex_id/1,
    get_trap_start_id/1,
    get_trap_next_id/1,
    get_drop_start_id/1,
    get_drop_next_id/1,
    get_robot_start_id/1,
    get_robot_next_id/1,
    get_background_start_id/0,
    get_background_next_id/1,
    get_background_log_start_id/0,
    get_background_log_next_id/1,
    get_family_start_id/0,
    get_family_next_id/1,
    get_team_start_id/0,
    get_team_next_id/1,
    get_junhai_gold_log_start_id/0,
    get_junhai_gold_log_next_id/1,
    get_pay_start_id/0,
    get_pay_next_id/1,
    get_auction_start_id/0,
    get_auction_next_id/1
]).

-export([
    get_agent_server_id/1
]).

%%%===================================================================
%%% API
%%%===================================================================
-define(MAX_ELEMENT_NUM,1000000).
-define(MONSTER_MAX_ELEMENT_NUM, 100000).
-define(COLLECTION_MAX_ELEMENT_NUM, 200000).
-define(TRAP_MAX_ELEMENT_NUM, 300000).
-define(DROP_MAX_ELEMENT_NUM, 400000).
-define(ROBOT_MAX_ELEMENT_NUM, 500000).

%% 角色初始id
get_start_role_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ((AgentID * ?MAX_SERVER_ID) + ServerID) *?MAX_ROLE_NUM.

%% 怪物id xxxxx[0]000000
get_monster_start_id(MapID)->
    (MapID * 10 + 0) * ?MAX_ELEMENT_NUM.

get_monster_next_id(ID)->
    get_cycle_next_id(ID, ?MONSTER_MAX_ELEMENT_NUM).

%% 采集物id xxxxx[1]000000
get_collection_start_id(MapID) ->
    (MapID * 10 + 1) * ?MAX_ELEMENT_NUM.

get_collection_nex_id(ID) ->
    get_cycle_next_id(ID, ?COLLECTION_MAX_ELEMENT_NUM).

%% 召唤体id xxxxx[2]000000
get_trap_start_id(MapID) ->
    (MapID * 10 + 2) * ?MAX_ELEMENT_NUM.

get_trap_next_id(ID) ->
    get_cycle_next_id(ID, ?TRAP_MAX_ELEMENT_NUM).

%% 掉落物id xxxxx[3]000000
get_drop_start_id(MapID) ->
    (MapID * 10 + 3) * ?MAX_ELEMENT_NUM.

get_drop_next_id(ID) ->
    get_cycle_next_id(ID, ?DROP_MAX_ELEMENT_NUM).

get_robot_start_id(MapID) ->
    (MapID * 10 + 4) * ?MAX_ELEMENT_NUM.

get_robot_next_id(ID) ->
    get_cycle_next_id(ID, ?ROBOT_MAX_ELEMENT_NUM).

get_background_start_id() ->
    1.

get_background_next_id(LastID) ->
    LastID + 1.

%% 获取background_log_log的id
get_background_log_start_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ?MAX_AGENT_ID * ?MAX_SERVER_ID + ((AgentID *  ?MAX_SERVER_ID) + ServerID).

get_background_log_next_id(LastID) ->
    LastID + ?MAX_AGENT_ID * ?MAX_SERVER_ID.

%% 获取仙盟的id
get_family_start_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ?MAX_AGENT_ID * ?MAX_SERVER_ID + ((AgentID *  ?MAX_SERVER_ID) + ServerID).

get_family_next_id(LastID) ->
    LastID + ?MAX_AGENT_ID * ?MAX_SERVER_ID.

%% 获取junhai_gold_log的id
get_junhai_gold_log_start_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ?MAX_AGENT_ID * ?MAX_SERVER_ID + ((AgentID *  ?MAX_SERVER_ID) + ServerID).

get_junhai_gold_log_next_id(LastID) ->
    LastID + ?MAX_AGENT_ID * ?MAX_SERVER_ID.

%% 获取初始的组队id
get_team_start_id() ->
    ServerID = common_config:get_server_id(),
    ?MAX_SERVER_ID + ServerID.

get_team_next_id(LastID) ->
    LastID + ?MAX_SERVER_ID.

get_pay_start_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ?MAX_AGENT_ID * ?MAX_SERVER_ID + ((AgentID *  ?MAX_SERVER_ID) + ServerID).

get_pay_next_id(LastID) ->
    LastID + ?MAX_AGENT_ID * ?MAX_SERVER_ID.

get_auction_start_id() ->
    AgentID = common_config:get_agent_id(),
    ServerID = common_config:get_server_id(),
    ?MAX_AGENT_ID * ?MAX_SERVER_ID + ((AgentID *  ?MAX_SERVER_ID) + ServerID).

get_auction_next_id(LastID) ->
    LastID + ?MAX_AGENT_ID * ?MAX_SERVER_ID.

%% ===== 循环使用id =====
%% ID 当前id
%% MaxOffsetNum 最大偏移值
%% 当前id是否即将超过偏移值（不允许等于偏移值）,如果等于偏移值,则清除偏移值,重新计算
get_cycle_next_id(ID, MaxOffsetNum)->
    case ID rem MaxOffsetNum >= MaxOffsetNum - 1  of
        true ->
            ID div MaxOffsetNum * MaxOffsetNum + 1;
        false ->
            ID+1
    end.
%% ===== 获取id中的信息

get_agent_server_id(RoleID) ->
    IndexID = RoleID div ?MAX_ROLE_NUM,
    {IndexID div ?MAX_SERVER_ID, IndexID rem ?MAX_SERVER_ID}.