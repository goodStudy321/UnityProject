%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 五月 2017 14:34
%%%-------------------------------------------------------------------
-module(mod_monster_buff).
-author("laijichang").
-include("monster.hrl").

%%%% API
-export([
    add_buff/2,
    remove_buff/2,
    loop/1
]).

add_buff(MonsterID,  #buff_args{} = BuffArgs)->
    add_buff(MonsterID, [BuffArgs]);
add_buff(MonsterID, BuffList) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{} = MonsterData ->
            add_buff2(MonsterData, BuffList);
        _ ->
            ignore
    end.

add_buff2(_MonsterData, []) ->
    ok;
add_buff2(MonsterData, BuffList) ->
    #r_monster{monster_id = MonsterID, buffs = Buffs, debuffs = Debuffs} = MonsterData,
    MonsterList = mod_monster_data:get_monster_buff_list(),
    {Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList} = common_buff:add_buff(BuffList, Buffs, Debuffs),
    MonsterData2 = MonsterData#r_monster{buffs = Buffs2, debuffs = Debuffs2},
    case lists:member(MonsterID, MonsterList) of
        true -> ok;
        _ -> mod_monster_data:set_monster_buff_list([MonsterID|MonsterList])
    end,
    do_update(MonsterID, MonsterData2, Buffs2 ++ Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList).

remove_buff(MonsterID, BuffID) when erlang:is_integer(BuffID) ->
    remove_buff(MonsterID, [BuffID]);
remove_buff(MonsterID, BuffList) ->
    case mod_monster_data:get_monster_data(MonsterID) of
        #r_monster{} = MonsterData ->
            remove_buff2(MonsterData, BuffList);
        _ ->
            ignore
    end.

remove_buff2(_MonsterData, []) ->
    ok;
remove_buff2(MonsterData, BuffList) ->
    #r_monster{monster_id = MonsterID, buffs = Buffs, debuffs = Debuffs} = MonsterData,
    MonsterList = mod_monster_data:get_monster_buff_list(),
    {Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList} = common_buff:remove_buff(BuffList, Buffs, Debuffs),
    MonsterData2 = MonsterData#r_monster{buffs = Buffs2, debuffs = Debuffs2},
    case lists:member(MonsterID, MonsterList) andalso Buffs2 =:= [] andalso Debuffs2 =:= [] of
        true ->
            mod_monster_data:set_monster_buff_list(lists:delete(MonsterID, MonsterList));
        _ ->
            ok
    end,
    do_update(MonsterID, MonsterData2, Buffs2 ++ Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList).

loop(Now) ->
    MonsterList = mod_monster_data:get_monster_buff_list(),
    MonsterList2 =
        lists:foldl(
            fun(MonsterID, Acc) ->
                case ?TRY_CATCH(loop2(Now, MonsterID)) of
                    true ->
                        [MonsterID|Acc];
                    _->
                        Acc
                end
        end, [], MonsterList),
    mod_monster_data:set_monster_buff_list(MonsterList2).

loop2(Now, MonsterID) ->
    #r_monster{buffs = Buffs, debuffs = Debuffs} = MonsterData = mod_monster_data:get_monster_data(MonsterID),
    {Buffs2, Debuffs2, EffectList, IsCalc, IsStatus, DelIDList} = common_buff:loop(Now, Buffs, Debuffs),
    MonsterData2 = MonsterData#r_monster{buffs = Buffs2, debuffs = Debuffs2},
    AllBuffs = Buffs2 ++ Debuffs2,
    do_effect(MonsterID, MonsterData, EffectList),
    do_update(MonsterID, MonsterData2, AllBuffs, IsCalc, IsStatus, [], DelIDList),
    AllBuffs =/= [].

do_effect(_MonsterID, _MonsterData, []) ->
    ok;
do_effect(MonsterID, MonsterData, [Effect|R]) ->
    #r_monster{level = MonsterLevel, type_id = TypeID, attr = #actor_fight_attr{max_hp = MaxHp, attack = Attack}} = MonsterData,
    case Effect of
        {?BUFF_POISON, BuffID, FromActorID, Value} ->
            Value2 = mod_map_battle:get_battle_monster_reduce(TypeID, Value),
            mod_map_monster:monster_buff_reduce_hp(MonsterID, FromActorID, Value2, ?BUFF_POISON, BuffID);
        {?BUFF_BURN, BuffID, FromActorID, Value} ->
            Value2 = mod_map_battle:get_battle_monster_reduce(TypeID, Value),
            mod_map_monster:monster_buff_reduce_hp(MonsterID, FromActorID, Value2, ?BUFF_BURN, BuffID);
        {?BUFF_ADD_HP, BuffID, _FromActorID, Value} ->
            HealValue = lib_tool:ceil(MaxHp * Value/?RATE_10000),
            mod_map_monster:monster_buff_heal(MonsterID, HealValue, ?BUFF_ADD_HP, BuffID);
        {?BUFF_ATTACK_HEAL, BuffID, _FromActorID, Value} ->
            HealValue = lib_tool:ceil(Attack * Value/?RATE_10000),
            mod_map_monster:monster_buff_heal(MonsterID, HealValue, ?BUFF_ATTACK_HEAL, BuffID);
        {?BUFF_LEVEL_HP_BUFF, BuffID, _FromActorID, Value} ->
            HealValue = lib_tool:ceil(MonsterLevel * Value),
            mod_map_monster:monster_buff_heal(MonsterID, HealValue, ?BUFF_LEVEL_HP_BUFF, BuffID);
        Error ->
            ?ERROR_MSG("unknow match Error :~w", [Error])
    end,
    do_effect(MonsterID, MonsterData, R).

do_update(MonsterID, MonsterData, AllBuffs, IsCalc, IsStatus, UpdateList, DelIDList) ->
    case UpdateList =/= [] orelse DelIDList =/= [] of
        true ->
            AllBuffIDs = [ BuffID|| #r_buff{buff_id = BuffID} <- AllBuffs],
            UpdateIDList = [ BuffID || #r_buff{buff_id = BuffID} <- UpdateList],
            mod_map_monster:monster_update_buffs(MonsterID, AllBuffIDs, UpdateIDList, DelIDList);
        _ ->
            ok
    end,
    case IsStatus of
        true ->
            BuffStatus = common_buff:recal_status(AllBuffs),
            MonsterData2 = MonsterData#r_monster{buff_status = BuffStatus},
            mod_map_monster:monster_update_buff_status(MonsterID, BuffStatus);
        _ ->
            MonsterData2 = MonsterData
    end,
    case IsCalc of
        true ->
            monster_misc:recal_attr(MonsterData2);
        _ ->
            mod_monster_data:set_monster_data(MonsterID, MonsterData2)
    end.

