%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 防沉迷服务
%%% @end
%%% Created : 6. 八月 2018
%%%-------------------------------------------------------------------
-module(center_addict_server).
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
    get_addict_info/3,
    add_addict_info/4,
    add_addict_info/5
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%% @doc 获取防沉迷信息
get_addict_info(AgentID, GameChannelID, UID) ->
    pname_server:call(?MODULE, {get_addict_info, AgentID, GameChannelID, UID}).

%%  @doc 增加防沉迷信息
add_addict_info(AgentID, GameChannelID, UID, IsPassed) ->
    add_addict_info(AgentID, GameChannelID, UID, IsPassed, ?IF(IsPassed, 18, 14)).
add_addict_info(AgentID, GameChannelID, UID, IsPassed, Age) ->
    pname_server:send(?MODULE, {add_addict_info, AgentID, GameChannelID, UID, IsPassed, Age}).

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
do_handle({get_addict_info, AgentID, GameChannelID, UID}) ->
    do_get_addict_info(AgentID, GameChannelID, UID);
do_handle({add_addict_info, AgentID, GameChannelID, UID, IsPassed, Age}) ->
    do_add_addict_info(AgentID, GameChannelID, UID, IsPassed, Age);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%% 获取防沉迷信息
do_get_addict_info(AgentID, GameChannelID, UID) ->
    case get_center_addict({AgentID, GameChannelID, UID}) of
        [#r_center_addict{is_auth = IsAuth, is_passed = IsPassed, age = Age}] ->
            {ok, IsAuth, IsPassed, Age};
        _ ->
            false
    end.

%% 验证完增加防沉迷信息
do_add_addict_info(AgentID, GameChannelID, UID, IsPassed, Age) ->
    CenterAddict = #r_center_addict{key = {AgentID, GameChannelID, UID}, is_auth = true, is_passed = IsPassed, age = Age},
    set_center_addict(CenterAddict).

%%%===================================================================
%%% dict
%%%===================================================================
get_center_addict(Key) ->
    ets:lookup(?DB_CENTER_ADDICT_P, Key).
set_center_addict(CenterAddict) ->
    db:insert(?DB_CENTER_ADDICT_P, CenterAddict).