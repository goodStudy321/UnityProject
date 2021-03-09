%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     守卫仙盟
%%% @end
%%% Created : 29. 三月 2018 19:20
%%%-------------------------------------------------------------------
-module(mod_map_family_td).
-author("laijichang").
-include("global.hrl").
-include("family_td.hrl").
-include("monster.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_map_family_td.hrl").

%% API
-export([
    i/1,
    init/0,
    loop/1,
    handle/1
]).

-export([
    gm_succ/1,
    activity_end/1
]).

-export([
    role_enter_map/1,
    monster_reduce_hp/3,
    monster_dead/1,
    add_exp/1
]).

i(ExtraID) ->
    pname_server:call(map_misc:get_map_pname(?MAP_FAMILY_TD, ExtraID), {mod, ?MODULE, i}).

activity_end(FamilyID) ->
    case pname_server:pid(map_misc:get_map_pname(?MAP_FAMILY_TD, FamilyID)) of
        PID when erlang:is_pid(PID) ->
            pname_server:send(map_misc:get_map_pname(?MAP_FAMILY_TD, FamilyID), {mod, ?MODULE, activity_end});
        _ ->
            ok
    end.

gm_succ(FamilyID) ->
    case pname_server:pid(map_misc:get_map_pname(?MAP_FAMILY_TD, FamilyID)) of
        PID when erlang:is_pid(PID) ->
            pname_server:send(map_misc:get_map_pname(?MAP_FAMILY_TD, FamilyID), {mod, ?MODULE, gm_succ});
        _ ->
            ok
    end.

init() ->
    do_init_bases(),
    set_rank_info([]),
    set_damage_info([]),
    {RefreshList1, RefreshList2, AssaultTime, AllNum} = get_refresh(),
    [#c_family_td_pos{pos_string = PosList1}] = lib_config:find(cfg_family_td_pos, ?AREA_POS_1),
    [#c_family_td_pos{pos_string = PosList2}] = lib_config:find(cfg_family_td_pos, ?AREA_POS_2),
    [#c_family_td_pos{pos_string = PosList3}] = lib_config:find(cfg_family_td_pos, ?AREA_POS_3),
    MapCtrl = #r_map_family_td{
        status = ?FAMILY_TD_STATUS_NORMAL,
        shutdown_time = time_tool:now() + ?AN_HOUR / 2 + ?ONE_MINUTE,
        cur_wave = 0,
        all_num = AllNum,
        all_wave = erlang:length(RefreshList1),
        kill_num = 0,
        buff_multi = 3,
        star = ?FAMILY_TD_ALL_STAR,
        assault_time_list = lists:reverse(AssaultTime),
        normal_refresh_list = lists:reverse(RefreshList1),
        assault_refresh_list = lists:reverse(RefreshList2),
        area_pos_list = [
            {?AREA_1, lib_tool:string_to_intlist(PosList1)},
            {?AREA_2, lib_tool:string_to_intlist(PosList2)},
            {?AREA_3, lib_tool:string_to_intlist(PosList3)}
        ]
    },
    set_map_ctrl(MapCtrl).

loop(Now) ->
    #r_map_family_td{
        status = Status,
        shutdown_time = ShutDownTime,
        cur_wave = CurWave,
        assault_time_list = AssaultTimeList,
        normal_refresh_list = FreshList1,
        assault_refresh_list = FreshList2,
        area_pos_list = AreaPosList} = MapCtrl = get_map_ctrl(),
    if
        Status =:= ?FAMILY_TD_STATUS_NORMAL ->
            WorldLevel = world_data:get_world_level(),
            %% 刷普通怪
            MapCtrl2 =
            case FreshList1 of
                [#r_td_monster_fresh{time = BornTime, monster_refresh = MonsterRefresh}|R1] when Now >= BornTime ->
                    do_born_monsters(MonsterRefresh, WorldLevel, AreaPosList),
                    CurWave2 = CurWave + 1,
                    NextWaveTime = get_next_wave_time(R1),
                    UpdateList = [#p_kv{id = ?FAMILY_TD_UPDATE_WAVE, val = CurWave2}, #p_kv{id = ?FAMILY_TD_UPDATE_NEXT_TIME, val = NextWaveTime}],
                    map_server:send_all_gateway(#m_family_td_info_update_toc{kv_list = UpdateList}),
                    MapCtrl#r_map_family_td{cur_wave = CurWave2, normal_refresh_list = R1};
                _ ->
                    MapCtrl
            end,
            %% 刷突袭怪
            MapCtrl3 =
            case FreshList2 of
                [#r_td_monster_fresh{time = BornTime2, monster_refresh = MonsterRefresh2}|R2] when Now >= BornTime2 ->
                    do_born_monsters(MonsterRefresh2, WorldLevel, AreaPosList),
                    MapCtrl2#r_map_family_td{assault_refresh_list = R2};
                _ ->
                    MapCtrl2
            end,
            %% 通知时间
            MapCtrl4 =
            case AssaultTimeList of
                [Time|TimeR] when Now >= Time ->
                    AssaultTime = get_assault_time(TimeR),
                    map_server:send_all_gateway(#m_family_td_info_update_toc{kv_list = [#p_kv{id = ?FAMILY_TD_UPDATE_ASSAULT_TIME, val = AssaultTime}]}),
                    MapCtrl3#r_map_family_td{assault_time_list = TimeR};
                _ ->
                    MapCtrl3
            end,
            set_map_ctrl(MapCtrl4),
            ?IF(Now rem 5 =:= 0, do_rank(), ok);
        true ->
            ?IF(Now >= ShutDownTime, do_map_end(), ok)
    end.

handle(i) ->
    do_i();
handle(activity_end) ->
    do_activity_end();
handle(gm_succ) ->
    do_reward(true);
handle({family_member_leave, RoleID}) ->
    do_family_member_leave(RoleID);
handle({#m_family_td_rank_info_tos{}, RoleID, _PID}) ->
    do_get_rank(RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

do_family_member_leave(RoleID) ->
    List = get_damage_info(),
    List2 = lists:keydelete(RoleID, #p_family_td_rank.role_id, List),
    set_damage_info(List2).


role_enter_map(RoleID) ->
    #r_map_family_td{
        buff_multi = BuffMulti,
        cur_wave = CurWave,
        all_wave = AllWave,
        kill_num = KillNum,
        normal_refresh_list = RefreshList,
        assault_time_list = AssaultTimeList} = get_map_ctrl(),
    [LeftBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_LEFT_BASE),
    [RightBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_RIGHT_BASE),
    [Base|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_BASE),
    HpList = [#p_kv{id = TypeID, val = get_hp_rate(TypeID)} || TypeID <- [LeftBase, RightBase, Base]],
    NextWaveTime = get_next_wave_time(RefreshList),
    DataRecord = #m_family_td_info_toc{
        wave = CurWave,
        next_wave_time = NextWaveTime,
        all_wave = AllWave,
        kill_num = KillNum,
        assault_time = get_assault_time(AssaultTimeList),
        hp_list = HpList},
    common_misc:unicast(RoleID, DataRecord),
    role_misc:info_role(RoleID, {mod, mod_role_family_td, {buff_multi, BuffMulti}}).

%% 怪物掉血，更新伤害数据
monster_reduce_hp(MapInfo, ReduceSrc, ReduceHp) ->
    #r_reduce_src{actor_id = ActorID, actor_type = ActorType} = ReduceSrc,
    case ActorType of
        ?ACTOR_TYPE_ROLE ->
            DamageInfo = get_damage_info(),
            case lists:keyfind(ActorID, #p_family_td_rank.role_id, DamageInfo) of
                #p_family_td_rank{damage = Damage} = DamageRank ->
                    DamageRank2 = DamageRank#p_family_td_rank{damage = Damage + ReduceHp},
                    DamageInfo2 = lists:keyreplace(ActorID, #p_family_td_rank.role_id, DamageInfo, DamageRank2);
                _ ->
                    DamageRank = #p_family_td_rank{role_id = ActorID, damage = ReduceHp, role_name = common_role_data:get_role_name(ActorID)},
                    DamageInfo2 = [DamageRank|DamageInfo]
            end,
            set_damage_info(DamageInfo2);
        _ ->
            #r_map_actor{hp = Hp, max_hp = MaxHp, monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
            [LeftBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_LEFT_BASE),
            [RightBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_RIGHT_BASE),
            [Base|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_BASE),
            case lists:member(TypeID, [LeftBase, RightBase, Base]) of
                true -> %% 基地血量更新
                    Rate = lib_tool:ceil(?RATE_10000 * Hp / MaxHp),
                    DataRecord = #m_family_td_hp_toc{hp = #p_kv{id = TypeID, val = Rate}},
                    set_hp_rate(TypeID, Rate),
                    map_server:send_all_gateway(DataRecord);
                _ ->
                    ok
            end
    end.

monster_dead(MapInfo) ->
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    #r_map_family_td{kill_num = KillNum, all_num = AllNum, star = OldStar, area_pos_list = AreaPosList, buff_multi = BuffMulti} = MapCtrl = get_map_ctrl(),
    [LeftBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_LEFT_BASE),
    [RightBase|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_RIGHT_BASE),
    [Base|_] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_BASE),
    FamilyID = map_common_dict:get_map_extra_id(),
    if
        TypeID =:= LeftBase ->
            [#c_family_td_pos{pos_string = PosString1}] = lib_config:find(cfg_family_td_pos, ?AREA_POS_1),
            [#c_family_td_pos{pos_string = ExtraPosString1}] = lib_config:find(cfg_family_td_pos, ?AREA_EXTRA_POS_1),
            PosList1 = lib_tool:string_to_intlist(PosString1),
            ExtraPosList1 = lib_tool:string_to_intlist(ExtraPosString1),
            Area1PosList = PosList1 ++ ExtraPosList1,
            Area1PosList2 = lists:keyreplace(?AREA_1, 1, AreaPosList, {?AREA_1, Area1PosList}),
            BuffMulti2 = BuffMulti - 1,
            map_server:send_all_role({mod, mod_role_family_td, {buff_multi, BuffMulti2}}),
            set_hp_rate(TypeID, 0),
            set_map_ctrl(MapCtrl#r_map_family_td{star = OldStar - ?BASE_STAR_REDUCE, area_pos_list = Area1PosList2, buff_multi = BuffMulti2}),
            mod_map_monster:td_change_pos({?AREA_1, copy_single_td:get_td_pos_list(ExtraPosList1)});
        TypeID =:= RightBase ->
            [#c_family_td_pos{pos_string = PosString2}] = lib_config:find(cfg_family_td_pos, ?AREA_POS_2),
            [#c_family_td_pos{pos_string = ExtraPosString2}] = lib_config:find(cfg_family_td_pos, ?AREA_EXTRA_POS_2),
            PosList2 = lib_tool:string_to_intlist(PosString2),
            ExtraPosList2 = lib_tool:string_to_intlist(ExtraPosString2),
            Area2PosList = PosList2 ++ ExtraPosList2,
            Area2PosList2 = lists:keyreplace(?AREA_2, 1, AreaPosList, {?AREA_2, Area2PosList}),
            BuffMulti2 = BuffMulti - 1,
            map_server:send_all_role({mod, mod_role_family_td, {buff_multi, BuffMulti2}}),
            set_hp_rate(TypeID, 0),
            set_map_ctrl(MapCtrl#r_map_family_td{star = OldStar - ?BASE_STAR_REDUCE, area_pos_list = Area2PosList2, buff_multi = BuffMulti2}),
            mod_map_monster:td_change_pos({?AREA_2, copy_single_td:get_td_pos_list(ExtraPosList2)});
        TypeID =:= Base ->
            ?WARNING_MSG("famiy td end"),
            Status = ?FAMILY_TD_STATUS_FAILED_END,
            BuffMulti2 = BuffMulti - 1,
            map_server:send_all_role({mod, mod_role_family_td, {buff_multi, BuffMulti2}}),
            set_hp_rate(TypeID, 0),
            set_map_ctrl(MapCtrl#r_map_family_td{status = Status, star = 0, buff_multi = BuffMulti2, shutdown_time = time_tool:now() + ?ONE_MINUTE, normal_refresh_list = []}),
            mod_family_td:map_end(FamilyID),
            do_reward(false);
        true ->
            KillNum2 = KillNum + 1,
            map_server:send_all_gateway(#m_family_td_info_update_toc{kv_list = [#p_kv{id = ?FAMILY_TD_UPDATE_KILL_NUM, val = KillNum2}]}),
            MapCtrl2 = MapCtrl#r_map_family_td{kill_num = KillNum2},
            case KillNum2 >= AllNum of
                true ->
                    ?WARNING_MSG("kill end : ~w", [{KillNum2, AllNum}]),
                    Status = ?FAMILY_TD_STATUS_SUCCESS_END,
                    set_map_ctrl(MapCtrl2#r_map_family_td{status = Status, shutdown_time = time_tool:now() + ?ONE_MINUTE}),
                    mod_family_td:map_end(FamilyID),
                    do_reward(true);
                _ ->
                    set_map_ctrl(MapCtrl2)
            end
    end.

add_exp(AddExp) ->
    #r_map_family_td{kill_exp = KillExp} = MapCtrl = get_map_ctrl(),
    set_map_ctrl(MapCtrl#r_map_family_td{kill_exp = KillExp + AddExp}).

do_i() ->
    {dictionary, List} = erlang:process_info(erlang:self(), dictionary),
    lists:foldl(
        fun(Dict, Acc) ->
            case Dict of
                {{?MODULE, _, _}, _} ->
                    [Dict|Acc];
                {{?MODULE, _}, _} ->
                    [Dict|Acc];
                _ ->
                    Acc
            end
        end, [], lists:sort(List)).

do_activity_end() ->
    #r_map_family_td{status = Status} = MapCtrl = get_map_ctrl(),
    case Status of
        ?FAMILY_TD_STATUS_NORMAL ->
            ?WARNING_MSG("activit end"),
            Status2 = ?FAMILY_TD_STATUS_FAILED_END,
            set_map_ctrl(MapCtrl#r_map_family_td{status = Status2, shutdown_time = time_tool:now() + ?ONE_MINUTE}),
            do_reward(false);
        _ ->
            ok
    end,
    do_map_end().

do_reward(IsSucc) ->
    #r_map_family_td{
        kill_num = KillNum,
        kill_exp = KillExp,
        star = Star
    } = get_map_ctrl(),
    StarList = common_misc:get_global_string_list(?GLOBAL_FAMILY_TD_STAR_EXP),
    StarExp =
    case IsSucc of
        true ->
            {_, Rate} = lists:keyfind(Star, 1, StarList),
            lib_tool:ceil(KillExp * Rate / ?RATE_10000);
        _ ->
            0
    end,
    TDEnd = #r_family_td_end{
        is_succ = IsSucc,
        kill_num = KillNum,
        kill_exp = KillExp,
        star = Star,
        star_exp = StarExp,
        rank_list = get_rank_info()
    },
    map_server:send_all_role({mod, mod_role_family_td, {family_td_end, TDEnd}}).

do_map_end() ->
    mod_role_daily_liveness:trigger_daily_liveness(mod_map_ets:get_in_map_roles(), ?LIVENESS_FAMILY_TD),
    map_server:kick_all_roles(),
    map_server:delay_shutdown().

do_get_rank(RoleID) ->
    RankInfos = get_rank_info(),
    common_misc:unicast(RoleID, #m_family_td_rank_info_toc{rank_info = RankInfos}).

do_rank() ->
    DamageInfo = get_damage_info(),
    {SortAllEs1, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#p_family_td_rank{rank = Rank},
            {[E1|Acc], Rank + 1}
        end, {[], 1}, lists:reverse(lists:keysort(#p_family_td_rank.damage, DamageInfo))),
    set_rank_info(lists:reverse(SortAllEs1)).

do_init_bases() ->
    [LeftBase, Mx1, My1, MDir1] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_LEFT_BASE),
    [RightBase, Mx2, My2, MDir2] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_RIGHT_BASE),
    [Base, Mx3, My3, MDir3] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_BASE),
    WorldLevel = world_data:get_world_level(),
    %% 取整5级
    WorldLevel2 = (WorldLevel div 5) * 5,
    LeftNpc = monster_misc:get_dynamic_monster(WorldLevel2, LeftBase),
    RightNpc = monster_misc:get_dynamic_monster(WorldLevel2, RightBase),
    MiddleNpc = monster_misc:get_dynamic_monster(WorldLevel2, Base),
    MonsterDatas = [
        LeftNpc#r_monster{born_pos = map_misc:get_pos_by_offset_pos(Mx1, My1, MDir1)},
        RightNpc#r_monster{born_pos = map_misc:get_pos_by_offset_pos(Mx2, My2, MDir2)},
        MiddleNpc#r_monster{born_pos = map_misc:get_pos_by_offset_pos(Mx3, My3, MDir3)}
    ],
    mod_map_monster:born_monsters(MonsterDatas),
    set_hp_rate(LeftBase, ?RATE_10000),
    set_hp_rate(RightBase, ?RATE_10000),
    set_hp_rate(Base, ?RATE_10000).

do_born_monsters([], _WorldLevel, _AreaPosList) ->
    ok;
do_born_monsters([{Area, Monsters}|R], WorldLevel, AreaPosList) ->
    {Area, PosList} = lists:keyfind(Area, 1, AreaPosList),
    MonsterList = do_born_monsters2(Monsters, WorldLevel, PosList, Area, ?MIN_COUNTER, []),
    mod_map_monster:born_monsters(MonsterList),
    do_born_monsters(R, WorldLevel, AreaPosList).

do_born_monsters2([], _WorldLevel, _PosList, _Area, _Counter, MonsterList) ->
    MonsterList;
do_born_monsters2([{TypeID, Num}|R], WorldLevel, PosList, Area, Counter, MonsterList) ->
    [{Mx, My}|RemainList] = PosList,
    MonsterData = monster_misc:get_dynamic_monster(WorldLevel, TypeID),
    AddMonsterList =
    [begin
         MonsterData2 =
         MonsterData#r_monster{
             born_pos = map_misc:get_pos_by_offset_pos(Mx, My),
             td_index = Area,
             td_pos_list = copy_single_td:get_td_pos_list(RemainList)},
         {MonsterData2, Counter + (Index - 1) * ?SECOND_COUNTER}
     end || Index <- lists:seq(1, Num)],
    do_born_monsters2(R, WorldLevel, PosList, Area, Counter + Num * ?SECOND_COUNTER, AddMonsterList ++ MonsterList).

get_refresh() ->
    Now = time_tool:now(),
    get_refresh2(cfg_family_td_refresh:list(), Now, [], [], [], 0).

get_refresh2([], _Now, Refresh1Acc, Refresh2Acc, TimeAcc, NumAcc) ->
    {Refresh1Acc, Refresh2Acc, TimeAcc, NumAcc};
get_refresh2([{_, Config}|R], Now, Refresh1Acc, Refresh2Acc, TimeAcc, NumAcc) ->
    #c_family_td_refresh{
        bron_time = BornTime,
        area_1 = Area1,
        area_2 = Area2,
        area_3 = Area3
    } = Config,
    Time = Now + BornTime,
    {NewRefresh1Acc, AddNum1} =
    case Area1 =/= [] orelse Area2 =/= [] of
        true ->
            {AreaList1, AreaNum1} = get_monster_refresh(Area1),
            {AreaList2, AreaNum2} = get_monster_refresh(Area2),
            Refresh1 = #r_td_monster_fresh{
                time = Time,
                monster_refresh = [
                    {?AREA_1, AreaList1},
                    {?AREA_2, AreaList2}
                ]},
            {[Refresh1|Refresh1Acc], AreaNum1 + AreaNum2};
        _ ->
            {Refresh1Acc, 0}
    end,
    {TimeAcc2, NewRefresh2Acc, AddNum2} =
    case Area3 =/= [] of
        true ->
            {AreaList3, AreaNum3} = get_monster_refresh(Area3),
            Refresh2 = #r_td_monster_fresh{
                time = Time,
                monster_refresh = [{?AREA_3, AreaList3}]},
            {[Time|TimeAcc], [Refresh2|Refresh2Acc], AreaNum3};
        _ ->
            {TimeAcc, Refresh2Acc, 0}
    end,
    get_refresh2(R, Now, NewRefresh1Acc, NewRefresh2Acc, TimeAcc2, NumAcc + AddNum1 + AddNum2).

get_monster_refresh(Area) ->
    get_monster_refresh2(string:tokens(Area, ";"), [], 0).

get_monster_refresh2([], MonsterList, BornNum) ->
    {MonsterList, BornNum};
get_monster_refresh2([MonsterString|R], MonsterList, BornNum) ->
    [TypeID, Num] = string:tokens(MonsterString, ","),
    Num2 = lib_tool:to_integer(Num),
    MonsterList2 = [{lib_tool:to_integer(TypeID), Num2}|MonsterList],
    get_monster_refresh2(R, MonsterList2, BornNum + Num2).

get_assault_time([]) ->
    0;
get_assault_time([First|_]) ->
    First.

get_next_wave_time(RefreshList) ->
    case RefreshList of
        [#r_td_monster_fresh{time = Time}|_] ->
            Time;
        _ ->
            0
    end.


%%%===================================================================
%%% dict
%%%===================================================================
set_map_ctrl(MapCtrl) ->
    erlang:put({?MODULE, map_ctrl}, MapCtrl).
get_map_ctrl() ->
    erlang:get({?MODULE, map_ctrl}).

set_rank_info(RankInfo) ->
    erlang:put({?MODULE, rank_info}, RankInfo).
get_rank_info() ->
    erlang:get({?MODULE, rank_info}).

set_damage_info(DamageInfo) ->
    erlang:put({?MODULE, damage_info}, DamageInfo).
get_damage_info() ->
    erlang:get({?MODULE, damage_info}).

set_hp_rate(TypeID, Rate) ->
    erlang:put({?MODULE, hp_rate, TypeID}, Rate).
get_hp_rate(TypeID) ->
    erlang:get({?MODULE, hp_rate, TypeID}).
