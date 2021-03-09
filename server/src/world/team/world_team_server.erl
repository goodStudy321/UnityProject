%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十月 2017 19:30
%%%-------------------------------------------------------------------
-module(world_team_server).
-include("global.hrl").

%% API
-export([
    i/0,
    start/0,
    start_link/0,
    handle/1,
    is_team_server/0
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

i() ->
    pname_server:call(?MODULE, i).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

handle(Info)->
    do_handle(Info).

is_team_server() ->
    erlang:get(team_server) =:= true.

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:put(team_server, true),
    mod_team_data:init(),
    erlang:send_after(?ONE_MINUTE * 1000, erlang:self(), loop_min),
    time_tool:reg(world, [1000]),
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
    time_tool:dereg(world, [1000]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({loop_sec, Now}) ->
    mod_team:loop(Now);
do_handle(loop_min) ->
    erlang:send_after(?ONE_MINUTE * 1000, erlang:self(), loop_min),
    mod_team:loop_min();
do_handle(i) ->
    erlang:get();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%%%===================================================================
%%% 数据操作
%%%===================================================================