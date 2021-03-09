-module(gateway_tcp_acceptor).

-behaviour(gen_server).
-include("common.hrl").

-export([start_link/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-record(state, {listen_socket, ref, callback}).

%%--------------------------------------------------------------------

start_link(Callback, LSock) ->
    gen_server:start_link(?MODULE, {Callback, LSock}, []).

%%--------------------------------------------------------------------

init({Callback, LSock}) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{listen_socket=LSock, callback = Callback}}.

handle_info({event, start}, State) ->
    accept(State);

handle_info({inet_async, LSock, Ref, {ok, Sock}}, 
    State = #state{listen_socket = LSock, ref = Ref, callback = Callback}) ->
    %% patch up the socket so it looks like one we got from
    %% gen_tcp:accept/1
    {ok, Mod} = inet_db:lookup_socket(LSock),
    inet_db:register_socket(Sock, Mod),
    try        
        %% report
        {ok, {Address, Port}} = inet:sockname(LSock),
        {ok, {PeerAddress, PeerPort}} = inet:peername(Sock),
        ?DEBUG("accepted TCP connection on ~s:~p from ~s:~p~n",
                    [inet_parse:ntoa(Address), Port,
                     inet_parse:ntoa(PeerAddress), PeerPort]),
        do_callback(Sock, Callback)
    catch Error:Reason ->
            gen_tcp:close(Sock),
            ?INFO_MSG("unable to accept TCP connection: ~p ~p~n", [Error, Reason])
    end,
    accept(State);
handle_info({inet_async, LSock, Ref, {error, closed}}, State=#state{listen_socket=LSock, ref=Ref}) ->
    %% It would be wrong to attempt to restart the acceptor when we
    %% know this will fail.
    {stop, normal, State};

handle_info({'EXIT', _, shutdown}, State) ->    
    {stop, normal, State};
handle_info({'EXIT', _, _Reason}, State) ->
    {noreply, State};


handle_info(Info, State) ->
    ?INFO_MSG("~ts:~w", ["收到未知消息", Info]),
    {noreply, State}.


handle_call(_Request, _From, State) ->
    {noreply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("get msg from handle_case/2 ~w ~w", [Msg, State]),
    {noreply, State}.


terminate(Reason, _State) ->
    ?DEBUG("~ts:~w", ["acceptor进程结束", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 收到新链接时执行callback
do_callback(Sock, {M, F, Args}) ->
    erlang:apply(M, F, Args ++ [Sock]).

accept(State = #state{listen_socket=LSock}) ->
    case prim_inet:async_accept(LSock, -1) of
        {ok, Ref} -> 
            {noreply, State#state{ref=Ref}};
        _Error ->             
            {noreply, State}
    end.
