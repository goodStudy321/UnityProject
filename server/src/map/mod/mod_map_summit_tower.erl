%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2018 10:44
%%%-------------------------------------------------------------------
-module(mod_map_summit_tower).
-author("laijichang").
-include("global.hrl").
-include("monster.hrl").
-include("activity.hrl").
-include("summit_tower.hrl").
-include("proto/mod_role_summit_tower.hrl").

%% API
-export([
    i/2,
    activity_end/4
]).

-export([
    init/0,
    loop/1,
    handle/1
]).

-export([
    monster_dead/3,
    role_dead/3
]).

i(MapID, ExtraID) ->
    pname_server:call(map_misc:get_map_pname(MapID, ExtraID), {mod, ?MODULE, i}).

activity_end(MapID, ExtraID, PassRoles, DataRecord) ->
    pname_server:send(map_misc:get_map_pname(MapID, ExtraID), {mod, ?MODULE, {activity_end, PassRoles, DataRecord}}).

init() ->
    [#c_summit_tower{monster_args = MonsterArgs}] = lib_config:find(cfg_summit_tower, map_common_dict:get_map_id()),
    Now = time_tool:now(),
    List =
        [ begin
              [TypeID, Interval, Mx, My] = string:tokens(String, ","),
              BornPos = map_misc:get_pos_by_offset_pos(lib_tool:to_integer(Mx), lib_tool:to_integer(My)),
              #r_summit_monster{
                  type_id = lib_tool:to_integer(TypeID),
                  born_time = Now,
                  interval = lib_tool:to_integer(Interval),
                  born_pos = BornPos
              }
          end|| String <- string:tokens(MonsterArgs, "|")],
    set_monster_args(List),
    ok.

loop(Now) ->
    List = get_monster_args(),
    WorldLevel = world_data:get_world_level(),
    {List2, MonsterDatas} =
        lists:foldl(
            fun(#r_summit_monster{} = SummitMonster, {Acc1, Acc2}) ->
                #r_summit_monster{
                    type_id = TypeID,
                    born_time = BornTime,
                    born_pos = BornPos} = SummitMonster,
                case BornTime > 0 andalso Now >= BornTime of
                    true ->
                        MonsterData = monster_misc:get_dynamic_monster(WorldLevel, TypeID),
                        MonsterData2 = MonsterData#r_monster{born_pos = BornPos, camp_id = ?BATTLE_CAMP_MONSTER},
                        SummitMonster2 = SummitMonster#r_summit_monster{born_time = 0},
                        {[SummitMonster2|Acc1], [MonsterData2|Acc2]};
                    _ ->
                        {[SummitMonster|Acc1], Acc2}
                end
            end, {[], []}, List),
    ?IF(MonsterDatas =/= [], mod_map_monster:born_monsters(MonsterDatas), ok),
    set_monster_args(List2).

handle(i) ->
    do_i();
handle({activity_end, PassRoles, DataRecord}) ->
    do_activity_end(PassRoles, DataRecord);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

monster_dead(MapInfo, SrcID, ActorType) ->
    ?IF(ActorType =:= ?ACTOR_TYPE_ROLE, add_score(SrcID, ?MONSTER_ADD_SCORE), ok),
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    List = get_monster_args(),
    {value, SummitMonster, List2} = lists:keytake(TypeID, #r_summit_monster.type_id, List),
    #r_summit_monster{interval = Interval} = SummitMonster,
    SummitMonster2 = SummitMonster#r_summit_monster{born_time = time_tool:now() + Interval},
    set_monster_args([SummitMonster2|List2]).

role_dead(_RoleID, SrcID, ?ACTOR_TYPE_ROLE) ->
    add_score(SrcID, ?MONSTER_ADD_SCORE);
role_dead(_RoleID, _SrcID, _SrcType) ->
    ok.

add_score(RoleID, AddScore) ->
    mod_summit_tower:add_score(map_common_dict:get_map_id(), RoleID, AddScore).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_activity_end(PassRoles, DataRecord) ->
    AllRoles = mod_map_ets:get_in_map_roles(),
    SendRoles = AllRoles -- PassRoles,
    map_server:delay_kick_roles(),
    map_server:send_msg_by_roleids(SendRoles, DataRecord).

do_i() ->
    mod_map_ets:get_in_map_roles().

%%%===================================================================
%%% dict
%%%===================================================================
set_monster_args(List) ->
    erlang:put({?MODULE, monster_args}, List).
get_monster_args() ->
    erlang:get({?MODULE, monster_args}).
