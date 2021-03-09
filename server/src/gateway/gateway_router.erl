-module(gateway_router).
-include("proto/gateway.hrl").
-include("gateway.hrl").
-include("global.hrl").

-export([
    router/1
]).

-define(BAN_TOS, []).
router({DataRecord, Router, RoleID, PID}) ->
    if
        erlang:is_integer(RoleID) ->
            router2(DataRecord, Router, RoleID, PID);
        Router =:= {role, role_login} orelse Router =:= gateway -> %% 发往登录模块的，不管任何时候都发
            router2(DataRecord, Router, RoleID, PID);
        true ->
            ?WARNING_MSG("router DataRecord : ~w", [DataRecord])
    end.

router2(DataRecord, Router, RoleID, PID) ->
    RecordName = erlang:element(1, DataRecord),
    add_proto_count(RecordName),
    Info = {DataRecord, RoleID, PID},
    case lists:member(RecordName, ?BAN_TOS) of
        true ->
            false;
        _ ->
            router3(Router, Info)
    end.

router3(Router, Info) ->
    case Router of
        map ->
            ok;
        gateway ->
            do_gateway(Info);
        {map, Mod} ->
            catch erlang:send(gateway_tcp_client:get_map_pid(), {mod, Mod, Info});
        {role, Mod} ->
            erlang:send(gateway_tcp_client:get_role_pid(), {mod, Mod, Info});
        undefined->
            ?ERROR_MSG("NO PROTO:~w",[Info]);
        GlobalName when erlang:is_atom(GlobalName) ->
            erlang:send(GlobalName, Info);
        {GlobalName, Mod} ->
            erlang:send(GlobalName, {mod, Mod, Info})
    end.

do_gateway({{m_system_hb_tos}, _RoleID, _PID}) ->
    Now = time_tool:now_ms(),
    gateway_tcp_client:set_last_hb_time(time_tool:now()),
    R = {m_system_hb_toc, Now},
    gateway_packet:packet_send(gateway_tcp_client:get_socket(),  R).

add_proto_count(RecordName) ->
    case lists:keymember(RecordName, 1, ?PACKET_CHECK_LIST) of
        true ->
            gateway_tcp_client:add_packet_num(RecordName);
        _ ->
            ok
    end.