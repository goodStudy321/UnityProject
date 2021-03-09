%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2017 10:38
%%%-------------------------------------------------------------------
-module(mod_monster).
-author("laijichang").

%% API
-include("monster.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    init/1,
    loop_ms/1
]).

-export([
    init_monster/1,
    init_monster/2,
    init_monster/3,
    init_monster_i/2,
    init_monster_i/3,
    reborn_monster/1
]).

-export([
    monster_data_change/2
]).

init(MapID) ->
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{seqs = Seqs}] ->
            [begin
                 case lib_config:find(cfg_map_seq, SeqID) of
                     [#c_map_seq{monster_type_id = TypeID} = Seq] when TypeID > 0 ->
                         #c_map_seq{create_num = CreateNum, min_point = MinPoint, max_point = MaxPoint} = Seq,
                         [begin
                              BornPos = map_misc:get_seq_born_pos(MinPoint, MaxPoint),
                              MonsterData = #r_monster{
                                  seq_id = SeqID,
                                  born_pos = BornPos,
                                  type_id = TypeID},
                              case ?TRY_CATCH(init_monster(MonsterData, ?MIN_COUNTER)) of
                                  ok ->
                                      ok;
                                  _ ->
                                      ?ERROR_MSG("配置有误 Seq : ~w", [Seq])
                              end
                          end || _ <- lists:seq(1, CreateNum)];
                     _ ->
                         ok
                 end
             end || SeqID <- Seqs];
        _ ->
            ok
    end.

init_monster_i(MonsterData, HadInitAttr) ->
    init_monster_i(MonsterData, ?MIN_COUNTER, HadInitAttr).
init_monster_i(MonsterData, AddCounter, HadInitAttr) ->
    init_monster(MonsterData, AddCounter, mod_monster_data:get_new_monster_id(), HadInitAttr).
init_monster(MonsterData) ->
    init_monster(MonsterData, ?MIN_COUNTER).
init_monster(MonsterData, AddCounter) ->
    init_monster(MonsterData, AddCounter, mod_monster_data:get_new_monster_id(), false).
init_monster(MonsterData, AddCounter, NewID) ->
    init_monster(MonsterData, AddCounter, NewID, false).
init_monster(MonsterData, AddCounter, NewID, HadInitAttr) ->
    MonsterConfig = monster_misc:get_monster_config(MonsterData#r_monster.type_id),
    Now = time_tool:now(),
    #c_monster{
        rarity = Rarity,
        monster_name = MonsterName,
        camp_id = ConfigCampID,
        attack_speed = AttackSpeed,
        is_hatred = IsHatred,
        skill_list = SkillList
    } = MonsterConfig,
    SkillList2 = get_monster_skills(SkillList),
    CampID = MonsterData#r_monster.camp_id,
    CampID2 = ?IF(CampID =:= 0, ConfigCampID, CampID),
    CampID3 = ?IF(CampID2 =:= 0, ?DEFAULT_CAMP_MONSTER, CampID2),
    WorldBoss = ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, #r_monster_world_boss{}, undefined),
    NextCounter = mod_monster_data:get_loop_counter() + AddCounter,
    MonsterData2 = MonsterData#r_monster{
        monster_id = NewID,
        monster_name = MonsterName,
        state = ?MONSTER_STATE_BORN,
        next_counter = NextCounter,
        attack_speed = AttackSpeed,
        last_patrol_time = Now,
        camp_id = CampID3,
        born_time = Now,
        world_boss = WorldBoss,
        skill_list = SkillList2},
    MonsterData3 = ?IF(HadInitAttr, MonsterData2, monster_misc:init_base_attr(MonsterData2)),
    mod_monster_data:set_monster_data(NewID, MonsterData3),
    mod_monster_data:add_counter_monster(NewID, NextCounter),
    mod_monster_data:add_monster_id(NewID),
    ?IF(?IS_HATRED(IsHatred), mod_monster_data:add_hatred(NewID), ok),
    ?IF(Rarity =:= ?MONSTER_RARITY_WORLD_BOSS, mod_monster_data:add_world_boss(NewID), ok),
    monster_misc:recal_attr(NewID),
    ok.

reborn_monster(MonsterData) ->
    #r_monster{seq_id = SeqID} = MonsterData,
    case lib_config:find(cfg_map_seq, SeqID) of
        [#c_map_seq{monster_type_id = TypeID, refresh_interval = Refresh} = Seq] when TypeID > 0 andalso Refresh > 0 ->
            #c_map_seq{min_point = MinPoint, max_point = MaxPoint} = Seq,
            BornPos = map_misc:get_seq_born_pos(MinPoint, MaxPoint),
            MonsterData2 = #r_monster{
                seq_id = SeqID,
                born_pos = BornPos,
                born_time = time_tool:now(),
                type_id = TypeID},
            init_monster(MonsterData2, Refresh * 10);
        _ ->
            ok
    end.

loop_ms(_NowMs) ->
    Counter = mod_monster_data:get_loop_counter(),
    MonsterList = mod_monster_data:get_counter_monsters(Counter),
    [monster_work(MonsterID, Counter) || MonsterID <- MonsterList],
    mod_monster_data:erase_counter_monsters(Counter),
    mod_monster_data:set_loop_counter(Counter + 1),
    ok.

monster_work(MonsterID, Counter) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{} = MonsterData ->
            monster_work2(MonsterData, Counter);
        _ ->
            ignore
    end.

monster_work2(MonsterData, Counter) ->
    #r_monster{monster_id = MonsterID, state = State} = MonsterData,
    case State of
        ?MONSTER_STATE_BORN -> %% 异步发消息给map出生怪物
            mod_monster_map:monster_born(MonsterData);
        ?MONSTER_STATE_GUARD -> %% 正常警戒状态
            {ok, AddCounter, MonsterData2} = mod_monster_walk:guard(MonsterData),
            monster_work3(MonsterID, MonsterData2, Counter, AddCounter);
        ?MONSTER_STATE_PATROL -> %% 巡逻状态
            {ok, AddCounter, MonsterData2} = mod_monster_walk:patrol(MonsterData),
            monster_work3(MonsterID, MonsterData2, Counter, AddCounter);
        ?MONSTER_STATE_RETURN ->%% 回归状态
            {ok, AddCounter, MonsterData2} = mod_monster_walk:return(MonsterData),
            monster_work3(MonsterID, MonsterData2, Counter, AddCounter);
        ?MONSTER_STATE_FIGHT -> %% 战斗状态
            {ok, AddCounter, MonsterData2} = mod_monster_fight:fight(MonsterData),
            monster_work3(MonsterID, MonsterData2, Counter, AddCounter);
        ?MONSTER_STATE_TD -> %% TD移动状态
            {ok, AddCounter, MonsterData2} = mod_monster_walk:td_walk(MonsterData),
            monster_work3(MonsterID, MonsterData2, Counter, AddCounter)
    end.

monster_work3(MonsterID, MonsterData, Counter, AddCounter) ->
    %% 保证一定会循环到！！！
    AddCounter2 = erlang:max(AddCounter, 1),
    NextCounter = Counter + AddCounter2,
    MonsterData2 = MonsterData#r_monster{next_counter = NextCounter},
    mod_monster_data:set_monster_data(MonsterID, MonsterData2),
    mod_monster_data:add_counter_monster(MonsterID, Counter + AddCounter2).

monster_data_change(#r_monster{monster_id = MonsterID, state = OldState}, #r_monster{state = NewState}) ->
    if
        OldState =/= NewState andalso NewState =:= ?MONSTER_STATE_RETURN ->
            mod_map_monster:monster_update_status(MonsterID, ?MAP_STATUS_RETURN);
        OldState =/= NewState andalso OldState =:= ?MONSTER_STATE_RETURN ->
            mod_map_monster:monster_update_status(MonsterID, ?MAP_STATUS_NORMAL);
        true ->
            ok
    end;
monster_data_change(_, _) ->
    ok.


get_monster_skills(SkillList) ->
    lists:foldl(
        fun(SkillID, Acc) ->
            #c_skill{skill_type = SkillType} = common_skill:get_skill_config(SkillID),
            case SkillType =:= ?SKILL_ATTACK orelse SkillType =:= ?SKILL_NORMAL of
                true ->
                    [#r_monster_skill{skill_id = SkillID, skill_type = SkillType, time = 0}|Acc];
                _ ->
                    Acc
            end
        end, [], SkillList).