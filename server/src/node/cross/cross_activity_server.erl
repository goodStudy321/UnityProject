%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     跨服活动管理进程，与world_activity_server有一定关联
%%% @end
%%% Created : 05. 八月 2019 11:11
%%%-------------------------------------------------------------------
-module(cross_activity_server).
-author("laijichang").

-include("global.hrl").
-include("activity.hrl").
-include("family_god_beast.hrl").
-include("proto/world_activity_server.hrl").

-behaviour(gen_server).

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
    send_game_world_level/1,
    reload_config/0,
    info/1,
    call/1
]).

-export([
    info_mod/2,
    info_mod_by_time/3,
    call_mod/2
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

reload_config() ->
    info(reload_config).

send_game_world_level(WorldLevel) ->
    info({game_world_level, WorldLevel}).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

info_mod(Mod, Info) ->
    info({mod, Mod, Info}).

info_mod_by_time(TimeMs, Mod, Info) ->
    erlang:send_after(TimeMs, erlang:self(), {mod, Mod, Info}).

call_mod(Mod, Info) ->
    call({mod, Mod, Info}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [0, 1000]),
    pname_server:reg(?MODULE, erlang:self()),
    ets:new(?ETS_ACTIVITY, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_activity.id}]),
    do_reload_config(),
    [execute_mod(world_activity_server:get_activity_mod(ActivityID), init, []) || #r_activity{id = ActivityID} <- get_all_cross_activity()],
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
do_handle(reload_config) ->
    do_reload_config();
do_handle({game_world_level, WorldLevel}) ->
    do_cross_set_world_level(WorldLevel);
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle(zeroclock) ->
    do_zeroclock();
do_handle({gm_start, ID, Remain}) ->
    do_gm_start(ID, Remain);
do_handle({gm_stop, ID, Remain}) ->
    do_gm_stop(ID, Remain);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_reload_config() ->
    [world_activity_server:do_reload_activity(Config) || {_ID, #c_activity{is_cross = IsCross} = Config} <- lib_config:list(cfg_activity), IsCross > 0].

do_loop(Now) ->
    AllActivity = get_all_cross_activity(),
    [?TRY_CATCH(do_loop2(Now, Activity)) || Activity <- AllActivity].

do_loop2(Now, Activity) ->
    #r_activity{
        id = ID,
        status = Status,
        prepare_time = PrepareTime,
        start_time = StartTime,
        end_time = EndTime} = Activity,
    Mod = world_activity_server:get_activity_mod(ID),
    %% 先loop，再处理状态变化，注意这个顺序
    ?IF(Status =:= ?STATUS_OPEN, execute_mod(Mod, loop, [Now]), ok),
    if
        Now >= PrepareTime andalso Status =:= ?STATUS_CLOSE -> %% 准备阶段，可用来清理数据 准备环境
            ?WARNING_MSG("prepare activity, ID:~w", [{ID}]),
            world_activity_server:set_activity(Activity#r_activity{status = ?STATUS_PREPARE, is_cross = true}),
            execute_mod(Mod, activity_prepare, []);
        Now >= StartTime andalso Status =:= ?STATUS_PREPARE -> %% 开启活动
            ?WARNING_MSG("start activity, ID:~w", [{ID}]),
            world_activity_server:set_activity(Activity#r_activity{status = ?STATUS_OPEN, is_cross = true}),
            execute_mod(Mod, activity_start, []);
        Now >= EndTime andalso Status =:= ?STATUS_OPEN -> %% 关闭活动
            ?WARNING_MSG("end activity, ID:~w", [{ID}]),
            world_activity_server:del_activity(ID),
            world_activity_server:do_reload_activity(ID),
            execute_mod(Mod, activity_end, []);
        true ->
            ok
    end.

do_zeroclock() ->
    [?TRY_CATCH(execute_mod(world_activity_server:get_activity_mod(ID), zeroclock, [])) || #r_activity{id = ID} <- get_all_cross_activity()].

execute_mod(Mod, Fun, Args) ->
    world_activity_server:execute_mod(Mod, Fun, Args).

do_gm_start(ID, Remain) ->
    case ets:lookup(?ETS_ACTIVITY, ID) of
        [_Activity] ->
            world_activity_server:do_gm_start(ID, Remain);
        _ ->
            ok
    end.

do_gm_stop(ID, Remain) ->
    case ets:lookup(?ETS_ACTIVITY, ID) of
        [_Activity] ->
            world_activity_server:do_gm_stop(ID, Remain);
        _ ->
            ok
    end.

do_cross_set_world_level(WorldLevel) ->
    OldLevel = world_data:get_world_level(),
    MinLevel = ?IF(OldLevel > 0, erlang:min(OldLevel, WorldLevel), WorldLevel),
    Level = erlang:max(common_misc:get_global_int(?GLOBAL_CROSS_ACTIVITY_LEVEL), MinLevel),
    world_data:set_world_level(Level).
%%%===================================================================
%%% dict
%%%===================================================================
get_all_cross_activity() ->
    ets:tab2list(?ETS_ACTIVITY).