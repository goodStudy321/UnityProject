%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     仙侣 - 婚礼相关
%%% @end
%%% Created : 12. 十二月 2018 11:24
%%%-------------------------------------------------------------------
-module(mod_marry_feast).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").
-include("proto/mod_marry_feast.hrl").
-include("proto/mod_role_marry.hrl").

%% API
-export([
    init/0,
    zero/0,
    loop/1,
    handle/1
]).

-export([
    add_guest_num/2,
    check_enter_feast/1,
    buy_join/1,
    get_feast_start_time/0
]).

-export([
    role_online/1
]).

init() ->
    #r_marry_feast{date = OldDate, hour_list = HourList} = world_data:get_marry_feast(),
    Date = time_tool:date(),
    {Hour, _Min, _Sec} = erlang:time(),
    HourList2 = modify_hour_list(HourList, Date =:= OldDate, Hour, []),
    MarryFeast2 = #r_marry_feast{date = Date,hour_list = HourList2},
    world_data:set_marry_feast(MarryFeast2),
    reload_feast(MarryFeast2).

zero() ->
    MarryFeast = #r_marry_feast{date = time_tool:date(), hour_list = []},
    world_data:set_marry_feast(MarryFeast),
    reload_feast(MarryFeast).

loop(Now) ->
    #r_feast_state{
        status = Status,
        share_id = ShareID,
        prepare_time = PrepareTime,
        start_time = StartTime,
        end_time = EndTime
        } = FeastState = mod_marry_data:get_feast_state(),
    if
        ShareID =:= undefined orelse StartTime =:= 0 ->
            ok;
        Status =:= ?FEAST_END andalso Now >= PrepareTime ->
            ?ERROR_MSG("feast prepare:~w", [ShareID]),
            FeastState2 = FeastState#r_feast_state{status = ?FEAST_PREPARE},
            mod_marry_data:set_feast_state(FeastState2),
            DataRecord = get_feast_data_record(FeastState2),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = ?FEAST_MIN_LEVEL});
        Status =:= ?FEAST_PREPARE andalso Now >= StartTime ->
            ?ERROR_MSG("feast start:~w", [ShareID]),
            {RoleID1, RoleID2} = ShareID,
            map_sup:start_map(?MAP_MARRY_FEAST, 1, common_config:get_server_id(), {RoleID1, RoleID2, StartTime}),
            FeastState2 = FeastState#r_feast_state{status = ?FEAST_START},
            mod_marry_data:set_feast_state(FeastState2),
            DataRecord = get_feast_data_record(FeastState2),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = ?FEAST_MIN_LEVEL}),
            common_broadcast:send_world_common_notice(?NOTICE_MARRY_FEAST_START, [common_role_data:get_role_name(RoleID1), common_role_data:get_role_name(RoleID2)]),
            ?TRY_CATCH(marry_misc:log_marry_status(mod_marry_data:get_share_marry(ShareID), ?LOG_MARRY_START, 0));
        Status =:= ?FEAST_START andalso Now >= EndTime ->
            ?ERROR_MSG("feast end:~w", [ShareID]),
            FeastState2 = FeastState#r_feast_state{
                status = ?FEAST_END,
                share_id = undefined,
                prepare_time = 0,
                start_time = 0,
                end_time = 0},
            mod_marry_data:set_feast_state(FeastState2),
            ShareMarry = mod_marry_data:get_share_marry(ShareID),
            mod_marry_data:set_share_marry(ShareMarry#r_marry_share{extra_guest_num = 0, guest_list = [], apply_guest_list = []}),
            DataRecord = get_feast_data_record(FeastState2),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = ?FEAST_MIN_LEVEL}),
            reload_feast(world_data:get_marry_feast()),
            ?TRY_CATCH(marry_misc:log_marry_status(mod_marry_data:get_share_marry(ShareID), ?LOG_MARRY_END, 0));
        true ->
            ok
    end.

modify_hour_list([], _IsSameDate, _Hour, Acc) ->
    Acc;
modify_hour_list([FeastHour|R], IsSameDate, Hour, Acc) ->
    #r_feast_hour{hour = NeedHour, share_id = ShareID} = FeastHour,
    case IsSameDate andalso NeedHour > Hour of
        true ->
            modify_hour_list(R, IsSameDate, Hour, [FeastHour|Acc]);
        _ ->
            ShareMarry = mod_marry_data:get_share_marry(ShareID),
            mod_marry_data:set_share_marry(ShareMarry#r_marry_share{feast_start_time = 0}),
            modify_hour_list(R, IsSameDate, Hour, Acc)
    end.

reload_feast(MarryFeast) ->
    #r_feast_state{status = Status, share_id = ShareID, start_time = OldStartTime} = FeastState = mod_marry_data:get_feast_state(),
    case Status =:= ?FEAST_END of
        true -> %% 结束状态，这个时候可以reload
            {NowHour, _Min, _Sec} = erlang:time(),
            #r_marry_feast{hour_list = HourList} = MarryFeast,
            HourList2 = lists:keysort(#r_feast_hour.hour, [ FeastHour|| #r_feast_hour{hour = Hour} = FeastHour <- HourList, Hour > NowHour]),
            case HourList2 of
                [#r_feast_hour{hour = StartHour, share_id = StartShareID}|_] ->
                    case ShareID =:= StartShareID of
                        true ->
                            ok;
                        _ ->
                            Now = time_tool:now(),
                            StartTime = time_tool:timestamp({StartHour, 0, 0}),
                            case OldStartTime =:= 0 orelse Now > OldStartTime orelse StartTime < OldStartTime of
                                true -> %% 已经结束或者最新的时间比之前的近 可以替换
                                    FeastState2 = FeastState#r_feast_state{
                                        share_id = StartShareID,
                                        prepare_time = StartTime - ?FEAST_PREPARE_TIME,
                                        start_time = StartTime,
                                        end_time = StartTime + ?FEAST_TIME
                                    },
                                    mod_marry_data:set_feast_state(FeastState2);
                                _ ->
                                    ok
                            end
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

add_guest_num(RoleID, AddNum) ->
    marry_server:call_mod(?MODULE, {add_guest_num, RoleID, AddNum}).

check_enter_feast(RoleID) ->
    marry_server:call_mod(?MODULE, {check_enter_feast, RoleID}).

buy_join(RoleID) ->
    marry_server:call_mod(?MODULE, {buy_join, RoleID}).

get_feast_start_time() ->
    marry_server:call_mod(?MODULE, get_feast_start_time).

role_online(RoleID) ->
    common_misc:unicast(RoleID, get_feast_data_record(mod_marry_data:get_feast_state())).

handle({#m_marry_appoint_info_tos{}, RoleID, _PID}) ->
    do_appoint_info(RoleID);
handle({#m_marry_appoint_tos{hour = Hour}, RoleID, _PID}) ->
    do_appoint(RoleID, Hour);
handle({#m_marry_invite_guest_tos{role_id = InviteRoleID}, RoleID, _PID}) ->
    do_invite_guest(RoleID, InviteRoleID);
handle({add_guest_num, RoleID, AddNum}) ->
    do_add_guest_num(RoleID, AddNum);
handle({#m_marry_apply_guest_tos{}, RoleID, _PID}) ->
    do_apply_guest(RoleID);
handle({#m_marry_reply_guest_tos{op_type = OpType, role_ids = RoleIDs}, RoleID, _PID}) ->
    do_reply_guest(RoleID, OpType, RoleIDs);
handle({#m_marry_set_buy_tos{is_buy_join = IsBuyJoin}, RoleID, _PID}) ->
    do_set_buy(RoleID, IsBuyJoin);
handle({buy_join, RoleID}) ->
    do_buy_join(RoleID);
handle(get_feast_start_time) ->
    do_get_feast_start_time();
handle(reload_feast) ->
    reload_feast(world_data:get_marry_feast());
handle({check_enter_feast, RoleID}) ->
    do_check_enter_feast(RoleID);
handle({gm_start_feast, RoleID, Remain}) ->
    do_gm_start_feast(RoleID, Remain);
handle({gm_stop_feast, RoleID}) ->
    do_gm_stop_feast(RoleID);
handle({gm_clear_appoint, RoleID}) ->
    do_gm_clear_appoint(RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info: ~w", [Info]).

do_check_enter_feast(RoleID) ->
    #r_feast_state{
        status = Status,
        share_id = ShareID
        } = mod_marry_data:get_feast_state(),
    case Status =:= ?FEAST_START of
        true ->
            {RoleID1, RoleID2} = ShareID,
            #r_marry_share{guest_list = GuestList} = mod_marry_data:get_share_marry(ShareID),
            lists:member(RoleID, [RoleID1, RoleID2|GuestList]);
        _ ->
            false
    end.

%% GM设置开启 当前有正在举行的婚礼的话，是不会
do_gm_start_feast(RoleID, Remain) ->
    #r_feast_state{status = Status} = mod_marry_data:get_feast_state(),
    case Status =:= ?FEAST_END of
        true ->
            #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
            case ?HAS_COUPLE(CoupleID) of
                true ->
                    do_gm_clear_appoint(RoleID),
                    AddTime =
                        case Remain of
                            [AddTimeT] ->
                                erlang:min(AddTimeT, ?FEAST_PREPARE_TIME);
                            _ ->
                                ?ONE_MINUTE
                        end,
                    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
                    Now = time_tool:now(),
                    FeastStartTime = time_tool:now() + AddTime,
                    #r_marry_share{
                        extra_guest_num = ExtraGuestNum,
                        guest_list = GuestList,
                        apply_guest_list = ApplyGuestList
                    } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
                    FeastState2 = #r_feast_state{
                        status = ?FEAST_END,
                        share_id = ShareID,
                        prepare_time = Now,
                        start_time = FeastStartTime,
                        end_time = FeastStartTime + ?FEAST_TIME
                    },
                    DataRecord = #m_marry_feast_info_toc{
                        feast_start_time = FeastStartTime,
                        feast_times = ShareMarry#r_marry_share.feast_times,
                        extra_guest_num = ExtraGuestNum,
                        guest_list = marry_misc:trans_to_p_guest(GuestList),
                        apply_guest_list = ApplyGuestList
                    },
                    ShareMarry2 = ShareMarry#r_marry_share{
                        feast_start_time = FeastStartTime,
                        apply_guest_list = [],
                        guest_list = []},
                    mod_marry_data:set_share_marry(ShareMarry2),
                    mod_marry_data:set_feast_state(FeastState2),
                    common_misc:unicast(RoleID, DataRecord),
                    common_misc:unicast(CoupleID, DataRecord);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

do_gm_stop_feast(_RoleID) ->
    #r_feast_state{status = Status} = mod_marry_data:get_feast_state(),
    case Status =/= ?FEAST_END of
        true ->
            FeastState = #r_feast_state{},
            mod_marry_data:set_feast_state(FeastState),
            DataRecord = get_feast_data_record(FeastState),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = ?FEAST_MIN_LEVEL}),
            map_misc:info(map_misc:get_map_pname(?MAP_MARRY_FEAST, 1), {func, fun() -> map_server:kick_all_roles(), map_server:delay_shutdown() end}),
            ok;
        _ ->
            ok
    end.

do_gm_clear_appoint(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    case ?HAS_COUPLE(CoupleID) of
        true ->
            ShareID = marry_misc:get_share_id(RoleID, CoupleID),
            #r_marry_share{
                feast_start_time = FeastStartTime,
                feast_times = FeastTimes
            } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
            case marry_misc:is_feast_over(FeastStartTime) of
                true ->
                    ok;
                _ ->
                    {_, {Hour, _Min, _Sec}} = time_tool:timestamp_to_datetime(FeastStartTime),
                    Hour2 = ?IF(Hour =:= 0, 24, Hour),
                    #r_marry_feast{hour_list = HourList} = MarryFeast = world_data:get_marry_feast(),
                    HourList2 = lists:keydelete(Hour2, #r_feast_hour.hour, HourList),
                    MarryFeast2 = MarryFeast#r_marry_feast{hour_list = HourList2},
                    world_data:set_marry_feast(MarryFeast2),
                    mod_marry_data:set_share_marry(ShareMarry#r_marry_share{feast_start_time = 0, feast_times = FeastTimes + 1}),
                    reload_feast(MarryFeast2),
                    DataRecord = #m_marry_appoint_toc{
                        feast_start_time = 0,
                        feast_times = FeastTimes + 1
                    },
                    common_misc:unicast(RoleID, DataRecord),
                    common_misc:unicast(CoupleID, DataRecord)
            end;
        _ ->
            ok
    end.


%% 查看当天预约信息
do_appoint_info(RoleID) ->
    case catch check_appoint_info(RoleID) of
        {ok, HourList} ->
            common_misc:unicast(RoleID, #m_marry_appoint_info_toc{hour_list = HourList}),
            ok;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_appoint_info_toc{err_code = ErrCode})
    end.

check_appoint_info(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_INFO_001)),
    #r_marry_feast{hour_list = HourList} = world_data:get_marry_feast(),
    {NowHour, _Min, _Sec} = erlang:time(),
    HourList2 = [ Hour || #r_feast_hour{hour = Hour} <- HourList, Hour > NowHour],
    {ok, HourList2}.

%% 预约婚礼
do_appoint(RoleID, Hour) ->
    case catch check_appoint(RoleID, Hour) of
        {ok, ShareMarry, MarryFeast, CoupleID, FeastStartTime2, FeastTimes2, GoodsList} ->
            DataRecord = #m_marry_appoint_toc{
                feast_start_time = FeastStartTime2,
                feast_times = FeastTimes2
            },
            mod_marry_data:set_share_marry(ShareMarry),
            world_data:set_marry_feast(MarryFeast),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_MARRY_ORDER,
                goods_list = GoodsList,
                action = ?ITEM_GAIN_MARRY_APPOINT,
                text_string = [time_tool:timestamp_to_datetime_str(FeastStartTime2)]
            },
            do_appoint2(RoleID, DataRecord, LetterInfo),
            do_appoint2(CoupleID, DataRecord, LetterInfo),
            reload_feast(MarryFeast),
            marry_misc:log_marry_status(ShareMarry, ?LOG_MARRY_APPOINT_SUCC, 0);
        {error, ?ERROR_MARRY_APPOINT_005} ->
            common_misc:unicast(RoleID, #m_marry_appoint_toc{err_code = ?ERROR_MARRY_APPOINT_005}),
            do_appoint_info(RoleID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_appoint_toc{err_code = ErrCode})
    end.

do_appoint2(RoleID, DataRecord, LetterInfo) ->
    common_misc:unicast(RoleID, DataRecord),
    common_letter:send_letter(RoleID, LetterInfo).

check_appoint(RoleID, Hour) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_001)),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{
        feast_times = FeastTimes,
        feast_start_time = FeastStartTime
    } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF(FeastTimes > 0, ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_002)),
    ?IF(marry_misc:is_feast_over(FeastStartTime), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_003)),
    {NowHour, NowMin, _Sec} = erlang:time(),
    ?IF(1 =< Hour andalso Hour =< 24, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ?IF((Hour - 1 > NowHour) orelse (Hour - 1 =:= NowHour andalso NowMin < ?FEAST_APPOINT_MIN), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_004)),
    #r_marry_feast{hour_list = HourList} = MarryFeast = world_data:get_marry_feast(),
    ?IF(lists:keymember(Hour, #r_feast_hour.hour, HourList), ?THROW_ERR(?ERROR_MARRY_APPOINT_005), ok),
    HourList2 = [#r_feast_hour{hour = Hour, share_id = ShareID}|HourList],
    MarryFeast2 = MarryFeast#r_marry_feast{hour_list = HourList2},
    FeastTimes2 = FeastTimes - 1,
    FeastStartTime2 = time_tool:timestamp({Hour, 0, 0}),
    GuestList = [],
    ExtraGuestNum = 0,
    IsBuyJoin = true,
    ShareMarry2 = ShareMarry#r_marry_share{
        feast_times = FeastTimes2,
        feast_start_time = FeastStartTime2,
        guest_list = GuestList,
        apply_guest_list = [],
        extra_guest_num = ExtraGuestNum,
        is_buy_join = IsBuyJoin},
    GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_MARRY_FEAST_APPOINT)],
    {ok, ShareMarry2, MarryFeast2, CoupleID, FeastStartTime2, FeastTimes2, GoodsList}.

%% 邀请宾客
do_invite_guest(RoleID, InviteRoleID) ->
    case catch check_invite_guest(RoleID, InviteRoleID) of
        {ok, CoupleID, ShareMarry, FeastStartTime, GoodsList} ->
            mod_marry_data:set_share_marry(ShareMarry),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_MARRY_SUCC,
                goods_list = GoodsList,
                action = ?ITEM_GAIN_MARRY_GUEST,
                text_string = [
                    common_role_data:get_role_name(RoleID),
                    common_role_data:get_role_name(CoupleID),
                    time_tool:timestamp_to_datetime_str(FeastStartTime)]
            },
            common_letter:send_letter(InviteRoleID, LetterInfo),
            DataRecord = #m_marry_invite_guest_toc{guest = marry_misc:trans_to_p_guest(InviteRoleID)},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(CoupleID, DataRecord),
            ok;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_invite_guest_toc{err_code = ErrCode})
    end.

check_invite_guest(RoleID, InviteRoleID) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_001)),
    ?IF(common_role_data:get_role_level(InviteRoleID) >= ?FEAST_MIN_LEVEL, ok, ?THROW_ERR(?ERROR_MARRY_INVITE_GUEST_004)),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{
        feast_start_time = FeastStartTime,
        guest_list = GuestList,
        extra_guest_num = ExtraGuestNum,
        apply_guest_list = ApplyGuestList
    } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF(lists:member(InviteRoleID, [RoleID, CoupleID]), ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    ?IF(marry_misc:is_feast_over(FeastStartTime), ?THROW_ERR(?ERROR_MARRY_INVITE_GUEST_001), ok),
    ?IF(lists:member(InviteRoleID, GuestList), ?THROW_ERR(?ERROR_MARRY_INVITE_GUEST_002), ok),
    [DefaultNum, _MaxExtraNum, _UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
    ?IF(erlang:length(GuestList) >= DefaultNum + ExtraGuestNum, ?THROW_ERR(?ERROR_MARRY_INVITE_GUEST_003), ok),
    ApplyGuestList2 = lists:keydelete(InviteRoleID, #r_feast_apply.role_id, ApplyGuestList),
    GuestList2 = [InviteRoleID|GuestList],
    ShareMarry2 = ShareMarry#r_marry_share{guest_list = GuestList2, apply_guest_list = ApplyGuestList2},
    GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_MARRY_FEAST_APPOINT)],
    {ok, CoupleID, ShareMarry2, FeastStartTime, GoodsList}.

%% 增加宾客上限
do_add_guest_num(RoleID, AddNum) ->
    case catch check_add_guest_num(RoleID, AddNum) of
        {ok, ShareMarry, CoupleID, ExtraGuestNum} ->
            mod_marry_data:set_share_marry(ShareMarry),
            {ok, CoupleID, ExtraGuestNum};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_add_guest_num(RoleID, AddNum) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_001)),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{feast_start_time = FeastStartTime, extra_guest_num = ExtraGuestNum} = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF(marry_misc:is_feast_over(FeastStartTime), ?THROW_ERR(?ERROR_MARRY_ADD_GUEST_001), ok),
    [_DefaultNum, MaxExtraNum, _UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
    ?IF(ExtraGuestNum < MaxExtraNum, ok, ?THROW_ERR(?ERROR_MARRY_ADD_GUEST_002)),
    ExtraGuestNum2 = AddNum + ExtraGuestNum,
    ?IF(ExtraGuestNum2 =< MaxExtraNum, ok, ?THROW_ERR(?ERROR_MARRY_ADD_GUEST_003)),
    ShareMarry2 = ShareMarry#r_marry_share{extra_guest_num = ExtraGuestNum2},
    {ok, ShareMarry2, CoupleID, ExtraGuestNum2}.

%% 申请成为宾客
do_apply_guest(RoleID) ->
    case catch check_apply_guest(RoleID) of
        {ok, RoleID1, RoleID2, ShareMarry} ->
            mod_marry_data:set_share_marry(ShareMarry),
            DataRecord = #m_marry_apply_guest_toc{guest = marry_misc:trans_to_p_guest(RoleID)},
            common_broadcast:bc_record_to_roles([RoleID, RoleID1, RoleID2], DataRecord),
            ok;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_apply_guest_toc{err_code = ErrCode})
    end.

check_apply_guest(RoleID) ->
    #r_feast_state{
        status = Status,
        share_id = ShareID
    } = mod_marry_data:get_feast_state(),
    ?IF(Status =:= ?FEAST_END, ?THROW_ERR(?ERROR_MARRY_APPLY_GUEST_001), ok),
    ?IF(common_role_data:get_role_level(RoleID) >= ?FEAST_MIN_LEVEL, ok, ?THROW_ERR(?ERROR_MARRY_INVITE_GUEST_004)),
    #r_marry_share{
        guest_list = GuestList,
        extra_guest_num = ExtraGuestNum,
        apply_guest_list = ApplyGuestList} = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    {RoleID1, RoleID2} = ShareID,
    ?IF(lists:member(RoleID, [RoleID1, RoleID2]), ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    ?IF(lists:member(RoleID, GuestList), ?THROW_ERR(?ERROR_MARRY_APPLY_GUEST_002), ok),
    [DefaultNum, MaxExtraNum, _UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
    MaxApplyTimes = common_misc:get_global_int(?GLOBAL_MARRY_FEAST_APPOINT),
    case erlang:length(GuestList) >= DefaultNum + ExtraGuestNum of
        true ->
            ?THROW_ERR(?IF(ExtraGuestNum >= MaxExtraNum, ?ERROR_MARRY_APPLY_GUEST_004, ?ERROR_MARRY_APPLY_GUEST_003));
        _ ->
            ok
    end,
    ApplyGuestList2 =
        case lists:keyfind(RoleID, #r_feast_apply.role_id, ApplyGuestList) of
            #r_feast_apply{is_refuse = IsRefuse, times = OldApplyTimes} = FeastApply ->
                ?IF(IsRefuse, ok, ?THROW_ERR(?ERROR_MARRY_APPLY_GUEST_005)),
                ?IF(OldApplyTimes >= MaxApplyTimes, ?THROW_ERR(?ERROR_MARRY_APPLY_GUEST_006), ok),
                FeastApply2 = FeastApply#r_feast_apply{is_refuse = false},
                lists:keystore(RoleID, #r_feast_apply.role_id, ApplyGuestList, FeastApply2);
            _ ->
                FeastApply = #r_feast_apply{role_id = RoleID, is_refuse = false, times = 0},
                [FeastApply|ApplyGuestList]
        end,
    ShareMarry2 = ShareMarry#r_marry_share{apply_guest_list = ApplyGuestList2},
    {ok, RoleID1, RoleID2, ShareMarry2}.

%% 回复宾客
do_reply_guest(RoleID, OpType, RoleIDsT) ->
    RoleIDs = lib_tool:list_filter_repeat(RoleIDsT),
    case catch check_reply_guest(RoleID, OpType, RoleIDs) of
        {?FEAST_GUEST_REFUSE, ShareMarry, CoupleID} ->
            mod_marry_data:set_share_marry(ShareMarry),
            DataRecord = #m_marry_reply_guest_toc{op_type = OpType, roles = marry_misc:trans_to_p_guest(RoleIDs)},
            common_broadcast:bc_record_to_roles([RoleID, CoupleID], DataRecord);
        {?FEAST_GUEST_ACCEPT, ShareMarry, CoupleID, FeastStartTime, GoodsList} ->
            mod_marry_data:set_share_marry(ShareMarry),
            DataRecord = #m_marry_reply_guest_toc{op_type = OpType, roles = marry_misc:trans_to_p_guest(RoleIDs)},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(CoupleID, DataRecord),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_MARRY_SUCC,
                goods_list = GoodsList,
                action = ?ITEM_GAIN_MARRY_GUEST,
                text_string = [
                    common_role_data:get_role_name(RoleID),
                    common_role_data:get_role_name(CoupleID),
                    time_tool:timestamp_to_datetime_str(FeastStartTime)]
            },
            [ common_letter:send_letter(DestRoleID, LetterInfo) || DestRoleID <- RoleIDs];
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_reply_guest_toc{err_code = ErrCode})
    end.

check_reply_guest(RoleID, OpType, RoleIDs) ->
    #r_feast_state{
        status = Status,
        share_id = ShareID
    } = mod_marry_data:get_feast_state(),
    ?IF(Status =:= ?FEAST_END, ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_001), ok),
    {RoleID1, RoleID2} = ShareID,
    CoupleID =
        if
            RoleID1 =:= RoleID ->
                RoleID2;
            RoleID2 =:= RoleID ->
                RoleID1;
            true ->
                ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_002)
        end,
    #r_marry_share{
        guest_list = GuestList,
        extra_guest_num = ExtraGuestNum,
        feast_start_time = FeastStartTime,
        apply_guest_list = ApplyGuestList} = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF((RoleIDs --[RoleID1, RoleID2]) =:= RoleIDs, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    case OpType of
        ?FEAST_GUEST_ACCEPT ->
            [DefaultNum, _MaxExtraNum, _UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
            ?IF((RoleIDs -- GuestList) =:= RoleIDs, ok, ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_003)),
            ApplyGuestList2 = check_reply_agree(RoleIDs, ApplyGuestList),
            ?IF(erlang:length(GuestList) + erlang:length(RoleIDs) =< DefaultNum + ExtraGuestNum, ok, ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_005)),
            ShareMarry2 = ShareMarry#r_marry_share{guest_list = RoleIDs ++ GuestList, apply_guest_list = ApplyGuestList2},
            GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_MARRY_FEAST_APPOINT)],
            {?FEAST_GUEST_ACCEPT, ShareMarry2, CoupleID, FeastStartTime, GoodsList};
        ?FEAST_GUEST_REFUSE ->
            ApplyGuestList2 = check_reply_refuse(RoleIDs, ApplyGuestList),
            ShareMarry2 = ShareMarry#r_marry_share{apply_guest_list = ApplyGuestList2},
            {?FEAST_GUEST_REFUSE, ShareMarry2, CoupleID}
    end.

check_reply_agree([], ApplyGuestList) ->
    ApplyGuestList;
check_reply_agree([RoleID|R], ApplyGuestList) ->
    case lists:keytake(RoleID, #r_feast_apply.role_id, ApplyGuestList) of
        {value, #r_feast_apply{}, ApplyGuestList2} ->
            check_reply_agree(R, ApplyGuestList2);
        _ ->
            ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_004)
    end.

check_reply_refuse([], ApplyGuestList) ->
    ApplyGuestList;
check_reply_refuse([RoleID|R], ApplyGuestList) ->
    case lists:keytake(RoleID, #r_feast_apply.role_id, ApplyGuestList) of
        {value, #r_feast_apply{is_refuse = false, times = Times} = FeastApply, ApplyGuestList2} ->
            ApplyGuestList3 = [FeastApply#r_feast_apply{is_refuse = true, times = Times + 1}|ApplyGuestList2],
            check_reply_refuse(R, ApplyGuestList3);
        _ ->
            ?THROW_ERR(?ERROR_MARRY_REPLY_GUEST_004)
    end.

%% 设置是否可以购买进入
do_set_buy(RoleID, IsBuyJoin) ->
    case catch check_set_buy(RoleID, IsBuyJoin) of
        {ok, CoupleID, ShareMarry} ->
            mod_marry_data:set_share_marry(ShareMarry),
            common_misc:unicast(RoleID, #m_marry_set_buy_toc{is_buy_join = IsBuyJoin}),
            common_misc:unicast(CoupleID, #m_marry_set_buy_toc{is_buy_join = IsBuyJoin});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_set_buy_toc{err_code = ErrCode})
    end.

check_set_buy(RoleID, IsBuyJoin) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_APPOINT_001)),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{
        feast_start_time = FeastStartTime,
        is_buy_join = OldIsBuyJoin
    } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF(marry_misc:is_feast_over(FeastStartTime), ?THROW_ERR(?ERROR_MARRY_SET_BUY_001), ok),
    ?IF(OldIsBuyJoin =:= IsBuyJoin , ?THROW_ERR(?ERROR_MARRY_SET_BUY_002), ok),
    ShareMarry2 = ShareMarry#r_marry_share{is_buy_join = IsBuyJoin},
    {ok, CoupleID, ShareMarry2}.

%% 购买进入
do_buy_join(RoleID) ->
    case catch check_buy_join(RoleID) of
        {ok, RoleID1, RoleID2, ShareMarry, FeastStartTime, GoodsList, ExtraGuestNum2} ->
            mod_marry_data:set_share_marry(ShareMarry),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_MARRY_SUCC,
                goods_list = GoodsList,
                action = ?ITEM_GAIN_MARRY_GUEST,
                text_string = [
                    common_role_data:get_role_name(RoleID1),
                    common_role_data:get_role_name(RoleID2),
                    time_tool:timestamp_to_datetime_str(FeastStartTime)]
            },
            common_letter:send_letter(RoleID, LetterInfo),
            DataRecord = #m_marry_buy_join_toc{guest = marry_misc:trans_to_p_guest(RoleID)},
            common_broadcast:bc_record_to_roles([RoleID, RoleID1, RoleID2], DataRecord),
            common_broadcast:bc_record_to_roles([RoleID1, RoleID2], #m_marry_add_guest_toc{extra_guest_num = ExtraGuestNum2}),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_buy_join(RoleID) ->
    #r_feast_state{
        status = Status,
        share_id = ShareID
    } = mod_marry_data:get_feast_state(),
    ?IF(Status =:= ?FEAST_END, ?THROW_ERR(?ERROR_MARRY_BUY_JOIN_001), ok),
    {RoleID1, RoleID2} = ShareID,
    #r_marry_share{
        is_buy_join = IsBuyJoin,
        feast_start_time = FeastStartTime,
        guest_list = GuestList,
        extra_guest_num = ExtraGuestNum,
        apply_guest_list = ApplyGuestList
    } = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    ?IF(IsBuyJoin, ok, ?THROW_ERR(?ERROR_MARRY_BUY_JOIN_004)),
    ?IF(lists:member(RoleID, [RoleID1, RoleID2]), ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    ?IF(lists:member(RoleID, GuestList), ?THROW_ERR(?ERROR_MARRY_BUY_JOIN_002), ok),
    [DefaultNum, MaxExtraNum, _UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
    ExtraGuestNum2 = ?IF(ExtraGuestNum < MaxExtraNum, ExtraGuestNum + 1, ExtraGuestNum),
    ?IF(erlang:length(GuestList) >= DefaultNum + ExtraGuestNum2, ?THROW_ERR(?ERROR_MARRY_BUY_JOIN_003), ok),
    ApplyGuestList2 = lists:keydelete(RoleID, #r_feast_apply.role_id, ApplyGuestList),
    GuestList2 = [RoleID|GuestList],
    ShareMarry2 = ShareMarry#r_marry_share{
        guest_list = GuestList2,
        extra_guest_num = ExtraGuestNum2,
        apply_guest_list = ApplyGuestList2},
    GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_MARRY_FEAST_APPOINT)],
    {ok, RoleID1, RoleID2, ShareMarry2, FeastStartTime, GoodsList, ExtraGuestNum2}.

do_get_feast_start_time() ->
    #r_feast_state{start_time = StartTime} = mod_marry_data:get_feast_state(),
    StartTime.

get_feast_data_record(FeastState) ->
    #r_feast_state{
        status = Status,
        start_time = StartTime,
        end_time = EndTime,
        share_id = ShareID
    } = FeastState,
    case Status =:= ?FEAST_END of
        true ->
            #m_marry_feast_state_toc{status = Status};
        _ ->
            {RoleID1, RoleID2} = ShareID,
            FeastRole1 = get_feast_role(RoleID1),
            FeastRole2 = get_feast_role(RoleID2),
            StatusEndTime = ?IF(Status =:= ?FEAST_PREPARE, StartTime, EndTime),
            #m_marry_feast_state_toc{
                status = Status,
                end_time = StatusEndTime,
                feast_role1 = FeastRole1,
                feast_role2 = FeastRole2
            }
    end.

get_feast_role(RoleID) ->
    #r_role_attr{
        role_name = RoleName,
        category = Category,
        sex = Sex
    } = common_role_data:get_role_attr(RoleID),
    #p_feast_role{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex
    }.


