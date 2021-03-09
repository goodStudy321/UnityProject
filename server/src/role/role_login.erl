%%%-------------------------------------------------------------------
%%% @doc
%%% 登录流程
%%% auth_key -》role_detail -》enter_map -》sure_enter_map
%%% @end
%%% Created : 13. 八月 2015 下午3:58
%%%-------------------------------------------------------------------
-module(role_login).
-include("proto/gateway.hrl").
-include("proto/role_login.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_extra.hrl").
-include("node.hrl").
-include("role.hrl").
-include("gateway.hrl").

%% API
-export([
    init_state/0,
    logout_role/0,
    is_waiting_for_enter/0,
    handle/2
]).

-export([
    notify_exit/1,
    log_role_status/1,
    log_role_status/2
]).

-export([
    check_role_name_valid/1
]).

init_state() ->
    mod_role_dict:set_login_state(?STATE_WAITING_FOR_AUTH).

is_waiting_for_enter() ->
    mod_role_dict:get_login_state() =:= ?STATE_WAITING_FOR_ENTER.

logout_role() ->
    login_server:logout_role({mod_role_dict:get_account_name(), self()}).

handle({#m_auth_key_tos{} = DataIn, _RoleID, _PID}, State)->
    do_auth_key(DataIn),
    State;
handle({#m_create_role_tos{} = DataIn, _RoleID, _PID}, State) ->
    do_create_role(DataIn),
    State;
handle({#m_del_role_tos{role_id = RoleID}, _RoleID, _PID}, State) ->
    ?ERROR_MSG("del role : ~w", [RoleID]),
    State;
handle({#m_select_role_tos{role_id = RoleID}, _RoleID, _PID}, State) ->
    do_select_role(RoleID, State);
handle({#m_role_reconnect_tos{} = DataIn, _RoleID, _PID}, State) ->
    do_role_reconnect(DataIn, State);
handle(notify_role_offline, State) ->
    notify_exit(?ERROR_SYSTEM_ERROR_021),
    State;
handle(notify_role_login, State) ->
    case mod_role_dict:get_login_state() of
        ?STATE_WAITING_FOR_AUTH ->
            do_auth_key3(),
            State;
        ?STATE_WAITING_FOR_RECONNECT -> %% 重连的时候，已经设置好RoleID了
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_role_reconnect_toc{}),
            erlang:send_after(1000, erlang:self(), {mod, ?MODULE, {reconnect_select_role, mod_role_dict:get_role_id()}}),
            State
    end;
handle({reconnect_select_role, RoleID}, _State) ->
    do_select_role2(RoleID);
handle(Info, State) ->
    ?ERROR_MSG("unknow info:~w", [Info]),
    State.

%% 第一步验证
do_auth_key(DataIn) ->
    case catch do_auth_key2(DataIn) of
        ok ->
            ok;
        {error, ErrCode} ->
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_auth_key_toc{err_code = ErrCode}),
            notify_exit(ErrCode);
        Error->
            ?ERROR_MSG("do_auth error ~w",[Error]),
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_auth_key_toc{err_code = ?ERROR_SYSTEM_ERROR_003}),
            notify_exit(?ERROR_SYSTEM_ERROR_004)
    end.

do_auth_key2(Record)->
    ?IF(mod_role_dict:get_login_state() =:= ?STATE_WAITING_FOR_AUTH, ok, ?THROW_ERR(?ERROR_AUTH_KEY_003)),
    ?IF(world_online_server:get_online_num() =< ?MAX_ONLINE_NUM, ok, ?THROW_ERR(?ERROR_AUTH_KEY_006)),
    #m_auth_key_tos{
        account_name = UID,
        key = Key,
        time = Time,
        server_id = ServerID,
        pf_args = PFArgs,
        device_args = DeviceArgs} = Record,
    ?WARNING_MSG("UID:~s", [UID]),
    {AccountName, ChannelID, GameChannelID} = mod_role_pf:get_pf_login_args(UID, PFArgs),
    %% 禁止空账号名登录
    ?IF(AccountName =/= <<"">>, ok, ?THROW_ERR(?ERROR_AUTH_KEY_001)),
    AgentID = common_config:get_agent_id(),
    NowServerID = common_config:get_server_id(),
    %% 判断区服是否合法
    ServerID2 =
        case common_config:is_merge() of
            true ->
                case node_data:get_merge_server(AgentID, ServerID) of
                    #r_merge_server{merge_server_id = MergeServerID} ->
                        ?IF(MergeServerID =:= NowServerID, ServerID, ?THROW_ERR(?ERROR_AUTH_KEY_002));
                    _ ->
                        ?IF(common_config:is_gm_open(), ServerID, ?THROW_ERR(?ERROR_AUTH_KEY_002))
                end;
            _ ->
                NowServerID
        end,
    %% 帐号名ServerID_ChannelID_UID
    AccountName2 = lib_tool:to_binary(lib_tool:concat([ServerID2, "_", lib_tool:to_list(AccountName)])),
    check_ticket(Time, Key),
    set_auth_dict(DeviceArgs, ServerID2, UID, AccountName2, ChannelID, GameChannelID),
    do_auth_key3().

do_auth_key3() ->
    Account = mod_role_dict:get_account_name(),
    %% 判断是否有角色
    case login_server:login_role({Account, erlang:self()}) of
        {ok, RoleIDList} ->
            mod_role_dict:set_login_state(?STATE_WAITING_FOR_SELECT),
            mod_role_dict:set_login_roles(RoleIDList),
            LoginRole = get_login_role(RoleIDList),
            case LoginRole =:= [] andalso (not world_data:is_create_able()) of %% 没有创建过角色，并且该区服不允许注册
                true ->
                    ?THROW_ERR(?ERROR_CREATE_ROLE_006);
                _ ->
                    DataRecord = #m_auth_key_toc{role_list = LoginRole, is_gm = common_config:is_gm_open()},
                    common_misc:unicast(mod_role_dict:get_gateway_pid(), DataRecord),
                    ?TRY_CATCH(mod_role_pf:account_login_log()),
                    ok
            end;
        ok -> %% 等待其他进程关闭
            ok;
        Error->
            ?INFO_MSG("LOGIN ROLE ERROR:~w",[Error]),
            ?THROW_ERR(?ERROR_SYSTEM_ERROR_003)
    end.

do_create_role(DataIn) ->
    #m_create_role_tos{
        name = Name,
        sex = Sex,
        category = Category
    } = DataIn,
    case catch do_create_role2(Name, Sex, Category) of
        {ok, AccountName, RoleID, RoleIDList} ->
            {ChannelID, GameChannelID} = mod_role_dict:get_game_chanel_id(),
            UID = mod_role_dict:get_uid(),
            RoleAttr = #r_role_attr{
                role_id = RoleID,
                role_name = Name,
                uid = UID,
                server_id = mod_role_dict:get_server_id(),
                account_name = AccountName,
                sex = Sex,
                category = Category,
                level = 1,
                exp = 0,
                channel_id = ChannelID,
                last_offline_time = time_tool:now(),
                game_channel_id = GameChannelID},
            PrivateAttr = #r_role_private_attr{
                role_id = RoleID,
                create_time = time_tool:now()},
            db:insert(?DB_ROLE_ATTR_P, RoleAttr),
            db:insert(?DB_ROLE_PRIVATE_ATTR_P, PrivateAttr),
            LoginRole = #p_login_role{
                role_id = RoleID,
                role_name = Name,
                level = 1,
                sex = Sex,
                category = Category,
                skin_list = [],
                ornament_list = []
            },
            ?TRY_CATCH(log_role_create(AccountName, UID, RoleID, RoleIDList, Sex, Category, Name, ChannelID, GameChannelID)),
            ?TRY_CATCH(mod_role_pf:create_role_log(RoleAttr), Err1),
            ?TRY_CATCH(world_pay_back_server:role_create(RoleID, GameChannelID, UID), Err2),
            ?TRY_CATCH(do_support_send(RoleIDList, UID, GameChannelID), Err3),
            mod_role_dict:set_login_roles([RoleID|mod_role_dict:get_login_roles()]),
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_create_role_toc{role = LoginRole});
        {error, ErrCode} when erlang:is_integer(ErrCode) ->
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_create_role_toc{err_code = ErrCode});
        Error->
            ?ERROR_MSG("do_auth error ~w",[Error]),
            notify_exit(?ERROR_SYSTEM_ERROR_004)
    end.

do_create_role2(Name, Sex, _Category) ->
    AccountName = mod_role_dict:get_account_name(),
    ?IF(mod_role_dict:get_login_state() =:= ?STATE_WAITING_FOR_SELECT, ok, ?THROW_ERR(?ERROR_AUTH_KEY_003)),
    check_role_name_valid(Name),
    if
        Sex =:= ?SEX_GIRL ->
            Category = ?CATEGORY_1;
        Sex =:= ?SEX_BOY ->
            Category = ?CATEGORY_2;
        true ->
            Category = ?THROW_ERR(?ERROR_CREATE_ROLE_002)
    end,
    mod_role_dict:set_create_info({Name, Sex, Category}),
    case login_server:create_role({AccountName, Name}) of
        {ok, RoleID, RoleIDList} ->
            {ok, AccountName, RoleID, RoleIDList};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_role_name_valid(Name) ->
    ?IF(Name =/= <<"">>, ok, ?THROW_ERR(?ERROR_CREATE_ROLE_001)),
    ?IF(erlang:length(Name) =< 8, ok, ?THROW_ERR(?ERROR_CREATE_ROLE_007)),
    common_misc:role_name_check(Name),
    case login_server:get_role_name(Name) of
        [#r_role_name{}] ->
            ?THROW_ERR(?ERROR_CREATE_ROLE_004);
        _ ->
            ok
    end.


%%do_del_role(RoleID) ->
%%    case catch do_del_role2(RoleID) of
%%        {ok, RoleIDList} ->
%%            mod_role_dict:set_login_roles(RoleIDList),
%%            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_del_role_toc{del_role_id = RoleID});
%%        {error, ErrCode} ->
%%            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_del_role_toc{err_code = ErrCode})
%%    end.
%%
%%do_del_role2(RoleID) ->
%%    AccountName = mod_role_dict:get_account_name(),
%%    ?IF(mod_role_dict:get_login_state() =:= ?STATE_WAITING_FOR_SELECT, ok, ?THROW_ERR(?ERROR_AUTH_KEY_003)),
%%    RoleIDList = mod_role_dict:get_login_roles(),
%%    ?IF(lists:member(RoleID, RoleIDList), ok, ?THROW_ERR(?ERROR_DEL_ROLE_001)),
%%    case login_server:del_role({AccountName, RoleID}) of
%%        ok ->
%%            {ok, lists:delete(RoleID, RoleIDList)};
%%        {error, ErrCode} ->
%%            {error, ErrCode}
%%    end.

do_select_role(RoleID, State) ->
    case catch check_select_role(RoleID) of
        ok ->
            do_select_role2(RoleID);
        {error, ErrCode} ->
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_select_role_toc{err_code = ErrCode}),
            State
    end.

check_select_role(RoleID) ->
    ?IF(mod_role_dict:get_login_state() =:= ?STATE_WAITING_FOR_SELECT, ok, ?THROW_ERR(?ERROR_AUTH_KEY_003)),
    ?IF(lists:member(RoleID, mod_role_dict:get_login_roles()), ok, ?THROW_ERR(?ERROR_SELECT_ROLE_001)),
    ?IF(mod_role_ban:is_login_ban(RoleID), ?THROW_ERR(?ERROR_SELECT_ROLE_002), ok),
    Now = time_tool:now(),
    ?IF(mod_role_ban:is_ip_ban(mod_role_dict:get_ip(), Now), ?THROW_ERR(?ERROR_SELECT_ROLE_003), ok),
    ?IF(mod_role_ban:is_imei_ban(mod_role_dict:get_imei(), Now), ?THROW_ERR(?ERROR_SELECT_ROLE_004), ok),
    ?IF(mod_role_ban:is_uid_ban(mod_role_dict:get_uid(), Now), ?THROW_ERR(?ERROR_SELECT_ROLE_005), ok),
    ok.

do_select_role2(RoleID) ->
    %% 进入下一步登录流程
    mod_role_dict:set_role_id(RoleID),
    GatewayPID = mod_role_dict:get_gateway_pid(),
    gateway_misc:send(GatewayPID, {set_role_id, RoleID}),
    case catch role_misc:register_name(RoleID) of
        true -> next;
        _ -> ?THROW_ERR(?ERROR_SYSTEM_ERROR_030)
    end,
    State = role_server:init_role_state(RoleID),
    State2 = mod_role_fight:calc_attr(State),
    State3 = mod_role_map:init_map(State2),
    mod_role_dict:set_login_state(?STATE_WAITING_FOR_ENTER),
    gateway_misc:role_level_and_game_channel_id(GatewayPID, mod_role_data:get_role_level(State3), mod_role_data:get_role_game_channel_id(State3)),
    common_misc:unicast(RoleID, #m_role_guide_toc{guide_id_list = State3#r_role.role_private_attr#r_role_private_attr.guide_id_list}),
    common_misc:unicast(RoleID, #m_server_info_toc{agent_id = common_config:get_agent_id(), server_id = common_config:get_server_id(),
        server_name = common_config:get_server_name()}),
    ?WARNING_MSG("test:~w", [RoleID]),
    State4 = role_server:pre_enter(State3),
    #r_role{
        role_attr = RoleAttr,
        role_map = RoleMap,
        role_private_attr = PrivateAttr,
        role_fight = RoleFight,
        calc_list = CalcList} = State4,
    RoleBase = mod_role_fight:make_role_base(RoleFight),
    RolePowers = mod_role_fight:make_role_powers(CalcList),
    R = #m_select_role_toc{
        map_id = RoleMap#r_role_map.map_id,
        role_data = trans_to_p_role_data(RoleID, RoleAttr, PrivateAttr, RoleBase, RolePowers)
    },
    common_misc:unicast(RoleID, R),
    ?TRY_CATCH(log_role_login(State4), Err1),
    ?TRY_CATCH(log_role_status(State4), Err2),
    ?TRY_CATCH(mod_role_pf:role_login_log(State4), Err3),
    State4.

do_role_reconnect(DataIn, State) ->
    case catch check_role_reconnect(DataIn, State) of
        {ok, RoleID, DeviceArgs, ServerID, UID, AccountName, ChannelID, GameChannelID} ->
            set_auth_dict(DeviceArgs, ServerID, UID, AccountName, ChannelID, GameChannelID),
            case catch login_server:login_role({AccountName, erlang:self()}) of
                {ok, _RoleIDList} ->
                    common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_role_reconnect_toc{}),
                    erlang:send_after(1000, erlang:self(), {mod, ?MODULE, {reconnect_select_role, RoleID}}),
                    State;
                ok -> %% 等待其他进程关闭
                    mod_role_dict:set_login_state(?STATE_WAITING_FOR_RECONNECT),
                    mod_role_dict:set_role_id(RoleID),
                    State;
                Error ->
                    ?ERROR_MSG("reconnect Error:~w", [Error]),
                    notify_exit(?ERROR_SYSTEM_ERROR_003),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(mod_role_dict:get_gateway_pid(), #m_role_reconnect_toc{err_code = ErrCode}),
            notify_exit(?ERROR_SYSTEM_ERROR_003),
            State
    end.

check_role_reconnect(DataIn, State) ->
    #m_role_reconnect_tos{
        role_id = RoleID,
        key = Key,
        time = Time,
        device_args = DeviceArgs
    } = DataIn,
    check_ticket(Time, Key),
    #r_role{role_id = StateRoleID} = State,
    ?IF(mod_role_ban:is_login_ban(RoleID), ?THROW_ERR(?ERROR_SELECT_ROLE_002), ok),
    Now = time_tool:now(),
    ?IF(mod_role_ban:is_ip_ban(mod_role_dict:get_ip(), Now), ?THROW_ERR(?ERROR_SELECT_ROLE_003), ok),
    case StateRoleID =/= undefined of
        true ->
            ?THROW_ERR(?ERROR_ROLE_RECONNECT_001);
        _ ->
            case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
                [RoleAttr] ->
                    #r_role_attr{
                        uid = UID,
                        account_name = AccountName,
                        channel_id = ChannelID,
                        game_channel_id = GameChannelID,
                        server_id = ServerID
                    } = RoleAttr,
                    [#r_role_private_attr{imei = IMEI}] = db:lookup(?DB_ROLE_PRIVATE_ATTR_P, RoleID),
                    ?IF(mod_role_ban:is_imei_ban(IMEI, Now), ?THROW_ERR(?ERROR_SELECT_ROLE_004), ok),
                    ?IF(mod_role_ban:is_uid_ban(UID, Now), ?THROW_ERR(?ERROR_SELECT_ROLE_005), ok),
                    {ok, RoleID, DeviceArgs, ServerID, UID, AccountName, ChannelID, GameChannelID};
                _ ->
                    ?THROW_ERR(?ERROR_ROLE_RECONNECT_002)
            end
    end.

%% 验证key
check_ticket(Time, Key) ->
    case common_config:is_debug() of
        true ->
            ok;
        _ ->
            Ticket = lib_tool:md5(?GATEWAY_AUTH_KEY ++ lib_tool:to_list(Time)),
            ?IF(Key =:= Ticket, ok, ?THROW_ERR(?ERROR_AUTH_KEY_004))
    end.

set_auth_dict(DeviceArgs, ServerID, UID, AccountName, ChannelID, GameChannelID) ->
    case DeviceArgs of
        [DeviceName, OsType, OsVer, NetType, IMEI, PackageName, Width, Height] ->
            mod_role_dict:set_imei(IMEI),
            DeviceArgs2 = #r_device{
                device_name = DeviceName,
                os_type = OsType,
                os_ver = OsVer,
                net_type = NetType,
                imei = IMEI,
                package_name = PackageName,
                width = lib_tool:to_integer(Width),
                height = lib_tool:to_integer(Height)
            };
        _ ->
            mod_role_dict:set_imei(""),
            DeviceArgs2 = #r_device{}
    end,
    mod_role_dict:set_device_args(DeviceArgs2),
    mod_role_dict:set_server_id(ServerID),
    mod_role_dict:set_uid(UID),
    mod_role_dict:set_account_name(AccountName),
    mod_role_dict:set_game_chanel_id({ChannelID, GameChannelID}).

trans_to_p_role_data(RoleID, RoleAttr, PrivateAttr, RoleBase, RolePowers) ->
    #r_role_attr{
        role_name = RoleName,
        sex = Sex,
        category = Category,
        level = Level,
        exp = Exp} = RoleAttr,
    #r_role_private_attr{
        offline_fight_time = OfflineFightTime,
        create_time = CreateTime,
        last_level_time = LastLevelTime
    } = PrivateAttr,
    #p_role_data{
        role_id = RoleID,
        attr = #p_role_attr{
            role_name = RoleName,
            sex = Sex,
            category = Category,
            level = Level,
            exp = Exp,
            create_time = CreateTime,
            last_level_time = LastLevelTime,
            offline_fight_time = OfflineFightTime},
        base = RoleBase,
        powers = RolePowers
    }.


notify_exit(ErrCode)->
    ?TRY_CATCH(gateway_misc:exit(mod_role_dict:get_gateway_pid(), ErrCode)).

get_login_role(RoleList) ->
    get_login_role2(RoleList, []).

get_login_role2([], Acc) ->
    [ LoginRole || {_LastOfflineTime, LoginRole} <- lists:reverse(lists:keysort(1, Acc))];
get_login_role2([RoleID|R], Acc) ->
    [RoleAttr] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
    #r_role_attr{
        role_name = RoleName,
        level = Level,
        sex = Sex,
        category = Category,
        skin_list = SkinList,
        ornament_list = OrnamentList,
        last_offline_time = LastOfflineTime
    } = RoleAttr,
    LoginRole = #p_login_role{
        role_id = RoleID,
        role_name = RoleName,
        level = Level,
        sex = Sex,
        category = Category,
        skin_list = SkinList,
        ornament_list = OrnamentList
    },
    get_login_role2(R, [{LastOfflineTime, LoginRole}|Acc]).

log_role_create(AccountName, UID, RoleID, RoleIDList, Sex, Category, Name, ChannelID, GameChannelID) ->
    IsOld =
        case catch center_create_server:report_create(common_config:get_agent_id(), common_config:get_server_id(), GameChannelID, UID) of
            {ok, IsOldT} ->
                IsOldT;
            _ ->
                ?IF(common_config:is_debug(), ok, ?ERROR_MSG("注册上报中心服出错:~w", [{common_config:get_agent_id(), GameChannelID, UID}])),
                ?FALSE
        end,
    LogList =
        case RoleIDList =:= [RoleID] of
            true -> %% 第一次创建
                AdminLog = #log_admin_account{
                    uid = UID,
                    channel_id = ChannelID,
                    game_channel_id = GameChannelID
                },
                ?IF(IsOld =:= ?TRUE, [AdminLog], [#log_account{uid = UID, channel_id = ChannelID, game_channel_id = GameChannelID}, AdminLog]);
            _ ->
                []
        end,
    Log = #log_role_create{
        account_name = AccountName,
        uid = UID,
        is_old = IsOld,
        role_id = RoleID,
        sex = Sex,
        category = Category,
        imei = mod_role_dict:get_imei(),
        ip = mod_role_dict:get_ip(),
        create_server_id = mod_role_dict:get_server_id(),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    Now = time_tool:now(),
    Log2 = #log_role_status{
        role_id = RoleID,
        uid = UID,
        account_name = AccountName,
        role_name = unicode:characters_to_binary(Name),
        role_level = 1,
        role_vip_level = 0,
        relive_level = 0,
        category = Category,
        power = 0,
        gold = 0,
        create_time = Now,
        last_login_time = Now,
        last_login_ip = mod_role_dict:get_ip(),
        map_id = map_misc:get_home_map_id(),
        mission_id = 0,
        mission_status = 0,
        is_online = 0,
        is_insider = 0,
        insider_time = 0,
        insider_gold = 0,
        confine_id = 0,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs([Log, Log2|LogList]).

log_role_login(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{
        level = Level,
        account_name = AccountName,
        uid = UID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #r_role_private_attr{
        imei = IMEI,
        last_login_ip = IP
    } = PrivateAttr,
    Log = #log_role_login{
        role_id = RoleID,
        account_name = AccountName,
        imei = IMEI,
        ip = IP,
        uid = UID,
        role_level = Level,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

log_role_status(State) ->
    log_role_status(State, true).
log_role_status(State, IsOnline) ->
    #r_role{
        role_id = RoleID,
        role_attr = RoleAttr,
        role_private_attr = PrivateAttr,
        role_map = RoleMap,
        role_relive = RoleRelive,
        role_asset = RoleAsset} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        uid = UID,
        account_name = AccountName,
        level = RoleLevel,
        category = Category,
        power = Power,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #r_role_relive{relive_level = ReliveLevel} = RoleRelive,
    #r_role_private_attr{
        create_time = CreateTime,
        last_login_time = LastLoginTime,
        last_login_ip = LastLoginIP,
        is_insider = IsInsider,
        insider_time = InsiderTime,
        insider_gold = InsiderGold
    } = PrivateAttr,
    #r_role_map{map_id = MapID} = RoleMap,
    #r_role_asset{gold = Gold, bind_gold = BindGold} = RoleAsset,
    {MissionID, MissionStatus} = mod_role_mission:get_main_mission_id_status(State),
    Log = #log_role_status{
        role_id = RoleID,
        role_name = unicode:characters_to_binary(RoleName),
        uid = UID,
        account_name = AccountName,
        role_level = RoleLevel,
        role_vip_level = mod_role_vip:get_vip_level(State),
        relive_level = ReliveLevel,
        category = Category,
        power = Power,
        gold = Gold,
        bind_gold = BindGold,
        create_time = CreateTime,
        last_login_time = LastLoginTime,
        last_login_ip = LastLoginIP,
        map_id = MapID,
        mission_id = MissionID,
        mission_status = MissionStatus,
        is_online = common_misc:get_bool_int(IsOnline),
        is_insider = common_misc:get_bool_int(IsInsider),
        insider_time = InsiderTime,
        insider_gold = InsiderGold,
        confine_id = mod_role_confine:get_confine_id(State),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

%% 第一个号发资源
do_support_send([RoleID], UID, GameChannelID) ->
    [ begin
          mod_role_insider:mark_insider(RoleID, true, time_tool:now()),
          common_misc:send_support_goods(RoleID, SupportInfo)
      end|| #r_web_support{uid_list = UIDList, game_channel_id = NeedGameChannelID} = SupportInfo <- world_data:get_support_info(),
        lists:member(UID, UIDList) andalso GameChannelID =:= NeedGameChannelID],
    ok;
do_support_send(_RoleIDList, _UID, _GameChannelID) ->
    ok.