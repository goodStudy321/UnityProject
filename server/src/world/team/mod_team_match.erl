%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     组队匹配
%%% @end
%%% Created : 31. 十月 2017 10:15
%%%-------------------------------------------------------------------
-module(mod_team_match).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("team.hrl").
-include("proto/mod_role_team.hrl").
-include("proto/mod_role_map.hrl").

%% 进程外/进程内均可的API
-export([
    role_match/2,
    role_cancel_match/1,
    role_robot_match/1
]).

%% 本进程内调用的API
-export([
    do_match/2,
    do_match/3,
    do_cancel_match/1,
    do_cancel_match/2
]).

-export([
    handle/1
]).

role_match(RoleID, CopyID) ->
    team_misc:info_team({mod, ?MODULE, {match, RoleID, CopyID}}).

role_cancel_match(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {cancel_match, RoleID}}).

role_robot_match(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {role_robot_match, RoleID}}).

handle({match, RoleID, CopyID}) ->
    do_match(RoleID, CopyID);
handle({cancel_match, RoleID}) ->
    do_cancel_match(RoleID);
handle({role_robot_match, RoleID}) ->
    do_role_robot_match(RoleID);
handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

do_match(RoleID, CopyID) ->
    do_match(RoleID, CopyID, true).
do_match(RoleID, CopyID, IsSendErr) ->
    case catch check_match(RoleID, CopyID) of
        {team_add_role, RoleIDs, RoleMatchList, TeamID} -> %% 队伍匹配
            mod_team_data:set_role_match(CopyID, RoleMatchList),
            [mod_team_request:do_role_join_team(R, TeamID) || R <- RoleIDs],
            DataRecord = #m_team_match_toc{copy_id = CopyID, is_matching = false},
            common_broadcast:bc_record_to_roles(RoleIDs, DataRecord);
        {add_role_match, RoleTeam} -> %% 没有队伍，等待
            common_misc:unicast(RoleID, #m_team_match_toc{is_matching = true, copy_id = CopyID}),
            mod_team_data:add_role_match(CopyID, RoleID),
            mod_team_data:set_role_team(RoleTeam#r_role_team{match_copy_id = CopyID});
        {role_join_team, TeamID} -> %% 玩家直接加入队伍
            common_misc:unicast(RoleID, #m_team_match_toc{copy_id = CopyID, is_matching = false}),
            mod_team_request:do_role_join_team(RoleID, TeamID);
        {create_team, OtherRoleIDs, RoleMatchList, TeamData} -> %% 有志同道合的人，直接加入
            DataRecord = #m_team_match_toc{copy_id = CopyID, is_matching = false},
            common_broadcast:bc_record_to_roles([RoleID|OtherRoleIDs], DataRecord),
            TeamID = mod_team_data:get_new_team_id(),
            mod_team_data:set_role_match(CopyID, RoleMatchList),
            TeamData2 = TeamData#r_team{captain_role_id = RoleID, team_id = TeamID},
            mod_team_request:do_role_join_team(RoleID, TeamData2),
            [ mod_team_request:do_role_join_team(R, TeamID) || R <- OtherRoleIDs],
            %% 这里已经满员了，所以不用手动掉匹配
            mod_team_data:add_team_match(CopyID, TeamID);
        {error, ErrCode} ->
            ?IF(IsSendErr, common_misc:unicast(RoleID, #m_team_match_toc{err_code = ErrCode}), ok)
    end.

check_match(RoleID, CopyID) ->
    #r_role_team{team_id = TeamID} = RoleTeam = mod_team_data:get_role_team(RoleID),
    case ?HAS_TEAM(TeamID) of
        true -> %% 有队伍，队伍进行匹配
            check_team_match(RoleID, TeamID);
        _ -> %% 没有队伍
            check_role_match(RoleTeam, CopyID)
    end.

%% 队伍匹配
check_team_match(RoleID, TeamID) ->
    #r_team{
        captain_role_id = CaptainRoleID,
        copy_id = MyCopyID,
        role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(RoleID =:= CaptainRoleID, ok, ?THROW_ERR(?ERROR_TEAM_CAPTAIN_002)),
    ?IF(erlang:length(RoleList) >= ?MAX_TEAM_NUM, ?THROW_ERR(?ERROR_TEAM_MATCH_001), ok),
    ?IF(MyCopyID > 0 andalso map_misc:is_copy_team(MyCopyID), ok, ?THROW_ERR(?ERROR_TEAM_MATCH_002)),
    RoleMatchList = mod_team_data:get_role_match(MyCopyID),
    NeedNum = ?MAX_TEAM_NUM - erlang:length(RoleList),
    {AddList, RemainList} = get_match_roles(TeamData, MyCopyID, NeedNum, RoleMatchList, [], []),
    {team_add_role, AddList, RemainList, TeamID}.

%% 玩家匹配
check_role_match(RoleTeam, CopyID) ->
    #r_role_team{role_level = RoleLevel, match_copy_id = MatchCopyID} = RoleTeam,
    ?IF(map_misc:is_copy_team(CopyID) orelse CopyID =:= common_misc:get_global_int(?GLOBAL_TEAM_WILD), ok, ?THROW_ERR(?ERROR_TEAM_MATCH_002)),
    ?IF(MatchCopyID > 0, ?THROW_ERR(?ERROR_TEAM_START_COPY_003), ok),
    case CopyID =:= common_misc:get_global_int(?GLOBAL_TEAM_WILD) of
        true ->
            ok;
        _ ->
            case catch team_misc:check_copy_pass(RoleTeam, CopyID) of
                ?LEVEL_LIMIT ->
                    ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL);
                ?COPY_DEGREE_LIMIT ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_004);
                ?COPY_TIMES_LIMIT ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_009);
                ?COPY_TIMES_ALL_LIMITS ->
                    ?THROW_ERR(?ERROR_TEAM_START_COPY_006);
                _ ->
                    ok
            end
    end,
    case mod_team_data:get_team_match(CopyID) of
        [_|_] = TeamList ->
            case get_match_team(RoleLevel, TeamList) of
                {ok, TeamID} ->
                    {role_join_team, TeamID};
                _ ->
                    {add_role_match, RoleTeam}
            end;
        _ ->
            RoleMatchList = mod_team_data:get_role_match(CopyID),
            NeedNum = ?MAX_TEAM_NUM - 1,
            case erlang:length(RoleMatchList) >= NeedNum of
                true ->
                    {OtherRoleIDs, RemainList} = lists:split(NeedNum, RoleMatchList),
                    TeamData = #r_team{
                        min_level = 1,
                        max_level = 1000,
                        add_friendly_time = team_misc:get_add_friendly_time(),
                        copy_id = CopyID},
                    {create_team, OtherRoleIDs, RemainList, TeamData};
                _ ->
                    {add_role_match, RoleTeam}
            end
    end.

%% 取消匹配
do_cancel_match(RoleID) ->
    do_cancel_match(RoleID, true).
do_cancel_match(RoleID, IsSendErr) ->
    case catch check_cancel_match(RoleID) of
        {role_cancel_match, CopyID, RoleTeam} ->
            mod_team_data:del_role_match(CopyID, RoleID),
            mod_team_data:set_role_team(RoleTeam),
            common_misc:unicast(RoleID, #m_team_match_toc{is_matching = false}),
            ok;
        {error, ErrCode} ->
            ?IF(IsSendErr, common_misc:unicast(RoleID, #m_team_match_toc{err_code = ErrCode}), ok)
    end.

check_cancel_match(RoleID) ->
    #r_role_team{team_id = TeamID} = RoleTeam = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ?THROW_ERR(?ERROR_TEAM_MATCH_003), ok),
    #r_role_team{match_copy_id = MatchCopyID} = RoleTeam,
    {role_cancel_match, MatchCopyID, RoleTeam#r_role_team{match_copy_id = 0}}.

%% 队伍获取匹配玩家
get_match_roles(_TeamData, _CopyID, 0, RoleMatchList, RolesAcc, MatchAcc) ->
    {RolesAcc, RoleMatchList ++ MatchAcc};
get_match_roles(_TeamData, _CopyID, _NeedNum, [], RolesAcc, MatchAcc) ->
    {RolesAcc, MatchAcc};
get_match_roles(TeamData, CopyID, NeedNum, [RoleID|R], RolesAcc, MatchAcc) ->
    #r_role_team{role_level = RoleLevel} = RoleTeam = mod_team_data:get_role_team(RoleID),
    case catch team_misc:check_copy_pass(RoleTeam, CopyID) of
        ok ->
            IsCopyPass = true;
        _ ->
            IsCopyPass = false
    end,
    case team_misc:is_team_match(RoleLevel, TeamData) andalso IsCopyPass of
        true ->
            get_match_roles(TeamData, CopyID, NeedNum - 1, R, [RoleID|RolesAcc], MatchAcc);
        _ ->
            get_match_roles(TeamData, CopyID, NeedNum, R, RolesAcc, [RoleID|MatchAcc])
    end.

%% 玩家获取队伍
get_match_team(_RoleLevel, []) ->
    false;
get_match_team(RoleLevel, [TeamID|R]) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{} = TeamData ->
            ?IF(team_misc:is_team_match(RoleLevel, TeamData), {ok, TeamID}, get_match_team(RoleLevel, R));
        _ ->
            get_match_team(RoleLevel, R)
    end.

do_role_robot_match(RoleID) ->
    TeamID = mod_team_data:get_new_team_id(),
    CopyID = ?COPY_EQUIP_GUIDE,
    TeamData = #r_team{
        min_level = 1,
        max_level = 1000,
        add_friendly_time = time_tool:timestamp({2099, 1, 1}),
        copy_id = CopyID,
        enter_copy_id = CopyID},
    DataRecord = #m_team_match_toc{copy_id = CopyID, is_matching = false},
    common_misc:unicast(RoleID, DataRecord),
    TeamData2 = TeamData#r_team{captain_role_id = RoleID, team_id = TeamID},
    mod_team_request:do_role_join_team(RoleID, TeamData2),

    do_role_robot_match2(?SEX_BOY, ?CATEGORY_2, 1, TeamID),
    do_role_robot_match2(?SEX_GIRL, ?CATEGORY_1, 1, TeamID),
    erlang:send_after(500, erlang:self(), {func, fun() -> mod_team_copy:start_copy(RoleID, CopyID) end}).

do_role_robot_match2(Sex, Category, IndexID, TeamID) when IndexID < ?TEAM_ROBOT_NUM ->
    case mod_team_data:get_role_team(IndexID) of
        #r_role_team{team_id = RobotTeamID, role_name = RoleName, sex = SexT} when RoleName =/= "" ->
            ?IF(?HAS_TEAM(RobotTeamID) orelse Sex =/= SexT, do_role_robot_match2(Sex, Category, IndexID + 1, TeamID), do_role_robot_match3(IndexID, TeamID));
        _ ->
            Name = common_misc:get_random_name(),
            [RoleLevel|_] = common_misc:get_global_list(?GLOBAL_EQUIP_GUIDE),
            mod_team_data:set_role_team(#r_role_team{
                role_id = IndexID,
                role_name = Name,
                map_id = 10010,
                role_level = RoleLevel,
                category = Category,
                sex = Sex,
                skin_list = [3040205, 3050000, 30200000],
                is_online = true
            }),
            do_role_robot_match3(IndexID, TeamID)
    end.

do_role_robot_match3(IndexID, TeamID) ->
    mod_team_request:do_role_join_team(IndexID, TeamID).


