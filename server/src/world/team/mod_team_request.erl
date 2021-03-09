%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2017 14:21
%%%-------------------------------------------------------------------
-module(mod_team_request).
-author("laijichang").
-include("global.hrl").
-include("team.hrl").
-include("copy.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    create_team/2,
    invite_team/2,
    invite_reply_team/3,
    apply_team/3,
    apply_reply_team/3,
    leave_team/1,
    kick_role/2,
    change_captain/2,
    set_copy_info/4,
    get_copy_team/3
]).

-export([
    do_role_join_team/2
]).

-export([
    handle/1
]).

create_team(RoleID, TeamArgs) ->
    team_misc:call_team({mod, ?MODULE, {create_team, RoleID, TeamArgs}}).
invite_team(RoleID, DestRoleID) ->
    team_misc:info_team({mod, ?MODULE, {invite_team, RoleID, DestRoleID}}).
invite_reply_team(RoleID, DestRoleID, Info) ->
    team_misc:info_team({mod, ?MODULE, {invite_reply_team, RoleID, DestRoleID, Info}}).
apply_team(RoleID, TeamID, DestRoleID) ->
    team_misc:info_team({mod, ?MODULE, {apply_team, RoleID, TeamID, DestRoleID}}).
apply_reply_team(RoleID, DestRoleID, OpType) ->
    team_misc:info_team({mod, ?MODULE, {apply_reply_team, RoleID, DestRoleID, OpType}}).
leave_team(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {leave_team, RoleID}}).
kick_role(RoleID, DestRoleID) ->
    team_misc:info_team({mod, ?MODULE, {kick_role, RoleID, DestRoleID}}).
change_captain(RoleID, DestRoleID) ->
    team_misc:info_team({mod, ?MODULE, {change_captain, RoleID, DestRoleID}}).
set_copy_info(RoleID, CopyID, MinLevel, MaxLevel) ->
    team_misc:info_team({mod, ?MODULE, {set_copy_info, RoleID, CopyID, MinLevel, MaxLevel}}).
get_copy_team(RoleID, CopyID, RoleLevel) ->
    team_misc:info_team({mod, ?MODULE, {get_copy_team, RoleID, CopyID, RoleLevel}}).

handle({create_team, RoleID, TeamArgs}) ->
    do_create_team(RoleID, TeamArgs);
handle({invite_team, RoleID, DestRoleID}) ->
    do_invite_team(RoleID, DestRoleID);
handle({invite_reply_team, RoleID, DestRoleID, Info}) ->
    do_invite_reply_team(RoleID, DestRoleID, Info);
handle({apply_team, RoleID, TeamID, DestRoleID}) ->
    do_apply_team(RoleID, TeamID, DestRoleID);
handle({apply_reply_team, RoleID, DestRoleID, OpType}) ->
    do_apply_reply(RoleID, DestRoleID, OpType);
handle({leave_team, RoleID}) ->
    do_leave_team(RoleID);
handle({kick_role, RoleID, DestRoleID}) ->
    do_kick_role(RoleID, DestRoleID);
handle({change_captain, RoleID, DestRoleID}) ->
    do_change_captain(RoleID, DestRoleID);
handle({set_copy_info, RoleID, CopyID, MinLevel, MaxLevel}) ->
    do_set_copy_info(RoleID, CopyID, MinLevel, MaxLevel);
handle({get_copy_team, RoleID, CopyID, RoleLevel}) ->
    do_get_copy_team(RoleID, CopyID, RoleLevel);

handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

%% 创建队伍
do_create_team(RoleID, TeamArgs) ->
    case catch check_can_create(RoleID, TeamArgs) of
        {ok, TeamData} ->
            TeamID = mod_team_data:get_new_team_id(),
            TeamData2 = TeamData#r_team{team_id = TeamID, captain_role_id = RoleID},
            do_role_join_team(RoleID, TeamData2),
            common_misc:unicast(RoleID, #m_team_create_toc{}),
            ok;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_create_toc{err_code = ErrCode})
    end.

check_can_create(RoleID, TeamArgs) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(TeamID > 0, ?THROW_ERR(?ERROR_TEAM_CREATE_001), ok),
    #team_create_args{
        min_level = MinLevel,
        max_level = MaxLevel
    } = TeamArgs,
    TeamData = #r_team{
        add_friendly_time = team_misc:get_add_friendly_time(),
        min_level = MinLevel,
        max_level = MaxLevel},
    {ok, TeamData}.

%% 邀请别人加入队伍
do_invite_team(RoleID, DestRoleID) ->
    case catch check_can_invite(RoleID, DestRoleID) of
        {ok, TeamID} ->
            DataRecord = #m_team_invite_toc{team_id = TeamID, invited_role_id = DestRoleID, invite_role = team_misc:get_team_invite(RoleID)},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID, DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_invite_toc{err_code = ErrCode})
    end.

check_can_invite(RoleID, DestRoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_INVITE_001)),
    #r_role_team{team_id = DestTeamID} = mod_team_data:get_role_team(DestRoleID),
    case ?HAS_TEAM(DestTeamID) of
        true ->
            ?IF(DestTeamID =/= TeamID, ?THROW_ERR(?ERROR_TEAM_INVITE_004), ?THROW_ERR(?ERROR_TEAM_INVITE_005));
        _ ->
            ok
    end,
%%    ?IF(?HAS_TEAM(DestTeamID), ?THROW_ERR(?ERROR_TEAM_INVITE_004), ok),
    ?IF(role_misc:is_online(DestRoleID), ok, ?THROW_ERR(?ERROR_TEAM_INVITE_003)),
    #r_team{role_list = RoleList} = mod_team_data:get_team_data(TeamID),
    ?IF(erlang:length(RoleList) < ?MAX_TEAM_NUM, ok, ?THROW_ERR(?ERROR_TEAM_INVITE_002)),
    {ok, TeamID}.

%% 邀请回复
do_invite_reply_team(RoleID, DestRoleID, Info) ->
    case catch check_invite_reply(RoleID, DestRoleID, Info) of
        {join_team, OpType, TeamData} ->
            do_role_join_team(RoleID, TeamData),
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            DataRecord = #m_team_invite_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID, DataRecord);
        {refuse_team, OpType} ->
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            DataRecord = #m_team_invite_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID, DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_invite_reply_toc{err_code = ErrCode})
    end.

check_invite_reply(RoleID, DestRoleID, Info) ->
    {OpType, TeamID} = Info,
    #r_role_team{team_id = MyTeamID} = mod_team_data:get_role_team(RoleID),
    #r_role_team{team_id = DestTeamID} = mod_team_data:get_role_team(DestRoleID),
    ?IF(?HAS_TEAM(MyTeamID), ?THROW_ERR(?ERROR_TEAM_INVITE_REPLY_001), ok),
    ?IF(?HAS_TEAM(DestTeamID) andalso DestTeamID =:= TeamID, ok, ?THROW_ERR(?ERROR_TEAM_INVITE_REPLY_002)),
    case OpType of
        ?TEAM_INVITE_REPLY_ACCEPT ->
            #r_team{role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
            ?IF(erlang:length(RoleList) < ?MAX_TEAM_NUM, ok, ?THROW_ERR(?ERROR_TEAM_INVITE_REPLY_003)),
            {join_team, OpType, TeamData};
        ?TEAM_INVITE_REPLY_REFUSE ->
            {refuse_team, OpType}
    end.

%% 申请加入队伍
do_apply_team(RoleID, TeamID, DestRoleID) ->
    case catch check_can_apply(RoleID, TeamID, DestRoleID) of
        {ok, DestRoleID2} ->
            DataRecord = #m_team_apply_toc{apply_role = team_misc:get_team_invite(RoleID)},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID2, DataRecord);
        {direct_join, TeamData} ->
            DataRecord = #m_team_apply_toc{apply_role = team_misc:get_team_invite(RoleID)},
            common_misc:unicast(RoleID, DataRecord),
            do_role_join_team(RoleID, TeamData);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_apply_toc{err_code = ErrCode})
    end,
    ok.

check_can_apply(RoleID, TeamID, DestRoleID) ->
    #r_role_team{team_id = MyTeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(MyTeamID), ?THROW_ERR(?ERROR_TEAM_APPLY_001), ok),
    TeamData =
    case ?HAS_TEAM(TeamID) of
        true ->
            mod_team_data:get_team_data(TeamID);
        _ ->
            #r_role_team{team_id = DestTeamID} = mod_team_data:get_role_team(DestRoleID),
            mod_team_data:get_team_data(DestTeamID)
    end,
    ?IF(TeamData =:= undefined, ?THROW_ERR(?ERROR_TEAM_APPLY_003), ok),
    #r_team{
        copy_id = CopyID,
        min_level = MinLevel,
        max_level = MaxLevel,
        captain_role_id = DestRoleID2,
        role_list = RoleList} = TeamData,
    ?IF(erlang:length(RoleList) < ?MAX_TEAM_NUM, ok, ?THROW_ERR(?ERROR_TEAM_APPLY_002)),
    case CopyID > 0 of
        true -> %% 如果对方有目标，并且满足对应的等级，可以直接加入
            RoleLevel = common_role_data:get_role_level(RoleID),
            ?IF(MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel, {direct_join, TeamData}, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL));
        _ ->
            {ok, DestRoleID2}
    end.

%% 申请的回复
do_apply_reply(RoleID, DestRoleID, OpType) ->
    case catch check_apply_reply(RoleID, DestRoleID, OpType) of
        {join_team, TeamData} ->
            do_role_join_team(DestRoleID, TeamData),
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            DataRecord = #m_team_apply_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName, apply_role_id = DestRoleID},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID, DataRecord);
        {refuse_team} ->
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            common_misc:unicast(RoleID, #m_team_apply_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName}),
            common_misc:unicast(DestRoleID, #m_team_apply_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_apply_reply_toc{err_code = ErrCode})
    end.

check_apply_reply(RoleID, DestRoleID, OpType) ->
    #r_role_team{team_id = MyTeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(MyTeamID), ok, ?THROW_ERR(?ERROR_TEAM_APPLY_REPLY_001)),
    #r_role_team{team_id = DestTeamID} = mod_team_data:get_role_team(DestRoleID),
    ?IF(?HAS_TEAM(DestTeamID), ?THROW_ERR(?ERROR_TEAM_APPLY_REPLY_002), ok),
    case OpType of
        ?TEAM_APPLY_REPLY_ACCEPT ->
            #r_team{role_list = RoleList} = TeamData = mod_team_data:get_team_data(MyTeamID),
            ?IF(erlang:length(RoleList) < ?MAX_TEAM_NUM, ok, ?THROW_ERR(?ERROR_TEAM_APPLY_REPLY_003)),
            {join_team, TeamData};
        ?TEAM_APPLY_REPLY_REFUSE ->
            {refuse_team}
    end.

%% 离开队伍
do_leave_team(RoleID) ->
    case catch check_can_leave(RoleID) of
        {owner_leave, TeamID, CopyID, AllRoleIDs, TeamData} ->
            case AllRoleIDs of
                [RoleID] ->
                    RoleTeam = mod_team_data:get_role_team(RoleID),
                    RoleTeam2 = RoleTeam#r_role_team{team_id = 0},
                    mod_team_data:set_role_team(RoleTeam2),
                    hook_team:role_leave_team(RoleID, TeamID),
                    mod_team_data:del_team_data(TeamID),
                    mod_team_data:del_team_match(CopyID, TeamID),
                    mod_team_data:del_team_start_list(TeamID);
                _ ->
                    OtherRoles = lists:delete(RoleID, AllRoleIDs),
                    CaptainRoleID = lib_tool:random_element_from_list(OtherRoles),
                    TeamData2 = TeamData#r_team{captain_role_id = CaptainRoleID},
                    do_role_leave_team(RoleID, TeamData2),
                    NewTeamData = mod_team_data:get_team_data(TeamID),
                    #r_role_team{role_level = Level} = mod_team_data:get_role_team(CaptainRoleID),
                    common_broadcast:send_team_common_notice(TeamID, ?NOTICE_TEAM_CAPTAIN_TEAM,
                        [lib_tool:to_list(CaptainRoleID), common_role_data:get_role_name(CaptainRoleID), lib_tool:to_list(Level)]),
                    common_broadcast:bc_record_to_roles(OtherRoles, #m_team_info_toc{team_info = team_misc:trans_to_p_team(NewTeamData)})
            end;
        {role_leave, MemberRoles, TeamData} ->
            [ mod_role_team:member_leave(MemberRoleID, RoleID) || MemberRoleID <- MemberRoles],
            do_role_leave_team(RoleID, TeamData);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_leave_toc{err_code = ErrCode})
    end.

check_can_leave(RoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_LEAVE_001)),
    #r_team{captain_role_id = CaptainRoleID, copy_id = CopyID, role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(CaptainRoleID =:= RoleID, {owner_leave, TeamID, CopyID, RoleList, TeamData}, {role_leave, lists:delete(RoleID, RoleList), TeamData}).

%% 踢出队伍
do_kick_role(RoleID, DestRoleID) ->
    case catch check_kick_role(RoleID, DestRoleID) of
        {ok, TeamData} ->
            do_role_leave_team(DestRoleID, TeamData),
            [ mod_role_team:member_leave(MemberRoleID, DestRoleID) || MemberRoleID <- TeamData#r_team.role_list, MemberRoleID =/= DestRoleID],
            common_misc:unicast(RoleID, #m_team_kick_toc{});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_kick_toc{err_code = ErrCode})
    end.

check_kick_role(RoleID, DestRoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_KICK_001)),
    #r_team{captain_role_id = CaptainRoleID, role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(CaptainRoleID =:= RoleID, ok, ?THROW_ERR(?ERROR_TEAM_KICK_002)),
    ?IF(RoleID =/= DestRoleID, ok, ?THROW_ERR(?ERROR_TEAM_KICK_003)),
    ?IF(lists:member(DestRoleID, RoleList), ok, ?THROW_ERR(?ERROR_TEAM_KICK_004)),
    {ok, TeamData}.

%% 改变队长
do_change_captain(RoleID, DestRoleID) ->
    case catch check_change_captain(RoleID, DestRoleID) of
        {ok, TeamData} ->
            mod_team_data:set_team_data(TeamData),
            #r_role_team{role_level = Level} = mod_team_data:get_role_team(DestRoleID),
            common_broadcast:send_family_common_notice(TeamData#r_team.team_id, ?NOTICE_TEAM_CAPTAIN_TEAM,
                [lib_tool:to_list(DestRoleID), common_role_data:get_role_name(DestRoleID), lib_tool:to_list(Level)]),
            team_misc:broadcast_record(TeamData, #m_team_captain_toc{captain_id = DestRoleID});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_captain_toc{err_code = ErrCode})
    end.

check_change_captain(RoleID, DestRoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_CAPTAIN_001)),
    #r_team{captain_role_id = CaptainRoleID, role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(RoleID =:= CaptainRoleID, ok, ?THROW_ERR(?ERROR_TEAM_CAPTAIN_002)),
    ?IF(lists:member(DestRoleID, RoleList), ok, ?THROW_ERR(?ERROR_TEAM_CAPTAIN_003)),
    TeamData2 = TeamData#r_team{captain_role_id = DestRoleID},
    {ok, TeamData2}.

%% 改变副本目标
do_set_copy_info(RoleID, CopyID, MinLevel, MaxLevel) ->
    case catch check_set_copy_info(RoleID, CopyID, MinLevel, MaxLevel) of
        {ok, OldCopyID, TeamID, TeamData} ->
            mod_team_data:set_team_data(TeamData),
            team_misc:broadcast_record(TeamData, #m_team_set_copy_info_toc{copy_id = CopyID, min_level = MinLevel, max_level = MaxLevel}),
            ?IF(OldCopyID > 0, mod_team_data:del_team_match(OldCopyID, TeamID), ok),
            mod_team_data:add_team_match(CopyID, TeamID),
            mod_team_match:do_match(RoleID, CopyID, false);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_set_copy_info_toc{err_code = ErrCode})
    end.

check_set_copy_info(RoleID, CopyID, MinLevel, MaxLevel) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_SET_COPY_INFO_001)),
    #r_team{copy_id = OldCopyID, captain_role_id = CaptainRoleID} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(CaptainRoleID =:= RoleID, ok, ?THROW_ERR(?ERROR_TEAM_SET_COPY_INFO_003)),
    WildID = common_misc:get_global_int(?GLOBAL_TEAM_WILD),
    ?IF(CopyID =:= WildID orelse map_misc:is_copy_team(CopyID), ok, ?THROW_ERR(?ERROR_TEAM_CREATE_002)),
    TeamData2 = TeamData#r_team{
            copy_id = CopyID,
            min_level = MinLevel,
            max_level = MaxLevel,
            is_start = false},
    {ok, OldCopyID, TeamID, TeamData2}.

%% 获取副本组队信息
do_get_copy_team(RoleID, CopyID, RoleLevel) ->
    TeamList = mod_team_data:get_team_match(CopyID),
    TeamInfos = do_get_copy_team2(RoleLevel, TeamList, []),
    common_misc:unicast(RoleID, #m_team_copy_info_toc{copy_teams = TeamInfos}).

do_get_copy_team2(_RoleLevel, [], CopyTeams) ->
    CopyTeams;
do_get_copy_team2(RoleLevel, [TeamID|R], Acc) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{} = TeamData ->
            #r_team{
                min_level = MinLevel,
                max_level = MaxLevel,
                captain_role_id = CaptainRoleID,
                role_list = RoleList} = TeamData,
            case team_misc:is_team_match(RoleLevel, TeamData) of
                true ->
                    CopyTeam = #p_team_copy{
                        team_id = TeamID,
                        min_level = MinLevel,
                        max_level = MaxLevel,
                        captain_role_id = CaptainRoleID,
                        team_roles = [ team_misc:trans_to_p_team_role(RoleID) || RoleID <- RoleList]},
                    Acc2 = [CopyTeam|Acc];
                _ ->
                    Acc2 = Acc
            end,
            do_get_copy_team2(RoleLevel, R, Acc2);
        _ ->
            do_get_copy_team2(RoleLevel, R, Acc)
    end.

%% 玩家进入队伍操作
do_role_join_team(RoleID, TeamID) when erlang:is_integer(TeamID) ->
    do_role_join_team(RoleID, mod_team_data:get_team_data(TeamID));
do_role_join_team(RoleID, TeamData) ->
    #r_team{
        captain_role_id = CaptainRoleID,
        team_id = TeamID,
        role_list = RoleList} = TeamData,
    #r_role_team{
        role_name = RoleName,
        role_level = RoleLevel,
        category = Category,
        sex = Sex,
        match_copy_id = MatchCopyID
    } = RoleTeam = mod_team_data:get_role_team(RoleID),
    RoleList2 = [RoleID|RoleList],
    RoleTeam2 = RoleTeam#r_role_team{
        role_id = RoleID,
        team_id = TeamID,
        match_copy_id = 0,
        role_name = RoleName,
        role_level = RoleLevel,
        category = Category,
        sex = Sex,
        is_online = ?IF(RoleID > ?TEAM_ROBOT_NUM, role_misc:is_online(RoleID), true),
        is_ready = false},
    TeamData2 = TeamData#r_team{role_list = RoleList2},
    mod_team_data:del_role_match(MatchCopyID, RoleID),
    mod_team_data:set_role_team(RoleTeam2),
    mod_team_data:set_team_data(TeamData2),

    DataRecord = #m_team_role_update_toc{role = team_misc:trans_to_p_team_role(RoleTeam2)},
    common_broadcast:bc_record_to_roles(RoleList, DataRecord),
    hook_team:role_join_team(RoleID, TeamID, TeamData2),
    %% 这一步有可能会改变team_data
    mod_team_copy:do_stop_copy(CaptainRoleID),
    [ mod_role_team:member_join(OldRoleID, RoleID) || OldRoleID <- RoleList].

%% 玩家退出队伍操作
do_role_leave_team(RoleID, TeamData) ->
    #r_team{
        captain_role_id = CaptainRoleID,
        team_id = TeamID,
        role_list = RoleList} = TeamData,
    RoleList2 = lists:delete(RoleID, RoleList),
    TeamData2 = TeamData#r_team{role_list = RoleList2},
    RoleTeam = mod_team_data:get_role_team(RoleID),
    RoleTeam2 = RoleTeam#r_role_team{team_id = 0, is_ready = false},
    mod_team_data:set_role_team(RoleTeam2),
    mod_team_data:set_team_data(TeamData2),

    DataRecord = #m_team_role_update_toc{del_role_id = RoleID},
    team_misc:broadcast_record(TeamData2, DataRecord),
    hook_team:role_leave_team(RoleID, TeamID),
    %% 下面几步有可能会改变team_data
    mod_team_copy:do_stop_copy(CaptainRoleID).

