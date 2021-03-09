%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     广播 worker
%%% @end
%%% Created : 15. 七月 2017 10:32
%%%-------------------------------------------------------------------
-module(world_broadcast_worker).
-author("laijichang").
-include("global.hrl").

-behaviour(gen_server).

%% API
-export([
    start_link/1
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

start_link(WorkerID) ->
    PName = lib_tool:to_atom(lists:concat([?MODULE, "_", WorkerID])),
    gen_server:start_link({local, PName}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({broadcast_msg, Channel, Msg}) ->
    do_broadcast_msg(Channel, Msg);
do_handle({broadcast_msg_by_roles, RoleList, Msg}) ->
    do_broadcast_msg_by_roles(RoleList, Msg);
do_handle(Info) ->
    ?INFO_MSG("unknow info :~w", [Info]).


do_broadcast_msg({?CHANNEL_WORLD, _}, Msg) ->
    do_broadcast_world(Msg);
do_broadcast_msg(Channel, Msg) ->
    case world_broadcast_server:get_broadcast_channel(Channel) of
        [#r_broadcast_channel{role_list = RoleList}] ->
            do_broadcast_msg_by_roles(RoleList, Msg);
        _ ->
            ok
    end.

%% 世界频道特殊处理
do_broadcast_world({?BROADCAST_RECORD, DataRecord}) ->
    Bin = gateway_packet:packet(DataRecord),
    Info = {binary, Bin},
    [ pname_server:send(GatewayPID, Info) || #r_broadcast_role{gateway_pid = GatewayPID} <- world_broadcast_server:get_all_broadcast_role()];
do_broadcast_world({?BROADCAST_RECORD, Condition, DataRecord}) ->
    Bin = gateway_packet:packet(DataRecord),
    Info = {binary_filter, Condition, Bin},
    [ pname_server:send(GatewayPID, Info) || #r_broadcast_role{gateway_pid = GatewayPID} <- world_broadcast_server:get_all_broadcast_role()];
do_broadcast_world({?BROADCAST_TO_ROLE, Info}) ->
    [ pname_server:send(RolePID, Info) || #r_broadcast_role{role_pid = RolePID} <- world_broadcast_server:get_all_broadcast_role()].

%% 其他频道
do_broadcast_msg_by_roles(RoleList, {?BROADCAST_RECORD, DataRecord}) ->
    Bin = gateway_packet:packet(DataRecord),
    Info = {binary, Bin},
    [ begin
          case world_broadcast_server:get_broadcast_role(RoleID) of
              [#r_broadcast_role{gateway_pid = GatewayPID}] ->
                  pname_server:send(GatewayPID, Info);
              _ ->
                  ok
          end
      end || RoleID <- RoleList];
do_broadcast_msg_by_roles(RoleList, {?BROADCAST_RECORD, Condition, DataRecord}) ->
    Bin = gateway_packet:packet(DataRecord),
    Info = {binary_filter, Condition, Bin},
    [ begin
          case world_broadcast_server:get_broadcast_role(RoleID) of
              [#r_broadcast_role{gateway_pid = GatewayPID}] ->
                  pname_server:send(GatewayPID, Info);
              _ ->
                  ok
          end
      end || RoleID <- RoleList];
do_broadcast_msg_by_roles(RoleList, {?BROADCAST_TO_ROLE, Info}) ->
    [ begin
          case world_broadcast_server:get_broadcast_role(RoleID) of
              [#r_broadcast_role{role_pid = RolePID}] ->
                  pname_server:send(RolePID, Info);
              _ ->
                  ok
          end
      end || RoleID <- RoleList].