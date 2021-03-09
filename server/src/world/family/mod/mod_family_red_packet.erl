%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 七月 2018 10:13
%%%-------------------------------------------------------------------
-module(mod_family_red_packet).
-author("WZP").

-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").
-include("red_packet.hrl").


%% API


%%family_server
-export([
    family_give_red_packet/2,
    family_get_red_packet/5,
    family_see_red_packet/3,

    family_auction_red_packet/2
]).

-export([
    handle/1
]).

%%common
-export([
    create_red_packet/4,
    separate_red_packet/2,
    delete_overdue_red_packet/0,
    create_red_packet_list/2
]).


-export([
    gm_add_red_packet/2
]).



family_see_red_packet(PacketID, FamilyID, RoleID) ->
    family_misc:info_family({mod, ?MODULE, {see_red_packet, FamilyID, RoleID, PacketID}}).
family_give_red_packet(RedPacket, FamilyID) ->
    family_misc:call_family({mod, ?MODULE, {give_red_packet, RedPacket, FamilyID}}).
family_get_red_packet(PacketID, FamilyID, RoleID, Name, Category) ->
    family_misc:call_family({mod, ?MODULE, {get_red_packet, PacketID, FamilyID, RoleID, Name, Category}}).

family_auction_red_packet(FamilyID, RedPacket) ->
    family_misc:info_family({mod, ?MODULE, {family_auction_red_packet, FamilyID, RedPacket}}).

handle({see_red_packet, FamilyID, RoleID, PacketID}) ->
    do_see_red_packet(PacketID, FamilyID, RoleID);
handle({give_red_packet, RedPacket, FamilyID}) ->
    do_give_red_packet(RedPacket, FamilyID);
handle({add_red_packet_log, FamilyID, RoleName, From, Amount, Now}) ->
    do_add_red_packet_log(FamilyID, RoleName, From, Amount, Now);
handle({get_red_packet, PacketID, FamilyID, RoleID, Name, Category}) ->
    do_get_red_packet(PacketID, FamilyID, RoleID, Name, Category);
handle({family_auction_red_packet, FamilyID, RedPacket}) ->
    do_family_auction_red_packet(FamilyID, RedPacket).

do_give_red_packet(RedPacket, FamilyID) ->
    case catch check_give_red_packet(RedPacket, FamilyID) of
        {ok, NewRedPacket2} ->
            {ok, NewRedPacket2};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_give_red_packet(#p_red_packet{piece = Piece} = RedPacket, FamilyID) ->
    FamilyData = mod_family_data:get_family(FamilyID),
%%    ?IF(erlang:length(FamilyData#p_family.members) >= Piece, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_006)),
    #p_family{packet_id = NowPacketID} = FamilyData,
    NewRedPacket = RedPacket#p_red_packet{id = NowPacketID},
    NewFamilyData = FamilyData#p_family{packet_id = NowPacketID + 1},
    List = create_red_packet_list(Piece, NewRedPacket#p_red_packet.amount),
    NewRedPacket2 = NewRedPacket#p_red_packet{packet_list = List},
    NewFamilyData2 = NewFamilyData#p_family{red_packet = [NewRedPacket2|NewFamilyData#p_family.red_packet]},
    mod_family_data:set_family(NewFamilyData2),
    {ok, NewRedPacket2}.



do_get_red_packet(PacketID, FamilyID, RoleID, Name, Category) ->
    #p_family{red_packet = RedPackets} = FamilyData = mod_family_data:get_family(FamilyID),
    case lists:keytake(PacketID, #p_red_packet.id, RedPackets) of
        false ->
            {error, ?ERROR_FAMILY_GET_RED_PACKET_002};
        {value, #p_red_packet{sent_num = SentNum, packet_list = PacketList, bind = Bind, role_list = RoleList} = Packet, OtherPacket} ->
            ?IF(RoleList =:= [] orelse lists:member(RoleID, RoleList), ok, ?THROW_ERR(?ERROR_FAMILY_GET_RED_PACKET_004)),
            case lists:keyfind(RoleID, #p_red_packet_content.role_id, PacketList) of
                false ->
                    case lists:keytake(SentNum + 1, #p_red_packet_content.id, PacketList) of
                        false ->
                            {error, ?ERROR_FAMILY_GET_RED_PACKET_001};
                        {value, PacketContent, OtherPacketList} ->
                            NewPacketContent = PacketContent#p_red_packet_content{name = Name, role_id = RoleID, icon = Category},
                            NewPacketList = [NewPacketContent|OtherPacketList],
                            NewRedPacket = Packet#p_red_packet{sent_num = SentNum + 1, packet_list = NewPacketList},
                            NewFamilyData = FamilyData#p_family{red_packet = [NewRedPacket|OtherPacket]},
                            mod_family_data:set_family(NewFamilyData),
                            Record = #m_family_red_packet_content_toc{content = NewPacketList, id = PacketID},
                            common_broadcast:bc_record_to_family(FamilyID, Record),
                            {ok, NewPacketContent#p_red_packet_content.amount, Bind}
                    end;
                _ ->
                    {error, ?ERROR_FAMILY_GET_RED_PACKET_003}
            end
    end.


do_see_red_packet(PacketID, FamilyID, RoleID) ->
    case catch check_can_see_red_packet(PacketID, FamilyID) of
        {ok, PacketList} ->
            common_misc:unicast(RoleID, #m_family_see_red_packet_toc{list = PacketList, id = PacketID});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_see_red_packet_toc{err_code = ErrCode})
    end.

check_can_see_red_packet(PacketID, FamilyID) ->
    #p_family{red_packet = RedPackets} = mod_family_data:get_family(FamilyID),
    case lists:keyfind(PacketID, #p_red_packet.id, RedPackets) of
        false ->
            ?THROW_ERR(?ERROR_FAMILY_SEE_RED_PACKET_001);
        RedPacket ->
            {ok, RedPacket#p_red_packet.packet_list}
    end.

do_add_red_packet_log(FamilyID, RoleName, From, Amount, Now) ->
    Family = mod_family_data:get_family(FamilyID),
    NewRedPacketLog = #p_red_packet_log{sender_name = RoleName, from = From, amount = Amount, time = Now},
    NewRedPacketLogs = [NewRedPacketLog|Family#p_family.red_packet_log],
    NewFamily = Family#p_family{red_packet_log = NewRedPacketLogs},
    mod_family_data:set_family(NewFamily),
    DataRecord = #m_family_red_packet_log_toc{log = NewRedPacketLogs},
    common_broadcast:bc_record_to_family(FamilyID, DataRecord).

%%Amount  必须 >= Piece
create_red_packet_list(Piece, Amount) ->
    ?IF(Amount >= Piece, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_006)),
    separate_red_packet(Amount, Piece).

separate_red_packet(Amount, Piece) ->
    Base = max(lib_tool:floor(Amount / Piece * ?FAMILY_RED_PACKET_MIN_RATE), ?FAMILY_RED_PACKET_MIX_NUM),
    MaxRoleAmount = lib_tool:ceil(Amount / Piece * ?FAMILY_RED_PACKET_MAX_RATE),
    OtherAmount = Amount - Piece * Base,
    NumList = lists:seq(1, Piece),
    BaseList = lists:foldl(fun(Num, PacketList) ->
        [#p_red_packet_content{id = Num, amount = Base, name = "", role_id = ?FAMILY_RED_PACKET_EXIST}|PacketList]
                           end, [], NumList),
    separate_red_packet_i(BaseList, OtherAmount, MaxRoleAmount, []).

separate_red_packet_i(PacketList, OtherAmount, _MaxRoleAmount, MaxList) when OtherAmount =:= 0 ->
    PacketList ++ MaxList;

separate_red_packet_i(PacketList, OtherAmount, MaxRoleAmount, MaxList) ->
    #p_red_packet_content{amount = RoleAmount} = RoundPacket = lib_tool:random_element_from_list(PacketList),
    NewRoleAmount = RoleAmount + 1,
    NewRoundPacket = RoundPacket#p_red_packet_content{amount = NewRoleAmount},
    case NewRoleAmount =:= MaxRoleAmount of
        true ->
            NewPacketList = lists:keydelete(NewRoundPacket#p_red_packet_content.id, #p_red_packet_content.id, PacketList),
            separate_red_packet_i(NewPacketList, OtherAmount - 1, MaxRoleAmount, [NewRoundPacket|MaxList]);
        _ ->
            NewPacketList = lists:keyreplace(NewRoundPacket#p_red_packet_content.id, #p_red_packet_content.id, PacketList, NewRoundPacket),
            separate_red_packet_i(NewPacketList, OtherAmount - 1, MaxRoleAmount, MaxList)
    end.


%%处理仙盟过期红包 日志
delete_overdue_red_packet() ->
    AllFamily = mod_family_data:get_all_family(),
    [delete_overdue_red_packet(Family) || Family <- AllFamily].

delete_overdue_red_packet(#p_family{red_packet = RedPackets, family_id = FamilyID} = Family) ->
    case RedPackets =/= [] of
        true ->
            DeleteIDs = [RedPackets#p_red_packet.id || RedPackets < - RedPackets],
            DataRecord = #m_family_red_packet_overdue_toc{packet_id = DeleteIDs, type = ?FAMILY_RED_PACKET_SENT},
            DataRecord2 = #m_family_red_packet_log_delete_toc{},
            common_broadcast:bc_record_to_family(FamilyID, DataRecord),
            common_broadcast:bc_record_to_family(FamilyID, DataRecord2);
        _ ->
            ok
    end,
    Family2 = Family#p_family{red_packet = [], packet_id = 1, red_packet_log = []},
    mod_family_data:set_family(Family2).

do_family_auction_red_packet(FamilyID, RedPacket) ->
    case mod_family_data:get_family(FamilyID) of
        #p_family{} ->
            case catch do_give_red_packet(RedPacket, FamilyID) of
                {ok, NewRedPacket2} ->
                    DataRecord = #m_family_new_red_packet_toc{red_packet = NewRedPacket2},
                    common_broadcast:bc_record_to_family(FamilyID, DataRecord);
                Error ->
                    ?ERROR_MSG("Error : ~w", [Error])
            end;
        _ ->
            ok
    end.


create_red_packet(RoleID, RoleName, From, Amount) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    Now = time_tool:now(),
    case ?HAS_FAMILY(FamilyID) of
        true ->
            Family = mod_family_data:get_family(FamilyID),
            case lists:keymember(RoleID, #p_family_member.role_id, Family#p_family.members) of
                true ->
                    family_misc:info_family({mod, ?MODULE, {add_red_packet_log, FamilyID, RoleName, From, Amount, Now}});
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    mod_role_red_packet:receive_system_red_packet(RoleID, #p_kvt{id = Now, type = From, val = Amount}).



gm_add_red_packet(#r_role{role_id = RoleID, role_attr = Attr}, Amount) ->
    create_red_packet(RoleID, Attr#r_role_attr.role_name, 1, Amount).
