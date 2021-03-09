%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 六月 2017 16:41
%%%-------------------------------------------------------------------
-module(mod_role_bag).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_bag.hrl").

%% API
-export([
    init/1,
    pre_enter/1,
    handle/2
]).

-export([
    check_bag_by_id/2,
    check_bag_by_ids/2,
    check_bag_by_kv_list/2,
    check_bag_empty_grid/2,
    check_bag_empty_grid/3,
    spilt_bag_letter_goods/2,
    check_num_by_item_list/3,
    check_num_by_type_id/4,
    get_num_by_type_id/2,
    get_no_bind_num_by_type_id/2,
    get_goods_by_type_id/2,
    get_goods_by_bag_id/2,
    get_decrease_goods_by_num/3,
    get_create_list/1,
    get_create_list/2
]).

-export([
    do/2,
    merge_goods_log/1,
    trans_to_log/3
]).

-export([
    get_bag/1,
    get_bag/2
]).

-export([
    gm_clear_bag/1
]).

init(#r_role{role_id = RoleID, role_bag = undefined} = State) ->
    RoleBag = #r_role_bag{role_id = RoleID},
    init(State#r_role{role_bag = RoleBag});
init(State) ->
    #r_role{role_bag = RoleBag} = State,
    #r_role_bag{bag_list = BagContents} = RoleBag,
    ConfigList = cfg_bag_content:list(),
    BagContents2 = init_bag_content(ConfigList, BagContents),
    RoleBag2 = RoleBag#r_role_bag{bag_list = BagContents2},
    State#r_role{role_bag = RoleBag2}.

init_bag_content([], BagContents) ->
    BagContents;
init_bag_content([{BagID, Config}|R], BagContents) ->
    case lists:keyfind(BagID, #p_bag_content.bag_id, BagContents) of
        #p_bag_content{} ->
            init_bag_content(R, BagContents);
        _ ->
            #c_bag_content{min_grid = MinGrid} = Config,
            BagContents2 = [#p_bag_content{bag_id = BagID, bag_grid = MinGrid, goods_list = []}|BagContents],
            init_bag_content(R, BagContents2)
    end.

pre_enter(#r_role{role_id = RoleID, role_bag = RoleBag} = State) ->
    #r_role_bag{bag_list = BagList} = RoleBag,
    common_misc:unicast(RoleID, #m_bag_info_toc{bag_list = BagList}),
    State.

handle({#m_bag_merge_tos{merge_list = MergeList}, RoleID, _PID}, State) ->
    do_merge(RoleID, MergeList, State);
handle({#m_bag_grid_open_tos{bag_id = BagID, add_num = AddNum}, RoleID, _PID}, State) ->
    do_grid_open(RoleID, BagID, AddNum, State);
handle({#m_bag_depot_tos{from_bag_id = FromID, to_bag_id = ToID, id = GoodsID}, RoleID, _PID}, State) ->
    do_bag_depot(RoleID, FromID, ToID, GoodsID, State);
handle({#m_bag_all_depot_tos{bag_id = BagID}, RoleID, _PID}, State) ->
    do_all_depot(RoleID, BagID, State);
handle({#m_bag_item_self_tos{kv_list = KVList}, RoleID, _PID}, State) ->
    do_bag_item_self(RoleID, KVList, State);
handle({create_goods, Action, GoodsList}, State) ->
    role_misc:create_goods(State, Action, GoodsList).

gm_clear_bag(State) ->
    #r_role{role_id = RoleID, role_bag = RoleBag} = State,
    #r_role_bag{bag_list = BagList} = RoleBag,
    {BagList2, DelIDList} =
    lists:foldl(
        fun(BagContent, {Acc1, Acc2}) ->
            #p_bag_content{goods_list = GoodsList} = BagContent,
            {[BagContent#p_bag_content{goods_list = []}|Acc1], [ID || #p_goods{id = ID} <- GoodsList] ++ Acc2}
        end, {[], []}, BagList),
    DataRecord = #m_bag_update_toc{del_list = DelIDList},
    common_misc:unicast(RoleID, DataRecord),
    RoleBag2 = RoleBag#r_role_bag{bag_list = BagList2},
    State#r_role{role_bag = RoleBag2}.

check_bag_by_id(ID, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_id(ID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    case lists:keyfind(ID, #p_goods.id, GoodsList) of
        #p_goods{} = Goods ->
            {ok, Goods};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS)
    end.

%% 检查IDList对应的道具| {ok, GoodsList} or ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS)
check_bag_by_ids(IDList, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagDelList = get_bag_del_list(IDList),
    GoodsList = check_bag_by_ids2(BagDelList, RoleBag, []),
    {ok, GoodsList}.

check_bag_by_ids2([], _RoleBag, GoodsAcc) ->
    GoodsAcc;
check_bag_by_ids2([{BagID, IDList}|R], RoleBag, GoodsAcc) ->
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    AddGoods = check_bag_by_ids3(IDList, GoodsList, []),
    check_bag_by_ids2(R, RoleBag, AddGoods ++ GoodsAcc).

check_bag_by_ids3([], _GoodsList, GoodsAcc) ->
    GoodsAcc;
check_bag_by_ids3(_IDList, [], _GoodsAcc) ->
    ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS);
check_bag_by_ids3(IDList, [#p_goods{id = ID} = Goods|R], GoodsAcc) ->
    case lists:member(ID, IDList) of
        true ->
            IDList2 = lists:delete(ID, IDList),
            check_bag_by_ids3(IDList2, R, [Goods|GoodsAcc]);
        _ ->
            check_bag_by_ids3(IDList, R, GoodsAcc)
    end.

%% 检查#p_kv{id = ID, val = NeedNum} | 返回{ok, BagDoings, GoodsList(num = NeedNum)} or ?THROW_ERR(ErrCode)
check_bag_by_kv_list(KVList, State) ->
    #r_role{role_bag = RoleBag} = State,
    check_bag_by_kv_list2(KVList, RoleBag, [], [], []).

check_bag_by_kv_list2([], _RoleBag, _HasIDs, DecreaseAcc, GoodsAcc) ->
    {ok, DecreaseAcc, GoodsAcc};
check_bag_by_kv_list2([#p_kv{id = ID, val = NeedNum}|R], RoleBag, HasIDs, DecreaseAcc, GoodsAcc) ->
    case lists:member(ID, HasIDs) of
        true ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM);
        _ ->
            BagID = get_bag_id_by_id(ID),
            #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
            case lists:keyfind(ID, #p_goods.id, GoodsList) of
                #p_goods{num = Num} = Goods ->
                    ?IF(NeedNum > 0 andalso Num >= NeedNum, ok, ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS)),
                    DecreaseAcc2 = [#r_goods_decrease_info{id = ID, num = NeedNum}|DecreaseAcc],
                    HasIDs2 = [ID|HasIDs],
                    GoodsAcc2 = [Goods#p_goods{num = NeedNum}|GoodsAcc],
                    check_bag_by_kv_list2(R, RoleBag, HasIDs2, DecreaseAcc2, GoodsAcc2);
                _ ->
                    ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS)
            end
    end.


get_bag_empty_grid(BagID, State) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = get_bag(BagID, RoleBag),
    BagGrid - erlang:length(GoodsList).

%% 根据GoodsList检查格子，这里可能检查多个背包
check_bag_empty_grid(Num, State) when erlang:is_integer(Num) ->
    check_bag_empty_grid(?BAG_ID_BAG, Num, State);
check_bag_empty_grid(List, State) ->
    BagCreateList = get_bag_create_list(List),
    [check_bag_empty_grid(BagID, GoodsList, State) || {BagID, GoodsList} <- BagCreateList],
    true.

check_bag_empty_grid(BagID, CreateList, State) when erlang:is_list(CreateList) ->
    CreateList2 = get_create_list(CreateList),
    Num =
    lists:foldl(
        fun(#p_goods{type_id = TypeID}, Acc) ->
            ?IF(is_need_grid_goods(TypeID), Acc + 1, Acc)
        end, 0, CreateList2),
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = get_bag(BagID, RoleBag),
    ?IF(BagGrid - erlang:length(GoodsList) >= Num, true, ?THROW_ERR(?ERROR_COMMON_BAG_FULL));
check_bag_empty_grid(BagID, Num, State) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = get_bag(BagID, RoleBag),
    ?IF(BagGrid - erlang:length(GoodsList) >= Num, true, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)).

spilt_bag_letter_goods(GoodsList, State) ->
    BagCreateList = get_bag_create_list(GoodsList),
    spilt_bag_letter_goods2(BagCreateList, State, [], []).

spilt_bag_letter_goods2([], _State, BagList, LetterList) ->
    {BagList, LetterList};
spilt_bag_letter_goods2([{BagID, GoodsList}|R], State, BagAcc, LetterAcc) ->
    GoodsList2 = get_create_list(GoodsList),
    {GoodsList3, BagList} =
    lists:foldl(
        fun(#p_goods{type_id = TypeID} = Goods, {GoodsAcc, OtherAcc}) ->
            case is_need_grid_goods(TypeID) of
                true ->
                    {[Goods|GoodsAcc], OtherAcc};
                _ ->
                    {GoodsAcc, [Goods|OtherAcc]}
            end
        end, {[], []}, GoodsList2),
    EmptyGrid = get_bag_empty_grid(BagID, State),
    {BagList2, LetterList} = check_split(BagID, EmptyGrid, GoodsList3, State),
    spilt_bag_letter_goods2(R, State, BagList ++ BagList2 ++ BagAcc, LetterList ++ LetterAcc).

check_split(?BAG_ID_NATURE, _EmptyGrid, GoodsList3, State) ->
    mod_role_nature:check_goods_bag_refine(State, GoodsList3);
check_split(_BagID, EmptyGrid, GoodsList3, _State) ->
    lib_tool:split(EmptyGrid, GoodsList3).

%% 部分道具是不需要格子就可以创建的
is_need_grid_goods(TypeID) ->
    case is_asset_item(TypeID) of %% 货币类道具
        true ->
            false;
        _ ->
            #c_item{effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
            not lists:member(EffectType, [?ITEM_ADD_RUNE, ?ITEM_IMMORTAL_SOUL, ?ITEM_IMMORTAL_SOUL_STONE, ?ITEM_MYTHICAL_EQUIP, ?BAG_NAT_INTENSIFY_GOODS])
    end.

%% ItemList -> [{TypeID, Num}....]
check_num_by_item_list(ItemList, Action, State) ->
    ItemList2 = modify_item_list(ItemList, []),
    DecreaseList =
    [begin
         case get_num_by_type_id(TypeID, State) >= Num of
             true ->
                 #r_goods_decrease_info{type_id = TypeID, num = Num};
             _ ->
                 ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM)
         end
     end || {TypeID, Num} <- ItemList2],
    [{decrease, Action, DecreaseList}].

check_num_by_type_id(TypeID, Num, Action, State) ->
    case get_num_by_type_id(TypeID, State) >= Num of
        true ->
            [{decrease, Action, [#r_goods_decrease_info{type_id = TypeID, num = Num}]}];
        _ ->
            ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM)
    end.

modify_item_list([], Acc) ->
    Acc;
modify_item_list([{TypeID, Num1}|R], Acc) ->
    case lists:keyfind(TypeID, 1, Acc) of
        {TypeID, Num2} ->
            Acc2 = lists:keyreplace(TypeID, 1, Acc, {TypeID, Num1 + Num2});
        _ ->
            Acc2 = [{TypeID, Num1}|Acc]
    end,
    modify_item_list(R, Acc2).

%% 返回 Num
get_num_by_type_id(TypeID, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_item(TypeID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    get_num_by_type_id2(GoodsList, TypeID, 0).

get_num_by_type_id2([], _TypeID, Num) ->
    Num;
get_num_by_type_id2([Goods|R], TypeID, Num) ->
    #p_goods{type_id = TypeID2, num = Num2} = Goods,
    NumAcc = ?IF(TypeID =:= TypeID2, Num + Num2, Num),
    get_num_by_type_id2(R, TypeID, NumAcc).

%% 返回 {ok, Num}
get_no_bind_num_by_type_id(TypeID, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_item(TypeID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    get_no_bind_num_by_type_id2(GoodsList, TypeID, 0).

get_no_bind_num_by_type_id2([], _TypeID, Num) ->
    Num;
get_no_bind_num_by_type_id2([Goods|R], TypeID, Num) ->
    #p_goods{type_id = TypeID2, num = Num2, bind = Bind} = Goods,
    NumAcc = ?IF(TypeID =:= TypeID2 andalso Bind =:= false, Num + Num2, Num),
    get_no_bind_num_by_type_id2(R, TypeID, NumAcc).

%% 返回  Goods  or  false
get_goods_by_type_id(TypeID, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_item(TypeID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    lists:keyfind(TypeID, #p_goods.type_id, GoodsList).


%% 返回  Goods  or  false
get_goods_by_bag_id(ID, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_id(ID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    lists:keyfind(ID, #p_goods.id, GoodsList).

get_decrease_goods_by_num(TypeID, Num, State) ->
    #r_role{role_bag = RoleBag} = State,
    BagID = get_bag_id_by_item(TypeID),
    #p_bag_content{goods_list = GoodsList} = get_bag(BagID, RoleBag),
    get_decrease_goods_by_num2(GoodsList, TypeID, Num, 0, []).

get_decrease_goods_by_num2([], _TypeID, _Num, _HasNum, _DecreaseList) ->
    ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_ITEM);
get_decrease_goods_by_num2([Goods|R], TypeID, Num, HasNum, DecreaseList) ->
    #p_goods{id = GoodsID, type_id = GoodsTypeID, num = GoodsNum, bind = Bind} = Goods,
    case TypeID =:= GoodsTypeID of
        true ->
            case GoodsNum + HasNum >= Num of
                true ->
                    [#r_goods_decrease_info{id = GoodsID, id_bind_type = Bind, type_id = TypeID, num = Num - HasNum}|DecreaseList];
                _ ->
                    DecreaseList2 = [#r_goods_decrease_info{id = GoodsID, id_bind_type = Bind, type_id = TypeID, num = GoodsNum}|DecreaseList],
                    get_decrease_goods_by_num2(R, TypeID, Num, HasNum + GoodsNum, DecreaseList2)
            end;
        _ ->
            get_decrease_goods_by_num2(R, TypeID, Num, HasNum, DecreaseList)
    end.

%% 外部调用时要注意传入职业
get_create_list(GoodsList) ->
    get_create_list(GoodsList, mod_role_dict:get_category()).
get_create_list(GoodsList, Category) ->
    {CoverList, UnCoverList} = get_create_modify_list(GoodsList, Category),
    CoverList2 = modify_cover_goods(CoverList),
    CoverList2 ++ UnCoverList.

do([], State) ->
    State;
do(Doings, #r_role{role_id = RoleID} = State) ->
    %% 天机印自动分解, Doings会改变
    Doings2 = mod_role_nature:check_goods_refine(Doings, State),
    {State2, RecordList, LogList, CallBackList, ChangeList} =
    lists:foldl(
        fun(Doing, {StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc}) ->
            case Doing of
                {_, _Action, []} -> %% 第二个是空列表，忽略
                    {StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc};
                {create, Action, CreateList} ->
                    BagCreateList = get_bag_create_list(CreateList),
                    do_create(BagCreateList, Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc, [], []);
                {create, BagID, Action, CreateList} ->
                    do_create([{BagID, CreateList}], Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc, [], []);
                {delete, Action, IDList} ->
                    BagDelList = get_bag_del_list(IDList),
                    do_delete(BagDelList, Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc);
                {decrease, Action, DecreaseList} ->
                    BagDecreaseList = get_bag_decrease_list(DecreaseList),
                    do_decrease(BagDecreaseList, Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc);
                _ ->
                    ?ERROR_MSG("mod_role_bag:doing unkonw type,RoleID:~w,Doing:~w", [RoleID, Doing]),
                    ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
            end end, {State, [], [], [], []}, Doings2),
    [common_misc:unicast(RoleID, Record) || Record <- lists:reverse(RecordList)],
    [?TRY_CATCH(CallBack()) || CallBack <- CallBackList],
    mod_role_dict:add_background_logs(LogList),
    State3 = do_trigger(ChangeList, Doings2, State2),
    State3.

do_trigger(ChangeList, Doings, State) ->
    FuncList = [
        fun(StateAcc) -> mod_role_mission:item_trigger(ChangeList, StateAcc) end,
        fun(StateAcc) -> mod_role_warning:add_item_doings(Doings, StateAcc) end,
        fun(StateAcc) -> mod_role_nature:item_trigger(ChangeList, StateAcc) end
    ],
    role_server:execute_state_fun(FuncList, State).


do_create([], Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc, UpdateAcc, KVAcc) ->
    RecordAcc2 = ?IF(UpdateAcc =/= [] orelse KVAcc =/= [],
                     [#m_bag_update_toc{update_list = UpdateAcc, action = Action, kv_list = KVAcc}|RecordAcc],
                     RecordAcc),
    {StateAcc, RecordAcc2, LogAcc, CallBackAcc, ChangeAcc};
do_create([{BagID, CreateList}|R], Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc, UpdateAcc, KVAcc) ->
    %%非系统首次产生已获得物品   例：装备替换 帮派兑换获得（合成统一例外，算作系统首次产生）
    IsRecreate = lists:member(Action, ?NON_SYSTEM_CREATE),
    {ok, StateAcc2, UpdateList, NoticeGoods, CallBacks, KVList, Changes} = create_goods(BagID, Action, CreateList, StateAcc, IsRecreate),
    UpdateAcc2 = UpdateList ++ UpdateAcc,
    KVAcc2 = KVList ++ KVAcc,
    LogList = trans_to_log(StateAcc2, merge_goods_log(CreateList), Action),
    ?TRY_CATCH(item_common_notice(StateAcc2, Action, NoticeGoods)),
    do_create(R, Action, StateAcc2, RecordAcc, LogList ++ LogAcc, CallBacks ++ CallBackAcc, Changes ++ ChangeAcc, UpdateAcc2, KVAcc2).

do_delete([], _Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc) ->
    {StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc};
do_delete([{BagID, IDList}|R], Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc) ->
    {ok, StateAcc2, LogGoodsList, Changes} = delete_goods(IDList, BagID, StateAcc),
    LogList = trans_to_log(StateAcc2, LogGoodsList, Action),
    DataRecord = #m_bag_update_toc{del_list = IDList, action = Action},
    do_delete(R, Action, StateAcc2, [DataRecord|RecordAcc], LogList ++ LogAcc, CallBackAcc, Changes ++ ChangeAcc).

do_decrease([], _Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc) ->
    {StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc};
do_decrease([{BagID, DecreaseList}|R], Action, StateAcc, RecordAcc, LogAcc, CallBackAcc, ChangeAcc) ->
    {ok, StateAcc2, UpdateList, DelList, LogGoodsList, Changes} = decrease_goods(DecreaseList, BagID, StateAcc),
    LogList = trans_to_log(StateAcc2, LogGoodsList, Action),
    DataRecord = #m_bag_update_toc{update_list = UpdateList, del_list = DelList, action = Action},
    do_decrease(R, Action, StateAcc2, [DataRecord|RecordAcc], LogList ++ LogAcc, CallBackAcc, Changes ++ ChangeAcc).

%% num必须大于0
%% CreateList -> [#p_goods{}|_]
create_goods(_BagID, _Action, [], State, _IsRecreate) ->
    {ok, State, [], [], [], [], []};
create_goods(BagID, Action, CreateList, State, IsRecreate) ->
    #r_role{role_bag = RoleBag, role_addict = #r_role_addict{reduce_rate = ReduceRate}} = State,
    #p_bag_content{bag_grid = MaxBagGrid, goods_list = GoodsList} = BagContent = get_bag(BagID, RoleBag),
    {CreateList2, OtherDoings, CallBackList, KVList} = get_other_doings(CreateList, Action, ReduceRate, State, [], #r_bag_other_doing{}, [], []),
    Changes = lib_tool:list_filter_repeat([CreateTypeID || #p_goods{type_id = CreateTypeID} <- CreateList2]),
    {CoverCreate, UnCoverCreate} = get_create_modify_list(CreateList2),
    %% 在update之前先给got_time赋值进行判断
    Now = time_tool:now(),
    CoverCreateT = add_cover_market_time(CoverCreate, Now, IsRecreate),
    {GoodsList2, CoverCreate2, UpdateList} = update_bag_goods(GoodsList, CoverCreateT, Now, [], []),
    case UnCoverCreate =/= [] orelse CoverCreate2 =/= [] of
        true ->
            UsedList = [ID || #p_goods{id = ID} <- GoodsList2],
            AllID = get_bag_ids(BagID, MaxBagGrid),
            RemainIDList = AllID -- UsedList,
            {UnCoverGoods, RemainIDList2} = create_new_goods(UnCoverCreate, RemainIDList, IsRecreate),
            {CoverGoods, _RemainIDList3} = create_cover_goods(CoverCreate2, RemainIDList2, IsRecreate),
            CreateGoods = UnCoverGoods ++ CoverGoods,
            NoticeGoods = CoverCreate ++ UnCoverGoods,
            UpdateList2 = CreateGoods ++ UpdateList,
            GoodsList3 = CreateGoods ++ GoodsList2;
        _ ->
            NoticeGoods = CoverCreate,
            UpdateList2 = UpdateList,
            GoodsList3 = GoodsList2
    end,
    BagContent2 = BagContent#p_bag_content{goods_list = GoodsList3},
    RoleBag2 = set_bag(BagContent2, RoleBag),
    State2 = State#r_role{role_bag = RoleBag2},
    State3 = create_other_doings(OtherDoings, State2),
    {ok, State3, UpdateList2, NoticeGoods, CallBackList, KVList, Changes}.

%% 叠加道具有时限，在update之前要整理
add_cover_market_time(CoverCreate, _Now, false) ->
    [begin
         case not Bind of
             true ->
                 case mod_role_item:get_item_config(TypeID) of
                     #c_item{protect_time = ProtectTime, auction_sub_class = SubClass} when ProtectTime > 0 andalso SubClass > 0
                         andalso MarketEndTime =:= 0 ->
                         Now = time_tool:now(),
                         Goods#p_goods{market_end_time = Now};
                     _ ->
                         Goods
                 end;
             _ ->
                 Goods
         end
     end || #p_goods{bind = Bind, type_id = TypeID, market_end_time = MarketEndTime} = Goods <- CoverCreate];
add_cover_market_time(CoverCreate, _Now, _IsRecreate) ->
    CoverCreate.


%% 背包其他处理
create_other_doings(BagOtherDoings, State) ->
    #r_bag_other_doing{
        add_exp = AddExp,
        add_essence = AddEssence,
        add_rune_exp = AddRuneExp,
        asset_doings = AssetDoings,
        rune_doings = RuneDoings,
        immortal_soul_doings = ImmortalSoulDoings,
        immortal_soul_stone = ImmortalSoulStone,
        add_mythical_equips = MythicalEquips,
        add_war_spirit_equips = SpiritEquips,
        add_handbook_essence = AddHandbookEssence,
        add_throne_essence = AddThroneEssence,
        talent_points = TalentPoints,
        training_point = TrainingPoint,
        intensify_nature = IntensifyNature
%%        add_war_god_pieces = AddWarGodPieces
    } = BagOtherDoings,
    StateFunc =
    [
        fun(StateAcc) -> mod_role_rune:add_exp(AddRuneExp, StateAcc) end,
        fun(StateAcc) -> mod_role_asset:do(AssetDoings, StateAcc) end,
        fun(StateAcc) -> mod_role_rune:add_rune(RuneDoings, StateAcc) end,
        fun(StateAcc) -> mod_role_level:do_add_exp(StateAcc, AddExp, ?EXP_ADD_FROM_ITEM_USE) end,
        fun(StateAcc) -> mod_role_immortal_soul:add_immortal_soul(ImmortalSoulDoings, StateAcc) end,
        fun(StateAcc) -> mod_role_immortal_soul:add_immortal_soul_stone(ImmortalSoulStone, StateAcc) end,
        fun(StateAcc) -> mod_role_rune:add_essence(AddEssence, StateAcc) end,
        fun(StateAcc) -> mod_role_mythical_equip:add_equips(MythicalEquips, StateAcc) end,
        fun(StateAcc) -> mod_role_confine:add_equips(SpiritEquips, StateAcc) end,
        fun(StateAcc) -> mod_role_handbook:add_handbook_essence(AddHandbookEssence, StateAcc) end,
        fun(StateAcc) -> mod_role_throne:add_throne_essence(AddThroneEssence, StateAcc) end,
        fun(StateAcc) -> mod_role_relive:add_talent_points(TalentPoints, StateAcc) end,
        fun(StateAcc) -> mod_role_act_esoterica:add_training_point(TrainingPoint, StateAcc) end,
        fun(StateAcc) -> mod_role_nature:add_intensify_nature(IntensifyNature, StateAcc) end
%%        fun(StateAcc) -> mod_role_confine:add_war_god_pieces(AddWarGodPieces, StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

%% 尝试合并道具，不能合并的，跟UnCover的一起创建
%% 返回最新的GoodsList, 剩余的CreateList, 以及有变化的UpdateList(推送给前端)
update_bag_goods([], CreateList, _Now, GoodsListAcc, UpdateList) ->
    {GoodsListAcc, CreateList, UpdateList};
update_bag_goods(GoodsList, [], _Now, GoodsListAcc, UpdateList) ->
    {GoodsList ++ GoodsListAcc, [], UpdateList};
update_bag_goods([Goods|R], CreateList, Now, GoodsListAcc, UpdateList) ->
    {Goods2, CreateList2, IsUpdate} = update_bag_goods2(Goods, CreateList, Now, [], false),
    UpdateList2 = ?IF(IsUpdate, [Goods2|UpdateList], UpdateList),
    update_bag_goods(R, CreateList2, Now, [Goods2|GoodsListAcc], UpdateList2).

%% 对每个物品尝试合并
update_bag_goods2(Goods, [], _Now, CreateAcc, IsUpdate) ->
    {Goods, CreateAcc, IsUpdate};
update_bag_goods2(Goods, [CreateInfo|R], Now, CreateAcc, IsUpdate) ->
    #p_goods{type_id = TypeID1, bind = Bind1, market_end_time = MarketEndTime1, num = Num1} = Goods,
    #p_goods{type_id = TypeID2, bind = Bind2, market_end_time = MarketEndTime2, num = Num2} = CreateInfo,
    case TypeID1 =:= TypeID2 andalso Bind1 =:= Bind2 andalso is_market_time_merge(Now, MarketEndTime1, MarketEndTime2) of %% 可以合并
        true ->
            #c_item{cover_num = CoverNum} = mod_role_item:get_item_config(TypeID1),
            if
                (Num1 + Num2) > CoverNum -> %% 超过上限
                    Goods2 = Goods#p_goods{num = CoverNum},
                    CreateInfo2 = CreateInfo#p_goods{num = Num1 + Num2 - CoverNum},
                    {Goods2, [CreateInfo2|R] ++ CreateAcc, true};
                (Num1 + Num2) =:= CoverNum -> %% 正好达到上限
                    Goods2 = Goods#p_goods{num = CoverNum},
                    {Goods2, R ++ CreateAcc, true};
                true ->
                    Goods2 = Goods#p_goods{num = Num1 + Num2},
                    update_bag_goods2(Goods2, R, Now, CreateAcc, true)
            end;
        _ ->
            update_bag_goods2(Goods, R, Now, [CreateInfo|CreateAcc], IsUpdate)
    end.

create_cover_goods(CoverCreate, RemainIDList, IsRecreate) ->
    {CoverCreate2, _UnCover} = get_create_modify_list(CoverCreate),
    CoverCreate3 = modify_cover_goods(CoverCreate2),
    create_new_goods(CoverCreate3, RemainIDList, IsRecreate).

modify_cover_goods(CoverCreate) ->
    lists:foldl(
        fun(#p_goods{type_id = TypeID, num = Num} = CreateInfo, Acc) ->
            #c_item{cover_num = CoverNum} = mod_role_item:get_item_config(TypeID),
            case is_asset_item(TypeID) orelse Num =< CoverNum of
                true ->
                    [CreateInfo#p_goods{num = Num}|Acc];
                _ ->
                    Length = Num div CoverNum,
                    RemainNum = Num rem CoverNum,
                    LenList = [CreateInfo#p_goods{num = CoverNum} || _Num <- lists:seq(1, Length)],
                    LenList2 = ?IF(RemainNum > 0, LenList ++ [CreateInfo#p_goods{num = RemainNum}], LenList),
                    LenList2 ++ Acc
            end
        end, [], CoverCreate).

create_new_goods(CreateList, RemainIDList, IsRecreate) ->
    case erlang:length(CreateList) =< erlang:length(RemainIDList) of
        true ->
            create_new_goods2(CreateList, RemainIDList, [], IsRecreate);
        _ ->
            erlang:throw({error, id_not_enough})
    end.

create_new_goods2([], RemainIDList, GoodsAcc, _IsRecreate) ->
    {GoodsAcc, RemainIDList};
create_new_goods2([CreateInfo|CreateRemain], [ID|RemainIDList], GoodsAcc, IsRecreate) ->
    CreateInfo2 = make_new_create_info(CreateInfo, IsRecreate),
    Goods = CreateInfo2#p_goods{id = ID},
    GoodsAcc2 = [Goods|GoodsAcc],
    create_new_goods2(CreateRemain, RemainIDList, GoodsAcc2, IsRecreate).

make_new_create_info(CreateInfo, _IsRecreate) ->
    #p_goods{
        bind = Bind,
        end_time = EndTime,
        start_time = StartTime,
        type_id = TypeID,
        market_end_time = MarketEndTime} = CreateInfo,
    #c_item{
        effect_type = EffectType,
        effective_time = EffectiveTime,
        protect_time = ProtectTime,
        auction_sub_class = SubClass} = ItemConfig = mod_role_item:get_item_config(TypeID),
    {StartTime2, EndTime2} = get_new_create_end_time(EndTime, EffectiveTime, EffectType, StartTime),
    Now = time_tool:now(),
    MarketEndTime2 =
    case MarketEndTime > 0 of
        true ->
            MarketEndTime;
        _ ->
            ?IF(not Bind andalso ProtectTime > 0 andalso SubClass > 0, Now, MarketEndTime)
    end,
    CreateInfo2 = CreateInfo#p_goods{start_time = StartTime2, end_time = EndTime2, market_end_time = MarketEndTime2},
    make_new_create_info2(EffectType, CreateInfo2, ItemConfig).

make_new_create_info2(?ITEM_EQUIP, CreateInfo, _ItemConfig) ->
    #p_goods{type_id = TypeID, excellent_list = ExcellentList} = CreateInfo,
    ExcellentList2 = mod_role_equip:get_new_excellent(TypeID, ExcellentList),
    CreateInfo#p_goods{excellent_list = ExcellentList2};
make_new_create_info2(_EffectType, CreateInfo, _ItemConfig) ->
    CreateInfo.

%%获取道具结束时间戳
get_new_create_end_time(EndTime, EffectiveTime, EffectType, StartTime) ->
    if
        EndTime =/= 0 ->
            {StartTime, EndTime};
        EffectiveTime > 0 ->
            {?IF(EffectType =/= ?ITEM_USE_GUARD, time_tool:now(), StartTime), time_tool:now() + EffectiveTime};
        true ->
            {StartTime, 0}
    end.


%% 对可以覆盖的p_goods 进行合并
%% 返回{可覆盖的CreateList, 不可覆盖的CreateList}
get_create_modify_list(CreateList) ->
    get_create_modify_list(CreateList, mod_role_dict:get_category()).
get_create_modify_list(CreateList, Category) ->
    lists:foldl(
        fun(CreateInfo, {Acc1, Acc2}) ->
            #p_goods{type_id = TypeID, bind = Bind, num = Num, start_time = StartTime, end_time = EndTime} = CreateInfo,
            Bind2 = ?IF(erlang:is_boolean(Bind), Bind, ?IS_BIND(Bind)),
            ?IF((Num > 0 andalso Num =< ?MAX_ITEM_CREATE_NUM) orelse is_asset_item(TypeID), ok, erlang:throw(num_error)),
            #c_item{type_id = TypeID2, cover_num = CoverNum, effect_type = EffectType, effective_time = EffectiveTime} = mod_role_item:get_item_config(TypeID, Category),
            %% 部分道具根据职业生成，这里做一个处理
            CreateInfo2 = CreateInfo#p_goods{type_id = TypeID2},
            case ?IS_ITEM_COVER(CoverNum) of
                true ->
                    NewAcc1 = get_create_modify_list2(CreateInfo2#p_goods{bind = Bind2}, Acc1, []),
                    NewAcc2 = Acc2;
                _ ->
                    NewAcc1 = Acc1,
                    {StartTime2, EndTime2} = get_new_create_end_time(EndTime, EffectiveTime, EffectType, StartTime),
                    AddAcc2 = [CreateInfo2#p_goods{start_time = StartTime2, end_time = EndTime2, num = 1, bind = Bind2} || _ <- lists:seq(1, Num)],
                    NewAcc2 = AddAcc2 ++ Acc2
            end,
            {NewAcc1, NewAcc2}
        end, {[], []}, CreateList).

get_create_modify_list2(CreateInfo, [], Acc) ->
    [CreateInfo|Acc];
get_create_modify_list2(CreateInfo, [CreateInfo2|R], Acc) ->
    #p_goods{type_id = TypeID1, bind = Bind1, num = Num1} = CreateInfo,
    #p_goods{type_id = TypeID2, bind = Bind2, num = Num2} = CreateInfo2,
    case TypeID1 =:= TypeID2 andalso Bind1 =:= Bind2 of
        true ->
            [CreateInfo2#p_goods{num = Num1 + Num2}|R] ++ Acc;
        _ ->
            get_create_modify_list2(CreateInfo, R, [CreateInfo2|Acc])
    end.

get_other_doings([], _Action, _ReduceRate, _State, CreateList, BagOtherDoings, CallBacks, KVList) ->
    {CreateList, BagOtherDoings, CallBacks, KVList};
get_other_doings([Goods|R], Action, ReduceRate, State, CreateAcc, BagOtherDoings, CallBacks, KVList) ->
    #p_goods{type_id = TypeID, num = Num} = Goods,
    #c_item{effect_type = EffectType, effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
    KV = #p_kv{id = TypeID, val = Num},
    #r_bag_other_doing{
        add_exp = AddExp,
        add_essence = AddEssence,
        add_rune_exp = AddRuneExp,
        asset_doings = AssetDoings,
        rune_doings = RuneDoings,
        immortal_soul_doings = ImmortalSoulDoings,
        immortal_soul_stone = ImmortalSoulStone,
        add_mythical_equips = MythicalEquips,
        add_war_spirit_equips = WarSpiritEquips,
        add_handbook_essence = AddHandBookEssence,
        add_throne_essence = AddThroneEssence,
        talent_points = AddTalentPoints,
        training_point = TrainingPoint,
        intensify_nature = IntensifyNature
%%        add_war_god_pieces = AddWarGodPieces
    } = BagOtherDoings,
    if
        TypeID =:= ?BAG_ASSET_SILVER -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_silver, Action, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ASSET_GOLD -> %% 防沉迷衰减在mod_role_asset里
            Asset = {add_gold, Action, Num, 0},
            AssetDoings2 = [Asset|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ASSET_BIND_GOLD -> %% 防沉迷衰减在mod_role_asset里
            Asset = {add_gold, Action, 0, Num},
            AssetDoings2 = [Asset|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_GLORY -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_GLORY, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_PRESTIGE -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_PRESTIGE, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_FAMILY_MONEY ->
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            #r_role{role_attr = #r_role_attr{family_id = FamilyID}} = State,
            Fun = fun() -> mod_family_operation:add_family_money(FamilyID, Num2) end,
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings, [Fun|CallBacks], [KV|KVList]);
        TypeID =:= ?BAG_ITEM_FORGE_SOUL -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_FORGE_SOUL, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_WAR_GOD_SCORE -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_WAR_GOD_SCORE, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_HUNT_TREASURE_SCORE -> %% 宝珠 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_HUNT_TREASURE_SCORE, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_TALENT_SKILL -> %% 天赋技能
            TalentPoints = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{talent_points = AddTalentPoints + TalentPoints},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_FAMILY_CON -> %% 防沉迷衰减在mod_role_asset里
            AssetDoings2 = [{add_score, Action, ?ASSET_FAMILY_CON, Num}|AssetDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{asset_doings = AssetDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_RUNE_EXP -> %% 符文经验
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_rune_exp = AddRuneExp + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ITEM_EXP -> %% 防沉迷衰减在mod_role_level里
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_exp = AddExp + Num},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_RUNE_ESSENCE -> %% 符文精粹
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_essence = AddEssence + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_ACT_RUNE_BOX -> %% 符文活动宝箱
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BoxID = mod_role_copy:get_tower_act_box(State),
            CreateAcc2 = ?IF(BoxID > 0 andalso Num2 > 0, [Goods#p_goods{type_id = BoxID, num = Num2}|CreateAcc], CreateAcc),
            get_other_doings(R, Action, ReduceRate, State, CreateAcc2, BagOtherDoings, CallBacks, KVList);
        EffectType =:= ?ITEM_ADD_RUNE -> %% 符文
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            RuneDoings2 = lists:duplicate(Num2, lib_tool:to_integer(EffectArgs)) ++ RuneDoings,
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{rune_doings = RuneDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        EffectType =:= ?ITEM_WORLD_LEVEL -> %% 根据世界等级获取当前装备
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            ItemID = get_world_level_item(TypeID),
            CreateAcc2 = ?IF(ItemID > 0 andalso Num2 > 0, [Goods#p_goods{type_id = ItemID, num = Num2}|CreateAcc], CreateAcc),
            get_other_doings(R, Action, ReduceRate, State, CreateAcc2, BagOtherDoings, CallBacks, KVList);
        EffectType =:= ?ITEM_IMMORTAL_SOUL -> %% 仙魂
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            ImmortalSoulDoings2 = [{TypeID, Num2}|ImmortalSoulDoings],
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{immortal_soul_doings = ImmortalSoulDoings2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        EffectType =:= ?ITEM_IMMORTAL_SOUL_STONE -> %% 仙魂石
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            ImmortalSoulStone2 = ImmortalSoulStone + Num2,
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{immortal_soul_stone = ImmortalSoulStone2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        EffectType =:= ?ITEM_MYTHICAL_EQUIP -> %% 魂兽装备
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = ?IF(Num2 > 0,
                                  BagOtherDoings#r_bag_other_doing{add_mythical_equips = [TypeID || _Index <- lists:seq(1, Num2)] ++ MythicalEquips},
                                  BagOtherDoings),
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        EffectType =:= ?ITEM_WAR_SPIRIT_EQUIP -> %% 战灵灵饰
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = ?IF(Num2 > 0,
                                  BagOtherDoings#r_bag_other_doing{add_war_spirit_equips = [TypeID || _Index <- lists:seq(1, Num2)] ++ WarSpiritEquips},
                                  BagOtherDoings),
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_HANDBOOK_ESSENCE -> %% 图鉴卡片精华
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_handbook_essence = AddHandBookEssence + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_THRONE_ESSENCE -> %% 宝座精华
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_throne_essence = AddThroneEssence + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
%%        EffectType =:= ?ITEM_WAR_GOD_PIECE -> %% 战神套装
%%            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
%%            AddWarGodPieces2 = ?IF(Num2 > 0, [#p_kv{id = TypeID, val = Num2}|AddWarGodPieces], AddWarGodPieces),
%%            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{add_war_god_pieces = AddWarGodPieces2},
%%            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_NAT_INTENSIFY_GOODS -> %% 天机勾玉
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{intensify_nature = IntensifyNature + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        TypeID =:= ?BAG_TRAINING_POINT -> %% 修炼点
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            BagOtherDoings2 = BagOtherDoings#r_bag_other_doing{training_point = TrainingPoint + Num2},
            get_other_doings(R, Action, ReduceRate, State, CreateAcc, BagOtherDoings2, CallBacks, [KV|KVList]);
        true ->
            Num2 = mod_role_addict:get_addict_num2(Num, ReduceRate),
            CreateAcc2 = ?IF(Num2 =:= 0, CreateAcc, [Goods#p_goods{num = Num2}|CreateAcc]),
            get_other_doings(R, Action, ReduceRate, State, CreateAcc2, BagOtherDoings, CallBacks, KVList)
    end.

%% 删除物品
delete_goods([], _BagID, State) ->
    {ok, State, [], []};
delete_goods(IDList, BagID, State) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = GoodsList} = BagContent = get_bag(BagID, RoleBag),
    case delete_goods2(IDList, GoodsList, [], [], []) of
        {ok, GoodsList2, LogGoodsList, Changes} ->
            BagContent2 = BagContent#p_bag_content{goods_list = GoodsList2},
            RoleBag2 = set_bag(BagContent2, RoleBag),
            State2 = State#r_role{role_bag = RoleBag2},
            {ok, State2, merge_goods_log(LogGoodsList), Changes};
        {remain, IDList} ->
            erlang:throw({error, id_remain, IDList})
    end.

delete_goods2([], GoodsList, GoodsListAcc, LogGoodsAcc, ChangeAcc) ->
    {ok, GoodsList ++ GoodsListAcc, LogGoodsAcc, ChangeAcc};
delete_goods2(IDList, [], _GoodsListAcc, _LogGoodsAcc, _ChangeAcc) ->
    {remain, IDList};
delete_goods2(IDList, [#p_goods{id = ID, type_id = TypeID} = Goods|GoodsRemain], GoodsListAcc, LogGoodsAcc, ChangeAcc) ->
    case lists:member(ID, IDList) of
        true ->
            IDList2 = lists:delete(ID, IDList),
            LogGoodsAcc2 = [Goods|LogGoodsAcc],
            GoodsListAcc2 = GoodsListAcc,
            ChangeAcc2 = ?IF(lists:member(TypeID, ChangeAcc), ChangeAcc, [TypeID|ChangeAcc]);
        _ ->
            IDList2 = IDList,
            LogGoodsAcc2 = LogGoodsAcc,
            GoodsListAcc2 = [Goods|GoodsListAcc],
            ChangeAcc2 = ChangeAcc
    end,
    delete_goods2(IDList2, GoodsRemain, GoodsListAcc2, LogGoodsAcc2, ChangeAcc2).


%% 减少物品
%% [#r_goods_decrease_info{}|_]
%% 返回{ok, State, UpdateList, DelList}
decrease_goods([], _BagID, State) ->
    {ok, State, [], [], [], []};
decrease_goods(DecreaseList, BagID, State) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = GoodsList} = BagContent = get_bag(BagID, RoleBag),
    {IDList, FirstBindList, BindList, UnBindList} = get_decrease_modify_list(DecreaseList),
    {GoodsList2, UpdateList2, DelList2, LogList1, Changes1} = decrease_id_goods(IDList, GoodsList, [], [], [], [], []),
    {GoodsList3, [], UpdateList3, DelList3, LogList2, Changes2} = decrease_goods_by_bind(GoodsList2, BindList, true, [], [], [], [], []),
    {GoodsList4, FirstBindList2, UpdateList4, DelList4, LogList3, Changes3} = decrease_goods_by_bind(GoodsList3, FirstBindList, true, [], [], [], [], []),
    {GoodsList5, [], UpdateList5, DelList5, LogList4, Changes4} = decrease_goods_by_bind(GoodsList4, UnBindList ++ FirstBindList2, false, [], [], [], [], []),

    UpdateList6 = lib_tool:list_filter_repeat(UpdateList2 ++ UpdateList3 ++ UpdateList4 ++ UpdateList5),
    FinalUpdate = get_update(GoodsList5, UpdateList6, []),
    FinalDelete = DelList2 ++ DelList3 ++ DelList4 ++ DelList5,
    FinalLogList = merge_goods_log(LogList1 ++ LogList2 ++ LogList3 ++ LogList4),
    Changes = lib_tool:list_filter_repeat(Changes1 ++ Changes2 ++ Changes3 ++ Changes4),
    BagContent2 = BagContent#p_bag_content{goods_list = GoodsList5},
    RoleBag2 = set_bag(BagContent2, RoleBag),
    State2 = State#r_role{role_bag = RoleBag2},
    {ok, State2, FinalUpdate, FinalDelete, FinalLogList, Changes}.

%% 通过id减少物品
decrease_id_goods([], GoodsList, GoodsAcc, UpdateList, DelList, LogList, ChangesAcc) ->
    {lists:reverse(GoodsAcc) ++ GoodsList, UpdateList, DelList, LogList, ChangesAcc};
decrease_id_goods(DecreaseList, [], _GoodsAcc, _UpdateList, _DelList, _LogList, _ChangesAcc) ->
    erlang:throw({error, decrease_list, DecreaseList});
decrease_id_goods(DecreaseList, [Goods|GoodsRemain], GoodsAcc, UpdateList, DelList, LogList, ChangesAcc) ->
    #p_goods{id = ID, type_id = TypeID, bind = Bind, num = Num} = Goods,
    case lists:keytake(ID, #r_goods_decrease_info.id, DecreaseList) of
        {value, DecreaseInfo, DecreaseList2} ->
            #r_goods_decrease_info{num = DecreaseNum} = DecreaseInfo,
            RemainNum = Num - DecreaseNum,
            LogGoods = #p_goods{type_id = TypeID, bind = Bind, num = DecreaseNum},
            if
                RemainNum > 0 ->
                    Goods2 = Goods#p_goods{num = RemainNum},
                    decrease_id_goods(DecreaseList2, GoodsRemain, [Goods2|GoodsAcc], [ID|UpdateList], DelList, [LogGoods|LogList], [TypeID|ChangesAcc]);
                RemainNum =:= 0 ->
                    decrease_id_goods(DecreaseList2, GoodsRemain, GoodsAcc, UpdateList, [ID|DelList], [LogGoods|LogList], [TypeID|ChangesAcc]);
                true ->
                    erlang:throw({error, num_not_enouth, ID, Num, DecreaseNum})
            end;
        _ ->
            decrease_id_goods(DecreaseList, GoodsRemain, [Goods|GoodsAcc], UpdateList, DelList, LogList, ChangesAcc)
    end.

%% 扣除对应绑定/不绑定的道具
decrease_goods_by_bind([], DecreaseList, _Bind, GoodsAcc, UpdateList, DelList, LogList, ChangesAcc) ->
    {lists:reverse(GoodsAcc), DecreaseList, UpdateList, DelList, LogList, ChangesAcc};
decrease_goods_by_bind(GoodsList, [], _Bind, GoodsAcc, UpdateList, DelList, LogList, ChangesAcc) ->
    {lists:reverse(GoodsAcc) ++ GoodsList, [], UpdateList, DelList, LogList, ChangesAcc};
decrease_goods_by_bind([Goods|GoodsRemain], DecreaseList, Bind, GoodsAcc, UpdateList, DelList, LogList, ChangesAcc) ->
    #p_goods{id = ID, type_id = TypeID, num = Num1, bind = Bind2} = Goods,
    case Bind =:= Bind2 of %% 绑定属性相同
        true ->
            case lists:keytake(TypeID, #r_goods_decrease_info.type_id, DecreaseList) of
                {value, DecreaseInfo, DecreaseList2} ->
                    #r_goods_decrease_info{num = Num2} = DecreaseInfo,
                    if
                        Num1 =:= Num2 -> %% 正好扣除
                            LogGoods = #p_goods{type_id = TypeID, bind = Bind2, num = Num2},
                            decrease_goods_by_bind(GoodsRemain, DecreaseList2, Bind, GoodsAcc, UpdateList, [ID|DelList], [LogGoods|LogList], [TypeID|ChangesAcc]);
                        Num1 > Num2 -> %% 背包数量比这个多
                            Goods2 = Goods#p_goods{num = Num1 - Num2},
                            LogGoods = #p_goods{type_id = TypeID, bind = Bind2, num = Num2},
                            decrease_goods_by_bind(GoodsRemain, DecreaseList2, Bind, [Goods2|GoodsAcc], [ID|UpdateList], DelList, [LogGoods|LogList], [TypeID|ChangesAcc]);
                        Num1 < Num2 -> %% 背包数量比这个少
                            DecreaseInfo2 = DecreaseInfo#r_goods_decrease_info{num = Num2 - Num1},
                            LogGoods = #p_goods{type_id = TypeID, bind = Bind2, num = Num1},
                            decrease_goods_by_bind(GoodsRemain, [DecreaseInfo2|DecreaseList2], Bind, GoodsAcc, UpdateList, [ID|DelList], [LogGoods|LogList], [TypeID|ChangesAcc])
                    end;
                _ ->
                    decrease_goods_by_bind(GoodsRemain, DecreaseList, Bind, [Goods|GoodsAcc], UpdateList, DelList, LogList, ChangesAcc)
            end;
        _ ->
            decrease_goods_by_bind(GoodsRemain, DecreaseList, Bind, [Goods|GoodsAcc], UpdateList, DelList, LogList, ChangesAcc)
    end.

get_decrease_modify_list(DecreaseList) ->
    lists:foldl(
        fun(DecreaseInfo, {Acc1, Acc2, Acc3, Acc4}) ->
            #r_goods_decrease_info{id = ID, type = Type, num = Num} = DecreaseInfo,
            ?IF(Num > 0, ok, erlang:throw(num_error)),
            if
                ID > 0 -> %% 需要优先扣除带ID的
                    {[DecreaseInfo|Acc1], Acc2, Acc3, Acc4};
                Type =:= first_bind -> %% 优先扣除绑定
                    {Acc1, get_decrease_modify_list2(DecreaseInfo, Acc2, []), Acc3, Acc4};
                Type =:= must_bind ->  %% 必须扣除绑定
                    {Acc1, Acc2, get_decrease_modify_list2(DecreaseInfo, Acc3, []), Acc4};
                Type =:= must_unbind ->  %% 必须扣除不绑定
                    {Acc1, Acc2, Acc3, get_decrease_modify_list2(DecreaseInfo, Acc4, [])}
            end
        end, {[], [], [], []}, DecreaseList).

get_decrease_modify_list2(DecreaseInfo, [], Acc) ->
    [DecreaseInfo|Acc];
get_decrease_modify_list2(DecreaseInfo, [DecreaseInfo2|R], Acc) ->
    #r_goods_decrease_info{type_id = TypeID1, num = Num1} = DecreaseInfo,
    #r_goods_decrease_info{type_id = TypeID2, num = Num2} = DecreaseInfo2,
    case TypeID1 =:= TypeID2 of
        true ->
            [DecreaseInfo2#r_goods_decrease_info{num = Num1 + Num2}|R] ++ Acc;
        _ ->
            get_decrease_modify_list2(DecreaseInfo, R, [DecreaseInfo2|Acc])
    end.

get_update([], _IDList, UpdateAcc) ->
    UpdateAcc;
get_update(_GoodsList, [], UpdateAcc) ->
    UpdateAcc;
get_update([Goods|GoodsRemain], IDList, UpdateAcc) ->
    #p_goods{id = ID} = Goods,
    case lists:member(ID, IDList) of
        true ->
            IDList2 = lists:delete(ID, IDList),
            get_update(GoodsRemain, IDList2, [Goods|UpdateAcc]);
        _ ->
            get_update(GoodsRemain, IDList, UpdateAcc)
    end.

%% 整理道具
do_merge(RoleID, MergeList, State) ->
    case catch check_can_merge(MergeList, State) of
        {ok, State2, UpdateList, DelList} ->
            ?IF(UpdateList =/= [] orelse DelList =/= [], common_misc:unicast(RoleID, #m_bag_update_toc{update_list = UpdateList, del_list = DelList}), ok),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bag_merge_toc{err_code = ErrCode}),
            State
    end.

check_can_merge(MergeList, State) ->
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = GoodsList} = BagContent = get_bag(RoleBag),
    MergeList2 = [BagMerge || #p_bag_merge{id_list = IDList} = BagMerge <- MergeList, IDList =/= []],
    {GoodsList2, UpdateList, DelList} = check_can_merge2(MergeList2, GoodsList, time_tool:now(), [], [], []),
    BagContent2 = BagContent#p_bag_content{goods_list = GoodsList2},
    RoleBag2 = set_bag(BagContent2, RoleBag),
    {ok, State#r_role{role_bag = RoleBag2}, UpdateList, DelList}.

%% 对所有可合并分组进行操作
check_can_merge2([], GoodsRemain, _Now, NewGoods, UpdateList, DelList) ->
    {NewGoods ++ GoodsRemain, UpdateList, DelList};
check_can_merge2([BagMerge|R], GoodsRemain, Now, GoodsAcc, UpdateAcc, DelAcc) ->
    #p_bag_merge{id_list = IDList} = BagMerge,
    {[#p_goods{type_id = TypeID}|_] = MergeGoods, GoodsRemain2} = get_merge_goods(IDList, GoodsRemain, [], []),
    #c_item{cover_num = CoverNum} = mod_role_item:get_item_config(TypeID),
    {MergeGoods2, FullList} =
    lists:foldl(
        fun(#p_goods{num = Num} = Goods, {MergeAcc, FullAcc}) ->
            ?IF(Num >= CoverNum, {MergeAcc, [Goods|FullAcc]}, {[Goods|MergeAcc], FullAcc})
        end, {[], []}, MergeGoods),
    MergeGoods3 = lists:keysort(#p_goods.id, MergeGoods2),
    {GoodsAcc2, UpdateList, DelList} = check_can_merge3(MergeGoods3, CoverNum, Now, [], [], []),
    check_can_merge2(R, GoodsRemain2, Now, FullList ++ GoodsAcc2 ++ GoodsAcc, UpdateList ++ UpdateAcc, DelList ++ DelAcc).

%% 对单个分组进行操作
check_can_merge3([], _CoverNum, _Now, GoodsList, UpdateIDList, DelList) ->
    UpdateList = get_update(GoodsList, UpdateIDList, []),
    {GoodsList, UpdateList, DelList};
check_can_merge3([Goods|R], CoverNum, Now, GoodsAcc, UpdateIDAcc, DelAcc) ->
    {NewGoods, R2, UpdateIDList, DelList} = check_can_merge4(Goods, R, CoverNum, Now, [], []),
    check_can_merge3(R2, CoverNum, Now, [NewGoods|GoodsAcc], lib_tool:list_filter_repeat(UpdateIDList ++ UpdateIDAcc), DelList ++ DelAcc).

%% 开始合并
check_can_merge4(Goods, [], _CoverNum, _Now, UpdateAcc, DelAcc) ->
    {Goods, [], UpdateAcc, DelAcc};
check_can_merge4(Goods, [MergeGoods|R], CoverNum, Now, UpdateAcc, DelAcc) ->
    #p_goods{id = ID1, type_id = TypeID1, bind = Bind1, market_end_time = MarketEndTime1, num = Num1} = Goods,
    #p_goods{id = ID2, type_id = TypeID2, bind = Bind2, market_end_time = MarketEndTime2, num = Num2} = MergeGoods,
    case TypeID1 =:= TypeID2 andalso Bind1 =:= Bind2 andalso is_market_time_merge(Now, MarketEndTime1, MarketEndTime2) of %% 可以合并
        true ->
            ?IF(CoverNum > 1, ok, ?THROW_ERR(?ERROR_BAG_MERGE_001)),
            if

                Num1 >= CoverNum ->  %% 本身就已经超过上限
                    {Goods, [MergeGoods|R], UpdateAcc, DelAcc};
                (Num1 + Num2) > CoverNum -> %% 超过上限
                    Goods2 = Goods#p_goods{num = CoverNum},
                    MergeGoods2 = MergeGoods#p_goods{num = Num1 + Num2 - CoverNum},
                    {Goods2, [MergeGoods2|R], [ID1, ID2|UpdateAcc], DelAcc};
                (Num1 + Num2) =:= CoverNum -> %% 正好达到上限
                    Goods2 = Goods#p_goods{num = CoverNum},
                    {Goods2, R, [ID1|UpdateAcc], [ID2|DelAcc]};
                true ->
                    Goods2 = Goods#p_goods{num = Num1 + Num2},
                    check_can_merge4(Goods2, R, CoverNum, Now, [ID1|UpdateAcc], [ID2|DelAcc])
            end;
        _ ->
            ?THROW_ERR(?ERROR_BAG_MERGE_001)
    end.

get_merge_goods([], GoodsList, GoodsAcc, MergeAcc) ->
    {MergeAcc, GoodsAcc ++ GoodsList};
get_merge_goods(_IDList, [], _GoodsAcc, _MergeAcc) ->
    ?THROW_ERR(?ERROR_BAG_MERGE_001);
get_merge_goods(IDList, [#p_goods{id = ID} = Goods|R], GoodsAcc, MergeAcc) ->
    case lists:member(ID, IDList) of
        true ->
            IDList2 = lists:delete(ID, IDList),
            get_merge_goods(IDList2, R, GoodsAcc, [Goods|MergeAcc]);
        _ ->
            get_merge_goods(IDList, R, [Goods|GoodsAcc], MergeAcc)
    end.

merge_goods_log(Goods) ->
    merge_goods_log(Goods, []).
merge_goods_log([], LogAcc) ->
    [#p_goods{type_id = TypeID, bind = Bind, num = Num} || {{TypeID, Bind}, Num} <- LogAcc];
merge_goods_log([Goods|R], LogAcc) ->
    #p_goods{type_id = TypeID, bind = Bind, num = Num} = Goods,
    case lists:keyfind({TypeID, Bind}, 1, LogAcc) of
        {{TypeID, Bind}, OldNum} ->
            NewNum = OldNum + Num,
            LogAcc2 = lists:keyreplace({TypeID, Bind}, 1, LogAcc, {{TypeID, Bind}, NewNum});
        _ ->
            LogAcc2 = [{{TypeID, Bind}, Num}|LogAcc]
    end,
    merge_goods_log(R, LogAcc2).

do_grid_open(RoleID, BagID, AddNum, State) ->
    case catch check_grid_open(BagID, AddNum, State) of
        {ok, OpenBagGrid, BagGrid, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_bag_grid_open_toc{bag_id = BagID, bag_grid = BagGrid}),
            State3 = mod_role_bag:do(BagDoings, State2),
            if
                BagID =:= ?BAG_ID_BAG ->
                    mod_role_achievement:bag_grid_open(OpenBagGrid, State3);
                BagID =:= ?BAG_ID_DEPOT ->
                    mod_role_achievement:depot_grid_open(OpenBagGrid, State3);
                true ->
                    State3
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bag_grid_open_toc{err_code = ErrCode}),
            State
    end.

check_grid_open(BagID, AddNum, State) ->
    ?IF(AddNum > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{bag_grid = BagGrid} = BagContent = get_bag(BagID, RoleBag),
    {MinGrid, MaxGrid} = get_bag_grid_config(BagID),
    TypeID = common_misc:get_global_int(?GLOBAL_BAG_GRID),
    ?IF(BagGrid >= MaxGrid, ?THROW_ERR(?ERROR_BAG_GRID_OPEN_001), ok),
    AddNum2 = erlang:min(AddNum, (MaxGrid - BagGrid)),
    ItemNum = AddNum2 * ?BAG_KEY_NUM,
%%    {AddNum2, ItemNum} = check_grid_open2(AddNum, NowIndex, 0, 0),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, ItemNum, ?ITEM_REDUCE_BAG_GRID_OPEN, State),
    BagGrid2 = BagGrid + AddNum2,
    BagContent2 = BagContent#p_bag_content{bag_grid = BagGrid2},
    RoleBag2 = set_bag(BagContent2, RoleBag),
    State2 = State#r_role{role_bag = RoleBag2},
    {ok, BagGrid2 - MinGrid, BagGrid2, BagDoings, State2}.

%%check_grid_open2(0, _Index, AddNumAcc, ItemNumAcc) ->
%%    {AddNumAcc, ItemNumAcc};
%%check_grid_open2(AddNum, NowIndex, AddNumAcc, ItemNumAcc) ->
%%    Index = NowIndex + 1,
%%    case lib_config:find(cfg_bag_grid, Index) of
%%        [#c_bag_grid{num = Num}] ->
%%            ItemNumAcc2 = Num + ItemNumAcc,
%%            check_grid_open2(AddNum - 1, Index, AddNumAcc + 1, ItemNumAcc2);
%%        _ ->
%%            {AddNumAcc, ItemNumAcc}
%%    end.

%% 道具移动
do_bag_depot(RoleID, FromID, ToID, GoodsID, State) ->
    case catch check_bag_depot(FromID, ToID, GoodsID, State) of
        {ok, TypeID, UpdateList, State2} ->
            common_misc:unicast(RoleID, #m_bag_depot_toc{}),
            common_misc:unicast(RoleID, #m_bag_update_toc{update_list = UpdateList, del_list = [GoodsID]}),
            mod_role_mission:item_trigger([TypeID], State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bag_depot_toc{err_code = ErrCode}),
            State
    end.

check_bag_depot(FromID, ToID, GoodsID, State) ->
    if
        FromID =:= ?BAG_ID_BAG andalso ToID =:= ?BAG_ID_DEPOT -> %% 从背包到个人仓库
            ok;
        (FromID =:= ?BAG_ID_DEPOT orelse FromID =:= ?BAG_ID_TREASURE orelse FromID =:= ?BAG_ID_TREVI_FOUNTAIN orelse FromID =:= ?BAG_ID_ALCHEMY orelse FromID =:= ?BAG_ID_CYCLE_TOWER)
        andalso ToID =:= ?BAG_ID_BAG -> %% 从其他仓库到背包
            ok;
        true ->
            ?THROW_ERR(?ERROR_BAG_DEPOT_001)
    end,
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = FromGoodsList} = FromBagContent = get_bag(FromID, RoleBag),
    case lists:keytake(GoodsID, #p_goods.id, FromGoodsList) of
        {value, FromGoods, FromGoodsList2} ->
            ok;
        _ ->
            FromGoods = FromGoodsList2 = ?THROW_ERR(?ERROR_COMMON_NO_BAG_GOODS)
    end,
    mod_role_bag:check_bag_empty_grid(ToID, 1, State),
    #p_bag_content{goods_list = ToGoodsList, bag_grid = MaxBagGrid} = ToBagContent = get_bag(ToID, RoleBag),
    {ToGoodsList2, CreateList, UpdateList} = update_bag_goods(ToGoodsList, [FromGoods], time_tool:now(), [], []),
    case CreateList =/= [] of
        true ->
            UsedList = [ID || #p_goods{id = ID} <- ToGoodsList2],
            AllID = get_bag_ids(ToID, MaxBagGrid),
            RemainIDList = AllID -- UsedList,
            CreateList2 = do_depot_create(CreateList, RemainIDList, []),
            UpdateList2 = CreateList2 ++ UpdateList,
            ToGoodsList3 = CreateList2 ++ ToGoodsList2;
        _ ->
            UpdateList2 = UpdateList,
            ToGoodsList3 = ToGoodsList2
    end,
    FromBagContent2 = FromBagContent#p_bag_content{goods_list = FromGoodsList2},
    ToBagContent2 = ToBagContent#p_bag_content{goods_list = ToGoodsList3},
    RoleBag2 = set_bag(FromBagContent2, RoleBag),
    RoleBag3 = set_bag(ToBagContent2, RoleBag2),
    State2 = State#r_role{role_bag = RoleBag3},
    {ok, FromGoods#p_goods.type_id, UpdateList2, State2}.

%% 道具移动
do_all_depot(RoleID, BagID, State) ->
    case catch check_all_depot(BagID, State) of
        {ok, UpdateList, DelList, ChangeList, State2} ->
            common_misc:unicast(RoleID, #m_bag_all_depot_toc{}),
            common_misc:unicast(RoleID, #m_bag_update_toc{update_list = UpdateList, del_list = DelList}),
            mod_role_mission:item_trigger(ChangeList, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bag_all_depot_toc{err_code = ErrCode}),
            State
    end.

check_all_depot(BagID, State) ->
    if
        BagID =:= ?BAG_ID_TREASURE -> %% 从寻宝仓库到背包
            ok;
        BagID =:= ?BAG_ID_TREVI_FOUNTAIN -> %% 从许愿池到背包
            ok;
        BagID =:= ?BAG_ID_ALCHEMY -> %% 从新炼丹到背包
            ok;
        BagID =:= ?BAG_ID_CYCLE_TOWER -> %% 从周期活动宝塔到背包
            ok;
        true ->
            ?THROW_ERR(?ERROR_BAG_DEPOT_001)
    end,
    #r_role{role_bag = RoleBag} = State,
    #p_bag_content{goods_list = FromGoodsList} = FromBagContent = get_bag(BagID, RoleBag),
    #p_bag_content{goods_list = ToGoodsList, bag_grid = MaxBagGrid} = ToBagContent = get_bag(RoleBag),
    EmptyGrid = MaxBagGrid - erlang:length(ToGoodsList),
    ?IF(EmptyGrid > 0, ok, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)),
    {FromGoodsList2, RemainGoodsList} = lib_tool:split(EmptyGrid, FromGoodsList),
    {DelList, ChangeList} =
    lists:foldl(
        fun(Goods, {Acc1, Acc2}) ->
            #p_goods{id = DelID, type_id = DelTypeID} = Goods,
            NewAcc1 = [DelID|Acc1],
            NewAcc2 = ?IF(lists:member(DelTypeID, Acc2), Acc2, [DelTypeID|Acc2]),
            {NewAcc1, NewAcc2}
        end, {[], []}, FromGoodsList2),
    {ToGoodsList2, CreateList, UpdateList} = update_bag_goods(ToGoodsList, FromGoodsList2, time_tool:now(), [], []),
    case CreateList =/= [] of
        true ->
            UsedList = [ID || #p_goods{id = ID} <- ToGoodsList2],
            AllID = get_bag_ids(?BAG_ID_BAG, MaxBagGrid),
            RemainIDList = AllID -- UsedList,
            CreateList2 = do_depot_create(CreateList, RemainIDList, []),
            UpdateList2 = CreateList2 ++ UpdateList,
            ToGoodsList3 = CreateList2 ++ ToGoodsList2;
        _ ->
            UpdateList2 = UpdateList,
            ToGoodsList3 = ToGoodsList2
    end,
    FromBagContent2 = FromBagContent#p_bag_content{goods_list = RemainGoodsList},
    ToBagContent2 = ToBagContent#p_bag_content{goods_list = ToGoodsList3},
    RoleBag2 = set_bag(FromBagContent2, RoleBag),
    RoleBag3 = set_bag(ToBagContent2, RoleBag2),
    State2 = State#r_role{role_bag = RoleBag3},
    {ok, UpdateList2, DelList, ChangeList, State2}.

do_depot_create([], _RemainIDList, Acc) ->
    Acc;
do_depot_create([Goods|R1], [ID|R2], Acc) ->
    Acc2 = [Goods#p_goods{id = ID}|Acc],
    do_depot_create(R1, R2, Acc2).

do_bag_item_self(RoleID, KVList, State) ->
    #r_role{role_id = RoleID, role_bag = RoleBag} = State,
    #r_role_bag{bag_list = BagList} = RoleBag,
    case catch check_bag_item_self(KVList, BagList, [], []) of
        {ok, BagList2, UpdateList} ->
            common_misc:unicast(RoleID, #m_bag_update_toc{update_list = UpdateList}),
            RoleBag2 = RoleBag#r_role_bag{bag_list = BagList2},
            State#r_role{role_bag = RoleBag2};
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bag_item_self_toc{err_code = ErrCode}),
            State
    end.

check_bag_item_self([], BagAcc, UpdateAcc, AddGoodsAcc) ->
    check_bag_item_self3(AddGoodsAcc, BagAcc, UpdateAcc);
check_bag_item_self([#p_kv{id = ID, val = SelfNum}|R], BagAcc, UpdateAcc, AddGoodsAcc) ->
    BagID = get_bag_id_by_id(ID),
    {value, #p_bag_content{goods_list = GoodsList} = BagContent, BagAcc2} = lists:keytake(BagID, #p_bag_content.bag_id, BagAcc),
    case lists:keytake(ID, #p_goods.id, GoodsList) of
        {value, #p_goods{num = Num} = Goods, GoodsList2} ->
            ?IF(SelfNum > 0 andalso Num >= SelfNum, ok, ?THROW_ERR(?ERROR_BAG_ITEM_SELF_002)),
            {GoodsList3, AddGoodsAcc2} =
            case SelfNum >= Num of
                true ->
                    Goods2 = Goods#p_goods{bind = true, market_end_time = 0},
                    {[Goods2|GoodsList2], AddGoodsAcc};
                _ ->
                    Goods2 = Goods#p_goods{num = Num - SelfNum},
                    {[Goods2|GoodsList2], check_bag_item_self2(BagID, Goods#p_goods{bind = true, market_end_time = 0, num = SelfNum}, AddGoodsAcc)}
            end,
            BagContent2 = BagContent#p_bag_content{goods_list = GoodsList3},
            check_bag_item_self(R, [BagContent2|BagAcc2], [Goods2|UpdateAcc], AddGoodsAcc2);
        _ ->
            ?THROW_ERR(?ERROR_BAG_ITEM_SELF_001)
    end.

check_bag_item_self2(BagID, Goods, AddGoodsAcc) ->
    case lists:keytake(BagID, 1, AddGoodsAcc) of
        {value, {BagID, OldGoodsList}, AddGoodsAcc2} ->
            [{BagID, [Goods|OldGoodsList]}|AddGoodsAcc2];
        _ ->
            [{BagID, [Goods]}|AddGoodsAcc]
    end.

check_bag_item_self3([], BagAcc, UpdateAcc) ->
    {ok, BagAcc, UpdateAcc};
check_bag_item_self3([{BagID, GoodsList}|R], BagAcc, UpdateAcc) ->
    GoodsList2 = get_create_list(GoodsList),
    {value, #p_bag_content{goods_list = ToGoodsList, bag_grid = MaxBagGrid} = BagContent, BagAcc2} = lists:keytake(BagID, #p_bag_content.bag_id, BagAcc),
    EmptyGrid = MaxBagGrid - erlang:length(GoodsList2),
    ?IF(EmptyGrid > 0, ok, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)),
    {ToGoodsList2, CreateList, UpdateList} = update_bag_goods(ToGoodsList, GoodsList2, time_tool:now(), [], []),
    case CreateList =/= [] of
        true ->
            UsedList = [ID || #p_goods{id = ID} <- ToGoodsList2],
            AllID = get_bag_ids(BagID, MaxBagGrid),
            RemainIDList = AllID -- UsedList,
            CreateList2 = do_depot_create(CreateList, RemainIDList, []),
            UpdateList2 = CreateList2 ++ UpdateList,
            ToGoodsList3 = CreateList2 ++ ToGoodsList2;
        _ ->
            UpdateList2 = UpdateList,
            ToGoodsList3 = ToGoodsList2
    end,
    BagContent2 = BagContent#p_bag_content{goods_list = ToGoodsList3},
    check_bag_item_self3(R, [BagContent2|BagAcc2], UpdateAcc ++ UpdateList2).

%% 道具获取广播
item_common_notice(State, Action, NoticeGoods) ->
    case lists:member(Action, ?ITEM_COMMON_NOTICE_IGNORE) of
        true ->
            ok;
        _ ->
            NoticeGoods2 = get_notice_goods(NoticeGoods, []),
            NoticeID =
            case lib_config:find(cfg_notice_condition, Action) of
                [#c_notice_condition{notice_id = NoticeIDT}] ->
                    NoticeIDT;
                _ ->
                    ?NOTICE_ITEM_GET
            end,
            ?IF(NoticeGoods2 =/= [], common_broadcast:send_world_common_notice(NoticeID, [mod_role_data:get_role_name(State)], NoticeGoods2), ok)
    end.

get_notice_goods([], GoodsAcc) ->
    GoodsAcc;
get_notice_goods([Goods|R], GoodsAcc) ->
    #p_goods{type_id = TypeID} = Goods,
    GoodsAcc2 = ?IF(mod_role_item:is_item_notice(TypeID), [Goods|GoodsAcc], GoodsAcc),
    get_notice_goods(R, GoodsAcc2).


trans_to_log(State, LogList, Action) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID}} = State,
    [begin
         #log_item{
             role_id = RoleID,
             action = Action,
             type_id = TypeID,
             bind = common_misc:get_bool_int(Bind),
             num = Num,
             channel_id = ChannelID,
             game_channel_id = GameChannelID}
     end || #p_goods{type_id = TypeID, bind = Bind, num = Num} <- LogList].

%% 默认选择背包，如果要选择其他仓库，传对应ID
get_bag(RoleBag) ->
    get_bag(?BAG_ID_BAG, RoleBag).
get_bag(BagID, RoleBag) ->
    #r_role_bag{bag_list = BagList} = RoleBag,
    lists:keyfind(BagID, #p_bag_content.bag_id, BagList).

set_bag(BagContent, RoleBag) ->
    #r_role_bag{bag_list = BagList} = RoleBag,
    #p_bag_content{bag_id = BagID} = BagContent,
    BagList2 = lists:keystore(BagID, #p_bag_content.bag_id, BagList, BagContent),
    RoleBag#r_role_bag{bag_list = BagList2}.


get_bag_grid_config(BagID) ->
    [#c_bag_content{min_grid = MinGrid, max_grid = MaxGrid}] = lib_config:find(cfg_bag_content, BagID),
    {MinGrid, MaxGrid}.

get_bag_ids(BagID, MaxBagGrid) ->
    Index = (BagID - 1) * 1000 + 1,
    lists:seq(Index, Index + MaxBagGrid - 1).

get_bag_id_by_id(ID) ->
    ID div 1000 + 1.

%% 根据道具类型决定到哪个背包
get_bag_id_by_item(TypeID) when erlang:is_integer(TypeID) ->
    get_bag_id_by_item(mod_role_item:get_item_config(TypeID));
get_bag_id_by_item(ItemConfig) ->
    #c_item{item_type = ItemType} = ItemConfig,
    if
        ItemType =:= ?IS_TYPE_OF_NATURE -> %% 天机印材料到天机印背包
            ?BAG_ID_NATURE;
        true ->
            ?BAG_ID_BAG
    end.

get_world_level_item(TypeID) ->
    WorldLevel = world_data:get_world_level(),
    [#c_world_level_item{item_string = ItemString}] = lib_config:find(cfg_world_level_item, TypeID),
    LevelList = lib_tool:string_to_intlist(ItemString),
    LevelList2 = lists:reverse(lists:keysort(1, LevelList)),
    get_world_level_item2(TypeID, WorldLevel, LevelList2).

get_world_level_item2(TypeID, WorldLevel, []) ->
    ?ERROR_MSG("对应等级的TypeID不存在 : ~w", [{WorldLevel, TypeID}]);
get_world_level_item2(TypeID, WorldLevel, [{NeedLevel, ItemID}|R]) ->
    case WorldLevel >= NeedLevel of
        true ->
            ItemID;
        _ ->
            get_world_level_item2(TypeID, WorldLevel, R)
    end.

is_asset_item(TypeID) ->
    TypeID =< ?BAG_RUNE_ESSENCE.

is_market_time_merge(Now, MarketEndTime1, MarketEndTime2) ->
    (Now > MarketEndTime1 andalso Now > MarketEndTime2) orelse (MarketEndTime1 =:= MarketEndTime2).

%% 创建背包时根据类型判断进哪个背包
get_bag_create_list(CreateList) ->
    lists:foldl(
        fun(#p_goods{type_id = TypeID} = Goods, Acc) ->
            BagID = get_bag_id_by_item(TypeID),
            case lists:keytake(BagID, 1, Acc) of
                {value, {_BagID, OldList}, AccT} ->
                    [{BagID, [Goods|OldList]}|AccT];
                _ ->
                    [{BagID, [Goods]}|Acc]
            end
        end, [], CreateList).

%% [{BagID, [ID|...]}|....]
get_bag_del_list(DelIDList) ->
    lists:foldl(
        fun(ID, Acc) ->
            BagID = get_bag_id_by_id(ID),
            case lists:keytake(BagID, 1, Acc) of
                {value, {_BagID, OldList}, AccT} ->
                    [{BagID, [ID|OldList]}|AccT];
                _ ->
                    [{BagID, [ID]}|Acc]
            end
        end, [], DelIDList).

%% [{BagID, [#r_goods_decrease_info{}|...]}, .....]
get_bag_decrease_list(DecreaseList) ->
    lists:foldl(
        fun(#r_goods_decrease_info{id = ID, type_id = TypeID} = Decrease, Acc) ->
            BagID = ?IF(ID > 0, get_bag_id_by_id(ID), get_bag_id_by_item(TypeID)),
            case lists:keytake(BagID, 1, Acc) of
                {value, {_BagID, OldList}, AccT} ->
                    [{BagID, [Decrease|OldList]}|AccT];
                _ ->
                    [{BagID, [Decrease]}|Acc]
            end
        end, [], DecreaseList).