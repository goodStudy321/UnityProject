%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     神奇渠道
%%% @end
%%% Created : 30. 七月 2019 17:55
%%%-------------------------------------------------------------------
-module(mod_role_sq_ios).
-author("laijichang").
-include("role.hrl").
-include("platform.hrl").

%% API
-export([
    get_pf_pay_url/0,

    chat_log/2
]).

get_pf_pay_url() ->
    {ok, web_misc:get_web_url(?IQIYI_IOS_PAY_URL)}.

chat_log(PFChat, State) ->
    #r_role{role_id = RoleID,
        role_attr = #r_role_attr{uid = UID, role_name = RoleName},
        role_private_attr = #r_role_private_attr{imei = IMEI, last_login_ip = LoginIP},
        role_pay = #r_role_pay{total_pay_fee = TotalPayFee}
        } = State,
    [PlatFormID] = lib_config:find(cfg_sq, platform_id),
    [AppID] = lib_config:find(cfg_sq, app_id),
    [GameKey] = lib_config:find(cfg_sq, game_key),
    ZoneID = common_config:get_server_id(),
    #r_pf_chat_args{
        channel_type = ChannelType,
        channel_lang = ChannelLang,
        receiver = Receiver,
        receiver_name = ReceiverName,
        msg_type = MsgType,
        msg = Msg
    } = PFChat,
    PlatFormIDString = lib_tool:to_list(PlatFormID),
    AppIDString = lib_tool:to_list(AppID),
    ZoneIDString = lib_tool:to_list(ZoneID),
    ChatChannelString = lib_tool:to_list(ChannelType),
    ChatChannelName = unicode:characters_to_binary(ChannelLang),
    SenderString = lib_tool:to_list(RoleID),
    RoleNameString = unicode:characters_to_binary(RoleName),
    ReceiverString = ?IF(Receiver > 0, unicode:characters_to_binary(Receiver), ""),
    ReceiverNameString = unicode:characters_to_binary(ReceiverName),
    ChatInfo = unicode:characters_to_binary(Msg),
    RechargeMoney = lib_tool:to_list(TotalPayFee),
    MessageType = lib_tool:to_list(MsgType),
    ChatTime = lib_tool:to_list(time_tool:now_ms()),
    VipLevel = lib_tool:to_list(mod_role_vip:get_vip_level(State)),

    MD5String = PlatFormIDString ++ AppIDString ++ ZoneIDString ++ SenderString ++ RechargeMoney ++ ChatInfo ++ VipLevel ++ GameKey,
    Sign =  string:to_upper(lib_tool:md5(MD5String)),
    LogList = [
        {platformId, PlatFormIDString},
        {appId, AppIDString},
        {zoneId, ZoneIDString},
        {chatChannel, ChatChannelString},
        {chatChannelName, ChatChannelName},
        {sender, SenderString},
        {senderName, RoleNameString},
        {receiver, ReceiverString},
        {receiverName, ReceiverNameString},
        {chatInfo, ChatInfo},
        {rechargeMoney, RechargeMoney},
        {messageType, MessageType},
        {chatTime, ChatTime},
        {vipLevel, VipLevel},
        {ip, LoginIP},
        {deviceId, IMEI},
        {userId, UID},
        {sign, Sign}
    ],
    Log = #r_junhai_log{log = LogList},
    mod_role_dict:add_pf_logs(Log).