%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 九月 2019 16:00
%%%-------------------------------------------------------------------
-module(world_cycle_act_server).
-author("WZP").
-include("cycle_act.hrl").
-include("global.hrl").
-include("proto/mod_role_cycle_act.hrl").
-include("proto/mod_role_act_lucky_cat.hrl").

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
    info/1,
    call/1,
    info_mod/2,
    call_mod/2
]).

-export([
    reload_config/0
]).

-export([
    is_act_open/1,
    get_all_act/0,
    get_act_config_num/1,
    get_all_open_act/1,
    get_act/1,
    trans_to_p_cycle_act/1,
    get_act_config/1,
    get_time_by_week_day/3,
    get_new_open_info/3
]).

-export([
    add_luckycat_logs/1
]).

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

add_luckycat_logs(LogList) ->
    info({add_luckycat_logs, LogList}).

reload_config() ->
    info(reload_config).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    do_reload_config(),
    time_tool:reg(world, [0, 1000, ?HOUR_CHANGE]),
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
    ?WARNING_MSG("-----------_Reason----------------~w", [_Reason]),
    List = get_all_act(),
    [hook_cycle_act:terminate(ID) || #r_cycle_act{status = Status, id = ID} <- List, Status =:= ?CYCLE_ACT_STATUS_OPEN],
    time_tool:dereg(world, [0, 1000]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({add_luckycat_logs, LogList}) ->
    do_add_luckycat_logs(LogList);
do_handle(reload_config) ->
    do_reload_config();
do_handle({add_egg_log, RareLogs, NormalLogs}) ->
    hook_cycle_act:add_egg_log(RareLogs, NormalLogs);
do_handle({?HOUR_CHANGE, Now}) ->
    do_hour_change(Now);
do_handle(zeroclock) ->
    do_reload_config_zeroclock();
do_handle({loop_sec, Now}) ->
    do_reload_config_loop_sec(Now);
do_handle({gm_start, ID}) ->
    do_gm_status(ID, ?CYCLE_ACT_STATUS_OPEN);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({gm_stop, ID}) ->
    do_gm_status(ID, ?CYCLE_ACT_STATUS_CLOSE);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).


do_reload_config() ->
    Now = time_tool:now(),
    [do_check_act(Config, Now) || {_ID, Config} <- cfg_cycle_act:list()].

do_hour_change(Now) ->
    [?IF(is_act_open(ID), ?TRY_CATCH(hook_cycle_act:hour_change(Now, ID)), ok) || {ID, _Config} <- cfg_cycle_act:list()].

do_reload_config_zeroclock() ->
    Now = time_tool:now(),
    [begin
         BeforeZero = time_tool:midnight(Now - 3600) + ?ONE_DAY - 1,    %%确保处理   {23, 59, 59}
         do_check_act(Config, BeforeZero),
         ?IF(is_act_open(ID), ?TRY_CATCH(hook_cycle_act:zero(ID)), ok),
         do_check_act(Config, Now)
     end || {ID, Config} <- cfg_cycle_act:list()].

do_reload_config_loop_sec(Now) ->
    [do_check_act(Config, Now) || {_ID, Config} <- cfg_cycle_act:list(), hour_span(Now)].

hour_span(Now) ->
    case time_tool:timestamp_to_datetime(Now) of
        {_, {23, 59, 59}} ->
            false;
        {_, {_, 59, 59}} ->
            true;
        {_, {_, 29, 59}} ->
            true;
        _ ->
            false
    end.



do_check_act(ID, Now) when erlang:is_integer(ID) ->
    [Config] = lib_config:find(cfg_cycle_act, ID),
    do_check_act(Config, Now);
do_check_act(Config, Now) ->
    #c_cycle_act{
        id = ID,
        level = MinLevel
    } = Config,
    #r_cycle_act{
        status = OldStatus,
        is_gm_set = IsGmeSet,
        start_time = OldStartTime,
        end_time = OldEndTime,
        first_day_open = FirstDayOpen
    } = Act = get_act(ID),
    if
        IsGmeSet ->
            StartTime2 = OldStartTime,
            EndTime2 = OldEndTime,
            NowStatus = OldStatus,
            OpenType = ?CYCLE_ACT_GM_OPEN,
            FirstDayOpen2 = true;
        true ->
            {NowStatus, StartTime2, EndTime2, OpenType, FirstDayOpen2} = get_new_open_info(Now, FirstDayOpen, Config)
    end,
    Act2 = Act#r_cycle_act{
        first_day_open = FirstDayOpen2,
        level = MinLevel,
        status = NowStatus,
        start_time = StartTime2,
        end_time = EndTime2},
    if
        NowStatus =/= OldStatus andalso NowStatus =:= ?CYCLE_ACT_STATUS_OPEN ->
            ConfigNum = hook_cycle_act:get_config_num(ID),
            Act3 = Act2#r_cycle_act{open_type = OpenType, config_num = ConfigNum},
            hook_cycle_act:init_cycle_act(Act3),
            DataRecord = #m_cycle_update_toc{act = trans_to_p_cycle_act(Act3)},
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = MinLevel}),
            common_broadcast:bc_role_info_to_world({mod, mod_role_cycle_act, {act_update, ID, NowStatus, Act3#r_cycle_act.start_time, Act3#r_cycle_act.config_num, MinLevel}}),
            set_act(Act3);
        NowStatus =/= OldStatus andalso NowStatus =:= ?CYCLE_ACT_STATUS_CLOSE ->
            hook_cycle_act:cycle_act_end(Act2),
            DataRecord = #m_cycle_update_toc{act = trans_to_p_cycle_act(Act2)},
            common_broadcast:bc_role_info_to_world({mod, mod_role_cycle_act, {act_update, ID, NowStatus, Act#r_cycle_act.start_time, Act#r_cycle_act.config_num, MinLevel}}),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = MinLevel}),
            set_act(Act2);
        true ->
            ok
    end.


%%  EndTime  统一为23:59:59   而非 0:0:0       FirstDayOpen     不经历第一天就不开启
get_new_open_info(Now, FirstDayOpen, Config) ->
    #c_cycle_act{
        open_day = OpenDay,                              %% 活动时长
        server_open_day = ServerOpenDayList,             %% 开服天数
        open_time = OpenTimeString,                      %% 开启日期
        limited_time = LimitedTime,                      %% 开服几天后进入月循环
        month_loop = MonthLoopString                     %% 月循环
    } = Config,
    NowOpenDay = common_config:get_open_days_by_time(Now),
    case LimitedTime < NowOpenDay of
        false ->%%开服天数
            {Status, StartTime, EndTime, FirstDayOpen2} = get_new_open_info_a(ServerOpenDayList, OpenDay, Now, LimitedTime, FirstDayOpen),
            {Status, StartTime, EndTime, ?CYCLE_ACT_FIRST_OPEN, FirstDayOpen2};
        _ ->
            %%   默认   日期开启与月循环无交集
            case get_new_open_info_i(MonthLoopString, OpenDay, Now, FirstDayOpen) of
                {ok, ?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime, FirstDayOpen2} ->
                    {?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime, ?CYCLE_ACT_SECOND_OPEN, FirstDayOpen2};
                _ ->
                    case OpenTimeString of
                        [Year, Month, Day] ->
                            StartTime = time_tool:timestamp({Year, Month, Day}),
                            EndTime = StartTime + OpenDay * ?ONE_DAY - 1,  %%减1秒 23:59:59
                            {Status, FirstDayOpen2} = case FirstDayOpen of
                                                          true ->
                                                              case Now >= StartTime andalso EndTime > Now of
                                                                  true ->
                                                                      {?CYCLE_ACT_STATUS_OPEN, true};
                                                                  _ ->
                                                                      {?CYCLE_ACT_STATUS_CLOSE, true}
                                                              end;
                                                          _ ->
                                                              case Now >= StartTime andalso (StartTime + ?ONE_DAY) > Now of
                                                                  true ->
                                                                      {?CYCLE_ACT_STATUS_OPEN, true};
                                                                  _ ->
                                                                      {?CYCLE_ACT_STATUS_CLOSE, false}
                                                              end
                                                      end,
                            {Status, StartTime, EndTime, ?CYCLE_ACT_THIRD_OPEN, FirstDayOpen2};
                        _ ->
                            {?CYCLE_ACT_STATUS_CLOSE, 0, 0, ?CYCLE_ACT_NO_OPEN, false}
                    end
            end
    end.


get_new_open_info_a([], _OpenDay, _Now, _LimitedTime, _FirstDayOpen) ->
    {?CYCLE_ACT_STATUS_CLOSE, 0, 0, false};
get_new_open_info_a([ServerOpenDay|T], OpenDay, Now, LimitedTime, FirstDayOpen) ->
    OpenTime = common_config:get_open_time(),
    StartTime = case ServerOpenDay =:= 1 of
                    true ->
                        time_tool:midnight(OpenTime);
                    _ ->
                        time_tool:midnight(OpenTime) + (ServerOpenDay - 1) * ?ONE_DAY    %%减1天
                end,
    EndTime = case ServerOpenDay =:= 1 of
                  true ->
                      time_tool:midnight(StartTime) + OpenDay * ?ONE_DAY - 1;    %%减1秒  23:59:59
                  _ ->
                      StartTime + OpenDay * ?ONE_DAY - 1                               %%减1秒 23:59:59
              end,
    EndTime2 = time_tool:midnight(OpenTime) + ?ONE_DAY * LimitedTime - 1,
    EndTime3 = erlang:min(EndTime, EndTime2),
    case Now >= StartTime andalso EndTime3 > Now of
        true ->
            {?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime3, true};
        _ ->
            get_new_open_info_a(T, OpenDay, Now, LimitedTime, FirstDayOpen)
    end.




get_new_open_info_i(MonthLoopString, OpenDay, Now, FirstDayOpen) ->
    List = lib_tool:string_to_intlist(MonthLoopString),
    check_month_loop_list(List, OpenDay, Now, FirstDayOpen).

check_month_loop_list([], _OpenDay, _Now, _FirstDayOpen) ->
    false;
check_month_loop_list([{Week, Day}|T], OpenDay, Now, FirstDayOpen) ->
    StartTime = get_time_by_week_day(Week, Day, Now),
    EndTime = StartTime + OpenDay * ?ONE_DAY - 1,   %%减1秒 23:59:59
    case FirstDayOpen of
        true ->
            case Now >= StartTime andalso EndTime > Now of
                true ->
                    {ok, ?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime, true};
                _ ->
                    check_month_loop_list(T, OpenDay, Now, FirstDayOpen)
            end;
        _ ->
            case Now >= StartTime andalso (StartTime + ?ONE_DAY) > Now of
                true ->
                    {ok, ?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime, true};
                _ ->
                    check_month_loop_list(T, OpenDay, Now, FirstDayOpen)
            end
    end.


%%  1，6；2，5 ——》  第一周的第六天和第二周的第五天
%%  每周 周一为第一天
%%  周一所在的月份为这周的所在月份
%%  得到当前时间的当月第Week周，第Day天时间戳
get_time_by_week_day(Week, Day, Time) ->
    DayOfWeek = time_tool:weekday(Time),
    MondayTime = Time - (DayOfWeek - 1) * ?ONE_DAY,
    {TimeYear, TimeMonth, _TimeDay} = time_tool:timestamp_to_date(MondayTime),
    MonthBeginTime = time_tool:timestamp({TimeYear, TimeMonth, 1}),
    DayOfWeek2 = time_tool:weekday(MonthBeginTime),
    FirstMonday = case DayOfWeek2 =:= 1 of   %%得到当月第一个星期一时间戳
                      true ->
                          MonthBeginTime;
                      _ ->
                          (8 - DayOfWeek2) * ?ONE_DAY + MonthBeginTime
                  end,
    FirstMonday + (Week - 1) * ?ONE_WEEK + (Day - 1) * ?ONE_DAY.


%%get_right_day(_NowDay, [], _OpenDay) ->
%%    {?CYCLE_ACT_STATUS_CLOSE, 0, 0};
%%get_right_day(NowDay, [Day|T], OpenDay) ->
%%    case NowDay >= Day andalso (OpenDay + Day) > NowDay of
%%        true ->
%%            OpenTime = common_config:get_open_time(),
%%            StartTime = case Day =:= 1 of
%%                            true ->
%%                                OpenTime;
%%                            _ ->
%%                                time_tool:midnight(OpenTime) + (Day - 1) * ?ONE_DAY    %%减1天
%%                        end,
%%            EndTime = case Day =:= 1 of
%%                          true ->
%%                              time_tool:midnight(StartTime) + OpenDay * ?ONE_DAY - 1;    %%减1秒
%%                          _ ->
%%                              StartTime + OpenDay * ?ONE_DAY - 1
%%                      end,
%%
%%            {?CYCLE_ACT_STATUS_OPEN, StartTime, EndTime};
%%        _ ->
%%            get_right_day(NowDay, T, OpenDay)
%%    end.

do_add_luckycat_logs(LogList) ->
    OldLogList = world_data:get_lucky_cat_logs(),
    LogList2 = lists:sublist(LogList ++ OldLogList, 30),
    world_data:set_lucky_cat_logs(LogList2),
    DataRecord = #m_luckycat_log_update_toc{logs = LogList},
    common_broadcast:bc_record_to_world(DataRecord).


do_gm_status(ID, NowStatus) ->
    #r_cycle_act{status = Status} = Act = get_act(ID),
    case Status =:= NowStatus of
        true ->
            ok;
        _ ->
            Now = time_tool:now(),
            {StartTime, EndTime} =
            if
                NowStatus =:= ?CYCLE_ACT_STATUS_OPEN ->
                    {Now, Now + 3600 * 240};
                NowStatus =:= ?CYCLE_ACT_STATUS_CLOSE ->
                    {0, Now - 10}
            end,
            [#c_cycle_act{level = Level}] = lib_config:find(cfg_cycle_act, ID),
            ConfigNum = hook_cycle_act:get_config_num(ID),
            set_act(Act#r_cycle_act{is_gm_set = true, start_time = StartTime, end_time = EndTime, status = NowStatus, level = Level, config_num = ConfigNum,
                                    open_type = ?CYCLE_ACT_NO_OPEN}),
            Act3 = get_act(ID),
            DataRecord = #m_cycle_update_toc{act = trans_to_p_cycle_act(Act3)},
            common_broadcast:bc_role_info_to_world({mod, mod_role_cycle_act, {act_update, ID, NowStatus, StartTime, ConfigNum, Level}}),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = Level}),
            ?IF(NowStatus =:= ?CYCLE_ACT_STATUS_CLOSE, hook_cycle_act:cycle_act_end(Act3), ok)
    end.


%%%===================================================================
%%% 数据操作
%%%===================================================================

get_act_config(ID) ->
    ID2 = case ID > 9999 of
              true ->
                  lib_tool:to_integer(string:substr(lib_tool:to_list(ID), 1, 4));
              _ ->
                  ID
          end,
    lib_config:find(cfg_cycle_act, ID2).

is_act_open(ID) ->
    #r_cycle_act{status = Status} = get_act(ID),
    Status =:= ?CYCLE_ACT_STATUS_OPEN.

get_all_act() ->
    ets:tab2list(?DB_R_CYCLE_ACT_P).

get_all_open_act(Level) ->
    List = ets:tab2list(?DB_R_CYCLE_ACT_P),
    [Act || #r_cycle_act{status = Status, level = NeedLevel} = Act <- List, Status =:= ?CYCLE_ACT_STATUS_OPEN, Level >= NeedLevel].

set_act(Act) ->
    db:insert(?DB_R_CYCLE_ACT_P, Act).
get_act(ID) ->
    case db:lookup(?DB_R_CYCLE_ACT_P, ID) of
        [#r_cycle_act{} = Act] ->
            Act;
        _ ->
            #r_cycle_act{id = ID}
    end.

get_act_config_num(ID) ->
    case ets:lookup(?DB_R_CYCLE_ACT_P, ID) of
        [#r_cycle_act{config_num = ConfigNum}] ->
            ConfigNum;
        _ ->
            1
    end.

trans_to_p_cycle_act(Act) ->
    #r_cycle_act{
        id = ID,
        status = NowStatus,
        start_time = StartTime2,
        config_num = ConfigNum,
        end_time = EndTime2}
    = Act,
    #p_cycle_act{
        id = ID,
        val = NowStatus,
        start_time = StartTime2,
        config_num = ConfigNum,
        end_time = EndTime2
    }.


