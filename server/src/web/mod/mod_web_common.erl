%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 后台设置推送
%%% @end
%%% Created : 25. 五月 2018 9:53
%%%-------------------------------------------------------------------
-module(mod_web_common).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").
-include("role.hrl").
-include("node.hrl").

%% API
-export([
    info/1,
    reload_common_config/1,
    send_notice/1,
    del_notice/1,
    send_open_notices/1,
    set_addict_state/1,
    send_survey/1,
    stop_survey/1,
    auth_switch/1,
    send_junhai_gift/1,
    send_support_info/1,
    send_merge_info/1,
    ban_rename_action/1,
    reset_addict_holiday/0,

    get_time/1
]).

%% 请求服务器状态
info(_Req) ->
    Record = #web_info{
        is_open = true,
        is_create_able = world_data:is_create_able(),
        agent_id = common_config:get_agent_id(),
        server_id = common_config:get_server_id(),
        gateway_port = common_config:get_gateway_port()
    },
    Status = web_tool:transfer_to_json(Record),
    {ok, Status}.

reload_common_config(_Req) ->
    common_reloader:reload_config(common),
    web_server:init_data(),
    ok.

%% 发送公告
send_notice(Req) ->
    Post = Req:parse_post(),
    NoticeID = web_tool:get_int_param("id", Post),
    Text = web_tool:to_utf8(web_tool:get_string_param("txt", Post)),
    Interval = web_tool:get_int_param("interval", Post),
    StartTime = web_tool:get_int_param("start_time", Post),
    EndTime = web_tool:get_int_param("end_time", Post),
    GameChannelList = web_tool:get_integer_list("game_channel_id", Post),
    DataRecord = #m_common_notice_toc{text_string = [Text]},
    world_notice_server:send_notice(NoticeID, DataRecord, Interval, StartTime, EndTime, GameChannelList),
    ok.

del_notice(Req) ->
    Post = Req:parse_post(),
    NoticeID = web_tool:get_int_param("id", Post),
    GameChannelList = web_tool:get_integer_list("game_channel_id", Post),
    KeyList = [{NoticeID, GameChannelID} || GameChannelID <- GameChannelList],
    world_notice_server:del_notice(KeyList),
    ok.

send_open_notices(Req) ->
    case common_config:is_game_node() of
        true ->
            Post = Req:parse_post(),
            JsonData = web_tool:get_string_param("data", Post),
            GameChannelList = web_tool:get_integer_list("game_channel_id", Post),
            [begin
                 NoticeID = web_tool:get_int_param("id", DataList2),
                 NoticeID2 = NoticeID - 100000000,
                 Text = web_tool:to_utf8(web_tool:get_string_param("txt", DataList2)),
                 DataRecord = #m_common_notice_toc{text_string = [Text]},
                 Interval = web_tool:get_int_param("interval", DataList2),
                 StartTime = web_tool:get_int_param("start_time", Post),
                 EndTime = web_tool:get_int_param("end_time", Post),
                 world_notice_server:send_notice(NoticeID2, DataRecord, Interval, StartTime, EndTime, GameChannelList)
             end || {_Key, {obj, DataList2}} <- JsonData],
            ok;
        _ ->
            ok
    end.

%% @doc 设置防沉迷状态
%% 1、包渠道推送防沉迷状态选择
set_addict_state(Req) ->
    Post = Req:parse_post(),
    ?ERROR_MSG("-------1-1----~w", [Post]),
    Status = web_tool:get_int_param("status", Post),
    GameChannelLists =
    case proplists:get_value("game_channel_id", Post) of
        undefined ->
            [];
        true ->
            [];
        SL ->
            GameChannel = [lib_tool:to_integer(Select) || Select <- string:tokens(SL, ",")],
            [#p_kvl{id = ?ADDICT_GAME_CHANNEL, list = GameChannel}]
    end,
    AddictArgs =
    if
        Status =:= ?ADDICT_TYPE_NONE ->
            #p_kvl{id = ?ADDICT_TYPE_NONE, list = []};
        Status =:= ?ADDICT_TYPE_NORMAL ->
            Data = proplists:get_value("data", Post),
            Min = web_tool:get_int_param("param", Data),
            #p_kvl{id = ?ADDICT_TYPE_NORMAL, list = [Min] ++ GameChannelLists};
        Status =:= ?ADDICT_TYPE_STRICT ->
            Data = proplists:get_value("data", Post),
            {_obj, ParamList} = proplists:get_value("param", Data),
            {_obj, Visitor} = proplists:get_value("visitor", Data),
            ?ERROR_MSG("-------1-1----~w", [ParamList]),
            X = web_tool:get_int_param("X", ParamList),
            W = web_tool:get_int_param("W", ParamList),
            Y2 = web_tool:get_int_param("Y2", ParamList),
            Y1 = web_tool:get_int_param("Y1", ParamList),
            L = web_tool:get_int_param("L", ParamList),
            O = web_tool:get_int_param("O", ParamList),
            Y = web_tool:get_int_param("Y", ParamList),
            M = web_tool:get_int_param("M", ParamList),
            N = web_tool:get_int_param("N", ParamList),
            A1 = web_tool:get_int_param("A1", ParamList),
            A2 = web_tool:get_int_param("A2", ParamList),
            A3 = web_tool:get_int_param("A3", ParamList),
            T1 = web_tool:get_int_param("T1", ParamList),
            T2 = web_tool:get_int_param("T2", ParamList),
            R1 = web_tool:get_int_param("R1", ParamList),
            R2 = web_tool:get_int_param("R2", ParamList),
            Z1 = web_tool:get_int_param("Z1", ParamList),
            Z2 = web_tool:get_int_param("Z2", ParamList),
            TouristX = web_tool:get_int_param("X", Visitor),
            TouristY = web_tool:get_int_param("D", Visitor),
            LoginTimeString = binary_to_list(web_tool:get_string_param("alowlogin", ParamList)),
            [LoginStartTime, LoginEndTime] = get_time(LoginTimeString),
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
             end || Select <- string:tokens(lib_tool:to_list(proplists:get_value("indulge", Data)), ",")],
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
             end || Select <- string:tokens(lib_tool:to_list(proplists:get_value("tourist", Data)), ",")],
            ?ERROR_MSG("-------1-----~w", [#p_kvl{id = ?ADDICT_TYPE_STRICT, list = SelectList2 ++ SelectList ++ GameChannelLists}]),
            #p_kvl{id = ?ADDICT_TYPE_STRICT, list = SelectList2 ++ SelectList ++ GameChannelLists}
    end,
    world_data:set_addict_args(AddictArgs),
    case AddictArgs of
        #p_kvl{id = ?ADDICT_TYPE_STRICT} ->
            reset_addict_holiday();
        _ ->
            ok
    end,
    common_broadcast:bc_role_info_to_world({mod_role_addict, online, []}),
    ok.

reset_addict_holiday() ->
    Function =
    fun() ->
        Times = 1,
        Now = time_tool:now() + 3,
        {{Y, M, D}, _} = time_tool:timestamp_to_datetime(Now),
        M2 = ?IF(M < 10, "0" ++ lib_tool:to_list(M), lib_tool:to_list(M)),
        D2 = ?IF(D < 10, "0" ++ lib_tool:to_list(D), lib_tool:to_list(D)),
        Date = lib_tool:to_list(Y) ++ M2 ++ D2,
        Url = "https://www.mxnzp.com/api/holiday/single/" ++ Date,
        IsHoliday = get_holiday(Url, Now, Times),
        case world_data:get_addict_args() of
            #p_kvl{id = ?ADDICT_TYPE_STRICT, list = ArgList} ->
                NewArgList = lists:keydelete(?ADDICT_STRICT_IS_HOLIDAY, #p_kvl.id, ArgList),
                NewArgList2 = [#p_kvl{id = ?ADDICT_STRICT_IS_HOLIDAY, list = IsHoliday}|NewArgList],
                ?ERROR_MSG("---------reset_addict_holiday---~w", [IsHoliday]),
                world_data:set_addict_args(#p_kvl{id = ?ADDICT_TYPE_STRICT, list = NewArgList2});
            _ ->
                ok
        end
    end,
    spawn(Function).


get_holiday(_Url, _Now, Times) when Times > 10 ->
    true;
get_holiday(Url, Now, Times) ->
    ?ERROR_MSG("---------Times---~w", [Times]),
    case ibrowse:send_req(Url, [], get, [], [], 20000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Data} = mochijson2:decode(Body2),
            {_, List} = proplists:get_value(<<"data">>, Data),
            Res = proplists:get_value(<<"type">>, List),
            ?IF(Res =:= 2, true, false);
        _ ->
            get_holiday(Url, Now, Times + 1)
    end.


get_time(LoginTimeString) ->
    [StartTimeString, EndTimeString] = string:tokens(LoginTimeString, "-"),
    [H, M, S] = string:tokens(StartTimeString, ":"),
    [H2, M2, S2] = string:tokens(EndTimeString, ":"),
    [lib_tool:to_integer(H) * 3600 + lib_tool:to_integer(M) * 60 + lib_tool:to_integer(S), lib_tool:to_integer(H2) * 3600 + lib_tool:to_integer(M2) * 60 + lib_tool:to_integer(S2)].



send_survey(Req) ->
    Post = Req:parse_post(),
    SurveyID = web_tool:get_int_param("question_id", Post),
    GameChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
    MinLevel = web_tool:get_int_param("min_level", Post),
    Text = web_tool:to_utf8(rfc4627:encode(web_tool:get_string_param("question_topic", Post))),
    RewardJson = web_tool:get_string_param("rewards", Post),
    Rewards =
    [begin
         ItemID = web_tool:get_int_param("item_id", DataList2),
         ItemNum = web_tool:get_int_param("number", DataList2),
         #p_kv{id = ItemID, val = ItemNum}
     end || {obj, DataList2} <- RewardJson],
    Survey = #r_survey{
        survey_id = SurveyID,
        game_channel_id_list = GameChannelIDList,
        min_level = MinLevel,
        questions = Text,
        rewards = Rewards
    },
    SurveyList = world_data:get_survey_list(),
    SurveyList2 = [Survey|lists:keydelete(SurveyID, #r_survey.survey_id, SurveyList)],
    world_data:set_survey_list(SurveyList2),
    common_broadcast:bc_role_info_to_world({mod, mod_role_survey, {survey_change, SurveyID}}).

stop_survey(Req) ->
    Post = Req:parse_post(),
    DelSurveyID = web_tool:get_int_param("survey_id", Post),
    SurveyList = world_data:get_survey_list(),
    world_data:set_survey_list(lists:keydelete(DelSurveyID, #r_survey.survey_id, SurveyList)),
    common_broadcast:bc_role_info_to_world({mod, mod_role_survey, {survey_change, DelSurveyID}}).

auth_switch(Req) ->
    Post = Req:parse_post(),
    Type = web_tool:get_int_param("type", Post),
    if
        Type =:= 1 ->
            {ok, world_data:is_create_able()};
        Type =:= 2 ->
            IsOpen = web_tool:get_int_param("is_open", Post),
            Bool = ?IF(IsOpen > 0, true, false),
            world_data:set_create_able(Bool),
            {ok, Bool}
    end.

send_junhai_gift(Req) ->
    Post = Req:parse_post(),
    RoleID = web_tool:get_int_param("role_id", Post),
    GiftID = web_tool:get_int_param("gift_id", Post),
    GiftList = world_data:get_junhai_gifts(),
    case catch mod_role_item:get_item_config(GiftID) of
        #c_item{} ->
            GiftList2 =
            case lists:keytake(GiftID, #p_kvl.id, GiftList) of
                {value, #p_kvl{list = List} = KVL, GiftListT} ->
                    case lists:member(RoleID, List) of
                        true ->
                            erlang:throw({error, "this_id_is_use"});
                        _ ->
                            [KVL#p_kvl{list = [RoleID|List]}|GiftListT]
                    end;
                _ ->
                    [#p_kvl{id = GiftID, list = [RoleID]}|GiftList]
            end,
            world_data:set_junhai_gifts(GiftList2),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_JUNHAI_GIFT,
                action = ?ITEM_GAIN_LETTER_JUNHAI_GIFT,
                goods_list = [#p_goods{type_id = GiftID, num = 1, bind = true}]
            },
            common_letter:send_letter(RoleID, LetterInfo),
            ok;
        _ ->
            {error, "gift_not_exists"}
    end.

send_support_info(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    Type = web_tool:get_int_param("type", Post),
    UIDString = web_tool:get_string_param("uids", Post),
    ItemString = web_tool:get_string_param("item", Post),
    GameChannelID = web_tool:get_int_param("game_channel_id", Post),
    UIDList = string:tokens(UIDString, ","),
    GoodsList = web_tool:get_goods(ItemString),
    List = world_data:get_support_info(),
    case Type of
        ?CHAT_TYPE_DEL ->
            List2 = lists:keydelete(ID, #r_web_support.id, List),
            world_data:set_support_info(List2);
        _ ->
            WebSupport =
            #r_web_support{
                id = ID,
                uid_list = UIDList,
                goods_list = GoodsList,
                game_channel_id = GameChannelID
            },
            List2 = lists:keystore(ID, #r_web_support.id, List, WebSupport),
            world_data:set_support_info(List2),
            ServerID = common_config:get_server_id(),
            Now = time_tool:now(),
            [begin
                 Account = lib_tool:to_binary(lists:concat([ServerID, "_", GameChannelID, "_", UID])),
                 case login_server:get_account_role(Account) of
                     [#r_account_role{role_id_list = [FirstRoleID|_]}] ->
                         mod_role_insider:mark_insider(FirstRoleID, true, Now),
                         common_misc:send_support_goods(FirstRoleID, WebSupport);
                     _ ->
                         ok
                 end
             end || UID <- UIDList]
    end,
    ok.

send_merge_info(Req) ->
    Post = Req:parse_post(),
    JsonData = web_tool:get_string_param("data", Post),
    [begin
         ParentServerID = web_tool:get_int_param("p", DataList2),
         AgentID = web_tool:get_int_param("a", DataList2),
         ServerID = web_tool:get_int_param("s", DataList2),
         node_data:set_merge_server(#r_merge_server{agent_server_key = {AgentID, ServerID}, merge_server_id = ParentServerID})
     end || {obj, DataList2} <- JsonData],
    ok.

ban_rename_action(Req) ->
    Post = Req:parse_post(),
    TypeList = web_tool:get_integer_list("type", Post),
    world_data:set_ban_rename_actions(TypeList),
    ok.

