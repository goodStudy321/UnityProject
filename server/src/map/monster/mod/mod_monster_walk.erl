%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 五月 2017 15:30
%%%-------------------------------------------------------------------
-module(mod_monster_walk).
-author("laijichang").

-include("global.hrl").
-include("monster.hrl").

-export([
    guard/1,
    return/1,
    patrol/1,
    td_walk/1
]).
-export([
    start_walk/4,
    get_nearest_pos/3,
    get_nearest_empty_pos/2,
    get_random_around_pos/3,
    get_random_around_pos/2,
    get_walkable_random_around_pos/3
]).

%% ==================== 警戒状态 =============================

guard(#r_monster{monster_id = MonsterID} = MonsterData)->
    case catch guard2(MonsterID, MonsterData) of
        {ok, AddCounter, MonsterData2}->
            {ok, AddCounter, MonsterData2};
        Error->
            ?ERROR_MSG("GUARD error:~w",[Error]),
            {ok, ?BLAME_COUNTER, MonsterData}
    end.

guard2(MonsterID, MonsterData)->
    #r_monster{monster_id = MonsterID, type_id = TypeID,
                last_patrol_time = LastPTime, patrol_pos = PatrolPos} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    MonsterConfig = monster_misc:get_monster_config(TypeID),
    #c_monster{rarity = Rarity, patrol_range = PatrolRangeMs, patrol_cd = CD, fight_type = FightType} = MonsterConfig,
    MonsterData2 = ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, mod_monster_world_boss:recover_hp(MonsterData), MonsterData),

    case FightType of
        ?FIGHT_TYPE_ACTIVE ->%% 主动怪
            begin_to_fight(MonsterID, MonsterData2, MonsterConfig);
        _ ->
            ok
    end,
    ?IF(MoveSpeed =/= 0,  ok, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2)),
    ?IF(time_tool:now() - LastPTime >= CD andalso CD =/= 0, ok, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2)),
    case PatrolPos of
        #r_pos{}->
            ReturnData = MonsterData2#r_monster{state = ?MONSTER_STATE_PATROL},
            ?MONSTER_RETURN(?MIN_COUNTER, ReturnData);
        undefined->
            next
    end,
    %% 出生点附近巡逻
    BornPos = MonsterData2#r_monster.born_pos,
    #r_pos{mx = Mx, my = My, dir = Dir} = BornPos,
    AddX = lib_tool:random(PatrolRangeMs * 2) - PatrolRangeMs,
    AddY = lib_tool:random(PatrolRangeMs * 2) - PatrolRangeMs,
    PatrolPos2 = map_misc:get_pos_by_meter(Mx + AddX, My + AddY,  Dir),
    MonsterData3 = MonsterData2#r_monster{state = ?MONSTER_STATE_PATROL, patrol_pos = PatrolPos2},
    ?MONSTER_RETURN(?MIN_COUNTER, MonsterData3).

%% 开始攻击
begin_to_fight(MonsterID, MonsterData, MonsterConfig) ->
    Enemy = mod_monster_attack:active_find_enemies(MonsterID, MonsterData, MonsterConfig),
    case Enemy of
        #r_monster_enemy{} ->
            MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_FIGHT,
                                                 first_enemies = [Enemy], walk_path = []},
            mod_monster_map:monster_stop(MonsterID),
            ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2);
        _ ->
            ok
    end.


%% ===================== 巡逻 ================================
%%巡逻
patrol(#r_monster{monster_id = MonsterID} = MonsterData) ->
    case catch patrol2(MonsterID, MonsterData) of
        {ok, AddCounter, MonsterData2}->
            {ok, AddCounter, MonsterData2};
        Error->
            ?ERROR_MSG("PATROL error:~w",[Error]),
            {ok, ?BLAME_COUNTER, MonsterData}
    end.

patrol2(MonsterID, MonsterData)->
    #r_monster{monster_id = MonsterID, type_id = TypeID,
                attack_speed = AttackSpeed, patrol_pos = PatrolPos} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    ?IF(MoveSpeed =/= 0 andalso AttackSpeed =/= 0, ok, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData)),
    #r_pos{tx = Tx, ty = Ty} = MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    #c_monster{fight_type = FightType} = MonsterConfig = monster_misc:get_monster_config(TypeID),
    case FightType of
        ?FIGHT_TYPE_ACTIVE  ->%% 主动怪
            begin_to_fight(MonsterID, MonsterData, MonsterConfig);
        _ ->
            next
    end,
    case {Tx, Ty} =:= {PatrolPos#r_pos.tx, PatrolPos#r_pos.ty} of
        true ->
            MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_GUARD, last_patrol_time = time_tool:now(), patrol_pos = undefined, walk_path=[]},
            ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2);
        _ ->
            start_walk(MonsterPos, PatrolPos, MonsterID, MonsterData)
    end.

%% ==================== 返回 ========================
%%怪物返回出生点
return(#r_monster{monster_id = MonsterID} = MonsterData)->
    case catch return2(MonsterID, MonsterData) of
        {ok, AddCounter, MonsterData2}->
            {ok, AddCounter, MonsterData2};
        Error->
            ?ERROR_MSG("RETURN error:~w",[Error]),
            {ok, ?BLAME_COUNTER, MonsterData}
    end.

return2(MonsterID, MonsterData)->
    #r_monster{type_id = TypeID, born_pos = BornPos, return_list = ReturnList, owner = Owner} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    #c_monster{move_speed = DefaultSpeed, rarity = Rarity} = monster_misc:get_monster_config(TypeID),
    #r_pos{} = MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    IsInDis = monster_misc:judge_in_distance(MonsterPos, BornPos, 0),
    if
        DefaultSpeed =:= 0 ->   %% 默认速度为0的话，当前位置就为出生位置
            try_recover_hp(MonsterData),
            MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_GUARD, first_enemies = [], second_enemies = [], fight_args = [], born_pos = MonsterPos},
            ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2);
        MoveSpeed =:= 0 ->
            ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData);
        IsInDis ->
            case ReturnList of
                [] ->
                    try_recover_hp(MonsterData),
                    Counter = ?NORMAL_COUNTER,
                    MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_GUARD};
                [#r_monster_path{delay_counter = Counter}] ->
                    try_recover_hp(MonsterData),
                    monster_misc:update_base_move_speed(MonsterData, DefaultSpeed),
                    mod_map_monster:monster_reach_pos(MonsterID, MonsterPos),
                    MonsterData2 = MonsterData#r_monster{
                        state = ?MONSTER_STATE_GUARD,
                        return_list = []};
                [#r_monster_path{delay_counter = Counter}|R] ->
                    [#r_monster_path{pos = Pos, use_time = UseTime}|_] = R,
                    MoveSpeed2 = monster_misc:get_path_move_speed(mod_map_ets:get_actor_pos(MonsterID), Pos, UseTime, DefaultSpeed),
                    MonsterDataT = monster_misc:update_base_move_speed(MonsterData, DefaultSpeed),
                    mod_map_monster:monster_update_move_speed(MonsterID, MoveSpeed2),
                    MonsterData2 = MonsterDataT#r_monster{
                        born_pos = Pos,
                        state = ?MONSTER_STATE_RETURN,
                        return_list = R}
            end,
            Owner2 = ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, Owner, undefined),
            MonsterData3 = MonsterData2#r_monster{first_enemies = [], second_enemies = [], fight_args = [], owner = Owner2},
            ?MONSTER_RETURN(Counter, MonsterData3);
        true ->
            start_walk(MonsterPos, BornPos, MonsterID, MonsterData)
    end.

try_recover_hp(MonsterData) ->
    #r_monster{
        monster_id = MonsterID,
        attr = FightAttr
        } = MonsterData,
    case copy_misc:is_copy_five_elements(map_common_dict:get_map_id()) of
        true ->
            mod_map_monster:monster_buff_heal(MonsterID, FightAttr#actor_fight_attr.max_hp, ?BUFF_ADD_HP, 0);
        _ ->
            ok
    end.
%% ============================ 走路 =======================================

%% ============================ td ========================================
td_walk(MonsterData) ->
    case catch td_walk2(MonsterData) of
        {ok, AddCounter, MonsterData2}->
            {ok, AddCounter, MonsterData2};
        Error->
            ?ERROR_MSG("RETURN error:~w",[Error]),
            {ok, ?BLAME_COUNTER, MonsterData}
    end.

td_walk2(MonsterData)->
    #r_monster{monster_id = MonsterID, attack_speed = AttackSpeed, td_pos_list = TDPosList} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    ?IF(MoveSpeed =/= 0 andalso AttackSpeed =/= 0, ok, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData)),
    #r_pos{tx = Tx, ty = Ty} = MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    [{TargetTx, TargetTy}|R] = TDPosList,
    case TargetTx =:= Tx andalso TargetTy =:= Ty of
        true ->
            case R of
                [{NextTx, NextTy}|_] ->
                    MonsterData2 = MonsterData#r_monster{td_pos_list = R, born_pos = map_misc:get_pos_by_tile(NextTx, NextTy)};
                _ ->
                    ?IF(copy_data:is_immortal_map(map_common_dict:get_map_id()), mod_map_monster:immortal_reach_pos(MonsterID), ok),
                    MonsterData2 = MonsterData#r_monster{
                        td_pos_list = [],
                        state = ?MONSTER_STATE_RETURN,
                        born_pos = map_misc:get_pos_by_tile(TargetTx, TargetTy)}
            end,
            ?MONSTER_RETURN(?ONE_COUNTER, MonsterData2);
        _ ->
            start_walk(MonsterPos, map_misc:get_pos_by_tile(TargetTx, TargetTy), MonsterID, MonsterData)
    end.

%% ============================ td ========================================

%%怪物行走
start_walk(#r_pos{}=MonsterPos, #r_pos{}=DestPos, MonsterID, MonsterData) ->
    #r_monster{state = State, walk_path = WalkPath, type_id = TypeID, buff_status = BuffStatus,
                last_dest_pos = LastDestPos} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    %% 晕眩、移动加上buff判断
    case ?IS_BUFF_IMPRISON(BuffStatus) orelse ?IS_BUFF_DIZZY(BuffStatus) of
        true ->
            ?IF(WalkPath =/= [], mod_monster_map:monster_stop(MonsterID), ok),
            ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData#r_monster{walk_path = []});
        _ ->
            ok
    end,
    #c_monster{rarity = Rarity} = monster_misc:get_monster_config(TypeID),
    {AddCounter, MonsterData2} =
        case (Rarity =:= ?MONSTER_RARITY_BOSS orelse Rarity =:= ?MONSTER_RARITY_WORLD_BOSS) andalso State =:= ?MONSTER_STATE_FIGHT of
            true -> %% BOSS 级怪物战斗中才用高级寻路
                NewWalkPath = ?IF(DestPos =:= LastDestPos , WalkPath, []),
                case NewWalkPath of
                    [] ->
                        second_level_walk(MonsterID, MonsterData, MonsterPos, DestPos, MoveSpeed);
                    [_|_]->
                        walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath)
                end;
            _ -> %% 普通怪物寻路
                case WalkPath of
                    [] ->
                        first_level_walk(MonsterID, MonsterData, MonsterPos, DestPos, MoveSpeed);
                    [_|_] ->
                        walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath)
                end
        end,
    ?MONSTER_RETURN(AddCounter, MonsterData2);
start_walk(_MonsterPos, _DestPos, _MonsterID, MonsterData)->
    ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData).

%%按照寻路除的路径走路,如果遇到阻挡则重新寻路
walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPathList) ->
    [ #r_path{corner = Corner, path = [WalkPos|WalkPosList]}=WalkPath | WalkPathRem ] = WalkPathList,
    case WalkPosList of
        [] -> NewWalkPosList = WalkPathRem;
        _ -> NewWalkPosList = [ WalkPath#r_path{corner = 0, path = WalkPosList} |WalkPathRem]
    end,
    case Corner of
        0-> ignore;
        _-> mod_map_monster:monster_move_point(MonsterID, Corner)
    end,
    mod_map_monster:monster_move(MonsterID, WalkPos, map_misc:pos_encode(WalkPos)),
    case NewWalkPosList of
        []->
            mod_map_monster:monster_stop(MonsterID);
        _->
            ignore
    end,
    MonsterData2 = MonsterData#r_monster{last_dest_pos = DestPos, walk_path = NewWalkPosList},
    AddCounter = mod_walk:get_move_speed_counter(MoveSpeed, WalkPos#r_pos.dir),
    {AddCounter, MonsterData2}.


%%低级寻路,对巡逻和返回装他的怪物的只做直线寻路处理
first_level_walk(MonsterID, MonsterData, MonsterPos, DestPos, MoveSpeed) ->
    #r_monster{state = State} = MonsterData,
    case State of
        ?MONSTER_STATE_PATROL ->
            case mod_walk:get_straight_line_path(MonsterPos, DestPos) of
                {ok, [_|_] = WalkPath} ->
                    walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath);
                _ ->
                    MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_GUARD, patrol_pos = undefined, walk_path = []},
                    {?BLAME_COUNTER, MonsterData2}
            end;
        ?MONSTER_STATE_RETURN ->
            case mod_walk:get_walk_path(MonsterPos, DestPos) of
                {ok, [_|_] = WalkPath} ->
                    walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath);
                _Err ->
                    MonsterData2 = MonsterData#r_monster{state = ?MONSTER_STATE_GUARD, last_dest_pos = undefined, walk_path = []},
                    mod_map_monster:monster_change_pos(MonsterID, DestPos, map_misc:pos_encode(DestPos)),
                    ?TRY_CATCH( ?INFO_MSG("debug info:~w", [{MonsterPos, DestPos, MonsterID, MonsterData#r_monster.type_id, _Err}]), Err1),
                    {?BLAME_COUNTER, MonsterData2}
            end;
        _ ->
            case mod_walk:get_walk_path(MonsterPos, DestPos) of
                {ok, [_|_] = WalkPath} ->
                    walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath);
                _Err ->
                    {?BLAME_COUNTER, MonsterData#r_monster{walk_path = []}}
            end
    end.

%%BOSS在战斗中是直接采用高级寻路
second_level_walk(MonsterID, MonsterData, MonsterPos, DestPos, MoveSpeed) ->
    case mod_walk:get_senior_path(MonsterPos, DestPos) of
        {ok, [_|_] = WalkPath} ->
            walk_inpath(MonsterID, MonsterData, DestPos, MoveSpeed, WalkPath);
        _ ->
            {?BLAME_COUNTER, MonsterData}
    end.

get_nearest_pos(MonsterPos, DestPos, Distance) ->
    MDir = map_misc:get_direction(MonsterPos, DestPos),
    Dir = map_misc:dir_m2t(MDir),
    #r_pos{tx = Tx, ty = Ty} = DestPos,
    {NewTx, NewTy} = get_nearest_pos2(Tx, Ty, Dir, ?IF(Distance > 5, 5, Distance)),
    NewMx = NewTx * ?TILE_SIZE + lib_tool:random(?TILE_SIZE - 1),
    NewMy = NewTy * ?TILE_SIZE + lib_tool:random(?TILE_SIZE - 1),
    Pos = map_misc:get_pos_by_meter(NewMx, NewMy),
    MDir2 = map_misc:get_direction(Pos, DestPos),
    Pos#r_pos{mdir = MDir2, dir = map_misc:dir_m2t(MDir2)}.

get_nearest_pos2(Tx, Ty, Dir, 1) ->
    List =  mod_walk:get_pos_1_1(Dir),
    case get_nearest_pos3(Tx, Ty, List) of
        {Tx2, Ty2} ->
            {Tx2, Ty2};
        _ ->
            get_random_around_pos(Tx, Ty, 1)
    end;
get_nearest_pos2(Tx, Ty, DirT, Dis) ->
    Dir = (((DirT+1) div 2) rem 4) * 2,
    {L, _Length} = mod_walk:get_pos_1(Dis, Dir),
    case get_nearest_pos3(Tx, Ty, L) of
        {Tx2, Ty2} ->
            {Tx2, Ty2};
        _ ->
            {L2, _Length2} = mod_walk:get_pos_2(Dis, Dir),
            case get_nearest_pos3(Tx, Ty, L2) of
                {Tx2, Ty2} ->
                    {Tx2, Ty2};
                _ ->
                    {Tx, Ty}
            end
    end.

get_nearest_pos3(_Tx, _Ty, []) ->
    false;
get_nearest_pos3(Tx, Ty, [{AddTx, AddTy}|R]) ->
    Tx2 = Tx + AddTx,
    Ty2 = Ty + AddTy,
    case map_base_data:is_exist(Tx2, Ty2) of
        true -> {Tx2, Ty2};
        _ -> get_nearest_pos3(Tx, Ty, R)
    end.


%% 分N个方向,取最近的格子
get_nearest_empty_pos(#r_pos{tx = Tx2, ty = Ty2} = DestPos, Distance) ->
    {NewTx, NewTy} = get_pretreatment_pos(Tx2, Ty2, lib_tool:random(0, 7), ?IF(Distance > 5, 5, Distance)),
    NewMx = NewTx * ?TILE_SIZE + lib_tool:random(?TILE_SIZE - 1),
    NewMy = NewTy * ?TILE_SIZE + lib_tool:random(?TILE_SIZE - 1),
    Pos = map_misc:get_pos_by_meter(NewMx, NewMy),
    MDir = map_misc:get_direction(Pos, DestPos),
    Pos#r_pos{mdir = MDir, dir = map_misc:dir_m2t(MDir)}.

%% 地图进程调用 最多取20次
get_walkable_random_around_pos(Tx, Ty, Area) ->
    get_walkable_random_around_pos2(Tx, Ty, Area, 20).

get_walkable_random_around_pos2(Tx, Ty, _Area, 0) ->
    {Tx, Ty};
get_walkable_random_around_pos2(Tx, Ty, Area, Times) ->
    {Tx2, Ty2} = get_random_around_pos(Tx, Ty, Area),
    case map_base_data:is_exist(Tx2, Ty2) of
        true -> {Tx2, Ty2};
        _ -> get_walkable_random_around_pos2(Tx, Ty, Area,Times - 1)
    end.

get_random_around_pos(Tx, Ty, Area) ->
    RanX = lib_tool:random(-Area, Area),
    RanY = lib_tool:random(-Area, Area),
    FTx = Tx + RanX,
    FTY = Ty + RanY,
    {FTx, FTY}.
get_random_around_pos(#r_pos{tx = Tx, ty = TY} = Pos, Area) ->
    {FTx, FTY} = get_random_around_pos(Tx, TY, Area),
    Pos#r_pos{tx = FTx, ty = FTY}.


get_pretreatment_pos(Tx, Ty, Dir, 1) ->
    List =  mod_walk:get_pos_1_1(Dir),
    case get_pretreatment_pos2(Tx, Ty, List) of
        false -> get_random_around_pos(Tx, Ty, 1);
        Pos -> Pos
    end;
get_pretreatment_pos(Tx, Ty, DirT, Dis) ->
    Dir = (((DirT+1) div 2) rem 4) * 2,
    {L, Length} = mod_walk:get_pos_1(Dis, Dir),
    case get_random_empty_pos(Tx, Ty, L, Length, 2) of %% 随机两次
        false ->
            {L2, Length2} = mod_walk:get_pos_2(Dis, Dir),
            case get_random_empty_pos(Tx, Ty, L2, Length2, 3) of %% 随机3次
                false ->
                    {Tx, Ty};
                Pos ->
                    Pos
            end;
        Pos ->
            Pos
    end.

get_pretreatment_pos2(Tx2, Ty2, [{Tx, Ty}|List]) ->
    case mod_map_tile:is_empty(Tx + Tx2, Ty + Ty2) of
        true -> {Tx + Tx2, Ty + Ty2};
        _ -> get_pretreatment_pos2(Tx2, Ty2, List)
    end;
get_pretreatment_pos2(_,_,_) ->
    false.

%% 随机拿一个空格子
get_random_empty_pos(Tx, Ty, L, Length, TryTimes) when TryTimes>0 ->
    {AddTx, AddTy} = lists:nth(lib_tool:random(1, Length), L),
    Tx2 = Tx + AddTx,
    Ty2 = Ty + AddTy,
    case mod_map_tile:is_empty(Tx2, Ty2) of
        true -> {Tx2, Ty2};
        false -> get_random_empty_pos(Tx, Ty, L, Length, TryTimes-1)
    end;
get_random_empty_pos(_Tx, _Ty, _L, _Length, _TryTimes) ->
    false.
