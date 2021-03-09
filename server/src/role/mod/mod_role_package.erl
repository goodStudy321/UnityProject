%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 三月 2018 10:13
%%%-------------------------------------------------------------------
-module(mod_role_package).
-author("WZP").
-include("role.hrl").
-include("global.hrl").
-include("family.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    use_package/4,
    family_use_package/2,
    use_mythical_package/5,
    get_package_goods/2
]).

-export([
    string_to_intlist/1
]).

%%Num一般为1,以后有改动再改动
use_package(Goods, EffectArgs, Num, State) ->
    case EffectArgs =/= [] of
        true ->
            case catch lib_tool:string_to_integer_list(EffectArgs) of
                [Gold] when Gold > 0 andalso erlang:is_integer(Gold) -> %% 礼包只配置一个价格
                    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Gold * Num, ?ASSET_GOLD_REDUCE_FROM_USE_PACKAGE, State),
                    State2 = mod_role_asset:do(AssetDoing, State),
                    use_package2(Goods, Num, State2);
                [_OldGold, Gold] when Gold > 0 andalso erlang:is_integer(Gold) -> %% 礼包配置原价、现价
                    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Gold * Num, ?ASSET_GOLD_REDUCE_FROM_USE_PACKAGE, State),
                    State2 = mod_role_asset:do(AssetDoing, State),
                    use_package2(Goods, Num, State2);
                true ->
                    erlang:throw(unkonw_package_args)
            end;
        _ ->
            use_package2(Goods, Num, State)
    end.

use_package2(Goods, Num, State) ->
    #p_goods{type_id = TypeID} = Goods,
    #c_package{need_grid = NeeGrid, min_multi = MinMulti, max_multi = MaxMulti} = Config = get_package_config(TypeID),
    Multi = get_multi(MinMulti, MaxMulti),
    ?IF(mod_role_bag:check_bag_empty_grid(NeeGrid, State), ok, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)),
    {CreateList, State2} = get_package_goods(Config, Num, Multi, State),
    role_misc:create_goods(State2, ?ITEM_GAIN_PACKAGE, CreateList).


family_use_package(BoxList, #r_role{role_attr = RoleAttr, role_id = RoleID} = State) ->
    {CreateList2, GoodsList, ColorList, LogList, State2} = lists:foldl(
        fun(#p_family_box{id = TypeID, type = BoxFrom, param = BoxFromValue}, {AccGood, AccList, ColorList, AccLog, StateAcc}) ->
            #c_package{min_multi = MinMulti, max_multi = MaxMulti} = Config = get_package_config(TypeID),
            Multi = get_multi(MinMulti, MaxMulti),
            {CreateList, StateAcc2} = get_package_goods(Config, 1, Multi, StateAcc),
            [Good|_] = CreateList,
            ColorList2 = get_color_list(ColorList, TypeID),
            Log = #log_role_family_box{role_id = RoleID, type = 1, box_type = TypeID, box_from = BoxFrom, box_from_value = BoxFromValue, open_item = Good#p_goods.type_id, open_item_num = Good#p_goods.num},
            {AccGood ++ CreateList, [Good|AccList], ColorList2, [Log|AccLog], StateAcc2}
        end, {[], [], [{Color, 0} || Color <- lists:seq(1, 6)], [], State}, BoxList),
    [begin
         case lib_config:find(cfg_box_notice, TypeID) of
             [NoticeConfig] ->
                 case NoticeConfig#c_box_notice.num =< ItemNum of
                     false ->
                         ok;
                     _ ->
                         BcInfo = #m_common_notice_toc{id = ?NOTICE_FAMILY_BOX, text_string = [lib_tool:to_list(RoleID), lib_tool:to_list(RoleAttr#r_role_attr.role_name), lib_tool:to_list(ItemNum)],
                                                       goods_list = [#p_goods{num = ItemNum, type_id = TypeID}]},
                         common_broadcast:bc_record_to_family(RoleAttr#r_role_attr.family_id, BcInfo)
                 end;
             _ ->
                 ok
         end
     end || #p_goods{num = ItemNum, type_id = TypeID} <- CreateList2],
    mod_role_dict:add_background_logs(LogList),
    State3 = role_misc:create_goods(State2, ?ITEM_GAIN_FAMILY_BOX, CreateList2),
    State4 = mod_role_confine:open_box(State3, ColorList),
    {ok, State4, GoodsList, BoxList}.

get_color_list(ColorList, TypeID) ->
    [Config] = lib_config:find(cfg_item, TypeID),
    get_color_list_i(ColorList, Config#c_item.quality, []).

get_color_list_i([], _Color, List) ->
    List;
get_color_list_i([{ColorType, Num}|T], Color, List) ->
    case Color =:= ColorType of
        true ->
            get_color_list_i(T, Color, [{ColorType, Num + 1}|List]);
        _ ->
            get_color_list_i(T, Color, [{ColorType, Num}|List])
    end.


%% 使用魂兽礼包
use_mythical_package(Goods, EffectType, _EffectArgs, Num, State) ->
    #p_goods{type_id = TypeID} = Goods,
    #c_package{need_grid = NeeGrid, min_multi = MinMulti, max_multi = MaxMulti} = Config = get_package_config(TypeID),
    Multi = get_multi(MinMulti, MaxMulti),
    ?IF(mod_role_mythical_equip:is_bag_full(NeeGrid, State), ?THROW_ERR(?ERROR_COMMON_BAG_FULL), ok),
    State2 = mod_role_world_boss:check_package_times(EffectType, Num, State),
    {CreateList, State3} = get_package_goods(Config, Num, Multi, State2),
    mod_role_bag:do([{create, ?ITEM_GAIN_PACKAGE, CreateList}], State3).


get_package_goods(TypeID, State) ->
    #c_package{min_multi = MinMulti, max_multi = MaxMulti} = Config = get_package_config(TypeID),
    get_package_goods(Config, 1, get_multi(MinMulti, MaxMulti), State).

get_package_goods(Config, ItemNum, Multi, State) ->
    #c_package{fixed_drop = FixedDrop} = Config,
    FixedLs = string_to_intlist(FixedDrop),
    FixedGoods = lists:flatten(lists:duplicate(ItemNum, FixedLs)),
    {RandomGoods, State2} = get_package_random_goods(Config, ItemNum, Multi, State),
    {FixedGoods ++ RandomGoods, State2}.

%% 随机获得奖励，有保底
get_package_random_goods(Config, ItemNum, Multi, State) ->
    #c_package{package_id = PackageID, item1 = Item1, item2 = Item2, item3 = Item3, item4 = Item4, item5 = Item5,
        floor_item = FloorItem, item6 = Item6, item7 = Item7, item8 = Item8, item9 = Item9, item10 = Item10} = Config,
    List = [Item1, Item2, Item3, Item4, Item5, Item6, Item7, Item8, Item9, Item10],
    case FloorItem =:= [] of
        true ->
            {lists:flatten([get_random_goods(List, []) || _Times <- lists:seq(1, ItemNum * Multi)]), State};
        _ -> %% 查看保底
            PackageFloorList = mod_role_extra:get_data(?EXTRA_KEY_PACKAGE_FLOOR, [], State),
            OpenNum =
                case lists:keyfind(PackageID, 1, PackageFloorList) of
                    {_, OpenNumT} ->
                        OpenNumT;
                    _ ->
                        0
                end,
            {NeedOpenNum, ItemList} = get_floor_item_args(FloorItem),
            {GoodsList, OpenNum2} =
                lists:foldl(
                    fun(_Index, {GoodsAcc, OpenNumAcc}) ->
                        AddGoods = lists:flatten([get_random_goods(List, []) || _Times <- lists:seq(1, Multi)]),
                        case is_get_floor_goods(ItemList, AddGoods) of
                            true -> %% 这次开的物品里，有保底奖励
                                {AddGoods ++ GoodsAcc, 0};
                            _ ->
                                case OpenNumAcc + 1 >= NeedOpenNum of
                                    true -> %% 可以保底
                                        {common_misc:get_reward_p_goods(ItemList) ++ GoodsAcc, 0};
                                    _ ->
                                        {AddGoods ++ GoodsAcc, OpenNumAcc + 1}
                                end
                        end
                    end, {[], OpenNum}, lists:seq(1, ItemNum)),
            PackageFloorList2 = lists:keystore(PackageID, 1, PackageFloorList, {PackageID, OpenNum2}),
            State2 = mod_role_extra:set_data(?EXTRA_KEY_PACKAGE_FLOOR, PackageFloorList2, State),
            {GoodsList, State2}
    end.

is_get_floor_goods([], _AddGoods) ->
    false;
is_get_floor_goods([Item|R], AddGoods) ->
    case lists:keyfind(erlang:element(1, Item), #p_goods.type_id, AddGoods) of
        #p_goods{} ->
            true;
        _ ->
            is_get_floor_goods(R, AddGoods)
    end.

%%进行随机返回礼包开启得到物品
get_random_goods([], List) ->
    List;
get_random_goods([Item|_H], List) when Item =:= [] ->
    List;
get_random_goods([Item|H], List) ->
    {Probability, WeightList} = string_to_intlist(Item),
    Num = lib_tool:random(?RATE_1000000),
    case Num =< Probability of
        true ->
            {ItemId, ItemNum, Bind} = lib_tool:get_weight_output(WeightList),
            Goods = #p_goods{type_id = ItemId, num = ItemNum, bind = ?IS_BIND(Bind)},
            get_random_goods(H, [Goods|List]);
        _ ->
            get_random_goods(H, List)
    end.

get_package_config(ID) ->
    [Config] = lib_config:find(cfg_package, ID),
    Config.

get_multi(MinMulti, MaxMulti) ->
    if
        MinMulti =:= 0 andalso MaxMulti =:= 0 ->
            1;
        MinMulti =:= 0 ->
            MaxMulti;
        MaxMulti =:= 0 ->
            MinMulti;
        true ->
            lib_tool:random(MinMulti, MaxMulti)
    end.

%% 概率|物品ID，数量,权重；物品ID，数量,权重  拆分为{概率 ， List}  List = [ {{物品ID,数量} ,权重 },{{物品ID,数量} ,权重 },{{物品ID,数量} ,权重 }]
string_to_intlist(SL) ->
    case string:str(SL, "|") of
        0 when SL =/= "" ->
            string_to_intlist(SL, ";", ",");
        0 ->
            [];
        _ ->
            string_to_intlist(SL, "|", ";", ",")
    end.

%% 根据Split1, Split2拆分字符串成单个列表
string_to_intlist(SL, Split1, Split2, Split3) ->
    [Probability, SList] = string:tokens(SL, Split1),
    SList1 = string:tokens(SList, Split2),
    F = fun(X, L) ->
        [ID, Num, Bind, Weight] = string:tokens(X, Split3),
        [{lib_tool:to_integer(Weight), {lib_tool:to_integer(ID), lib_tool:to_integer(Num), lib_tool:to_integer(Bind)}}|L]
        end,
    WeightList = lists:foldr(F, [], SList1),
    {lib_tool:to_integer(Probability), WeightList}.

%% @doc 固定掉落使用
%% 物品id，数量，是否绑定；物品id，数量，是否绑定
string_to_intlist(SL, Split1, Split2) ->
    SList = string:tokens(SL, Split1),
    F = fun(X, AccL) ->
        [ID, Num, Bind] = string:tokens(X, Split2),
        [#p_goods{type_id = lib_tool:to_integer(ID), num = lib_tool:to_integer(Num), bind = ?IS_BIND(Bind)}|AccL]
        end,
    lists:foldr(F, [], SList).


get_floor_item_args(FloorItem) ->
    [NeedOpenNum, String] = string:tokens(FloorItem, "|"),
    {lib_tool:to_integer(NeedOpenNum), lib_tool:string_to_intlist(String)}.
