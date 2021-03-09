%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     boss指引地图
%%% @end
%%% Created : 29. 4月 2019 11:20
%%%-------------------------------------------------------------------
-module(copy_guide_boss).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").
-include("world_boss.hrl").
-include("world_robot.hrl").

%% API
-export([
    role_init/1,
    init/1,
    handle/1,
    monster_dead/1,
    robot_dead/1,
    monster_enter/1,
    monster_reduce_hp/1,
    init_robot_monster/1
]).

%% @doc 进入地图的初始化
role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    init_robot_monster(CopyInfo2),
    copy_data:set_copy_info(CopyInfo2).

monster_enter({MapInfo}) ->
    #r_map_actor{actor_id = MonsterID} = MapInfo,
    set_monster_id(MonsterID).

%% @doc 提前出手机器人和boss
% 1:boss出生
init_robot_monster(#r_map_copy{enter_roles = [RoleID | _] = EnterRoles}) ->
%%    Guide = mod_role_world_boss:get_world_boss_guide(RoleID),

    #r_map_role{is_guide = Guide} = mod_map_ets:get_map_role(RoleID),
    [#c_copy_guide_boss{monster_type_id = TypeID, pos = [Mx, My | _]}] = lib_config:find(cfg_copy_guide_boss, Guide + 1),
    BornPos = map_misc:get_pos_by_offset_pos(Mx, My),
    [#c_global{list = [Sec | _]}] = lib_config:find(cfg_global, ?GLOBAL_GUIDE_BOSS),
    MonsterData = [#r_monster{type_id = TypeID, born_pos = BornPos}],

    % 1
    mod_map_monster:born_monsters(MonsterData),
    ?IF(Guide < ?COPY_BOSS_GUIDE_ONE, do_add_robot(?COPY_BOSS_GUIDE_ONE, Guide, EnterRoles, [TypeID]),
        erlang:send_after(Sec * 1000, erlang:self(), {mod, ?MODULE, {add_robot, ?COPY_BOSS_GUIDE_ONE, Guide, EnterRoles, [TypeID]}})),
    erlang:send_after(100, erlang:self(), {mod, ?MODULE, {loop_msec, 10}}).


%% @doc cfg_copy配置表的start_countdown字段，副本开始倒计结束后
init(#r_map_copy{}) ->
    ok.

handle({add_robot, IndexID, Guide, EnterRoles, MonsterLists}) ->
    do_add_robot(IndexID, Guide, EnterRoles, MonsterLists);
handle({loop_msec, Num}) ->
    case Num > 0 of
        true ->
            mod_map_monster:loop_msec(),
            mod_map_robot:loop_msec(),
            erlang:send_after(100, erlang:self(), {mod, ?MODULE, {loop_msec, Num - 1}});
        _ ->
            ok
    end.


do_add_robot(IndexID, Guide, EnterRoles, MonsterLists) ->
    MapID = map_common_dict:get_map_id(),
    RobotStartID = common_id:get_robot_start_id(MapID),

    [#c_global{list = [X1, Y1, X2, Y2]}] = lib_config:find(cfg_global, ?GLOBAL_GUIDE_BOSS_POINT),
    {OffsetMx, OffsetMy} = ?IF(IndexID =:= ?COPY_BOSS_GUIDE, {X2, Y2}, {X1, Y1}),

    {Sex, Category} = lib_tool:random_element_from_list([{?SEX_GIRL, ?CATEGORY_1}, {?SEX_BOY, ?CATEGORY_2}]),
    [#c_global{string = String, int = MaxNum}] = lib_config:find(cfg_global, ?GLOBAL_GUIDE_BOSS),
    [{RoleLevel, _}, {Attack1, Attack2}, {Hp1, Hp2}, {Defence, Defence2}] = lib_tool:string_to_intlist(String, ",", ":"),
    Enemies = ?IF(IndexID =:= ?COPY_BOSS_GUIDE, EnterRoles, MonsterLists),

    RobotData = [
        #r_robot{
            robot_id = RobotStartID + IndexID,
            robot_name = common_misc:get_random_name(),
            sex = Sex,
            category = Category,
            level = RoleLevel,
            skin_list = [3040205, 3050000, 30200000],
            skill_list = copy_wave:get_robot_skill(Category),
            ornament_list = [],
            min_point = [OffsetMx, OffsetMy],
            max_point = [OffsetMx, OffsetMy],
            forever_enemies = Enemies,
            base_attr = #actor_fight_attr{
                max_hp = ?IF(IndexID =:= ?COPY_BOSS_GUIDE, Hp2, Hp1),
                attack = ?IF(IndexID =:= ?COPY_BOSS_GUIDE, Attack2, Attack1),
                defence = ?IF(IndexID =:= ?COPY_BOSS_GUIDE, Defence2, Defence),
                move_speed = 550
            }
        }],
    ?LXG({IndexID, RobotData}),
    mod_map_robot:born_robots(RobotData),
    case IndexID >= MaxNum orelse Guide =/= ?COPY_BOSS_GUIDE_ONE of
        true ->
            ok;
        _ ->
            do_add_robot(IndexID + 1, Guide, EnterRoles, MonsterLists)
    end.

%% @doc boss 死亡
monster_dead({MapInfo, SrcID, _SrcType}) ->
    #r_map_actor{actor_id = ActorID} = MapInfo,
    case ActorID =:= SrcID of
        true ->
            ok;
        _ ->
            #r_map_copy{enter_roles = EnterRoles} = copy_data:get_copy_info(),
            [ mod_role_world_boss:kill_guide_boss(RoleID) || RoleID <- EnterRoles],
            map_server:delay_kick_roles()
    end,
    copy_common:do_copy_end(?COPY_SUCCESS).

%% @doc 怪物流血
%% 1 机器人死亡后角色才有归属
%% 2 首个引导副本BOSS或玩家打死机器人都回清空归属
monster_reduce_hp({MapInfo, ReduceSrc, _ReduceHp}) ->
    #r_reduce_src{actor_id = SrcID, actor_type = ActorType, actor_name = FirstRoleName, actor_level = FirstLevel, family_id = FamilyID, team_id = TeamID} = ReduceSrc,
    #r_map_actor{actor_id = ActorID} = MapInfo,
    case ActorID =:= SrcID of
        true ->
            ok;
        _ ->
            #r_map_copy{enter_roles = [RoleID | _]} = copy_data:get_copy_info(),
            #r_map_role{is_guide = Guide} = mod_map_ets:get_map_role(RoleID),
            #r_map_actor{monster_extra = #p_map_monster{world_boss_owner = OldOwner}} = mod_map_ets:get_actor_mapinfo(ActorID),
            EnemiesBool = lists:member(SrcID, mod_map_ets:get_robot_enemies(SrcID)),
            case ActorType of
                ?ACTOR_TYPE_ROBOT when OldOwner =:= undefined ->
                    Owner = #p_world_boss_owner{
                        owner_id = SrcID,
                        owner_name = FirstRoleName,
                        owner_level = FirstLevel,
                        family_id = FamilyID,
                        team_id = TeamID},
                    ?IF(Guide < ?COPY_BOSS_GUIDE_ONE andalso Owner =/= OldOwner, mod_map_monster:do_update_world_boss_owner(get_monster_id(), Owner), ok);
                ?ACTOR_TYPE_ROLE when EnemiesBool =:= true orelse Guide =:= ?COPY_BOSS_GUIDE_ONE -> % 机器人死亡后角色才有归属
                    Owner = #p_world_boss_owner{
                        owner_id = SrcID,
                        owner_name = FirstRoleName,
                        owner_level = FirstLevel,
                        family_id = FamilyID,
                        team_id = TeamID},
                    mod_map_ets:del_robot_enemies(SrcID),
                    case OldOwner of
                        #p_world_boss_owner{owner_id = SrcID} ->
                            ok;
                        #p_world_boss_owner{owner_name = OldName} ->
                            mod_map_monster:owner_change_broadcast(OldName, FirstRoleName),
                            mod_map_monster:do_update_world_boss_owner(get_monster_id(), Owner);
                        _ ->
                            mod_map_monster:do_update_world_boss_owner(get_monster_id(), Owner)
                    end;
                _ ->
                    ok
            end
    end.

robot_dead(_SrcID) ->
    case map_misc:is_copy_guide_boss(map_common_dict:get_map_id()) of
        true ->
            MonsterID = get_monster_id(),
            #r_map_copy{enter_roles = [RoleID | _]} = copy_data:get_copy_info(),
            #r_map_role{is_guide = Guide} = mod_map_ets:get_map_role(RoleID),
            mod_map_ets:set_robot_enemies(RoleID, [RoleID]),
            #r_map_actor{actor_name = FirstRoleName, role_extra = #p_map_role{level = FirstLevel, family_id = FamilyID, team_id = TeamID}} = mod_map_ets:get_actor_mapinfo(RoleID),
            Owner = #p_world_boss_owner{
                owner_id = RoleID,
                owner_name = FirstRoleName,
                owner_level = FirstLevel,
                family_id = FamilyID,
                team_id = TeamID},
            case Guide < ?COPY_BOSS_GUIDE_ONE andalso mod_map_ets:get_actor_mapinfo(MonsterID) of
                #r_map_actor{monster_extra = #p_map_monster{world_boss_owner = #p_world_boss_owner{owner_name = OldName} = OldOwner}}
                    when OldOwner =/= undefined andalso Owner =/= OldOwner ->
                    mod_map_monster:owner_change_broadcast(OldName, FirstRoleName);
                _ ->
                    ok
            end,
            ?IF(Guide < ?COPY_BOSS_GUIDE_ONE, mod_map_monster:do_update_world_boss_owner(MonsterID, undefined), ok);
        _ ->
            ok
    end.


get_monster_id() ->
    erlang:get({?MODULE, monster_id}).
set_monster_id(MonsterID) ->
    erlang:put({?MODULE, monster_id}, MonsterID).