%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_ai_fight).

-include("robot.hrl").
-include("global.hrl").
-include("proto/mod_map_role_move.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_fight.hrl").
-include("proto/mod_role_skill.hrl").

-export([
    fight/1,
    fight_condition/1
]).

-define(FIGHT_CD, 400).
-define(SEQ_CD, 3000).
-define(ATTACK_DIS, 5).
-define(NORMAL_ATTACK, 1001001).

-define(TYPE_AUTO_FIGHT, 1). %% 被攻击时反击, 无敌人时自动寻找可攻击的目标
-define(TYPE_FIGHT_BACK, 2). %% 被攻击时反击
-define(MAX_MOVE_TIMES, 3). %% %% 如果移动的太多,重新再找敌人

fight_condition(FightSec) ->
    NowPos = robot_data:get_now_pos(),
    MapID = robot_data:get_map_id(),
    #r_pos{tx = Tx, ty = Ty} = map_misc:pos_decode(NowPos),
    #c_map_tile{is_safe = IsSafe} = map_base_data:get_tile(Tx, Ty),
    IsFight =
        if
            FightSec =:= 0 ->
                true;
            true ->
                fight_condition2(FightSec)
        end,
    if
        MapID =:= ?MAP_BATTLE orelse ?IS_MAP_SUMMIT_TOWER(MapID) ->
            not IsSafe andalso IsFight;
        true ->
            IsFight
    end.

fight_condition2(FightSec) ->
    Now = time_tool:now(),
    case robot_data:get_fight_condition() of
        {?ROBOT_FIGHT_FIGHT, LastTime} ->
            case Now >= LastTime of
                true ->
                    robot_data:set_fight_condition({?ROBOT_FIGHT_OTHER, Now + FightSec}),
                    false;
                _ ->
                    true
            end;
        {?ROBOT_FIGHT_OTHER, LastTime} ->
            case Now >= LastTime of
                true ->
                    robot_data:set_fight_condition(FightSec),
                    true;
                _ ->
                    false
            end;
        _ ->
            robot_data:set_fight_condition(FightSec),
            true
    end.

add_fight_condition() ->
    case robot_data:get_fight_condition() of
        {?ROBOT_FIGHT_FIGHT, _LastTime} ->
            ok;
        FightSec when erlang:is_integer(FightSec) ->
            robot_data:set_fight_condition({?ROBOT_FIGHT_FIGHT, time_tool:now() + FightSec});
        _ ->
            ok
    end.

fight(Type) ->
    NowMs = time_tool:now_ms(),
    LastTime = robot_data:get_last_skill_time(),
    MapID = robot_data:get_map_id(),
    case catch get_fight_targets(MapID, Type) of
        {ok, Enemy, NewPos, DestPos} ->
            robot_data:set_enemy(Enemy),
            add_fight_condition(),
            Skills = robot_data:get_fight_skills(),
            case common_skill:get_next_skill(Skills) of
                {next_prepare, Action, FightArgs} ->
                    robot_data:set_fight_skills(FightArgs),
                    robot_data:set_last_skill_time(NowMs),
                    attack_prepare(Enemy, Action, NewPos);
                {next_hurt, Action, Hurt, FightArgs} ->
                    #r_skill_hurt{delay = Delay} = Hurt,
                    case NowMs >= LastTime + Delay of
                        true ->
                            attack(Action, Enemy, DestPos),
                            robot_data:set_fight_skills(FightArgs),
                            robot_data:set_last_skill_time(NowMs);
                        _ ->
                            ok
                    end;
                _ ->
                    RoleSkills = robot_data:get_skills(),
                    {SkillID, RoleSkills2} = get_fight_skills(NowMs, RoleSkills, []),
                    [Action|_] = FightArgs = common_skill:get_skill_action_list(SkillID),
                    robot_data:set_skills(RoleSkills2),
                    robot_data:set_fight_skills(FightArgs),
                    robot_data:set_last_skill_time(NowMs),
                    attack_prepare(Enemy, Action, NewPos)
            end,
            robot_data:set_now_pos(NewPos),
            true;
        {go_to_pos, Enemy, DestPos} ->
            robot_data:set_enemy(Enemy),
            robot_ai_move:fight_move(DestPos);
        _ ->
            robot_data:erase_enemy(),
            false
    end.

get_fight_targets(MapID, _Type) when MapID =:= ?MAP_SOLO orelse ?IS_MAP_SUMMIT_TOWER(MapID) ->
    Enemy = robot_data:get_enemy(),
    Pos = robot_data:get_now_pos(),
    case robot_data:get_actor(Enemy) of
        #p_map_actor{pos = DestPos, status = Status} when Status =/= ?MAP_STATUS_DEAD ->
            get_fight_targets3(Pos, DestPos, Enemy);
        _ ->
            ActorIDs = robot_data:get_actor_ids(),
            get_fight_targets2(0, Pos, ActorIDs)
    end;
get_fight_targets(_MapID, _Type) ->
    CampID = robot_data:get_camp_id(),
    Enemy = robot_data:get_enemy(),
    Pos = robot_data:get_now_pos(),
    case robot_data:get_actor(Enemy) of
        #p_map_actor{pos = DestPos, status = Status, camp_id = DestCampID} when Status =/= ?MAP_STATUS_DEAD andalso
            DestCampID =/= ?BATTLE_CAMP_NORMAL andalso CampID =/= DestCampID ->
            get_fight_targets3(Pos, DestPos, Enemy);
        _ ->
            ActorIDs = robot_data:get_actor_ids(),
            get_fight_targets2(CampID, Pos, ActorIDs)
    end.

get_fight_targets2(_CampID, _Pos, []) ->
    false;
get_fight_targets2(CampID, Pos, [ActorID|R]) ->
    #p_map_actor{actor_type = ActorType, camp_id = DestCampID, pos = TargetPos} = robot_data:get_actor(ActorID),
    case lists:member(ActorType, ?ATTACK_LIST) andalso CampID =/= DestCampID of
        true ->
            get_fight_targets3(Pos, TargetPos, ActorID);
        _ ->
            get_fight_targets2(CampID, Pos, R)
    end.

get_fight_targets3(Pos, DestPos, Enemy) ->
    Pos2 = map_misc:pos_decode(Pos),
    DestPos2 = map_misc:pos_decode(DestPos),
    MDir = map_misc:get_direction(Pos2, DestPos2),
    NewPos = map_misc:pos_encode(Pos2#r_pos{mdir = MDir}), %% todo 之后可以考虑加上技能的位移
    case monster_misc:judge_in_distance(Pos2, DestPos2, ?ATTACK_DIS) of
        true ->
            robot_data:set_move_times(0),
            erlang:throw({ok, Enemy, NewPos, DestPos});
        _ ->
            MoveTimes = robot_data:get_move_times(),
            robot_data:set_move_times(MoveTimes + 1),
            case MoveTimes >= ?MAX_MOVE_TIMES of
                true ->
                    robot_data:set_move_times(0),
                    erlang:throw({another_enemy});
                _ ->
                    DestPos3 = get_random_dest_pos(DestPos2),
                    erlang:throw({go_to_pos, Enemy, DestPos3})
            end
    end.

get_fight_skills(_NowMs, [], SkillsAcc) ->
    {?NORMAL_ATTACK, SkillsAcc};
get_fight_skills(NowMs, [#p_skill{skill_id = SkillID, time = Time} = Skill|R], SkillsAcc) ->
    case NowMs >= Time of
        true ->
            #c_skill{cd = CD} = common_skill:get_skill_config(SkillID),
            Skill2 = Skill#p_skill{time = NowMs + CD},
            {SkillID, SkillsAcc ++ [Skill2|R]};
        _ ->
            get_fight_skills(NowMs, R, [Skill|SkillsAcc])
    end.

get_random_dest_pos(DestPos) ->
    AddList = lists:seq(-4, 4),
    #r_pos{tx = Tx, ty = Ty} = DestPos,
    {Tx2, Ty2} = get_random_dest_pos2(Tx, Ty, AddList, 5),
    DestPos#r_pos{tx = Tx2, ty = Ty2}.

get_random_dest_pos2(Tx, Ty, _AddList, 0) ->
    {Tx, Ty};
get_random_dest_pos2(Tx, Ty, AddList, Times) ->
    Random1 = lib_tool:random_element_from_list(AddList),
    Random2 = lib_tool:random_element_from_list(AddList),
    Tx2 = Tx + Random1, Ty2 = Ty + Random2,
    case map_base_data:is_exist(Tx + Random1, Ty + Random2) of
        true -> {Tx2, Ty2};
        _ -> get_random_dest_pos2(Tx, Ty, AddList, Times - 1)
    end.

attack_prepare(Enemy, Action, SrcPos) ->
    #r_skill_action{skill_id = SkillID, step_id = StepID} = Action,
    DataRecord =
        #m_fight_prepare_tos{
            skill_id = SkillID,
            dest_id = Enemy,
            step_id = StepID,
            src_pos= SrcPos},
    robot_client:send_data(DataRecord).

attack(Action, Enemy, DestPos) ->
    #r_skill_action{skill_id = SkillID} = Action,
    DataRecord = #m_fight_attack_tos{
        skill_id = SkillID,
        dest_id_list = [Enemy],
        skill_pos = DestPos
    },
    robot_client:send_data(DataRecord).
