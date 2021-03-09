%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 聊天
%%% @end
%%% Created : 19. 七月 2017 10:44
%%%-------------------------------------------------------------------
-module(mod_role_chat).
-author("laijichang").
-include("role.hrl").
-include("chat.hrl").
-include("role_extra.hrl").
-include("platform.hrl").
-include("proto/mod_role_chat.hrl").
-include("proto/gateway.hrl").

%% API
-export([
    online/1,
    offline/1,
    handle/2
]).

-export([
    level_up/3
]).

-export([
    word_replace/1,
    get_p_chat_role/1,
    get_p_chat_role/2
]).

online(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{level = Level, team_id = TeamID, family_id = FamilyID} = RoleAttr,
    world_chat_history_server:online_send_chat_history(RoleID, FamilyID),
    GatewayPID = mod_role_dict:get_gateway_pid(),
    world_broadcast_server:role_online(RoleID, erlang:self(), GatewayPID),
    ChannelList = [{?CHANNEL_WORLD, 0}],
    ChannelList2 = ?IF(FamilyID > 0, [{?CHANNEL_FAMILY, FamilyID}|ChannelList], ChannelList),
    ChannelList3 = ?IF(TeamID > 0, [{?CHANNEL_TEAM, TeamID}|ChannelList2], ChannelList2),
    ChannelList4 = ?IF(Level >= common_misc:get_global_int(?GLOBAL_CROSS_LEVEL), [{?CHANNEL_CROSS_AREA, 0}|ChannelList3], ChannelList3),
    world_broadcast_server:role_add_channel(RoleID, ChannelList4),
    AreaBanRoles = mod_role_extra:get_data(?EXTRA_KEY_CHAT_AREA_BAN, [], State),
    case AreaBanRoles =/= [] andalso cross_role_data_server:get_role_cross_datas(AreaBanRoles) of
        RoleCrossDatas when erlang:is_list(RoleCrossDatas) ->
            {RoleInfos, AreaBanRoles2} =
                lists:foldl(
                    fun(RoleCrossData, {Acc1, Acc2}) ->
                        case RoleCrossData of
                            #r_role_cross_data{role_id = RoleCrossID} ->
                                {[cross_data_trans_to_p_chat(RoleCrossData)|Acc1], [RoleCrossID|Acc2]};
                            _ ->
                                {Acc1, Acc2}
                        end
                    end, {[], []}, RoleCrossDatas),
            common_misc:unicast(RoleID, #m_chat_area_ban_info_toc{role_infos = RoleInfos}),
            mod_role_extra:set_data(?EXTRA_KEY_CHAT_AREA_BAN, AreaBanRoles2, State);
        _ ->
            State
    end.

offline(State) ->
    #r_role{role_id = RoleID} = State,
    world_broadcast_server:role_offline(RoleID),
    State.

%% 进入地图时检查是否在跨服区域频道
level_up(OldLevel, NewLevel, State) ->
    NeedLevel = common_misc:get_global_int(?GLOBAL_CROSS_LEVEL),
    case OldLevel < NeedLevel andalso NewLevel >= NeedLevel of
        true ->
            ChannelList = [{?CHANNEL_CROSS_AREA, 0}],
            world_broadcast_server:role_add_channel(State#r_role.role_id, ChannelList);
        _ ->
            ok
    end.


handle({chat_info, FromRoleID, DataRecord}, State) ->
    #r_role{role_id = RoleID} = State,
    CrossBanRoles = mod_role_extra:get_data(?EXTRA_KEY_CHAT_AREA_BAN, [], State),
    ?IF(world_friend_server:is_friend(RoleID, FromRoleID),
        world_chat_history_server:add_chat_history(RoleID, ?CHAT_CHANNEL_PRIVATE, DataRecord), ok),
    Binary = {binary, gateway_packet:packet(DataRecord)},
    ?IF(world_friend_server:is_black(RoleID, FromRoleID) orelse lists:member(FromRoleID, CrossBanRoles),
        ok,
        pname_server:send(mod_role_dict:get_gateway_pid(), Binary)),
    State;
handle({#m_chat_text_tos{} = DataIn, RoleID, _PID}, State) ->
    do_chat_text(RoleID, DataIn, State);
handle({#m_chat_pos_tos{} = DataIn, RoleID, _PID}, State) ->
    do_chat_pos(RoleID, DataIn, State);
handle({#m_chat_area_ban_add_tos{add_role_id = AddRoleID}, RoleID, _PID}, State) ->
    do_chat_area_ban_add(RoleID, AddRoleID, State);
handle({#m_chat_area_ban_del_tos{del_role_id = DelRoleID}, RoleID, _PID}, State) ->
    do_chat_area_ban_del(RoleID, DelRoleID, State).

%% @doc 发起聊天
do_chat_text(RoleID, DataIn, State) ->
    case catch check_can_text(RoleID, DataIn, State) of
        {ok, Log, Fun, PFChat} ->
            Fun(),
            mod_role_dict:add_key_time(?MODULE, ?HALF_SECOND_MS),
            mod_role_dict:add_background_logs(Log),
            ?TRY_CATCH(mod_role_pf:chat_log(PFChat, State)),
            State2 = do_check_chat_ban(DataIn, State),
            State2;
        {error, banwords, AddTime} ->
            mod_role_ban:add_ban(RoleID, ?BAN_TYPE_WORD_CHAT, time_tool:now() + AddTime),
            mod_web_role:ban_chat(RoleID, AddTime),
            common_misc:unicast(RoleID, #m_chat_text_toc{err_code = ?ERROR_CHAT_TEXT_005}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_chat_text_toc{err_code = ErrCode}),
            State
    end.

check_can_text(RoleID, DataIn, State) ->
    mod_role_dict:is_time_able(?MODULE),
    #r_role{role_attr = RoleAttr, role_map = RoleMap} = State,
    #r_role_attr{
        family_id = FamilyID,
        family_name = FamilyName,
        team_id = TeamID,
        role_name = Name,
        channel_id = PFChannelID,
        level = RoleLevel, % 角色等级
        game_channel_id = PFGameChannelID} = RoleAttr,
    #m_chat_text_tos{
        channel_type = ChannelType,
        channel_id = ChannelID,
        voice_sec = VoiceSec,
        msg = Msg,
        goods_id_list = GoodsIDList,
        voice_url = VoiceURL} = DataIn,
%%    ?IF(mod_role_ban:is_chat_word_ban(RoleID), ?THROW_ERR(?ERROR_CHAT_TEXT_005), ok),
    ?IF(erlang:length(GoodsIDList) =< 3, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    check_ban_chat_config(ChannelType, State),
    GoodsList =
    [begin
         {ok, Goods} = mod_role_bag:check_bag_by_id(GoodsID, State),
         Goods
     end || GoodsID <- GoodsIDList],
    ChatRole = get_p_chat_role(ChannelType, State),
    ReplaceMsg =
        case VoiceSec > 0 of
            true ->
                Msg;
            _ ->
                MsgT = trim_specail_char(Msg),
                check_ban_word(RoleID, MsgT),
                MsgT2 = check_word(Msg),
                word_replace(MsgT2)
        end,
    DataRecord = #m_chat_text_toc{
        channel_type = ChannelType,
        channel_id = ChannelID,
        role_info = ChatRole,
        voice_sec = VoiceSec,
        msg = ReplaceMsg,
        goods_list = GoodsList,
        time = time_tool:now(),
        voice_url = VoiceURL},
%%    ?IF(mod_role_ban:is_chat_ban(RoleID), ?THROW_ERR(?ERROR_CHAT_TEXT_005), ok),
    if
        ChannelType =:= ?CHAT_CHANNEL_PRIVATE ->     % 私密频道(暂为好友聊天)
            ?IF(world_friend_server:is_black(RoleID, ChannelID), ?THROW_ERR(?ERROR_CHAT_TEXT_003), ok),
            ?IF(world_friend_server:is_black(ChannelID, RoleID), ?THROW_ERR(?ERROR_CHAT_TEXT_004), ok),
            ChatName = common_role_data:get_role_name(ChannelID),
            ChatLang = ?CHAT_PRIVATE_LANG,
            ChannelIDRoleLevel =
            case role_misc:is_online(ChannelID) of
                true ->
                    #r_role_attr{level = ChannelIDRoleLevel0} = role_server:i(ChannelID, role_attr),
                    ChannelIDRoleLevel0;
                _ ->
                    [#r_role_attr{level = ChannelIDRoleLevel0}] = db:lookup(?DB_ROLE_ATTR_P, ChannelID),
                    ChannelIDRoleLevel0
            end,

            [Config] = lib_config:find(cfg_global, ?GLOBAL_PRIVATE_CHAT),
            [{PrivateChatLevel}] = common_misc:get_global_string_list(Config#c_global.string),
            ?IF(RoleLevel >= PrivateChatLevel andalso ChannelIDRoleLevel >= PrivateChatLevel, ok, ?THROW_ERR(?ERROR_CHAT_TEXT_008)), % 服务端加入对私聊发言的等级限制
            Fun = fun() ->
                case mod_role_ban:is_chat_ban(RoleID) of
                    true ->
                        world_friend_server:add_chat(RoleID, ChannelID),%%这个里面加一个朋友密聊频道
                        world_chat_history_server:add_chat_history(RoleID, ?CHAT_CHANNEL_PRIVATE, DataRecord),
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary);
                    _ ->
                        DataRecord1 = DataRecord#m_chat_text_toc{channel_id = RoleID},
                        ?IF(role_misc:is_online(ChannelID), role_misc:info_role(ChannelID, {mod, ?MODULE, {chat_info, RoleID, DataRecord1}}),
                            world_chat_history_server:add_chat_history(ChannelID, ?CHAT_CHANNEL_PRIVATE, DataRecord1)),
                        world_friend_server:add_chat(RoleID, ChannelID),%%这个里面加一个朋友密聊频道
                        world_chat_history_server:add_chat_history(RoleID, ?CHAT_CHANNEL_PRIVATE, DataRecord),
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary)
                end end;
        ChannelType =:= ?CHAT_CHANNEL_FAMILY ->  % 家族频道
            ChatName = FamilyName,
            ChatLang = ?CHAT_FAMILY_LANG,
            Fun = fun() ->
                case mod_role_ban:is_chat_ban(RoleID) of
                    true ->
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary);
                    _ ->
                        common_broadcast:bc_role_info_to_family(FamilyID, {mod, ?MODULE, {chat_info, RoleID, DataRecord}})
                end,
                world_chat_history_server:add_chat_history(FamilyID, ChannelType, DataRecord),
                ?IF(?IS_MAP_FAMILY_AS(RoleMap#r_role_map.map_id), mod_map_family_as:answer_question(Msg, Name, RoleMap#r_role_map.map_pname, RoleID), ok) end;
        ChannelType =:= ?CHAT_CHANNEL_TEAM ->  % 组队频道
            ChatName = "",
            ChatLang = ?CHAT_TEAM_LANG,
            Fun = fun() ->
                case mod_role_ban:is_chat_ban(RoleID) of
                    true ->
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary);
                    _ ->
                        common_broadcast:bc_role_info_to_team(TeamID, {mod, ?MODULE, {chat_info, RoleID, DataRecord}})
                end end;
        ChannelType =:= ?CHAT_CHANNEL_WORLD ->   % 世界频道 注意 加入等级限制
            ChatName = "",
            ChatLang = ?CHAT_WORLD_LANG,
            [Config] = lib_config:find(cfg_global, ?GLOBAL_WORLD_CHAT_LEVEL),
            ChatLevel = Config#c_global.int,
            ?IF(RoleLevel < ChatLevel, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL), ok), % 服务端加入对世界频道发言的等级限制
            Fun = fun() ->
                case mod_role_ban:is_chat_ban(RoleID) of
                    true ->
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary);
                    _ ->
                        common_broadcast:bc_role_info_to_world({mod, ?MODULE, {chat_info, RoleID, DataRecord}})
                end,
                world_chat_history_server:add_chat_history(ChannelType, ChannelType, DataRecord) end;
        ChannelType =:= ?CHAT_CHANNEL_CROSS_AREA -> %% 区域频道
            ChatName = "",
            ChatLang = ?CHAT_AREA_LANG,
            Fun = fun() ->
                case mod_role_ban:is_chat_ban(RoleID) of
                    true ->
                        Binary = {binary, gateway_packet:packet(DataRecord)},
                        pname_server:send(mod_role_dict:get_gateway_pid(), Binary);
                    _ ->
                        node_misc:game_send_mfa_to_cross({common_broadcast, bc_role_info_to_area, [{mod, ?MODULE, {chat_info, RoleID, DataRecord}}]})
                end end
    end,
    LogMsg = ?IF(VoiceSec > 0, VoiceURL, unicode:characters_to_binary(Msg)),
    Log = #log_chat{
        role_id = RoleID,
        role_name = unicode:characters_to_binary(Name),
        chat_type = ChannelType,
        chat_id = ChannelID,
        chat_name = unicode:characters_to_binary(ChatName),
        msg = LogMsg,
        channel_id = PFChannelID,
        game_channel_id = PFGameChannelID
    },
    PFChat = #r_pf_chat_args{
        channel_type = ChannelType,
        channel_lang = ChatLang,
        receiver = ChannelID,
        receiver_name = ?IF(ChannelType =:= ?CHAT_CHANNEL_PRIVATE, ChatName, ""),
        msg_type = ?IF(VoiceSec > 0, ?SQ_CHAT_VOICE, ?SQ_CHAT_TEXT),
        msg = LogMsg
    },
    {ok, Log, Fun, PFChat}.

do_chat_pos(RoleID, DataIn, State) ->
    case catch check_chat_pos(RoleID, DataIn, State) of
        {ok, Fun} ->
            Fun(),
            mod_role_dict:add_key_time(?MODULE, ?HALF_SECOND_MS),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_chat_text_toc{err_code = ErrCode})
    end.

check_chat_pos(RoleID, DataIn, State) ->
    mod_role_dict:is_time_able(?MODULE),
    #r_role{role_attr = RoleAttr, role_map = RoleMap} = State,
    #m_chat_pos_tos{channel_type = ChannelType, channel_id = ChannelID, pos = Pos} = DataIn,
    ChatRole = get_p_chat_role(State),
    DataRecord = #m_chat_pos_toc{
        channel_type = ChannelType,
        channel_id = ChannelID,
        role_info = ChatRole,
        pos = Pos,
        map_id = RoleMap#r_role_map.map_id,
        time = time_tool:now()},
%%    Bin = gateway_packet:packet(DataRecord),
%%    Binary = {binary, Bin},
%%    Bin2 = gateway_packet:packet(DataRecord#m_chat_pos_toc{channel_id = RoleID}),
%%    Binary2 = {binary, Bin2},
    DataRecord2 = DataRecord#m_chat_pos_toc{channel_id = RoleID},
    Fun = check_common_chat(RoleAttr, ChannelType, ChannelID, DataRecord, DataRecord2),
    {ok, Fun}.

check_common_chat(RoleAttr, ChannelType, ChannelID, DataRecord, DataRecord2) ->
    #r_role_attr{role_id = RoleID, family_id = FamilyID, team_id = TeamID} = RoleAttr,
    if
        ChannelType =:= ?CHAT_CHANNEL_PRIVATE ->
%%            ?IF(role_misc:is_online(ChannelID), ok, ?THROW_ERR(?ERROR_CHAT_TEXT_001)),
            ?IF(world_friend_server:is_black(RoleID, ChannelID), ?THROW_ERR(?ERROR_CHAT_TEXT_003), ok),
            ?IF(world_friend_server:is_black(ChannelID, RoleID), ?THROW_ERR(?ERROR_CHAT_TEXT_004), ok),
            fun() ->
                ?IF(role_misc:is_online(ChannelID), role_misc:info_role(ChannelID, {mod, ?MODULE, {chat_info, RoleID, DataRecord2}}),
                    world_chat_history_server:add_chat_history(ChannelID, ?CHAT_CHANNEL_PRIVATE, DataRecord2)),
                world_friend_server:add_chat(RoleID, ChannelID),
                world_chat_history_server:add_chat_history(RoleID, ?CHAT_CHANNEL_PRIVATE, DataRecord),
                Binary = {binary, gateway_packet:packet(DataRecord)},
                pname_server:send(mod_role_dict:get_gateway_pid(), Binary)
            end;
        ChannelType =:= ?CHAT_CHANNEL_FAMILY ->
            fun() ->
                world_chat_history_server:add_chat_history(FamilyID, ChannelType, DataRecord),
                common_broadcast:bc_role_info_to_family(FamilyID, {mod, ?MODULE, {chat_info, RoleID, DataRecord}}) end;
        ChannelType =:= ?CHAT_CHANNEL_TEAM ->
            fun() -> common_broadcast:bc_role_info_to_team(TeamID, {mod, ?MODULE, {chat_info, RoleID, DataRecord}}) end;
        ChannelType =:= ?CHAT_CHANNEL_WORLD ->
            fun() ->
                world_chat_history_server:add_chat_history(ChannelType, ChannelType, DataRecord),
                common_broadcast:bc_role_info_to_world({mod, ?MODULE, {chat_info, RoleID, DataRecord}}) end;
        ChannelType =:= ?CHAT_CHANNEL_CROSS_AREA ->
            fun() -> node_misc:game_send_mfa_to_cross({common_broadcast, bc_role_info_to_area, [{mod, ?MODULE, {chat_info, RoleID, DataRecord}}]}) end
    end.

do_chat_area_ban_add(RoleID, AddRoleID, State) ->
    case catch check_area_ban_add(AddRoleID, State) of
        {ok, BanChatRole, State2} ->
            common_misc:unicast(RoleID, #m_chat_area_ban_add_toc{add_role_info = BanChatRole}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_chat_area_ban_add_toc{err_code = ErrCode}),
            State
    end.

check_area_ban_add(AddRoleID, State) ->

    case db:lookup(?DB_ROLE_ATTR_P, AddRoleID) of
        [_RoleAttr] ->
            ?THROW_ERR(?ERROR_CHAT_AREA_BAN_ADD_001);
        _ ->
            ok
    end,
    RoleList = mod_role_extra:get_data(?EXTRA_KEY_CHAT_AREA_BAN, [], State),
    ?IF(lists:member(AddRoleID, RoleList), ?THROW_ERR(?ERROR_CHAT_AREA_BAN_ADD_002), ok),
    ?IF(erlang:length(RoleList) < 50, ok, ?THROW_ERR(?ERROR_CHAT_AREA_BAN_ADD_003)),
    case cross_role_data_server:get_role_cross_data(AddRoleID) of
        #r_role_cross_data{} = RoleCrossData ->
            State2 = mod_role_extra:set_data(?EXTRA_KEY_CHAT_AREA_BAN, [AddRoleID|RoleList], State),
            {ok, cross_data_trans_to_p_chat(RoleCrossData), State2};
        _ ->
            ?THROW_ERR(?ERROR_CHAT_AREA_BAN_ADD_004)
    end.

do_chat_area_ban_del(RoleID, DelRoleID, State) ->
    case catch check_area_ban_del(DelRoleID, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_chat_area_ban_del_toc{del_role_id = DelRoleID}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_chat_area_ban_del_toc{err_code = ErrCode}),
            State
    end.

check_area_ban_del(DelRoleID, State) ->
    RoleList = mod_role_extra:get_data(?EXTRA_KEY_CHAT_AREA_BAN, [], State),
    RoleList2 =
        case DelRoleID of
            0 ->
                [];
            _ ->
                ?IF(lists:member(DelRoleID, RoleList), ok, ?THROW_ERR(?ERROR_CHAT_AREA_BAN_DEL_001)),
                lists:delete(DelRoleID, RoleList)
        end,
    State2 = mod_role_extra:set_data(?EXTRA_KEY_CHAT_AREA_BAN, RoleList2, State),
    {ok, State2}.

get_p_chat_role(State) ->
    get_p_chat_role(?CHANNEL_WORLD, State).
get_p_chat_role(ChannelType, #r_role_attr{
    role_id = RoleID,
    role_name = RoleName,
    sex = Sex,
    level = Level,
    category = Category}) ->
    #p_chat_role{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        vip_level = common_role_data:get_role_vip_level(RoleID),
        server_name = ?IF(ChannelType =:= ?CHAT_CHANNEL_CROSS_AREA, common_config:get_server_name(), ""),
        skin_list = mod_role_fashion:get_chat_skin2(common_role_data:get_cur_id_list(RoleID))};
get_p_chat_role(ChannelType, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category} = RoleAttr,
    #p_chat_role{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        vip_level = mod_role_vip:get_vip_level(State),
        server_name = ?IF(ChannelType =:= ?CHAT_CHANNEL_CROSS_AREA, common_config:get_server_name(), ""),
        skin_list = mod_role_fashion:get_chat_skin(State)}.

cross_data_trans_to_p_chat(RoleCrossData) ->
    #r_role_cross_data{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        vip_level = VipLevel,
        server_name = ServerName,
        skin_list = SkinList} = RoleCrossData,
    #p_chat_role{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        vip_level = VipLevel,
        server_name = ServerName,
        skin_list = mod_role_fashion:get_chat_skin2(SkinList)}.

%%
word_replace(Msg) ->
    case lib_config:find(cfg_word_check, word_check) of
        [WordList] ->
            FilterWords = world_data:get_filter_words(),
            word_replace2(Msg, FilterWords ++ WordList);
        _ ->
            Msg
    end.

%% [0-9] (48~57) [a-z] (97~122) [A-Z] (65~90)   [①-⑨] (9312~9320) [壹-玖]CHAT_LIST  # 35 [一 - 九] ()
check_word_recursion(Msg)->
    lists:foldl(fun(Word, Acc) ->
        case (Word >= 48 andalso Word =< 57) orelse (Word >= 97 andalso Word =< 122) orelse (Word >= 65 andalso Word =< 90)
            orelse (Word >= 9312 andalso Word =< 9320) orelse lists:member(Word, ?CHAT_LIST) orelse lists:member(Word, ?CHAT_LIST2) of
            true ->
                Acc + 1;
            _ ->
                ?IF(Word =:= 35, - 2, 0)
        end end, 0, Msg).

check_word(Msg) ->
    Length = check_word_recursion(Msg),
    ?IF(Length >= 5, string:chars($*, erlang:length(Msg)), Msg).

word_replace2(Msg, []) ->
    Msg;
word_replace2(Msg, [Word|R]) ->
    case catch re:replace(Msg, Word, "*", [unicode, global]) of
        Msg2 when erlang:is_list(Msg2) ->
            word_replace2(Msg2, R);
        _ ->
            word_replace2(Msg, R)
    end.

check_ban_word(RoleID, ReplaceMsg) ->
    case mod_role_ban:is_chat_ban(RoleID) of
        true -> %% 已经被禁言了，就不再写
            ok;
        _ ->
            BanWords = world_data:get_ban_words(),
            case lists:keyfind(ReplaceMsg, #r_ban_word.ban_word, BanWords) of
                #r_ban_word{ban_time = BanTime} ->
                    mod_role_ban:add_ban(RoleID, ?BAN_TYPE_CHAT, time_tool:now() + BanTime),
                    mod_web_role:ban_chat(RoleID, BanTime),
                    ok;
                _ ->
                    ok
            end
    end.

%% 后台聊天设置检测
check_ban_chat_config(ChannelType, State) ->
    List = mod_web_chat:get_chat_config(?CHAT_BAN_CHAT_CONFIG),
    case List of
        [_|_] ->
            OpenDay = common_config:get_open_days(),
            #r_role{role_attr = #r_role_attr{level = RoleLevel, game_channel_id = GameChannelID}} = State,
            VipLevel = mod_role_vip:get_vip_level(State),
            check_ban_chat_config2(List, ChannelType, OpenDay, RoleLevel, VipLevel, GameChannelID),
            ok;
        _ ->
            []
    end,
    ok.

check_ban_chat_config2([], _ChannelType, _OpenDay, _RoleLevel, _VipLevel, _GameChannelID) ->
    ok;
check_ban_chat_config2([ChatConfig|R], ChannelType, OpenDay, RoleLevel, VipLevel, GameChannelID) ->
    #r_ban_chat_config{
        min_open_day = NeedOpenDay1,
        max_open_day = NeedOpenDay2,
        channel_list = NeedChannelList,
        role_level = NeedRoleLevel,
        vip_level = NeedVipLevel,
        game_channel_id_list = NeedGameChannelList
    } = ChatConfig,
    case NeedOpenDay1 =< OpenDay andalso OpenDay =< NeedOpenDay2 andalso lists:member(ChannelType, NeedChannelList) andalso lists:member(GameChannelID, NeedGameChannelList)
        andalso (NeedRoleLevel < RoleLevel) andalso VipLevel < NeedVipLevel of
        true ->
            ?THROW_ERR(?ERROR_CHAT_TEXT_007);
        _ ->
            check_ban_chat_config2(R, ChannelType, OpenDay, RoleLevel, VipLevel, GameChannelID)
    end.

do_check_chat_ban(DataIn, State) ->
    #m_chat_text_tos{
        channel_type = ChannelType,
        voice_sec = VoiceSec,
        msg = Msg} = DataIn,
    case VoiceSec > 0 of
        true ->
            State;
        _ ->
            TextList = mod_role_extra:get_data(?EXTRA_KEY_CHAT_MSG, [], State),
            Now = time_tool:now(),
            BanText = #r_ban_chat_text{
                time = Now,
                type = ChannelType,
                msg = Msg
            },
            TextList2 = lists:sublist([BanText|TextList], ?MAX_CHAT_LEN),
            case catch do_check_chat_ban2(TextList2, Now, State) of
                ok ->
                    ok;
                Error ->
                    ?ERROR_MSG("check ban Error : ~w", [Error])
            end,
            mod_role_extra:set_data(?EXTRA_KEY_CHAT_MSG, TextList2, State)
    end.

%% 聊天封禁检查
do_check_chat_ban2(TextList, Now, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = RolePrivateAttr, role_pay = #r_role_pay{total_pay_fee = TotalPayFee}} = State,
    #r_role_private_attr{
        imei = IMEI,
        last_login_ip = IP
    } = RolePrivateAttr,
    VipLevel = mod_role_vip:get_vip_level(State),
    #r_role_attr{
        level = RoleLevel,
        game_channel_id = GameChannelID
    } = RoleAttr,
    ChatBan = world_data:get_chat_ban(),
    RoleArgs = {RoleID, IMEI, IP},
    check_chat_ban_key_word(mod_web_chat:get_chat_config(?CHAT_BAN_KEY_WORD, ChatBan, []), TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID),
    check_chat_ban_series(mod_web_chat:get_chat_config(?CHAT_BAN_SERIES, ChatBan, []), TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID),
    TextList2 = [ ChatText || #r_ban_chat_text{type = ChannelType} = ChatText <- TextList, ChannelType =:= ?CHAT_CHANNEL_PRIVATE],
    check_chat_private(mod_web_chat:get_chat_config(?CHAT_BAN_PRIVATE, ChatBan, []), TextList2, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID),
    ok.

check_chat_ban_key_word([], _TextList, _RoleArgs, _Now, _RoleLevel, _VipLevel, _TotalPayFee, _GameChannelID) ->
    ok;
check_chat_ban_key_word([KeyWordConfig|R], TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID) ->
    #r_ban_key_word{
        title = NeedTitle,
        is_ban_role = IsBanRole,
        is_ban_imei = IsBanIMEI,
        is_ban_ip = IsBanIP,
        time_duration = TimeDuration,
        times = Times,
        pay_fee = PayFee,
        vip_level = NeedVipLevel,
        game_channel_id_list = GameChannelIDList
    } = KeyWordConfig,
    case TotalPayFee < PayFee andalso VipLevel < NeedVipLevel andalso lists:member(GameChannelID, GameChannelIDList) of
        true ->
            case catch check_chat_ban_key_word2(TextList, NeedTitle, Now, TimeDuration, Times, 0) of
                {ban, Text} ->
                    ?WARNING_MSG("ban key_word :~w", [{Text, IsBanRole, IsBanIMEI, IsBanIP}]),
                    BanList = get_ban_list(IsBanRole, IsBanIMEI, IsBanIP),
                    do_upload_ban(RoleArgs, Text, ?BAN_TYPE_NORMAL, 0, ?BAN_SUB_TYPE_KEY_WORD, true, BanList);
                _ ->
                    check_chat_ban_key_word(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
            end;
        _ ->
            check_chat_ban_key_word(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
    end.

check_chat_ban_key_word2([], _NeedTitle, _Now, _TimeDuration, _Times, _TimesAcc) ->
    ok;
check_chat_ban_key_word2([ChatText|R], NeedTitle, Now, TimeDuration, Times, TimesAcc) ->
    #r_ban_chat_text{
        time = Time,
        msg = Msg
    } = ChatText,
    case Now - TimeDuration < Time of
        true ->
            case catch re:run(Msg, NeedTitle, [unicode]) of
                {match, _} ->
                    TimesAcc2 = TimesAcc + 1,
                    case TimesAcc2 >= Times of
                        true ->
                            erlang:throw({ban, Msg});
                        _ ->
                            check_chat_ban_key_word2(R, NeedTitle, Now, TimeDuration, Times, TimesAcc2)
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

%% 连续发言
check_chat_ban_series([], _TextList, _RoleArgs, _Now, _RoleLevel, _VipLevel, _TotalPayFee, _GameChannelID) ->
    ok;
check_chat_ban_series([KeyWordConfig|R], TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID) ->
    #r_ban_series{
        time_duration = TimeDuration,
        times = Times,
        ban_time = BanTime,
        pay_fee = PayFee,
        vip_level = NeedVipLevel,
        game_channel_id_list = GameChannelIDList
    } = KeyWordConfig,
    case TotalPayFee < PayFee andalso VipLevel < NeedVipLevel andalso lists:member(GameChannelID, GameChannelIDList) of
        true ->
            case catch check_chat_ban_series2(TextList, Now, TimeDuration, Times, 0) of
                {ban, Text} ->
                    ?WARNING_MSG("ban series :~w", [Text]),
                    BanEndTime = Now + BanTime,
                    do_upload_ban(RoleArgs, Text, ?BAN_TYPE_TALK, BanEndTime, 0, false, [{?BAN_WORD, BanEndTime}]);
                _ ->
                    check_chat_ban_series(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
            end;
        _ ->
            check_chat_ban_series(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
    end.

check_chat_ban_series2([], _Now, _TimeDuration, _Times, _TimesAcc) ->
    ok;
check_chat_ban_series2([_ChatText], _Now, _TimeDuration, _Times, _TimesAcc) ->
    ok;
check_chat_ban_series2([ChatText1, ChatText2|R], Now, TimeDuration, Times, TimesAcc) ->
    #r_ban_chat_text{
        time = Time1,
        msg = Msg1
    } = ChatText1,
    #r_ban_chat_text{
        time = Time2,
        msg = Msg2
    } = ChatText2,
    case Now - TimeDuration < Time1 andalso Now - TimeDuration < Time2 andalso Msg1 =:= Msg2 of
        true ->
            TimesAcc2 = TimesAcc + 1,
            case TimesAcc2 >= Times of
                true ->
                    erlang:throw({ban, Msg1});
                _ ->
                    check_chat_ban_series2(R, Now, TimeDuration, Times, TimesAcc2 + 1)
            end;
        _ ->
            ok
    end.

%% 个人私聊
check_chat_private([], _TextList, _RoleArgs, _Now, _RoleLevel, _VipLevel, _TotalPayFee, _GameChannelID) ->
    ok;
check_chat_private([KeyWordConfig|R], TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID) ->
    #r_ban_private{
        is_ban_role = IsBanRole,
        is_ban_imei = IsBanIMEI,
        is_ban_ip = IsBanIP,
        time_duration = TimeDuration,
        times = Times,
        pay_fee = PayFee,
        vip_level = NeedVipLevel,
        game_channel_id_list = GameChannelIDList
    } = KeyWordConfig,
    case TotalPayFee < PayFee andalso VipLevel < NeedVipLevel andalso lists:member(GameChannelID, GameChannelIDList) of
        true ->
            case catch check_chat_private2(TextList, Now, TimeDuration, Times, 0) of
                {ban, Text} ->
                    ?WARNING_MSG("ban private :~w", [{Text, IsBanRole, IsBanIMEI, IsBanIP}]),
                    BanList = get_ban_list(IsBanRole, IsBanIMEI, IsBanIP),
                    do_upload_ban(RoleArgs, Text, ?BAN_TYPE_NORMAL, 0, ?BAN_SUB_TYPE_PRIVATE, true, BanList);
                _ ->
                    check_chat_private(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
            end;
        _ ->
            check_chat_private(R, TextList, RoleArgs, Now, RoleLevel, VipLevel, TotalPayFee, GameChannelID)
    end.

check_chat_private2([], _Now, _TimeDuration, _Times, _TimesAcc) ->
    ok;
check_chat_private2([_ChatText], _Now, _TimeDuration, _Times, _TimesAcc) ->
    ok;
check_chat_private2([ChatText1, ChatText2|R], Now, TimeDuration, Times, TimesAcc) ->
    #r_ban_chat_text{
        time = Time1,
        msg = Msg1
    } = ChatText1,
    #r_ban_chat_text{
        time = Time2,
        msg = Msg2
    } = ChatText2,
    case Now - TimeDuration < Time1 andalso Now - TimeDuration < Time2 andalso Msg1 =:= Msg2 of
        true ->
            TimesAcc2 = TimesAcc + 1,
            case TimesAcc2 >= Times of
                true ->
                    erlang:throw({ban, Msg1});
                _ ->
                    check_chat_private2(R, Now, TimeDuration, Times, TimesAcc2 + 1)
            end;
        _ ->
            ok
    end.

%% 上传封禁信息，并且设置对应状态
do_upload_ban(RoleArgs, Talk, BanType, EndTime, Type, IsKickRole, BanList) ->
    {RoleID, IMEI, IP} = RoleArgs,
    URL = web_misc:get_web_url(chat_upload_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    SealString = get_seal_list(BanList),
    Body =
        [
            {role_id, RoleID},
            {talk, unicode:characters_to_binary(Talk)},
            {ban_type, BanType},
            {end_time, EndTime},
            {time, Time},
            {ticket, Ticket},
            {type, Type},
            {imei, IMEI},
            {ip, IP},
            {agent_id, common_config:get_agent_id()},
            {server_id, common_config:get_server_id()},
            {seal, SealString}
        ],
    case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                    [ begin
                          case BanRoleType of
                              ?BAN_WORD ->
                                  mod_role_ban:add_ban(RoleID, ?BAN_TYPE_CHAT, BanEndTime);
                              ?BAN_ROLE ->
                                  mod_role_ban:add_ban(RoleID, ?BAN_TYPE_LOGIN, BanEndTime);
                              ?BAN_IP ->
                                  BanIPs = world_data:get_ban_ips(),
                                  BanIPs2 = lists:keystore(IP, 1, BanIPs, {IP, EndTime}),
                                  world_data:set_ban_ips(BanIPs2);
                              ?BAN_IMEI ->
                                  BanIMEIs = world_data:get_ban_imei(),
                                  BanIMEIs2 = lists:keystore(IMEI, 1, BanIMEIs, {IMEI, EndTime}),
                                  world_data:set_ban_imei(BanIMEIs2)
                          end
                      end|| {BanRoleType, BanEndTime} <- BanList],
                    ?IF(IsKickRole, role_misc:kick_role(RoleID, ?ERROR_SYSTEM_ERROR_026), ok);
                _ ->
                    ?WARNING_MSG("Body:~s, Code:~p", [lib_json:to_json(Body), Code])
            end;
        Error ->
            ?ERROR_MSG("Error:~p", [Error]),
            ok
    end.

get_ban_list(IsBanRole, IsBanIMEI, IsBanIP) ->
    List1 = ?IF(IsBanRole, [{?BAN_ROLE, 0}], []),
    List2 = ?IF(IsBanIMEI, [{?BAN_IMEI, 0}|List1], List1),
    ?IF(IsBanIP, [{?BAN_IP, 0}|List2], List2).

get_seal_list(BanList) ->
    List = lists:flatten(
        [begin
             case BanRoleType of
                 ?BAN_ROLE ->
                     1;
                 ?BAN_IP ->
                     2;
                 ?BAN_IMEI ->
                     3;
                 ?BAN_WORD ->
                     4;
                 _ ->
                     []
             end
         end || {BanRoleType, _BanEndTime} <- BanList ]),
    common_misc:get_list_string(List).

trim_specail_char(String) ->
    [Value || Value <- String, not lists:member(Value, [38, 32, 59254, 12288, 59269, 59410, 9, 10, 13])].
