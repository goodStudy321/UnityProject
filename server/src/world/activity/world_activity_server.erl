%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     单服server，注意与cross_activity_server的关联
%%% @end
%%% Created : 14. 七月 2017 19:19
%%%-------------------------------------------------------------------
-module(world_activity_server).
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
    get_all_activity/0,
    get_activity/1,
    reload_config/0,
    info/1,
    call/1
]).

-export([
    get_start_time/5,
    get_broadcast/4
]).

-export([
    info_mod/2,
    info_mod_by_time/3,
    call_mod/2
]).

%% cross_activity_server调用接口
-export([
    do_reload_activity/1,
    del_activity/1,
    get_activity_mod/1,
    execute_mod/3,
    do_gm_start/2,
    do_gm_stop/2,
    set_activity/1
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

reload_config() ->
    info(reload_config).

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
    ets:new(?ETS_ACTIVITY, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_activity.id}]),
    do_reload_config(),
    [execute_mod(get_activity_mod(ID), init, []) || {ID, _Config} <- cfg_activity:list()],
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
do_handle(reload_config) ->
    do_reload_config();
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle(zeroclock) ->
    do_zeroclock(),
    mod_web_common:reset_addict_holiday();  %%  挂载在world_activity_server 每日零点重置  与本系统无关
do_handle({gm_start, ID, Remain}) ->
    do_gm_start(ID, Remain);
do_handle({gm_stop, ID, Remain}) ->
    do_gm_stop(ID, Remain);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_reload_config() ->
    [do_reload_activity(Config) || {_ID, Config} <- cfg_activity:list()].

do_reload_activity(ID) when erlang:is_integer(ID) ->
    [Config] = lib_config:find(cfg_activity, ID),
    do_reload_activity(Config);
do_reload_activity(Config) ->
    #c_activity{
        id = ID,
        day_list = DayList,
        time_list = TimeString,
        last_time = LastTime,
        broadcast_list = BroadcastList} = Config,
    #r_activity{status = NowStatus} = get_activity(ID),
    case NowStatus =:= ?STATUS_OPEN orelse DayList =:= [] of %% 已经开启或者星期数为空
        true ->
            ok;
        _ ->
            Now = time_tool:now(),
            TimeList2 =
            [begin
                 [Hour, Min] = string:tokens(TimeString2, ","),
                 {lib_tool:to_integer(Hour), lib_tool:to_integer(Min)}
             end || TimeString2 <- string:tokens(TimeString, ";")],
            {StartTime, EndTime} = get_start_time(ID, Now, DayList, TimeList2, LastTime, []),
            {BroadcastTime, BroadcastMin} = get_broadcast(Now, StartTime, BroadcastList, []),
            Activity =
            #r_activity{
                id = ID,
                status = ?STATUS_CLOSE,
                prepare_time = StartTime - ?PREPARE_TIME, %% @todo 准备时间现在是默认开始前的10秒
                start_time = StartTime,
                end_time = EndTime,
                broadcast_time = BroadcastTime,
                broadcast_min = BroadcastMin,
                is_cross = get_is_cross(ID)},
            set_activity(Activity)
    end.


%% 获取活动开始的时间

get_start_time(ID, Now, DayList, TimeList2, LastTime, StartAcc) ->
    case ID =:= ?ACTIVITY_FAMILY_BATTLE of
        true ->
            get_especially_start_time(Now, DayList, TimeList2, LastTime, StartAcc);
        _ ->
            get_start_time(Now, DayList, TimeList2, LastTime, StartAcc)
    end.



get_start_time(_Now, [], _TimeList, LastTime, StartAcc) ->
    [First|_] = lists:keysort(1, StartAcc),
    {_Distance, StartTime} = First,
    {StartTime, StartTime + LastTime};
get_start_time(Now, [WeekDay|R], TimeList, LastTime, StartAcc) ->
    StartTime = get_start_time2(Now, WeekDay, TimeList, LastTime, []),
    get_start_time(Now, R, TimeList, LastTime, [StartTime|StartAcc]).

get_start_time2(_Now, _WeekDay, [], _LastTime, StartAcc) ->
    [First|_] = lists:keysort(1, StartAcc),
    First;
get_start_time2(Now, WeekDay, [{Hour, Min}|R], LastTime, StartAcc) ->
    StartTime = time_tool:weekday_timestamp(WeekDay, Hour, Min),
    if
        StartTime >= Now ->
            StartAcc2 = [{StartTime - Now, StartTime}|StartAcc];
        Now - StartTime < LastTime ->
            StartAcc2 = [{0, StartTime}|StartAcc];
        true ->
            NextTime = time_tool:diff_next_weekdaytime(WeekDay, Hour, Min),
            StartAcc2 = [{NextTime, Now + NextTime}|StartAcc]
    end,
    get_start_time2(Now, WeekDay, R, LastTime, StartAcc2).

%%特别开启时间开服X天必定第N天开启（替代本周正常开启时间），之后正常开启
get_especially_start_time(Now, DayList, TimeList2, LastTime, StartAcc) ->
    {OldStartTime, OldEndTime} = get_start_time(Now, DayList, TimeList2, LastTime, StartAcc),
    Day = common_config:get_open_days(),
    case Day < 8 of
        false ->
            {OldStartTime, OldEndTime};
        _ ->
            if
                Day > 3 ->
                    MaxTime = time_tool:nextnight() + (7 - Day) * 86400,
                    case OldStartTime =< MaxTime of
                        true ->
                            {OldStartTime + 604800, OldStartTime + 604800 + LastTime};
                        _ ->
                            {OldStartTime, OldStartTime + LastTime}
                    end;
                Day =:= 3 ->
                    [{Hour, Min}] = TimeList2,
                    case time_tool:midnight() + Hour * 3600 + Min * 60 >= Now of
                        true ->
                            {time_tool:midnight() + Hour * 3600 + Min * 60, time_tool:midnight() + Hour * 3600 + Min * 60 + LastTime};
                        _ ->
                            MaxTime = time_tool:nextnight() + (7 - Day) * 86400,
                            case OldStartTime =< MaxTime of
                                true ->
                                    {OldStartTime + 604800, OldStartTime + 604800 + LastTime};
                                _ ->
                                    {OldStartTime, OldStartTime + LastTime}
                            end
                    end;
                true ->
                    [{Hour, Min}] = TimeList2,
                    StartTime = (2 - Day) * 86400 + time_tool:nextnight() + Hour * 3600 + Min * 60,
                    {StartTime, StartTime + LastTime}
            end
    end.


%% 根据开启时间获取广播时间
get_broadcast(_Now, _StartTime, [], Acc) ->
    case Acc =/= [] of
        true ->
            [{BroadcastTime, BroadcastMin}|_] = lists:keysort(1, Acc),
            {BroadcastTime, BroadcastMin};
        _ ->
            {0, 0}
    end;
get_broadcast(Now, StartTime, [Min|R], Acc) ->
    BroadcastTime = StartTime - Min * ?ONE_MINUTE,
    Acc2 = ?IF(Now >= BroadcastTime, Acc, [{BroadcastTime, Min}|Acc]),
    get_broadcast(Now, StartTime, R, Acc2).

do_loop(Now) ->
    AllActivity = get_all_activity(),
    [?TRY_CATCH(do_loop2(Now, Activity)) || Activity <- AllActivity].

do_loop2(Now, Activity) ->
    #r_activity{
        id = ID,
        status = Status,
        prepare_time = PrepareTime,
        start_time = StartTime,
        end_time = EndTime,
        broadcast_time = BroadcastTime,
        broadcast_min = BroadcastMin} = Activity,
    Mod = get_activity_mod(ID),
    %% 先loop，再处理状态变化，注意这个顺序
    ?IF(Status =:= ?STATUS_OPEN, execute_mod(Mod, loop, [Now]), ok),
    Minutes = common_misc:get_global_int(?GLOBAL_ACTIVITY_REMIND),
    case Now =:= StartTime - ?ONE_MINUTE * Minutes of  %% 部分活动处理 开始前X分钟发协议给客户端显示活动图标（活动并未开始）
        true ->
            ?WARNING_MSG("before minutes activity, ID:~w", [{ID}]),
            DataRecords = #m_activity_info_toc{activity_list = [#p_activity{id = ID, status = ?STATUS_BEFORE_MINUTES, end_time = StartTime}]}, %% 此时发给客户端的end_time是活动的开始时间
            ?IF(lists:member(ID, ?ACTIVITY_LIST), do_broadcast_activity(ID, DataRecords), ok);
        _ ->
            ok
    end,
    if
        Now >= BroadcastTime andalso BroadcastTime =/= 0 -> %% 广播
            ?WARNING_MSG("broadcast, ID:~w, Min:~w", [ID, BroadcastMin]),
            do_reload_activity(ID);
        Now >= PrepareTime andalso Status =:= ?STATUS_CLOSE -> %% 准备阶段，可用来清理数据 准备环境
            ?WARNING_MSG("prepare activity, ID:~w", [{ID}]),
            set_activity(Activity#r_activity{status = ?STATUS_PREPARE}),
            execute_mod(Mod, activity_prepare, []);
        Now >= StartTime andalso Status =:= ?STATUS_PREPARE -> %% 开启活动
            ?WARNING_MSG("start activity, ID:~w", [{ID}]),
            set_activity(Activity#r_activity{status = ?STATUS_OPEN, is_cross = get_is_cross(ID)}),
            execute_mod(Mod, activity_start, []),
            DataRecord = #m_activity_info_toc{activity_list = [#p_activity{id = ID, status = ?STATUS_OPEN, end_time = EndTime}]},
            do_broadcast_activity(ID, DataRecord),
            [#c_activity{broadcast_id = BroadcastID}] = lib_config:find(cfg_activity, ID),
            ?IF(BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, []), ok);
        Now >= EndTime andalso Status =:= ?STATUS_OPEN -> %% 关闭活动
            ?WARNING_MSG("end activity, ID:~w", [{ID}]),
            del_activity(ID),
            do_reload_activity(ID),
            execute_mod(Mod, activity_end, []),
            DataRecord = #m_activity_info_toc{activity_list = [#p_activity{id = ID, status = ?STATUS_CLOSE, end_time = EndTime}]},
            do_broadcast_activity(ID, DataRecord);
        true ->
            ok
    end.

do_zeroclock() ->
    ?INFO_MSG("-------------------~w",["world_activity_server_do_zeroclock"]),
    [?TRY_CATCH(execute_mod(get_activity_mod(ID), zeroclock, [])) || #r_activity{id = ID} <- get_all_activity()].

get_activity_mod(ID) ->
    case lists:keyfind(ID, #c_activity_mod.activity_id, ?ACTIVITY_MOD_LIST) of
        #c_activity_mod{mod = Mod} ->
            Mod;
        _ ->
            undefined
    end.

execute_mod(Mod, Fun, Args) ->
    case erlang:function_exported(Mod, Fun, erlang:length(Args)) of
        true ->
            ?TRY_CATCH(erlang:apply(Mod, Fun, Args));
        _ ->
            ignore
    end.

do_broadcast_activity(ID, DataRecord) ->
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ID),
    common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = MinLevel}).

do_gm_start(ID, Remain) ->
    #r_activity{status = Status} = Activity = get_activity(ID),
    case Status =:= ?STATUS_OPEN of
        true ->
            ok;
        _ ->
            Now = time_tool:now(),
            StartTime = Now + do_get_gm_remain_time(Remain),
            [#c_activity{last_time = LastTime}] = lib_config:find(cfg_activity, ID),
            Activity2 = Activity#r_activity{
                status = ?STATUS_CLOSE,
                prepare_time = Now,
                start_time = StartTime,
                end_time = StartTime + LastTime,
                broadcast_time = 0,
                broadcast_min = 0
            },
            set_activity(Activity2)
    end.

do_gm_stop(ID, Remain) ->
    #r_activity{status = Status} = Activity = get_activity(ID),
    case Status =:= ?STATUS_OPEN of
        true ->
            Now = time_tool:now(),
            set_activity(Activity#r_activity{end_time = Now + do_get_gm_remain_time(Remain)}),
            ?IF(ID =:= ?ACTIVITY_FAMILY_BATTLE, mod_family_bt:gm_end(), ok),
            ?IF(ID =:= ?ACTIVITY_ANSWER, mod_answer:gm_activity_end(), ok);
        _ ->
            ok
    end.

do_get_gm_remain_time(Remain) ->
    case Remain of
        [Time] ->
            Time;
        _ ->
            0
    end.

get_is_cross(ID) ->
    case common_config:is_cross_node() of
        true -> %% 如果是跨服节点
            true;
        _ when ID =:= ?ACTIVITY_SOLO ->
            [#c_activity{is_cross = IsCross}] = lib_config:find(cfg_activity, ID),
            IsCross > 0;
        _ ->
            [#c_activity{is_cross = IsCross}] = lib_config:find(cfg_activity, ID),
            IsCross > 0 andalso world_data:get_world_level() >= common_misc:get_global_int(?GLOBAL_CROSS_ACTIVITY_LEVEL)
    end.

%%%===================================================================
%%% dict
%%%===================================================================
get_all_activity() ->
    ets:tab2list(?ETS_ACTIVITY).

set_activity(Activity) ->
    ets:insert(?ETS_ACTIVITY, Activity).
get_activity(ID) ->
    case ets:lookup(?ETS_ACTIVITY, ID) of
        [#r_activity{} = Activity] ->
            Activity;
        _ ->
            #r_activity{id = ID}
    end.
del_activity(ID) ->
    ets:delete(?ETS_ACTIVITY, ID).

