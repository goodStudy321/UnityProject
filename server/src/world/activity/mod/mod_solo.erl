%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 三月 2018 10:16
%%%-------------------------------------------------------------------
-module(mod_solo).
-author("laijichang").
-include("activity.hrl").
-include("solo.hrl").
-include("global.hrl").
-include("daily_liveness.hrl").
-include("mod_role_map.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_solo.hrl").
-include("proto/mod_solo.hrl").

%% API
-export([
    i/0,
    init/0,
    activity_prepare/0,
    activity_start/0,
    activity_stop/0,
    loop/1,
    handle/1,
    zeroclock/0
]).

%% map
-export([
    send_map_solo_end/2
]).

%% role
-export([
    send_solo_match/2,
    send_role_add_rank/1,
    send_role_offline/1,
    call_role_pre_enter/1,
    call_role_step_reward/2,
    call_role_enter_reward/2,
    call_role_solo_rank_info/3,
    call_role_get_is_fighting/1,
    call_role_online_solo_info/1
]).

-export([
    is_activity_open/0,
    get_activity/0,
    get_role_solo/1,
    get_season_stop_time/0
]).

-export([
    gm_add_score/2,
    gm_clear_solo/1,
    send_server_solo_gm_season_stop/0,
    send_server_solo_gm_season_start/0,
    get_step_by_score/1,
    do_send_solo_entering/0
]).

-export([
    get_role_activity_mod/0,
    get_map_activity_mod/0
]).

i() ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, i).

%% @doc
%% 1 建立排行
%% 2 1v1赛季开始时间
init() ->
    world_data:init_season_count(),
    world_data:set_cross_domain_server_peg(false),
    world_data:init_solo_rank(),           % 1
    world_data:init_solo_reset_date(),     % 2
    do_rank().

activity_prepare() ->
    set_solo_match([]),
    set_extra_id(1),
    ok.

activity_start() ->

    common_broadcast:bc_role_info_to_world({mod, mod_role_solo, activity_start}),
    do_rank(),
    ok.

activity_stop() ->
    do_rank(),
    RoleList =
        [begin
             RoleSolo2 = RoleSolo#r_role_solo{
                 is_matching = false,
                 is_fighting = false,
                 extra_id = 0},
             db:insert(?DB_ROLE_SOLO_P, RoleSolo2),
             RoleID
         end || #r_role_solo{role_id = RoleID} = RoleSolo <- db_lib:all(?DB_ROLE_SOLO_P)],
    DataRecord = #m_solo_role_info_update_toc{kb_list = [#p_kb{id = ?ROLE_INFO_IS_MATCHING, val = false}]},
    common_broadcast:bc_record_to_roles(RoleList, DataRecord),
    ok.

loop(Now) ->
    %% 每5秒进行一次匹配
    ?IF(Now rem 5 =:= 0, do_loop_match(), ok),

    do_loop_cross_server_peg(Now),

    %% 每30秒进行一次排行
    ?IF(Now rem 30 =:= 0, do_rank(), ok).

handle(Info) ->
    do_handle_info(Info).

zeroclock() ->
    do_zeroclock().

%% @doc 角色进程调用
get_role_activity_mod() ->
    OpenDays = common_config:get_open_days(),
    ?IF(OpenDays >= ?SINGLE_SERVER_SEND orelse common_config:is_cross_node(), activity_misc:get_activity_mod(?ACTIVITY_SOLO), world_activity_server).
%% @doc 地图进程调用
get_map_activity_mod() ->
    OpenDays = common_config:get_open_days(),
    ?IF(OpenDays >= ?SINGLE_SERVER_SEND orelse common_config:is_cross_node(), activity_misc:get_map_activity_mod(), world_activity_server).

%% @doc 玩家上线
call_role_online_solo_info(RoleID) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {role_online_solo_info, RoleID}).
%% @doc 玩家下线
send_role_offline(RoleID) ->
    Mod = get_role_activity_mod(),
    Mod:info_mod(?MODULE, {role_offline, RoleID}).
%% @doc 等级到添加并排序
send_role_add_rank(RoleID) ->
    world_activity_server:info_mod(?MODULE, {role_add_rank, RoleID}).
%% @doc 地图预进
call_role_pre_enter(RoleID) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {role_pre_enter, RoleID}).
call_role_get_is_fighting(RoleID) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {role_get_is_solo_able, RoleID}).
%% @doc 段位奖励领取
call_role_step_reward(RoleID, Step) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {step_reward, RoleID, Step}).
%% @doc 进入次数奖励
call_role_enter_reward(RoleID, Type) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {enter_reward, RoleID, Type}).
%% @doc 排行信息
call_role_solo_rank_info(RoleID, RoleName, Power) ->
    Mod = get_role_activity_mod(),
    Mod:call_mod(?MODULE, {role_solo_rank_info, RoleID, RoleName, Power}).
%% @doc 匹配
send_solo_match(RoleID, Type) ->
    Mod = get_role_activity_mod(),
    Mod:info_mod(?MODULE, {solo_match, RoleID, Type}).
gm_add_score(RoleID, AddScore) ->
    Mod = get_role_activity_mod(),
    Mod:info_mod(?MODULE, {gm_add_score, RoleID, AddScore}).
gm_clear_solo(RoleID) ->
    Mod = get_role_activity_mod(),
    Mod:info_mod(?MODULE, {gm_clear_solo, RoleID}).
%% @doc 地图结束(战斗结束)
send_map_solo_end(WinnerRoleID, LoseRoleID) ->
    Mod = get_map_activity_mod(),
    Mod:info_mod(?MODULE, {solo_end, WinnerRoleID, LoseRoleID}).
%% @doc 夸服录入玩家数据
send_server_solo_entering(RoleID) ->
    cross_activity_server:info_mod(?MODULE, {solo_entering, RoleID}).
%% @doc 赛季开始
send_server_solo_gm_season_start() ->
    cross_activity_server:info_mod(?MODULE, solo_gm_season_start).
send_server_solo_gm_season_stop() ->
    cross_activity_server:info_mod(?MODULE, solo_gm_season_stop).

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% @doc 循环匹配数据
do_loop_match() ->
    MatchList = do_sort_match_list(),
    NewMatchList = do_loop_match2(MatchList, []),
    set_solo_match(NewMatchList).

do_loop_match2([], MatchAcc) ->
    MatchAcc;
do_loop_match2([#r_role_solo_match{wait_round = WaitRound} = RoleSoloMatch], MatchAcc) ->
    [RoleSoloMatch#r_role_solo_match{wait_round = WaitRound + 1} | MatchAcc];
do_loop_match2([RoleSoloMatch1, RoleSoloMatch2 | R], MatchAcc) ->
    #r_role_solo_match{role_id = RoleID1, grade = Grade1, wait_round = WaitRound1} = RoleSoloMatch1,
    #r_role_solo_match{role_id = RoleID2, grade = Grade2} = RoleSoloMatch2,
    if
        Grade1 =:= Grade2 -> %% 两者段位相同,搞起
            do_loop_match3(RoleID1, RoleID2),
            do_loop_match2(R, MatchAcc);
        (Grade1 - Grade2) =< (WaitRound1 div 2) -> %% 10秒一轮，等待的轮数与段位差值相同
            do_loop_match3(RoleID1, RoleID2),
            do_loop_match2(R, MatchAcc);
        true ->
            MatchAcc2 = [RoleSoloMatch1#r_role_solo_match{wait_round = WaitRound1 + 1} | MatchAcc], % 没有匹配上
            do_loop_match2([RoleSoloMatch2 | R], MatchAcc2)
    end.

%% @doc 匹配好了
do_loop_match3(RoleID1, RoleID2) ->
    MapID = ?MAP_SOLO,
    ExtraID = update_extra_id(),
    {ok, _MapPID} = map_sup:start_map(MapID, ExtraID, common_config:get_server_id(), [RoleID1, RoleID2]),   % 启动地图
    % 数据记录
    #r_role_solo{enter_times = EnterTimes1, season_enter_times = SeasonEnterTimes1} = RoleSolo1 = get_role_solo(RoleID1),
    #r_role_solo{enter_times = EnterTimes2, season_enter_times = SeasonEnterTimes2} = RoleSolo2 = get_role_solo(RoleID2),
    set_role_solo(RoleSolo1#r_role_solo{extra_id = ExtraID, is_fighting = true, is_matching = false, enter_times = EnterTimes1 + 1, season_enter_times = SeasonEnterTimes1 + 1}),
    set_role_solo(RoleSolo2#r_role_solo{extra_id = ExtraID, is_fighting = true, is_matching = false, enter_times = EnterTimes2 + 1, season_enter_times = SeasonEnterTimes2 + 1}),
    % 信息通知发送
    DataRecord1 = #m_solo_role_info_update_toc{
        kv_list = [#p_dkv{id = ?ROLE_INFO_ENTER_TIMES, val = EnterTimes1 + 1},
            #p_dkv{id = ?ROLE_INFO_SEASON_ENTER_TIMES, val = SeasonEnterTimes1 + 1}],
        kb_list = [#p_kb{id = ?ROLE_INFO_IS_MATCHING, val = false}]},
    DataRecord2 = #m_solo_role_info_update_toc{
        kv_list = [
            #p_dkv{id = ?ROLE_INFO_ENTER_TIMES, val = EnterTimes2 + 1},
            #p_dkv{id = ?ROLE_INFO_SEASON_ENTER_TIMES, val = SeasonEnterTimes2 + 1}
        ],
        kb_list = [#p_kb{id = ?ROLE_INFO_IS_MATCHING, val = false}]},
    common_misc:unicast(RoleID1, DataRecord1),
    common_misc:unicast(RoleID2, DataRecord2),
    common_misc:unicast(RoleID1, #m_solo_match_ready_toc{}),
    common_misc:unicast(RoleID2, #m_solo_match_ready_toc{}),
    % 活跃度
    mod_role_daily_liveness:trigger_daily_liveness([RoleID1, RoleID2], ?LIVENESS_ROLE_SOLO),
    ok.

do_sort_match_list() ->
    MatchList = lib_tool:random_reorder_list(get_solo_match()),
    lists:sort(
        fun(#r_role_solo_match{grade = Grade1, wait_round = WaitRound1}, #r_role_solo_match{grade = Grade2, wait_round = WaitRound2}) ->
            ?IF(Grade1 =:= Grade2, WaitRound1 > WaitRound2, Grade1 > Grade2)
        end, MatchList).

%% @doc 检测是否超出时间，还没同步单服玩家数据到跨服
do_loop_cross_server_peg(Now) ->
    Bool = world_data:get_cross_domain_server_peg(),
    NodeBool = common_config:is_cross_node(),
    Mod = get_role_activity_mod(),
    StartTime = world_data:get_solo_reset_date(),
    StopTime = get_season_stop_time() + ?AN_HOUR,
    if
        NodeBool =:= false andalso Bool =:= false andalso 'cross_activity_server' =:= Mod ->
            world_data:set_cross_domain_server_peg(true),
%%            do_send_solo_entering(),
            do_season_reset(),
            activity_start();
        Now =:= StartTime -> % 赛季开始
            activity_start();
        Now > StopTime -> % 赛季结束检测
            ?LXG(time_tool:timestamp_to_datetime(StopTime)),
            world_data:set_solo_reset_date(time_tool:weekday_timestamp(?START_SATURDAY, 0, 0)),  % 下个开始赛季时间
            do_season_reset(),
            activity_start();
        true ->
            ok
    end.

do_handle_info(i) ->
    do_i();
do_handle_info({role_solo_rank_info, RoleID, RoleName, Power}) ->
    do_role_solo_rank_info(RoleID, RoleName, Power);
do_handle_info({role_get_is_solo_able, RoleID}) ->
    do_role_get_is_solo_able(RoleID);
do_handle_info({role_pre_enter, RoleID}) ->
    do_role_pre_enter(RoleID);
do_handle_info({role_online_solo_info, RoleID}) ->
    do_role_online_solo_info(RoleID);
do_handle_info({solo_end, WinnerRoleID, LoseRoleID}) ->
    do_solo_end(WinnerRoleID, LoseRoleID);
do_handle_info({step_reward, RoleID, Step}) ->
    do_step_reward(RoleID, Step);
do_handle_info({enter_reward, RoleID, Type}) ->
    do_enter_reward(RoleID, Type);
do_handle_info({role_add_rank, RoleID}) ->
    do_add_rank(RoleID);
do_handle_info({role_offline, RoleID}) ->
    do_role_offline(RoleID);
do_handle_info({solo_match, RoleID, Type}) ->
    do_solo_match(RoleID, Type);
do_handle_info({gm_add_score, RoleID, AddScore}) ->
    do_gm_add_score(RoleID, AddScore);
do_handle_info({gm_clear_solo, RoleID}) ->
    do_gm_clear_solo(RoleID);
do_handle_info({solo_entering, RoleID}) ->
    do_solo_entering(RoleID);
do_handle_info(solo_gm_season_start) ->
    do_solo_gm_season_start();
do_handle_info(solo_gm_season_stop) ->
    do_solo_gm_season_stop();
do_handle_info(Info) ->
    ?ERROR_MSG("Error Info : Info", Info).

do_i() ->
    {get_solo_match(), get_extra_id(), time_tool:timestamp_to_datetime(world_data:get_solo_reset_date())}.
%% @doc 跨天数据
do_zeroclock() ->

    Exp = 0,                % 当天获得经验
    EnterTimes = 0,         % 今天参与次数
    EnterRewardList = [],   % 当天已经领取参与奖励列表

    {RoleList, RoleSoloList} =
        lists:foldl(fun(#r_role_solo{role_id = RoleID} = RoleSolo, {Acc1, Acc2}) ->
            RoleSolo2 = RoleSolo#r_role_solo{
                enter_times = EnterTimes,
                enter_reward_list = EnterRewardList,
                exp = Exp},
            {[RoleID | Acc1], [RoleSolo2 | Acc2]} end, {[], []}, db:table_all(?DB_ROLE_SOLO_P)),

    DataRecord = #m_solo_role_info_update_toc{
        kv_list = [#p_dkv{id = ?ROLE_INFO_EXP, val = Exp}, #p_dkv{id = ?ROLE_INFO_ENTER_TIMES, val = EnterTimes}],
        kl_list = [#p_kvl{id = ?ROLE_INFO_ENTER_REWARDS, list = EnterRewardList}],
        kb_list = [#p_kb{id = ?ROLE_INFO_DAILY_REWARD, val = false}]},
    common_broadcast:bc_record_to_roles(RoleList, DataRecord),

    NodeBool = common_config:is_cross_node(),
    Bool = world_data:get_cross_domain_server_peg(),
    Mod = get_role_activity_mod(),
    StopTime = get_season_stop_time() + ?AN_HOUR,
    IsSame = time_tool:is_same_date(StopTime),

    if
        Bool =:= false andalso 'cross_activity_server' =:= Mod andalso NodeBool =:= false -> % 单服开服第8天0点 通过邮件发放对应奖励
            world_data:set_cross_domain_server_peg(true),
            do_season_reset(RoleSoloList),
            activity_start();
        IsSame andalso Bool =:= false andalso NodeBool =:= true -> % 每13天一个赛季
            world_data:set_solo_reset_date(time_tool:weekday_timestamp(?START_SATURDAY, 0, 0)),  % 下个开始赛季时间
            do_season_reset(RoleSoloList),
            world_data:gain_season_count(),
            activity_start();
        true ->
            db:insert(?DB_ROLE_SOLO_P, RoleSoloList)
    end.

%% @doc 赛季重置
do_season_reset() ->
    do_season_reset(db:table_all(?DB_ROLE_SOLO_P)).
do_season_reset(RoleSoloList) ->
    do_rank(),
    give_out_rank_reward(),

    Score = 0,
    SeasonWinTimes = 0,
    SeasonEnterTimes = 0,
    StepRewardList = [],
    List = [Solo#r_role_solo{
        score = Score,                          % 当前积分
        season_win_times = SeasonWinTimes,      % 赛季胜利总场次
        season_enter_times = SeasonEnterTimes,  % 赛季参与次总数
        step_reward_list = StepRewardList       % 已领取段位奖励
    } || Solo <- RoleSoloList],
    db:insert(?DB_ROLE_SOLO_P, List),
    KVList = [
        #p_dkv{id = ?ROLE_INFO_SCORE, val = Score},
        #p_dkv{id = ?ROLE_INFO_SEASON_ENTER_TIMES, val = SeasonEnterTimes},
        #p_dkv{id = ?ROLE_INFO_SEASON_WIN_TIMES, val = SeasonWinTimes}
    ],
    KLList = [#p_kvl{id = ?ROLE_INFO_STEP_REWARD_LIST, list = StepRewardList}],
    DataRecord = #m_solo_role_info_update_toc{kv_list = KVList, kl_list = KLList},
    RoleList = [RoleID || #r_role_solo{role_id = RoleID} <- List],
    common_broadcast:bc_record_to_roles(RoleList, DataRecord).
% 发排行榜奖励

%% @doc 匹配打完
do_solo_end(WinnerRoleID, LoseRoleID) ->
    #r_role_solo{score = WinnerScore} = WinnerSolo = get_role_solo(WinnerRoleID),
    #r_role_solo{score = LoseScore} = LoseSolo = get_role_solo(LoseRoleID),
    % 获取旧段位数据
    DailyList = cfg_solo_step_reward:list(),
    #c_solo_step_reward{step = Step1, win_add_score = WinAddScore} = WinnerConfig = get_score_config2(WinnerScore, DailyList, []),
    #c_solo_step_reward{lose_add_score = LoseAddScore} = LoseConfig = get_score_config2(LoseScore, DailyList, []),
    % 积分计算
    WinnerScore2 = WinnerScore + WinAddScore,
    LoseScore2 = LoseScore + LoseAddScore,
    % 输赢通知
    role_misc:info_role(WinnerRoleID, {hook_role, solo_win, [WinnerScore2]}),
    role_misc:info_role(LoseRoleID, {hook_role, role_solo, []}),
    % 获取奖励
    do_solo_end2(WinnerSolo, true, WinnerConfig, WinnerScore2, WinnerRoleID, LoseRoleID),
    do_solo_end2(LoseSolo, false, LoseConfig, LoseScore2, LoseRoleID, WinnerRoleID),
    % 发送公告
    #c_solo_step_reward{step = Step2, grade_name = GradeName} = get_score_config2(WinnerScore2, DailyList, []),
    ?IF(Step1 =/= Step2, common_broadcast:send_world_common_notice(?NOTICE_SOLO, [common_role_data:get_role_name(WinnerRoleID), GradeName]), ok).

%% @doc 获取奖励
do_solo_end2(Solo, IsWin, Config, NewScore, RoleID, OtherRoleID) ->
    #r_role_solo{enter_times = EnterTimes, season_win_times = SeasonWinTimes, exp = Exp, combo_win = ComboWin} = Solo,
    case EnterTimes =< ?SOLO_ADD_EXP_TIMES of % 前10次 获取奖励和经验
        true ->
            {ExpRate, AddHonor, GoodsList} = get_first_ten_rewards(IsWin, Config),
            AddExp = mod_role_level:get_activity_level_exp(common_role_data:get_role_level(RoleID), ExpRate),
            mod_role_solo:solo_end_reward(RoleID, AddExp, AddHonor, GoodsList); % 发送
        _ ->
            AddExp = 0
    end,
    Exp2 = Exp + AddExp,
    KVList1 = ?IF(AddExp > 0, [#p_dkv{id = ?ROLE_INFO_EXP, val = Exp2}], []),
    case IsWin of
        true -> % 胜利数据变更
            Solo2 = Solo#r_role_solo{season_win_times = SeasonWinTimes + 1, combo_win = ComboWin + 1},
            KVList2 = [#p_dkv{id = ?ROLE_INFO_SEASON_WIN_TIMES, val = SeasonWinTimes + 1} | KVList1];
        _ ->
            Solo2 = Solo#r_role_solo{combo_win = 0}, % 去掉连胜
            KVList2 = KVList1
    end,
    set_role_solo(Solo2#r_role_solo{score = NewScore, extra_id = 0, exp = Exp2, is_fighting = false, break_time = time_tool:now()}),
    DataRecord = #m_solo_result_toc{
        is_success = IsWin,
        solo_role_id = OtherRoleID,
        solo_role_name = common_role_data:get_role_name(OtherRoleID),
        new_score = NewScore,
        add_exp = AddExp
    },
    common_misc:unicast(RoleID, DataRecord),
    ?IF(KVList2 =/= [], common_misc:unicast(RoleID, #m_solo_role_info_update_toc{kv_list = KVList2}), ok).


%% @doc 段位奖励
do_step_reward(RoleID, Step) ->
    case catch check_step_reward(RoleID, Step) of
        {ok, AddHonor, RewardString, RoleSolo} ->
            set_role_solo(RoleSolo),
            {ok, AddHonor, RewardString};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_step_reward(RoleID, Step) ->
    activity_misc:check_role_level(?ACTIVITY_SOLO, RoleID),
    ?IF(common_config:is_cross_node(), ok, ?THROW_ERR(?ERROR_SOLO_ENTER_REWARD_003)),
    case lib_config:find(cfg_solo_step_reward, Step) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_SOLO_STEP_REWARD_001)
    end,
    #c_solo_step_reward{add_honor = AddHonor, score = NeedScore, reward_string = RewardString} = Config,
    #r_role_solo{score = Score, step_reward_list = StepRewardList} = RoleSolo = get_role_solo(RoleID),
    ?IF(lists:member(Step, StepRewardList), ?THROW_ERR(?ERROR_SOLO_STEP_REWARD_002), ok),
    ?IF(Score >= NeedScore, ok, ?THROW_ERR(?ERROR_SOLO_STEP_REWARD_003)),
    RoleSolo2 = RoleSolo#r_role_solo{step_reward_list = [Step | StepRewardList]},
    {ok, AddHonor, RewardString, RoleSolo2}.

%% @doc 参与奖励
do_enter_reward(RoleID, Type) ->
    case catch check_enter_reward(RoleID, Type) of
        {ok, GoodsList, EnterList, RoleSolo} ->
            set_role_solo(RoleSolo),
            {ok, GoodsList, EnterList};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_enter_reward(RoleID, Type) ->
    activity_misc:check_role_level(?ACTIVITY_SOLO, RoleID),
    #r_role_solo{enter_times = EnterTimes, enter_reward_list = EnterList} = RoleSolo = get_role_solo(RoleID),
    ?IF(EnterTimes >= Type, ok, ?THROW_ERR(?ERROR_SOLO_ENTER_REWARD_001)),
    ?IF(lists:member(Type, EnterList), ?THROW_ERR(?ERROR_SOLO_ENTER_REWARD_002), ok),
    case lib_config:find(cfg_solo_enter_reward, Type) of
        [#c_solo_enter_reward{rewards = RewardString}] ->
            ok;
        _ ->
            RewardString = ?THROW_ERR(?ERROR_SOLO_ENTER_REWARD_003)
    end,
    RewardList = common_misc:get_item_reward(RewardString),
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- RewardList],
    EnterList2 = [Type | EnterList],
    RoleSolo2 = RoleSolo#r_role_solo{enter_reward_list = EnterList2},
    {ok, GoodsList, EnterList2, RoleSolo2}.

%% @doc 添加并排序
do_add_rank(RoleID) ->
    #r_role_solo{rank = Rank} = mod_solo:get_role_solo(RoleID),
    if
        Rank =:= 0 ->
            case db:lookup(?DB_ROLE_SOLO_P, RoleID) of
                [#r_role_solo{}] ->
                    ok;
                _ ->
                    OpenDays = common_config:get_open_days(),
                    set_role_solo(#r_role_solo{role_id = RoleID, break_time = time_tool:now()}),
                    ?IF(common_config:is_cross_node(), do_rank(), ok),
                    ?IF((not common_config:is_cross_node()) andalso OpenDays >= ?SINGLE_SERVER_SEND, send_server_solo_entering(RoleID), ok)
            end;
        true ->
            ok
    end.

%% @doc 玩家下线
do_role_offline(RoleID) ->
    case mod_solo:is_activity_open() of
        true ->
            #r_role_solo{is_matching = IsMatching} = RoleSolo = mod_solo:get_role_solo(RoleID),
            if
                IsMatching ->
                    SoloMatch = get_solo_match(),
                    SoloMatch2 = lists:keydelete(RoleID, #r_role_solo_match.role_id, SoloMatch),
                    set_role_solo(RoleSolo#r_role_solo{is_matching = false}),
                    set_solo_match(SoloMatch2);
                true ->
                    ok
            end;
        _ ->
            ok
    end.

%% @doc 匹配准备
do_solo_match(RoleID, Type) ->
    case catch check_solo_match(RoleID, Type) of
        {ok, RoleSolo2, SoloMatch2} ->
            common_misc:unicast(RoleID, #m_solo_match_toc{type = Type}),
            set_role_solo(RoleSolo2),
            set_solo_match(SoloMatch2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_solo_match_toc{err_code = ErrCode})
    end.

check_solo_match(RoleID, Type) ->
    ?IF(is_activity_open(), ok, ?THROW_ERR(?ERROR_SOLO_MATCH_002)),
    StartTime = world_data:get_solo_reset_date(),
    StopTime = get_season_stop_time(),
    NowWeek = time_tool:now(),
    NodeBool = common_config:is_cross_node(),
    ?IF((StartTime =< NowWeek andalso NowWeek =< StopTime) orelse NodeBool =:= false, ok, ?THROW_ERR(?ERROR_FAMILY_BATTLE_CV_REWARD_005)),
    #r_role_solo{score = Score, is_matching = IsMatching} = RoleSolo = get_role_solo(RoleID),
    SoloMatch = get_solo_match(),
    if
        Type =:= ?SOLO_MATCH_START andalso not IsMatching -> % 开始
            IsMatching2 = true,
            #c_solo_step_reward{step = Grade} = get_score_config(Score),
            SoloMatch2 = [#r_role_solo_match{role_id = RoleID, grade = Grade} | SoloMatch];
        Type =:= ?SOLO_MATCH_STOP andalso IsMatching -> % 结束(取消)
            IsMatching2 = false,
            SoloMatch2 = lists:keydelete(RoleID, #r_role_solo_match.role_id, SoloMatch);
        true ->
            IsMatching2 = SoloMatch2 = ?THROW_ERR(?ERROR_SOLO_MATCH_001)
    end,
    RoleSolo2 = RoleSolo#r_role_solo{is_matching = IsMatching2},
    {ok, RoleSolo2, SoloMatch2}.

do_gm_add_score(RoleID, AddScore) ->
    #r_role_solo{score = Score} = Solo = get_role_solo(RoleID),
    Score2 = Score + AddScore,
    set_role_solo(Solo#r_role_solo{score = Score2}),
    common_misc:unicast(RoleID, #m_solo_role_info_update_toc{kv_list = [#p_dkv{id = ?ROLE_INFO_SCORE, val = Score2}]}).

do_gm_clear_solo(RoleID) ->
    Solo = get_role_solo(RoleID),
    set_role_solo(Solo#r_role_solo{enter_times = 0}),
    common_misc:unicast(RoleID, #m_solo_role_info_update_toc{kv_list = [#p_dkv{id = ?ROLE_INFO_ENTER_TIMES, val = 0}]}).

do_role_online_solo_info(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            do_add_rank(RoleID), % 预防跨服变换
            StopTime = get_season_stop_time(),
            StartTime = world_data:get_solo_reset_date(),
            {mod_solo:get_role_solo(RoleID), {StartTime, StopTime, world_data:get_season_count()}};
        _ ->
            {mod_solo:get_role_solo(RoleID), {0, 0, 0}}
    end.

%% @doc 预进地图
do_role_pre_enter(RoleID) ->
    case catch check_role_pre_enter(RoleID) of
        {ok, ExtraID, CampID, RecordPos} ->
            {ok, common_config:get_server_id(), ExtraID, CampID, RecordPos};
        {error, ErrCode} ->
            ErrCode
    end.
check_role_pre_enter(RoleID) ->
    case mod_solo:is_activity_open() of
        true ->
            #r_role_solo{extra_id = ExtraID, is_fighting = IsFighting} = mod_solo:get_role_solo(RoleID),
            case IsFighting of
                true ->
                    {CampID, RecordPos} = mod_map_solo:role_pos(RoleID, ExtraID),
                    {ok, ExtraID, CampID, RecordPos};
                _ ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_012)
            end;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_011)
    end.

%% @doc 是否在战斗中
do_role_get_is_solo_able(RoleID) ->
    case mod_solo:is_activity_open() of
        true ->
            #r_role_solo{is_fighting = IsFighting} = mod_solo:get_role_solo(RoleID),
            case IsFighting of
                true ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

%% @doc 排行信息
do_role_solo_rank_info(RoleID, RoleName, Power) ->
    AllList = world_data:get_solo_rank(),
    #r_role_solo{rank = Rank, score = Score} = mod_solo:get_role_solo(RoleID),
    Ranks = [SoloRank#p_solo_rank{role_name = common_role_data:get_role_name(RankRoleID),
        power = common_role_data:get_role_power(RankRoleID), server_name = get_server_name(RankRoleID),
        category = common_role_data:get_role_category(RankRoleID)} || #p_solo_rank{role_id = RankRoleID} = SoloRank <- AllList],

    MyRank = ?IF(Score =:= 0 orelse AllList =:= [] orelse Rank > ?SOLO_RANK_NUM, undefined, #p_solo_rank{role_id = RoleID, role_name = RoleName, power = Power,
        server_name = get_server_name(RoleID), rank = Rank, score = Score, category = common_role_data:get_role_category(RoleID)}),

    {ok, MyRank, Ranks}.

%% @doc 数据进行排行
do_rank() ->
    AllSolo = ets:tab2list(?DB_ROLE_SOLO_P),
    RankSolo =
        lists:sort(fun(#r_role_solo{score = Score1, break_time = BreakTime1}, #r_role_solo{score = Score2, break_time = BreakTime2}) ->
            if
                Score1 > Score2 ->
                    true;
                Score1 < Score2 ->
                    false;
                true ->
                    BreakTime1 =< BreakTime2
            end end, AllSolo),

    {RankSolo2, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#r_role_solo{rank = Rank},
            {[E1 | Acc], Rank + 1}
        end, {[], 1}, RankSolo),

    db:insert(?DB_ROLE_SOLO_P, RankSolo2),
    % 数据截取
    Ranks = [#p_solo_rank{role_id = RoleID, rank = Rank, score = Score} ||
        #r_role_solo{role_id = RoleID, rank = Rank, score = Score} <- lists:sublist(lists:reverse(RankSolo2), ?SOLO_RANK_NUM), Score > 0],
    world_data:set_solo_rank(Ranks).

%% @doc 排行奖励
give_out_rank_reward() ->
    Type = ?IF(common_config:is_cross_node(), 2, ?SINGLE_SERVER_TYPE),
    lists:foreach(fun(#p_solo_rank{role_id = RankRoleID, rank = Rank}) ->
        #c_solo_rank_reward{reward = Reward} = get_rank_reward_config(Rank, Type),
        GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(Reward)],
        letter(Type, RankRoleID, Rank, world_data:get_season_count(), GoodsList);
        ({p_solo_rank, Rank, RankRoleID}) ->
            #c_solo_rank_reward{reward = Reward} = get_rank_reward_config(Rank, Type),
            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(Reward)],
            letter(Type, RankRoleID, Rank, world_data:get_season_count(), GoodsList) end, world_data:get_solo_rank()).

get_rank_reward_config(Rank, Type) ->
    List = cfg_solo_rank_reward:list(),
    get_rank_reward_config(Rank, Type, List).
get_rank_reward_config(_Rank, _Type, []) ->
    [];
get_rank_reward_config(Rank, Type, [{_, SoloRank = #c_solo_rank_reward{type = Type, region = [A, B]}} | List]) ->
    case A =< Rank andalso Rank =< B of
        true ->
            SoloRank;
        _ ->
            get_rank_reward_config(Rank, Type, List)
    end;
get_rank_reward_config(Rank, Type, [{_, #c_solo_rank_reward{}} | List]) ->
    get_rank_reward_config(Rank, Type, List).
%% @doc 发邮件
letter(?SINGLE_SERVER_TYPE, RoleID, Rank, _Reset, GoodsList) ->
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_SOLO_SINGLE_SERVER_AWARD,
        action = ?ITEM_GAIN_SOLO_SINGLE_SERVER_AWARD,
        text_string = [lib_tool:to_list(Rank)],
        goods_list = GoodsList},
    common_letter:send_cross_letter(RoleID, LetterInfo);
letter(_, RoleID, Rank, Reset, GoodsList) ->
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_SOLO_SPAN_SERVER_AWARD,
        action = ?ITEM_GAIN_SOLO_SPAN_SERVER_AWARD,
        text_string = [lib_tool:to_list(Reset), lib_tool:to_list(Rank)],
        goods_list = GoodsList},
    common_letter:send_cross_letter(RoleID, LetterInfo).

%% @doc 根据积分选取对应的段位信息
get_score_config(Score) ->
    List = cfg_solo_step_reward:list(),
    get_score_config2(Score, List, []).
get_score_config2(_Score, [], Config) ->
    Config;
get_score_config2(Score, [{_, DailyReward} | R], Config) ->
    #c_solo_step_reward{score = NeedScore} = DailyReward,
    case Score >= NeedScore of
        true ->
            get_score_config2(Score, R, DailyReward);
        _ ->
            Config
    end.

%% @doc 奖励获取
%% 1 输赢都有奖励
get_first_ten_rewards(IsWin, Config) ->
    #c_solo_step_reward{
        win_exp_rate = WinExpRate,
        win_honor = WinHonor,
        lose_exp_rate = LoseExpRate,
        lose_honor = LoseHonor,
        item_rewards = ItemRewards
    } = Config,
    % 1
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(ItemRewards)],
    case IsWin of
        true ->
            {WinExpRate, WinHonor, GoodsList};
        _ ->
            {LoseExpRate, LoseHonor, GoodsList}
    end.

%% @doc 赛季结束时间
get_season_stop_time() ->
    Time = world_data:get_solo_reset_date(),
    {Data, _} = time_tool:timestamp_to_datetime(Time),
    time_tool:timestamp(time_tool:add_days({Data, ?END_RESET_TIME}, ?SOLO_RESET_WEEK - 1)).

do_solo_gm_season_start() ->
    NowWeek = time_tool:now(),
    world_data:set_solo_reset_date(NowWeek - 2).

do_solo_gm_season_stop() ->
    NowWeek = time_tool:now(),
    world_data:set_solo_reset_date(NowWeek + ?ONE_DAY),  % 下个开始赛季时间
    do_season_reset(),
    activity_start().

%% @doc 把单服的玩家数据同步到跨服
do_send_solo_entering() ->
    Lists = [RoleID || #r_role_solo{role_id = RoleID} <- ets:tab2list(?DB_ROLE_SOLO_P)],
    send_server_solo_entering(Lists).

%% @doc 录入单服发来的数据
do_solo_entering(RoleIDList) when is_list(RoleIDList) ->
    [do_add_rank(RoleID) || RoleID <- RoleIDList];
do_solo_entering(RoleID) ->
    do_add_rank(RoleID).

%%%===================================================================
%%% dict
%%%===================================================================
%% @doc 活动状态
is_activity_open() ->
    #r_activity{status = Status} = get_activity(),
    Status =:= ?STATUS_OPEN.

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_SOLO).

set_role_solo(RoleSolo) ->
    db:insert(?DB_ROLE_SOLO_P, RoleSolo).
get_role_solo(RoleID) ->
    case db:lookup(?DB_ROLE_SOLO_P, RoleID) of
        [#r_role_solo{} = RoleSolo] ->
            RoleSolo;
        _ ->
            #r_role_solo{role_id = RoleID}
    end.

%% @doc 准备匹配的玩家信息
set_solo_match(MatchList) ->
    erlang:put({?MODULE, solo_match}, MatchList).
get_solo_match() ->
    erlang:get({?MODULE, solo_match}).

%% @doc 分线
update_extra_id() ->
    ExtraID = get_extra_id(),
    set_extra_id(ExtraID + 1),
    ExtraID.
set_extra_id(ExtraID) ->
    erlang:put({?MODULE, extra_id}, ExtraID).
get_extra_id() ->
    erlang:get({?MODULE, extra_id}).

%% @doc 根据积分选取对应的段位
get_step_by_score(Score) ->
    List = cfg_solo_step_reward:list(),
    get_step_by_score(List, Score, 0).

get_step_by_score([], _Score, Step) ->
    Step;
get_step_by_score([{ID, Config} | T], Score, Step) ->
    case Config#c_solo_step_reward.score > Score of
        true ->
            Step;
        _ ->
            get_step_by_score(T, Score, ID)
    end.

get_server_name(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            case cross_role_data_server:get_role_data(RoleID) of
                #r_role_cross_data{server_name = ServerName} ->
                    ServerName;
                _ ->
                    ""
            end;
        _ ->
            ""
    end.