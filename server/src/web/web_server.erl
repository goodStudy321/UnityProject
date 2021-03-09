%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 后台服务
%%% @end
%%% Created : 23. 三月 2018 16:07
%%%-------------------------------------------------------------------
-module(web_server).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").
-include("chat.hrl").
-include("node.hrl").

%% API
-export([
    start/1,
    loop/1,
    init_data/0,
    init_merge_server/0
]).

start(Options) ->
    erlang:spawn(fun() -> ?MODULE:init_data() end),
    erlang:spawn(fun() -> ?MODULE:init_merge_server() end),
    Loop = fun(Req) ->
        ?MODULE:loop(Req)
           end,
    {_, Port} = lists:keyfind(port, 1, Options),
    Name = lib_tool:list_to_atom(lists:flatten(lists:concat([?MODULE, "_", Port]))),
    mochiweb_http:start([{name, Name}, {loop, Loop}|Options]).


loop(Req) ->
    case catch handle(Req) of
        ok ->
            web_tool:return_ok(Req);
        {ok, Data} ->
            web_tool:return_ok(Req, Data);
        {list, DataList} ->
            web_tool:return_list(Req, DataList);
        {str, StringResult} ->
            web_tool:return_string(StringResult, Req);
        {xml, XML} ->
            web_tool:return_xml(XML, Req);
        {error, ErrInfo} ->
            web_tool:return_error(Req, ErrInfo);
        Reason ->
            ?ERROR_MSG("web loop error,Req=~p,~nReason=~w,stacktrace=~n~p", [Req, Reason, erlang:get_stacktrace()]),
            web_tool:return_error(Req, "internal error")
    end.

handle(Req) ->
        "/" ++ Path = Req:get(path),
    ?INFO_MSG("Web Req : ~w", [Req:parse_post()]),
    case web_misc:get_func(Path, Req) of
        {Mod, Func, Args} ->
            case web_misc:auth_req(Req) of
                ok ->
                    erlang:apply(Mod, Func, Args);
                {error, Reason} ->
                    ?ERROR_MSG("~w auth error, Reason:~w", [?MODULE, Reason]),
                    {error, Reason}
            end;
        undefined ->
            {error, "unknown request"}
    end.

init_data() ->
    ServerID = common_config:get_server_id(),
    AgentID = common_config:get_agent_id(),
    URL = web_misc:get_web_url(init_data_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    Body =
    [
        {agent_id, AgentID},
        {server_id, ServerID},
        {time, Time},
        {ticket, Ticket}
    ],
    case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 5000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                    {_, Data} = proplists:get_value(<<"data">>, Obj2),
                    init_filter_word(Data),
                    init_ban_words(Data),
                    init_role_addict(Data),
                    init_open_notices(Data),
                    init_ban_infos(Data),
                    init_chat_set(Data),
                    init_key_words(Data),
                    init_chat_series(Data),
                    init_chat_private(Data),
                    init_support(Data),
                    init_ban_rename_actions(Data);
                _ ->
                    ?ERROR_MSG("Code : ~w", [Code]),
                    ok
            end;
        Error ->
            ?ERROR_MSG("Error:~p", [Error]),
            ok
    end.

%% 屏蔽词
init_filter_word(Data) ->
    KeyWords =
    case proplists:get_value(<<"filterword">>, Data) of
        [_|_] = KeyWordList ->
            [unicode:characters_to_list(Binary) || Binary <- KeyWordList];
        _ ->
            []
    end,
    world_data:set_filter_words(KeyWords).

init_ban_words(Data) ->
    BanWords =
    case proplists:get_value(<<"sensitive">>, Data) of
        {_, BanList} ->
            [                                                                             #r_ban_word{
                ban_word = unicode:characters_to_list(proplists:get_value(<<"title">>, BanWord)),
                ban_time = lib_tool:to_integer(proplists:get_value(<<"time">>, BanWord))} || {_ID, {_, BanWord}} <- BanList];
        _ ->
            []
    end,
    world_data:set_ban_words(BanWords).

%% @doc 防沉迷后台信息初始化
init_role_addict(Data) ->
    case proplists:get_value(<<"indulge">>, Data) of
        {_, Data2} ->
            Status = proplists:get_value(<<"status">>, Data2),
            ?ERROR_MSG("-----------~w", [Data2]),
            GameChannelLists =
            case proplists:get_value(<<"game_channel_id">>, Data2) of
                undefined ->
                    [];
                true ->
                    [];
                SL ->
                    GameChannel = [lib_tool:to_integer(Select) || Select <- string:tokens(lib_tool:to_list(SL), ",")],
                    [#p_kvl{id = ?ADDICT_GAME_CHANNEL, list = GameChannel}]
            end,

            AddictArgs =
            if
                Status =:= ?ADDICT_TYPE_NONE ->
                    #p_kvl{id = ?ADDICT_TYPE_NONE, list = []};
                Status =:= ?ADDICT_TYPE_NORMAL ->
                    Min = web_tool:get_int_param(<<"data">>, Data2),
                    #p_kvl{id = ?ADDICT_TYPE_NORMAL, list = [Min] ++ GameChannelLists};
                Status =:= ?ADDICT_TYPE_STRICT ->
                    {_, Post} = proplists:get_value(<<"data">>, Data2),
                    {_obj, ParamList} = proplists:get_value(<<"param">>, Post),
                    {_obj, Visitor} = proplists:get_value(<<"visitor">>, Post),
                    X = lib_tool:to_integer(proplists:get_value(<<"X">>, ParamList)),
                    W = lib_tool:to_integer(proplists:get_value(<<"W">>, ParamList)),
                    Y1 = lib_tool:to_integer(proplists:get_value(<<"Y1">>, ParamList)),
                    Y2 = lib_tool:to_integer(proplists:get_value(<<"Y2">>, ParamList)),
                    O = lib_tool:to_integer(proplists:get_value(<<"O">>, ParamList)),
                    L = lib_tool:to_integer(proplists:get_value(<<"L">>, ParamList)),
                    Y = lib_tool:to_integer(proplists:get_value(<<"Y">>, ParamList)),
                    M = lib_tool:to_integer(proplists:get_value(<<"M">>, ParamList)),
                    N = lib_tool:to_integer(proplists:get_value(<<"N">>, ParamList)),
                    A1 =lib_tool:to_integer( proplists:get_value(<<"A1">>, ParamList)),
                    A2 =lib_tool:to_integer(proplists:get_value(<<"A2">>, ParamList)),
                    A3 =lib_tool:to_integer( proplists:get_value(<<"A3">>, ParamList)),
                    T1 = lib_tool:to_integer(proplists:get_value(<<"T1">>, ParamList)),
                    T2 = lib_tool:to_integer(proplists:get_value(<<"T2">>, ParamList)),
                    R1 = lib_tool:to_integer(proplists:get_value(<<"R1">>, ParamList)),
                    R2 = lib_tool:to_integer(proplists:get_value(<<"R2">>, ParamList)),
                    Z1 =lib_tool:to_integer( proplists:get_value(<<"Z1">>, ParamList)),
                    Z2 = lib_tool:to_integer(proplists:get_value(<<"Z2">>, ParamList)),
                    TouristX =lib_tool:to_integer( proplists:get_value(<<"X">>, Visitor)),
                    TouristY = lib_tool:to_integer(proplists:get_value(<<"D">>, Visitor)),
                    LoginTimeString = binary_to_list(proplists:get_value(<<"alowlogin">>, ParamList)),
                    [LoginStartTime, LoginEndTime] = mod_web_common:get_time(LoginTimeString),
                    SelectList =
                    [begin
                         Select2 = lib_tool:to_integer(Select),
                         if
                             Select2 =:= ?ADDICT_STRICT_WINDOW ->
                                 #p_kvl{id = Select2, list = [0, W, Y1, Y2, M, N]};
                             Select2 =:= ?ADDICT_STRICT_WINDOW_I ->
                                 #p_kvl{id = Select2, list = [O, L]};
                             Select2 =:= ?ADDICT_STRICT_BENEFIT ->
                                 #p_kvl{id = Select2, list = [X, Y, A3]};
                             Select2 =:= ?ADDICT_STRICT_PAY ->
                                 #p_kvl{id = Select2, list = [A1, A2, R1, Z1]};
                             Select2 =:= ?ADDICT_STRICT_PAY_I ->
                                 #p_kvl{id = Select2, list = [A2, A3, R2, Z2]};
                             Select2 =:= ?ADDICT_STRICT_OFFLINE ->
                                 #p_kvl{id = Select2, list = [A1]};
                             Select2 =:= ?ADDICT_STRICT_ONLINE_TIME ->
                                 #p_kvl{id = Select2, list = [A3, LoginStartTime, LoginEndTime]};
                             Select2 =:= ?ADDICT_STRICT_ONLINE_TIME_LENGTH ->
                                 #p_kvl{id = Select2, list = [A3, T1, T2]}
                         end
                     end || Select <- string:tokens(lib_tool:to_list(proplists:get_value(<<"indulge">>, Post)), ",")],
                    SelectList2 =
                    [begin
                         Select2 = lib_tool:to_integer(Select) + 10,  %%偏移10
                         if
                             Select2 =:= ?ADDICT_TOURIST_PAY ->
                                 #p_kvl{id = Select2, list = []};
                             Select2 =:= ?ADDICT_TOURIST_PLAY_TIME ->
                                 #p_kvl{id = Select2, list = [TouristX]};
                             Select2 =:= ?ADDICT_TOURIST_EQUIPMENT_TIME ->
                                 #p_kvl{id = Select2, list = [TouristY]}
                         end
                     end || Select <- string:tokens(lib_tool:to_list(proplists:get_value(<<"tourist">>, Post)), ",")],
                    ?ERROR_MSG("-------------SelectList2-----~w", [SelectList2]),
                    ?ERROR_MSG("-------------SelectList-----~w", [SelectList]),
                    ?ERROR_MSG("-------------GameChannelLists-----~w", [GameChannelLists]),
                    #p_kvl{id = ?ADDICT_TYPE_STRICT, list = SelectList2 ++ SelectList ++ GameChannelLists}
            end,
            world_data:set_addict_args(AddictArgs),
            case AddictArgs of
                #p_kvl{id = ?ADDICT_TYPE_STRICT} ->
                    mod_web_common:reset_addict_holiday();
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

init_open_notices(Data) ->
    case proplists:get_value(<<"notice">>, Data) of
        {_, NoticeList} ->
            [begin
                 NoticeID2 = lib_tool:to_integer(NoticeID),
                 Text = web_tool:to_utf8(lib_tool:to_list(proplists:get_value(<<"txt">>, ValueList))),
                 Interval = proplists:get_value(<<"interval">>, ValueList),
                 StartTime = proplists:get_value(<<"start_time">>, ValueList),
                 EndTime = proplists:get_value(<<"end_time">>, ValueList),
                 GameChannelList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"game_channel_id">>, ValueList))),
                 DataRecord = #m_common_notice_toc{text_string = [Text]},
                 world_notice_server:send_notice(NoticeID2, DataRecord, Interval, StartTime, EndTime, GameChannelList)
             end || {NoticeID, {_, ValueList}} <- NoticeList],
            ok;
        _ ->
            ok
    end.

%% IP封禁
init_ban_infos(Data) ->
    case proplists:get_value(<<"closure">>, Data) of
        Closure when erlang:is_list(Closure) ->
            {BanIPs, BanIMEIs, BanUIDs} =
            lists:foldl(
                fun({_, ValueList}, {BanIPAcc, BanIMEIAcc, BanUIDAcc}) ->
                    Key = lib_tool:to_list(proplists:get_value(<<"role_args">>, ValueList)),
                    BanType = proplists:get_value(<<"ban_type">>, ValueList),
                    EndTime = proplists:get_value(<<"end_time">>, ValueList),
                    Value = {Key, EndTime},
                    if
                        BanType =:= ?BAN_TYPE_IP ->
                            {[Value|BanIPAcc], BanIMEIAcc, BanUIDAcc};
                        BanType =:= ?BAN_TYPE_IMEI ->
                            {BanIPAcc, [Value|BanIMEIAcc], BanUIDAcc};
                        BanType =:= ?BAN_TYPE_UID ->
                            {BanIPAcc, BanIMEIAcc, [Value|BanUIDAcc]};
                        true ->
                            {BanIPAcc, BanIMEIAcc, BanUIDAcc}
                    end
                end, {[], [], []}, Closure),
            world_data:set_ban_ips(BanIPs),
            world_data:set_ban_imei(BanIMEIs),
            world_data:set_ban_uid(BanUIDs);
        _ ->
            ok
    end.

%% 聊天设置
init_chat_set(Data) ->
    case proplists:get_value(<<"chat_set">>, Data) of
        SetList when erlang:is_list(SetList) ->
            List =
            [begin
                 ID = proplists:get_value(<<"id">>, ValueList),
                 MinOpenDay = proplists:get_value(<<"start_day">>, ValueList),
                 MaxOpenDay = proplists:get_value(<<"end_day">>, ValueList),
                 ChannelList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"chat_type">>, ValueList))),
                 RoleLevel = proplists:get_value(<<"role_level">>, ValueList),
                 VipLevel = proplists:get_value(<<"role_vip_level">>, ValueList),
                 GameChannelIDList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"game_channel_id">>, ValueList))),
                 #r_ban_chat_config{
                     id = ID,
                     min_open_day = MinOpenDay,
                     max_open_day = MaxOpenDay,
                     channel_list = ChannelList,
                     role_level = RoleLevel,
                     vip_level = VipLevel,
                     game_channel_id_list = GameChannelIDList
                 }
             end || {_, ValueList} <- SetList],
            world_data:set_chat_ban(mod_web_chat:set_chat_config(?CHAT_BAN_CHAT_CONFIG, List, world_data:get_chat_ban())),
            ok;
        _ ->
            ok
    end.

%% 关键字封禁
init_key_words(Data) ->
    case proplists:get_value(<<"keyword">>, Data) of
        KeyWordList when erlang:is_list(KeyWordList) ->
            List =
            [begin
                 ID = proplists:get_value(<<"id">>, ValueList),
                 Title = web_tool:to_utf8(lib_tool:to_list(proplists:get_value(<<"title">>, ValueList))),
                 SealRole = proplists:get_value(<<"seal_role">>, ValueList),
                 SealImei = proplists:get_value(<<"seal_imei">>, ValueList),
                 SealIP = proplists:get_value(<<"seal_ip">>, ValueList),
                 LimitTime = proplists:get_value(<<"limit_time">>, ValueList),
                 LimitTimes = proplists:get_value(<<"limit_times">>, ValueList),
                 RolePay = proplists:get_value(<<"role_pay">>, ValueList),
                 VipLevel = proplists:get_value(<<"role_vip_level">>, ValueList),
                 GameChannelIDList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"game_channel_id">>, ValueList))),
                 #r_ban_key_word{
                     id = ID,
                     title = Title,
                     is_ban_role = SealRole > 0,
                     is_ban_imei = SealImei > 0,
                     is_ban_ip = SealIP > 0,
                     time_duration = LimitTime,
                     times = LimitTimes,
                     pay_fee = RolePay,
                     vip_level = VipLevel,
                     game_channel_id_list = GameChannelIDList
                 }
             end || {_, ValueList} <- KeyWordList],
            world_data:set_chat_ban(mod_web_chat:set_chat_config(?CHAT_BAN_KEY_WORD, List, world_data:get_chat_ban())),
            ok;
        _ ->
            ok
    end.

%% 连续封禁
init_chat_series(Data) ->
    case proplists:get_value(<<"speak">>, Data) of
        SeriesList when erlang:is_list(SeriesList) ->
            List =
            [begin
                 ID = proplists:get_value(<<"id">>, ValueList),
                 BanTime = proplists:get_value(<<"ban_time">>, ValueList),
                 LimitTime = proplists:get_value(<<"limit_time">>, ValueList),
                 LimitTimes = proplists:get_value(<<"limit_times">>, ValueList),
                 RolePay = proplists:get_value(<<"role_pay">>, ValueList),
                 VipLevel = proplists:get_value(<<"role_vip_level">>, ValueList),
                 GameChannelIDList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"game_channel_id">>, ValueList))),
                 #r_ban_series{
                     id = ID,
                     time_duration = LimitTime,
                     times = LimitTimes,
                     ban_time = BanTime,
                     pay_fee = RolePay,
                     vip_level = VipLevel,
                     game_channel_id_list = GameChannelIDList
                 }
             end || {_, ValueList} <- SeriesList],
            world_data:set_chat_ban(mod_web_chat:set_chat_config(?CHAT_BAN_SERIES, List, world_data:get_chat_ban())),
            ok;
        _ ->
            ok
    end.

%% 连续封禁
init_chat_private(Data) ->
    case proplists:get_value(<<"private_chat">>, Data) of
        PrivateList when erlang:is_list(PrivateList) ->
            List =
            [begin
                 ID = proplists:get_value(<<"id">>, ValueList),
                 SealRole = proplists:get_value(<<"seal_role">>, ValueList),
                 SealImei = proplists:get_value(<<"seal_imei">>, ValueList),
                 SealIP = proplists:get_value(<<"seal_ip">>, ValueList),
                 LimitTime = proplists:get_value(<<"limit_time">>, ValueList),
                 LimitTimes = proplists:get_value(<<"limit_times">>, ValueList),
                 RolePay = proplists:get_value(<<"role_pay">>, ValueList),
                 VipLevel = proplists:get_value(<<"role_vip_level">>, ValueList),
                 GameChannelIDList = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"game_channel_id">>, ValueList))),
                 #r_ban_private{
                     id = ID,
                     is_ban_role = SealRole > 0,
                     is_ban_imei = SealImei > 0,
                     is_ban_ip = SealIP > 0,
                     time_duration = LimitTime,
                     times = LimitTimes,
                     pay_fee = RolePay,
                     vip_level = VipLevel,
                     game_channel_id_list = GameChannelIDList
                 }
             end || {_, ValueList} <- PrivateList],
            world_data:set_chat_ban(mod_web_chat:set_chat_config(?CHAT_BAN_PRIVATE, List, world_data:get_chat_ban())),
            ok;
        _ ->
            ok
    end.

init_support(Data) ->
    case proplists:get_value(<<"support">>, Data) of
        SupportList when erlang:is_list(SupportList) ->
            List =
            [begin
                 ID = proplists:get_value(<<"id">>, ValueList),
                 UIDList = string:tokens(lib_tool:to_list(proplists:get_value(<<"uids">>, ValueList)), ","),
                 GameChannelID = proplists:get_value(<<"game_channel_id">>, ValueList),
                 GoodsList = web_tool:get_goods(lib_tool:to_list(proplists:get_value(<<"item">>, ValueList))),
                 #r_web_support{
                     id = ID,
                     uid_list = UIDList,
                     goods_list = GoodsList,
                     game_channel_id = GameChannelID
                 }
             end || {_, ValueList} <- SupportList],
            world_data:set_support_info(List),
            ok;
        _ ->
            ok
    end.

init_merge_server() ->
    URL = web_misc:get_web_url(init_merge_server_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    Body = [{time, Time}, {ticket, Ticket}],
    case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 5000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                    Data = proplists:get_value(<<"data">>, Obj2),
                    init_merge_server2(Data);
                _ ->
                    ?ERROR_MSG("Code : ~w", [Code]),
                    erlang:send_after(30 * 1000, erlang:whereis(pname_server), {mfa, erlang, spawn, [fun() ->
                        ?MODULE:init_merge_server() end]}),
                    ok
            end;
        Error ->
            ?ERROR_MSG("Error:~p", [Error]),
            erlang:send_after(30 * 1000, erlang:whereis(pname_server), {mfa, erlang, spawn, [fun() ->
                ?MODULE:init_merge_server() end]}),
            ok
    end.

init_merge_server2(Data) ->
    ets:delete_all_objects(?ETS_MERGE_SERVER),
    [begin
         ParentServerID = lib_tool:to_integer(proplists:get_value(<<"p">>, ValueList)),
         AgentID = lib_tool:to_integer(proplists:get_value(<<"a">>, ValueList)),
         ServerID = lib_tool:to_integer(proplists:get_value(<<"s">>, ValueList)),
         node_data:set_merge_server(#r_merge_server{agent_server_key = {AgentID, ServerID}, merge_server_id = ParentServerID}),
         {{AgentID, ServerID}, ParentServerID}
     end || {_, ValueList} <- Data].

init_ban_rename_actions(Data) ->
    case proplists:get_value(<<"ban_rename">>, Data) of
        {_, ValueList} ->
            List = lib_tool:string_to_integer_list(lib_tool:to_list(proplists:get_value(<<"type">>, ValueList))),
            world_data:set_ban_rename_actions(List),
            ok;
        _ ->
            ok
    end.