%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 三月 2019 19:56
%%%-------------------------------------------------------------------
-module(copy_treasure_wave).
-author("laijichang").
-include("copy.hrl").
-include("monster.hrl").
-include("team.hrl").
-include("hunt_treasure.hrl").
-include("proto/mod_role_copy.hrl").
-include("proto/copy_common.hrl").


%% API
-export([
    role_init/1,
    init/1,
    handle/1,
    monster_dead/1,
    role_enter/1
]).

-export([
    get_cheer_config/1,
    born_wave_monster/1
]).

role_init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    Refresh = get_refresh(MapID),
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Refresh, all_wave = erlang:length(Refresh)},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{mod_args = Refresh} = CopyInfo,
    [First|_Remain] = Refresh,
    CurProgress = 1,
    CopyInfo2 = CopyInfo#r_map_copy{cur_progress = CurProgress},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress}]),
    born_wave_monster(First).

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

handle({born_monster, CopyWave}) ->
    do_born_monster(CopyWave).

born_wave_monster(CopyWave) ->
    #r_copy_wave{born_time = Time} = CopyWave,
    erlang:send_after(Time * 1000, erlang:self(), {mod, copy_common, {mod, ?MODULE, {born_monster, CopyWave}}}).

monster_dead({_MapInfo, _SrcID, _SrcType}) ->
    #r_map_copy{mod_args = ModArgs, cur_progress = CurProgress} = CopyInfo = copy_data:get_copy_info(),
    case ModArgs of
        [CopyWave|Remain] ->
            #r_copy_wave{kill_num = KillNum, born_num = BornNum} = CopyWave,
            KillNum2 = KillNum + 1,
            if
                KillNum2 >= BornNum andalso Remain =:= [] -> %% 最后一波，结束
                    copy_data:set_copy_info(CopyInfo#r_map_copy{mod_args = [], cur_progress = CurProgress, sub_progress = KillNum2}),
                    UpdateList = [#p_kv{id = ?COPY_UPDATE_SUB, val = KillNum2}],
                    copy_common:broadcast_update(UpdateList),
                    copy_common:do_copy_end(?COPY_SUCCESS),
                    copy_treasure_boss:do_event_reward();
                KillNum2 >= BornNum -> %% 准备生成下一波
                    [NextCopyWave|_] = Remain,
                    born_wave_monster(NextCopyWave),
                    CurProgress2 = CurProgress + 1,
                    SubProgress = 0,
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Remain, cur_progress = CurProgress + 1, sub_progress = SubProgress},
                    copy_data:set_copy_info(CopyInfo2),
                    UpdateList = [#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}, #p_kv{id = ?COPY_UPDATE_SUB, val = SubProgress}],
                    copy_common:broadcast_update(UpdateList);
                true ->
                    CopyWave2 = CopyWave#r_copy_wave{kill_num = KillNum2},
                    ModArgs2 = [CopyWave2|Remain],
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = ModArgs2, sub_progress = KillNum2},
                    copy_data:set_copy_info(CopyInfo2),
                    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_SUB, val = KillNum2}])
            end;
        _ ->
            ?ERROR_MSG("没有对应的波数了，不应该出现在这里:~w", [CopyInfo])
    end.

do_born_monster(CopyWave) ->
    #r_copy_wave{
        type_id = TypeID,
        born_num = BornNum,
        born_pos_list = BornPosList,
        add_props = AddProps
    } = CopyWave,
    MonsterDatas = [ #r_monster{
        type_id = TypeID,
        add_props = AddProps,
        born_pos = copy_misc:get_pos(BornPosList)} || _Num <- lists:seq(1, BornNum)],
    mod_map_monster:born_monsters(MonsterDatas).

get_refresh(MapID) ->
    #r_map_team{captain_role_id = CaptainRoleID} = mod_map_dict:get_map_params(),
    %% 单服玩法，可以直接调用
    RoleLevel = common_role_data:get_role_level(CaptainRoleID),
    ConfigList = lib_config:list(cfg_hunt_treasure_event),
    RefreshID = get_refresh_id(ConfigList, MapID, RoleLevel),
    AllList = lib_config:list(cfg_hunt_treasure_wave),
    List = [ WaveConfig|| {WaveID, WaveConfig} <- AllList, ?GET_MAP_BY_WAVE_ID(WaveID) =:= RefreshID],
    List2 = lists:keysort(#c_copy_wave.wave_id, List),
    [begin
         #c_copy_wave{
             monster_type = TypeID,
             num = Num,
             interval = Interval,
             add_props = AddProps,
             pos = Pos} = Wave,
         #r_copy_wave{
             type_id = TypeID,
             born_num = Num,
             born_pos_list = copy_misc:get_pos_list(Pos),
             kill_num = 0,
             born_time = Interval,
             add_props = AddProps
         }
     end || Wave <- List2].

get_refresh_id([{_EventID, Config}|R], MapID, RoleLevel) ->
    #c_hunt_treasure_event{
        wave_string = WaveString,
        map_id = ConfigMapID} = Config,
    case ConfigMapID =:= MapID of
        true ->
            WaveList = lib_tool:string_to_intlist(WaveString, "|", ","),
            copy_treasure_boss:get_treasure_args(WaveList, RoleLevel, []);
        _ ->
            get_refresh_id(R, MapID, RoleLevel)
    end.


get_cheer_config(ID) ->
    Key =
        if
            ID =:= ?CHEER_SKILL_ID_1 ->
                ?GLOBAL_COPY_TREASURE_SKILL_1;
            ID =:= ?CHEER_SKILL_ID_2 ->
                ?GLOBAL_COPY_TREASURE_SKILL_2;
            true ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    [#c_global{string = Cost, list = [SilverTimes, MaxTimes], int = AddBuffID}] = lib_config:find(cfg_global, Key),
    #r_cheer_args{
        cost_list = common_misc:get_global_string_list(Cost),
        silver_times = SilverTimes,
        all_times = MaxTimes,
        add_buff_id = AddBuffID
    }.
