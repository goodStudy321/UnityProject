%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     藏宝图-击杀boss
%%% @end
%%% Created : 22. 三月 2019 17:23
%%%-------------------------------------------------------------------
-module(copy_treasure_boss).
-author("laijichang").
-include("copy.hrl").
-include("monster.hrl").
-include("team.hrl").
-include("hunt_treasure.hrl").

%% API
-export([
    role_init/1,
    init/1,
    monster_dead/1
]).

-export([
    do_event_reward/0,
    get_treasure_args/3
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    #r_map_team{captain_role_id = CaptainRoleID} = mod_map_dict:get_map_params(),
    %% 单服玩法，可以直接调用
    RoleLevel = common_role_data:get_role_level(CaptainRoleID),
    ConfigList = lib_config:list(cfg_hunt_treasure_event),
    {BossTypeID, BornPos} = get_boss_type_id(ConfigList, MapID, RoleLevel),
    MonsterDatas = [ #r_monster{
        type_id = BossTypeID,
        born_pos = BornPos}],
     mod_map_monster:born_monsters(MonsterDatas).

monster_dead({_MapInfo, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_SUCCESS),
    do_event_reward().

do_event_reward() ->
    #r_map_team{captain_role_id = CaptainRoleID, role_id_list = RoleList} = mod_map_dict:get_map_params(),
    mod_role_hunt_treasure:do_event_item_reward(get_event_id(), CaptainRoleID, RoleList).

get_boss_type_id([{_EventID, Config}|R], MapID, RoleLevel) ->
    #c_hunt_treasure_event{
        boss_string = BossString,
        map_id = ConfigMapID,
        boss_pos = PosString} = Config,
    case ConfigMapID =:= MapID of
        true ->
            BossList = lib_tool:string_to_intlist(BossString, "|", ","),
            BossTypeID = get_treasure_args(BossList, RoleLevel, []),
            {BossTypeID, copy_misc:get_pos(copy_misc:get_pos_list(PosString))};
        _ ->
            get_boss_type_id(R, MapID, RoleLevel)
    end.

get_treasure_args([], _RoleLevel, WeightAcc) ->
    lib_tool:get_weight_output(WeightAcc);
get_treasure_args([{ID, MinLevel, MaxLevel, Weight}|R], RoleLevel, WeightAcc) ->
    case MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel of
        true ->
            get_treasure_args(R, RoleLevel, [{Weight, ID}|WeightAcc]);
        _ ->
            get_treasure_args(R, RoleLevel, WeightAcc)
    end.

get_event_id() ->
    MapID = map_common_dict:get_map_id(),
    get_event_id2(lib_config:list(cfg_hunt_treasure_event), MapID).

get_event_id2([{EventID, #c_hunt_treasure_event{map_id = ConfigMapID}}|R], MapID) ->
    ?IF(ConfigMapID =:= MapID, EventID, get_event_id2(R, MapID)).
