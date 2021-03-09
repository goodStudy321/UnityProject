%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 七月 2017 12:02
%%%-------------------------------------------------------------------
-module(mod_role_friend).
-author("laijichang").
-include("team.hrl").
-include("role.hrl").
-include("friend.hrl").
-include("proto/mod_role_friend.hrl").


%% API
-export([
    online/1,
    offline/1,
    update/1,
    handle/2
]).

-export([
    get_friend_num/1,
    gm_add_friendly/2
]).

-export([
    member_change/2,
    do_add_friend_buff/1
]).

-export([
    trans_to_p_friend2/1
]).

online(State) ->
    #r_role{role_id = RoleID} = State,
    #r_world_friend{
        friend_list = FriendList,
        request_list = RequestList,
        black_list = BlackList,
        chat_list = ChatList} = world_friend_server:get_role_info(RoleID),

    NewChatList =
        lists:foldl(fun(FriendID, Acc) ->
            case lists:keyfind(FriendID, #r_friend.role_id, FriendList) of
                #r_friend{} = Friend ->
                    [Friend | Acc];
                _ ->
                    [FriendID | Acc]
            end end, [], ChatList),

    DataRecord = #m_friend_info_toc{
        friend_list = trans_to_p_friend(FriendList),
        request_list = trans_to_p_friend(RequestList),
        black_list = trans_to_p_friend(BlackList),
        chat_list = trans_to_p_friend(NewChatList)},

    common_misc:unicast(RoleID, DataRecord),
    do_update_is_online(RoleID, FriendList, BlackList, ChatList, true),
    State2 = do_add_friend_buff(State),
    State3 = do_friend_trigger(State2),
    do_friendly_level_trigger(State3).

offline(State) ->
    #r_role{role_id = RoleID} = State,
    #r_world_friend{friend_list = FriendList, black_list = BlackList, chat_list = ChatList} = world_friend_server:get_role_info(RoleID),
    do_update_is_online(RoleID, FriendList, BlackList, ChatList, false),
    State.

update(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_marry = RoleMarry} = State,
    #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID),
    RoleIDList1 = [FriendRoleID || #r_friend{role_id = FriendRoleID} <- FriendList],
    #r_role_marry{couple_id = CoupleID} = RoleMarry,
    DataRecord = #m_friend_info_update_toc{friend_info = trans_to_p_friend3(RoleAttr, mod_role_vip:get_vip_level(State), 0, CoupleID)},
    common_broadcast:bc_record_to_roles(lib_tool:list_filter_repeat(RoleIDList1), DataRecord),
    State.

handle({#m_friend_recommend_tos{}, RoleID, _PID}, State) ->
    do_friend_recommend(RoleID, State);
handle({#m_friend_search_tos{role_name = RoleName}, RoleID, _PID}, State) ->
    do_friend_search(RoleID, RoleName, State);
handle({friend_level_change, DestRoleID}, State) ->
    State2 = do_friend_level_change(DestRoleID, State),
    do_friendly_level_trigger(State2);
handle(friend_update, State) ->
    do_friend_trigger(State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

get_friend_num(State) ->
    #r_role{role_id = RoleID} = State,
    #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID),
    erlang:length(FriendList).

gm_add_friendly(AddFriendly, State) ->
    #r_role{role_id = RoleID} = State,
    #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID),
    AddList = [ {RoleID, FriendID} || #r_friend{role_id = FriendID} <- FriendList],
    world_friend_server:add_friendly(AddList, AddFriendly),
    State.

%% 队伍里的成员发生变化
member_change(ChangeRoleID, State) ->
    #r_role{role_id = RoleID} = State,
    case world_friend_server:is_friend(RoleID, ChangeRoleID) of
        true ->
            State2 = mod_role_buff:remove_by_class(?FRIEND_BUFF_CLASS, State),
            do_add_friend_buff(State2);
        _ ->
            State
    end.

%% 有朋友的亲密度发生变化
do_friend_level_change(DestRoleID, State) ->
    #r_role{role_attr = #r_role_attr{team_id = TeamID}} = State,
    TeamRoleIDs = team_misc:get_team_role_ids(TeamID),
    case lists:member(DestRoleID, TeamRoleIDs) of
        true ->
            State2 = mod_role_buff:remove_by_class(?FRIEND_BUFF_CLASS, State),
            do_add_friend_buff(State2);
        _ ->
            State
    end.

do_add_friend_buff(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{team_id = TeamID}} = State,
    case ?HAS_TEAM(TeamID) of
        true ->
            TeamRoleIDs = lists:delete(RoleID, team_misc:get_team_role_ids(TeamID)),
            #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID),
            #c_friendly_level{friendly_level = FriendLevel, buff_list = BuffList} = get_max_friend_config(FriendList, TeamRoleIDs, [0]),
            case FriendLevel > 0 of
                true ->
                    [#c_friendly_level{buff_list = BuffList}] = lib_config:find(cfg_friendly_level, FriendLevel),
                    BuffList2 = [ #buff_args{buff_id = BuffID, from_actor_id = RoleID}|| BuffID <- BuffList],
                    mod_role_buff:do_add_buff(BuffList2, State);
                _ ->
                    State
            end;
        _ ->
            State
    end.

do_friend_recommend(RoleID, State) ->
    Now = time_tool:now(),
    RecommendList2 =
        case mod_role_dict:get_friend_recommend() of
            {LastTime, RecommendList} ->
                case Now >= LastTime + ?RECOMMEND_TIME of
                    true -> %% 超过5秒，重新请求
                        do_friend_recommend2(Now, RoleID, State);
                    _ ->
                        #r_world_friend{friend_list = FriendList, black_list = BlackList} = world_friend_server:get_role_info(RoleID),
                        FriendRoleList = [R || #r_friend{role_id = R} <- FriendList],
                        RoleList = [RoleID] ++ FriendRoleList ++ BlackList,
                        [ Recommend  || #p_friend{role_id = RecommendID} = Recommend <- RecommendList,
                            not lists:member(RecommendID, RoleList) andalso not is_dest_filter(RoleID, RecommendID)]
                end;
            _ ->
                do_friend_recommend2(Now, RoleID, State)
        end,
    common_misc:unicast(RoleID, #m_friend_recommend_toc{recommend_list = RecommendList2}),
    State.

do_friend_recommend2(Now, RoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{level = Level} = RoleAttr,
    #r_world_friend{friend_list = FriendList, black_list = BlackList, request_list = RequestList} = world_friend_server:get_role_info(RoleID),
    FriendRoleList = [R || #r_friend{role_id = R} <- FriendList],
    RoleList = [RoleID] ++ FriendRoleList ++ BlackList ++ RequestList,
    AllList = lib_tool:random_reorder_list(world_online_server:get_all_info()),
    RecommendList = do_friend_recommend3(AllList, Level, RoleList, RoleID, [], [], []),
    RecommendList2 = trans_to_p_recommend(RecommendList),
    mod_role_dict:set_friend_recommend({Now, RecommendList2}),
    RecommendList2.

do_friend_recommend3([], _Level, _RoleList, _RoleID, Acc1, Acc2, Acc3) ->
    lists:sublist(Acc1 ++ Acc2 ++ Acc3, ?MAX_RECOMMEND_NUM);
do_friend_recommend3([RoleOnline | R], Level, RoleList, RoleID, Acc1, Acc2, Acc3) ->
    #r_role_online{role_id = OnlineRoleID, level = OnlineLevel} = RoleOnline,
    case lists:member(OnlineRoleID, RoleList) orelse is_dest_filter(RoleID, OnlineRoleID) of
        true ->
            do_friend_recommend3(R, Level, RoleList, RoleID, Acc1, Acc2, Acc3);
        _ ->
            LevelDiff = erlang:abs(Level - OnlineLevel),
            if
                LevelDiff =< 7 ->
                    NewAcc1 = [RoleOnline | Acc1],
                    case erlang:length(NewAcc1) >= ?MAX_RECOMMEND_NUM of
                        true ->
                            NewAcc1;
                        _ ->
                            do_friend_recommend3(R, Level, RoleList, RoleID, NewAcc1, Acc2, Acc3)
                    end;
                LevelDiff =< 14 ->
                    do_friend_recommend3(R, Level, RoleList, RoleID, Acc1, [RoleOnline | Acc2], Acc3);
                true ->
                    do_friend_recommend3(R, Level, RoleList, RoleID, Acc1, Acc2, [RoleOnline | Acc3])
            end
    end.


do_friend_search(RoleID, RoleName, State) ->
    case catch check_can_search(RoleName) of
        {ok, FriendInfo} ->
            common_misc:unicast(RoleID, #m_friend_search_toc{friend_info = FriendInfo}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_friend_search_toc{err_code = ErrCode}),
            State
    end.

check_can_search(RoleName) ->
    FriendID = common_role_data:get_role_id_by_name(RoleName),
    ?IF(FriendID > 0, ok, ?THROW_ERR(?ERROR_FRIEND_SEARCH_001)),
    {ok, trans_to_p_friend2(#r_friend{role_id = FriendID})}.

%% 更新
do_update_is_online(RoleID, FriendList, BlackList, ChatList, IsOnline) ->
    RoleIDList1 = [FriendRoleID || #r_friend{role_id = FriendRoleID} <- FriendList],
    DataRecord = #m_friend_is_online_toc{role_id = RoleID, is_online = IsOnline},
    common_broadcast:bc_record_to_roles(lib_tool:list_filter_repeat(RoleIDList1 ++ BlackList ++ ChatList), DataRecord).

do_friend_trigger(State) ->
    mod_role_mission:friend_trigger(State).

do_friendly_level_trigger(State) ->
    State.

get_max_friend_config(_FriendList, [], FriendlyList) ->
    world_friend_server:get_friendly_config(lists:max(FriendlyList));
get_max_friend_config([], _TeamRoleIDs, FriendlyList) ->
    world_friend_server:get_friendly_config(lists:max(FriendlyList));
get_max_friend_config([Friend|R], TeamRoleIDs, FriendlyList) ->
    #r_friend{role_id = RoleID, friendly = Friendly} = Friend,
    case lists:member(RoleID, TeamRoleIDs) of
        true ->
            get_max_friend_config(R, lists:delete(RoleID, TeamRoleIDs), [Friendly|FriendlyList]);
        _ ->
            get_max_friend_config(R, TeamRoleIDs, FriendlyList)
    end.

trans_to_p_friend(List) ->
    [trans_to_p_friend2(Friend) || Friend <- List].
trans_to_p_friend2(RoleID) when erlang:is_integer(RoleID) ->
    trans_to_p_friend2(#r_friend{role_id = RoleID});
trans_to_p_friend2(#r_friend{role_id = RoleID, friendly = Friendly}) ->
    RoleAttr = common_role_data:get_role_attr(RoleID),
    VipLevel = common_role_data:get_role_vip_level(RoleID),
    CoupleID = marry_misc:get_couple_id(RoleID),
    trans_to_p_friend3(RoleAttr, VipLevel, Friendly, CoupleID).

trans_to_p_friend3(RoleAttr, VipLevel, Friendly, CoupleID) ->
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        family_name = FamilyName,
        sex = Sex,
        level = Level,
        category = Category
    } = RoleAttr,
    #p_friend{
        role_id = RoleID,
        role_name = RoleName,
        family_name = FamilyName,
        sex = Sex,
        level = Level,
        vip_level = VipLevel,
        category = Category,
        friendly = Friendly,
        is_online = role_misc:is_online(RoleID),
        couple_id = CoupleID}.

trans_to_p_recommend(List) ->
    [trans_to_p_recommend2(RoleOnline) || RoleOnline <- List].
trans_to_p_recommend2(RoleOnline) ->
    #r_role_online{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category
    } = RoleOnline,
    #p_friend{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        is_online = role_misc:is_online(RoleID)}.

is_dest_filter(RoleID, RecommendID) ->
    #r_world_friend{black_list = BlackList, request_list = RequestList} = world_friend_server:get_role_info(RecommendID),
    lists:member(RoleID, BlackList ++ RequestList).