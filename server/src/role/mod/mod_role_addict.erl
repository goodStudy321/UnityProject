%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 防沉迷机制
%%% @end
%%% Created : 06. 八月 2018 12:11
%%%-------------------------------------------------------------------
-module(mod_role_addict).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_addict.hrl").
-include("proto/gateway.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    online/1,
    loop_min/2,
    handle/2
]).

-export([
    get_addict_num/2,
    get_addict_num2/2,
    is_pay_ban/2,
    get_imei_time/2,
    update_imei_time/2
]).





init(#r_role{role_id = RoleID, role_addict = undefined} = State) ->
    RoleAddict = #r_role_addict{role_id = RoleID},
    State#r_role{role_addict = RoleAddict};
init(State) ->
    State.

online(State) ->
    #r_role{role_attr = RoleAttr, role_addict = RoleAddict} = State,
    #r_role_addict{is_auth = IsAuth} = RoleAddict,
    State2 =
        case common_config:is_gm_open()  of
            true->
                RoleAddict2 = RoleAddict#r_role_addict{is_auth = true, is_passed = true, age = 18},
                State#r_role{role_addict = RoleAddict2};
            _->
                case IsAuth of
                    true ->
                        State;
                    _ ->       % 获取沉迷信息
                        #r_role_attr{uid = UID, game_channel_id = GameChannelID} = RoleAttr,
                        case catch center_addict_server:get_addict_info(common_config:get_agent_id(), GameChannelID, UID) of
                            {ok, IsCenterAuth, IsPassed, Age} ->
                                RoleAddict2 = RoleAddict#r_role_addict{is_auth = IsCenterAuth, is_passed = IsPassed, age = Age},
                                State#r_role{role_addict = RoleAddict2};
                            _ ->
                                State
                        end
                end
        end,
    do_notice_info(State2),
    loop_min(time_tool:now(), State2).

day_reset(State) ->
    #r_role{role_addict = RoleAddict} = State,
    RoleAddict2 = RoleAddict#r_role_addict{last_remain_min = 0, reduce_rate = 0},
    State#r_role{role_addict = RoleAddict2}.

%% @doc 循环
loop_min(Now, State) ->
    #r_role{role_private_attr = #r_role_private_attr{today_online_time = TodayOnlineTime}, role_addict = RoleAddict, role_id = RoleID} = State,
    #r_role_addict{is_passed = IsPassed, last_remain_min = LastMin, is_auth = IsAuth, age = Age} = RoleAddict,
    OnlineMin = TodayOnlineTime div 60,
    #p_kvl{id = AddictStatus, list = Args} = world_data:get_addict_args(),
    RoleAddict2 = RoleAddict#r_role_addict{reduce_rate = 0},
    State2 = State#r_role{role_addict = RoleAddict2},
    Bool = game_channel_bool(State2),
    if
        Bool =:= false -> %% 当前包渠道不推送防沉迷
            State2;
        IsPassed -> %% 已经通过不做校验
            do_strict_window(OnlineMin, LastMin, Args, State2);
        AddictStatus =:= ?ADDICT_TYPE_NORMAL -> %% 宽松版
            %% 先写死每2小时提醒一次
            [NoticeMin|_] = Args,
            do_addict_window(OnlineMin, LastMin, NoticeMin, NoticeMin, State2);
        AddictStatus =:= ?ADDICT_TYPE_STRICT andalso IsAuth -> %% 严格版  并且已认证过
            State3 = do_strict_change_rate(OnlineMin, Age, Args, State2),
            do_strict_kick_role(Age, Args, State3),
            do_strict_kick_role_i(Now, Age, Args, State),
            do_strict_kick_role_by_time(OnlineMin, Age, Args, State),
            do_strict_window(OnlineMin, LastMin, Args, State3);
        AddictStatus =:= ?ADDICT_TYPE_STRICT ->                    %% 严格版  并且没认证过   检查游客模式
            NewState = case RoleAddict2#r_role_addict.is_tourist of
                           true ->
                               do_tourist_check(State2, RoleAddict2, Args, Now);
                           _ ->
                               TouristTimeSpan = get_tourist_time_span(Args),
                               case Now - RoleAddict2#r_role_addict.tourist_time >= TouristTimeSpan of
                                   true ->   %% 已过15天能重新游客模式
                                       case get_imei_time(State, Now) of
                                           {ok, TouristTime} ->
                                               case TouristTime > RoleAddict2#r_role_addict.tourist_time of
                                                   true ->   %%有更新的游戏设备时间
                                                       case Now - TouristTime >= TouristTimeSpan of
                                                           true ->   %%有更新后依旧 可以 开始游客模式
                                                               common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = ?ADDICT_TYPE_STRICT, is_tourist = 1, min = 0, is_auth = false, is_passed = false}),
                                                               RoleAddict3 = RoleAddict2#r_role_addict{tourist_time = Now, can_tourist = false, is_tourist = true},
                                                               update_imei_time(State2, Now),
                                                               State2#r_role{role_addict = RoleAddict3};
                                                           _ ->       %%有更新后 不能 开始游客模式   需提示马上认证并且收益减少至100%
                                                               Min = get_tourist_time(Args),
                                                               common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = ?ADDICT_TYPE_STRICT, is_tourist = 3, min = Min, is_auth = false, is_passed = false}),
                                                               RoleAddict3 = RoleAddict2#r_role_addict{tourist_time = TouristTime, reduce_rate = 100},
                                                               State2#r_role{role_addict = RoleAddict3}
                                                       end;
                                                   _ -> %%能进行游客模式选择
                                                       common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = ?ADDICT_TYPE_STRICT, is_tourist = 1, min = 0, is_auth = false, is_passed = false}),
                                                       RoleAddict3 = RoleAddict2#r_role_addict{tourist_time = Now, can_tourist = false, is_tourist = true},
                                                       update_imei_time(State2, Now),
                                                       State2#r_role{role_addict = RoleAddict3}
                                               end
                                       end;
                                   _ ->        %%不能 开始游客模式   需提示马上认证并且收益减少至100%
                                       Min = get_tourist_time(Args),
                                       common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = ?ADDICT_TYPE_STRICT, is_tourist = 3, min = Min, is_auth = false, is_passed = false}),
                                       RoleAddict3 = RoleAddict2#r_role_addict{reduce_rate = 100},
                                       State2#r_role{role_addict = RoleAddict3}
                               end
                       end,
            do_strict_window(OnlineMin, LastMin, Args, NewState);
        true ->
            State2
    end.

%% @doc 防沉迷信息
do_notice_info(State) ->
    #r_role{role_id = RoleID, role_addict = RoleAddict} = State,
    #r_role_addict{is_auth = IsAuth, is_passed = IsPassed} = RoleAddict,
    #p_kvl{id = AddictStatus} = world_data:get_addict_args(),
    AddictStatusNew = ?IF(game_channel_bool(State), AddictStatus, ?ADDICT_TYPE_NONE),
    common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = AddictStatusNew, is_auth = IsAuth, is_passed = IsPassed}).

%% @doc 收益下降
%% OnlineMin：今天在在线时长
do_strict_change_rate(OnlineMin, Age, Args, State) ->
    #r_role{role_addict = RoleAddict} = State,
    case lists:keyfind(?ADDICT_STRICT_BENEFIT, #p_kvl.id, Args) of
        #p_kvl{list = [X, Y, A2|_]} when Age < A2 ->
            ReduceRate2 =
            if
                OnlineMin >= Y ->
                    ?RATE_100;
                OnlineMin >= X ->
                    ?RATE_100 div 2;
                true ->
                    0
            end,
            RoleAddict2 = RoleAddict#r_role_addict{reduce_rate = ReduceRate2},
            State#r_role{role_addict = RoleAddict2};
        _ ->
            State
    end.

%% 在XX周岁以下，每日可在线时间
do_strict_kick_role_by_time(OnlineMin, Age, Args, State) ->
    case lists:keyfind(?ADDICT_STRICT_ONLINE_TIME_LENGTH, #p_kvl.id, Args) of
        #p_kvl{list = [A3, T1, T2]} when Age =< A3 ->
            T3 = case lists:keyfind(?ADDICT_STRICT_IS_HOLIDAY, #p_kvl.id, Args) of
                     #p_kvl{list = true} when Age =< A3 ->
                         T1;
                     _ ->
                         T2
                 end,
            case OnlineMin > T3 of
                true ->
                    Msg = "您是的账号已达每日游戏时间上限",
                    common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg, type = 1}),
                    role_misc:kick_role(State#r_role.role_id, ?ERROR_ROLE_ADDICT_AUTH_006);
                _ ->
                    State
            end;
        _ ->
            State
    end.


%% 在XX周岁以下，每日可登录时间
do_strict_kick_role_i(Now, Age, Args, State) ->
    NowSec = time_tool:time_to_sec(Now),
    case lists:keyfind(?ADDICT_STRICT_ONLINE_TIME, #p_kvl.id, Args) of
        #p_kvl{list = [A3, LoginStartTime, LoginEndTime]} when Age =< A3 andalso (NowSec > LoginEndTime orelse LoginStartTime > NowSec) ->
            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = "您的账号22点以后不能登录 ， 请次日8点以后再次登录", type = 1}),
            role_misc:kick_role(State#r_role.role_id, ?ERROR_ROLE_ADDICT_AUTH_005);
        _ ->
            State
    end.

%% 在XX年纪，不能登录
do_strict_kick_role(Age, Args, State) ->
    case lists:keyfind(?ADDICT_STRICT_OFFLINE, #p_kvl.id, Args) of
        #p_kvl{list = [A1]} when Age =< A1 andalso Age =/= 0 ->
            Msg = "您是未满" ++ lib_tool:to_list(Age) ++ "周岁的未成年人，根据健康系统规则，您不能进行游戏",
            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg, type = 1}),
            role_misc:kick_role(State#r_role.role_id, ?ERROR_SYSTEM_ERROR_044);
        _ ->
            State
    end.

%% @doc 弹窗提示
%% LastMin：上次提醒的分钟数
do_strict_window(OnlineMin, LastMin, Args, State) ->
    case lists:keyfind(?ADDICT_STRICT_WINDOW, #p_kvl.id, Args) of
        #p_kvl{list = [W1, W2, Y1, Y2, M, N|_]} ->
            if
                OnlineMin >= W1 andalso W2 >= OnlineMin -> do_addict_window(OnlineMin, LastMin, 0, M, State);
                OnlineMin >= Y1 andalso Y2 >= OnlineMin -> do_addict_window(OnlineMin, LastMin, Y1, N, State);
                true ->
                    case lists:keyfind(?ADDICT_STRICT_WINDOW_I, #p_kvl.id, Args) of
                        #p_kvl{list = [O, L|_]} ->
                            do_addict_window(OnlineMin, LastMin, O, L, State);
                        _ ->
                            State
                    end
            end;
        _ ->
            State
    end.

%% @doc 防沉迷弹窗提醒
do_addict_window(OnlineMin, LastMin, BeginMin, NoticeMin, State) ->
    case OnlineMin >= BeginMin andalso OnlineMin - LastMin >= NoticeMin of
        true ->
            #r_role{role_id = RoleID, role_addict = RoleAddict} = State,
            #r_role_addict{reduce_rate = ReduceRate} = RoleAddict,
            Benefit = ?IF(ReduceRate > 0, lib_tool:to_list(?RATE_100 - ReduceRate), ""),
            common_misc:unicast(RoleID, #m_role_addict_remain_toc{online_time = OnlineMin, benefit = Benefit}),
            RoleAddict2 = RoleAddict#r_role_addict{last_remain_min = OnlineMin},
            State#r_role{role_addict = RoleAddict2};
        _ ->
            State
    end.

%% @doc 是否选择包渠道推送防沉迷状态
game_channel_bool(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{game_channel_id = GameChannelID} = RoleAttr,
    GameChannelID = RoleAttr#r_role_attr.game_channel_id,
    #p_kvl{list = List} = world_data:get_addict_args(),
    case lists:keyfind(?ADDICT_GAME_CHANNEL, #p_kvl.id, List) of
        #p_kvl{list = L} ->
            lists:member(GameChannelID, L);
        _ ->
            false
    end.

get_addict_num(Num, State) ->
    #r_role{role_addict = #r_role_addict{reduce_rate = ReduceRate}} = State,
    get_addict_num2(Num, ReduceRate).

get_addict_num2(Num, ReduceRate) ->
    ?IF(ReduceRate =< 0, Num, lib_tool:ceil(Num * (?RATE_100 - ReduceRate) / ?RATE_100)).

%% 是不是不让充值了
is_pay_ban(State, Monday) ->
    #p_kvl{id = AddictStatus, list = Args} = world_data:get_addict_args(),
    case AddictStatus of
        ?ADDICT_TYPE_STRICT -> %% 严格版
            #r_role{role_addict = RoleAddict} = State,
            #r_role_addict{age = Age, is_passed = IsPassed, pay_money = PayMoney, pay_time = PayTime, is_auth = IsAuth} = RoleAddict,
            case IsPassed of
                true ->
                    false;
                _ ->
                    case IsAuth of
                        true ->
                            case lists:keyfind(?ADDICT_STRICT_PAY, #p_kvl.id, Args) of
                                #p_kvl{list = [_A1, A2, R1, Z1|_]} when Age < A2 ->
                                    case Monday > R1 of
                                        true ->
                                            Msg = "您是未满" ++ lib_tool:to_list(A2) ++ "周岁的未成年人，根据健康系统规则，您单次充值不能超过" ++ lib_tool:to_list(R1) ++ "元",
                                            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                            true;
                                        _ ->
                                            case time_tool:is_same_month(PayTime, time_tool:now()) of
                                                false ->
                                                    Msg = "您的账号已被纳入防沉迷系统，单次消费额度为" ++ lib_tool:to_list(R1) ++ "元，每月消费限额为" ++ lib_tool:to_list(Z1) ++ "，请注意合理消费",
                                                    common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                    RoleAddict2 = RoleAddict#r_role_addict{pay_money = 0, pay_time = time_tool:now()},
                                                    {ok, State#r_role{role_addict = RoleAddict2}};
                                                _ ->
                                                    case Z1 >= PayMoney + Monday of
                                                        true ->
                                                            Msg = "您的账号已被纳入防沉迷系统，单次消费额度为" ++ lib_tool:to_list(R1) ++ "元，每月消费限额为" ++ lib_tool:to_list(Z1) ++ "，请注意合理消费",
                                                            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                            false;
                                                        _ ->
                                                            Msg = "您是未满" ++ lib_tool:to_list(A2) ++ "周岁的未成年人，根据健康系统规则，您每月充值不能超过" ++ lib_tool:to_list(Z1) ++ "元",
                                                            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                            true
                                                    end
                                            end
                                    end;
                                _ ->
                                    case lists:keyfind(?ADDICT_STRICT_PAY_I, #p_kvl.id, Args) of
                                        #p_kvl{list = [A2, A3, R1, Z1|_]} when Age >= A2 andalso Age =< A3 ->
                                            case Monday > R1 of
                                                true ->
                                                    Msg = "您是未满" ++ lib_tool:to_list(18) ++ "周岁的未成年人，根据健康系统规则，您单次充值不能超过" ++ lib_tool:to_list(R1) ++ "元",
                                                    common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                    true;
                                                _ ->
                                                    case time_tool:is_same_month(PayTime, time_tool:now()) of
                                                        false ->
                                                            Msg = "您的账号已被纳入防沉迷系统，单次消费额度为" ++ lib_tool:to_list(R1) ++ "元，每月消费限额为" ++ lib_tool:to_list(Z1) ++ "，请注意合理消费",
                                                            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                            RoleAddict2 = RoleAddict#r_role_addict{pay_money = 0, pay_time = time_tool:now()},
                                                            {ok, State#r_role{role_addict = RoleAddict2}};
                                                        _ ->
                                                            case Z1 >= PayMoney + Monday of
                                                                true ->
                                                                    Msg = "您的账号已被纳入防沉迷系统，单次消费额度为" ++ lib_tool:to_list(R1) ++ "元，每月消费限额为" ++ lib_tool:to_list(Z1) ++ "，请注意合理消费",
                                                                    common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                                    false;
                                                                _ ->
                                                                    Msg = "您是未满" ++ lib_tool:to_list(A2) ++ "周岁的未成年人，根据健康系统规则，您每月充值不能超过" ++ lib_tool:to_list(Z1) ++ "元",
                                                                    common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                                                                    true
                                                            end
                                                    end
                                            end;
                                        _ ->
                                            false
                                    end
                            end;
                        _ ->  %%未验证直接禁止(包含游客)
                            Msg = "您是的账号未经实名验证，根据健康系统规则，您不能充值消费",
                            common_misc:unicast(State#r_role.role_id, #m_role_addict_window_toc{notice = Msg}),
                            true
                    end
            end;
        _ ->
            false
    end.

handle({#m_role_addict_notice_tos{is_passed = IsPassed}, _RoleID, _PID}, State) ->
    do_addict_notice(IsPassed, ?IF(IsPassed, 18, 14), State);
handle({#m_role_addict_auth_tos{id_card = IDCard, real_name = RealName}, RoleID, _PID}, State) ->
    do_addict_auth(RoleID, string:to_upper(IDCard), RealName, State).

do_addict_notice(NewPassed, Age, State) ->
    #r_role{role_attr = RoleAttr, role_addict = RoleAddict} = State,
    #r_role_attr{uid = UID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_addict{is_auth = IsAuth, is_passed = IsPassed, reduce_rate = ReduceRate} = RoleAddict,
    case IsAuth =:= true andalso IsPassed =:= NewPassed of
        true ->
            do_notice_info(State),
            State;
        _ ->
            ReduceRate2 = ?IF(NewPassed, 0, ReduceRate),
            RoleAddict2 = RoleAddict#r_role_addict{is_auth = true, is_passed = NewPassed, reduce_rate = ReduceRate2, age = Age, is_tourist = false},
            State2 = State#r_role{role_addict = RoleAddict2},
            do_notice_info(State2),
            ?TRY_CATCH(center_addict_server:add_addict_info(common_config:get_agent_id(), GameChannelID, UID, NewPassed, Age)),
            State2
    end.

do_addict_auth(RoleID, IDCard, RealName, State) ->
    case catch check_addict_auth(IDCard, RealName, State) of
        {ok, IsPassed, Age} ->
            AreaCode = "CN",
            [GameID] = lib_config:find(cfg_junhai, game_id),
            [BaseUrl] = lib_config:find(cfg_junhai, addict_url),
            #r_role{role_attr = RoleAttr} = State,
            #r_role_attr{
                uid = UID,
                channel_id = ChannelID,
                game_channel_id = GameChannelID
            } = RoleAttr,
            %% 兼容PC情况
            ChannelID2 = ?IF(ChannelID =:= 0, 18, ChannelID),
            GameChannelID2 = ?IF(GameChannelID =:= 0 orelse GameChannelID =:= 1000, 104287, GameChannelID),
            [BaseUrl] = lib_config:find(cfg_junhai, addict_url),
            [AppSecret] = lib_config:find(cfg_junhai, app_secret),
            Params = lib_tool:concat(["area_code=", AreaCode, "&channel_id=", ChannelID2, "&game_channel_id=", GameChannelID2, "&game_id=",
                                      GameID, "&id_card=", IDCard, "&real_name=", lib_tool:to_list(unicode:characters_to_binary(RealName)), "&user_id=", UID]),
            SignArgs = Params ++ "&" ++ AppSecret,
            Sign = lib_tool:md5(SignArgs),
            Url = BaseUrl ++ "?" ++ Params ++ "&sign=" ++ Sign,
            case catch ibrowse:send_req(Url, [], get, [], [], 2000) of
                {ok, "200", _Headers2, Body2} ->
                    {_, Obj2} = mochijson2:decode(Body2),
                    Ret2 = proplists:get_value(<<"ret">>, Obj2),
                    case lib_tool:to_integer(Ret2) of
                        1 ->
                            common_misc:unicast(RoleID, #m_role_addict_auth_toc{}),
                            %% 之前没认证，有奖励哇
                            GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_ADDICT_REWARD)],
                            LetterInfo = #r_letter_info{template_id = ?LETTER_TEMPLATE_ADDICT, action = ?ITEM_GAIN_ADDICT, goods_list = GoodsList},
                            common_letter:send_letter(RoleID, LetterInfo),
                            State2 = do_addict_notice(IsPassed, Age, State),
                            loop_min(time_tool:now(), State2);
                        _ ->
                            ?INFO_MSG("Url:~s    Return:~w", [Url, Body2]),
                            common_misc:unicast(RoleID, #m_role_addict_auth_toc{err_code = ?ERROR_ROLE_ADDICT_AUTH_002}),
                            State
                    end;
                {ok, Code, _Headers, _Body} ->
                    ?ERROR_MSG("Error:~s ", [Code]),
                    common_misc:unicast(RoleID, #m_role_addict_auth_toc{err_code = ?ERROR_ROLE_ADDICT_AUTH_001}),
                    State;
                Error ->
                    common_misc:unicast(RoleID, #m_role_addict_auth_toc{err_code = ?ERROR_ROLE_ADDICT_AUTH_001}),
                    ?ERROR_MSG("Error:~w ", [Error]),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_addict_auth_toc{err_code = ErrCode}),
            State;
        _ ->
            common_misc:unicast(RoleID, #m_role_addict_auth_toc{err_code = ?ERROR_ROLE_ADDICT_AUTH_002}),
            State
    end.

check_addict_auth(IDCard, RealName, State) ->
    #r_role{role_addict = #r_role_addict{is_auth = IsAuth}} = State,
    ?IF(IsAuth, ?THROW_ERR(?ERROR_ROLE_ADDICT_AUTH_004), ok),
    ?IF(IDCard =/= [] andalso RealName =/= [], ok, ?THROW_ERR(?ERROR_ROLE_ADDICT_AUTH_003)),
    Len = erlang:length(IDCard),
    if
        Len =:= 15 -> %%
            {ok, true, 18};
        Len =:= 18 ->
            {NowYear, NowMonth, NowDay} = time_tool:date(),
            Year = lib_tool:to_integer(string:substr(IDCard, 7, 4)),
            Month = lib_tool:to_integer(string:substr(IDCard, 11, 2)),
            Day = lib_tool:to_integer(string:substr(IDCard, 13, 2)),
            Age = NowYear - Year,
            if
                NowYear - Year > 18 ->
                    {ok, true, Age};
                NowYear - Year =:= 18 andalso ((NowMonth > Month) orelse (NowMonth =:= Month andalso NowDay >= Day)) ->
                    {ok, true, 18};
                true ->
                    {ok, false, Age}
            end;
        true ->
            ?THROW_ERR(?ERROR_ROLE_ADDICT_AUTH_002)
    end.


update_imei_time(#r_role{role_private_attr = PrivateAttr, role_attr = RoleAttr, role_id = RoleID}, Now) ->
    #r_role_private_attr{imei = IMEI} = PrivateAttr,
    #r_role_attr{uid = Uid} = RoleAttr,
    ServerID = common_config:get_server_id(),
    AgentID = common_config:get_agent_id(),
    req_imei_time(IMEI, Uid, RoleID, Now, AgentID, ServerID, 1).
get_imei_time(#r_role{role_private_attr = PrivateAttr, role_attr = RoleAttr, role_id = RoleID}, Now) ->
    #r_role_private_attr{imei = IMEI} = PrivateAttr,
    #r_role_attr{uid = Uid} = RoleAttr,
    ServerID = common_config:get_server_id(),
    AgentID = common_config:get_agent_id(),
    req_imei_time(IMEI, Uid, RoleID, Now, AgentID, ServerID, 2).
req_imei_time(IMEI, Uid, RoleID, Now, AgentID, ServerID, Type) ->
    Ticket = web_misc:get_key(Now),
    Body =
    [
        {imei, IMEI},
        {uid, Uid},
        {role_id, RoleID},
        {time, Now},
        {agent_id, AgentID},
        {server_id, ServerID},
        {type, Type},
        {ticket, Ticket}
    ],
    Url = web_misc:get_web_url(equipment_tourist_time_url),
    case ibrowse:send_req(Url, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Data} = mochijson2:decode(Body2),
            {struct, DataList} = proplists:get_value(lib_tool:to_binary("data"), Data),
            Time = proplists:get_value(lib_tool:to_binary("time"), DataList),
            {ok, Time};
        Error ->
            ?ERROR_MSG("----------req_imei_time--------~w", [Error]),
            ?ERROR_MSG("----------IMEI, Uid, RoleID, Now, AgentID, ServerID, Type---------~w", [{IMEI, Uid, RoleID, Now, AgentID, ServerID, Type}]),
            {ok, 0}
    end.

%%游客检查
do_tourist_check(#r_role{role_id = RoleID} = State, RoleAddict, Args, Now) ->
    case lists:keyfind(?ADDICT_TOURIST_PLAY_TIME, #p_kvl.id, Args) of   %%游客时长有
        #p_kvl{list = [TouristTime|_]} ->
            case (Now - RoleAddict#r_role_addict.tourist_time) >= TouristTime * 60 of
                true ->
                    RoleAddict2 = RoleAddict#r_role_addict{is_tourist = false},
                    State2 = State#r_role{role_addict = RoleAddict2},
                    common_misc:unicast(RoleID, #m_role_addict_info_toc{addict_state = ?ADDICT_TYPE_STRICT, is_tourist = 3, min = TouristTime, is_auth = false, is_passed = false}),
                    State2;
                _ ->
                    State
            end;
        _ ->
            State
    end.

get_tourist_time_span(Args) ->
    case lists:keyfind(?ADDICT_TOURIST_EQUIPMENT_TIME, #p_kvl.id, Args) of
        #p_kvl{list = [Day|_]} ->
            Day * ?ONE_DAY;
        _ ->
            12960000
    end.

get_tourist_time(Args) ->
    case lists:keyfind(?ADDICT_TOURIST_PLAY_TIME, #p_kvl.id, Args) of
        #p_kvl{list = [Min|_]} ->
            Min;
        _ ->
            60  %%
    end.

