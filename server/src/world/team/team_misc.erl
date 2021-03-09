%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2017 14:22
%%%-------------------------------------------------------------------
-module(team_misc).
-author("laijichang").
-include("copy.hrl").
-include("team.hrl").
-include("global.hrl").
-include("proto/mod_role_team.hrl").

%% API
-export([
    info_team/1,
    call_team/1,
    broadcast_record/2
]).

-export([
    get_captain/1,
    get_team_role_ids/1,
    add_team_friendly/2,
    get_friendly_add_list/1,
    get_add_friendly_time/0,
    get_add_friendly_time/1,
    get_team_invite/1
]).

-export([
    check_copy_pass/2,
    is_team_match/2
]).

-export([
    trans_to_p_team/1,
    trans_to_p_team_role/1
]).

info_team(Info) ->
    case world_team_server:is_team_server() of
        true ->
            world_team_server:handle(Info);
        _ ->
            pname_server:send(world_team_server, Info)
    end.

call_team(Info) ->
    case world_team_server:is_team_server() of
        true ->
            world_team_server:handle(Info);
        _ ->
            pname_server:call(world_team_server, Info)
    end.

%% team_server 内部调用
broadcast_record(TeamID, DataRecord) when erlang:is_integer(TeamID) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{} = TeamData ->
            broadcast_record(TeamData, DataRecord);
        _ ->
            ok
    end;
broadcast_record(TeamData, DataRecord) ->
    #r_team{role_list = RoleList} = TeamData,
    common_broadcast:bc_record_to_roles(RoleList, DataRecord).

%% 通过TeamID获取队长ID
get_captain(TeamID) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{captain_role_id = RoleID} ->
            RoleID;
        _ ->
            0
    end.

%% 通过TeamID获取RoleID列表
get_team_role_ids(TeamID) ->
    case mod_team_data:get_team_data(TeamID) of
        #r_team{role_list = RoleList} ->
            RoleList;
        _ ->
            []
    end.

add_team_friendly(TeamID, AddFriendly) ->
    RoleIDs = get_team_role_ids(TeamID),
    FriendlyList = get_friendly_add_list(RoleIDs),
    world_friend_server:add_friendly(FriendlyList, AddFriendly).

get_friendly_add_list(RoleIDs) ->
    get_friendly_add_list(RoleIDs, []).

get_friendly_add_list([], Acc) ->
    Acc;
get_friendly_add_list([RoleID|R], Acc) ->
    List = get_friendly_add_list2(RoleID, R, []),
    get_friendly_add_list(R, List ++ Acc).

get_friendly_add_list2(_RoleID, [], Acc) ->
    Acc;
get_friendly_add_list2(RoleID, [DestRoleID|R], Acc) ->
    Acc2 = [{RoleID, DestRoleID}|Acc],
    get_friendly_add_list2(RoleID, R, Acc2).

get_add_friendly_time() ->
    get_add_friendly_time(time_tool:now()).
get_add_friendly_time(Time) ->
    Time + 3 * ?ONE_MINUTE.

get_team_invite(RoleID) ->
    #r_role_attr{
        role_name = RoleName,
        level = RoleLevel,
        category = Category,
        sex = Sex
    } = common_role_data:get_role_attr(RoleID),
    #p_team_invite{
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        category = Category,
        sex = Sex
    }.

check_copy_pass(RoleID, CopyID) when erlang:is_integer(RoleID) ->
    check_copy_pass(mod_team_data:get_role_team(RoleID), CopyID);
check_copy_pass(RoleTeam, CopyID) ->
    #r_role_team{role_level = RoleLevel, team_id = TeamID, copy_list = CopyList} = RoleTeam,
    #r_team{role_list = RoleList} = mod_team_data:get_team_data(TeamID),
    [#c_copy{enter_level = EnterLevel, copy_type = CopyType, copy_degree = CopyDegree, times = ConfigTimes}] = lib_config:find(cfg_copy, CopyID),
    ?IF(RoleLevel >= EnterLevel, ok, erlang:throw(?LEVEL_LIMIT)),
    case lists:keyfind(CopyType, #p_kv.id, CopyList) of
        #p_kvt{val = Degree, type = Times} ->
            ok;
        _ ->
            Times = 0,
            Degree = 0
    end,
    ?IF(Degree >= CopyDegree orelse CopyDegree =< ?COPY_DEGREE_NORMAL, ok, erlang:throw(?COPY_DEGREE_LIMIT)),
%%    ?IF(ConfigTimes + Times > 0, ok, erlang:throw(?COPY_TIMES_LIMIT)),
    case erlang:length(RoleList) =:= 1 of
        true ->
            ?IF(ConfigTimes + Times > 0, ok, erlang:throw(?COPY_TIMES_LIMIT));
        _ ->
            Result = check_copy_pass2(ConfigTimes, CopyType, RoleList),
            ?IF(Result =:= false, erlang:throw(?COPY_TIMES_ALL_LIMITS), ok)
    end,
    ok.

check_copy_pass2(_ConfigTimes, _CopyType, []) ->
    false;
check_copy_pass2(ConfigTimes, CopyType, [RoleID | R]) ->
    #r_role_team{copy_list = CopyList} = mod_team_data:get_role_team(RoleID),
    case lists:keyfind(CopyType, #p_kv.id, CopyList) of
        #p_kvt{type = Times} ->
            ok;
        _ ->
            Times = 0
    end,
    case ConfigTimes + Times > 0 of
        true ->
            {ok, RoleID};
        _ ->
            check_copy_pass2(ConfigTimes, CopyType, R)
    end.

is_team_match(RoleLevel, TeamData) ->
    #r_team{
        min_level = MinLevel,
        max_level = MaxLevel,
        is_start = IsStart,
        role_list = TeamRoleList
    } = TeamData,
    erlang:length(TeamRoleList) < ?MAX_TEAM_NUM andalso (not IsStart) andalso MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel.

trans_to_p_team(TeamData) ->
    #r_team{
        team_id = TeamID,
        copy_id = CopyID,
        min_level = MinLevel,
        max_level = MaxLevel,
        captain_role_id = CaptainRoleID,
        role_list = TeamRoleList
    } = TeamData,
    #p_team{
        team_id = TeamID,
        copy_id = CopyID,
        min_level = MinLevel,
        max_level = MaxLevel,
        captain_role_id = CaptainRoleID,
        role_list = [ trans_to_p_team_role(RoleID) || RoleID <- TeamRoleList]
    }.

trans_to_p_team_role(RoleID) when erlang:is_integer(RoleID) ->
    trans_to_p_team_role(mod_team_data:get_role_team(RoleID));
trans_to_p_team_role(RoleTeam) ->
    #r_role_team{
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        category = Category,
        sex = Sex,
        is_online = IsOnline,
        map_id = MapID,
        skin_list = SkinList
    } = RoleTeam,
    #p_team_role{
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        category = Category,
        sex = Sex,
        is_online = IsOnline,
        map_id = MapID,
        skin_list = SkinList}.

