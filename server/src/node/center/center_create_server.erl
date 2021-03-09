%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十月 2018
%%%-------------------------------------------------------------------
-module(center_create_server).
-author("laijichang").
-behaviour(gen_server).
-include("node.hrl").

-export([
    start/0,
    start_link/0
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    report_create/4
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

report_create(AgentID, ServerID, GameChannelID, UID) ->
    pname_server:call(?MODULE, {report_create, AgentID, ServerID, GameChannelID, UID}).

%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    pname_server:reg(?MODULE, erlang:self()),
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
    pname_server:dereg(?MODULE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({report_create, AgentID, ServerID, GameChannelID, UID}) ->
    do_report_create(AgentID, ServerID, GameChannelID, UID);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_report_create(AgentID, ServerID, GameChannelID, UID) ->
    Key = {AgentID, GameChannelID, UID},
    case get_center_create(Key) of
        [#r_center_create{first_server_id = FirstServerID}] ->
            IsOld = ?IF(ServerID =:= FirstServerID, ?FALSE, ?TRUE),
            {ok, IsOld};
        _ ->
            CenterAddict = #r_center_create{key = Key, first_server_id = ServerID},
            set_center_create(CenterAddict),
            {ok, 0}
    end.

%%%===================================================================
%%% dict
%%%===================================================================
get_center_create(Key) ->
    ets:lookup(?DB_CENTER_CREATE_P, Key).
set_center_create(CenterAddict) ->
    db:insert(?DB_CENTER_CREATE_P, CenterAddict).