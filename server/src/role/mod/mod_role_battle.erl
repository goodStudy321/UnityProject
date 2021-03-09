%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 三月 2018 19:39
%%%-------------------------------------------------------------------
-module(mod_role_battle).
-author("laijichang").
-include("role.hrl").
-include("battle.hrl").
-include("proto/mod_battle.hrl").
-include("daily_liveness.hrl").
%% API
-export([
    check_role_pre_enter/3,
    role_enter_map/1,
    is_battle_able/1,
    gm_camp_change/2
]).

check_role_pre_enter(RoleID, MapID, MaxPower) ->
    case catch mod_battle:role_pre_enter(RoleID, MaxPower) of
        {ok, ServerID, ExtraID, CampID, RecordPos2} ->
            {MapID, ExtraID, ServerID, CampID, RecordPos2};
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode)
    end.

role_enter_map(State) ->
    case ?IS_MAP_BATTLE(State#r_role.role_map#r_role_map.map_id) of
        true ->
            RoleID = State#r_role.role_id,
            RankInfos = mod_battle:role_get_rank_info(RoleID),
            common_misc:unicast(State#r_role.role_id, #m_battle_rank_info_toc{ranks = RankInfos}),
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_ACTIVITY_BATTLE);
        _ ->
            State
    end.

is_battle_able(State) ->
    #r_role{role_id = RoleID} = State,
    #r_role_battle{extra_id = ExtraID} = mod_battle:get_role_battle(RoleID),
    ?IF(ExtraID > 0, true, false).

gm_camp_change(CampID, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{camp_id = CampID},
    mod_battle:gm_camp_change(RoleID, CampID),
    mod_map_role:update_role_camp(mod_role_dict:get_map_pid(), RoleID, CampID),
    State#r_role{role_map = RoleMap2}.