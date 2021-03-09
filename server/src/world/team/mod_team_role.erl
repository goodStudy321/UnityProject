%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2017 12:07
%%%-------------------------------------------------------------------
-module(mod_team_role).
-author("laijichang").
-include("global.hrl").
-include("team.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    role_online/1,
    role_offline/1,
    role_info_update/8,
    role_copy_update/2
]).

-export([
    handle/1
]).

role_online(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {role_online, RoleID}}).
role_offline(RoleID) ->
    team_misc:info_team({mod, ?MODULE, {role_offline, RoleID}}).
role_info_update(RoleID, MapID, Level, Sex, Category, RoleName, SkinList, OrnamentList) ->
    team_misc:info_team({mod, ?MODULE, {role_info_update, RoleID, MapID, Level, Sex,  Category, RoleName, SkinList, OrnamentList}}).
role_copy_update(RoleID, CopyList) ->
    team_misc:info_team({mod, ?MODULE, {role_copy_update, RoleID, CopyList}}).

handle({role_online, RoleID}) ->
    do_role_online(RoleID);
handle({role_offline, RoleID}) ->
    do_role_offline(RoleID);
handle({role_info_update, RoleID, MapID, Level, Sex, Category, RoleName, SkinList, OrnamentList}) ->
    do_role_info_update(RoleID, MapID, Level, Sex, Category, RoleName, SkinList, OrnamentList);
handle({role_copy_update, RoleID, CopyList}) ->
    do_role_copy_update(RoleID, CopyList);
handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

do_role_online(RoleID) ->
    case mod_team_data:get_role_team(RoleID) of
        #r_role_team{team_id = TeamID} = RoleTeam when ?HAS_TEAM(TeamID) ->
            mod_team_data:set_role_team(RoleTeam#r_role_team{is_online = true}),
            #r_team{role_list = RoleList} = TeamData = mod_team_data:get_team_data(TeamID),
            common_misc:unicast(RoleID, #m_team_info_toc{team_info = team_misc:trans_to_p_team(TeamData)}),
            update_other_role_info(RoleID, lists:delete(RoleID, RoleList)),
            mod_team_data:set_team_data(TeamData#r_team{dissolve_time = 0});
        _ ->
            ok
    end.

do_role_offline(RoleID) ->
    #r_role_team{team_id = TeamID, match_copy_id = MatchCopyID} = RoleTeam = mod_team_data:get_role_team(RoleID),
    mod_team_data:del_role_match(MatchCopyID, RoleID),
    RoleTeam2 = RoleTeam#r_role_team{match_copy_id = 0, is_online = false},
    mod_team_data:set_role_team(RoleTeam2),
    case ?HAS_TEAM(TeamID) of
        true ->
            mod_team_copy:do_stop_copy(RoleID, ?CONDITION_TYPE_OFFLINE),
            update_other_role_info(RoleID, lists:delete(RoleID, team_misc:get_team_role_ids(TeamID))),
            #r_team{role_list = RoleIDList} = TeamData = mod_team_data:get_team_data(TeamID),
            ?IF(is_all_offline(RoleIDList), mod_team_data:set_team_data(TeamData#r_team{dissolve_time = time_tool:now() + ?TEN_MINUTE}), ok);
        _ ->
            ok
    end.

do_role_info_update(RoleID, MapID, Level, Sex, Category, RoleName, SkinList, OrnamentList) ->
    #r_role_team{team_id = TeamID} = RoleTeam = mod_team_data:get_role_team(RoleID),
    RoleTeam2 = RoleTeam#r_role_team{
        map_id = MapID,
        role_level = Level,
        sex = Sex,
        category = Category,
        role_name = RoleName,
        skin_list = SkinList,
        ornament_list = OrnamentList},
    mod_team_data:set_role_team(RoleTeam2),
    update_other_role_info(RoleID, team_misc:get_team_role_ids(TeamID)).

do_role_copy_update(RoleID, CopyList) ->
    RoleTeam = mod_team_data:get_role_team(RoleID),
    mod_team_data:set_role_team(RoleTeam#r_role_team{copy_list = CopyList}).

update_other_role_info(_RoleID, []) ->
    ok;
update_other_role_info(RoleID, RoleList) ->
    DataRecord = #m_team_role_update_toc{role = team_misc:trans_to_p_team_role(RoleID)},
    common_broadcast:bc_record_to_roles(RoleList, DataRecord).

is_all_offline([]) ->
    true;
is_all_offline([RoleID|R]) ->
    #r_role_team{is_online = IsOnline} = mod_team_data:get_role_team(RoleID),
    ?IF(RoleID > ?TEAM_ROBOT_NUM andalso IsOnline, false, is_all_offline(R)).