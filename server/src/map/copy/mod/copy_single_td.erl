%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 三月 2018 19:51
%%%-------------------------------------------------------------------
-module(copy_single_td).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("monster.hrl").

%% API
-export([
    role_init/1,
    init/1,
    monster_dead/1
]).

-export([
    get_td_pos_list/1
]).

role_init(CopyInfo) ->
    do_born_base(CopyInfo),
    do_born_defenders(CopyInfo),
    #r_map_copy{map_id = MapID} = CopyInfo,
    Refresh = get_refresh(MapID),
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = erlang:length(Refresh)},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{map_id = MapID, copy_level = CopyLevel} = CopyInfo,
    [First|_Remain] = Refresh = get_refresh(MapID),
    CurProgress = 1,
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Refresh, cur_progress = CurProgress, all_wave = erlang:length(Refresh)},
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress}]),
    copy_data:set_copy_info(CopyInfo2),
    do_born_monsters(CopyLevel, First).

monster_dead({MapInfo, _SrcID, _SrcType}) ->
    #r_map_actor{camp_id = CampID} = MapInfo,
    case CampID =:= ?DEFAULT_CAMP_MONSTER of
        true ->
            #r_map_copy{mod_args = ModArgs, cur_progress = CurProgress, copy_level = CopyLevel} = CopyInfo = copy_data:get_copy_info(),
            case ModArgs of
                [CopyWave|Remain] ->
                    #r_copy_single_td{remain_num = RemainNum, need_remain_num = NeedRemainNum} = CopyWave,
                    RemainNum2 = RemainNum - 1,
                    if
                        RemainNum2 =< NeedRemainNum andalso Remain =:= [] -> %% 最后一波，结束
                            copy_data:set_copy_info(CopyInfo#r_map_copy{mod_args = [], cur_progress = CurProgress}),
                            copy_common:do_copy_end(?COPY_SUCCESS);
                        RemainNum2 =< NeedRemainNum -> %% 准备生成下一波
                            [#r_copy_single_td{remain_num = ConfigNum} = NextWave|R] = Remain,
                            NextWave2 = NextWave#r_copy_single_td{remain_num = ConfigNum + RemainNum2},
                            Remain2 = [NextWave2|R],
                            CurProgress2 = CurProgress + 1,
                            copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}]),
                            do_born_monsters(CopyLevel, NextWave2),
                            CopyInfo2 = CopyInfo#r_map_copy{mod_args = Remain2, cur_progress = CurProgress2},
                            copy_data:set_copy_info(CopyInfo2);
                        true ->
                            CopyWave2 = CopyWave#r_copy_single_td{remain_num = RemainNum2},
                            ModArgs2 = [CopyWave2|Remain],
                            CopyInfo2 = CopyInfo#r_map_copy{mod_args = ModArgs2},
                            copy_data:set_copy_info(CopyInfo2)
                    end;
                _ ->
                    ?ERROR_MSG("没有对应的波数了，不应该出现在这里:~w", [CopyInfo])
            end;
        _ ->
            ok
    end.
%%%===================================================================
%%% Internal functions
%%%===================================================================
do_born_base(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    #r_map_copy{success_args = TypeID} = CopyInfo,
    Config = get_config_name(MapID),
    [#c_copy_single_td{target_pos = [Mx, My, MDir]}] = lib_config:find(Config, ?GET_WAVE_ID_BY_MAP(MapID) + 1),
    MonsterDatas = [
        #r_monster{
            type_id = TypeID,
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My, MDir)}],
    mod_map_monster:born_monsters(MonsterDatas).

do_born_defenders(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    Config = get_config_name(MapID),
    [#c_copy_single_td{defenders = Defenders}] = lib_config:find(Config, ?GET_WAVE_ID_BY_MAP(MapID) + 1),
    MonsterDatas = [
        #r_monster{
        type_id = TypeID,
        born_pos = map_misc:get_pos_by_offset_pos(Mx, My, MDir)} || {TypeID, Mx, My, MDir} <- lib_tool:string_to_intlist(Defenders)],
    mod_map_monster:born_monsters(MonsterDatas).


do_born_monsters(CopyLevel, SingleTD) ->
    #r_copy_single_td{
        area_1 = NewArea1,
        area_2 = NewArea2,
        area_3 = NewArea3} = SingleTD,
    do_do_born_monsters2(NewArea1, CopyLevel, ?ROUND_1_POS_LIST),
    do_do_born_monsters2(NewArea2, CopyLevel, ?ROUND_2_POS_LIST),
    do_do_born_monsters2(NewArea3, CopyLevel, ?ROUND_3_POS_LIST).

do_do_born_monsters2(AreaMonsters, CopyLevel, PosList) ->
    MonsterDatas = lists:flatten([
        [begin
             PosList2 = lib_tool:random_element_from_list(PosList),
             [{Mx, My}|R] = PosList2,
             MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
             MonsterData#r_monster{
                 born_pos = map_misc:get_random_pos_by_offset_meter(Mx, My),
                 td_pos_list = get_td_pos_list(R)}
         end|| _Num <- lists:seq(1, Num)]
        || {TypeID, Num} <- AreaMonsters]),
    mod_map_monster:born_monsters(MonsterDatas).


get_refresh(MapID) ->
    Config = get_config_name(MapID),
    AllList = Config:list(),
    List = [ WaveConfig|| {WaveID, WaveConfig} <- AllList, ?GET_MAP_BY_WAVE_ID(WaveID) =:= MapID],
    List2 = lists:keysort(#c_copy_single_td.wave_id, List),
    [begin
         #c_copy_single_td{
             area_1 = Area1,
             area_2 = Area2,
             area_3 = Area3,
             need_remain_num = NeedRemainNum
         } = Wave,
         {NewArea1, BornNum1} = get_area_monster(Area1),
         {NewArea2, BornNum2} = get_area_monster(Area2),
         {NewArea3, BornNum3} = get_area_monster(Area3),
         AllBornNum = BornNum1 + BornNum2 + BornNum3,
         #r_copy_single_td{
             area_1 = NewArea1,
             area_2 = NewArea2,
             area_3 = NewArea3,
             remain_num = AllBornNum,
             need_remain_num = NeedRemainNum
         }
     end || Wave <- List2].

get_area_monster(Area) ->
    get_area_monster2(string:tokens(Area, ";"), [], 0).

get_area_monster2([], MonsterAcc, BornNumAcc) ->
    {MonsterAcc, BornNumAcc};
get_area_monster2([MonsterString|R], MonsterAcc, BornNumAcc) ->
    [TypeID, Num] = string:tokens(MonsterString, ","),
    Num2 = lib_tool:to_integer(Num),
    MonsterAcc2 = [{lib_tool:to_integer(TypeID), Num2}|MonsterAcc],
    BornNumAcc2 = Num2 + BornNumAcc,
    get_area_monster2(R, MonsterAcc2, BornNumAcc2).

get_td_pos_list(R) ->
    [ begin
          #r_pos{tx = Tx, ty = Ty} = map_misc:get_pos_by_offset_pos(Mx, My),
          {Tx, Ty}
      end || {Mx, My} <- R].

get_config_name(MapID) ->
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    case CopyType of
        ?COPY_SINGLE_TD ->
            cfg_copy_single_td;
        ?COPY_MISSION_TD ->
            cfg_copy_mission_td
    end.