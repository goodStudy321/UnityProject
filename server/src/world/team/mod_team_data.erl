%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十月 2017 19:30
%%%-------------------------------------------------------------------
-module(mod_team_data).
-author("laijichang").
-include("team.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    init/0
]).

-export([
    get_new_team_id/0
]).

-export([
    get_all_team/0,
    set_team_data/1,
    get_team_data/1,
    del_team_data/1,
    set_role_team/1,
    get_role_team/1,

    add_team_match/2,
    del_team_match/2,
    set_team_match/2,
    get_team_match/1,

    add_role_match/2,
    del_role_match/2,
    set_role_match/2,
    get_role_match/1,

    add_team_start_list/1,
    del_team_start_list/1,
    get_team_start_list/0,
    set_team_start_list/1
]).

-export([
    gm_get_team_match/1
]).

init() ->
    init_ets(),
    set_team_id(common_id:get_team_start_id()),
    set_team_start_list([]).

init_ets() ->
    lib_tool:init_ets(?ETS_TEAM_DATA, #r_team.team_id),
    lib_tool:init_ets(?ETS_ROLE_TEAM, #r_role_team.role_id).

get_new_team_id() ->
    LastID = get_team_id(),
    set_team_id(common_id:get_team_next_id(LastID)),
    LastID.

gm_get_team_match(CopyID) ->
    team_misc:call_team({func, fun() -> ?MODULE:get_team_match(CopyID) end}).
%%%===================================================================
%%% 数据操作
%%%===================================================================
set_team_id(TeamID) ->
    erlang:put({?MODULE, team_id}, TeamID).
get_team_id() ->
    erlang:get({?MODULE, team_id}).

get_all_team() ->
    ets:tab2list(?ETS_TEAM_DATA).
set_team_data(TeamData) ->
    ets:insert(?ETS_TEAM_DATA, TeamData).
get_team_data(TeamID) ->
    case ets:lookup(?ETS_TEAM_DATA, TeamID) of
        [#r_team{} = TeamData] -> TeamData;
        _ -> undefined
    end.
del_team_data(TeamID) ->
    ets:delete(?ETS_TEAM_DATA, TeamID).

set_role_team(RoleTeam) ->
    ets:insert(?ETS_ROLE_TEAM, RoleTeam).
get_role_team(RoleID) ->
    case ets:lookup(?ETS_ROLE_TEAM, RoleID) of
        [#r_role_team{} = RoleTeam] -> RoleTeam;
        _ -> #r_role_team{role_id = RoleID, team_id = 0}
    end.

add_team_match(CopyID, TeamID) ->
    TeamList = get_team_match(CopyID),
    set_team_match(CopyID, [TeamID|lists:delete(TeamID, TeamList)]).
del_team_match(CopyID, TeamID) ->
    TeamList = get_team_match(CopyID),
    set_team_match(CopyID, lists:delete(TeamID, TeamList)).
set_team_match(CopyID, TeamList) ->
    erlang:put({?MODULE, team_match, CopyID}, TeamList).
get_team_match(CopyID) ->
    case erlang:get({?MODULE, team_match, CopyID}) of
        List when erlang:is_list(List) -> List;
        _ -> []
    end.

add_role_match(CopyID, RoleID) ->
    RoleList = get_role_match(CopyID),
    set_role_match(CopyID, [RoleID|lists:delete(RoleID, RoleList)]).
del_role_match(CopyID, RoleID) ->
    RoleList = get_role_match(CopyID),
    set_role_match(CopyID, lists:delete(RoleID, RoleList)).
set_role_match(CopyID, RoleList) ->
    erlang:put({?MODULE, role_match, CopyID}, RoleList).
get_role_match(CopyID) ->
    case erlang:get({?MODULE, role_match, CopyID}) of
        List when erlang:is_list(List) -> List;
        _ -> []
    end.

add_team_start_list(TeamID) ->
    TeamList = get_team_start_list(),
    case lists:member(TeamID, TeamList) of
        true ->
            ok;
        _ ->
            set_team_start_list([TeamID|TeamList])
    end.
del_team_start_list(TeamID) ->
    set_team_start_list(lists:delete(TeamID, get_team_start_list())).
get_team_start_list() ->
    erlang:get({?MODULE, team_start_list}).
set_team_start_list(List) ->
    erlang:put({?MODULE, team_start_list}, List).