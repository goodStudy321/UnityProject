%%%-------------------------------------------------------------------
%%% 
%%% @doc
%%%     时间相关服务
%%% @end
%%%-------------------------------------------------------------------
-module(time_tool).

-export([
    start_server/3,
    reg/2,
    reg/3,
    dereg/2,
    dereg/3,
    reset_hour_change/1,
    reg_pids/2
]).


-export([
    now_tuple/0,
    now_cached/1,
    now_ms_cached/1,
    now/0,
    now_ms/0,
    date/0,
    get_time_tuple/0,
    now_os/0,
    now_os_ms/0,
    now_us/0]).

-export([
    midnight/0,
    midnight/1,
    nextnight/0,
    time_to_sec/1,
    timestamp/1,
    timestamp_to_datetime/1,
    timestamp_to_date/1,
    weekday/0,
    weekday/1,
    day_of_year/0,
    day_of_year/1,
    week_of_year/0,
    week_of_year/1,
    is_same_week/1,
    is_same_week/2,
    is_same_month/2
]).

-export([
    str_to_timestamp/1,
    timestamp_to_datetime_str/0,
    timestamp_to_datetime_str/1,
    time_to_str/1,
    date_to_str/0,
    date_to_str/1,
    min_sec_str/0,
    hour_min_sec_str/0,
    hour_min_str/0,
    now_hour/1
]).

-export([
    add_days/2,
    weekday_timestamp/3,
    diff_next_weekdaytime/3,
    diff_next_daytime/2,
    diff_next_hoursec/2,
    diff_next_hoursec/3,
    diff_next_hour/0,
    diff_date/2,
    diff_date_abs/2,
    get_diff_days_by_weekday/2,
    diff_sec/2,
    is_same_date/1,
    is_same_date/2,
    get_server_pname/1
]).


-define(GREGORIAN_INTERVIAL_TIME,
    (case erlang:get(universal_timestamp) of
         V when erlang:is_integer(V) -> V;
         _ ->
             V = calendar:datetime_to_gregorian_seconds(calendar:universal_time_to_local_time({{1970, 1, 1}, {0, 0, 0}})),
             erlang:put(universal_timestamp, V),
             V
     end)
).
-define(DAY_SECOND, 86400).
-define(HOUR_SECOND, 3600).
-define(MINUTE_SECOND, 60).

-type timestamp_tuple() ::
{integer(), integer(), integer()}.
-type year() ::
integer().
-type month() ::
1..12.
-type day() ::
1..31.
-type hour() ::
0..23.
-type minute() ::
0..59.
-type second() ::
0..59.
-type week() ::
1..7.
-type date() ::
{year(), month(), day()}.
-type time() ::
{hour(), minute(), second()}.
-type datetime() ::
{date(), time()}.


%% %%@doc 所有需要0点处理进程需要有如下实现,
%% do_handle(zeroclock) ->
%%     your_zeroclock_fun(...);
%% %%@doc 所有需要秒循环进程需要有如下实现,
%% do_handle({loop_sec,Now}) ->
%%     time_tool:now_cached(Now),
%%     your_loop_sec_fun(...);
%% %%@doc 需要毫秒级循环进程需要有如下实现,Msec：需要的毫秒整数，匹配用(如果需要多重毫秒循环)
%% do_handle({loop_msec,Msec}) ->
%%     your_loop_msec_fun(...);
-type child() ::
'undefined' | pid().
-type startchild_err() ::
'already_present'
| {'already_started', Child :: child()}
| term().
-type startchild_ret() ::
{'ok', Child :: child()}
| {'ok', Child :: child(), Info :: term()}
| {'error', startchild_err()}.


-spec start_server(ServerType, SupName, LoopMSecs) -> startchild_ret() when
    ServerType :: atom(),
    SupName :: atom(),
    LoopMSecs :: [pos_integer()].

%% @doc 每个需要秒循环的APP启动时要调用下面相应的 time_xxx_server进程
%% LoopMSecs 中如果有0，则启动0点处理
%% ServerType in [role,gate,map,world,mnode]
%% @end
start_server(ServerType, SupName, LoopMSecs) ->
    time_server:start(SupName, get_server_pname(ServerType), LoopMSecs).

-spec reg(ServerType, LoopMSecs) -> {reg, LoopMSecs, PID} when
    ServerType :: atom(),
    LoopMSecs :: [non_neg_integer()],
    PID :: pid().
%% @doc 每个需要循环的进程在启动时（网关在需要时）调用下面相应的reg函数进行loop注册
%% LoopMSecs 中如果有0，则会收到0点消息
%% 退出时调用相应的dereg函数
%% ServerType in [role,gate,map,world,mnode]
%% @end
reg(ServerType, LoopMSecs) ->
    reg(ServerType, LoopMSecs, self()).

-spec reg(ServerType, LoopMSecs, PID) -> {reg, LoopMSecs, PID} when
    ServerType :: atom(),
    LoopMSecs :: [non_neg_integer()],
    PID :: pid().
%% @doc 每个需要循环的进程在启动时（网关在需要时）调用下面相应的reg函数进行loop注册
%% LoopMSecs 中如果有0，则会收到0点消息
%% 退出时调用相应的dereg函数
%% ServerType in [role,gate,map,world,mnode]
%% @end
reg(ServerType, LoopMSecs, PID) ->
    erlang:send(get_server_pname(ServerType), {reg, LoopMSecs, PID}).

-spec dereg(ServerType, LoopMSecs) -> {dereg, LoopMSecs, PID} when
    ServerType :: atom(),
    LoopMSecs :: [non_neg_integer()],
    PID :: pid().
%% @doc 解除loop注册
dereg(ServerType, LoopMSecs) ->
    dereg(ServerType, LoopMSecs, self()).

-spec dereg(ServerType, LoopMSecs, PID) -> {dereg, LoopMSecs, PID} when
    ServerType :: atom(),
    LoopMSecs :: [non_neg_integer()].
%% @doc 解除loop注册
dereg(ServerType, LoopMSecs, PID) ->
    erlang:send(get_server_pname(ServerType), {dereg, LoopMSecs, PID}).

-spec reg_pids(ServerType, LoopMSec) -> PIDList when
    ServerType :: atom(),
    LoopMSec :: pos_integer(),
    PIDList :: [pid()] | [].
%% @doc 获取time_serverType_server服务进程中LoopMSec循环的PID
reg_pids(ServerType, LoopMSec) ->
    ServerPName = get_server_pname(ServerType),
    case erlang:whereis(ServerPName) of
        undefined -> [];
        _ ->
            gen_server:call(ServerPName, {get_reg_pids, LoopMSec}, infinity)
    end.

reset_hour_change(Type) ->
    erlang:send(get_server_pname(Type), reset_hour_change).
%% @doc 根据ServerType获取time_server的服务注册名称，通常是time_serverType_server
get_server_pname(ServerType) ->
    case ServerType of
        db -> time_db_server;
        role -> time_role_server;
        gate -> time_gate_server;
        map -> time_map_server;
        world -> time_world_server;
        node -> time_node_server;
        common -> time_common_server;
        robot -> time_robot_server
    end.


%% @doc os:timestamp/0，仅用于随机种子
-spec now_tuple() -> timestamp_tuple().
now_tuple() ->
    os:timestamp().

-spec now_cached(Now) -> undefined | integer() when
    Now :: integer().
%% @doc 缓存now
now_cached(Now) ->
    erlang:put(now, Now).
now_ms_cached(NowMs) ->
    erlang:put(now_ms, NowMs).

-spec now() -> integer().
%% @doc 秒时间戳，先取进程字典缓存的时间戳，如果没有取系统时间戳
now() ->
    case erlang:get(now) of
        Now when erlang:is_integer(Now) -> Now;
        _ -> now_os()
    end.
now_ms() ->
    case erlang:get(now_ms) of
        NowMS when erlang:is_integer(NowMS) -> NowMS;
        _ -> now_os_ms()
    end.

-spec date() -> date().
date() ->
    erlang:date().

-spec now_os() -> integer().
%% @doc 秒时间戳，系统时间戳
now_os() ->
    {A, B, _} = now_tuple(),
    A * 1000000 + B.

-spec now_ms() -> integer().
%% @doc 毫秒
now_os_ms() ->
    {A, B, C} = now_tuple(),
    A * 1000000000 + B * 1000 + C div 1000.

-spec now_us() -> integer().
%% @doc 微秒
now_us() ->
    {A, B, C} = now_tuple(),
    A * 1000000000000 + B * 1000000 + C.

-spec midnight() -> integer().
%% @doc 今天凌晨0点时间戳
midnight() ->
    midnight(time_tool:now()).

-spec midnight(TimeStamp) -> integer() when
    TimeStamp :: integer().
%% @doc 计算时间戳TimeStamp当天的0点时间戳
midnight(TimeStamp) ->
    TimeStamp - (TimeStamp + ?GREGORIAN_INTERVIAL_TIME) rem ?DAY_SECOND.

-spec nextnight() -> integer().
%% @doc 明天凌晨0点时间戳
nextnight() ->
    midnight() + ?DAY_SECOND.

-spec time_to_sec(Time) -> integer() when
    Time :: tuple() | integer().
%% @doc 指定时间是当日第几秒
time_to_sec(TimeStamp) when erlang:is_integer(TimeStamp) ->
    (TimeStamp + ?GREGORIAN_INTERVIAL_TIME) rem ?DAY_SECOND;
time_to_sec({HH, MM, SS}) ->
    HH * ?HOUR_SECOND + MM * ?MINUTE_SECOND + SS.

-spec timestamp(DateTime) -> integer() when
    DateTime :: tuple().
%% @doc 某个时间点的时间戳
timestamp({YY, MM, DD}) when YY >= 1970 ->   %%年月日 ->时间戳
    timestamp({{YY, MM, DD}, {0, 0, 0}});
timestamp({HH, MM, SS}) ->   %%时分秒 ->时间戳
    timestamp({time_tool:date(), {HH, MM, SS}});
timestamp({{Y, M, D}, {HH, MM, SS}}) -> %%年月日时分秒 ->时间戳
    calendar:datetime_to_gregorian_seconds({{Y, M, D}, {HH, MM, SS}}) - ?GREGORIAN_INTERVIAL_TIME.

-spec timestamp_to_datetime(TimeStamp) -> tuple() when
    TimeStamp :: integer().
%% @doc 某个时间戳的时间点
timestamp_to_datetime(TimeStamp) ->
    calendar:gregorian_seconds_to_datetime(?GREGORIAN_INTERVIAL_TIME + TimeStamp).

-spec timestamp_to_date(TimeStamp) -> tuple() when
    TimeStamp :: integer().
%% @doc 某个时间戳的日期
timestamp_to_date(TimeStamp) ->
    {Date, _Time} = timestamp_to_datetime(TimeStamp),
    Date.

-spec weekday() -> integer().
%% @doc 当前是星期几
weekday() ->
    weekday(erlang:localtime()).

-spec weekday(DateTime) -> integer() when
    DateTime :: {date(), time()} | date().
%% @doc 日期是星期几
weekday({Date, _Time}) ->
    weekday(Date);
weekday(TimeStamp) when erlang:is_integer(TimeStamp) ->
    weekday(timestamp_to_datetime(TimeStamp));
weekday(Date) ->
    calendar:day_of_the_week(Date).

-spec day_of_year() -> integer().
%% @doc 今天天是一年的第几天
day_of_year() ->
    day_of_year(time_tool:date()).

-spec day_of_year(DateTime) -> integer() when
    DateTime :: datetime() | date().
%% @doc 日期是一年的第几天
day_of_year({Date, _Time}) ->
    day_of_year(Date);
day_of_year({Y, M, D}) ->
    diff_date({Y, M, D}, {Y, 1, 1}).

-spec week_of_year() -> integer().
%% @doc 今天是一年中的第几周（新一年第一天是新一年第一周）
week_of_year() ->
    week_of_year(time_tool:date()).

-spec week_of_year(Date) -> integer() when
    Date :: date().
%% @doc 日期是一年中的第几周（新一年第一天是新一年第一周）
week_of_year({Year, _Month, _Day} = Date) ->
    Dayofyear = day_of_year(Date),
    FirstDayweek = calendar:day_of_the_week({Year, 1, 1}),
    DayOutof = Dayofyear - (7 - FirstDayweek),
    case DayOutof =< 0 of
        true -> 1;
        false ->
            CheckMod = (DayOutof rem 7),
            case CheckMod =/= 0 of
                true -> Weeks = DayOutof div 7 + 1;
                false -> Weeks = DayOutof div 7
            end,
            Weeks + 1
    end.
-spec is_same_week(TimeStamp) -> true | false when
    TimeStamp :: integer() | date().
%% @doc 日期和今天是否同周
is_same_week(TimeStamp) when erlang:is_integer(TimeStamp) ->
    Date1 = timestamp_to_date(TimeStamp),
    Today = time_tool:date(),
    is_same_week(Date1, Today);
is_same_week({_, _, _} = Date1) ->
    Today = time_tool:date(),
    is_same_week(Date1, Today).

-spec is_same_week(TimeStamp1, TimeStamp2) -> true | false when
    TimeStamp1 :: integer() | date(),
    TimeStamp2 :: integer() | date().
%% @doc 两个日期是否同一周
is_same_week(TimeStamp1, TimeStamp2) when erlang:is_integer(TimeStamp1) andalso erlang:is_integer(TimeStamp2) ->
    Date1 = timestamp_to_date(TimeStamp1),
    Date2 = timestamp_to_date(TimeStamp2),
    is_same_week(Date1, Date2);
is_same_week({_, _, _} = Date1, {_, _, _} = Date2) ->
    calendar:iso_week_number(Date1) =:= calendar:iso_week_number(Date2).


-spec str_to_timestamp(Format) -> integer() when
    Format :: string().
%% @doc 将分秒格式的时间转换成时间戳 传入时间如"1990-11-28 8:00:00"
str_to_timestamp(Format) ->
    [Date, Time] = string:tokens(Format, " "),
    [Y, M, D] = string:tokens(Date, "-"),
    [H, MM, S] = string:tokens(Time, ":"),
    timestamp({{lib_tool:to_integer(Y), lib_tool:to_integer(M), lib_tool:to_integer(D)}, {lib_tool:to_integer(H), lib_tool:to_integer(MM), lib_tool:to_integer(S)}}).

-spec timestamp_to_datetime_str() -> string().
%% @doc 当前日期时间，格式如"2015-11-23 17:50:48"
timestamp_to_datetime_str() ->
    {{Y, M, D}, {HH, MM, SS}} = erlang:localtime(),
    lists:flatten(io_lib:format("~w-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [Y, M, D, HH, MM, SS])).
-spec timestamp_to_datetime_str(Time) -> string() when
    Time :: integer().
%% @doc 时间戳转换为日期时间格式，结果格式:"2015-11-23 17:50:48"
timestamp_to_datetime_str(Time) ->
    {{Y, M, D}, {HH, MM, SS}} = timestamp_to_datetime(Time),
    lists:flatten(io_lib:format("~w-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [Y, M, D, HH, MM, SS])).

-spec time_to_str(Time) -> string() when
    Time :: integer().
%% @doc 今天第几秒转换为当天时间，格式"HH:MM:SS"
time_to_str(Time) ->
    HH = Time div ?HOUR_SECOND,
    MM = (Time - (HH * ?HOUR_SECOND)) div ?MINUTE_SECOND,
    SS = Time - (HH * ?HOUR_SECOND) - (MM * ?MINUTE_SECOND),
    lists:flatten(io_lib:format("~2..0B:~2..0B:~2..0B", [HH, MM, SS])).

-spec date_to_str() -> string().
%% @doc 今日日期，格式"Y-M-D"
date_to_str() ->
    Date = time_tool:date(),
    date_to_str(Date).

-spec date_to_str(Date) -> string() when
    Date :: date().
%% @doc 日期格式化，{Y,M,D} -> "Y-M-D"
date_to_str({Y, M, D}) ->
    lists:flatten(io_lib:format("~w-~2..0B-~2..0B", [Y, M, D])).

-spec min_sec_str() -> string().
%% @doc 获取当前时间的分秒格式:"MM-SS"
min_sec_str() ->
    {{_Y, _M, _D}, {_HH, MM, SS}} = timestamp_to_datetime(time_tool:now()),
    lists:flatten(io_lib:format("~2..0B-~2..0B", [MM, SS])).

-spec hour_min_sec_str() -> string().
%% @doc 获取当前时间的时分秒格式:"HH:MM:SS"
hour_min_sec_str() ->
    {{_Y, _M, _D}, {HH, MM, SS}} = timestamp_to_datetime(time_tool:now()),
    lists:flatten(io_lib:format("~2..0B:~2..0B:~2..0B", [HH, MM, SS])).

-spec hour_min_str() -> string().
%% @doc 获取当前时间的时分格式:""HH:MM"
hour_min_str() ->
    {{_Y, _M, _D}, {HH, MM, _SS}} = timestamp_to_datetime(time_tool:now()),
    lists:flatten(io_lib:format("~2..0B:~2..0B", [HH, MM])).

-spec add_days(TheDate, Diff) -> datetime() | date() when
    TheDate :: datetime() | date(),
    Diff :: integer().
%% @doc 日期增加天数
add_days(TheDate, Diff) when erlang:is_integer(Diff) andalso erlang:is_tuple(TheDate) ->
    case TheDate of
        {Date, Time} ->
            GregDate2 = calendar:date_to_gregorian_days(Date) + Diff,
            {calendar:gregorian_days_to_date(GregDate2), Time};
        _ ->
            GregDate2 = calendar:date_to_gregorian_days(TheDate) + Diff,
            calendar:gregorian_days_to_date(GregDate2)
    end.

weekday_timestamp(WeekDay, Hour, Min) ->
    Today = weekday(),
    Time = time_tool:timestamp(erlang:date()),
    Time + (WeekDay - Today) * ?DAY_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND.

-spec diff_next_weekdaytime(WeekDay, Hour, Min) -> integer() when
    WeekDay :: week(),
    Hour :: hour(),
    Min :: minute().
%% @doc 距离到下个星期几的几时几分还有多少秒
diff_next_weekdaytime(WeekDay, Hour, Min) ->
    Today = weekday(),
    case Today > WeekDay of
        true ->
            (7 - Today + WeekDay) * 24 * ?HOUR_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - (calendar:time_to_seconds(erlang:time()));
        false ->
            Rtn = (WeekDay - Today) * 24 * ?HOUR_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - (calendar:time_to_seconds(erlang:time())),
            case Rtn =< 0 of
                true -> 7 * ?DAY_SECOND + Rtn;
                false -> Rtn
            end
    end.

-spec diff_next_daytime(Hour, Min) -> integer() when
    Hour :: hour(),
    Min :: minute().
%% @doc 距离到明天的几时几分还有多少秒
diff_next_daytime(Hour, Min) ->
    ?DAY_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - (calendar:time_to_seconds(erlang:time())).

-spec diff_next_hoursec(Hour, Min) -> integer() when
    Hour :: hour(),
    Min :: minute().
%% @doc 距离下个几时几分还有多少秒
diff_next_hoursec(Hour, Min) ->
    ThisDaySecond = calendar:time_to_seconds(erlang:time()),
    case ThisDaySecond >= Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND of  %%由‘>’改为‘>=’,避免send_after一秒间隔时间内重复发送消息
        true ->
            ?DAY_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - ThisDaySecond;
        false ->
            Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - ThisDaySecond
    end.

diff_next_hoursec(Time, Hour, Min) ->
    {_, HMS} = timestamp_to_datetime(Time),
    ThisDaySecond = calendar:time_to_seconds(HMS),
    case ThisDaySecond >= Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND of  %%由‘>’改为‘>=’,避免send_after一秒间隔时间内重复发送消息
        true ->
            ?DAY_SECOND + Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - ThisDaySecond;
        false ->
            Hour * ?HOUR_SECOND + Min * ?MINUTE_SECOND - ThisDaySecond
    end.


-spec diff_next_hour() -> integer().
%% @doc 距离下一个整点还有多少秒
diff_next_hour() ->
    ThisDaySecond = calendar:time_to_seconds(erlang:time()),
    ?HOUR_SECOND - ThisDaySecond rem ?HOUR_SECOND.

-spec diff_date(TimeStamp1, TimeStamp2) -> integer() when
    TimeStamp1 :: integer() | date(),
    TimeStamp2 :: integer() | date().
%% @doc 计算两个时间戳或者两个日期相距的天数，前面的日期大时返回正数
diff_date(TimeStamp1, TimeStamp2) when erlang:is_integer(TimeStamp1) andalso erlang:is_integer(TimeStamp2) ->
    GregorianTs = ?GREGORIAN_INTERVIAL_TIME,
    ((TimeStamp1 + GregorianTs) div ?DAY_SECOND) - ((TimeStamp2 + GregorianTs) div ?DAY_SECOND);
diff_date(Date1, Date2) ->
    calendar:date_to_gregorian_days(Date1) - calendar:date_to_gregorian_days(Date2).

-spec diff_date_abs(TimeStamp1, TimeStamp2) -> integer() when
    TimeStamp1 :: integer() | date(),
    TimeStamp2 :: integer() | date().
%% @doc 计算两个时间戳或者两个日期相隔的天数
diff_date_abs(Date1, Date2) ->
    erlang:abs(diff_date(Date1, Date2)).

get_diff_days_by_weekday(NowWeekDay, DestWeekDay) ->
    case DestWeekDay >= NowWeekDay of
        true ->
            DestWeekDay - NowWeekDay;
        _ ->
            DestWeekDay - NowWeekDay + 7
    end.

-spec diff_sec(Time1, Time2) -> integer() when
    Time1 :: time() | datetime(),
    Time2 :: time() | datetime().
%% @doc 两个时分秒或者时间戳相隔的秒数
diff_sec({HH1, MM1, SS1}, {HH2, MM2, SS2}) ->
    diff_sec({time_tool:date(), {HH1, MM1, SS1}}, {time_tool:date(), {HH2, MM2, SS2}});
diff_sec(Time1, Time2) ->
    erlang:abs(calendar:datetime_to_gregorian_seconds(Time1) - calendar:datetime_to_gregorian_seconds(Time2)).

-spec is_same_date(TimeStamp) -> boolean() when
    TimeStamp :: integer().
%% @doc 跟当前时间是不是同一天
is_same_date(TimeStamp) ->
    NowTimeStamp = time_tool:now(),
    is_same_date(TimeStamp, NowTimeStamp).

-spec is_same_date(TimeStamp1, TimeStamp2) -> boolean() when
    TimeStamp1 :: integer(),
    TimeStamp2 :: integer().
%% @doc 两个时间戳是否是同一天
is_same_date(TimeStamp1, TimeStamp2) ->
    GregorianTs = ?GREGORIAN_INTERVIAL_TIME,
    ((TimeStamp1 + GregorianTs) div ?DAY_SECOND) =:= ((TimeStamp2 + GregorianTs) div ?DAY_SECOND).

get_time_tuple() ->
    erlang:timestamp().

%%是否同一个月  Time1,Time2时间戳
is_same_month(Time1, Times2) ->
    {{Y, M, _}, {_, _, _}} = timestamp_to_datetime(Time1),
    {{Y2, M2, _}, {_, _, _}} = timestamp_to_datetime(Times2),
    Y =:= Y2 andalso M =:= M2.

now_hour(Now) ->
    {{_Y, _M, _D}, {HH, _MM, _SS}} = timestamp_to_datetime(Now),
    HH.