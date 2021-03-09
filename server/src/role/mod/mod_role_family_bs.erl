%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 五月 2018 10:29
%%%-------------------------------------------------------------------
-module(mod_role_family_bs).
-author("WZP").
-include("role.hrl").
-include("family.hrl").
-include("family_boss.hrl").
-include("proto/mod_role_family_bs.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    online/1,
    handle/2
]).

-export([
    check_role_pre_enter/1,
    role_join_family/1
]).




handle({#m_family_boss_time_tos{}, RoleID, _PID}, State) ->
    do_get_boss_time_tos(RoleID, State).

do_get_boss_time_tos(RoleID, State) ->
    case catch check_can_get_time(State) of
        {ok, Time, Dead} ->
            common_misc:unicast(RoleID, #m_family_boss_time_toc{time = Time, dead = Dead, delayed = ?FAMILY_BOSS_MAP_END_DELAY - time_tool:now() + Dead}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_boss_time_toc{err_code = ErrCode}),
            State
    end.


check_can_get_time(#r_role{role_attr = RoleAttr}) ->
    #r_role_attr{family_id = FamilyId} = RoleAttr,
    MapPName = map_misc:get_map_pname(?MAP_FAMILY_BOSS, FamilyId),
    case erlang:whereis(MapPName) of
        PID when erlang:is_pid(PID) ->
            pname_server:call(PID, {mod, mod_map_family_bs, get_boss_time});
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_BOSS_TIME_001)
    end.



online(#r_role{role_id = RoleID, role_attr = RoleAttr} = State) ->
    #r_role_attr{family_id = FamilyId} = RoleAttr,
    case ?HAS_FAMILY(FamilyId) of
        true ->
            MapPName = map_misc:get_map_pname(?MAP_FAMILY_BOSS, FamilyId),
            case erlang:whereis(MapPName) of
                PID when erlang:is_pid(PID) ->
                    DataRecord = #m_family_boss_notice_toc{type = ?FAMILY_BOSS_LOGIN_BC},
                    common_misc:unicast(RoleID, DataRecord);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    State.



role_join_family(#r_role{role_id = RoleID, role_attr = RoleAttr}) ->
    #r_role_attr{family_id = FamilyId} = RoleAttr,
    MapPName = map_misc:get_map_pname(?MAP_FAMILY_BOSS, FamilyId),
    case erlang:whereis(MapPName) of
        PID when erlang:is_pid(PID) ->
            DataRecord = #m_family_boss_notice_toc{type = ?FAMILY_BOSS_LOGIN_BC},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.



check_role_pre_enter(#r_role{role_attr = Attr}) ->
    #r_role_attr{family_id = FamilyID} = Attr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_001)),
    {ok, RecordPos} = map_misc:get_born_pos(?MAP_FAMILY_BOSS),
    {FamilyID, ?DEFAULT_CAMP_ROLE, RecordPos}.




