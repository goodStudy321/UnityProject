%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 九月 2019 17:04
%%%-------------------------------------------------------------------
-module(update_9).
-author("huangxiangrui").
-include("db.hrl").
-include("role.hrl").
-include("act.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_confine/1,
    update_act_init_time/1,
    update_role_clword/1,
    update_role_huntboss/1,
    get_all_act/0
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_CONFINE_P, update_role_confine},

        %%   update_act_init_time   必须在其他活动开始时间前
        {?DB_ACT_INIT_TIME_P, update_act_init_time},
        {?DB_ROLE_CLWORD_P, update_role_clword},
        {?DB_ROLE_ACT_HUNT_BOSS_P, update_role_huntboss}

    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.

update_role_confine(RoleConfineList) ->
    [begin
         case RoleConfine of
             {r_role_confine, ROLE_ID, Mission_List, Confine, War_Spirit, War_Spirit_List, War_Spirit_Change, Refine_All_Exp,
                 Bag_Id, Bag_List, War_God_List, War_God_Pieces, Confine_Reward} ->
                 {r_role_confine, ROLE_ID, Mission_List, Confine, War_Spirit, War_Spirit_List, War_Spirit_Change, Refine_All_Exp,
                     Bag_Id, Bag_List, War_God_List, War_God_Pieces, Confine_Reward, []};
             _ ->
                 RoleConfine
         end
     end || RoleConfine <- RoleConfineList].

update_act_init_time(_List) ->
    ets:new(?ETS_ACT, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_act.id}]),
    AllAct = get_all_act(),
    ets:delete(?ETS_ACT),
    [begin
         {r_act_init_time, ID, StartTime}
     end || #r_act{id = ID, start_time = StartTime, status = Status} <- AllAct, Status =:= ?ACT_STATUS_OPEN].

update_role_clword(RoleClwordList) ->
    [#c_act{min_level = MinLevel}] = lib_config:find(cfg_act, ?ACT_CLWORD_ID),
    [begin
         case RoleClword of
             {r_role_clword, RoleID, List} ->
                 [#r_role_attr{level = RoleLevel}] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
                 StartDate = case RoleLevel >= MinLevel of
                                 true ->
                                     case db:lookup(?DB_ACT_INIT_TIME_P, ?ACT_CLWORD_ID) of
                                         [#r_act_init_time{time = StartTime}] ->
                                             StartTime;
                                         _ ->
                                             0
                                     end;
                                 _ ->
                                     0
                             end,
                 {r_role_clword, RoleID, List, StartDate};
             _ ->
                 RoleClword
         end
     end || RoleClword <- RoleClwordList].

update_role_huntboss(RoleActHuntList) ->
    [#c_act{min_level = MinLevel}] = lib_config:find(cfg_act, ?ACT_HUNT_BOSS_ID),
    [begin
         case RoleActHunt of
             {r_role_act_hunt_boss, RoleID, Score, RewardList} ->
                 [#r_role_attr{level = RoleLevel}] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
                 StartDate = case RoleLevel >= MinLevel of
                                 true ->
                                     case db:lookup(?DB_ACT_INIT_TIME_P, ?ACT_HUNT_BOSS_ID) of
                                         [#r_act_init_time{time = StartTime}] ->
                                             StartTime;
                                         _ ->
                                             0
                                     end;
                                 _ ->
                                     0
                             end,
                 {r_role_act_hunt_boss, RoleID, StartDate, Score, RewardList};
             _ ->
                 RoleActHunt
         end
     end || RoleActHunt <- RoleActHuntList].



get_all_act() ->
    Now = time_tool:now(),
    [do_check_act(Config, Now) || {ID, Config} <- cfg_act:list(), ID =:= ?ACT_HUNT_BOSS_ID orelse ?ACT_CLWORD_ID].



do_check_act(Config, Now) ->
    #c_act{
        id = ID,
        type = Type,
        min_level = MinLevel,
        start_args = StartArgs,
        end_args = EndArgs,
        start_date = StartDate,
        end_date = EndDate,
        time_string = TimeString,
        drop = DropInfo,
        merge_start_args = MergeStartDate,
        merge_end_args = MergeEndDate} = Config,
    do_check_act(Type, MinLevel, StartArgs, EndArgs, StartDate, EndDate, TimeString, Now, DropInfo, ID, MergeStartDate, MergeEndDate, undefined).



do_check_act(Type, _MinLevel, StartArgs, EndArgs, StartDate, EndDate, TimeString, Now, _DropInfo, ID, MergeStartDate, MergeEndDate, _GameChannelID) ->
    if
        Type =:= ?ACT_OPEN_DAYS -> %% 开服N天内
            {StartTime2, EndTime2, IsVisible, StartDate2, EndDate2, NowStatus} = case common_config:is_merge() of
                                                                                     true ->
                                                                                         MergeStartDays = world_act_server:get_days(MergeStartDate),
                                                                                         MergeEndDays = world_act_server:get_days(MergeEndDate),
                                                                                         StartTime2I = world_act_server:get_merge_days_time(MergeStartDays),
                                                                                         EndTime2I = world_act_server:get_merge_days_time(MergeEndDays + 1) - 1,
                                                                                         IsOpenI = StartTime2I =< Now andalso Now < EndTime2I,
                                                                                         IsVisibleI = IsOpenI,
                                                                                         StartDate2I = StartTime2I,
                                                                                         EndDate2I = EndTime2I,
                                                                                         NowStatusI = ?IF(IsOpenI, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE),
                                                                                         {StartTime2I, EndTime2I, IsVisibleI, StartDate2I, EndDate2I, NowStatusI};
                                                                                     _ ->
                                                                                         StartDays = world_act_server:get_days(StartArgs),
                                                                                         EndDays = world_act_server:get_days(EndArgs),
                                                                                         StartTime2I = world_act_server:get_days_time(StartDays),
                                                                                         EndTime2I = world_act_server:get_days_time(EndDays + 1) - 1,
                                                                                         IsOpenI = StartTime2I =< Now andalso Now < EndTime2I,
                                                                                         IsVisibleI = IsOpenI,
                                                                                         StartDate2I = StartTime2I,
                                                                                         EndDate2I = EndTime2I,
                                                                                         NowStatusI = ?IF(IsOpenI, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE),
                                                                                         {StartTime2I, EndTime2I, IsVisibleI, StartDate2I, EndDate2I, NowStatusI}
                                                                                 end;
        Type =:= ?ACT_ANY_TIME -> %% 特定配置时间
            {StartTime2, EndTime2, IsOpen, IsVisible, StartDate2, EndDate2} = world_act_server:get_open_time(Now, StartDate, EndDate, TimeString),
            NowStatus = ?IF(IsOpen, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE);
        true ->
            StartDate2 = EndDate2 = StartTime2 = EndTime2 = 0,
            IsVisible = false,
            NowStatus = ?ACT_STATUS_CLOSE
    end,
    #r_act{
        id = ID,
        status = NowStatus,
        is_visible = IsVisible,
        start_time = StartTime2,
        end_time = EndTime2,
        start_date = StartDate2,
        end_date = EndDate2}.

