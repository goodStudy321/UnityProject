%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 14:56
%%%-------------------------------------------------------------------
-module(mod_monster_fight).
-author("laijichang").

%% API
-include("monster.hrl").
-include("proto/mod_role_skill.hrl").

-export([
    fight/1
]).

-export([
    get_direction_pos/2,
    get_other_enemy/5
]).


%% ============================= 战斗 ============================
%% 怪物状态机触发战斗状态
fight(MonsterData) ->
    #r_monster{buff_status = BuffStatus, monster_id = MonsterID} =  MonsterData,
    MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    case catch mod_fight_etc:check_can_attack_buffs(BuffStatus) of
        true ->
            case catch fight2(MonsterID, MonsterData, MapInfo) of
                {ok, AddCounter, MonsterData2}->
                    {ok, AddCounter, MonsterData2};
                Error ->
                    ?ERROR_MSG("FIGHT error:~w Data:~w",[Error, MonsterData]),
                    {ok, ?BLAME_COUNTER, MonsterData}
            end;
        _ ->
            {ok, ?NORMAL_COUNTER, MonsterData}
    end.

fight2(MonsterID, MonsterData, MapInfo)->
    FightArgs = MonsterData#r_monster.fight_args,
    case common_skill:get_next_skill(FightArgs) of
        {next_prepare, Action, Remain} ->
            fight_prepare(MonsterID, MonsterData, {Action, Remain});
        {next_hurt, Action, Hurt, Remain} ->
            fight(MonsterID, MonsterData, MapInfo, {Action, Hurt, Remain});
        _ ->
            fight_prepare(MonsterID, MonsterData, undefined)
    end.

fight(MonsterID, MonsterData, MapInfo, FightInfo) ->
    #r_monster{type_id = TypeID, last_attack_time = LastAttackTime} = MonsterData,
    NowMs = time_tool:now_ms(),
    case FightInfo of
        {#r_skill_action{skill_id = SkillID}, #r_skill_hurt{delay = Time} = Hurt, Remain} when NowMs >= LastAttackTime + Time ->
            #c_monster{active_radius = ActiveRadiusMs} = monster_misc:get_monster_config(TypeID),
            ActiveRadius = ActiveRadiusMs div ?TILE_SIZE,
            MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
            MonsterData2 = mod_monster_attack:update_enemy_lists(MonsterData, MonsterPos, ActiveRadius),
            ReturnData = MonsterData2#r_monster{state = ?MONSTER_STATE_RETURN},
            case mod_monster_attack:get_enemy(MonsterData2) of
                #r_monster_enemy{actor_id = DestActorID} ->
                    next;
                _ ->
                    DestActorID = ?MONSTER_RETURN(?MIN_COUNTER, ReturnData)
            end,
            DestActorPos = mod_map_ets:get_actor_pos(DestActorID),
            ?IF(DestActorPos =:= undefined, ?MONSTER_RETURN(?MIN_COUNTER, ReturnData), ok),
            #c_skill{
                pos_type = PosType,
                attack_type = AttackType,
                range_args = RangeArgs} = common_skill:get_skill_config(SkillID),
            NewMonsterPos = get_direction_pos(MonsterPos, DestActorPos),
            OtherList = get_other_enemy(MapInfo, NewMonsterPos, DestActorPos, AttackType, RangeArgs),
            SkillPos = common_skill:get_skill_pos(NewMonsterPos, DestActorPos, PosType, []),
            attack_enemy(MonsterID, SkillID, Hurt, [DestActorID|lists:delete(DestActorID, OtherList)], SkillPos),
            MonsterData3 = MonsterData#r_monster{fight_args = Remain, last_attack_time = NowMs},
            ?MONSTER_RETURN(?MIN_COUNTER, MonsterData3);
        _ ->
            ?MONSTER_RETURN(?MIN_COUNTER, MonsterData)
    end.

fight_prepare(MonsterID, MonsterData, FightInfo) ->
    #r_monster{
        type_id = TypeID,
        attack_speed = AttackSpeed,
        born_pos=BornPos,
        last_dest_pos = DestPos,
        last_skill = LastSkillID,
        last_skill_time= LastSkillTime,
        skill_list = SkillList,
        buff_status = BuffStatus,
        attack_pos = AttackPos} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    NowMs = time_tool:now_ms(),
    ?IF(AttackSpeed =:= 0, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData), ok),
    ?IF(is_common_cd(NowMs, LastSkillTime, LastSkillID), ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData), ok),
    #c_monster{active_radius = ActiveRadiusMs, not_around = NotAround} = monster_misc:get_monster_config(TypeID),
    ActiveRadius = ActiveRadiusMs div ?TILE_SIZE,
    MonsterPos = mod_map_ets:get_actor_pos(MonsterID),
    %% 非TD副本移动状态 超出活动范围则拉回
    case monster_misc:judge_in_distance(MonsterPos, BornPos, ActiveRadius) orelse monster_misc:is_td_move(MonsterData) of
        true ->
            next;
        false ->
            ReturnData = MonsterData#r_monster{state = ?MONSTER_STATE_RETURN},
            ?MONSTER_RETURN(?MIN_COUNTER, ReturnData)
    end,

    MonsterData2 = mod_monster_attack:update_enemy_lists(MonsterData, MonsterPos, ActiveRadius),
    case mod_monster_attack:get_enemy(MonsterData2) of
        #r_monster_enemy{actor_id = DestActorID} ->
            next;
        _ ->
            State = ?IF(monster_misc:is_td_move(MonsterData2), ?MONSTER_STATE_TD, ?MONSTER_STATE_RETURN),
            ReturnData2 = MonsterData2#r_monster{state = State},
            DestActorID = ?MONSTER_RETURN(?MIN_COUNTER, ReturnData2)
    end,
    DestActorPos = mod_map_ets:get_actor_pos(DestActorID),
    {SkillList2, CanUse, AttAckDis, SkillConfig, Action, FightArgs} = try_monster_skill(FightInfo, SkillList, NowMs, BuffStatus),
    ?IF(CanUse, ok, ?MONSTER_RETURN(?NORMAL_COUNTER, MonsterData2)),

    case check_next_step(MonsterPos, DestActorPos, DestPos, AttackPos, AttAckDis, BuffStatus, MoveSpeed, NotAround) of %% 目标点能攻击到玩家且当前不在目标点
        walk -> %% 继续朝目标走
            mod_monster_walk:start_walk(MonsterPos, DestPos, MonsterID, MonsterData2);
        {walk, DestActorPos2, AttackPos2} -> %% 改变目标走
            mod_monster_walk:start_walk(MonsterPos, DestActorPos2, MonsterID, MonsterData2#r_monster{walk_path = [], attack_pos = AttackPos2});
        {attack, AttackPos2} -> %% 可以攻击了
            mod_monster_map:monster_stop(MonsterID),
            #c_skill{skill_id = SkillID, bullet_speed = BulletSpeed} = SkillConfig,
            NewMonsterPos = get_direction_pos(MonsterPos, DestActorPos),
            {ok, Counter} = attack_prepare(Action, BulletSpeed, MonsterID, DestActorID, NewMonsterPos, DestActorPos),
            LastSkillTime2 = ?IF(FightInfo =/= undefined, LastSkillTime, NowMs),
            MonsterData3 = MonsterData2#r_monster{
                last_skill = SkillID,
                last_skill_time = LastSkillTime2,
                fight_args = FightArgs,
                walk_path = [],
                attack_pos = AttackPos2,
                skill_list = lists:reverse(lists:keysort(#r_monster_skill.skill_type, SkillList2))},
            ?MONSTER_RETURN(Counter, MonsterData3);
        stay -> %% 我动不了
            ?MONSTER_RETURN(?BLAME_COUNTER, MonsterData2)
    end.

check_next_step(MonsterPos, DestActorPos, _DestPos, _AttackPos, AttAckDis, BuffStatus, MoveSpeed, _NotAround)
    when MoveSpeed =:= 0 orelse ?IS_BUFF_IMPRISON(BuffStatus) ->
    case monster_misc:judge_in_distance(MonsterPos, DestActorPos, AttAckDis) of
        true -> {attack, MonsterPos};
        false -> stay
    end;
check_next_step(MonsterPos, DestActorPos, _DestPos, _AttackPos, AttAckDis, _BuffStatus, _MoveSpeed, NotAround) when NotAround > 0 ->
    case monster_misc:judge_in_distance(MonsterPos, DestActorPos, AttAckDis) of
        true -> %% 到达自己可攻击的范围
            {attack, MonsterPos};
        _ -> %% 寻找最近的目标点
            NewDestPos = mod_monster_walk:get_nearest_pos(MonsterPos, DestActorPos, AttAckDis),
            {walk, NewDestPos, NewDestPos}
    end;
check_next_step(MonsterPos, DestActorPos, DestPos, AttackPos, AttAckDis, _BuffStatus, _MoveSpeed, _NotAround) ->
    %% 当前位置能攻击到玩家且只有自己则攻击,或者是目标点也攻击
    %% 目标位置能攻击到玩家则继续走,否则找一个能攻击到玩家的最近位置（优先不被占位）
    case monster_misc:judge_in_distance(MonsterPos, DestActorPos, AttAckDis) of
        true -> %% 到达自己可攻击的范围
            case is_self_pos(MonsterPos) of
                true -> %% 当前坐标只有自己 攻击
                    {attack, MonsterPos};
                _ ->
                    IsSameTile = map_misc:check_same_tile(AttackPos, DestPos),
                    IsSameTile2 = map_misc:check_same_tile(AttackPos, MonsterPos),
                    if
                        IsSameTile2 -> %% 移动到了，攻击吧
                            {attack, MonsterPos};
                        IsSameTile -> %% 移动至目标攻击位置
                            walk;
                        true -> %% 没有目标，很迷茫
                            NewDestPos = mod_monster_walk:get_nearest_empty_pos(DestActorPos, AttAckDis),
                            {walk, NewDestPos, NewDestPos}
                    end
            end;
        _ -> %% 先朝目标方向移动
            case map_misc:check_same_tile(DestPos, DestActorPos) of
                true -> %% 继续移动
                    walk;
                _ ->
                    {walk, DestActorPos, #r_pos{}}
            end
    end.

attack_prepare(Action, BulletSpeed, MonsterID, DestActorID, MonsterPos, DestActorPos)->
    #r_skill_action{skill_id = SkillID, hurt_list = HurtList, step_id = StepID} = Action,
    [#r_skill_hurt{delay = Delay}|_] = HurtList,
    case BulletSpeed > 0 of
        true ->
            #r_pos{mx = X1, my = Y1} = MonsterPos,
            #r_pos{mx = X2, my = Y2} = DestActorPos,
            Delay2 = map_misc:get_dis(X1, Y1, X2, Y2) * 1000 / BulletSpeed,
            Counter = lib_tool:ceil((Delay + Delay2) / 100);
        _ ->
            Counter = lib_tool:ceil(Delay / 100)
    end,
    Direction = map_misc:get_direction(MonsterPos, DestActorPos),
    MonsterPos2 = MonsterPos#r_pos{mdir = Direction},
    mod_map_monster:monster_fight_prepare(MonsterID, DestActorID, SkillID, StepID, MonsterPos2, map_misc:pos_encode(MonsterPos2)),
    {ok, Counter}.

attack_enemy(MonsterID, SkillID, Hurt, DestList, SkillPos) ->
    #r_skill_hurt{self_effect = SelfEffects, enemy_effect = EnemyEffects} = Hurt,
    IntPos = map_misc:pos_encode(SkillPos),
    mod_map_monster:monster_fight(
        #fight_args{
            dest_id_list = DestList,
            skill_id = SkillID,
            enemy_effect_list = EnemyEffects,
            self_effect_list = SelfEffects,
            skill_pos = IntPos,
            src_id = MonsterID,
            src_type = ?ACTOR_TYPE_MONSTER}),
    ok.

try_monster_skill(FightInfo, SkillList, NowMs, BuffStatus) ->
    case FightInfo of
        {Action, Remain} ->
            #r_skill_action{skill_id = SkillID} = Action,
            case common_skill:check_skill_by_buff_status(SkillID, BuffStatus) of
                {ok, #c_skill{dis = Dis} = SkillConfig} ->
                    {SkillList, true, lib_tool:ceil(Dis/100), SkillConfig, Action, Remain};
                _ ->
                    {SkillList, false, 0, undefined, Action, Remain}
            end;
        _ ->
            try_monster_skill2(SkillList, [], NowMs, BuffStatus)
    end.

try_monster_skill2([], SkillAcc, _NowMS, _BuffStatus) ->
    {SkillAcc, false, 1, undefined, undefined, []};
try_monster_skill2([Skill|R], SkillAcc, NowMs, BuffStatus) ->
    #r_monster_skill{skill_id = SkillID, time = Time} = Skill,
    case NowMs >= Time andalso common_skill:check_skill_by_buff_status(SkillID, BuffStatus) of
        {ok, #c_skill{dis = Dis, cd = CD} = SkillConfig} ->
            Skill2 = Skill#r_monster_skill{time = NowMs + CD},
            [Action|_] = ActionList = common_skill:get_skill_action_list(SkillID),
            {SkillAcc ++ [Skill2|R], true, lib_tool:ceil(Dis/100), SkillConfig, Action, ActionList};
        _ ->
            try_monster_skill2(R, [Skill|SkillAcc], NowMs, BuffStatus)
    end.

get_direction_pos(Pos1, Pos2) ->
    MDir = map_misc:get_direction(Pos1, Pos2),
    Pos1#r_pos{dir = map_misc:dir_m2t(MDir), mdir = MDir}.

is_common_cd(_NowMs, _LastSkillTime, 0) ->
    false;
is_common_cd(NowMs, LastSkillTime, LastSkillID) ->
    #c_skill{common_cd = CommonCD, action_cd = ActionCD} = common_skill:get_skill_config(LastSkillID),
    NowMs < LastSkillTime + CommonCD + ActionCD.

%% 这代码看似有问题其实木有问题,检查是否格子只有一个对象,有的话必然是怪物自身
is_self_pos({Tx, Ty}) ->
    case mod_map_ets:get_tile_actors(Tx, Ty) of
        [_] -> true;
        _ -> false
    end;
is_self_pos(#r_pos{tx = Tx, ty = Ty}) ->
    is_self_pos({Tx, Ty});
is_self_pos(_) ->
    false.

get_other_enemy(_MapInfo, _MonsterPos, _DestActorPos, ?SKILL_ONE, _) ->
    [];
get_other_enemy(MapInfo, MonsterPos, DestActorPos, AttackType, Range) ->
    %% 根据类型,范围来获取要攻击的格子
    Tiles = get_tiles(MonsterPos, DestActorPos, AttackType, Range),
    CampID = MapInfo#r_map_actor.camp_id,
    get_other_enemy2(CampID, Tiles, []).


get_other_enemy2(_CampID, [], Acc) ->
    Acc;
get_other_enemy2(CampID, [{Tx, Ty}|R], Acc) ->
    case mod_map_ets:get_tile_actors(Tx, Ty) of
        [_|_] = ActorList  ->
            get_other_enemy2(CampID, R, get_other_enemy3(CampID, ActorList, []) ++ Acc);
        _ ->
            get_other_enemy2(CampID, R, Acc)
    end.

get_other_enemy3(_CampID, [], Acc) ->
    Acc;
get_other_enemy3(CampID, [{_ActorType, ActorID}|R], Acc) ->
    case mod_map_ets:get_actor_mapinfo(ActorID) of
        #r_map_actor{status = Status, camp_id = ActorCampID} ->
            case Status =/= ?MAP_STATUS_DEAD andalso CampID =/= ActorCampID of
                true ->
                    get_other_enemy3(CampID, R, [ActorID|Acc]);
                false ->
                    get_other_enemy3(CampID, R, Acc)
            end;
        _ ->
            Acc
    end;
get_other_enemy3(CampID, [_|R], Acc) ->
    get_other_enemy3(CampID, R, Acc).

%% 获取目标格子
get_tiles(#r_pos{tx = Tx, ty = Ty, dir = Dir}, _DestActorPos, ?SKILL_SELF_RECT, [Length, Width]) ->
    get_actors_front_map_tiles(Tx, Ty, get_range(Length), get_range(Width), Dir);
get_tiles(#r_pos{tx = Tx, ty = Ty}, _DestActorPos, ?SKILL_SELF_ROUND, [Range]) ->
    get_actors_around_map_tiles(Tx, Ty, get_range(Range));
get_tiles(_MonsterPos, #r_pos{tx = Tx, ty = Ty}, ?SKILL_ENEMY_ROUND, [Range]) ->
    get_actors_around_map_tiles(Tx, Ty, get_range(Range)).

get_range(Range) ->
    Range div ?TILE_SIZE + 1.

%% 圆形范围
get_actors_around_map_tiles(Tx, Ty, Range) ->
    %%TargetArea为3表示3*3的区域,即玩家自身格子和周围一圈的格子
    Num = round((Range-1)/2),
    SX = Tx - Num,
    EX = Tx + Num,
    SY = Ty - Num,
    EY = Ty + Num,
    format_tiles(SX, EX, SY ,EY).

%% 矩形范围
get_actors_front_map_tiles(Tx, Ty, Length, Width, 0) -> %% 正Y方向
    Num = round((Width-1)/2),
    SX = Tx - Num, EX = Tx + Num,
    SY = Ty, EY = Ty + Length,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 1) -> %% 正X、正Y 45度
    LengthNum = round(Length * 0.7),
    WidthNum = round((Width*1.4-1)/2),
    SX = Tx, EX = Tx + WidthNum,
    SY = Ty, EY = Ty + LengthNum,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 2) -> %% 正X方向
    Num = round((Width-1)/2),
    SX = Tx, EX = Tx + Length,
    SY = Ty - Num, EY = Ty + Num,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 3) -> %% 正X、负Y 45度
    LengthNum = round(Length * 0.7),
    WidthNum = round((Width*1.4-1)/2),
    SX = Tx, EX = Tx + WidthNum,
    SY = Ty - LengthNum, EY = Ty,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 4) -> %% 负Y方向
    Num = round((Width-1)/2),
    SX = Tx - Num, EX = Tx + Num,
    SY = Ty - Length, EY = Ty,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 5) -> %% 负X、负Y 45度
    LengthNum = round(Length * 0.7),
    WidthNum = round((Width*1.4-1)/2),
    SX = Tx - WidthNum, EX = Tx,
    SY = Ty - LengthNum, EY = Ty,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 6) -> %% 负X方向
    Num = round((Width-1)/2),
    SX = Tx - Length, EX = Tx,
    SY = Ty - Num, EY = Ty + Num,
    format_tiles(SX, EX, SY ,EY);
get_actors_front_map_tiles(Tx, Ty, Length, Width, 7) -> %% 负X、正Y 45度
    LengthNum = round(Length * 0.7),
    WidthNum = round((Width*1.4-1)/2),
    SX = Tx - WidthNum, EX = Tx,
    SY = Ty, EY = Ty + LengthNum,
    format_tiles(SX, EX, SY ,EY).

format_tiles(SX, EX, SY ,EY) ->
    lists:foldl(
        fun(X, Acc) ->
            lists:foldl(
                fun(Y, Acc0) ->
                    [{X, Y}|Acc0]
                end, Acc, lists:seq(SY, EY))
        end, [], lists:seq(SX, EX)).

