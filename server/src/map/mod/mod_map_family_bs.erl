%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 五月 2018 20:05
%%%-------------------------------------------------------------------
-module(mod_map_family_bs).
-author("WZP").
-include("common.hrl").
-include("family_boss.hrl").
-include("monster.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_family_bs.hrl").

%% API
-export([
    handle/1
]).

-export([
    boss_killed/0
]).




do_get_boss_time() ->
    {ok, get_open_time(), get_boss_dead_state()}.

handle({boss_id, BossID}) ->
    init_boss(BossID);
handle(do_map_end_i) ->
    do_map_end();
handle(get_boss_time) ->
    do_get_boss_time();
handle(boss_killed) ->
    do_boss_killed();
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).


init_boss(BoosID) ->
    [BossConfig] = lib_config:find(cfg_family_boss, BoosID),
    [X, Z, D] = BossConfig#c_family_boss.point,
    RecordPos = map_misc:get_pos_by_offset_pos(X, Z, D),
    MonsterData = [#r_monster{type_id = BossConfig#c_family_boss.boss_id, born_pos = RecordPos}],
    mod_map_monster:born_monsters(MonsterData),
    Time = time_tool:now(),
    set_open_time(Time),
    set_boss_dead_state(0).


do_map_end() ->
    mod_role_daily_liveness:trigger_daily_liveness(mod_map_ets:get_in_map_roles(), ?LIVENESS_FAMILY_BS),
    map_server:kick_all_roles(),
    map_server:delay_shutdown().


do_boss_killed() ->
    set_boss_dead_state(time_tool:now()),
    Time = get_open_time(),
    DeadTime = get_boss_dead_state(),
    DataRecord = #m_family_boss_time_toc{time = Time, dead = DeadTime,delayed = ?FAMILY_BOSS_MAP_END_DELAY},
    map_server:send_all_gateway(DataRecord),
    erlang:send_after(120000, erlang:self(), {mod, mod_map_family_bs, do_map_end_i}).

boss_killed() ->
    pname_server:send(map_common_dict:get_map_pid(), {mod, ?MODULE, boss_killed}).

set_open_time(Time) ->
    erlang:put({?MODULE, time}, Time).

get_open_time() ->
    erlang:get({?MODULE, time}).


set_boss_dead_state(State) ->
    erlang:put({?MODULE, boss}, State).

get_boss_dead_state() ->
    erlang:get({?MODULE, boss}).
