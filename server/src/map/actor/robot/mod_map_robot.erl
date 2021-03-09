%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 五月 2017 17:43
%%%-------------------------------------------------------------------
-module(mod_map_robot).
-author("laijichang").
-include("world_robot.hrl").

%% 机器人进程mod_robot_map发起的操作
-export([
    robot_enter_map/3,
    robot_dead_ack/3,
    robot_move_point/2,
    robot_move/3,
    robot_stop/1,
    robot_fight_prepare/6,
    robot_fight/1,
    robot_update_status/2,
    robot_update_buff_status/2,
    robot_update_buffs/4,
    robot_update_fight_attr/2,
    robot_update_move_speed/2,
    robot_change_pos/3,
    robot_buff_reduce_hp/5,
    robot_buff_heal/4
]).

%% mod_map_actor 回调
-export([
    enter_map/1,
    leave_map/1,
    dead/1,
    dead_ack/1,
    loop_msec/0,
    map_change_pos/1
]).

%% 其他API
-export([
    add_buff/2,
    born_robots/1,
    delete_robot/1
]).
%%%===================================================================
%%% mod_robot_map 调用 start
%%%===================================================================
%% 机器人进入地图
robot_enter_map(MapInfo, Attr, Args) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:enter_map(MapInfo, Attr, Args) end).

%% 机器人死亡同步地图确认
robot_dead_ack(RobotID, SrcID, SrcType) ->
    DeadArgs = #r_actor_dead{src_id = SrcID, src_type = SrcType},
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:dead_ack(RobotID, DeadArgs) end).

%% 机器人移动至某个点
robot_move_point(RobotID, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move_point(RobotID, IntPos) end).

%% 机器人移动
robot_move(RobotID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move(RobotID, ?ACTOR_TYPE_ROBOT, RecordPos, IntPos) end).

%% 机器人停止移动
robot_stop(RobotID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:move_stop(RobotID) end).

robot_fight_prepare(ActorID, DestID, SkillID, StepID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_fight:fight_prepare(ActorID, ?ACTOR_TYPE_ROBOT, DestID, SkillID, StepID, RecordPos, IntPos) end).

%% 机器人发起战斗
robot_fight(Args) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_fight:fight(Args) end).

%% 更新状态
robot_update_status(RobotID, Status) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_status(RobotID, Status) end).

%% 更新buff status
robot_update_buff_status(RobotID, BuffStatus) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_buff_status(RobotID, BuffStatus) end).

robot_update_buffs(RobotID, Buffs, UpdateList, DelList) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_buffs(RobotID, Buffs, UpdateList, DelList) end).

robot_update_fight_attr(RobotID, Attr) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_fight_attr(RobotID, Attr) end).

robot_update_move_speed(RobotID, MoveSpeed) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:update_move_speed(RobotID, MoveSpeed) end).

robot_change_pos(RobotID, RecordPos, IntPos) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:map_change_pos(RobotID, RecordPos, IntPos, ?ACTOR_MOVE_NORMAL, 0) end).

robot_buff_reduce_hp(RobotID, FromActorID, ReduceHp, BuffType, BuffID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:buff_reduce_hp(RobotID, FromActorID, ReduceHp, BuffType, BuffID) end).

robot_buff_heal(RobotID, AddHp, BuffType, BuffID) ->
    map_misc:info(map_common_dict:get_map_pid(), fun() -> mod_map_actor:buff_heal(RobotID, AddHp, BuffType, BuffID) end).
%%%===================================================================
%%% mod_robot_map 调用 end
%%%===================================================================


%%%===================================================================
%%% mod_map_actor 回调 start
%%%===================================================================
enter_map({RobotID, _RecordPos, _RobotPID}) ->
    MapID = map_common_dict:get_map_id(),
    ExtraID = map_common_dict:get_map_extra_id(),
    info_robot_pid({func, fun() -> mod_robot_map:enter_map(RobotID) end}),
    ?IF(map_branch_manager:is_branch_map(MapID), map_branch_worker:role_enter_map(MapID, ExtraID), ok),
    copy_common:robot_enter(RobotID).

leave_map({_MapActor, _}) ->
    MapID = map_common_dict:get_map_id(),
    ExtraID = map_common_dict:get_map_extra_id(),
    ?IF(map_branch_manager:is_branch_map(MapID), map_branch_worker:role_leave_map(MapID, ExtraID), ok).

dead({RobotID, ReduceSrc, _SrcName}) ->
    info_robot_pid({func, fun() -> mod_robot_map:dead(RobotID, ReduceSrc) end}).

%% @doc 地图同步机器人死亡
dead_ack({RobotID, _DeadArgs}) ->
    copy_common:robot_dead(RobotID),
    mod_map_actor:leave_map(RobotID, []).

map_change_pos({RobotID, RecordPos}) ->
    info_robot_pid({func, fun() -> mod_robot_map:map_change_pos(RobotID, RecordPos) end}).

%% @doc 提前触发机器人
loop_msec() ->
    info_robot_pid({guide_loop_msec, time_tool:now_os_ms()}).

%%%===================================================================
%%% mod_map_actor 回调 end
%%%===================================================================


%%%===================================================================
%%% 其他API start
%%%===================================================================
add_buff(_RobotID, []) ->
    ok;
add_buff(RobotID, BuffList) ->
    info_robot_pid({func, fun() -> mod_robot_buff:add_buff(RobotID, BuffList) end}).

born_robots(RobotDatas) ->
    info_robot_pid({func, fun() -> mod_robot_map:born_robots(RobotDatas) end}).

delete_robot(RobotID) ->
    info_robot_pid({func, fun() -> mod_robot_map:delete_robot(RobotID) end}).
%%%===================================================================
%%% 其他API 回调 start
%%%===================================================================


info_robot_pid(Info) ->
    pname_server:send(mod_map_dict:get_robot_pid(), Info).
