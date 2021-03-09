%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 五月 2018 16:44
%%%-------------------------------------------------------------------
-module(mod_role_world_level).
-author("WZP").

-include("common.hrl").
-include("act.hrl").
-include("bg_act.hrl").
-include("role.hrl").
-include("common_records.hrl").
-include("marry.hrl").
-include("proto/mod_role_world_level.hrl").
-include("role_extra.hrl").

%% API
-export([
    handle/2,
    calc/1,
    update_attr/1,
    online/1
]).

-export([
    get_world_level_add/1
]).


online(#r_role{role_id = RoleID} = State) ->
    Level = world_data:get_world_level(),
    common_misc:unicast(RoleID, #m_world_level_toc{level = Level}),
    State.


handle(update_world_level, State) ->
    update_attr(State);
handle(bg_act, State) ->
    update_attr(State);
handle(Info, State) ->
    ?ERROR_MSG("unkow info :~w", [Info]),
    State.

update_attr(#r_role{role_id = RoleID} = State) ->
    WorldLevel = world_data:get_world_level(),
    common_misc:unicast(RoleID, #m_world_level_toc{level = WorldLevel}),
    mod_role_fight:calc_attr_and_update(calc(State), ?POWER_UPDATE_WORLD_LEVEL, WorldLevel).

calc(State) ->
    ExpAdd1 = get_world_level_add(State),
    ExpAdd2 = ?IF(mod_role_bg_act:is_bg_act_open(?BG_ACT_DOUBLE_EXP, State), calc_bg_exp_add(State), 0),
    CalcAttr = #actor_cal_attr{monster_exp_add = {ExpAdd1 + ExpAdd2, 0}},
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_WORLD, CalcAttr).

get_world_level_add(#r_role{role_attr = #r_role_attr{level = Level}} = State) ->
    WorldLevel = world_data:get_world_level(),
    Difference = WorldLevel - Level,
    IsGMAdd = mod_role_extra:get_data(?EXTRA_KEY_WORLD_LEVEL_ADD, true, State),
    case Level >= ?WORLD_LEVEL_OPEN_LV andalso Difference > 10 andalso IsGMAdd of
        true ->
            %% 世界等级经验加成： MIN(50, MAX(0,世界等级-玩家等级-10))*6%
            erlang:min(50, Difference - 10) * ?WORLD_LEVEL_EVERY_RATE;
        _ ->
            0
    end.


calc_bg_exp_add(State) ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_DOUBLE_EXP),
    Condition = proplists:get_value(condition, BgInfo#r_bg_act.config),
    case check_is_fit(Condition, State) of
        false ->
            0;
        _ ->
            Rate = proplists:get_value(rate, BgInfo#r_bg_act.config),
            lib_tool:to_integer(?RATE_10000 * (Rate - 1))
    end.

check_is_fit([], _State) ->
    false;
check_is_fit([Condition|T], State) ->
    case Condition of
        {?BG_DOUBLE_EXP_ALL} ->
            true;
        {?BG_DOUBLE_EXP_LOVERS} ->
            RoleMarry = State#r_role.role_marry,
            case ?HAS_COUPLE(RoleMarry#r_role_marry.couple_id) of
                true ->
                    true;
                _ ->
                    check_is_fit(T, State)
            end;
        _ ->
            check_is_fit(T, State)
    end.
