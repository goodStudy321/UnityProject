%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 修炼秘籍系统
%%% @end
%%% Created : 10. 十月 2019 10:43
%%%-------------------------------------------------------------------
-module(mod_role_act_esoterica).
-author("huangxiangrui").

-include("common.hrl").
-include("role.hrl").
-include("cycle_act.hrl").
-include("role_extra.hrl").
-include("act_esoterica.hrl").
-include("mod_role_act_esoterica.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    zero/1,               %% 零点
    online/1,            %% 上线
    offline/1
]).

-export([handle/2]).

-export([init_data/2, send/2]).

-export([
    random_mission/0,
    purchase_celestial/1,
    gather_esoterica_task/2,
    gather_esoterica_task/3,
    gm_add_gather_task/3
]).

-export([
    send_letter/1,
    do_egg_end/1,
    add_training_point/2,
    set_esoterica_last_offline_time/2
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

init(#r_role{role_id = RoleID, role_act_esoterica = undefined} = State) ->
    ActEsoterica = #r_role_act_esoterica{role_id = RoleID},
    set_esoterica_last_offline_time(State#r_role{role_act_esoterica = ActEsoterica}, none);
init(State) ->
    set_esoterica_last_offline_time(State, none).

zero(#r_role{role_id = RoleID} = State) ->
    case is_esoterica_open(State) of
        false ->
            State;
        true ->
            {_Retrieve, State1} = compute_training_point(State),
            State2 = do_act_esoterica_info(RoleID, State1),
            #r_role{role_act_esoterica = ActEsoterica} = State2,
            #r_role_act_esoterica{} = ActEsoterica,

            Now = time_tool:now(),
            {Task, Mission} = random_mission(),
            NewActEsoterica = ActEsoterica#r_role_act_esoterica{task_list = Task, mission_list = Mission, task_time = Now},
            State3 = State2#r_role{role_act_esoterica = NewActEsoterica},
            do_act_esoterica_task(RoleID, State3)
    end.

online(#r_role{role_id = RoleID} = State) ->
    case is_esoterica_open(State) of
        false -> % 活动结束检测没领取的奖励
            do_act_esoterica_info(RoleID, send_letter(State));
        true ->
            {_Retrieve, State1} = compute_training_point(State),
            State2 = do_act_esoterica_info(RoleID, State1),
            #r_role{role_act_esoterica = ActEsoterica} = State2,
            #r_role_act_esoterica{task_time = TaskTime} = ActEsoterica,
            case time_tool:is_same_date(TaskTime) of
                true ->
                    do_act_esoterica_task(RoleID, State2);
                _ ->
                    Now = time_tool:now(),
                    {Task, Mission} = random_mission(),
                    NewActEsoterica = ActEsoterica#r_role_act_esoterica{task_list = Task, mission_list = Mission, task_time = Now},
                    State3 = State2#r_role{role_act_esoterica = NewActEsoterica},
                    do_act_esoterica_task(RoleID, State3)
            end
    end.

offline(State) ->
    set_esoterica_last_offline_time(State, offline).


init_data(StartTime, #r_role{role_id = RoleID} = State) ->
    #r_role{role_act_esoterica = ActEsoterica1} = State1 = send_letter(State), % 活动开始检测之前没领取的奖励
    LastOfflineTime = mod_role_extra:get_data(?EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, 0, State),
    #r_role{role_act_esoterica = OldActEsoterica} = State2 =
        ?IF(LastOfflineTime =:= 0, begin {_Retrieve, NewState} = compute_training_point(State1#r_role{role_act_esoterica = ActEsoterica1#r_role_act_esoterica{open_time = StartTime}}), NewState end, State1),
    Now = time_tool:now(),
    {Task, Mission} = random_mission(),
    NeedConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_ESOTERICA),
    ActEsoterica = OldActEsoterica#r_role_act_esoterica{role_id = RoleID, open_time = StartTime, task_list = Task, mission_list = Mission, task_time = Now, config_num = NeedConfigNum},
    State3 = do_act_esoterica_info(RoleID, State2#r_role{role_act_esoterica = ActEsoterica}),
    do_act_esoterica_task(RoleID, State3).

%% 活动结束
do_egg_end(State) ->
    send_letter(State).

%% @doc 购买仙籍
purchase_celestial(#r_role{role_id = RoleID} = State) ->
    common_misc:unicast(RoleID, #m_role_act_esoterica_activate_toc{}),
    LargessExp = common_misc:get_global_int(?GLOBAL_ACT_ESOTERICA_LARGESS),
    {_Grade, #r_role{role_act_esoterica = ActEsoterica} = State1} = upgrade_grade(LargessExp, State),
    NewActEsoterica = ActEsoterica#r_role_act_esoterica{is_activate = 1},
    do_act_esoterica_info(RoleID, State1#r_role{role_act_esoterica = NewActEsoterica}).

%% @doc 购买修炼点
add_training_point(TrainingPoint, #r_role{role_id = RoleID} = State) ->
    case is_esoterica_open(State) of
        false ->
            State;
        _ when TrainingPoint > 0 ->
            {_Grade, State1} = upgrade_grade(TrainingPoint, State),
            do_act_esoterica_info(RoleID, State1);
        _ ->
            State
    end.

handle({#m_role_act_esoterica_info_tos{}, RoleID, _PID}, State) ->
    do_act_esoterica_info(RoleID, State);
handle({#m_role_act_esoterica_task_tos{}, RoleID, _PID}, State) ->
    do_act_esoterica_task(RoleID, State);
handle({#m_role_act_esoterica_award_tos{training_id = TrainingID, type = Type}, RoleID, _PID}, State) ->
    do_act_esoterica_award(TrainingID, Type, RoleID, State);
handle({#m_role_act_esoterica_draw_task_tos{mission_id = MissionID}, RoleID, _PID}, State) ->
    do_act_esoterica_draw_task(MissionID, RoleID, State);
handle({#m_role_act_esoterica_training_point_tos{training_point = TrainingPoint}, RoleID, _PID}, State) ->
    do_act_esoterica_training_point(TrainingPoint, RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc 随机任务
random_mission() ->
    ExtractNum = common_misc:get_global_int(?GLOBAL_ACT_ESOTERICA_LIMIT_EXTRACTION),
    {ok, Question} = lib_tool:random_elements_from_list(ExtractNum, cfg_act_esoterica_task:list()),

    lists:foldl(fun({ID, #c_act_esoterica_task{judge_id = JudgeID}}, {Acc1, Acc2}) ->
        Task = #r_act_esoterica_task{task_id = ID},
        Mission = #r_act_esoterica_mission{mission_id = JudgeID},
        {[Task | Acc1], [Mission | Acc2]} end, {[], []}, Question).

do_act_esoterica_info(RoleID, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    #r_role_act_esoterica{
        training_grade = TrainingGrade,
        experience = Exp,
        celestial_grade = CelestialGrade,
        ordinary_grade = OrdinaryGrade,
        retrieve = Retrieve,
        is_activate = IsActivate} = ActEsoterica,
    Msg = #m_role_act_esoterica_info_toc{
        training_grade = TrainingGrade,
        experience = Exp,
        ordinary_grade = OrdinaryGrade,
        celestial_grade = CelestialGrade,
        retrieve = Retrieve,
        is_activate = IsActivate},
    common_misc:unicast(RoleID, Msg),
    State.

%% @doc 任务库
do_act_esoterica_task(RoleID, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    #r_role_act_esoterica{task_list = Task, mission_list = Mission} = ActEsoterica,
    TaskList = to_p_act_esoterica_task(Task, Mission),
    Msg = #m_role_act_esoterica_task_toc{task_list = TaskList},
    common_misc:unicast(RoleID, Msg),
    State.

to_p_act_esoterica_task(Task, Mission) ->
    lists:map(fun(#r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}) ->
        #c_act_esoterica_task{parameter = Parameter, judge_id = MissionID} = get_c_act_esoterica_task(TaskID),
        #r_act_esoterica_mission{expedite = Expedite} = lists:keyfind(MissionID, #r_act_esoterica_mission.mission_id, Mission),
        NewExpedite = ?IF(Expedite >= Parameter, Parameter, Expedite),
        #p_act_esoterica_task{mission_id = TaskID, expedite = NewExpedite, is_reward = IsReward} end, Task).

%% @doc 升级
upgrade_grade(AddExp, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    #r_role_act_esoterica{experience = Exp, training_grade = TrainingGrade} = ActEsoterica,
    {NewExp, Grade} = upgrade_grade(AddExp + Exp, TrainingGrade),
    {Grade, State#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{experience = NewExp, training_grade = Grade}}};
upgrade_grade(0, TrainingGrade) ->
    {0, TrainingGrade};
upgrade_grade(Exp, TrainingGrade) ->
    [ReduceExp, Total_Grade] = common_misc:get_global_list(?GLOBAL_ACT_ESOTERICA_LIMIT_EXTRACTION),
    case Exp >= ReduceExp andalso Total_Grade > TrainingGrade of
        true ->
            upgrade_grade(Exp - ReduceExp, TrainingGrade + 1);
        _ ->
            {Exp, TrainingGrade}
    end.

%% @doc 奖励领取
do_act_esoterica_award(TrainingID, Type, RoleID, State) ->
    case catch check_act_esoterica_award(Type, TrainingID, State) of
        {ok, ?ORDINARY, AddGoodsList, OrdinaryGrade, State1} ->
            State2 = #r_role{role_act_esoterica = ActEsoterica} = role_misc:create_goods(State1, ?ITEM_GAIN_ACT_ESOTERICA_ORDINARY, AddGoodsList),
            Msg = #m_role_act_esoterica_award_toc{training_id = TrainingID, type = Type},
            common_misc:unicast(RoleID, Msg),
            State2#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{ordinary_grade = OrdinaryGrade}};
        {ok, ?CELESTIAL, AddGoodsList, Celestial_grade, State1} ->
            Msg = #m_role_act_esoterica_award_toc{training_id = TrainingID, type = Type},
            common_misc:unicast(RoleID, Msg),
            State2 = #r_role{role_act_esoterica = ActEsoterica} = role_misc:create_goods(State1, ?ITEM_GAIN_ACT_ESOTERICA_CELESTIAL, AddGoodsList),
            State2#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{celestial_grade = Celestial_grade}};
        {error, ErrCode} ->
            Msg = #m_role_act_esoterica_award_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, Msg),
            State
    end.

check_act_esoterica_award(?ORDINARY, TrainingID, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    ?IF(is_esoterica_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    ?IF(lib_config:find(cfg_act_esoterica_reward, TrainingID) =/= [], ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_001)),

    #c_act_esoterica_reward{grade = Grade, ordinary_award = OrdinaryAward, config_num = ConfigNum} = get_act_esoterica_reward(TrainingID),
    #r_role_act_esoterica{training_grade = TrainingGrade, ordinary_grade = OrdinaryGrade} = ActEsoterica,
    ?IF(TrainingGrade >= Grade, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_002)),
    NeedConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_ESOTERICA),
    ?IF(ConfigNum =:= NeedConfigNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    ?IF(lists:member(TrainingID, OrdinaryGrade), ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_003), ok),

    AddGoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(OrdinaryAward)],

    {ok, ?ORDINARY, AddGoodsList, [Grade | OrdinaryGrade], State};

check_act_esoterica_award(?CELESTIAL, TrainingID, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    ?IF(is_esoterica_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    ?IF(lib_config:find(cfg_act_esoterica_reward, TrainingID) =/= [], ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_001)),

    #c_act_esoterica_reward{grade = Grade, celestial_award = CelestialAward, config_num = ConfigNum} = get_act_esoterica_reward(TrainingID),
    #r_role_act_esoterica{training_grade = TrainingGrade, celestial_grade = CelestialGrade, is_activate = IsActivate} = ActEsoterica,
    ?IF(TrainingGrade >= Grade, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_002)),
    NeedConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_ESOTERICA),
    ?IF(ConfigNum =:= NeedConfigNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    ?IF(lists:member(TrainingID, CelestialGrade), ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_003), ok),
    ?IF(IsActivate =:= 1, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_AWARD_004)),

    AddGoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(CelestialAward)],
    {ok, ?CELESTIAL, AddGoodsList, [Grade | CelestialGrade], State}.

%% @doc 任务经验领取
do_act_esoterica_draw_task(MissionID, RoleID, State) ->
    case catch check_act_esoterica_draw_task(MissionID, State) of
        {ok, Grade, Exp, State2} ->
            Msg = #m_role_act_esoterica_draw_task_toc{training_grade = Grade, experience = Exp, mission_id = MissionID},
            common_misc:unicast(RoleID, Msg),
            State2;
        {error, ErrCode} ->
            Msg = #m_role_act_esoterica_draw_task_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, Msg)
    end.

check_act_esoterica_draw_task(TaskID, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    ?IF(is_esoterica_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),

    #r_role_act_esoterica{task_list = TaskList, mission_list = OrdinaryGrade} = ActEsoterica,

    Task = lists:keytake(TaskID, #r_act_esoterica_task.task_id, TaskList),
    ?IF(Task =/= false, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_DRAW_TASK_001)),

    {value, EsotericaTask = #r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}, TupleList2} = Task,

    ?IF(IsReward =/= true, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_DRAW_TASK_002)),

    #c_act_esoterica_task{judge_id = MissionID, parameter = Parameter, award_num = AwardNum} = get_c_act_esoterica_task(TaskID),

    #r_act_esoterica_mission{expedite = Expedite} = lists:keyfind(MissionID, #r_act_esoterica_mission.mission_id, OrdinaryGrade),

    ?IF(Expedite >= Parameter, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_DRAW_TASK_003)),

    State1 = State#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{task_list = [EsotericaTask#r_act_esoterica_task{is_reward = true} | TupleList2]}},
    {Grade, #r_role{role_act_esoterica = #r_role_act_esoterica{experience = Exp}} = State2} = upgrade_grade(AwardNum, State1),

    {ok, Grade, Exp, State2}.

%% @doc 任务信息变化
gather_esoterica_task(MissionID, State) ->
    gather_esoterica_task(MissionID, 1, State).
gather_esoterica_task(MissionID, Times, #r_role{role_id = RoleID, role_act_esoterica = ActEsoterica} = State) ->
    case is_esoterica_open(State) of
        true ->
            #r_role_act_esoterica{mission_list = OrdinaryGrade, task_list = TaskList} = ActEsoterica,
            case lists:keytake(MissionID, #r_act_esoterica_mission.mission_id, OrdinaryGrade) of
                {value, EsotericaMission = #r_act_esoterica_mission{expedite = Expedite}, TupleList2} ->
                    NewActEsoterica = ActEsoterica#r_role_act_esoterica{mission_list = [EsotericaMission#r_act_esoterica_mission{expedite = Expedite + Times} | TupleList2]},
                    lists:foreach(fun(#r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}) ->
                        #c_act_esoterica_task{judge_id = JudgeID, parameter = Parameter} = get_c_act_esoterica_task(TaskID),
                        case JudgeID =:= MissionID andalso IsReward =:= false of
                            true ->
                                NewExpedite = ?IF(Expedite + Times >= Parameter, Parameter, Expedite + Times),
                                Task = #p_act_esoterica_task{mission_id = TaskID, expedite = NewExpedite, is_reward = IsReward},
                                Msg = #m_role_act_esoterica_task_info_toc{task = Task},
                                common_misc:unicast(RoleID, Msg);
                            _ ->
                                none
                        end end, TaskList),
                    State#r_role{role_act_esoterica = NewActEsoterica};
                _ ->
                    State
            end;
        _ ->
            State
    end.

%% @doc 活动结束把没领取的奖励发送到邮件
send_letter(#r_role{role_id = RoleID, role_act_esoterica = ActEsoterica} = State) ->
    #r_role_act_esoterica{training_grade = TrainingGrade, ordinary_grade = OrdinaryGrade, celestial_grade = CelestialGrade, is_activate = IsActivate, config_num = OldConfigNum} = ActEsoterica,
    EsotericaRewardLists =
        lists:foldl(fun({_ID, Reward = #c_act_esoterica_reward{config_num = ConfigNum}}, Acc) ->
            case ConfigNum =:= OldConfigNum of
                true ->
                    [Reward | Acc];
                _ ->
                    Acc
            end end, [], cfg_act_esoterica_reward:list()),

    GoodsList =
        lists:foldl(fun(Grade, Acc) ->
            AccLists =
                case lists:member(Grade, OrdinaryGrade) of
                    false ->
                        #c_act_esoterica_reward{ordinary_award = OrdinaryAward} = lists:keyfind(Grade, #c_act_esoterica_reward.grade, EsotericaRewardLists),
                        [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(OrdinaryAward)] ++ Acc;
                    _ ->
                        Acc
                end,
            case (not lists:member(Grade, CelestialGrade)) andalso IsActivate =:= 1 of
                true ->
                    #c_act_esoterica_reward{celestial_award = CelestialAward} = lists:keyfind(Grade, #c_act_esoterica_reward.grade, EsotericaRewardLists),
                    [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(CelestialAward)] ++ AccLists;
                _ ->
                    AccLists
            end end, [], lists:seq(1, TrainingGrade)),
    case GoodsList =/= [] of
        true ->
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_ACT_ESOTERICA,
                action = ?ITEM_GAIN_ACT_ESOTERICA_SERVER_AWARD,
                goods_list = GoodsList},
            common_letter:send_cross_letter(RoleID, LetterInfo);
        _ ->
            none
    end,
    State#r_role{role_act_esoterica = #r_role_act_esoterica{role_id = RoleID}}.

%% @doc 计算可以找回的修炼点
compute_training_point(#r_role{role_act_esoterica = ActEsoterica} = State) ->
    New = time_tool:now(),
    #r_role_act_esoterica{open_time = OpenTime, task_list = TaskList, retrieve = Retrieve} = ActEsoterica,
    LastOfflineTime = mod_role_extra:get_data(?EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, 0, State),

    case time_tool:is_same_date(New, LastOfflineTime) of
        true ->
            {0, State};
        _ ->
            {Task, _Mission} = random_mission(),
            if
                OpenTime > LastOfflineTime -> %% 新号和长时间没登录的号
                    OpenDays = time_tool:diff_date(New, OpenTime),
                    Count1 =
                        lists:foldl(fun(#r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}, AccCount) ->
                            case IsReward =:= false of
                                true ->
                                    #c_act_esoterica_task{award_num = AwardNum} = get_c_act_esoterica_task(TaskID),
                                    AccCount + AwardNum;
                                _ ->
                                    AccCount
                            end end, 0, Task),
                    RetrieveNum = Count1 * OpenDays + Retrieve,
                    RecoveryPrice = common_misc:get_global_int(?GLOBAL_ACT_ESOTERICA_RECOVERY_PRICE),
                    NewRetrieveNum = ?IF(RecoveryPrice >= RetrieveNum, RetrieveNum, RecoveryPrice),
                    {NewRetrieveNum, set_esoterica_last_offline_time(State#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{retrieve = NewRetrieveNum}}, 0)};
                true ->
                    OpenDays = time_tool:diff_date(New, LastOfflineTime),
                    Count =
                        lists:foldl(fun(#r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}, AccCount) ->
                            case IsReward =:= false of
                                true ->
                                    #c_act_esoterica_task{award_num = AwardNum} = get_c_act_esoterica_task(TaskID),
                                    AccCount + AwardNum;
                                _ ->
                                    AccCount
                            end end, 0, TaskList),
                    Days = erlang:max(OpenDays - 1, 0),
                    Count1 =
                        lists:foldl(fun(#r_act_esoterica_task{task_id = TaskID, is_reward = IsReward}, AccCount) ->
                            case IsReward =:= false of
                                true ->
                                    #c_act_esoterica_task{award_num = AwardNum} = get_c_act_esoterica_task(TaskID),
                                    AccCount + AwardNum;
                                _ ->
                                    AccCount
                            end end, 0, Task),
                    RetrieveNum = Count + (Count1 * Days) + Retrieve,
                    RecoveryPrice = common_misc:get_global_int(?GLOBAL_ACT_ESOTERICA_RECOVERY_PRICE),
                    NewRetrieveNum = ?IF(RecoveryPrice >= RetrieveNum, RetrieveNum, RecoveryPrice),
                    {NewRetrieveNum, set_esoterica_last_offline_time(State#r_role{role_act_esoterica = ActEsoterica#r_role_act_esoterica{retrieve = NewRetrieveNum}}, 0)}
            end
    end.

%% @doc 找回修炼点
do_act_esoterica_training_point(TrainingPoint, RoleID, State) ->
    case catch check_act_esoterica_training_point(TrainingPoint, State) of
        {ok, RetrieveNum, AssetDoing, State1} ->
            State2 = mod_role_asset:do(AssetDoing, State1),
            {Grade, #r_role{role_act_esoterica = #r_role_act_esoterica{experience = Exp}} = State3} = upgrade_grade(TrainingPoint, State2),
            Msg = #m_role_act_esoterica_training_point_toc{training_point = RetrieveNum, training_grade = Grade, experience = Exp},
            common_misc:unicast(RoleID, Msg),
            State3;
        {error, ErrCode} ->
            Msg = #m_role_act_esoterica_training_point_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, Msg),
            State
    end.

check_act_esoterica_training_point(TrainingPoint, #r_role{role_act_esoterica = ActEsoterica} = State) ->
    ?IF(is_esoterica_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    #r_role_act_esoterica{retrieve = Retrieve} = ActEsoterica,

    ?IF(TrainingPoint > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ?IF(Retrieve >= TrainingPoint, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_TRAINING_POINT_001)),

    ?IF(Retrieve > 0, ok, ?THROW_ERR(?ERROR_ROLE_ACT_ESOTERICA_TRAINING_POINT_002)),

    [AssetType, Gold] = common_misc:get_global_list(?GLOBAL_ACT_ESOTERICA_RECOVERY_PRICE),
    AssetDoing = mod_role_asset:check_asset_by_type(AssetType, TrainingPoint * Gold, ?ASSET_GOLD_ACT_ESOTERICA_RECOVERY_PRICE, State),

    {ok, Retrieve - TrainingPoint, AssetDoing, State}.

%% @doc gm
gm_add_gather_task(MissionID, Times, State) ->
    gather_esoterica_task(MissionID, Times, State).

set_esoterica_last_offline_time(State, Default) ->
    case mod_role_extra:get_data(?EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, Default, State) of
        none ->
            mod_role_extra:set_data(?EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, 0, State);
        _ ->
            mod_role_extra:set_data(?EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, time_tool:now(), State)
    end.

is_esoterica_open(State) ->
    mod_role_cycle_act:is_act_open(?CYCLE_ACT_ESOTERICA, State).

%% @doc 修炼秘籍等级奖励
get_act_esoterica_reward(ID) ->
    [Config] = lib_config:find(cfg_act_esoterica_reward, ID),
    Config.

%% @doc 修炼秘境任务库
get_c_act_esoterica_task(ID) ->
    [Config] = lib_config:find(cfg_act_esoterica_task, ID),
    Config.