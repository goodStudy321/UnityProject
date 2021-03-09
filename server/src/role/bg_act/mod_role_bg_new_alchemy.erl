%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2019 17:58
%%%-------------------------------------------------------------------
-module(mod_role_bg_new_alchemy).
-author("WZP").
-include("proto/mod_role_bg_new_alchemy.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("role.hrl").
-include("bg_act.hrl").

%% API
-export([
    handle/2,
    online/1,
    check_can_buy/2,
    function_open/1,
    time_store_online/1,
    new_alchemy_online/2,
    gm_add_times/3
]).


new_alchemy_online(RoleID, Info) ->
    {PactInfo, Record} = new_alchemy_online_i(Info),
    common_misc:unicast(RoleID, Record),
    {ok, PactInfo#p_bg_act{entry_list = []}}.

new_alchemy_online_i(Info) ->
    PactInfo = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    NeedItem = proplists:get_value(exchange, Info#r_bg_act.config),
    Price1 = proplists:get_value(price1, Info#r_bg_act.config),
    Price2 = proplists:get_value(price2, Info#r_bg_act.config),
    BtnText = proplists:get_value(btn_text, Info#r_bg_act.config),
    BtnText2 = proplists:get_value(btn_text2, Info#r_bg_act.config),
    ListOne = [begin
                   [PItem|_] = BgInfo#bg_act_config_info.items,
                   PItem
               end || BgInfo <- Info#r_bg_act.config_list, BgInfo#bg_act_config_info.title =:= 1],
    ListTwo = [begin
                   [PItem|_] = BgInfo#bg_act_config_info.items,
                   PItem
               end || BgInfo <- Info#r_bg_act.config_list, BgInfo#bg_act_config_info.title =:= 2],
    ListThree = [begin
                     [PItem|_] = BgInfo#bg_act_config_info.items,
                     PItem
                 end || BgInfo <- Info#r_bg_act.config_list, BgInfo#bg_act_config_info.title =:= 3],
    {PactInfo, #m_role_bg_alchemy_one_toc{need_item = NeedItem, once_gold = Price1, ten_gold = Price2, btn_text = BtnText,
        btn_text_i = BtnText2, list_one = ListOne, list_two = ListTwo, list_three = ListThree}}.



handle({#m_role_bg_alchemy_submit_tos{bag = List}, _RoleID, _PID}, State) ->
    do_alchemy_submit(List, State);
handle({#m_role_bg_alchemy_draw_tos{times = Times, type = Type}, _RoleID, _PID}, State) ->
    case Type =:= 1 of
        true ->
            do_alchemy_draw_a(Times, Type, State);
        _ ->
            do_alchemy_draw_b(Times, Type, State)
    end.






do_alchemy_draw_a(Times, Type, #r_role{role_id = RoleID} = State) ->
    case catch check_can_draw_a(Times, State) of
        {ok, State2, AssetDoing, BagDoing} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_role_bg_alchemy_draw_toc{type = Type}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_bg_alchemy_draw_toc{err_code = ErrCode, type = Type}),
            State
    end.


check_can_draw_a(Times, State) ->
    ?IF(Times =:= 1 orelse Times =:= 10, ok, ?THROW_ERR(1)),
    BgActInfo = world_bg_act_server:get_bg_act(?BG_ACT_ALCHEMY_ONE),
    Exchange = proplists:get_value(exchange, BgActInfo#r_bg_act.config),
    GetAssetNum = proplists:get_value(btn_number, BgActInfo#r_bg_act.config),
    GetAssetNum2 = ?IF(Times =:= 1, GetAssetNum, GetAssetNum * Times),
    GetAssetType = proplists:get_value(btn_asset, BgActInfo#r_bg_act.config),
    Rate = proplists:get_value(btn_times, BgActInfo#r_bg_act.config),
    Times2 = Rate * Times,
    {NeedAssetType, NeedAssetNum} = case Times =:= 1 of
                                        true ->
                                            {proplists:get_value(price_asset, BgActInfo#r_bg_act.config), proplists:get_value(price1, BgActInfo#r_bg_act.config)};
                                        _ ->
                                            {proplists:get_value(price_asset2, BgActInfo#r_bg_act.config), proplists:get_value(price2, BgActInfo#r_bg_act.config)}
                                    end,
    ExchangeNum = mod_role_bag:get_num_by_type_id(Exchange, State),
    {BagDoing2, AssetDoing2} = case ExchangeNum > 0 of
                                   false ->
                                       AssetDoing = mod_role_asset:check_asset_by_type(NeedAssetType, NeedAssetNum, ?ASSET_GOLD_REDUCE_FROM_NEW_ALCHEMY_A, State),
                                       {[], AssetDoing};
                                   _ ->
                                       case Times2 > ExchangeNum of
                                           true ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_NEW_ALCHEMY_A, [#r_goods_decrease_info{type_id = Exchange, num = ExchangeNum}]}],
                                               AssetDoing = mod_role_asset:check_asset_by_type(NeedAssetType, lib_tool:ceil((Times - ExchangeNum) * NeedAssetNum / 10), ?ASSET_GOLD_REDUCE_FROM_NEW_ALCHEMY_A, State),
                                               {BagDoing, AssetDoing};
                                           _ ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_NEW_ALCHEMY_A, [#r_goods_decrease_info{type_id = Exchange, num = Times}]}],
                                               {BagDoing, []}
                                       end
                               end,
    AssetDoing3 = [mod_role_asset:add_asset_by_type(GetAssetType, GetAssetNum2, ?ASSET_GOLD_ADD_FROM_BG_NEW_ALCHEMY)|AssetDoing2],
    DrawList = get_draw_list(BgActInfo#r_bg_act.config_list, []),
    GoodsList = draw(Times2, DrawList, []),
    mod_role_bag:check_bag_empty_grid(?BAG_ID_ALCHEMY, GoodsList, State),   %%检查包包空间够不够
    BagDoing3 = [{create, ?BAG_ID_ALCHEMY, ?ITEM_GAIN_NEW_ALCHEMY_A, GoodsList}|BagDoing2],
    {ok, State, AssetDoing3, BagDoing3}.

get_draw_list([], List) ->
    List;
get_draw_list([Info|T], List) ->
    get_draw_list(T, [{Info#bg_act_config_info.condition, Info#bg_act_config_info.items}|List]).

draw(Times, DrawList, GoodLists) when Times > 0 ->
    List = lib_tool:get_weight_output(DrawList),
    GoodLists2 = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(IsBind)} || #p_item_i{type_id = Type, num = Num, is_bind = IsBind} <- List],
    draw(Times - 1, DrawList, GoodLists2 ++ GoodLists);
draw(_Times, _DrawList, GoodLists) ->
    GoodLists.


%%   ---------------------------------------------------  限时商店   start   ------------------------------

time_store_online(Info) ->
    PBgAct2 = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
    {ok, PBgAct2}.

check_can_buy(State, Entry) ->
    #r_bg_act{config_list = ConfigList} = world_bg_act_server:get_bg_act(?BG_ACT_TIME_STORE),
    case lists:keyfind(Entry, #bg_act_config_info.sort, ConfigList) of
        false ->
            ?THROW_ERR(1);
        #bg_act_config_info{condition = Time, items = Items, status = Status} ->
            [#p_item_i{num = Num}|_] = Items,
            ?IF(Num =:= 0, ?THROW_ERR(1), ok),
            ?IF(time_tool:now() - time_tool:midnight() >= Time, ok, ?THROW_ERR(1)),
            AssetDoing = mod_role_asset:check_asset_by_type(?ASSET_GOLD, Status, ?ASSET_GOLD_REDUCE_FROM_BG_TIME_STORE, State),
            GoodsList = [#p_goods{type_id = ItemID, num = 1, bind = ?IS_BIND(IsBind)} || #p_item_i{type_id = ItemID, is_bind = IsBind} <- Items],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
            BagDoings = [{create, ?ITEM_GAIN_TIME_STORE, GoodsList}],
            case Num < 0 of
                true ->
                    {ok, State, BagDoings, AssetDoing, Num};
                _ ->
                    case world_bg_act_server:call({time_store_buy, Entry}) of
                        {error, Error} ->
                            ?THROW_ERR(Error);
                        {ok, NewNum} ->
                            {ok, State, BagDoings, AssetDoing, NewNum};
                        Err ->
                            ?ERROR_MSG("-------------------------~w", [Err]),
                            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
                    end
            end
    end.


%%   ---------------------------------------------------  限时商店   end     ------------------------------


%%   ---------------------------------------------    凡品     start  --------------------------------------
function_open(#r_role{role_new_alchemy = undefined, role_id = RoleID} = State) ->
    RoleNewAlchemy = #r_role_new_alchemy{role_id = RoleID, schedule = 0, times = 0},
    common_misc:unicast(RoleID, #m_role_bg_alchemy_two_toc{times = RoleNewAlchemy#r_role_new_alchemy.times, schedule = RoleNewAlchemy#r_role_new_alchemy.schedule}),
    State#r_role{role_new_alchemy = RoleNewAlchemy};
function_open(State) ->
    State.


online(#r_role{role_new_alchemy = undefined} = State) ->
    State;
online(#r_role{role_new_alchemy = RoleNewAlchemy, role_id = RoleID} = State) ->
    common_misc:unicast(RoleID, #m_role_bg_alchemy_two_toc{times = RoleNewAlchemy#r_role_new_alchemy.times, schedule = RoleNewAlchemy#r_role_new_alchemy.schedule}),
    State.



do_alchemy_submit(List, #r_role{role_id = RoleID} = State) ->
    case catch check_can_submit(List, State) of
        {ok, State2, Schedule, Times, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_role_bg_alchemy_submit_toc{schedule = Schedule, times = Times}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_bg_alchemy_submit_toc{err_code = ErrCode}),
            State
    end.


check_can_submit(List, #r_role{role_new_alchemy = RoleNewAlchemy} = State) ->
    List2 = lists:usort(List),
    {BagDoings, AddSchedule} = get_bag_action(List2, State, [], 0),
    [GlobalConfig] = lib_config:find(cfg_global, 171),
    MaxSchedule = GlobalConfig#c_global.int,
    AddTimes = (AddSchedule + RoleNewAlchemy#r_role_new_alchemy.schedule) div MaxSchedule,
    NewSchedule = (AddSchedule + RoleNewAlchemy#r_role_new_alchemy.schedule) rem MaxSchedule,
    RoleNewAlchemy2 = RoleNewAlchemy#r_role_new_alchemy{times = AddTimes + RoleNewAlchemy#r_role_new_alchemy.times, schedule = NewSchedule},
    {ok, State#r_role{role_new_alchemy = RoleNewAlchemy2}, RoleNewAlchemy2#r_role_new_alchemy.schedule, RoleNewAlchemy2#r_role_new_alchemy.times, BagDoings}.

get_bag_action([], _State, BagDoings, AddSchedule) ->
    {BagDoings, AddSchedule};
get_bag_action([ID|T], State, BagDoings, AddSchedule) ->
    case mod_role_bag:check_bag_by_id(ID, State) of
        {ok, #p_goods{type_id = TypeID, num = Num}} ->
            BagDoings2 = [{decrease, ?ITEM_REDUCE_NEW_ALCHEMY_B, [#r_goods_decrease_info{type_id = TypeID, num = Num}]}|BagDoings],
            [Config] = lib_config:find(cfg_item, TypeID),
            case Config#c_item.effect_type =:= ?ITEM_ADD_NEW_ALCHEMY_SCHEDULE of
                false ->
                    get_bag_action(T, State, BagDoings, AddSchedule);
                _ ->
                    AddSchedule2 = AddSchedule + lib_tool:to_integer(Config#c_item.effect_args) * Num,
                    get_bag_action(T, State, BagDoings2, AddSchedule2)
            end;
        _ ->
            get_bag_action(T, State, BagDoings, AddSchedule)
    end.


do_alchemy_draw_b(Times, Type, #r_role{role_id = RoleID} = State) ->
    case catch check_can_draw_b(Times, State) of
        {ok, State2, BagDoing, NewTimes} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_role_bg_alchemy_draw_toc{type = Type, times = NewTimes}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_bg_alchemy_draw_toc{err_code = ErrCode}),
            State
    end.


check_can_draw_b(Times, #r_role{role_new_alchemy = RoleNewAlchemy} = State) ->
    Times2 = ?IF(RoleNewAlchemy#r_role_new_alchemy.times > Times, Times, RoleNewAlchemy#r_role_new_alchemy.times),
    ?IF(Times2 > 0, ok, ?THROW_ERR(?ERROR_ROLE_BG_ALCHEMY_DRAW_001)),
    DrawList = [{Config#c_new_alchemy.weight, {Config#c_new_alchemy.type, Config#c_new_alchemy.num}} || {_, Config} <- cfg_new_alchemy:list()],
    GoodsList = draw_b(Times2, DrawList, []),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
    BagDoing3 = [{create, ?ITEM_GAIN_NEW_ALCHEMY_B, GoodsList}],
    RoleNewAlchemy2 = RoleNewAlchemy#r_role_new_alchemy{times = RoleNewAlchemy#r_role_new_alchemy.times - Times2},
    {ok, State#r_role{role_new_alchemy = RoleNewAlchemy2}, BagDoing3, RoleNewAlchemy2#r_role_new_alchemy.times}.


draw_b(Times, DrawList, GoodList) when Times > 0 ->
    {Type, Num} = lib_tool:get_weight_output(DrawList),
    draw_b(Times - 1, DrawList, [#p_goods{type_id = Type, num = Num}|GoodList]);
draw_b(_Times, _DrawList, GoodList) ->
    GoodList.




gm_add_times(#r_role{role_new_alchemy = RoleNewAlchemy} = State, Times1, Times2) ->
    State2 = State#r_role{role_new_alchemy = RoleNewAlchemy#r_role_new_alchemy{times = Times1, schedule = Times2}},
    online(State2).
%%   ---------------------------------------------    凡品     end  --------------------------------------