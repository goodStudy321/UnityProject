%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     广播server
%%% @end
%%% Created : 14. 七月 2017 19:19
%%%-------------------------------------------------------------------
-module(world_broadcast_server).
-author("laijichang").
-include("global.hrl").

-behaviour(gen_server).

%% API
-export([
    i/0,
    start/0,
    start_link/0
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

-export([
    info/1,
    role_online/3,
    role_offline/1,
    role_add_channel/2,
    role_leave_channel/2
]).

-export([
    get_broadcast_role/1,
    get_all_broadcast_role/0,
    get_broadcast_channel/1,

    broadcast_msg/2,
    broadcast_delay_msg/3,
    broadcast_msg_by_roles/2
]).

i() ->
    {ets:tab2list(?ETS_BROADCAST_CHANNEL), ets:tab2list(?ETS_BROADCAST_ROLE)}.

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

role_online(RoleID, RolePID, GatewayPID) ->
    info({role_online, RoleID, RolePID, GatewayPID}).

role_offline(RoleID) ->
    info({role_offline, RoleID}).

role_add_channel(RoleID, ChannelList) ->
    info({role_add_channel, RoleID, ChannelList}).

role_leave_channel(RoleID, ChannelList) ->
    info({role_leave_channel, RoleID, ChannelList}).

broadcast_msg(Channel, Msg) ->
    info({broadcast_msg, Channel, Msg}).

broadcast_delay_msg(Delay, Channel, Msg) ->
    erlang:send_after(Delay * 1000, ?MODULE, {broadcast_msg, Channel, Msg}).

broadcast_msg_by_roles([], _Msg) ->
    ok;
broadcast_msg_by_roles(RoleList, Msg) ->
    info({broadcast_msg_by_roles, RoleList, Msg}).

info(Info) ->
    pname_server:send(?MODULE, Info).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    [begin
         {ok, PID} = world_broadcast_worker:start_link(WorkerID),
         set_worker_pid(WorkerID, PID)
     end || WorkerID <- lists:seq(0, ?MAX_WORKER_NUM)],
    ets:new(?ETS_BROADCAST_ROLE, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_broadcast_role.role_id}]),
    ets:new(?ETS_BROADCAST_CHANNEL, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_broadcast_channel.channel}]),
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
do_handle({role_online, RoleID, RolePID, GatewayPID}) ->
    do_role_online(RoleID, RolePID, GatewayPID);
do_handle({role_offline, RoleID}) ->
    do_role_offline(RoleID);
do_handle({role_add_channel, RoleID, ChannelList}) ->
    do_role_add_channel(RoleID, ChannelList);
do_handle({role_leave_channel, RoleID, ChannelList}) ->
    do_role_leave_channel(RoleID, ChannelList);
do_handle({broadcast_msg, Channel, Msg}) ->
    do_broadcast_msg(Channel, Msg);
do_handle({broadcast_msg_by_roles, RoleList, Msg}) ->
    do_broadcast_msg_by_roles(RoleList, Msg);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%% 角色上线
do_role_online(RoleID, RolePID, GatewayPID) ->
    BcRole = #r_broadcast_role{role_id = RoleID, role_pid = RolePID, gateway_pid = GatewayPID, channel_list = []},
    set_broadcast_role(BcRole).

%% 角色下线
do_role_offline(RoleID) ->
    case get_broadcast_role(RoleID) of
        [#r_broadcast_role{channel_list = ChannelList}] when ChannelList =/= [] ->
            do_role_leave_channel2(RoleID, ChannelList);
        _ ->
            ok
    end,
    del_broadcast_role(RoleID).

%% 角色加入某些频道（世界频道的广播是直接读整个ets）
do_role_add_channel(RoleID, ChannelList) ->
    [ begin
          do_role_add_channel2(RoleID, ChannelType, ChannelID),
          ?TRY_CATCH(do_role_add_channel3(RoleID, ChannelType, ChannelID))
      end || {ChannelType, ChannelID} <- ChannelList].

%% 频道加上该角色
do_role_add_channel2(_RoleID, ?CHANNEL_WORLD, _ChannelID) ->
    ok;
do_role_add_channel2(RoleID, ChannelType, ChannelID) ->
    case get_broadcast_channel({ChannelType, ChannelID}) of
        [#r_broadcast_channel{role_list = RoleList} = BcChannel] ->
            RoleList2 = ?IF(lists:member(RoleID, RoleList), RoleList, [RoleID|RoleList]),
            set_broadcast_channel(BcChannel#r_broadcast_channel{role_list = RoleList2});
        _ ->
            set_broadcast_channel(#r_broadcast_channel{channel = {ChannelType, ChannelID}, role_list = [RoleID]})
    end.

%% 角色加上频道的映射
do_role_add_channel3(RoleID, ChannelType, ChannelID) ->
    Channel = {ChannelType, ChannelID},
    [#r_broadcast_role{channel_list = ChannelList} = BcRole] = get_broadcast_role(RoleID),
    case lists:member(Channel, ChannelList) of
        true ->
            ok;
        _ ->
            set_broadcast_role(BcRole#r_broadcast_role{channel_list = [Channel|ChannelList]})
    end.


%% 角色离开某些频道
do_role_leave_channel(RoleID, ChannelList) ->
    case get_broadcast_role(RoleID) of
        [#r_broadcast_role{channel_list = OldChannelList} = RoleChannel] ->
            do_role_leave_channel2(RoleID, ChannelList),
            set_broadcast_role(RoleChannel#r_broadcast_role{channel_list = OldChannelList -- ChannelList});
        _ ->
            ok
    end.

do_role_leave_channel2(RoleID, ChannelList) ->
    [ do_role_leave_channel3(RoleID, ChannelType, ChannelID) || {ChannelType, ChannelID} <- ChannelList].

do_role_leave_channel3(_RoleID, ?CHANNEL_WORLD, _ChannelID) ->
    ok;
do_role_leave_channel3(RoleID, ChannelType, ChannelID) ->
    case get_broadcast_channel({ChannelType, ChannelID}) of
        [#r_broadcast_channel{role_list = RoleList} = BcChannel] ->
            RoleList2 = lists:delete(RoleID, RoleList),
            ?IF(RoleList2 =:= [], del_broadcast_channel({ChannelType, ChannelID}), set_broadcast_channel(BcChannel#r_broadcast_channel{role_list = RoleList2}));
        _ ->
            ok
    end.

do_broadcast_msg(Channel, Msg) ->
    PID = get_pid_by_channel(Channel),
    pname_server:send(PID, {broadcast_msg, Channel, Msg}).

do_broadcast_msg_by_roles(RoleList, Msg) ->
    PID = get_worker_pid(erlang:phash(RoleList, ?MAX_WORKER_NUM)),
    pname_server:send(PID, {broadcast_msg_by_roles, RoleList, Msg}).

get_pid_by_channel({?CHANNEL_WORLD, _}) ->
    get_worker_pid(0);
get_pid_by_channel(Channel) ->
    get_worker_pid(erlang:phash(Channel, ?MAX_WORKER_NUM)).

%%%===================================================================
%%% dict
%%%===================================================================
set_worker_pid(WorkerID, PID) ->
    erlang:put({?MODULE, worker_pid, WorkerID}, PID).
get_worker_pid(WorkerID) ->
    erlang:get({?MODULE, worker_pid, WorkerID}).

set_broadcast_role(BcRole) ->
    ets:insert(?ETS_BROADCAST_ROLE, BcRole).
get_broadcast_role(RoleID) ->
    ets:lookup(?ETS_BROADCAST_ROLE, RoleID).
del_broadcast_role(RoleID) ->
    ets:delete(?ETS_BROADCAST_ROLE, RoleID).
get_all_broadcast_role() ->
    ets:tab2list(?ETS_BROADCAST_ROLE).

set_broadcast_channel(BcChannel) ->
    ets:insert(?ETS_BROADCAST_CHANNEL, BcChannel).
get_broadcast_channel(Channel) ->
    ets:lookup(?ETS_BROADCAST_CHANNEL, Channel).
del_broadcast_channel(Channel) ->
    ets:delete(?ETS_BROADCAST_CHANNEL, Channel).

