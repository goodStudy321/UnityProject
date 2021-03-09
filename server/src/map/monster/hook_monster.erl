%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2017 14:45
%%%-------------------------------------------------------------------
-module(hook_monster).
-author("laijichang").
-include("monster.hrl").
-include("mission.hrl").
-include("drop.hrl").
-include("act.hrl").
-include("team.hrl").
-include("bg_act.hrl").
-include("daily_liveness.hrl").

%% API
-export([
    monster_dead/2,
    init_act_drop/1,
    drop_act_change/2
]).

-export([
    get_special_drop/2,
    get_act_drop_id_list/1
]).


monster_dead(MonsterData, ReduceSrc) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcType} = ReduceSrc,
    #r_monster{
        monster_id = MonsterID,
        type_id = TypeID,
        seq_id = SeqID,
        add_exp = AddExp,
        level = MonsterLevel,
        attack_list = AttackList} = MonsterData,
    #c_monster{rarity = Rarity} = MonsterConfig = monster_misc:get_monster_config(TypeID),
    MonsterData2 = ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, mod_monster_world_boss:rank(time_tool:now(), MonsterData), MonsterData),
    IsSelfKill = SrcID =:= MonsterID,
    MapID = map_common_dict:get_map_id(),
    MissionRoles = get_mission_roles(SrcID, SrcType, SeqID, MapID),
    MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    IsFamilyID = ?IS_MAP_FAMILY_TD(MapID),
    case SrcType =:= ?ACTOR_TYPE_ROLE of
        true -> %% 角色独有的fun
            ExpRoles = get_exp_roles(SrcID, IsFamilyID),
            RoleFuncList = [
                fun() -> [mod_role_level:monster_dead_add_exp(RoleID, AddExp) || RoleID <- ExpRoles] end,
                fun() -> deal_monster_dead_by_map(map_common_dict:get_map_id(), ExpRoles) end,
                fun() -> ?IF(IsFamilyID, mod_map_monster:family_td_exp(AddExp), ok) end
            ];
        _ ->
            RoleFuncList =
            case map_monster_server:is_immortal_map() andalso not IsSelfKill of
                true ->
                    [fun() ->
                        [mod_role_level:monster_dead_add_exp(RoleID, AddExp) || RoleID <- mod_map_ets:get_in_map_roles()] end];
                _ ->
                    []
            end
    end,
    %% 通用fun
    FuncList = [
        fun() -> [role_server:kill_monster(RoleID, TypeID, MonsterLevel, MonsterPos) || RoleID <- MissionRoles] end,
        fun() -> mod_monster_silver:monster_dead(MonsterID) end,
        fun() ->
            ?IF(SrcType =:= ?ACTOR_TYPE_ROBOT orelse IsSelfKill, ok, do_monster_drop(MonsterData2, MonsterConfig)) end,
        fun() -> ?IF(?IS_MAP_MARRY_FEAST(MapID), mod_map_marry:boss_dead(AttackList, TypeID, MonsterPos), ok) end
    ],
    [?TRY_CATCH(F()) || F <- RoleFuncList ++ FuncList],
    ok.

%% 流程树被击杀的怪物，都走任务
%% 部分怪物，是区域任务共享
get_mission_roles(SrcActorID, SrcType, SeqID, MapID) ->
    case map_misc:is_copy_front(MapID) of
        true ->
            mod_map_ets:get_in_map_roles();
        _ ->
            case lib_config:find(cfg_map_seq, SeqID) of
                [#c_map_seq{is_mission_share = IsShare, min_point = [MinMx, MinMy], max_point = [MaxMx, MaxMy]}] ->
                    case ?IS_MISSION_SHARE(IsShare) of
                        true ->
                            case mod_monster_data:get_seq_tiles(SeqID) of
                                Tiles when erlang:is_list(Tiles) -> ok;
                                _ ->
                                    #r_pos{mx = MinMx2, my = MinMy2} = map_misc:get_pos_by_offset_pos(MinMx, MinMy),
                                    #r_pos{mx = MaxMx2, my = MaxMy2} = map_misc:get_pos_by_offset_pos(MaxMx, MaxMy),
                                    MinTx = ?M2T(MinMx2),
                                    MaxTx = ?M2T(MaxMx2),
                                    MinTy = ?M2T(MinMy2),
                                    MaxTy = ?M2T(MaxMy2),
                                    case MinMx =:= MaxMx andalso MinMy =:= MaxMy of
                                        true -> %% 当最小点跟最大点是一个点的时候，取5*5范围的格子
                                            Tiles = lists:flatten([[{Tx, Ty} || Ty <- lists:seq(MinTy - 5, MaxTy + 5)] || Tx <- lists:seq(MinTx - 5, MaxTx + 5)]);
                                        _ ->
                                            Tiles = lists:flatten([[{Tx, Ty} || Ty <- lists:seq(MinTy, MaxTy)] || Tx <- lists:seq(MinTx, MaxTx)])
                                    end,
                                    mod_monster_data:set_seq_tiles(SeqID, Tiles)
                            end,
                            Roles =
                            lists:foldl(
                                fun({Tx, Ty}, Acc) ->
                                    TileActors = mod_map_ets:get_tile_actors(Tx, Ty),
                                    ActorRoles = [ActorID || {ActorType, ActorID} <- TileActors, ActorType =:= ?ACTOR_TYPE_ROLE],
                                    ActorRoles ++ Acc
                                end, [], Tiles),
                            ?IF(lists:member(SrcActorID, Roles), Roles, [SrcActorID|Roles]);
                        _ ->
                            ?IF(SrcType =:= ?ACTOR_TYPE_ROLE, [SrcActorID], [])
                    end;
                _ ->
                    ?IF(SrcType =:= ?ACTOR_TYPE_ROLE, [SrcActorID], [])
            end
    end.

%% 部分怪物死了是大家都加经验
get_exp_roles(SrcID, IsFamilyID) ->
    if
        IsFamilyID ->
            mod_map_ets:get_in_map_roles();
        true ->
            [SrcID]
    end.


do_monster_drop(MonsterData, MonsterConfig) ->
    #r_monster{type_id = TypeID, owner = Owner, attack_list = AttackList} = MonsterData,
    #c_monster{rarity = Rarity, owner_type = OwnerType, drop_id_list = DropIDList, level = Level} = MonsterConfig,
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_1 andalso Rarity =:= ?MONSTER_RARITY_WORLD_BOSS -> %% 第一种世界boss场景实现方式不一样。。。
            WorldBossRoles = mod_monster_world_boss:get_drop_roles(MonsterData),
            case WorldBossRoles =/= [] of
                true ->
                    KillerRoleID = lists:nth(1, WorldBossRoles),
                    world_boss_server:world_boss_dead(TypeID, KillerRoleID, get_role_name(KillerRoleID)),
                    [_LoopAdd, _CopyEquipAdd, BossAdd] = common_misc:get_global_list(?GLOBAL_FRIENDLY_ADD),
                    world_friend_server:add_friendly(team_misc:get_friendly_add_list(WorldBossRoles), BossAdd);
                _ ->
                    world_boss_server:world_boss_dead(TypeID, 0, "")
            end,
            Roles = [],
            IsDrop = false;
        Rarity =:= ?MONSTER_RARITY_WORLD_BOSS -> %% 其他世界boss
            WorldBossRoles = mod_monster_world_boss:get_drop_roles(MonsterData),
            case ?IS_WORLD_BOSS_SUB_TYPE(SubType) andalso WorldBossRoles =/= [] of
                true ->
                    KillerRoleID = lists:nth(1, WorldBossRoles),
                    world_boss_server:world_boss_dead(TypeID, KillerRoleID, get_role_name(KillerRoleID)),
                    [_LoopAdd, _CopyEquipAdd, BossAdd] = common_misc:get_global_list(?GLOBAL_FRIENDLY_ADD),
                    world_friend_server:add_friendly(team_misc:get_friendly_add_list(WorldBossRoles), BossAdd),
                    [begin
                         role_server:kill_world_boss(RoleID, TypeID),
                         mod_role_world_boss:add_world_boss_drop(RoleID, TypeID)
                     end || RoleID <- WorldBossRoles],
                    if
                        SubType =:= ?SUB_TYPE_WORLD_BOSS_2 -> %% 洞天福地，需要给前5的队友、盟友援助次数
                            AssistRoles = mod_monster_world_boss:get_assist_roles(MonsterData, lists:nth(1, WorldBossRoles)),
                            [mod_role_world_boss:add_cave_assist_times(AssistRoleID) || AssistRoleID <- AssistRoles];
                        true ->
                            ok
                    end;
                _ ->
                    world_boss_server:world_boss_dead(TypeID, 0, "")
            end,
            Roles = can_get_drop_roles(WorldBossRoles, Level, []),
            IsDrop = Roles =/= [];
        true ->
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 蛮荒禁地  && 远古遗迹
                    Roles = monster_misc:get_owner_roles(Owner),
                    [mod_role_world_boss:add_world_boss_drop(RoleID, TypeID) || RoleID <- Roles],
                    IsDrop = true;
                SubType =:= ?SUB_TYPE_MYTHICAL_BOSS orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 神兽岛地图
                    Roles = mod_monster_world_boss:get_mythical_monster(AttackList),
                    IsDrop = true;
                OwnerType =:= ?DROP_OWNER_FIRST -> %% 首刀
                    Roles = monster_misc:get_owner_roles(Owner),
                    IsDrop = true;
                OwnerType =:= ?DROP_OWNER_SHARE -> %% 共享
                    Roles = [],
                    IsDrop = true;
                true -> %% 其他
                    Roles = [],
                    IsDrop = true
            end
    end,
    case IsDrop of
        true ->
            do_monster_drop2(MonsterData, MonsterConfig, MapID, DropIDList, Roles);
        _ ->
            ok
    end.

do_monster_drop2(MonsterData, MonsterConfig, MapID, DropIDList, Roles) ->
    #r_monster{monster_id = MonsterID, type_id = TypeID, born_time = BornTime} = MonsterData,
    #c_monster{rarity = Rarity, special_drop_id = SpecialDropID, drop_id_list = DropIDList, drop_type = DropType} = MonsterConfig,
    MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    DropIDList2 = get_drop_id_list(DropIDList, Rarity, BornTime),
    DropIDList3 = get_act_drop_id_list(DropIDList2),
    Multi = act_double_copy:get_drop_multi(MapID),
    DropIDList4 = lists:flatten([DropIDList3 || _Index <- lists:seq(1, Multi)]),
    DropArgsList =
    case Roles of
        [FirstRoleID|_] ->
            if
                DropType =:= ?DROP_FB_TEAM -> %%
                    [begin
                         SpecialDropList = get_role_special_drop(FirstRoleID, SpecialDropID),
                         #drop_args{drop_id_list = SpecialDropList ++ DropIDList4, drop_role_id = OwnerRoleID, monster_type_id = TypeID,
                                    owner_roles = [OwnerRoleID], center_pos = MonsterPos, broadcast_roles = [OwnerRoleID]}
                     end || OwnerRoleID <- Roles];
                true ->
                    %% 特殊掉落出发
                    SpecialDropList = get_role_special_drop(FirstRoleID, SpecialDropID),
                    [#drop_args{drop_id_list = SpecialDropList ++ DropIDList4, drop_role_id = FirstRoleID, monster_type_id = TypeID, owner_roles = Roles, center_pos = MonsterPos}]
            end;
        _ ->
            [#drop_args{drop_id_list = DropIDList4, monster_type_id = TypeID, owner_roles = Roles, center_pos = MonsterPos}]
    end,
    mod_map_monster:monster_drop(DropArgsList).


%%%%%%%%%%%%%%%%%%%%%%%%%          道庭boss屏蔽   open   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



get_drop_id_list(DropIDList, _Rarity, _BornTime) ->
    DropIDList.
%%    if
%%        Rarity =:= ?MONSTER_RARITY_FAMILY_BOSS ->
%%            get_family_boss_drop_list(BornTime, DropIDList);
%%        true ->
%%            DropIDList
%%    end.

%%get_family_boss_drop_list(BornTime, DropIDList) ->
%%    UseTime = time_tool:now() - BornTime,
%%    Start = get_drop_start(UseTime),
%%    case lists:keyfind(Start, 1, DropIDList) of
%%        false ->
%%            [];
%%        {Start, DropIDList2} when erlang:is_list(DropIDList2) ->
%%            DropIDList2;
%%        _ ->
%%            []
%%    end.

%%get_drop_start(UseTime) ->
%%    [Config] = lib_config:find(cfg_family_boss_start, 5),
%%    [Begin, End] = Config#c_family_boss_start.region,
%%    Res = UseTime >= Begin andalso End >= UseTime,
%%    ?IF(Res, Config#c_family_boss_start.start, get_drop_start(UseTime, Config#c_family_boss_start.start - 1)).

%%get_drop_start(_UseTime, 0) ->
%%    0;
%%get_drop_start(UseTime, Start) ->
%%    [Config] = lib_config:find(cfg_family_boss_start, Start),
%%    [Begin, End] = Config#c_family_boss_start.region,
%%    Res = UseTime >= Begin andalso End >= UseTime,
%%    ?IF(Res, Config#c_family_boss_start.start, get_drop_start(UseTime, Config#c_family_boss_start.start - 1)).


%%%%%%%%%%%%%%%%%%%%%%%%%          道庭boss屏蔽   close   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_act_drop_id_list(DropIDList) ->
    ActDropIDList = get_act_drops(),
    DropIDList2 = ActDropIDList ++ DropIDList,
    IsCross = common_config:is_cross_node(),
    filter_drop_id(DropIDList2, IsCross, []).

filter_drop_id([], _IsCross, Acc) ->
    Acc;
filter_drop_id([DropID|R], IsCross, Acc) ->
    case lib_config:find(cfg_act_drop, DropID) of
        [{ActID, ActType}] ->
            Acc2 = ?IF((not IsCross) andalso check_act(ActType, ActID, DropID), [DropID|Acc], Acc),
            filter_drop_id(R, IsCross, Acc2);
        _ ->
            filter_drop_id(R, IsCross, [DropID|Acc])
    end.

check_act(0, ActID, _) ->
    world_act_server:is_act_open(ActID);
check_act(2, ActID, _) ->
    world_cycle_act_server:is_act_open(ActID);
check_act(_, ActID, DropID) ->
    case world_bg_act_server:get_bg_act(ActID) of
        #r_bg_act{status = ?BG_ACT_STATUS_TWO, config = [{boss_drop, BossDrop}, {boss_drop2, BossDrop2}|_]} ->
            BossDrop =:= DropID orelse BossDrop2 =:= DropID;
        _ ->
            false
    end.


can_get_drop_roles([], _Level, Roles) ->
    Roles;
can_get_drop_roles([RoleID|T], Level, Roles) ->
    case get_role_level(RoleID) - Level > common_misc:get_global_int(?GLOBAL_WORLD_BOSS_LEVEL) of
        true ->
            can_get_drop_roles(T, Level, Roles);
        _ ->
            can_get_drop_roles(T, Level, [RoleID|Roles])
    end.


init_act_drop(MapID) ->
    [MapConfig] = lib_config:find(cfg_map_base, MapID),
    case lib_tool:string_to_intlist(MapConfig#c_map_base.act_drop) of
        [] ->
            set_act_drops([]);
        ActDropList ->
            world_act_server:info({monster_server_open, ActDropList, erlang:self()}),
            ActList = world_act_server:get_all_act(),
            DropList2 = lists:foldl(
                fun(Act, DropList) ->
                    case Act#r_act.status =:= ?ACT_STATUS_OPEN of
                        true ->
                            case lists:keyfind(Act#r_act.id, 1, ActDropList) of
                                false ->
                                    DropList;
                                {_, DropID} ->
                                    [DropID|DropList]
                            end;
                        _ ->
                            DropList
                    end
                end, [], ActList),
            set_act_drops(DropList2)
    end.

drop_act_change(ActID, Status) ->
    MapID = map_common_dict:get_map_id(),
    [MapConfig] = lib_config:find(cfg_map_base, MapID),
    ActDropList = lib_tool:string_to_intlist(MapConfig#c_map_base.act_drop),
    case lists:keyfind(ActID, 1, ActDropList) of
        false ->
            ok;
        {_, DropID} ->
            Drops = get_act_drops(),
            case Status of
                ?ACT_STATUS_OPEN ->
                    case lists:member(DropID, Drops) of
                        true ->
                            ok;
                        _ ->
                            set_act_drops([DropID|Drops])
                    end;
                _ ->
                    set_act_drops(lists:delete(DropID, Drops))
            end
    end.


set_act_drops(List) ->
    erlang:put({?MODULE, dropList}, List).
get_act_drops() ->
    case erlang:get({?MODULE, dropList}) of
        [_|_] = List -> List;
        _ -> []
    end.

get_role_special_drop(RoleID, SpecialDropID) ->
    case mod_map_ets:get_map_role(RoleID) of
        #r_map_role{special_drops = SpecialDrops} ->
            {DropIDList, AddList} = get_special_drop(SpecialDrops, SpecialDropID),
            ?IF(AddList =/= [], mod_role_extra:add_special_drop(RoleID, AddList), ok),
            DropIDList;
        _ ->
            []
    end.

%% 返回{DropIDList, AddList}
get_special_drop(_SpecialDrops, SpecialDropID) when SpecialDropID =< 0 ->
    {[], []};
get_special_drop(SpecialDrops, SpecialDropID) ->
    [IndexList] = lib_config:find(cfg_special_drop, {drop_group_index, SpecialDropID}),
    get_special_drop2(IndexList, SpecialDrops, [], []).

get_special_drop2([], _SpecialDrops, DropAcc, AddAcc) ->
    {DropAcc, AddAcc};
get_special_drop2([IndexID|R], SpecialDrops, DropAcc, AddAcc) ->
    [#c_special_drop{
        min_times = MinTimes,
        max_times = MaxTimes,
        times = Times,
        drop_id_list = DropIDList}] = lib_config:find(cfg_special_drop, IndexID),
    {KillTimes, DropTimes} =
    case lists:keyfind(IndexID, #p_kvt.id, SpecialDrops) of
        #p_kvt{val = KillTimesT, type = DropTimesT} ->
            {KillTimesT, DropTimesT};
        _ ->
            {0, 0}
    end,
    KillTimes2 = KillTimes + 1,
    if
        KillTimes2 > MaxTimes ->  %% 超过上限，不再触发
            get_special_drop2(R, SpecialDrops, DropAcc, AddAcc);
        KillTimes2 < MinTimes -> %% 还没达到下限，也不触发
            get_special_drop2(R, SpecialDrops, DropAcc, AddAcc);
        DropTimes >= Times -> %% 掉落足够了，不用再触发了
            get_special_drop2(R, SpecialDrops, DropAcc, AddAcc);
        MinTimes =:= MaxTimes -> %% 上下限一致，必定触发
            get_special_drop2(R, SpecialDrops, DropIDList ++ DropAcc, [{IndexID, true}|AddAcc]);
        true ->
            case (MaxTimes - KillTimes - DropTimes) =< Times of
                true -> %% 剩余次数不足了，一定触发
                    get_special_drop2(R, SpecialDrops, DropIDList ++ DropAcc, [{IndexID, true}|AddAcc]);
                _ ->
                    Rate = lib_tool:ceil(((Times - DropTimes) / (MaxTimes - KillTimes)) * ?RATE_10000),
                    case common_misc:is_active(Rate) of
                        true ->
                            get_special_drop2(R, SpecialDrops, DropIDList ++ DropAcc, [{IndexID, true}|AddAcc]);
                        _ ->
                            get_special_drop2(R, SpecialDrops, DropAcc, [{IndexID, false}|AddAcc])
                    end
            end
    end.


%%根据地图类型处理

deal_monster_dead_by_map(MapID, ExpRoles) ->
    [#c_map_base{sub_type = SubType}] = lib_config:find(cfg_map_base, MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_2 ->
            mod_role_daily_liveness:trigger_daily_liveness(ExpRoles, ?LIVENESS_WORLD_BOSS2);
        SubType =:= ?SUB_TYPE_WORLD_BOSS_3 ->
            mod_role_daily_liveness:trigger_daily_liveness(ExpRoles, ?LIVENESS_PERSONAL_BOSS);
        true ->
            ok
    end.

get_role_level(RoleID) ->
    case mod_map_ets:get_actor_mapinfo(RoleID) of
        #r_map_actor{role_extra = #p_map_role{level = RoleLevel}} ->
            RoleLevel;
        _ ->
            0
    end.

get_role_name(RoleID) ->
    case mod_map_ets:get_actor_mapinfo(RoleID) of
        #r_map_actor{actor_name = ActorName} ->
            ActorName;
        _ ->
            ""
    end.


