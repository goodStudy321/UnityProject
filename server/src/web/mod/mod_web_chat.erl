%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 六月 2019 15:50
%%%-------------------------------------------------------------------
-module(mod_web_chat).
-author("laijichang").
-include("web.hrl").
-include("chat.hrl").

%% API
-export([
    chat_ban_chat_config/1,
    chat_ban_key_word/1,
    chat_ban_series/1,
    chat_ban_private/1
]).

-export([
    get_chat_config/1,
    get_chat_config/3,
    set_chat_config/3
]).

chat_ban_chat_config(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    Type = web_tool:get_int_param("type", Post),
    Map = world_data:get_chat_ban(),
    Key = ?CHAT_BAN_CHAT_CONFIG,
    List = get_chat_config(Key, Map, []),
    List2 =
        case Type of
            ?CHAT_TYPE_DEL ->
                lists:keydelete(ID, #r_ban_chat_config.id, List);
            _ ->
                MinOpenDay = web_tool:get_int_param("start_day", Post),
                MaxOpenDay = web_tool:get_int_param("end_day", Post),
                ChannelList = web_tool:get_integer_list("chat_type", Post),
                RoleLevel = web_tool:get_int_param("role_level", Post),
                VipLevel = web_tool:get_int_param("role_vip_level", Post),
                GameChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
                ChatConfig = #r_ban_chat_config{
                    id = ID,
                    min_open_day = MinOpenDay,
                    max_open_day = MaxOpenDay,
                    channel_list = ChannelList,
                    role_level = RoleLevel,
                    vip_level = VipLevel,
                    game_channel_id_list = GameChannelIDList
                },
                lists:keystore(ID, #r_ban_chat_config.id, List, ChatConfig)
        end,
    world_data:set_chat_ban(set_chat_config(Key, List2, Map)),
    ok.

chat_ban_key_word(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    Type = web_tool:get_int_param("type", Post),
    Map = world_data:get_chat_ban(),
    Key = ?CHAT_BAN_KEY_WORD,
    List = get_chat_config(Key, Map, []),
    List2 =
        case Type of
            ?CHAT_TYPE_DEL ->
                lists:keydelete(ID, #r_ban_key_word.id, List);
            _ ->
                Title = web_tool:to_utf8(web_tool:get_string_param("title", Post)),
                SealRole = web_tool:get_int_param("seal_role", Post),
                SealImei = web_tool:get_int_param("seal_imei", Post),
                SealIP = web_tool:get_int_param("seal_ip", Post),
                LimitTime = web_tool:get_int_param("limit_time", Post),
                LimitTimes = web_tool:get_int_param("limit_times", Post),
                RolePay = web_tool:get_int_param("role_pay", Post),
                VipLevel = web_tool:get_int_param("role_vip_level", Post),
                GameChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
                ChatConfig = #r_ban_key_word{
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
                },
                lists:keystore(ID, #r_ban_key_word.id, List, ChatConfig)
        end,
    world_data:set_chat_ban(set_chat_config(Key, List2, Map)),
    ok.

chat_ban_series(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    Type = web_tool:get_int_param("type", Post),
    Map = world_data:get_chat_ban(),
    Key = ?CHAT_BAN_SERIES,
    List = get_chat_config(Key, Map, []),
    List2 =
        case Type of
            ?CHAT_TYPE_DEL ->
                lists:keydelete(ID, #r_ban_series.id, List);
            _ ->
                LimitTime = web_tool:get_int_param("limit_time", Post),
                LimitTimes = web_tool:get_int_param("limit_times", Post),
                BanTime = web_tool:get_int_param("ban_time", Post),
                RolePay = web_tool:get_int_param("role_pay", Post),
                VipLevel = web_tool:get_int_param("role_vip_level", Post),
                GameChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
                ChatConfig = #r_ban_series{
                    id = ID,
                    time_duration = LimitTime,
                    times = LimitTimes,
                    ban_time = BanTime,
                    pay_fee = RolePay,
                    vip_level = VipLevel,
                    game_channel_id_list = GameChannelIDList
                },
                lists:keystore(ID, #r_ban_series.id, List, ChatConfig)
        end,
    world_data:set_chat_ban(set_chat_config(Key, List2, Map)),
    ok.

chat_ban_private(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    Type = web_tool:get_int_param("type", Post),
    Map = world_data:get_chat_ban(),
    Key = ?CHAT_BAN_PRIVATE,
    List = get_chat_config(Key, Map, []),
    List2 =
        case Type of
            ?CHAT_TYPE_DEL ->
                lists:keydelete(ID, #r_ban_private.id, List);
            _ ->
                LimitTime = web_tool:get_int_param("limit_time", Post),
                LimitTimes = web_tool:get_int_param("limit_times", Post),
                SealRole = web_tool:get_int_param("seal_role", Post),
                SealImei = web_tool:get_int_param("seal_imei", Post),
                SealIP = web_tool:get_int_param("seal_ip", Post),
                RolePay = web_tool:get_int_param("role_pay", Post),
                VipLevel = web_tool:get_int_param("role_vip_level", Post),
                GameChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
                ChatConfig = #r_ban_private{
                    id = ID,
                    is_ban_role = SealRole > 0,
                    is_ban_imei = SealImei > 0,
                    is_ban_ip = SealIP > 0,
                    time_duration = LimitTime,
                    times = LimitTimes,
                    pay_fee = RolePay,
                    vip_level = VipLevel,
                    game_channel_id_list = GameChannelIDList
                },
                lists:keystore(ID, #r_ban_private.id, List, ChatConfig)
        end,
    world_data:set_chat_ban(set_chat_config(Key, List2, Map)),
    ok.

get_chat_config(Key) ->
    Map = world_data:get_chat_ban(),
    get_chat_config(Key, Map, []).

get_chat_config(Key, Map, Default) ->
    case maps:find(Key, Map) of
        {ok, Value} ->
            Value;
        _ ->
            Default
    end.

set_chat_config(Key, Value, Map) ->
    maps:put(Key, Value, Map).

