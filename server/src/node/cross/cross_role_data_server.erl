%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     跨服角色数据
%%% @end
%%% Created : 23. 二月 2019 16:41
%%%-------------------------------------------------------------------
-module(cross_role_data_server).
-author("laijichang").
-include("node.hrl").
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
    code_change/3
]).

-export([
    update_role_cross_data/1,
    get_role_cross_datas/1,
    get_role_cross_data/1
]).

-export([
    get_role_data/1
]).

start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

update_role_cross_data(RoleCrossData) ->
    info({update_role_cross_data, RoleCrossData}).

get_role_cross_datas(RoleList) ->
    call({get_role_cross_datas, RoleList}).

get_role_cross_data(RoleID) ->
    call({get_role_cross_data, RoleID}).

info(Info) ->
    pname_server:send(pname_server:pid(?MODULE), Info).

call(Info) ->
    pname_server:call(pname_server:pid(?MODULE), Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
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
do_handle({update_role_cross_data, RoleCrossData}) ->
    do_update_role_cross_data(RoleCrossData);
do_handle({get_role_cross_datas, RoleList}) ->
    do_get_role_cross_datas(RoleList);
do_handle({get_role_cross_data, RoleID}) ->
    get_role_data(RoleID);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_update_role_cross_data(RoleCrossData) ->
    set_role_data(RoleCrossData).

do_get_role_cross_datas(RoleList) ->
     [ get_role_data(RoleID) || RoleID <- RoleList].

%%%===================================================================
%%% data
%%%===================================================================
set_role_data(RoleCrossData) ->
    db:insert(?DB_ROLE_CROSS_DATA_P, RoleCrossData).
get_role_data(RoleID) ->
    case ets:lookup(?DB_ROLE_CROSS_DATA_P, RoleID) of
        [RoleCrossData] ->
            RoleCrossData;
        _ ->
            undefined
    end.