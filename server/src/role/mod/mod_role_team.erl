%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2017 12:07
%%%-------------------------------------------------------------------
-module(mod_role_team).
-author("laijichang").
-include("role.hrl").
-include("team.hrl").
-include("hunt_treasure.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    role_enter_map/1,
    offline/1,
    role_level/1,
    role_rename/1,
    update_role_info/1,
    handle/2
]).

-export([
    member_join/2,
    member_leave/2
]).

init(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_team{team_id = TeamID} = mod_team_data:get_role_team(RoleID),
    RoleAttr2 = RoleAttr#r_role_attr{team_id = TeamID},
    State#r_role{role_attr = RoleAttr2}.

calc(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{team_id = TeamID} = RoleAttr,
    case ?HAS_TEAM(TeamID) of
        true ->
            RoleList = team_misc:get_team_role_ids(TeamID),
            Len = erlang:length(RoleList),
            if
                Len =:= 2 ->
                    Attr = #actor_cal_attr{monster_exp_add = {1500, 0}};
                Len =:= 3 ->
                    Attr = #actor_cal_attr{monster_exp_add = {3000, 0}};
                true ->
                    Attr = #actor_cal_attr{}
            end;
        _ ->
            Attr = #actor_cal_attr{}
    end,
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_TEAM, Attr).

online(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, team_id = TeamID} = RoleAttr,
    update_role_info(State),
    case ?HAS_TEAM(TeamID) of
        true ->
            mod_team_role:role_online(RoleID),
            mod_role_copy:update_role_team(State);
        _ ->
            ok
    end,
    State.

role_enter_map(State) ->
    update_role_info(State).

offline(State) ->
    #r_role{role_id = RoleID} = State,
    mod_team_role:role_offline(RoleID),
    State.

role_level(State) ->
    update_role_info(State).

role_rename(State) ->
    update_role_info(State).

update_role_info(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_attr = RoleAttr} = State,
    #r_role_map{map_id = MapID} = RoleMap,
    #r_role_attr{
        level = Level,
        sex = Sex,
        category = Category,
        role_name = RoleName,
        skin_list = SkinList,
        ornament_list = OrnamentList} = RoleAttr,
    mod_team_role:role_info_update(RoleID, MapID, Level, Sex, Category, RoleName, SkinList, OrnamentList).


member_join(RoleID, JoinRoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {member_join, JoinRoleID}}).

member_leave(RoleID, LeaveRoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {member_leave, LeaveRoleID}}).

handle({#m_team_create_tos{}, RoleID, _PID}, State) ->
    do_team_create(RoleID, State);
handle({#m_team_invite_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    do_team_invite(RoleID, DestRoleID, State);
handle({#m_team_invite_reply_tos{op_type = OpType, team_id = TeamID, role_id = DestRoleID}, RoleID, _PID}, State) ->
    mod_team_request:invite_reply_team(RoleID, DestRoleID, {OpType, TeamID}),
    State;
handle({#m_team_apply_tos{team_id = TeamID, role_id = DestRoleID}, RoleID, _PID}, State) ->
    mod_team_request:apply_team(RoleID, TeamID, DestRoleID),
    State;
handle({#m_team_apply_reply_tos{op_type = OpType, role_id = DestRoleID}, RoleID, _PID}, State) ->
    mod_team_request:apply_reply_team(RoleID, DestRoleID, OpType),
    State;
handle({#m_team_leave_tos{}, RoleID, _PID}, State) ->
    mod_team_request:leave_team(RoleID),
    State;
handle({#m_team_kick_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    mod_team_request:kick_role(RoleID, DestRoleID),
    State;
handle({#m_team_captain_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    mod_team_request:change_captain(RoleID, DestRoleID),
    State;
handle({#m_team_set_copy_info_tos{copy_id = CopyID, min_level = MinLevel, max_level = MaxLevel}, RoleID, _PID}, State) ->
    mod_team_request:set_copy_info(RoleID, CopyID, MinLevel, MaxLevel),
    State;
handle({#m_team_copy_info_tos{copy_id = CopyID}, RoleID, _PID}, State) ->
    mod_team_request:get_copy_team(RoleID, CopyID, mod_role_data:get_role_level(State)),
    State;
handle({#m_team_start_copy_tos{enter_copy_id = EnterCopyID}, RoleID, _PID}, State) ->
    do_start_copy(RoleID, EnterCopyID, State);
handle({#m_team_copy_ready_tos{is_ready = IsReady}, RoleID, _PID}, State) ->
    ?IF(IsReady, mod_team_copy:get_ready(RoleID), mod_team_copy:refuse_ready(RoleID)),
    State;

handle({#m_team_guide_match_tos{}, RoleID, _PID}, State) ->
    #r_role{role_attr = #r_role_attr{level = RoleLevel, team_id = TeamID}} = State,
    ?IF(RoleLevel =< 200 andalso (not ?HAS_TEAM(TeamID)), mod_team_match:role_robot_match(RoleID), ok),
    State;
handle({#m_team_match_tos{copy_id = CopyID, matching = Matching}, RoleID, _PID}, State) ->
    ?IF(Matching, mod_team_match:role_match(RoleID, CopyID), mod_team_match:role_cancel_match(RoleID)),
    State;
handle({#m_team_recruit_tos{sub_type = SubType}, RoleID, _PID}, State) ->
    do_team_recruit(RoleID, SubType, State),
    State;
handle({join_team, RoleID, TeamID, TeamData}, State) ->
    do_join_team(RoleID, TeamID, TeamData, State);
handle({leave_team, RoleID, TeamID}, State) ->
    do_leave_team(RoleID, TeamID, State);
handle({member_join, JoinRoleID}, State) ->
    do_member_join(JoinRoleID, State);
handle({member_leave, LeaveRoleID}, State) ->
    do_member_leave(LeaveRoleID, State);
handle({invite_team, RoleID, DestRoleID}, State) ->
    do_team_invite(RoleID, DestRoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]),
    State.

%% 创建队伍
do_team_create(RoleID, State) ->
    case catch check_can_create(State) of
        {ok, TeamArgs} ->
            mod_team_request:create_team(RoleID, TeamArgs),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_create_toc{err_code = ErrCode}),
            State
    end.

check_can_create(State) ->
    TeamArgs = #team_create_args{},
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{team_id = TeamID} = RoleAttr,
    ?IF(?HAS_TEAM(TeamID), ?THROW_ERR(?ERROR_TEAM_CREATE_001), ok),
    {ok, TeamArgs}.

%% 邀请别人加入队伍
do_team_invite(RoleID, DestRoleID, State) ->
    case catch check_can_invite(State) of
        ok ->
            mod_team_request:invite_team(RoleID, DestRoleID),
            State;
        create ->
            case mod_team_request:create_team(RoleID, #team_create_args{}) of
                ok ->
                    role_misc:info_role(RoleID, {mod, ?MODULE, {invite_team, RoleID, DestRoleID}}),
                    State;
                Error ->
                    ?ERROR_MSG("create team : ~w", [Error]),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_invite_toc{err_code = ErrCode}),
            State
    end.

check_can_invite(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{team_id = TeamID} = RoleAttr,
    ?IF(?HAS_TEAM(TeamID), ok, create).

%% 角色招募
do_team_recruit(RoleID, SubType, State) ->
    case catch check_team_recruit(State) of
        {ok, ChatInfo, MapID, MinLevel, MaxLevel, TeamID} ->
            DataRecord = #m_team_recruit_toc{
                role_info = ChatInfo,
                map_id = MapID,
                min_level = MinLevel,
                max_level = MaxLevel,
                team_id = TeamID,
                sub_type = SubType},
            Condition = #r_broadcast_condition{min_level = MinLevel, max_level = MaxLevel},
            mod_role_dict:add_key_time(team_recruit, ?ONE_MINUTE div 2),
            common_broadcast:bc_record_to_world_by_condition(DataRecord, Condition);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_recruit_toc{err_code = ErrCode})
    end.

check_team_recruit(State) ->
    #r_role{role_attr = #r_role_attr{team_id = TeamID}, role_map = #r_role_map{map_id = MapID}} = State,
    ?IF(?HAS_TEAM(TeamID), ok, ?THROW_ERR(?ERROR_TEAM_RECRUIT_001)),
    mod_role_dict:is_time_able(team_recruit),
    #r_team{
        copy_id = CopyID,
        min_level = MinLevel,
        max_level = MaxLevel,
        role_list = RoleList
    } = mod_team_data:get_team_data(TeamID),
    ?IF(erlang:length(RoleList) < ?MAX_TEAM_NUM, ok, ?THROW_ERR(?ERROR_TEAM_RECRUIT_002)),
    MapID2 = ?IF(CopyID =:= 0 orelse CopyID =:= common_misc:get_global_int(?GLOBAL_TEAM_WILD), MapID, CopyID),
    ChatInfo = mod_role_chat:get_p_chat_role(State),
    {ok, ChatInfo, MapID2, MinLevel, MaxLevel, TeamID}.

do_start_copy(RoleID, EnterCopyID, State) ->
    case catch check_start_copy(EnterCopyID, State) of
        {ok, EnterCopyID2} ->
            mod_team_copy:start_copy(RoleID, EnterCopyID2),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_team_start_copy_toc{err_code = ErrCode}),
            State
    end.

check_start_copy(EnterCopyID, State) ->
    case map_misc:is_copy_treasure(EnterCopyID) of
        true ->
            #r_role{role_hunt_treasure = #r_role_hunt_treasure{end_time = EndTime, event_id = EventID}} = State,
            ?IF(time_tool:now() < EndTime, ok, ?THROW_ERR(?ERROR_TEAM_START_COPY_005)),
            [#c_hunt_treasure_event{map_id = MapID}] = lib_config:find(cfg_hunt_treasure_event, EventID),
            {ok, MapID};
        _ ->
            {ok, EnterCopyID}
    end.

%% 角色加入队伍hook
do_join_team(RoleID, TeamID, TeamData, State) ->
    #r_role{role_attr = RoleAttr} = State,
    RoleAttr2 = RoleAttr#r_role_attr{team_id = TeamID},
    common_misc:unicast(RoleID, #m_team_info_toc{team_info = team_misc:trans_to_p_team(TeamData)}),
    world_broadcast_server:role_add_channel(RoleID, [{?CHANNEL_TEAM, TeamID}]),
    mod_map_role:update_role_team(mod_role_dict:get_map_pid(), RoleID, TeamID),
    State2 = State#r_role{role_attr = RoleAttr2},
    mod_role_copy:update_role_team(State2),
    role_enter_map(State2),
    State3 = mod_role_skill:add_team_buffs(State2),
    State4 = mod_role_friend:do_add_friend_buff(State3),

    ?IF(TeamData#r_team.captain_role_id =/= RoleID, common_broadcast:send_team_common_notice(TeamData#r_team.role_list, ?NOTICE_TEAM_JOIN_TEAM,
        [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State4), lib_tool:to_list(RoleAttr#r_role_attr.level)]), ok),

    ?IF(TeamData#r_team.captain_role_id =:= RoleID, common_broadcast:send_team_common_notice(TeamID, ?NOTICE_TEAM_CAPTAIN_TEAM,
        [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State4), lib_tool:to_list(RoleAttr#r_role_attr.level)]), ok),
    mod_role_fight:calc_attr_and_update(calc(State4)).

%% 角色离开队伍hook
do_leave_team(RoleID, OldTeamID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    TeamID = 0,
    RoleAttr2 = RoleAttr#r_role_attr{team_id = TeamID},
    common_misc:unicast(RoleID, #m_team_leave_toc{}),
    world_broadcast_server:role_leave_channel(RoleID, [{?CHANNEL_TEAM, OldTeamID}]),
    mod_map_role:update_role_team(mod_role_dict:get_map_pid(), RoleID, TeamID),
    State2 = State#r_role{role_attr = RoleAttr2},
    State3 = mod_role_buff:role_leave_team(State2),
    State4 = mod_role_skill:add_team_buffs(State3),
    common_broadcast:send_team_common_notice(OldTeamID, ?NOTICE_TEAM_LEAVE_TEAM,
        [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State4), lib_tool:to_list(RoleAttr#r_role_attr.level)]),
    mod_role_fight:calc_attr_and_update(calc(State4)).

do_member_join(JoinRoleID, State) ->
    State2 = mod_role_skill:member_join(JoinRoleID, State),
    State3 = mod_role_friend:member_change(JoinRoleID, State2),
    mod_role_fight:calc_attr_and_update(calc(State3)).

do_member_leave(LeaveRoleID, State) ->
    State2 = mod_role_buff:member_leave(LeaveRoleID, State),
    State3 = mod_role_friend:member_change(LeaveRoleID, State2),
    mod_role_fight:calc_attr_and_update(calc(State3)).
