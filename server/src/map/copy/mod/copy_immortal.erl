%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2018 14:26
%%%-------------------------------------------------------------------
-module(copy_immortal).
-author("laijichang").
-include("proto/copy_immortal.hrl").
-include("proto/mod_role_copy.hrl").
-include("global.hrl").
-include("copy.hrl").
-include("monster.hrl").

%% API
-export([
    role_init/1,
    init/1,
    role_enter/1,
    loop/1,
    handle/1,
    monster_enter/1,
    monster_dead/1,
    get_run_num/1,
    immortal_reach_pos/1
]).

-export([
    immortal_reset/3,
    immortal_summon/1
]).

-export([
    copy_clean/1,
    get_extra_star_reward/2
]).

role_init(CopyInfo) ->
    SkillList = [ #p_kvt{id = SkillID, type = UseTimes}|| {SkillID, #c_copy_immortal_skill{use_times = UseTimes}}<- cfg_copy_immortal_skill:list()],
    PosList = common_misc:get_global_string_list(?GLOBAL_IMMORTAL_POS),
    set_pos_list([ map_misc:get_pos_by_offset_pos(Mx, My)|| {Mx, My} <- PosList]),
    MaxWave = lists:max( [ WaveID|| {{WaveID, _MinLevel, _MaxLevel}, _Config}<- cfg_copy_immortal_wave:list()]),
    Immortal = #r_copy_immortal{max_wave = MaxWave, skill_list = SkillList},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal, all_wave = MaxWave},
    copy_data:set_copy_info(CopyInfo2).

init(CopyInfo) ->
    #r_map_copy{mod_args = #r_copy_immortal{guard_list = GuardList}} = CopyInfo,
    do_init_wave(CopyInfo),
    [ begin
          mod_role_copy:immortal_start(RoleID, GuardList),
          common_misc:unicast(RoleID, #m_copy_immortal_start_toc{})
      end || RoleID <- mod_map_ets:get_in_map_roles()].

role_enter(RoleID) ->
    #r_map_copy{mod_args = ModArgs} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{
        guard_list = GuardList,
        skill_list = SkillList,
        remain_num = RemainNum,
        run_num = RunNum,
        summon_boss_round = SummonRound,
        is_auto_summon = IsAutoSummon
    } = ModArgs,
    DataRecord = #m_copy_immortal_info_toc{
        guard_list = GuardList,
        skill_list = SkillList,
        remain_num = RemainNum,
        run_num = RunNum,
        summon_boss_round = SummonRound,
        is_auto_summon = IsAutoSummon
    },
    common_misc:unicast(RoleID, DataRecord),
    try_summon_boss(CopyInfo).

loop(Now) ->
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal, copy_level = CopyLevel} = CopyInfo = copy_data:get_copy_info(),
    case CurProgress > 0 of %% 刷怪了
        true ->
            #r_copy_immortal{monster_list = MonsterList} = Immortal,
            case MonsterList of
                [{TypeID, Time}|MonsterList2] when Now >= Time ->
                    do_born_monster(TypeID, CopyLevel),
                    Immortal2 = Immortal#r_copy_immortal{monster_list = MonsterList2},
                    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
                    copy_data:set_copy_info(CopyInfo2);
                _ ->
                    ok
            end;
        _ ->
            ignore
    end.

handle({#m_copy_immortal_start_tos{}, RoleID, _PID}) ->
    do_immortal_start(RoleID);
handle({#m_copy_immortal_set_guard_tos{guard_list = Guard}, RoleID, _PID}) ->
    do_set_guard(RoleID, Guard);
handle({#m_copy_immortal_use_skill_tos{skill_id = SkillID}, RoleID, _PID}) ->
    do_use_skill(RoleID, SkillID);
handle({#m_copy_immortal_auto_summon_tos{is_auto_summon = IsAutoSummon}, RoleID, _PID}) ->
    do_auto_summon(RoleID, IsAutoSummon);
handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE, Info]).

monster_enter({MapInfo}) ->
    ?IF(is_summon_boss(MapInfo), summon_boss_enter(MapInfo), ok).

summon_boss_enter(_MapInfo) ->
    #r_map_copy{mod_args = Immortal} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{remain_num = RemainNum} = Immortal,
    RemainNum2 = RemainNum + 1,
    Immortal2 = Immortal#r_copy_immortal{remain_num = RemainNum2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    DataRecord = #m_copy_immortal_remain_monster_toc{remain_num = RemainNum2},
    map_server:send_all_gateway(DataRecord),
    copy_data:set_copy_info(CopyInfo2).

monster_dead({MapInfo, _SrcID, _SrcType}) ->
    ?IF(is_enemy(MapInfo), monster_dead2(MapInfo), ok).

monster_dead2(_MapInfo) ->
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{max_wave = MaxWave, monster_list = MonsterList, remain_num = RemainNum, next_remain_num = NeedRemainNum} = Immortal,
    RemainNum2 = RemainNum - 1,
    Immortal2 = Immortal#r_copy_immortal{remain_num = RemainNum2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    DataRecord = #m_copy_immortal_remain_monster_toc{remain_num = RemainNum2},
    map_server:send_all_gateway(DataRecord),
    copy_data:set_copy_info(CopyInfo2),
    case CurProgress >= MaxWave andalso MonsterList =:= [] andalso RemainNum2 =< 0 of
        true ->%% 结束
            copy_common:do_copy_end(?COPY_SUCCESS);
        _ ->
            ?IF(MonsterList =:= [] andalso RemainNum2 =< NeedRemainNum, do_init_wave(CopyInfo2), ok)
    end.

get_run_num(CopyInfo) ->
    #r_map_copy{mod_args = #r_copy_immortal{run_num = RunNum}} = CopyInfo,
    RunNum.

immortal_reach_pos(MonsterID) ->
    case mod_map_ets:get_actor_mapinfo(MonsterID) of
        #r_map_actor{} ->
            mod_map_actor:reduce_hp(MonsterID, MonsterID, 999999999999),
            #r_map_copy{mod_args = Immortal} = CopyInfo = copy_data:get_copy_info(),
            #r_copy_immortal{run_num = RunNum} = Immortal,
            RunNum2 = RunNum + 1,
            Immortal2 = Immortal#r_copy_immortal{run_num = RunNum2},
            CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
            copy_data:set_copy_info(CopyInfo2),
            DataRecord = #m_copy_immortal_run_monster_toc{run_num = RunNum2},
            map_server:send_all_gateway(DataRecord);
        _ ->
            ok
    end.


immortal_reset(MapPID, RoleID, GuardList) ->
    case map_server:is_map_process() of
        true ->
            do_immortal_reset(RoleID, GuardList);
        _ ->
            map_misc:info(MapPID, fun() -> ?MODULE:immortal_reset(MapPID, RoleID, GuardList) end)
    end.

immortal_summon(MapPID) ->
    case map_server:is_map_process() of
        true ->
            do_immortal_summon();
        _ ->
            map_misc:call(MapPID, fun() -> ?MODULE:immortal_summon(MapPID) end)
    end.
%%%===================================================================
%%% Internal functions
%%%===================================================================
do_init_wave(CopyInfo) ->
    Now = time_tool:now(),
    #r_map_copy{cur_progress = CurProgress, copy_level = CopyLevel, mod_args = Immortal} = CopyInfo,
    #c_copy_immortal_wave{
        monster = Monster,
        boss_type_id = BossTypeID,
        interval = Interval,
        need_remain_num = NeedRemainNum} = get_wave_config(CurProgress + 1, CopyLevel),
    {MonsterList, AddTime} =
        lists:foldl(
            fun({TypeID, Num}, {Acc1, Acc2}) ->
                NewAcc1 = Acc1 ++ [ {TypeID, (Index - 1) * Interval + Acc2 + Now}|| Index <- lists:seq(1, Num)],
                NewAcc2 = Acc2 + Interval * Num,
                {NewAcc1, NewAcc2}
            end, {[], 0}, lib_tool:string_to_intlist(Monster)),
    MonsterList2 = MonsterList ++ [{BossTypeID, AddTime + Now}],
    RemainNum2 = Immortal#r_copy_immortal.remain_num + erlang:length(MonsterList2),
    Immortal2 = Immortal#r_copy_immortal{remain_num = RemainNum2, next_remain_num = NeedRemainNum, monster_list = MonsterList2},
    CurProgress2 = CurProgress + 1,
    CopyInfo2 = CopyInfo#r_map_copy{cur_progress = CurProgress2, mod_args = Immortal2},
    copy_data:set_copy_info(CopyInfo2),
    copy_common:broadcast_update([#p_kv{id = ?COPY_UPDATE_CUR, val = CurProgress2}]),
    DataRecord = #m_copy_immortal_remain_monster_toc{remain_num = RemainNum2},
    map_server:send_all_gateway(DataRecord),
    try_summon_boss(CopyInfo2).

do_born_monster(TypeID, CopyLevel) ->
    [Pos|R] = get_pos_list(),
    MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
    MonsterData2 = MonsterData#r_monster{
        born_pos = Pos,
        td_pos_list = get_td_pos_list(R)},
    mod_map_monster:born_monsters([MonsterData2]).

do_immortal_start(RoleID) ->
    case catch check_immortal_start() of
        ok ->
            copy_common:copy_start();
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_immortal_start_toc{err_code = ErrCode})
    end.

check_immortal_start() ->
    #r_map_copy{cur_progress = CurProgress, mod_args = ModArgs} = copy_data:get_copy_info(),
    ?IF(CurProgress > 0, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    #r_copy_immortal{guard_list = GuardList} = ModArgs,
    GuardConfig = common_misc:get_global_string_list(?GLOBAL_IMMORTAL_GUARD_AND_BOSS),
    AllNum = lists:sum([ Num|| {_TypeID, Num} <- GuardConfig]),
    ?IF(erlang:length(GuardList) >= AllNum, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_START_001)),
    ok.

do_set_guard(RoleID, Guard) ->
    case catch check_set_guard(Guard) of
        {born, CopyInfo2, MonsterData} ->
            mod_map_monster:born_monsters([MonsterData]),
            copy_data:set_copy_info(CopyInfo2),
            common_misc:unicast(RoleID, #m_copy_immortal_set_guard_toc{guard_list = Guard});
        {delete, CopyInfo2, TDIndex} ->
            mod_map_monster:immortal_delete_guard(TDIndex),
            copy_data:set_copy_info(CopyInfo2),
            common_misc:unicast(RoleID, #m_copy_immortal_set_guard_toc{guard_list = Guard});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_immortal_set_guard_toc{err_code = ErrCode})
    end.

check_set_guard(Guard) ->
    #p_kv{id = AreaID, val = TypeID} = Guard,
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal, copy_level = CopyLevel} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{guard_list = GuardList} = Immortal,
    [[Mx, My]] = lib_config:find(cfg_copy_immortal_area, AreaID),
    ?IF(CurProgress =< 0, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SET_GUARD_004)),
    case lists:keytake(AreaID, #p_kv.id, GuardList) of
        {value, #p_kv{}, GuardList2} ->
            ?IF(TypeID =:= 0, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SET_GUARD_001)),
            Immortal2 = Immortal#r_copy_immortal{guard_list = GuardList2},
            CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
            {delete, CopyInfo2, AreaID};
        _ ->
            ?IF(TypeID =:= 0, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SET_GUARD_002), ok),
            GuardConfig = common_misc:get_global_string_list(?GLOBAL_IMMORTAL_GUARD_AND_BOSS),
            {TypeID, AllNum} = lists:keyfind(TypeID, 1, GuardConfig),
            OldNum = erlang:length([ OldTypeID || #p_kv{val = OldTypeID} <- GuardList, OldTypeID =:= TypeID]),
            ?IF(OldNum >= AllNum, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SET_GUARD_003), ok),
            GuardList2 = [Guard|GuardList],
            Immortal2 = Immortal#r_copy_immortal{guard_list = GuardList2},
            CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
            MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
            MonsterData2 = MonsterData#r_monster{born_pos = map_misc:get_pos_by_meter(Mx, My), td_index = AreaID},
            {born, CopyInfo2, MonsterData2}
    end.

do_immortal_reset(RoleID, GuardList) ->
    case catch check_immortal_reset(GuardList) of
        {ok, CopyInfo2, MonsterDatas} ->
            copy_data:set_copy_info(CopyInfo2),
            mod_map_monster:immortal_delete_guard(0),
            mod_map_monster:born_monsters(MonsterDatas),
            common_misc:unicast(RoleID, #m_copy_immortal_reset_guard_toc{guard_list = GuardList});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_immortal_reset_guard_toc{err_code = ErrCode})
    end.

check_immortal_reset(GuardList) ->
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal, copy_level = CopyLevel} = CopyInfo = copy_data:get_copy_info(),
    ?IF(CurProgress =< 0, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_RESET_GUARD_002)),
    #r_copy_immortal{guard_list = NowGuardList} = Immortal,
    ?IF(GuardList =:= NowGuardList, ?THROW_ERR(?ERROR_COPY_IMMORTAL_RESET_GUARD_003), ok),
    Immortal2 = Immortal#r_copy_immortal{guard_list = GuardList},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    MonsterDatas =
        [begin
             [[Mx, My]] = lib_config:find(cfg_copy_immortal_area, AreaID),
             MonsterData = monster_misc:get_dynamic_monster(CopyLevel, TypeID),
             MonsterData#r_monster{born_pos = map_misc:get_pos_by_meter(Mx, My), td_index = AreaID}
         end|| #p_kv{id = AreaID, val = TypeID}<- GuardList],
    {ok, CopyInfo2, MonsterDatas}.

do_use_skill(RoleID, SkillID) ->
    case catch check_use_skill(SkillID) of
        {ok, CopyInfo2, Skill, AddBuffs} ->
            copy_data:set_copy_info(CopyInfo2),
            mod_map_monster:immortal_add_buff(AddBuffs),
            common_misc:unicast(RoleID, #m_copy_immortal_use_skill_toc{skill = Skill});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_immortal_use_skill_toc{err_code = ErrCode})
    end.

check_use_skill(SkillID) ->
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{skill_list = SkillList} = Immortal,
    Now = time_tool:now(),
    #p_kvt{val = UseTime, type = Times} = Skill = lists:keyfind(SkillID, #p_kvt.id, SkillList),
    [#c_copy_immortal_skill{cd = CD, buff_id = BuffID}] = lib_config:find(cfg_copy_immortal_skill, SkillID),
    ?IF(Now >= UseTime, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_USE_SKILL_001)),
    ?IF(Times =< 0, ?THROW_ERR(?ERROR_COPY_IMMORTAL_USE_SKILL_002), ok),
    ?IF(CurProgress > 0, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_USE_SKILL_003)),
    Skill2 = Skill#p_kvt{val = Now + CD, type = Times - 1},
    SkillList2 = lists:keyreplace(SkillID, #p_kvt.id, SkillList, Skill2),
    Immortal2 = Immortal#r_copy_immortal{skill_list = SkillList2},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    {ok, CopyInfo2, Skill2, [#buff_args{buff_id = BuffID}]}.

do_auto_summon(RoleID, IsAutoSummon) ->
    case catch check_auto_summon(IsAutoSummon) of
        {ok, CopyInfo} ->
            copy_data:set_copy_info(CopyInfo),
            common_misc:unicast(RoleID, #m_copy_immortal_auto_summon_toc{is_auto_summon = IsAutoSummon});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_immortal_auto_summon_toc{err_code = ErrCode})
    end.

check_auto_summon(IsAutoSummon) ->
    #r_map_copy{mod_args = Immortal} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{is_auto_summon = OldIsAuto} = Immortal,
    ?IF(IsAutoSummon =:= OldIsAuto, ?THROW_ERR(?ERROR_COPY_IMMORTAL_AUTO_SUMMON_001), ok),
    Immortal2 = Immortal#r_copy_immortal{is_auto_summon = IsAutoSummon},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    {ok, CopyInfo2}.

do_immortal_summon() ->
    case catch check_immortal_summon() of
        {ok, CopyInfo, CopyLevel, SummonRound, BossTypeID} ->
            do_born_monster(BossTypeID, CopyLevel),
            copy_data:set_copy_info(CopyInfo),
            set_summon_boss(BossTypeID),
            {ok, SummonRound};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_immortal_summon() ->
    #r_map_copy{cur_progress = CurProgress, mod_args = Immortal, copy_level = CopyLevel} = CopyInfo = copy_data:get_copy_info(),
    #r_copy_immortal{summon_boss_round = SummonRound} = Immortal,
    ?IF(CurProgress =< 0, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SUMMON_BOSS_003), ok),
    ?IF(CurProgress > SummonRound, ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SUMMON_BOSS_002)),
    Immortal2 = Immortal#r_copy_immortal{summon_boss_round = CurProgress},
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = Immortal2},
    #c_copy_immortal_wave{summon_boss = BossTypeID} = get_wave_config(CurProgress, CopyLevel),
    {ok, CopyInfo2, CopyLevel, CurProgress, BossTypeID}.

try_summon_boss(CopyInfo) ->
    #r_map_copy{cur_progress = CurProgress, mod_args = ModArgs} = CopyInfo,
    #r_copy_immortal{summon_boss_round = SummonBossRound, is_auto_summon = IsAutoSummon} = ModArgs,
    case CurProgress > SummonBossRound andalso IsAutoSummon of
        true ->
            [ mod_role_copy:immortal_auto_summon(RoleID) || RoleID <- mod_map_ets:get_in_map_roles()];
        _ ->
            ok
    end.

get_td_pos_list(R) ->
    [ {Tx, Ty}|| #r_pos{tx = Tx, ty = Ty} <- R].

is_enemy(MapInfo) ->
    #r_map_actor{camp_id = CampID} = MapInfo,
    CampID =/= ?DEFAULT_CAMP_ROLE.

is_summon_boss(MapInfo) ->
    #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    get_summon_boss() =:= TypeID.

get_wave_config(CurWave, CopyLevel) ->
    List = cfg_copy_immortal_wave:list(),
    get_wave_config2(CurWave, CopyLevel, List).

get_wave_config2(CurWave, CopyLevel, []) ->
    erlang:throw({config_not_found, CurWave, CopyLevel});
get_wave_config2(CurWave, CopyLevel, [{{NeedWave, MinLevel, MaxLevel}, Config}|R]) ->
    case NeedWave =:= CurWave andalso MinLevel =< CopyLevel andalso CopyLevel =< MaxLevel of
        true ->
            Config;
        _ ->
            get_wave_config2(CurWave, CopyLevel, R)
    end.

copy_clean(CleanArgs) ->
    #r_clean_args{
        role_level = RoleLevel,
        num = Num,
        boss_num = BossNum} = CleanArgs,
    ConfigList = [ Config|| {{_WaveID, MinLevel, MaxLevel}, Config} <- lib_config:list(cfg_copy_immortal_wave), MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel],
    ?IF(BossNum > erlang:length(ConfigList), ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    copy_clean2(ConfigList, Num, BossNum, [], 0).

copy_clean2([], _Num, _BossNum, GoodsList, AddExp) ->
    {GoodsList, lib_tool:ceil(AddExp)};
copy_clean2([Wave|R], Num, BossNum, GoodsAcc, AddExpAcc) ->
    #c_copy_immortal_wave{monster = MonsterString, summon_boss = SummonBoss, boss_type_id = BossTypeID} = Wave,
    {BossNum2, BossList} =
        case BossNum > 0 of
            true ->
                {BossNum - 1, [{SummonBoss, 1}, {BossTypeID, 1}]};
            _ ->
                {BossNum, [{BossTypeID, 1}]}
        end,
    {AddGoods, AddExp} = get_monster_clean_reward(BossList ++ lib_tool:string_to_intlist(MonsterString), Num),
    copy_clean2(R, Num, BossNum2, AddGoods ++ GoodsAcc, AddExp + AddExpAcc).

%% 返回{GoodsList, AddExp}
get_monster_clean_reward(MonsterList, Num) ->
    lists:foldl(
        fun({MonsterTypeID, MonsterNum}, {GoodsAcc, ExpAcc}) ->
            {AddGoods, AddExp} = get_monster_clean_reward2(MonsterTypeID, MonsterNum, Num),
            {AddGoods ++ GoodsAcc, AddExp + ExpAcc}
        end, {[], 0}, MonsterList).

get_monster_clean_reward2(MonsterTypeID, MonsterNum, Num) ->
    #c_monster{add_exp = AddExp, drop_id_list = DropIDList} = monster_misc:get_monster_config(MonsterTypeID),
    Goods =
    lists:flatten([ [ #p_goods{type_id = ItemTypeID,
        num = ItemNum,
        bind = Bind} || {ItemTypeID, ItemNum, Bind} <- mod_map_drop:get_drop_item_list2(DropID)] || DropID <- lists:flatten(lists:duplicate(MonsterNum * Num, DropIDList))]),
    {Goods, AddExp * MonsterNum * Num}.

get_extra_star_reward(Stars, RoleLevel) ->
    ConfigList = cfg_copy_immortal_star:list(),
    Config = get_extra_star_reward2(RoleLevel, ConfigList),
    #c_copy_immortal_star{base_rewards = BaseRewardString,
        star_1_rewards = Star1Rewards,
        star_2_rewards = Star2Rewards,
        star_3_rewards = Star3Rewards} = Config,
    BaseRewards = common_misc:get_item_reward(BaseRewardString),
    StarRewards =
        case lists:keyfind(Stars, 1, [{?COPY_STAR_1, Star1Rewards}, {?COPY_STAR_2, Star2Rewards}, {?COPY_STAR_3, Star3Rewards}]) of
            {_, RewardString} ->
                common_misc:get_item_reward(RewardString);
            _ ->
                []
        end,
    BaseRewards ++ StarRewards.

get_extra_star_reward2(_RoleLevel, []) ->
    undefined;
get_extra_star_reward2(RoleLevel, [{NeedLevel, Config}|R]) ->
    case RoleLevel > NeedLevel of
        true ->
            get_extra_star_reward2(RoleLevel, R);
        _ ->
            Config
    end.



set_pos_list(PosList) ->
    erlang:put({?MODULE, pos_list}, PosList).
get_pos_list() ->
    erlang:get({?MODULE, pos_list}).

set_summon_boss(BossTypeID) ->
    erlang:put({?MODULE, summon_boss}, BossTypeID).
get_summon_boss() ->
    erlang:get({?MODULE, summon_boss}).