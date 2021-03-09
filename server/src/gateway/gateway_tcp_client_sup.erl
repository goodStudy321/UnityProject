-module(gateway_tcp_client_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("proto/gateway.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_client/3]).

-export([
         start_link/0,
         start/0
        ]).
%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_client(Socket, GatewayPort, Record) ->
    supervisor:start_child(?MODULE, [Socket, GatewayPort, Record]).

start() ->
    {ok,PID} = supervisor:start_child(
                   gateway_sup,
                   {?MODULE,
                    {?MODULE, start_link, []},
                    transient, infinity, supervisor, [?MODULE]}),
    {ok,PID}.


start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% ---------------------------------------------------------------------
init([]) ->
    {ok, {{simple_one_for_one, 0, 3600},
          [{gateway_tcp_client, {gateway_tcp_client, start_link, []}, 
            temporary, 20000000, worker, [gateway_tcp_client]}]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

