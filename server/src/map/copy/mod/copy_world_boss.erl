%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 二月 2018 16:08
%%%-------------------------------------------------------------------
-module(copy_world_boss).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("world_boss.hrl").
-include("monster.hrl").

%% API
-export([
    role_init/1,
    init/1,
    monster_dead/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

init(_CopyInfo) ->
    MapID = map_common_dict:get_map_id(),
    [begin
         #c_copy_world_boss{
             monster_type = TypeID,
             num = BornNum,
             pos = PosList
         } = Config,
         BornPosList = copy_misc:get_pos_list(PosList),
         MonsterDatas = [ #r_monster{
             type_id = TypeID,
             born_pos = copy_misc:get_pos(BornPosList)} || _Num <- lists:seq(1, BornNum)],
         mod_map_monster:born_monsters(MonsterDatas)
     end || {BossMapID, Config}<- cfg_copy_world_boss:list(), BossMapID =:= MapID].

monster_dead({MapInfo, SrcID, _SrcType}) ->
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    role_server:kill_world_boss(SrcID, TypeID).