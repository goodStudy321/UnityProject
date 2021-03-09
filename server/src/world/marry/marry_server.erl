%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 11:56
%%%-------------------------------------------------------------------
-module(marry_server).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").

%% API
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
    call/1,
    info_mod/2,
    call_mod/2
]).

-export([
    role_online/1,
    gm_start_feast/2,
    gm_stop_feast/1,
    gm_clear_appoint/1
]).

i() ->
    call(i).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

info_mod(Mod, Info) ->
    info({mod, Mod, Info}).

call_mod(Mod, Info) ->
    call({mod, Mod, Info}).

role_online(RoleID) ->
    info({role_online, RoleID}).

gm_start_feast(RoleID, Remain) ->
    info_mod(mod_marry_feast, {gm_start_feast, RoleID, Remain}).

gm_stop_feast(RoleID) ->
    info_mod(mod_marry_feast, {gm_stop_feast, RoleID}).

gm_clear_appoint(RoleID) ->
    info_mod(mod_marry_feast, {gm_clear_appoint, RoleID}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    mod_marry_data:init(),
    time_tool:reg(world, [0, 1000]),
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
    time_tool:dereg(world, [0, 1000]),
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
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle(?TIME_ZERO) ->
    do_zero();
do_handle({role_online, RoleID}) ->
    do_role_online(RoleID);
do_handle(i) ->
    erlang:get();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_loop(Now) ->
    FuncList = [
        fun() -> mod_marry_propose:loop(Now) end,
        fun() -> mod_marry_feast:loop(Now) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList].

do_zero() ->
    FuncList = [
        fun() -> mod_marry_feast:zero() end
    ],
    [?TRY_CATCH(F()) || F <- FuncList].

do_role_online(RoleID) ->
    FuncList = [
        fun() -> mod_marry_feast:role_online(RoleID) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList].