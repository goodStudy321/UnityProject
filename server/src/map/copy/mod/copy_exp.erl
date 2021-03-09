%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     经验副本
%%% @end
%%% Created : 01. 九月 2017 16:53
%%%-------------------------------------------------------------------
-module(copy_exp).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("monster.hrl").
-include("proto/mod_role_copy.hrl").
-include("proto/copy_common.hrl").

%% 地图回调API
-export([
    role_init/1,
    init/1,
    handle/1,
    role_enter/1,
    monster_dead/1,
    copy_end/1
]).

%% 角色调用API
-export([
    get_cheer_config/1,
    role_auto_cheer/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = erlang:length( common_misc:get_global_string_list(?GLOBAL_COPY_EXP_MONSTER))},
    copy_data:set_copy_info(CopyInfo2),
    [ mod_role_copy:auto_cheer(RoleID) || RoleID <- mod_map_ets:get_in_map_roles()].

init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    [#c_copy_exp{
        monster_num = MonsterNum,
        interval = Interval,
        pos = StringPos}
    ] = lib_config:find(cfg_copy_exp, MapID),
    BornList = copy_misc:get_pos_list(StringPos),
    CopyWave = #r_copy_exp{
        born_num = MonsterNum,
        born_pos_list = BornList,
        born_time = Interval
    },
    CurProgress = 1,
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyWave, cur_progress = CurProgress},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress}]),
    born_wave_monster(CopyWave),
    TimeList = common_misc:get_global_string_list(?GLOBAL_COPY_EXP_MONSTER),
    [ erlang:send_after(Time * 1000, erlang:self(), {mod, copy_common, {mod, ?MODULE, add_wave}})|| {Time, _} <- TimeList, Time > 0].

handle({born_monster, CopyWave}) ->
    do_born_monster(CopyWave);
handle(add_wave) ->
    do_add_wave().

born_wave_monster(CopyWave) ->
    #r_copy_exp{born_time = Time} = CopyWave,
    erlang:send_after(Time * 1000, erlang:self(), {mod, copy_common, {mod, ?MODULE, {born_monster, CopyWave}}}).

role_enter(RoleID) ->
    #r_copy_role{cheer_list = CheerList} = copy_data:get_copy_role(RoleID),
    case CheerList =/= [] of
        true ->
            [ begin
                  #r_cheer_args{add_buff_id = AddBuffID} = get_cheer_config(ID),
                  BuffList = [ #buff_args{buff_id = AddBuffID, from_actor_id = RoleID}|| _Times <- lists:seq(1, CheerTimes)],
                  role_misc:add_buff(RoleID, BuffList)
              end|| #p_copy_cheer{id = ID, all_cheer_times = CheerTimes} <- CheerList];
        _ ->
            ok
    end,
    common_misc:unicast(RoleID, #m_copy_cheer_times_toc{cheer_list = CheerList}).

%% 怪物死亡马上刷下一只
monster_dead({_MapInfo, _SrcID, SrcType}) ->
    case SrcType of
        ?ACTOR_TYPE_ROLE ->
            #r_map_copy{mod_args = CopyWave, sub_progress = SubProgress} = CopyInfo = copy_data:get_copy_info(),
            SubProgress2 = SubProgress + 1,
            CopyInfo2 = CopyInfo#r_map_copy{sub_progress = SubProgress2},
            copy_data:set_copy_info(CopyInfo2),
            copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_SUB, val = SubProgress2}]),
            do_born_monster(CopyWave#r_copy_exp{born_num = 1});
        _ ->
            ok
    end.

copy_end(CopyInfo) ->
    #r_map_copy{
        map_id = MapID,
        enter_roles = EnterRoles} = CopyInfo,
    Now = time_tool:now(),
    [ mod_role_copy:copy_exp_end(EnterRoleID, MapID, Now) || EnterRoleID <- EnterRoles].

%% 第一波出生
do_born_monster(CopyWave) ->
    #r_copy_exp{born_num = BornNum, born_pos_list = BornPosList} = CopyWave,
    #r_map_copy{copy_level = CopyLevel, start_time = StartTime} = copy_data:get_copy_info(),
    Time = erlang:max(0, time_tool:now() - StartTime),
    TypeID = get_refresh_monster(Time, common_misc:get_global_string_list(?GLOBAL_COPY_EXP_MONSTER), 0),
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
    MonsterDatas = [{MonsterData#r_monster{born_pos = copy_misc:get_pos(BornPosList)}, ?SECOND_COUNTER} || _Index <- lists:seq(1, BornNum)],
    mod_map_monster:born_monsters(MonsterDatas).

do_add_wave() ->
    #r_map_copy{cur_progress = CurProgress} = CopyInfo = copy_data:get_copy_info(),
    CurProgress2 = CurProgress + 1,
    CopyInfo2 = CopyInfo#r_map_copy{cur_progress = CurProgress2},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}]).

get_cheer_config(ID) ->
    Key = ?IF(ID =:= ?CHEER_SKILL_ID_1, ?GLOBAL_COPY_EXP_COST, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [#c_global{string = Cost, list = [SilverTimes, MaxTimes]}] = lib_config:find(cfg_global, Key),
    #r_cheer_args{
        cost_list = common_misc:get_global_string_list(Cost),
        silver_times = SilverTimes,
        all_times = MaxTimes,
        add_buff_id = ?CHEER_BUFF_ID
    }.

role_auto_cheer({RoleID, SilverTimes, GoldTimes}) ->
    CopyRole = copy_data:get_copy_role(RoleID),
    AllTimes = SilverTimes + GoldTimes,
    CopyCheer = #p_copy_cheer{id = ?CHEER_SKILL_ID_1, silver_cheer_times = SilverTimes, all_cheer_times = AllTimes},
    copy_data:set_copy_role(RoleID, CopyRole#r_copy_role{cheer_list = [CopyCheer]}),
    role_enter(RoleID),
    ok.

get_refresh_monster(_Time, [], Acc) ->
    Acc;
get_refresh_monster(Time, [{NeedTime, TypeID}|R], Acc) ->
    case Time >= NeedTime of
        true ->
            get_refresh_monster(Time, R, TypeID);
        _ ->
            Acc
    end.