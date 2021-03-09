%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 六月 2017 16:41
%%%-------------------------------------------------------------------
-module(mod_role_item).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_role_bag.hrl").

%% API
-export([
    handle/2
]).

-export([
    is_item_notice/1,
    get_item_config/1,
    get_item_config/2
]).

-export([
    check_common_use/2
]).

-export([
    gm_overdue_item/2
]).

handle({#m_item_use_tos{type = Type, id = ID, num = Num}, RoleID, _PID}, State) ->  % T 物品使用通用接口
    do_item_use(RoleID, Type, ID, Num, State);
handle({#m_item_sell_tos{item_list = ItemList}, RoleID, _PID}, State) ->    % T 物品售卖通用接口
    do_item_sell(RoleID, State, ItemList).

do_item_use(RoleID, Type, ID, Num, State) ->
    case catch check_can_use(Type, ID, Num, State) of
        {ok, BagDoings, Goods, ItemConfig} ->
            case catch do_item_effect(Goods, ItemConfig, Num, State) of
                #r_role{} = State2 ->
                    common_misc:unicast(RoleID, #m_item_use_toc{type_id = Goods#p_goods.type_id}),
                    State3 = mod_role_bag:do(BagDoings, State2),
                    use_item_trigger(ItemConfig, Num, State3);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_item_use_toc{err_code = ErrCode}),
                    State
            end;
        {error, ?ERROR_ITEM_USE_001} ->
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_item_use_toc{err_code = ErrCode}),
            State
    end.

use_item_trigger(ItemConfig, Num, State) ->
    #c_item{type_id = TypeID} = ItemConfig,
    FunList = [
        fun(StateAcc) -> mod_role_achievement:use_skin_item(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:use_item(TypeID, Num, StateAcc) end
    ],
    role_server:execute_state_fun(FunList, State).

check_can_use(?ITEM_USE_TYPE_ID, TypeID, Num, State) ->
    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #c_item{cover_num = CoverNum} = ItemConfig = check_common_use(TypeID, State),
    {BagDoings, Goods} =
    case ?IS_ITEM_COVER(CoverNum) orelse Num > 1 of
        true -> %% 道具可以叠加，或者使用超过1个
            BagDoingsT = mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_ITEM_USE, State),
            GoodsT = #p_goods{type_id = TypeID, num = Num},
            {BagDoingsT, GoodsT};
        _ -> %% 部分道具类型，不叠加道具使用，要注意要用原有的数据
            case mod_role_bag:get_goods_by_type_id(TypeID, State) of
                #p_goods{} = GoodsT ->
                    check_common_goods(GoodsT),
                    {[{decrease, ?ITEM_REDUCE_ITEM_USE, [#r_goods_decrease_info{id = GoodsT#p_goods.id, num = GoodsT#p_goods.num}]}], GoodsT};
                _ ->
                    ?THROW_ERR(?ERROR_ITEM_USE_001)
            end
    end,
    {ok, BagDoings, Goods, ItemConfig};
check_can_use(?ITEM_USE_ID, ID, Num, State) ->
    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    case mod_role_bag:check_bag_by_id(ID, State) of
        {ok, #p_goods{type_id = TypeID, num = CurNum} = Goods} ->
            check_common_goods(Goods),
            ItemConfig = check_common_use(TypeID, State),
            ?IF(CurNum >= Num, ok, ?THROW_ERR(?ERROR_ITEM_USE_002)),
            BagDoings = [{decrease, ?ITEM_REDUCE_ITEM_USE, [#r_goods_decrease_info{id = ID, num = Num}]}],
            {ok, BagDoings, Goods, ItemConfig};
        _ ->
            ?THROW_ERR(?ERROR_ITEM_USE_001)
    end.


check_common_use(TypeID, State) ->
    #c_item{
        can_use = CanUse,
        use_level = UseLevel,
        need_confine = NeedConfine,
        category = UseCategory,
        need_vip = NeedVipLevel,
        effective_time = EffectiveTime
    } = ItemConfig = get_item_config(TypeID),
    ?IF(EffectiveTime =/= 0 andalso TypeID =:= ?ITEM_USE_TYPE_ID, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        level = RoleLevel,
        category = Category
    } = RoleAttr,
    ?IF(CanUse =:= ?ITEM_CAN_USE, ok, ?THROW_ERR(?ERROR_ITEM_USE_003)),
    ?IF(mod_role_vip:get_vip_level(State) >= NeedVipLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL)),
    ?IF(RoleLevel >= UseLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(mod_role_confine:get_confine_id(State) >= NeedConfine, ok, ?THROW_ERR(?ERROR_COMMON_CONFINE_LIMIT)),
    ?IF(UseCategory > 0 andalso Category =/= UseCategory, ?THROW_ERR(?ERROR_COMMON_NO_CATEGORY), ok),
    ItemConfig.

check_common_goods(Goods) ->
    #p_goods{end_time = EndTime} = Goods,
    ?IF(EndTime =/= 0 andalso time_tool:now() >= EndTime, ?THROW_ERR(?ERROR_ITEM_USE_011), ok).

do_item_effect(Goods, ItemConfig, Num, State) ->
    #c_item{effect_type = EffectType, effect_args = EffectArgs} = ItemConfig,
    do_item_effect2(EffectType, EffectArgs, Num, Goods, State).
do_item_effect2(?ITEM_EQUIP, _EffectArgs, _Num, Goods, State) ->
    mod_role_equip:load_equip(Goods, State);
do_item_effect2(?ITEM_MOUNT_QUALITY, _EffectArgs, Num, Goods, State) ->
    #p_goods{type_id = TypeID} = Goods,
    mod_role_mount:add_quality(TypeID, Num, State);
do_item_effect2(?ITEM_MAGIC_WEAPON_SOUL, _EffectArgs, Num, Goods, State) ->
    #p_goods{type_id = TypeID} = Goods,
    mod_role_magic_weapon:add_soul(TypeID, Num, State);
do_item_effect2(?ITEM_GOD_WEAPON_SOUL, _EffectArgs, Num, Goods, State) ->  % T 神兵-丹药
    #p_goods{type_id = TypeID} = Goods,
    mod_role_god_weapon:add_soul(TypeID, Num, State);
do_item_effect2(?ITEM_PTE_SPIRIT, _EffectArgs, Num, Goods, State) ->  % T 宠物-精魄就是丹药！！
    #p_goods{type_id = TypeID} = Goods,
    mod_role_pet:add_spirit(TypeID, Num, State);
do_item_effect2(?ITEM_WING_QUALITY, _EffectArgs, Num, Goods, State) ->
    #p_goods{type_id = TypeID} = Goods,
    mod_role_wing:add_soul(TypeID, Num, State);
do_item_effect2(?ITEM_PTE_EXP, EffectArgs, Num, _Goods, State) ->
    mod_role_pet:add_exp(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_MOUNT_SKIN, EffectArgs, _Num, _Goods, State) ->
    mod_role_mount:add_skin(lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_MAGIC_WEAPON_SKIN, EffectArgs, Num, _Goods, State) ->   %  T 法宝皮肤【激活】和【进阶】
    mod_role_magic_weapon:add_skin(lib_tool:to_integer(EffectArgs), Num, State);
do_item_effect2(?ITEM_GOD_WEAPON_SKIN, EffectArgs, Num, _Goods, State) ->
    mod_role_god_weapon:add_skin(lib_tool:to_integer(EffectArgs), Num, State);
do_item_effect2(?ITEM_ADD_WING_SKIN, EffectArgs, Num, _Goods, State) ->
    mod_role_wing:add_skin(lib_tool:to_integer(EffectArgs), Num, State);
do_item_effect2(?ITEM_MOUNT_STEP_EXP, EffectArgs, Num, Goods, State) -> % T  坐骑进阶丹
    mod_role_mount:do_mount_step(lib_tool:to_integer(EffectArgs) * Num, Goods#p_goods.type_id, Num, State);
do_item_effect2(?ITEM_ADD_MAGIC_WEAPON_EXP, EffectArgs, Num, Goods, State) ->
    mod_role_magic_weapon:add_exp(lib_tool:to_integer(EffectArgs) * Num, Goods#p_goods.type_id, Num, State);
do_item_effect2(?ITEM_ADD_GOD_WEAPON_EXP, EffectArgs, Num, Goods, State) ->
    mod_role_god_weapon:add_exp(lib_tool:to_integer(EffectArgs) * Num, Goods#p_goods.type_id, Num, State);
do_item_effect2(?ITEM_PTE_STEP_EXP, EffectArgs, Num, Goods, State) -> % T %% 宠物进阶丹
    mod_role_pet:add_step_exp(lib_tool:to_integer(EffectArgs) * Num, Goods#p_goods.type_id, Num, State);
do_item_effect2(?ITEM_ADD_WING_EXP, EffectArgs, Num, Goods, State) ->
    mod_role_wing:add_exp(lib_tool:to_integer(EffectArgs) * Num, Goods#p_goods.type_id, Num, State);
do_item_effect2(?ITEM_ADD_RUNE_PIECE, EffectArgs, _Num, _Goods, State) ->
    mod_role_rune:add_piece(lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_ADD_RUNE_ESSENCE, EffectArgs, _Num, _Goods, State) ->
    mod_role_rune:add_essence(lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_ADD_RUNE, EffectArgs, _Num, _Goods, State) ->
    mod_role_rune:add_rune(lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_ADD_SILVER, EffectArgs, Num, _Goods, State) ->
    mod_role_asset:use_silver_item(EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_GOLD, EffectArgs, Num, _Goods, State) ->
    mod_role_asset:use_gold_item(EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_BIND_GOLD, EffectArgs, Num, _Goods, State) ->
    mod_role_asset:use_bind_gold_item(EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_GLORY, EffectArgs, Num, _Goods, State) ->
    mod_role_asset:use_glory_item(EffectArgs, Num, State);
do_item_effect2(?ITEM_USE_PACKAGE, EffectArgs, Num, Goods, State) ->
    mod_role_package:use_package(Goods, EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_BUFF, EffectArgs, Num, _Goods, State) ->
    RoleID = State#r_role.role_id,
    BuffList = [#buff_args{buff_id = lib_tool:to_integer(EffectArgs), from_actor_id = RoleID} || _Index <- lists:seq(1, Num)],
    role_misc:add_buff(RoleID, BuffList),
    State;
do_item_effect2(?ITEM_ADD_OFFLINE_TIME, EffectArgs, Num, _Goods, State) ->
    mod_role_world_robot:add_time(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_VIP_EXPERIENCE_CARD, EffectArgs, Num, Goods, State) ->
    mod_role_vip:add_vip_experience(Goods#p_goods.type_id, lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_VIP_EXP_CARD, EffectArgs, Num, _Goods, State) ->
    mod_role_vip:add_vip_exp(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_ADD_FAMILY_CON, EffectArgs, Num, _Goods, State) ->
    AssetDoing = [{add_score, ?ASSET_FAMILY_CON_ADD_FROM_USE_ITEM, ?ASSET_FAMILY_CON, lib_tool:to_integer(EffectArgs) * Num}],
    mod_role_asset:do(AssetDoing, State);
do_item_effect2(?ITEM_ADD_COPY_TIMES, EffectArgs, Num, _Goods, State) ->
    mod_role_copy:add_copy_times(lib_tool:to_integer(EffectArgs), Num, State);
do_item_effect2(?ITEM_ADD_EXP, EffectArgs, Num, _Goods, State) ->                              %% T 增加经验
    mod_role_level:do_add_exp(State, lib_tool:to_integer(EffectArgs) * Num, ?EXP_ADD_FROM_ITEM_USE);
do_item_effect2(?ITEM_ADD_EXP_OR_LEVEL, EffectArgs, _Num, _Goods, State) ->                     %% T 增加经验或者等级
    mod_role_level:add_exp_or_level(State, EffectArgs, ?EXP_ADD_FROM_ITEM_USE);
do_item_effect2(?ITEM_ADD_VIP, _EffectArgs, _Num, Goods, State) ->
    mod_role_vip:use_vip_item(Goods#p_goods.type_id, State);
do_item_effect2(?ITEM_USE_GUARD, [], _Num, Goods, State) ->
    mod_role_guard:load_guard(Goods, 0, State);
do_item_effect2(?ITEM_USE_GUARD, EffectArgs, _Num, Goods, State) ->
    mod_role_guard:load_guard(Goods, lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_ADD_TITLE, EffectArgs, _Num, Goods, State) ->
    #p_goods{end_time = EndTime} = Goods,
    mod_role_title:add_title(EndTime, lib_tool:to_integer(EffectArgs), State);
do_item_effect2(?ITEM_ADD_WORLD_BOSS_TIMES, _EffectArgs, Num, _Goods, State) ->
    mod_role_world_boss:add_item_times(Num, State);
do_item_effect2(?ITEM_ADD_LEVEL_EXP, EffectArgs, Num, _Goods, State) ->
    {Rate, Level} =
        case lib_tool:string_to_integer_list(EffectArgs) of
            [RateT] ->
                {RateT, mod_role_data:get_role_level(State)};
            [RateT, MaxLevelT] ->
                {RateT, erlang:min(mod_role_data:get_role_level(State), MaxLevelT)}
        end,
    mod_role_level:do_add_level_exp2(Level, Rate, Num, ?EXP_ADD_FROM_ITEM_USE, State);
do_item_effect2(?ITEM_ADD_FASHION, EffectArgs, Num, _Goods, State) ->
    mod_role_fashion:use_fashion(lib_tool:to_integer(EffectArgs), Num, State);
do_item_effect2(?ITEM_INSIDE_PAY, EffectArgs, Num, Goods, State) ->
    mod_role_insider:use_pay_item(Goods#p_goods.type_id, lib_tool:to_integer(EffectArgs), Num, State);
%%do_item_effect2(?ITEM_CONFINE_UP, EffectArgs, Num, _Goods, State) ->
%%    mod_role_confine:add_confine_exp(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_MARRY_KNOT, EffectArgs, Num, Goods, State) ->
    mod_role_marry:add_knot(Goods#p_goods.type_id, Num, lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_MARRY_FIREWORKS, EffectArgs, Num, Goods, State) ->
    mod_role_marry:fireworks(Goods#p_goods.type_id, EffectArgs, Num, State);
do_item_effect2(?ITEM_CLEAR_PK_VALUE, _EffectArgs, _Num, _Goods, State) ->
    mod_role_fight:clear_pk_value(State);
do_item_effect2(?ITEM_MYTHICAL_COLLECT, EffectArgs, Num, Goods, State) ->
    mod_role_package:use_mythical_package(Goods, ?ITEM_MYTHICAL_COLLECT, EffectArgs, Num, State);
do_item_effect2(?ITEM_MYTHICAL_COLLECT2, EffectArgs, Num, Goods, State) ->
    mod_role_package:use_mythical_package(Goods, ?ITEM_MYTHICAL_COLLECT2, EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_MYTHICAL_TIMES, _EffectArgs, Num, _Goods, State) ->
    mod_role_world_boss:add_mythical_times(Num, State);
do_item_effect2(?ITEM_GOLD_PAY, EffectArgs, Num, _Goods, State) ->
    mod_role_pay:use_pay_item(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_HUNT_TREASURE, _EffectArgs, _Num, Goods, State) ->
    mod_role_hunt_treasure:use_item(Goods#p_goods.type_id, State);
do_item_effect2(?ITEM_WORLD_BOSS_REFRESH, EffectArgs, _Num, _Goods, State) ->   %%  T 世界BOSS刷新令
    mod_role_world_boss:clear_the_world_boss_cd(EffectArgs, State);
do_item_effect2(?ITEM_WORLD_BOSS_FLOOR_REFRESH, EffectArgs, _Num, _Goods, State) ->   %%  T 世界BOSS刷新令（洞天福地 刷新整层）
    mod_role_world_boss:clear_world_boss_all_floor_cd(EffectArgs, State);
do_item_effect2(?ITEM_OPEN_SKILL, _EffectArgs, _Num, Goods, State) ->
    mod_role_function:do_trigger_function(?FUNCTION_TYPE_ITEM, Goods#p_goods.type_id, State);
do_item_effect2(?ITEM_ADD_TALENT_POINTS, EffectArgs, Num, _Goods, State) ->
    mod_role_relive:add_talent_points(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_LIMIT_ADD_ILLUSION, EffectArgs, Num, _Goods, State) ->
    mod_role_copy:add_limit_times_illusion(?ITEM_LIMIT_ADD_ILLUSION, EffectArgs, Num, State);
do_item_effect2(?ITEM_ADD_ILLUSION, EffectArgs, Num, _Goods, State) ->
    mod_role_copy:add_illusion(lib_tool:to_integer(EffectArgs) * Num, State);
do_item_effect2(?ITEM_ADD_TIME_FASHION_1, EffectArgs, _Num, Goods, State) ->
    mod_role_fashion:use_time_fashion(lib_tool:to_integer(EffectArgs), 1, Goods#p_goods.end_time, State);
do_item_effect2(?ITEM_ADD_TIME_FASHION_2, EffectArgs, _Num, _Goods, State) ->
    [TimeString, FashionIDString] = string:tokens(EffectArgs, ","),
    mod_role_fashion:use_time_fashion(lib_tool:to_integer(FashionIDString), 1, time_tool:now() + lib_tool:to_integer(TimeString), State);
do_item_effect2(EffectType, EffectArgs, _Num, Goods, State) ->
    ?ERROR_MSG("item error: ~w", [{Goods#p_goods.type_id, EffectType, EffectArgs}]),
    ?THROW_ERR(?ERROR_ITEM_USE_003),
    State.

do_item_sell(RoleID, State, ItemList) ->
    case catch check_can_sell(State, ItemList) of
        {ok, BagDoings, AssetDoings} ->
            State2 = mod_role_bag:do(BagDoings, State),
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_item_sell_toc{}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_item_sell_toc{err_code = ErrCode}),
            State
    end.

check_can_sell(State, ItemList) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = GoodsList} = mod_role_bag:get_bag(RoleBag),
    {AddSilver, DecreaseList} = check_can_sell2(ItemList, GoodsList, 0, []),
    AssetDoings = [{add_silver, ?ASSET_SILVER_ADD_FROM_SELL_ITEM, AddSilver}],
    BagDoings = [{decrease, ?ITEM_REDUCE_ITEM_SELL, DecreaseList}],
    {ok, BagDoings, AssetDoings}.

check_can_sell2([], _GoodsList, AddSilver, DecreaseList) ->
    {AddSilver, DecreaseList};
check_can_sell2(_ItemList, [], _AddSilver, _DecreaseList) ->
    ?THROW_ERR(?ERROR_ITEM_SELL_001);
check_can_sell2(ItemList, [Goods|R], AddSilver, DecreaseList) ->
    #p_goods{id = ID, num = Num, type_id = TypeID} = Goods,
    case lists:keytake(ID, #p_kv.id, ItemList) of
        {value, #p_kv{val = ItemNum}, ItemList2} ->
            ?IF(Num >= ItemNum, ok, ?THROW_ERR(?ERROR_ITEM_SELL_002)),
            #c_item{sell_silver = SellSilver} = get_item_config(TypeID),
            AddSilverAcc = ?IF(SellSilver > 0, SellSilver * ItemNum + AddSilver, ?THROW_ERR(?ERROR_ITEM_SELL_003)),
            DecreaseListAcc = [#r_goods_decrease_info{id = ID, num = ItemNum}] ++ DecreaseList,
            check_can_sell2(ItemList2, R, AddSilverAcc, DecreaseListAcc);
        _ ->
            check_can_sell2(ItemList, R, AddSilver, DecreaseList)
    end.

is_item_notice(TypeID) ->
    #c_item{is_notice = IsNotice} = get_item_config(TypeID),
    ?IS_ITEM_NOTICE(IsNotice).

get_item_config(TypeID) ->
    get_item_config(TypeID, mod_role_dict:get_category()).
get_item_config(TypeID, Category) ->
    %% 外部进程调用时，职业可能获取不到，强制为职业1
    Category2 = ?IF(Category =:= undefined, ?CATEGORY_1, Category),
    TypeID2 = ?IF(?IS_CATEGORY_ITEM(TypeID), get_category_item(TypeID, Category2), TypeID),
    case lib_config:find(cfg_item, TypeID2) of
        [Config] ->
            Config;
        _ ->
            ?ERROR_MSG("道具配置不存在:~w", [TypeID2]),
            erlang:throw(config_error)
    end.

get_category_item(TypeID, Category) ->
    case lib_config:find(cfg_category_item, TypeID) of
        [#c_category_item{category_1 = Item1, category_2 = Item2}] ->
            if
                Category =:= ?CATEGORY_1 ->
                    Item1;
                Category =:= ?CATEGORY_2 ->
                    Item2
            end;
        _ ->
            ?ERROR_MSG("职业道具道具配置不存在:~w", [TypeID]),
            erlang:throw(config_error)
    end.




gm_overdue_item(ID, State) ->
    #r_role{role_bag = RoleBag} = State,
    #r_role_bag{bag_list = BagList} = RoleBag,
    case lists:keytake(?BAG_ID_BAG, #p_bag_content.bag_id, BagList) of
        {value, #p_bag_content{} = BagContent, OtherBagContent} ->
            case lists:keytake(ID, #p_goods.id, BagContent#p_bag_content.goods_list) of
                {value, Item, OthersGoods} ->
                    Now = time_tool:now(),
                    NewItem = Item#p_goods{end_time = Now - 1},
                    NewGoods = [NewItem|OthersGoods],
                    NewBagContent = BagContent#p_bag_content{goods_list = NewGoods},
                    NewBagList = [NewBagContent|OtherBagContent],
                    NewRoleBag = RoleBag#r_role_bag{bag_list = NewBagList},
                    State2 = State#r_role{role_bag = NewRoleBag},
                    mod_role_guard:loop_min(Now, State2);
                _ ->
                    State
            end;
        _ ->
            State
    end


.

