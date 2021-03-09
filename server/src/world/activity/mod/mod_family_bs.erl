%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 五月 2018 19:23
%%%-------------------------------------------------------------------
-module(mod_family_bs).
-author("WZP").
-include("map.hrl").
-include("role.hrl").
-include("common.hrl").
-include("common_records.hrl").
-include("activity.hrl").
-include("family_boss.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    init/0,
    activity_prepare/0,
    activity_end/0,
    handle/1
]).

-export([
    open_family_boss/1,
    gm_update_family_grain/3,
    get_boss_id_by_world_lv/1
]).

init() ->
    set_family_bs_ctrl(#r_family_boss_ctrl{status = ?FAMILY_BOSS_CLOSE, family_list = []}).


activity_prepare() ->
    set_open_list([]),
    Level = get_world_lv(),
    BossID = get_boss_id_by_world_lv(Level),
    set_boss_id(BossID),
    set_family_bs_ctrl(#r_family_boss_ctrl{status = ?FAMILY_BOSS_OPEN, family_list = []}).


activity_end() ->
    do_map_end(),
    set_family_bs_ctrl(#r_family_boss_ctrl{status = ?FAMILY_BOSS_CLOSE, family_list = []}).


handle({gm_update_grain, RoleID, Grain, Times}) ->
    do_update_grain(RoleID, Grain, Times);
handle({open_family_boss, Family}) ->
    start_map(Family);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

do_map_end() ->
    ok.

start_map(Family) ->
    case lists:member(Family, get_open_list()) of
        true ->
            {error, ?ERROR_FAMILY_BOSS_005};
        _ ->
            set_open_list([Family|get_open_list()]),
            MapPName = map_misc:get_map_pname(?MAP_FAMILY_BOSS, Family),
            case erlang:whereis(MapPName) of
                PID when erlang:is_pid(PID) ->
                    ?THROW_ERR(?ERROR_FAMILY_BOSS_004);
                _ ->
                    {ok, MapPID} = map_sup:start_map(?MAP_FAMILY_BOSS, Family),
                    pname_server:send(MapPID, {mod, mod_map_family_bs, {boss_id, get_boss_id()}}),
                    Ctrl = get_family_bs_ctrl(),
                    set_family_bs_ctrl(Ctrl#r_family_boss_ctrl{family_list = [Family|Ctrl#r_family_boss_ctrl.family_list]}),
                    {ok, MapPID}
            end
    end.

set_family_bs_ctrl(FamilyList) ->
    erlang:put({?MODULE, ctrl}, FamilyList).

get_family_bs_ctrl() ->
    erlang:get({?MODULE, ctrl}).

set_boss_id(BossID) ->
    erlang:put({?MODULE, boss_id}, BossID).

get_boss_id() ->
    erlang:get({?MODULE, boss_id}).

get_open_list() ->
    erlang:get({?MODULE, open_familys}).

set_open_list(FamilyList) ->
    erlang:put({?MODULE, open_familys}, FamilyList).

get_world_lv() ->
    world_data:get_world_level().

get_boss_id_by_world_lv(Level) ->
    [Config] = lib_config:find(cfg_family_boss, 1),
    ?IF(Config#c_family_boss.level > Level, Config#c_family_boss.id, get_boss_id_by_world_lv(Config, Level)).

get_boss_id_by_world_lv(Config, Level) ->
    case lib_config:find(cfg_family_boss, Config#c_family_boss.id + 1) of
        [] ->
            Config#c_family_boss.id;
        [NextConfig] ->
            case NextConfig#c_family_boss.level > Level of
                true ->
                    Value1 = NextConfig#c_family_boss.level - Level,
                    Value2 = Level - Config#c_family_boss.level,
                    ?IF(Value1 > Value2, Config#c_family_boss.id, NextConfig#c_family_boss.id);
                _ ->
                    get_boss_id_by_world_lv(NextConfig, Level)
            end
    end.

open_family_boss(FamilyID) ->
    world_activity_server:call({mod, ?MODULE, {open_family_boss, FamilyID}}).


gm_update_family_grain(#r_role{role_id = RoleID} = State, Grain, Times) ->
    FamilyData = family_misc:call_family({mod, ?MODULE, {gm_update_grain, RoleID, Grain, Times}}),
    BoxList = mod_role_family:get_role_family_box(FamilyData#p_family.family_id, RoleID),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = FamilyData, box_list = BoxList}),
    State.

do_update_grain(_RoleID, _Grain, _Times) ->
    ok.
%%    RoleFamily = mod_family_data:get_role_family(RoleID),
%%    Family = mod_family_data:get_family(RoleFamily#r_role_family.family_id),
%%    Family2 = Family#p_family{boss_grain = Grain, boss_times = Times},
%%    mod_family_data:set_family(Family2),
%%    Family2.