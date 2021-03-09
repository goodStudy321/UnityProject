%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     andriod 与 IOS通用接口
%%% @end
%%% Created : 13. 十一月 2018 16:46
%%%-------------------------------------------------------------------
-module(mod_role_junhai).
-author("laijichang").
-include("role.hrl").
-include("platform.hrl").

%% API
-export([
    account_login_log/0,
    create_role_log/1,
    role_login_log/1,
    pay_log/5,
    level_up_log/1,
    offline_log/1,
    get_pf_gold_log/3,
    chat_log/2
]).

account_login_log() ->
    ok.

create_role_log(RoleAttr) ->
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        level = RoleLevel,
        category = Category,
        server_id = ServerID
    } = RoleAttr,
    RoleInfos = [
        {role_id, RoleID},
        {role_name, unicode:characters_to_binary(RoleName)},
        {role_level, RoleLevel},
        {role_type, Category},
        {server_id, ServerID},
        {server_name, unicode:characters_to_binary(common_config:get_server_name())}
    ],
    LogList = [{role, RoleInfos}|get_login_list(?JUNHAI_LOG_CREATE)],
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).

role_login_log(State) ->
    LogList = get_common(?JUNHAI_LOG_LOGIN, State),
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).

%% 这个不是角色进程调用，是world_pay_server
pay_log(OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr) ->
    CommonList = get_common2(?JUNHAI_LOG_PAY, RoleAttr, RolePrivateAttr),
    OrderList = [
        {order_sn, OrderID},
        {channel_trade_sn, PFOrderID},
        {currency_type, "CNY"},
        {currency_amount, PayFee/100},
        {order_type, ""}
    ],
    LogList = [{order, OrderList}|CommonList],
    Log = #r_junhai_log{log = LogList},
    junhai_misc:log(Log).

level_up_log(State) ->
    LogList = get_common(?JUNHAI_LOG_EVENT_LEVEL, State),
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).

offline_log(State) ->
    #r_role{role_attr = #r_role_attr{last_offline_time = LastOfflineTime}, role_private_attr = #r_role_private_attr{last_login_time = LastLoginTime}} = State,
    CommonList = get_common(?JUNHAI_LOG_OFFLINE, State),
    OfflineList = [
        {login_time, LastLoginTime},
        {logout_time, LastOfflineTime},
        {duration, LastOfflineTime - LastLoginTime}
    ],
    LogList = [{offline, OfflineList}|CommonList],
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).

get_pf_gold_log(State2, State, Args) ->
    #r_role{role_asset = #r_role_asset{gold = NewGold}} = State2,
    #r_role{role_asset = #r_role_asset{gold = OldGold}} = State,
    case NewGold =/= OldGold of
        true ->
            TradeList =
                case Args of
                    {Action, TypeID, Num} ->
                        Type = get_action_type(Action),
                        [Desc] = lib_config:find(cfg_gold_log, Action),
                        #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
                        [
                            {trade_type, Type},
                            {trade_amount, NewGold - OldGold},
                            {remain_amount, NewGold},
                            {item_name, unicode:characters_to_binary(ItemName)},
                            {item_amount, Num},
                            {trade_desc, unicode:characters_to_binary(Desc)}
                        ];
                    _ ->
                        Action = Args,
                        Type = get_action_type(Action),
                        [Desc] = lib_config:find(cfg_gold_log, Action),
                        [
                            {trade_type, Type},
                            {trade_amount, NewGold - OldGold},
                            {remain_amount, NewGold},
                            {item_name, ""},
                            {item_amount, ""},
                            {trade_desc, Desc}
                        ]
                end,
            LogList = [{trade, TradeList}|get_common(?JUNHAI_LOG_EVENT_GOLD, State)],
            #r_junhai_log{log = LogList};
        _ ->
            ok
    end.

get_action_type(Action) ->
    if
        Action =:= ?ASSET_GOLD_ADD_FROM_PAY ->
            ?GOLD_TYPE_PAY;
        Action =:= ?ASSET_GOLD_ADD_FROM_BACK_SEND orelse Action =:= ?ASSET_GOLD_ADD_FROM_ITEM ->
            ?GOLD_TYPE_BACK_SEND;
        Action =:= ?ITEM_GAIN_LETTER_MARKET_BUY orelse Action =:= ?ITEM_GAIN_LETTER_MARKET_SELL orelse Action >= ?ASSET_GOLD_REDUCE_FROM_MARKET_DEMAND  ->
            ?GOLD_TYPE_EXCHANGE;
        Action =:= ?ASSET_GOLD_ADD_FROM_PAY_SEND ->
            ?GOLD_TYPE_PAY_SEND;
        Action >= ?ASSET_GOLD_REDUCE_FROM_GM ->
            ?GOLD_TYPE_CONSUME;
        true ->
            ?GOLD_TYPE_OTHER
    end.

chat_log(PFChat, State) ->
    #r_pf_chat_args{
        channel_lang = ChannelLang,
        msg = ChatMsg
    } = PFChat,
    CommonList = get_common(?JUNHAI_LOG_CHAT, State),
    ChatList = [
        {chat_type, unicode:characters_to_binary(ChannelLang)},
        {chat_content, unicode:characters_to_binary(ChatMsg)}
    ],
    LogList = [{chat, ChatList}|CommonList],
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).

%%%===================================================================
%%% 通用
%%%===================================================================
get_login_list(Event) ->
    Common = common_junhai:get_log_common(Event),
    ClientIP = {client_ip, mod_role_dict:get_ip()},
    {ChannelID, GameChannelID} = mod_role_dict:get_game_chanel_id(),
    Agent = {agent, [{channel_id, ChannelID}, {game_channel_id, GameChannelID}]},
    #r_device{
        device_name = DeviceName,
        os_type = OsType,
        os_ver = OsVer,
        net_type = NetType,
        imei = IMEI,
        package_name = PackageName,
        width = Width,
        height = Height} = mod_role_dict:get_device_args(),
    %% IOS与and不一样
    IMEIList = ?IF(common_pf:is_log_ios(ChannelID, GameChannelID), [{android_imei, ""}, {ios_idfa, IMEI}], [{android_imei, IMEI}, {ios_idfa, ""}]),
    DeviceList = IMEIList ++ [
        {device_name, unicode:characters_to_binary(DeviceName)},
        {os_type, OsType},
        {os_ver, unicode:characters_to_binary(OsVer)},
        {net_type, NetType},
        {package_name, unicode:characters_to_binary(PackageName)},
        {screen_width, Width},
        {screen_height, Height},
        {"user-agent", ""}
    ],
    Device = {device, DeviceList},
    User = {user, [{user_id, mod_role_dict:get_uid()}]},
    Common ++ [ClientIP, Agent, Device, User].

get_common(Event, State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    get_common2(Event, RoleAttr, PrivateAttr).

get_common2(Event, RoleAttr, PrivateAttr) ->
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        uid = UID,
        level = RoleLevel,
        category = Category,
        server_id = ServerID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #r_role_private_attr{
        last_login_ip = IP,
        device_name = DeviceName,
        os_type = OsType,
        os_ver = OsVer,
        net_type = NetType,
        imei = IMEI,
        package_name = PackageName,
        width = Width,
        height = Height
    } = PrivateAttr,
    Common = common_junhai:get_log_common(Event),
    ClientIP = {client_ip, IP},
    %% IOS与and不一样
    IMEIList = ?IF(common_pf:is_log_ios(ChannelID, GameChannelID), [{android_imei, ""}, {ios_idfa, IMEI}], [{android_imei, IMEI}, {ios_idfa, ""}]),
    DeviceList = IMEIList ++ [
        {device_name, unicode:characters_to_binary(DeviceName)},
        {os_type, OsType},
        {os_ver, unicode:characters_to_binary(OsVer)},
        {net_type, NetType},
        {package_name, unicode:characters_to_binary(PackageName)},
        {screen_width, Width},
        {screen_height, Height},
        {"user-agent", ""}
    ],
    RoleInfos = [
        {role_id, RoleID},
        {role_name, unicode:characters_to_binary(RoleName)},
        {role_level, RoleLevel},
        {role_type, Category},
        {server_id, ServerID},
        {server_name, unicode:characters_to_binary(common_config:get_server_name())}
    ],

    Agent = {agent, [{channel_id, ChannelID}, {game_channel_id, GameChannelID}]},
    Device = {device, DeviceList},
    User = {user, [{user_id, UID}]},
    Role = {role, RoleInfos},
    Common ++ [ClientIP, Agent, Device, User, Role].
