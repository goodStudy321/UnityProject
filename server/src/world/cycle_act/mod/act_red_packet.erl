%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十月 2019 17:26
%%%-------------------------------------------------------------------
-module(act_red_packet).
-author("laijichang").
-include("global.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_act_red_packet.hrl").
-include("proto/mod_role_family.hrl").
-include("family.hrl").

%% API
-export([
    zero/0,
    hour_change/1,
    handle/1
]).

-export([
    get_red_packet/4
]).

-export([
    gm_send_red_packet/1,
    create_red_packet_list/2
]).

get_red_packet(PacketID, RoleID, RoleName, Category) ->
    world_cycle_act_server:call_mod(?MODULE, {get_red_packet, PacketID, RoleID, RoleName, Category}).

gm_send_red_packet(Hour) ->
    world_cycle_act_server:info_mod(?MODULE, {gm_send_red_packet, Hour}).

zero() ->
    PacketIDs = [ PacketID|| #p_act_red_packet{packet_id = PacketID}<- world_data:get_act_red_packet()],
    DataRecord = #m_act_red_packet_del_toc{packet_ids = PacketIDs},
    broadcast_record(DataRecord),
    world_data:set_act_red_packet([]).

hour_change(Now) ->
    case world_cycle_act_server:is_act_open(?CYCLE_ACT_RED_PACKET) of
        true ->
            {_, {Hour, _Min, _Sec}} = time_tool:timestamp_to_datetime(Now),
            send_red_packet(Hour),
            ok;
        _ ->
            ok
    end.

%% 延时发放红包
send_red_packet(Hour) ->
    case lib_config:find(cfg_act_red_packet, Hour) of
        [Config] ->
            SendList = common_misc:get_global_list(?GLOBAL_ACT_RED_PACKET),
            Now = time_tool:now(),
            AddRedPackets = send_red_packet2(SendList, 1, Hour, Now, Config, []),
            RedPackets = world_data:get_act_red_packet(),
            world_data:set_act_red_packet(AddRedPackets ++ RedPackets),
            DataRecord = #m_act_red_packet_toc{red_packets = AddRedPackets},
            broadcast_record(DataRecord);
        _ ->
            ok
    end.

send_red_packet2([], _Index, _Hour, _Now, _Config, RedPacketAcc) ->
    RedPacketAcc;
send_red_packet2([Min|R], Index, Hour, Now, Config, RedPacketAcc) ->
    String = erlang:element(Index + 2, Config),
    [AssetType, Piece, Amount|_] = lib_tool:string_to_integer_list(String, ":"),
    PacketList = create_red_packet_list(Piece, Amount),
    PacketID = Now * 100 + Index,
    StartTime = Now + Min * ?ONE_MINUTE,
    ActRedPacket = #p_act_red_packet{
        packet_id = PacketID,
        start_time = StartTime,
        end_time = StartTime + common_misc:get_global_int(?GLOBAL_ACT_RED_PACKET) * ?ONE_MINUTE,
        amount = Amount,
        piece = Piece,
        bind = AssetType,
        packet_list = lists:keysort(#p_red_packet_content.id, PacketList)},
    send_red_packet2(R, Index + 1, Hour, Now, Config, [ActRedPacket|RedPacketAcc]).


handle({get_red_packet, PacketID, RoleID, RoleName, Category}) ->
    do_get_red_packet(PacketID, RoleID, RoleName, Category);
handle({gm_send_red_packet, Hour}) ->
    send_red_packet(Hour).

do_get_red_packet(PacketID, RoleID, RoleName, Category) ->
    case catch check_get_red_packet(PacketID, RoleID, RoleName, Category) of
        {ok, AssetType, AssetValue, RedPacket, RedPackets} ->
            world_data:set_act_red_packet(RedPackets),
            broadcast_record(#m_act_red_packet_toc{red_packets = [RedPacket]}),
            {ok, AssetType, AssetValue, RedPacket};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_get_red_packet(PacketID, RoleID, RoleName, Category) ->
    RedPackets = world_data:get_act_red_packet(),
    {RedPacket, RedPackets2} =
        case lists:keytake(PacketID, #p_act_red_packet.packet_id, RedPackets) of
            {value, RedPacketT, RedPacketsT} ->
                {RedPacketT, RedPacketsT};
            _ ->
                ?THROW_ERR(?ERROR_ACT_GET_RED_PACKET_002)
        end,
    #p_act_red_packet{
        start_time = StartTime,
        end_time = EndTime,
        bind = AssetType,
        packet_list = PacketList} = RedPacket,
    Now = time_tool:now(),
    ?IF(Now >= StartTime, ok, ?THROW_ERR(?ERROR_ACT_GET_RED_PACKET_004)),
    ?IF(Now >= EndTime, ?THROW_ERR(?ERROR_ACT_GET_RED_PACKET_004), ok),
    {PacketList2, AssetValue} = check_get_red_packet2(PacketList, RoleID, RoleName, Category, []),
    RedPacket2 = RedPacket#p_act_red_packet{packet_list = PacketList2},
    RedPackets3 = [RedPacket2|RedPackets2],
    {ok, AssetType, AssetValue, RedPacket2, RedPackets3}.

check_get_red_packet2([], _RoleID, _RoleName, _Category, _Acc) ->
    ?THROW_ERR(?ERROR_ACT_GET_RED_PACKET_001);
check_get_red_packet2([Packet|R], RoleID, RoleName, Category, Acc) ->
    #p_red_packet_content{
        role_id = PacketRoleID,
        amount = Amount
    } = Packet,
    ?IF(RoleID =:= PacketRoleID, ?THROW_ERR(?ERROR_ACT_GET_RED_PACKET_003), ok),
    case PacketRoleID =:= 1 of
        true -> %% 可以领取
            Packet2 = Packet#p_red_packet_content{
                role_id = RoleID,
                name = RoleName,
                icon = Category
            },
            PacketList = lists:keysort(#p_red_packet_content.id, [Packet2|R] ++ Acc),
            {PacketList, Amount};
        _ ->
            check_get_red_packet2(R, RoleID, RoleName, Category, [Packet|Acc])
    end.

broadcast_record(DataRecord) ->
    [#c_cycle_act{level = NeedLevel}] = lib_config:find(cfg_cycle_act, ?CYCLE_ACT_RED_PACKET),
    common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = NeedLevel}).

create_red_packet_list(Piece, Amount) ->
    Base = erlang:max(lib_tool:floor(Amount / Piece * 0.75), ?FAMILY_RED_PACKET_MIX_NUM),
    OtherAmount = Amount - Piece * Base,
    MaxAdd = lib_tool:ceil(2 * OtherAmount/Piece),
    NumList = lists:seq(1, Piece),
    AddAcc = get_add_list(NumList, MaxAdd, OtherAmount, []),
    {_Index, Packets} =
    lists:foldl(
        fun(AddAmount, {Index, PacketList}) ->
            {Index + 1, [#p_red_packet_content{id = Index, amount = Base + AddAmount, name = "", role_id = ?FAMILY_RED_PACKET_EXIST}|PacketList]}
        end, {1, []}, lib_tool:random_reorder_list(AddAcc)),
    Packets.

get_add_list([], _MaxAdd, _OtherAmount, Acc) ->
    Acc;
get_add_list([_Num], _MaxAdd, OtherAmount, Acc) ->
    [OtherAmount|Acc];
get_add_list([_Num|R], MaxAdd, OtherAmount, Acc) ->
    Add = ?IF(OtherAmount > 0 andalso MaxAdd > 0, erlang:min(lib_tool:random(1, MaxAdd), OtherAmount), 0),
    Acc2 = [Add|Acc],
    get_add_list(R, MaxAdd, OtherAmount - Add, Acc2).