%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     经验副本
%%% @end
%%% Created : 01. 九月 2017 16:53
%%%-------------------------------------------------------------------
-module(copy_tower).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("monster.hrl").

%% API
-export([
    role_init/1,
    init/1,
    role_dead/1,
    copy_end/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = erlang:length(get_monster_datas(CopyInfo))},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    MonsterDatas = get_monster_datas(CopyInfo),
    mod_map_monster:born_monsters(MonsterDatas).

get_monster_datas(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    [#c_copy_tower{
        monster_type = TypeID,
        num = BornNum,
        pos = StringPos}
    ] = lib_config:find(cfg_copy_tower, MapID),
    BornPosList = copy_misc:get_pos_list(StringPos),
    [
        begin
            Pos = copy_misc:get_pos(BornPosList),
            #r_monster{
                type_id = TypeID,
                born_pos = Pos#r_pos{mdir = 0}}
        end|| _Num <- lists:seq(1, BornNum)].

role_dead({_RoleID, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_FAILED).

copy_end(_CopyInfo) ->
    [mod_map_actor:add_hp(RoleID, 9999999999) || RoleID <- mod_map_ets:get_in_map_roles()].