%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 天机印系统
%%% @end
%%% Created : 24. 六月 2019 19:53
%%%-------------------------------------------------------------------
-module(mod_role_nature).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("db.hrl").
-include("copy.hrl").
-include("nature.hrl").
-include("proto/mod_role_bag.hrl").
-include("proto/mod_role_throne.hrl").
-include("proto/mod_role_nature.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    calc/1,               %% 属性统计
    online/1             %% 上线cfg_item
]).

-export([handle/2]).

-export([i/1, send/2, gm_nature_hole/2, gm_del_nature/1]).

-export([
    get_nature_open_num/2,
    check_goods_refine/2,
    add_intensify_nature/2,
    check_goods_bag_refine/2,
    get_book_list/1,
    item_trigger/2
]).

-export([
    function_open/1,
    up_role_info/1,
    get_nature_intensify/1,
    get_nature_hole/1,
    get_nature_seal/1,
    get_nature_suit/1,
    open_nature_place/2
]).

-export([
    get_nature_refine_level/1,
    get_nature_hole_num/1,
    get_color_num/2,
    get_refine_level_num/2
]).

i(RoleID) ->
    get_role_info(RoleID).
send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

init(#r_role{role_id = RoleID, role_nature = undefined} = State) ->
    RoleNature = #r_role_nature{role_id = RoleID},
    up_role_info(State#r_role{role_nature = RoleNature});
init(State) ->
    State.

calc(#r_role{role_nature = RoleNature} = State) ->
    #r_role_nature{nature = Nature} = RoleNature,
    CalcAttr1 = nature_seal_attr(Nature),
    CalcAttr2 = nature_intensify_attr(Nature),
    {CalcAttr3, SkillLists} = nature_suit_attr(Nature),
    State1 = mod_role_fight:get_state_by_kv(State, ?CALC_KEY_NATURE, common_misc:sum_calc_attr([CalcAttr1, CalcAttr2, CalcAttr3])),
    ?IF(SkillLists =/= [], mod_role_skill:skill_fun_change(?SKILL_FUN_NATURE, SkillLists, State1), State1).

online(#r_role{role_id = RoleID} = State) ->
    do_nature_info(RoleID, State).

handle({#m_role_nature_info_tos{}, RoleID, _PID}, State) ->
    do_nature_info(RoleID, State);
handle({#m_role_nature_place_open_tos{aperture_id = ApertureID, type = Type}, RoleID, _PID}, State) ->
    do_nature_place_open(RoleID, ApertureID, Type, State, true);
handle({#m_role_nature_place_operate_tos{aperture_id = ApertureID, type = Type, goods_id = GoodsID, operate_type = OperateType}, RoleID, _PID}, State) ->
    do_nature_place_operate(ApertureID, Type, GoodsID, OperateType, RoleID, State);
handle({#m_role_nature_place_refine_tos{aperture_id = ApertureID, type = Type}, RoleID, _PID}, State) ->
    do_nature_place_refine(ApertureID, Type, RoleID, State);
handle({#m_role_nature_goods_refine_tos{rune_ids = RuneIDs}, RoleID, _PID}, State) ->
    do_nature_goods_refine(RoleID, RuneIDs, State);
handle({#m_role_nature_opt_tos{quality = Quality, star = Star}, RoleID, _PID}, State) ->
    do_nature_opt(RoleID, Quality, Star, State);
handle({#m_role_nature_compose_tos{compose_id = ComposeID}, RoleID, _PID}, State) ->
    do_nature_compose(RoleID, ComposeID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc 天机印属性
nature_seal_attr(Nature) ->
    BaseList = nature_seal_attr(Nature, []),
    common_misc:sum_calc_attr(BaseList).
nature_seal_attr([], AccLists) ->
    AccLists;
nature_seal_attr([#r_nature{goods = Goods} | Nature], AccLists) ->
    case Goods of
        [] ->
            nature_seal_attr(Nature, AccLists);
        [#p_goods{type_id = TypeID} | _] ->
            #c_nature_seal{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp,
                metal = Metal,
                wood = Wood,
                water = Water,
                fire = Fire,
                earth = Earth} = get_nature_seal(TypeID),
            BaseAttr = #actor_cal_attr{
                max_hp = {AddHp, 0},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                arp = {AddArp, 0},
                metal = {Metal, 0},
                wood = {Wood, 0},
                water = {Water, 0},
                fire = {Fire, 0},
                earth = {Earth, 0}},
            nature_seal_attr(Nature, [BaseAttr | AccLists])
    end.

%% @doc 天机印强化属性
nature_intensify_attr(Nature) ->
    BaseList = nature_intensify_attr(Nature, []),
    common_misc:sum_calc_attr(BaseList).
nature_intensify_attr([], AccLists) ->
    AccLists;
nature_intensify_attr([#r_nature{goods = Goods, refine_id = RefineID} | Nature], AccLists) ->
    case Goods of
        [] ->
            nature_intensify_attr(Nature, AccLists);
        [#p_goods{type_id = TypeID} | _] when RefineID > 0 ->
            #c_nature_seal{place = Place, intensify_num = IntensifyNum} = get_nature_seal(TypeID),
            #c_nature_intensify{level = Level} = NatureIntensify = get_nature_intensify(RefineID),
            case IntensifyNum < Level of
                true ->
                    #c_nature_intensify{
                        add_hp = AddHp,
                        add_attack = AddAttack,
                        add_defence = AddDefence,
                        add_arp = AddArp,
                        metal = Metal,
                        wood = Wood,
                        water = Water,
                        fire = Fire,
                        earth = Earth
                    } = get_nature_intensify(get_nature_intensify({get_id, Place, IntensifyNum})),
                    BaseAttr = #actor_cal_attr{
                        max_hp = {AddHp, 0},
                        attack = {AddAttack, 0},
                        defence = {AddDefence, 0},
                        arp = {AddArp, 0},
                        metal = {Metal, 0},
                        wood = {Wood, 0},
                        water = {Water, 0},
                        fire = {Fire, 0},
                        earth = {Earth, 0}},
                    nature_intensify_attr(Nature, [BaseAttr | AccLists]);
                _ ->
                    #c_nature_intensify{
                        add_hp = AddHp,
                        add_attack = AddAttack,
                        add_defence = AddDefence,
                        add_arp = AddArp,
                        metal = Metal,
                        wood = Wood,
                        water = Water,
                        fire = Fire,
                        earth = Earth
                    } = NatureIntensify,
                    BaseAttr = #actor_cal_attr{
                        max_hp = {AddHp, 0},
                        attack = {AddAttack, 0},
                        defence = {AddDefence, 0},
                        arp = {AddArp, 0},
                        metal = {Metal, 0},
                        wood = {Wood, 0},
                        water = {Water, 0},
                        fire = {Fire, 0},
                        earth = {Earth, 0}},
                    nature_intensify_attr(Nature, [BaseAttr | AccLists])
            end;
        _ ->
            nature_intensify_attr(Nature, AccLists)
    end.

%% @doc 天机印套装属性
nature_suit_attr(Nature) ->
    %% 部件分类、技能统计
    {SuitLists, Skill1Lists, Skill2Lists, GoodsLists} =
        lists:foldl(fun(#r_nature{type = Type, goods = Goods}, {Acc, Acc1, Acc2, Acc3}) ->
            case Goods of
                [] ->
                    {Acc, Acc1, Acc2, Acc3};
                [#p_goods{type_id = TypeID} | _] ->
                    #c_nature_seal{suit = Suit, skill1 = Skill1, skill2 = Skill2} = get_nature_seal(TypeID),
                    ListsAcc =
                        case lists:keytake(Type, 1, Acc2) of
                            {value, {Type, _}, TupleList2} when Skill2 =/= [] ->
                                [{Type, Skill2} | TupleList2];
                            _ when Skill2 =/= [] ->
                                [{Type, Skill2} | Acc2];
                            _ ->
                                Acc2
                        end,
                    SuitLists2 =
                        case lists:keytake(Type, 1, Acc) of
                            {value, {Type, SuitLists1}, TupleList} ->
                                [{Type, Suit ++ SuitLists1} | TupleList];
                            _ ->
                                [{Type, Suit} | Acc]
                        end,
                    {SuitLists2, Skill1 ++ Acc1, ListsAcc, [{TypeID, Type} | Acc3]}
            end end, {[], [], [], []}, Nature),

    Lists = lists:usort(lists:foldl(fun({Type, Suit}, Acc) ->
        [{Type, SuitID} || SuitID <- Suit] ++ Acc end, [], SuitLists)),

    %% 套机统计
    NewSuitLists =
        lists:filter(fun({Type, SuitID}) ->
            #c_nature_suit{nature = _NatureIDLists, number_units = NumberUnits, max_suit_id = MaxSuitID} = get_nature_suit(SuitID),
%%            case NatureIDLists of
%%                [] ->
            #c_nature_suit{nature = MaxNatureIDLists} = get_nature_suit(MaxSuitID),
            Count =
                lists:foldl(fun(NatureID, AccNum) ->
                    case lists:member({NatureID, Type}, GoodsLists) of
                        true when NatureID =/= ?CENTRALITY ->
                            AccNum + 1;
                        _ ->
                            AccNum
                    end end, 0, MaxNatureIDLists),
            Count >= NumberUnits
%%                _ ->
%%                    lists:all(fun(NatureID) ->
%%                        lists:keymember(NatureID, #p_goods.type_id, L)
%%                              end, NatureIDLists)
%%            end
                     end, Lists),

    %% 技能2的计算
    NewLists = Lists -- NewSuitLists,
    NewSuitLists1 =
        lists:foldl(fun({Type, SuitID}, Acc) ->
            #c_nature_suit{number_units = NumberUnits, max_suit_id = MaxSuitID} = get_nature_suit(SuitID),
            case lists:keyfind(Type, 1, Skill2Lists) of
                {Type, [Wipe, Count | _]} when NumberUnits >= Count ->
                    #c_nature_suit{nature = MaxNatureIDLists} = get_nature_suit(MaxSuitID),
                    Count1 = lists:foldl(fun(NatureID, Acc1) ->
                        case lists:member({NatureID, Type}, GoodsLists) of
                            true when NatureID =/= ?CENTRALITY ->
                                Acc1 + 1;
                            _ ->
                                Acc1
                        end end, 0, MaxNatureIDLists),
                    case (Count1 + Wipe) >= NumberUnits of
                        true ->
                            [SuitID | Acc];
                        _ ->
                            Acc
                    end;
                _ ->
                    Acc
            end end, [], NewLists),
    ?LXG({SuitLists, Lists, NewSuitLists1, NewSuitLists, NewLists, Skill1Lists, Skill2Lists}),
    BaseList = nature_suit_attr(NewSuitLists1 ++ [SuitID || {_Type, SuitID} <- NewSuitLists], []),
    {common_misc:sum_calc_attr(BaseList), Skill1Lists}.
nature_suit_attr([], AccLists) ->
    AccLists;
nature_suit_attr([SuitID | SuitLists], AccLists) ->
    #c_nature_suit{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_defence = AddDefence,
        add_arp = AddArp,
        metal = Metal,
        wood = Wood,
        water = Water,
        fire = Fire,
        earth = Earth,
        hp_rate = HpRate,
        attack_rate = AttackRate
    } = get_nature_suit(SuitID),
    BaseAttr = #actor_cal_attr{
        max_hp = {AddHp * (1 + HpRate / ?RATE_100), 0},
        attack = {AddAttack * (1 + AttackRate / ?RATE_100), 0},
        defence = {AddDefence, 0},
        arp = {AddArp, 0},
        metal = {Metal, 0},
        wood = {Wood, 0},
        water = {Water, 0},
        fire = {Fire, 0},
        earth = {Earth, 0}},
    nature_suit_attr(SuitLists, [BaseAttr | AccLists]).

%% @doc gm
gm_nature_hole(Type, #r_role{role_id = RoleID} = State) ->
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{quality = Quality, star = Star, consume_money = ConsumeMoney} = RoleNature,

    Lists =
        lists:foldl(fun({ID, #c_nature_hole{type = Type1}}, Acc) ->
            case Type =:= Type1 orelse Type =:= 0 of
                true ->
                    [{ID, Type1} | Acc];
                _ ->
                    Acc
            end end, [], cfg_nature_hole:list()),
    NatureLists = [#r_nature{aperture_id = ID, type = Type2} || {ID, Type2} <- Lists],
    NaturePlace = [to_p_nature_place(E) || E <- NatureLists],
    DataRecord = #m_role_nature_info_toc{nature_place = NaturePlace, quality = Quality, star = Star,  consume_money = ConsumeMoney},
    common_misc:unicast(RoleID, DataRecord),
    up_role_info(State#r_role{role_nature = RoleNature#r_role_nature{nature = NatureLists}}).

gm_del_nature(#r_role{role_id = RoleID} = State) ->
    RoleNature = #r_role_nature{role_id = RoleID},
    up_role_info(State#r_role{role_nature = RoleNature}).

%% @doc 添加天机勾玉
add_intensify_nature(0, State) ->
    State;
add_intensify_nature(IntensifyNature, #r_role{role_id = RoleID, role_nature = RoleNature} = State) ->
    #r_role_nature{consume_money = ConsumeMoney} = RoleNature,
    NewRoleNature = RoleNature#r_role_nature{consume_money = ConsumeMoney + IntensifyNature},
    common_misc:unicast(RoleID, #m_role_nature_consume_money_toc{consume_money = ConsumeMoney + IntensifyNature}),
    up_role_info(State#r_role{role_nature = NewRoleNature}).

%% @doc 获取当前的天机印开孔数量
%% Type:类型，阴阳
get_nature_open_num(RoleID, Type) ->
    #r_role_nature{nature = Nature} = get_role_info(RoleID),
    Lists = lists:filter(fun(#r_nature{type = InlayType}) -> InlayType =:= Type end, Nature),
    length(Lists).


%% @doc 获取天机信息
do_nature_info(_RoleID, State) ->
    case mod_role_function:get_is_function_open(?FUNCTION_NATURE, State) of
        true ->
            function_open(State);
        _ ->
            State
    end.

function_open(State) ->
    #r_role{role_id = RoleID, role_nature = RoleNature} = State,
    #r_role_nature{nature = Nature, quality = Quality, star = Star, consume_money = ConsumeMoney, book_list = BookList} = RoleNature,

    Lists = check_nature_hole(State),

    Nature1 = [begin #c_nature_hole{type = Type} = get_nature_hole(ID),
    #r_nature{aperture_id = ID, type = Type} end || ID <- Lists] ++ Nature,
    NaturePlace = [to_p_nature_place(E) || E <- Nature1],

    DataRecord = #m_role_nature_info_toc{nature_place = NaturePlace, quality = Quality, star = Star, consume_money = ConsumeMoney, book_list = BookList},
    common_misc:unicast(RoleID, DataRecord),
    up_role_info(State#r_role{role_nature = RoleNature#r_role_nature{nature = Nature1}}).

%% @doc 检测开孔条件
check_nature_hole(#r_role{role_nature = #r_role_nature{nature = Nature}} = State) ->
    check_nature_hole(State, Nature, 0).
check_nature_hole(State, Nature, MapID) ->
    ApertureLists = [ApertureID || #r_nature{aperture_id = ApertureID} <- Nature],
    Lists = cfg_nature_hole:list(),
    lists:foldl(fun({ID, #c_nature_hole{open_condition = OpenConditionMapID, open_prop = OpenProp}}, Acc) ->
        case lists:member(ID, ApertureLists) of
            true ->
                Acc;
            false when OpenConditionMapID =:= 0 ->
                [ID | Acc];
            _ ->
                case MapID =:= OpenConditionMapID of
                    true ->
                        [ID | Acc];
                    _ when MapID =:= 0->
                        #r_role{role_copy = #r_role_copy{cur_five_elements = CurFiveElements}} = State,
                        case catch mod_role_copy:check_copy_five_elements_open(OpenConditionMapID, State) of
                            ok when OpenProp =:= "" andalso CurFiveElements >= OpenConditionMapID ->
                                [ID | Acc];
                            _ ->
                                Acc
                        end;
                    _ ->
                        Acc
                end
        end end, [], Lists).

%% @doc 部位开启检查
open_nature_place(#r_role{role_id = RoleID, role_nature = #r_role_nature{nature = Nature}} = State, MapID) ->
    lists:foldl(fun(ApertureID, AccState) ->
        #c_nature_hole{type = Type} = get_nature_hole(ApertureID),
        do_nature_place_open(RoleID, ApertureID, Type, AccState, false)
                end, State, check_nature_hole(State, Nature, MapID)).
%% @doc 部位开启
do_nature_place_open(RoleID, ApertureID, Type, State, Bool) ->
    case catch check_nature_place_open(ApertureID, Type, State) of
        {ok, State1} ->
            DataRecord = #m_role_nature_place_open_toc{type = Type, aperture_id = ApertureID},
            common_misc:unicast(RoleID, DataRecord),
            State1;
        {error, ErrCode} when Bool =:= true ->
            DataRecord = #m_role_nature_place_open_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State;
        {error, _ErrCode} ->
            State
    end.
check_nature_place_open(ApertureID, Type, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{nature = Nature} = RoleNature,
    ?IF(lib_config:find(cfg_nature_hole, ApertureID) =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #c_nature_hole{open_condition = OpenConditionMapID, type = Type, open_prop = OpenProp} = get_nature_hole(ApertureID),
    ?IF(OpenConditionMapID =:= 0, ok, mod_role_copy:check_copy_five_elements_open(OpenConditionMapID, State)),
    ?IF(lists:keymember(ApertureID, #r_nature.aperture_id, Nature), ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPEN_001), ok),
    NewNature = [#r_nature{aperture_id = ApertureID, type = Type} | Nature],
    case lib_tool:string_to_intlist(OpenProp)of
        [_|_] = ItemList ->
            BagDoing = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_NATURE_PLACE_OPEN, State),
            State2 = mod_role_bag:do(BagDoing, State);
        _ ->
            State2 = State
    end,
    {ok, up_role_info(State2#r_role{role_nature = RoleNature#r_role_nature{nature = NewNature}})}.

%% @doc 天机印操作
do_nature_place_operate(ApertureID, Type, GoodsID, OperateType, RoleID, State) ->
    case catch check_nature_place_operate(ApertureID, Type, GoodsID, OperateType, State) of
        {ok, ?DIS_BOARD, Goods, _BagDoing, State4} ->
            DataRecord = #m_role_nature_place_operate_toc{aperture_id = ApertureID, type = Type, goods = Goods, operate_type = OperateType},
            common_misc:unicast(RoleID, DataRecord),
            role_misc:create_goods(State4, ?ITEM_GAIN_NATURE_DIS_BOARD, Goods);
        {ok, ?INLAY, Goods, BagDoing, State4} ->
            DataRecord = #m_role_nature_place_operate_toc{aperture_id = ApertureID, type = Type, goods = Goods, operate_type = OperateType},
            common_misc:unicast(RoleID, DataRecord),
            State5 = mod_role_bag:do(BagDoing, State4),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:nature_hole_num(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:nature_color(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State5);
        {ok, ?SUBSTITUTE, Goods, GoodsOld, BagDoing, State4} ->
            DataRecord = #m_role_nature_place_operate_toc{aperture_id = ApertureID, type = Type, goods = Goods, operate_type = OperateType},
            common_misc:unicast(RoleID, DataRecord),
            State5 = mod_role_bag:do(BagDoing, State4),
            State6 = role_misc:create_goods(State5, ?ITEM_GAIN_NATURE_SUBSTITUTE, GoodsOld),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:nature_color(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State6);
        {error, ErrCode} ->
            DataRecord = #m_role_nature_place_operate_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_nature_place_operate(ApertureID, Type, GoodsID, ?DIS_BOARD, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{nature = NatureLists} = RoleNature,

    ?IF(lists:keymember(ApertureID, #r_nature.aperture_id, NatureLists), ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_002)),
    #c_nature_hole{type = NewType, place = Place1} = get_nature_hole(ApertureID),

    #r_nature{goods = GoodsLists, history = History} = Nature = lists:keyfind(ApertureID, #r_nature.aperture_id, NatureLists),
    ?IF(lists:keymember(GoodsID, #p_goods.id, GoodsLists), ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_001)),
    #p_goods{type_id = TypeID} = Goods = lists:keyfind(GoodsID, #p_goods.id, GoodsLists),
    #c_nature_seal{place = Place2} = get_nature_seal(TypeID),
    ?IF(Type =:= NewType andalso Place1 =:= Place2, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),

    NewNature = Nature#r_nature{goods = [], history = [{GoodsID, TypeID} | lists:sublist(History, ?GET_LENGTH)]},
    State2 = State#r_role{role_nature = RoleNature#r_role_nature{nature = [NewNature | lists:keydelete(ApertureID, #r_nature.aperture_id, NatureLists)]}},

    BagDoing = [{create, ?ITEM_GAIN_NATURE_DIS_BOARD, [Goods]}],

    State4 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_NATURE_REMOVE_SEAL, GoodsID),
    {ok, ?DIS_BOARD, [Goods], BagDoing, State4};

check_nature_place_operate(ApertureID, Type, GoodsID, ?INLAY, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{nature = NatureLists} = RoleNature,

    ?IF(lists:keymember(ApertureID, #r_nature.aperture_id, NatureLists), ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_002)),
    #c_nature_hole{type = NewType, place = Place1} = get_nature_hole(ApertureID),
    #r_nature{goods = GoodsLists} = Nature = lists:keyfind(ApertureID, #r_nature.aperture_id, NatureLists),
    ?IF(GoodsLists =:= [], ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_003)),

    {ok, #p_goods{type_id = TypeID, num = Num} = Goods} = mod_role_bag:check_bag_by_id(GoodsID, State),
    #c_nature_seal{place = Place2} = get_nature_seal(TypeID),
    ?IF(Type =:= NewType andalso Place1 =:= Place2, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),

    BagDoing = [{decrease, ?ITEM_REDUCE_NATURE_INSTALL, [#r_goods_decrease_info{type_id = TypeID, num = Num}]}],

    NewNature = Nature#r_nature{goods = [Goods]},
    State2 = State#r_role{role_nature = RoleNature#r_role_nature{nature = [NewNature | lists:keydelete(ApertureID, #r_nature.aperture_id, NatureLists)]}},
    State4 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_NATURE_SEAL, GoodsID),
    {ok, ?INLAY, [Goods], BagDoing, State4};

check_nature_place_operate(ApertureID, Type, GoodsID, ?SUBSTITUTE, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{nature = NatureLists} = RoleNature,

    ?IF(lists:keymember(ApertureID, #r_nature.aperture_id, NatureLists), ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_002)),
    #c_nature_hole{type = NewType, place = Place1} = get_nature_hole(ApertureID),
    #r_nature{goods = GoodsLists, history = History} = Nature = lists:keyfind(ApertureID, #r_nature.aperture_id, NatureLists),
    ?IF(GoodsLists =/= [], ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_001)),

    {ok, #p_goods{type_id = TypeID, num = Num} = Goods} = mod_role_bag:check_bag_by_id(GoodsID, State),
    #c_nature_seal{place = Place2} = get_nature_seal(TypeID),
    ?IF(Type =:= NewType andalso Place1 =:= Place2, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),

    [#p_goods{type_id = TypeID1, id = GoodsID1} = OldGoods | _] = GoodsLists,
    BagDoing = [{decrease, ?ITEM_REDUCE_NATURE_INSTALL, [#r_goods_decrease_info{type_id = TypeID, num = Num}]}],
%%    ?IF(TypeID1 =/= TypeID, ok, ?THROW_ERR(?ERROR_THRONE_SURFACE_ACT_001)),

    NewNature = Nature#r_nature{goods = [Goods], history = [{GoodsID1, TypeID1} | lists:sublist(History, ?GET_LENGTH)]},
    State2 = State#r_role{role_nature = RoleNature#r_role_nature{nature = [NewNature | lists:keydelete(ApertureID, #r_nature.aperture_id, NatureLists)]}},

    State4 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_NATURE_SEAL_UP, GoodsID),

    {ok, ?SUBSTITUTE, [Goods], [OldGoods], BagDoing, State4}.

%% @doc 自动分解
check_goods_refine(BagDoing, State) when is_tuple(State) ->
    lists:foldl(fun(Doing, Acc) ->
        case Doing of
            {_, _Action, []} ->
                Acc;
            {create, Action, CreateList} ->
                {Lists, Lists1} =
                    lists:foldl(fun(#p_goods{type_id = TypeID} = Goods, {Acc1, Acc2}) ->
                        #c_item{item_type = ItemType, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        case ItemType =:= ?IS_TYPE_OF_NATURE andalso EffectType > 0 of
                            true ->
                                {[Goods | Acc1], Acc2};
                            _ ->
                                {Acc1, [Goods | Acc2]}
                        end end, {[], []}, CreateList),
                case Lists of
                    [] ->
                        [{create, Action, CreateList} | Acc];
                    _ ->
                        {AddBagDoing, AddGoods} = check_goods_refine(State, Lists),
                        case AddBagDoing of
                            [] ->
                                [{create, Action, CreateList} | Acc];
                            _ ->
                                AddBagDoing ++ [{create, Action, Lists1 ++ AddGoods} | Acc]
                        end
                end;
            {create, BagID, Action, CreateList} ->
                {Lists, Lists1} =
                    lists:foldl(fun(#p_goods{type_id = TypeID} = Goods, {Acc1, Acc2}) ->
                        #c_item{item_type = ItemType, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        case ItemType =:= ?IS_TYPE_OF_NATURE andalso EffectType > 0 of
                            true ->
                                {[Goods | Acc1], Acc2};
                            _ ->
                                {Acc1, [Goods | Acc2]}
                        end end, {[], []}, CreateList),
                case Lists of
                    [] ->
                        [{create, BagID, Action, CreateList} | Acc];
                    _ ->
                        {AddBagDoing, AddGoods} = check_goods_refine(State, Lists),
                        case AddBagDoing of
                            [] ->
                                [{create, BagID, Action, CreateList} | Acc];
                            _ ->
                                AddBagDoing ++ [{create, BagID, Action, Lists1 ++ AddGoods} | Acc]
                        end
                end;
            _ ->
                [Doing | Acc]
        end end, [], BagDoing);
%% @doc 进行分解
check_goods_refine(State, AddGoods) ->
    #r_role{role_bag = RoleBag, role_nature = RoleNature} = State,
    #r_role_nature{quality = Quality, star = Star} = RoleNature,
    #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = mod_role_bag:get_bag(?BAG_ID_NATURE, RoleBag),

    case Quality > 0 of
        false ->
            {BagList, LetterList} = classify_nature_drug(BagGrid =< length(GoodsList), AddGoods),
            case BagList of
                [] ->
                    Lists1 = [];
                _ ->
                    NewNum = lists:foldl(fun(#p_goods{type_id = TypeID, num = Num}, AccNum) ->
                        #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
                        AccNum + (lib_tool:to_integer(EffectArgs) * Num) end, 0, BagList),
                    Lists1 = [{create, ?ITEM_GAIN_NATURE_RESOLVE, [#p_goods{type_id = ?BAG_NAT_INTENSIFY_GOODS, num = NewNum}]}]
            end,

            {Lists1, LetterList};
        _ ->
            case BagGrid =< length(AddGoods ++ GoodsList) of
                true ->
                    Lists = lists:filter(fun(#p_goods{type_id = TypeID}) ->
                        #c_item{quality = Quality1, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        #c_nature_seal{star_level = StarLevel} = get_nature_seal(TypeID),
                        is_fit_condition(Quality, Quality1, Star, StarLevel, EffectType) end, GoodsList),

                    Lists1 = lists:filter(fun(#p_goods{type_id = TypeID}) ->
                        #c_item{quality = Quality1, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        #c_nature_seal{star_level = StarLevel} = get_nature_seal(TypeID),
                        is_fit_condition(Quality, Quality1, Star, StarLevel, EffectType) end, AddGoods),

                    BagList = AddGoods -- Lists1,

                    case BagGrid < (length(GoodsList -- Lists) + length(BagList)) of
                        true ->
                            {BagList1, LetterList1} = classify_nature_drug(true, BagList);
                        _ ->
                            BagList1 = [],
                            LetterList1 = BagList
                    end,

                    NewNum = lists:foldl(fun(#p_goods{type_id = TypeID, num = Num}, AccNum) ->
                        #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
                        AccNum + (lib_tool:to_integer(EffectArgs) * Num) end, 0, BagList1 ++ Lists1 ++ Lists),

                    Lists2 = ?IF(NewNum > 0, [{decrease, ?ITEM_REDUCE_NATURE_RESOLVE, [#r_goods_decrease_info{type_id = TypeID, num = Num} || #p_goods{type_id = TypeID, num = Num} <- Lists]},
                        {create, ?ITEM_GAIN_NATURE_RESOLVE, [#p_goods{type_id = ?BAG_NAT_INTENSIFY_GOODS, num = NewNum}]}], []),

                    {Lists2, LetterList1};
                _ ->
                    {[], AddGoods}
            end
    end.


%% @doc 检测自动分解的背包格子
check_goods_bag_refine(State, AddGoods) ->
    #r_role{role_bag = RoleBag, role_nature = RoleNature} = State,
    #r_role_nature{quality = Quality, star = Star} = RoleNature,
    #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = mod_role_bag:get_bag(?BAG_ID_NATURE, RoleBag),

    case Quality > 0 of
        false ->
            {BagList, LetterList} = classify_nature_drug(BagGrid =< length(GoodsList), AddGoods),
            {BagList1, LetterList1} = lib_tool:split(BagGrid - erlang:length(GoodsList), LetterList),
            {BagList ++ BagList1, LetterList1};
        _ ->

            case BagGrid =< length(AddGoods ++ GoodsList) of
                true ->
                    Lists = lists:filter(fun(#p_goods{type_id = TypeID}) ->
                        #c_item{quality = Quality1, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        #c_nature_seal{star_level = StarLevel} = get_nature_seal(TypeID),
                        is_fit_condition(Quality, Quality1, Star, StarLevel, EffectType) end, GoodsList),

                    Lists1 = lists:filter(fun(#p_goods{type_id = TypeID}) ->
                        #c_item{quality = Quality1, effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
                        #c_nature_seal{star_level = StarLevel} = get_nature_seal(TypeID),
                        is_fit_condition(Quality, Quality1, Star, StarLevel, EffectType) end, AddGoods),
                    case BagGrid =< (length(AddGoods ++ GoodsList) - length(Lists1 ++ Lists)) of
                        true ->
                            EmptyGrid = BagGrid - length(GoodsList -- Lists),
                            {BagList, LetterList} = classify_nature_drug(true, AddGoods),
                            {BagList1, LetterList1} = lib_tool:split(EmptyGrid, LetterList),
                            {BagList ++ BagList1, LetterList1};
                        _ ->
                            {AddGoods, []}
                    end;
                _ ->
                    {AddGoods, []}
            end
    end.

is_fit_condition(Quality, ConfigQuality, Star, ConfigStar, EffectType) ->
    Quality > ConfigQuality orelse (Quality =:= ConfigQuality andalso Star >= ConfigStar) andalso EffectType > 0.

%% @doc 背包满了，分解当前获取到的天机药（新改需求）
%% 从获取的物品里吧天机药分类
classify_nature_drug(true, AddGoods) ->
    lists:foldl(fun(#p_goods{type_id = TypeID} = Goods, {Acc1, Acc2}) ->
        #c_item{effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
        case EffectType =:= ?NATURE_DRUG of
            true ->
                {[Goods | Acc1], Acc2};
            _ ->
                {Acc1, [Goods | Acc2]}
        end end, {[], []}, AddGoods);
classify_nature_drug(false, AddGoods) ->
    {[], AddGoods}.

get_book_list(State) ->
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{book_list = BookList} = RoleNature,
    BookList.

item_trigger(TypeIDList, State) ->
    AddList =
        lists:foldl(
            fun(TypeID, Acc) ->
                case mod_role_item:get_item_config(TypeID) of
                    #c_item{effect_type = ?ITEM_NATURE_ITEM} ->
                        ?IF(lists:member(TypeID, Acc), Acc, [TypeID|Acc]);
                    _ ->
                        Acc
                end
            end, [], TypeIDList),
    case AddList =/= [] of
        true ->
            #r_role{role_id = RoleID, role_nature = RoleNature} = State,
            #r_role_nature{book_list = BookList} = RoleNature,
            case AddList -- BookList of
                [_|_] = NewList ->
                    BookList2 = lib_tool:list_filter_repeat(NewList ++ BookList),
                    RoleNature2 = RoleNature#r_role_nature{book_list = BookList2},
                    common_misc:unicast(RoleID, #m_role_nature_book_update_toc{book_list = BookList2}),
                    State#r_role{role_nature = RoleNature2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

%% @doc 部位强化
do_nature_place_refine(ApertureID, Type, RoleID, State) ->
    case catch check_nature_place_refine(ApertureID, Type, State) of
        {ko, NexLevel, NewConsumeMoney, State2} ->
            DataRecord = #m_role_nature_place_refine_toc{aperture_id = ApertureID, type = Type, refine = NexLevel},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(RoleID, #m_role_nature_consume_money_toc{consume_money = NewConsumeMoney}),
            State3 = up_role_info(State2),
            FuncList = [
                fun(StateAcc) -> mod_role_day_target:nature_refine(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:nature_refine_num(StateAcc) end
            ],
            role_server:execute_state_fun(FuncList, State3);
        {error, ErrCode} ->
            DataRecord = #m_role_nature_place_refine_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_nature_place_refine(ApertureID, Type, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{nature = NatureLists, consume_money = ConsumeMoney} = RoleNature,

    ?IF(lists:keymember(ApertureID, #r_nature.aperture_id, NatureLists), ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_OPERATE_002)),
    #c_nature_hole{type = NewType, intensify_id = IntensifyID, place = Place1} = get_nature_hole(ApertureID),
    #r_nature{goods = GoodsLists, refine_id = RefineID} = Nature = lists:keyfind(ApertureID, #r_nature.aperture_id, NatureLists),
    ?IF(GoodsLists =/= [], ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_REFINE_002)),
    ?IF(Type =:= NewType, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
    NewRefineID = ?IF(RefineID =:= 0, IntensifyID, RefineID),
    ?IF(lib_config:find(cfg_new_nature_intensify, NewRefineID) =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),

    [#p_goods{type_id = TypeID} | _] = GoodsLists,
    #c_nature_seal{intensify_num = IntensifyNum, place = Place2} = get_nature_seal(TypeID),

    #c_nature_intensify{next_id = NextID, level = Level, num = Num, consume_goods = ConsumeGoods, place = Place3} = get_nature_intensify(NewRefineID),
    case lib_config:find(cfg_new_nature_intensify, NextID) =/= [] andalso RefineID =/= 0 of
        true ->
            #c_nature_intensify{intensify_id = NewIntensifyID, level = NexLevel, num = NewNum, consume_goods = NewConsumeGoods, place = Place4} = get_nature_intensify(NextID),
            ?IF(IntensifyNum >= NexLevel, ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_REFINE_001));
        _ ->
            NexLevel = Level,
            NewNum = Num,
            NewConsumeGoods = ConsumeGoods,
            NewIntensifyID = NewRefineID,
            Place4 = Place3,
            ?IF(NextID =/= 0, ok, ?THROW_ERR(?ERROR_ROLE_NATURE_PLACE_REFINE_001))
    end,

    ?IF(Place1 =:= Place2 andalso Place2 =:= Place4, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
    ?IF(ConsumeMoney >= NewNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM)),

    NewConsumeMoney = ConsumeMoney - NewNum,

    NewNature = Nature#r_nature{refine_id = NewIntensifyID},
    State2 = State#r_role{role_nature = RoleNature#r_role_nature{nature = [NewNature | lists:keydelete(ApertureID, #r_nature.aperture_id, NatureLists)], consume_money = NewConsumeMoney}},
    State4 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_NATURE_REFINE, ApertureID),
    LogList = mod_role_bag:trans_to_log(State4, mod_role_bag:merge_goods_log([#p_goods{type_id = NewConsumeGoods, num = NewNum}]), ?ITEM_REDUCE_NATURE_REFINE),
    mod_role_dict:add_background_logs(LogList),
    {ko, NexLevel, NewConsumeMoney, State4}.

%% @doc 分解
do_nature_goods_refine(RoleID, RuneIDs, State) ->
    case catch check_nature_goods_refine(RuneIDs, State) of
        {ok, Tally, BagDoing, State1} ->
            DataRecord = #m_role_nature_goods_refine_toc{},
            common_misc:unicast(RoleID, DataRecord),
            State2 = mod_role_bag:do(BagDoing, State1),
            FuncList = [
                fun(StateAcc) -> mod_role_day_target:refine_nat_intensify(Tally, StateAcc) end
            ],
            role_server:execute_state_fun(FuncList, State2);
        {error, ErrCode} ->
            DataRecord = #m_role_nature_goods_refine_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_nature_goods_refine(RuneIDs, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{} = RoleNature,
    ?IF(RuneIDs =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    {Tally, GoodsLists} =
        lists:foldl(fun(GoodsID, {AccNum, Acc}) ->
            {ok, #p_goods{type_id = TypeID, num = Num} = Goods} = mod_role_bag:check_bag_by_id(GoodsID, State),
            #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
            case lists:keytake(TypeID, #p_goods.type_id, Acc) of
                {value, #p_goods{num = Count} = NewGoods, TupleList2} ->
                    {AccNum + (Num * lib_tool:to_integer(EffectArgs)), [NewGoods#p_goods{num = Count + Num} | TupleList2]};
                _ ->
                    {AccNum + (Num * lib_tool:to_integer(EffectArgs)), [Goods | Acc]}
            end end, {0, []}, RuneIDs),

    BagDoing = [{decrease, ?ITEM_REDUCE_NATURE_RESOLVE, [#r_goods_decrease_info{type_id = TypeID, num = Num} || #p_goods{type_id = TypeID, num = Num} <- GoodsLists]},
        {create, ?ITEM_GAIN_NATURE_RESOLVE, [#p_goods{type_id = ?BAG_NAT_INTENSIFY_GOODS, num = Tally}]}],
    {ok, Tally, BagDoing, State}.


%% @doc 设置品质
do_nature_opt(RoleID, Quality, Star, State) ->
    case check_nature_opt(Quality, Star, State) of
        {ok, State2} ->
            DataRecord = #m_role_nature_opt_toc{quality = Quality, star = Star},
            common_misc:unicast(RoleID, DataRecord),
            State2;
        {error, ErrCode} ->
            DataRecord = #m_role_nature_opt_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_nature_opt(Quality, Star, State) ->
    mod_role_function:is_function_open(?FUNCTION_NATURE, State),
    #r_role{role_nature = RoleNature} = State,
    #r_role_nature{} = RoleNature,

    ?IF(is_integer(Quality), ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    [{_MaxID, #c_nature_seal{quality = MaxQuality}} | _] =
        lists:sort(fun({_ID1, #c_nature_seal{quality = Quality1}}, {_ID2, #c_nature_seal{quality = Quality2}}) ->
            Quality1 > Quality2 end, cfg_nature_seal:list()),

    ?IF(MaxQuality >= Quality, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    State2 = State#r_role{role_nature = RoleNature#r_role_nature{quality = Quality, star = Star}},
    {ok, up_role_info(State2)}.

do_nature_compose(RoleID, ComposeID, State) ->
    case catch check_nature_compose(ComposeID, State) of
        {ok, BagDoings} ->
            common_misc:unicast(RoleID, #m_role_nature_compose_toc{}),
            mod_role_bag:do(BagDoings, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_nature_compose_toc{err_code = ErrCode}),
            State
end.

check_nature_compose(TypeID, State) ->
    mod_role_function:is_function_open(?FUNCTION_EQUIP_COMPOSE, State),
    Config =
        case lib_config:find(cfg_nature_compose, TypeID) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    mod_role_bag:check_bag_empty_grid(?BAG_ID_NATURE, 1, State),
    #c_nature_compose{need_num = NeedNum, need_type_id = NeedTypeID} = Config,
    ?IF(NeedNum > 0, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
    BagDoings = mod_role_bag:check_num_by_type_id(NeedTypeID, NeedNum, ?ITEM_REDUCE_NATURE_COMPOSE, State),
    BagDoings2 = BagDoings ++ [{create, ?ITEM_GAIN_NATURE_COMPOSE, [#p_goods{type_id = TypeID, num = 1}]}],
    {ok, BagDoings2}.


to_p_nature_place(#r_nature{
    aperture_id = ApertureID,
    type = Type,
    refine_id = RefineID,
    goods = Goods}) ->

    case RefineID > 0 of
        true ->
            #c_nature_intensify{level = Level} = get_nature_intensify(RefineID);
        _ ->
            Level = 0
    end,

    #p_nature_place{
        aperture_id = ApertureID,
        nature = Goods,
        type = Type,
        refine = Level}.

up_role_info(State) ->
    role_server:dump_table(?DB_ROLE_NATURE_P, State).
get_role_info(RoleID) ->
    case db:lookup(?DB_ROLE_NATURE_P, RoleID) of
        [#r_role_nature{} = RoleNature] ->
            RoleNature;
        _ ->
            #r_role_nature{role_id = RoleID}
    end.

%% 获取天机印总强化等级
get_nature_refine_level(State) ->
    #r_role{role_nature = #r_role_nature{nature = NatureList}} = State,
    get_nature_refine_level2(NatureList, 0).

get_nature_refine_level2([], LevelAcc) ->
    LevelAcc;
get_nature_refine_level2([Nature|R], LevelAcc) ->
    #r_nature{refine_id = RefineID} = Nature,
    Level =
        case RefineID > 0 of
            true ->
                #c_nature_intensify{level = LevelT} = get_nature_intensify(RefineID),
                LevelT;
            _ ->
                0
        end,
    get_nature_refine_level2(R, LevelAcc + Level).

%% 获取天机印镶嵌孔数
get_nature_hole_num(State) ->
    #r_role{role_nature = #r_role_nature{nature = NatureList}} = State,
    get_nature_hole_num2(NatureList, 0).

get_nature_hole_num2([], NumAcc) ->
    NumAcc;
get_nature_hole_num2([Nature|R], NumAcc) ->
    #r_nature{goods = Goods} = Nature,
    NumAcc2 = erlang:length(Goods) + NumAcc,
    get_nature_hole_num2(R, NumAcc2).

get_color_num(NeedQuality, State) ->
    #r_role{role_nature = #r_role_nature{nature = NatureList}} = State,
    get_color_num2(NatureList, NeedQuality, 0).

get_color_num2([], _NeedQuality, NumAcc) ->
    NumAcc;
get_color_num2([Nature|R], NeedQuality, NumAcc) ->
    #r_nature{goods = Goods} = Nature,
    NumAcc2 =
        case Goods of
            [#p_goods{type_id = TypeID}|_] ->
                #c_nature_seal{quality = Quality} = get_nature_seal(TypeID),
                ?IF(Quality >= NeedQuality, NumAcc + 1, NumAcc);
            _ ->
                NumAcc
        end,
    get_color_num2(R, NeedQuality, NumAcc2).

get_refine_level_num(NeedLevel, State) ->
    #r_role{role_nature = #r_role_nature{nature = NatureList}} = State,
    get_refine_level_num2(NatureList, NeedLevel, 0).

get_refine_level_num2([], _NeedLevel, NumAcc) ->
    NumAcc;
get_refine_level_num2([Nature|R], NeedLevel, NumAcc) ->
    #r_nature{refine_id = RefineID} = Nature,
    NumAcc2 =
        case RefineID > 0 of
            true ->
                #c_nature_intensify{level = Level} = get_nature_intensify(RefineID),
                ?IF(Level >= NeedLevel, NumAcc + 1, NumAcc);
            _ ->
                NumAcc
        end,
    get_refine_level_num2(R, NeedLevel, NumAcc2).

%% @doc 天机印强化表
get_nature_intensify(Key) ->
    [Config] = lib_config:find(cfg_new_nature_intensify, Key),
    Config.

%% @doc 天机印开孔表
get_nature_hole(ID) ->
    [Config] = lib_config:find(cfg_nature_hole, ID),
    Config.

%% @doc 天机印属性表
get_nature_seal(ID) ->
    [Config] = lib_config:find(cfg_nature_seal, ID),
    Config.

%% @doc 天机印套装表
get_nature_suit(ID) ->
    [Config] = lib_config:find(cfg_nature_suit, ID),
    Config.

