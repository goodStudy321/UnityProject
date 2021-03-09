%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 七月 2017 12:24
%%%-------------------------------------------------------------------
-module(world_offline_event_server).
-author("laijichang").

-behaviour(gen_server).
-include("global.hrl").

%% API
-export([
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
    code_change/3]).

-export([
    role_online/1,
    add_event/2
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 参数没有带State，注意
add_event(RoleID, MFA) ->
    info({add_event, RoleID, MFA}).

role_online(RoleID) ->
    call({role_online, RoleID}).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
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
do_handle({add_event, RoleID, MFA}) ->
    do_add_event(RoleID, MFA);
do_handle({role_online, RoleID}) ->
    do_role_online(RoleID);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_add_event(RoleID, MFA) ->
    #r_role_offline_event{event_list = EventList} = RoleOffline = get_role_offline(RoleID),
    RoleOffline2 = RoleOffline#r_role_offline_event{event_list = [MFA|EventList]},
    set_role_offline(RoleOffline2).

do_role_online(RoleID) ->
    #r_role_offline_event{event_list = EventList} = RoleOffline = get_role_offline(RoleID),
    set_role_offline(RoleOffline#r_role_offline_event{event_list = []}),
    lists:reverse(EventList).

%%%===================================================================
%%% dict
%%%===================================================================
get_role_offline(RoleID) ->
    case db:lookup(?DB_OFFLINE_EVENT_P, RoleID) of
        [#r_role_offline_event{} = RoleOffline] ->
            RoleOffline;
        _ ->
            #r_role_offline_event{role_id = RoleID}
    end.

set_role_offline(RoleOffline) ->
    db:insert(?DB_OFFLINE_EVENT_P, RoleOffline).