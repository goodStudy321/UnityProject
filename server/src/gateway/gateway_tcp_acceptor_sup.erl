-module(gateway_tcp_acceptor_sup).

-behaviour(supervisor).

-export([start_link/1]).
-export([init/1]).

start_link(Callback) ->
    supervisor:start_link(?MODULE, Callback).

init(Callback) ->
    {ok, {{simple_one_for_one, 10, 10},
          [{gateway_tcp_acceptor, {gateway_tcp_acceptor, start_link, [Callback]},
            transient, brutal_kill, worker, [gateway_tcp_acceptor]}]}}.
