%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 二月 2019 11:48
%%%-------------------------------------------------------------------
-module(mod_role_node).
-author("laijichang").
-include("role.hrl").
-include("node.hrl").
-include("proto/mod_role_node.hrl").

%% API
-export([
    online/1,
    loop_10min/2
]).

-export([
    update_role_cross_data/1
]).

online(State) ->
    #r_role{role_id = RoleID} = State,
    IsCrossConnected = node_base:is_node_connected(node_misc:game_get_cross_node()),
    DataRecord = #m_cross_status_toc{is_connected = IsCrossConnected, next_match_time = global_data:get_cross_next_match_time()},
    common_misc:unicast(RoleID, DataRecord),
    update_role_cross_data(State),
    State.

loop_10min(_Now, State) ->
    update_role_cross_data(State),
    State.

update_role_cross_data(State) ->
    CrossLevel = common_misc:get_global_int(?GLOBAL_CROSS_LEVEL),
    RoleLevel = mod_role_data:get_role_level(State),
    %% 世界等级或者玩家等级达到，就上传玩家数据
    case RoleLevel >= CrossLevel orelse (world_data:get_world_level() >= CrossLevel andalso RoleLevel >= 100) of
        true ->
            #r_role{role_attr = RoleAttr, role_fight = #r_role_fight{fight_attr = FightAttr}} = State,
            #r_role_attr{
                role_id = RoleID,
                role_name = RoleName,
                sex = Sex,
                level = Level,
                category = Category,
                skin_list = SkinList,
                power = Power,
                channel_id = ChannelID,
                game_channel_id = GameChannelID,
                family_id = FamilyID,
                family_name = FamilyName
                } = RoleAttr,
            RoleCrossData = #r_role_cross_data{
                role_id = RoleID,
                role_name = RoleName,
                sex = Sex,
                level = Level,
                category = Category,
                vip_level = mod_role_vip:get_vip_level(State),
                server_name = common_config:get_server_name(),
                skin_list = SkinList,
                power = Power,
                channel_id = ChannelID,
                game_channel_id = GameChannelID,
                fight_attr = FightAttr,
                family_id = FamilyID,
                family_name = FamilyName
            },
            cross_role_data_server:update_role_cross_data(RoleCrossData);
        _ ->
            ok
    end.