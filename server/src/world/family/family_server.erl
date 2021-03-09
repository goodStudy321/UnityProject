%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     帮派进程
%%% @end
%%% Created : 13. 十月 2017 17:07
%%%-------------------------------------------------------------------
-module(family_server).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    start/0,
    start_link/0,
    handle/1,
    is_family_server/0,
    info_family/1,
    add_box/4,
    add_box_by_role/3
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


info_family(Info) ->
    pname_server:send(?MODULE, Info).

add_box(Type, Value, FamilyID , RoleID) ->
    pname_server:send(?MODULE, {func, mod_family_box, add_box, [Type, Value, FamilyID,RoleID]}).

add_box_by_role(Type, Value, RoleID) ->
    pname_server:send(?MODULE, {func, mod_family_box, add_box_by_role, [Type, Value, RoleID]}).


start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

handle(Info) ->
    do_handle(Info).

is_family_server() ->
    erlang:get(is_family_server) =:= true.

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:put(is_family_server, true),
    mod_family_data:init(),
    hook_family:init(),
    time_tool:reg(world, [0]),
    Delayed = 3600 - time_tool:now() rem 3600,
    erlang:send_after(Delayed * 1000, self(), integer_hour),
    erlang:send_after(?TEN_MINUTE * 1000, self(), loop_10min),
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
    time_tool:dereg(world, [0]),
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
do_handle(zeroclock) ->
    ?IF(time_tool:weekday() =:= 1, hook_family:family_week_refresh(), ok),
    hook_family:family_day_refresh();
do_handle(loop_10min) ->
    erlang:send_after(?TEN_MINUTE * 1000, self(), loop_10min),
    mod_family_briefs:loop_10min();
do_handle(integer_hour) ->
    erlang:send_after(?AN_HOUR * 1000, self(), integer_hour),
    hook_family:loop_integer_hour();
do_handle(check_need_create_family) ->
    family_misc:check_need_create_family();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%%%===================================================================
%%% 数据操作
%%%===================================================================