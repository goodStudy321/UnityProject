-module(gateway_tcp_listener_sup).

-behaviour(supervisor).

-export([start_link/5, start_link/7]).

-export([init/1]).

start_link(Port, SocketOpts, OnStartup, OnShutdown,
           AcceptCallback) ->
    start_link(Port, SocketOpts, OnStartup, OnShutdown,
               AcceptCallback, 1,test).

start_link(Port, SocketOpts, OnStartup, OnShutdown,
           AcceptCallback, ConcurrentAcceptorCount,Name) ->
    {ok, Sup} = supervisor:start_link(?MODULE, []),
    {ok, Acceptor} = do_start_acceptor_sup(Sup, AcceptCallback,Name),
    {ok, _} = do_start_tcp_listener(Sup, Acceptor, Port, 
        SocketOpts, ConcurrentAcceptorCount, OnStartup, OnShutdown,Name),
    {ok, Sup}.

init([]) ->
    {ok, {{one_for_all, 10, 10}, []}}.

%%------------------------
%% internal API
%%------------------------

%% 启动tcp_acceptor_sup
do_start_acceptor_sup(Sup, AcceptCallback,Name) ->
    Child = {gateway_tcp_acceptor_sup, {gateway_tcp_acceptor_sup, start_link, [AcceptCallback]},
    transient, infinity, supervisor, [gateway_tcp_acceptor_sup]},
    {ok,PID} = start_child(Sup, Child),
    erlang:register(erlang:list_to_atom(erlang:atom_to_list(Name)++"_acceptor_sup"),PID),
    {ok,PID} .

%% 启动tcp_listner
do_start_tcp_listener(Sup, Acceptor, 
    Port, SocketOpts, ConcurrentAcceptorCount, OnStartup, OnShutdown,Name) ->
    Child = {gateway_tcp_listener, {gateway_tcp_listener, start_link, 
            [Port, SocketOpts, ConcurrentAcceptorCount, Acceptor, OnStartup, OnShutdown,Name]},
    transient, 100, worker, [gateway_tcp_listener]},
    {ok,PID} = start_child(Sup, Child),
    erlang:register(erlang:list_to_atom(erlang:atom_to_list(Name)++"_tcp_listener"),PID),
    {ok,PID} .

%% 启动子进程
start_child(Sup, Child) ->
    case catch supervisor:start_child(Sup, Child) of
        {ok, PID} ->
            {ok, PID}; 
        {error, {{already_started, PID}, _}} ->
            {ok, PID};
        Other ->
            Other
    end.
