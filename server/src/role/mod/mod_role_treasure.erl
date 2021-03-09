%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     寻宝
%%% @end
%%% Created : 06. 六月 2018 10:52
%%%-------------------------------------------------------------------
-module(mod_role_treasure).
-author("laijichang").
-include("role.hrl").
-include("role_extra.hrl").
-include("copy.hrl").
-include("proto/mod_role_treasure.hrl").

%%%% API
-export([
    init/1,
    online/1,
    handle/2
]).

init(#r_role{role_id = RoleID, role_treasure = undefined} = State) ->
    RoleTreasure = #r_role_treasure{role_id = RoleID},
    State#r_role{role_treasure = RoleTreasure};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_treasure = RoleTreasure} = State,
    #r_role_treasure{
        equip_logs = EquipLogs,
        equip_weight = EquipWeight,
        rune_free_time = RuneFreeTime,
        summit_logs = SummitLogs,
        summit_weight = SummitWeight} = RoleTreasure,
    DataRecord = #m_treasure_info_toc{
        world_equip_logs = world_data:get_equip_treasure_logs(),
        equip_logs = EquipLogs,
        rune_free_time = RuneFreeTime,
        summit_logs = SummitLogs,
        world_summit_logs = world_data:get_summit_logs(),
        equip_weight = EquipWeight,
        summit_weight = SummitWeight
    },
    common_misc:unicast(RoleID, DataRecord),
    State.

handle({#m_equip_treasure_tos{times = Times}, RoleID, _PID}, State) ->
    do_equip_treasure(RoleID, Times, State);
handle({#m_summit_treasure_tos{times = Times}, RoleID, _PID}, State) ->
    do_summit_treasure(RoleID, Times, State);
handle({#m_rune_treasure_tos{times = Times}, RoleID, _PID}, State) ->
    do_rune_treasure(RoleID, Times, State).

%% 装备寻宝
do_equip_treasure(RoleID, Times, State) ->
    case catch check_equip_treasure(Times, State) of
        {ok, AssetDoing, BagDoing, EquipWeight, AddLogs, WorldLogList, _RoleName, _NoticeGoods, Log, State2} ->
            world_act_server:add_treasure_logs(WorldLogList),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_equip_treasure_toc{add_log_list = AddLogs, equip_weight = EquipWeight}),
            mod_role_dict:add_background_logs(Log),
            hook_role:equip_treasure(State4,Times);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_treasure_toc{err_code = ErrCode}),
            State
    end.

check_equip_treasure(Times, State) ->
    ?IF(Times =:= ?TREASURE_ONE orelse Times =:= ?TREASURE_TEN orelse Times =:= ?TREASURE_FIFTY, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_attr = #r_role_attr{level = RoleLevel, category = Category, role_name = RoleName}, role_treasure = RoleTreasure} = State,
    #r_role_treasure{equip_times = EquipTimes, equip_weight = EquipWeight, equip_logs = EquipLogs} = RoleTreasure,
    MaxTimes = common_misc:get_global_int(?GLOBAL_MAX_TREASURE_TIMES),
    [#c_global{string = String, list = [TreasureKey], int = SilverItem}] = lib_config:find(cfg_global, ?GLOBAL_EQUIP_TREASURE),
    TimesList = common_misc:get_global_string_list(String),
    {DecreaseDoing, GoldDoing, UseNum, LogGold} =
        case lists:keyfind(Times, 1, TimesList) of
            {Times, NeedGold} ->
                {_, OneTimesGold} = lists:keyfind(1, 1, TimesList),
                KeyNum = mod_role_bag:get_num_by_type_id(TreasureKey, State),
                get_treasure_args(TreasureKey, KeyNum, OneTimesGold, NeedGold, ?ITEM_REDUCE_EQUIP_TREASURE, ?ASSET_GOLD_REDUCE_FROM_EQUIP_TREASURE, State);
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    ?IF(EquipTimes + Times < MaxTimes, ok, ?THROW_ERR(?ERROR_EQUIP_TREASURE_001)),
    mod_role_bag:check_bag_empty_grid(?BAG_ID_TREASURE, Times + 1, State),
    AssetDoing = GoldDoing ++ [{add_score, ?ASSET_TREASURE_SCORE_ADD_FROM_EQUIP_TREASURE, ?ASSET_TREASURE_SCORE, Times}],
    {GoodsList, NoticeGoods, EquipWeight2} = gen_equip_treasure(Times, RoleLevel, Category, EquipWeight),
    AddLogs = [TypeID || #p_goods{type_id = TypeID} <- GoodsList],
    GoodsList2 = [#p_goods{type_id = SilverItem, num = Times, bind = true}|GoodsList],
    BagDoing = DecreaseDoing ++ [{create, ?BAG_ID_TREASURE, ?ITEM_GAIN_EQUIP_TREASURE, GoodsList2}],
    [#c_global{int = LogNum}] = lib_config:find(cfg_global, ?GLOBAL_TREASURE_LOGS),
    EquipLogs2 = lists:sublist(AddLogs ++ EquipLogs, LogNum),
    WorldLogList = get_world_log_list(NoticeGoods, RoleName, []),
    RoleTreasure2 = RoleTreasure#r_role_treasure{equip_times = EquipTimes + Times, equip_logs = EquipLogs2, equip_weight = EquipWeight2},
    State2 = State#r_role{role_treasure = RoleTreasure2},
    Log = get_treasure_log(?LOG_EQUIP_TREASURE, Times, TreasureKey, UseNum, LogGold, GoodsList2, State),
    {ok, AssetDoing, BagDoing, EquipWeight2, AddLogs, WorldLogList, RoleName, NoticeGoods, Log, State2}.

gen_equip_treasure(Times, RoleLevel, Category, EquipWeight) ->
    ConfigList = lib_config:list(cfg_equip_treasure),
    [MinWeight, MaxWeight] = common_misc:get_global_list(?GLOBAL_EQUIP_TREASURE_WEIGHT),
    {FirstList, SecondList, ControlList} = get_equip_config(RoleLevel, Category, ConfigList, [], [], []),
    gen_equips(Times, EquipWeight, {MinWeight, MaxWeight, FirstList, SecondList, ControlList}, [], []).

gen_equips(0, EquipWeight, _, GoodsList, NoticeGoods) ->
    {GoodsList, NoticeGoods, EquipWeight};
gen_equips(Times, EquipWeight, {MinWeight, MaxWeight, FirstList, SecondList, ControlList} = Record, GoodsAcc, NoticeAcc) ->
    {IsControl, IsBroadcast, Goods} =
    if
        EquipWeight < MinWeight -> %% 低于最低权重，从初级列表中随机
            gen_one_equip(FirstList);
        MinWeight =< EquipWeight andalso EquipWeight < MaxWeight -> %% 在中间，可以从中级列表中出
            gen_one_equip(SecondList);
        EquipWeight >= MaxWeight -> %% 出货了出货了
            gen_one_equip(ControlList)
    end,
    %% 出了好东西的话，权重清零
    EquipWeight2 = ?IF(IsControl, 0, EquipWeight + 1),
    GoodsAcc2 = [Goods|GoodsAcc],
    NoticeAcc2 = ?IF(IsBroadcast, [Goods|NoticeAcc], NoticeAcc),
    gen_equips(Times - 1, EquipWeight2, Record, GoodsAcc2, NoticeAcc2).

gen_one_equip(WeightList) ->
    Config = lib_tool:get_weight_output(WeightList),
    #c_equip_treasure{type_id = TypeID, bind = IsBind, num = Num, is_control = IsControl, is_broadcast = IsBroadcast} = Config,
    TypeID2 = mod_map_drop:get_item_by_equip_drop_id(TypeID),
    Goods = #p_goods{type_id = TypeID2, num = Num, bind = ?IS_BIND(IsBind)},
    {IsControl > 0, IsBroadcast > 0, Goods}.


get_equip_config(_RoleLevel, _Category, [], FirstList, SecondList, ControlList) ->
    {FirstList, SecondList, ControlList};
get_equip_config(RoleLevel, RoleCategory, [{_ID, Config}|R], FirstList, SecondList, ControlList) ->
    #c_equip_treasure{role_level = LevelList, category = Category, weight = Weight, is_control = IsControl, control_weight = ControlWeight} = Config,
    case LevelList of
        [] ->
            IsLevel = true;
        [MinLevel, MaxLevel] ->
            IsLevel = MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel
    end,
    case IsLevel andalso (Category =:= RoleCategory orelse Category =:= 0) andalso Weight > 0 of
        true ->
            SecondList2 = [{Weight, Config}|SecondList],
            case IsControl > 0 of
                true ->
                    FirstList2 = FirstList,
                    ControlList2 = [{ControlWeight, Config}|ControlList];
                _ ->
                    FirstList2 = [{Weight, Config}|FirstList],
                    ControlList2 = ControlList
            end,
            get_equip_config(RoleLevel, RoleCategory, R, FirstList2, SecondList2, ControlList2);
        _ ->
            get_equip_config(RoleLevel, RoleCategory, R, FirstList, SecondList, ControlList)
    end.

get_world_log_list([], _RoleName, Acc) ->
    lists:reverse(Acc);
get_world_log_list([Goods|R], RoleName, Acc) ->
    #p_goods{type_id = TypeID} = Goods,
    Log = #p_ks{id = TypeID, str = RoleName},
    get_world_log_list(R, RoleName, [Log|Acc]).

%% 装备寻宝
do_summit_treasure(RoleID, Times, State) ->
    case catch check_summit_treasure(Times, State) of
        {ok, AssetDoing, BagDoing, SummitWeight, AddLogs, WorldLogList, _RoleName, _NoticeGoods, Log, State2} ->
            world_act_server:add_summit_logs(WorldLogList),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_summit_treasure_toc{add_log_list = AddLogs, summit_weight = SummitWeight}),
            mod_role_dict:add_background_logs(Log),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_summit_treasure_toc{err_code = ErrCode}),
            State
    end.

check_summit_treasure(Times, State) ->
    ?IF(Times =:= ?TREASURE_ONE orelse Times =:= ?TREASURE_TEN orelse Times =:= ?TREASURE_FIFTY, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_attr = #r_role_attr{level = RoleLevel, category = Category, role_name = RoleName}, role_treasure = RoleTreasure} = State,
    #r_role_treasure{summit_times = SummitTimes, summit_weight = SummitWeight, summit_logs = SummitLogs} = RoleTreasure,
    MaxTimes = common_misc:get_global_int(?GLOBAL_MAX_TREASURE_TIMES),
    [#c_global{string = String, list = [TreasureKey], int = SilverItem}] = lib_config:find(cfg_global, ?GLOBAL_SUMMIT_TREASURE),
    TimesList = common_misc:get_global_string_list(String),
    {DecreaseDoing, GoldDoing, UseNum, LogGold} =
    case lists:keyfind(Times, 1, TimesList) of
        {_Times, NeedGold} ->
            {_, OneTimesGold} = lists:keyfind(1, 1, TimesList),
            KeyNum = mod_role_bag:get_num_by_type_id(TreasureKey, State),
            get_treasure_args(TreasureKey, KeyNum, OneTimesGold, NeedGold, ?ITEM_REDUCE_SUMMIT_TREASURE, ?ASSET_GOLD_REDUCE_FROM_SUMMIT_TREASURE, State);
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    ?IF(SummitTimes + Times < MaxTimes, ok, ?THROW_ERR(?ERROR_SUMMIT_TREASURE_001)),
    mod_role_bag:check_bag_empty_grid(?BAG_ID_TREASURE, Times + 1, State),
    AssetDoing = GoldDoing ++ [{add_score, ?ASSET_TREASURE_SCORE_ADD_FROM_SUMMIT_TREASURE, ?ASSET_TREASURE_SCORE, Times * 2}],
    {GoodsList, NoticeGoods, SummitWeight2} = gen_summit_treasure(Times, RoleLevel, Category, SummitWeight),
    AddLogs = [TypeID || #p_goods{type_id = TypeID} <- GoodsList],
    GoodsList2 = [#p_goods{type_id = SilverItem, num = Times, bind = true}|GoodsList],
    BagDoing = DecreaseDoing ++ [{create, ?BAG_ID_TREASURE, ?ITEM_GAIN_SUMMIT_TREASURE, GoodsList2}],
    [#c_global{int = LogNum}] = lib_config:find(cfg_global, ?GLOBAL_TREASURE_LOGS),
    SummitLogs2 = lists:sublist(AddLogs ++ SummitLogs, LogNum),
    WorldLogList = get_world_log_list(NoticeGoods, RoleName, []),
    RoleTreasure2 = RoleTreasure#r_role_treasure{summit_times = SummitTimes + Times, summit_logs = SummitLogs2, summit_weight = SummitWeight2},
    State2 = State#r_role{role_treasure = RoleTreasure2},
    Log = get_treasure_log(?LOG_SUMMIT_TREASURE, Times, TreasureKey, UseNum, LogGold, GoodsList2, State),
    {ok, AssetDoing, BagDoing, SummitWeight2, AddLogs, WorldLogList, RoleName, NoticeGoods, Log, State2}.

gen_summit_treasure(Times, RoleLevel, Category, SummitWeight) ->
    ConfigList = cfg_summit_treasure:list(),
    [MinWeight, MaxWeight] = common_misc:get_global_list(?GLOBAL_EQUIP_TREASURE_WEIGHT),
    {FirstList, SecondList, ControlList} = get_equip_config(RoleLevel, Category, ConfigList, [], [], []),
    gen_equips(Times, SummitWeight, {MinWeight, MaxWeight, FirstList, SecondList, ControlList}, [], []).

%% 符文寻宝
do_rune_treasure(RoleID, Times, State) ->
    case catch check_rune_treasure(Times, State) of
        {ok, AssetDoing, BagDoing, RuneFreeTime2, AddPieces, Log, BroadcastGoods, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            State5 = mod_role_rune:add_piece(AddPieces, State4),
            State6 = mod_role_extra:set_data(?EXTRA_KEY_RUNE_TREASURE_FIRST, true, State5),
            common_misc:unicast(RoleID, #m_rune_treasure_toc{rune_free_time = RuneFreeTime2}),
            mod_role_dict:add_background_logs(Log),
            ?IF(BroadcastGoods =/= [], common_broadcast:send_world_common_notice(?NOTICE_RUNE_TREASURE, [mod_role_data:get_role_name(State6)], BroadcastGoods), ok),
            hook_role:rune_treasure(State6, Times);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_treasure_toc{err_code = ErrCode}),
            State
    end.

check_rune_treasure(Times, State) ->
    ?IF(Times =:= ?TREASURE_ONE orelse Times =:= ?TREASURE_TEN, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    mod_role_rune:is_bag_full(State),
    #r_role{role_treasure = RoleTreasure, role_copy = RoleCopy} = State,
    #r_role_copy{tower_id = TowerID} = RoleCopy,
    #r_role_treasure{rune_times = RuneTimes, rune_free_time = RuneFreeTime} = RoleTreasure,
    MaxTimes = common_misc:get_global_int(?GLOBAL_MAX_TREASURE_TIMES),
    [#c_global{string = String, list = [TreasureKey, FreeHours, MinPieces, MaxPieces]}] = lib_config:find(cfg_global, ?GLOBAL_RUNE_TREASURE),
    TimesList = common_misc:get_global_string_list(String),
    ?IF(RuneTimes + Times < MaxTimes, ok, ?THROW_ERR(?ERROR_RUNE_TREASURE_001)),
    Now = time_tool:now(),
    {RuneFreeTime2, BagDoing, AssetDoing, UseNum, LogGold} =
        case lists:keyfind(Times, 1, TimesList) of
            {_Times, NeedGold} ->
                case Times =:= ?TREASURE_ONE andalso Now >= RuneFreeTime of
                    true ->
                        {Now + FreeHours * ?AN_HOUR, [], [], 0, 0};
                    _ ->
                        {_, OneTimesGold} = lists:keyfind(1, 1, TimesList),
                        KeyNum = mod_role_bag:get_num_by_type_id(TreasureKey, State),
                        {BagDoingT, AssetDoingT, UseNumT, LogGoldT} = get_treasure_args(TreasureKey, KeyNum, OneTimesGold, NeedGold, ?ITEM_REDUCE_RUNE_TREASURE, ?ASSET_GOLD_REDUCE_FROM_RUNE_TREASURE, State),
                        {RuneFreeTime, BagDoingT, AssetDoingT, UseNumT, LogGoldT}
                end;
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    PiecesList = [lib_tool:random(MinPieces, MaxPieces) || _ <- lists:seq(1, Times)],
    AddPieces = lists:sum(PiecesList),
    {BaseRareList, RoleTreasure2} = gen_rune_list(Times, State),
    {RuneList, _BroadList} =
    lists:foldl(
        fun({BaseID, IsRare}, {RuneAcc, BroadcastAcc}) ->
            RuneAcc2 = [?RUNE_LEVEL_ID(BaseID, 1)|RuneAcc],
            BroadcastAcc2 = ?IF(IsRare, [BaseID|BroadcastAcc], BroadcastAcc),
            {RuneAcc2, BroadcastAcc2}
        end, {[], []}, BaseRareList),
    RoleTreasure3 = RoleTreasure2#r_role_treasure{rune_times = RuneTimes + Times, rune_free_time = RuneFreeTime2},
    State2 = State#r_role{role_treasure = RoleTreasure3},
    {RunesGoodsList, BroadcastGoods} =
    lists:foldl(
        fun(RuneID, {Acc1, Acc2}) ->
            Goods = #p_goods{type_id = RuneID, num = 1},
            NewAcc1 = [Goods|Acc1],
            #c_item{quality = Quality} = mod_role_item:get_item_config(RuneID),
            NewAcc2 = ?IF(Quality >= ?QUALITY_RED, [Goods|Acc2], Acc2),
            {NewAcc1, NewAcc2}
        end, {[], []}, RuneList),
    RuneEssence = get_rune_essence(lib_config:find(cfg_copy_tower, TowerID), Times),  %% T 通关窥星塔80层以后寻宝获得【魂晶】
    NewRunesGoodsList = RuneEssence ++ RunesGoodsList,
    BagDoing2 = [{create, ?ITEM_GAIN_RUNE_TREASURE, NewRunesGoodsList}],
    Log = get_treasure_log(?LOG_RUNE_TREASURE, Times, TreasureKey, UseNum, LogGold, RunesGoodsList, State),
    {ok, AssetDoing, BagDoing ++ BagDoing2, RuneFreeTime2, AddPieces, Log, BroadcastGoods, State2}.

gen_rune_list(Times, State) ->
    #r_role{role_treasure = RoleTreasure} = State,
    #r_role_treasure{rune_single_times = SingleTimes} = RoleTreasure,
    TowerID = mod_role_copy:get_cur_tower_id(State),
    TowerID2 = ?IF(TowerID > 0, TowerID, ?MAP_FIRST_COPY_TOWER),
    [#c_copy_tower{box_id = BoxID}] = lib_config:find(cfg_copy_tower, TowerID2),
    ?IF(BoxID > 0, ok, ?THROW_ERR(?ERROR_RUNE_TREASURE_002)),
    [IDList] = lib_config:find(cfg_rune_treasure, {box_id, BoxID}),
    case Times of
        ?TREASURE_TEN -> %% 10连
            {lib_tool:random_reorder_list(gen_ten_runes(Times, IDList)), RoleTreasure};
        _ ->
            HasFirst = mod_role_extra:get_data(?EXTRA_KEY_RUNE_TREASURE_FIRST, false, State),
            SingleRareTimes = common_misc:get_global_int(?GLOBAL_RUNE_TREASURE),
            {SingleTimes2, IsForceRare} = ?IF(SingleTimes + 1 >= SingleRareTimes, {0, true}, {SingleTimes + 1, false}),
            RoleTreasure2 = RoleTreasure#r_role_treasure{rune_single_times = SingleTimes2},
            GenRunes =
            case HasFirst of
                false ->
                    [RuneTypeID, _RuneNum] = common_misc:get_global_list(?GLOBAL_RUNE_FIRST_ITEM),
                    [{RuneTypeID, false}];
                _ ->
                    [gen_one_rune(IDList, IsForceRare)]
            end,
            {GenRunes, RoleTreasure2}
    end.

gen_ten_runes(Times, IDList) ->
    %% 先9连，看看有没珍惜的
    {BaseRareList, IsGenRare} =
    lists:foldl(
        fun(_Index, {BaseAcc, IsRareAcc}) ->
            {_, IsRare} = BaseRare = gen_one_rune(IDList, false),
            BaseAcc2 = [BaseRare|BaseAcc],
            IsRareAcc2 = IsRareAcc orelse IsRare,
            {BaseAcc2, IsRareAcc2}
        end, {[], false}, lists:seq(1, Times - 1)),
    NewBaseRare = gen_one_rune(IDList, not IsGenRare),
    [NewBaseRare|BaseRareList].

gen_one_rune(IDList, IsForceRare) ->
    WeightList = get_weight_runes(IDList, IsForceRare, []),
    lib_tool:get_weight_output(WeightList).

%% 返回[{Weight, {RuneID, IsRare}}|.....]
get_weight_runes([], _IsForceRare, Acc) ->
    Acc;
get_weight_runes([ID|R], IsForceRare, Acc) ->
    [#c_rune_treasure{rune_base_id = BaseID, weight = Weight, rare_weight = RareWeight}] = lib_config:find(cfg_rune_treasure, ID),
    Acc2 = ?IF(IsForceRare, [{RareWeight, {BaseID, true}}|Acc], [{Weight, {BaseID, RareWeight > 0}}|Acc]),
    get_weight_runes(R, IsForceRare, Acc2).

get_treasure_log(Action, Times, UseTypeID, UseNum, LogGold, GoodsList2, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, level = RoleLevel, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_treasure{
        role_id = RoleID,
        role_level = RoleLevel,
        action_type = Action,
        times = Times,
        use_type_id = UseTypeID,
        use_num = UseNum,
        use_gold = LogGold,
        goods_list = common_misc:to_goods_string(GoodsList2),
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_treasure_args(TreasureKey, HasKeyNum, OneTimesGold, NeedGold, BagAction, AssetAction, State) ->
    NeedKeyNum = lib_tool:ceil(NeedGold/OneTimesGold),
    ExtraKeyNum = erlang:max(NeedKeyNum - HasKeyNum, 0),
    ExtraGold = lib_tool:ceil(OneTimesGold * ExtraKeyNum),
    UseKeyNum = ?IF(ExtraKeyNum > 0, HasKeyNum, NeedKeyNum),
    BagDoingsT = ?IF(UseKeyNum > 0, [{decrease, BagAction, [#r_goods_decrease_info{type_id = TreasureKey, num = UseKeyNum}]}], []),
    GoldDoingsT = ?IF(ExtraGold > 0, mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, ExtraGold, AssetAction, State), []),
    {BagDoingsT, GoldDoingsT, UseKeyNum, ExtraGold}.

%% @doc  获得【魂晶】（爬塔80层以后）
get_rune_essence([], _Times) ->
    [];
get_rune_essence([#c_copy_tower{rune_essence = []}], _Times) ->
    [];
get_rune_essence([#c_copy_tower{rune_essence = [ID, Num]}], Times) ->
    [#p_goods{type_id = ID, num = Num * Times}].

