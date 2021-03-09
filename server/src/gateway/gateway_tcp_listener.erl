-module(gateway_tcp_listener).

-behaviour(gen_server).

-include("proto/gateway.hrl").
-include("common.hrl").

-export([start_link/7]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {sock, on_startup, on_shutdown}).

%%--------------------------------------------------------------------

start_link(Port, SocketOpts,
           ConcurrentAcceptorCount, AcceptorSup,
           OnStartup, OnShutdown,Name) ->
    gen_server:start_link(
      ?MODULE, {Port, SocketOpts,
                ConcurrentAcceptorCount, AcceptorSup,
                OnStartup, OnShutdown,Name}, []).

%%--------------------------------------------------------------------

init({Port, SocketOpts,ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name}) ->
    process_flag(trap_exit, true),
    do_init(Port, SocketOpts,ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name).
do_init(Port, SocketOpts,ConcurrentAcceptorCount, AcceptorSup,{M,F,A} = OnStartup, OnShutdown,Name) ->
    case gen_tcp:listen(Port, SocketOpts ++ [{active, false}]) of
        {ok, LSock} ->
            %% if listen successful ,we start several acceptor to accept it
            lists:foreach(
              fun (Seq) ->
                       {ok, APID} = supervisor:start_child(AcceptorSup, [LSock]),
                        erlang:register(erlang:list_to_atom(erlang:atom_to_list(Name)++"_acceptor"++erlang:integer_to_list(Seq)),APID),
                       APID ! {event, start}
              end,
              lists:seq(1,ConcurrentAcceptorCount)),
            apply(M, F, A ++ [Port]),
            {ok, #state{sock = LSock, on_startup = OnStartup, on_shutdown = OnShutdown}};
        {error, eaddrinuse} ->
            case Port of
                843 ->
                    %?WARNING_MSG("端口~w addrinuse", [Port]),
                    do_notify_reconnect(Port, SocketOpts, ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name),
                    {ok, #state{sock = undefined}};
                _ ->
                    ?INFO_MSG("端口被占用 ~p", [Port]),
                    {stop, {port_inuse, Port}}
            end;
        {error, Reason} ->
            ?INFO_MSG(
            "failed to start ~s on port:~w - ~w~n",
            [?MODULE, Port, Reason]),
            {stop, {cannot_listen, Port, Reason}}
    end.

%% 定时启动843端口的绑定
do_notify_reconnect(Port, SocketOpts, ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name) ->
    erlang:send_after(5000, erlang:self(), {reconnect, Port, SocketOpts, ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name}).

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', _, Reason}, State) ->
    ?INFO_MSG("listener stop ~w ", [Reason]),
    {stop, normal, State};

handle_info({reconnect, Port, SocketOpts, ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name}, State) ->
    %% 无论是否连接上都继续定时消息
    case do_init(Port, SocketOpts, ConcurrentAcceptorCount, AcceptorSup,OnStartup, OnShutdown,Name) of
        {ok, NewState} ->
            {noreply, NewState};
        _ ->
            {noreply, State}
    end;
handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, #state{sock=LSock, on_shutdown = {M,F,_A}}) ->
    {ok, {IPAddress, Port}} = inet:sockname(LSock),
    gen_tcp:close(LSock),
    ?INFO_MSG("stopped on ~w ~w, reason:~w", [inet_parse:ntoa(IPAddress), Port, Reason]),
    apply(M, F, [IPAddress, Port]).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
