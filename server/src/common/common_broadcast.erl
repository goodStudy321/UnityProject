%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     通用广播接口
%%% @end
%%% Created : 19. 七月 2017 10:15
%%%-------------------------------------------------------------------
-module(common_broadcast).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    bc_record_to_world/1,
    bc_record_to_family/2,
    bc_record_to_team/2,
    bc_record_to_area/1,
    bc_record_to_roles/2,

    bc_delay_record_to_world/2,

    bc_record_to_world_by_condition/2,
    bc_delay_record_to_world_by_condition/3,
    bc_record_to_family_by_condition/3,
    bc_record_to_roles_by_condition/3,

    bc_role_info_to_world/1,
    bc_role_info_to_family/2,
    bc_role_info_to_team/2,
    bc_role_info_to_area/1,
    bc_role_info_to_roles/2,

    bc_top_record_to_family/2,
    bc_del_top_record_to_family/1
]).

-export([
    send_world_common_notice/2,
    send_world_common_notice/3,
    send_delay_world_common_notice/3,
    send_delay_world_common_notice/4,
    send_family_common_notice/3,
    send_family_common_notice/4,
    send_roles_common_notice/3,
    send_roles_common_notice/4,
    send_team_common_notice/3,
    send_team_common_notice/4
]).

bc_record_to_world(DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_WORLD, 0}, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_world, [DataRecord]})
    end.
bc_record_to_family(FamilyID, DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_FAMILY, FamilyID}, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_family, [FamilyID, DataRecord]})
    end.
bc_record_to_team(TeamID, DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_TEAM, TeamID}, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_team, [TeamID, DataRecord]})
    end.
bc_record_to_area(DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_CROSS_AREA, 0}, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_area, [DataRecord]})
    end.
bc_record_to_roles(RoleList, DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg_by_roles(RoleList, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_roles, [RoleList, DataRecord]})
    end.

bc_delay_record_to_world(Delay, DataRecord) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_delay_msg(Delay, {?CHANNEL_WORLD, 0}, {?BROADCAST_RECORD, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_delay_record_to_world, [Delay, DataRecord]})
    end.

bc_record_to_world_by_condition(DataRecord, Condition) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_WORLD, 0}, {?BROADCAST_RECORD, Condition, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_world_by_condition, [DataRecord, Condition]})
    end.
bc_delay_record_to_world_by_condition(Second, DataRecord, Condition) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_delay_msg(Second, {?CHANNEL_WORLD, 0}, {?BROADCAST_RECORD, Condition, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_delay_record_to_world_by_condition, [Second, DataRecord, Condition]})
    end.
bc_record_to_family_by_condition(FamilyID, DataRecord, Condition) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_FAMILY, FamilyID}, {?BROADCAST_RECORD, Condition, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_family_by_condition, [FamilyID, DataRecord, Condition]})
    end.
bc_record_to_roles_by_condition(Roles, DataRecord, Condition) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg_by_roles(Roles, {?BROADCAST_RECORD, Condition, DataRecord});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_record_to_roles_by_condition, [Roles, DataRecord, Condition]})
    end.

bc_role_info_to_world(Info) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_WORLD, 0}, {?BROADCAST_TO_ROLE, Info});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_role_info_to_world, [Info]})
    end.
bc_role_info_to_family(FamilyID, Info) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_FAMILY, FamilyID}, {?BROADCAST_TO_ROLE, Info});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_role_info_to_family, [FamilyID, Info]})
    end.
bc_role_info_to_team(TeamID, Info) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_TEAM, TeamID}, {?BROADCAST_TO_ROLE, Info});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_role_info_to_team, [TeamID, Info]})
    end.
bc_role_info_to_area(Info) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg({?CHANNEL_CROSS_AREA, 0}, {?BROADCAST_TO_ROLE, Info});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_role_info_to_area, [Info]})
    end.
bc_role_info_to_roles(RoleList, Info) ->
    case common_config:is_game_node() of
        true ->
            world_broadcast_server:broadcast_msg_by_roles(RoleList, {?BROADCAST_TO_ROLE, Info});
        _ ->
            node_misc:cross_send_mfa_to_all_game_node({?MODULE, bc_role_info_to_roles, [RoleList, Info]})
    end.

send_world_common_notice(ID, StringList) ->
    send_world_common_notice(ID, StringList, []).
send_world_common_notice(ID, StringList, GoodsList) ->
    {DataRecord, Condition} = get_common_notice_info(ID, StringList, GoodsList),
    bc_record_to_world_by_condition(DataRecord, Condition).

send_delay_world_common_notice(Delay, ID, StringList) ->
    send_delay_world_common_notice(Delay, ID, StringList, []).
send_delay_world_common_notice(Delay, ID, StringList, GoodsList) ->
    {DataRecord, Condition} = get_common_notice_info(ID, StringList, GoodsList),
    bc_delay_record_to_world_by_condition(Delay, DataRecord, Condition).

send_family_common_notice(FamilyID, ID, StringList) ->
    send_family_common_notice(FamilyID, ID, StringList, []).
send_family_common_notice(FamilyID, ID, StringList, GoodsList) ->
    {DataRecord, Condition} = get_common_notice_info(ID, StringList, GoodsList),
    bc_record_to_family_by_condition(FamilyID, DataRecord, Condition).

send_roles_common_notice(Roles, ID, StringList) ->
    send_roles_common_notice(Roles, ID, StringList, []).
send_roles_common_notice(Roles, ID, StringList, GoodsList) ->
    {DataRecord, Condition} = get_common_notice_info(ID, StringList, GoodsList),
    bc_record_to_roles_by_condition(Roles, DataRecord, Condition).

send_team_common_notice(TeamID, ID, StringList) ->
    send_team_common_notice(TeamID, ID, StringList, []).
send_team_common_notice(TeamID, ID, StringList, GoodsList) ->
    {DataRecord, _Condition} = get_common_notice_info(ID, StringList, GoodsList),
    bc_record_to_team(TeamID, DataRecord).

get_common_notice_info(ID, StringList, GoodsList) ->
    DataRecord = #m_common_notice_toc{id = ID, text_string = StringList, goods_list = GoodsList},
    [#c_common_notice{level = Level}] = lib_config:find(cfg_common_notice, ID),
    Condition = #r_broadcast_condition{min_level = Level},
    {DataRecord, Condition}.

%%置顶消息
bc_top_record_to_family(FamilyID, Msg) ->
    DataRecord = #m_chat_set_top_toc{channel_type = ?CHANNEL_FAMILY, msg = Msg},
    bc_record_to_family(FamilyID, DataRecord).

%%删除置顶消息
bc_del_top_record_to_family(FamilyID) ->
    DataRecord = #m_chat_delete_top_toc{},
    bc_record_to_family(FamilyID, DataRecord).