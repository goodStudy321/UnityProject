-module(gateway_networking).

-define(TCP_OPTS, [
    binary,
    {packet, 0},
    {reuseaddr, true},
    {nodelay, true},
    {delay_send, true},
    {active, false},
    {backlog, 1024},
    {exit_on_close, false},
    {send_timeout, 15000}
]).

-include_lib("kernel/include/inet.hrl").

-include("common.hrl").
-include("gateway.hrl").

-define(CROSS_DOMAIN_FLAG, <<60, 112, 111, 108, 105, 99, 121, 45, 102, 105, 108, 101, 45, 114, 101, 113, 117, 101, 115, 116, 47, 62, 0>>).
-define(CROSS_FILE, "<?xml version=\"1.0\"?>\n<!DOCTYPE cross-domain-policy SYSTEM "
++ "\"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">\n"
    ++ "<cross-domain-policy>\n"
    ++ "<allow-access-from domain=\"*\" to-ports=\"*\"/>\n"
    ++ "</cross-domain-policy>\n\0").

-export([
    start/0,
    start_tcp_listener/2,
    start_sandbox_listener/1,
    stop_tcp_listener/1]).

-export([
    start_client/1,
    start_sandbox/1
]).

-export([
    tcp_listener_started/2,
    tcp_listener_stopped/2,
    tcp_host/1
]).

start() ->
    case common_config:get_gateway_port() of
        Port when erlang:is_integer(Port) ->
            AcceptorNum = ?ACCEPTOR_NUM,
            case lib_config:find(common, gateway_sandbox) of
                [true] ->
                    gateway_networking:start_sandbox_listener(AcceptorNum);
                _ -> ignore
            end,
            {ok, _} = gateway_networking:start_tcp_listener(Port, AcceptorNum);
        _ ->
            throw(wrong_port)
    end.

%% API Functions
%% @doc 启动游戏监听
start_tcp_listener(Port, AcceptorNum) ->
    start_listener(gateway_listener, Port, AcceptorNum, {?MODULE, start_client, []}).
%% @doc 启动安全沙箱监听
start_sandbox_listener(AcceptorNum) ->
    start_listener(sandbox_listener, 843, AcceptorNum, {?MODULE, start_sandbox, []}).

stop_tcp_listener(Name) ->
    ok = supervisor:terminate_child(gateway_sup, Name),
    ok = supervisor:delete_child(gateway_sup, Name),
    ok.

%% @doc 启动游戏client
start_client(Socket) ->
    case catch inet:peername(Socket) of
        {ok, {IP, _}} ->
            ok;
        {error, Reason} ->
            ?WARNING_MSG("~ts:~w", ["获取玩家IP失败", Reason]),
            IP = "127.0.0.1"
    end,
    ?WARNING_MSG("test: tcp连接建立:IP:~w, ~w, ", [IP, time_tool:now()]),
    case gen_tcp:recv(Socket, 0, 100000) of
        {ok, Binary} ->
            ?WARNING_MSG("新的socket连接 IP:~w Binary:~w", [IP, Binary]),
            case erlang:byte_size(Binary) > 0 of
                true ->
                    <<Len:32, Record/binary>> = Binary,
                    ?INFO_MSG(" packet splicing Record:~w", [Record]),
                    case Len =:= erlang:byte_size(Record) of
                        true ->
                            GatewayPort = common_config:get_gateway_port(),
                            gateway_tcp_client:start(Socket, GatewayPort, Record);
                        _ ->
                            ?ERROR_MSG("第一个消息长度不一致Len:~w Record:~w,RemainBinary:~w", [Len, Record, Binary]),
                            gen_tcp:close(Socket)
                    end;
                _ ->
                    ?ERROR_MSG("Socket Binary 大小不对 IP:~w Binary:~w", [IP, Binary]),
                    gen_tcp:close(Socket)
            end;
        R ->
            ?ERROR_MSG("recv_packet_error:~w IP:~w", [R, IP]),
            gen_tcp:close(Socket)
    end.


%% @doc 处理安全沙箱请求
start_sandbox(Socket) ->
    ?DEBUG("新的socket连接"),
    case gen_tcp:recv(Socket, 23, 30000) of
        {ok, ?CROSS_DOMAIN_FLAG} ->
            gen_tcp:send(Socket, ?CROSS_FILE),
            gen_tcp:close(Socket);
        _ ->
            gen_tcp:close(Socket)
    end.

tcp_listener_started(Host, Port) ->
    ?INFO_MSG("~ts ~w:~w", ["端口开始监听", Host, Port]),
    ok.

tcp_listener_stopped(Host, Port) ->
    ?INFO_MSG("~ts ~w:~w", ["端口停止监听", Host, Port]),
    ok.


tcp_host({0, 0, 0, 0}) ->
    {ok, Hostname} = inet:gethostname(),
    case inet:gethostbyname(Hostname) of
        {ok, #hostent{h_name = Name}} -> Name;
        {error, _Reason} -> Hostname
    end;
tcp_host(IPAddress) ->
    case inet:gethostbyaddr(IPAddress) of
        {ok, #hostent{h_name = Name}} -> Name;
        {error, _Reason} -> inet_parse:ntoa(IPAddress)
    end.

%%-----------------------
%% internal API
%%-----------------------

%% 启动监听
start_listener(Name, Port, AcceptorNum, OnConnect) ->
    {ok, PID} = supervisor:start_child(
        gateway_sup,
        {Name,
            {gateway_tcp_listener_sup, start_link,
                [Port, ?TCP_OPTS,
                    {?MODULE, tcp_listener_started, [localhost]},
                    {?MODULE, tcp_listener_stopped, [localhost]},
                    OnConnect, AcceptorNum, Name]},
            transient, infinity, supervisor, [gateway_tcp_listener_sup]}),
    erlang:register(Name, PID),
    {ok, PID}.

