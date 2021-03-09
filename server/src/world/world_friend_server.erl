%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 好友
%%% @end
%%% Created : 29. 七月 2017 12:02
%%%-------------------------------------------------------------------
-module(world_friend_server).
-author("laijichang").

-behaviour(gen_server).
-include("global.hrl").
-include("friend.hrl").
-include("marry.hrl").
-include("proto/mod_role_friend.hrl").
-include("proto/world_friend_server.hrl").

%% API
-export([start/0, start_link/0]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    get_role_info/1,
    add_chat/2,
    gm_friend_request/2,

    add_friendly/2,
    is_friend/2,
    is_black/2,
    is_chat/2,
    is_couple_friendly/3
]).

-export([
    get_friendly_config/1
]).


start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

add_chat(RoleID1, RoleID2) ->
    pname_server:send(?MODULE, {add_chat, RoleID1, RoleID2}).

gm_friend_request(RoleID, AddNum) ->
    pname_server:send(?MODULE, {gm_friend_request, RoleID, AddNum}).

%% [{RoleID1, RoleID2}|....]
add_friendly([], _AddFriendly) ->
    ok;
add_friendly(RoleList, AddFriendly) ->
    pname_server:send(?MODULE, {add_friendly, RoleList, AddFriendly}).

%% @doc 是否好友
is_friend(RoleID, DestRoleID) ->
    #r_world_friend{friend_list = FriendList} = get_role_info(RoleID),
    lists:keymember(DestRoleID, #r_friend.role_id, FriendList).

%% @doc 是否在黑名单里
is_black(RoleID, DestRoleID) ->
    #r_world_friend{black_list = BlackList} = get_role_info(RoleID),
    lists:member(DestRoleID, BlackList).

is_chat(RoleID, DestRoleID) ->
    #r_world_friend{chat_list = ChatList} = get_role_info(RoleID),
    lists:member(DestRoleID, ChatList).

is_couple_friendly(RoleID, DestRoleID, NeedFriendly) ->
    #r_world_friend{friend_list = FriendList} = get_role_info(RoleID),
    case lists:keyfind(DestRoleID, #r_friend.role_id, FriendList) of
        #r_friend{friendly = Friendly} ->
            Friendly >= NeedFriendly;
        _ ->
            false
    end.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({#m_friend_add_tos{role_id = FriendID}, RoleID, _PID}) ->
    do_friend_add(RoleID, FriendID);
do_handle({#m_friend_del_tos{role_id = FriendID}, RoleID, _PID}) ->
    do_friend_del(RoleID, FriendID);
do_handle({#m_friend_request_del_tos{request_id = RequestID}, RoleID, _PID}) ->
    do_request_del(RoleID, RequestID);
do_handle({#m_friend_black_add_tos{black_id = BlackID}, RoleID, _PID}) ->
    do_black_add(RoleID, BlackID);
do_handle({#m_friend_black_del_tos{black_id = BlackID}, RoleID, _PID}) ->
    do_black_del(RoleID, BlackID);
do_handle({#m_friend_all_add_tos{choose = Choose}, RoleID, _PID}) ->
    do_all_add(Choose, RoleID);
do_handle({add_chat, RoleID1, RoleID2}) ->
    do_add_chat(RoleID1, RoleID2);
do_handle({add_friendly, RoleList, AddFriendly}) ->
    do_add_friendly(RoleList, AddFriendly);
do_handle({gm_friend_request, RoleID, AddNum}) ->
    do_gm_friend_request(RoleID, AddNum);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%% 加朋友呀~
do_friend_add(RoleID, FriendID) ->
    case catch check_friend_add(RoleID, FriendID) of
        {add_friend, RoleFriend, DestRoleFriend, PFriend, DestPFriend} ->
            set_role_info(RoleFriend),
            set_role_info(DestRoleFriend),
            common_misc:unicast(RoleID, #m_friend_add_toc{friend_info = PFriend}),
            common_misc:unicast(FriendID, #m_friend_add_toc{friend_info = DestPFriend}),
            notice_friend_update(RoleID),
            notice_friend_update(FriendID);
        {request, DestRoleFriend2} ->
            set_role_info(DestRoleFriend2),
            common_misc:unicast(FriendID, #m_friend_request_info_toc{request_info = mod_role_friend:trans_to_p_friend2(RoleID)});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_add_toc{err_code = ErrCode})
    end.

check_friend_add(RoleID, FriendID) ->
    case db:lookup(?DB_ROLE_ATTR_P, FriendID) of
        [#r_role_attr{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_FRIEND_ADD_001)
    end,
    #r_world_friend{friend_list = FriendList, black_list = BlackList, request_list = RequestList} = RoleFriend = get_role_info(RoleID),
    ?IF(erlang:length(FriendList) < ?MAX_FRIEND_NUM, ok, ?THROW_ERR(?ERROR_FRIEND_ADD_003)),
    ?IF(lists:keymember(FriendID, #r_friend.role_id, FriendList), ?THROW_ERR(?ERROR_FRIEND_ADD_002), ok),
    ?IF(lists:member(FriendID, BlackList), ?THROW_ERR(?ERROR_FRIEND_ADD_005), ok),
    ?IF(RoleID =:= FriendID, ?THROW_ERR(?ERROR_FRIEND_ADD_004), ok),
    #r_world_friend{friend_list = DestFriendList, request_list = DestRequestList, black_list = DestBlackList} = DestRoleFriend = get_role_info(FriendID),
    ?IF(lists:member(RoleID, DestRequestList), ?THROW_ERR(?ERROR_FRIEND_ADD_006), ok),
    ?IF(lists:member(RoleID, DestBlackList), ?THROW_ERR(?ERROR_FRIEND_ADD_007), ok),
    case lists:member(FriendID, RequestList) of
        true -> %% 对方已经在我的申请列表中，那么就互相添加好友
            MyFriend = #r_friend{role_id = FriendID, friendly = 1},
            DestFriend = #r_friend{role_id = RoleID, friendly = 1},
            RoleFriend2 = RoleFriend#r_world_friend{friend_list = [MyFriend|FriendList], request_list = lists:delete(FriendID, RequestList)},
            DestRoleFriend2 = DestRoleFriend#r_world_friend{friend_list = [DestFriend|DestFriendList]},
            PFriend = mod_role_friend:trans_to_p_friend2(MyFriend),
            DestPFriend = mod_role_friend:trans_to_p_friend2(DestFriend),
            {add_friend, RoleFriend2, DestRoleFriend2, PFriend, DestPFriend};
        _ ->
            DestRoleFriend2 = DestRoleFriend#r_world_friend{request_list = [RoleID|DestRequestList]},
            {request, DestRoleFriend2}
    end.

%% 删除好友 双向删除
do_friend_del(RoleID, FriendID) ->
    case catch check_friend_del(RoleID, FriendID) of
        {ok, RoleFriend, DestRoleFriend} ->
            set_role_info(RoleFriend),
            set_role_info(DestRoleFriend),
            common_misc:unicast(RoleID, #m_friend_del_toc{role_id = FriendID}),
            common_misc:unicast(FriendID, #m_friend_del_toc{role_id = RoleID}),
            notice_friend_update(RoleID),
            notice_friend_update(FriendID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_del_toc{err_code = ErrCode})
    end.

check_friend_del(RoleID, FriendID) ->
    #r_world_friend{friend_list = FriendList} = RoleFriend = get_role_info(RoleID),
    case lists:keytake(FriendID, #r_friend.role_id, FriendList) of
        {value, _Value, FriendList2} ->
            ok;
        _ ->
            FriendList2 = ?THROW_ERR(?ERROR_FRIEND_DEL_001)
    end,
    ?IF(marry_misc:is_couple(RoleID, FriendID), ?THROW_ERR(?ERROR_FRIEND_DEL_004), ok),
    ?IF(marry_misc:is_propose(RoleID, FriendID), ?THROW_ERR(?ERROR_FRIEND_DEL_005), ok),
    #r_world_friend{friend_list = DestFriendList} = DestRoleFriend = get_role_info(FriendID),
    DestFriendList2 = lists:keydelete(RoleID, #r_friend.role_id, DestFriendList),
    DestRoleFriend2 = DestRoleFriend#r_world_friend{friend_list = DestFriendList2},
    {ok, RoleFriend#r_world_friend{friend_list = FriendList2}, DestRoleFriend2}.


%% 删除申请人
do_request_del(RoleID, RequestID) ->
    #r_world_friend{request_list = RequestList} = RoleFriend = get_role_info(RoleID),
    set_role_info(RoleFriend#r_world_friend{request_list = lists:delete(RequestID, RequestList)}),
    common_misc:unicast(RoleID, #m_friend_request_del_toc{request_id = RequestID}),
    common_misc:unicast(RequestID, #m_friend_request_reject_toc{from_role_name = common_role_data:get_role_name(RoleID)}).


%% 将某个玩家拉入黑名单
do_black_add(RoleID, BlackID) ->
    case catch check_black_add(RoleID, BlackID) of
        {ok, RoleFriend, DestRoleFriend, IsFriend} ->
            set_role_info(RoleFriend),
            set_role_info(DestRoleFriend),
            common_misc:unicast(RoleID, #m_friend_black_add_toc{black_info = mod_role_friend:trans_to_p_friend2(BlackID)}),
            ?IF(IsFriend, common_misc:unicast(BlackID, #m_friend_del_toc{role_id = RoleID}), ok);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_black_add_toc{err_code = ErrCode})
    end.

check_black_add(RoleID, BlackID) ->
    #r_world_friend{friend_list = FriendList, request_list = RequestList, black_list = BlackList} = RoleFriend = get_role_info(RoleID),
    ?IF(RoleID =:= BlackID, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    ?IF(lists:member(BlackID, BlackList), ?THROW_ERR(?ERROR_FRIEND_BLACK_ADD_001), ok),
    ?IF(marry_misc:is_couple(RoleID, BlackID), ?THROW_ERR(?ERROR_FRIEND_BLACK_ADD_002), ok),
    ?IF(marry_misc:is_propose(RoleID, BlackID), ?THROW_ERR(?ERROR_FRIEND_BLACK_ADD_003), ok),
    case lists:keytake(BlackID, #r_friend.role_id, FriendList) of
        {value, #r_friend{}, FriendList2} ->
            IsFriend = true,
            BlackList2 = [BlackID|BlackList];
        _ ->
            IsFriend = false,
            BlackList2 = [BlackID|BlackList],
            FriendList2 = FriendList
    end,
    RoleFriend2 = RoleFriend#r_world_friend{friend_list = FriendList2, request_list = lists:delete(BlackID, RequestList), black_list = BlackList2},
    #r_world_friend{friend_list = DestFriendList} = DestRoleFriend = get_role_info(BlackID),
    DestFriendList2 = lists:keydelete(RoleID, #r_friend.role_id, DestFriendList),
    DestRoleFriend2 = DestRoleFriend#r_world_friend{friend_list = DestFriendList2},
    {ok, RoleFriend2, DestRoleFriend2, IsFriend}.

%% 将某个玩家从黑名单中移除
do_black_del(RoleID, BlackID) ->
    case catch check_black_del(RoleID, BlackID) of
        {ok, RoleFriend} ->
            set_role_info(RoleFriend),
            common_misc:unicast(RoleID, #m_friend_black_del_toc{black_id = BlackID});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_black_del_toc{err_code = ErrCode})
    end.

check_black_del(RoleID, BlackID) ->
    #r_world_friend{black_list = BlackList} = RoleFriend = get_role_info(RoleID),
    ?IF(lists:member(BlackID, BlackList), ok, ?THROW_ERR(?ERROR_FRIEND_BLACK_DEL_001)),
    {ok, RoleFriend#r_world_friend{black_list = lists:delete(BlackID, BlackList)}}.

do_add_chat(RoleID1, RoleID2) ->
    do_add_chat2(RoleID1, RoleID2),
    do_add_chat2(RoleID2, RoleID1).

do_add_chat2(RoleID, DestRoleID) ->
    #r_world_friend{chat_list = ChatList, friend_list = FriendList} = RoleFriend = get_role_info(RoleID),
    case lists:member(DestRoleID, ChatList) of
        true ->
            ChatList2 = [DestRoleID|lists:delete(DestRoleID, ChatList)];
        _ ->
            ChatList2 = [DestRoleID|ChatList],
            Friend = ?IF(is_friend(RoleID, DestRoleID), lists:keyfind(DestRoleID, #r_friend.role_id, FriendList), DestRoleID),
            common_misc:unicast(RoleID, #m_friend_chat_update_toc{friend_info = mod_role_friend:trans_to_p_friend2(Friend)})
    end,
    RoleFriend2 = RoleFriend#r_world_friend{chat_list = lists:sublist(ChatList2, ?PRIVATE_CHAT_NUM)},
    set_role_info(RoleFriend2).

do_add_friendly(RoleList, AddFriendly) ->
    [do_add_friendly(RoleID1, RoleID2, AddFriendly) || {RoleID1, RoleID2} <- RoleList].
do_add_friendly(RoleID1, RoleID2, AddFriendly) ->
    #r_world_friend{friend_list = FriendList} = RoleFriend1 = get_role_info(RoleID1),
    case lists:keytake(RoleID2, #r_friend.role_id, FriendList) of
        {value, #r_friend{friendly = Friendly} = Friend, FriendList2} ->
            Friendly2 = Friendly + AddFriendly,
            Friend2 = Friend#r_friend{friendly = Friendly2},
            FriendList3 = [Friend2|FriendList2],

            #r_world_friend{friend_list = OtherFriendList} = RoleFriend2 = get_role_info(RoleID2),
            {value, OtherFriend, OtherFriendList2} = lists:keytake(RoleID1, #r_friend.role_id, OtherFriendList),
            OtherFriend2 = OtherFriend#r_friend{friendly = Friendly2},
            OtherFriendList3 = [OtherFriend2|OtherFriendList2],
            set_role_info(RoleFriend1#r_world_friend{friend_list = FriendList3}),
            set_role_info(RoleFriend2#r_world_friend{friend_list = OtherFriendList3}),
            DataRecord = #m_friend_friendly_update_toc{friendly = Friendly2},
            common_misc:unicast(RoleID1, DataRecord#m_friend_friendly_update_toc{friend_id = RoleID2}),
            common_misc:unicast(RoleID2, DataRecord#m_friend_friendly_update_toc{friend_id = RoleID1}),
            #c_friendly_level{friendly_level = OldLevel} = get_friendly_config(Friendly),
            #c_friendly_level{friendly_level = NewLevel} = get_friendly_config(Friendly2),
            case OldLevel =/= NewLevel of
                true ->
                    role_misc:info_role(RoleID1, {mod, mod_role_friend, {friend_level_change, RoleID2}}),
                    role_misc:info_role(RoleID2, {mod, mod_role_friend, {friend_level_change, RoleID1}});
                _ ->
                    ok
            end,
            ?IF(marry_misc:is_couple(RoleID1, RoleID2), do_marry_add_friendly(RoleID1, RoleID2, Friendly, Friendly2), ok);
        _ ->
            ok
    end.

do_marry_add_friendly(RoleID1, RoleID2, Friendly, Friendly2) ->
    IsIDChange = is_marry_id_change(Friendly, Friendly2),
    case IsIDChange of
        true ->
            role_misc:info_role(RoleID1, {mod, mod_role_marry, marry_friendly_change}),
            role_misc:info_role(RoleID2, {mod, mod_role_marry, marry_friendly_change});
        _ ->
            ok
    end.

do_gm_friend_request(RoleID, AddNum) ->
    #r_world_friend{friend_list = FriendList, request_list = RequestList, black_list = BlackList} = RoleFriend = get_role_info(RoleID),
    AllRoleIDs = db_lib:all_keys(?DB_ROLE_ATTR_P),
    HasList = FriendList ++ RequestList ++ BlackList ++ [RoleID],
    AddRequestList = lists:sublist(AllRoleIDs -- HasList, AddNum),
    RequestList2 = AddRequestList ++ RequestList,
    set_role_info(RoleFriend#r_world_friend{request_list = RequestList2}),
    [ common_misc:unicast(RoleID, #m_friend_request_info_toc{request_info = mod_role_friend:trans_to_p_friend2(RequestRoleID)}) || RequestRoleID <- RequestList2].


notice_friend_update(RoleID) ->
    role_misc:info_role(RoleID, {mod, mod_role_friend, friend_update}).

%% @doc 一键操作
do_all_add(Choose, RoleID) ->
    case catch check_all_add(Choose, RoleID) of
        ok ->
            common_misc:unicast(RoleID, #m_friend_all_add_toc{choose = Choose});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_all_add_toc{err_code = ErrCode})
    end.

check_all_add(?REFUSE, RoleID) ->
    #r_world_friend{request_list = RequestList} = get_role_info(RoleID),
    ?IF(RequestList =/= [], ok, ?THROW_ERR(?ERROR_FRIEND_ALL_ADD_001)),
    lists:map(fun(RequestID) -> do_request_del(RoleID, RequestID) end, RequestList),
    ok;

check_all_add(?AGREE, RoleID) ->
    #r_world_friend{request_list = RequestList} = get_role_info(RoleID),
    ?IF(RequestList =/= [], ok, ?THROW_ERR(?ERROR_FRIEND_ALL_ADD_001)),
    lists:map(fun(FriendID) -> do_friend_add(RoleID, FriendID) end, RequestList),
    ok.


%%%===================================================================
%%% 数据操作
%%%===================================================================
get_friendly_config(Friendly) ->
    ConfigList = cfg_friendly_level:list(),
    get_friendly_config(ConfigList, Friendly, []).

get_friendly_config([], _Friendly, Config) ->
    Config;
get_friendly_config([{_Level, Config}|R], Friendly, ConfigAcc) ->
    #c_friendly_level{need_friendly = NeedFriendly} = Config,
    case Friendly >= NeedFriendly of
        true ->
            get_friendly_config(R, Friendly, Config);
        _ ->
            ConfigAcc
    end.

is_marry_id_change(Friendly, Friendly2) ->
    ConfigList = cfg_marry_title:list(),
    is_marry_id_change2(ConfigList, Friendly, Friendly2).

is_marry_id_change2([], _Friendly, _Friendly2) ->
    false;
is_marry_id_change2([{_ID, Config}|R], Friendly, Friendly2) ->
    #c_marry_title{friendly = ConfigFriendly} = Config,
    if
        Friendly2 < ConfigFriendly ->
            false;
        Friendly < ConfigFriendly andalso ConfigFriendly =< Friendly2 ->
            true;
        true ->
            is_marry_id_change2(R, Friendly, Friendly2)
    end.

set_role_info(RoleFriend) ->
    db:insert(?DB_WORLD_FRIEND_P, RoleFriend).
get_role_info(RoleID) ->
    case db:lookup(?DB_WORLD_FRIEND_P, RoleID) of
        [#r_world_friend{} = RoleFriend] ->
            RoleFriend;
        _ ->
            #r_world_friend{role_id = RoleID}
    end.



