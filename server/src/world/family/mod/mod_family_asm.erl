%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 道庭任务
%%% @end
%%% Created : 14. 六月 2019 16:17
%%%-------------------------------------------------------------------
-module(mod_family_asm).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("db.hrl").
-include("family_asm.hrl").

%% API
-export([
    call_first_time_task/2,
    call_check_task/2,
    send_operate_accept/3,
    send_ask_for_help/2,
    send_renounce_task/2,
    send_receive_rewards/3,
    send_help_member/3,
    send_nonsuch_renovate/4,
    call_role_leave_family/1,
    call_del_role_info/1,
    gm_help_member/2
]).

-export([
    i/1,
    send/1,
    call/1,
    handle/1
]).

i(RoleID) ->
    mod_family_data:get_role_family_asm_info(RoleID).

call_del_role_info(RoleID) ->
    call({del_role_info, RoleID}).
%% @doc 建立可接任务
call_first_time_task(RoleID, TaskIDList) ->
    call({first_time_task, RoleID, TaskIDList}).
%% @doc 检测任务
call_check_task(RoleID, VIP) ->
    call({check_task, RoleID, VIP}).
%% @doc 离开公会
call_role_leave_family(RoleID) ->
    call({role_leave_family, RoleID}).
%% @doc 接任务
send_operate_accept(RoleID, MissionID, FamilyMi) ->
    send({operate_accept, RoleID, MissionID, FamilyMi}).
%% @doc 请求道庭帮助
send_ask_for_help(RoleID, MissionID) ->
    send({ask_for_help, RoleID, MissionID}).
%% @doc 放弃任务
send_renounce_task(RoleID, MissionID) ->
    send({renounce_task, RoleID, MissionID}).
%% @doc 领取奖励
send_receive_rewards(RoleID, MissionID, NewAccept) ->
    send({receive_rewards, RoleID, MissionID, NewAccept}).
%% @doc 帮助加速
send_help_member(RoleID, MissionID, MemberID) ->
    send({help_member, RoleID, MissionID, MemberID}).
%% @doc 极品刷新
send_nonsuch_renovate(RoleID, TaskIDList, NonsuchTime, TaskID) ->
    send({nonsuch_renovate, RoleID, TaskIDList, NonsuchTime, TaskID}).

handle({del_role_info, RoleID}) ->
    do_del_role_info(RoleID);
handle({role_leave_family, RoleID}) ->
    do_role_leave_family(RoleID);
handle({nonsuch_renovate, RoleID, TaskIDList, NonsuchTime, TaskID}) ->
    do_nonsuch_renovate(RoleID, TaskIDList, NonsuchTime, TaskID);
handle({help_member, RoleID, MissionID, MemberID}) ->
    do_help_member(RoleID, MissionID, MemberID);
handle({receive_rewards, RoleID, MissionID, NewAccept}) ->
    do_task_receive_rewards(RoleID, MissionID, NewAccept);
handle({renounce_task, RoleID, MissionID}) ->
    do_renounce_task(RoleID, MissionID);
handle({ask_for_help, RoleID, MissionID}) ->
    do_ask_for_help(RoleID, MissionID);
handle({operate_accept, RoleID, MissionID, FamilyMi}) ->
    do_operate_accept(RoleID, MissionID, FamilyMi);
handle({check_task, RoleID, VIP}) ->
    do_check_task(RoleID, VIP);
handle({first_time_task, RoleID, TaskIDList}) ->
    do_first_time_task(RoleID, TaskIDList).

send(Msg) ->
    family_misc:info_family({mod, ?MODULE, Msg}).
call(Msg) ->
    family_misc:call_family({mod, ?MODULE, Msg}).

%% @doc 建立可接任务
do_first_time_task(RoleID, TaskIDList) ->
    #r_role_family_mi{nonsuch_time = NonsuchTime} = FamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    Accept = [#r_family_mi{mission_id = TaskID, type = ?ACCEPTABLE} || TaskID <- TaskIDList],

    NewNonsuchTime = ?IF(?IF_THE_REFRESH(NonsuchTime), NonsuchTime,
        begin
            New = time_tool:now(),
            {D, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(New),
            time_tool:timestamp({D, {Hour, Min, (60 - Sec) + 2}})
        end),

    mod_family_data:set_role_family_asm_info(FamilyMi#r_role_family_mi{accept = Accept, nonsuch_time = NewNonsuchTime}),
    {NewNonsuchTime, Accept}.

%% @doc 检测任务
do_check_task(RoleID, VIP) ->
    #r_role_family_mi{
        nonsuch_time = NonsuchTime,
        accept = Accept,
        under_way = UnderWay,
        reward = Reward,
        history = History} = FamilyMi = mod_family_data:get_role_family_asm_info(RoleID),

    Now = time_tool:now(),
    if
        Accept =:= UnderWay andalso Reward =:= Accept andalso UnderWay =:= [] ->
%%            Already = ?IF(time_tool:is_same_date(NonsuchTime, Now), [ID || #r_family_mi{mission_id = ID} <- History], []),
            TaskIDList = mod_role_family_asm:filtrate_task(RoleID, VIP, ?CHOOSE_NUM, false, [], []),
            NewAccept = [#r_family_mi{mission_id = TaskID, type = ?ACCEPTABLE} || TaskID <- TaskIDList],

            {Data, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(Now),
            NonsuchTimeNow = time_tool:timestamp({Data, {Hour, Min, (60 - Sec) + 2}}),
            NewNonsuchTime = ?IF(time_tool:is_same_date(NonsuchTime, Now), NonsuchTime, NonsuchTimeNow),

            NewHistory = ?IF(time_tool:is_same_date(NonsuchTime, Now), History, []),
            NewFamilyMi = FamilyMi#r_role_family_mi{accept = NewAccept, nonsuch_time = NewNonsuchTime, history = NewHistory};
        true ->
            case time_tool:is_same_date(NonsuchTime, Now) of
                false -> % 夸天
                    {NowUnderWay, NewReward} =
                        lists:foldl(fun(#r_family_mi{stop_time = StopTime} = FamilyMi1, {AccUnderWay, AccReward}) ->
                            case StopTime =< Now of
                                true ->
                                    {AccUnderWay, [FamilyMi1#r_family_mi{type = ?RECEIVE_REWARD} | AccReward]};
                                _ ->
                                    {[FamilyMi1 | AccUnderWay], AccReward}
                            end end, {[], Reward}, UnderWay),

                    {Data2, {Hour2, Min2, Sec2}} = time_tool:timestamp_to_datetime(Now),
                    case ?JUDGEMENT_TIME(NonsuchTime) of
                        true -> % 缓降时间，保持用时间点为判断的正确
                            NewNonsuchTime = time_tool:timestamp({Data2, {Hour2, Min2, (60 - Sec2) + 2}});
                        _ ->
                            {_, {Hour3, MinOld, SecOld}} = time_tool:timestamp_to_datetime(NonsuchTime),
                            [FixedHour, FixedHour1 | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_RENOVATE),
                            if
                                Hour3 =:= FixedHour andalso FixedHour < FixedHour1 -> % 前一天的18点的刷新次数没用
                                    NewNonsuchTime = time_tool:timestamp({Data2, {Hour2, Min2, (60 - Sec2) + 2}});
                                Hour3 =:= FixedHour1 andalso FixedHour > FixedHour1 ->
                                    NewNonsuchTime = time_tool:timestamp({Data2, {Hour2, Min2, (60 - Sec2) + 2}});
                                Hour3 =:= ?BADGE_PLACE andalso MinOld =:= 0 andalso SecOld =:= MinOld ->
                                    NewNonsuchTime = time_tool:timestamp({Data2, {Hour2, Min2, (60 - Sec2) + 2}});
                                FixedHour < FixedHour1 -> % 前一天的18点用掉了，用当前12点作为标记
                                    NewNonsuchTime = time_tool:timestamp({Data2, {FixedHour, 0, 0}});
                                true ->
                                    NewNonsuchTime = time_tool:timestamp({Data2, {FixedHour1, 0, 0}})
                            end
                    end,

                    NewFamilyMi = FamilyMi#r_role_family_mi{nonsuch_time = NewNonsuchTime, under_way = NowUnderWay, reward = NewReward, history = []};
                _ ->
                    {NowUnderWay, NewReward} =
                        lists:foldl(fun(#r_family_mi{stop_time = StopTime} = FamilyMi1, {AccUnderWay, AccReward}) ->
                            case StopTime =< Now of
                                true ->
                                    {AccUnderWay, [FamilyMi1#r_family_mi{type = ?RECEIVE_REWARD} | AccReward]};
                                _ ->
                                    {[FamilyMi1 | AccUnderWay], AccReward}
                            end end, {[], Reward}, UnderWay),

                    {Data, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(Now),
                    {Data, {Hour1, _Min, _Sec}} = time_tool:timestamp_to_datetime(NonsuchTime),
                    [FixedHour, FixedHour1 | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_RENOVATE),

                    NewNonsuchTime = ?IF(
                        (Hour1 =< FixedHour andalso FixedHour =< Hour)
                            orelse (Hour1 < FixedHour1 andalso FixedHour1 =< Hour),
                        time_tool:timestamp({Data, {Hour, Min, (60 - Sec) + 2}}), NonsuchTime),

                    UnderWayNow = ?IF(lists:any(fun(#r_family_mi{start_time = StartTime}) ->
                        StartTime =< Now end, NowUnderWay), NowUnderWay, update_check(NowUnderWay, Now)),
                    NewFamilyMi = FamilyMi#r_role_family_mi{nonsuch_time = NewNonsuchTime, under_way = UnderWayNow, reward = NewReward}
            end
    end,

    ToolList = Accept ++ NewFamilyMi#r_role_family_mi.under_way ++ NewFamilyMi#r_role_family_mi.reward,
    case length(ToolList) =:= ?CHOOSE_NUM of
        true ->
            ToolListNow = ToolList,
            mod_family_data:set_role_family_asm_info(NewFamilyMi);
        _ ->
            TaskIDList1 = mod_role_family_asm:filtrate_task(RoleID, VIP, ?CHOOSE_NUM - length(ToolList), false, [], ToolList),
            Accept1 = [#r_family_mi{mission_id = TaskID, type = ?ACCEPTABLE} || TaskID <- TaskIDList1],
            mod_family_data:set_role_family_asm_info(NewFamilyMi#r_role_family_mi{accept = Accept1 ++ Accept}),
            ToolListNow = Accept1 ++ ToolList
    end,
    {NewFamilyMi#r_role_family_mi.nonsuch_time, ToolListNow}.

%% @doc 接任务
do_operate_accept(RoleID, MissionID, FamilyMi) ->
    #r_role_family_mi{accept = Accept, under_way = UnderWay} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    NewRoleFamilyMi = RoleFamilyMi#r_role_family_mi{
        accept = lists:keydelete(MissionID, #r_family_mi.mission_id, Accept),
        under_way = lists:keystore(MissionID, #r_family_mi.mission_id, UnderWay, FamilyMi)},
    mod_family_data:set_role_family_asm_info(NewRoleFamilyMi).

%% @doc 请求帮助
do_ask_for_help(RoleID, MissionID) ->
    #r_role_family_mi{under_way = UnderWay} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    #r_family_mi{is_help = IsHelp} = FamilyMi = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    mod_family_data:set_role_family_asm_info(
        RoleFamilyMi#r_role_family_mi{
            under_way = lists:keystore(MissionID, #r_family_mi.mission_id, UnderWay, FamilyMi#r_family_mi{type = ?ALREADY_QUICKEN,is_help = IsHelp + 1})}),
    role_misc:info_role(RoleID, {mod, mod_role_family_asm, {update_task, RoleID, MissionID}}).

%% @doc 放弃任务
do_renounce_task(RoleID, MissionID) ->
    Now = time_tool:now(),
    #r_role_family_mi{under_way = UnderWay, accept = Accept} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(RoleID),

    case lists:keydelete(MissionID, #r_family_mi.mission_id, UnderWay) of
        [#r_family_mi{start_time = StartTime, mission_id = MissionID} = FamilyMi] when StartTime > Now ->
            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionID),
            NewUnderWay = [FamilyMi#r_family_mi{start_time = Now, stop_time = Now + (Time * 60)}];
        [_ | _] = L ->
            [#r_family_mi{start_time = StartTime, stop_time = StopTime} = MinFamilyMi | H] =
                lists:sort(fun(FamilyMi1, FamilyMi2) ->
                    FamilyMi1#r_family_mi.accept_time < FamilyMi2#r_family_mi.accept_time end, L),
            {_, NewUnderWay} =
                case StartTime =< Now of
                    true ->
                        {Time1, RetLists} =
                            lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                                #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                                {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {StopTime, []}, H),
                        {Time1, [MinFamilyMi | RetLists]};
                    _ ->
                        lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                            {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {Now, []}, [MinFamilyMi | H])
                end;
        _ ->
            NewUnderWay = []
    end,

    #r_family_mi{attend = _Attend} = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    mod_family_data:set_role_family_asm_info(
        RoleFamilyMi#r_role_family_mi{
            accept = [#r_family_mi{mission_id = MissionID, type = ?ACCEPTABLE} | Accept],
            under_way = NewUnderWay}),
    mod_role_family_asm:send_task_info(RoleID).

%% @doc 领取奖励
do_task_receive_rewards(RoleID, MissionID, NewAccept) ->
    #r_role_family_mi{under_way = UnderWay, reward = Reward, accept = Accept, history = History} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    case lists:keymember(MissionID, #r_family_mi.mission_id, UnderWay) of
        true ->
            {value, FamilyMi, NewUnderWay} = lists:keytake(MissionID, #r_family_mi.mission_id, UnderWay),
            RoleFamilyMi1 = RoleFamilyMi#r_role_family_mi{
                    accept = [NewAccept | Accept],
                    history = [FamilyMi#r_family_mi{type = ?RECEIVE_REWARD1} | History],
                    under_way = NewUnderWay};
        _ ->
            {value, FamilyMi, NewReward} = lists:keytake(MissionID, #r_family_mi.mission_id, Reward),

            RoleFamilyMi1 = RoleFamilyMi#r_role_family_mi{
                    accept = [NewAccept | Accept],
                    history = [FamilyMi#r_family_mi{type = ?RECEIVE_REWARD1} | History],
                    reward = NewReward}
    end,

    Now = time_tool:now(),
    case RoleFamilyMi1#r_role_family_mi.under_way of
        [#r_family_mi{start_time = StartTime, mission_id = MissionID} = FamilyMi1] when StartTime > Now ->
            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionID),
            NewUnderWay1 = [FamilyMi1#r_family_mi{start_time = Now, stop_time = Now + (Time * 60)}];
        [_ | _] = L ->
            [#r_family_mi{start_time = StartTime, stop_time = StopTime} = MinFamilyMi | H] =
                lists:sort(fun(FamilyMi1, FamilyMi2) ->
                    FamilyMi1#r_family_mi.accept_time < FamilyMi2#r_family_mi.accept_time end, L),
            {_, NewUnderWay1} =
                case StartTime =< Now of
                    true ->
                        {Time1, RetLists} =
                            lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                                #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                                {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {StopTime, []}, H),
                        {Time1, [MinFamilyMi | RetLists]};
                    _ ->
                        lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                            {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {Now, []}, [MinFamilyMi | H])
                end;
        _ ->
            NewUnderWay1 = []
    end,
    mod_family_data:set_role_family_asm_info(RoleFamilyMi1#r_role_family_mi{under_way = NewUnderWay1}),
    mod_role_family_asm:send_task_info(RoleID).

%%
gm_help_member(RoleID, MissionID) ->
    do_help_member(RoleID, MissionID, RoleID, true).

%% @doc 帮助道庭成员
do_help_member(RoleID, MissionID, MemberID) ->
    do_help_member(RoleID, MissionID, MemberID, false).
do_help_member(RoleID, MissionID, MemberID, GmBool) ->
    Now = time_tool:now(),
    #r_role_family_mi{under_way = UnderWay, reward = Reward} = RoleFamilyMi = mod_family_data:get_role_family_asm_info(MemberID),
    [Percentage, MinNum | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_TIME),
    #r_family_mi{stop_time = StopTime, attend = Attend, expedite = Expedite} = FamilyMi = lists:keyfind(MissionID, #r_family_mi.mission_id, UnderWay),
    RetTime = StopTime - Now,
    Remainder = ?IF(GmBool =:= true, RetTime - 10, lib_tool:ceil((Percentage / 100) * RetTime)),
    NewStopTime = StopTime - ?IF(Remainder > MinNum orelse GmBool =:= true, Remainder, erlang:min(MinNum, RetTime)),
    case NewStopTime =< Now of
        true ->
            NewFamilyMi = FamilyMi#r_family_mi{type = ?RECEIVE_REWARD, stop_time = NewStopTime, expedite = Expedite +1, attend = [RoleID | Attend]},
            mod_family_data:set_role_family_asm_info(
                RoleFamilyMi#r_role_family_mi{
                    under_way = lists:keydelete(MissionID, #r_family_mi.mission_id, UnderWay),
                    reward = [NewFamilyMi | Reward]});
        _ ->
            NewFamilyMi = FamilyMi#r_family_mi{stop_time = NewStopTime, expedite = Expedite +1, attend = [RoleID | Attend]},
            mod_family_data:set_role_family_asm_info(
                RoleFamilyMi#r_role_family_mi{
                    under_way = lists:keystore(MissionID, #r_family_mi.mission_id, UnderWay, NewFamilyMi)})
    end,
    role_misc:info_role(MemberID, {mod, mod_role_family_asm, {update_task, RoleID, MissionID}}).


%% @doc 极品刷新
do_nonsuch_renovate(RoleID, TaskIDList, NonsuchTime, MissionID) ->
    #r_role_family_mi{} = FamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    Accept = [#r_family_mi{mission_id = TaskID, type = ?ACCEPTABLE} || TaskID <- TaskIDList],
    mod_family_data:set_role_family_asm_info(FamilyMi#r_role_family_mi{accept = Accept, nonsuch_time = NonsuchTime}),
    role_misc:info_role(RoleID, {mod, mod_role_family_asm, {update_task, RoleID, MissionID}}).

%% @doc 离开公会
do_role_leave_family(RoleID) ->
    #r_role_family_mi{nonsuch_time = NonsuchTime, history = History} = FamilyMi = mod_family_data:get_role_family_asm_info(RoleID),
    mod_family_data:set_role_family_asm_info(FamilyMi#r_role_family_mi{history = History, accept = [], under_way = [], reward = [], nonsuch_time = NonsuchTime}).

do_del_role_info(RoleID) ->
    mod_family_data:del_role_family_asm_info(RoleID).

update_check(Under_way, Now) ->
    case Under_way of
        [#r_family_mi{start_time = StartTime, mission_id = MissionID} = FamilyMi1] when StartTime > Now ->
            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionID),
            NewUnderWay1 = [FamilyMi1#r_family_mi{start_time = Now, stop_time = Now + (Time * 60)}];
        [_ | _] = L ->
            [#r_family_mi{start_time = StartTime, stop_time = StopTime} = MinFamilyMi | H] =
                lists:sort(fun(FamilyMi1, FamilyMi2) ->
                    FamilyMi1#r_family_mi.accept_time < FamilyMi2#r_family_mi.accept_time end, L),
            {_, NewUnderWay1} =
                case StartTime =< Now of
                    true ->
                        {Time1, RetLists} =
                            lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                                #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                                {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {StopTime, []}, H),
                        {Time1, [MinFamilyMi | RetLists]};
                    _ ->
                        lists:foldl(fun(#r_family_mi{mission_id = MissionIDNow, stop_time = StopTimeNow} = FamilyMiNow, {AccStopTime, Acc}) ->
                            #c_family_asm{time = Time} = mod_role_family_asm:get_family_asm_config(MissionIDNow),
                            {StopTimeNow, [FamilyMiNow#r_family_mi{start_time = AccStopTime, stop_time = AccStopTime + (Time * 60)} | Acc]} end, {Now, []}, [MinFamilyMi | H])
                end;
        _ ->
            NewUnderWay1 = []
    end,
    NewUnderWay1.