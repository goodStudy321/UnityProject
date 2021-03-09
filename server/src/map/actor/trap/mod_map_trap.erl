%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2017 19:55
%%%-------------------------------------------------------------------
-module(mod_map_trap).
-author("laijichang").
-include("global.hrl").

%% API

%% mod_collection
-export([
    trap_enter_map/2,
    trap_leave_map/1,
    trap_move/3,
    trap_fight/1,
    trap_fight_prepare/5
]).

%% mod_map_actor回调
-export([
    enter_map/1
]).

-export([
    summon_trap/1
]).
%%%===================================================================
%%% mod_trap 调用 start
%%%===================================================================
trap_enter_map(MapInfo, Attr) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:enter_map(MapInfo, Attr, []) end).

trap_leave_map(ActorID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:leave_map(ActorID, []) end).

trap_move(ActorID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move(ActorID, ?ACTOR_TYPE_TRAP, RecordPos, IntPos) end).

trap_fight(Args) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_fight:fight(Args) end).

trap_fight_prepare(ActorID, DestID, SkillID, Section, SrcPos) ->
    IntPos = map_misc:pos_encode(SrcPos),
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_fight:fight_prepare(ActorID, ?ACTOR_TYPE_TRAP, DestID, SkillID, Section, SrcPos, IntPos) end).

%%%===================================================================
%%% mod_collection 调用 start
%%%===================================================================



%%%===================================================================
%%% mod_map_actor 调用 start
%%%==================================================================
enter_map({TrapID, _RecordPos, _Args}) ->
    info_trap_pid({func, fun() -> mod_trap_map:enter_map(TrapID) end}).


%%%===================================================================
%%% mod_map_actor 调用 end
%%%==================================================================


summon_trap(TrapArgs) ->
    info_trap_pid({func, fun() -> mod_trap_map:summon_trap(TrapArgs) end}).

info_trap_pid(Info) ->
    pname_server:send(mod_map_dict:get_trap_pid(), Info).