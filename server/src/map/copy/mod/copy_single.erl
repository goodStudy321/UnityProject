%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 六月 2017 16:36
%%%-------------------------------------------------------------------
-module(copy_single).
-author("laijichang").
-include("global.hrl").
-include("proto/copy_single.hrl").

%% API
-export([
    handle/1
]).

-export([
    monster_reach/2
]).

monster_reach(MonsterID, RecordPos) ->
    DataRecord = #m_monster_reach_toc{monster_id = MonsterID},
    map_server:broadcast_by_pos(RecordPos, DataRecord).


handle({#m_single_summon_tos{monster = Monster}, _RoleID, _PID}) ->
    do_summon_monster(Monster);
handle({#m_single_ai_tos{monster_id = MonsterID, type = Type, args = Args}, RoleID, _PID}) ->
    do_single_ai(RoleID, MonsterID, Type, Args);
handle(Info) ->
    ?INFO_MSG("unknow info : ~w", [Info]).

do_summon_monster(Monster) ->
    case map_misc:is_copy_front(map_common_dict:get_map_id()) orelse common_config:is_debug() of
        true ->
            mod_map_monster:summon_monsters([Monster]);
        _ ->
            ignore
    end.

do_single_ai(RoleID, MonsterID, Type, Args) ->
    mod_map_monster:single_ai(RoleID, MonsterID, Type, Args).
