%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 七月 2019 9:57
%%%-------------------------------------------------------------------
-module(mod_role_bg_treasure_trove).
-author("WZP").
-include("proto/mod_role_bg_treasure_trove.hrl").
-include("proto/mod_role_map_panel.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("role.hrl").
-include("bg_act.hrl").

%% API
-export([
    init/1,
    handle/2,
    init_ttc/2,
    init_ttb/2,
    init_tta/2,
    online_action_a/2,
    online_action_b/2,
    online_action_c/2,
    check_can_buy/2,
    role_pre_enter/2,
    copy_win/1
]).

init(#r_role{role_bg_tt = undefined, role_id = RoleID} = State) ->
    RoleBgTt = #r_role_bg_tt{role_id = RoleID},
    State#r_role{role_bg_tt = RoleBgTt};
init(State) ->
    State.

init_tta(#r_role{role_bg_tt = RoleBgTt} = State, EditTime) ->
    RoleBgTt2 = RoleBgTt#r_role_bg_tt{open_list_one = [], choice_list_one = [], open_list_two = [], choice_list_two = [], tta_edit_time = EditTime, open_layer = 1},
    State#r_role{role_bg_tt = RoleBgTt2}.


%%  open_list_one  id  =  pos   val = type , type =  掉落ID
online_action_a(Info, #r_role{role_id = RoleID, role_bg_tt = RoleBgTt}) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    {Rare, Normal, Rare2, Normal2} = get_reward_info(Info#r_bg_act.config_list),
    case [Val || {_Weight, #p_tta{id = ID, type_id = Val}} <- RoleBgTt#r_role_bg_tt.choice_list_one, ID < 3] of
        [RareChoice|_] ->
            RareChoice;
        _ ->
            RareChoice = 0
    end,  %%代表稀有
    NormalChoice = [Val || {_Weight, #p_tta{id = ID, type_id = Val}} <- RoleBgTt#r_role_bg_tt.choice_list_one, ID > 2],  %%代表普通
    case [Val || {_Weight, #p_tta{id = ID, type_id = Val}} <- RoleBgTt#r_role_bg_tt.choice_list_two, ID < 3] of
        [RareChoiceI|_] ->
            RareChoiceI;
        _ ->
            RareChoiceI = 0
    end,  %%代表稀有
    NormalChoiceI = [Val || {_Weight, #p_tta{id = ID, type_id = Val}} <- RoleBgTt#r_role_bg_tt.choice_list_two, ID > 2],  %%代表普通
    PriceRegion = proplists:get_value(limit, Info#r_bg_act.config),
    Gold = proplists:get_value(price, Info#r_bg_act.config),
    OpenID = [#p_kv{id = ID, val = Val} || #p_kvt{id = ID, val = Val} <- RoleBgTt#r_role_bg_tt.open_list_one],
    OpenIDI = [#p_kv{id = ID, val = Val} || #p_kvt{id = ID, val = Val} <- RoleBgTt#r_role_bg_tt.open_list_two],
    DataRecord = #m_role_bg_tta_toc{info = PBgAct#p_bg_act{entry_list = []}, rare = Rare, normal = Normal, rare_choice = RareChoice, normal_choice = NormalChoice, price_region = PriceRegion, open_id = OpenID,
                                    gold = Gold, rare_i = Rare2, normal_i = Normal2, rare_choice_i = RareChoiceI, normal_choice_i = NormalChoiceI,
                                    open_id_i = OpenIDI, open_layer = RoleBgTt#r_role_bg_tt.open_layer},
%%    DataRecord = #m_role_bg_tta_toc{info = PBgAct, rare = Rare, normal = Normal, rare_choice = RareChoice, normal_choice = NormalChoice, price_region = PriceRegion, open_id = OpenID,
%%                                    gold = Gold, rare_i = Rare2, normal_i = Normal2, rare_choice_i = RareChoiceI, normal_choice_i = NormalChoiceI,
%%                                    open_id_i = OpenIDI, open_layer = RoleBgTt#r_role_bg_tt.open_layer},
    common_misc:unicast(RoleID, DataRecord),
    ok.

get_reward_info(List) ->
    get_reward_info(List, [], [], [], []).

get_reward_info([], Rare, Normal, Rare2, Normal2) ->
    {Rare, Normal, Rare2, Normal2};
get_reward_info([Info|T], Rare, Normal, Rare2, Normal2) ->
    [Type, Num, Bind, Se] = Info#bg_act_config_info.items,
    case Info#bg_act_config_info.sort < 3 of
        true ->
            case Info#bg_act_config_info.title =:= 1 of
                true ->
                    get_reward_info(T, [#p_tta{id = Info#bg_act_config_info.sort, type_id = Type, num = Num, is_bind = Bind, special_effect = Se}|Rare], Normal, Rare2, Normal2);
                _ ->
                    get_reward_info(T, Rare, Normal, [#p_tta{id = Info#bg_act_config_info.sort, type_id = Type, num = Num, is_bind = Bind, special_effect = Se}|Rare2], Normal2)
            end;
        _ ->
            case Info#bg_act_config_info.title =:= 1 of
                true ->
                    get_reward_info(T, Rare, [#p_tta{id = Info#bg_act_config_info.sort, type_id = Type, num = Num, is_bind = Bind, special_effect = Se}|Normal], Rare2, Normal2);
                _ ->
                    get_reward_info(T, Rare, Normal, Rare2, [#p_tta{id = Info#bg_act_config_info.sort, type_id = Type, num = Num, is_bind = Bind, special_effect = Se}|Normal2])
            end
    end.


handle({#m_role_bg_tta_draw_tos{times = Times, layer = Layer}, RoleID, _PID}, State) ->
    do_draw(RoleID, Times, Layer, State);
handle({#m_role_bg_tta_choice_tos{list = IDs}, RoleID, _PID}, State) ->
    do_choice(RoleID, IDs, State).



do_choice(RoleID, IDs, State) ->
    case catch check_can_choice(IDs, State) of
        {ok, State2, Layer} ->
            common_misc:unicast(RoleID, #m_role_bg_tta_choice_toc{list = IDs, layer = Layer}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_bg_tta_choice_toc{err_code = ErrCode}),
            State
    end.


check_can_choice(IDs, #r_role{role_bg_tt = RoleBgTt} = State) ->
    ?IF(erlang:length(IDs) =:= 4, ok, ?THROW_ERR(?ERROR_ROLE_BG_TTA_CHOICE_003)),
    case RoleBgTt#r_role_bg_tt.open_layer of
        1 ->
            ?IF(RoleBgTt#r_role_bg_tt.choice_list_one =:= [], ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN));
        _ ->
            ?IF(RoleBgTt#r_role_bg_tt.choice_list_two =:= [], ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN))
    end,
    case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_TREASURE_TROVE, State) of
        false ->
            ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN);
        #r_bg_act{config_list = ConfigList} ->
            ConfigList2 = [Info || #bg_act_config_info{title = Title} = Info <- ConfigList, Title =:= RoleBgTt#r_role_bg_tt.open_layer],
            ChoiceList = get_rare_list(ConfigList2, IDs, []),
            RoleBgTt2 = case RoleBgTt#r_role_bg_tt.open_layer =:= 1 of
                            true ->
                                RoleBgTt#r_role_bg_tt{choice_list_one = ChoiceList};
                            _ ->
                                RoleBgTt#r_role_bg_tt{choice_list_two = ChoiceList}
                        end,
            {ok, State#r_role{role_bg_tt = RoleBgTt2}, RoleBgTt#r_role_bg_tt.open_layer}
    end.

get_rare_list(_ConfigList, [], List) ->
    List;
get_rare_list(ConfigList, [ID|T], List) ->
    case lists:keyfind(ID, #bg_act_config_info.sort, ConfigList) of
        false ->
            ?THROW_ERR(?ERROR_ROLE_BG_TTA_CHOICE_001);
        #bg_act_config_info{items = [Type, Num, IsBind, SpecialEffect], condition = Condition} ->
            Ptta = #p_tta{id = ID, type_id = Type, num = Num, is_bind = IsBind, special_effect = SpecialEffect},
            get_rare_list(ConfigList, T, [{Condition, Ptta}|List])
    end.




do_draw(RoleID, Times, Layer, State) ->
    case catch check_can_draw(Layer, Times, State) of
        {ok, State2, BagDoing, AssetDoing, ReturnReward, OpenLayer} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = ?IF(AssetDoing =:= [], State3, mod_role_asset:do(AssetDoing, State3)),
            common_misc:unicast(RoleID, #m_role_bg_tta_draw_toc{times = Times, reward = ReturnReward, layer = Layer, open_layer = OpenLayer}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_bg_tta_draw_toc{err_code = ErrCode}),
            State
    end.

check_can_draw(Layer, Times, #r_role{role_bg_tt = RoleBgTt} = State) ->
    ?IF(RoleBgTt#r_role_bg_tt.open_layer >= Layer, ok, ?THROW_ERR(?ERROR_ROLE_BG_TTA_DRAW_001)),
    case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_TREASURE_TROVE, State) of
        false ->
            ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN);
        #r_bg_act{config = Config} ->
            {OpenList, ChoiceList} = ?IF(Layer =:= 1, {RoleBgTt#r_role_bg_tt.open_list_one, RoleBgTt#r_role_bg_tt.choice_list_one}, {RoleBgTt#r_role_bg_tt.open_list_two, RoleBgTt#r_role_bg_tt.choice_list_two}),
            DrawNum = erlang:length(OpenList),
            Times2 = case DrawNum + Times > 25 of
                         true ->
                             25 - DrawNum;
                         _ ->
                             Times
                     end,
            ?IF(Times2 > 0, ok, ?THROW_ERR(?ERROR_ROLE_BG_TTA_DRAW_002)),
            PriceRegion = proplists:get_value(limit, Config),
            ItemType = proplists:get_value(need_item, Config),
            Price = proplists:get_value(price, Config),
            Bless = proplists:get_value(min_bless, Config),
            NeedItemNum = get_need_item_num(DrawNum + 1 , DrawNum + Times2, PriceRegion, 0),
            AllItemNum = mod_role_bag:get_num_by_type_id(ItemType, State),
            {BagDoing2, AssetDoing2} = case AllItemNum >= NeedItemNum of
                                           true ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_BG_TREASURE_TROVE, [#r_goods_decrease_info{type_id = ItemType, num = NeedItemNum}]}],
                                               {BagDoing, []};
                                           _ ->
                                               BagDoing = ?IF(AllItemNum =:= 0, [], [{decrease, ?ITEM_REDUCE_BG_TREASURE_TROVE, [#r_goods_decrease_info{type_id = ItemType, num = AllItemNum}]}]),
                                               AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, (NeedItemNum - AllItemNum) * Price, ?ASSET_GOLD_REDUCE_FROM_TREASURE_TROVE, State),
                                               {BagDoing, AssetDoing}
                                       end,
            RewardPool = [{Weight, {ID, ItemInfo}} || {_, #c_treasure_trove{id = ID, layer = LayerI, item = ItemInfo, weight = Weight}} <- cfg_treasure_trove:list(), LayerI =:= Layer],
            ChoiceList2 = [{Weight, {ID, [Type, Num, IsBind]}} || {Weight, #p_tta{id = ID, type_id = Type, num = Num, is_bind = IsBind}} <- ChoiceList, ID > 2],
            [RareReward|_] = [{Weight, {ID, [Type, Num, IsBind]}} || {Weight, #p_tta{id = ID, type_id = Type, num = Num, is_bind = IsBind}} <- ChoiceList, ID < 3],
            RewardPool2 = filter_reward(RewardPool ++ ChoiceList2, OpenList),
            Bingo = check_is_bingo(OpenList),
            PosList = get_pos_list(OpenList, lists:seq(1, 25)),
            {GoodsList, ReturnReward, OpenList2, Bingo2} = draw_reward(Times2, PosList, RewardPool2, OpenList, Bless, DrawNum, RareReward, [], [], Bingo),
            BagAction = ?IF(Times2 > 1, ?ITEM_GAIN_ACT_TTA_I, ?ITEM_GAIN_ACT_TTA),
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoing3 = BagDoing2 ++ [{create, BagAction, GoodsList}],
            RoleBgTt2 = case Layer =:= 1 of
                            true ->
                                RoleBgTt#r_role_bg_tt{open_list_one = OpenList2, open_layer = ?IF(Bingo2, 2, RoleBgTt#r_role_bg_tt.open_layer)};
                            _ ->

                                RoleBgTt#r_role_bg_tt{open_list_two = OpenList2, open_layer = ?IF(Bingo2, 2, RoleBgTt#r_role_bg_tt.open_layer)}
                        end,
            {ok, State#r_role{role_bg_tt = RoleBgTt2}, BagDoing3, AssetDoing2, ReturnReward, RoleBgTt2#r_role_bg_tt.open_layer}
    end.



draw_reward(_, _, [], OpenList, _Bless, _DrawNum, _, GoodsList, ReturnReward, Bingo) when Bingo =:= true ->
    {GoodsList, ReturnReward, OpenList, Bingo};
draw_reward(0, _, _RewardPool, OpenList, _Bless, _DrawNum, _, GoodsList, ReturnReward, Bingo) ->
    {GoodsList, ReturnReward, OpenList, Bingo};
draw_reward(Times, PosList, RewardPool, OpenList, Bless, DrawNum, RareReward, GoodsList, ReturnReward, Bingo) ->
    RewardPool2 = case DrawNum >= Bless andalso not Bingo of
                      true ->
                          [RareReward|RewardPool];
                      _ ->
                          RewardPool
                  end,
    {ID, [Type, Num, IsBind]} = lib_tool:get_weight_output(RewardPool2),
    Bingo2 = Bingo orelse ID < 3,
    RewardPool3 = filter_reward_i(RewardPool, ID, []),
    Pos = lib_tool:random_element_from_list(PosList),
    PosList2 = lists:delete(Pos, PosList),
    draw_reward(Times - 1, PosList2, RewardPool3, [#p_kvt{id = Pos, val = Type, type = ID}|OpenList], Bless, DrawNum + 1, RareReward,
                [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(IsBind)}|GoodsList], [#p_kvt{id = Pos, val = ?IF(ID < 9, 1, 0), type = Type}|ReturnReward], Bingo2).

%%  open_list_one  id  =  pos   val = type , type =  掉落ID
get_pos_list([], PosList) ->
    PosList;
get_pos_list([#p_kvt{id = ID}|T], PosList) ->
    PosList2 = lists:delete(ID, PosList),
    get_pos_list(T, PosList2).


check_is_bingo(OpenList) ->
    check_is_bingo(OpenList, false).

check_is_bingo([], Bingo) ->
    Bingo;
check_is_bingo([#p_kvt{type = ID}|T], Bingo) ->
    case ID < 3 of
        true ->
            true;
        _ ->
            check_is_bingo(T, Bingo)
    end.


filter_reward(RewardPool, []) ->
    RewardPool;
filter_reward(RewardPool, [#p_kvt{type = ID}|T]) ->
    RewardPool2 = filter_reward_i(RewardPool, ID, []),
    filter_reward(RewardPool2, T).

filter_reward_i([], _Key, List) ->
    List;
filter_reward_i([{Weight, {ID, ItemInfo}}|T], Key, List) ->
    case Key =:= ID of
        true ->
            T ++ List;
        _ ->
            filter_reward_i(T, Key, [{Weight, {ID, ItemInfo}}|List])
    end.




get_need_item_num(Times, DrawTimes, _PriceRegion, NeedItemNum) when Times > DrawTimes ->
    NeedItemNum;
get_need_item_num(Times, DrawTimes, PriceRegion, NeedItemNum) ->
    Num = get_need_item_num(Times, PriceRegion),
    get_need_item_num(Times + 1, DrawTimes, PriceRegion, NeedItemNum + Num).

get_need_item_num(_Times, []) ->
    0;
get_need_item_num(Times, [#p_kvt{id = Start, val = End, type = Used}|T]) ->
    case Start =< Times andalso End >= Times of
        true ->
            Used;
        _ ->
            get_need_item_num(Times, T)
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     后台商城                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init_ttc(#r_role{role_bg_tt = RoleBgTt} = State, EditTime) ->
    RoleBgTt2 = RoleBgTt#r_role_bg_tt{buy_list = [], ttc_edit_time = EditTime},
    State#r_role{role_bg_tt = RoleBgTt2}.


online_action_c(Info, #r_role{role_id = RoleID, role_bg_tt = RoleBgTt}) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    ConfigList = [
        begin
            #bg_act_config_info{title = AllNum, condition = Price, items = [ItemID, ItemNum, Bind, SpecialEffect], sort = Sort, status = AssetType} = EntryInfo,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect}],
            Num = case lists:keyfind(Sort, #p_kv.id, RoleBgTt#r_role_bg_tt.buy_list) of
                      false ->
                          AllNum;
                      #p_kv{val = Val} ->
                          AllNum - Val
                  end,
            #p_bg_act_entry{sort = Sort, items = Items2, status = AssetType, schedule = Num, num = Price, target = AllNum}
        end
        || EntryInfo <- Info#r_bg_act.config_list],
    common_misc:unicast(RoleID, #m_role_bg_ttc_toc{info = PBgAct#p_bg_act{entry_list = ConfigList}}),
    ok.

check_can_buy(#r_role{role_bg_tt = RoleBgTt} = State, Entry) ->
    #r_bg_act{config_list = ConfigList} = world_bg_act_server:get_bg_act(?BG_ACT_ST_STORE),
    case lists:keyfind(Entry, #bg_act_config_info.sort, ConfigList) of
        false ->
            ?THROW_ERR(1);
        #bg_act_config_info{items = [ItemID, ItemNum, ItemBind, _], condition = Price, title = Times, status = AssetType} ->
            case lists:keytake(Entry, #p_kv.id, RoleBgTt#r_role_bg_tt.buy_list) of
                {value, #p_kv{val = Val}, Other} ->
                    Num = Val;
                _ ->
                    Num = 0, Other = RoleBgTt#r_role_bg_tt.buy_list
            end,
            ?IF(Times > Num, ok, ?THROW_ERR(1)),
            AssetDoing = mod_role_asset:check_asset_by_type(AssetType, Price, ?ASSET_GOLD_REDUCE_FROM_BG_STORE, State),
            GoodsList = [#p_goods{type_id = ItemID, bind = ?IS_BIND(ItemBind), num = ItemNum}],
            BagDoing = [{create, ?ITEM_GAIN_TTC_BUY, GoodsList}],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            RoleBgTt2 = RoleBgTt#r_role_bg_tt{buy_list = [#p_kv{id = Entry, val = Num + 1}|Other]},
            {ok, State#r_role{role_bg_tt = RoleBgTt2}, BagDoing, AssetDoing, Num + 1}
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     宝藏秘境                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


init_ttb(#r_role{role_bg_tt = RoleBgTt, role_attr = RoleAttr} = State, EditTime) ->
    RoleBgTt2 = RoleBgTt#r_role_bg_tt{init_power = RoleAttr#r_role_attr.power, ttb_edit_time = EditTime, check_point = 1},
    State#r_role{role_bg_tt = RoleBgTt2}.

%%online_action_b(Info, #r_role{})->
%%    Info,
%%    ok.
online_action_b(Info, #r_role{role_id = RoleID, role_bg_tt = RoleBgTt}) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    CheckPointNum = erlang:length(Info#r_bg_act.config_list),
    CheckPoint3 = erlang:min(RoleBgTt#r_role_bg_tt.check_point, CheckPointNum),
    Entry = lists:keyfind(CheckPoint3, #bg_act_config_info.sort, Info#r_bg_act.config_list),
    Reward = ?IF(RoleBgTt#r_role_bg_tt.check_point > CheckPointNum, [], Entry#bg_act_config_info.items),
    common_misc:unicast(RoleID, #m_role_bg_ttb_toc{info = PBgAct#p_bg_act{entry_list = []}, check_point = RoleBgTt#r_role_bg_tt.check_point, all_check_point = CheckPointNum,
                                                   boss = Entry#bg_act_config_info.status, reward = Reward}),
    ok.




role_pre_enter(PreEnterMap, #r_role{role_id = RoleID, role_bg_tt = RoleBgTt, role_attr = RoleAttr, role_fight = RoleFight}) ->
    case ?IS_MAP_TREASURE_SECRET(PreEnterMap) of
        false ->
            ok;
        _ ->
            RBgAct = world_bg_act_server:get_bg_act(?BG_ACT_SECRET_TERRITORY),
            CheckPoint = RoleBgTt#r_role_bg_tt.check_point,
            Entry = lists:keyfind(CheckPoint, #bg_act_config_info.sort, RBgAct#r_bg_act.config_list),
            FirstPassPower = proplists:get_value(first_pass_power, RBgAct#r_bg_act.config),
            Coefficient = (RoleAttr#r_role_attr.power - RoleBgTt#r_role_bg_tt.init_power + FirstPassPower) / Entry#bg_act_config_info.condition,
            ServerID = common_config:get_server_id(),
            MapPName = map_misc:get_map_pname(PreEnterMap, RoleID, ServerID),
            pname_server:send(MapPName, {func, copy_treasure_secret, born_monster, [Entry#bg_act_config_info.status, RoleFight#r_role_fight.fight_attr, Coefficient]})
    end.


copy_win(RoleID) when erlang:is_integer(RoleID) ->
    role_misc:info_role(RoleID, {?MODULE, copy_win, []});
copy_win(#r_role{role_id = RoleID, role_bg_tt = RoleBgTt, role_attr = RoleAttr} = State) ->
    RBgAct = world_bg_act_server:get_bg_act(?BG_ACT_SECRET_TERRITORY),
    CheckPoint = RoleBgTt#r_role_bg_tt.check_point,
    case lists:keyfind(CheckPoint, #bg_act_config_info.sort, RBgAct#r_bg_act.config_list) of
        false ->
            State;
        Entry ->
            CheckPoint2 = CheckPoint + 1,
            Reward = Entry#bg_act_config_info.items,
            GoodList = [#p_kv{id = Type, val = Num} || #p_goods{type_id = Type, num = Num} <- Reward],
            RoleBgTt2 = RoleBgTt#r_role_bg_tt{check_point = CheckPoint2, init_power = RoleAttr#r_role_attr.power},
            common_misc:unicast(RoleID, #m_copy_success_toc{exp = 0, goods_list = GoodList}),
            State2 = State#r_role{role_bg_tt = RoleBgTt2},
            PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(RBgAct),
            CheckPointNum = erlang:length(RBgAct#r_bg_act.config_list),
            CheckPoint3 = erlang:min(CheckPoint2, CheckPointNum),
            Entry2 = lists:keyfind(CheckPoint3, #bg_act_config_info.sort, RBgAct#r_bg_act.config_list),
            Reward2 = ?IF(CheckPoint2 > CheckPointNum, [], Entry2#bg_act_config_info.items),
            common_misc:unicast(RoleID, #m_role_bg_ttb_toc{info = PBgAct#p_bg_act{entry_list = []}, check_point = RoleBgTt2#r_role_bg_tt.check_point, all_check_point = CheckPointNum,
                                                           boss = Entry2#bg_act_config_info.status, reward = Reward2}),
            role_misc:create_goods(State2, ?ITEM_GAIN_ACT_TTB, Reward)
    end.