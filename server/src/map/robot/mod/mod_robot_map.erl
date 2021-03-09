%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2017 10:09
%%%-------------------------------------------------------------------
-module(mod_robot_map).
-author("laijichang").
-include("world_robot.hrl").

%% API
%% info到map时，需要额外判断的接口
-export([
    robot_born/1,
    robot_stop/1
]).

%% map进程回调
-export([
    enter_map/1,
    dead/2,
    map_change_pos/2,
    born_robots/1,
    delete_robot/1
]).

-export([
    handle/1
]).

handle(_Info) ->
    ok.

%%%===================================================================
%%% to map start
%%%===================================================================
robot_born(RobotData) ->
    {MapInfo, Attr} = make_map_info(RobotData),
    Self = self(),
    mod_map_robot:robot_enter_map(MapInfo, Attr, Self).

make_map_info(RobotData) ->
    #r_robot{
        robot_id = RobotID,
        robot_name = RobotName,
        min_point = MinPoint,
        max_point = MaxPoint,
        attr = Attr,
        sex = Sex,
        category = Category,
        level = Level,
        team_id = TeamID,
        family_id = FamilyID,
        family_name = FamilyName,
        family_title_id = FamilyTitle,
        power = Power,
        skin_list = SkinList,
        ornament_list = OrnamentList} = RobotData,
    MoveSpeed = mod_robot:get_move_speed(RobotData),
    BornPos = map_misc:pos_encode(map_misc:get_seq_born_pos(MinPoint, MaxPoint)),
    MapInfo = #r_map_actor{
        actor_id = RobotID,
        actor_type = ?ACTOR_TYPE_ROBOT,
        actor_name = RobotName,
        pos = BornPos,
        hp = Attr#actor_fight_attr.max_hp,
        max_hp = Attr#actor_fight_attr.max_hp,
        camp_id = ?DEFAULT_CAMP_ROLE,
        move_speed = MoveSpeed,
        pk_mode = ?PK_MODE_ALL,
        role_extra = #p_map_role{
            sex = Sex,
            category = Category,
            level = Level,
            power = Power,
            team_id = TeamID,
            family_id = FamilyID,
            family_name = FamilyName,
            family_title = FamilyTitle,
            skin_list = SkinList,
            ornament_list = OrnamentList}
    },
    {MapInfo, Attr}.

robot_stop(RobotID) ->
    case mod_map_ets:get_actor_mapinfo(RobotID) of
        #r_map_actor{target_pos = TargetPos} ->
            case TargetPos > 0 of
                true ->
                    mod_map_robot:robot_stop(RobotID);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
%%%===================================================================
%%% to map end
%%%===================================================================


%%%===================================================================
%%% from map start
%%%===================================================================
enter_map(RobotID) ->
    RobotData = mod_robot_data:get_robot_data(RobotID),
    AddCounter = ?MIN_COUNTER,
    NextCounter = mod_robot_data:get_loop_counter() + AddCounter,
    State = ?ROBOT_STATE_GUARD,
    mod_robot_data:set_robot_data(RobotID, RobotData#r_robot{state = State, next_counter = NextCounter}),
    mod_robot_data:add_counter_robot(RobotID, NextCounter).

dead(RobotID, ReduceSrc) ->
    dead(RobotID, ReduceSrc, true).
dead(RobotID, ReduceSrc, IsReborn)->
    case mod_robot_data:get_robot_data(RobotID) of
        #r_robot{state = RobotState, next_counter = NextCounter} = RobotData ->
            #r_reduce_src{actor_id = SrcID, actor_type = SrcType} = ReduceSrc,
            mod_robot_data:del_robot_id(RobotID),
            mod_robot_data:del_robot_data(RobotID),
            mod_robot_data:del_robot_buff_list(RobotID),
            mod_robot_data:del_counter_robot(RobotID, NextCounter),
            ?IF(RobotState =:= ?ROBOT_STATE_BORN, ok, mod_map_robot:robot_dead_ack(RobotID, SrcID, SrcType)),
            MapID = map_common_dict:get_map_id(),
            ?IF(IsReborn andalso (not map_misc:is_copy_guide_boss(MapID)), mod_robot:reborn_robot(RobotData), ok);
        _ -> %% 加这个是避免出现2条dead消息时会报错
            ok
    end.

map_change_pos(RobotID, _RecordPos) ->
    case mod_robot_data:get_robot_data(RobotID) of
        #r_robot{next_counter = NextCounter} = RobotData ->
            mod_robot_data:del_counter_robot(RobotID, NextCounter),
            NextCounter2 = mod_robot_data:get_loop_counter() + ?SECOND_COUNTER,
            mod_robot_data:add_counter_robot(RobotID, NextCounter2),
            mod_robot_data:set_robot_data(RobotID, RobotData#r_robot{walk_path = [], next_counter = NextCounter2});
        _ ->
            ok
    end.

%% 按波次刷怪召唤
born_robots(RobotDatas) ->
    [ mod_robot:init_robot(RobotData, ?MIN_COUNTER) || RobotData <- RobotDatas].

delete_robot(RobotID) ->
    dead(RobotID, #r_reduce_src{actor_id = RobotID, actor_type = ?ACTOR_TYPE_ROBOT}, false).
%%%===================================================================
%%% from map end
%%%===================================================================
