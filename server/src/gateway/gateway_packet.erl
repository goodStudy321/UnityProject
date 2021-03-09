%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 四月 2017 9:54
%%%-------------------------------------------------------------------
-module(gateway_packet).
-include("common.hrl").

%% API
-export([
    send/2,
    packet_send/2,
    packet/1,
    packet2/3,
    unpack/1,
    robot_packet/1,
    robot_unpack/1
]).

send(Socket, Bin) ->
    erlang:port_command(Socket, Bin, [force]).

packet_send(Socket, DataRecord) ->
    send(Socket, packet(DataRecord)).

packet(DataRecord) ->
    ?DEBUG("to role_id:~w, packet:~w", [gateway_tcp_client:get_role_id(), DataRecord]),
    RecordName = erlang:element(1, DataRecord),
    MsgID = gateway_proto_router:get_protoid(RecordName),
    packet2(RecordName, MsgID, DataRecord).

packet2(_RecordName, MsgID, DataRecord) ->
    Msg = proto:encode_msg(DataRecord),
%%    case erlang:byte_size(Msg) > 0 of
%%        true ->
%%            ?ERROR_MSG("size:~w, DataRecord:~w", [erlang:byte_size(Msg), DataRecord]);
%%        _ ->
%%            ok
%%    end,
    <<MsgID:16, Msg/binary>>.

unpack(<<MsgID:16, Bin/binary>>) ->
    case gateway_proto_router:get_map(MsgID) of
        {Name, Router} ->
            ?DEBUG("from role_id:~w, proto:~w", [gateway_tcp_client:get_role_id(), proto:decode_msg(Bin, Name)]),
            {proto:decode_msg(Bin, Name), Router};
        _ -> ?ERROR_MSG("unpack error:~w", [{MsgID, Bin}]), error
    end.

robot_packet(DataRecord) ->
    RecordName = erlang:element(1, DataRecord),
    MsgID = robot_proto_router:find(RecordName),
    gateway_packet:packet2(RecordName, MsgID, DataRecord).

robot_unpack(<<MsgID:16, Bin/binary>>) ->
    case robot_proto_router:find(MsgID) of
        Name when erlang:is_atom(Name) ->
            proto:decode_msg(Bin, Name);
        _ ->
            ?ERROR_MSG("robot unpack error:~w", [{MsgID, Bin}]), error
    end.