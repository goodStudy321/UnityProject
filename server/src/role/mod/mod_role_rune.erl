%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     符文系统
%%% @end
%%% Created : 20. 十一月 2017 21:18
%%%-------------------------------------------------------------------
-module(mod_role_rune).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_rune.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    handle/2
]).

-export([
    add_rune/2,
    add_exp/2,
    add_piece/2,
    add_essence/2
]).

-export([
    is_bag_full/1,
    get_all_level/1,
    get_the_quality_num/2
]).

-export([
    gm_clear_bag/1
]).

init(#r_role{role_id = RoleID, role_rune = undefined} = State) ->
    RoleRune = #r_role_rune{role_id = RoleID},
    State#r_role{role_rune = RoleRune};
init(State) ->
    State.

calc(State) ->
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{load_runes = LoadRunes} = RoleRune,
    {PropList, OtherList} = get_props_and_seconds(LoadRunes, [], []),
    CalcAttr1 = common_misc:get_attr_by_kv(lists:flatten(PropList)),
    CalcAttr2 = get_attr_by_second(OtherList, State),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_RUNE, common_misc:sum_calc_attr2(CalcAttr1, CalcAttr2)).

get_attr_by_second(OtherList, State) ->
    {ArmorAttr, WeaponAttr, GodAttr} = mod_role_equip:get_rune_equip_attr(State),
    LevelAttr = mod_role_level:get_level_attr(State),
    get_attr_by_second2(OtherList, ArmorAttr, WeaponAttr, GodAttr, LevelAttr, #actor_cal_attr{}).

get_attr_by_second2([], _ArmorAttr, _WeaponAttr, _GodAttr, _LevelAttr, Attr) ->
    Attr;
get_attr_by_second2([#p_kv{id = Key, val = Val}|R], ArmorAttr, WeaponAttr, GodAttr, LevelAttr, Attr) ->
    #actor_cal_attr{
        max_hp = {MaxHp, MaxHpRate},
        defence = {Defence, DefenceRate},
        attack = {Attack, AttackRate},
        arp = {Arp, ArpRate}
    } = Attr,
    #actor_cal_attr{
        max_hp = {ArmorMaxHp, _},
        defence = {ArmorDefence, _}
    } = ArmorAttr,
    #actor_cal_attr{
        attack = {WeaponAttack, _},
        arp = {WeaponArp, _}
    } = WeaponAttr,
    #actor_cal_attr{
        attack = {GodAttack, _}
    } = GodAttr,
    #actor_cal_attr{
        max_hp = {LevelHp, _},
        attack = {LevelAttack, _},
        defence = {LevelDefence, _},
        arp = {LevelArp, _}
    } = LevelAttr,
    if
        Key =:= ?ATTR_EQUIP_ARMOR_HP_RATE ->
            Attr2 = Attr#actor_cal_attr{max_hp = {ArmorMaxHp * Val / ?RATE_10000 + MaxHp, MaxHpRate}};
        Key =:= ?ATTR_EQUIP_ARMOR_DEF_RATE ->
            Attr2 = Attr#actor_cal_attr{defence = {ArmorDefence * Val / ?RATE_10000 + Defence, DefenceRate}};
        Key =:= ?ATTR_EQUIP_WEAPON_ARP_RATE ->
            Attr2 = Attr#actor_cal_attr{arp = {WeaponArp * Val / ?RATE_10000 + Arp, ArpRate}};
        Key =:= ?ATTR_EQUIP_WEAPON_ATTACK_RATE ->
            Attr2 = Attr#actor_cal_attr{attack = {WeaponAttack * Val / ?RATE_10000 + Attack, AttackRate}};
        Key =:= ?ATTR_EQUIP_GOD_ATTACK_RATE ->
            Attr2 = Attr#actor_cal_attr{attack = {GodAttack * Val / ?RATE_10000 + Attack, AttackRate}};
        Key =:= ?ATTR_BASE_ARP_RATE ->
            Attr2 = Attr#actor_cal_attr{arp = {LevelArp * Val / ?RATE_10000 + Arp, ArpRate}};
        Key =:= ?ATTR_BASE_HP_RATE ->
            Attr2 = Attr#actor_cal_attr{max_hp = {LevelHp * Val / ?RATE_10000 + MaxHp, MaxHpRate}};
        Key =:= ?ATTR_BASE_DEF_RATE ->
            Attr2 = Attr#actor_cal_attr{defence = {LevelDefence * Val / ?RATE_10000 + Defence, DefenceRate}};
        Key =:= ?ATTR_BASE_ATTACK_RATE ->
            Attr2 = Attr#actor_cal_attr{attack = {LevelAttack * Val / ?RATE_10000 + Attack, AttackRate}};
        true ->
            Attr2 = Attr
    end,
    get_attr_by_second2(R, ArmorAttr, WeaponAttr, GodAttr, LevelAttr, Attr2).


get_props_and_seconds([], PropList, OtherList) ->
    {PropList, OtherList};
get_props_and_seconds([Rune|R], PropList, OtherList) ->
    #p_rune{level_id = LevelID} = Rune,
    [#c_rune{
        prop_id1 = PropID1,
        prop_value1 = PropValue1,
        prop_id2 = PropID2,
        prop_value2 = PropValue2
    }] = lib_config:find(cfg_rune, LevelID),
    Prop1 = #p_kv{id = PropID1, val = PropValue1},
    Prop2 = #p_kv{id = PropID2, val = PropValue2},
    {PropList2, OtherList2} = ?IF(?IS_RUNE_SECOND_PROP(PropID1), {PropList, [Prop1|OtherList]}, {[Prop1|PropList], OtherList}),
    {PropList3, OtherList3} = ?IF(?IS_RUNE_SECOND_PROP(PropID2), {PropList2, [Prop2|OtherList2]}, {[Prop2|PropList2], OtherList2}),
    get_props_and_seconds(R, PropList3, OtherList3).

online(State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{exp = Exp, piece = Piece, essence = Essence, load_runes = LoadRunes, bag_runes = BagRunes} = RoleRune,
    common_misc:unicast(RoleID, #m_rune_info_toc{exp = Exp, piece = Piece, essence = Essence, load_runes = LoadRunes, bag_runes = BagRunes}),
    State.

handle({#m_rune_level_up_tos{rune_id = RuneID}, RoleID, _PID}, State) ->
    do_level_up(RoleID, RuneID, State);
handle({#m_rune_decompose_tos{rune_ids = RuneIDs}, RoleID, _PID}, State) ->
    do_decompose(RoleID, RuneIDs, State);
handle({#m_rune_exchange_tos{level_id = LevelID}, RoleID, _PID}, State) ->
    do_exchange(RoleID, LevelID, State);
handle({#m_rune_compose_tos{type_id = TypeID}, RoleID, _PID}, State) ->
    do_compose(RoleID, TypeID, State);
handle({#m_rune_load_tos{rune_id = RuneID, index = Index}, RoleID, _PID}, State) ->
    do_load(RoleID, RuneID, Index, State);
handle(bag_runes_enough, State) ->
    do_one_key_decompose(State);
handle(Info, State) ->
    ?ERROR_MSG("unkonw Info : ~w", [Info]),
    State.

%% 添加符文

add_rune(RuneLevelID, State) when erlang:is_integer(RuneLevelID) ->
    add_rune([RuneLevelID], State);
add_rune([], State) ->
    State;
add_rune(RuneList, State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{rune_id = RuneIDCounter, bag_runes = BagRunes} = RoleRune,
    {RuneIDCounter2, AddRunes} = add_rune2(RuneList, RuneIDCounter, []),
    RoleRune2 = RoleRune#r_role_rune{rune_id = RuneIDCounter2, bag_runes = AddRunes ++ BagRunes},
    State2 = State#r_role{role_rune = RoleRune2},
    common_misc:unicast(RoleID, #m_rune_bag_update_toc{update_runes = AddRunes}),
    check_bag_runes(State2),
    State2.

add_rune2([], RuneIDCounter, RunesAcc) ->
    {RuneIDCounter, RunesAcc};
add_rune2([RuneLevelID|R], RuneIDCounter, RunesAcc) ->
    [#c_rune{}] = lib_config:find(cfg_rune, RuneLevelID),
    Rune = #p_rune{rune_id = RuneIDCounter, level_id = RuneLevelID},
    add_rune2(R, RuneIDCounter + 1, [Rune|RunesAcc]).

add_exp(AddExp, State) when AddExp > 0 ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{exp = Exp} = RoleRune,
    NewExp = Exp + AddExp,
    RoleRune2 = RoleRune#r_role_rune{exp = NewExp},
    State2 = State#r_role{role_rune = RoleRune2},
    common_misc:unicast(RoleID, #m_rune_exp_update_toc{exp = NewExp}),
    State2;
add_exp(_AddExp, State) ->
    State.

%% 增加碎片
add_piece(AddPiece, State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{piece = Piece} = RoleRune,
    NewPiece = Piece + AddPiece,
    RoleRune2 = RoleRune#r_role_rune{piece = NewPiece},
    State2 = State#r_role{role_rune = RoleRune2},
    common_misc:unicast(RoleID, #m_rune_piece_update_toc{piece = NewPiece}),
    State2.

%% 增加符文精粹
add_essence(AddEssence, State) when AddEssence > 0 ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{essence = Essence} = RoleRune,
    NewEssence = Essence + AddEssence,
    RoleRune2 = RoleRune#r_role_rune{essence = NewEssence},
    State2 = State#r_role{role_rune = RoleRune2},
    common_misc:unicast(RoleID, #m_rune_essence_update_toc{essence = NewEssence}),
    State2;
add_essence(_AddEssence, State) ->
    State.

is_bag_full(State) ->
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{bag_runes = BagRunes} = RoleRune,
    ?IF(erlang:length(BagRunes) >= ?BAG_FULL_RUNE_NUM, ?THROW_ERR(?ERROR_COMMON_RUNE_BAG_FULL), ok).

gm_clear_bag(State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{bag_runes = BagRunes} = RoleRune,
    RoleRune2 = RoleRune#r_role_rune{bag_runes = []},
    RuneIDs = [RuneID || #p_rune{rune_id = RuneID} <- BagRunes],
    common_misc:unicast(RoleID, #m_rune_bag_update_toc{del_runes = RuneIDs}),
    State2 = State#r_role{role_rune = RoleRune2},
    State2.

%% 符文升级
do_level_up(RoleID, RuneID, State) ->
    case catch check_level_up(RuneID, State) of
        {ok, Rune, NewExp, Log, AllLevel, State2} ->
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_RUNE_LEVEL_UP, RuneID),
            State4 = mod_role_confine:all_rune_level(AllLevel, State3),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_rune_level_up_toc{rune = Rune}),
            common_misc:unicast(RoleID, #m_rune_exp_update_toc{exp = NewExp}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_level_up_toc{err_code = ErrCode}),
            State
    end.

check_level_up(RuneID, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_rune = RoleRune} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_rune{load_runes = LoadRunes, exp = Exp} = RoleRune,
    case lists:keyfind(RuneID, #p_rune.rune_id, LoadRunes) of
        #p_rune{} = Rune ->
            ok;
        _ ->
            Rune = ?THROW_ERR(?ERROR_RUNE_LEVEL_UP_001)
    end,
    #p_rune{level_id = LevelID} = Rune,
    NewLevelID = get_new_level_id(LevelID, 1),
    case lib_config:find(cfg_rune, NewLevelID) of
        [#c_rune{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_RUNE_LEVEL_UP_002)
    end,
    [#c_rune{level_exp = LevelExp}] = lib_config:find(cfg_rune, LevelID),
    ?IF(Exp >= LevelExp, ok, ?THROW_ERR(?ERROR_RUNE_LEVEL_UP_003)),
    Exp2 = Exp - LevelExp,
    Rune2 = Rune#p_rune{level_id = NewLevelID},
    LoadRunes2 = lists:keystore(RuneID, #p_rune.rune_id, LoadRunes, Rune2),
    AllLevel = get_all_level(LoadRunes2),
    RoleRune2 = RoleRune#r_role_rune{exp = Exp2, load_runes = LoadRunes2},
    State2 = State#r_role{role_rune = RoleRune2},
    Log = #log_role_rune{
        role_id = RoleID,
        use_exp = LevelExp,
        old_level_id = LevelID,
        new_level_id = NewLevelID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID},
    {ok, Rune2, Exp2, Log, AllLevel, State2}.

get_all_level(LoadRunes) ->
    lists:foldl(
        fun(#p_rune{level_id = Level}, Acc) ->
            Acc + ?RUNE_LEVEL(Level)
        end, 0, LoadRunes).

%% 符文分解
do_decompose(RoleID, RuneIDs, State) ->
    case catch check_can_decompose(RuneIDs, State) of
        {ok, NewExp, State2} ->
            common_misc:unicast(RoleID, #m_rune_exp_update_toc{exp = NewExp}),
            common_misc:unicast(RoleID, #m_rune_bag_update_toc{del_runes = RuneIDs}),
            common_misc:unicast(RoleID, #m_rune_decompose_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_decompose_toc{err_code = ErrCode}),
            State
    end.

check_can_decompose(RuneIDs, State) ->
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{exp = Exp, bag_runes = BagRunes} = RoleRune,
    {AddExp, BagRunes2} = check_can_decompose2(RuneIDs, BagRunes, 0),
    NewExp = Exp + AddExp,
    RoleRune2 = RoleRune#r_role_rune{exp = NewExp, bag_runes = BagRunes2},
    State2 = State#r_role{role_rune = RoleRune2},
    {ok, NewExp, State2}.

check_can_decompose2([], BagRunes, AddExp) ->
    {AddExp, BagRunes};
check_can_decompose2(_RuneIDs, [], _AddExp) ->
    ?THROW_ERR(?ERROR_RUNE_DECOMPOSE_001);
check_can_decompose2([RuneID|R], BagRunes, AddExpAcc) ->
    case lists:keytake(RuneID, #p_rune.rune_id, BagRunes) of
        {value, Rune, BagRunes2} ->
            #p_rune{level_id = LevelID} = Rune,
            [#c_rune{decompose_exp = DecomposeExp}] = lib_config:find(cfg_rune, LevelID),
            check_can_decompose2(R, BagRunes2, AddExpAcc + DecomposeExp);
        _ ->
            ?THROW_ERR(?ERROR_RUNE_DECOMPOSE_001)
    end.

%% 兑换
do_exchange(RoleID, LevelID, State) ->
    case catch check_can_exchange(LevelID, State) of
        {ok, NewPiece, NewRune, State2} ->
            common_misc:unicast(RoleID, #m_rune_bag_update_toc{update_runes = [NewRune]}),
            common_misc:unicast(RoleID, #m_rune_piece_update_toc{piece = NewPiece}),
            common_misc:unicast(RoleID, #m_rune_exchange_toc{}),
            check_bag_runes(State2),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_exchange_toc{err_code = ErrCode}),
            State
    end.

check_can_exchange(LevelID, State) ->
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{rune_id = RuneIDCounter, piece = Piece, bag_runes = BagRunes} = RoleRune,
    case lib_config:find(cfg_rune_exchange, LevelID) of
        [#c_rune_exchange{piece_cost = PieceCost, need_tower_id = NeedTowerID}] ->
            ?IF(mod_role_copy:get_cur_tower_id(State) >= NeedTowerID, ok, ?THROW_ERR(?ERROR_RUNE_EXCHANGE_001)),
            ?IF(Piece >= PieceCost, ok, ?THROW_ERR(?ERROR_RUNE_EXCHANGE_002)),
            NewPiece = Piece - PieceCost,
            NewRune = #p_rune{rune_id = RuneIDCounter, level_id = LevelID},
            BagRunes2 = [NewRune|BagRunes],
            RoleRune2 = RoleRune#r_role_rune{rune_id = RuneIDCounter + 1, piece = NewPiece, bag_runes = BagRunes2},
            State2 = State#r_role{role_rune = RoleRune2},
            {ok, NewPiece, NewRune, State2};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end.

%% 合成
do_compose(RoleID, TypeID, State) ->
    case catch check_can_compose(TypeID, State) of
        {ok, NewEssence, IsExpChange, NewExp, DelLoadIDs, DelBagIDs, NewRune, State2} ->
            common_misc:unicast(RoleID, #m_rune_essence_update_toc{essence = NewEssence}),
            ?IF(IsExpChange, common_misc:unicast(RoleID, #m_rune_exp_update_toc{exp = NewExp}), ok),
            common_misc:unicast(RoleID, #m_rune_bag_update_toc{update_runes = [NewRune], del_runes = DelBagIDs}),
            common_misc:unicast(RoleID, #m_rune_compose_toc{}),
            do_compose_broadcast(NewRune, State2),
            case DelLoadIDs =/= [] of
                true ->
                    common_misc:unicast(RoleID, #m_rune_load_update_toc{del_runes = DelLoadIDs}),
                    mod_role_fight:calc_attr_and_update(State2, ?POWER_UPDATE_RUNE_COMPOSE, TypeID);
                _ ->
                    State2
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_compose_toc{err_code = ErrCode}),
            State
    end.

check_can_compose(TypeID, State) ->
    mod_role_function:is_function_open(?FUNCTION_RUNE_COMPOSE, State),
    case lib_config:find(cfg_rune_compose, TypeID) of
        [#c_rune_compose{} = Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_RUNE_COMPOSE_001)
    end,
    LevelID = ?RUNE_LEVEL_ID(TypeID, 1),
    #c_rune_compose{
        essence_cost = EssenceCost,
        compose_rune1 = TypeID1,
        compose_rune2 = TypeID2,
        need_tower_id = NeedTowerID} = Config,
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{
        rune_id = RuneIDCounter,
        exp = Exp,
        essence = Essence,
        load_runes = LoadRunes,
        bag_runes = BagRunes} = RoleRune,
    ?IF(Essence >= EssenceCost, ok, ?THROW_ERR(?ERROR_RUNE_COMPOSE_002)),
    ?IF(mod_role_copy:get_cur_tower_id(State) >= NeedTowerID, ok, ?THROW_ERR(?ERROR_RUNE_COMPOSE_003)),
    {BagRunes2, NeedTypeIDs, ComposeRunes1} = check_can_compose2(lists:keysort(#p_rune.level_id, BagRunes), [TypeID1, TypeID2], [], []),
    {LoadRunes2, NeedTypeIDs2, ComposeRunes2} = check_can_compose2(lists:keysort(#p_rune.level_id, LoadRunes), NeedTypeIDs, [], []),
    ?IF(NeedTypeIDs2 =:= [], ok, ?THROW_ERR(?ERROR_RUNE_COMPOSE_004)),
    DelBagIDs = [ComposeID || #p_rune{rune_id = ComposeID} <- ComposeRunes1],
    DelLoadIDs = [ComposeID || #p_rune{rune_id = ComposeID} <- ComposeRunes2],

    NewEssence = Essence - EssenceCost,
    {AddExp, NewRune} = get_compose_rune(ComposeRunes1 ++ ComposeRunes2, RuneIDCounter, LevelID),
    NewExp = Exp + AddExp,
    BagRunes3 = [NewRune|BagRunes2],
    RoleRune2 = RoleRune#r_role_rune{
        rune_id = RuneIDCounter + 1,
        exp = NewExp,
        essence = NewEssence,
        load_runes = LoadRunes2,
        bag_runes = BagRunes3},
    State2 = State#r_role{role_rune = RoleRune2},
    {ok, NewEssence, NewExp =/= Exp, NewExp, DelLoadIDs, DelBagIDs, NewRune, State2}.

check_can_compose2(Runes, [], RunesAcc, ComposeRunesAcc) ->
    {RunesAcc ++ Runes, [], ComposeRunesAcc};
check_can_compose2([], NeedTypeIDs, Runes, ComposeRunesAcc) ->
    {Runes, NeedTypeIDs, ComposeRunesAcc};
check_can_compose2([Rune|R], NeedTypeIDs, RunesAcc, ComposeRunesAcc) ->
    #p_rune{level_id = LevelID} = Rune,
    TypeID = ?RUNE_TYPE_ID(LevelID),
    case lists:member(TypeID, NeedTypeIDs) of
        true ->
            NeedTypeIDs2 = lists:delete(TypeID, NeedTypeIDs),
            check_can_compose2(R, NeedTypeIDs2, RunesAcc, [Rune|ComposeRunesAcc]);
        _ ->
            check_can_compose2(R, NeedTypeIDs, [Rune|RunesAcc], ComposeRunesAcc)
    end.

get_compose_rune(ComposeRunes, RuneIDCounter, LevelID) ->
    AllExpList =
    [begin
         [#c_rune{decompose_exp = DecomposeExp}] = lib_config:find(cfg_rune, ComposeLevelID),
         [#c_rune{decompose_exp = DecomposeExp2}] = lib_config:find(cfg_rune, ?RUNE_LEVEL_ID(?RUNE_TYPE_ID(ComposeLevelID), 1)),
         DecomposeExp - DecomposeExp2
     end || #p_rune{level_id = ComposeLevelID} <- ComposeRunes],
    AllExp = lists:sum(AllExpList),
    {AddExp, NewLevelID} = get_compose_rune2(AllExp, LevelID),
    {AddExp, #p_rune{rune_id = RuneIDCounter, level_id = NewLevelID}}.

get_compose_rune2(AllExp, LevelID) ->
    NewLevelID = get_new_level_id(LevelID, 1),
    case lib_config:find(cfg_rune, NewLevelID) of
        [#c_rune{}] ->
            [#c_rune{level_exp = LevelExp}] = lib_config:find(cfg_rune, LevelID),
            case AllExp >= LevelExp of
                true ->
                    get_compose_rune2(AllExp - LevelExp, NewLevelID);
                _ ->
                    {AllExp, LevelID}
            end;
        _ ->
            {AllExp, LevelID}
    end.

do_compose_broadcast(NewRune, State) ->
    #p_rune{level_id = LevelID} = NewRune,
    [#c_rune_base{name = Name, quality = Quality}] = lib_config:find(cfg_rune_base, ?RUNE_TYPE_ID(LevelID)),
    ?IF(Quality >= ?QUALITY_ORANGE, common_broadcast:send_world_common_notice(?NOTICE_RUNE_TREASURE, [mod_role_data:get_role_name(State), Name]), ok).

%% 装备符文
do_load(RoleID, RuneID, Index, State) ->
    case catch check_can_load(RuneID, Index, State) of
        {ok, LoadUpdateRune, LoadDelIDs, BagUpdateRunes, Quality, LoadRunes3, State2} ->
            common_misc:unicast(RoleID, #m_rune_load_update_toc{update_rune = LoadUpdateRune, del_runes = LoadDelIDs}),
            common_misc:unicast(RoleID, #m_rune_bag_update_toc{update_runes = BagUpdateRunes, del_runes = [RuneID]}),
            common_misc:unicast(RoleID, #m_rune_load_toc{}),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_RUNE_LOAD, RuneID),
            Num = get_the_quality_num(LoadRunes3, Quality),
            AllLevel = get_all_level(LoadRunes3),
            State4 = mod_role_confine:rune_num(Num, Quality, State3),
            mod_role_confine:all_rune_level(AllLevel, State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_rune_load_toc{err_code = ErrCode}),
            State
    end.

check_can_load(RuneID, Index, State) ->
    #r_role{role_rune = RoleRune} = State,
    #r_role_rune{load_runes = LoadRunes, bag_runes = BagRunes} = RoleRune,
    case lists:keytake(RuneID, #p_rune.rune_id, BagRunes) of
        {value, Rune, BagRunes2} ->
            ok;
        _ ->
            Rune = BagRunes2 = ?THROW_ERR(?ERROR_RUNE_LOAD_001)
    end,
    TowerID = mod_role_copy:get_cur_tower_id(State),
    ?IF(Index > 0, ok, ?THROW_ERR(?ERROR_RUNE_LOAD_004)),
    [#c_rune_open{need_tower_floor = NeedTowerID}] = lib_config:find(cfg_rune_open, Index),
    ?IF(TowerID >= NeedTowerID, ok, ?THROW_ERR(?ERROR_RUNE_LOAD_002)),
    #p_rune{level_id = LevelID} = Rune,
    [#c_rune_base{type_list = TypeList}] = lib_config:find(cfg_rune_base, ?RUNE_TYPE_ID(LevelID)),
    ?IF(lists:member(?RUNE_TYPE_EXP, TypeList), ?THROW_ERR(?ERROR_RUNE_LOAD_005), ok),

    LoadUpdateRune = Rune#p_rune{index = Index},
    case lists:keytake(Index, #p_rune.index, LoadRunes) of
        {value, #p_rune{rune_id = LoadDelID} = OldLoadRune, LoadRunes2} ->
            LoadRunes3 = [LoadUpdateRune|LoadRunes2],
            LoadDelIDs = [LoadDelID],
            BagUpdateRunes = [OldLoadRune#p_rune{index = 0}],
            BagRunes3 = BagUpdateRunes ++ BagRunes2;
        _ ->
            LoadRunes2 = LoadRunes,
            LoadRunes3 = [LoadUpdateRune|LoadRunes],
            LoadDelIDs = BagUpdateRunes = [],
            BagRunes3 = BagRunes2
    end,
    [begin
         [#c_rune_base{type_list = LoadTypeList}] = lib_config:find(cfg_rune_base, ?RUNE_TYPE_ID(LoadLevelID)),
         ?IF((TypeList -- LoadTypeList) =:= TypeList, ok, ?THROW_ERR(?ERROR_RUNE_LOAD_003))
     end || #p_rune{level_id = LoadLevelID} <- LoadRunes2],
    RoleRune2 = RoleRune#r_role_rune{load_runes = LoadRunes3, bag_runes = BagRunes3},
    State2 = State#r_role{role_rune = RoleRune2},
    [#c_rune_base{quality = Quality, punch_list = PunchList}] = lib_config:find(cfg_rune_base, ?RUNE_TYPE_ID(Rune#p_rune.level_id)),
    %% ,2,3,4,5,6,7,8——>用0 特殊配置转换
    PunchList2 = ?IF(PunchList =:= [] orelse PunchList =:= [0], [1,2,3,4,5,6,7,8], PunchList),
    ?IF(lists:member(Index, PunchList2), ok, ?THROW_ERR(?ERROR_RUNE_LOAD_004)),
    {ok, LoadUpdateRune, LoadDelIDs, BagUpdateRunes, Quality, LoadRunes3, State2}.

get_the_quality_num(LoadRunes, Quality) ->
    lists:foldl(fun(#p_rune{level_id = LevelID}, Acc) ->
        [#c_rune_base{quality = Quality2}] = lib_config:find(cfg_rune_base, ?RUNE_TYPE_ID(LevelID)),
        ?IF(Quality2 =:= Quality, Acc + 1, Acc)
                end, 0, LoadRunes).

do_one_key_decompose(State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{exp = Exp, bag_runes = BagRunes} = RoleRune,
    {DelRuneIDs, BagRunes2, AddExp} = do_one_key_decompose(BagRunes, [], [], 0),
    Exp2 = AddExp + Exp,
    common_misc:unicast(RoleID, #m_rune_bag_update_toc{del_runes = DelRuneIDs}),
    common_misc:unicast(RoleID, #m_rune_exp_update_toc{exp = Exp2}),
    RoleRune2 = RoleRune#r_role_rune{bag_runes = BagRunes2, exp = Exp2},
    State#r_role{role_rune = RoleRune2}.

do_one_key_decompose([], DelRuneIDs, BagRunesAcc, AddExp) ->
    {DelRuneIDs, BagRunesAcc, AddExp};
do_one_key_decompose([Rune|R], DelRuneIDs, BagRunesAcc, AddExp) ->
    #p_rune{rune_id = RuneID, level_id = LevelID} = Rune,
    TypeID = ?RUNE_TYPE_ID(LevelID),
    [#c_rune_base{quality = Quality, type_list = TypeList}] = lib_config:find(cfg_rune_base, TypeID),
    case Quality < ?RUNE_QUALITY_PURPLE orelse [?RUNE_TYPE_EXP] =:= TypeList of
        true -> %% 紫色以下符文分解 或者 符文精华
            [#c_rune{decompose_exp = DecomposeExp}] = lib_config:find(cfg_rune, LevelID),
            do_one_key_decompose(R, [RuneID|DelRuneIDs], BagRunesAcc, AddExp + DecomposeExp);
        _ ->
            do_one_key_decompose(R, DelRuneIDs, [Rune|BagRunesAcc], AddExp)
    end.

%% 检查符文背包的空间
check_bag_runes(State) ->
    #r_role{role_id = RoleID, role_rune = RoleRune} = State,
    #r_role_rune{bag_runes = BagRunes} = RoleRune,
    case erlang:length(BagRunes) >= ?ENOUGH_BAG_RUNE_NUM of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, bag_runes_enough});
        _ ->
            ok
    end.

get_new_level_id(LevelID, AddLevel) ->
    RuneLevel = ?RUNE_LEVEL(LevelID),
    ?RUNE_LEVEL_ID(?RUNE_TYPE_ID(LevelID), RuneLevel + AddLevel).