%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 二月 2019 16:53
%%%-------------------------------------------------------------------
-module(mod_role_trevi_fountain).
-author("WZP").
-include("proto/mod_role_trevi_fountain.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("role.hrl").
-include("bg_act.hrl").

%% API
-export([
    init/1,
    handle/2
]).

-export([
    online_action/2,
    init_trevi_fountain/3,
    check_can_get_reward/2,
    close_notice/1
]).


init(#r_role{role_trevi_fountain = undefined, role_id = RoleID} = State) ->
    RoleTF = #r_role_trevi_fountain{role_id = RoleID},
    State#r_role{role_trevi_fountain = RoleTF};
init(State) ->
    State.



init_trevi_fountain(#r_role{role_id = RoleID} = State, ConfigList, EditTime) ->
    Reward = [begin
                  #p_kvt{id = Info#bg_act_config_info.sort, val = ?ACT_REWARD_CANNOT_GET, type = Info#bg_act_config_info.condition}
              end || Info <- ConfigList],
    RoleActStore = #r_role_trevi_fountain{role_id = RoleID, reward = Reward, integral = 0, edit_time = EditTime, bless = 0},
    State#r_role{role_trevi_fountain = RoleActStore}.


online_action(Info, #r_role{role_trevi_fountain = RoleTF, role_id = RoleID}) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    RewardList = [
        begin
            #bg_act_config_info{title = Title, condition = Condition, items = Items, sort = Sort} = EntryInfo,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, ItemNum, Bind, SpecialEffect} <- Items],
            Status = case lists:keyfind(Sort, #p_kvt.id, RoleTF#r_role_trevi_fountain.reward) of
                         false ->
                             ?ACT_REWARD_GOT;
                         #p_kvt{val = Val} ->
                             Val
                     end,
            Schedule = ?IF(Condition > RoleTF#r_role_trevi_fountain.integral, RoleTF#r_role_trevi_fountain.integral, Condition),
            #p_bg_act_entry{sort = Sort, items = Items2, title = Title, status = Status, schedule = Schedule, num = -1, target = Condition}
        end || EntryInfo <- PBgAct#p_bg_act.entry_list],
    PBgAct2 = PBgAct#p_bg_act{entry_list = RewardList},
    Exchange = proplists:get_value(exchange, Info#r_bg_act.config),
    TwoReward = proplists:get_value(two_reward, Info#r_bg_act.config),
    TwoReward2 = [RewardInfo || {_, RewardInfo} <- TwoReward],
    OneReward = proplists:get_value(one_reward, Info#r_bg_act.config),
    OneReward2 = [RewardInfo || {_, _, IsShow, RewardInfo} <- OneReward, IsShow =:= 1],
    UnitPrice = proplists:get_value(unit_price, Info#r_bg_act.config),
    FullPrice = proplists:get_value(full_price, Info#r_bg_act.config),
    RareList2 = [{Rate, {SortID, PItem}} || {Rate, SortID, _IsShow, PItem} <- OneReward, not lists:member(SortID, RoleTF#r_role_trevi_fountain.reward_list)],
    common_misc:unicast(RoleID, #m_bg_trevi_fountain_toc{info = PBgAct2, consume_item = Exchange, unit_price = UnitPrice, full_price = FullPrice, precious_reward = OneReward2,
                                                         common_reward = TwoReward2, integral = RoleTF#r_role_trevi_fountain.integral, bless = RoleTF#r_role_trevi_fountain.bless,
                                                         precious_exist = RareList2 =/= [], notice = RoleTF#r_role_trevi_fountain.notice}),
    ok.

close_notice(#r_role{role_trevi_fountain = RoleTF} = State)->
    RoleTF2 = RoleTF#r_role_trevi_fountain{notice = false},
    State#r_role{role_trevi_fountain = RoleTF2}.

handle({#m_bg_trevi_fountain_draw_tos{times = Times}, RoleID, _PID}, State) ->
    do_lucky_draw(RoleID, Times, State).



do_lucky_draw(RoleID, Times, State) ->
    case catch check_can_draw(Times, State) of
        {ok, State2, NewIntegral, Reward, UpdateList, BagDoing, AssetDoing, Bless, PreciousExist} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = ?IF(AssetDoing =:= [], State3, mod_role_asset:do(AssetDoing, State3)),
            common_misc:unicast(RoleID, #m_bg_trevi_fountain_draw_toc{integral = NewIntegral, reward = Reward, times = Times, update_list = UpdateList, bless = Bless, precious_exist = PreciousExist}),
            hook_role:trevi_fountain(State4, Times);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bg_trevi_fountain_draw_toc{err_code = ErrCode}),
            State
    end.


check_can_draw(Times, #r_role{role_attr = RoleAttr, role_trevi_fountain = RoleTF} = State) ->
    ?IF(Times =:= 1 orelse Times =:= 10, ok, ?THROW_ERR(1)),
    BgActInfo = world_bg_act_server:get_bg_act(?BG_ACT_TREVI_FOUNTAIN),
    ?IF(BgActInfo#r_bg_act.status =:= ?BG_ACT_STATUS_TWO andalso RoleAttr#r_role_attr.level >= BgActInfo#r_bg_act.min_level, ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    UnitPrice = proplists:get_value(unit_price, BgActInfo#r_bg_act.config),
    Exchange = proplists:get_value(exchange, BgActInfo#r_bg_act.config),
    ExchangeNum = mod_role_bag:get_num_by_type_id(Exchange, State),
    {BagDoing2, AssetDoing2} = case ExchangeNum > 0 of
                                   false ->
                                       AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Times * UnitPrice, ?ASSET_GOLD_REDUCE_FROM_TREVI_FOUNTAIN, State),
                                       {[], AssetDoing};
                                   _ ->
                                       case Times > ExchangeNum of
                                           true ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_TREVI_FOUNTAIN, [#r_goods_decrease_info{type_id = Exchange, num = ExchangeNum}]}],
                                               AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, (Times - ExchangeNum) * UnitPrice, ?ASSET_GOLD_REDUCE_FROM_TREVI_FOUNTAIN, State),
                                               {BagDoing, AssetDoing};
                                           _ ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_TREVI_FOUNTAIN, [#r_goods_decrease_info{type_id = Exchange, num = Times}]}],
                                               {BagDoing, []}
                                       end
                               end,
    NewIntegral = RoleTF#r_role_trevi_fountain.integral + Times,
    {NewRewardList, UpdateList} = lists:foldl(
        fun(RewardInfo, {AccRewardList, AccUpdateList}) ->
            case RewardInfo#p_kvt.val =:= ?ACT_REWARD_CANNOT_GET of
                false ->
                    {[RewardInfo|AccRewardList], AccUpdateList};
                _ ->
                    case NewIntegral >= RewardInfo#p_kvt.type of
                        true ->
                            {[RewardInfo#p_kvt{val = ?ACT_REWARD_CAN_GET}|AccRewardList], [RewardInfo#p_kvt{val = ?ACT_REWARD_CAN_GET}|AccUpdateList]};
                        _ ->
                            {[RewardInfo|AccRewardList], [RewardInfo#p_kvt{val = ?ACT_REWARD_CANNOT_GET, type = NewIntegral}|AccUpdateList]}
                    end
            end
        end, {[], []}, RoleTF#r_role_trevi_fountain.reward),
    RareList = proplists:get_value(one_reward, BgActInfo#r_bg_act.config),
    NormalList = proplists:get_value(two_reward, BgActInfo#r_bg_act.config),
    MaxValue = proplists:get_value(max_bless, BgActInfo#r_bg_act.config),
    MinValue = proplists:get_value(min_bless, BgActInfo#r_bg_act.config),
    {GotRewards, NewBless, NewRareGodRewardList, PreciousExist} = draw_reward_by_times(Times, RoleTF#r_role_trevi_fountain.bless, MinValue, MaxValue, RareList, RoleTF#r_role_trevi_fountain.reward_list, NormalList),
    RoleTF2 = RoleTF#r_role_trevi_fountain{integral = NewIntegral, reward = NewRewardList, bless = NewBless, reward_list = NewRareGodRewardList},
    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum, bind = ?IS_BIND(IsBind)} || #p_item_i{type_id = ItemType, num = ItemNum, is_bind = IsBind} <- GotRewards],
    mod_role_bag:check_bag_empty_grid(?BAG_ID_TREVI_FOUNTAIN, GoodsList, State),
    BagDoing3 = [{create, ?BAG_ID_TREVI_FOUNTAIN, ?ITEM_GAIN_TREVI_FOUNTAIN, GoodsList}|BagDoing2],
    State2 = State#r_role{role_trevi_fountain = RoleTF2},
    {ok, State2, NewIntegral, GotRewards, UpdateList, BagDoing3, AssetDoing2, NewBless, PreciousExist}.


draw_reward_by_times(Times, Bless, MinValue, MaxValue, RareList, GodRareReward, NormalList) ->
    RareList2 = [{Rate, {SortID, PItem}} || {Rate, SortID, _IsShow, PItem} <- RareList, not lists:member(SortID, GodRareReward)],
    draw_reward_by_times(Times, RareList2, NormalList, MinValue, MaxValue, GodRareReward, [], Bless).

draw_reward_by_times(Times, RareList, _NormalList, _MinValue, _MaxValue, GodRareReward, RewardList, Bless) when Times =< 0 ->
    {RewardList, Bless, GodRareReward, RareList =/= []};
draw_reward_by_times(Times, RareList, NormalList, MinValue, MaxValue, GodRareReward, RewardList, Bless) ->
    if
        Bless < MinValue ->
            PItem = lib_tool:get_weight_output(NormalList),
            draw_reward_by_times(Times - 1, RareList, NormalList, MinValue, MaxValue, GodRareReward, [PItem|RewardList], Bless + 1);
        Bless < MaxValue ->
            case lib_tool:get_weight_output(RareList ++ NormalList) of
                {SortID, PItem} ->
                    RareList2 = delete_by_id(RareList, SortID, []),
                    draw_reward_by_times(Times - 1, RareList2, NormalList, MinValue, MaxValue, [SortID|GodRareReward], [PItem|RewardList], 0);
                PItem ->
                    draw_reward_by_times(Times - 1, RareList, NormalList, MinValue, MaxValue, GodRareReward, [PItem|RewardList], Bless + 1)
            end;
        RareList =:= [] ->
            PItem = lib_tool:get_weight_output(NormalList),
            draw_reward_by_times(Times - 1, RareList, NormalList, MinValue, MaxValue, GodRareReward, [PItem|RewardList], Bless + 1);
        true ->
            {SortID, PItem} = lib_tool:get_weight_output(RareList),
            RareList2 = delete_by_id(RareList, SortID, []),
            draw_reward_by_times(Times - 1, RareList2, NormalList, MinValue, MaxValue, [SortID|GodRareReward], [PItem|RewardList], 0)
    end.

delete_by_id([], _KeySortID, List) ->
    List;
delete_by_id([{_, {SortID, _}} = Info|T], KeySortID, List) ->
    case SortID =:= KeySortID of
        true ->
            T ++ List;
        _ ->
            delete_by_id(T, KeySortID, [Info|List])
    end.



check_can_get_reward(State, Entry) ->
    #r_role{role_trevi_fountain = RoleTF} = State,
    #r_role_trevi_fountain{reward = RewardList} = RoleTF,
    {value, #p_kvt{val = Val, type = Type}, Other} = lists:keytake(Entry, #p_kvt.id, RewardList),
    ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
    GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_TREVI_FOUNTAIN, Entry),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_TREVI_FOUNTAIN_REWARD, GoodsList}],
    RewardList2 = [#p_kvt{id = Entry, type = Type, val = ?ACT_REWARD_GOT}|Other],
    RoleTF2 = RoleTF#r_role_trevi_fountain{reward = RewardList2},
    State2 = State#r_role{role_trevi_fountain = RoleTF2},
    {ok, BagDoings, State2}.




