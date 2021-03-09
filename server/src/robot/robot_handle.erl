%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_handle).
-include("role.hrl").
-include("global.hrl").
-include("robot.hrl").
-include("team.hrl").

-include("proto/role_login.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_map_role_move.hrl").
-include("proto/mod_role_fight.hrl").
-include("proto/mod_map_actor.hrl").
-include("proto/mod_map_collection.hrl").
-include("proto/mod_role_skill.hrl").
-include("proto/mod_role_friend.hrl").
-include("proto/world_friend_server.hrl").
-include("proto/world_activity_server.hrl").
-include("proto/mod_solo.hrl").
-include("proto/mod_role_mission.hrl").
-include("proto/mod_role_level.hrl").
-include("proto/mod_role_extra.hrl").
-include("proto/mod_role_bag.hrl").
-include("proto/mod_role_equip.hrl").
-include("proto/mod_role_team.hrl").
-include("proto/copy_marry.hrl").
-include("proto/mod_role_map_panel.hrl").
-include("proto/mod_marry_propose.hrl").
-include("proto/mod_role_marry.hrl").

-export([
    i/0,
    handle/1
]).

%%%===================================================================
%%% API
%%%===================================================================
i() ->
    RoleID = robot_data:get_role_id(),
    io:format("~w map:~w; pos:~w", [RoleID, robot_data:get_map_id(), robot_data:get_now_pos()]).

handle(#m_auth_key_toc{role_list = []}) ->
    Sex = lib_tool:random_element_from_list([?SEX_BOY, ?SEX_GIRL]),
    Category =
        case Sex of
            ?SEX_BOY ->
                ?CATEGORY_2;
            ?SEX_GIRL ->
                ?CATEGORY_1
        end,
    DataRecord = #m_create_role_tos{
        name = robot_data:get_robot_account(),
        sex = Sex,
        category = Category
    },
    robot_client:send_data(DataRecord);
handle(#m_auth_key_toc{role_list = [#p_login_role{role_id = RoleID, level = RoleLevel}|_]}) ->
    DataRecord = #m_select_role_tos{role_id = RoleID},
    robot_data:set_level(RoleLevel),
    robot_client:send_data(DataRecord);
handle(#m_create_role_toc{role = #p_login_role{role_id = RoleID}}) ->
    DataRecord = #m_select_role_tos{role_id = RoleID},
    robot_client:send_data(DataRecord);
handle(#m_select_role_toc{role_data = RoleData}) ->
    #p_role_data{role_id = RoleID} = RoleData,
    robot_data:set_role_id(RoleID),
    robot_client:send_data(#m_enter_map_tos{}),
    robot_ai:init();
handle(#m_pre_enter_toc{map_id = MapID, err_code = ErrorCode})->
    case ErrorCode of
        0 ->
            robot_client:send_data(#m_enter_map_tos{map_id = MapID});
        _ ->
            case ErrorCode =:= ?ERROR_PRE_ENTER_017 of
                true ->
                    NowMapID = robot_data:get_map_id(),
                    [#c_map_base{data_id = DataID}] = lib_config:find(cfg_map_base, NowMapID),
                    robot_client:send_data(#m_pre_enter_tos{map_id = DataID});
                _ ->
                    ?INFO_MSG("ErrorCode:~w", [ErrorCode])
            end
    end;
handle(#m_enter_map_toc{err_code = ErrCode, map_id = MapID, role_map_info = RoleMapInfo})->
    case ErrCode of
        0 ->
            #p_map_actor{pos = Pos, camp_id = CampID} = RoleMapInfo,
            robot_data:set_map_id(MapID),
            robot_data:set_now_pos(Pos),
            robot_data:set_camp_id(CampID),
            robot_ai:change_map(MapID),
            %%清理旧的数据
            del_all_actors();
        _ ->
            ignore
    end;
handle(#m_map_slice_enter_toc{} = Info) ->
    do_slice_enter(Info);
handle(#m_map_actor_attr_change_toc{} = Info) ->
    do_actor_change(Info);
handle(#m_move_point_toc{actor_id = ActorID,point = NewPos}) ->
    mark_actor_change(ActorID, NewPos);
handle(#m_move_stop_toc{actor_id = ActorID, pos = NewPos}) ->
    mark_actor_change(ActorID, NewPos);
handle(#m_stick_move_toc{actor_id = ActorID, pos = NewPos}) ->
    mark_actor_change(ActorID, NewPos);
handle(#m_move_sync_toc{actor_id = ActorID, pos=NewPos}) ->
    case robot_data:get_role_id() =:= ActorID of
        true ->
            robot_ai:del_executing_mod(robot_ai_move),
            robot_data:set_now_pos(NewPos);
        _ ->
            mark_actor_change(ActorID, NewPos)
    end;
handle(#m_map_change_pos_toc{actor_id = ActorID, dest_pos = NewPos}) ->
    case robot_data:get_role_id() =:= ActorID of
        true ->
            robot_data:set_now_pos(NewPos),
            robot_ai:start_loop_ms();
        _ ->
            mark_actor_change(ActorID, NewPos)
    end;
handle(#m_fight_attack_toc{src_id = SrcID, effect_list = EffectList}) ->
    do_fight_attack(robot_data:get_role_id(), SrcID, EffectList);
handle(#m_role_dead_toc{}) ->
    do_robot_dead();
handle(#m_role_relive_toc{}) ->
    ok;
handle(#m_friend_request_info_toc{request_info = #p_friend{role_id = RoleID}}) ->
    robot_client:send_data(#m_friend_add_tos{role_id = RoleID});
handle(#m_role_skill_toc{skill_list = SkillList}) ->
    robot_common:init_skills(SkillList);
handle(#m_skill_update_toc{update_list = UpdateList, del_list = DelList}) ->
    robot_common:update_skills(UpdateList, DelList);
handle(#m_activity_info_toc{activity_list = ActivityList}) ->
    do_set_activity(ActivityList);
handle(#m_solo_match_ready_toc{}) ->
    robot_client:send_data(#m_pre_enter_tos{map_id = 30002});
handle(#m_solo_result_toc{}) ->
    robot_client:send_data(#m_quit_map_tos{});
handle(#m_role_level_toc{level = Level}) ->
    robot_data:set_level(Level);
handle(#m_mission_info_toc{missions = Missions}) ->
    robot_data:set_missions(Missions);
handle(#m_mission_accept_toc{err_code = ErrCode, mission_id = MissionID}) ->
    ?IF(ErrCode =:= 0, robot_ai_mission:accept_mission(MissionID), ok);
handle(#m_mission_complete_toc{err_code = ErrCode, mission_id = MissionID}) ->
    ?IF(ErrCode =:= 0, robot_ai_mission:complete_mission(MissionID), ok);
handle(#m_mission_update_toc{del = DelList, update = UpdateList}) ->
    robot_ai_mission:update_mission(DelList, UpdateList);
handle(#m_listen_update_toc{mission_id = MissionID, listens = Listens}) ->
    robot_ai_mission:listen_update(MissionID, Listens);
handle(#m_bag_update_toc{update_list = UpdateList}) ->
    robot_common:update_goods(UpdateList);
handle(#m_equip_info_toc{equip_list = EquipList}) ->
    robot_common:init_equip(EquipList);
handle(#m_equip_load_toc{equip = Equip}) ->
    robot_common:update_equip(Equip);
handle(#m_team_start_copy_toc{}) ->
    robot_client:send_data(#m_team_copy_ready_tos{is_ready = true});
handle(#m_team_invite_toc{team_id = TeamID, invite_role = #p_team_invite{role_id = DestRoleID}}) ->
    robot_client:send_data(#m_team_invite_reply_tos{op_type = ?TEAM_INVITE_REPLY_ACCEPT, team_id = TeamID, role_id = DestRoleID});
handle(#m_marry_copy_icon_toc{item_list = [ItemID|_]}) ->
    robot_client:send_data(#m_marry_copy_select_tos{item = ItemID});
handle(#m_copy_success_toc{}) ->
    robot_client:send_data(#m_quit_map_tos{});
handle(#m_marry_propose_toc{from_role_id = ProposeID}) ->
    robot_client:send_data(#m_marry_propose_reply_tos{to_propose_id = ProposeID, answer_type = 1});
handle(_Info) ->
    ok.

del_all_actors() ->
    case robot_data:get_actor_ids() of
        [_|_] = ActorList ->
            [ robot_data:del_actor(ActorID) || ActorID <- ActorList];
        _ -> ignore
    end,
    robot_data:set_actor_ids([]).

do_slice_enter(Info) ->
    #m_map_slice_enter_toc{actors = AddActors, del_actors = DelActors} = Info,
    ActorIDs = robot_data:get_actor_ids(),
    ActorIDs2 = ActorIDs -- DelActors,
    [ robot_data:del_actor(DelActorID) || DelActorID <- DelActors],
    AddActorIDs =
    [ begin
          robot_data:set_actor(ActorID, MapInfo),
          ?TRY_CATCH(try_pick_drop(MapInfo)),
          ActorID
      end|| #p_map_actor{actor_id = ActorID} = MapInfo <- AddActors],
    ActorIDs3 = AddActorIDs ++ ActorIDs2,
    robot_data:set_actor_ids(ActorIDs3).

do_actor_change(Info) ->
    #m_map_actor_attr_change_toc{actor_id = ActorID, kv_list = KVList, ks_list = _KSList, kl_list = _KLList} = Info,
    case robot_data:get_actor(ActorID) of
        #p_map_actor{} = MapInfo ->
            MapInfo2 = do_kv_list_change(MapInfo, KVList),
            robot_data:set_actor(ActorID, MapInfo2);
        _ ->
            ok
    end.

do_kv_list_change(MapInfo, []) ->
    MapInfo;
do_kv_list_change(MapInfo, [#p_dkv{id = Key, val = Val}|R]) ->
    MapInfo2 =
    if
        Key =:= ?MAP_ATTR_STATUS ->
            MapInfo#p_map_actor{status = Val};
        Key =:= ?MAP_ATTR_CAMP_ID ->
            MapInfo#p_map_actor{camp_id = Val};
        true ->
            MapInfo
    end,
    do_kv_list_change(MapInfo2, R).



mark_actor_change(_ActorID, 0) ->
    ignore;
mark_actor_change(ActorID, NewPos) ->

    case robot_data:get_actor(ActorID) of
        #p_map_actor{} = Info ->
            robot_data:set_actor(ActorID, Info#p_map_actor{pos = NewPos});
        _ ->
            ignore
    end.

%% 自己发起的战斗包
do_fight_attack(RoleID, RoleID, _EffectList) ->
    ok;
do_fight_attack(RoleID, SrcID, EffectList) ->
    lists:foreach(
        fun(#p_result{actor_id = ActorID}) ->
            case ActorID =:= RoleID of
                true -> %% 自己被攻击
                    case robot_data:get_enemy() =:= 0 of
                        true ->
                            robot_data:set_enemy(SrcID);
                        _ ->
                            ignore
                    end;
                _ ->
                    ok
            end
        end, EffectList).

%% 打倒我，我就会一直这么回来
do_robot_dead() ->
    robot_client:send_data(#m_role_relive_tos{op_type = 1}).

%% 设置玩法活动的状态
do_set_activity(ActivityList) ->
    OldList = robot_data:get_activity(),
    List = do_set_activity2(ActivityList, OldList, []),
    robot_data:set_activity(List).

do_set_activity2(ActivityList, [], Acc) ->
    ActivityList ++ Acc;
do_set_activity2([], OldList, Acc) ->
    OldList ++ Acc;
do_set_activity2([Activity|R], OldList, Acc) ->
    #p_activity{id = ID} = Activity,
    Acc2 = [Activity|Acc],
    case lists:keytake(ID, #p_activity.id, OldList) of
        {value, #p_activity{}, OldList2} ->
            ok;
        _ ->
            OldList2 = OldList
    end,
    do_set_activity2(R, OldList2, Acc2).

try_pick_drop(MapInfo) ->
    #p_map_actor{actor_id = ActorID, actor_type = ActorType, drop_extra = DropExtra} = MapInfo,
    case ActorType =:= ?ACTOR_TYPE_DROP of
        true ->
            #p_map_drop{owner_roles = OwnerRoles} = DropExtra,
            case OwnerRoles =:= [] orelse lists:member(robot_data:get_role_id(), OwnerRoles) of
                true ->
                    robot_client:send_data(#m_pick_drop_tos{drop_id = ActorID});
                _ ->
                    ok
            end;
        _ ->
            ok
    end.