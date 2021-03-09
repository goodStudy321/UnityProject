%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     五行秘境
%%% @end
%%% Created : 22. 6月 2019 11:35
%%%-------------------------------------------------------------------
-module(copy_five_elements).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").

%% API
-export([
    role_init/1,
    role_dead/1,
    monster_dead/1
]).

role_init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    [#c_five_elements_detail{
        monster_type_id = TypeID,
        monster_pos = MonsterPos,
        monster_num = MonsterNum
        }] = lib_config:find(cfg_five_elements_detail, MapID),
    born_monster(TypeID, MonsterPos, MonsterNum),
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1, mod_args = MonsterNum, cur_progress = 0, sub_progress = 0},
    copy_data:set_copy_info(CopyInfo2).

role_dead({_RoleID, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_FAILED).

%% 怪物死亡
monster_dead({MapInfo, SrcID, _SrcType}) ->
    #r_map_actor{actor_id = ActorID, monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    case ActorID =:= SrcID of
        true ->
            ok;
        _ ->
            ?IF(monster_misc:is_normal_monster(TypeID), ok, [ mod_role_copy:five_element_boss_dead(RoleID, TypeID)|| RoleID <- mod_map_ets:get_in_map_roles()]),
            #r_map_copy{mod_args = NeedNum, sub_progress = SubProgress} = CopyInfo = copy_data:get_copy_info(),
            SubProgress2 = SubProgress + 1,
            CopyInfo2 = CopyInfo#r_map_copy{sub_progress = SubProgress2},
            copy_data:set_copy_info(CopyInfo2),
            UpdateList = [#p_kv{id = ?COPY_UPDATE_SUB, val = SubProgress2}],
            copy_common:broadcast_update(UpdateList),
            ?IF(SubProgress >= NeedNum, copy_common:do_copy_end(?COPY_SUCCESS), ok)
    end.

born_monster(TypeID, PosString, BornNum) ->
    BornList = copy_misc:get_pos_list(PosString),
    MonsterDatas = [#r_monster{type_id = TypeID, born_pos = copy_misc:get_pos(BornList)} || _Index <- lists:seq(1, BornNum)],
    mod_map_monster:born_monsters(MonsterDatas).



