%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十二月 2018 20:11
%%%-------------------------------------------------------------------
-module(copy_marry).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").
-include("monster.hrl").
-include("team.hrl").
-include("proto/copy_marry.hrl").

%% API
-export([
    role_init/1,
    init/1,
    loop/1,
    handle/1,
    role_enter/1,
    monster_dead/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = #r_copy_marry{}, all_wave = erlang:length(get_refresh())},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{copy_level = CopyLevel} = CopyInfo,
    [First|_Remain] = Refresh = get_refresh(),
    CurProgress = 1,
    CopyMarry = #r_copy_marry{refresh_list = Refresh},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry, cur_progress = CurProgress},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress}]),
    do_born_monster(First, CopyLevel),
    do_born_hearts(CopyLevel).

loop({Now, CopyInfo}) ->
    #r_map_copy{status = Status, mod_args = CopyMarry} = CopyInfo,
    #r_copy_marry{icon_end_time = IconEndTime, buff_end_time = BuffEndTime} = CopyMarry,
    CopyInfo2 =
        case BuffEndTime > 0 andalso Now >= BuffEndTime of
            true ->
                CopyMarry2 = CopyMarry#r_copy_marry{sweet_percent = 0, buff_end_time = 0},
                CopyInfoT = CopyInfo#r_map_copy{mod_args = CopyMarry2},
                copy_data:set_copy_info(CopyInfoT),
                CopyInfoT;
            _ ->
                CopyInfo
        end,
    case Status =:= ?COPY_NOT_END andalso IconEndTime > 0 andalso Now >= IconEndTime of
        true ->
            do_marry_finish(?GLOBAL_MARRY_COPY_REWARD2, CopyInfo2);
        _ ->
            ok
    end.

handle({#m_marry_copy_select_tos{item = ItemID}, RoleID, _PID}) ->
    do_marry_select(RoleID, ItemID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

role_enter(RoleID) ->
    #r_map_copy{status = Status, mod_args = ModArgs} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_marry{
        icon_end_time = IconEndTime,
        select_list = SelectList,
        icon_list = IconList
    } = ModArgs,
    %% 重新上线推送图标
    case Status =:= ?COPY_NOT_END andalso IconEndTime > 0 andalso (not lists:keymember(RoleID, #p_dkv.id, SelectList)) of
        true ->
            DataRecord = #m_marry_copy_icon_toc{
                item_list = lib_tool:random_reorder_list(IconList),
                end_time = IconEndTime
            },
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end,
    add_role_sweet(RoleID, CopyInfo, 0).

monster_dead({MapInfo, _SrcID, _SrcType}) ->
    #r_map_actor{monster_extra = #p_map_monster{type_id = DeadTypeID}} = MapInfo,
    CopyInfo = copy_data:get_copy_info(),
    [BigHeart, AddPercent1] = common_misc:get_global_list(?GLOBAL_MARRY_COPY_HEART1),
    [SmallHeart, AddPercent2] = common_misc:get_global_list(?GLOBAL_MARRY_COPY_HEART2),
    if
        DeadTypeID =:= BigHeart ->
            add_sweet(CopyInfo, AddPercent1);
        DeadTypeID =:= SmallHeart ->
            add_sweet(CopyInfo, AddPercent2);
        true ->
            normal_dead(CopyInfo)
    end.

add_sweet(CopyInfo, AddPercent) ->
    #r_map_copy{mod_args = CopyMarry} = CopyInfo,
    #r_copy_marry{sweet_percent = SweetPercent, buff_end_time = BuffEndTime} = CopyMarry,
    {_BuffID, BuffTime} = get_buff_args(),
    Now = time_tool:now(),
    DelayTime = 2,
    if
        SweetPercent >= ?RATE_100 -> %% 衰减中
            Now = time_tool:now(),
            AddTime = lib_tool:ceil(BuffTime * AddPercent/?RATE_100),
            NewTime = erlang:min(BuffEndTime - Now + AddTime, BuffTime),
            BuffEndTime2 = Now + NewTime + DelayTime,
            CopyMarry2 = CopyMarry#r_copy_marry{buff_end_time = BuffEndTime2};
        true ->
            SweetPercent2 = erlang:min(SweetPercent + AddPercent, ?RATE_100),
            BuffEndTime2 = ?IF(SweetPercent2 =:= ?RATE_100, erlang:min(Now + BuffTime, erlang:max(BuffEndTime, Now) + BuffTime) + DelayTime, BuffEndTime),
            CopyMarry2 = CopyMarry#r_copy_marry{sweet_percent = SweetPercent2, buff_end_time = BuffEndTime2}
    end,
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2},
    copy_data:set_copy_info(CopyInfo2),
    [ add_role_sweet(RoleID, CopyInfo2, DelayTime) || RoleID <- mod_map_ets:get_in_map_roles()].

add_role_sweet(RoleID, CopyInfo, DelayTime) ->
    #r_map_copy{mod_args = CopyMarry} = CopyInfo,
    #r_copy_marry{sweet_percent = SweetPercent, buff_end_time = BuffEndTime} = CopyMarry,
    {BuffID, BuffTime} = get_buff_args(),
    Now = time_tool:now(),
    case SweetPercent =:= ?RATE_100 of
        true ->
            RemainTime = BuffEndTime - Now,
            Fun = fun() -> role_misc:add_buff(RoleID, #buff_args{buff_id = BuffID, buff_last_time = RemainTime}) end,
            erlang:send_after(DelayTime * 1000, erlang:self(), {func, Fun}),
            common_misc:unicast(RoleID, #m_marry_copy_sweet_toc{is_decrease = true, remain_time = RemainTime});
        _ ->
            RemainTime = lib_tool:ceil(BuffTime * SweetPercent/?RATE_100),
            common_misc:unicast(RoleID, #m_marry_copy_sweet_toc{is_decrease = false, remain_time = RemainTime})
    end.


normal_dead(CopyInfo) ->
    #r_map_copy{mod_args = CopyMarry, cur_progress = CurProgress, copy_level = CopyLevel} = CopyInfo,
    #r_copy_marry{refresh_list = Refresh} = CopyMarry,
    case Refresh of
        [CopyWave|Remain] ->
            #r_copy_marry_monster{kill_num = KillNum, born_num = BornNum} = CopyWave,
            KillNum2 = KillNum + 1,
            if
                KillNum2 >= BornNum andalso Remain =:= [] -> %% 最后一波，结束
                    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_SUB, val = KillNum2}]),
                    CopyMarry2 = CopyMarry#r_copy_marry{refresh_list = []},
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2, cur_progress = CurProgress, sub_progress = KillNum2},
                    copy_data:set_copy_info(CopyInfo2),
                    marry_icon(CopyInfo2);
                KillNum2 >= BornNum -> %% 准备生成下一波
                    [NextCopyWave|_] = Remain,
                    do_born_monster(NextCopyWave, CopyLevel),
                    CurProgress2 = CurProgress + 1,
                    SubProgress = 0,
                    CopyMarry2 = CopyMarry#r_copy_marry{refresh_list = Remain},
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2, cur_progress = CurProgress + 1, sub_progress = SubProgress},
                    copy_data:set_copy_info(CopyInfo2),
                    UpdateList = [#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}, #p_kv{id = ?COPY_UPDATE_SUB, val = SubProgress}],
                    copy_common:broadcast_update(UpdateList);
                true ->
                    CopyWave2 = CopyWave#r_copy_marry_monster{kill_num = KillNum2},
                    CopyMarry2 = CopyMarry#r_copy_marry{refresh_list = [CopyWave2|Remain]},
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2, sub_progress = KillNum2},
                    copy_data:set_copy_info(CopyInfo2),
                    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_SUB, val = KillNum2}])
            end;
        _ ->
            ?ERROR_MSG("没有对应的波数了，不应该出现在这里:~w", [CopyInfo])
    end.

marry_icon(CopyInfo) ->
    #r_map_copy{mod_args = CopyMarry, enter_roles = EnterRoles} = CopyInfo,
    [#c_global{list = IconList, int = AddTime}] = lib_config:find(cfg_global, ?GLOBAL_COPY_MARRY_ICON),
    IconEndTime = time_tool:now() + AddTime,
    {ok, IconList2} = lib_tool:random_elements_from_list(3, IconList),
    [ begin
          RoleIconList = lib_tool:random_reorder_list(IconList2),
          common_misc:unicast(RoleID, #m_marry_copy_icon_toc{end_time = IconEndTime, item_list = RoleIconList}),
          ok
      end|| RoleID <- EnterRoles],
    CopyMarry2 = CopyMarry#r_copy_marry{icon_end_time = IconEndTime, icon_list = IconList2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2},
    copy_data:set_copy_info(CopyInfo2).

do_born_hearts(CopyLevel) ->
    [#c_global{string = PosList1, list = [BigHeart, _AddPercent1]}] = lib_config:find(cfg_global, ?GLOBAL_MARRY_COPY_HEART1),
    [#c_global{string = PosList2, list = [SmallHeart, _AddPercent2]}] = lib_config:find(cfg_global, ?GLOBAL_MARRY_COPY_HEART2),
    MonsterData1 = monster_misc:get_dynamic_monster(CopyLevel, BigHeart),
    MonsterData2 = monster_misc:get_dynamic_monster(CopyLevel, SmallHeart),
    MonsterDatas1 =
        [ MonsterData1#r_monster{
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My)
        }|| {Mx, My} <- common_misc:get_global_string_list(PosList1)],
    MonsterDatas2 =
        [ MonsterData2#r_monster{
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My)
        }|| {Mx, My} <- common_misc:get_global_string_list(PosList2)],
    mod_map_monster:born_monsters(MonsterDatas1 ++ MonsterDatas2).

do_born_monster(CopyWave, CopyLevel) ->
    #r_copy_marry_monster{
        type_id = TypeID,
        born_list = BornList
    } = CopyWave,
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
    MonsterDatas = lists:flatten([
        [
            MonsterData#r_monster{
                born_pos = copy_misc:get_pos(BornPosList)}
            || _Num <- lists:seq(1, BornNum)
        ]
        || {BornNum, BornPosList} <- BornList]),
    mod_map_monster:born_monsters(MonsterDatas).

get_refresh() ->
    AllList = cfg_copy_marry_monster:list(),
    [begin
         #c_copy_marry_monster{
             type_id = TypeID,
             num = Num,
             pos_1 = Pos1,
             pos_2 = Pos2} = Config,
         {BornNum1, BornList1} = ?IF(Pos1 =:= "", {0, []}, {Num, [{Num, copy_misc:get_pos_list(Pos1)}]}),
         {BornNum2, BornList2} = ?IF(Pos2 =:= "", {0, []}, {Num, [{Num, copy_misc:get_pos_list(Pos2)}]}),
         #r_copy_marry_monster{
             type_id = TypeID,
             born_num = BornNum1 + BornNum2,
             born_list = BornList1 ++ BornList2,
             kill_num = 0
         }
     end || {_Wave, Config} <- AllList].

do_marry_select(RoleID, ItemID) ->
    case catch check_marry_select(RoleID, ItemID) of
        {ok, CopyInfo2} ->
            copy_data:set_copy_info(CopyInfo2),
            common_misc:unicast(RoleID, #m_marry_copy_select_toc{item = ItemID}),
            ok;
        {finish, Type, CopyInfo2} ->
            common_misc:unicast(RoleID, #m_marry_copy_select_toc{item = ItemID}),
            do_marry_finish(Type, CopyInfo2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_copy_select_toc{err_code = ErrCode})
    end.

check_marry_select(RoleID, ItemID) ->
    CopyInfo = copy_data:get_copy_info(),
    #r_map_copy{status = Status, mod_args = CopyMarry} = CopyInfo,
    #r_copy_marry{icon_end_time = IconEndTime, icon_list = IconList, select_list = SelectList} = CopyMarry,
    ?IF(Status =:= ?COPY_NOT_END andalso IconEndTime > 0, ok, ?THROW_ERR(?ERROR_MARRY_COPY_SELECT_001)),
    ?IF(lists:member(ItemID, IconList), ok, ?THROW_ERR(?ERROR_MARRY_COPY_SELECT_002)),
    SelectList2 = [#p_dkv{id = RoleID, val = ItemID}|SelectList],
    CopyMarry2 = CopyMarry#r_copy_marry{select_list = SelectList2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = CopyMarry2},
    case SelectList of
        [] ->
            {ok, CopyInfo2};
        [#p_dkv{id = RoleID2, val = DestItem}] when RoleID =/= RoleID2 ->
            Type = ?IF(DestItem =:= ItemID, ?GLOBAL_MARRY_COPY_REWARD1, ?GLOBAL_MARRY_COPY_REWARD2),
            {finish, Type, CopyInfo2};
        _ ->
            ?THROW_ERR(?ERROR_MARRY_COPY_SELECT_003)
    end.

do_marry_finish(Type, CopyInfo) ->
    #r_map_copy{mod_args = RoleMarry, enter_roles = EnterRoles} = CopyInfo,
    RoleMarry2 = RoleMarry#r_copy_marry{icon_end_time = 0},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = RoleMarry2},
    copy_data:set_copy_info(CopyInfo2),
    GoodsList = [ #p_goods{type_id = TypeID, num  = Num} || {TypeID, Num} <- common_misc:get_global_string_list(Type)],
    PanelList = [ #p_kv{id = TypeID, val = Num}|| #p_goods{type_id = TypeID, num = Num} <- GoodsList],
    NormalRoleList = get_copy_reward_role(EnterRoles),
    [ begin
          common_misc:unicast(RoleID, #m_marry_copy_finish_toc{reward_type = Type}),
          role_misc:give_goods(RoleID, ?ITEM_GAIN_MARRY_COPY_REWARD, GoodsList),
          role_misc:info_role(RoleID, {mod_role_map_panel, add_drop, [PanelList]})
      end|| RoleID <- EnterRoles, lists:member(RoleID, NormalRoleList)],
    copy_common:do_copy_end(?COPY_SUCCESS).


get_copy_reward_role(EnterRoles) ->
    #r_map_team{extra_role_id_list = ExtraRoleList} = mod_map_dict:get_map_params(),
    EnterRoles -- ExtraRoleList.



get_buff_args() ->
    BuffID = common_misc:get_global_int(?GLOBAL_MARRY_COPY_HEART1),
    [#c_buff{last_time = LastTime}] = lib_config:find(cfg_buff, BuffID),
    {BuffID, LastTime}.