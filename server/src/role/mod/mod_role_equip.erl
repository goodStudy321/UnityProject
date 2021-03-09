%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 装备
%%% @end
%%% Created : 22. 六月 2017 19:30
%%%-------------------------------------------------------------------
-module(mod_role_equip).
-author("laijichang").
-include("role.hrl").
-include("daily_liveness.hrl").
-include("discount_pay.hrl").
-include("proto/mod_role_equip.hrl").


%% API
-export([
    init/1,
    calc/1,
    day_reset/1,
    zero/1,
    pre_enter/1,
    handle/2,
    immortal_calc_equip_refine/1
]).

-export([
    level_up/2,
    role_vip_expire/1
]).

-export([
    load_equip/2,
    get_new_excellent/2,
    get_stone_level/1,
    get_suit_list/1
]).

-export([
    get_level_num/2,
    get_refine_level_num/2,
    get_all_refine_level/1,
    get_equip_snapshot/1,
    get_equip_base_attr/1,
    get_rune_equip_attr/1,
    is_prop_equip_fit/1,
    get_equip_concise_num/1,
    get_stone_level_num/2
]).

-export([
    gen_first_concise/3,
    gen_normal_concise/4,
    get_stone_level_by_type/2,
    get_base_equip_attr/1,
    get_equip_attr/1
]).

-export([
    modify_role_equip_concise/1
]).

init(#r_role{role_id = RoleID, role_equip = undefined} = State) ->
    RoleEquip = #r_role_equip{role_id = RoleID},
    State#r_role{role_equip = RoleEquip};
init(State) ->
    State.

calc(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {BaseList, RefineList, SuitList, StoneHoningList, SealList, ExcellentList, ConciseList, RefineLevel, StarLevel} = calc_equips(EquipList),
    SuitAttr = calc_equip_suit_attr(SuitList),
    RefineAttr = get_immortal_refine_add(common_misc:sum_calc_attr(RefineList), State),
    RefineSuitAttr = get_equip_level_attr(RefineLevel, cfg_equip_refine_suit:list(), #actor_cal_attr{}),
    StarSuitAttr = get_equip_level_attr(StarLevel, cfg_equip_star_suit:list(), #actor_cal_attr{}),
    State2 = mod_role_fight:get_state_by_kv(State, ?CALC_KEY_EQUIP_BASE, common_misc:sum_calc_attr(BaseList)),
    State3 = mod_role_fight:get_state_by_kv(State2, ?CALC_KEY_EQUIP_REFINE, RefineAttr),
    State4 = mod_role_fight:get_state_by_kv(State3, ?CALC_KEY_EQUIP_REFINE_LEVEL, RefineSuitAttr),
    State5 = mod_role_fight:get_state_by_kv(State4, ?CALC_KEY_EQUIP_SUIT, SuitAttr),
    State6 = mod_role_fight:get_state_by_kv(State5, ?CALC_KEY_EQUIP_EXCELLENT, role_misc:get_attr_by_kv(ExcellentList, State5)),
    State7 = mod_role_fight:get_state_by_kv(State6, ?CALC_KEY_EQUIP_CONCISE, role_misc:get_attr_by_kv(ConciseList, State6)),
    State8 = calc_stones(StoneHoningList, State7),
    State9 = calc_seals(SealList, State8),
    State10 = mod_role_fight:get_state_by_kv(State9, ?CALC_KEY_EQUIP_STAR_SUIT, StarSuitAttr),
    State10.

calc_equips(EquipList) ->
    lists:foldl(
        fun(Equip, {Acc1, RefineAttrAcc, SuitAcc, StoneAcc, SealAcc, ExcellentListAcc, ConciseListAcc, RefineLvAcc, StarLevelAcc}) ->
            #p_equip{
                equip_id = EquipID,
                suit_level = SuitLv,
                stone_list = StoneList,
                refine_level = RefineLv,
                excellent_list = ExcellentList,
                concise_list = ConciseList,
                forge_soul = ForgeSoulID,
                forge_soul_cultivate = ForgeSoulLevel,
                stone_honings = StoneHoning,
                seal_list = SealList
            } = Equip,
            [EquipConfig] = lib_config:find(cfg_equip, EquipID),
            #c_equip{
                index = IndexID,
                step = Step,
                star = StarLevel,
                suit_level1 = SuitLv1,
                suit_id1 = SuitID1,
                suit_level2 = SuitLv2,
                suit_id2 = SuitID2
            } = EquipConfig,
            case RefineLv > 0 of
                true ->
                    RefineAttr = get_refine_attr(EquipConfig, RefineLv),
                    RefineAttrAcc2 = [RefineAttr|RefineAttrAcc];
                _ ->
                    RefineAttrAcc2 = RefineAttrAcc
            end,
            {ForgeSoulRate, ForgeSoulList} = get_forge_soul_rate_and_attr(ForgeSoulID, Step, IndexID, ForgeSoulLevel),%% 镇魂属性，装备阶数，装备部位，镇魂养成
            BaseAttr = get_forge_base_attr(EquipConfig, ForgeSoulRate, common_misc:get_attr_by_kv(ForgeSoulList)), %% 得到【镇魂属性+镇魂养成】带来的属性提升
            SpecialAttr = get_equip_special_attr(EquipConfig#c_equip.id),
            SuitAcc2 = calc_equip_suit_list(SuitLv, SuitLv1, SuitID1, SuitLv2, SuitID2, SuitAcc),
            ConciseList2 = [#p_kv{id = PropKey, val = PropValue} || #p_equip_concise{prop_key = PropKey, prop_value = PropValue} <- ConciseList],
            {[BaseAttr, SpecialAttr|Acc1], RefineAttrAcc2, SuitAcc2, [{StoneList, StoneHoning}|StoneAcc], [SealList|SealAcc], ExcellentList ++ ExcellentListAcc, ConciseList2 ++ ConciseListAcc, RefineLv + RefineLvAcc, StarLevel + StarLevelAcc}
        end, {[], [], [], [], [], [], [], 0, 0}, EquipList).

calc_equip_suit_list(SuitLv, SuitLv1, SuitID1, SuitLv2, SuitID2, SuitList) when SuitLv > 0 ->
    if
        SuitLv > 0 andalso SuitLv =:= SuitLv1 ->
            SuitIDList = [SuitID1];
        SuitLv2 > 0 andalso SuitLv =:= SuitLv2 ->
            SuitIDList = [SuitID1, SuitID2]
    end,
    lists:foldl(
        fun(SuitID, SuitListAcc) ->
            case lists:keyfind(SuitID, 1, SuitListAcc) of
                {_SuitID, Num} ->
                    Num2 = Num + 1;
                _ ->
                    Num2 = 1
            end,
            lists:keystore(SuitID, 1, SuitListAcc, {SuitID, Num2})
        end, SuitList, SuitIDList);
calc_equip_suit_list(_SuitLv, _SuitLv1, _SuitID1, _SuitLv2, _SuitID2, SuitList) ->
    SuitList.

%% 计算套装属性
calc_equip_suit_attr(SuitList) ->
    SuitList2 = lists:reverse(lists:keysort(1, SuitList)),
    calc_equip_suit_attr2(SuitList2, #actor_cal_attr{}).

calc_equip_suit_attr2([], Attr) ->
    Attr;
calc_equip_suit_attr2([{SuitID, NowNum}|R], AttrAcc) ->
    [#c_equip_suit{
        suit_num1 = SuitNum1,
        suit_props1 = SuitProps1,
        suit_num2 = SuitNum2,
        suit_props2 = SuitProps2,
        suit_num3 = SuitNum3,
        suit_props3 = SuitProps3
    }] = lib_config:find(cfg_equip_suit, SuitID),
    SuitList = [{SuitNum1, SuitProps1}, {SuitNum2, SuitProps2}, {SuitNum3, SuitProps3}],
    AttrList = calc_equip_suit_attr3(SuitList, NowNum, []),
    Attr = common_misc:sum_calc_attr(lists:flatten(AttrList)),
    calc_equip_suit_attr2(R, common_misc:sum_calc_attr2(AttrAcc, Attr)).

calc_equip_suit_attr3([], _NowNum, AttrListAcc) ->
    AttrListAcc;
calc_equip_suit_attr3([{SuitNum, SuitProps}|R], NowNum, AttrListAcc) ->
    case NowNum >= SuitNum of
        true ->
            Attr = common_misc:get_attr_by_kv(common_misc:get_string_props(SuitProps)),
            AttrListAcc2 = [Attr|AttrListAcc],
            calc_equip_suit_attr3(R, NowNum, AttrListAcc2);
        _ ->
            AttrListAcc
    end.

%% 计算宝石加成以及宝石套装加成
calc_stones(StoneHoningList, State) ->
    {BaseList, AllLevel} = calc_stones2(StoneHoningList),
    SuitAttr = get_stone_level_attr(AllLevel),
    State2 = mod_role_fight:get_state_by_kv(State, ?CALC_KEY_STONE, common_misc:sum_calc_attr(BaseList)),
    mod_role_fight:get_state_by_kv(State2, ?CALC_KEY_STONE_LEVEL, SuitAttr).

calc_stones2(StoneHoningList) ->
    lists:foldl(
        fun({StoneList, HoningList}, {Acc1, Acc2}) ->
            {BaseAcc, LevelAcc, _HoningRemain} =
            lists:foldl(
                fun(#p_kv{id = Index, val = StoneID}, {Acc3, Acc4, HoningAcc}) ->
                    [StoneConfig] = lib_config:find(cfg_stone, StoneID),
                    #c_stone{
                        level = Level,
                        add_hp = AddHp,
                        add_attack = AddAttack,
                        add_defence = AddDefence,
                        add_arp = AddArp
                    } = StoneConfig,
                    case Level >= ?STONE_HONING_LEVEL andalso lists:keytake(Index, #p_kv.id, HoningAcc) of
                        {value, #p_kv{val = HoningID}, HoningAcc2} ->
                            [#c_stone_honing{
                                base_add_rate = BaseAddRate,
                                prop_string = PropString
                            }] = lib_config:find(cfg_stone_honing, HoningID),
                            BaseAttr = #actor_cal_attr{
                                max_hp = {lib_tool:ceil(AddHp * (1 + BaseAddRate / ?RATE_10000)), 0},
                                attack = {lib_tool:ceil(AddAttack * (1 + BaseAddRate / ?RATE_10000)), 0},
                                defence = {lib_tool:ceil(AddDefence * (1 + BaseAddRate / ?RATE_10000)), 0},
                                arp = {lib_tool:ceil(AddArp * (1 + BaseAddRate / ?RATE_10000)), 0}},
                            HoningAttr = common_misc:get_attr_by_kv(common_misc:get_string_props(PropString)),
                            BaseAttr2 = common_misc:sum_calc_attr([BaseAttr, HoningAttr]),
                            {[BaseAttr2|Acc3], Level + Acc4, HoningAcc2};
                        _ ->
                            BaseAttr = #actor_cal_attr{
                                max_hp = {AddHp, 0},
                                attack = {AddAttack, 0},
                                defence = {AddDefence, 0},
                                arp = {AddArp, 0}},
                            {[BaseAttr|Acc3], Level + Acc4, HoningAcc}
                    end
                end, {[], 0, HoningList}, StoneList),
            {BaseAcc ++ Acc1, LevelAcc + Acc2}
        end, {[], 0}, StoneHoningList).

calc_seals(AllSealList, State) ->
    {BaseList, _AllLevel} = calc_seals2(AllSealList),
    Attr = common_misc:sum_calc_attr(BaseList),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_SEAL, Attr).

calc_seals2(AllSealList) ->
    lists:foldl(
        fun(SealList, {Acc1, Acc2}) ->
            {BaseAcc, LevelAcc} =
            lists:foldl(
                fun(#p_kv{val = SealID}, {Acc3, Acc4}) ->
                    [SealConfig] = lib_config:find(cfg_seal, SealID),
                    #c_seal{
                        level = Level,
                        add_miss = AddMiss,
                        add_hit_rate = AddHitRate,
                        add_double_anti = AddDoubleAnti,
                        add_double = AddDouble
                    } = SealConfig,
                    BaseAttr = #actor_cal_attr{
                        miss = {AddMiss, 0},
                        hit_rate = {AddHitRate, 0},
                        double_anti = {AddDoubleAnti, 0},
                        double = {AddDouble, 0}},
                    {[BaseAttr|Acc3], Level + Acc4}
                end, {[], 0}, SealList),
            {BaseAcc ++ Acc1, LevelAcc + Acc2}
        end, {[], 0}, AllSealList).


get_level_num(Level, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    AllStoneList = lists:flatten([StoneList || #p_equip{stone_list = StoneList} <- EquipList]),
    get_level_num2(AllStoneList, Level).


get_level_num2(StoneList, NeedLevel) ->
    lists:foldl(
        fun(#p_kv{val = StoneID}, Acc) ->
            [#c_stone{level = Level}] = lib_config:find(cfg_stone, StoneID),
            ?IF(NeedLevel > Level, Acc, Acc + 1)
        end, 0, StoneList).







get_stone_type_level(StoneType, AllStoneList, StoneLevel) ->
    LevelNumList = [{Level, 0} || Level <- lists:seq(1, StoneLevel)],
    lists:foldl(
        fun(#p_kv{val = StoneID}, {AccLevel, AccLevelNumList}) ->
            [#c_stone{type = Type, level = NowLevel}] = lib_config:find(cfg_stone, StoneID),
            AccLevelNumList2 = [?IF(NowLevel >= Level, {Level, Num + 1}, {Level, Num}) || {Level, Num} <- AccLevelNumList],
            AccLevel2 = ?IF(Type =:= StoneType, AccLevel + NowLevel, AccLevel),
            {AccLevel2, AccLevelNumList2}
        end, {0, LevelNumList}, AllStoneList).

immortal_calc_equip_refine(State) ->
    #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
    RefineAttr = lists:foldl(
        fun(Equip, AttrAcc) ->
            [EquipConfig] = lib_config:find(cfg_equip, Equip#p_equip.equip_id),
            RefineLv = Equip#p_equip.refine_level,
            ?IF(RefineLv > 0, common_misc:sum_calc_attr2(get_refine_attr(EquipConfig, RefineLv), AttrAcc), AttrAcc)
        end, #actor_cal_attr{}, EquipList),
    RefineAttr2 = get_immortal_refine_add(RefineAttr, State),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_EQUIP_REFINE, RefineAttr2).

get_equip_level_attr(_Level, [], Attr) ->
    Attr;
get_equip_level_attr(Level, [{MinLevel, SuitConfig}|R], Attr) ->
    case Level >= MinLevel of
        true ->
            #c_equip_refine_suit{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp} = SuitConfig,
            Attr2 =
            #actor_cal_attr{
                max_hp = {AddHp, 0},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                arp = {AddArp, 0}},
            get_equip_level_attr(Level, R, Attr2);
        _ ->
            Attr
    end.

get_immortal_refine_add(RefineAttr, State) ->
    #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        defence = {AddDefence, 0},
        arp = {AddArp, 0}} = RefineAttr,
    RefineAdd = mod_role_immortal_soul:get_equip_refine_add(State),
    RefineAttr#actor_cal_attr{
        max_hp = {lib_tool:ceil(AddHp * (1 + RefineAdd / ?RATE_10000)), 0},
        attack = {lib_tool:ceil(AddAttack * (1 + RefineAdd / ?RATE_10000)), 0},
        defence = {lib_tool:ceil(AddDefence * (1 + RefineAdd / ?RATE_10000)), 0},
        arp = {lib_tool:ceil(AddArp * (1 + RefineAdd / ?RATE_10000)), 0}
    }.

get_stone_level_attr(0) ->
    #actor_cal_attr{};
get_stone_level_attr(Level) ->
    get_stone_level_attr2(Level, cfg_stone_suit:list(), #actor_cal_attr{}).

get_stone_level_attr2(_Level, [], Acc) ->
    Acc;
get_stone_level_attr2(Level, [{NeedLevel, SuitConfig}|R], Acc) ->
    case Level >= NeedLevel of
        true ->
            #c_stone_suit{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_hit_rate = AddHitRate,
                add_miss = AddMiss,
                add_double = AddDouble,
                add_double_anti = AddDoubleAnti} = SuitConfig,
            Acc2 =
            #actor_cal_attr{
                max_hp = {AddHp, 0},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                hit_rate = {AddHitRate, 0},
                miss = {AddMiss, 0},
                double = {AddDouble, 0},
                double_anti = {AddDoubleAnti, 0}},
            get_stone_level_attr2(Level, R, Acc2);
        _ ->
            Acc
    end.

day_reset(State) ->
    #r_role{role_equip = RoleEquip} = State,
    RoleEquip2 = RoleEquip#r_role_equip{free_concise_times = 3},
    State#r_role{role_equip = RoleEquip2}.

zero(State) ->
    notice_concise_times(State),
    State.

pre_enter(#r_role{role_id = RoleID, role_equip = RoleEquip} = State) ->
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    DataRecord = #m_equip_info_toc{equip_list = EquipList},
    common_misc:unicast(RoleID, DataRecord),
    notice_concise_times(State),
    State.

%% 穿上装备
load_equip(Goods, State) ->
    #r_role{role_id = RoleID, role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    #p_goods{type_id = EquipID, excellent_list = ExcellentList, bind = Bind} = Goods,
    [#c_equip{index = Index, quality = Quality, step = Step, star = Star} = EquipConfig] = lib_config:find(cfg_equip, EquipID),
    case catch load_equip2(EquipConfig, State, Bind, ExcellentList, EquipList, []) of
        {ok, Equip, OldEquipID, GoodsList, EquipList2} ->
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State2 = State#r_role{role_equip = RoleEquip2},
            case GoodsList =/= [] of %% 需要创建新装备 or 宝石 or 套装返还！
                true ->
                    mod_role_bag:check_bag_empty_grid(GoodsList, State2),
                    BagDoing = [{create, ?ITEM_GAIN_EQUIP_REPLACE, GoodsList}],
                    State3 = mod_role_bag:do(BagDoing, State2);
                _ ->
                    State3 = State2
            end,
            State4 = calc(State3),
            State5 = lists:foldl(
                fun(Mod, StateAcc) ->
                    Mod:calc(StateAcc)
                end, State4, [mod_role_family, mod_role_rune, mod_role_skill]),
            State6 = mod_role_god_book:load_equip([Index, Quality, Step], State5),
            DataRecord = #m_equip_load_toc{equip = Equip},
            common_misc:unicast(RoleID, DataRecord),
            mod_role_dict:add_background_logs(get_load_log(Index, EquipID, OldEquipID, State6)),
            State7 = mod_role_fight:calc_attr_and_update(State6, ?POWER_UPDATE_LOAD_EQUIP, EquipID),
            State8 = mod_role_achievement:load_equip(Quality, Star, Index, State7),
            State9 = mod_role_confine:check_equip_list(State8, EquipList2, Step, Quality, Star),
            State10 = mod_role_day_target:equip_concise_num(State9),
            suit_trigger(State10);
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode)
    end.

load_equip2(EquipConfig, State, Bind, ExcellentList, [], Acc) ->
    Equip = #p_equip{equip_id = EquipConfig#c_equip.id, excellent_list = ExcellentList, bind = Bind},
    %% 新穿装备可能要激活洗练属性
    Equip2 = do_equip_new_concise(Equip, EquipConfig, State),
    {ok, Equip2, 0, [], [Equip2|Acc]};
load_equip2(EquipConfig, State, Bind, ExcellentList, [OldEquip|R], Acc) ->
    OldEquipID = OldEquip#p_equip.equip_id,
    [#c_equip{index = DestIndex, stone_num = OldStoneNum, seal_num = OldSealNum}] = lib_config:find(cfg_equip, OldEquipID),
    case EquipConfig#c_equip.index =:= DestIndex of
        true -> %% 位置一样，宝石、装备得拆卸下来
            #p_equip{
                equip_id = DestID,
                suit_level = SuitLevel,
                stone_list = StoneList,
                seal_list = SealList,
                excellent_list = DestList,
                bind = OldBind} = OldEquip,
            #c_equip{id = EquipID, stone_num = StoneNum, seal_num = SealNum} = EquipConfig,
            {StoneList2, StoneGoodsList} = load_equip_stone(lists:keysort(#p_kv.id, StoneList), OldStoneNum, StoneNum),
            {SealList2, SealGoodsList} = load_equip_seal(lists:keysort(#p_kv.id, SealList), OldSealNum, SealNum),
            SuitGoodsList = get_suit_items(DestID, SuitLevel),
            GoodsList = [#p_goods{type_id = DestID, bind = OldBind, num = 1, excellent_list = DestList}|StoneGoodsList] ++ SealGoodsList ++ SuitGoodsList,
            Equip2 = OldEquip#p_equip{
                equip_id = EquipID,
                bind = Bind,
                suit_level = 0,
                stone_list = StoneList2,
                seal_list = SealList2,
                excellent_list = ExcellentList},
            EquipList = [Equip2|R] ++ Acc,
            {ok, Equip2, OldEquipID, GoodsList, EquipList};
        _ ->
            load_equip2(EquipConfig, State, Bind, ExcellentList, R, [OldEquip|Acc])
    end.

load_equip_stone(StoneList, OldStoneNum, StoneNum) ->
    if
        StoneNum >= OldStoneNum -> %% 新装备孔数比旧装备多
            {StoneList, []};
        StoneNum >= erlang:length(StoneList) -> %% 新装备孔数可以容纳的下当前的位置
            {StoneList, []};
        true ->
            case lists:keytake(?VIP_STONE_INDEX, #p_kv.id, StoneList) of
                {value, VipStone, StoneList2} ->
                    VipStoneList = [VipStone];
                _ ->
                    VipStoneList = [],
                    StoneList2 = StoneList
            end,
            {StoneList3, RemainList} = lib_tool:split(StoneNum, StoneList2),
            {StoneList4, _} =
            lists:foldl(
                fun(Stone, {AccList, AccNum}) ->
                    {[Stone#p_kv{id = AccNum}|AccList], AccNum + 1}
                end, {[], 1}, StoneList3),
            GoodsList = [#p_goods{type_id = StoneID, bind = true, num = 1} || #p_kv{val = StoneID} <- RemainList],
            {VipStoneList ++ StoneList4, GoodsList}
    end.

load_equip_seal(SealList, OldSealNum, SealNum) ->
    if
        SealNum >= OldSealNum -> %% 新装备孔数比旧装备多
            {SealList, []};
        SealNum >= erlang:length(SealList) -> %% 新装备孔数可以容纳的下当前的位置
            {SealList, []};
        true ->
            case lists:keytake(?VIP_SEAL_INDEX, #p_kv.id, SealList) of
                {value, VipSeal, SealList2} ->
                    VipSealList = [VipSeal];
                _ ->
                    VipSealList = [],
                    SealList2 = SealList
            end,
            {SealList3, RemainList} = lib_tool:split(SealNum, SealList2),
            {SealList4, _} =
            lists:foldl(
                fun(Seal, {AccList, AccNum}) ->
                    {[Seal#p_kv{id = AccNum}|AccList], AccNum + 1}
                end, {[], 1}, SealList3),
            GoodsList = [#p_goods{type_id = SealID, bind = true, num = 1} || #p_kv{val = SealID} <- RemainList],
            {VipSealList ++ SealList4, GoodsList}
    end.

do_equip_new_concise(Equip, EquipConfig, State) ->
    #c_equip{index = EquipIndex} = EquipConfig,
    [NeedLevel] = lib_config:find(cfg_equip_concise_level, EquipIndex),
    case mod_role_data:get_role_level(State) >= NeedLevel of
        true ->
            ConciseList = gen_first_concise(EquipIndex, [1], []),
            Equip#p_equip{concise_num = 1, concise_list = ConciseList};
        _ ->
            Equip
    end.

get_suit_items(_DestID, 0) ->
    [];
get_suit_items(DestID, SuitLevel) ->
    [#c_equip{
        suit_level1 = SuitLevel1,
        suit_item1 = SuitItem1,
        suit_item2 = SuitItem2
    }] = lib_config:find(cfg_equip, DestID),
    SuitList = ?IF(SuitLevel =:= SuitLevel1, [SuitItem1], [SuitItem1, SuitItem2]),
    get_suit_items2(SuitList, []).

get_suit_items2([], Acc) ->
    Acc;
get_suit_items2([SuitItem|R], GoodsAcc) ->
    GoodsList =
    [begin
         [TypeID, Num] = string:tokens(ItemString, ","),
         #p_goods{type_id = lib_tool:to_integer(TypeID), num = lib_tool:to_integer(Num)}
     end || ItemString <- string:tokens(SuitItem, ";")],
    get_suit_items2(R, GoodsList ++ GoodsAcc).

suit_trigger(State) ->
    #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
    List = get_suit_list(EquipList),
    State2 = mod_role_achievement:suit_level(List, State),
    mod_role_confine:suit_num(List, State2).

get_suit_list(EquipList) ->
    lists:foldl(
        fun(#p_equip{suit_level = SuitLevel}, Acc) ->
            case SuitLevel > 0 of
                true ->
                    get_suit_list2(SuitLevel, Acc, []);
                _ ->
                    Acc
            end
        end, [{?EQUIP_SUIT_LEVEL_IMMORTAL, 0}, {?EQUIP_SUIT_LEVEL_GOD, 0}], EquipList).

get_suit_list2(_SuitLevel, [], Acc2) ->
    Acc2;
get_suit_list2(SuitLevel, [{Level, Num}|R], Acc2) ->
    case SuitLevel >= Level of
        true ->
            get_suit_list2(SuitLevel, R, [{Level, Num + 1}|Acc2]);
        _ ->
            get_suit_list2(SuitLevel, R, [{Level, Num}|Acc2])
    end.

get_new_excellent(EquipID, ExcellentList) ->
    case ExcellentList =:= [] of
        true ->
            case lib_config:find(cfg_equip, EquipID) of
                [Config] ->
                    ok;
                _ ->
                    ?ERROR_MSG("test:~w", [EquipID]),
                    Config = erlang:throw(config_error)
            end,
            #c_equip{star = Star, index = Index, quality = Quality} = Config,
            Groups = get_start_groups(cfg_equip_star:list(), Star, Index, Quality),
            get_new_excellent2(Groups, [], []);
        _ ->
            ExcellentList
    end.

get_start_groups([], _Star, _Index, _Quality) ->
    [];
get_start_groups([{_ID, Config}|R], Star, Index, Quality) ->
    #c_equip_star{
        index_list = IndexList,
        star = NeedStar,
        quality = NeedQuality,
        groups = Groups
    } = Config,
    case lists:member(Index, IndexList) andalso NeedStar =:= Star andalso NeedQuality =:= Quality of
        true ->
            Groups;
        _ ->
            get_start_groups(R, Star, Index, Quality)
    end.

get_new_excellent2([], _HasProps, Props) ->
    Props;
get_new_excellent2([ExcellentGroup|R], HasProps, Props) ->
    [EquipExcellent] = lib_config:find(cfg_equip_excellent, ExcellentGroup),
    #c_equip_excellent{
        defence_rate = DefenceRate,
        hp_rate = HpRate,
        hurt_derate = HurtDeRate,
        attack_rate = AttackRate,
        arp_rate = ArpRate,
        hurt_rate = HurtRate,
        double_rate = DoubleRate,
        every_three_attack = EveryThreeAttack,
        every_three_arp = EveryThreeArp,
        every_three_hp = EveryThreeHp,
        every_three_defence = EveryThreeDefence,
        double_anti_rate = DoubleAntiRate,
        miss_rate = MissRate
    } = EquipExcellent,
    List = [DefenceRate, HpRate, HurtDeRate, AttackRate, ArpRate, HurtRate, DoubleRate, EveryThreeAttack, EveryThreeArp, EveryThreeHp, EveryThreeDefence,
            DoubleAntiRate, MissRate],
    PropList = get_new_excellent3(List, ?EQUIP_EXCELLENT_PROPS, HasProps, []),
    #p_kv{id = HasKey} = Prop = lib_tool:get_weight_output(PropList),
    get_new_excellent2(R, [HasKey|HasProps], [Prop|Props]).

%% 已经拥有的属性，要排除掉
get_new_excellent3([], [], _HasProps, PropsAcc) ->
    PropsAcc;
get_new_excellent3([Value|R1], [Key|R2], HasProps, PropsAcc) ->
    case lists:member(Key, HasProps) of
        true ->
            get_new_excellent3(R1, R2, HasProps, PropsAcc);
        _ ->
            case Value of
                [Weight, PropValue, _Score] ->
                    PropsAcc2 = [{Weight, #p_kv{id = Key, val = PropValue}}|PropsAcc],
                    get_new_excellent3(R1, R2, HasProps, PropsAcc2);
                _ ->
                    get_new_excellent3(R1, R2, HasProps, PropsAcc)
            end
    end.

get_stone_level(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    AllStoneList = lists:flatten([StoneList || #p_equip{stone_list = StoneList} <- EquipList]),
    get_stone_level2(AllStoneList).


get_stone_level2(StoneList) ->
    lists:foldl(
        fun(#p_kv{val = StoneID}, Acc) ->
            [#c_stone{level = Level}] = lib_config:find(cfg_stone, StoneID),
            Acc + Level
        end, 0, StoneList).

get_seal_level(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    AllSealList = lists:flatten([SealList || #p_equip{seal_list = SealList} <- EquipList]),
    get_seal_level2(AllSealList).

get_seal_level2(AllSealList) ->
    lists:foldl(
        fun(#p_kv{val = SealID}, Acc) ->
            [#c_seal{level = Level}] = lib_config:find(cfg_seal, SealID),
            Acc + Level
        end, 0, AllSealList).

get_refine_level_num(NeedLevel, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    lists:foldl(
        fun(#p_equip{refine_level = RefineLevel}, AccNum) ->
            ?IF(RefineLevel >= NeedLevel, AccNum + 1, AccNum)
        end, 0, EquipList).

get_all_refine_level(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    lists:foldl(
        fun(#p_equip{refine_level = RefineLevel}, AccNum) ->
            RefineLevel + AccNum
        end, 0, EquipList).

get_all_stars(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    lists:foldl(
        fun(#p_equip{equip_id = EquipID}, Acc) ->
            [#c_equip{star = Star}] = lib_config:find(cfg_equip, EquipID),
            Star + Acc
        end, 0, EquipList).

get_equip_snapshot(EquipList) ->
    lists:foldl(
        fun(#p_equip{equip_id = EquipID, stone_list = StoneList, refine_level = RefineLevel}, {Acc1, Acc2, Acc3}) ->
            [#c_equip{star = Star}] = lib_config:find(cfg_equip, EquipID),
            AllLevel = get_stone_level2(StoneList),
            NewAcc1 = Star + Acc2,
            NewAcc2 = RefineLevel + Acc1,
            NewAcc3 = AllLevel + Acc3,
            {NewAcc1, NewAcc2, NewAcc3}
        end, {0, 0, 0}, EquipList).

get_equip_base_attr(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    lists:foldl(
        fun(#p_equip{equip_id = EquipID}, Acc) ->
            [EquipConfig] = lib_config:find(cfg_equip, EquipID),
            common_misc:sum_calc_attr2(Acc, get_base_equip_attr2(EquipConfig))
        end, #actor_cal_attr{}, EquipList).

level_up(NewLevel, State) ->
    LevelList = cfg_equip_concise_level:list(),
    #r_role{role_id = RoleID, role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {EquipList2, UpdateEquips} =
    lists:foldl(
        fun({EquipIndex, NeedLevel}, {EquipAcc, UpdateAcc}) ->
            case NewLevel >= NeedLevel of
                true -> %% 检测下是否可以开启
                    {EquipAcc2, UpdateList} = level_up2(EquipIndex, EquipAcc, []),
                    {EquipAcc2, UpdateList ++ UpdateAcc};
                _ ->
                    {EquipAcc, UpdateAcc}
            end
        end, {EquipList, []}, LevelList),
    case UpdateEquips =/= [] of
        true ->
            [common_misc:unicast(RoleID, #m_equip_load_toc{equip = UpdateEquip}) || UpdateEquip <- UpdateEquips],
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State2 = State#r_role{role_equip = RoleEquip2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_EQUIP_CONCISE_OPEN, NewLevel),
            mod_role_day_target:equip_concise_num(State3);
        _ ->
            State
    end.

level_up2(_EquipIndex, [], EquipAcc) ->
    {EquipAcc, []};
level_up2(EquipIndex, [Equip|R], EquipAcc) ->
    #p_equip{equip_id = EquipID, concise_num = ConciseNum} = Equip,
    [#c_equip{index = LoadIndex}] = lib_config:find(cfg_equip, EquipID),
    case ConciseNum =< 0 andalso EquipIndex =:= LoadIndex of
        true -> %% 生成一个属性
            ConciseList = gen_first_concise(LoadIndex, [1], []),
            Equip2 = Equip#p_equip{concise_num = 1, concise_list = ConciseList},
            {[Equip2|EquipAcc] ++ R, [Equip2]};
        _ ->
            level_up2(EquipIndex, R, [Equip|EquipAcc])
    end.

role_vip_expire(State) ->
    #r_role{role_id = RoleID, role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {EquipList2, GoodsList} =
    lists:foldl(
        fun(#p_equip{stone_list = StoneList, seal_list = SealList} = Equip, {EquipAcc, GoodsAcc}) ->
            {Equip2, AddGoods} =
            case lists:keytake(?VIP_STONE_INDEX, #p_kv.id, StoneList) of
                {value, #p_kv{val = StoneID}, StoneList2} ->
                    StoneGoods = #p_goods{type_id = StoneID, num = 1, bind = true},
                    EquipT = Equip#p_equip{stone_list = StoneList2},
                    {EquipT, [StoneGoods]};
                _ ->
                    {Equip, []}
            end,
            case lists:keytake(?VIP_SEAL_INDEX, #p_kv.id, SealList) of
                {value, #p_kv{val = SealID}, SealList2} ->
                    SealGoods = #p_goods{type_id = SealID, num = 1, bind = true},
                    Equip3 = Equip2#p_equip{seal_list = SealList2},
                    {[Equip3|EquipAcc], [SealGoods|AddGoods] ++ GoodsAcc};
                _ ->
                    {[Equip2|EquipAcc], AddGoods ++ GoodsAcc}
            end
        end, {[], []}, EquipList),
    case GoodsList =/= [] of
        true ->
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            common_misc:unicast(RoleID, #m_equip_info_toc{equip_list = EquipList2}),
            State2 = State#r_role{role_equip = RoleEquip2},
            role_misc:create_goods(State2, ?ITEM_GAIN_VIP_EXPIRE_STONE, GoodsList);
        _ ->
            State
    end.

get_rune_equip_attr(State) ->
    #r_role_equip{equip_list = EquipList} = State#r_role.role_equip,
    get_rune_equip_attr2(EquipList, #actor_cal_attr{}, #actor_cal_attr{}, #actor_cal_attr{}).

get_rune_equip_attr2([], ArmorAttr, WeaponAttr, GodAttr) ->
    {ArmorAttr, WeaponAttr, GodAttr};
get_rune_equip_attr2([Equip|R], ArmorAttr, WeaponAttr, GodAttr) ->
    #p_equip{equip_id = EquipID} = Equip,
    [#c_equip{index = Index,
              add_hp = AddHp,
              add_attack = AddAttack,
              add_arp = AddArp,
              add_defence = AddDefence}] = lib_config:find(cfg_equip, EquipID),
    Attr = #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        defence = {AddDefence, 0},
        arp = {AddArp, 0}
    },
    IsArmor = ?IS_EQUIP_ARMOR(Index),
    IsWeapon = ?IS_EQUIP_WEAPON(Index),
    IsGod = ?IS_EQUIP_GOD(Index),
    if
        IsArmor ->
            get_rune_equip_attr2(R, common_misc:sum_calc_attr2(ArmorAttr, Attr), WeaponAttr, GodAttr);
        IsWeapon ->
            get_rune_equip_attr2(R, ArmorAttr, common_misc:sum_calc_attr2(WeaponAttr, Attr), GodAttr);
        IsGod ->
            get_rune_equip_attr2(R, ArmorAttr, WeaponAttr, common_misc:sum_calc_attr2(GodAttr, Attr));
        true ->
            get_rune_equip_attr2(R, ArmorAttr, WeaponAttr, GodAttr)
    end.

%% 全身穿戴7阶以上红色3星装备
is_prop_equip_fit(State) ->
    #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
    ?IF(erlang:length(EquipList) >= 10, is_prop_equip_fit2(EquipList), false).

is_prop_equip_fit2([]) ->
    true;
is_prop_equip_fit2([Equip|R]) ->
    #p_equip{equip_id = EquipID} = Equip,
    [#c_equip{star = Star, step = Step}] = lib_config:find(cfg_equip, EquipID),
    ?IF(Step >= 7 andalso Star >= 3, is_prop_equip_fit2(R), false).

%% 解锁装备洗练属性条目
get_equip_concise_num(State) ->
    #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
    get_equip_concise_num2(EquipList, 0).

get_equip_concise_num2([], NumAcc) ->
    NumAcc;
get_equip_concise_num2([Equip|R], NumAcc) ->
    #p_equip{concise_num = ConciseNum} = Equip,
    get_equip_concise_num2(R, ConciseNum + NumAcc).

get_stone_level_num(NeedLevel, State) ->
    #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
    get_stone_level_num2(EquipList, NeedLevel, 0).

get_stone_level_num2([], _NeedLevel, NumAcc) ->
    NumAcc;
get_stone_level_num2([Equip|R], NeedLevel, NumAcc) ->
    #p_equip{stone_list = StoneList} = Equip,
    NumAcc2 = get_stone_level_num3(StoneList, NeedLevel, 0) + NumAcc,
    get_stone_level_num2(R, NeedLevel, NumAcc2).

get_stone_level_num3([], _NeedLevel, NumAcc) ->
    NumAcc;
get_stone_level_num3([#p_kv{val = StoneID}|R], NeedLevel, NumAcc) ->
    NumAcc2 =
        case lib_config:find(cfg_stone, StoneID) of
            [#c_stone{level = Level}] ->
                ?IF(Level >= NeedLevel, NumAcc + 1, NumAcc);
            _ ->
                NumAcc
        end,
    get_stone_level_num3(R, NeedLevel, NumAcc2).

get_base_equip_attr(TypeID) ->
    [EquipConfig] = lib_config:find(cfg_equip, TypeID),
    get_base_equip_attr2(EquipConfig).

get_base_equip_attr2(EquipConfig) ->
    #c_equip{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_arp = AddArp,
        add_defence = AddDefence,
        add_hit_rate = AddHitRate,
        add_miss = AddMiss,
        add_double = AddDouble,
        add_double_anti = AddDoubleAnti
    } = EquipConfig,
    #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        arp = {AddArp, 0},
        defence = {AddDefence, 0},
        hit_rate = {AddHitRate, 0},
        miss = {AddMiss, 0},
        double = {AddDouble, 0},
        double_anti = {AddDoubleAnti, 0}}.

get_equip_special_attr(TypeID) ->
    case lib_config:find(cfg_equip_special_props, TypeID) of
        [Config] ->
            #c_equip_special_props{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_drain = AddDrain,
                add_role_hurt_add = AddRoleHurtAdd,
                add_skill_hurt = AddSkillHurt,
                add_kill_hurt_anti = AddSkillHurtAnti,
                add_hp_rate = AddHpRate,
                add_attack_rate = AddAttackRate,
                add_hurt_rate = AddHurtRate,
                add_hurt_derate = AddHurtDerate
            } = Config,
            #actor_cal_attr{
                max_hp = {AddHp, AddHpRate},
                attack = {AddAttack, AddAttackRate},
                drain = {AddDrain, 0},
                role_hurt_add = AddRoleHurtAdd,
                skill_hurt = {AddSkillHurt, 0},
                skill_hurt_anti = {AddSkillHurtAnti, 0},
                hurt_rate = AddHurtRate,
                hurt_derate = AddHurtDerate};
        _ ->
            #actor_cal_attr{}
    end.

%% 装备基础属性 + 装备特殊属性
get_equip_attr(TypeID) ->
    common_misc:sum_calc_attr([get_base_equip_attr(TypeID), get_equip_special_attr(TypeID)]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 得到铸魂属性与铸魂养成
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_forge_soul_rate_and_attr(ForgeSoulID, Step, IndexID, ForgeSoulLevel) ->  %% 返回{ForgeSoulRate, ForgeSoulList}
    case Step >= ?EQUIP_FORGE_SOUL_LEVEL of  %%  9阶才生效
        true ->
            PropsList1 =    %% 得到【镇魂属性】的加成列表
            case ForgeSoulID > 0 andalso lib_config:find(cfg_forge_soul, ForgeSoulID) of
                [#c_forge_soul{add_attribute_recursive = AddPropString}] ->
                    common_misc:get_string_props(AddPropString);
                _ ->
                    []
            end,
            PropsList2 =    %% 得到【镇魂养成】的加成列表
            case ForgeSoulLevel > 0 andalso lib_config:find(cfg_forge_soul_cultivate, {IndexID, ForgeSoulLevel}) of
                [#c_forge_soul_cultivate{add_attribute_recursive = AddPropString2}] ->
                    common_misc:get_string_props(AddPropString2);
                _ ->
                    []
            end,
            lists:foldl(
                fun(#p_kv{id = Key, val = Val} = KV, {RateAcc, PropAcc}) ->
                    if
                        Key =:= ?ATTR_EQUIP_BASE_RATE ->
                            {Val + RateAcc, PropAcc};
                        true ->
                            {RateAcc, [KV|PropAcc]}
                    end
                end, {0, []}, PropsList1 ++ PropsList2);
        _ ->
            {0, []}
    end.

get_forge_base_attr(EquipConfig, ForgeSoulRate, ForgeSoulAttr) ->
    BaseAttr = ?IF(ForgeSoulRate > 0, get_forge_base_attr2(EquipConfig, ForgeSoulRate), get_base_equip_attr2(EquipConfig)),
    common_misc:sum_calc_attr2(BaseAttr, ForgeSoulAttr). %% 把增加过的-基础属性-和-属性增量-相加

get_forge_base_attr2(EquipConfig, Rate) ->
    #c_equip{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_arp = AddArp,
        add_defence = AddDefence,
        add_hit_rate = AddHitRate,
        add_miss = AddMiss,
        add_double = AddDouble,
        add_double_anti = AddDoubleAnti
    } = EquipConfig,
    NewHp = AddHp * (1 + Rate / ?RATE_10000),
    NewAttack = AddAttack * (1 + Rate / ?RATE_10000),
    NewAddArp = AddArp * (1 + Rate / ?RATE_10000),
    NewDefence = AddDefence * (1 + Rate / ?RATE_10000),
    NewHitRate = AddHitRate * (1 + Rate / ?RATE_10000),
    NewMiss = AddMiss * (1 + Rate / ?RATE_10000),
    NewAddDouble = AddDouble * (1 + Rate / ?RATE_10000),
    NewAddDoubleAnti = AddDoubleAnti * (1 + Rate / ?RATE_10000),
    #actor_cal_attr{
        max_hp = {NewHp, 0},
        attack = {NewAttack, 0},
        arp = {NewAddArp, 0},
        defence = {NewDefence, 0},
        hit_rate = {NewHitRate, 0},
        miss = {NewMiss, 0},
        double = {NewAddDouble, 0},
        double_anti = {NewAddDoubleAnti, 0}}.

handle({#m_equip_refine_tos{equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_refine(RoleID, State, EquipID);
handle({#m_equip_stone_compose_tos{equip_id = EquipID, index = StoneIndex, material_list = MaterialList}, RoleID, _PID}, State) ->
    do_equip_stone_compose(RoleID, EquipID, StoneIndex, MaterialList, State);
handle({#m_stone_punch_tos{equip_id = EquipID, stone_id = StoneID, punch_index = PunchIndex}, RoleID, _PID}, State) ->
    do_stone_punch(RoleID, State, EquipID, StoneID, PunchIndex);
handle({#m_stone_remove_tos{equip_id = EquipID, stone_index = StoneIndex}, RoleID, _PID}, State) ->
    do_stone_remove(RoleID, State, EquipID, StoneIndex);
handle({#m_equip_compose_tos{equip_id = EquipID, material_list = MaterialList}, RoleID, _PID}, State) ->
    do_equip_compose(RoleID, State, EquipID, MaterialList);
handle({#m_equip_suit_tos{equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_suit(RoleID, State, EquipID);
handle({#m_stone_compose_tos{stone_id = StoneID}, RoleID, _PID}, State) ->
    do_stone_compose(RoleID, StoneID, State);
handle({#m_stone_one_key_tos{type = ?EQUIP_STONE_ONE_KEY_UP, id_list = IDList}, RoleID, _PID}, State) ->
    do_stone_one_key_up(RoleID, IDList, State);
handle({#m_stone_one_key_tos{type = ?EQUIP_STONE_ONE_KEY_REMOVE}, RoleID, _PID}, State) ->
    do_stone_one_key_remove(RoleID, State);
handle({#m_stone_honing_tos{equip_id = EquipID, index = Index}, RoleID, _PID}, State) ->
    do_stone_honing(RoleID, EquipID, Index, State);
handle({#m_equip_concise_open_tos{equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_concise_open(RoleID, EquipID, State);
handle({#m_equip_concise_tos{equip_id = EquipID, type = Type, lock_index_list = LockIndexList}, RoleID, _PID}, State) ->
    do_equip_concise(RoleID, EquipID, Type, LockIndexList, State);
handle({#m_equip_jewelry_step_tos{equip_id = EquipID}, RoleID, _PID}, State) ->
    do_jewelry_step(RoleID, State, EquipID);
handle({#m_equip_forge_soul_open_tos{equip_id = EquipID, equip_location_id = EquipLocationID}, RoleID, _PID}, State) ->
    do_equip_forge_soul_open_tos(RoleID, EquipID, EquipLocationID, State);
handle({#m_equip_forge_soul_cultivate_tos{equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_forge_soul_cultivate(RoleID, EquipID, State);
handle({#m_equip_seal_compose_tos{equip_id = EquipID, index = StoneIndex, material_list = MaterialList}, RoleID, _PID}, State) ->
    do_equip_seal_compose(RoleID, EquipID, StoneIndex, MaterialList, State);
handle({#m_seal_punch_tos{equip_id = EquipID, seal_id = StoneID, punch_index = PunchIndex}, RoleID, _PID}, State) ->
    do_seal_punch(RoleID, State, EquipID, StoneID, PunchIndex);
handle({#m_seal_remove_tos{equip_id = EquipID, seal_index = StoneIndex}, RoleID, _PID}, State) ->
    do_seal_remove(RoleID, State, EquipID, StoneIndex);
handle({#m_seal_compose_tos{seal_id = StoneID}, RoleID, _PID}, State) ->
    do_seal_compose(RoleID, StoneID, State);
handle({#m_seal_one_key_tos{type = ?EQUIP_STONE_ONE_KEY_UP, id_list = IDList}, RoleID, _PID}, State) ->
    do_seal_one_key_up(RoleID, IDList, State);
handle({#m_seal_one_key_tos{type = ?EQUIP_STONE_ONE_KEY_REMOVE}, RoleID, _PID}, State) ->
    do_seal_one_key_remove(RoleID, State);
handle(modify_role_equip_concise, State) ->
    modify_role_equip_concise(State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info : ~w", [Info]),
    State.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% 装备强化
do_equip_refine(RoleID, State, EquipID) ->
    case catch check_can_refine(EquipID, State) of
        {ok, RefineLevel, RefineLevel2, Multi, NewEquip, AssetDoing, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_equip_refine_toc{equip = NewEquip, multi = Multi}),
            State6 =
            case RefineLevel =/= RefineLevel2 of
                true ->
                    NoticeLevel = common_misc:get_global_int(?GLOBAL_NOTICE_LEVEL),
                    [                                                           common_broadcast:send_world_common_notice(?NOTICE_EQUIP_REFINE, [mod_role_data:get_role_name(State), get_equip_name(EquipID), lib_tool:to_list(LevelIndex)]) ||
                        LevelIndex <- lists:seq(RefineLevel + 1, RefineLevel2), LevelIndex rem NoticeLevel =:= 0, LevelIndex >= 40],
                    State4 = calc(State3),
                    State5 = mod_role_fight:calc_attr_and_update(State4, ?POWER_UPDATE_EQUIP_REFINE, EquipID),
                    mod_role_confine:all_equip_Level(Log#log_equip_refine.all_refine_level, State5);
                _ ->
                    State3
            end,
            mod_role_dict:add_background_logs(Log),
            State7 = mod_role_daily_liveness:trigger_daily_liveness(State6, ?LIVENESS_STRENGTHEN_EQUIP),
            mod_role_mission:refine_trigger(State7);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_refine_toc{err_code = ErrCode}),
            case ErrCode =:= ?ERROR_COMMON_NO_ENOUGH_SILVER of
                true ->
                    State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_STRENGTH_COIN_NOT_ENOUGH, State),
                    mod_role_discount_pay:condition_update(State2);
                _ ->
                    State
            end
    end.

check_can_refine(EquipID, State) ->
    mod_role_function:is_function_open(?FUNCTION_EQUIP_REFINE, State),
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case lists:keyfind(EquipID, #p_equip.equip_id, EquipList) of
        #p_equip{} = Equip ->
            ok;
        _ ->
            Equip = ?THROW_ERR(?ERROR_EQUIP_REFINE_001)
    end,
    #p_equip{equip_id = EquipID, refine_level = RefineLevel, mastery = Mastery} = Equip,
    [#c_equip{index = EquipIndex} = EquipConfig] = lib_config:find(cfg_equip, EquipID),
    NewRefineLevel = RefineLevel + 1,
    case get_refine_config(EquipConfig, NewRefineLevel) of
        [#c_equip_refine{} = RefineConfig] -> ok;
        _ -> RefineConfig = ?THROW_ERR(?ERROR_EQUIP_REFINE_002)
    end,
    #c_equip_refine{
        need_role_level = NeedRoleLevel,
        asset_num = AssetNum,
        add_mastery = AddMastery,
        multi_rate = MultiRateString
    } = RefineConfig,
    ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_SILVER, AssetNum, ?ASSET_SILVER_REDUCE_FROM_EQUIP_REFINE, State),
    Multi = lib_tool:get_weight_output(lib_tool:string_to_intlist(MultiRateString)),
    {RefineLevel2, Mastery2} = get_new_refine_level(EquipConfig, RefineLevel, Mastery + AddMastery * Multi),
    NewEquip = Equip#p_equip{refine_level = RefineLevel2, mastery = Mastery2},
    EquipList2 = lists:keyreplace(EquipID, #p_equip.equip_id, EquipList, NewEquip),
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    Log = get_refine_log(EquipID, EquipIndex, AddMastery, RefineLevel, RefineLevel2, AssetNum, State2),
    {ok, RefineLevel, RefineLevel2, Multi, NewEquip, AssetDoing, Log, State2}.


get_new_refine_level(EquipConfig, RefineLevel, Mastery) ->
    NewRefineLevel = RefineLevel + 1,
    case get_refine_config(EquipConfig, RefineLevel + 1) of
        [#c_equip_refine{level_mastery = LevelMastery}] ->
            case Mastery >= LevelMastery of
                true ->
                    get_new_refine_level(EquipConfig, NewRefineLevel, Mastery - LevelMastery);
                _ ->
                    {RefineLevel, Mastery}
            end;
        _ ->
            {RefineLevel, Mastery}
    end.

%% 身上的灵石升级
do_equip_stone_compose(RoleID, EquipID, StoneIndex, MaterialList, State) ->
    case catch check_equip_stone_compose(EquipID, StoneIndex, MaterialList, State) of
        {ok, BagDoings, Log, Equip2, State2} ->
            mod_role_dict:add_background_logs(Log),
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_equip_stone_compose_toc{equip = Equip2}),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_STONE_UP, StoneIndex),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:stone_compose(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:stone_level_num(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_stone_compose_toc{err_code = ErrCode}),
            State
    end.

check_equip_stone_compose(EquipID, StoneIndex, MaterialList, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipListT} ->
            #p_equip{stone_list = StoneList} = Equip,
            case lists:keytake(StoneIndex, #p_kv.id, StoneList) of
                {value, #p_kv{val = StoneID} = KV, StoneListT} ->
                    [#c_stone{compose_type_id = NewStoneID, compose_num = Num}] = lib_config:find(cfg_stone, StoneID),
                    ?IF(NewStoneID > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                    check_equip_stone_compose2(lists:keysort(#p_kv.id, MaterialList), StoneID, Num - 1),
                    {ItemList, LogGoods} =
                    lists:foldl(
                        fun(#p_kv{id = MaterialID, val = MaterialNum}, {Acc1, Acc2}) ->
                            {[{MaterialID, MaterialNum}|Acc1], [#p_goods{type_id = MaterialID, num = MaterialNum}|Acc2]}
                        end, {[], []}, MaterialList),
                    BagDoings = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_STONE_COMPOSE, State),
                    Log = mod_role_extra:get_compose_log(StoneID, LogGoods, State),
                    StoneList2 = [KV#p_kv{val = NewStoneID}|StoneListT],
                    Equip2 = Equip#p_equip{stone_list = StoneList2},
                    EquipList2 = [Equip2|EquipListT],
                    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
                    State2 = State#r_role{role_equip = RoleEquip2},
                    {ok, BagDoings, Log, Equip2, State2};
                _ ->
                    ?THROW_ERR(?ERROR_EQUIP_STONE_COMPOSE_002)
            end;
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_STONE_COMPOSE_001)
    end.

check_equip_stone_compose2([], _NeedStoneID, _NeedNum) ->
    ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM);
check_equip_stone_compose2([#p_kv{id = StoneID, val = Num}|R], NeedStoneID, NeedNum) ->
    [#c_stone{compose_type_id = ComposeStoneID, compose_num = ComposeNum}] = lib_config:find(cfg_stone, StoneID),
    case StoneID =:= NeedStoneID of
        true ->
            ?IF(Num =:= NeedNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM));
        _ ->
            ?IF(Num >= ComposeNum andalso Num rem ComposeNum =:= 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
            Num2 = Num div ComposeNum,
            R2 =
            case lists:keytake(ComposeStoneID, #p_kv.id, R) of
                {value, #p_kv{val = OldVal} = KV, RT} ->
                    [KV#p_kv{val = OldVal + Num2}|RT];
                _ ->
                    [#p_kv{id = ComposeStoneID, val = Num2}|R]
            end,
            check_equip_stone_compose2(R2, NeedStoneID, NeedNum)
    end.

%% 灵石镶嵌
do_stone_punch(RoleID, State, EquipID, StoneID, PunchIndex) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case catch check_stone_punch(EquipID, StoneID, PunchIndex, EquipList, State) of
        {ok, Equip2, EquipList2, AllStoneList2, BagDoings, Log, StoneName, StoneType, StoneLevel} ->
            common_misc:unicast(RoleID, #m_stone_punch_toc{equip = Equip2}),
            State2 = mod_role_bag:do(BagDoings, State),
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State3 = State2#r_role{role_equip = RoleEquip2},
            State4 = calc(State3),
            {StoneTypeLevel, LevelNumList} = get_stone_type_level(StoneType, lists:flatten(AllStoneList2), StoneLevel),
            mod_role_dict:add_background_logs(Log),
            State6 = mod_role_fight:calc_attr_and_update(State4, ?POWER_UPDATE_EQUIP_STONE, StoneID),
            ?IF(StoneName =/= [],
                common_broadcast:send_world_common_notice(?NOTICE_EQUIP_STONE, [mod_role_data:get_role_name(State6), get_equip_name(EquipID), StoneName]),
                ok),
            FuncList = [
                fun(StateAcc) -> mod_role_confine:equip_stone(StoneTypeLevel, StoneType, StateAcc) end,
                fun(StateAcc) -> mod_role_confine:equip_stone_level(LevelNumList, StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:stone_level_num(StateAcc) end
            ],
            role_server:execute_state_fun(FuncList, State6);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_punch_toc{err_code = ErrCode}),
            State
    end.

check_stone_punch(EquipID, StoneID, PunchIndex, EquipList, State) ->
    mod_role_function:is_function_open(?FUNCTION_EQUIP_STONE, State),
    Num = mod_role_bag:get_num_by_type_id(StoneID, State),
    ?IF(Num >= 1, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM)),
    BagDoings = [{decrease, ?ITEM_REDUCE_EQUIP_PUNCH, [#r_goods_decrease_info{type = first_bind, type_id = StoneID, num = 1}]}],
    [#c_stone{equip_index_list = EquipIndexList, name = StoneName, level = StoneLevel, type = StoneType}] = lib_config:find(cfg_stone, StoneID),
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, RemainList} -> ok;
        _ -> Equip = RemainList = ?THROW_ERR(?ERROR_STONE_PUNCH_001)
    end,
    #p_equip{stone_list = StoneList} = Equip,
    [#c_equip{index = EquipIndex, stone_num = StoneNum}] = lib_config:find(cfg_equip, EquipID),
    ?IF(lists:member(EquipIndex, EquipIndexList), ok, ?THROW_ERR(?ERROR_STONE_PUNCH_002)),
    case PunchIndex =:= ?VIP_STONE_INDEX of
        true ->
            ?IF(mod_role_vip:get_vip_stone_num(State) > 0, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL));
        _ ->
            ?IF(StoneNum >= PunchIndex andalso PunchIndex > 0, ok, ?THROW_ERR(?ERROR_STONE_PUNCH_003))
    end,
    case lists:keytake(PunchIndex, #p_kv.id, StoneList) of
        {value, #p_kv{val = OldStone}, StoneList2} ->
            ReplaceStoneID = OldStone,
            mod_role_bag:check_bag_empty_grid(1, State),
            BagDoings2 = BagDoings ++ [{create, ?ITEM_GAIN_EQUIP_STONE_PUNCH, [#p_goods{type_id = OldStone, num = 1, bind = true}]}],
            StoneList3 = [#p_kv{id = PunchIndex, val = StoneID}|StoneList2];
        _ ->
            BagDoings2 = BagDoings,
            ReplaceStoneID = 0,
            StoneList3 = [#p_kv{id = PunchIndex, val = StoneID}|StoneList]
    end,
    Equip2 = Equip#p_equip{stone_list = StoneList3},
    AllStoneList = [EquipStoneList || #p_equip{stone_list = EquipStoneList} <- RemainList],
    AllStoneList2 = [StoneList3|AllStoneList],
    EquipList2 = [Equip2|RemainList],
    Log = get_stone_log(EquipID, EquipIndex, ?LOG_TYPE_PUNCH, PunchIndex, StoneID, ReplaceStoneID, State),
    StoneName2 = ?IF(StoneLevel >= 7, StoneName, ""),
    {ok, Equip2, EquipList2, AllStoneList2, BagDoings2, Log, StoneName2, StoneType, StoneLevel}.


%% 灵石移除
do_stone_remove(RoleID, State, EquipID, StoneIndex) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case catch check_stone_remove(EquipID, StoneIndex, EquipList, State) of
        {ok, Equip2, EquipList2, _AllStoneList, BagDoings, Log} ->
            common_misc:unicast(RoleID, #m_stone_remove_toc{equip = Equip2}),
            State2 = mod_role_bag:do(BagDoings, State),
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State3 = State2#r_role{role_equip = RoleEquip2},
            State4 = calc(State3),
            mod_role_dict:add_background_logs(Log),
            mod_role_fight:calc_attr_and_update(State4, ?POWER_UPDATE_EQUIP_REMOVE_STONE, StoneIndex);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_remove_toc{err_code = ErrCode}),
            State
    end.

check_stone_remove(EquipID, StoneIndex, EquipList, State) ->
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipList2} -> ok;
        _ -> Equip = EquipList2 = ?THROW_ERR(?ERROR_STONE_PUNCH_001)
    end,
    #p_equip{stone_list = StoneList} = Equip,
    case lists:keytake(StoneIndex, #p_kv.id, StoneList) of
        {value, Stone, StoneList2} ->
            ok;
        _ ->
            Stone = StoneList2 = ?THROW_ERR(?ERROR_STONE_REMOVE_003)
    end,
    mod_role_bag:check_bag_empty_grid(1, State),
    [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
    #p_kv{val = StoneID} = Stone,
    BagDoings = [{create, ?ITEM_GAIN_EQUIP_STONE_REMOVE, [#p_goods{bind = true, type_id = StoneID, num = 1}]}],

    Equip2 = Equip#p_equip{stone_list = StoneList2},
    AllStoneList = [EquipStones || #p_equip{stone_list = EquipStones} <- EquipList2],
    AllStoneList2 = [StoneList2|AllStoneList],
    EquipList3 = [Equip2|EquipList2],
    Log = get_stone_log(EquipID, EquipIndex, ?LOG_TYPE_REMOVE, StoneIndex, StoneID, 0, State),
    {ok, Equip2, EquipList3, AllStoneList2, BagDoings, Log}.

%% 装备合成
do_equip_compose(RoleID, State, EquipID, MaterialList) ->
    case catch check_can_compose(EquipID, MaterialList, State) of
        {ok, BagDoings, IsSuccess, Log} ->
            common_misc:unicast(RoleID, #m_equip_compose_toc{is_success = IsSuccess}),
            State2 = mod_role_bag:do(BagDoings, State),
            mod_role_dict:add_background_logs(Log),
            case IsSuccess of
                true ->
                    [#c_equip{index = Index, quality = Quality}] = lib_config:find(cfg_equip, EquipID),
                    ?IF(Quality >= ?QUALITY_RED, common_broadcast:send_world_common_notice(?NOTICE_EQUIP_COMPOSE, [mod_role_data:get_role_name(State2)]), ok),
                    FunList = [
                        fun(StateAcc) -> mod_role_mission:compose_trigger(EquipID, StateAcc) end,
                        fun(StateAcc) ->
                            if
                                Index =:= ?AMULET_1_INDEX orelse Index =:= ?AMULET_2_INDEX ->
                                    mod_role_day_target:compose_jewelry(StateAcc);
                                true ->
                                    mod_role_day_target:compose_equip(StateAcc)
                            end
                        end
                    ],
                    role_server:execute_state_fun(FunList, State2);
                _ ->
                    State2
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_compose_toc{err_code = ErrCode}),
            State
    end.

check_can_compose(EquipID, MaterialList, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    mod_role_function:is_function_open(?FUNCTION_EQUIP_COMPOSE, State),
    case lib_config:find(cfg_equip_compose, EquipID) of
        [Config] -> ok;
        _ -> Config = ?THROW_ERR(?ERROR_EQUIP_COMPOSE_001)
    end,
    mod_role_bag:check_bag_empty_grid(1, State),
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(MaterialList, State),
    #c_equip_compose{material_list = EquipIDList, rate = RateList} = Config,
    Num = check_can_compose2(GoodsList, EquipIDList, 0),
    RateList2 =
    [begin
         [RateNum, Rate] = string:tokens(RateString, ","),
         {lib_tool:to_integer(RateNum), lib_tool:to_integer(Rate)}
     end || RateString <- string:tokens(RateList, ";")],
    case lists:keyfind(Num, 1, RateList2) of
        {Num, Rate} ->
            DecreaseList = [#r_goods_decrease_info{id = ID, num = 1} || #p_goods{id = ID} <- GoodsList],
            Bind = lists:keymember(true, #p_goods.bind, GoodsList),
            BagDoings = [{decrease, ?ITEM_REDUCE_EQUIP_COMPOSE, DecreaseList}],
            IsSuccess = common_misc:is_active(Rate),
            BagDoings2 = ?IF(IsSuccess, [{create, ?ITEM_GAIN_EQUIP_COMPOSE, [#p_goods{type_id = EquipID, num = 1, bind = Bind}]}|BagDoings], BagDoings),
            Log = #log_equip_compose{
                role_id = RoleID,
                goods_list = common_misc:to_goods_string([Goods#p_goods{num = 1} || Goods <- GoodsList]),
                is_succ = common_misc:get_bool_int(IsSuccess),
                type_id = EquipID,
                channel_id = ChannelID,
                game_channel_id = GameChannelID
            },
            {ok, BagDoings2, IsSuccess, Log};
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_COMPOSE_003)
    end.

check_can_compose2([], _EquipIDList, Num) ->
    Num;
check_can_compose2([Goods|R], EquipIDList, Num) ->
    #p_goods{type_id = TypeID} = Goods,
    case lists:member(TypeID, EquipIDList) of
        true ->
            check_can_compose2(R, EquipIDList, Num + 1);
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_COMPOSE_002)
    end.

%% 提升套装等级
do_equip_suit(RoleID, State, EquipID) ->
    case catch check_can_suit(EquipID, State) of
        {ok, BagDoings, BroadcastName1, BroadcastName2, Equip, GodBookArgs, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_equip_suit_toc{equip = Equip}),
            State4 = calc(State3),
            State5 = mod_role_fight:calc_attr_and_update(State4, ?POWER_UPDATE_EQUIP_SUIT, EquipID),
            State6 = mod_role_god_book:load_suit_equip(GodBookArgs, State5),
            State7 = suit_trigger(State6),
            common_broadcast:send_world_common_notice(?NOTICE_EQUIP_SUIT, [mod_role_data:get_role_name(State7), BroadcastName1, BroadcastName2]),
            State7;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_suit_toc{err_code = ErrCode}),
            State
    end.

check_can_suit(EquipID, State) ->
    mod_role_function:is_function_open(?FUNCTION_EQUIP_SUIT, State),
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case lists:keyfind(EquipID, #p_equip.equip_id, EquipList) of
        #p_equip{} = Equip ->
            ok;
        _ ->
            Equip = ?THROW_ERR(?ERROR_EQUIP_SUIT_001)
    end,
    #p_equip{suit_level = SuitLevel} = Equip,
    [#c_equip{
        index = Index,
        step = Step,
        suit_level1 = SuitLevel1,
        suit_item1 = SuitItem1,
        suit_level2 = SuitLevel2,
        suit_item2 = SuitItem2
    }] = lib_config:find(cfg_equip, EquipID),
    EquipName = get_equip_name(EquipID),
    if
        SuitLevel1 > 0 andalso SuitLevel < SuitLevel1 ->
            BroadcastName1 = EquipName,
            BroadcastName2 = ?EQUIP_SUIT_1 ++ EquipName,
            NewSuitLevel = ?EQUIP_SUIT_LEVEL_IMMORTAL,
            SuitItem = SuitItem1;
        SuitLevel2 > 0 andalso SuitLevel < SuitLevel2 ->
            BroadcastName1 = EquipName,
            BroadcastName2 = ?EQUIP_SUIT_2 ++ EquipName,
            NewSuitLevel = ?EQUIP_SUIT_LEVEL_GOD,
            SuitItem = SuitItem2;
        true ->
            BroadcastName1 = BroadcastName2 = NewSuitLevel = SuitItem = ?THROW_ERR(?ERROR_EQUIP_SUIT_002)
    end,
    ItemList = common_misc:get_item_reward(SuitItem),
    BagDoings = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_EQUIP_SUIT, State),
    Equip2 = Equip#p_equip{suit_level = NewSuitLevel},
    EquipList2 = lists:keyreplace(EquipID, #p_equip.equip_id, EquipList, Equip2),
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, BroadcastName1, BroadcastName2, Equip2, [Index, Step, NewSuitLevel], State2}.

%% 宝石合成
do_stone_compose(RoleID, StoneID, State) ->
    case catch check_stone_compose(StoneID, State) of
        {ok, BagDoings, Log} ->
            common_misc:unicast(RoleID, #m_stone_compose_toc{}),
            State2 = mod_role_bag:do(BagDoings, State),
            State3 = mod_role_mission:compose_trigger(StoneID, State2),
            mod_role_dict:add_background_logs(Log),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:stone_compose(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_compose_toc{err_code = ErrCode}),
            State
    end.

check_stone_compose(TypeID, State) ->
    mod_role_function:is_function_open(?FUNCTION_EQUIP_COMPOSE, State),
    case lib_config:find(cfg_stone, TypeID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_EQUIP_COMPOSE_001)
    end,
    mod_role_bag:check_bag_empty_grid(1, State),
    case Config of
        #c_stone{compose_type_id = StoneID, compose_num = Num} when StoneID > 0 ->
            ok;
        _ ->
            StoneID = Num = ?THROW_ERR(?ERROR_EQUIP_COMPOSE_002)
    end,
    DecreaseList = mod_role_bag:get_decrease_goods_by_num(TypeID, Num, State),
    Bind = lists:keymember(true, #r_goods_decrease_info.id_bind_type, DecreaseList),
    BagDoings2 = [{decrease, ?ITEM_REDUCE_STONE_COMPOSE, DecreaseList}] ++
                 [{create, ?ITEM_GAIN_STONE_COMPOSE, [#p_goods{type_id = StoneID, num = 1, bind = Bind}]}],
    Log = mod_role_extra:get_compose_log(StoneID, [#p_goods{type_id = TypeID, num = Num}], State),
    {ok, BagDoings2, Log}.

%% 一键
do_stone_one_key_up(RoleID, IDList, State) ->
    case catch check_stone_one_key_up(IDList, State) of
        {ok, BagDoings, UpdateEquips, Logs, HpNum, AtNum, LevelNumList, State2} ->
            State4 = mod_role_bag:do(BagDoings, State2),
            mod_role_dict:add_background_logs(Logs),
            common_misc:unicast(RoleID, #m_stone_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_UP, equip_list = UpdateEquips}),
            State5 = mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_EQUIP_ONE_KEY_UP, 0),
            State6 = mod_role_confine:equip_stone(HpNum, ?STONE_HP, State5),
            State7 = mod_role_confine:equip_stone(AtNum, ?STONE_AT, State6),
            mod_role_confine:equip_stone_level(LevelNumList, State7);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_UP, err_code = ErrCode}),
            State
    end.

check_stone_one_key_up(IDList, State) ->
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(IDList, State),
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    HasVipStone = mod_role_vip:get_vip_stone_num(State) > 0,
    {EquipList2, BagDoings, UpdateEquips, Logs} = check_stone_one_key_up2(GoodsList, EquipList, HasVipStone, State),
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {HpNum, AtNum, LevelNumList} = cal_hp_at_level_stone_num(EquipList2),
    {ok, BagDoings, UpdateEquips, Logs, HpNum, AtNum, LevelNumList, State2}.

check_stone_one_key_up2(GoodsList, EquipList, HasVipStone, State) ->
    StoneList =
    lists:foldl(
        fun(#p_goods{type_id = TypeID, num = Num}, Acc) ->
            case lists:keyfind(TypeID, #p_kvs.id, Acc) of
                #p_kvs{val = OldNum} = KVS ->
                    lists:keyreplace(TypeID, #p_kvs.id, Acc, KVS#p_kvs{val = OldNum + Num});
                _ ->
                    [#c_stone{equip_index_list = IndexList}] = lib_config:find(cfg_stone, TypeID),
                    [#p_kvs{id = TypeID, val = Num, text = IndexList}|Acc]
            end
        end, [], GoodsList),
    SortEquipList = sort_equip_list(EquipList),
    {StoneList2, EquipList2, UpdateEquips, Logs} = check_stone_one_key_up3(StoneList, SortEquipList, HasVipStone, State, [], [], []),
    DecreaseList = get_stone_up_decrease(StoneList, StoneList2, []),
    ?IF(DecreaseList =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    BagDoings = [{decrease, ?ITEM_REDUCE_EQUIP_PUNCH, DecreaseList}],
    {EquipList2, BagDoings, UpdateEquips, Logs}.


check_stone_one_key_up3([], SortEquipList, _HasVipStone, _State, EquipAcc, UpdateAcc, LogsAcc) ->
    EquipList = [Equip || {_Index, _StoneNum, Equip} <- SortEquipList],
    {[], EquipList ++ EquipAcc, UpdateAcc, LogsAcc};
check_stone_one_key_up3(StoneList, [], _HasVipStone, _State, EquipAcc, UpdateAcc, LogsAcc) ->
    {StoneList, EquipAcc, UpdateAcc, LogsAcc};
check_stone_one_key_up3(StoneList, [{EquipIndex, StoneNum, Equip}|R], HasVipStone, State, EquipAcc, UpdateAcc, LogsAcc) ->
    CheckList = ?IF(StoneNum > 0, [CheckSealIndex || CheckSealIndex <- lists:seq(1, StoneNum)], []),
    CheckList2 = ?IF(HasVipStone, [?VIP_STONE_INDEX|CheckList], CheckList),
    case CheckList2 =/= [] of
        true ->
            %% 先按大小进行排序
            StoneList2 = lists:reverse(lists:keysort(#p_kvs.id, StoneList)),
            {Equip2, StoneList3, Logs} = check_stone_one_key_up4(StoneList2, EquipIndex, CheckList2, Equip, State),
            UpdateAcc2 = ?IF(Logs =/= [], [Equip2|UpdateAcc], UpdateAcc),
            check_stone_one_key_up3(StoneList3, R, HasVipStone, State, [Equip2|EquipAcc], UpdateAcc2, Logs ++ LogsAcc);
        _ ->
            check_stone_one_key_up3(StoneList, R, HasVipStone, State, [Equip|EquipAcc], UpdateAcc, LogsAcc)
    end.

%% 对一件装备进行替换
check_stone_one_key_up4(StoneList, EquipIndex, CheckList2, Equip, State) ->
    #p_equip{equip_id = EquipID, stone_list = EquipStoneList} = Equip,
    EmptyList = get_stone_empty_list(CheckList2, EquipStoneList),
    case EmptyList =/= [] of
        true ->
            {StoneAddList, StoneList2, Logs} = replace_stones(EmptyList, EquipID, EquipIndex, StoneList, State, [], [], []),
            case StoneAddList =/= [] of
                true ->
                    EquipStoneList2 = StoneAddList ++ EquipStoneList,
                    Equip2 = Equip#p_equip{stone_list = EquipStoneList2},
                    {Equip2, StoneList2, Logs};
                _ ->
                    {Equip, StoneList, []}
            end;
        _ ->
            {Equip, StoneList, []}
    end.

sort_equip_list(EquipList) ->
    SortEquipList =
    [begin
         [#c_equip{index = Index, stone_num = StoneNum}] = lib_config:find(cfg_equip, Equip#p_equip.equip_id),
         {Index, StoneNum, Equip}
     end || Equip <- EquipList],
    lists:keysort(1, SortEquipList).

get_stone_empty_list([], _EquipStoneList) ->
    [];
get_stone_empty_list(CheckList, []) ->
    CheckList;
get_stone_empty_list(CheckList, [#p_kv{id = Index}|R]) ->
    CheckList2 = lists:delete(Index, CheckList),
    get_stone_empty_list(CheckList2, R).

replace_stones([], _EquipID, _EquipIndex, StoneList, _State, StoneAddAcc, StoneAcc, LogsAcc) ->
    {StoneAddAcc, StoneList ++ StoneAcc, LogsAcc};
replace_stones(_EmptyList, _EquipID, _EquipIndex, [], _State, StoneAddAcc, StoneAcc, LogsAcc) ->
    {StoneAddAcc, StoneAcc, LogsAcc};
replace_stones(EmptyList, EquipID, EquipIndex, [#p_kvs{id = TypeID, val = Num, text = IndexList} = KVS|R], State, StoneAddAcc, StoneAcc, LogsAcc) ->
    case lists:member(EquipIndex, IndexList) of
        true ->
            CheckNum = erlang:length(EmptyList),
            case Num >= CheckNum of
                true -> %% 填满~~
                    AddList = EmptyList,
                    EmptyList2 = [],
                    Num2 = Num - CheckNum;
                _ ->
                    {AddList, EmptyList2} = lib_tool:split(Num, EmptyList),
                    Num2 = 0
            end,
            StoneList2 = ?IF(Num2 > 0, [KVS#p_kvs{val = Num2}|R], R),
            StoneAdd = [#p_kv{id = StoneIndex, val = TypeID} || StoneIndex <- AddList],
            Logs = [get_stone_log(EquipID, EquipIndex, ?LOG_TYPE_PUNCH, StoneIndex, TypeID, 0, State) || StoneIndex <- AddList],
            replace_stones(EmptyList2, EquipID, EquipIndex, StoneList2, State, StoneAdd ++ StoneAddAcc, StoneAcc, Logs ++ LogsAcc);
        _ ->
            replace_stones(EmptyList, EquipID, EquipIndex, R, State, StoneAddAcc, [KVS|StoneAcc], LogsAcc)
    end.

get_stone_up_decrease(StoneList, [], Acc) ->
    DecreaseList = [#r_goods_decrease_info{type_id = TypeID, num = Num} || #p_kvs{id = TypeID, val = Num} <- StoneList],
    DecreaseList ++ Acc;
get_stone_up_decrease([#p_kvs{id = TypeID, val = Num}|R], StoneList2, Acc) ->
    case lists:keytake(TypeID, #p_kvs.id, StoneList2) of
        {value, #p_kvs{val = RemainNum}, StoneList3} ->
            Acc2 = ?IF(Num > RemainNum, [#r_goods_decrease_info{type_id = TypeID, num = Num - RemainNum}|Acc], Acc);
        _ ->
            StoneList3 = StoneList2,
            Acc2 = [#r_goods_decrease_info{type_id = TypeID, num = Num}|Acc]
    end,
    get_stone_up_decrease(R, StoneList3, Acc2).

do_stone_one_key_remove(RoleID, State) ->
    case catch check_one_key_remove(State) of
        {ok, BagDoings, UpdateEquips, Logs, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_stone_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_REMOVE, equip_list = UpdateEquips}),
            mod_role_dict:add_background_logs(Logs),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_ONE_KEY_DOWN, 0);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_REMOVE, err_code = ErrCode}),
            State
    end.

check_one_key_remove(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {EquipList2, UpdateEquips, TypeIDList, Logs} = check_one_key_remove2(EquipList, State, [], [], [], []),
    CreateList = [#p_goods{type_id = TypeID, num = 1, bind = true} || TypeID <- TypeIDList],
    CreateList2 = mod_role_bag:get_create_list(CreateList),
    mod_role_bag:check_bag_empty_grid(CreateList2, State),
    BagDoings = [{create, ?ITEM_GAIN_EQUIP_STONE_REMOVE, CreateList2}],
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, UpdateEquips, Logs, State2}.

check_one_key_remove2([], _State, EquipAcc, UpdateAcc, StoneAcc, LogAcc) ->
    {EquipAcc, UpdateAcc, StoneAcc, LogAcc};
check_one_key_remove2([#p_equip{equip_id = EquipID, stone_list = StoneList} = Equip|R], State, EquipAcc, UpdateAcc, StoneAcc, LogAcc) ->
    case StoneList =/= [] of
        true ->
            [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
            {Stones, Logs} =
            lists:foldl(
                fun(#p_kv{id = StoneIndex, val = StoneID}, {Acc1, Acc2}) ->
                    NewAcc1 = [StoneID|Acc1],
                    NewAcc2 = [get_stone_log(EquipID, EquipIndex, ?LOG_TYPE_REMOVE, StoneIndex, StoneID, 0, State)|Acc2],
                    {NewAcc1, NewAcc2}
                end, {[], []}, StoneList),
            Equip2 = Equip#p_equip{stone_list = []},
            check_one_key_remove2(R, State, [Equip2|EquipAcc], [Equip2|UpdateAcc], Stones ++ StoneAcc, Logs ++ LogAcc);
        _ ->
            check_one_key_remove2(R, State, [Equip|EquipAcc], UpdateAcc, StoneAcc, LogAcc)
    end.

do_stone_honing(RoleID, EquipID, Index, State) ->
    case catch check_stone_honing(EquipID, Index, State) of
        {ok, BagDoings, StoneHoning, State2} ->
            common_misc:unicast(RoleID, #m_stone_honing_toc{equip_id = EquipID, stone_honing = StoneHoning}),
            State3 = mod_role_bag:do(BagDoings, State2),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_STONE_HONING, EquipID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_stone_honing_toc{err_code = ErrCode}),
            case ErrCode =:= ?ERROR_COMMON_NO_ENOUGH_ITEM of
                true ->
                    State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_STONE_HONE, State),
                    mod_role_discount_pay:condition_update(State2);
                _ ->
                    State
            end
    end.

check_stone_honing(EquipID, Index, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {Equip, EquipList2} =
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, #p_equip{} = EquipT, EquipListT} ->
            {EquipT, EquipListT};
        _ ->
            ?THROW_ERR(?ERROR_STONE_HONING_001)
    end,
    #p_equip{stone_list = StoneList, stone_honings = StoneHoningList} = Equip,
    StoneID =
    case lists:keyfind(Index, #p_kv.id, StoneList) of
        #p_kv{val = StoneIDT} ->
            StoneIDT;
        _ ->
            ?THROW_ERR(?ERROR_STONE_HONING_002)
    end,
    [#c_stone{type = StoneType, level = StoneLevel}] = lib_config:find(cfg_stone, StoneID),
    ?IF(StoneLevel >= ?STONE_HONING_LEVEL, ok, ?THROW_ERR(?ERROR_STONE_HONING_002)),
    {StoneHoning2, StoneHoningList2} =
    case lists:keytake(Index, #p_kv.id, StoneHoningList) of
        {value, StoneHoningT, StoneHoningListT} ->
            #p_kv{val = HoningID} = StoneHoningT,
            HoningID2 = HoningID + 1,
            case lib_config:find(cfg_stone_honing, HoningID2) of
                [_Config] ->
                    {StoneHoningT#p_kv{val = HoningID2}, StoneHoningListT};
                _ ->
                    ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
            end;
        _ ->
            HoningID = get_first_honing_id(StoneType),
            {#p_kv{id = Index, val = HoningID}, StoneHoningList}
    end,
    #p_kv{val = UpHoningID} = StoneHoning2,
    [#c_stone_honing{need_item = NeedItemString}] = lib_config:find(cfg_stone_honing, UpHoningID),
    NeedItemList = lib_tool:string_to_intlist(NeedItemString),
    BagDoings = mod_role_bag:check_num_by_item_list(NeedItemList, ?ITEM_REDUCE_STONE_HONING, State),
    StoneHoningList3 = [StoneHoning2|StoneHoningList2],
    Equip2 = Equip#p_equip{stone_honings = StoneHoningList3},
    EquipList3 = [Equip2|EquipList2],
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList3},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, StoneHoning2, State2}.

%% 洗练孔数开启
do_equip_concise_open(RoleID, EquipID, State) ->
    case catch check_concise_open(EquipID, State) of
        {ok, Equip2, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_equip_concise_open_toc{equip = Equip2}),
            State4 = calc(State3),
            State5 = mod_role_fight:calc_attr_and_update(State4, ?POWER_UPDATE_EQUIP_CONCISE_OPEN, 0),
            mod_role_day_target:equip_concise_num(State5);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_concise_open_toc{err_code = ErrCode}),
            State
    end.

check_concise_open(EquipID, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipList2} ->
            ok;
        _ ->
            Equip = EquipList2 = ?THROW_ERR(?ERROR_EQUIP_CONCISE_OPEN_001)
    end,
    #p_equip{concise_num = ConciseNum, concise_list = ConciseList} = Equip,
    [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
    [NeedLevel] = lib_config:find(cfg_equip_concise_level, EquipIndex),
    ?IF(mod_role_data:get_role_level(State) >= NeedLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    [MaxNum, NeedGold, NeedVipLevel|_] = common_misc:get_global_list(?GLOBAL_CONCISE_OPEN),
    ?IF(ConciseNum >= MaxNum, ?THROW_ERR(?ERROR_EQUIP_CONCISE_OPEN_002), ok),
    %% 最后一级要VIPX才能开启
    ?IF((ConciseNum =:= MaxNum - 1) andalso mod_role_vip:get_vip_level(State) < NeedVipLevel, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL), ok),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_CONCISE_OPEN, State),
    ConciseNum2 = ConciseNum + 1,
    ConciseList2 = gen_first_concise(EquipIndex, [ConciseNum2], ConciseList),
    Equip2 = Equip#p_equip{concise_num = ConciseNum2, concise_list = ConciseList2},
    EquipList3 = [Equip2|EquipList2],
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList3},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, Equip2, AssetDoings, State2}.

%% 装备洗练
do_equip_concise(RoleID, EquipID, Type, LockIndexList, State) ->
    case catch check_equip_concise(EquipID, Type, LockIndexList, State) of
        {ok, IsFree, BagDoings, AssetDoings, Equip2, Log, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            State4 = mod_role_asset:do(AssetDoings, State3),
            State5 = mod_role_confine:equip_concise(State4),
            ?IF(IsFree, notice_concise_times(State4), ok),
            common_misc:unicast(RoleID, #m_equip_concise_toc{equip = Equip2}),
            mod_role_dict:add_background_logs(Log),
            State6 = calc(State5),
            mod_role_fight:calc_attr_and_update(State6, ?POWER_UPDATE_EQUIP_CONCISE, EquipID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_concise_toc{err_code = ErrCode}),
            case ErrCode =:= ?ERROR_COMMON_NO_ENOUGH_ITEM of
                true ->
                    State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_EQUIP_CONCISE, State),
                    mod_role_discount_pay:condition_update(State2);
                _ ->
                    State
            end
    end.

check_equip_concise(EquipID, Type, LockIndexList, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList, free_concise_times = FreeConciseTimes} = RoleEquip,
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipList2} ->
            ok;
        _ ->
            Equip = EquipList2 = ?THROW_ERR(?ERROR_EQUIP_CONCISE_001)
    end,
    #p_equip{concise_num = ConciseNum, concise_list = ConciseList} = Equip,
    [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
    ?IF(ConciseNum > 0, ok, ?THROW_ERR(?ERROR_EQUIP_CONCISE_002)),
    ?IF(erlang:length(LockIndexList) >= erlang:length(ConciseList), ?THROW_ERR(?ERROR_EQUIP_CONCISE_003), ok),
    case lib_config:find(cfg_equip_concise_lock, erlang:length(LockIndexList)) of
        [LockConfig] ->
            ok;
        _ ->
            LockConfig = ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    #c_equip_concise_lock{type_id = TypeID, item_num = ItemNum, gold = Gold} = LockConfig,
    if
        Type =:= ?CONCISE_ITEM_OPEN ->
            AssetDoings = [];
        Type =:= ?CONCISE_GOLD_OPEN ->
            AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, Gold, ?ASSET_GOLD_REDUCE_FROM_EQUIP_CONCISE, State)
    end,
    {FreeConciseTimes2, BagDoings, UseItemNum} =
    case FreeConciseTimes > 0 of
        true ->
            {FreeConciseTimes - 1, [], 0};
        _ ->
            Doings = mod_role_bag:check_num_by_type_id(TypeID, ItemNum, ?ITEM_REDUCE_EQUIP_CONCISE, State),
            {FreeConciseTimes, Doings, ItemNum}
    end,
    LockConciseList = check_equip_concise2(LockIndexList, ConciseList, []),
    GenIndexList = lists:seq(1, ConciseNum) -- LockIndexList,
    ConciseList2 = gen_normal_concise(EquipIndex, Type, GenIndexList, LockConciseList),
    Equip2 = Equip#p_equip{concise_list = ConciseList2},
    EquipList3 = [Equip2|EquipList2],
    RoleEquip2 = RoleEquip#r_role_equip{free_concise_times = FreeConciseTimes2, equip_list = EquipList3},
    State2 = State#r_role{role_equip = RoleEquip2},
    OldPropList = [#p_kv{id = PropKey, val = PropValue} || #p_equip_concise{prop_key = PropKey, prop_value = PropValue} <- ConciseList],
    NewPropList = [#p_kv{id = PropKey, val = PropValue} || #p_equip_concise{prop_key = PropKey, prop_value = PropValue} <- ConciseList2],
    Log = get_concise_log(EquipID, EquipIndex, OldPropList, NewPropList, TypeID, UseItemNum, Gold, State2),
    {ok, FreeConciseTimes2 =/= FreeConciseTimes, BagDoings, AssetDoings, Equip2, Log, State2}.

check_equip_concise2([], _ConciseList, Acc) ->
    Acc;
check_equip_concise2([Index|R], ConciseList, Acc) ->
    case lists:keytake(Index, #p_equip_concise.index, ConciseList) of
        {value, Concise, ConciseList2} ->
            check_equip_concise2(R, ConciseList2, [Concise|Acc]);
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_CONCISE_003)
    end.

notice_concise_times(State) ->
    #r_role{role_id = RoleID, role_equip = #r_role_equip{free_concise_times = FreeConciseTimes}} = State,
    common_misc:unicast(RoleID, #m_equip_concise_times_toc{free_concise_times = FreeConciseTimes}).

get_refine_config(EquipConfig, Level) ->
    #c_equip{index = Index} = EquipConfig,
    case ?IS_EQUIP_ARMOR(Index) of
        true ->
            lib_config:find(cfg_equip_refine, {Level, 2});
        _ ->
            lib_config:find(cfg_equip_refine, {Level, 1})
    end.

get_load_log(EquipIndex, EquipID, OldEquipID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_equip_load{
        role_id = RoleID,
        equip_index = EquipIndex,
        load_equip_id = EquipID,
        replace_equip_id = OldEquipID,
        all_equip_stars = get_all_stars(State),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_refine_log(EquipID, EquipIndex, AddMastery, OldLevel, NewLevel, AssetNum, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_equip_refine{
        role_id = RoleID,
        equip_id = EquipID,
        equip_index = EquipIndex,
        add_mastery = AddMastery,
        old_level = OldLevel,
        new_level = NewLevel,
        consume_silver = AssetNum,
        all_refine_level = get_all_refine_level(State),
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_stone_log(EquipID, EquipIndex, Type, Index, StoneID, ReplaceStoneID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_equip_stone{
        role_id = RoleID,
        equip_id = EquipID,
        equip_index = EquipIndex,
        action_type = Type,
        stone_index = Index,
        stone_id = StoneID,
        replace_stone_id = ReplaceStoneID,
        all_stone_level = get_stone_level(State),
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_seal_log(EquipID, EquipIndex, Type, Index, SealID, ReplaceID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_equip_seal{
        role_id = RoleID,
        equip_id = EquipID,
        equip_index = EquipIndex,
        action_type = Type,
        seal_index = Index,
        seal_id = SealID,
        replace_seal_id = ReplaceID,
        all_seal_level = get_seal_level(State),
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_concise_log(EquipID, EquipIndex, OldPropList, NewPropList, ItemID, ItemNum, UseGold, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_equip_concise{
        role_id = RoleID,
        equip_id = EquipID,
        equip_index = EquipIndex,
        old_prop_list = common_misc:to_kv_string(OldPropList),
        new_prop_list = common_misc:to_kv_string(NewPropList),
        item_id = ItemID,
        item_num = ItemNum,
        use_gold = UseGold,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_refine_attr(EquipConfig, RefineLv) ->
    [#c_equip_refine{
        add_attack = AddAttack,
        add_hp = AddHp,
        add_arp = AddArp,
        add_defence = AddDefence
    }] = get_refine_config(EquipConfig, RefineLv),
    #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        arp = {AddArp, 0},
        defence = {AddDefence, 0}
    }.

%% 获取初次开启的属性
gen_first_concise(EquipIndex, PropIndexList, ConciseList) ->
    ConfigList = get_concise_config_list(EquipIndex, PropIndexList, ?CONCISE_FIRST_OPEN),
    get_concise_props(ConfigList, ConciseList).

%% 元宝 or 道具洗练
gen_normal_concise(EquipIndex, Type, PropIndexList, ConciseList) ->
    ConfigList = get_concise_config_list(EquipIndex, PropIndexList, Type),
    get_concise_props(ConfigList, ConciseList).

%% 获取[{PropIndex, Config}|...]
get_concise_config_list(EquipIndex, PropIndexList, OpenType) ->
    ConfigList = cfg_equip_concise_prop:list(),
    if
        OpenType =:= ?CONCISE_FIRST_OPEN -> %%
            ConfigList2 =
            [begin
                 #c_equip_concise_prop{item_weight = ItemWeight} = Config,
                 {ItemWeight, Config}
             end || {{LoadIndex, Quality}, Config} <- ConfigList, LoadIndex =:= EquipIndex andalso Quality < ?QUALITY_PURPLE],
            get_concise_config_list2(PropIndexList, ConfigList2, []);
        OpenType =:= ?CONCISE_ITEM_OPEN ->
            ConfigList2 =
            [begin
                 #c_equip_concise_prop{item_weight = ItemWeight} = Config,
                 {ItemWeight, Config}
             end || {{LoadIndex, _Quality}, Config} <- ConfigList, LoadIndex =:= EquipIndex],
            get_concise_config_list2(PropIndexList, ConfigList2, []);
        OpenType =:= ?CONCISE_GOLD_OPEN ->
            {GoldConfigList, NormalList} =
            lists:foldl(
                fun({{LoadIndex, Quality}, Config}, {GoldAcc, NormalAcc}) ->
                    case EquipIndex =:= LoadIndex of
                        true ->
                            #c_equip_concise_prop{item_weight = ItemWeight, gold_weight = GoldWeight} = Config,
                            GoldAcc2 = ?IF(Quality >= ?QUALITY_PURPLE, [{GoldWeight, Config}|GoldAcc], GoldAcc),
                            NormalAcc2 = [{ItemWeight, Config}|NormalAcc],
                            {GoldAcc2, NormalAcc2};
                        _ ->
                            {GoldAcc, NormalAcc}
                    end
                end, {[], []}, ConfigList),
            [GoldIndex|R] = lib_tool:random_reorder_list(PropIndexList),
            List1 = get_concise_config_list2([GoldIndex], GoldConfigList, []),
            List2 = get_concise_config_list2(R, NormalList, []),
            List1 ++ List2
    end.

get_concise_config_list2([], _ConfigList, IndexConfigAcc) ->
    IndexConfigAcc;
get_concise_config_list2([Index|R], ConfigList, IndexConfigAcc) ->
    Config = lib_tool:get_weight_output(ConfigList),
    IndexConfigAcc2 = [{Index, Config}|IndexConfigAcc],
    get_concise_config_list2(R, ConfigList, IndexConfigAcc2).

get_concise_props([], ConciseList) ->
    ConciseList;
get_concise_props([{Index, ConciseConfig}|R], ConciseList) ->
    #c_equip_concise_prop{
        attack = Attack,
        attack_rate = AttackRate,
        arp = Arp,
        arp_rate = ArpRate,
        hit_rate = HitRate,
        hit_rate_r = HitRateR,
        double = Double,
        double_rate = DoubleRate,
        hp = Hp,
        hp_rate = HpRate,
        defence = Defence,
        defence_rate = DefenceRate,
        miss = Miss,
        miss_rate = MissRate,
        double_anti = DoubleAnti,
        double_anti_rate = DoubleAntiRate
    } = ConciseConfig,
    List = [Attack, AttackRate, Arp, ArpRate, HitRate, HitRateR, Double, DoubleRate,
            Hp, HpRate, Defence, DefenceRate, Miss, MissRate, DoubleAnti, DoubleAntiRate],
    PropList = get_concise_props2(List, ?EQUIP_CONCISE_PROPS, ConciseList, []),
    Concise = lib_tool:get_weight_output(PropList),
    Concise2 = Concise#p_equip_concise{index = Index},
    get_concise_props(R, [Concise2|ConciseList]).

%% 已经拥有的属性，要排除掉
get_concise_props2([], [], _ConciseList, PropsAcc) ->
    PropsAcc;
get_concise_props2([Value|R1], [Key|R2], ConciseList, PropsAcc) ->
    case lists:keymember(Key, #p_equip_concise.prop_key, ConciseList) of
        true ->
            get_concise_props2(R1, R2, ConciseList, PropsAcc);
        _ ->
            case Value of
                [MinValue, MaxValue] ->
                    Prop = #p_equip_concise{prop_key = Key, prop_value = lib_tool:random(MinValue, MaxValue)},
                    PropsAcc2 = [{?RATE_100, Prop}|PropsAcc],
                    get_concise_props2(R1, R2, ConciseList, PropsAcc2);
                _ ->
                    get_concise_props2(R1, R2, ConciseList, PropsAcc)
            end
    end.

get_equip_name(EquipID) ->
    [#c_equip{name = Name}] = lib_config:find(cfg_equip, EquipID),
    Name.

modify_role_equip_concise(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    EquipList2 = modify_role_equip_concise2(EquipList, []),
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    pre_enter(State2).

modify_role_equip_concise2([], Acc) ->
    Acc;
modify_role_equip_concise2([Equip|R], Acc) ->
    #p_equip{
        equip_id = TypeID,
        concise_list = ConciseList} = Equip,
    [#c_equip{
        index = Index,
        quality = Quality}] = lib_config:find(cfg_equip, TypeID),
    ConciseList2 = modify_role_equip_concise3(ConciseList, {Index, Quality}, []),
    Equip2 = Equip#p_equip{concise_list = ConciseList2},
    modify_role_equip_concise2(R, [Equip2|Acc]).

modify_role_equip_concise3([], _Key, Acc) ->
    Acc;
modify_role_equip_concise3([EquipConcise|R], Key, Acc) ->
    #p_equip_concise{
        prop_key = PropKey,
        prop_value = PropValue
    } = EquipConcise,
    [NewConfig] = lib_config:find(cfg_equip_concise_prop, Key),
    NewIndex = lib_tool:list_element_index(PropKey, ?EQUIP_CONCISE_PROPS),
    [MinValue, MaxValue] = erlang:element(#c_equip_concise_prop.prop_quality + NewIndex, NewConfig),
    EquipConcise2 =
    case MinValue =< PropValue andalso PropValue =< MaxValue of
        true ->
            EquipConcise;
        _ ->
            EquipConcise#p_equip_concise{prop_value = lib_tool:random(MinValue, MaxValue)}
    end,
    modify_role_equip_concise3(R, Key, [EquipConcise2|Acc]).



get_stone_level_by_type(Type, #r_role{role_equip = RoleEquip}) ->
    lists:foldl(
        fun(#p_equip{stone_list = StoneList}, AccNum) ->
            AccNum2 = lists:foldl(
                fun(#p_kv{val = StoneID}, Num) ->
                    case lib_config:find(cfg_stone, StoneID) of
                        [#c_stone{level = Level, type = Type}] ->
                            Num + Level;
                        _ ->
                            Num
                    end
                end, 0, StoneList),
            AccNum + AccNum2
        end, 0, RoleEquip#r_role_equip.equip_list).


cal_hp_at_level_stone_num(EquipList) ->
    lists:foldl(
        fun(#p_equip{stone_list = StoneList}, {HpNum, AtNum, LevelNumList}) ->
            {HpNum2, AtNum2, LevelNumList2} = lists:foldl(
                fun(#p_kv{val = StoneID}, {Num1, Num2, AccLevelNumList}) ->
                    case lib_config:find(cfg_stone, StoneID) of
                        [#c_stone{type = Type, level = Level}] ->
                            AccLevelNumList2 = case lists:keytake(Level, 1, AccLevelNumList) of
                                                   {value, {Level, LevelNum}, OtherAccLevelNumList} ->
                                                       [{Level, LevelNum + 1}|OtherAccLevelNumList];
                                                   _ ->
                                                       [{Level, 1}|AccLevelNumList]
                                               end,
                            case Type of
                                ?STONE_HP ->
                                    {Level + Num1, Num2, AccLevelNumList2};
                                ?STONE_AT ->
                                    {Num1, Level + Num2, AccLevelNumList2};
                                _ ->
                                    {Num1, Num2, AccLevelNumList2}
                            end;
                        _ ->
                            {Num1, Num2, AccLevelNumList}
                    end
                end, {0, 0, LevelNumList}, StoneList),
            {HpNum + HpNum2, AtNum + AtNum2, LevelNumList2}
        end, {0, 0, [{MLevel, 0} || MLevel <- lists:seq(1, 10)]}, EquipList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 首饰进阶
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_jewelry_step(RoleID, State, EquipID) ->
    case catch check_can_jewelry_step(EquipID, State) of
        {ok, BagDoings, Equip, StepID, State2} ->   %% BroadcastName1 进阶前的id， BroadcastName2 进阶后的id
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_equip_jewelry_step_toc{equip = Equip}),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_JEWELRY_STEP, EquipID),  %% 计算战力变化
            Good1 = #p_goods{type_id = EquipID},
            Good2 = #p_goods{type_id = StepID},
            GoodsList = [Good1, Good2],
            common_broadcast:send_world_common_notice(?NOTICE_JEWELRY_STEP, [mod_role_data:get_role_name(State3)], GoodsList),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_jewelry_step_toc{err_code = ErrCode}),
            State
    end.

check_can_jewelry_step(EquipID, State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,  %% 取出身上装备列表
    case lists:keyfind(EquipID, #p_equip.equip_id, EquipList) of %% 看看身上的装备列表里面有没有这个装备
        #p_equip{} = Equip ->  %% 有的话~~
            ok;
        _ ->  %%  没有就报错
            Equip = ?THROW_ERR(?ERROR_EQUIP_JEWELRY_STEP_001)  %%
    end,
    case lib_config:find(cfg_jewelry_step, EquipID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_EQUIP_JEWELRY_STEP_001)

    end,
    #c_jewelry_step{cost = Cost, step_id = StepID} = Config,
    NeedItems = lib_tool:string_to_intlist(Cost),
    BagDoings = mod_role_bag:check_num_by_item_list(NeedItems, ?ITEM_REDUCE_JEWELRY_STEP, State),
    NewEquip = Equip#p_equip{equip_id = StepID, excellent_list = get_new_excellent(StepID, [])},
    EquipList2 = lists:keyreplace(EquipID, #p_equip.equip_id, EquipList, NewEquip), %% 把装备列表中的替换
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, NewEquip, StepID, State2}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 铸魂属性
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_equip_forge_soul_open_tos(RoleID, EquipID, EquipLocationID, State) ->
    case catch check_can_forge_soul_open(EquipID, EquipLocationID, State) of
        {ok, EquipLocationID, State2} ->   %% BroadcastName1 进阶前的id， BroadcastName2 进阶后的id
            common_misc:unicast(RoleID, #m_equip_forge_soul_open_toc{equip_id = EquipID, forge_soul = EquipLocationID}),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_FORGE_SOUL_OPEN, EquipID),  %% 计算战力变化
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_forge_soul_open_toc{err_code = ErrCode}),
            State
    end.

check_can_forge_soul_open(EquipID, EquipLocationID, State) ->
    #r_role{role_equip = RoleEquip} = State,
    mod_role_function:is_function_open(?FUNCTION_FORGE_SOUL, State), %% 判断巅峰（化神）等级和首饰进阶功能是否开启
    #r_role_equip{equip_list = EquipList} = RoleEquip,  %% 取出身上装备列表
    case lists:keyfind(EquipID, #p_equip.equip_id, EquipList) of %%  判断--1--.看看身上的装备列表里面有没有这个装备
        #p_equip{} = Equip ->  %% 有的话~~
            ok;
        _ ->  %%  没有就报错
            Equip = ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_001)  %% 没有该装备
    end,
    case lib_config:find(cfg_equip, EquipID) of   %% 判断--2--看看这件装备有没有到9阶
        [#c_equip{step = Step}] ->
            ?IF(Step >= ?EQUIP_FORGE_SOUL_LEVEL, ok, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)); %%不能开启
        _ ->   %%  没有就报错
            ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)
    end,
    case lib_config:find(cfg_forge_soul, EquipLocationID) of  %% 判断--3--看看配置表里面有没有这个铸魂属性ID
        [#c_forge_soul{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)
    end,
    [#c_forge_soul{forge_soul_cultivate_level = NeedCultivateLevel, tower_floor = NeedTowerFloor}] = lib_config:find(cfg_forge_soul, EquipLocationID),
    #p_equip{forge_soul_cultivate = ForgeSoulCultivate} = Equip,
    ?IF(ForgeSoulCultivate >= NeedCultivateLevel, ok, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)), %% 判断--4-- 铸魂养成不够不能开启
    TowerFloorNow = mod_role_copy:is_forge_soul_open(NeedTowerFloor, State),
    ?IF(TowerFloorNow, ok, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)), %% 判断--5--看看有没有到爬塔的层数
    NewEquip = Equip#p_equip{forge_soul = EquipLocationID},
    NewEquipList = lists:keyreplace(EquipID, #p_equip.equip_id, EquipList, NewEquip),%% 用激活的新装备替换旧装备
    NewRoleEquip = RoleEquip#r_role_equip{equip_list = NewEquipList},
    State2 = State#r_role{role_equip = NewRoleEquip},
    {ok, EquipLocationID, State2}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 铸魂养成
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_equip_forge_soul_cultivate(RoleID, EquipID, State) ->
    case catch check_can_forge_soul_cultivate(EquipID, State) of
        {ok, AssetDoing, ForgeSoulCultivateLevel, State2} ->   %% BroadcastName1 进阶前的id， BroadcastName2 进阶后的id
            common_misc:unicast(RoleID, #m_equip_forge_soul_cultivate_toc{equip_id = EquipID, forge_soul_cultivate = ForgeSoulCultivateLevel}),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_FORGE_SOUL_CULTIVATE, EquipID),  %% 计算战力变化
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_forge_soul_cultivate_toc{err_code = ErrCode}),
            State
    end.

check_can_forge_soul_cultivate(EquipID, State) ->
    #r_role{role_equip = RoleEquip} = State,
    mod_role_function:is_function_open(?FUNCTION_FORGE_SOUL_CULTIVATE, State), %% 判断--1--巅峰（化神）等级和首饰进阶功能是否开启
    #r_role_equip{equip_list = EquipList} = RoleEquip,  %% 取出身上装备列表
    case lists:keyfind(EquipID, #p_equip.equip_id, EquipList) of %%  判断--2--看看身上的装备列表里面有没有这个装备
        #p_equip{} = Equip ->  %% 有的话~~
            ok;
        _ ->  %%  没有就报错
            Equip = ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_CULTIVATE_001)  %%
    end,
    case lib_config:find(cfg_equip, EquipID) of   %% 判断--3--看看这件装备有没有到9阶
        [#c_equip{step = Step}] ->
            ?IF(Step >= ?EQUIP_FORGE_SOUL_LEVEL, ok, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)); %%不能开启
        _ ->   %%  没有就报错
            ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)
    end,
    %% 通过传过来的装备id找到 部位id 和 等级
    [#c_equip{index = Index}] = lib_config:find(cfg_equip, EquipID), %% 需要找到装备部位（Index)
    #p_equip{forge_soul_cultivate = ForgeSoulCultivate} = Equip,    %% 需要找到装备的镇魂养成值 (ForgeSoulCultivate)
    ?IF(ForgeSoulCultivate + 1 > 100, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002), ok),  %% 判断--4-- 是不是大于100级了 相当于10阶10星
    [#c_forge_soul_cultivate{level = Level, consume = NeedConsume, tower_floor = NeedTowerFloor}] = lib_config:find(cfg_forge_soul_cultivate, {Index, ForgeSoulCultivate + 1}), %% 根据 部位id 和等级值 读表
    TowerFloorNow = mod_role_copy:is_forge_soul_open(NeedTowerFloor, State),
    ?IF(TowerFloorNow, ok, ?THROW_ERR(?ERROR_EQUIP_FORGE_SOUL_OPEN_002)), %% 判断--5--看看有没够爬塔的层数
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_FORGE_SOUL, NeedConsume, ?ASSET_FORGE_SOUL_REDUCE_FROM_FORGE_SOUL_CULTIVATE, State),
    NewEquip = Equip#p_equip{forge_soul_cultivate = Level},
    NewEquipList = lists:keyreplace(EquipID, #p_equip.equip_id, EquipList, NewEquip),%% 用激活的新装备替换旧装备
    NewRoleEquip = RoleEquip#r_role_equip{equip_list = NewEquipList},
    State2 = State#r_role{role_equip = NewRoleEquip},
    {ok, AssetDoing, Level, State2}.


%% 纹印系统
%% 身上的纹印升级
do_equip_seal_compose(RoleID, EquipID, SealIndex, MaterialList, State) ->
    case catch check_equip_seal_compose(EquipID, SealIndex, MaterialList, State) of
        {ok, BagDoings, Log, Equip2, State2} ->
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_equip_seal_compose_toc{equip = Equip2}),
            State3 = mod_role_bag:do(BagDoings, State2),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_SEAL_UP, SealIndex);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_equip_seal_compose_toc{err_code = ErrCode}),
            State
    end.

check_equip_seal_compose(EquipID, SealIndex, MaterialList, State) ->
    mod_role_function:is_function_open(?FUNCTION_SEAL, State),
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipListT} ->
            #p_equip{seal_list = SealList} = Equip,
            case lists:keytake(SealIndex, #p_kv.id, SealList) of
                {value, #p_kv{val = SealID} = KV, SealListT} ->
                    [#c_seal{compose_type_id = NewSealID, compose_num = Num}] = lib_config:find(cfg_seal, SealID),
                    ?IF(NewSealID > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                    check_equip_seal_compose2(lists:keysort(#p_kv.id, MaterialList), SealID, Num - 1),
                    {ItemList, LogGoods} =
                    lists:foldl(
                        fun(#p_kv{id = MaterialID, val = MaterialNum}, {Acc1, Acc2}) ->
                            {[{MaterialID, MaterialNum}|Acc1], [#p_goods{type_id = MaterialID, num = MaterialNum}|Acc2]}
                        end, {[], []}, MaterialList),
                    BagDoings = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_SEAL_COMPOSE, State),
                    Log = mod_role_extra:get_compose_log(SealID, LogGoods, State),
                    SealList2 = [KV#p_kv{val = NewSealID}|SealListT],
                    Equip2 = Equip#p_equip{seal_list = SealList2},
                    EquipList2 = [Equip2|EquipListT],
                    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
                    State2 = State#r_role{role_equip = RoleEquip2},
                    {ok, BagDoings, Log, Equip2, State2};
                _ ->
                    ?THROW_ERR(?ERROR_EQUIP_SEAL_COMPOSE_002)
            end;
        _ ->
            ?THROW_ERR(?ERROR_EQUIP_SEAL_COMPOSE_001)
    end.

check_equip_seal_compose2([], _NeedSealID, _NeedNum) ->
    ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM);
check_equip_seal_compose2([#p_kv{id = SealID, val = Num}|R], NeedSealID, NeedNum) ->
    [#c_seal{compose_type_id = ComposeSealID, compose_num = ComposeNum}] = lib_config:find(cfg_seal, SealID),
    case SealID =:= NeedSealID of
        true ->
            ?IF(Num =:= NeedNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM));
        _ ->
            ?IF(Num >= ComposeNum andalso Num rem ComposeNum =:= 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
            Num2 = Num div ComposeNum,
            R2 =
            case lists:keytake(ComposeSealID, #p_kv.id, R) of
                {value, #p_kv{val = OldVal} = KV, RT} ->
                    [KV#p_kv{val = OldVal + Num2}|RT];
                _ ->
                    [#p_kv{id = ComposeSealID, val = Num2}|R]
            end,
            check_equip_seal_compose2(R2, NeedSealID, NeedNum)
    end.

%% 纹印镶嵌
do_seal_punch(RoleID, State, EquipID, SealID, PunchIndex) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case catch check_can_punch(EquipID, SealID, PunchIndex, EquipList, State) of
        {ok, Equip2, EquipList2, BagDoings, Log} ->
            common_misc:unicast(RoleID, #m_seal_punch_toc{equip = Equip2}),
            mod_role_dict:add_background_logs(Log),
            State2 = mod_role_bag:do(BagDoings, State),
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State3 = State2#r_role{role_equip = RoleEquip2},
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_SEAL, SealID),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_seal_punch_toc{err_code = ErrCode}),
            State
    end.

check_can_punch(EquipID, SealID, PunchIndex, EquipList, State) ->
    mod_role_function:is_function_open(?FUNCTION_SEAL, State),
    Num = mod_role_bag:get_num_by_type_id(SealID, State),
    ?IF(Num >= 1, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM)),
    BagDoings = [{decrease, ?ITEM_REDUCE_EQUIP_PUNCH, [#r_goods_decrease_info{type = first_bind, type_id = SealID, num = 1}]}],
    [#c_seal{equip_index_list = EquipIndexList}] = lib_config:find(cfg_seal, SealID),
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, RemainList} -> ok;
        _ -> Equip = RemainList = ?THROW_ERR(?ERROR_SEAL_PUNCH_001)
    end,
    #p_equip{seal_list = SealList} = Equip,
    [#c_equip{index = EquipIndex, seal_num = SealNum}] = lib_config:find(cfg_equip, EquipID),
    ?IF(lists:member(EquipIndex, EquipIndexList), ok, ?THROW_ERR(?ERROR_SEAL_PUNCH_002)),
    case PunchIndex =:= ?VIP_SEAL_INDEX of
        true ->
            ?IF(mod_role_vip:get_vip_seal_num(State) > 0, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL));
        _ ->
            ?IF(SealNum >= PunchIndex andalso PunchIndex > 0, ok, ?THROW_ERR(?ERROR_SEAL_PUNCH_003))
    end,
    case lists:keytake(PunchIndex, #p_kv.id, SealList) of
        {value, #p_kv{val = OldSeal}, SealList2} ->
            ReplaceSealID = OldSeal,
            mod_role_bag:check_bag_empty_grid(1, State),
            BagDoings2 = BagDoings ++ [{create, ?ITEM_GAIN_EQUIP_SEAL_PUNCH, [#p_goods{type_id = OldSeal, num = 1, bind = true}]}],
            SealList3 = [#p_kv{id = PunchIndex, val = SealID}|SealList2];
        _ ->
            BagDoings2 = BagDoings,
            ReplaceSealID = 0,
            SealList3 = [#p_kv{id = PunchIndex, val = SealID}|SealList]
    end,
    Equip2 = Equip#p_equip{seal_list = SealList3},
    EquipList2 = [Equip2|RemainList],
    Log = get_seal_log(EquipID, EquipIndex, ?LOG_TYPE_PUNCH, PunchIndex, SealID, ReplaceSealID, State),
    {ok, Equip2, EquipList2, BagDoings2, Log}.


%% 纹印移除
do_seal_remove(RoleID, State, EquipID, SealIndex) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    case catch check_can_remove(EquipID, SealIndex, EquipList, State) of
        {ok, Equip2, EquipList2, BagDoings, Log} ->
            common_misc:unicast(RoleID, #m_seal_remove_toc{equip = Equip2}),
            mod_role_dict:add_background_logs(Log),
            State2 = mod_role_bag:do(BagDoings, State),
            RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
            State3 = State2#r_role{role_equip = RoleEquip2},
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_REMOVE_SEAL, SealIndex);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_seal_remove_toc{err_code = ErrCode}),
            State
    end.

check_can_remove(EquipID, SealIndex, EquipList, State) ->
    case lists:keytake(EquipID, #p_equip.equip_id, EquipList) of
        {value, Equip, EquipList2} -> ok;
        _ -> Equip = EquipList2 = ?THROW_ERR(?ERROR_SEAL_PUNCH_001)
    end,
    #p_equip{seal_list = SealList} = Equip,
    case lists:keytake(SealIndex, #p_kv.id, SealList) of
        {value, Seal, SealList2} ->
            ok;
        _ ->
            Seal = SealList2 = ?THROW_ERR(?ERROR_SEAL_REMOVE_003)
    end,
    mod_role_bag:check_bag_empty_grid(1, State),
    [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
    #p_kv{val = SealID} = Seal,
    BagDoings = [{create, ?ITEM_GAIN_EQUIP_SEAL_REMOVE, [#p_goods{bind = true, type_id = SealID, num = 1}]}],

    Equip2 = Equip#p_equip{seal_list = SealList2},
    EquipList3 = [Equip2|EquipList2],
    Log = get_seal_log(EquipID, EquipIndex, ?LOG_TYPE_REMOVE, SealIndex, SealID, 0, State),
    {ok, Equip2, EquipList3, BagDoings, Log}.

%% 纹印合成
do_seal_compose(RoleID, SealID, State) ->
    case catch check_seal_compose(SealID, State) of
        {ok, BagDoings, Log} ->
            State2 = mod_role_bag:do(BagDoings, State),
            common_misc:unicast(RoleID, #m_seal_compose_toc{}),
            State3 = mod_role_mission:compose_trigger(SealID, State2),
            mod_role_dict:add_background_logs(Log),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_seal_compose_toc{err_code = ErrCode}),
            State
    end.

check_seal_compose(TypeID, State) ->
    mod_role_function:is_function_open(?FUNCTION_SEAL, State),
    case lib_config:find(cfg_seal, TypeID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_EQUIP_COMPOSE_001)
    end,
    mod_role_bag:check_bag_empty_grid(1, State),
    case Config of
        #c_seal{compose_type_id = SealID, compose_num = Num} when SealID > 0 ->
            ok;
        _ ->
            SealID = Num = ?THROW_ERR(?ERROR_EQUIP_COMPOSE_002)
    end,
    DecreaseList = mod_role_bag:get_decrease_goods_by_num(TypeID, Num, State),
    Bind = lists:keymember(true, #r_goods_decrease_info.id_bind_type, DecreaseList),
    BagDoings2 = [{decrease, ?ITEM_REDUCE_SEAL_COMPOSE, DecreaseList}] ++
                 [{create, ?ITEM_GAIN_SEAL_COMPOSE, [#p_goods{type_id = SealID, num = 1, bind = Bind}]}],
    Log = mod_role_extra:get_compose_log(SealID, [#p_goods{type_id = TypeID, num = Num}], State),
    {ok, BagDoings2, Log}.

%% 一键
do_seal_one_key_up(RoleID, IDList, State) ->
    case catch check_seal_one_key_up(IDList, State) of
        {ok, BagDoings, UpdateEquips, Logs, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            mod_role_dict:add_background_logs(Logs),
            common_misc:unicast(RoleID, #m_seal_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_UP, equip_list = UpdateEquips}),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_SEAL_ONE_KEY_UP, 0);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_seal_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_UP, err_code = ErrCode}),
            State
    end.

check_seal_one_key_up(IDList, State) ->
    mod_role_function:is_function_open(?FUNCTION_SEAL, State),
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(IDList, State),
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    HasVipSeal = mod_role_vip:get_vip_seal_num(State) > 0,
    {EquipList2, BagDoings, UpdateEquips, Logs} = check_seal_one_key_up2(GoodsList, EquipList, HasVipSeal, State),
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, UpdateEquips, Logs, State2}.

check_seal_one_key_up2(GoodsList, EquipList, HasVipSeal, State) ->
    SealList =
    lists:foldl(
        fun(#p_goods{type_id = TypeID, num = Num}, Acc) ->
            case lists:keyfind(TypeID, #p_kvs.id, Acc) of
                #p_kvs{val = OldNum} = KVS ->
                    lists:keyreplace(TypeID, #p_kvs.id, Acc, KVS#p_kvs{val = OldNum + Num});
                _ ->
                    [#c_seal{equip_index_list = IndexList}] = lib_config:find(cfg_seal, TypeID),
                    [#p_kvs{id = TypeID, val = Num, text = IndexList}|Acc]
            end
        end, [], GoodsList),
    SortEquipListT =
    [begin
         [#c_equip{index = Index, seal_num = SealNum}] = lib_config:find(cfg_equip, Equip#p_equip.equip_id),
         {Index, SealNum, Equip}
     end || Equip <- EquipList],
    SortEquipList = lists:keysort(1, SortEquipListT),
    {SealList2, EquipList2, UpdateEquips, Logs} = check_seal_one_key_up3(SealList, SortEquipList, HasVipSeal, State, [], [], []),
    DecreaseList = get_seal_up_decrease(SealList, SealList2, []),
    ?IF(DecreaseList =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    BagDoings = [{decrease, ?ITEM_REDUCE_EQUIP_PUNCH, DecreaseList}],
    {EquipList2, BagDoings, UpdateEquips, Logs}.


check_seal_one_key_up3([], SortEquipList, _HasVipSeal, _State, EquipAcc, UpdateAcc, LogsAcc) ->
    EquipList = [Equip || {_Index, _SealNum, Equip} <- SortEquipList],
    {[], EquipList ++ EquipAcc, UpdateAcc, LogsAcc};
check_seal_one_key_up3(SealList, [], _HasVipSeal, _State, EquipAcc, UpdateAcc, LogsAcc) ->
    {SealList, EquipAcc, UpdateAcc, LogsAcc};
check_seal_one_key_up3(SealList, [{EquipIndex, SealNum, Equip}|R], HasVipSeal, State, EquipAcc, UpdateAcc, LogsAcc) ->
    CheckList = ?IF(SealNum > 0, [CheckSealIndex || CheckSealIndex <- lists:seq(1, SealNum)], []),
    CheckList2 = ?IF(HasVipSeal, [?VIP_SEAL_INDEX|CheckList], CheckList),
    case CheckList2 =/= [] of
        true ->
            %% 先按大小进行排序
            SealList2 = lists:reverse(lists:keysort(#p_kvs.id, SealList)),
            {Equip2, SealList3, Logs} = check_seal_one_key_up4(SealList2, EquipIndex, CheckList2, Equip, State),
            UpdateAcc2 = ?IF(Logs =/= [], [Equip2|UpdateAcc], UpdateAcc),
            check_seal_one_key_up3(SealList3, R, HasVipSeal, State, [Equip2|EquipAcc], UpdateAcc2, Logs ++ LogsAcc);
        _ ->
            check_seal_one_key_up3(SealList, R, HasVipSeal, State, [Equip|EquipAcc], UpdateAcc, LogsAcc)
    end.

%% 对一件装备进行替换
check_seal_one_key_up4(SealList, EquipIndex, CheckList2, Equip, State) ->
    #p_equip{equip_id = EquipID, seal_list = EquipSealList} = Equip,
    EmptyList = get_seal_empty_list(CheckList2, EquipSealList),
    case EmptyList =/= [] of
        true ->
            {SealAddList, SealList2, Logs} = replace_seals(EmptyList, EquipID, EquipIndex, SealList, State, [], [], []),
            case SealAddList =/= [] of
                true ->
                    EquipSealList2 = SealAddList ++ EquipSealList,
                    Equip2 = Equip#p_equip{seal_list = EquipSealList2},
                    {Equip2, SealList2, Logs};
                _ ->
                    {Equip, SealList, []}
            end;
        _ ->
            {Equip, SealList, []}
    end.

get_seal_empty_list([], _EquipSealList) ->
    [];
get_seal_empty_list(CheckList, []) ->
    CheckList;
get_seal_empty_list(CheckList, [#p_kv{id = Index}|R]) ->
    CheckList2 = lists:delete(Index, CheckList),
    get_seal_empty_list(CheckList2, R).

replace_seals([], _EquipID, _EquipIndex, SealList, _State, SealAddAcc, SealAcc, LogsAcc) ->
    {SealAddAcc, SealList ++ SealAcc, LogsAcc};
replace_seals(_EmptyList, _EquipID, _EquipIndex, [], _State, SealAddAcc, SealAcc, LogsAcc) ->
    {SealAddAcc, SealAcc, LogsAcc};
replace_seals(EmptyList, EquipID, EquipIndex, [#p_kvs{id = TypeID, val = Num, text = IndexList} = KVS|R], State, SealAddAcc, SealAcc, LogsAcc) ->
    case lists:member(EquipIndex, IndexList) of
        true ->
            CheckNum = erlang:length(EmptyList),
            case Num >= CheckNum of
                true -> %% 填满~~
                    AddList = EmptyList,
                    EmptyList2 = [],
                    Num2 = Num - CheckNum;
                _ ->
                    {AddList, EmptyList2} = lib_tool:split(Num, EmptyList),
                    Num2 = 0
            end,
            SealList2 = ?IF(Num2 > 0, [KVS#p_kvs{val = Num2}|R], R),
            SealAdd = [#p_kv{id = SealIndex, val = TypeID} || SealIndex <- AddList],
            Logs = [get_seal_log(EquipID, EquipIndex, ?LOG_TYPE_PUNCH, SealIndex, TypeID, 0, State) || SealIndex <- AddList],
            replace_seals(EmptyList2, EquipID, EquipIndex, SealList2, State, SealAdd ++ SealAddAcc, SealAcc, Logs ++ LogsAcc);
        _ ->
            replace_seals(EmptyList, EquipID, EquipIndex, R, State, SealAddAcc, [KVS|SealAcc], LogsAcc)
    end.

get_seal_up_decrease(SealList, [], Acc) ->
    DecreaseList = [#r_goods_decrease_info{type_id = TypeID, num = Num} || #p_kvs{id = TypeID, val = Num} <- SealList],
    DecreaseList ++ Acc;
get_seal_up_decrease([#p_kvs{id = TypeID, val = Num}|R], SealList2, Acc) ->
    case lists:keytake(TypeID, #p_kvs.id, SealList2) of
        {value, #p_kvs{val = RemainNum}, SealList3} ->
            Acc2 = ?IF(Num > RemainNum, [#r_goods_decrease_info{type_id = TypeID, num = Num - RemainNum}|Acc], Acc);
        _ ->
            SealList3 = SealList2,
            Acc2 = [#r_goods_decrease_info{type_id = TypeID, num = Num}|Acc]
    end,
    get_seal_up_decrease(R, SealList3, Acc2).

do_seal_one_key_remove(RoleID, State) ->
    case catch check_seal_one_key_remove(State) of
        {ok, BagDoings, UpdateEquips, Logs, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_seal_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_REMOVE, equip_list = UpdateEquips}),
            mod_role_dict:add_background_logs(Logs),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_EQUIP_ONE_KEY_DOWN, 0);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_seal_one_key_toc{type = ?EQUIP_STONE_ONE_KEY_REMOVE, err_code = ErrCode}),
            State
    end.

check_seal_one_key_remove(State) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    {EquipList2, UpdateEquips, TypeIDList, Logs} = check_seal_one_key_remove2(EquipList, State, [], [], [], []),
    CreateList = [#p_goods{type_id = TypeID, num = 1, bind = true} || TypeID <- TypeIDList],
    CreateList2 = mod_role_bag:get_create_list(CreateList),
    mod_role_bag:check_bag_empty_grid(CreateList2, State),
    BagDoings = [{create, ?ITEM_GAIN_EQUIP_SEAL_REMOVE, CreateList2}],
    RoleEquip2 = RoleEquip#r_role_equip{equip_list = EquipList2},
    State2 = State#r_role{role_equip = RoleEquip2},
    {ok, BagDoings, UpdateEquips, Logs, State2}.

check_seal_one_key_remove2([], _State, EquipAcc, UpdateAcc, SealAcc, LogAcc) ->
    {EquipAcc, UpdateAcc, SealAcc, LogAcc};
check_seal_one_key_remove2([#p_equip{equip_id = EquipID, seal_list = SealList} = Equip|R], State, EquipAcc, UpdateAcc, SealAcc, LogAcc) ->
    case SealList =/= [] of
        true ->
            [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
            {Seals, Logs} =
            lists:foldl(
                fun(#p_kv{id = SealIndex, val = SealID}, {Acc1, Acc2}) ->
                    NewAcc1 = [SealID|Acc1],
                    NewAcc2 = [get_seal_log(EquipID, EquipIndex, ?LOG_TYPE_REMOVE, SealIndex, SealID, 0, State)|Acc2],
                    {NewAcc1, NewAcc2}
                end, {[], []}, SealList),
            Equip2 = Equip#p_equip{seal_list = []},
            check_seal_one_key_remove2(R, State, [Equip2|EquipAcc], [Equip2|UpdateAcc], Seals ++ SealAcc, Logs ++ LogAcc);
        _ ->
            check_seal_one_key_remove2(R, State, [Equip|EquipAcc], UpdateAcc, SealAcc, LogAcc)
    end.

get_first_honing_id(StoneType) ->
    ConfigList = lib_config:list(cfg_stone_honing),
    get_first_honing_id2(ConfigList, StoneType).

get_first_honing_id2([{HoningID, Config}|R], StoneType) ->
    #c_stone_honing{stone_type = ConfigStoneType} = Config,
    ?IF(StoneType =:= ConfigStoneType, HoningID, get_first_honing_id2(R, StoneType)).