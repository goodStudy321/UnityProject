%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 四月 2017 16:37
%%%-------------------------------------------------------------------
-module(mod_role_map).
-author("laijichang").
-include("role.hrl").
-include("role_extra.hrl").
-include("copy.hrl").
-include("discount_pay.hrl").
-include("proto/gateway.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    pre_init/1,
    init_map/1,
    day_reset/1,
    zero/1,
    online/1,
    offline/1,
    do_first_enter_map/2,
    handle/2
]).

-export([
    do_enter_map/2,
    do_quit_map/1,
    do_pre_enter/3,
    do_gm_pre_enter/2
]).

-export([
    pre_enter_map/2,
    quit_map/1
]).

-export([
    add_map_lock/2,
    remove_map_lock/1
]).

-export([
    gm_clear_enter_list/1
]).

pre_init(#r_role{role_id = RoleID, role_map = undefined} = State) ->
    MapID = map_misc:get_home_map_id(),
    ExtraID = map_branch_manager:get_map_cur_extra_id(MapID),
    {ok, Pos} = map_misc:get_born_pos(MapID),
    ServerID = common_config:get_server_id(),
    RoleMap = #r_role_map{
        role_id = RoleID,
        pos = Pos,
        server_id = ServerID,
        map_id = MapID,
        extra_id = ExtraID,
        map_pname = map_misc:get_map_pname(MapID, ExtraID, ServerID)},
    State#r_role{role_map = RoleMap};
pre_init(State) ->
    State.

init_map(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr, role_map = RoleMap, role_fight = RoleFight} = State,
    RoleMap2 = init_map2(RoleID, RoleMap, RoleAttr, State),
    {RoleMap3, PrivateAttr2} = modify_role_dead(RoleAttr, RoleMap2, PrivateAttr, RoleFight),
    State#r_role{role_map = RoleMap3, role_private_attr = PrivateAttr2}.

%%初始化RoleMap
init_map2(RoleID, RoleMap, RoleAttr, State) ->
    #r_role_map{server_id = ServerID, map_pname = MapPName, map_id = MapID, extra_id = ExtraID, pos = NowPos,
        old_server_id = OldServerID, old_map_id = OldMapID, old_extra_id = OldExtraID,
        old_map_pname = OldMapPName, old_pos = OldPos, camp_id = CampID} = RoleMap,
    AuthEnter = ?IF(mod_map_role_auth:auth_enter(RoleID, MapPName) =:= true, true, false),
    #r_role_attr{sex = Sex} = RoleAttr,
    case catch (not map_misc:is_copy_front(MapID)) andalso AuthEnter andalso is_able(MapID, ExtraID, State) of %% 先检查之前的地图能不能进入
        true ->
            case map_misc:is_copy(MapID) orelse ?IS_MAP_ANSWER(MapID) of
                true -> %% 副本地图在出生点位置
                    {ok, Pos} = map_misc:get_born_pos(#r_born_args{map_id = MapID, camp_id = CampID, sex = Sex}),
                    RoleMap#r_role_map{pos = Pos};
                _ ->
                    NowPos2 = map_misc:modify_pos(MapID, NowPos),
                    RoleMap#r_role_map{pos = NowPos2}
            end;
        _ ->
            case catch check_branch_map(RoleID, MapID, ServerID, NowPos, RoleMap) of
                {ok, RoleMap2} -> %% 如果之前的地图是野外，进入最新的分线
                    RoleMap2;
                _ ->
                    case catch mod_map_role_auth:auth_enter(RoleID, OldMapPName) of %% 查看旧地图能不能进入
                        true ->
                            OldPos2 = map_misc:modify_pos(OldMapID, OldPos),
                            RoleMap#r_role_map{server_id = OldServerID, map_pname = OldMapPName, map_id = OldMapID, extra_id = OldExtraID, pos = OldPos2, camp_id = ?DEFAULT_CAMP_ROLE};
                        _ ->
                            case catch check_branch_map(RoleID, OldMapID, OldServerID, OldPos, RoleMap) of
                                {ok, RoleMap2} -> %% 如果旧地图是野外，进入最新的分线
                                    RoleMap2;
                                _ -> %% 没办法了，只能回到主城了
                                    NewMapID = map_misc:get_home_map_id(),
                                    NewServerID = common_config:get_server_id(),
                                    {ok, NewPos} = map_misc:get_born_pos(map_misc:get_home_map_id()),
                                    NewExtraID = map_branch_manager:get_map_cur_extra_id(NewMapID),
                                    RoleMap#r_role_map{server_id = NewServerID, map_id = NewMapID,
                                        camp_id = ?DEFAULT_CAMP_ROLE, extra_id = NewExtraID,
                                        map_pname = map_misc:get_map_pname(NewMapID, NewExtraID), pos = NewPos}
                            end
                    end
            end
    end.

check_branch_map(RoleID, MapID, ServerID, Pos, RoleMap) ->
    case map_branch_manager:is_branch_map(MapID) of
        true ->
            NewExtraID = map_branch_manager:get_map_cur_extra_id(MapID),
            MapPName = map_misc:get_map_pname(MapID, NewExtraID, ServerID),
            Pos2 = map_misc:modify_pos(MapID, Pos),
            case catch mod_map_role_auth:auth_enter(RoleID, MapPName) of
                true ->
                    {ok, RoleMap#r_role_map{server_id = ServerID, map_pname = MapPName, map_id = MapID, extra_id = NewExtraID, pos = Pos2}};
                _ ->
                    false
            end;
        _ ->
            false
    end.

is_able(MapID, ExtraID, State) ->
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_2 orelse SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 洞天福地 && 蛮荒禁地 && 远古遗迹
            mod_role_world_boss:is_time_able(State);
        SubType =:= ?SUB_TYPE_WORLD_BOSS_1 -> %% 世界boss
            mod_role_world_boss:is_first_boss_able(MapID, State);
        ?IS_MAP_BATTLE(MapID) -> %% 战场
            mod_role_battle:is_battle_able(State);
        ?IS_MAP_SOLO(MapID) -> %% 1v1地图
            mod_role_solo:is_solo_able(State);
        ?IS_MAP_FAMILY_TD(MapID) -> %% 守卫道庭
            mod_role_family_td:is_able(State);
        ?IS_MAP_ANSWER(MapID) -> %% 道题
            mod_role_answer:is_able(State);
        ?IS_MAP_FAMILY_AS(MapID) -> %% 道庭答题
            mod_role_family_as:is_able(State);
        ?IS_MAP_SUMMIT_TOWER(MapID) -> %% 巅峰爬塔
            mod_role_summit_tower:is_able(State);
        ?IS_MAP_FAMILY_BT(MapID) -> %% 道庭战
            mod_role_family_bt:is_able(State);
        ?IS_MAP_MARRY_FEAST(MapID) -> %% 结婚场景
            mod_role_marry:is_able(State);
        ?IS_MAP_DEMON_BOSS(MapID) -> %% 魔域Boss
            mod_role_demon_boss:is_able(MapID, ExtraID, State);
        true ->
            true
    end.

day_reset(State) ->
    #r_role{role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{enter_list = []},
    State#r_role{role_map = RoleMap2}.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{enter_list = EnterList} = RoleMap,
    common_misc:unicast(RoleID, #m_map_enter_times_toc{enter_list = EnterList}),
    State.

offline(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    case mod_role_dict:get_pre_enter() of
        #r_role_enter{old_hp = OldHp, old_pos = OldPos} ->
            State#r_role{role_map = RoleMap#r_role_map{hp = OldHp, pos = OldPos}};
        _ ->
            case mod_role_dict:get_map_pid() of
                MapPID when erlang:is_pid(MapPID) ->
                    State2 = hook_role:role_quit_map(State),
                    {ok, #r_map_actor{hp = CurHp, pos = Pos}} = mod_map_role:role_get_mapinfo(MapPID, RoleID),
                    State2#r_role{role_map = RoleMap#r_role_map{hp = CurHp, pos = map_misc:pos_decode(Pos)}};
                _ ->
                    ?WARNING_MSG("map test:~w", [{mod_role_dict:get_login_state()}]),
                    State
            end
    end.

handle(quit_map, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_SERVER_QUIT, mod_role_data:get_role_map_id(State), State)),
    do_quit_map(State);
handle(home_map, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_SERVER_QUIT, map_misc:get_home_map_id(), State)),
    do_pre_enter(State#r_role.role_id, map_misc:get_home_map_id(), State);
handle(cross_disconnect, State) -> %% 跨服连接断开，退出地图
    #r_role{role_map = #r_role_map{server_id = ServerID}} = State,
    ?IF(common_config:is_cross_server_id(ServerID), do_quit_map(State), State);
handle({pre_enter_map, MapID}, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_SERVER_QUIT, MapID, State)),
    do_pre_enter(State#r_role.role_id, MapID, State);
handle({#m_pre_enter_tos{map_id = MapID, extra_id = ExtraID} = _DataIn, RoleID, _PID}, State) -> %% 第一次进入地图跟后续进入地图区别开
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_PRE_ENTER, MapID, State)),
    case role_login:is_waiting_for_enter() of
        true ->
            do_first_pre_enter(RoleID, MapID, State);
        _ ->
            do_pre_enter(RoleID, MapID, State, undefined, ExtraID)
    end;
handle({#m_enter_map_tos{} = _DataIn, RoleID, _PID}, State) -> %% 第一次进入地图跟后续进入地图区别开
    case role_login:is_waiting_for_enter() of
        true -> do_first_enter_map(RoleID, State);
        _ -> do_enter_map(RoleID, State)
    end;
handle({#m_quit_map_tos{}, _RoleID, _PID}, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_QUIT_MAP, mod_role_data:get_role_map_id(State), State)),
    do_quit_map(State);
handle({#m_map_change_pos_tos{map_id = DestMapID, dest_pos = DestPos, jump_id = JumpID, dest_jump_id = DestJumpID}, RoleID, _PID}, State) ->
    do_change_pos(RoleID, State, DestMapID, DestPos, JumpID, DestJumpID);
handle({#m_map_line_info_tos{map_id = MapID}, RoleID, _PID}, State) ->
    do_map_line(RoleID, MapID, State);
handle({copy_team_start, MapID, TeamID}, State) ->
    do_copy_team_start(MapID, TeamID, State);
handle({role_reduce_hp, SrcID, SrcActorType, ReduceHp, RemainHp}, State) ->
    do_role_reduce_hp(SrcID, SrcActorType, ReduceHp, RemainHp, State);
handle({role_add_hp, RemainHp}, State) ->
    do_role_add_hp(RemainHp, State);
handle({hp_change, RemainHp}, State) ->
    do_role_hp_change(RemainHp, State);
handle({role_dead, NowPos, SrcID, SrcType, SrcName}, State) ->
    do_role_dead(State, NowPos, SrcID, SrcType, SrcName);
handle({#m_role_relive_tos{op_type = OpType}, RoleID, _PID}, State) ->
    do_role_relive(RoleID, OpType, State).

pre_enter_map(RoleID, MapID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {pre_enter_map, MapID}}).
quit_map(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, quit_map}).

%% 初次登录准备进入地图
do_first_pre_enter(RoleID, MapID, State) ->
    State2 =
    case MapID =:= 0 of
        true -> %% 老号没资源的情况，要拉到另外一张地图
            MapID2 = map_misc:get_home_map_id(),
            {ok, BronPos} = map_misc:get_born_pos(MapID2),
            #r_role{role_map = RoleMap} = State,
            MapPName = map_misc:get_map_pname(MapID2, map_branch_manager:get_map_cur_extra_id(MapID2)),
            ServerID = common_config:get_server_id(),
            RoleMap2 = RoleMap#r_role_map{map_id = MapID2, pos = BronPos, server_id = ServerID, map_pname = MapPName},
            State#r_role{role_map = RoleMap2};
        _ ->
            State
    end,
    DestMapID = State2#r_role.role_map#r_role_map.map_id,
    common_misc:unicast(RoleID, #m_pre_enter_toc{map_id = DestMapID, pos = map_misc:pos_encode(State2#r_role.role_map#r_role_map.pos)}),
    ?TRY_CATCH(log_map_enter(?ACTION_PRE_ENTER, DestMapID, State), Err1),
    hook_role:role_pre_enter([], true, 0, State2#r_role.role_map#r_role_map.map_id, State2).

%% 角色第一次进入地图
do_first_enter_map(RoleID, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_ENTER, mod_role_data:get_role_map_id(State), State)),
    State2 = do_enter_map2(RoleID, true, State),
    mod_role_dict:set_login_state(?STATE_NORMAL_GAME),
    role_misc:info_role(RoleID, role_first_enter),
    State2.

%% 玩家准备进入地图
do_pre_enter(RoleID, MapID, State) ->
    do_pre_enter(RoleID, MapID, State, undefined).
do_pre_enter(RoleID, MapID, State, RecordPos) ->
    do_pre_enter(RoleID, MapID, State, RecordPos, 0).

do_gm_pre_enter(MapID, State) ->
    #r_role{role_id = RoleID} = State,
    ServerID = common_config:get_server_id(),
    ExtraID =
        case map_misc:is_copy(MapID) of
            true ->
                map_sup:start_map(MapID, RoleID, ServerID, []),
                RoleID;
            _ ->
                map_branch_manager:get_map_cur_extra_id(MapID)
        end,
    PreEnter = #r_role_enter{
        map_id = MapID,
        extra_id = ExtraID,
        server_id = ServerID,
        camp_id = ?DEFAULT_CAMP_ROLE,
        map_pname = map_misc:get_map_pname(MapID, ExtraID),
        record_pos = map_misc:get_born_pos(MapID)
    },
    do_pre_enter2(PreEnter, [], [], State).

do_pre_enter(RoleID, MapID, State, RecordPos, ExtraID) ->
    case catch check_pre_enter(MapID, State, RecordPos, ExtraID) of
        {pre_enter, MapID, EnterPos} -> %% 已经设置了地图进入数据
            common_misc:unicast(RoleID, #m_pre_enter_toc{map_id = MapID, pos = map_misc:pos_encode(EnterPos)}),
            State;
        {ok, PreEnter, AssetDoings, BagDoings, State2} ->
            ?IF(State#r_role.role_map#r_role_map.enter_list =/= State2#r_role.role_map#r_role_map.enter_list,
                common_misc:unicast(RoleID, #m_map_enter_times_toc{enter_list = State2#r_role.role_map#r_role_map.enter_list}),
                ok),
            do_pre_enter2(PreEnter, AssetDoings, BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pre_enter_toc{err_code = ErrCode}),
            case MapID =:= ?MAP_COPY_EXP andalso ErrCode =:= ?ERROR_COMMON_NO_ENOUGH_ITEM of
                true ->
                    State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_ENTER_COPY_EXP, State),
                    mod_role_discount_pay:condition_update(State2);
                _ ->
                    State
            end
    end.

do_pre_enter2(PreEnter, AssetDoings, BagDoings, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr ,  role_fight = #r_role_fight{fight_attr = FightAttr}} = State,
    {OldHp, OldPos} =
    case catch mod_map_role:role_quit_map(mod_role_dict:get_map_pid(), RoleID, {erlang:self(), true, RoleAttr#r_role_attr.skin_list}) of
        {ok, #r_map_actor{hp = OldHpT, pos = OldIntPos}} ->
            {OldHpT, map_misc:pos_decode(OldIntPos)};
        _ ->
            #r_role{role_map = #r_role_map{hp = OldHpT, pos = OldRecordPosT}} = State,
            {OldHpT, OldRecordPosT}
    end,
    #r_role{role_id = RoleID, role_map = #r_role_map{map_id = OldMapID}} = State,
    OldHp2 = case map_misc:is_copy(OldMapID) of
                 true ->
                     #actor_fight_attr{ max_hp = MaxHp} = FightAttr,
                     MaxHp;
                 _ ->
                     OldHp
             end,
    #r_role_enter{map_id = MapID} = PreEnter,
    mod_role_dict:set_map_pid(undefined),
    PreEnter2 = PreEnter#r_role_enter{old_hp = OldHp2, old_pos = OldPos},
    State2 = mod_role_asset:do(AssetDoings, State),
    State3 = mod_role_bag:do(BagDoings, State2),
    State4 = get_enter_state(State3, PreEnter2),
    State5 = hook_role:role_quit_map(State4),
    State6 = hook_role:role_pre_enter(BagDoings, false, OldMapID, MapID, State5),
    ?TRY_CATCH(log_map_enter(?ACTION_PRE_ENTER, MapID, State6)),
    common_misc:unicast(RoleID, #m_pre_enter_toc{map_id = MapID, pos = map_misc:pos_encode(State6#r_role.role_map#r_role_map.pos)}),
    State6.

check_pre_enter(FrontMapID, State, RecordPos, FrontExtraID) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{map_id = NowMapID, extra_id = NowExtraID} = RoleMap,
    %% 根据前端发来的MapID进行检测，这里检测完MapID也许会有修改 注意这里的State、RoleMap可能会有修改！！！
    {ServerID, MapID, ExtraID, CampID, RecordPos2, BagDoings, AssetDoings, State2} = check_pre_enter2(FrontMapID, FrontExtraID, RecordPos, State),
%%    case catch check_map_lock(MapID, MapLock) of
%%        ok ->
%%            ok;
%%        is_lock ->
%%            ?THROW_ERR(?ERROR_PRE_ENTER_018);
%%        Error ->
%%            ?ERROR_MSG("-------------ERROR MAP LOCK---------~w", [Error]),
%%            ok
%%    end,
    case mod_role_dict:get_pre_enter() of
        #r_role_enter{map_id = EnterMapID, extra_id = EnterExtraID, record_pos = DestPos} when MapID =:= EnterMapID andalso ExtraID =:= EnterExtraID -> %% 之前已经发起请求进入该地图了
            erlang:throw({pre_enter, MapID, DestPos});
        _ ->
            ok
    end,
    ?IF(NowMapID =/= MapID orelse (FrontExtraID > 0 andalso map_branch_manager:is_branch_map(MapID) andalso FrontExtraID =/= NowExtraID), ok, ?THROW_ERR(?ERROR_PRE_ENTER_005)),
    %% 流程树场景(非500001)只能进入旧的场景
    ?IF((map_misc:is_copy_front(NowMapID) andalso NowMapID =/= 500001) andalso not (map_misc:is_same_map_data(NowMapID, MapID)), ?THROW_ERR(?ERROR_PRE_ENTER_017), ok),
    %% 当前场景是副本场景不能进入500001场景
    ?IF((map_misc:is_copy(NowMapID) andalso MapID =:= 500001), ?THROW_ERR(?ERROR_PRE_ENTER_036), ok),
    [#c_map_base{min_level = MinLevel}] = lib_config:find(cfg_map_base, MapID),
    ?IF(mod_role_data:get_role_level(State) >= MinLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    MapPName = map_misc:get_map_pname(MapID, ExtraID, ServerID),
    case mod_map_role_auth:auth_enter(RoleID, MapPName) of
        true ->
            ok;
        {error, ErrCode} when erlang:is_integer(ErrCode) ->
            ?THROW_ERR(ErrCode);
        _ ->
            case ?IS_MAP_FAMILY_BOSS(MapID) of
                true ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_025);
                _ ->
                    ok
            end,
            ?THROW_ERR(?ERROR_PRE_ENTER_013)
    end,
    PreEnter = #r_role_enter{
        map_id = MapID,
        extra_id = ExtraID,
        server_id = ServerID,
        camp_id = CampID,
        map_pname = map_misc:get_map_pname(MapID, ExtraID, ServerID),
        record_pos = RecordPos2
    },
    {ok, PreEnter, AssetDoings, BagDoings, State2}.

%% 获取进入场景的具体信息
check_pre_enter2(FrontMapID, FrontExtraID, RecordPos, State) ->
    case map_misc:is_copy(FrontMapID) of
        true ->
            ?IF(map_misc:is_copy_team(FrontMapID), ?THROW_ERR(?ERROR_PRE_ENTER_007), ok),
            ?IF(map_misc:is_personal_boss_map(FrontMapID) andalso map_misc:is_copy(mod_role_data:get_role_map_id(State)), ?THROW_ERR(?ERROR_PRE_ENTER_029), ok),
            {State2, ExtraID, BagDoings, MapParams} = mod_role_copy:check_copy_enter(FrontMapID, State),
            ServerID = common_config:get_server_id(),
            MapID = FrontMapID,
            CampID = ?DEFAULT_CAMP_ROLE,
            RecordPos2 = ?IF(copy_misc:is_copy_marry(FrontMapID), mod_role_marry:get_born_pos(FrontMapID, State2), RecordPos),
            map_sup:start_map(FrontMapID, ExtraID, ServerID, MapParams),
            {ServerID, MapID, ExtraID, CampID, RecordPos2, BagDoings, [], State2};
        _ ->
            #c_map_base{sub_type = SubType, vip_enter_level = VIPEnterLevel} = ConfigMap = map_misc:get_map_base(FrontMapID),
            %% 在副本的时候，不能跳转世界boss场景
            ?IF(?IS_WORLD_BOSS_SUB_TYPE(SubType) andalso map_misc:is_copy(mod_role_data:get_role_map_id(State)), ?THROW_ERR(?ERROR_PRE_ENTER_029), ok),
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_1 -> %% 世界boss，检查次数
                    ?IF(mod_role_world_boss:check_first_boss(FrontMapID, State), ok, ?THROW_ERR(?ERROR_PRE_ENTER_002));
                true ->
                    ok
            end,
            ?IF(mod_role_vip:get_vip_level(State) >= VIPEnterLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL)),
            {MapID, ExtraID, ServerID, CampID, RecordPos2} = get_enter_args(State, FrontMapID, FrontExtraID, RecordPos),
            {BagDoings, AssetDoings, State2} = check_item_enter_times(ConfigMap, State),
            {ServerID, MapID, ExtraID, CampID, RecordPos2, BagDoings, AssetDoings, State2}
    end.

%%check_map_lock(MapID, MapLock) ->
%%    case MapLock of
%%        ?MAP_NO_LOCK ->
%%            ok;
%%        ?MAP_FAIRY_LOCK ->
%%            mod_role_fairy:check_map_lock(MapID);
%%        Other ->
%%            ?ERROR_MSG("-------------ERROR MAP LOCK1---------~w", [Other]),
%%            ok
%%    end.

%% 部分地图有进入地图限制
check_item_enter_times(Config, State) ->
    #c_map_base{
        sub_type = SubType,
        free_enter_times = FreeEnterTimes,
        vip_free_level = VipFreeLevel,
        use_gold = UseGold,
        use_item_string = UseItemString} = Config,
    #r_role{role_map = RoleMap} = State,
    #r_role_map{enter_list = EnterList} = RoleMap,
    case UseGold =< 0 andalso UseItemString =:= [] of
        true -> %% 不需要道具不需要元宝
            {[], [], State};
        _ ->
            {BagDoings, AssetDoings} =
            case (VipFreeLevel > 0 andalso mod_role_vip:get_vip_level(State) >= VipFreeLevel) orelse is_enter_free_times(SubType, EnterList, FreeEnterTimes) of
                true ->
                    {[], []};
                _ ->
                    TimesList = lib_tool:string_to_intlist(UseItemString, ";", ","),
                    AssetDoingsT = ?IF(UseGold > 0, mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, UseGold, ?ASSET_GOLD_REDUCE_FROM_ENTER_MAP, State), []),
                    MaxEnterTimes = mod_role_vip:get_vip_enter_times(SubType, State),
                    EnterTimes =
                        case MaxEnterTimes > 0 of
                            true ->
                                case lists:keyfind(SubType, #p_kv.id, EnterList) of
                                    #p_kv{val = Times} ->
                                        ?IF(Times < MaxEnterTimes, Times + 1, ?THROW_ERR(?ERROR_PRE_ENTER_009));
                                    _ ->
                                        1
                                end;
                            _ ->
                                0
                        end,
                    BagDoingsT =
                        case TimesList =/= [] of
                            true ->
                                {_Times, TypeID, Num} = lists:keyfind(EnterTimes , 1, TimesList),
                                mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_ENTER_MAP, State);
                            _ ->
                                []
                        end,
                    {BagDoingsT, AssetDoingsT}
            end,
            EnterList2 = get_new_enter_list(SubType, EnterList),
            RoleMap2 = RoleMap#r_role_map{enter_list = EnterList2},
            {BagDoings, AssetDoings, State#r_role{role_map = RoleMap2}}
    end.

is_enter_free_times(SubType, EnterList, FreeEnterTimes) ->
    case lists:keyfind(SubType, #p_kv.id, EnterList) of
        #p_kv{val = Times} ->
            Times < FreeEnterTimes;
        _ ->
            FreeEnterTimes > 0
    end.

get_new_enter_list(SubType, EnterList) ->
    case lists:keyfind(SubType, #p_kv.id, EnterList) of
        #p_kv{val = EnterTimes} = KV ->
            lists:keystore(SubType, #p_kv.id, EnterList, KV#p_kv{val = EnterTimes + 1});
        _ ->
            [#p_kv{id = SubType, val = 1}|EnterList]
    end.

%% 部分地图获取extra_id要到对应的管理进程获取
%% return : {MapID, ExtraID, ServerID, CampID, RecordPos}
get_enter_args(State, MapID, FrontExtraID, RecordPos) ->
    case get_enter_args2(State, MapID, FrontExtraID, RecordPos) of
        {ExtraID, CampID, RecordPos2} ->
            {MapID, ExtraID, common_config:get_server_id(), CampID, RecordPos2};
        {MapID2, ExtraID, CampID, RecordPos2} ->
            {MapID2, ExtraID, common_config:get_server_id(), CampID, RecordPos2};
        {MapID2, ExtraID, ServerID, CampID, RecordPos2} ->
            {MapID2, ExtraID, ServerID, CampID, RecordPos2}
    end.

%% 可返回 {ExtraID, CampID, RecordPos} or {MapID, ExtraID, CampID, RecordPos} or {MapID, ExtraID, ServerID, CampID, RecordPos}
get_enter_args2(State, MapID, FrontExtraID, RecordPos) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    if
        MapID =:= ?MAP_BATTLE ->    %% 战场地图
            #r_role_attr{max_power = MaxPower} = RoleAttr,
            mod_role_battle:check_role_pre_enter(RoleID, MapID, MaxPower);
        MapID =:= ?MAP_SOLO ->      %% 1v1地图
            mod_role_solo:check_role_pre_enter(RoleID, MapID);
        MapID =:= ?MAP_FAMILY_TD -> %% 守卫仙盟地图
            mod_role_family_td:check_role_pre_enter(State);
        MapID =:= ?MAP_FAMILY_AS -> %% 仙盟答题地图
            mod_role_family_as:check_role_pre_enter(State);
        MapID =:= ?MAP_FAMILY_BOSS ->    %% 仙盟Boss
            mod_role_fgb:check_role_pre_enter(State);
        MapID =:= ?MAP_ANSWER ->    %% 答题地图
            mod_role_answer:check_role_pre_enter(State,MapID);
        ?IS_MAP_SUMMIT_TOWER(MapID) -> %% 巅峰爬塔
            mod_role_summit_tower:check_role_pre_enter(RoleID, MapID);
        ?IS_MAP_FAMILY_BT(MapID) -> %% 帮会战
            mod_role_family_bt:check_role_pre_enter(State);
        ?IS_MAP_MARRY_FEAST(MapID) -> %% 婚礼场景
            mod_role_marry:check_enter_feast(RoleID),
            {map_branch_manager:get_map_cur_extra_id(MapID), ?DEFAULT_CAMP_ROLE, RecordPos};
        ?IS_MAP_DEMON_BOSS(MapID) -> %% 魔域Boss
            mod_role_demon_boss:check_enter_demon_boss(FrontExtraID, State),
            {FrontExtraID, ?DEFAULT_CAMP_ROLE, RecordPos};
        true ->
            case map_misc:is_cross_map(MapID) of
                true -> %% 暂时先这么处理，后续再优化
                    ServerID = global_data:get_cross_server_id(),
                    ExtraID = map_branch_manager:get_cross_extra_id(MapID),
                    {MapID, ExtraID, ServerID, ?DEFAULT_CAMP_ROLE, RecordPos};
                _ ->
                    ExtraID =
                        case FrontExtraID > 0 of
                            true -> %% 前端发起要切换分线
                                map_branch_manager:check_map_extra(MapID, FrontExtraID),
                                FrontExtraID;
                            _ ->
                                map_branch_manager:get_map_cur_extra_id(MapID)
                        end,
                    {ExtraID, ?DEFAULT_CAMP_ROLE, RecordPos}
            end
    end.

get_enter_state(State, PreEnter) ->
    #r_role{
        role_attr = RoleAttr,
        role_map = RoleMap,
        role_private_attr = PrivateAttr,
        role_fight = RoleFight} = State,
    #r_role_enter{
        server_id = NewServerID,
        camp_id = CampID,
        map_id = NewMapID,
        extra_id = ExtraID,
        map_pname = NewMapPName,
        record_pos = NewPos,
        old_hp = Hp,
        old_pos = NowPos
    } = PreEnter,
    #r_role_map{
        map_pname = NowMapPname,
        server_id = NowServerID,
        map_id = NowMapID,
        extra_id = NowExtraID} = RoleMap,
    RoleMap2 = RoleMap#r_role_map{
        hp = Hp,
        server_id = NewServerID,
        map_id = NewMapID,
        extra_id = ExtraID,
        map_pname = NewMapPName,
        camp_id = CampID},
    {RoleMap3, PrivateAttr2} = modify_role_dead(RoleAttr, RoleMap2, PrivateAttr, RoleFight),
    IsCopyFront = (NowMapID =:= NewMapID orelse map_misc:is_copy_front(NowMapID) orelse map_misc:is_copy_front(NewMapID))
        andalso map_misc:is_same_map_data(NowMapID, NewMapID),
    if
        IsCopyFront -> %% 流程树副本处理 && 分线切换处理
            NewPos2 = NowPos;
        true ->
            case erlang:is_record(NewPos, r_pos) of
                true ->
                    NewPos2 = NewPos;
                _ ->
                    {ok, NewPos2} = map_misc:get_born_pos(NewMapID)
            end
    end,
    RoleMap4 =
        case map_misc:is_copy(NowMapID) orelse map_misc:is_condition_map(NowMapID) of
            true -> %% 如果当前地图是副本地图或者是世界boss耗时或者是一些特殊开启的地图，则不记录进旧地图信息里
                RoleMap3#r_role_map{pos = NewPos2};
            _ ->
                RoleMap3#r_role_map{
                    camp_id = CampID,
                    pos = NewPos2,
                    old_server_id = NowServerID,
                    old_map_id = NowMapID,
                    old_extra_id = NowExtraID,
                    old_map_pname = NowMapPname,
                    old_pos = NowPos}
        end,
    mod_role_dict:set_pre_enter(PreEnter#r_role_enter{record_pos = NewPos2}),
    State#r_role{role_map = RoleMap4, role_private_attr = PrivateAttr2}.

%% 玩家正式进入地图
do_enter_map(RoleID, State) ->
    ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_ENTER, mod_role_data:get_role_map_id(State), State)),
    case catch check_can_enter() of
        ok ->
            do_enter_map2(RoleID, false, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_enter_map_toc{err_code = ErrCode}),
            State
    end.

do_enter_map2(RoleID, IsFirstEnter, State) ->
    {MapInfo, FightAttr, MapPName} = make_map_info(State),
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{is_guide = IsGuide} = RoleWorldBoss,
    {CaveTimes, CaveAssistTimes, MythicalTimes, MythicalCollect, MythicalCollect2} = mod_role_world_boss:get_map_args(State),
    MapRole = #r_map_role{
        role_id = RoleID,
        role_pid = erlang:self(),
        is_guide = IsGuide,
        gateway_pid = mod_role_dict:get_gateway_pid(),
        cave_times = CaveTimes,
        cave_assist_times = CaveAssistTimes,
        mythical_times = MythicalTimes,
        mythical_collect = MythicalCollect,
        mythical_collect2 = MythicalCollect2,
        missions = mod_role_mission:get_mission_ids(State),
        special_drops = mod_role_extra:get_data(?EXTRA_KEY_SPECIAL_DROP_LIST, [], State),
        item_drops = mod_role_extra:get_data(?EXTRA_KEY_ITEM_DROP_LIST, [], State)
    },
    case catch mod_map_role:role_enter_map(MapPName, MapInfo, FightAttr, MapRole) of
        {ok, #r_map_enter{} = MapEnter} ->
            set_map_enter(MapEnter),
            do_notice_dead(State),
            ?TRY_CATCH(log_map_enter(?ACTION_ENTER, mod_role_data:get_role_map_id(State), State)),
            hook_role:role_enter_map(IsFirstEnter, State);
        {error, pos_error} ->
            #r_role{role_map = RoleMap} = State,
            {ok, BornPos} = map_misc:get_born_pos(RoleMap#r_role_map.map_id),
            RoleMap2 = RoleMap#r_role_map{pos = BornPos},
            common_misc:unicast(RoleID, #m_enter_map_toc{err_code = ?ERROR_COMMON_SYSTEM_ERROR}),
            role_login:notify_exit(?ERROR_SYSTEM_ERROR_016),
            State#r_role{role_map = RoleMap2};
        {error, map_process_not_found} ->
            #r_role{role_map = RoleMap} = State,
            {ok, BornPos} = map_misc:get_born_pos(RoleMap#r_role_map.map_id),
            RoleMap2 = RoleMap#r_role_map{pos = BornPos},
            common_misc:unicast(RoleID, #m_enter_map_toc{err_code = ?ERROR_COMMON_SYSTEM_ERROR}),
            role_login:notify_exit(?ERROR_SYSTEM_ERROR_016),
            State#r_role{role_map = RoleMap2};
        {error, ErrCode} when erlang:is_integer(ErrCode) ->
            common_misc:unicast(RoleID, #m_enter_map_toc{err_code = ErrCode}),
            State;
        Error ->
            ?ERROR_MSG("Error:~w", [Error]),
            common_misc:unicast(RoleID, #m_enter_map_toc{err_code = ?ERROR_COMMON_SYSTEM_ERROR}),
            State
    end.

%% 从副本地图退出时，有可能会要求返回到特定地图
check_can_enter() ->
    case mod_role_dict:erase_pre_enter() of
        #r_role_enter{} ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_ENTER_MAP_001)
    end,
    ok.

make_map_info(State) ->
    #r_role{
        role_id = RoleID,
        role_attr = RoleAttr,
        role_private_attr = PrivateAttr,
        role_fight = #r_role_fight{fight_attr = FightAttr},
        role_map = RoleMap,
        role_buff = RoleBuff,
        role_confine = RoleConfine,
        role_relive = RoleRelive,
        role_marry = RoleMarry,
        role_title = #r_role_title{cur_title = CurTitle}} = State,
    #r_role_attr{sex = Sex, category = Category, level = Level, power = Power, skin_list = SkinList, team_id = TeamID, ornament_list = OrnamentList} = RoleAttr,
    #r_role_map{hp = Hp, pos = Pos, map_pname = MapPName, server_id = ServerID, camp_id = CampID, pk_mode = PKMode, pk_value = PKValue} = RoleMap,
    #r_role_attr{role_name = RoleName, family_id = FamilyID, family_name = FamilyName} = RoleAttr,
    #r_role_private_attr{status = Status} = PrivateAttr,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    Confine = ?IF(RoleConfine =:= undefined, 0, RoleConfine#r_role_confine.confine),
    #r_role_relive{relive_level = ReliveLevel} = RoleRelive,
    #r_role_marry{couple_id = CoupleID, couple_name = CoupleName} = RoleMarry,
    AllBuffs = Buffs ++ Debuffs,
    AllBuffsID = [BuffID || #r_buff{buff_id = BuffID} <- AllBuffs],
    #actor_fight_attr{move_speed = MoveSpeed, max_hp = MaxHp} = FightAttr,
    ServerName = ?IF(common_config:is_cross_server_id(ServerID), common_config:get_server_name(), ""),
    MapRole = #p_map_role{
        sex = Sex,
        category = Category,
        level = Level,
        pk_value = PKValue,
        family_id = FamilyID,
        family_name = FamilyName,
        couple_id = CoupleID,
        couple_name = CoupleName,
        skin_list = SkinList,
        power = Power,
        confine = Confine,
        title = CurTitle,
        family_title = mod_role_family:get_family_title_id(RoleID),
        team_id = TeamID,
        server_id = common_config:get_server_id(),
        server_name = ServerName,
        relive_level = ReliveLevel,
        ornament_list = OrnamentList
    },
    MapInfo = #r_map_actor{
        actor_id = RoleID,
        actor_type = ?ACTOR_TYPE_ROLE,
        hp = ?IF(Hp >= MaxHp, MaxHp, Hp),
        max_hp = MaxHp,
        camp_id = CampID,
        actor_name = RoleName,
        status = Status,
        pos = map_misc:pos_encode(Pos),
        buffs = AllBuffsID,
        pk_mode = PKMode,
        buff_status = common_buff:recal_status(AllBuffs),
        prop_effects = mod_role_skill:get_map_prop_effects(State),
        fight_effects = mod_role_skill_seal:get_fight_effect(State),
        target_pos = 0,
        move_speed = MoveSpeed,
        role_extra = MapRole},
    {MapInfo, FightAttr, MapPName}.

%% 准备退出当前地图
do_quit_map(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    #r_role_map{map_id = MapID, old_map_id = OldMapID, old_pos = OldPos} = RoleMap,
    case map_misc:is_copy(MapID) of
        true -> %% 副本地图
            case mod_role_copy:get_copy_quit_info(MapID) of
                {NewMapID, NewPos} ->
                    ok;
                _ ->
                    NewMapID = OldMapID,
                    NewPos = OldPos
            end;
        _ ->
            NewMapID = OldMapID,
            NewPos = OldPos
    end,
    ?IF(NewMapID > 0, do_pre_enter(RoleID, NewMapID, State, NewPos), State).

do_change_pos(RoleID, State, DestMapID, DestPos, JumpID, DestJumpID) ->
    case catch check_can_change(RoleID, State, DestMapID, DestPos, JumpID, DestJumpID) of
        {ok, same_map_change, BagDoings, RecordPos, MoveType} ->
            State2 = mod_role_bag:do(BagDoings, State),
            mod_map_role:role_change_pos(mod_role_dict:get_map_pid(), RoleID, RecordPos, DestPos, MoveType, JumpID),
            State2;
        {ok, diff_map_change, BagDoings, RecordPos} ->
            State2 = mod_role_bag:do(BagDoings, State),
            ?TRY_CATCH(log_map_enter(?ACTION_REQUEST_MAP_CHANGE, DestMapID, State2)),
            do_pre_enter(RoleID, DestMapID, State2, RecordPos);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_map_change_pos_toc{err_code = ErrCode}),
            State
    end.

check_can_change(RoleID, State, DestMapID, DestPos, JumpID, DestJumpID) ->
    #r_role{role_map = RoleMap} = State,
    #r_role_map{map_id = MapID} = RoleMap,
    {BagDoings, MoveType, RecordPos} =
    case map_base_data:get_jump_point(MapID, JumpID) of
        #c_jump_point{mx = Mx, my = My} ->
            {ok, #r_map_actor{pos = Pos}} = mod_map_role:role_get_mapinfo(mod_role_dict:get_map_pid(), RoleID),
            #r_pos{mx = NowMs, my = NowMy} = map_misc:pos_decode(Pos),
            ?IF(map_misc:get_dis(Mx, My, NowMs, NowMy) < 800, ok, ?THROW_ERR(?ERROR_MAP_CHANGE_POS_001)),
            DestPos2 =
            case (MapID =/= DestMapID andalso DestMapID =/= 0) andalso DestJumpID =/= 0 of
                true -> %% 跨地图跳转
                    #c_jump_point{mx = DestMx, my = DestMy} = map_base_data:get_jump_point(DestMapID, DestJumpID),
                    map_misc:get_pos_by_meter(DestMx, DestMy);
                _ ->
                    map_misc:pos_decode(DestPos)
            end,
            {[], ?ACTOR_MOVE_JUMP, DestPos2};
        _ ->
            Doings = ?IF(map_misc:is_copy_front(MapID) orelse mod_role_vip:is_transfer_free(State),
                         [],
                         mod_role_bag:check_num_by_type_id(?TRANSFER_ITEM, 1, ?ITEM_REDUCE_MAP_TRANSFER, State)),
            {Doings, ?ACTOR_MOVE_NORMAL, map_misc:pos_decode(DestPos)}
    end,
    case MapID =:= DestMapID orelse DestMapID =:= 0 of
        true ->
            #r_pos{tx = Tx, ty = Ty} = RecordPos,
            ?IF(map_base_data:is_exist(MapID, Tx, Ty), ok, ?THROW_ERR(?ERROR_MAP_CHANGE_POS_001)),
            {ok, same_map_change, BagDoings, RecordPos, MoveType};
        _ ->
            #r_pos{tx = Tx, ty = Ty} = RecordPos,
            ?IF(map_base_data:is_exist(DestMapID, Tx, Ty), ok, ?THROW_ERR(?ERROR_MAP_CHANGE_POS_001)),
            {ok, diff_map_change, BagDoings, RecordPos}
    end.

%% 获取分线信息
do_map_line(RoleID, MapID, State) ->
    #r_role{role_map = #r_role_map{extra_id = CurExtraID}} = State,
    ExtraIDList = map_branch_manager:get_map_all_extra_id(MapID),
    DataRecord = #m_map_line_info_toc{extra_id_list = ExtraIDList, cur_extra_id = CurExtraID},
    common_misc:unicast(RoleID, DataRecord),
    State.

%% 组队副本开启
do_copy_team_start(MapID, TeamID, State) ->
    #r_role{role_id = RoleID} = State,
    case catch check_copy_team(MapID, TeamID, State) of
        {ok, PreEnter, BagDoings, State2} ->
            do_pre_enter2(PreEnter, [], BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pre_enter_toc{err_code = ErrCode}),
            State
    end.

check_copy_team(MapID, TeamID, State) ->
    {State2, _RoleID, BagDoings, _MapParams} = mod_role_copy:check_copy_enter(MapID, State),
    ServerID = common_config:get_server_id(),
    MapPName = map_misc:get_map_pname(MapID, TeamID, ServerID),
    RecordPos = ?IF(copy_misc:is_copy_marry(MapID), mod_role_marry:get_born_pos(MapID, State2), undefined),
    MapEnter = #r_role_enter{
        server_id = ServerID,
        map_id = MapID,
        extra_id = TeamID,
        map_pname = MapPName,
        record_pos = RecordPos
    },
    {ok, MapEnter, BagDoings, State2}.

%% 角色扣血
do_role_reduce_hp(_SrcID, SrcActorType, _ReduceHp, RemainHp, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_fight = RoleFight} = State,
    RoleMap2 = RoleMap#r_role_map{hp = RemainHp},
    #actor_fight_attr{max_hp = MaxHp} = RoleFight#r_role_fight.fight_attr,
    IsAddBuff = mod_role_data:get_role_level(State) =< ?FRESH_LEVEL andalso (?RATE_10000 * RemainHp / MaxHp =< ?FRESH_REMAIN_HP),
    ?IF(IsAddBuff, role_misc:add_buff(RoleID, [#buff_args{buff_id = 108001, from_actor_id = RoleID, extra_value = MaxHp}]), ok),
    mod_role_skill:role_be_attacked(SrcActorType),
    State2 = mod_role_fight:role_be_attacked(State#r_role{role_map = RoleMap2}),
    State3 = mod_role_skill:do_attack_result(?ATTACK_RESULT_ATTACK, State2),
    State4 = ?IF(SrcActorType =:= ?ACTOR_TYPE_ROLE, mod_role_skill:do_attack_result(?ATTACK_RESULT_ATTACK_FROM_ROLE, State3), State3),
    mod_role_skill:hp_change_buffs(State, State4).

%% 角色加血
do_role_add_hp(RemainHp, State) ->
    #r_role{role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{hp = RemainHp},
    State2 = State#r_role{role_map = RoleMap2},
    mod_role_skill:hp_change_buffs(State, State2).

do_role_hp_change(RemainHp, State) ->
    #r_role{role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{hp = RemainHp},
    State#r_role{role_map = RoleMap2}.

%% 角色死亡
do_role_dead(State, NowPos, SrcID, SrcType, SrcName) ->
    Now = time_tool:now(),
    #r_role{role_id = RoleID, role_map = RoleMap, role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{status = OldStatus} = PrivateAttr,
    case OldStatus =:= ?MAP_STATUS_DEAD of
        true -> %% 已经死亡，不重复触发
            State;
        _ ->
            PrivateAttr2 = PrivateAttr#r_role_private_attr{status = ?MAP_STATUS_DEAD},
            RoleMap2 = RoleMap#r_role_map{dead_time = Now},
            {ReliveArgs, _RoleMap} = get_relive_args(RoleMap2),
            #r_relive_args{
                normal_relive_time = NormalReliveTime,
                normal_relive_times = NormalReliveTimes,
                fee_relive_time = _FeeReliveTime,
                fee_relive_times = _FeeReliveTimes,
                fee = _ReliveFee
            } = ReliveArgs,
            DataRecord = #m_role_dead_toc{
                src_id = SrcID,
                src_name = SrcName,
                normal_relive_time = NormalReliveTime,
                normal_times = NormalReliveTimes},
            common_misc:unicast(RoleID, DataRecord),
            mod_map_role:role_dead_ack(RoleMap2#r_role_map.map_pname, RoleID, SrcID, SrcType),
            State2 = State#r_role{role_private_attr = PrivateAttr2, role_map = RoleMap2},
            ?TRY_CATCH(mod_role_world_boss:role_dead_notice(NowPos, SrcName, State2)),
            hook_role:role_dead(State2)
    end.

do_notice_dead(State) ->
    #r_role{role_id = RoleID, role_private_attr = #r_role_private_attr{status = Status}, role_map = RoleMap} = State,
    case Status =:= ?MAP_STATUS_DEAD of
        true ->
            {ReliveArgs, _RoleMap} = get_relive_args(RoleMap),
            #r_relive_args{
                normal_relive_time = NormalReliveTime,
                normal_relive_times = NormalReliveTimes,
                fee_relive_time = _FeeReliveTime,
                fee_relive_times = _FeeReliveTimes,
                fee = _ReliveFee
            } = ReliveArgs,
            DataRecord = #m_role_dead_toc{
                normal_relive_time = NormalReliveTime,
                normal_times = NormalReliveTimes},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.

get_relive_args(RoleMap) ->
    #r_role_map{map_id = MapID} = RoleMap,
    case copy_misc:is_copy_relive(MapID) of
        true ->
            get_copy_relive_args(RoleMap);
        _ ->
            get_other_relive_args(RoleMap)
    end.

%% 副本地图
get_copy_relive_args(RoleMap) ->
    MapPID = mod_role_dict:get_map_pid(),
    #r_role_map{map_id = MapID, dead_time = DeadTime, relive_list = ReliveList} = RoleMap,
    CopyType = copy_misc:get_copy_type(MapID),
    Now = time_tool:now(),
    case lists:keyfind(CopyType, #r_map_relive.map_id, ReliveList) of
        #r_map_relive{map_pid = MapPID} = ReLive -> %% 之前复活过了呀
            ReLive;
        _ ->
            ReLive = #r_map_relive{map_id = CopyType, map_pid = MapPID, relive_times = 0, time = 0}
    end,
    #r_map_relive{relive_times = ReliveTimes} = ReLive,
    case lib_config:find(cfg_copy_relive, {CopyType, ReliveTimes + 1}) of
        [Config] ->
            ReliveTimes2 = ReliveTimes + 1,
            Config;
        _ ->
            ReliveTimes2 = ReliveTimes,
            [Config] = lib_config:find(cfg_copy_relive, {CopyType, ReliveTimes})
    end,
    #c_copy_relive{
        is_normal_relive = IsNormal,
        relive_fee_cd = ReliveCD,
        relive_fee = ReliveFee} = Config,
    ReLive2 = ReLive#r_map_relive{relive_times = ReliveTimes2},
    ReliveList2 = lists:keystore(CopyType, #r_map_relive.map_id, ReliveList, ReLive2),
    FeeReliveTime = DeadTime + ReliveCD,
    NormalReliveTime = ?IF(?IS_NORMAL_RELIVE(IsNormal), Now, 0),
    ReliveArgs =
    #r_relive_args{
        normal_relive_time = NormalReliveTime,
        normal_relive_times = 0,
        fee_relive_time = FeeReliveTime,
        fee_relive_times = ReliveTimes,
        fee = ReliveFee
    },
    RoleMap2 = RoleMap#r_role_map{relive_list = ReliveList2},
    {ReliveArgs, RoleMap2}.

%% 野外地图
get_other_relive_args(RoleMap) ->
    #r_role_map{map_id = MapID} = RoleMap,
    [#c_map_base{is_normal_relive = IsNormal, is_fee_relive = IsFeeRelive, relive_gold = Gold} = Config] = lib_config:find(cfg_map_base, MapID),
    Now = time_tool:now(),
    {NormalReliveTime, NormalReliveTimes, RoleMap2} =
    case ?IS_NORMAL_RELIVE(IsNormal) of
        true ->
            get_normal_relive_args(RoleMap, Now, Config);
        _ ->
            {0, 0, RoleMap}
    end,
    FeeReliveTime = ?IF(?IS_FEE_RELIVE(IsFeeRelive), Now, 0),
    ReliveArgs =
    #r_relive_args{
        normal_relive_time = NormalReliveTime,
        normal_relive_times = NormalReliveTimes,
        fee_relive_time = FeeReliveTime,
        fee_relive_times = 0,
        fee = Gold
    },
    {ReliveArgs, RoleMap2}.

get_normal_relive_args(RoleMap, Now, Config) ->
    #r_role_map{map_id = MapID, dead_time = DeadTime, relive_list = ReliveList} = RoleMap,
    #c_map_base{
        normal_times = NormalTimes,
        normal_cd = NormalCD,
        times_cd = TimesCD} = Config,
    case NormalTimes > 0 of
        true ->
            case lists:keyfind(MapID, #r_map_relive.map_id, ReliveList) of
                #r_map_relive{relive_times = ReliveTimes, time = FirstTime} = Relive ->
                    case Now >= FirstTime + TimesCD of
                        true -> %% 冷却到了
                            Relive2 = Relive#r_map_relive{relive_times = 1, time = Now},
                            ReliveList2 = lists:keystore(MapID, #r_map_relive.map_id, ReliveList, Relive2),
                            RoleMap2 = RoleMap#r_role_map{relive_list = ReliveList2},
                            {DeadTime, 0, RoleMap2};
                        _ -> %% 复活CD还没到，校验次数
                            case ReliveTimes >= NormalTimes of
                                true ->
                                    {DeadTime + NormalCD, ReliveTimes, RoleMap};
                                _ ->
                                    ReliveTimes2 = ReliveTimes + 1,
                                    Relive2 = Relive#r_map_relive{relive_times = ReliveTimes2},
                                    ReliveList2 = lists:keystore(MapID, #r_map_relive.map_id, ReliveList, Relive2),
                                    RoleMap2 = RoleMap#r_role_map{relive_list = ReliveList2},
                                    {DeadTime, 0, RoleMap2}
                            end
                    end;
                _ ->  %% 第一次复活
                    Relive2 = #r_map_relive{map_id = MapID, relive_times = 1, time = Now},
                    ReliveList2 = lists:keystore(MapID, #r_map_relive.map_id, ReliveList, Relive2),
                    RoleMap2 = RoleMap#r_role_map{relive_list = ReliveList2},
                    {DeadTime, 0, RoleMap2}
            end;
        _ -> %% 必须等N秒才能复活
            {DeadTime + NormalCD, 0, RoleMap}
    end.

do_role_relive(RoleID, OpType, State) ->
    case catch check_can_relive(OpType, State) of
        {ok, AssetDoing, State2} ->
            State3 = ?IF(AssetDoing =/= [], mod_role_asset:do(AssetDoing, State2), State2),
            mod_map_role:role_relive(mod_role_dict:get_map_pid(), RoleID, OpType),
            common_misc:unicast(RoleID, #m_role_relive_toc{op_type = OpType}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_relive_toc{err_code = ErrCode}),
            State
    end.

check_can_relive(ReliveType, State) ->
    #r_role{role_map = RoleMap, role_private_attr = PrivateAttr} = State,
    ?IF(PrivateAttr#r_role_private_attr.status =:= ?MAP_STATUS_DEAD, ok, ?THROW_ERR(?ERROR_ROLE_RELIVE_001)),
    Now = time_tool:now(),
    PrivateAttr2 = PrivateAttr#r_role_private_attr{status = ?MAP_STATUS_NORMAL},
    {ReliveArgs, RoleMap2} = get_relive_args(RoleMap),
    #r_relive_args{
        normal_relive_time = NormalReliveTime,
        fee_relive_time = FeeReliveTime,
        fee = Gold
    } = ReliveArgs,
    if
        ReliveType =:= ?RELIVE_TYPE_FEE ->
            ?IF(Now >= FeeReliveTime andalso FeeReliveTime =/= 0, ok, ?THROW_ERR(?ERROR_ROLE_RELIVE_003)),
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, Gold, ?ASSET_GOLD_REDUCE_FROM_MAP_RELIVE, State),
            RoleMap3 = RoleMap;
        true ->
            ?IF(Now >= NormalReliveTime - 2 andalso NormalReliveTime =/= 0, ok, ?THROW_ERR(?ERROR_ROLE_RELIVE_003)),
            AssetDoing = [],
            RoleMap3 = RoleMap2
    end,
    State2 = State#r_role{role_map = RoleMap3, role_private_attr = PrivateAttr2},
    {ok, AssetDoing, State2}.

modify_role_dead(RoleAttr, RoleMap, PrivateAttr, RoleFight) ->
    #r_role_attr{sex = Sex} = RoleAttr,
    #r_role_map{hp = Hp, map_id = MapID, camp_id = CampID} = RoleMap,
    #r_role_private_attr{status = Status} = PrivateAttr,
    case (Hp =< 0 orelse Status =:= ?MAP_STATUS_DEAD) andalso not (map_misc:is_world_boss_map(MapID) orelse ?IS_MAP_DEMON_BOSS(MapID)) of
        true -> %% 世界boss、魔域副本，不修正死亡状态
            {ok, BornPos} = map_misc:get_born_pos(#r_born_args{map_id = MapID, camp_id = CampID, sex = Sex}),
            RoleMap2 = RoleMap#r_role_map{pos = BornPos, hp = RoleFight#r_role_fight.fight_attr#actor_fight_attr.max_hp},
            PrivateAttr2 = PrivateAttr#r_role_private_attr{status = ?MAP_STATUS_NORMAL},
            {RoleMap2, PrivateAttr2};
        _ ->
            {RoleMap, PrivateAttr}
    end.

add_map_lock(#r_role{role_map = RoleMap} = State, Lock) ->
    NewRoleMap = RoleMap#r_role_map{lock = Lock},
    State#r_role{role_map = NewRoleMap}.

remove_map_lock(#r_role{role_map = RoleMap} = State) ->
    NewRoleMap = RoleMap#r_role_map{lock = ?MAP_NO_LOCK},
    State#r_role{role_map = NewRoleMap}.

log_map_enter(ActionType, MapID, State) ->
    #r_role{
        role_id = RoleID,
        role_attr = #r_role_attr{level = Level}} = State,
    Log = #log_map_enter{
        role_id = RoleID,
        role_level = Level,
        map_id = MapID,
        action_type = ActionType
    },
    mod_role_dict:add_background_logs(Log).

gm_clear_enter_list(State) ->
    #r_role{role_map = RoleMap} = State,
    RoleMap2 = RoleMap#r_role_map{enter_list = []},
    State2 = State#r_role{role_map = RoleMap2},
    online(State2).

%%%===================================================================
%%% set
%%%===================================================================
set_map_enter(MapEnter) ->
    mod_role_dict:set_map_pid(MapEnter#r_map_enter.map_pid).