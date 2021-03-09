%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 四月 2018 21:09
%%%-------------------------------------------------------------------
-module(mod_role_family_as).
-author("WZP").

-include("global.hrl").
-include("map.hrl").
-include("activity.hrl").
-include("common.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_family_as.hrl").
-include("family_as.hrl").
-include("role.hrl").
-include("daily_liveness.hrl").
-include("family.hrl").

%% API


-export([
    check_role_pre_enter/1,
    role_join_family/1
]).


-export([
    handle/2,
    online/1
]).

-export([
    get_family_as_exp/1,
    is_able/1,
    is_activity_open/0
]).

-export([
    role_collect/1
]).

online(#r_role{role_attr = RoleAttr, role_id = RoleID} = State) ->
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    case ?HAS_FAMILY(FamilyID) of
        true ->
            MapPName = map_misc:get_map_pname(?MAP_FAMILY_AS, FamilyID),
            case erlang:whereis(MapPName) of
                PID when erlang:is_pid(PID) ->
                    pname_server:send(PID, {mod, mod_map_family_as, {do_get_question, RoleID}});
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    State.

role_join_family(#r_role{role_attr = RoleAttr, role_id = RoleID}) ->
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    MapPName = map_misc:get_map_pname(?MAP_FAMILY_AS, FamilyID),
    case erlang:whereis(MapPName) of
        PID when erlang:is_pid(PID) ->
            pname_server:send(PID, {mod, mod_map_family_as, {do_get_question, RoleID}});
        _ ->
            ok
    end.


check_role_pre_enter(#r_role{role_attr = RoleAttr}) ->
    #r_role_attr{level = Level, family_id = ExtraID, role_id = RoleID} = RoleAttr,
    case catch check_pre_enter(Level, ExtraID, RoleID) of
        {ok, RecordPos} ->
            {ExtraID, ?DEFAULT_CAMP_ROLE, RecordPos};
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode)
    end.

check_pre_enter(Level, ExtraID, RoleID) ->
    ?IF(Level < ?FAMILY_AS_LEVEL, ?THROW_ERR(?ERROR_PRE_ENTER_001), ok),
    Activity = world_activity_server:get_activity(?ACTIVITY_FAMILY_AS),
    ?IF(Activity#r_activity.status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_PRE_ENTER_003)),
    RoleAsExp = mod_role_family_as:get_family_as_exp(RoleID),
    case RoleAsExp#r_family_as_exp.add_daily_liveness of
        true ->
            ok;
        _ ->
            mod_role_daily_liveness:trigger_daily_liveness(RoleID,?LIVENESS_FAMILY_ANSWER),
            set_family_as_exp(RoleAsExp#r_family_as_exp{add_daily_liveness = true})
    end,
    MapPName = map_misc:get_map_pname(?MAP_FAMILY_AS, ExtraID),
    case erlang:whereis(MapPName) of
        PID when erlang:is_pid(PID) ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_024)
    end,
    map_misc:get_born_pos(?MAP_FAMILY_AS).

role_collect(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, role_collect}).

handle(add_reward, State) ->
    do_add_reward(State);
handle(right_answer, State) ->
    do_right_answer(State);
handle(role_collect, State) ->
    do_role_collect(State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info: ~w", [Info]),
    State.



do_add_reward(#r_role{role_id = RoleID, role_attr = Attr} = State) ->
    [Config] = lib_config:find(cfg_global, ?FAMILY_AS_ADD_EXP_TIME),
    [_, Rate, Contribute, _] = Config#c_global.list,
    AddExp = mod_role_level:get_activity_level_exp(Attr#r_role_attr.level, Rate),
    RoleAsExp = get_family_as_exp(RoleID),
    NewRoleAsExp = RoleAsExp#r_family_as_exp{exp = RoleAsExp#r_family_as_exp.exp + AddExp},
    set_family_as_exp(NewRoleAsExp),
    common_misc:unicast(RoleID, #m_family_as_exp_toc{exp = NewRoleAsExp#r_family_as_exp.exp}),
    State2 = mod_role_level:do_add_exp(State, AddExp, ?EXP_ADD_FROM_FAMILY_ANSWER),
    AssetDoing = [{add_score, ?ASSET_FAMILY_AS_TURN_OVER, ?ASSET_FAMILY_CON, Contribute}],
    mod_role_asset:do(AssetDoing, State2).



do_right_answer(State) ->
    [Config] = lib_config:find(cfg_global, ?FAMILY_AS_ADD_EXP_TIME),
    [_, _, _, Contribute] = Config#c_global.list,
    AssetDoing = [{add_score, ?ASSET_FAMILY_AS_TURN_OVER, ?ASSET_FAMILY_CON, Contribute}],
    State2 = mod_role_asset:do(AssetDoing, State),
    mod_role_achievement:family_answer(State2).

do_role_collect(State) ->
    mod_role_achievement:family_collect(State).


%% 更变积分数据
set_family_as_exp(RoleExp) ->
    ets:insert(?ETS_FAMILY_AS_EXP, RoleExp).

get_family_as_exp(RoleID) ->
    case ets:lookup(?ETS_FAMILY_AS_EXP, RoleID) of
        [#r_family_as_exp{} = RoleExp] ->
            RoleExp;
        _ ->
            #r_family_as_exp{role_id = RoleID, exp = 0}
    end.



is_able(State) ->
    #r_role{role_attr = #r_role_attr{last_offline_time = LastOfflineTime}} = State,
    case is_activity_open() of
        true ->
            case time_tool:is_same_date(LastOfflineTime, time_tool:now()) of
                true ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

is_activity_open() ->
    #r_activity{status = Status} = world_activity_server:get_activity(?ACTIVITY_FAMILY_AS),
    Status =:= ?STATUS_OPEN.