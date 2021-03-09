%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     妖魔岭
%%% @end
%%% Created : 19. 七月 2018 11:28
%%%-------------------------------------------------------------------
-module(copy_demon).
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

role_init(CopyInfo) ->
    #r_map_copy{copy_level = CopyLevel} = CopyInfo,
    List = cfg_copy_demon:list(),
    {_MonsterBuffList, _BuffList, MonsterDatas} = get_born_monsters(List, CopyLevel, [], [], []),
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = erlang:length(MonsterDatas)},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{copy_level = CopyLevel} = CopyInfo,
    List = cfg_copy_demon:list(),
    {MonsterBuffList, BuffList, MonsterDatas} = get_born_monsters(List, CopyLevel, [], [], []),
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = #r_copy_demon{buff_monster = MonsterBuffList}},
    copy_data:set_copy_info(CopyInfo2),
    mod_map_monster:born_monsters(MonsterDatas),
    erlang:send_after(?SECOND_MS, erlang:self(), {func, fun() -> mod_map_monster:all_add_buff(BuffList) end}).


get_born_monsters([], _CopyLevel, MonsterBuffAcc, BuffListAcc, MonsterDataAcc) ->
    {MonsterBuffAcc, BuffListAcc, MonsterDataAcc};
get_born_monsters([{_ID, Config}|R], CopyLevel, MonsterBuffAcc, BuffListAcc, MonsterDataAcc) ->
    #c_copy_demon{
        type_id = TypeID,
        num = BornNum,
        pos = StringPos,
        buff_list = BuffList
    } = Config,
    MonsterBuffAcc2 = ?IF(BuffList =/= [], [{TypeID, BuffList}|MonsterBuffAcc], MonsterBuffAcc),
    BuffListAcc2 =  [ #buff_args{buff_id = BuffID}|| BuffID <- BuffList] ++ BuffListAcc,
    BornList = copy_misc:get_pos_list(StringPos),
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
    MonsterDatas = [MonsterData#r_monster{born_pos = copy_misc:get_pos(BornList)} || _Index <- lists:seq(1, BornNum)],
    MonsterDataAcc2 = MonsterDatas ++ MonsterDataAcc,
    get_born_monsters(R, CopyLevel, MonsterBuffAcc2, BuffListAcc2, MonsterDataAcc2).

monster_dead({MapInfo, _SrcID, _SrcType}) ->
    #r_map_copy{mod_args = ModArgs} = copy_data:get_copy_info(),
    #r_copy_demon{buff_monster = BuffMonsters} = ModArgs,
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    case lists:keyfind(TypeID, 1, BuffMonsters) of
        {_, BuffIDList} ->
            mod_map_monster:all_remove_buff(BuffIDList);
        _ ->
            ok
    end.


