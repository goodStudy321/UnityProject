%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 道庭任务
%%% @end
%%% Created : 14. 六月 2019 16:00
%%%-------------------------------------------------------------------
-module(mod_role_family_asm).
-author("huangxiangrui").
-include("common.hrl").
-include("vip.hrl").
-include("role.hrl").
-include("family.hrl").
-include("family_asm.hrl").
-include("global.hrl").
-include("role_extra.hrl").
-include("copy_immortal.hrl").
-include("mod_role_item.hrl").
-include("mod_role_mission.hrl").
-include("mod_role_fairy.hrl").
-include("mod_role_family.hrl").
-include("mod_map_collection.hrl").
-include("mod_role_family_asm.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    send/2,
    hour_change/2,
    day_reset/1,          %% 夸天重置
    online/1             %% 上线
]).

-export([handle/2]).

-export([
    role_join_family/1,
    role_leave_family/1,
    gm_change_task_type/2,
    gm_nonsuch_time/1,
    get_family_asm_config/1,
    send_task_info/1,
    get_family_asm_log/3
]).

-export([
    filtrate_task/6
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

online(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, family_id = _FamilyID} = RoleAttr,
    State2 = do_asm_info(RoleID, State),
    do_asm_ask_info(RoleID, State2).

day_reset(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, family_id = _FamilyID} = RoleAttr,

    State2 = do_asm_info(RoleID, State),
    State3 = do_asm_ask_info(RoleID, State2),
    mod_role_extra:set_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State3).

hour_change(Hour, State) ->
    HourLists = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_RENOVATE),
    case lists:member(Hour, HourLists) of
        true ->
            online(State);
        _ ->
            State
    end.

%% @doc 角色加入公会
%% 要在hook_role模块里添加才生效
role_join_family(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, family_id = _FamilyID} = RoleAttr,
    State2 = do_asm_info(RoleID, State),
    do_asm_ask_info(RoleID, State2).

%% @doc 离开公会
role_leave_family(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, family_id = _FamilyID} = RoleAttr,
    mod_family_asm:call_role_leave_family(RoleID),
    State2 = do_asm_info(RoleID, State),
    do_asm_ask_info(RoleID, State2).

handle({#m_role_family_asm_ask_info_tos{}, RoleID, _PID}, State) ->
    do_asm_ask_info(RoleID, State);
handle({#m_role_family_asm_info_tos{}, RoleID, _PID}, State) ->
    do_asm_info(RoleID, State);
handle({#m_role_family_asm_operate_tos{mission_id = MissionID, type = Type}, RoleID, _PID}, State) ->
    do_operate(MissionID, Type, RoleID, State);
handle({#m_role_family_asm_help_member_tos{mission_id = MissionID, member_id = MemberID}, RoleID, _PID}, State) ->
    do_help_member(MissionID, MemberID, RoleID, State);
handle({#m_role_family_asm_ref_tos{type = Type}, RoleID, _PID}, State) ->
    do_ref(Type, RoleID, State);
handle({update_task, _MemberID, MissionID}, State) ->
    do_update_task(MissionID, State);
handle(send_task_info, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID} = RoleAttr,
    do_asm_info(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

send_task_info(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, send_task_info}).

%% @doc 道庭任务信息
do_asm_info(RoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    VIP = mod_role_vip:get_vip_level(State),
    case mod_role_function:get_is_function_open(?FUNCTION_FAMILY_MISSION, State) andalso ?HAS_FAMILY(FamilyID) of
        false ->
            State2 = State,
            Renovate = false,
            FamilyMission = [];
        _ ->
            #r_role_family_mi{nonsuch_time = NonsuchTime} = mod_family_data:get_role_family_asm_info(RoleID),
            {Renovate, FamilyMission} =
                if
                    ?IF_THE_REFRESH(NonsuchTime) =:= false ->
                        TaskIDList = filtrate_task(RoleID, VIP, ?CHOOSE_NUM, false, [], []),
                        {NewNonsuchTime, Accept} = mod_family_asm:call_first_time_task(RoleID, TaskIDList),
                        {?JUDGEMENT_TIME(NewNonsuchTime), [to_p_family_mission(E) || E <- Accept]};
                    true ->
                        {NewNonsuchTime, L} = mod_family_asm:call_check_task(RoleID, VIP),
                        {?JUDGEMENT_TIME(NewNonsuchTime), [to_p_family_mission(E) || E <- L]}
                end,
            State2 = ?IF(?IF_THE_REFRESH(NonsuchTime) =:= false andalso time_tool:is_same_date(NonsuchTime), mod_role_extra:set_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State), State)
    end,
    common_misc:unicast(RoleID, #m_role_family_asm_info_toc{renovate = Renovate, family_mission = FamilyMission}),
    State2.

%% @doc 道庭任务求助信息
do_asm_ask_info(RoleID, State) ->
    #r_role{role_attr = Attr} = State,
    #r_role_attr{family_id = FamilyID} = Attr,
    case ?HAS_FAMILY(FamilyID) andalso mod_role_function:get_is_function_open(?FUNCTION_FAMILY_MISSION, State) of
        true ->
            PFamily = mod_family_data:get_family(FamilyID),

            MissionAsk =
                lists:foldl(fun(#p_family_member{role_id = MembersID}, Acc) ->
                    #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(MembersID),
                    case MembersID =/= RoleID andalso
                        lists:filter(fun(#r_family_mi{is_help = IsHelp, attend = Attend, stop_time = StopTime, expedite = Expedite}) ->
                            IsHelp > 0 andalso (not lists:member(RoleID, Attend)) andalso StopTime > time_tool:now()
                                     andalso get_family_quicken(common_role_data:get_role_vip_level(MembersID)) > Expedite end, UnderWay) of
                        [_ | _] = Lists ->
                            [to_p_family_mission_ask(MembersID, [to_p_family_mission(E)||E<-Lists]) | Acc];
                        _ ->
                            Acc
                    end end, [], PFamily#p_family.members),

            Inspire = mod_role_extra:get_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State);
        _ ->
            Inspire = 0,
            MissionAsk = []
    end,
    common_misc:unicast(RoleID, #m_role_family_asm_ask_info_toc{inspire = Inspire, mission_ask = MissionAsk}),
    State.

%% @doc 道庭任务操作
do_operate(MissionID, Type, RoleID, State) ->
    case catch check_operate(MissionID, Type, RoleID, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_role_family_asm_operate_toc{mission_id = MissionID, type = Type});
        {ok, NewFamilyMi, State2} ->
            ?TRY_CATCH(mod_role_log_statistics:log_family_task(State)),
            common_misc:unicast(RoleID, #m_role_family_asm_operate_toc{mission_id = MissionID, type = Type}),
            common_misc:unicast(RoleID, #m_role_family_asm_up_toc{family_mission = NewFamilyMi});
        {ok, StarLevel, GoodsList, NewFamilyMi, State1} ->
            common_misc:unicast(RoleID, #m_role_family_asm_operate_toc{mission_id = MissionID, type = Type}),
            StateNow = role_misc:create_goods(State1, ?ITEM_GAIN_FAMILY_ASM, GoodsList),
            State2 = hook_role:family_task_finish(StateNow, MissionID),
            Log = get_family_asm_log(MissionID, StarLevel, State2),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_role_family_asm_up_toc{family_mission = NewFamilyMi});
        {error, ErrCode} ->
            State2 = State,
            common_misc:unicast(RoleID, #m_role_family_asm_operate_toc{err_code = ErrCode})
    end,
    State2.

check_operate(MissionID, ?RECEIVE_TASK, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #r_role_family_mi{accept = Accept, under_way = UnderWay} = mod_family_data:get_role_family_asm_info(RoleID),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay), ?THROW_ERR(?ERROR_FAIRY_GET_TASK_003), ok),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, Accept), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_002)),
    #r_family_mi{} = FamilyMi = lists:keyfind(MissionID, #r_family_mi.mission_id, Accept),

    Now = time_tool:now(),
    #c_family_asm{time = Time} = get_family_asm_config(MissionID),
    case UnderWay of
        [] ->
            NewFamilyMi = FamilyMi#r_family_mi{type = ?QUICKEN, accept_time = Now, start_time = Now, stop_time = Now + (Time * 60)};
        _ ->
            [#r_family_mi{stop_time = StopTime} | _] = lists:sort(fun(FamilyMi1, FamilyMi2) ->
                FamilyMi1#r_family_mi.accept_time > FamilyMi2#r_family_mi.accept_time end, UnderWay),
            NewFamilyMi = FamilyMi#r_family_mi{type = ?QUICKEN, accept_time = Now, start_time = StopTime, stop_time = StopTime + (Time * 60)}
    end,
    mod_family_asm:send_operate_accept(RoleID, MissionID, NewFamilyMi),
    {ok, to_p_family_mission(NewFamilyMi), State};

check_operate(MissionID, ?SEEK_HELP_MEMBERS, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(RoleID),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_002)),
    #r_family_mi{is_help = IsHelp, stop_time = StopTime, start_time = StartTime} = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    ?IF(StartTime =< time_tool:now(), ok, ?THROW_ERR(?ERROR_COMMON_ACTION_TOO_FAST)),
    ?IF(StopTime > time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_005)),
    ?IF(get_family_quicken(mod_role_vip:get_vip_level(State)) > 0, ok, ?THROW_ERR(?ERROR_ITEM_USE_005)),
    ?IF(IsHelp =:= 0, ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_001)),
    mod_family_asm:send_ask_for_help(RoleID, MissionID),
    common_broadcast:bc_record_to_family(FamilyID, #m_role_family_asm_face_help_toc{member_id = RoleID}),
    {ok, State};

check_operate(MissionID, ?ABANDON, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(RoleID),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_002)),
    #r_family_mi{stop_time = StopTime} = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    ?IF(StopTime > time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_005)),
    mod_family_asm:send_renounce_task(RoleID, MissionID),
    NewFamilyMi = #r_family_mi{mission_id = MissionID, type = ?ACCEPTABLE},
    {ok, to_p_family_mission(NewFamilyMi), State};

check_operate(MissionID, ?RECEIVE_REWARD_ALREADY, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #r_role_family_mi{accept = Accept, under_way = UnderWay, reward = Reward, history = _History} = mod_family_data:get_role_family_asm_info(RoleID),
%%    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, History), ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_004), ok),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay ++ Reward), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_002)),
    #r_family_mi{stop_time = StopTime} = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay ++ Reward),
    ?IF(StopTime =< time_tool:now(), ok, ?THROW_ERR(?ERROR_MISSION_COMPLETE_002)),
    #c_family_asm{reward = Rewards} = get_family_asm_config(MissionID),
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(Rewards)],
    VIP = mod_role_vip:get_vip_level(State),
    [TaskID] = filtrate_task(RoleID, VIP, 1, false, [], [ID || #r_family_mi{mission_id = ID} <- Accept ++ UnderWay ++ Reward]),
    NewAccept = #r_family_mi{mission_id = TaskID, type = ?ACCEPTABLE},
    mod_family_asm:send_receive_rewards(RoleID, MissionID, NewAccept),
    #c_family_asm{star_level = StarLevel} = mod_role_family_asm:get_family_asm_config(TaskID),
    {ok, StarLevel, GoodsList, to_p_family_mission(NewAccept), State}.


%% @doc 一键加速
do_help_member(0, 0, RoleID, State) ->
    #r_role{role_attr = Attr} = State,
    #r_role_attr{family_id = FamilyID} = Attr,

    PFamily = mod_family_data:get_family(FamilyID),

    MissionAsk =
        lists:foldl(fun(#p_family_member{role_id = MembersID}, Acc) ->
            #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(MembersID),
            case MembersID =/= RoleID andalso
                lists:filter(fun(#r_family_mi{is_help = IsHelp, attend = Attend, stop_time = StopTime, start_time = StartTime}) ->
                    IsHelp > 0 andalso (not lists:member(RoleID, Attend)) andalso StopTime > time_tool:now() andalso StartTime =< time_tool:now() end, UnderWay) of
                [_ | _] = Lists ->
                    [{MembersID, Lists} | Acc];
                _ ->
                    Acc
            end end, [], PFamily#p_family.members),

    {ErrCodeLists, State3} =
        lists:foldl(fun({MemberID, Lists}, {AccErrCode, AccState}) ->
            lists:foldl(fun(#r_family_mi{mission_id = MissionID}, {AccErrCode1, AccState1}) ->
                case catch check_help_member(MissionID, MemberID, RoleID, AccState1) of
                    {ok, _Inspire, State2} ->
                        {AccErrCode1, State2};
                    {error, ErrCode} ->
                        {[ErrCode | AccErrCode1], AccState1}
                end end, {AccErrCode, AccState}, Lists) end, {[], State}, MissionAsk),

    common_misc:unicast(RoleID, #m_role_family_asm_help_member_toc{inspire = mod_role_extra:get_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State)}),

    case ErrCodeLists of
        [_ | _] ->
            [ErrCode | _] = ErrCodeLists,
            common_misc:unicast(RoleID, #m_role_family_asm_help_member_toc{err_code = ErrCode});
        _ ->
            ok
    end,
    do_asm_ask_info(RoleID, State3);

%% @doc 帮助道庭成员加速
do_help_member(MissionID, MemberID, RoleID, State) ->
    case catch check_help_member(MissionID, MemberID, RoleID, State) of
        {ok, Inspire, State2} ->
            common_misc:unicast(RoleID, #m_role_family_asm_help_member_toc{member_id = MemberID, mission_id = MissionID, inspire = Inspire});
        {error, ErrCode} ->
            State2 = State,
            common_misc:unicast(RoleID, #m_role_family_asm_help_member_toc{err_code = ErrCode})
    end,
    State2.

check_help_member(MissionID, MemberID, RoleID, State) ->
    ?IF(MemberID =/= RoleID, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_attr = Attr} = State,
    #r_role_attr{family_id = FamilyID} = Attr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #p_family{members = Members} = mod_family_data:get_family(FamilyID),
    ?IF(lists:keymember(MemberID, #p_family_member.role_id, Members), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_004)),
    #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(MemberID),
    ?IF(lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_002)),
    #r_family_mi{stop_time = StopTime, expedite = Expedite, attend = Attend, is_help = IsHelp} = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    ?IF(StopTime > time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_OPERATE_005)),

    FamilyQuicken = get_family_quicken(common_role_data:get_role_vip_level(MemberID)),
    ?IF(FamilyQuicken > Expedite, ok, ?THROW_ERR(?ERROR_COLLECT_START_005)),
    ?IF(IsHelp > 0, ok, ?THROW_ERR(?ERROR_COMMON_ROLE_DATA_ERROR)),
    ?IF(lists:member(RoleID, Attend), ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_HELP_MEMBER_001), ok),
    Inspire = mod_role_extra:get_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State),
    [Dao1, Count | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_REWARD),

    case (Count div Dao1) > Inspire of
        true ->
            State2 = mod_role_extra:set_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, Inspire + 1, State),
            State3 = role_misc:create_goods(State2, ?ITEM_GAIN_FAMILY_ASM_SEEK_HELP, [#p_goods{type_id = 13, num = Dao1}]);
        _ ->
            State3 = State
    end,
    mod_family_asm:send_help_member(RoleID, MissionID, MemberID),
    {ok, mod_role_extra:get_data(?EXTRA_KEY_FAMILY_ASM_INSPIRE, 0, State3), State3}.

%% @doc 道庭任务极品和元宝刷新
do_ref(Type, RoleID, State) ->
    case catch check_ref(Type, RoleID, State) of
        {ok, MissionID, _TaskID, State3} ->
            common_misc:unicast(RoleID, #m_role_family_asm_ref_toc{type = Type, mission_id = MissionID});
        {ok, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_role_family_asm_ref_toc{type = Type}),
            send_task_info(RoleID);
        {error, ErrCode} ->
            State3 = State,
            common_misc:unicast(RoleID, #m_role_family_asm_ref_toc{err_code = ErrCode})
    end,
    State3.

check_ref(?REFURBISH_1, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    #r_role_family_mi{accept = Accept, under_way = UnderWay, reward = Reward} = mod_family_data:get_role_family_asm_info(RoleID),
    ?IF(length(Accept ++ UnderWay ++ Reward) =:= ?CHOOSE_NUM, ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),
    ?IF(length(Accept) > 0, ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_REF_002)),

    NeedGold = common_misc:get_global_int(?GLOBAL_FAMILY_ASM_DINGBAT),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_FAMILY_DO_REF, State),

    VIP = mod_role_vip:get_vip_level(State),
    TaskIDLs = filtrate_task(RoleID, VIP, length(Accept), false, Accept, [ID || #r_family_mi{mission_id = ID} <- Accept ++ UnderWay ++ Reward]),
    ?IF(length(TaskIDLs) =:= length(Accept), ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),
    mod_family_asm:call_first_time_task(RoleID, TaskIDLs),
    {ok, AssetDoings, State};

check_ref(?REFURBISH_2, RoleID, State) ->
    mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),

    #r_role_family_mi{nonsuch_time = NonsuchTime, accept = Accept, under_way = UnderWay, reward = Reward} = mod_family_data:get_role_family_asm_info(RoleID),
    ?IF(length(Accept ++ UnderWay ++ Reward) =:= ?CHOOSE_NUM, ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),
    ?IF(length(Accept) > 0, ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_REF_002)),
    ?IF(?JUDGEMENT_TIME(NonsuchTime), ok, ?THROW_ERR(?ERROR_ROLE_FAMILY_ASM_REF_001)),

    [FixedHour, FixedHour1 | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_RENOVATE),
    {Data, {Hour, _Min, _Sec}} = time_tool:timestamp_to_datetime(time_tool:now()),
    if
        Hour < FixedHour ->
            NewNonsuchTime = time_tool:timestamp({Data, {FixedHour, 0, 0}});
        Hour < FixedHour1 ->
            NewNonsuchTime = time_tool:timestamp({Data, {?BADGE_PLACE, 0, 0}});
        true ->
            NewNonsuchTime = time_tool:timestamp({Data, {FixedHour1, 0, 0}})
    end,

    VIP = mod_role_vip:get_vip_level(State),
    case lists:foldl(fun(#r_family_mi{mission_id = ID}, Acc) ->
        #c_family_asm{star_level = StarLevel} = mod_role_family_asm:get_family_asm_config(ID),
        [{_MaxID, #c_family_asm{star_level = MaxStarLevel}} | _H] =
            lists:sort(fun({_ID1, #c_family_asm{star_level = StarLevel1}}, {_ID2, #c_family_asm{star_level = StarLevel2}}) ->
                StarLevel1 > StarLevel2 end, cfg_family_asm:list()),
        case StarLevel =:= MaxStarLevel of
            true ->
                [ID | Acc];
            _ ->
                Acc
        end end, [], Accept) of
        [] ->
            [#c_family_asm{id = MissionID} | _] =
                lists:sort(fun(#c_family_asm{star_level = StarLevel3}, #c_family_asm{star_level = StarLevel4}) ->
                    StarLevel3 < StarLevel4 end, [mod_role_family_asm:get_family_asm_config(MissionID2) || #r_family_mi{mission_id = MissionID2} <- Accept]),

            Lists = [MissionID1 || #r_family_mi{mission_id = MissionID1} <- lists:keydelete(MissionID, #r_family_mi.mission_id, Accept)],
            [TaskID] = filtrate_task(RoleID, VIP, 1, true, [], [ID || #r_family_mi{mission_id = ID} <- Accept ++ UnderWay ++ Reward]);
        [_ | _] = L when length(L) =:= length(Accept) ->
            MissionID = TaskID = Lists = ?THROW_ERR(?ERROR_COPY_IMMORTAL_AUTO_SUMMON_001);
        [_ | _] = L ->
            AcceptLists = [FamilyMi || #r_family_mi{mission_id = MissionID} = FamilyMi <- Accept, (not lists:member(MissionID, L))],

            [#c_family_asm{id = MissionID} | _] =
                lists:sort(fun(#c_family_asm{star_level = StarLevel3}, #c_family_asm{star_level = StarLevel4}) ->
                    StarLevel3 < StarLevel4 end, [mod_role_family_asm:get_family_asm_config(MissionID2) || #r_family_mi{mission_id = MissionID2} <- AcceptLists]),

%%            #r_family_mi{mission_id = MissionID} = lib_tool:random_element_from_list(AcceptLists),
            Lists = [MissionID1 || #r_family_mi{mission_id = MissionID1} <- lists:keydelete(MissionID, #r_family_mi.mission_id, Accept)],
            [TaskID] = filtrate_task(RoleID, VIP, 1, true, [], [ID || #r_family_mi{mission_id = ID} <- Accept ++ UnderWay ++ Reward])
    end,
    ?IF(length([TaskID | Lists] ++ UnderWay ++ Reward) =:= ?CHOOSE_NUM, ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),

    mod_family_asm:send_nonsuch_renovate(RoleID, [TaskID | Lists], NewNonsuchTime, TaskID),
    {ok, MissionID, TaskID, State}.

%% @doc 更新任务信息
do_update_task(MissionID, State) ->
    #r_role{role_attr = Attr} = State,
    #r_role_attr{family_id = _FamilyID, role_id = RoleID} = Attr,
    #r_role_family_mi{accept = Accept, under_way = UnderWay, reward = Reward} = mod_family_data:get_role_family_asm_info(RoleID),

    #r_family_mi{} = NewFamilyMi = lists:keyfind(MissionID, #r_family_mi.mission_id, Accept ++ UnderWay ++ Reward),
    FamilyMi = to_p_family_mission(NewFamilyMi),
    common_misc:unicast(RoleID, #m_role_family_asm_up_toc{family_mission = FamilyMi}),
    State.

gm_change_task_type(_MissionID, State) ->
    Now = time_tool:now(),
    #r_role{role_attr = Attr} = State,
    #r_role_attr{role_id = RoleID} = Attr,
    #r_role_family_mi{under_way = UnderWay} = mod_family_data:get_role_family_asm_info(RoleID),


    L1 =  lists:filter(fun(#r_family_mi{start_time = StartTime, stop_time = StopTime}) ->
        StartTime =< Now  andalso Now < StopTime end, UnderWay),

    case lists:sort(fun(#r_family_mi{start_time = StartTime1}, #r_family_mi{start_time = StartTime2}) ->
        StartTime1 < StartTime2 end, L1) of
        [#r_family_mi{mission_id = MissionID} | _] = L ->
            ?LXG({MissionID,L}),
            mod_family_asm:gm_help_member(RoleID, MissionID);
        _ ->
            ok
    end,
    State.

gm_nonsuch_time(State) ->
    #r_role{role_attr = Attr} = State,
    #r_role_attr{role_id = RoleID} = Attr,
    #r_role_family_mi{} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(RoleID),

    New = time_tool:now(),
    {D, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(New),
    NewNonsuchTime = time_tool:timestamp({D, {Hour, Min, (60 - Sec) + 2}}),
    mod_family_data:set_role_family_asm_info(RoleFamilyMi#r_role_family_mi{nonsuch_time = NewNonsuchTime}),

    State.


to_p_family_mission_ask(RoleID, FamilyMission) ->
    #r_role_attr{
        role_name = RoleName,
        sex = Sex,
        category = Category} = common_role_data:get_role_attr(RoleID),
    #p_family_mission_ask{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        vip_level = common_role_data:get_role_vip_level(RoleID),
        category = Category,
        family_mission = FamilyMission}.


to_p_family_mission(#r_family_mi{
    mission_id = MissionID,
    type = Type,
    expedite = Expedite,
    start_time = StartTime,
    stop_time = StopTime}) ->
    #p_family_mission{
        mission_id = MissionID,
        type = Type,
        expedite = Expedite,
        start_time = StartTime,
        stop_time = StopTime}.

%% @doc 筛选任务
filtrate_task(RoleID, VIP, Count, IsNonsuch, Accept, Already) when is_list(Already) ->

    [{_MaxID, #c_family_asm{star_level = MaxStarLevel}} | _H] =
        lists:sort(fun({_ID1, #c_family_asm{star_level = StarLevel1}}, {_ID2, #c_family_asm{star_level = StarLevel2}}) ->
            StarLevel1 > StarLevel2 end, cfg_family_asm:list()),

    AcceptAcc =
        lists:foldl(fun(#r_family_mi{mission_id = ID}, Acc) ->
            #c_family_asm{star_level = StarLevel} = mod_role_family_asm:get_family_asm_config(ID),
            case StarLevel =:= MaxStarLevel of
                true ->
                    [ID | Acc];
                _ ->
                    Acc
            end end, [], Accept),

    NewCount = erlang:max(0, Count - length(AcceptAcc)),
    filtrate_task(RoleID, VIP, NewCount, Already, AcceptAcc, IsNonsuch, MaxStarLevel).

filtrate_task(_RoleID, _VIP, 0, _Already, AcceptAcc, _IsNonsuch, _MaxStarLevel) ->
    AcceptAcc;
filtrate_task(RoleID, VIP, Count, Already, AcceptAcc, IsNonsuch, MaxStarLevel) ->
    AcceptID = filtrate_task(VIP, IsNonsuch, Already),
    #c_family_asm{star_level = Star} = get_family_asm_config(AcceptID),
    ?IF(MaxStarLevel =:= Star, common_broadcast:send_world_common_notice(?NOTICE_ESCORT_FAMILY_TASK, [lib_tool:to_list(RoleID),common_role_data:get_role_name(RoleID)]), ok),
    filtrate_task(RoleID, VIP, Count - 1, [AcceptID | Already], [AcceptID | AcceptAcc], IsNonsuch, MaxStarLevel).
%% 普通筛选
filtrate_task(VIP, false, Already) ->
    AllList =
        lists:foldl(fun({ID, #c_family_asm{vip_weight = VIPWeight}}, Acc) ->
            Lists = lib_tool:string_to_intlist(VIPWeight),
            case (not lists:member(ID, Already)) andalso lists:keyfind(VIP, 1, Lists) of
                {_, Weight} when Weight > 0 ->
                    [{Weight, ID} | Acc];
                _ ->
                    Acc
            end end, [], cfg_family_asm:list()),

    lib_tool:get_weight_output(AllList);

%% 极品筛选
filtrate_task(VIP, true, Already) ->
    AllList =
        lists:foldl(fun({ID, _Config = #c_family_asm{nonsuch_weight = NonsuchWeightLists}}, Acc) ->
            Lists = lib_tool:string_to_intlist(NonsuchWeightLists),
            case (not lists:member(ID, Already)) andalso lists:keyfind(VIP, 1, Lists) of
                {_, Weight} when Weight > 0 ->
                    [{Weight, ID} | Acc];
                _ ->
                    Acc
            end end, [], cfg_family_asm:list()),
    lib_tool:get_weight_output(AllList).


get_family_asm_log(MissionID, _StarLevel, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #log_family_asm{
        role_id = RoleID,
        mission_id = MissionID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_family_asm_config(ID) ->
    [Config] = lib_config:find(cfg_family_asm, ID),
    Config.

get_family_quicken(VIPLevel) ->
    [#c_vip_level{family_quicken = FamilyQuicken}] = lib_config:find(cfg_vip_level, VIPLevel),
    FamilyQuicken.