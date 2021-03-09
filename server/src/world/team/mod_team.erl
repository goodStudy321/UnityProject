%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2018 10:07
%%%-------------------------------------------------------------------
-module(mod_team).
-author("laijichang").
-include("global.hrl").
-include("team.hrl").

%% API
-export([
    loop/1,
    loop_min/0
]).

loop(Now) ->
    [ begin
          case mod_team_data:get_team_data(TeamID) of
              #r_team{start_copy_time = StartCopyTime} = TeamData ->
                  ?IF(Now >= StartCopyTime, mod_team_copy:do_stop_copy2(TeamData, ?CONDITION_TYPE_TIMEOUT, 0), ok);
              _ ->
                  mod_team_data:del_team_start_list(TeamID)
          end
      end|| TeamID <- mod_team_data:get_team_start_list()].

loop_min() ->
    Now = time_tool:now(),
    AllTeam = mod_team_data:get_all_team(),
    [LoopAdd, _CopyEquipAdd, _BossAdd] = common_misc:get_global_list(?GLOBAL_FRIENDLY_ADD),
    [begin
         #r_team{team_id = TeamID, role_list = RoleList, dissolve_time = DissolveTime, add_friendly_time = AddTime} = TeamData,
         if
             DissolveTime =/= 0 andalso Now >= DissolveTime -> %% 下线久了要解散队伍
                 ?WARNING_MSG("dissolve team : ~w", [{DissolveTime, TeamID}]),
                 dissolve_team(TeamData);
             Now >= AddTime ->
                 AddRoleIDs = [
                     begin
                         #r_role_team{is_online = IsOnline} = mod_team_data:get_role_team(RoleID),
                         ?IF(IsOnline, RoleID, [])
                     end|| RoleID <- RoleList, RoleID > ?TEAM_ROBOT_NUM],
                 AddRoleIDs2 = lists:flatten(AddRoleIDs),
                 mod_team_data:set_team_data(TeamData#r_team{add_friendly_time = team_misc:get_add_friendly_time(Now)}),
                 world_friend_server:add_friendly(team_misc:get_friendly_add_list(AddRoleIDs2), LoopAdd);
             true ->
                 ok
         end
     end || TeamData <- AllTeam].

dissolve_team(TeamData) ->
    #r_team{
        team_id = TeamID,
        copy_id = CopyID,
        role_list = RoleIDList} = TeamData,
    [begin
         RoleTeam = mod_team_data:get_role_team(RoleID),
         RoleTeam2 = RoleTeam#r_role_team{team_id = 0},
         mod_team_data:set_role_team(RoleTeam2),
         hook_team:role_leave_team(RoleID, TeamID)
     end|| RoleID <- RoleIDList],
    mod_team_data:del_team_data(TeamID),
    mod_team_data:del_team_match(CopyID, TeamID),
    mod_team_data:del_team_start_list(TeamID).