%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 六月 2017 16:36
%%%-------------------------------------------------------------------
-module(copy_common).
-author("laijichang").
-include("global.hrl").
-include("copy.hrl").
-include("team.hrl").
-include("proto/copy_common.hrl").
-include("proto/mod_role_copy.hrl").

-define(IS_COPY_DO(A), (?IF(copy_data:get_copy_do() =:= true, (A), {error, not_copy}))).

%% API
-export([
    copy_restart/1,
    first_init/1,
    role_enter/1,
    copy_start/0,
    init/1,
    loop/1,
    role_leave/2,
    role_dead/3,
    role_level_up/1,
    monster_enter/1,
    monster_dead/3,
    monster_reduce_hp/3,
    role_get_cheer/3,
    role_cheer/3,
    role_auto_cheer/3,
    robot_enter/1,
    robot_dead/1
]).

-export([
    handle/1
]).

-export([
    do_copy_end/1,
    broadcast_update/1
]).

copy_restart(RoleID) ->
    %% 各自模块清理数据
    #r_map_copy{status = Status} = copy_data:get_copy_info(),
    case Status of
        ?COPY_FAILED ->
            common_misc:unicast(RoleID, #m_copy_restart_toc{}),
            execute_mod(copy_data:get_copy_info(), copy_restart, []),
            mod_map_monster:delete_monsters(),
            copy_data:erase_copy_do(),
            role_enter(RoleID);
        _ ->
            common_misc:unicast(RoleID, #m_copy_restart_toc{err_code = ?ERROR_COPY_RESTART_002})
    end.

%% 地图初始化
first_init(MapID) ->
    case map_misc:is_copy(MapID) of
        true ->
            TimeRef = erlang:send_after(?LEAVE_SHUTDOWN_TIME, erlang:self(), {mod, ?MODULE, force_shutdown}),
            copy_data:set_shutdown_ref(TimeRef);
        _ ->
            ok
    end.

%% 玩家进入地图(正式进入)
role_enter(RoleID) ->
    case copy_data:get_copy_do() of
        true ->
            role_enter2(RoleID);
        _ ->
            MapID = map_common_dict:get_map_id(),
            case map_misc:is_copy(MapID) of
                true ->
                    role_init(MapID),
                    role_enter2(RoleID);
                _ ->
                    ok
            end
    end.

role_enter2(RoleID) ->
    copy_data:cancel_shutdown_ref(),
    #r_map_copy{map_id = MapID, enter_roles = EnterRoles} = CopyInfo = copy_data:get_copy_info(),
    case lists:member(RoleID, EnterRoles) of
        true ->
            CopyInfo2 = CopyInfo;
        _ ->
            CopyLevel = copy_misc:get_average_level(),
            CopyInfo2 = CopyInfo#r_map_copy{copy_level = CopyLevel, enter_roles = [RoleID|lists:delete(RoleID, EnterRoles)]},
            copy_data:set_copy_info(CopyInfo2)
    end,
    common_misc:unicast(RoleID, get_info_record(CopyInfo2)),
    execute_mod(CopyInfo2, role_enter, RoleID),
    ?IF(map_misc:is_normal_copy(MapID), log_role_copy(RoleID, MapID, ?LOG_COPY_ENTER), ok),
    ok.

%% 跳过准备阶段直接开启
copy_start() ->
    case copy_data:get_copy_do() of
        true ->
            case copy_data:cancel_start_ref() of
                true ->
                    #r_map_copy{map_id = MapID} = CopyInfo = copy_data:get_copy_info(),
                    Now = time_tool:now(),
                    [#c_copy{exist_time = ExistTime}] = lib_config:find(cfg_copy, MapID),
                    EndTime = Now + ExistTime,
                    CopyInfo2 = CopyInfo#r_map_copy{
                        start_time = Now,
                        start_time_ms = time_tool:now_ms(),
                        end_time = EndTime,
                        shutdown_time = EndTime + ?END_SHUTDOWN_TIME},
                    copy_data:set_copy_info(CopyInfo2),
                    copy_common:init(map_common_dict:get_map_id()),
                    UpdateList = [#p_kv{id = ?COPY_UPDATE_START_TIME, val = Now}, #p_kv{id = ?COPY_UPDATE_END_TIME, val = EndTime}],
                    broadcast_update(UpdateList);
                _ ->
                    false
            end;
        _ ->
            false
    end.


%% 角色离开地图
role_leave(RoleID, IsOnline) ->
    ?IS_COPY_DO(role_leave2(RoleID, IsOnline)).

role_leave2(RoleID, IsOnline) ->
    MapID = map_common_dict:get_map_id(),
    IsNormalCopy = map_misc:is_normal_copy(MapID),
    NoRoles = mod_map_ets:get_in_map_roles() =:= [],
    if
        NoRoles andalso (not IsNormalCopy) ->  %% 流程树副本只要没人就直接关闭
            do_copy_end(?COPY_FAILED);
        NoRoles andalso (not IsOnline) -> %% 如果是下线退出地图，保留30秒
            TimeRef = erlang:send_after(?LEAVE_SHUTDOWN_TIME, erlang:self(), {mod, ?MODULE, force_end}),
            copy_data:set_shutdown_ref(TimeRef);
        NoRoles ->
            do_copy_end(?COPY_FAILED);
        true ->
            ok
    end,
    ?IF(IsNormalCopy, log_role_copy(RoleID, MapID, ?LOG_COPY_QUIT), ok).

role_init(MapID) ->
    Now = time_tool:now(),
    [#c_copy{
        exist_time = ExistTime,
        start_countdown = StartCountDown,
        copy_type = CopyType,
        success_type = SuccessType,
        success_args = SuccessArgs}] = lib_config:find(cfg_copy, MapID),
    StartTime = Now + StartCountDown,
    EndTime = StartTime + ExistTime,
    {SuccessType2, SuccessArgs2} = copy_data:get_success_info(SuccessType, SuccessArgs),
    CopyInfo = #r_map_copy{
        map_id = MapID,
        end_time = EndTime,
        copy_mod = copy_data:get_copy_mod(CopyType),
        start_time = StartTime,
        start_time_ms = time_tool:now_ms() + StartCountDown * ?SECOND_MS,
        shutdown_time = EndTime + ?END_SHUTDOWN_TIME,
        success_type = SuccessType2,
        success_args = SuccessArgs2,
        cur_progress = 0,
        sub_progress = 0,
        all_wave = 0,
        copy_level = copy_misc:get_average_level(),
        enter_roles = mod_map_ets:get_in_map_roles()},
    copy_data:set_copy_do(),
    copy_data:set_copy_info(CopyInfo),
    StartRef = erlang:send_after(StartCountDown * 1000, erlang:self(), {func, fun() -> copy_common:init(MapID) end}),
    copy_data:set_start_ref(StartRef),
    execute_mod(CopyInfo, role_init, CopyInfo).

%% 玩家进入副本，StartCountDown秒后调用
init(MapID) ->
    ?IS_COPY_DO(init2(MapID)).

init2(_MapID) ->
    CopyInfo = copy_data:get_copy_info(),
    execute_mod(CopyInfo, init, CopyInfo).

loop(Now) ->
    ?IS_COPY_DO(loop2(Now)).

loop2(Now) ->
    #r_map_copy{
        success_type = SuccessType,
        status = Status,
        end_time = EndTime,
        shutdown_time = ShutDownTime} = CopyInfo = copy_data:get_copy_info(),
    %% 这里CopyInfo可能会修改
    execute_mod(CopyInfo, loop, {Now, CopyInfo}),
    IsEmpty = mod_map_ets:get_in_map_roles() =:= [],
    IsShutDown = Now >= ShutDownTime,
    IsEnd = (Status =/= ?COPY_NOT_END) orelse IsShutDown,
    if
        (IsEnd andalso IsEmpty) -> %% 结束并且没有人在副本里了
            do_copy_shutdown();
        IsShutDown ->  %% 超过最大时间了，踢人踢人
            map_server:kick_all_roles();
        Now >= EndTime andalso (not IsEnd) -> %% 超过时间，副本结算
            EndType = ?IF(SuccessType =:= ?SUCCESS_TIME, ?COPY_SUCCESS, ?COPY_FAILED),
            do_copy_end(EndType);
        true ->
            ok
    end.

%% 角色死亡
role_dead(RoleID, SrcID, SrcType) ->
    ?IS_COPY_DO(role_dead2(RoleID, SrcID, SrcType)).

role_dead2(RoleID, SrcID, SrcType) ->
    execute_mod(copy_data:get_copy_info(), role_dead, {RoleID, SrcID, SrcType}).

%% 角色升级
role_level_up(RoleID) ->
    ?IS_COPY_DO(role_level_up2(RoleID)).

role_level_up2(_RoleID) ->
    CopyInfo = copy_data:get_copy_info(),
    copy_data:set_copy_info(CopyInfo#r_map_copy{copy_level = copy_misc:get_average_level()}).

monster_enter(MapInfo) ->
    ?IS_COPY_DO(monster_enter2(MapInfo)).

monster_enter2(MapInfo) ->
    execute_mod(copy_data:get_copy_info(), monster_enter, {MapInfo}).

monster_dead(MapInfo, SrcID, SrcType) ->
    ?IS_COPY_DO(monster_dead2(MapInfo, SrcID, SrcType)).

monster_dead2(MapInfo, SrcID, SrcType) ->
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    #r_map_copy{
        success_type = SuccessType,
        success_args = SuccessArgs,
        cur_progress = CurProgress
    } = CopyInfo = copy_data:get_copy_info(),
    case SuccessType of
        ?SUCCESS_MONSTER ->
            {DestType, NeedNum} = SuccessArgs,
            case DestType =:= 0 orelse DestType =:= TypeID of
                true ->
                    case CurProgress < NeedNum of
                        true ->
                            CurProgress2 = CurProgress + 1,
                            CopyInfo2 = CopyInfo#r_map_copy{cur_progress = CurProgress + 1},
                            copy_data:set_copy_info(CopyInfo2),
                            broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}]),
                            ?IF(CurProgress2 =:= NeedNum, do_copy_end(?COPY_SUCCESS), ok);
                        _ ->
                            ok
                    end;
                _ ->
                    ok
            end;
        ?SUCCESS_DEFENCE ->
            ?IF(SuccessArgs =:= TypeID, do_copy_end(?COPY_FAILED), ok);
        _ ->
            ok
    end,
    execute_mod(copy_data:get_copy_info(), monster_dead, {MapInfo, SrcID, SrcType}).

monster_reduce_hp(MapInfo, ReduceSrc, ReduceHp) ->
    ?IS_COPY_DO(monster_reduce_hp2(MapInfo, ReduceSrc, ReduceHp)).

monster_reduce_hp2(MapInfo, ReduceSrc, ReduceHp) ->
    execute_mod(copy_data:get_copy_info(), monster_reduce_hp, {MapInfo, ReduceSrc, ReduceHp}).

role_get_cheer(RoleID, ID, AssetType) ->
    ?IS_COPY_DO(role_get_cheer2(RoleID, ID, AssetType)).

role_get_cheer2(RoleID, ID, AssetType) ->
    do_role_get_cheer(RoleID, ID, AssetType).

role_cheer(RoleID, ID, AssetType) ->
    ?IS_COPY_DO(role_cheer2(RoleID, ID, AssetType)).

role_cheer2(RoleID, ID, AssetType) ->
    do_role_cheer(RoleID, ID, AssetType).

role_auto_cheer(RoleID, SilverTimes, GoldTimes) ->
    ?IS_COPY_DO(role_auto_cheer2(RoleID, SilverTimes, GoldTimes)).

role_auto_cheer2(RoleID, SilverTimes, GoldTimes) ->
    execute_mod(copy_data:get_copy_info(), role_auto_cheer, {RoleID, SilverTimes, GoldTimes}).

robot_enter(RobotID) ->
    ?IS_COPY_DO(robot_enter2(RobotID)).

robot_enter2(RobotID) ->
    execute_mod(copy_data:get_copy_info(), robot_enter, RobotID).

robot_dead(RobotID) ->
    ?IS_COPY_DO(robot_dead2(RobotID)).

robot_dead2(RobotID) ->
    execute_mod(copy_data:get_copy_info(), robot_dead, {RobotID}).

handle(force_end) ->
    do_copy_end(?COPY_FAILED);
handle(force_shutdown) ->
    map_server:kick_all_roles(),
    map_server:delay_shutdown();
handle({gm_set_copy_time, RemainTime}) ->
    do_gm_set_copy_time(RemainTime);
handle({mod, Mod, Info}) ->
    Mod:handle(Info);
handle(Info) ->
    ?ERROR_MSG("unknow msg :~w", [Info]).

execute_mod(#r_map_copy{copy_mod = CopyMod}, Fun, Args) ->
    case erlang:function_exported(CopyMod, Fun, 1) of
        true ->
            ?TRY_CATCH(CopyMod:Fun(Args));
        _ ->
            ok
    end.

do_copy_end(Status) ->
    CopyInfo = copy_data:get_copy_info(),
    case CopyInfo#r_map_copy.status of
        ?COPY_NOT_END ->
            MapID = map_common_dict:get_map_id(),
            [#c_copy{copy_type = CopyType, succ_end_time = SuccEndTime, is_team_map = IsTeamMap} = Config] = lib_config:find(cfg_copy, MapID),
            Now = time_tool:now(),
            ShutDownTime = Now + ?END_SHUTDOWN_TIME,
            CopyInfo2 = CopyInfo#r_map_copy{status = Status, end_time = 0, shutdown_time = ShutDownTime},
            copy_data:set_copy_info(CopyInfo2),
            case lists:member(CopyType, [?COPY_TREASURE_SECRET]) of
                false ->
                    case Status =:= ?COPY_SUCCESS of
                        true ->
                            do_copy_finish(CopyInfo2, Config, Now, MapID),
                            Fun = fun() ->
                                [mod_role_map_panel:copy_success(RoleID, MapID) || RoleID <- mod_map_ets:get_in_map_roles()] end,
                            ?IF(SuccEndTime > 0, erlang:send_after(SuccEndTime * 1000, erlang:self(), {func, Fun}), Fun()),
                            if
                                CopyType =:= ?COPY_EQUIP -> %% 通关装备副本加亲密度
                                    [_LoopAdd, CopyEquipAdd, _BossAdd] = common_misc:get_global_list(?GLOBAL_FRIENDLY_ADD),
                                    team_misc:add_team_friendly(map_common_dict:get_map_extra_id(), CopyEquipAdd);
                                true ->
                                    ok
                            end;
                        _ ->
                            #r_map_copy{enter_roles = EnterRoles} = CopyInfo,
                            [mod_role_copy:copy_failed(RoleID, MapID) || RoleID <- EnterRoles]
                    end,
                    ?IF(CopyType =:= ?COPY_GUIDE_BOSS, ok, broadcast_update([#p_kv{id = ?COPY_UPDATE_STATUS, val = Status}]));
                _ -> %% 宝藏、boss指引不走结算
                    broadcast_update([#p_kv{id = ?COPY_UPDATE_STATUS, val = Status}]),
                    ok
            end,
            execute_mod(CopyInfo2, copy_end, CopyInfo2),
            ?IF(CopyType =:= ?COPY_TREASURE_SECRET, ok, mod_map_monster:delete_monsters()),
            ?IF(?IS_TEAM_MAP(IsTeamMap), mod_team_copy:copy_end(map_common_dict:get_map_extra_id()), ok);
        _ ->
            ok
    end.

do_copy_finish(CopyInfo, Config, Now, MapID) ->
    #r_map_copy{
        start_time = StartTime,
        start_time_ms = StartTimeMs,
        enter_roles = EnterRoles
    } = CopyInfo,
    #c_copy{
        times_type = TimesType,
        stars_type = StarsType,
        stars_args = StarsArgs,
        is_team_map = IsTeamMap} = Config,
    UseTime = Now - StartTime,
    Stars =
        if
            StarsType =:= ?STARS_TIME -> %% 时间计算星级
                [ThreeStars, TwoStars, OneStar] = StarsArgs,
                if
                    UseTime =< ThreeStars ->
                        ?COPY_STAR_3;
                    UseTime =< TwoStars ->
                        ?COPY_STAR_2;
                    UseTime =< OneStar ->
                        ?COPY_STAR_1;
                    true ->
                        0
                end;
            StarsType =:= ?STARS_RUN_NUM -> %% 按逃跑人数计算星级
                RunNum = execute_mod(CopyInfo, get_run_num, CopyInfo),
                [ThreeStars, TwoStars, OneStar] = StarsArgs,
                if
                    RunNum =< ThreeStars ->
                        ?COPY_STAR_3;
                    RunNum =< TwoStars ->
                        ?COPY_STAR_2;
                    RunNum =< OneStar ->
                        ?COPY_STAR_1;
                    true ->
                        0
                end;
            true ->
                0
        end,
        UseTimeMs = time_tool:now_ms() - StartTimeMs,
        case ?IS_TEAM_MAP(IsTeamMap) of
            true ->
                #r_map_team{extra_role_id_list = ExtraRoleIDList} = mod_map_dict:get_map_params(),
                RewardRoles = ?IF(TimesType =:= ?TIMES_TYPE_SUCC, mod_map_ets:get_in_map_roles() -- ExtraRoleIDList, EnterRoles -- ExtraRoleIDList),
                [mod_role_copy:finish_copy(RoleID, MapID, Stars, UseTimeMs, execute_mod(CopyInfo, get_finish_args, CopyInfo)) || RoleID <- RewardRoles],
                ?IF(ExtraRoleIDList =/= [], [mod_role_copy:finish_team_copy_reward(RoleID) || RoleID <- ExtraRoleIDList], ok);
            _ ->
                RewardRoles = ?IF(TimesType =:= ?TIMES_TYPE_SUCC, mod_map_ets:get_in_map_roles(), EnterRoles),
                [mod_role_copy:finish_copy(RoleID, MapID, Stars, UseTimeMs, execute_mod(CopyInfo, get_finish_args, CopyInfo)) || RoleID <- RewardRoles]
        end.



do_copy_shutdown() ->
    pname_server:send(erlang:self(), {map_shutdwon, copy_shutdown}).

broadcast_update(KVList) ->
    DataRecord = #m_copy_info_update_toc{kv_list = KVList},
    map_server:send_msg_by_roleids(mod_map_ets:get_in_map_roles(), DataRecord).

get_info_record(CopyInfo) ->
    #r_map_copy{
        map_id = MapID,
        status = Status,
        start_time = StartTime,
        end_time = EndTime,
        cur_progress = CurProgress,
        sub_progress = SubProgress,
        all_wave = AllWave} = CopyInfo,
    #m_copy_info_toc{
        map_id = MapID,
        status = Status,
        start_time = StartTime,
        end_time = EndTime,
        cur_progress = CurProgress,
        sub_progress = SubProgress,
        all_wave = AllWave}.

do_gm_set_copy_time(RemainTime) ->
    CopyInfo = copy_data:get_copy_info(),
    case CopyInfo#r_map_copy.status of
        ?COPY_NOT_END ->
            EndTime = time_tool:now() + RemainTime,
            CopyInfo2 = CopyInfo#r_map_copy{end_time = EndTime},
            copy_data:set_copy_info(CopyInfo2),
            broadcast_update([#p_kv{id = ?COPY_UPDATE_END_TIME, val = EndTime}]);
        _ ->
            ok
    end.

log_role_copy(RoleID, MapID, ActionType) ->
    #r_role_attr{
        level = Level,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log = #log_role_copy{
        role_id = RoleID,
        role_level = Level,
        map_id = MapID,
        action_type = ActionType,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    background_misc:log(Log).

do_role_get_cheer(RoleID, ID, AssetType) ->
    case catch check_can_cheer(RoleID, ID, AssetType) of
        {ok, AssetType, AssetValue, AddBuffID} ->
            {ok, AssetType, AssetValue, AddBuffID};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_cheer(RoleID, ID, AssetType) ->
    #r_copy_role{cheer_list = CheerList} = copy_data:get_copy_role(RoleID),
    #r_cheer_args{
        cost_list = CostList,
        silver_times = SilverTimes,
        all_times = MaxTimes,
        add_buff_id = AddBuffID
    } = execute_mod(copy_data:get_copy_info(), get_cheer_config, ID),
    CopyCheer =
    case lists:keyfind(ID, #p_copy_cheer.id, CheerList) of
        #p_copy_cheer{} = CopyCheerT ->
            CopyCheerT;
        _ ->
            #p_copy_cheer{id = ID}
    end,
    #p_copy_cheer{silver_cheer_times = SilverCheerTimes, all_cheer_times = AllTimes} = CopyCheer,
    ?IF(AllTimes < MaxTimes, ok, ?THROW_ERR(?ERROR_COPY_EXP_CHEER_001)),
    ?IF(AssetType =:= ?CONSUME_SILVER andalso SilverCheerTimes >= SilverTimes, ?THROW_ERR(?ERROR_COPY_EXP_CHEER_003), ok),
    AssetValue =
    case lists:keyfind(AssetType, 1, CostList) of
        {_, AssetValueT} ->
            AssetValueT;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    {ok, AssetType, AssetValue, AddBuffID}.

do_role_cheer(RoleID, ID, AssetType) ->
    #r_copy_role{cheer_list = CheerList} = CopyRole = copy_data:get_copy_role(RoleID),
    {CopyCheer, CheerList2} =
    case lists:keytake(ID, #p_copy_cheer.id, CheerList) of
        {value, #p_copy_cheer{} = CopyCheerT, CheerListT} ->
            {CopyCheerT, CheerListT};
        _ ->
            {#p_copy_cheer{id = ID}, CheerList}
    end,
    #p_copy_cheer{silver_cheer_times = SilverCheerTimes, all_cheer_times = CheerTimes} = CopyCheer,
    SilverCheerTimes2 = ?IF(AssetType =:= ?CONSUME_SILVER, SilverCheerTimes + 1, SilverCheerTimes),
    CheerTimes2 = CheerTimes + 1,
    CopyCheer2 = CopyCheer#p_copy_cheer{silver_cheer_times = SilverCheerTimes2, all_cheer_times = CheerTimes2},
    CheerList3 = [CopyCheer2|CheerList2],
    copy_data:set_copy_role(RoleID, CopyRole#r_copy_role{cheer_list = CheerList3}),
    {ok, CopyCheer2}.
