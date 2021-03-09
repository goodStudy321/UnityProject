%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 五月 2018 15:26
%%%-------------------------------------------------------------------
-module(mod_team_copy).
-author("laijichang").
-include("team.hrl").
-include("global.hrl").
-include("copy.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    start_copy/2,
    get_ready/1,
    refuse_ready/1,
    copy_end/1
]).

-export([
    handle/1
]).

-export([
    do_stop_copy/1,
    do_stop_copy/2,
    do_stop_copy2/3
]).

start_copy(RoleID, CopyID) ->
    team_misc:info_team({mod, ?MODULE, {start_copy, RoleID, CopyID}}).

get_ready(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {get_ready, RoleID}}).
refuse_ready(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {refuse_ready, RoleID}}).

copy_end(TeamID) ->
    team_misc:info_team({mod, ?MODULE, {copy_end, TeamID}}).

handle({start_copy, RoleID, CopyID}) ->
    do_start_copy(RoleID, CopyID);
handle({get_ready, RoleID}) ->
    do_get_ready(RoleID);
handle({refuse_ready, RoleID}) ->
    do_stop_copy(RoleID, ?CONDITION_TYPE_REFUSE);
handle({copy_end, TeamID}) ->
    do_copy_end(TeamID);
handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

do_start_copy(RoleID, CopyID) ->
    case catch check_start_copy(RoleID, CopyID) of
        {start_copy, TeamID, TeamData, ExtraRoleIDList} ->
            start_copy_map(CopyID, TeamID, TeamData, [RoleID], ExtraRoleIDList),
            mod_team_data:set_team_data(TeamData#r_team{is_start = true});
        {ok, RoleTeam, TeamID, TeamData, RobotIDs} ->
            mod_team_data:set_role_team(RoleTeam),
            mod_team_data:set_team_data(TeamData),
            mod_team_data:add_team_start_list(TeamID),
            DataRecord = #m_team_start_copy_toc{enter_copy_id = CopyID},
            team_misc:broadcast_record(TeamData, DataRecord),
            DataRecord2 = #m_team_copy_ready_toc{role_id = RoleID},
            team_misc:broadcast_record(TeamData, DataRecord2),
            lists:foldl(
                fun(RobotID, AddTime) ->
                    erlang:send_after(AddTime, erlang:self(), {mod, ?MODULE, {get_ready, RobotID}}),
                    AddTime + 1000
                end, 1000, RobotIDs),
            ok;
        {condtion, Type, ConditionRoleID} ->
            common_misc:unicast(RoleID, #m_team_copy_stop_toc{type = Type, role_id = ConditionRoleID});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_start_copy_toc{err_code = ErrCode})
    end.

check_start_copy(RoleID, CopyID) ->
    #r_role_team{team_id = TeamID} = RoleTeam = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_START_COPY_001)),
    #r_team{
        captain_role_id = Captain,
        enter_copy_id = OldCopyID,
        role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(OldCopyID > 0, ?THROW_ERR(?ERROR_TEAM_START_COPY_002), ok),
    ?IF(RoleID =:= Captain, ok, ?THROW_ERR(?ERROR_TEAM_CAPTAIN_002)),
    ?IF(map_misc:is_copy_team(CopyID), ok, ?THROW_ERR(?ERROR_TEAM_MATCH_002)),
    %% 其中可能混杂了机器人
    check_marry_copy(RoleList, CopyID),
    check_start_copy2(RoleList, CopyID),
    ExtraRoleIDList = check_get_reward(RoleList, CopyID, []),
    case RoleList =:= [RoleID] of
        true -> %% 自己一个人开启副本
            {start_copy, TeamID, TeamData, ExtraRoleIDList};
        _ ->
            RoleTeam2 = RoleTeam#r_role_team{is_ready = true},
            RobotIDs = [ TeamRoleID || TeamRoleID <- RoleList, TeamRoleID =< ?TEAM_ROBOT_NUM],
            %% 加多一层容错
            DestCopyID = ?IF(RobotIDs =/= [], ?COPY_EQUIP_GUIDE, CopyID),
            %% 这个进入副本的ID错了。。。打印日志
            ?IF(RobotIDs =/= [] andalso CopyID =/= ?COPY_EQUIP_GUIDE, ?ERROR_MSG("装备指引ID出错 :~w", [CopyID]), ok),
            TeamData2 = TeamData#r_team{enter_copy_id = DestCopyID, start_copy_time = time_tool:now() + ?COPY_READY_TIME},
            {ok, RoleTeam2, TeamID, TeamData2, RobotIDs}
    end.

check_get_reward([], _CopyID, ExtraRoleIDListAcc) ->
    ExtraRoleIDListAcc;
check_get_reward([RoleID | R], CopyID, ExtraRoleIDListAcc) ->
    #r_role_team{copy_list = CopyList} = mod_team_data:get_role_team(RoleID),
    [#c_copy{copy_type = CopyType, times = ConfigTimes}] = lib_config:find(cfg_copy, CopyID),
    Times =
        case lists:keyfind(CopyType, #p_kv.id, CopyList) of
            #p_kvt{type = Times0} -> Times0;
            _ -> 0
        end,
    ExtraRoleIDListAcc2 =
    case ConfigTimes + Times > 0 of
        true ->
            ExtraRoleIDListAcc;
        _ ->
            [RoleID | ExtraRoleIDListAcc]
    end,
    check_get_reward(R, CopyID, ExtraRoleIDListAcc2).

check_start_copy2([], _CopyID) ->
    ok;
check_start_copy2([RoleID|R], CopyID) ->
    #r_role_team{map_id = MapID, is_online = IsOnline} = RoleTeam = mod_team_data:get_role_team(RoleID),
    ?IF(IsOnline, ok, erlang:throw({condtion, ?CONDITION_TYPE_OFFLINE, RoleID})),
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), erlang:throw({condtion, ?CONDITION_TYPE_IN_COPY, RoleID}), ok),
    case catch team_misc:check_copy_pass(RoleTeam, CopyID) of
        ?LEVEL_LIMIT ->
            erlang:throw({condtion, ?CONDITION_TYPE_LEVEL, RoleID});
        ?COPY_DEGREE_LIMIT ->
            erlang:throw({condtion, ?CONDITION_TYPE_DEGREE, RoleID});
        ?COPY_TIMES_LIMIT ->
            erlang:throw({condtion, ?CONDITION_TYPE_TIMES_NOT_ENOUGH, RoleID});
        ?COPY_TIMES_ALL_LIMITS ->
            ?THROW_ERR(?ERROR_TEAM_START_COPY_006);
        _ ->
            ok
    end,
    check_start_copy2(R, CopyID).

%% 结婚副本特殊检查
check_marry_copy(RoleList, CopyID) ->
    case copy_misc:is_copy_marry(CopyID) of
        true ->
            ?IF(erlang:length(RoleList) =:= 2, ok, ?THROW_ERR(?ERROR_TEAM_START_COPY_004)),
            [RoleID1, RoleID2] = RoleList,
            #r_role_attr{sex = Sex1} = common_role_data:get_role_attr(RoleID1),
            #r_role_attr{sex = Sex2} = common_role_data:get_role_attr(RoleID2),
            ?IF(Sex1 =/= Sex2, ok, ?THROW_ERR(?ERROR_TEAM_START_COPY_004));
        _ ->
            ok
    end.

do_stop_copy(RoleID) ->
    do_stop_copy(RoleID, 0).
do_stop_copy(RoleID, Type) ->
    case catch check_stop_copy(RoleID) of
        {ok, TeamData} ->
            do_stop_copy2(TeamData, Type, RoleID),
            true;
        _ ->
            false
    end.

do_stop_copy2(TeamData, Type, RoleID) ->
    #r_team{team_id = TeamID, role_list = RoleList} = TeamData2 = TeamData#r_team{enter_copy_id = 0, start_copy_time = 0},
    mod_team_data:set_team_data(TeamData2),
    mod_team_data:del_team_start_list(TeamID),
    [ begin
          RoleTeam = mod_team_data:get_role_team(TeamRoleID),
          mod_team_data:set_role_team(RoleTeam#r_role_team{is_ready = false})
      end|| TeamRoleID <- RoleList],
    DataRecord = #m_team_copy_stop_toc{type = Type, role_id = RoleID},
    team_misc:broadcast_record(TeamData, DataRecord),
    true.

check_stop_copy(RoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, erlang:throw(not_team)),
    #r_team{enter_copy_id = EnterCopyID} = TeamData = mod_team_data:get_team_data(TeamID),
    ?IF(EnterCopyID > 0, ok, erlang:throw(not_enter_copy_id)),
    {ok, TeamData}.



do_get_ready(RoleID) ->
    case catch check_get_ready(RoleID) of
        {all_ready, CopyID, TeamID, RoleList, TeamData, ExtraRoleIDList} ->
            DataRecord = #m_team_copy_ready_toc{role_id = RoleID},
            team_misc:broadcast_record(TeamData, DataRecord),
            TeamData2 = TeamData#r_team{is_start = true, start_copy_time = 0, enter_copy_id = 0},
            mod_team_data:set_team_data(TeamData2),
            [ begin
                  RoleTeam = mod_team_data:get_role_team(TeamRoleID),
                  mod_team_data:set_role_team(RoleTeam#r_role_team{is_ready = false})
              end|| TeamRoleID <- RoleList],
            mod_team_data:del_team_start_list(TeamID),
            start_copy_map(CopyID, TeamID, TeamData, RoleList, ExtraRoleIDList);
        {ready, RoleTeam, TeamData} ->
            mod_team_data:set_role_team(RoleTeam),
            DataRecord = #m_team_copy_ready_toc{role_id = RoleID},
            team_misc:broadcast_record(TeamData, DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_copy_ready_toc{err_code = ErrCode})
    end.

check_get_ready(RoleID) ->
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_COPY_READY_001)),
    #r_team{enter_copy_id = CopyID, role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
    #r_role_team{is_ready = IsReady} = RoleTeam = mod_team_data:get_role_team(RoleID),
    RoleTeam2 = RoleTeam#r_role_team{is_ready = true},
    ?IF(IsReady, ?THROW_ERR(?ERROR_TEAM_COPY_READY_002), ok),
    ?IF(CopyID > 0, ok, ?THROW_ERR(?ERROR_TEAM_COPY_READY_002)),
    RoleList2 = [ mod_team_data:get_role_team(TeamRoleID)|| TeamRoleID <- lists:delete(RoleID, RoleList)],
    BoolList = [ IsTeamReady || #r_role_team{is_ready = IsTeamReady} <- RoleList2],
    ExtraRoleIDList = check_get_reward(RoleList, CopyID, []),
    case lists:member(false, BoolList) of
        true ->
            {ready, RoleTeam2, TeamData};
        _ ->
            {all_ready, CopyID, TeamID, RoleList, TeamData, ExtraRoleIDList}
    end.

start_copy_map(CopyID, TeamID, TeamData, RoleList, ExtraRoleIDList) ->
    erlang:spawn(
        fun() ->
            #r_team{captain_role_id = CaptainRoleID} = TeamData,
            MapTeam = #r_map_team{
                team_id = TeamID,
                captain_role_id = CaptainRoleID,
                role_id_list = RoleList,
                role_list = [ mod_team_data:get_role_team(RoleID) || RoleID <- RoleList],
                extra_role_id_list = ExtraRoleIDList
            },
            case CopyID =:= 0 of
                true ->
                    ?ERROR_MSG("CopyID=:=0 : ~w", [{TeamData, MapTeam}]);
                _ ->
                    ok
            end,
            {ok, _PID} = map_sup:start_map(CopyID, TeamID, common_config:get_server_id(), MapTeam),
            common_broadcast:bc_role_info_to_roles(RoleList, {mod, mod_role_map, {copy_team_start, CopyID, TeamID}})
        end).

do_copy_end(TeamID) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{role_list = RoleList} = TeamData ->
            mod_team_data:set_team_data(TeamData#r_team{is_start = false}),
            [ mod_team_request:leave_team(RobotID)|| RobotID <- RoleList, RobotID =< ?TEAM_ROBOT_NUM];
        _ ->
            ok
    end.