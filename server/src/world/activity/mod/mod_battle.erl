%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 三月 2018 10:29
%%%-------------------------------------------------------------------
-module(mod_battle).
-author("laijichang").
-include("battle.hrl").
-include("global.hrl").
-include("activity.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_battle.hrl").

%% API
-export([
    init/0,
    handle/1,
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    loop/1
]).

-export([
    i/0,
    gm_camp_change/2
]).

-export([
    role_enter_map/1,
    role_leave_map/1,
    role_be_killed/3,
    monster_dead/3
]).

-export([
    cmp_rank/2
]).

-export([
    role_pre_enter/2,
    role_get_rank_info/1,
    role_get_battle/1
]).

-export([
    get_activity/0,
    get_map_battle/1,
    get_role_battle/1,
    get_rank_info/1,
    get_camp_id_pos/1
]).

i() ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, i).

gm_camp_change(RoleID, CampID) ->
    world_activity_server:info_mod(?MODULE, {gm_camp_change, RoleID, CampID}).

%% 进程启动时的init
init() ->
    lib_minheap:new_heap(?MODULE, ?BATTLE_ALL_RANK_NUM, {?MODULE, cmp_rank}, []),
    lib_tool:init_ets(?ETS_MAP_BATTLE, #r_map_battle.extra_id),
    lib_tool:init_ets(?ETS_ROLE_BATTLE, #r_role_battle.role_id),
    lib_tool:init_ets(?ETS_RANK_BATTLE, 1),
    set_battle_ctrl(#r_battle_ctrl{}).

handle(Info) ->
    do_handle_info(Info).

activity_prepare() ->
    cancel_time_ref(),
    close_all_maps(),
    set_battle_ctrl(#r_battle_ctrl{}),
    lib_minheap:clear_heap(?MODULE),
    ets:delete_all_objects(?ETS_MAP_BATTLE),
    ets:delete_all_objects(?ETS_ROLE_BATTLE),
    ok.

activity_start() ->
    ExtraID = 1,
    start_map(ExtraID),
    ok.

activity_end() ->
    AllRanks = do_all_rank(),
    set_rank_info(?ALL_RANK_KEY, AllRanks),
    TimeRef = world_activity_server:info_mod_by_time(?ONE_MINUTE * 1000, ?MODULE, close_all_maps),
    cancel_time_ref(),
    set_time_ref(TimeRef),
    #r_battle_ctrl{extra_id_list = ExtraIDList} = get_battle_ctrl(),
    ConfigList = cfg_battle_rank_reward:list(),
    %% 加经验
    [ begin
          RankInfos = get_rank_info(ExtraID),
          [ begin
                case get_battle_rank_reward(Rank, ConfigList) of
                    #c_battle_rank_reward{exp_rate = ExpRate, item_rewards = ItemRewards} ->
                        AddExp = mod_role_level:get_activity_level_exp(common_role_data:get_role_level(RoleID), ExpRate),
                        mod_role_level:add_exp(RoleID, AddExp, ?EXP_ADD_FROM_BATTLE),
                        ItemRewardList = common_misc:get_item_reward(ItemRewards),
                        GoodsList = [ #p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- ItemRewardList],
                        LetterInfo = #r_letter_info{
                            template_id = ?LETTER_TEMPLATE_BATTLE_CAMP,
                            action = ?ITEM_GAIN_BATTLE_RANK,
                            goods_list = GoodsList,
                            text_string = [lib_tool:to_list(Rank)]
                        },
                        common_letter:send_cross_letter(RoleID, LetterInfo),
                        case Rank =:= 1 of
                            true ->
                                RoleName = common_role_data:get_role_name(RoleID),
                                common_broadcast:send_world_common_notice(?NOTICE_BATTLE_END, [RoleName], GoodsList);
                            _ ->
                                ok
                        end;
                    _ ->
                        ok
                end,
                Log = #log_role_battle{role_id = RoleID, battle_rank = Rank, score = Score, camp_id = RoleCampID},
                background_misc:cross_log(RoleID, Log)
            end|| #r_rank_battle{role_id = RoleID, rank = Rank, score = Score, camp_id = RoleCampID} <- RankInfos]
      end || ExtraID <- ExtraIDList],
    kick_roles(),
    ok.

%% STATUS_OPEN时才会调用
loop(Now) ->
    case Now rem 30 =:= 0 of %% 每30秒加一次积分
        true ->
            do_loop_add_score();
        _ ->
            ok
    end.

start_map(ExtraID) ->
    {ok, MapPID} = map_sup:start_map(?MAP_BATTLE, ExtraID),
    #r_battle_ctrl{extra_id_list = ExtraIDList} = BattleCtrl = get_battle_ctrl(),
    set_battle_ctrl(BattleCtrl#r_battle_ctrl{cur_extra_id = ExtraID, cur_role_num = 0, extra_id_list = [ExtraID|ExtraIDList]}),
    PowerList = [#p_kvt{id = ?BATTLE_CAMP_IMMORTAL}, #p_kvt{id = ?BATTLE_CAMP_DEMON}, #p_kvt{id = ?BATTLE_CAMP_BUDDHA}],
    TowerList = [#p_kv{id = ?BATTLE_CAMP_IMMORTAL, val = 0}, #p_kv{id = ?BATTLE_CAMP_DEMON, val = 0}, #p_kv{id = ?BATTLE_CAMP_BUDDHA, val = 0}],
    set_map_battle(#r_map_battle{extra_id = ExtraID, power_list = PowerList, tower_list = TowerList}),
    set_rank_info(ExtraID, []),
    {ok, MapPID}.

close_all_maps() ->
    #r_battle_ctrl{extra_id_list = ExtraIDList} = get_battle_ctrl(),
    [ pname_server:send(map_misc:get_map_pname(?MAP_BATTLE, ExtraID), {map_shutdwon, shutdown}) || ExtraID <- ExtraIDList],
    set_battle_ctrl(#r_battle_ctrl{}).

kick_roles() ->
    #r_battle_ctrl{extra_id_list = ExtraIDList} = get_battle_ctrl(),
    [ pname_server:send(map_misc:get_map_pname(?MAP_BATTLE, ExtraID), {mod, mod_map_battle, kick_roles}) || ExtraID <- ExtraIDList].


role_enter_map(RoleID) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {role_enter_map, RoleID}).

role_leave_map(RoleID) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {role_leave_map, RoleID}).

role_be_killed(KilledRoleID, SrcRoleID, AssistRoles) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {role_be_killed, KilledRoleID, SrcRoleID, AssistRoles}).

monster_dead(ExtraID, OldCampID, CampID) ->
    Mod = activity_misc:get_map_activity_mod(),
    Mod:info_mod(?MODULE, {monster_dead, ExtraID, OldCampID, CampID}).

cmp_rank(RankInfo1, RankInfo2) ->
    #r_rank_battle{score = Score1, max_power = MaxPower1} = RankInfo1,
    #r_rank_battle{score = Score2, max_power = MaxPower2} = RankInfo2,
    rank_misc:cmp([{Score1, Score2}, {MaxPower1, MaxPower2}]).

%% 角色进程调用
role_pre_enter(RoleID, MaxPower) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_pre_enter, RoleID, MaxPower}).

role_get_rank_info(RoleID) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_get_rank_info, RoleID}).

role_get_battle(RoleID) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_get_battle, RoleID}).

get_p_battle_rank(RankInfos) ->
    [begin
         #r_role_attr{role_name = RoleName, level = RoleLevel} = common_role_data:get_role_attr(RankRoleID),
         #p_battle_rank{
             role_id = RankRoleID,
             rank = Rank,
             role_name = RoleName,
             score = Score,
             role_level = RoleLevel,
             power = MaxPower,
             camp_id = CampID}
     end || #r_rank_battle{role_id = RankRoleID, camp_id = CampID, rank = Rank, score = Score, max_power = MaxPower} <- RankInfos].

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle_info(i) ->
    do_i();
do_handle_info({gm_camp_change, RoleID, CampID}) ->
    do_gm_camp_change(RoleID, CampID);
do_handle_info(close_all_maps) ->
    close_all_maps();
do_handle_info({role_pre_enter, RoleID, MaxPower}) ->
    do_role_pre_enter(RoleID, MaxPower);
do_handle_info({role_get_rank_info, RoleID}) ->
    do_role_get_rank_info(RoleID);
do_handle_info({role_get_battle, RoleID}) ->
    get_role_battle(RoleID);
do_handle_info({role_enter_map, RoleID}) ->
    do_role_enter_map(RoleID);
do_handle_info({role_leave_map, RoleID}) ->
    do_role_leave_map(RoleID);
do_handle_info({role_be_killed, KilledRoleID, SrcRoleID, AssistRoles}) ->
    do_role_be_killed(KilledRoleID, SrcRoleID, AssistRoles);
do_handle_info({monster_dead, ExtraID, OldCampID, CampID}) ->
    do_tower_change(ExtraID, OldCampID, CampID, 1);
do_handle_info(Info) ->
    ?ERROR_MSG("unkonw info : ~w", [Info]).

do_i() ->
    {get_battle_ctrl(), ets:tab2list(?ETS_RANK_BATTLE), ets:tab2list(?ETS_MAP_BATTLE), ets:tab2list(?ETS_ROLE_BATTLE)}.

do_gm_camp_change(RoleID, CampID) ->
    RoleBattle = get_role_battle(RoleID),
    set_role_battle(RoleBattle#r_role_battle{camp_id = CampID}).

do_role_pre_enter(RoleID, MaxPower) ->
    case catch check_pre_enter(RoleID, MaxPower) of
        {ok, ExtraID, CampID} -> %% 之前进入过地图
            {ok, common_config:get_server_id(), ExtraID, CampID, get_camp_id_pos(CampID)};
        {ok, ExtraID, CampID, IsNewMap, BattleCtrl, MapBattle, RoleBattle} ->
            set_role_battle(RoleBattle),
            set_map_battle(MapBattle),
            set_battle_ctrl(BattleCtrl),
            ?IF(IsNewMap, start_map(ExtraID + 1), ok),
            do_battle_rank(ExtraID),
            {ok, common_config:get_server_id(), ExtraID, CampID, get_camp_id_pos(CampID)};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_pre_enter(RoleID, MaxPower) ->
    #r_activity{status = Status} = get_activity(),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_PRE_ENTER_010)),
    #r_role_battle{extra_id = OldExtraID, camp_id = OldCampID} = RoleBattle = get_role_battle(RoleID),
    activity_misc:check_role_level(?ACTIVITY_BATTLE, RoleID),
    case OldExtraID =:= 0 of
        true ->
            #r_battle_ctrl{cur_extra_id = CurExtraID, cur_role_num = RoleNum} = BattleCtrl = get_battle_ctrl(),
            MapBattle = get_map_battle(CurExtraID),
            {CampID, MapBattle2} = get_enter_camp_id(RoleID, MaxPower, MapBattle),
            RoleNum2 = RoleNum + 1,
            BattleCtrl2 = BattleCtrl#r_battle_ctrl{cur_role_num = RoleNum2},
            RoleBattle2 = RoleBattle#r_role_battle{extra_id = CurExtraID, camp_id = CampID, max_power = MaxPower},
            {ok, CurExtraID, CampID, RoleNum2 >= ?MAX_BATTLE_ROLE_NUM, BattleCtrl2, MapBattle2, RoleBattle2};
        _ ->
            {ok, OldExtraID, OldCampID}
    end.

get_enter_camp_id(RoleID, MaxPower, MapBattle) ->
    #r_map_battle{all_role_ids = AllRoleIDs, power_list = PowerList} = MapBattle,
    [#p_kvt{id = CampID, val = OldPower, type = OldNum} = KVT|Remain] = PowerList,
    KVT2 = KVT#p_kvt{val = OldPower + MaxPower, type = OldNum + 1},
    PowerList2 = lists:sort(
        fun(#p_kvt{val = Val1, type = Type1}, #p_kvt{val = Val2, type = Type2}) ->
            OneNum = ?MAX_BATTLE_ROLE_NUM div 3,
            if
                Type1 >= OneNum ->
                    false;
                Type2 >= OneNum ->
                    true;
                true ->
                    Val1 < Val2
            end
        end, [KVT2|Remain]),
    MapBattle2 = MapBattle#r_map_battle{all_role_ids = [RoleID|AllRoleIDs], power_list = PowerList2},
    {CampID, MapBattle2}.

get_camp_id_pos(CampID) ->
    {ok, BornPos} = map_misc:get_born_pos(#r_born_args{map_id = ?MAP_BATTLE, camp_id = CampID}),
    BornPos.

do_role_get_rank_info(RoleID) ->
    #r_role_battle{extra_id = ExtraID} = mod_battle:get_role_battle(RoleID),
    get_p_battle_rank(mod_battle:get_rank_info(ExtraID)).

do_role_enter_map(RoleID) ->
    #r_role_battle{extra_id = ExtraID} = get_role_battle(RoleID),
    #r_map_battle{enter_role_ids = EnterRoleIDs} = MapBattle = get_map_battle(ExtraID),
    EnterRoleIDs2 = [RoleID|EnterRoleIDs],
    set_map_battle(MapBattle#r_map_battle{enter_role_ids = EnterRoleIDs2}).

%% 玩家离开地图
do_role_leave_map(RoleID) ->
    #r_role_battle{extra_id = ExtraID} = get_role_battle(RoleID),
    #r_map_battle{enter_role_ids = EnterRoleIDs} = MapBattle = get_map_battle(ExtraID),
    EnterRoleIDs2 = lists:delete(RoleID, EnterRoleIDs),
    set_map_battle(MapBattle#r_map_battle{enter_role_ids = EnterRoleIDs2}).

%% 玩家被杀
do_role_be_killed(KilledRoleID, SrcRoleID, AssistRoles) ->
    #r_role_battle{combo_kill = KilledComboKill} = KilledRoleBattle = get_role_battle(KilledRoleID),
    set_role_battle(KilledRoleBattle#r_role_battle{combo_kill = 0}),
    #r_role_battle{extra_id = ExtraID, combo_kill = ComboKill, camp_id = SrcCampID} = SrcRoleBattle = get_role_battle(SrcRoleID),
    ComboKill2 = ComboKill + 1,
    SrcRoleBattle2 = SrcRoleBattle#r_role_battle{combo_kill = ComboKill2},
    {KillScore, AssistScore, IsEndCombo} = get_killed_args(KilledComboKill, cfg_battle_combo_kill:list(), 0, 0, false),
    do_role_add_score(SrcRoleBattle2, KillScore),
    [ begin
          #r_role_battle{camp_id = CampID} = AssistBattle = get_role_battle(AssistRoleID),
          ?IF(CampID =:= SrcCampID, do_role_add_score(AssistBattle, AssistScore), ok)
      end|| AssistRoleID <- AssistRoles],

    SrcRoleName = common_role_data:get_role_name(SrcRoleID),
    KilledRoleName = common_role_data:get_role_name(KilledRoleID),
    case IsEndCombo of %% 被终结连杀提示
        true ->
            DataRecord = #m_battle_end_combo_kill_toc{kill_role_name = SrcRoleName, killed_role_name = KilledRoleName, kill_num = KilledComboKill},
            do_broadcast_by_extra_id(ExtraID, DataRecord);
        _ ->
            ok
    end,
    case lib_config:find(cfg_battle_combo_kill, ComboKill2) of %% 连杀提示
        [_Content] ->
            do_broadcast_by_extra_id(ExtraID, #m_battle_combo_kill_toc{role_name = SrcRoleName, kill_num = ComboKill2});
        _ ->
            ok
    end,
    do_battle_rank(ExtraID).

get_killed_args(_KilledComboKill, [], KillScoreAcc, AssistScoreAcc, IsEndCombo) ->
    {KillScoreAcc, AssistScoreAcc, IsEndCombo};
get_killed_args(KilledComboKill, [{NeedNum, Config}|Acc], KillScoreAcc, AssistScoreAcc, IsEndCombo) ->
    case KilledComboKill >= NeedNum of
        true ->
            #c_battle_combo{kill_score = KillScore, assist_score = AssistScore} = Config,
            IsEndCombo2 = ?IF(NeedNum > 0, true, IsEndCombo),
            get_killed_args(KilledComboKill, Acc, KillScore, AssistScore, IsEndCombo2);
        _ ->
            {KillScoreAcc, AssistScoreAcc, IsEndCombo}
    end.


%% 怪物被杀或者buff改变，需要改一下聚灵桩的个数
do_tower_change(ExtraID, OldCampID, CampID, AddNum) ->
    #r_map_battle{tower_list = TowerList} = MapBattle = get_map_battle(ExtraID),
    #p_kv{val = Num} = NewKV = lists:keyfind(CampID, #p_kv.id, TowerList),
    TowerList2 = lists:keyreplace(CampID, #p_kv.id, TowerList, NewKV#p_kv{val = Num + AddNum}),
    case lists:keyfind(OldCampID, #p_kv.id, TowerList2) of
        #p_kv{val = OldNum} = OldKv ->
            TowerList3 = lists:keyreplace(OldCampID, #p_kv.id, TowerList2, OldKv#p_kv{val = OldNum - AddNum});
        _ ->
            TowerList3 = TowerList2
    end,
    set_map_battle(MapBattle#r_map_battle{tower_list = TowerList3}).

%% 对总排行进行排序
do_all_rank() ->
    AllEs = lib_minheap:get_all_elements(?MODULE),
    SortAllEs = lists:sort(fun cmp_rank/2, AllEs),
    {SortAllEs1, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#r_rank_battle{rank = Rank},
            {[E1|Acc], Rank + 1}
        end, {[], 1}, lists:reverse(SortAllEs)),
    SortAllEs1.

%% 定时加积分
do_loop_add_score() ->
    MapBattles = ets:tab2list(?ETS_MAP_BATTLE),
    [ do_loop_add_score2(EnterRoleIDs, TowerList) || #r_map_battle{enter_role_ids = EnterRoleIDs, tower_list = TowerList} <- MapBattles],
    #r_battle_ctrl{extra_id_list = ExtraIDList} = get_battle_ctrl(),
    [ do_battle_rank(ExtraID) || ExtraID <- ExtraIDList].

do_loop_add_score2([], _TowerList) ->
    ok;
do_loop_add_score2([RoleID|R], TowerList) ->
    #r_role_battle{camp_id = CampID} = RoleBattle = get_role_battle(RoleID),
    #p_kv{val = AddMulti} = lists:keyfind(CampID, #p_kv.id, TowerList),
    do_role_add_score(RoleBattle, ?BATTLE_LOOP_SCORE * AddMulti),
    do_loop_add_score2(R, TowerList).

%% 加角色积分（有可能获取奖励）
do_role_add_score(RoleBattle, AddScore) when AddScore > 0 ->
    #r_role_battle{role_id = RoleID, camp_id = CampID, score = Score, max_power = MaxPower} = RoleBattle,
    Score2 = Score + AddScore,
    RoleBattle2 = RoleBattle#r_role_battle{score = Score2},
    set_role_battle(RoleBattle2),

    AllRewards = cfg_battle_score_reward:list(),
    {GoodsList, ExpRate} = do_get_score_reward(Score, Score2, AllRewards),
    ?IF(GoodsList =/= [], role_misc:give_goods(RoleID, ?ITEM_GAIN_BATTLE_SCORE, GoodsList), ok),
    ?IF(ExpRate > 0, mod_role_level:add_level_exp(RoleID, ExpRate, ?EXP_ADD_FROM_BATTLE_SCORE), ok),
    Rank = #r_rank_battle{role_id = RoleID, score = Score2, camp_id = CampID, max_power = MaxPower},
    lib_minheap:insert_element(?MODULE, RoleID, Rank);
do_role_add_score(_RoleBattle, _AddScore) ->
    ok.

do_get_score_reward(_Score, _Score2, []) ->
    {[], 0};
do_get_score_reward(Score, Score2, [{NeedScore, #c_battle_score_reward{exp_rate = ExpRate, item_reward = ItemReward}}|R]) ->
    case Score < NeedScore andalso Score2 >= NeedScore of
        true ->
            ItemReward2 = common_misc:get_item_reward(ItemReward),
            {[ #p_goods{type_id = TypeID, num = Num, bind = true}|| {TypeID, Num} <- ItemReward2], ExpRate};
        _ ->
            do_get_score_reward(Score, Score2, R)
    end.

%% 单场内的排行更新
do_battle_rank(ExtraID) ->
    #r_map_battle{all_role_ids = EnterRoleIDs} = get_map_battle(ExtraID),
    AllEs =
        [ begin
              #r_role_battle{score = Score, camp_id = CampID, max_power = MaxPower} = get_role_battle(RoleID),
              #r_rank_battle{role_id = RoleID, camp_id = CampID, score = Score, max_power = MaxPower}
          end|| RoleID <- EnterRoleIDs],
    {NewRanks, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#r_rank_battle{rank = Rank},
            {[E1|Acc], Rank + 1}
        end, {[], 1}, lists:reverse(lists:sort(fun cmp_rank/2, AllEs))),
    set_rank_info(ExtraID, NewRanks),
    do_broadcast_rank(ExtraID, NewRanks).

%% 广播排名
do_broadcast_rank(ExtraID, RankInfos) ->
    RankInfos2 = get_p_battle_rank(RankInfos),
    DataRecord = #m_battle_rank_info_toc{ranks = RankInfos2},
    do_broadcast_by_extra_id(ExtraID, DataRecord).

do_broadcast_by_extra_id(ExtraID, DataRecord) ->
    #r_map_battle{enter_role_ids = RoleIDs} = get_map_battle(ExtraID),
    common_broadcast:bc_record_to_roles(RoleIDs, DataRecord).

%%%===================================================================
%%% dict
%%%===================================================================
get_activity_mod() ->
    activity_misc:get_activity_mod(?ACTIVITY_BATTLE).

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_BATTLE).

%% 战场控制dict
set_battle_ctrl(BattleCtrl) ->
    erlang:put({?MODULE, battle_ctrl}, BattleCtrl).
get_battle_ctrl() ->
    erlang:get({?MODULE, battle_ctrl}).

%% 地图数据
set_map_battle(MapBattle) ->
    ets:insert(?ETS_MAP_BATTLE, MapBattle).
get_map_battle(ExtraID) ->
    case ets:lookup(?ETS_MAP_BATTLE, ExtraID) of
        [#r_map_battle{} = MapBattle] ->
            MapBattle;
        _ ->
            #r_map_battle{extra_id = ExtraID}
    end.

%% 人物数据
set_role_battle(RoleBattle) ->
    ets:insert(?ETS_ROLE_BATTLE, RoleBattle).
get_role_battle(RoleID) ->
    case ets:lookup(?ETS_ROLE_BATTLE, RoleID) of
        [#r_role_battle{} = RoleBattle] ->
            RoleBattle;
        _ ->
            #r_role_battle{role_id = RoleID}
    end.

%% 获取战场排行信息
set_rank_info(RankID, RankInfos) ->
    ets:insert(?ETS_RANK_BATTLE, {RankID, RankInfos}).
get_rank_info(RankID) ->
    case ets:lookup(?ETS_RANK_BATTLE, RankID) of
        [{_RankID, RankInfos}] ->
            RankInfos;
        _ ->
            []
    end.

cancel_time_ref() ->
    case erlang:erase({?MODULE, time_ref}) of
        TimeRef when erlang:is_reference(TimeRef) ->
            erlang:cancel_timer(TimeRef);
        _ ->
            ok
    end.
set_time_ref(TimeRef) ->
    erlang:put({?MODULE, time_ref}, TimeRef).

get_battle_rank_reward(_Rank, []) ->
    false;
get_battle_rank_reward(Rank, [{{MinRank, MaxRank}, Config}|R]) ->
    case MinRank =< Rank andalso Rank =< MaxRank of
        true ->
            Config;
        _ ->
            get_battle_rank_reward(Rank, R)
    end.