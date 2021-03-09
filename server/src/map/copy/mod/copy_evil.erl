%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     心魔副本
%%% @end
%%% Created : 12. 七月 2018 17:13
%%%-------------------------------------------------------------------
-module(copy_evil).
-author("laijichang").
-include("monster.hrl").
-include("copy.hrl").

%% API
-export([
    role_init/1,
    init/1,
    role_dead/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

init(_CopyInfo) ->
    MapID = map_common_dict:get_map_id(),
    [#c_copy_evil{
        monster_type_id = TypeID,
        pos = StringPos,
        mdir = MDir}] = lib_config:find(cfg_copy_evil, MapID),
    BornPos = copy_misc:get_pos(copy_misc:get_pos_list(StringPos)),
    BornPos2 = BornPos#r_pos{mdir = MDir},
    MonsterDatas = [#r_monster{type_id = TypeID, born_pos = BornPos2}],
    mod_map_monster:born_monsters(MonsterDatas).

role_dead({_RoleID, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_FAILED).