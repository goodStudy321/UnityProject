%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     场景掉落相关 不独立做server了
%%% @end
%%% Created : 04. 九月 2017 19:19
%%%-------------------------------------------------------------------
-module(mod_map_drop).
-author("laijichang").
-include("global.hrl").
-include("drop.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_extra.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    init/1,
    loop/1
]).

%% mod_map_actor回调
-export([
    enter_map/1
]).

-export([
    born_drops/1,
    born_drops3/5,
    monster_drop_silver/2,
    role_first_drop/4,
    marry_born_drop/3,
    pick_drop/3,
    get_drop_by_item_control/1,
    get_drop_item_list2/1,
    do_role_item_control/2
]).

-export([
    gm_add_drop/2,
    gm_drop_id/2,
    get_item_by_equip_drop_id/1,
    get_really_id/1
]).

init(MapID) ->
    mod_drop_data:init(MapID).

loop(Now) ->
    LoopList = mod_drop_data:get_drop_loop_list(),
    LoopList2 =
    lists:foldl(
        fun({ActorID, EndTime}, Acc) ->
            case Now >= EndTime of
                true ->
                    ?TRY_CATCH(mod_map_actor:leave_map(ActorID, [])),
                    Acc;
                _ ->
                    [{ActorID, EndTime}|Acc]
            end
        end, [], LoopList),
    mod_drop_data:set_drop_loop_list(LoopList2).


pick_drop(RoleID, DropID, PickCondition) ->
    case catch check_can_pick(RoleID, DropID, PickCondition) of
        {ok, IsMarryFeast, GoodsList, MapDrop} ->
            common_misc:unicast(RoleID, #m_pick_drop_toc{drop_id = DropID}),
            mod_map_actor:leave_map(DropID, []),
            mod_drop_data:del_drop_loop_list(DropID),
            ?IF(IsMarryFeast, mod_map_marry:pick_drop(RoleID), ok),
            {ok, GoodsList, MapDrop};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_pick(RoleID, DropID, PickCondition) ->
    case mod_map_ets:get_actor_mapinfo(DropID) of
        #r_map_actor{drop_extra = MapDrop} ->
            #r_map_actor{drop_extra = MapDrop} = mod_map_ets:get_actor_mapinfo(DropID),
            #p_map_drop{type_id = TypeID, num = Num, bind = Bind, owner_roles = OwnerRoles} = MapDrop,
            IsMarryFeast = ?IS_MAP_MARRY_FEAST(map_common_dict:get_map_id()),
            ?IF(IsMarryFeast, mod_map_marry:check_pick_drop(RoleID), ok),
            check_pick_condition(TypeID, PickCondition),
            ?IF(OwnerRoles =:= [] orelse lists:member(RoleID, OwnerRoles), ok, ?THROW_ERR(?ERROR_PICK_DROP_001)),
            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = Bind}],
            {ok, IsMarryFeast, GoodsList, MapDrop};
        _ ->
            ?THROW_ERR(?ERROR_PICK_DROP_001)
    end.

check_pick_condition(TypeID, PickCondition) ->
    #r_pick_condition{
        is_mythical_equip_full = IsMythicalFull,
        is_war_spirit_equip_full = IsWarSpiritFull
    } = PickCondition,
    case lib_config:find(cfg_mythical_equip_info, TypeID) of
        [_MythicalConfig] ->
            ?IF(IsMythicalFull, ?THROW_ERR(?ERROR_PICK_DROP_005), ok);
        _ ->
            ok
    end,
    case lib_config:find(cfg_war_spirit_equip_info, TypeID) of
        [_WarSpiritConfig] ->
            ?IF(IsWarSpiritFull, ?THROW_ERR(?ERROR_PICK_DROP_006), ok);
        _ ->
            ok
    end.

%%%===================================================================
%%% mod_map_actor回调 start
%%%===================================================================
enter_map({ActorID, _RecordPos, ExtraArgs}) ->
    EndTime =
    case ExtraArgs of
        {drop_end_time, EndTimeT} -> %% 掉落物自己设置结束时间
            EndTimeT;
        _ ->
            time_tool:now() + ?DROP_LEAVE_TIME
    end,
    mod_drop_data:add_drop_loop_list({ActorID, EndTime}).

%%%===================================================================
%%% mod_map_actor回调 end
%%%===================================================================

gm_add_drop(RoleID, TypeID) ->
    #r_pos{mx = Mx, my = My} = Pos = mod_map_ets:get_actor_pos(RoleID),
    DropList = [#p_map_drop{
        type_id = TypeID,
        num = 1,
        bind = true,
        monster_pos = map_misc:pos_encode(Pos),
        owner_roles = [RoleID],
        broadcast_roles = [RoleID]}
    ],
    MapInfos = born_drops4(DropList, [{Mx, My}], []),
    ExtraArgs = map_misc:get_enter_bc_filter([]),
    mod_map_actor:multi_enter_map(MapInfos, ExtraArgs).

gm_drop_id(RoleID, DropIDList) ->
    Pos = mod_map_ets:get_actor_pos(RoleID),
    DropArgs = 
        #drop_args{
              drop_id_list = DropIDList,
              drop_role_id = RoleID,
              monster_type_id = 200001,
              owner_roles = [],
              center_pos = Pos
        },
    born_drops([DropArgs]).

%% 出生掉落物
born_drops(DropArgsList) ->
    [ begin
          #drop_args{
              drop_id_list = DropIDList,
              monster_type_id = MonsterTypeID,
              drop_role_id = DropRoleID,
              owner_roles = OwnerRoles,
              center_pos = CenterPos,
              broadcast_roles = BroadcastRoles} = DropArgs,
          MapRole = mod_map_ets:get_map_role(DropRoleID),
          {DropList, MapRole2} = lists:foldl(
              fun(DropID, {DropAcc, MapRoleAcc}) ->
                  {AddDrop, MapRoleAcc2} = get_drop_item_list(DropID, CenterPos, MonsterTypeID, OwnerRoles, BroadcastRoles, MapRoleAcc),
                  {AddDrop ++ DropAcc, MapRoleAcc2}
          end, {[], MapRole}, DropIDList),
          case DropRoleID =/= undefined andalso MapRole =/= MapRole2 of
              true -> %% 通知角色，地图直接设置
                  mod_role_extra:add_item_drop(DropRoleID, MapRole2#r_map_role.item_drops),
                  mod_map_ets:set_map_role(DropRoleID, MapRole2);
              _ ->
                  ok
          end,
          born_drops3(DropList, OwnerRoles, MonsterTypeID, CenterPos, BroadcastRoles)
      end|| DropArgs <- DropArgsList].

born_drops3([], _OwnerRoles, _MonsterTypeID, _CenterPos, _BcRoles) ->
    ok;
born_drops3(DropList, OwnerRoles, MonsterTypeID, CenterPos, BcRoles) ->
    #r_pos{mx = Mx, my = My} = CenterPos,
    PosList = get_drop_pos_list(Mx, My, erlang:length(DropList)),
    MapInfos = born_drops4(DropList, PosList, []),
    ?TRY_CATCH(world_boss_drop(MonsterTypeID, OwnerRoles, DropList)),
    ExtraArgs = map_misc:get_enter_bc_filter(BcRoles),
    mod_map_actor:multi_enter_map(MapInfos, ExtraArgs).

born_drops4([], [], Acc) ->
    Acc;
born_drops4([MapDrop|R1], [{Mx, My}|R2], Acc) ->
    ActorID = mod_drop_data:get_new_drop_id(),
    MapInfo = #r_map_actor{
        actor_id = ActorID,
        actor_type = ?ACTOR_TYPE_DROP,
        pos = map_misc:pos_encode(map_misc:get_pos_by_meter(Mx, My)),
        hp = 1,
        max_hp = 1,
        camp_id = 0,
        move_speed = 0,
        drop_extra = MapDrop},
    Acc2 = [{MapInfo, #actor_fight_attr{}}|Acc],
    born_drops4(R1, R2, Acc2).

monster_drop_silver(DropItemList, CenterPos) ->
    #r_pos{mx = Mx, my = My} = CenterPos,
    PosList = get_slice_drop_list(Mx, My, erlang:length(DropItemList)),
    MapInfos = born_drops4(DropItemList, PosList, []),
    ExtraArgs = map_misc:get_enter_bc_filter([]),
    mod_map_actor:multi_enter_map(MapInfos, ExtraArgs).

role_first_drop(RoleID, MonsterTypeID, TypeIDList, MonsterPos) ->
    #r_pos{mx = Mx, my = My} = Pos = ?IF(MonsterPos =/= undefined, MonsterPos, mod_map_ets:get_actor_pos(RoleID)),
    PosList = get_drop_pos_list(Mx, My, erlang:length(TypeIDList)),
    MapDrops =
    [
        #p_map_drop{
            type_id = TypeID,
            num = Num,
            bind = true,
            monster_pos = map_misc:pos_encode(Pos),
            monster_type_id = MonsterTypeID,
            owner_roles = [RoleID],
            broadcast_roles = [RoleID]} || {TypeID, Num} <- TypeIDList],
    MapInfos = born_drops4(MapDrops, PosList, []),
    ExtraArgs = map_misc:get_enter_bc_filter([]),
    mod_map_actor:multi_enter_map(MapInfos, ExtraArgs).

marry_born_drop(MapDrops, Pos, EndTime) ->
    #r_pos{mx = Mx, my = My} = Pos,
    PosList = get_drop_pos_list(Mx, My, erlang:length(MapDrops)),
    MapInfos = born_drops4(MapDrops, PosList, []),
    ExtraArgs = {drop_end_time, EndTime},
    mod_map_actor:multi_enter_map(MapInfos, ExtraArgs).

%% 获取掉落道具列表
get_drop_item_list(DropID, CenterPos, MonsterTypeID, OwnerRoles, BroadcastRoles, MapRole) ->
    Items = get_drop_item_list2(DropID),
    Now = time_tool:now(),
    case Items =/= [] of
        true ->
            case do_item_control(DropID, MapRole, Now) of
                {true, MapRole2} ->
                    AddDrops = [  #p_map_drop{
                        type_id = TypeID,
                        num = Num,
                        bind = IsBind,
                        monster_pos = map_misc:pos_encode(CenterPos),
                        monster_type_id = MonsterTypeID,
                        owner_roles = OwnerRoles,
                        broadcast_roles = BroadcastRoles} || {TypeID, Num, IsBind} <- Items],
                    {AddDrops, MapRole2};
                {false, MapRole2} ->
                    {[], MapRole2};
                _ ->
                    AddDrops = [  #p_map_drop{
                        type_id = TypeID,
                        num = Num,
                        bind = IsBind,
                        monster_pos = map_misc:pos_encode(CenterPos),
                        monster_type_id = MonsterTypeID,
                        owner_roles = OwnerRoles,
                        broadcast_roles = BroadcastRoles} || {TypeID, Num, IsBind} <- Items],
                    {AddDrops, MapRole}
            end;
        _ ->
            {[], MapRole}
    end.

%% 有全服阈值控制
get_drop_by_item_control(DropID) ->
    Items = get_drop_item_list2(DropID),
    case Items =/= [] of
        true ->
            case lib_config:find(cfg_drop_item, DropID) of
                [#c_drop_item{index_id = IndexID} = Config] -> %% 需要掉落控制
                    WorldIndexList = world_data:get_drop_item_control(),
                    {IsDrop, WorldIndexList2} = do_item_control3(IndexID, Config, time_tool:now(), WorldIndexList, true),
                    case IsDrop of
                        true -> %% 全服控制可以掉落;
                            world_data:set_drop_item_control(WorldIndexList2),
                            Items;
                        _  ->
                            []
                    end;
                _ ->
                    Items
            end;
        _ ->
            []
    end.

get_drop_item_list2(DropID) ->
    case lib_config:find(cfg_drop, DropID) of
        [DropConfig] ->
            #c_drop{
                drop_times = Times,
                drop_bag_list = DropBagList
            } = DropConfig,
            get_drop_item_list3(Times, DropBagList, []);
        _ ->
            ?ERROR_MSG("未配置对应的掉落ID:~w", [DropID]),
            []
    end.

get_drop_item_list3(Times, _DropBagList, Items) when Times =:= 0 ->
    Items;
get_drop_item_list3(Times, DropBagList, Items) ->
    {Num2, ItemID2, Bind2} = case lib_tool:get_weight_output(DropBagList) of
                                 {Num, ItemID, Bind} ->
                                     {Num, ItemID, Bind};
                                 {Num, ItemID} ->
                                     {Num, ItemID, false}
                             end,
    case catch get_really_id(ItemID2) of
        {ok, RItemID} when RItemID =/= 0 ->
            get_drop_item_list3(Times - 1, DropBagList, [{RItemID, Num2, Bind2}|Items]);
        _ ->
            get_drop_item_list3(Times - 1, DropBagList, Items)
    end.

get_really_id(ItemID) ->
    case ItemID of
        {Color, List} ->
            [Random] = lib_config:find(cfg_equip_start_create, Color),
            Start = lib_tool:get_weight_output(Random#c_equip_start_create.list),
            case lists:keyfind(Start, 1, List) of
                false ->
                    false;
                {_, RItemID} ->
                    {ok, RItemID}
            end;
        ItemID when erlang:is_integer(ItemID) ->
            {ok, ItemID}
    end.


%% 优先3*3格子,再5*5 再7*7
%% 必须是有效位置
%% 尽量不要堆叠在一起
get_drop_pos_list(Mx, My, 1) ->
    [{Mx, My}];
get_drop_pos_list(Mx, My, Num) ->
    if
        Num =< 9 -> %% 3 * 3
            List = [{-150, 0}, {150, 0}, {0, -150}, {0, 150}, {-150, -150}, {150, -150}, {-150, 150}, {150, 150}, {0, 0}];
        Num =< 25 -> %% 5 * 5
            List = [{-150, 0}, {150, 0}, {0, -150}, {0, 150}, {-150, -150}, {150, -150}, {-150, 150}, {150, 150}, {0, 0},
                    {-300, 0}, {300, 0}, {0, -300}, {0, 300}, {-300, -150}, {-300, 150}, {300, -150}, {300, 150}, {-150, -300},
                    {150, -300}, {-150, 300}, {150, 300}, {-300, -300}, {300, -300}, {-300, 300}, {300, 300}, {0, 0}];
        true -> %% 7 * 7
            List = [{-150, 0}, {150, 0}, {0, -150}, {0, 150}, {-150, -150}, {150, -150}, {-150, 150}, {150, 150}, {0, 0},
                    {-300, 0}, {300, 0}, {0, -300}, {0, 300}, {-300, -150}, {-300, 150}, {300, -150}, {300, 150}, {-150, -300},
                    {150, -300}, {-150, 300}, {150, 300}, {-300, -300}, {300, -300}, {-300, 300}, {300, 300}, {0, -450}, {0, 450},
                    {-150, -450}, {-150, 450}, {150, -450}, {150, 450}, {-300, -450}, {-300, 450}, {300, -450}, {300, 450}, {-450, 0},
                    {-450, -150}, {-450, 150}, {-450, -300}, {-450, 300}, {-450, -450}, {-450, 450}, {450, 0}, {450, -150}, {450, 150}, {450, -300},
                    {450, 300}, {450, -450}, {450, 450}, {0, 0}]
    end,
    get_drop_pos_list2(Mx, My, Num, List, []).

get_drop_pos_list2(Mx, My, Num, [{AddMx, AddMy}|List], PosList) when Num > 0 ->
    Mx2 = Mx + AddMx, My2 = My + AddMy,
    case map_base_data:is_exist(?M2T(Mx2), ?M2T(My2)) of
        true ->
            get_drop_pos_list2(Mx, My, Num - 1, List, [{Mx2, My2}|PosList]);
        _ ->
            get_drop_pos_list2(Mx, My, Num, List, PosList)
    end;
get_drop_pos_list2(Mx, My, Num, [], PosList) when Num > 0 -> %% 取完了还没结束,那就在结果里面再取
    Len = erlang:length(PosList),
    case Len >= Num of
        true ->
            get_drop_pos_list2(Mx, My, 0, [], lists:sublist(PosList, Num) ++ PosList);
        _ ->
            get_drop_pos_list2(Mx, My, Num - Len, [], PosList ++ PosList)
    end;
get_drop_pos_list2(_Mx, _My, 0, _List, PosList) ->
    PosList.

get_slice_drop_list(Mx, My, 1) ->
    [{Mx, My}];
get_slice_drop_list(Mx, My, Num) ->
    List = [{-400, -400}, {-400, -200}, {-400, 0}, {-400, 200}, {-400, 400}, {-200, -400}, {-200, -200}, {-200, 200}, {-200, 400},
            {0, -400}, {0, 400}, {200, -400}, {200, -200}, {200, 200}, {200, 400}, {400, -400}, {400, -200}, {400, 0}, {400, 200}, {400, 400}],
    get_drop_pos_list2(Mx, My, Num, lib_tool:random_reorder_list(List), []).

world_boss_drop(MonsterTypeID, OwnerRoles, DropList) ->
    case lib_config:find(cfg_world_boss, MonsterTypeID) of
        [#c_world_boss{boss_type = BossType}] when ?IS_WORLD_BOSS_TYPE(BossType) ->
%%            [#c_monster{monster_name = Name}] = lib_config:find(cfg_monster, MonsterTypeID),
            {GoodsList, BroadcastList} =
            lists:foldl(
                fun(#p_map_drop{type_id = TypeID, num = Num, bind = Bind}, {Acc1, Acc2}) ->
                    Goods = #p_goods{type_id = TypeID, num = Num, bind = Bind},
                    NewAcc1 = [Goods|Acc1],
                    NewAcc2 = ?IF(mod_role_item:is_item_notice(TypeID), [Goods|Acc2], Acc2),
                    {NewAcc1, NewAcc2}
                end, {[], []}, DropList),
            RoleNames =
                [begin
                     #r_map_actor{actor_name = ActorName} = mod_map_ets:get_actor_mapinfo(RoleID),
                     ActorName
                 end || RoleID <- OwnerRoles],
            RoleNames2 = common_misc:get_log_string(RoleNames),
            Log =
                #log_world_boss_drop{
                    boss_type_id = MonsterTypeID,
                    drop_goods_list = common_misc:to_goods_string(GoodsList),
                    kill_role_names = RoleNames2
                },
            case OwnerRoles of
                [OwnerRoleID|_] ->
                    background_misc:cross_log(OwnerRoleID, Log);
                _ ->
                    background_misc:log(Log)
            end,
            ?IF(BroadcastList =/= [], ignore, ok);
        _ ->
            ok
    end.

get_item_by_equip_drop_id(TypeID) ->
    case lib_config:find(cfg_drop_equip, TypeID) of
        [Config] ->
            Color = ?GET_DROP_ID_COLOR(TypeID),
            Args = {Color, [{0, Config#c_drop_equip.start0}, {1, Config#c_drop_equip.start1}, {2, Config#c_drop_equip.start2}, {3, Config#c_drop_equip.start3}]},
            {ok, TypeID2} = get_really_id(Args),
            TypeID2;
        _ ->
            TypeID
    end.

%% 检查道具控制掉落是否触发
do_item_control(DropID, MapRoleAcc, Now) ->
    case lib_config:find(cfg_drop_item, DropID) of
        [Config] -> %% 需要掉落控制
            case MapRoleAcc of
                #r_map_role{item_drops = RoleIndexList} ->
                    case do_item_control2(RoleIndexList, Config, Now) of
                        {true, RoleIndexList2} ->
                            {true, MapRoleAcc#r_map_role{item_drops = RoleIndexList2}};
                        _ ->
                            {false, MapRoleAcc}
                    end;
                _ ->
                    {false, MapRoleAcc}
            end;
        _ ->
            ok
    end.

%% 角色进程调用
do_role_item_control(DropID, RoleIndexList) ->
    case lib_config:find(cfg_drop_item, DropID) of
        [#c_drop_item{} = Config] -> %% 需要掉落控制
            case do_item_control2(RoleIndexList, Config, time_tool:now()) of
                {true, RoleIndexList2} ->
                    {true, RoleIndexList2};
                _ ->
                    {false, RoleIndexList}
            end;
        _ ->
            {true, RoleIndexList}
    end.

do_item_control2(RoleIndexList, Config, Now) ->
    #c_drop_item{index_id = IndexID} = Config,
    WorldIndexList = world_data:get_drop_item_control(),
    {IsDrop, WorldIndexList2} = do_item_control3(IndexID, Config, Now, WorldIndexList, true),
    case IsDrop of
        true -> %% 全服控制可以掉落
            {IsDrop2, RoleIndexList2} = do_item_control3(IndexID, Config, Now, RoleIndexList, false),
            case IsDrop2 of
                true ->
                    %% 这里可能会有并发问题，概率太低，已经跟策划同步过可以接受
                    world_data:set_drop_item_control(WorldIndexList2),
                    {true, RoleIndexList2};
                _ ->
                    false
            end;
        _ ->
            false
    end.

do_item_control3(IndexID, Config, Now, IndexList, IsAll) ->
    #c_drop_item{
        all_num = AllNum,
        all_refresh_hours = AllRefreshHours,
        personal_num = PersonalNum,
        personal_refresh_hours = PersonalRefreshHours
    } = Config,
    case IsAll of
        true ->
            ?IF(AllNum =:= 0, {true, IndexList}, do_item_control4(IndexID, Now, AllNum, AllRefreshHours, IndexList));
        _ ->
            do_item_control4(IndexID, Now, PersonalNum, PersonalRefreshHours, IndexList)
    end.

do_item_control4(IndexID, Now, Num, Hours, IndexList) ->
    {ItemIndex, IndexList2} =
        case lists:keytake(IndexID, #r_item_index.index_id, IndexList) of
            {value, #r_item_index{} = ItemIndexT, IndexListT} ->
                {ItemIndexT, IndexListT};
            _ ->
                {#r_item_index{index_id = IndexID, drop_list = []}, IndexList}
        end,
    #r_item_index{times = Times, drop_list = DropList} = ItemIndex,
    {KV, DropList2} =
        case lists:keytake(Times, #p_kv.id, DropList) of
            {value, #p_kv{} = KVT, DropListT} ->
                {KVT, DropListT};
            _ ->
                {#p_kv{id = Times, val = 0}, DropList}
        end,
    #p_kv{val = LastDropTime} = KV,
    case Now >= LastDropTime + ?AN_HOUR * Hours of
        true -> %% 跟上次时间对比，可以掉了
            DropList3 = [KV#p_kv{val = Now}|DropList2],
            Times2 = ?IF(Times >= Num, 1, Times + 1),
            ItemIndex2 = ItemIndex#r_item_index{times = Times2, drop_list = DropList3},
            {true, [ItemIndex2|IndexList2]};
        _ ->
            {false, IndexList}
    end.
