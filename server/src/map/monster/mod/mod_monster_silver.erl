%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     铜钱怪
%%% @end
%%% Created : 20. 四月 2018 9:45
%%%-------------------------------------------------------------------
-module(mod_monster_silver).
-author("laijichang").
-include("monster.hrl").

%% API
-export([
    loop/1,
    add_silver/3,
    monster_dead/1
]).

-export([
    get_random_silver_list/3
]).

loop(Now) ->
    List = mod_monster_data:get_monster_silver_list(),
    List2 = loop2(List, Now, []),
    mod_monster_data:set_monster_silver_list(List2).

loop2([], _Now, Acc) ->
    Acc;
loop2([MonsterSilver|R], Now, Acc) ->
    #r_monster_silver{monster_id = MonsterID, drop_time = DropTime, drop_silver = DropSilver} = MonsterSilver,
    case Now >= DropTime andalso DropSilver >= ?SILVER_DROP_PIECES * 2 of
        true ->
            ?TRY_CATCH(do_born_silver(MonsterID, DropSilver)),
            Acc2 = Acc;
        _ ->
            Acc2 = [MonsterSilver|Acc]
    end,
    loop2(R, Now, Acc2).

add_silver(MonsterData, SilverDrop, ReduceHp) ->
    #r_monster{monster_id = MonsterID, attr = Attr} = MonsterData,
    List = mod_monster_data:get_monster_silver_list(),
    Multi = act_double_copy:get_drop_multi(map_common_dict:get_map_id()),
    AddSilver = lib_tool:ceil(SilverDrop * Multi * ReduceHp/Attr#actor_fight_attr.max_hp),
    case lists:keytake(MonsterID, #r_monster_silver.monster_id, List) of
        {value, #r_monster_silver{drop_silver = DropSilver} = MonsterSilver, R} ->
            MonsterSilver2 = MonsterSilver#r_monster_silver{drop_silver = AddSilver + DropSilver},
            List2 = [MonsterSilver2|R];
        _ ->
            List2 = [#r_monster_silver{monster_id = MonsterID, drop_time = time_tool:now() + ?SILVER_DROP_TIME, drop_silver = AddSilver}]
    end,
    mod_monster_data:set_monster_silver_list(List2).

monster_dead(MonsterID) ->
    List = mod_monster_data:get_monster_silver_list(),
    case lists:keytake(MonsterID, #r_monster_silver.monster_id, List) of
        {value, #r_monster_silver{drop_silver = DropSilver}, List2} ->
            do_born_silver(MonsterID, DropSilver);
        _ ->
            List2 = List
    end,
    mod_monster_data:set_monster_silver_list(List2).

do_born_silver(MonsterID, DropSilver) ->
    #r_monster{type_id = TypeID} = mod_monster_data:get_monster_data(MonsterID),
    Pos = mod_map_ets:get_actor_pos(MonsterID),
    MonsterPos = map_misc:pos_encode(Pos),
    case DropSilver >= ?SILVER_DROP_PIECES * 2 of
        true ->
            %% 先把1/2分成八份作为保底，再把剩下的取一个平均值
            AverageList = lists:duplicate(?SILVER_DROP_PIECES, DropSilver div (?SILVER_DROP_PIECES * 2)),
            RemainNum = DropSilver - lists:sum(AverageList),
            RandomList = get_random_silver_list(RemainNum, AverageList, []),
            DropList = [
                #p_map_drop{
                    type_id = ?ITEM_SILVER,
                    num = RandomNum,
                    bind = true,
                    monster_pos = MonsterPos,
                    monster_type_id = TypeID} || RandomNum <- RandomList];
        _ ->
            DropList = [
                #p_map_drop{
                    type_id = ?ITEM_SILVER,
                    num = DropSilver,
                    bind = true,
                    monster_pos = MonsterPos,
                    monster_type_id = TypeID}]
    end,
    mod_map_monster:monster_drop_silver(DropList, Pos).

get_random_silver_list(Remain, [Silver], List) -> %% 最后一份
    [Remain + Silver|List];
get_random_silver_list(Remain, [Silver|R], List) ->
    Random = lib_tool:random(0, Remain),
    Remain2 = Remain - Random,
    Silver2 = Silver + Random,
    case Remain2 > 0 of
        true ->
            get_random_silver_list(Remain2, R, [Silver2|List]);
        _ ->
            [Silver2|R] ++ List
    end.


