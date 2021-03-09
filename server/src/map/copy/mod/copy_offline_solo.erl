%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     离线竞技场地图
%%% @end
%%% Created : 29. 4月 2019 11:20
%%%-------------------------------------------------------------------
-module(copy_offline_solo).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").
-include("offline_solo.hrl").
-include("world_boss.hrl").
-include("world_robot.hrl").

%% API
-export([
    role_init/1,
    role_dead/1,
    role_enter/1,
    robot_enter/1,
    copy_end/1,
    robot_dead/1
]).

-export([
    solo_quit/2
]).

%% @doc 进入地图的初始化
role_init(CopyInfo) ->
    #r_offline_solo_dict{robot_args = RobotData} = mod_map_dict:get_map_params(),
    MapID = map_common_dict:get_map_id(),
    {ok, #r_pos{mx = Mx, my = My}} = map_misc:get_born_pos(#r_born_args{map_id = MapID, camp_id = ?DEFAULT_CAMP_ROLE}),
    {OffsetMx, OffsetMy} = map_misc:get_offset_meter(Mx, My),
    RobotData2 = RobotData#r_robot{
        forever_enemies = mod_map_ets:get_in_map_roles(),
        min_point = [OffsetMx, OffsetMy],
        max_point = [OffsetMx, OffsetMy]
    },
    mod_map_robot:born_robots([RobotData2]),
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = RobotData#r_robot.robot_id},
    copy_data:set_copy_info(CopyInfo2).

role_enter(RoleID) ->
    #r_offline_solo_dict{my_bestir_times = MyBestTirTimes} = mod_map_dict:get_map_params(),
    Buffs = get_add_buffs(RoleID, MyBestTirTimes),
    role_misc:add_buff(RoleID, Buffs).

robot_enter(RobotID) ->
    #r_offline_solo_dict{dest_bestir_times = DestBestTirTimes} = mod_map_dict:get_map_params(),
    Buffs = get_add_buffs(RobotID, DestBestTirTimes),
    mod_map_robot:add_buff(RobotID, Buffs).


solo_quit(MapPID, RoleID) ->
    map_misc:info(MapPID, {func, ?MODULE, copy_end, [RoleID]}).

role_dead(_Info) ->
    solo_end(false).

copy_end(_Info) ->
    solo_end(false).

robot_dead(_SrcID) ->
    solo_end(true).

solo_end(IsWin) ->
    #r_map_copy{status = Status, enter_roles = EnterRoles, mod_args = DestID} = CopyInfo = copy_data:get_copy_info(),
    case Status of
        ?COPY_NOT_END ->
            [RoleID|_] = EnterRoles,
            world_offline_solo_server:solo_result(RoleID, DestID, IsWin),
            ShutDownTime = time_tool:now() + ?END_SHUTDOWN_TIME,
            CopyInfo2 = CopyInfo#r_map_copy{status = ?COPY_SUCCESS, end_time = 0, shutdown_time = ShutDownTime},
            copy_data:set_copy_info(CopyInfo2),
            mod_map_robot:delete_robot(DestID),
            mod_map_actor:add_hp(RoleID, 9999999999);
        _ ->
            ok
    end.

get_add_buffs(RoleID, MyBestTirTimes) ->
    BestirBuffID = common_misc:get_global_int(?GLOBAL_SOLO_BESTIR_BUFF),
    ImmuneBuffID = common_misc:get_global_int(?GLOBAL_OFFLINE_SOLO_IMMUNE),
    BuffArgs = #buff_args{buff_id = ImmuneBuffID, from_actor_id = RoleID},
    AddBuffList = ?IF(MyBestTirTimes > 0, [ #buff_args{buff_id = BestirBuffID, from_actor_id = RoleID} || _Index<- lists:seq(1, MyBestTirTimes)], []),
    [BuffArgs|AddBuffList].