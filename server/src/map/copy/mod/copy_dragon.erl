%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2018 11:35
%%%-------------------------------------------------------------------
-module(copy_dragon).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").

%% API
-export([
    role_init/1,
    init/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{copy_level = CopyLevel} = CopyInfo,
    MapID = map_common_dict:get_map_id(),
    [#c_copy_evil{monster_type_id = TypeID, pos = Pos, mdir = MDir}] = lib_config:find(cfg_copy_dragon, MapID),
    [Mx, My] = Pos,
    BornPos = map_misc:get_pos_by_offset_pos(Mx, My, MDir),
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
    MonsterDatas = [MonsterData#r_monster{born_pos = BornPos}],
    mod_map_monster:born_monsters(MonsterDatas).