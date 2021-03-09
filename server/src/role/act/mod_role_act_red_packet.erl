%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十月 2019 9:41
%%%-------------------------------------------------------------------
-module(mod_role_act_red_packet).
-author("laijichang").
-include("role.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_act_red_packet.hrl").

%% API
-export([
    online/1,
    handle/2
]).

online(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_RED_PACKET, State) of
        true ->
            RedPackets = world_data:get_act_red_packet(),
            common_misc:unicast(State#r_role.role_id, #m_act_red_packet_toc{red_packets = RedPackets});
        _ ->
            ok
    end,
    State.

handle({#m_act_get_red_packet_tos{packet_id = PacketID}, RoleID, _Pid}, State) ->
    do_get_red_packet(RoleID, PacketID, State);
handle({#m_act_see_red_packet_tos{packet_id = PacketID}, RoleID, _Pid}, State) ->
    do_see_red_packet(RoleID, PacketID, State).

%% 领取红包
do_get_red_packet(RoleID, PacketID, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName, category = Category}} = State,
    case catch act_red_packet:get_red_packet(PacketID, RoleID, RoleName, Category) of
        {ok, AssetType, AssetValue, RedPacket} ->
            AssetDoings =
                case AssetType of
                    ?ASSET_SILVER -> %% 铜钱
                        [{add_silver, ?ASSET_SILVER_ADD_FROM_ACT_RED_PACKET, AssetValue}];
                    _ -> %% 绑定元宝、元宝
                        [mod_role_asset:add_asset_by_type(AssetType, AssetValue, ?ASSET_GOLD_ADD_FROM_ACT_RED_PACKET)]
                end,
            common_misc:unicast(RoleID, #m_act_get_red_packet_toc{red_packet = RedPacket}),
            mod_role_asset:do(AssetDoings, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_get_red_packet_toc{err_code = ErrCode}),
            State
    end.

%% 查看手气
do_see_red_packet(RoleID, PacketID, State) ->
    case catch check_see_red_packet(PacketID) of
        {ok, List} ->
            common_misc:unicast(RoleID, #m_act_see_red_packet_toc{packet_id = PacketID, list = List});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_see_red_packet_toc{err_code = ErrCode})
    end,
    State.

check_see_red_packet(PacketID) ->
    RedPackets = world_data:get_act_red_packet(),
    case lists:keyfind(PacketID, #p_act_red_packet.packet_id, RedPackets) of
        #p_act_red_packet{packet_list = List} ->
            {ok, List};
        _ ->
            ?THROW_ERR(?ERROR_ACT_SEE_RED_PACKET_001)
    end.
