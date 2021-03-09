%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 五月 2017 10:09
%%%-------------------------------------------------------------------
-module(mod_monster_map).
-author("laijichang").
-include("monster.hrl").
-include("battle.hrl").
-include("proto/copy_single.hrl").

%% API
%% info到map时，需要额外判断的接口
-export([
    monster_born/1,
    monster_stop/1
]).

%% map进程回调
-export([
    enter_map/1,
    reduce_hp/4,
    dead/2,
    map_change_pos/2,
    born_monsters/1,
    born_monsters/2,
    summon_monsters/1,
    single_ai/4,
    delete_monsters/0,
    td_change_pos/1,
    immortal_delete_guard/1,
    immortal_add_buff/1,
    type_add_buff/2,
    type_remove_buff/2,
    gm_delete_monsters/1,
    gm_delete_monster/2,
    gm_all_monster/0
]).

-export([
    handle/1
]).

handle(_Info) ->
    ok.

%%%===================================================================
%%% to map start
%%%===================================================================
monster_born(MonsterData) ->
    {MapInfo, Attr} = make_map_info(MonsterData),
    Self = self(),
    mod_map_monster:monster_enter_map(MapInfo, Attr, Self).

make_map_info(MonsterData) ->
    #r_monster{monster_id = MonsterID, born_pos = Pos, attr = Attr, camp_id = CampID, type_id = TypeID, level = Level,
                monster_name = MonsterName, action_string = ActionString, battle_owner = BattleOwner} = MonsterData,
    MoveSpeed = monster_misc:get_move_speed(MonsterData),
    MapInfo = #r_map_actor{
        actor_id = MonsterID,
        actor_type = ?ACTOR_TYPE_MONSTER,
        actor_name = MonsterName,
        pos = map_misc:pos_encode(Pos),
        hp = Attr#actor_fight_attr.max_hp,
        max_hp = Attr#actor_fight_attr.max_hp,
        camp_id = CampID,
        move_speed = MoveSpeed,
        monster_extra = #p_map_monster{type_id = TypeID, action_string = ActionString, level = Level, battle_owner = BattleOwner}},
    {MapInfo, Attr}.

monster_stop(MonsterID) ->
    case mod_map_ets:get_actor_mapinfo(MonsterID) of
        #r_map_actor{target_pos = TargetPos} ->
            case TargetPos > 0 of
                true ->
                    mod_map_monster:monster_stop(MonsterID);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
%%%===================================================================
%%% to map end
%%%===================================================================


%%%===================================================================
%%% from map start
%%%===================================================================
enter_map(MonsterID) ->
    MonsterData = mod_monster_data:get_monster_data(MonsterID),
    #c_monster{born_delay = BornDelay} = monster_misc:get_monster_config(MonsterData#r_monster.type_id),
    AddCounter = erlang:max(BornDelay div 100, ?MIN_COUNTER),
    NextCounter = mod_monster_data:get_loop_counter() + AddCounter,
    State = ?IF(monster_misc:is_td_move(MonsterData), ?MONSTER_STATE_TD, ?MONSTER_STATE_GUARD),
    mod_monster_data:set_monster_data(MonsterID, MonsterData#r_monster{state = State, next_counter = NextCounter}),
    mod_monster_data:add_counter_monster(MonsterID, NextCounter).

reduce_hp(MonsterID, ReduceSrc, ReduceHp, RemainHp) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{} ->
            mod_monster_attack:reduce_hp(MonsterID, ReduceSrc, ReduceHp, RemainHp);
        _ ->
            ok
    end.

dead(MonsterID, ReduceSrc) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcType} = ReduceSrc,
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{type_id = ?BATTLE_MONSTER} -> %% 战场聚灵碑文
            mod_map_monster:battle_monster_dead(MonsterID, SrcID, SrcType);
        #r_monster{state = State, next_counter = NextCounter, td_index = TDIndex} = MonsterData ->
            ?TRY_CATCH(hook_monster:monster_dead(MonsterData, ReduceSrc)),
            mod_monster_data:del_monster_id(MonsterID),
            mod_monster_data:del_hatred(MonsterID),
            mod_monster_data:del_world_boss(MonsterID),
            mod_monster_data:del_monster_data(MonsterID),
            mod_monster_data:del_monster_buff_list(MonsterID),
            mod_monster_data:del_counter_monster(MonsterID, NextCounter),
            DeadArgs = #r_actor_dead{src_id = SrcID, src_type = SrcType, extra_args = #r_monster_dead{td_index = TDIndex}},
            ?IF(State =:= ?MONSTER_STATE_BORN, ok, mod_map_monster:monster_dead_ack(MonsterID, DeadArgs)),
            mod_monster:reborn_monster(MonsterData);
        _ -> %% 加这个是避免出现2条dead消息时会报错
            ok
    end.

map_change_pos(MonsterID, _RecordPos) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{next_counter = NextCounter} = MonsterData ->
            mod_monster_data:del_counter_monster(MonsterID, NextCounter),
            NextCounter2 = mod_monster_data:get_loop_counter() + ?SECOND_COUNTER,
            mod_monster_data:add_counter_monster(MonsterID, NextCounter2),
            mod_monster_data:set_monster_data(MonsterID, MonsterData#r_monster{walk_path = [], next_counter = NextCounter2});
        _ ->
            ok
    end.

%% 按波次刷怪召唤
born_monsters(MonsterList) ->
    [ begin
          case MonsterArgs of
          {MonsterData, Counter} ->
              mod_monster:init_monster(MonsterData, Counter);
          _ ->
              mod_monster:init_monster(MonsterArgs)
          end
      end || MonsterArgs <- MonsterList].

%% 按波次刷怪召唤
born_monsters(MonsterList,HadInitAttr) ->
    [ begin
          case MonsterArgs of
          {MonsterData, Counter} ->
              mod_monster:init_monster_i(MonsterData, Counter,HadInitAttr);
          _ ->
              mod_monster:init_monster_i(MonsterArgs,HadInitAttr)
          end
      end || MonsterArgs <- MonsterList].

%% 单人副本发起的召唤怪物
summon_monsters(MonsterList) ->
    [ begin
          #c_monster{single_type = IsSingle} =  monster_misc:get_monster_config(TypeID),
          case IsSingle =:= ?MONSTER_SINGLE_COPY of
              true ->
                  MonsterData = #r_monster{
                      monster_id = MonsterID,
                      type_id = TypeID,
                      born_pos = map_misc:pos_decode(IntPos),
                      action_string = ActionString
                  },
                  dead(MonsterID, #r_reduce_src{actor_id = MonsterID, actor_type = ?ACTOR_TYPE_MONSTER}),
                  mod_monster:init_monster(MonsterData, ?MIN_COUNTER, MonsterID);
              _ ->
                  ok
          end
      end || #p_single_summon{actor_id = MonsterID, type_id = TypeID, pos = IntPos, action_string = ActionString} <- MonsterList].


single_ai(RoleID, MonsterID, Type, Args) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{} = MonsterData ->
            if
                Type =:= ?SINGLE_AI_STOP ->
                    mod_monster_ai:stop_action(MonsterData);
                Type =:= ?SINGLE_AI_START ->
                    mod_monster_ai:start_action(MonsterData);
                Type =:= ?SINGLE_AI_MOVE ->
                    mod_monster_ai:single_move(MonsterData, Args);
                Type =:= ?SINGLE_AI_DEAD ->
                    dead(MonsterID, #r_reduce_src{actor_id = RoleID, actor_type = ?ACTOR_TYPE_MONSTER});
                Type =:= ?SINGLE_AI_ATTACK ->
                    mod_monster_ai:attack_lock(MonsterData, Args);
                true ->
                    ok
            end;
        _ ->
            ok
    end.

delete_monsters() ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ dead(MonsterID, #r_reduce_src{actor_id = MonsterID, actor_type = ?ACTOR_TYPE_MONSTER}) || MonsterID <- MonsterList].

td_change_pos({Area, PosList}) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{state = Status, td_index = TDIndex, td_pos_list = OldPosList} = MonsterData = mod_monster_data:get_monster_data(MonsterID),
          case TDIndex =:= Area of
              true ->
                  Status2 = ?IF(Status =:= ?MONSTER_STATE_BORN, Status, ?MONSTER_STATE_TD),
                  MonsterData2 = MonsterData#r_monster{state = Status2, td_pos_list = OldPosList ++ PosList},
                  mod_monster_data:set_monster_data(MonsterID, MonsterData2),
                  ok;
              _ ->
                  ok
          end
    end || MonsterID <- MonsterList].

immortal_delete_guard(Index) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{td_index = TDIndex} = mod_monster_data:get_monster_data(MonsterID),
          ?IF(Index =:= 0 orelse TDIndex =:= Index, dead(MonsterID, #r_reduce_src{actor_id = MonsterID, actor_type = ?ACTOR_TYPE_MONSTER}), ok)
      end || MonsterID <- MonsterList].

immortal_add_buff(BuffList) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{td_index = TDIndex} = mod_monster_data:get_monster_data(MonsterID),
          ?IF(TDIndex > 0, mod_monster_buff:add_buff(MonsterID, BuffList), ok)
      end || MonsterID <- MonsterList].

type_add_buff(TypeID, BuffList) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{type_id = MonsterTypeID} = mod_monster_data:get_monster_data(MonsterID),
          case MonsterTypeID =:= TypeID orelse TypeID =:= 0 of
              true ->
                  mod_monster_buff:add_buff(MonsterID, BuffList);
              _ ->
                  ok
          end
      end || MonsterID <- MonsterList].

type_remove_buff(TypeID, BuffList) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{type_id = MonsterTypeID} = mod_monster_data:get_monster_data(MonsterID),
          case MonsterTypeID =:= TypeID orelse TypeID =:= 0 of
              true ->
                  mod_monster_buff:remove_buff(MonsterID, BuffList);
              _ ->
                  ok
          end
      end || MonsterID <- MonsterList].

gm_delete_monsters(RoleID) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ dead(MonsterID, #r_reduce_src{actor_id = RoleID, actor_type = ?ACTOR_TYPE_ROLE}) || MonsterID <- MonsterList].

gm_delete_monster(RoleID, TypeID) ->
    MonsterList = mod_monster_data:get_monster_id_list(),
    [ begin
          #r_monster{type_id = MonsterTypeID} = mod_monster_data:get_monster_data(MonsterID),
          case MonsterTypeID =:= TypeID of
              true ->
                  dead(MonsterID, #r_reduce_src{actor_id = RoleID, actor_type = ?ACTOR_TYPE_ROLE});
              _ ->
                  ok
          end
      end|| MonsterID <- MonsterList].

gm_all_monster()->
    MonsterList = mod_monster_data:get_monster_id_list(),
    MonsterDataList = [  mod_monster_data:get_monster_data(MonsterID)|| MonsterID <- MonsterList],
    ?ERROR_MSG("-----MonsterDataList-------------~w",[MonsterDataList]),
    MonsterDataList.

%%%===================================================================
%%% from map end
%%%===================================================================
