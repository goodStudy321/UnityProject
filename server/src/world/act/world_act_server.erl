%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     角色活动server
%%% @end
%%% Created : 14. 七月 2017 19:19
%%%-------------------------------------------------------------------
-module(world_act_server).
-author("laijichang").
-include("global.hrl").
-include("act.hrl").
-include("proto/mod_role_act_level.hrl").
-include("proto/mod_role_act.hrl").
-include("proto/mod_role_treasure.hrl").

-behaviour(gen_server).


%%%---------------------------------------------------------------------------------------
%%%
%%%
%%%
%%%  注意：当配置活动需适应game_channel_id时候，活动ID为   活动ID ++  game_channel_id
%%%
%%%
%%%
%%%----------------------------------------------------------------------------------------


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
    level_reward/2,
    add_treasure_logs/1,
    add_summit_logs/1,
    update_act_rank/3,
    reload_config/0,
    reload_common/0
]).

-export([
    is_act_open/1,
    get_all_act/0,
    get_act/1,
    get_role_act_rank/2,
    get_days_time/1,
    trans_to_p_act/1,
    get_act_config/1,
    get_act_open_day/1
]).

%%   for  update9
-export([
    get_days/1,
    get_merge_days_time/1,
    get_open_time/4
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

level_reward(Level, LimitNum) ->
    call({level_reward, Level, LimitNum}).

add_treasure_logs(LogList) ->
    info({add_treasure_logs, LogList}).

add_summit_logs(LogList) ->
    info({add_summit_logs, LogList}).

update_act_rank(RoleID, ID, Condition) ->
    info({update_act_rank, RoleID, ID, Condition}).

reload_config() ->
    info(reload_config).

reload_common() ->
    info(reload_common).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    ets:new(?ETS_ACT, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_act.id}]),
    do_reload_config(),
    [world_data:init_act_ranks(ID) || {ID, _Config} <- cfg_act_rank:list()],
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
    ?WARNING_MSG("-----------_Reason----------------~w", [_Reason]),
    List = get_all_act(),
    [hook_act:terminate(ID) || #r_act{status = Status, id = ID} <- List, Status =:= ?ACT_STATUS_OPEN],
    time_tool:dereg(world, [0, 1000]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({level_reward, Level, LimitNum}) ->
    do_level_reward(Level, LimitNum);
do_handle({add_treasure_logs, LogList}) ->
    do_add_treasure_logs(LogList);
do_handle({add_summit_logs, LogList}) ->
    do_add_summit_logs(LogList);
do_handle({update_act_rank, RoleID, ID, Condition}) ->
    do_update_act_rank(RoleID, ID, Condition);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle(reload_config) ->
    do_reload_config();
do_handle(reload_common) ->
    do_reload_common();
do_handle({monster_server_open, ActDropList, Pid}) ->
    do_monster_server_open(ActDropList, Pid);
do_handle({monster_server_close, MapID, Pid}) ->
    do_monster_server_close(MapID, Pid);
do_handle(zeroclock) ->
    do_reload_config_zeroclock();
do_handle({loop_sec, Now}) ->
    do_reload_config_loop_sec(Now);
do_handle({gm_start, ID}) ->
    do_gm_status(ID, ?ACT_STATUS_OPEN);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({gm_stop, ID}) ->
    do_gm_status(ID, ?ACT_STATUS_CLOSE);
do_handle({gm_end_time, EndTime}) ->
    do_gm_end_time(EndTime);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_reload_common() ->
    do_reload_config(),
    #r_act{start_time = StartTime, status = Status} = world_act_server:get_act(?ACT_LIMITED_TIME_BUY),
    Now = time_tool:now(),
    [#r_world_data{key = _Key,val = RoleID}] = world_data:get_role_id_counter(),
    case RoleID =:= common_id:get_start_role_id() andalso Status =:= ?ACT_STATUS_OPEN of
        true ->
            ets:delete(?ETS_ACT_LIMITEDTIME_BUY),
            ?WARNING_MSG("act_limited_time_buy init"),
            act_limited_time_buy:init(StartTime, Now),
            ok;
        _ ->
            ok
    end.

do_reload_config() ->
    Now = time_tool:now(),
    [do_check_act(Config, Now) || {_ID, Config} <- cfg_act:list()].

do_reload_config_zeroclock() ->
    Now = time_tool:now(),
    [begin
         ?IF(is_act_open(ID), catch hook_act:zero(ID), ok),
         do_check_act(Config, Now)
     end || {ID, Config} <- cfg_act:list()].

do_reload_config_loop_sec(Now) ->
    [do_check_act(Config, Now) || {_ID, Config} <- cfg_act:list(), Config#c_act.type =:= ?ACT_ANY_TIME orelse hour_span(Now)].

hour_span(Now) ->
    case time_tool:timestamp_to_datetime(Now) of
        {_, {_, 59, 59}} ->
            true;
        {_, {_, 29, 59}} ->
            true;
        _ ->
            false
    end.


do_check_act(ID, Now) when erlang:is_integer(ID) ->
    [Config] = lib_config:find(cfg_act, ID),
    do_check_act(Config, Now);

do_check_act(Config, Now) ->
    #c_act{
        id = ID,
        merge_effect = MergeEffect,
        type = Type,
        min_level = MinLevel,
        start_args = StartArgs,
        end_args = EndArgs,
        start_date = StartDate,
        end_date = EndDate,
        time_string = TimeString,
        drop = DropInfo,
        game_channel_list = GameChannelList,
        merge_start_args = MergeStartDate,
        merge_end_args = MergeEndDate} = Config,
    GameChannelList2 = lib_tool:string_to_intlist(GameChannelList),
    case GameChannelList2 =:= [] of
        true ->
            do_check_act(Type, MinLevel, StartArgs, EndArgs, StartDate, EndDate, TimeString, Now, DropInfo, ID, MergeStartDate, MergeEndDate, undefined, MergeEffect);
        _ ->
            [
                begin
                    [TimeConfig] = lib_config:find(cfg_act_time, TimeID),
                    #c_act_time{type = Type2, start_date = StartDate2, end_date = EndDate2, time_string = TimeString2, start_args = StartArgs2, end_args = EndArgs2} = TimeConfig,
                    ID2 = lib_tool:to_integer(lib_tool:to_list(ID) ++ lib_tool:to_list(GameChannelID)),
                    do_check_act(Type2, MinLevel, StartArgs2, EndArgs2, StartDate2, EndDate2, TimeString2, Now, DropInfo, ID2, MergeStartDate, MergeEndDate, GameChannelID, MergeEffect)
                end || {GameChannelID, TimeID} <- GameChannelList2]
    end.

do_check_act(Type, MinLevel, StartArgs, EndArgs, StartDate, EndDate, TimeString, Now, DropInfo, ID, MergeStartDate, MergeEndDate, GameChannelID, MergeEffect) ->
    #r_act{
        status = Status,
        is_gm_set = IsGmeSet,
        bc_pid = BcPid,
        start_time = OldStartTime,
        end_time = OldEndTime,
        start_date = OldStartDate,
        end_date = OldEndDate,
        is_visible = OldIsVisible
    } = Act = get_act(ID),
    if
        IsGmeSet ->
            StartTime2 = OldStartTime,
            EndTime2 = OldEndTime,
            IsOpen = (StartTime2 =< Now orelse StartTime2 =:= 0) andalso (Now =< EndTime2 orelse EndTime2 =:= 0),
            IsVisible = IsOpen,
            StartDate2 = StartTime2,
            EndDate2 = EndTime2,
            NowStatus = ?IF(IsOpen, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE);
        Type =:= ?ACT_ANY_TIME -> %% 特定配置时间
            {StartTime2, EndTime2, IsOpen, IsVisible, StartDate2, EndDate2} = get_open_time(Now, StartDate, EndDate, TimeString),
            NowStatus = ?IF(IsOpen, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE);
        Type =:= ?ACT_OPEN_DAYS -> %% 开服N天内
            {StartTime2, EndTime2, IsVisible, StartDate2, EndDate2, NowStatus} = case common_config:is_merge() andalso MergeEffect =:= 1 of
                                                                                     true ->
                                                                                         MergeStartDays = get_days(MergeStartDate),
                                                                                         MergeEndDays = get_days(MergeEndDate),
                                                                                         StartTime2I = get_merge_days_time(MergeStartDays),
                                                                                         EndTime2I = get_merge_days_time(MergeEndDays + 1) - 1,
                                                                                         IsOpenI = StartTime2I =< Now andalso Now < EndTime2I,
                                                                                         IsVisibleI = IsOpenI,
                                                                                         StartDate2I = StartTime2I,
                                                                                         EndDate2I = EndTime2I,
                                                                                         NowStatusI = ?IF(IsOpenI, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE),
                                                                                         {StartTime2I, EndTime2I, IsVisibleI, StartDate2I, EndDate2I, NowStatusI};
                                                                                     _ ->
                                                                                         StartDays = get_days(StartArgs),
                                                                                         EndDays = get_days(EndArgs),
                                                                                         StartTime2I = get_days_time(StartDays),
                                                                                         EndTime2I = get_days_time(EndDays + 1) - 1,
                                                                                         IsOpenI = StartTime2I =< Now andalso Now < EndTime2I,
                                                                                         IsVisibleI = IsOpenI,
                                                                                         StartDate2I = StartTime2I,
                                                                                         EndDate2I = EndTime2I,
                                                                                         NowStatusI = ?IF(IsOpenI, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE),
                                                                                         {StartTime2I, EndTime2I, IsVisibleI, StartDate2I, EndDate2I, NowStatusI}
                                                                                 end;
        true ->
            StartDate2 = EndDate2 = StartTime2 = EndTime2 = 0,
            IsVisible = false,
            NowStatus = ?ACT_STATUS_CLOSE
    end,
    Act3 = case NowStatus =/= Status orelse OldStartTime =/= StartTime2 orelse OldEndTime =/= EndTime2 orelse OldIsVisible =/= IsVisible
        orelse OldStartDate =/= StartDate2 orelse OldEndDate =/= EndDate2 of
               true ->
                   ?WARNING_MSG("activity_status :~w", [{ID, NowStatus, Status, IsVisible}]),
                   Act2 = Act#r_act{
                       status = NowStatus,
                       is_visible = IsVisible,
                       start_time = StartTime2,
                       end_time = EndTime2,
                       start_date = StartDate2,
                       end_date = EndDate2},
                   set_act(Act2),
                   case NowStatus =/= Status of
                       true ->
                           ?IF(NowStatus =:= ?ACT_STATUS_OPEN, hook_act:init_act(Act2, Now), hook_act:init_end(ID)),
                           hook_act:act_status_change(ID, NowStatus),
                           ?IF(?ACT_ABOUT_DROP(DropInfo), [pname_server:send(Pid, {drop, ID, NowStatus}) || Pid <- BcPid], ok);
                       _ ->
                           ok
                   end,
                   DataRecord = #m_act_update_toc{act = trans_to_p_act(Act2)},
                   common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = MinLevel, game_channel_id = GameChannelID}),
                   common_broadcast:bc_role_info_to_world({mod, mod_role_act, {act_update, ID, NowStatus, StartDate2}}),
                   Act2;
               _ ->
                   Act
           end,
    case NowStatus =:= ?ACT_STATUS_OPEN of
        true ->
            {_, {Hour, Min, _Sec}} = time_tool:timestamp_to_datetime(Now),
            case ID =:= ?ACT_OSS_WING orelse ID =:= ?ACT_OSS_MAGIC_WEAPON orelse ID =:= ?ACT_OSS_HANDBOOK of
                true ->
                    case (Min + 1) rem 30 =:= 0 of
                        true ->
                            act_oss:refresh_rank(ID, Now);
                        _ ->
                            ok
                    end;
                _ ->
                    ok
            end,
            ?IF(Min =:= 59, hook_act:hour(Now, Hour + 1, Act3), ok);
        _ ->
            ok
    end.

do_gm_status(ID, NowStatus) ->
    #r_act{status = Status} = Act = get_act(ID),
    case Status =:= NowStatus of
        true ->
            ok;
        _ ->
            Now = time_tool:now(),
            {StartTime, EndTime} =
                if
                    NowStatus =:= ?ACT_STATUS_OPEN ->
                        {Now, Now + 3600 * 240};
                    NowStatus =:= ?ACT_STATUS_CLOSE ->
                        {0, Now - 10}
                end,
            set_act(Act#r_act{is_gm_set = true, start_time = StartTime, end_time = EndTime}),
            do_check_act(ID, Now)
    end.

do_gm_end_time(AddTime) ->
    Now = time_tool:now(),
    [begin
         EndTime = Now + AddTime,
         Act = #r_act{
             is_gm_set = true,
             id = ID,
             end_time = EndTime,
             status = ?ACT_STATUS_OPEN
         },
         set_act(Act)
     end || {ID, _Config} <- cfg_act:list()].

do_level_reward(Level, LimitNum) ->
    case catch check_level_reward(Level, LimitNum) of
        {ok, KV, List2} ->
            world_data:set_act_level_list(List2),
            common_broadcast:bc_record_to_world(#m_act_level_update_toc{act_level = KV}),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_level_reward(Level, LimitNum) ->
    List = world_data:get_act_level_list(),
    case lists:keyfind(Level, #p_kv.id, List) of
        #p_kv{val = OldLimit} = KV ->
            Limit = OldLimit + 1,
            ?IF(Limit > LimitNum, ?THROW_ERR(?ERROR_ACT_LEVEL_REWARD_002), ok),
            KV2 = KV#p_kv{val = Limit};
        _ ->
            KV2 = #p_kv{id = Level, val = 1}
    end,
    List2 = lists:keystore(Level, #p_kv.id, List, KV2),
    {ok, KV2, List2}.

do_add_treasure_logs(LogList) ->
    OldLogList = world_data:get_equip_treasure_logs(),
    [#c_global{list = [_Quality, LogNum]}] = lib_config:find(cfg_global, ?GLOBAL_TREASURE_LOGS),
    LogList2 = lists:sublist(LogList ++ OldLogList, LogNum),
    world_data:set_equip_treasure_logs(LogList2),
    DataRecord = #m_treasure_log_update_toc{world_equip_logs = LogList},
    common_broadcast:bc_record_to_world(DataRecord).

do_add_summit_logs(LogList) ->
    OldLogList = world_data:get_summit_logs(),
    [#c_global{list = [_Quality, LogNum]}] = lib_config:find(cfg_global, ?GLOBAL_TREASURE_LOGS),
    LogList2 = lists:sublist(LogList ++ OldLogList, LogNum),
    world_data:set_summit_logs(LogList2),
    DataRecord = #m_summit_log_update_toc{world_summit_logs = LogList},
    common_broadcast:bc_record_to_world(DataRecord).

do_monster_server_open(ActDropList, Pid) ->
    lists:foreach(
        fun({ActID, _}) ->
            case ets:lookup(?ETS_ACT, ActID) of
                [#r_act{bc_pid = List} = Act] ->
                    case lists:member(Pid, List) of
                        false ->
                            set_act(Act#r_act{bc_pid = [Pid|List]});
                        _ ->
                            ok
                    end;
                _ ->
                    ok
            end
        end, ActDropList).

do_monster_server_close(MapID, Pid) ->
    [MapConfig] = lib_config:find(cfg_map_base, MapID),
    case lib_tool:string_to_intlist(MapConfig#c_map_base.act_drop) of
        [] ->
            ok;
        ActDropList ->
            lists:foreach(
                fun({ActID, _}) ->
                    case ets:lookup(?ETS_ACT, ActID) of
                        [#r_act{bc_pid = List} = Act] ->
                            NewList = lists:delete(Pid, List),
                            set_act(Act#r_act{bc_pid = NewList});
                        _ ->
                            ok
                    end
                end, ActDropList)

    end.

do_update_act_rank(RoleID, ID, Condition) ->
    [#c_act_rank{rank_num = RankNum}] = lib_config:find(cfg_act_rank, ID),
    RoleRank = #r_act_rank{role_id = RoleID, condition = Condition, time = time_tool:now()},
    Ranks = world_data:get_act_ranks(ID),
    Ranks2 = lists:sort(
        fun(#r_act_rank{condition = Condition1, time = Time}, #r_act_rank{condition = Condition2, time = Time2}) ->
            ?IF(Condition1 =:= Condition2, Time < Time2, Condition1 > Condition2)
        end, lists:keystore(RoleID, #r_act_rank.role_id, Ranks, RoleRank)),
    Ranks3 = lists:sublist(Ranks2, RankNum),
    {Ranks4, _Num} =
        lists:foldl(
            fun(Rank, {Acc, NumAcc}) ->
                {[Rank#r_act_rank{rank = NumAcc}|Acc], NumAcc + 1}
            end, {[], 1}, Ranks3),
    world_data:set_act_ranks(ID, Ranks4).

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
    lib_config:find(cfg_act, ID2).

is_act_open(ID) ->
    #r_act{status = Status} = get_act(ID),
    Status =:= ?ACT_STATUS_OPEN.

get_all_act() ->
    ets:tab2list(?ETS_ACT).

set_act(Act) ->
    ets:insert(?ETS_ACT, Act).
get_act(ID) ->
    case ets:lookup(?ETS_ACT, ID) of
        [#r_act{} = Act] ->
            Act;
        _ ->
            #r_act{id = ID}
    end.

get_days("") ->
    0;
get_days(StartArgs) ->
    lib_tool:to_integer(StartArgs).

get_days_time(Day) ->
    case Day of
        0 ->
            0;
        _ ->
            OpenDays = common_config:get_open_days(),
            DiffDays = Day - OpenDays,
            time_tool:timestamp({time_tool:add_days(time_tool:date(), DiffDays), {0, 0, 0}})
    end.


get_merge_days_time(Day) ->
    case Day of
        0 ->
            0;
        _ ->
            case common_config:get_merge_time() of
                [] ->
                    MergeTime2 = 0;
                MergeTime ->
                    MergeTime2 = lib_tool:to_integer(MergeTime)
            end,
            time_tool:midnight(MergeTime2) + (Day - 1) * ?ONE_DAY
    end.


get_open_time(Now, StartDate, EndDate, TimeString) ->
    [SYear, SMonth, SDay] = StartDate,
    [EYear, EMonth, EDay] = EndDate,
    StartTime = time_tool:timestamp({SYear, SMonth, SDay}),
    %% 这个是当天0点的结束时间
    EndTime = time_tool:timestamp({EYear, EMonth, EDay}) + ?ONE_DAY,
    IsOpen = StartTime =< Now andalso Now < EndTime,
    IsVisible = IsOpen,
    case TimeString of
        "" ->
            {StartTime, EndTime, IsOpen, IsVisible, StartTime, EndTime};
        _ ->
            case IsVisible of
                true ->
                    StringList = string:tokens(TimeString, "|"),
                    NowDate = time_tool:timestamp_to_date(Now),
                    {StartTime2, EndTime2, IsOpen2} = get_open_time2(Now, NowDate, StringList),
                    {StartTime2, EndTime2, IsOpen2, IsVisible, StartTime, EndTime};
                _ ->
                    {0, 0, false, IsVisible, StartTime, EndTime}
            end
    end.

get_open_time2(_Now, _NowDate, []) ->
    {0, 0, false};
get_open_time2(Now, NowDate, [TimeString|R]) ->
    [StartString, EndString] = string:tokens(TimeString, "-"),
    [StartHour, StartMin, StartSec] = string:tokens(StartString, ":"),
    [EndHour, EndMin, EndSec] = string:tokens(EndString, ":"),
    StartTime = time_tool:timestamp({NowDate, {lib_tool:to_integer(StartHour), lib_tool:to_integer(StartMin), lib_tool:to_integer(StartSec)}}),
    EndTime = time_tool:timestamp({NowDate, {lib_tool:to_integer(EndHour), lib_tool:to_integer(EndMin), lib_tool:to_integer(EndSec)}}),
    case StartTime =< Now andalso Now < EndTime of
        true ->
            {StartTime, EndTime, true};
        _ ->
            get_open_time2(Now, NowDate, R)
    end.

get_role_act_rank(RoleID, ID) ->
    Ranks = world_data:get_act_ranks(ID),
    case lists:keyfind(RoleID, #r_act_rank.role_id, Ranks) of
        #r_act_rank{rank = Rank} ->
            Rank;
        _ ->
            0
    end.

trans_to_p_act(Act) ->
    #r_act{
        id = ID,
        status = NowStatus,
        is_visible = IsVisible,
        start_time = StartTime2,
        end_time = EndTime2,
        start_date = StartDate,
        end_date = EndDate} = Act,
    #p_act{
        id = ID,
        val = NowStatus,
        is_visible = IsVisible,
        start_time = StartTime2,
        end_time = EndTime2,
        start_date = StartDate,
        end_date = EndDate}.


get_act_open_day(#r_act{start_date = StartDate}) ->
    time_tool:diff_date(time_tool:now(), StartDate) + 1;
get_act_open_day(ID) ->
    #r_act{start_date = StartDate} = get_act(ID),
    time_tool:diff_date(time_tool:now(), StartDate) + 1.