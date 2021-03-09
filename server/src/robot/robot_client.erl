%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_client).
-include("proto/gateway.hrl").
-include("proto/role_login.hrl").
-include("proto/mod_role_map.hrl").

-include("gateway.hrl").
-include("robot.hrl").
-include("global.hrl").
-export([start_link/5]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    start/5
]).

-export([
    send_data/1
]).

%% 连接超时
-define(CONN_TIMEOUT, 5000).
%% 发送超时
-define(SEND_TIMEOUT, 5000).
%% 心跳间隔(1sec)
-define(HEART_TIME, 1000).
%% 行为间隔(1sec)
-define(ACTION_TIME, 1500).
%% AI行为间隔ms
-define(AI_ACTION_LOOP, 200).

%%%===================================================================
%%% API
%%%===================================================================
start(Account, PName, IP, Port, Type) ->
    supervisor:start_child(robot_client_sup, {PName,
        {?MODULE, start_link, [PName, lib_tool:to_binary(Account), IP, Port, Type]},
        temporary, 3000000, worker,
        [?MODULE]}).

start_link(PName, Account, IP, Port, Type) ->
    gen_server:start_link({local, PName}, ?MODULE, [Account, IP, Port, Type], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Account,IP, Port, Type]) ->
    erlang:process_flag(trap_exit, true),
    pname_server:send(erlang:self(), {connect_server, Account, IP, Port}),
    robot_data:set_robot_type(Type),
    robot_data:set_robot_account(Account),
    {ok, []}.

handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request,State),
    {reply, Reply, State}.

handle_cast(Request, State) ->
    ?DO_HANDLE_INFO(Request, State),
    {noreply, State}.

handle_info(exit, State) ->
    do_terminate(),
    #r_role_client{socket = Socket} = robot_data:get_role_info(),
    gen_tcp:close(Socket),
    {stop, normal, State};
handle_info({inet_reply, _Sock, ok}, State) ->
    {noreply, State};
handle_info({inet_reply, _Sock, _Result}, State) ->
    do_terminate(),
    #r_role_client{socket = Socket} = robot_data:get_role_info(),
    gen_tcp:close(Socket),
    {stop, normal, State};
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
do_handle({mod,Mod,Info})->
    Mod:handle(Info);
do_handle({func,Fun})->
    Fun();
do_handle({func,M,F,A})->
    erlang:apply(M,F,A);
do_handle({connect_server, Account, IP, Port}) ->
    do_connect_server(Account, IP, Port);

do_handle({tcp, _Port, Data}) ->
    Data2 = gateway_packet:robot_unpack(Data),
    robot_handle:handle(Data2);
do_handle({loop_msec, NowMs}) ->
    time_tool:now_ms_cached(NowMs),
    robot_ai:loop_ms();
do_handle(Info)->
    ?ERROR_MSG("Unknow Message ~w",[Info]).

do_connect_server(Account, IP, Port) ->
    Opts = [
        binary,
        {packet, 4},
        {active, true},
        {reuseaddr, true},
        {send_timeout, ?SEND_TIMEOUT}
    ],
    %% 尝试
    do_connect_server2(Account, IP, Port, Opts, 10).

do_connect_server2(Account, IP, Port, _Opts, 0) ->
    ?ERROR_MSG("connect error:~w",[{Account, IP, Port}]);
do_connect_server2(Account, IP, Port, Opts, Times) ->
    case gen_tcp:connect(IP, Port, Opts, ?CONN_TIMEOUT) of
        {ok, Socket} ->
            robot_data:set_role_info(#r_role_client{socket = Socket}),
            do_role_login(Account),
            {ok, []};
        {error, Error} ->
            ?ERROR_MSG("reconecting ~w", [Error]),
            do_connect_server2(Account, IP, Port, Opts, Times - 1)
    end.

do_role_login(Account) ->
    Now = time_tool:now(),
    Ticket = lib_tool:md5(?GATEWAY_AUTH_KEY ++ lib_tool:to_list(Now)),
    Msg = #m_auth_key_tos{
        account_name = lib_tool:to_list(Account),
        time =  time_tool:now(),
        key = Ticket
    },
    send_data(Msg).

do_terminate()->
    ?ERROR_MSG("do_terminate").


send_data(Data0) ->
    Data = gateway_packet:robot_packet(Data0),
    #r_role_client{socket = Socket} = robot_data:get_role_info(),
    erlang:port_command(Socket, Data, [force]).



