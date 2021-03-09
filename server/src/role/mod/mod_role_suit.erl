%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 套装系统
%%% @end
%%% Created : 08. 五月 2019 15:24
%%%-------------------------------------------------------------------
-module(mod_role_suit).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("suit.hrl").
-include("proto/mod_role_suit.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,                 %% role初始化
    calc/1,                 %% 属性统计
    online/1                %% 上线
]).

-export([handle/2]).

-export([
    del/1,
    del/2,
    send/2,
    do_fun/2,
    level_up/3,
    calc_attr/4,
    string_to_intlist/3,
    string_to_tuple/3,
    integration_suit/3
]).

-export([
    get_thunder_active_num/1,
    get_thunder_gradation_num/2
]).

del(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, del}).
del(RoleID, PlaceID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {del, PlaceID}}).
send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, Msg}).
do_fun(RoleID, Fun) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {func, Fun}}).

init(#r_role{role_id = RoleID, role_suit = undefined} = State) ->
    RoleSuit = #r_role_suit{role_id = RoleID},
    State#r_role{role_suit = RoleSuit};
init(State) ->
    State.

online(State) ->
    send_suit_info(State),
    State.

calc(State) ->
    #r_role{role_suit = RoleSuit} = State,
    #r_role_suit{suit_list = SuitList} = RoleSuit,
    CalcAttr1 = calc_place_attr(SuitList),
    CalcAttr2 = calc_suit_attr(SuitList),
    CalAttr = common_misc:sum_calc_attr2(CalcAttr1, CalcAttr2),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_SUIT, CalAttr).

%% @doc 部位属性
calc_place_attr(SuitList) ->
    calc_place_attr(SuitList, #actor_cal_attr{}).
calc_place_attr([], AccAttr) ->
    AccAttr;
calc_place_attr([#p_suit{place = PlaceLs}|RetSuitList], AccAttr) ->
    AccKV =
    lists:foldl(       fun(PlaceID, Acc) ->
        #c_suit_star{attr = Attr} = get_suit_star_config(PlaceID),
        KV = common_misc:get_string_props(Attr),
        KV ++ Acc end, [], PlaceLs),
    CalcAttr = common_misc:get_attr_by_kv(AccKV),
    Attr = common_misc:sum_calc_attr2(CalcAttr, AccAttr),
    calc_place_attr(RetSuitList, Attr).

%% @doc 套装属性
calc_suit_attr(SuitList) ->
    calc_suit_attr(SuitList, #actor_cal_attr{}).
calc_suit_attr([], AccAttr) ->
    AccAttr;
calc_suit_attr([#p_suit{place = Place}|SuitList], AccAttr) ->
    SuitLists =
    lists:foldl( fun(PlaceID, Acc) ->
        #c_suit_star{suit_id = SuitID} = get_suit_star_config(PlaceID),
        case lists:keytake(SuitID, 1, Acc) of
            {value, {SuitID, Num}, TupleList2} ->
                [{SuitID, Num + 1}|TupleList2];
            _ ->
                [{SuitID, 1}|Acc]
        end end, [], Place),
    AccKV =
    lists:foldl(            fun({SuitID, Count}, Acc) ->
        #c_suit{attr = Attr} = get_suit_config(SuitID),
        StringTuple = string_to_tuple(Attr, ";", ":"),
        KVLists =
        lists:foldl( fun({ID, String}, AccKV) ->
            case Count >= ID of
                true ->
                    KV = common_misc:get_string_props(String),
                    KV ++ AccKV;
                _ ->
                    AccKV
            end end, [], StringTuple),
        KVLists ++ Acc end, [], SuitLists),
    CalcAttr = common_misc:get_attr_by_kv(AccKV),
    Attr = common_misc:sum_calc_attr2(CalcAttr, AccAttr),
    calc_suit_attr(SuitList, Attr).

calc_attr(PlaceLsNum, PlaceNumList, AttrString, AccAttr) ->
    PlaceNum = get_piece_num(PlaceLsNum, PlaceNumList),
    Index = lib_tool:get_lists_index(PlaceNumList, PlaceNum, 1),
    String = lists:nth(Index, string:tokens(AttrString, ";")),
    CalcAttr = common_misc:get_attr_by_kv(common_misc:get_string_props(String)),
    common_misc:sum_calc_attr2(CalcAttr, AccAttr).

%% @doc 获取件数
get_piece_num(PlaceNum, PlaceNumLists) ->
    MaxPlaceNum = lists:max(PlaceNumLists),
    lib_tool:foldl(fun(Num, AccNum) ->
        if
            MaxPlaceNum =< PlaceNum ->
                {return, MaxPlaceNum};
            Num =< PlaceNum ->
                Num;
            true ->
                AccNum
        end end,   0, PlaceNumLists).


%% @doc 角色升级
%% 要在hook_role模块里添加才生效
level_up(State, _OldLevel, _NewLevel) ->
    State.

handle({#m_suit_upgrade_star_tos{place_id = PlaceID}, _RoleID, _PID}, State) ->
    do_suit_upgrade_star(PlaceID, State);

handle({#m_suit_resolve_tos{place_id = PlaceID}, RoleID, _PID}, State) ->
    do_suit_resolve(PlaceID, RoleID, State);

handle(del, State) ->
    do_del(State);

handle({del, PlaceID}, State) ->
    do_del(PlaceID, State);

handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.


%% ====================================================
%%  fun
%% ====================================================

do_del(#r_role{role_id = RoleID} = State) ->
    RoleSuit = #r_role_suit{role_id = RoleID},
    State#r_role{role_suit = RoleSuit}.

do_del(PlaceID, #r_role{role_suit = RoleSuit} = State) ->
    #r_role_suit{suit_list = SuitList} = RoleSuit,
    NewSuitList = del_place(PlaceID, SuitList),
    State#r_role{role_suit = RoleSuit#r_role_suit{suit_list = NewSuitList}}.

%% @doc 发送套装信息
send_suit_info(State) ->
    #r_role{role_id = RoleID, role_suit = RoleSuit} = State,
    RoleSuit = #r_role_suit{suit_list = SuitList} = RoleSuit,
    common_misc:unicast(RoleID, #m_suit_info_toc{suit_info = SuitList}).

%% @doc 升级和激活部位星级
%% PlaceID：部位id
do_suit_upgrade_star(PlaceID, #r_role{role_id = RoleID} = State) ->
    case catch check_suit_upgrade_star(PlaceID, State) of
        {ok, NewPlaceID, State2, SubType, Type, PlaceList ,  Gradation} ->
            Msg = #m_suit_upgrade_star_toc{place_id = NewPlaceID},
            common_misc:unicast(RoleID, Msg),
            State3 = do_suit_upgrade_trigger(SubType, Type, PlaceList, Gradation, State2);
        {error, ErrCode} ->
            State3 = State,
            common_misc:unicast(RoleID, #m_suit_upgrade_star_toc{err_code = ErrCode})
    end,
    State3.

do_suit_upgrade_trigger(SubType, Type, PlaceList, Step, State) ->
    NumStepList = get_step_list(PlaceList, Step, []),
    FuncList = [
        fun(StateAcc) -> mod_role_confine:pos_suit(StateAcc, SubType, Type, NumStepList) end,
        fun(StateAcc) -> mod_role_achievement:pos_suit(SubType, Type, NumStepList, StateAcc) end,
        fun(StateAcc) -> mod_role_god_book:pos_suit(SubType, Type, NumStepList, StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:suit_up(StateAcc) end,
        fun(StateAcc) ->
            case Type of
                ?BIG_TYPE_THUNDER ->
                    StateAcc2 = mod_role_day_target:thunder_active(StateAcc),
                    mod_role_day_target:thunder_step(StateAcc2);
                _ ->
                    StateAcc
            end
        end
    ],
    role_server:execute_state_fun(FuncList, State).

get_step_list(_PlaceList, Step, List) when Step < 0 ->
    List;
get_step_list(PlaceList, Step, List) ->
    Num = get_step_list_i(PlaceList, Step, 0),
    get_step_list(PlaceList, Step - 1, [{Num, Step}|List]).

get_step_list_i([], _Step,Num) ->
    Num;
get_step_list_i([PlaceID|T], Step,Num) ->
    [#c_suit_star{gradation = Gradation}] = lib_config:find(cfg_suit_star, PlaceID),
    case Gradation >= Step of
        true ->
            get_step_list_i(T, Step,Num + 1);
        _ ->
            get_step_list_i(T, Step,Num)
    end.

%% @doc 分解
do_suit_resolve(PlaceID, RoleID, State) ->
    case catch check_suit_resolve(PlaceID, State) of
        {ok, NewPlaceID, State2} ->
            Msg = #m_suit_resolve_toc{place_id = NewPlaceID},
            common_misc:unicast(RoleID, Msg);
        {error, ErrCode} ->
            State2 = State,
            common_misc:unicast(RoleID, #m_suit_resolve_toc{err_code = ErrCode})
    end,
    State2.

%% @doc 检测升级和激活部位
%% 5：消耗道具
check_suit_upgrade_star(PlaceID, #r_role{role_suit = RoleSuit} = State) ->
    mod_role_function:is_function_open(?FUNCTION_SUIT, State),
    ?IF(lib_config:find(cfg_suit_star, PlaceID) =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    #r_role_suit{suit_list = SuitList} = RoleSuit,
    #c_suit_star{type = Type, subtype = SubType, gradation = Gradation, place = OldPlace, property = Property, next_id = NextID} = get_suit_star_config(PlaceID),

    #p_suit{place = Place} = Suit = integration_suit(Type, SubType, SuitList),
    ?IF(Gradation =:= ?MIN_GRADATION orelse lists:member(PlaceID, Place), ok, ?THROW_ERR(?ERROR_SUIT_UPGRADE_STAR_001)),
%%    ?IF((Gradation =:= ?MIN_GRADATION andalso length(Place) < ?PLACE_NUMBER) orelse length(Place) =:= ?PLACE_NUMBER, ok, ?THROW_ERR(?ERROR_COMMON_ROLE_DATA_ERROR)),

    ?IF(lists:member(NextID, Place), ?THROW_ERR(?ERROR_SUIT_UPGRADE_STAR_006), ok),
    Config = lib_config:find(cfg_suit_star, NextID),
    ?IF(Config =/= [], ok, ?THROW_ERR(?ERROR_SUIT_UPGRADE_STAR_002)),
    [#c_suit_star{place_id = NewPlaceID, place = NewPlace, gradation = NewGradation, property = NewProperty, type = NewType, subtype = NewSubType}] = Config,
    ?IF(OldPlace =:= NewPlace andalso Type =:= NewType andalso NewSubType =:= SubType, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
    ?IF(NewGradation - Gradation =:= 1, ok, ?THROW_ERR(?ERROR_SUIT_UPGRADE_STAR_005)),

    RetSuit = SuitList -- [Suit],
    if
        Gradation =:= ?MIN_GRADATION ->
            NewPlaceList = [NewPlaceID|Place],
            SuitListNow = [Suit#p_suit{place = NewPlaceList}|RetSuit];
        true ->
            NewPlaceList = [NewPlaceID|lists:delete(PlaceID, Place)],
            SuitListNow = [Suit#p_suit{place = NewPlaceList}|RetSuit]
    end,

    ItemList = string_to_intlist(Property, "|", ","),
    NowItemList = string_to_intlist(NewProperty, "|", ","),
    DecreaseList =
    lists:foldl( fun({GoodsId, Count}, Acc) ->
        case lists:keyfind(GoodsId, 1, ItemList) of
            {GoodsId, Num} ->
                [{GoodsId, erlang:max(0, Count - Num)}|Acc];
            _ ->
                [{GoodsId, Count}|Acc]
        end end, [], NowItemList),

    % 5
    BagDoing = mod_role_bag:check_num_by_item_list(DecreaseList, ?ITEM_REDUCE_SUIT_STAR, State),
    State2 = ?IF(BagDoing =:= [], State, mod_role_bag:do(BagDoing, State)),
    State3 = State2#r_role{role_suit = RoleSuit#r_role_suit{suit_list = SuitListNow}},

    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_SUIT_PLACE, PlaceID),
    {ok, NewPlaceID, State4, SubType, Type, NewPlaceList,NewGradation}.

check_suit_resolve(PlaceID, #r_role{role_suit = RoleSuit} = State) ->
    mod_role_function:is_function_open(?FUNCTION_SUIT, State),
    ?IF(lib_config:find(cfg_suit_star, PlaceID) =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role_suit{suit_list = SuitList} = RoleSuit,
    #c_suit_star{type = Type, subtype = SubType, restoration = Restoration} = get_suit_star_config(PlaceID),
    #p_suit{place = Place} = Suit = integration_suit(Type, SubType, SuitList),
    ?IF(lists:member(PlaceID, Place), ok, ?THROW_ERR(?ERROR_SUIT_RESOLVE_001)),

    RetSuit = SuitList -- [Suit],
    case lists:delete(PlaceID, Place) of
        [_|_] = RetPlace ->
            SuitListNow = [Suit#p_suit{place = RetPlace}|RetSuit];
        [] ->
            SuitListNow = RetSuit;
        _ ->
            SuitListNow = ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
    end,

    State2 = State#r_role{role_suit = RoleSuit#r_role_suit{suit_list = SuitListNow}},

    ItemList = string_to_intlist(Restoration, ";", ","),
    Goods = get_goods(ItemList, []),
    mod_role_bag:check_bag_empty_grid(Goods, State2),
    BagDoing = [{create, ?ITEM_GAIN_SUIT_RETURN, Goods}],
    State3 = mod_role_bag:do(BagDoing, State2),

    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_SUIT_RESOLVE, PlaceID),
    {ok, PlaceID, State4}.

%% @doc 获取类型 套装
integration_suit(Type, Subtype, []) ->
    #p_suit{type = Type, subtype = Subtype};
integration_suit(Type, Subtype, [#p_suit{type = Type, subtype = Subtype} = Suit|_SuitList]) ->
    Suit;
integration_suit(Type, Subtype, [_Suit|SuitList]) ->
    integration_suit(Type, Subtype, SuitList).

get_goods([], List) ->
    List;
get_goods([{TypeID, Num}|T], List) ->
    Goods = #p_goods{type_id = TypeID, num = Num},
    get_goods(T, [Goods|List]).

%% @doc 分割
string_to_intlist(SL, Split1, Split2) ->
    SList = string:tokens(SL, Split1),
    F = fun(X, AccL) ->
        [ID, Num] = string:tokens(X, Split2),
        [{lib_tool:to_integer(ID), lib_tool:to_integer(Num)}|AccL]
        end,
    lists:foldr(F, [], SList).
string_to_tuple(SL, Split1, Split2) ->
    SList = string:tokens(SL, Split1),
    F = fun(X, AccL) ->
        [ID, String] = string:tokens(X, Split2),
        [{lib_tool:to_integer(ID), String}|AccL]
        end,
    lists:foldr(F, [], SList).

del_place(PlaceID, SuitList) ->
    del_place(SuitList, PlaceID, []).
del_place([], _PlaceID, Acc) ->
    Acc;
del_place([#p_suit{place = Place} = Suit|SuitList], PlaceID, Acc) ->
    del_place(SuitList, PlaceID, [Suit#p_suit{place = lists:delete(PlaceID, Place)}|Acc]).

get_thunder_active_num(State) ->
    #r_role{role_suit = #r_role_suit{suit_list = SuitList}} = State,
    get_thunder_active_num2(SuitList, 0).

get_thunder_active_num2([], NumAcc) ->
    NumAcc;
get_thunder_active_num2([#p_suit{type = Type, place = Places}|R], NumAcc) ->
    NumAcc2 = ?IF(Type =:= ?BIG_TYPE_THUNDER, NumAcc + erlang:length(Places), NumAcc),
    get_thunder_active_num2(R, NumAcc2).

get_thunder_gradation_num(Gradation, State) ->
    #r_role{role_suit = #r_role_suit{suit_list = SuitList}} = State,
    get_thunder_gradation_num2(SuitList, Gradation, 0).

get_thunder_gradation_num2([], _Gradation, NumAcc) ->
    NumAcc;
get_thunder_gradation_num2([#p_suit{type = Type, place = Places}|R], Gradation, NumAcc) ->
    NumAcc2 = ?IF(Type =:= ?BIG_TYPE_THUNDER, NumAcc + get_thunder_gradation_num3(Places, Gradation, 0), NumAcc),
    get_thunder_gradation_num2(R, Gradation, NumAcc2).

get_thunder_gradation_num3([], _NeedGradation, NumAcc) ->
    NumAcc;
get_thunder_gradation_num3([PlaceID|R], NeedGradation, NumAcc) ->
    #c_suit_star{gradation = ConfigGradation} = get_suit_star_config(PlaceID),
    NumAcc2 = ?IF(ConfigGradation >= NeedGradation, NumAcc + 1, NumAcc),
    get_thunder_gradation_num3(R, NeedGradation, NumAcc2).

%% @doc 套装属性表
get_suit_config(ID) ->
    [Config] = lib_config:find(cfg_suit, ID),
    Config.

%% @doc 套装升星表
get_suit_star_config(ID) ->
    [Config] = lib_config:find(cfg_suit_star, ID),
    Config.