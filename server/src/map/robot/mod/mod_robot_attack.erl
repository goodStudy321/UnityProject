%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 9:54
%%%-------------------------------------------------------------------
-module(mod_robot_attack).
-author("laijichang").
-include("world_robot.hrl").

%% API
-export([
    active_find_enemies/2,
    update_enemy_lists/1,
    get_enemy/1
]).


active_find_enemies(RobotID, _RobotData) ->
    CampID = ?DEFAULT_CAMP_ROLE,
    RecordPos = mod_map_ets:get_actor_pos(RobotID),
    Slices = mod_map_slice:get_9slices_by_pos(RecordPos),
    MonsterIDs = mod_map_slice:get_monster_ids_by_slices(Slices),
    find_normal_enemy(lib_tool:random_reorder_list(MonsterIDs), CampID).

%% 找普通怪
find_normal_enemy([], _CampID) ->
    undefined;
find_normal_enemy([ActorID|R], CampID) ->
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{status = Status, camp_id = EnemyCampID} ->
            case Status =/= ?MAP_STATUS_DEAD andalso EnemyCampID =/= CampID of
                true ->
                    ActorID;
                false ->
                    find_normal_enemy(R, CampID)
            end;
        _ ->
            find_normal_enemy(R, CampID)
    end.

%%更新怪物仇恨列表
update_enemy_lists(RobotData) ->
    #r_robot{forever_enemies = ForEverEnemies, enemies = Enemies} = RobotData,
    List = lib_tool:list_filter_repeat(ForEverEnemies ++ Enemies),
    case List of
        [_|_] ->
            Enemies2 =
                lists:foldl(
                    fun(ActorID, Acc) ->
                        ?IF(check_enemy(mod_map_ets:get_actor_mapinfo(ActorID)), [ActorID|Acc], Acc)
                    end, [], List),
            RobotData#r_robot{enemies = Enemies2};
        _ ->
            RobotData
    end.

check_enemy(#r_map_actor{actor_type = ?ACTOR_TYPE_ROLE}) ->
    true;
check_enemy(#r_map_actor{status = Status}) ->
    not (Status =:= ?MAP_STATUS_DEAD);
check_enemy(_) ->
    false.

get_enemy(RobotData)->
    #r_robot{enemies = Enemies} = RobotData,
    ?IF(Enemies =/= [], lists:nth(1, Enemies), 0).