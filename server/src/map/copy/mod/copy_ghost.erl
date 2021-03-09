%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     鬼王殿
%%% @end
%%% Created : 20. 七月 2018 11:35
%%%-------------------------------------------------------------------
-module(copy_ghost).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").

%% API
-export([
    role_init/1,
    init/1,
    monster_reduce_hp/1,
    monster_dead/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{copy_level = CopyLevel} = CopyInfo,
    MapID = map_common_dict:get_map_id(),
    [#c_copy_ghost{
        ghost_id = GhostID,
        pos = [Mx, My],
        hp_list = HpRateList}] = lib_config:find(cfg_copy_ghost, MapID),
    CopyGhost = #r_copy_ghost{ghost_type_id = GhostID, monster_num = 0, hp_list = lists:reverse(lists:sort(HpRateList))},
    BornPos = map_misc:get_pos_by_offset_pos(Mx, My),
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, GhostID),
    MonsterDatas = [MonsterData#r_monster{born_pos = BornPos}],
    mod_map_monster:born_monsters(MonsterDatas),
    copy_data:set_copy_info(CopyInfo#r_map_copy{mod_args = CopyGhost}).

monster_reduce_hp({MapInfo, _ReduceSrc, _ReduceHp}) ->
    #r_map_actor{hp = Hp, max_hp = MaxHp, monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    #r_map_copy{copy_level = CopyLevel, mod_args = CopyGhost} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_ghost{ghost_type_id = GhostID, monster_num = MonsterNum, hp_list = HpList} = CopyGhost,
    case GhostID =:= TypeID of
        true ->
            HpRate = lib_tool:ceil(?RATE_10000 * Hp/MaxHp),
            {HpList2, IsBorn} = check_monster_born(HpList, HpRate, []),
            case IsBorn of
                true ->
                    BornNum = do_born_monsters(CopyLevel),
                    mod_map_monster:type_add_buff(GhostID, [#buff_args{buff_id = 108002}]),
                    CopyGhost2 = CopyGhost#r_copy_ghost{monster_num = MonsterNum + BornNum, hp_list = lists:reverse(lists:sort(HpList2))},
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyGhost2},
                    copy_data:set_copy_info(CopyInfo2);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

monster_dead({_MapInfo, _SrcID, _SrcType}) ->
    #r_map_copy{mod_args = CopyGhost} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_ghost{ghost_type_id = GhostID, monster_num = MonsterNum} = CopyGhost,
    MonsterNum2 = MonsterNum - 1,
    ?IF(MonsterNum2 =:= 0, mod_map_monster:type_remove_buff(GhostID, 108002), ok),
    CopyGhost2 = CopyGhost#r_copy_ghost{monster_num = MonsterNum2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyGhost2},
    copy_data:set_copy_info(CopyInfo2).

do_born_monsters(CopyLevel) ->
    [#c_copy_ghost{summon_monsters = MonsterString}] = lib_config:find(cfg_copy_ghost, map_common_dict:get_map_id()),
    MonsterList = lib_tool:string_to_intlist(MonsterString),
    MonsterDatas =
        [ begin
              MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
              BornPos = map_misc:get_pos_by_offset_pos(Mx, My),
              MonsterData#r_monster{born_pos = BornPos}
          end|| {TypeID, Mx, My}<- MonsterList],
    mod_map_monster:born_monsters(MonsterDatas),
    erlang:length(MonsterList).


check_monster_born([], _HpRate, HpList) ->
    {HpList, false};
check_monster_born([NeedRate|R], HpRate, HpList) ->
    case HpRate =< NeedRate of
        true ->
            {HpList ++ R, true};
        _ ->
            check_monster_born(R, HpRate, [NeedRate|HpList])
    end.

