%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 九月 2018 19:46
%%%-------------------------------------------------------------------
-module(mod_role_red_packet).
-author("WZP").

-include("role.hrl").
-include("red_packet.hrl").
-include("proto/mod_role_red_packet.hrl").

%% API
-export([
    init/1,
    handle/2,
    zero/1,
    loop_10min/2,
    day_reset/1
]).

-export([
    receive_system_red_packet/2,
    off_line_system_red_packet/1,
    tran_to_list/1,
    create_red_packet/3,
    create_red_packet/4
]).


%%  p_kvt{id=0,val=0,type=0}    id  红包产生时间   val  红包值    type  红包种类
init(#r_role{role_id = RoleID, role_red_packet = undefined} = State) ->
    RoleRedPacket = #r_role_red_packet{role_id = RoleID},
    State#r_role{role_red_packet = RoleRedPacket};
init(State) ->
    State.


zero(#r_role{role_id = RoleID, role_red_packet = RoleRedPacket} = State) ->
    common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = tran_to_list(RoleRedPacket#r_role_red_packet.red_packet), times = RoleRedPacket#r_role_red_packet.red_packet_num}),
    State.

day_reset(#r_role{role_red_packet = undefined} = State) ->
    State;
day_reset(#r_role{role_red_packet = RoleRedPacket} = State) ->
    NewRoleRedPacket = RoleRedPacket#r_role_red_packet{red_packet_num = 0},
    State#r_role{role_red_packet = NewRoleRedPacket}.

loop_10min(Now, #r_role{role_red_packet = RoleRedPacket, role_id = RoleID} = State) ->
    NewList = clean_out_time(Now, RoleRedPacket#r_role_red_packet.red_packet),
    common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = tran_to_list(NewList), times = RoleRedPacket#r_role_red_packet.red_packet_num}),
    NewRedPacket = RoleRedPacket#r_role_red_packet{red_packet = NewList},
    State#r_role{role_red_packet = NewRedPacket}.

clean_out_time(Now, List) ->
    clean_out_time(Now - 86400, List, []).
clean_out_time(_, [], List) ->
    List;
clean_out_time(CompareTime, [#p_kvt{id = Time} = Info|T], List) ->
    case CompareTime >= Time of
        true ->
            clean_out_time(CompareTime, T, List);
        _ ->
            clean_out_time(CompareTime, T, [Info|List])
    end.


handle({add_system_red_packet, RedPacket}, State) ->
    do_add_red_packet(State, RedPacket).

receive_system_red_packet(RoleID, RedPacket) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {add_system_red_packet, RedPacket}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_system_red_packet, [RedPacket]})
    end.


off_line_system_red_packet(RedPacket) ->
    erlang:send(erlang:self(), {mod, ?MODULE, {add_system_red_packet, RedPacket}}).

do_add_red_packet(#r_role{role_id = RoleID, role_red_packet = RoleRedPacket} = State, RedPacket) ->
    RoleRedPacket2 = RoleRedPacket#r_role_red_packet{red_packet = [RedPacket|RoleRedPacket#r_role_red_packet.red_packet]},
    common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = tran_to_list(RoleRedPacket2#r_role_red_packet.red_packet), times = RoleRedPacket#r_role_red_packet.red_packet_num}),
    State#r_role{role_red_packet = RoleRedPacket2}.




tran_to_list(List) ->
    tran_to_list(List, []).

tran_to_list([], List) ->
    List;
tran_to_list([#p_kvt{val = Val}|T], List) ->
    tran_to_list(T, [Val|List]).

create_red_packet(RoleID, RoleName, ConfigID, Param) ->
    case lib_config:find(cfg_red_packet, ConfigID) of
        [] ->
            ok;
        [Config] ->
            ?IF(Param >= Config#c_red_packet.param, mod_family_red_packet:create_red_packet(RoleID, RoleName, Config#c_red_packet.id, Config#c_red_packet.amount), ok)
    end.

create_red_packet(RoleID, RoleName, ConfigID) ->
    case lib_config:find(cfg_red_packet, ConfigID) of
        [] ->
            ok;
        [Config] ->
            mod_family_red_packet:create_red_packet(RoleID, RoleName, Config#c_red_packet.id, Config#c_red_packet.amount)
    end.
