%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十二月 2018 14:22
%%%-------------------------------------------------------------------
-module(bg_act_misc).
-author("WZP").
-include("bg_act.hrl").
-include("role.hrl").
-include("global.hrl").
-include("platform.hrl").
-include("copy.hrl").
-include("proto/mod_role_bg_act.hrl").

%% API
-export([
    trans_r_bg_act_to_p_bg_act_without_config_list/1,
    trans_r_bg_act_to_p_bg_act/1,
    trans_to_p_bg_act_entry/1,
    trans_to_p_bg_act_entry/2,
    init_bg_act_data/1,
    init_bg_act_data/0,
    bg_update_bg_act/1,
    bg_add_bg_act/1,
    get_status/5,
    cal_time/5,
    init_time/2
]).


%%get_open_type(Now) ->
%%    OpenDay = common_config:get_open_days(),
%%    case OpenDay > ?BG_CD of
%%        true ->
%%            {?REQUEST_BG_TYPE_NORMAL, time_tool:midnight(Now)};
%%        _ ->
%%            {?REQUEST_BG_TYPE_OPEN, OpenDay}
%%    end.

init_bg_act_data() ->
    Now = time_tool:now(),
    init_bg_act_data_i(Now).
init_bg_act_data(Now) ->
    init_bg_act_data_i(Now).

init_bg_act_data_i(Now) ->
%%    {OpenType, Today} = get_open_type(Now),
    ServerID = common_config:get_server_id(),
    AgentID = common_config:get_agent_id(),
    Url = web_misc:get_web_url(?BG_ACT_URL),
    Midnight = time_tool:midnight(Now),
    IsMidnight = Midnight =:= Now,
    Ticket = web_misc:get_key(Now),
    Body =
    [
        {agent_id, AgentID},
        {server_id, ServerID},
        {time, Now},
        {ticket, Ticket}
        %%        {atype, OpenType},
        %%        {today, Today}
    ],
    case ibrowse:send_req(Url, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Data} = mochijson2:decode(Body2),
            DataList = proplists:get_value(lib_tool:to_binary("data"), Data),
            ?ERROR_MSG("--------------DataList----------------~w", [DataList]),
            WorldLevel = world_data:get_world_level(),
            [
                begin
                    Type = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("type"), DataList2)),
                    BgID = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("id"), DataList2)),
                    OldBGActInfo = world_bg_act_server:get_bg_act(Type),
                    WorldLevel2 = ?IF(OldBGActInfo#r_bg_act.world_level =:= 0, WorldLevel, OldBGActInfo#r_bg_act.world_level),
                    ActivityName = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("activity_set_name"), DataList2)),
                    Icon = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("icon"), DataList2)),
                    Template = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("template"), DataList2)),
                    Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList2))),
                    MinLevel = proplists:get_value(lib_tool:to_binary("min_level"), DataList2),
                    TimeSlot = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("time_slot"), DataList2)),
                    Time = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("date"), DataList2)),
                    Sort = proplists:get_value(lib_tool:to_binary("sort"), DataList2),
                    IsVisible = proplists:get_value(lib_tool:to_binary("is_visible"), DataList2),
                    BackgroundImg = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("background_img"), DataList2))),
                    EditTime = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("edit_time"), DataList2)),
                    ConfigList = proplists:get_value(lib_tool:to_binary("config"), DataList2),
                    Config = proplists:get_value(lib_tool:to_binary("config2"), DataList2),
                    ?ERROR_MSG("--------------Config----------------~w", [Config]),
                    ChannelId = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("channel_id"), DataList2)),
                    GameChannelId = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("game_channel_id"), DataList2)),
                    {Config2, Explain1, Explain2} = init_tran_config(Config, Type, WorldLevel2),
                    ConfigList2 = init_tran_config_list(Type, ConfigList, WorldLevel2),
                    ?ERROR_MSG("--------------Time----------------~w", [Time]),
                    {StartTime, EndTime, StartDayTime, EndDayTime, StartDate, EndDate} = init_time(TimeSlot, Time),
                    BGActInfo = #r_bg_act{id = Type, start_time = StartTime, end_time = EndTime, start_day_time = StartDayTime, end_day_time = EndDayTime, start_date = StartDate, end_date = EndDate,
                                          icon_name = ActivityName, icon = Icon, status = ?BG_ACT_STATUS_FOUR, channel_id = ChannelId, game_channel_id = GameChannelId, title = Title, min_level = MinLevel,
                                          explain = Explain1, explain_i = Explain2, background_img = BackgroundImg, is_visible = ?INT2BOOL(IsVisible), sort = Sort, config_list = ConfigList2,
                                          edit_time = EditTime, config = Config2, template = Template, bg_id = BgID},
                    %%  决定数据是否插入
                    Insert = if
                                 Config2 =:= [] -> false;
                                 true ->
                                     case 0 =:= OldBGActInfo#r_bg_act.end_time of
                                         true ->  %%未有活动
                                             true;
                                         _ ->
                                             case BGActInfo#r_bg_act.id of
                                                 ?BG_ACT_TIME_STORE ->
                                                     ?IF(IsMidnight, true, false);
                                                 ?BG_ACT_CONSUME_RANK ->
                                                     false;
                                                 _ ->
                                                     true
                                             end
                                     end
                             end,
                    ?ERROR_MSG("--------------BGActInfo----------------~w", [BGActInfo#r_bg_act{status = OldBGActInfo#r_bg_act.status}]),
                    ?ERROR_MSG("--------------Insert----------------~w", [Insert]),
                    ?IF(Insert, db:insert(?DB_R_BG_ACT_P, BGActInfo#r_bg_act{status = OldBGActInfo#r_bg_act.status}), ok)
                end
                || {struct, DataList2} <- DataList],
            ok;
        Reason ->
            ?ERROR_MSG("--------------Reason----------------~w", [Reason])
    end.

init_tran_config_list(_Type, [], _WorldLevel2) ->
    [];
init_tran_config_list(Type, [{_, Config}|T], WorldLevel) ->
    MinWorldLevel = proplists:get_value(lib_tool:to_binary("min_world_level"), Config),
    MaxWorldLevel = proplists:get_value(lib_tool:to_binary("max_world_level"), Config),
    case MinWorldLevel =< WorldLevel andalso WorldLevel =< MaxWorldLevel of
        false ->
            init_tran_config_list(Type, T, WorldLevel);
        _ ->
            DataList = proplists:get_value(lib_tool:to_binary("condition"), Config),
            init_tran_config_list_i(Type, DataList, [])
    end.


init_tran_config_list_i(_Type, [], List) ->
    List;
init_tran_config_list_i(Type, [{_, DataList}|T], List) ->
    NewConfig = case Type of
                    ?BG_ACT_FEAST_ENTRY ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = Title, items = Items2, sort = Sort2};
                    ?BG_ACT_ACC_CONSUME ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = Title, items = Items2, sort = Sort2, condition = Condition};
                    ?BG_ACT_ACC_PAY ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = Title, items = Items2, sort = Sort2, condition = Condition};
                    ?BG_ACT_DOUBLE_COPY ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        STitle = string:tokens(Title, lib_tool:to_list(";")),
                        TitleList = lists:foldl(
                            fun(XTitle, AccTitle) ->
                                [TypeNum, XTitle1] = string:tokens(XTitle, lib_tool:to_list(",")),
                                [{lib_tool:to_integer(TypeNum), XTitle1}|AccTitle]
                            end, [], STitle),
                        Condition = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Condition2 = string:tokens(Condition, ","),
                        Condition3 = lists:foldl(
                            fun(CopyType, AccList) ->
                                CopyType2 = lib_tool:to_integer(CopyType),
                                NewList = copy_misc:get_map_list_bg_copy_type(CopyType2),
                                TitleStr2 = case lists:keyfind(CopyType2, 1, TitleList) of
                                                false ->
                                                    "";
                                                {_, TitleStr} ->
                                                    TitleStr
                                            end,
                                [{CopyType2, NewList, TitleStr2}|AccList]
                            end, [], Condition2),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        #bg_act_config_info{sort = Sort2, condition = Condition3, title = Title};
                    ?BG_ACT_STORE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        [{ItemID, ExchangeTimes, Bind, SpecialEffects}|_] = Items2,
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        #bg_act_config_info{sort = Sort2, condition = Condition, items = [{ItemID, ExchangeTimes, Bind, SpecialEffects}]};
                    ?BG_ACT_REGRESSION ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        ConditionStr = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        ConditionList = string:tokens(ConditionStr, ":"),
                        ConditionList2 = [lib_tool:to_integer(Val) || Val <- ConditionList],
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = Title, items = Items2, sort = Sort2, condition = ConditionList2};
                    ?BG_ACT_RECHARGE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{items = Items2, sort = Sort2};
                    ?BG_ACT_TREVI_FOUNTAIN ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        #bg_act_config_info{items = Items2, sort = Sort2, condition = Condition, title = Title};
                    ?BG_ACT_MISSION ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        #bg_act_config_info{items = Items2, sort = Sort2, status = ?ACT_REWARD_CANNOT_GET, condition = Condition, title = Title};
                    ?BG_ACT_RECHARGE_TURNTABLE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Times = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("times"), DataList)),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        #bg_act_config_info{items = Times, sort = Sort2, status = ?ACT_REWARD_CANNOT_GET, condition = Condition, title = Title};
                    ?BG_ACT_ACTIVE_TURNTABLE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Times = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("times"), DataList)),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Type2 = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("type"), DataList)),
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        #bg_act_config_info{items = Times, sort = Sort2, condition = Condition, title = Title, status = Type2};
                    ?BG_ACT_TREASURE_TROVE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        [{ItemID, ItemNum, ItemBind, ItemSp}|_] = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [ItemID, ItemNum, ItemBind, ItemSp],
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Title = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("title"), DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = Condition, title = Title};
                    ?BG_ACT_ST_STORE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        [ItemID, ItemNum, ItemBind, ItemSp|_] = string:tokens(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)), ","),
                        Items = [lib_tool:to_integer(ItemID), lib_tool:to_integer(ItemNum), lib_tool:to_integer(ItemBind), lib_tool:to_integer(ItemSp)],
                        Condition = proplists:get_value(lib_tool:to_binary("condition"), DataList),
                        {struct, ConditionList} = Condition,
                        Price = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price"), ConditionList)),
                        AssetType = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("asset"), ConditionList)),
                        Times = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("times"), ConditionList)),
                        #bg_act_config_info{items = Items, sort = Sort2, condition = lib_tool:to_integer(Price), title = lib_tool:to_integer(Times), status = lib_tool:to_integer(AssetType)};
                    ?BG_ACT_SECRET_TERRITORY ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_goods{type_id = ItemID, bind = ?IS_BIND(ItemBind), num = ItemNum} || {ItemID, ItemNum, ItemBind, _ItemSp} <- Items2],
                        Condition = proplists:get_value(lib_tool:to_binary("condition"), DataList),
                        {struct, ConditionList} = Condition,
                        Grow = proplists:get_value(lib_tool:to_binary("grow"), ConditionList),
                        Boss = proplists:get_value(lib_tool:to_binary("boss"), ConditionList),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = lib_tool:to_integer(Grow), status = lib_tool:to_integer(Boss)};
                    ?BG_ACT_RECHARGE_REWARD ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        Title = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("title"), DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, title = Title};
                    ?BG_ACT_CONSUME_RANK ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = 0};
                    ?BG_ACT_ALCHEMY_ONE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Title = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("title"), DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = Condition, title = Title};
                    ?BG_ACT_TIME_STORE ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        [{ItemID, ItemNum, ItemBind, ItemSp}|_] = Items2,
                        ItemNum2 = ?IF(ItemNum =:= 0, -1, ItemNum),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum2, special_effect = ItemSp}],
                        Condition = proplists:get_value(lib_tool:to_binary("condition"), DataList),
                        {struct, ConditionList} = Condition,
                        Price = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price"), ConditionList)),
                        LimitTime = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("limit_time"), ConditionList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = LimitTime, status = Price};
                    ?BG_ACT_RECHARGE_PACKET ->
                        Title = web_tool:to_utf8((proplists:get_value(lib_tool:to_binary("title"), DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), DataList)),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{title = Title, items = Items3, sort = Sort2, condition = Condition};
                    ?BG_ACT_QINGXIN ->
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{items = Items3, sort = Sort2};
                    _ ->
                        #bg_act_config_info{}
                end,
    init_tran_config_list_i(Type, T, [NewConfig|List]).

add_tran_config_list(_Type, [], _WorldLevel) ->
    [];
add_tran_config_list(Type, [{_, ConfigI}|T], WorldLevel) ->
    MinWorldLevel = proplists:get_value("min_world_level", ConfigI),
    MaxWorldLevel = proplists:get_value("max_world_level", ConfigI),
    case MinWorldLevel =< WorldLevel andalso WorldLevel =< MaxWorldLevel of
        false ->
            add_tran_config_list(Type, T, WorldLevel);
        _ ->
            Config = proplists:get_value("condition", ConfigI),
            add_tran_config_list_i(Type, Config, [])
    end.


add_tran_config_list_i(_Type, [], List) ->
    List;
add_tran_config_list_i(Type, [Config|T], List) ->
    NewConfig = case Type of
                    ?BG_ACT_FEAST_ENTRY ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = lib_tool:to_list(Title), items = Items2, sort = Sort2};
                    ?BG_ACT_ACC_CONSUME ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = lib_tool:to_list(Title), items = Items2, sort = Sort2, condition = Condition};
                    ?BG_ACT_ACC_PAY ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = lib_tool:to_list(Title), items = Items2, sort = Sort2, condition = Condition};
                    ?BG_ACT_DOUBLE_EXP ->
                        {obj, [{"id", _}, {"title", Title}, {"condition", Condition}, {"items", Items}, {"status", Status}, {"sort", Sort}]} = Config,
                        Items2 = lib_tool:string_to_intlist(lib_tool:to_list(Items), "|", ","),
                        [SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = [lib_tool:to_integer(SortStr1), lib_tool:to_integer(SortStr2)],
                        #bg_act_config_info{title = lib_tool:to_list(Title), condition = lib_tool:to_list(Condition), items = Items2, sort = Sort2, status = Status};
                    ?BG_ACT_DOUBLE_COPY ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        STitle = string:tokens(Title, lib_tool:to_list(";")),
                        TitleList = lists:foldl(
                            fun(XTitle, AccTitle) ->
                                [TypeNum, XTitle1] = string:tokens(XTitle, lib_tool:to_list(",")),
                                [{lib_tool:to_integer(TypeNum), XTitle1}|AccTitle]
                            end, [], STitle),
                        Condition = lib_tool:to_list((proplists:get_value("condition", DataList))),
                        Condition2 = string:tokens(Condition, ","),
                        Condition3 = lists:foldl(
                            fun(CopyType, AccList) ->
                                CopyType2 = lib_tool:to_integer(CopyType),
                                NewList = copy_misc:get_map_list_bg_copy_type(CopyType2),
                                TitleStr2 = case lists:keyfind(CopyType2, 1, TitleList) of
                                                false ->
                                                    "";
                                                {_, TitleStr} ->
                                                    TitleStr
                                            end,
                                [{CopyType2, NewList, TitleStr2}|AccList]
                            end, [], Condition2),
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        #bg_act_config_info{sort = Sort2, condition = Condition3, title = Title};
                    ?BG_ACT_BOSS_DROP ->
                        {obj, [{"id", _}, {"title", Title}, {"condition", Condition}, {"items", Items}, {"status", Status}, {"sort", Sort}]} = Config,
                        Items2 = lib_tool:string_to_intlist(lib_tool:to_list(Items), "|", ","),
                        [SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = [lib_tool:to_integer(SortStr1), lib_tool:to_integer(SortStr2)],
                        #bg_act_config_info{title = lib_tool:to_list(Title), condition = lib_tool:to_list(Condition), items = Items2, sort = Sort2, status = Status};
                    ?BG_ACT_STORE ->
                        {obj, DataList} = Config,
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        [{ItemID, ExchangeTimes, Bind, SpecialEffects}|_] = Items2,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        #bg_act_config_info{condition = Condition, items = [{ItemID, ExchangeTimes, Bind, SpecialEffects}], sort = Sort2};
                    ?BG_ACT_REGRESSION ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        ConditionStr = lib_tool:to_list(proplists:get_value("condition", DataList)),
                        ConditionList = string:tokens(ConditionStr, ":"),
                        ConditionList2 = [lib_tool:to_integer(Val) || Val <- ConditionList],
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{title = lib_tool:to_list(Title), items = Items2, sort = Sort2, condition = ConditionList2};
                    ?BG_ACT_RECHARGE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        #bg_act_config_info{items = Items2, sort = Sort2};
                    ?BG_ACT_TREVI_FOUNTAIN ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        #bg_act_config_info{items = Items2, sort = Sort2, title = Title, condition = Condition};
                    ?BG_ACT_MISSION ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        #bg_act_config_info{items = Items2, sort = Sort2, status = ?ACT_REWARD_CANNOT_GET, condition = Condition, title = Title};
                    ?BG_ACT_RECHARGE_TURNTABLE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Times = lib_tool:to_integer(proplists:get_value("times", DataList)),
                        #bg_act_config_info{items = Times, sort = Sort2, status = ?ACT_REWARD_CANNOT_GET, condition = Condition, title = Title};
                    ?BG_ACT_ACTIVE_TURNTABLE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Times = lib_tool:to_integer(proplists:get_value("times", DataList)),
                        Type2 = lib_tool:to_integer(proplists:get_value("type", DataList)),
                        #bg_act_config_info{items = Times, sort = Sort2, status = Type2, condition = Condition, title = Title};
                    ?BG_ACT_TREASURE_TROVE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Title = lib_tool:to_integer(proplists:get_value("title", DataList)),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        [{ItemID, ItemNum, ItemBind, ItemSp}|_] = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [ItemID, ItemNum, ItemBind, ItemSp],
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = Condition, title = Title};
                    ?BG_ACT_ST_STORE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = proplists:get_value("condition", DataList),
                        {obj, [{"price", Price}, {"asset", AssetType}, {"times", Times}]} = Condition,
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        [{ItemID, ItemNum, ItemBind, ItemSp}|_] = lib_tool:string_to_intlist(Items, "|", ","),
                        Items2 = [ItemID, ItemNum, ItemBind, ItemSp],
                        #bg_act_config_info{items = Items2, sort = Sort2, condition = lib_tool:to_integer(Price), title = lib_tool:to_integer(Times), status = lib_tool:to_integer(AssetType)};
                    ?BG_ACT_SECRET_TERRITORY ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Condition = proplists:get_value("condition", DataList),
                        {obj, [{"boss", Boss}, {"grow", Grow}]} = Condition,
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_goods{type_id = ItemID, bind = ?IS_BIND(ItemBind), num = ItemNum} || {ItemID, ItemNum, ItemBind, _ItemSp} <- Items2],
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = lib_tool:to_integer(Grow), status = lib_tool:to_integer(Boss)};
                    ?BG_ACT_RECHARGE_REWARD ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        Title = web_tool:to_utf8(proplists:get_value("title", DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, title = Title};
                    ?BG_ACT_CONSUME_RANK ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = 0};
                    ?BG_ACT_ALCHEMY_ONE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Title = lib_tool:to_integer(proplists:get_value("title", DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = Condition, title = Title};
                    ?BG_ACT_TIME_STORE ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        [{ItemID, ItemNum, ItemBind, ItemSp}|_] = Items2,
                        ItemNum2 = ?IF(ItemNum =:= 0, -1, ItemNum),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum2, special_effect = ItemSp}],
                        Condition = proplists:get_value("condition", DataList),
                        {obj, ConditionList} = Condition,
                        Price = lib_tool:to_integer(proplists:get_value("price", ConditionList)),
                        LimitTime = lib_tool:to_integer(proplists:get_value("limit_time", ConditionList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = LimitTime, status = Price};
                    ?BG_ACT_RECHARGE_PACKET ->
                        {obj, DataList} = Config,
                        Title = web_tool:to_utf8((proplists:get_value("title", DataList))),
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{title = Title, items = Items3, sort = Sort2, condition = Condition};
                    ?BG_ACT_QINGXIN ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        #bg_act_config_info{items = Items3, sort = Sort2};
                    ?BG_ACT_ALCHEMY_TWO ->
                        {obj, DataList} = Config,
                        Sort = lib_tool:to_list(proplists:get_value("sort", DataList)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        Items = lib_tool:to_list(proplists:get_value("items", DataList)),
                        Items2 = lib_tool:string_to_intlist(Items, "|", ","),
                        Items3 = [#p_item_i{type_id = ItemID, is_bind = ItemBind, num = ItemNum, special_effect = ItemSp} || {ItemID, ItemNum, ItemBind, ItemSp} <- Items2],
                        Condition = lib_tool:to_integer(proplists:get_value("condition", DataList)),
                        #bg_act_config_info{items = Items3, sort = Sort2, condition = Condition};
                    _ ->
                        {obj, [{"id", _}, {"title", Title}, {"condition", Condition}, {"items", Items}, {"status", Status}, {"sort", Sort}]} = Config,
                        Items2 = lib_tool:string_to_intlist(lib_tool:to_list(Items), "|", ","),
                        [SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = [lib_tool:to_integer(SortStr1), lib_tool:to_integer(SortStr2)],
                        #bg_act_config_info{title = lib_tool:to_list(Title), condition = lib_tool:to_list(Condition), items = Items2, sort = Sort2, status = Status}
                end,
    add_tran_config_list_i(Type, T, [NewConfig|List]).



init_tran_config([], _Type, _WorldLevel) ->
    {[], "", ""};
init_tran_config([{_, Config}|T], Type, WorldLevel) ->
    MinWorldLevel = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("min_world_level"), Config)),
    MaxWorldLevel = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("max_world_level"), Config)),
    case MinWorldLevel =< WorldLevel andalso WorldLevel =< MaxWorldLevel of
        false ->
            init_tran_config(T, Type, WorldLevel);
        _ ->
            Result = case Type of
                         ?BG_ACT_RECHARGE_TURNTABLE ->
                             Numbers = proplists:get_value(lib_tool:to_binary("numbers"), Config),
                             Magnifications = proplists:get_value(lib_tool:to_binary("magnification"), Config),
                             Numbers2 = [begin
                                             [GoldNum, GoldWeight] = string:tokens(lib_tool:to_list(Number), ","),
                                             {lib_tool:to_integer(GoldWeight), lib_tool:to_integer(GoldNum)}
                                         end || Number <- Numbers],
                             Magnifications2 = [
                                 begin
                                     [RateNum, RateWeight] = string:tokens(lib_tool:to_list(Magnification), ","),
                                     {lib_tool:to_integer(RateWeight), lib_tool:to_integer(RateNum)}
                                 end
                                 || Magnification <- Magnifications],
                             [{numbers_weight, Numbers2}, {rate_weight, Magnifications2}, {numbers, [Number2 || {_, Number2} <- Numbers2]}, {rate, [Magnification2 || {_, Magnification2} <- Magnifications2]}];
                         ?BG_ACT_RECHARGE ->
                             ModelId = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("model_id"), Config))),
                             Power = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("power"), Config))),
                             BackgroundImg = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("background_img"), Config)),
                             [{model_id, ModelId}, {power, Power}, {background_img, BackgroundImg}];
                         ?BG_ACT_DOUBLE_EXP ->
                             Rate = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("experience"), Config))),
                             Condition = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("condition"), Config)),
                             Condition2 = lib_tool:string_to_intlist(Condition, "|", ","),
                             [{rate, Rate}, {condition, Condition2}];
                         ?BG_ACT_STORE ->
                             Exchange = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("exchange"), Config)),
                             [{exchange, Exchange}];
                         ?BG_ACT_BOSS_DROP ->
                             BossDrop = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("drop1"), Config))),
                             BossDrop2 = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("drop2"), Config))),
                             [{boss_drop, BossDrop}, {boss_drop2, BossDrop2}];
                         ?BG_ACT_MISSION ->
                             MissionList = [
                                 begin
                                     Title = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("title"), InfoList)),
                                     Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), InfoList)),
                                     [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                                     Sort2 = lib_tool:to_integer(SortStr2),
                                     TaskType = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("type"), InfoList))),
                                     Task = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("task"), InfoList))),
                                     Reward = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("reward"), InfoList))),
                                     Times = lib_tool:to_integer(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("times"), InfoList))),
                                     #bg_act_mission{
                                         sort = Sort2,
                                         type = TaskType,
                                         target = Task,      %%任务目标
                                         title = Title,      %%任务描述
                                         reward = Reward,    %%奖励任务点数
                                         all_times = Times,
                                         now_times = 0,
                                         schedule = 0
                                     }
                                 end || {_, {struct, InfoList}} <- Config],
                             KeyWord = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("keyword"), Config)),
                             [{mission_list, MissionList}, {keyword, KeyWord}];
                         ?BG_ACT_TREVI_FOUNTAIN ->
                             Exchange = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("exchange"), Config)),
                             UnitPrice = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price1"), Config)),
                             FullPrice = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price2"), Config)),
                             MaxBless = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("keyword"), Config)),
                             MinBless = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("keyword2"), Config)),
                             OneReward = proplists:get_value(lib_tool:to_binary("one"), Config),
                             OneReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), OneRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), OneRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), OneRewardInfo)),
                                               IsShow = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("is_show"), OneRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, IsShow, Condition, ItemInfo2}
                                           end || {struct, OneRewardInfo} <- OneReward],
                             TwoReward = proplists:get_value(lib_tool:to_binary("two"), Config),
                             TwoReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), TwoRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), TwoRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), TwoRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {struct, TwoRewardInfo} <- TwoReward],
                             OneReward3 = lists:sort(fun({A, _, _, _}, {B, _, _, _}) -> A < B end, OneReward2),
                             OneReward4 = [{Rate, SortID, IsShow, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {SortID, IsShow, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- OneReward3],
                             TwoReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, TwoReward2),
                             TwoReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- TwoReward3],
                             [{one_reward, OneReward4}, {two_reward, TwoReward4}, {exchange, Exchange}, {unit_price, UnitPrice}, {full_price, FullPrice}, {max_bless, MaxBless}, {min_bless, MinBless}];
                         ?BG_ACT_ALCHEMY ->
                             OneReward = proplists:get_value(lib_tool:to_binary("one"), Config),
                             OneReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), OneRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), OneRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), OneRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {struct, OneRewardInfo} <- OneReward],
                             TwoReward = proplists:get_value(lib_tool:to_binary("two"), Config),
                             TwoReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), TwoRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), TwoRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), TwoRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {struct, TwoRewardInfo} <- TwoReward],
                             OneReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, OneReward2),
                             OneReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- OneReward3],
                             TwoReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, TwoReward2),
                             TwoReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- TwoReward3],
                             Price = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price"), Config)),
                             Asset = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price_asset"), Config)),
                             BtnText = proplists:get_value(lib_tool:to_binary("btn_text"), Config),
                             MaxLucky = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("max_lucky"), Config)),
                             RewardAssetNum = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("btn_number"), Config)),
                             RewardAsset = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("btn_asset"), Config)),
                             [{one_reward, OneReward4}, {two_reward, TwoReward4}, {asset, Asset}, {price, Price}, {btn_text, BtnText}, {max_lucky, MaxLucky}, {btn_number, RewardAssetNum}, {btn_asset, RewardAsset}];
                         ?BG_ACT_TREASURE_TROVE ->
                             NeedItem = proplists:get_value(lib_tool:to_binary("exchange"), Config),
                             Price = proplists:get_value(lib_tool:to_binary("price"), Config),
                             Limit = proplists:get_value(lib_tool:to_binary("limit"), Config),
                             MinBless = proplists:get_value(lib_tool:to_binary("keyword"), Config),
                             Limit2 = [begin
                                           Start = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("start"), LimitList)),
                                           End = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("end"), LimitList)),
                                           Used = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("used"), LimitList)),
                                           #p_kvt{id = Start, val = End, type = Used}
                                       end || {struct, LimitList} <- Limit],
                             [{need_item, NeedItem}, {price, Price}, {limit, Limit2}, {min_bless, MinBless}];
                         ?BG_ACT_SECRET_TERRITORY ->
                             Power = proplists:get_value(lib_tool:to_binary("first_pass_power"), Config),
                             [{first_pass_power, lib_tool:to_integer(Power)}];
                         ?BG_ACT_KING_GUARD ->
                             Price = proplists:get_value(lib_tool:to_binary("price"), Config),
                             [{price, lib_tool:to_integer(Price)}];
                         ?BG_ACT_RECHARGE_REWARD ->
                             Keyword = proplists:get_value(lib_tool:to_binary("keyword"), Config),
                             [{recharge_num, lib_tool:to_integer(Keyword)}];
                         ?BG_ACT_CONSUME_RANK ->
                             Keyword = proplists:get_value(lib_tool:to_binary("keyword"), Config),
                             [{comsume, lib_tool:to_integer(Keyword)}];
                         ?BG_ACT_ALCHEMY_ONE ->
                             Exchange = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("exchange"), Config)),
                             BtnNumber = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("btn_number"), Config)),
                             BtnAsset = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("btn_asset"), Config)),
                             BtnTimes = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("btn_times"), Config)),
                             BtnText = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("btn_text"), Config)),
                             BtnText2 = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("btn_text2"), Config)),
                             Price1 = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price1"), Config)),
                             PriceAsset = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price_asset"), Config)),
                             Price2 = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price2"), Config)),
                             Price_asset2 = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("price_asset2"), Config)),
                             [{exchange, Exchange}, {btn_number, BtnNumber}, {btn_asset, BtnAsset}, {btn_times, BtnTimes}, {btn_text, BtnText}, {btn_text2, BtnText2}, {price1, Price1}, {price_asset, PriceAsset},
                              {price2, Price2}, {price_asset2, Price_asset2}];
                         ?BG_ACT_QINGXIN ->
                             Keyword = proplists:get_value(lib_tool:to_binary("keyword"), Config),
                             KeywordNum = proplists:get_value(lib_tool:to_binary("keyword_num"), Config),
                             Exchange = proplists:get_value(lib_tool:to_binary("exchange"), Config),
                             ExchangeNum = proplists:get_value(lib_tool:to_binary("exchange_num"), Config),
                             Price = proplists:get_value(lib_tool:to_binary("price"), Config),
                             [{package, lib_tool:to_integer(Keyword)}, {exchange, lib_tool:to_integer(Exchange)}, {price, lib_tool:to_integer(Price)},
                              {package_num, lib_tool:to_integer(KeywordNum)}, {exchange_num, lib_tool:to_integer(ExchangeNum)}];
                         _ ->
                             [{is_open, true}]
                     end,
            Explain1 = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("explain1"), Config)),
            Explain2 = web_tool:to_utf8(proplists:get_value(lib_tool:to_binary("explain2"), Config)),
            {Result, Explain1, Explain2}
    end;



init_tran_config(Config, Type, _WorldLevel) ->
    case Type of
        ?BG_ACT_ACTIVE_TURNTABLE ->
            List = [begin
                        Weight = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("condition"), Info)),
                        [Items|_] = lib_tool:string_to_intlist(lib_tool:to_list(proplists:get_value(lib_tool:to_binary("items"), Info))),
                        Sort = lib_tool:to_list(proplists:get_value(lib_tool:to_binary("sort"), Info)),
                        [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                        Sort2 = lib_tool:to_integer(SortStr2),
                        {Sort2, {Weight, Items}}
                    end || {_, Info} <- Config],
            List2 = lists:sort(fun({A, _}, {B, _}) -> A < B end, List),
            List3 = [Items2 || {_, {_, Items2}} <- List2],
            [{reward_weight, List2}, {reward, List3}];
        _ ->
            []
    end.

add_tran_config_i(_Type, [], _WorldLevel) ->
    {[], "", ""};
add_tran_config_i(Type, [{_, Config}|T], WorldLevel) ->
    MinWorldLevel = proplists:get_value("min_world_level", Config),
    MaxWorldLevel = proplists:get_value("max_world_level", Config),
    ?ERROR_MSG("---------Config--------~w", [Config]),
    Config2 = Config,
    case MinWorldLevel =< WorldLevel andalso WorldLevel =< MaxWorldLevel of
        false ->
            add_tran_config_i(Type, T, WorldLevel);
        _ ->
            Result = case Type of
                         ?BG_ACT_ACTIVE_TURNTABLE ->
                             List = [begin
                                         Weight = lib_tool:to_integer(proplists:get_value("condition", Info)),
                                         [Items|_] = lib_tool:string_to_intlist(lib_tool:to_list(proplists:get_value("items", Info))),
                                         Sort = lib_tool:to_list(proplists:get_value("sort", Info)),
                                         [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                                         Sort2 = lib_tool:to_integer(SortStr2),
                                         {Sort2, {Weight, Items}}
                                     end || {_, Info} <- Config2],
                             List2 = lists:sort(fun({A, _}, {B, _}) -> A < B end, List),
                             List3 = [Items2 || {_, {_, Items2}} <- List2],
                             [{reward_weight, List2}, {reward, List3}];
                         ?BG_ACT_RECHARGE_TURNTABLE ->
                             Numbers = proplists:get_value("numbers", Config),
                             Magnifications = proplists:get_value("magnification", Config),
                             Numbers2 = [begin
                                             [GoldNum, GoldWeight] = string:tokens(lib_tool:to_list(Number), ","),
                                             {lib_tool:to_integer(GoldWeight), lib_tool:to_integer(GoldNum)}
                                         end || Number <- Numbers],
                             Magnifications2 = [
                                 begin
                                     [RateNum, RateWeight] = string:tokens(lib_tool:to_list(Magnification), ","),
                                     {lib_tool:to_integer(RateWeight), lib_tool:to_integer(RateNum)}
                                 end
                                 || Magnification <- Magnifications],
                             [{numbers_weight, Numbers2}, {rate_weight, Magnifications2}, {numbers, [Number2 || {_, Number2} <- Numbers2]}, {rate, [Magnification2 || {_, Magnification2} <- Magnifications2]}];
                         ?BG_ACT_RECHARGE ->
                             ModelId = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("model_id", Config2))),
                             Power = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("power", Config2))),
                             BackgroundImg = lib_tool:to_list(proplists:get_value("background_img", Config2)),
                             [{model_id, ModelId}, {power, Power}, {background_img, BackgroundImg}];
                         ?BG_ACT_DOUBLE_EXP ->
                             Rate = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("experience", Config2))),
                             Condition = lib_tool:to_list(proplists:get_value("condition", Config2)),
                             Condition2 = lib_tool:string_to_intlist(Condition, "|", ","),
                             [{rate, Rate}, {condition, Condition2}];
                         ?BG_ACT_STORE ->
                             Exchange = lib_tool:to_integer(proplists:get_value("exchange", Config2)),
                             [{exchange, Exchange}];
                         ?BG_ACT_BOSS_DROP ->
                             BossDrop = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("drop1", Config2))),
                             BossDrop2 = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("drop2", Config2))),
                             [{boss_drop, BossDrop}, {boss_drop2, BossDrop2}];
                         ?BG_ACT_MISSION ->
                             MissionList = [
                                 begin
                                     Title = web_tool:to_utf8(proplists:get_value("title", InfoList)),
                                     Sort = lib_tool:to_list(proplists:get_value("sort", InfoList)),
                                     [_SortStr1, SortStr2] = string:tokens(Sort, ":"),
                                     Sort2 = lib_tool:to_integer(SortStr2),
                                     TaskType = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("type", InfoList))),
                                     Task = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("task", InfoList))),
                                     Reward = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("reward", InfoList))),
                                     Times = lib_tool:to_integer(lib_tool:to_list(proplists:get_value("times", InfoList))),
                                     #bg_act_mission{
                                         sort = Sort2,
                                         type = TaskType,
                                         target = Task,      %%任务目标
                                         title = Title,      %%任务描述
                                         reward = Reward,    %%奖励任务点数
                                         all_times = Times,
                                         now_times = 0,
                                         schedule = 0
                                     }
                                 end || {_, {obj, InfoList}} <- Config2],
                             KeyWord = web_tool:to_utf8(proplists:get_value("keyword", Config2)),
                             [{mission_list, MissionList}, {keyword, KeyWord}];
                         ?BG_ACT_TREVI_FOUNTAIN ->
                             Exchange = lib_tool:to_integer(proplists:get_value("exchange", Config)),
                             UnitPrice = lib_tool:to_integer(proplists:get_value("price1", Config)),
                             MaxBless = lib_tool:to_integer(proplists:get_value("keyword", Config)),
                             MinBless = lib_tool:to_integer(proplists:get_value("keyword2", Config)),
                             FullPrice = lib_tool:to_integer(proplists:get_value("price2", Config)),
                             OneReward = proplists:get_value("one", Config),
                             OneReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value("sort", OneRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value("condition", OneRewardInfo)),
                                               IsShow = lib_tool:to_integer(proplists:get_value("is_show", OneRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value("items", OneRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, IsShow, Condition, ItemInfo2}
                                           end || {obj, OneRewardInfo} <- OneReward],
                             TwoReward = proplists:get_value("two", Config),
                             TwoReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value("sort", TwoRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value("condition", TwoRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value("items", TwoRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {obj, TwoRewardInfo} <- TwoReward],
                             OneReward3 = lists:sort(fun({A, _, _, _}, {B, _, _, _}) -> A < B end, OneReward2),
                             OneReward4 = [{Rate, SortID, IsShow, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {SortID, IsShow, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- OneReward3],
                             TwoReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, TwoReward2),
                             TwoReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- TwoReward3],
                             [{one_reward, OneReward4}, {two_reward, TwoReward4}, {exchange, Exchange}, {unit_price, UnitPrice}, {full_price, FullPrice}, {max_bless, MaxBless}, {min_bless, MinBless}];
                         ?BG_ACT_ALCHEMY ->
                             OneReward = proplists:get_value("one", Config2),
                             OneReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value("sort", OneRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value("condition", OneRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value("items", OneRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {obj, OneRewardInfo} <- OneReward],
                             TwoReward = proplists:get_value("two", Config2),
                             TwoReward2 = [begin
                                               SortStr = lib_tool:to_list(proplists:get_value("sort", TwoRewardInfo)),
                                               [_SortStr1, SortStr2] = string:tokens(SortStr, ":"),
                                               Sort2 = lib_tool:to_integer(SortStr2),
                                               Condition = lib_tool:to_integer(proplists:get_value("condition", TwoRewardInfo)),
                                               ItemInfo = lib_tool:to_list(proplists:get_value("items", TwoRewardInfo)),
                                               ItemInfo2 = lib_tool:string_to_intlist(ItemInfo, "|", ","),
                                               {Sort2, Condition, ItemInfo2}
                                           end || {obj, TwoRewardInfo} <- TwoReward],
                             OneReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, OneReward2),
                             OneReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- OneReward3],
                             TwoReward3 = lists:sort(fun({A, _, _}, {B, _, _}) -> A < B end, TwoReward2),
                             TwoReward4 = [{Rate, #p_item_i{type_id = ItemTypeID, num = ItemNum, is_bind = ItemBind, special_effect = ItemSpecialEffect}} || {_, Rate, [{ItemTypeID, ItemNum, ItemBind, ItemSpecialEffect}|_]} <- TwoReward3],
                             OneReward = proplists:get_value("one", Config2),
                             Price = lib_tool:to_integer(proplists:get_value("price", Config2)),
                             Asset = lib_tool:to_integer(proplists:get_value("price_asset", Config2)),
                             BtnText = proplists:get_value("btn_text", Config2),
                             MaxLucky = lib_tool:to_integer(proplists:get_value("max_lucky", Config2)),
                             RewardAssetNum = lib_tool:to_integer(proplists:get_value("btn_number", Config2)),
                             RewardAsset = lib_tool:to_integer(proplists:get_value("btn_asset", Config2)),
                             [{one_reward, OneReward4}, {two_reward, TwoReward4}, {asset, Asset}, {price, Price}, {btn_text, BtnText}, {max_lucky, MaxLucky}, {btn_number, RewardAssetNum}, {btn_asset, RewardAsset}];
                         ?BG_ACT_TREASURE_TROVE ->
                             NeedItem = proplists:get_value("exchange", Config),
                             Price = proplists:get_value("price", Config),
                             Limit = proplists:get_value("limit", Config),
                             MinBless = proplists:get_value("keyword", Config),
                             Limit2 = [begin
                                           Start = lib_tool:to_integer(proplists:get_value("start", LimitList)),
                                           End = lib_tool:to_integer(proplists:get_value("end", LimitList)),
                                           Used = lib_tool:to_integer(proplists:get_value("used", LimitList)),
                                           #p_kvt{id = Start, val = End, type = Used}
                                       end || {obj, LimitList} <- Limit],
                             [{need_item, NeedItem}, {price, Price}, {limit, Limit2}, {min_bless, MinBless}];
                         ?BG_ACT_SECRET_TERRITORY ->
                             Power = proplists:get_value("first_pass_power", Config),
                             [{first_pass_power, lib_tool:to_integer(Power)}];
                         ?BG_ACT_KING_GUARD ->
                             Price = proplists:get_value("price", Config2),
                             [{price, lib_tool:to_integer(Price)}];
                         ?BG_ACT_RECHARGE_REWARD ->
                             Keyword = proplists:get_value("keyword", Config2),
                             [{recharge_num, lib_tool:to_integer(Keyword)}];
                         ?BG_ACT_CONSUME_RANK ->
                             Keyword = proplists:get_value("keyword", Config),
                             [{comsume, lib_tool:to_integer(Keyword)}];
                         ?BG_ACT_ALCHEMY_ONE ->
                             Exchange = lib_tool:to_integer(proplists:get_value("exchange", Config)),
                             BtnNumber = lib_tool:to_integer(proplists:get_value("btn_number", Config)),
                             BtnAsset = lib_tool:to_integer(proplists:get_value("btn_asset", Config)),
                             BtnTimes = lib_tool:to_integer(proplists:get_value("btn_times", Config)),
                             BtnText = web_tool:to_utf8(proplists:get_value("btn_text", Config)),
                             BtnText2 = web_tool:to_utf8(proplists:get_value("btn_text2", Config)),
                             Price1 = lib_tool:to_integer(proplists:get_value("price1", Config)),
                             PriceAsset = lib_tool:to_integer(proplists:get_value("price_asset", Config)),
                             Price2 = lib_tool:to_integer(proplists:get_value("price2", Config)),
                             Price_asset2 = lib_tool:to_integer(proplists:get_value("price_asset2", Config)),
                             [{exchange, Exchange}, {btn_number, BtnNumber}, {btn_asset, BtnAsset}, {btn_times, BtnTimes}, {btn_text, BtnText}, {btn_text2, BtnText2}, {price1, Price1}, {price_asset, PriceAsset},
                              {price2, Price2}, {price_asset2, Price_asset2}];
                         ?BG_ACT_QINGXIN ->
                             Keyword = proplists:get_value("keyword", Config),
                             KeywordNum = proplists:get_value("keyword_num", Config),
                             ExchangeNum = proplists:get_value("exchange_num", Config),
                             Exchange = proplists:get_value("exchange", Config),
                             Price = proplists:get_value("price", Config),
                             [{package, lib_tool:to_integer(Keyword)}, {exchange, lib_tool:to_integer(Exchange)}, {price, lib_tool:to_integer(Price)},
                              {package_num, lib_tool:to_integer(KeywordNum)}, {exchange_num, lib_tool:to_integer(ExchangeNum)}];
                         _ ->
                             [{is_open, true}]
                     end,
            Explain1 = web_tool:to_utf8(proplists:get_value("explain1", Config)),
            Explain2 = web_tool:to_utf8(proplists:get_value("explain2", Config)),
            {Result, Explain1, Explain2}
    end.


%%初始化时间
init_time(TimeSlot, Time) ->
    [StartDateStr, EndDateStr] = string:tokens(Time, "-"),
    StartDate2 = lib_tool:to_integer(StartDateStr),
    EndDate2 = lib_tool:to_integer(EndDateStr),
    [StartDayTimeStr, EndDayTimeStr] = string:tokens(TimeSlot, " - "),
    [Hour1, Minute1, Second1] = string:tokens(StartDayTimeStr, ":"),
    [Hour2, Minute2, Second2] = string:tokens(EndDayTimeStr, ":"),
    StartDayTime = lib_tool:to_integer(Second1) + lib_tool:to_integer(Minute1) * 60 + lib_tool:to_integer(Hour1) * 3600,
    EndDayTime = lib_tool:to_integer(Second2) + lib_tool:to_integer(Minute2) * 60 + lib_tool:to_integer(Hour2) * 3600,
    {StartTime, EndTime} = cal_time(StartDate2, EndDate2, StartDayTime, EndDayTime, time_tool:now()),
    {StartTime, EndTime, StartDayTime, EndDayTime, StartDate2, EndDate2}.


%%计算出最新的开始结束时间
cal_time(StartDate, EndDate, StartDayTime, EndDayTime, Now) ->
    case StartDayTime + EndDayTime =:= 0 of
        true ->
            {StartDate, EndDate};
        _ ->
            OpenServerTime = time_tool:midnight(common_config:get_open_time()),
            CdTime = OpenServerTime,
            MaxTime = erlang:max(Now, CdTime),
            StartTime = StartDate + StartDayTime,
            EndTime = StartDate + EndDayTime,
            Midnight = time_tool:midnight(MaxTime),
            NeedOpenTime = Midnight + StartDayTime,
            NeedEndTime = Midnight + EndDayTime,
            case StartTime > NeedOpenTime of
                true ->
                    {StartTime, EndTime};
                _ ->
                    case MaxTime >= NeedEndTime of
                        false ->
                            {NeedOpenTime, NeedEndTime};
                        _ ->
                            {NeedOpenTime + ?ONE_DAY, NeedEndTime + ?ONE_DAY}
                    end
            end
    end.


%%后台增加新活动
bg_add_bg_act(Info) ->
    Type = lib_tool:to_integer(proplists:get_value("type", Info)),
    BgID = lib_tool:to_integer(proplists:get_value("id", Info)),
    WorldLevel = world_data:get_world_level(),
    OldBGActInfo = world_bg_act_server:get_bg_act(Type),
    WorldLevel2 = ?IF(OldBGActInfo#r_bg_act.world_level =:= 0, WorldLevel, OldBGActInfo#r_bg_act.world_level),
    ActivityName = web_tool:to_utf8(proplists:get_value("activity_set_name", Info)),
    Icon = lib_tool:to_integer(proplists:get_value("icon", Info)),
    Template = lib_tool:to_integer(proplists:get_value("template", Info)),
    Title = web_tool:to_utf8((proplists:get_value("title", Info))),
    MinLevel = lib_tool:to_integer(proplists:get_value("min_level", Info)),
    TimeSlot = lib_tool:to_list(proplists:get_value("time_slot", Info)),
    Time = lib_tool:to_list(proplists:get_value("date", Info)),
    Sort = lib_tool:to_integer(proplists:get_value("sort", Info)),
    IsVisible = proplists:get_value("is_visible", Info),
    BackgroundImg = web_tool:to_utf8((proplists:get_value("background_img", Info))),
    EditTime = lib_tool:to_integer(proplists:get_value("edit_time", Info)),
    ConfigList = proplists:get_value("config", Info),
    Config2 = proplists:get_value("config2", Info),
    ChannelId = lib_tool:to_list(proplists:get_value("channel_id", Info)),
    GameChannelId = lib_tool:to_list(proplists:get_value("game_channel_id", Info)),
    {Config3, Explain1, Explain2} = add_tran_config_i(Type, Config2, WorldLevel2),
    ConfigList2 = add_tran_config_list(Type, ConfigList, WorldLevel2),
    {StartTime, EndTime, StartDayTime, EndDayTime, StartDate, EndDate} = init_time(TimeSlot, Time),
    BGActInfo = #r_bg_act{id = Type, start_time = StartTime, end_time = EndTime, start_day_time = StartDayTime, end_day_time = EndDayTime, start_date = StartDate, end_date = EndDate,
                          status = ?BG_ACT_STATUS_FOUR, channel_id = ChannelId, game_channel_id = GameChannelId, title = Title, min_level = MinLevel, icon_name = ActivityName, icon = Icon,
                          explain = Explain1, explain_i = Explain2, background_img = BackgroundImg, is_visible = ?INT2BOOL(IsVisible), sort = Sort, config_list = ConfigList2, config = Config3,
                          edit_time = EditTime, template = Template},
    OldActInfo = world_bg_act_server:get_bg_act(Type),
    Insert = if
                 Config3 =:= [] -> false;
                 BgID =/= OldActInfo#r_bg_act.bg_id -> false;
                 true ->
                     true
             end,
    ?ERROR_MSG("---------Config--------~w", [BGActInfo]),
    ?ERROR_MSG("---------Insert--------~w", [Insert]),
    ?IF(Insert, db:insert(?DB_R_BG_ACT_P, BGActInfo), ok),
    ok.


%%后台更新活动
bg_update_bg_act(BgData) ->
    BgData.


trans_to_p_bg_act_entry(List, Type) ->
    trans_to_p_bg_act_entry_i(List, [], Type).

trans_to_p_bg_act_entry(List) ->
    trans_to_p_bg_act_entry_i(List, [], ?BG_ACT_ALL).

trans_to_p_bg_act_entry_i([], List, _Type) ->
    List;
trans_to_p_bg_act_entry_i([Info|T], List, Type) ->
    if
        Type =:= ?BG_ACT_STORE ->
            #bg_act_config_info{title = Title, condition = Condition, items = Items, sort = Sort, status = Status} = Info,
            [{_, ItemNum, _, _}|_] = Items,
            Items2 = [#p_item_i{type_id = ItemID, num = 1, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, _, Bind, SpecialEffect} <- Items],
            PInfo = #p_bg_act_entry{sort = Sort, items = Items2, title = Title, schedule = 0, status = Status, target = ItemNum, num = Condition};
        Type =:= ?BG_ACT_ACC_CONSUME ->
            #bg_act_config_info{title = Title, condition = Condition, items = Items, sort = Sort, status = Status} = Info,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, ItemNum, Bind, SpecialEffect} <- Items],
            PInfo = #p_bg_act_entry{sort = Sort, items = Items2, title = Title, status = Status, schedule = 0, num = -1, target = Condition};
        Type =:= ?BG_ACT_ACC_PAY ->
            #bg_act_config_info{title = Title, condition = Condition, items = Items, sort = Sort, status = Status} = Info,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, ItemNum, Bind, SpecialEffect} <- Items],
            PInfo = #p_bg_act_entry{sort = Sort, items = Items2, title = Title, status = Status, schedule = 0, num = -1, target = Condition};
        Type =:= ?BG_ACT_CONSUME_RANK ->
            #bg_act_config_info{title = Title, items = Items, sort = Sort} = Info,
            PInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title};
        Type =:= ?BG_ACT_TIME_STORE ->
            #bg_act_config_info{items = Items, sort = Sort, status = Price, condition = Time} = Info,
            [#p_item_i{num = Num}|_] = Items,
            PInfo = #p_bg_act_entry{sort = Sort, items = Items, schedule = Price, target = time_tool:midnight() + Time, num = Num};
        Type =:= ?BG_ACT_QINGXIN ->
            #bg_act_config_info{items = Items, sort = Sort} = Info,
            PInfo = #p_bg_act_entry{sort = Sort, items = Items};
        true ->
            #bg_act_config_info{title = Title, condition = _Condition, items = Items, sort = Sort, status = Status} = Info,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, ItemNum, Bind, SpecialEffect} <- Items],
            PInfo = #p_bg_act_entry{sort = Sort, items = Items2, title = Title, status = Status, schedule = 0, num = -1}
    end,
    trans_to_p_bg_act_entry_i(T, [PInfo|List], Type).


trans_r_bg_act_to_p_bg_act(Info) ->
    #r_bg_act{
        id = ID,
        start_day_time = StartDayTime,
        end_day_time = EndDayTime,
        start_date = StartDate,
        template = Template,
        end_date = EndDate,
        explain = Explain,
        background_img = BackgroundImg,
        sort = Sort,
        icon = Icon,                        %% 图标 直传前端
        icon_name = IconName,               %% 图标名 直传前端
        title = Title,
        config_list = ConfigList
    } = Info,
    EntryList = trans_to_p_bg_act_entry(ConfigList, ID),
    PBgAct = #p_bg_act{id = ID, sort = Sort, start_time = StartDayTime, end_time = EndDayTime, start_date = StartDate, end_date = EndDate, title = Title, explain = Explain, entry_list = EntryList,
                       bg_img = BackgroundImg, icon = Icon, icon_name = IconName, template = Template},
    PBgAct.



trans_r_bg_act_to_p_bg_act_without_config_list(Info) ->
    #r_bg_act{
        id = ID,
        start_time = StartTime,
        template = Template,
        end_time = EndTime,
        start_date = StartDate,
        end_date = EndDate,
        explain = Explain,
        background_img = BackgroundImg,
        sort = Sort,
        icon = Icon,                        %% 图标 直传前端
        icon_name = IconName,               %% 图标名 直传前端
        title = Title,
        config_list = ConfigList
    } = Info,
    PBgAct = #p_bg_act{id = ID, sort = Sort, start_time = StartTime, end_time = EndTime, start_date = StartDate, end_date = EndDate, title = Title, explain = Explain, entry_list = ConfigList,
                       bg_img = BackgroundImg, icon = Icon, icon_name = IconName, template = Template},
    PBgAct.


get_status(StartTime, EndTime, StartDate, EndDate, Now) ->
    IsOpenDate = StartDate =< Now andalso Now =< EndDate,
    IsOpenTime = StartTime =< Now andalso Now =< EndTime,
    {IsOpenDate, IsOpenTime}.

