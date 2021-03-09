%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     陷阱、弹道类运行模块
%%% @end
%%% Created : 06. 六月 2017 17:54
%%%-------------------------------------------------------------------
-module(mod_trap).
-author("laijichang").
-include("trap.hrl").

%% API
-export([
    init_trap/1,
    loop_ms/1
]).

init_trap(TrapArgs) ->
    #trap_args{
        type_id = TypeID,
        pos = BornPos,
        owner_id = OwnerID,
        owner_type = OwnerType,
        owner_level = OwnerLevel,
        fight_attr = FightAttr,
        pk_mode = PKMode,
        camp_id = CampID
    } = TrapArgs,
    [Config] = lib_config:find(cfg_trap, TypeID),
    #c_trap{
        trap_name = TrapName,
        length = Length,
        time = Time,
        skill_id = SkillID
    } = Config,
    [#c_skill{attack_type = AttackType, range_args = AttackRange}] = lib_config:find(cfg_skill, SkillID),
    MoveSpeed = lib_tool:floor(Length * 1000/Time),
    NewID = mod_trap_data:get_new_trap_id(),
    NowCounter = mod_trap_data:get_loop_counter(),
    if
        AttackType =:= ?SKILL_SELF_ROUND ->
            [AttackRange2|_] = AttackRange;
        true ->
            AttackRange2 = 0
    end,
    {TargetPos, PathList, TileList} = init_trap2(BornPos, Length, Time, AttackRange2),
    TrapData = #r_trap{
        trap_id = NewID,
        trap_name = TrapName,
        type_id = TypeID,
        skill_id = SkillID,
        owner_id = OwnerID,
        owner_type = OwnerType,
        owner_level = OwnerLevel,
        fight_attr = FightAttr,
        state = ?TRAP_STATE_BORN,
        end_counter = NowCounter + ?GET_COUNTER_BY_MS(Time),
        move_speed = MoveSpeed,
        pos = BornPos,
        target_pos = TargetPos,
        attack_type = AttackType,
        attack_range = AttackRange2,
        pk_mode = PKMode,
        camp_id = CampID,
        path_list = PathList,
        tile_list = TileList},
    mod_trap_data:set_trap_data(NewID, TrapData),
    mod_trap_data:add_counter_trap(NewID, NowCounter + ?TRAP_BORN_COUNTER).

init_trap2(BornPos, Length, Time, AttackRange) ->
    #r_pos{mx = Mx, my = My, mdir = MDir} = BornPos,
    RDir = MDir * math:pi()/180,
    AddX = lib_tool:ceil(Length * math:sin(RDir)),
    AddY = lib_tool:ceil(Length * math:cos(RDir)),
    TargetMx = Mx + AddX,
    TargetMy = My + AddY,
    TargetPos = #r_pos{mx = TargetMx, my = TargetMy, mdir = MDir,
        tx = ?M2T(TargetMx), ty = ?M2T(TargetMy), dir = map_misc:dir_m2t(MDir)},

    FinalPath = [{Mx + AddX, My + AddY, MDir}],
    FinalTileList = get_tile_list(TargetMx - AttackRange, TargetMx + AttackRange, TargetMy - AttackRange, TargetMy + AttackRange),
    case Time > ?TRAP_WORK_TIME andalso Length > 0 of %% 弹道 > 300毫秒
        true ->
            EveryX = lib_tool:ceil(AddX * ?TRAP_WORK_TIME / Time),
            EveryY = lib_tool:ceil(AddY * ?TRAP_WORK_TIME / Time),
            NumX = lib_tool:ceil(AddX/EveryX),
            NumY = lib_tool:ceil(AddY/EveryY),
            Num = erlang:max(NumX, NumY),
            {PathList, TileList} =
                lists:foldl(
                    fun(Multi, {Acc1, Acc2}) ->
                        DestMx = Mx + EveryX * Multi,
                        DestMy = My  + EveryY * Multi,
                        NewAcc1 = [{Mx + EveryX * Multi, My + EveryY * Multi, MDir}|Acc1],
                        TileAcc = get_tile_list(DestMx - AttackRange, DestMx + AttackRange, DestMy - AttackRange, DestMy + AttackRange),
                        NewAcc2 = [TileAcc|Acc2],
                        {NewAcc1, NewAcc2}
                    end, {[] , []}, lists:seq(1, Num - 1)),
            PathList2 = lists:reverse(FinalPath ++ PathList),
            TileList2 = lists:reverse([FinalTileList|TileList]);
        _ ->
            PathList2 = FinalPath,
            TileList2 = [FinalTileList]
    end,
    {TargetPos, PathList2, TileList2}.

loop_ms(NowMs) ->
    Counter = mod_trap_data:get_loop_counter(),
    TrapList = mod_trap_data:get_counter_traps(Counter),
    [ trap_work(TrapID, NowMs, Counter) || TrapID <- TrapList],
    mod_trap_data:erase_counter_traps(Counter),
    mod_trap_data:set_loop_counter(Counter + 1),
    ok.

trap_work(TrapID, NowMs, Counter) ->
    case mod_trap_data:get_trap_data(TrapID) of
        #r_trap{} = TrapData ->
            trap_work2(TrapData, NowMs, Counter);
        _ ->
            ignore
    end.

trap_work2(TrapData, NowMs, Counter) ->
    #r_trap{trap_id = TrapID, state = State, end_counter = EndCounter} = TrapData,
    case Counter > EndCounter of
        true -> %% 结束
            mod_trap_map:trap_leave(TrapID),
            mod_trap_data:del_trap_data(TrapID);
        _ ->
            case State of
                ?TRAP_STATE_BORN ->
                    mod_trap_map:trap_born(TrapData);
                ?TRAP_STATE_WORK ->
                    case ?TRY_CATCH(trap_work3(TrapData, NowMs)) of
                        {ok, AddCounter} ->
                            mod_trap_data:add_counter_trap(TrapID, Counter + AddCounter);
                        Error ->
                            ?ERROR_MSG("trap Error:~w", [Error]),
                            mod_trap_data:add_counter_trap(TrapID, Counter + ?BLAME_COUNTER)
                    end
            end
    end.

%% 每200ms移动位置
%% 每200ms触发伤害
trap_work3(TrapData, NowMs) ->
    #r_trap{
        trap_id = TrapID,
        skill_id = SkillID,
        can_attack_time = CanAttackTime,
        last_attack_time = LastAttackTime,
        fight_args = FightArgs,
        attack_type = AttackType,
        attack_range = AttackRange,
        move_speed = MoveSpeed,
        owner_id = OwnerID,
        path_list = PathList,
        tile_list = TileList
    } = TrapData,
    case MoveSpeed > 0 of
        true -> %% 移动的陷阱
            [{Mx, My, MDir}|RemainPath] = PathList,
            [CurTileList|RemainTile] = TileList,
            RecordPos = map_misc:get_pos_by_meter(Mx, My, MDir),
            IntPos = map_misc:pos_encode(RecordPos),
            mod_map_trap:trap_move(TrapID, RecordPos, IntPos);
        _ -> %% 静止的陷阱
            [{Mx, My, MDir}] = RemainPath = PathList,
            RecordPos = map_misc:get_pos_by_meter(Mx, My, MDir),
            RemainTile = TileList,
            [CurTileList] = TileList
    end,
    TrapData2 = TrapData#r_trap{path_list = RemainPath, tile_list = RemainTile},
    case NowMs >= CanAttackTime of
        true ->
            FightArgs2 = common_skill:get_skill_action_list(SkillID),
            #c_skill{cd = Cd} = common_skill:get_skill_config(SkillID),
            CanAttackTime2 = NowMs + Cd,
            TrapData3 = TrapData2#r_trap{fight_args = FightArgs2, can_attack_time = CanAttackTime2};
        _ ->
            case common_skill:get_next_skill(FightArgs) of
                {next_hurt, Action, #r_skill_hurt{delay = Delay} = Hurt, Remain} when NowMs >= LastAttackTime + Delay ->
                    trap_hurt(TrapData, OwnerID, RecordPos, {Action, Hurt}, AttackType, AttackRange, CurTileList),
                    TrapData3 = TrapData2#r_trap{fight_args = Remain, last_attack_time = NowMs};
                {next_prepare, NextAction, Remain} ->
                    #r_skill_action{skill_id = SkillID, step_id = StepID} = NextAction,
                    mod_map_trap:trap_fight_prepare(TrapID, 0, SkillID, StepID, map_misc:pos_encode(RecordPos)),
                    TrapData3 = TrapData2#r_trap{fight_args = Remain, last_attack_time = NowMs};
                _ ->
                    TrapData3 = TrapData2
            end
    end,
    mod_trap_data:set_trap_data(TrapID, TrapData3),
    {ok, ?TRAP_WORK_COUNTER}.

trap_hurt(TrapData, OwnerID, RecordPos, Fight, ?SKILL_SELF_ROUND, AttackRange, CurTileList) ->
    #r_pos{mx = Mx, my = My} = RecordPos,
    MinMx = Mx - AttackRange,
    MaxMx = Mx + AttackRange,
    MinMy = My - AttackRange,
    MaxMy = My + AttackRange,
    AttackList =
        lists:foldl(
            fun({Tx, Ty}, Acc) ->
                ActorList = mod_map_ets:get_tile_actors(Tx, Ty),
                get_hurt_list(TrapData, MinMx, MaxMx, MinMy, MaxMy, ActorList, []) ++ Acc
            end, [], CurTileList),
    trap_hurt2(TrapData, RecordPos, Fight, lists:delete(OwnerID, AttackList));
trap_hurt(_TrapData, _OwnerID, _RecordPos, _Fight, _AttackType, _AttackRange, _CurTileList) ->
    ok.

trap_hurt2(TrapData, RecordPos, Fight, AttackList) ->
    #r_trap{trap_id = TrapID} = TrapData,
    {#r_skill_action{skill_id = SkillID}, #r_skill_hurt{self_effect = SelfEffects, enemy_effect = EnemyEffects}} = Fight,
    IntPos = map_misc:pos_encode(RecordPos),
    mod_map_trap:trap_fight(
        #fight_args{
            dest_id_list = AttackList,
            skill_id = SkillID,
            enemy_effect_list = EnemyEffects,
            self_effect_list = SelfEffects,
            skill_pos = IntPos,
            src_id = TrapID,
            src_type = ?ACTOR_TYPE_TRAP}),
    ok.

get_hurt_list(_TrapData, _MinMx, _MaxMx, _MinMy, _MaxMy, [], ActorAcc) ->
    ActorAcc;
get_hurt_list(TrapData, MinMx, MaxMx, MinMy, MaxMy, [{ActorType, ActorID}|R], ActorAcc) ->
    case lists:member(ActorType, ?ATTACK_LIST) of
        true ->
            #r_map_actor{status = Status, pos = IntPos} = MapInfo = mod_map_ets:get_actor_mapinfo(ActorID),
            #r_pos{mx = DestMx, my = DestMy} = map_misc:pos_decode(IntPos),
            case Status =/= ?MAP_STATUS_DEAD
                andalso MinMx =< DestMx andalso DestMx =< MaxMx andalso MinMy =< DestMy andalso DestMy =< MaxMy
                    andalso check_can_fight(TrapData, MapInfo) of
                true -> %% 在判定范围内
                    get_hurt_list(TrapData, MinMx, MaxMx, MinMy, MaxMy, R, [ActorID|ActorAcc]);
                _ ->
                    get_hurt_list(TrapData, MinMx, MaxMx, MinMy, MaxMy, R, ActorAcc)
            end;
        _ ->
            get_hurt_list(TrapData, MinMx, MaxMx, MinMy, MaxMy, R, ActorAcc)
    end.

check_can_fight(TrapData, MapInfo) ->
    #r_trap{pk_mode = PKMode, camp_id = CampID} = TrapData,
    #r_map_actor{actor_type = ActorType, camp_id = DestCampID, role_extra = RoleExtra} = MapInfo,
    check_can_fight2(PKMode, CampID, DestCampID, ActorType, RoleExtra).

check_can_fight2(?PK_MODE_PEACE, CampID, DestCampID, ActorType, RoleExtra) ->
    if
        ActorType =:= ?ACTOR_TYPE_ROLE -> %% 红名玩家在和平模式下可以打
            RoleExtra#p_map_role.pk_value > 0;
        true ->
            CampID =/= DestCampID
    end;
check_can_fight2(?PK_MODE_CAMP, CampID, DestCampID, _ActorType, _RoleExtra) ->
    CampID =/= DestCampID;
check_can_fight2(?PK_MODE_ALL, _CampID, _DestCampID, _ActorType, _RoleExtra) ->
    true.

get_tile_list(MinMx, MaxMx, MinMy, MaxMy) ->
    MinTx = ?M2T(MinMx),
    MaxTx = ?M2T(MaxMx),
    MinTy = ?M2T(MinMy),
    MaxTy = ?M2T(MaxMy),
    lists:flatten([ [{Tx, Ty}|| Ty <- lists:seq(MinTy, MaxTy)] || Tx <- lists:seq(MinTx, MaxTx)]).