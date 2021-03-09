%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     金币、材料副本
%%% @end
%%% Created : 01. 九月 2017 16:53
%%%-------------------------------------------------------------------
-module(copy_wave).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("monster.hrl").
-include("team.hrl").
-include("world_robot.hrl").

%% API
-export([
    role_init/1,
    init/1,
    handle/1,
    monster_dead/1
]).

-export([
    born_wave_monster/1,
    get_robot_skill/1
]).

-export([
    copy_clean/1
]).

role_init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    Refresh = get_refresh(MapID),
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = erlang:length(Refresh)},
    copy_data:set_copy_info(CopyInfo2),
    born_equip_robots(MapID).

init(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    [First|_Remain] = Refresh = get_refresh(MapID),
    CurProgress = 1,
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Refresh, cur_progress = CurProgress},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress}]),
    born_wave_monster(First).

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
                    copy_common:do_copy_end(?COPY_SUCCESS);
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
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    AllList =
    case CopyType of
        ?COPY_SILVER ->
            lib_config:list(cfg_copy_silver);
        ?COPY_EQUIP ->
            lib_config:list(cfg_copy_equip);
        ?COPY_WAR_SPIRIT ->
            lib_config:list(cfg_copy_war_spirit);
        ?COPY_FORGE_SOUL ->
            lib_config:list(cfg_copy_forge_soul)
    end,
    List = [ WaveConfig|| {WaveID, WaveConfig} <- AllList, ?GET_MAP_BY_WAVE_ID(WaveID) =:= MapID],
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

copy_clean(CleanArgs) ->
    #r_clean_args{
        copy_type = CopyType,
        map_id = MapID,
        num = Num} = CleanArgs,
    AllList =
        case CopyType of
            ?COPY_SILVER ->
                lib_config:list(cfg_copy_silver);
            ?COPY_EQUIP ->
                lib_config:list(cfg_copy_equip);
            ?COPY_WAR_SPIRIT ->
                lib_config:list(cfg_copy_war_spirit);
            ?COPY_FORGE_SOUL ->
                lib_config:list(cfg_copy_forge_soul)
        end,
    List = [ WaveConfig|| {WaveID, WaveConfig} <- AllList, ?GET_MAP_BY_WAVE_ID(WaveID) =:= MapID],
    copy_clean2(List, Num, [], 0).

copy_clean2([], _Num, GoodsList, AddExp) ->
    {GoodsList, lib_tool:ceil(AddExp)};
copy_clean2([Wave|R], Num, GoodsAcc, AddExpAcc) ->
    #c_copy_wave{monster_type = TypeID, num = MonsterNum} = Wave,
    #c_monster{add_exp = AddExp, silver_drop = DropSilver, drop_id_list = DropIDList} = monster_misc:get_monster_config(TypeID),
    AddExpAcc2 = AddExp * MonsterNum * Num + AddExpAcc,
    SilverGoods = ?IF(?IS_SILVER(DropSilver), [#p_goods{type_id = ?ITEM_SILVER, num = DropSilver * Num}], []),
    GoodsList = SilverGoods ++ lists:flatten([copy_clean3(DropID, MonsterNum * Num, []) || DropID <- DropIDList]),
    GoodsList2 = [ #p_goods{type_id = ItemTypeID, num = ItemNum, bind = ?IS_BIND(Bind)} || {ItemTypeID, ItemNum, Bind} <- GoodsList],
    copy_clean2(R, Num, GoodsList2 ++ GoodsAcc, AddExpAcc2).

copy_clean3(_DropID, Num, Goods) when Num =< 0 ->
    Goods;
copy_clean3(DropID, Num, GoodsAcc) ->
    Goods = mod_map_drop:get_drop_item_list2(DropID),
    copy_clean3(DropID, Num - 1, Goods ++ GoodsAcc).

born_equip_robots(MapID) ->
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    case CopyType of
        ?COPY_EQUIP ->
            #r_map_team{team_id = TeamID, role_list = RoleList} = mod_map_dict:get_map_params(),
            RobotStartID = common_id:get_robot_start_id(MapID),
            {ok, #r_pos{mx = Mx, my = My}} = map_misc:get_born_pos(MapID),
            {OffsetMx, OffsetMy} = map_misc:get_offset_meter(Mx, My),
            RobotDatas = [
                begin
                    #r_role_team{
                        role_name = RoleName,
                        role_level = RoleLevel,
                        category = Category,
                        sex = Sex,
                        skin_list = SkinList,
                        ornament_list = OrnamentList
                    } = RoleTeam,
                    [_RoleLevel, Attack, Hp|_] = common_misc:get_global_list(?GLOBAL_EQUIP_GUIDE),
                    #r_robot{
                        robot_id = RobotStartID + RobotIndex,
                        robot_name = RoleName,
                        team_id = TeamID,
                        sex = Sex,
                        category = Category,
                        level = RoleLevel,
                        skin_list = SkinList,
                        skill_list = get_robot_skill(Category),
                        ornament_list = OrnamentList,
                        min_point = [OffsetMx, OffsetMy],
                        max_point = [OffsetMx, OffsetMy],
                        base_attr = #actor_fight_attr{
                            max_hp = Hp,
                            attack = Attack,
                            defence = 1000000,
                            move_speed = 500
                        }
                    }
                end|| #r_role_team{role_id = RobotIndex} = RoleTeam <- RoleList, RobotIndex =< ?TEAM_ROBOT_NUM],
            mod_map_robot:born_robots(RobotDatas);
        _ ->
            ok
    end.

get_robot_skill(Category) ->
    case Category of
        ?CATEGORY_1 ->
            [#r_robot_skill{skill_id = 1010001, skill_type = ?SKILL_ATTACK, time = 0}] ++
            [#r_robot_skill{skill_id = SkillID, skill_type = ?SKILL_NORMAL, time = 0} || SkillID <- [1011001, 1012001, 1013001, 1014001]];
        ?CATEGORY_2 ->
            [#r_robot_skill{skill_id = 1001001, skill_type = ?SKILL_ATTACK, time = 0}] ++
            [#r_robot_skill{skill_id = SkillID, skill_type = ?SKILL_NORMAL, time = 0} || SkillID <- [1002001, 1003001, 1004001, 1005001]]
    end.