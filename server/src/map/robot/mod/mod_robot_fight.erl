%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 14:56
%%%-------------------------------------------------------------------
-module(mod_robot_fight).
-author("laijichang").

%% API
-include("world_robot.hrl").
-include("proto/mod_role_skill.hrl").

-export([
    fight/1
]).


%% ============================= 战斗 ============================
%% 怪物状态机触发战斗状态
fight(RobotData) ->
    #r_robot{buff_status = BuffStatus, robot_id = RobotID} =  RobotData,
    MapInfo = mod_map_ets:get_actor_mapinfo(RobotID),
    case catch mod_fight_etc:check_can_attack_buffs(BuffStatus) of
        true ->
            case catch fight2(RobotID, RobotData, MapInfo) of
                {ok, AddCounter, RobotData2}->
                    {ok, AddCounter, RobotData2};
                Error ->
                    ?ERROR_MSG("FIGHT error:~w Data:~w",[Error, RobotData]),
                    {ok, ?BLAME_COUNTER, RobotData}
            end;
        _ ->
            {ok, ?ONE_COUNTER, RobotData}
    end.

fight2(RobotID, RobotData, MapInfo)->
    FightArgs = RobotData#r_robot.fight_args,
    case common_skill:get_next_skill(FightArgs) of
        {next_prepare, Action, Remain} ->
            fight_prepare(RobotID, RobotData, {Action, Remain});
        {next_hurt, Action, Hurt, Remain} ->
            fight(RobotID, RobotData, MapInfo, {Action, Hurt, Remain});
        _ ->
            fight_prepare(RobotID, RobotData, undefined)
    end.

fight(RobotID, RobotData, MapInfo, FightInfo) ->
    #r_robot{last_attack_time = LastAttackTime} = RobotData,
    NowMs = time_tool:now_ms(),
    case FightInfo of
        {#r_skill_action{skill_id = SkillID}, #r_skill_hurt{delay = Time} = Hurt, Remain} when NowMs >= LastAttackTime + Time ->
            RobotPos = mod_map_ets:get_actor_pos(RobotID),
            RobotData2 = mod_robot_attack:update_enemy_lists(RobotData),
            ReturnData = RobotData2#r_robot{state = ?ROBOT_STATE_GUARD},
            DestActorID = mod_robot_attack:get_enemy(RobotData2),
            DestActorPos = mod_map_ets:get_actor_pos(DestActorID),
            ?IF(DestActorPos =:= undefined, ?ROBOT_RETURN(?ONE_COUNTER, ReturnData), ok),
            #c_skill{
                pos_type = PosType,
                attack_type = AttackType,
                range_args = RangeArgs} = common_skill:get_skill_config(SkillID),
            NewRobotPos = mod_monster_fight:get_direction_pos(RobotPos, DestActorPos),
            OtherList = mod_monster_fight:get_other_enemy(MapInfo, NewRobotPos, DestActorPos, AttackType, RangeArgs),
            SkillPos = common_skill:get_skill_pos(NewRobotPos, DestActorPos, PosType, []),
            %% 最多攻击5个目标
            attack_enemy(RobotID, SkillID, Hurt, lists:sublist([DestActorID|lists:delete(DestActorID, OtherList)], 5), SkillPos),
            RobotData3 = RobotData#r_robot{fight_args = Remain, last_attack_time = NowMs},
            ?ROBOT_RETURN(?ONE_COUNTER, RobotData3);
        _ ->
            ?ROBOT_RETURN(?ONE_COUNTER, RobotData)
    end.

fight_prepare(RobotID, RobotData, FightInfo) ->
    #r_robot{
        last_dest_pos = DestPos,
        last_skill = LastSkillID,
        last_skill_time= LastSkillTime,
        skill_list = SkillList,
        buff_status = BuffStatus} = RobotData,
    MoveSpeed = mod_robot:get_move_speed(RobotData),
    NowMs = time_tool:now_ms(),
    ?IF(is_common_cd(NowMs, LastSkillTime, LastSkillID), ?ROBOT_RETURN(?ONE_COUNTER, RobotData), ok),
    RobotPos = mod_map_ets:get_actor_pos(RobotID),

    RobotData2 = mod_robot_attack:update_enemy_lists(RobotData),
    DestActorID =  mod_robot_attack:get_enemy(RobotData2),
    DestActorPos = mod_map_ets:get_actor_pos(DestActorID),
    ReturnData = RobotData2#r_robot{state = ?ROBOT_STATE_GUARD},
    ?IF(DestActorPos =:= undefined, ?ROBOT_RETURN(?ONE_COUNTER, ReturnData), ok),
    {SkillList2, CanUse, AttAckDis, SkillConfig, Action, FightArgs} = try_robot_skill(FightInfo, SkillList, NowMs, BuffStatus),
    ?IF(CanUse, ok, ?ROBOT_RETURN(?ONE_COUNTER, RobotData2)),
    case check_next_step(RobotPos, DestActorPos, DestPos, AttAckDis, BuffStatus, MoveSpeed) of %% 目标点能攻击到玩家且当前不在目标点
        walk -> %% 继续朝目标走
            mod_robot_walk:start_walk(RobotPos, DestPos, RobotID, RobotData2);
        {walk, DestActorPos2} -> %% 改变目标走
            mod_robot_walk:start_walk(RobotPos, DestActorPos2, RobotID, RobotData2#r_robot{walk_path = []});
        attack -> %% 可以攻击了
            mod_robot_map:robot_stop(RobotID),
            #c_skill{skill_id = SkillID, bullet_speed = BulletSpeed} = SkillConfig,
            NewRobotPos = mod_monster_fight:get_direction_pos(RobotPos, DestActorPos),
            {ok, Counter} = attack_prepare(Action, BulletSpeed, RobotID, DestActorID, NewRobotPos, DestActorPos),
            LastSkillTime2 = ?IF(FightInfo =/= undefined, LastSkillTime, NowMs),
            RobotData3 = RobotData2#r_robot{
                last_skill = SkillID,
                last_skill_time = LastSkillTime2,
                fight_args = FightArgs,
                walk_path = [],
                skill_list = lists:reverse(lists:keysort(#r_robot_skill.skill_type, SkillList2))},
            ?ROBOT_RETURN(Counter, RobotData3);
        stay -> %% 我动不了
            ?ROBOT_RETURN(?BLAME_COUNTER, RobotData2)
    end.

check_next_step(RobotPos, DestActorPos, _DestPos, AttAckDis, BuffStatus, MoveSpeed)
    when MoveSpeed =:= 0 orelse ?IS_BUFF_IMPRISON(BuffStatus) ->
    case monster_misc:judge_in_distance(RobotPos, DestActorPos, AttAckDis + 2) of
        true -> attack;
        false -> stay
    end;
check_next_step(RobotPos, DestActorPos, DestPos, AttAckDis, _BuffStatus, _MoveSpeed) ->
    %% 当前位置能攻击到玩家且只有自己则攻击,或者是目标点也攻击
    %% 目标位置能攻击到玩家则继续走,否则找一个能攻击到玩家的最近位置（优先不被占位）
    case monster_misc:judge_in_distance(RobotPos, DestActorPos, AttAckDis + 2) of
        true -> %% 到达自己可攻击的范围
            attack;
        _ -> %% 先朝目标方向移动
            case map_misc:check_same_tile(DestPos, DestActorPos) of
                true -> %% 继续移动
                    walk;
                _ ->
                    {walk, DestActorPos}
            end
    end.

attack_prepare(Action, BulletSpeed, RobotID, DestActorID, RobotPos, DestActorPos)->
    #r_skill_action{skill_id = SkillID, hurt_list = HurtList, step_id = StepID} = Action,
    [#r_skill_hurt{delay = Delay}|_] = HurtList,
    case BulletSpeed > 0 of
        true ->
            #r_pos{mx = X1, my = Y1} = RobotPos,
            #r_pos{mx = X2, my = Y2} = DestActorPos,
            Delay2 = map_misc:get_dis(X1, Y1, X2, Y2) * 1000 / BulletSpeed,
            Counter = lib_tool:ceil((Delay + Delay2) / 100);
        _ ->
            Counter = lib_tool:ceil(Delay / 100)
    end,
    mod_map_robot:robot_fight_prepare(RobotID, DestActorID, SkillID, StepID, RobotPos, map_misc:pos_encode(RobotPos)),
    {ok, Counter - 2}.

attack_enemy(RobotID, SkillID, Hurt, DestList, SkillPos) ->
    #r_skill_hurt{self_effect = SelfEffects, enemy_effect = EnemyEffects} = Hurt,
    IntPos = map_misc:pos_encode(SkillPos),
    mod_map_robot:robot_fight(
        #fight_args{
            dest_id_list = DestList,
            skill_id = SkillID,
            enemy_effect_list = EnemyEffects,
            self_effect_list = SelfEffects,
            skill_pos = IntPos,
            src_id = RobotID,
            src_type = ?ACTOR_TYPE_ROBOT}),
    ok.

try_robot_skill(FightInfo, SkillList, NowMs, BuffStatus) ->
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
            try_robot_skill2(SkillList, [], NowMs, BuffStatus)
    end.

try_robot_skill2([], SkillAcc, _NowMS, _BuffStatus) ->
    {SkillAcc, false, 1, undefined, undefined, []};
try_robot_skill2([Skill|R], SkillAcc, NowMs, BuffStatus) ->
    #r_robot_skill{skill_id = SkillID, time = Time} = Skill,
    case NowMs >= Time andalso common_skill:check_skill_by_buff_status(SkillID, BuffStatus) of
        {ok, #c_skill{dis = Dis, cd = CD} = SkillConfig} ->
            Skill2 = Skill#r_robot_skill{time = NowMs + CD},
            [Action|_] = ActionList = common_skill:get_skill_action_list(SkillID),
            {SkillAcc ++ [Skill2|R], true, lib_tool:ceil(Dis/100) + 3, SkillConfig, Action, ActionList};
        _ ->
            try_robot_skill2(R, [Skill|SkillAcc], NowMs, BuffStatus)
    end.

is_common_cd(_NowMs, _LastSkillTime, 0) ->
    false;
is_common_cd(NowMs, LastSkillTime, LastSkillID) ->
    #c_skill{common_cd = CommonCD, action_cd = ActionCD} = common_skill:get_skill_config(LastSkillID),
    NowMs < LastSkillTime + CommonCD + ActionCD.
