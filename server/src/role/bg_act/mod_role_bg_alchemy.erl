%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 四月 2019 9:51
%%%-------------------------------------------------------------------
-module(mod_role_bg_alchemy).
-author("WZP").
-include("role.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_bg_alchemy.hrl").

%% API
-export([
    init/1,
    handle/2
]).

-export([
    online_action/2,
    init_alchemy/3
]).

init(#r_role{role_bg_alchemy = undefined, role_id = RoleID} = State) ->
    RoleAlchemy = #r_role_bg_alchemy{role_id = RoleID},
    State#r_role{role_bg_alchemy = RoleAlchemy};
init(State) ->
    State.

online_action(Info, #r_role{role_id = RoleID, role_bg_alchemy = RoleAlchemy} = State) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
    Price = proplists:get_value(price, Info#r_bg_act.config),
    Asset = proplists:get_value(asset, Info#r_bg_act.config),
    MaxLucky = proplists:get_value(max_lucky, Info#r_bg_act.config),
    BtnText = proplists:get_value(btn_text, Info#r_bg_act.config),
    TwoReward = proplists:get_value(two_reward, Info#r_bg_act.config),
    OneReward = proplists:get_value(one_reward, Info#r_bg_act.config),
    OneReward2 = tran_to_no_rate(OneReward),
    case lists:keyfind(RoleAlchemy#r_role_bg_alchemy.big_reward, #p_item_i.type_id, OneReward2) of
        false ->
            [RoleOneReward|_] = OneReward2,
            common_misc:unicast(RoleID, #m_bg_alchemy_toc{info = PBgAct, price = Price, money = Asset, lucky = RoleAlchemy#r_role_bg_alchemy.lucky,
                                                          full_lucky = MaxLucky, tips = BtnText, picture_tips = Info#r_bg_act.explain_i, common_reward = tran_to_no_rate(TwoReward), precious_reward = RoleOneReward}),
            RoleAlchemy2 = RoleAlchemy#r_role_bg_alchemy{big_reward = RoleOneReward#p_item_i.type_id},
            {new_state, State#r_role{role_bg_alchemy = RoleAlchemy2}};
        RoleOneReward ->
            common_misc:unicast(RoleID, #m_bg_alchemy_toc{info = PBgAct, price = Price, money = Asset, lucky = RoleAlchemy#r_role_bg_alchemy.lucky,
                                                          full_lucky = MaxLucky, tips = BtnText, picture_tips = Info#r_bg_act.explain_i, common_reward = tran_to_no_rate(TwoReward), precious_reward = RoleOneReward}),
            ok
    end.

tran_to_no_rate(List) ->
    [Info || {_, Info} <- List].

init_alchemy(#r_role{role_id = RoleID} = State, Config, EditTime) ->
    OneReward = proplists:get_value(one_reward, Config),
    [{_, #p_item_i{type_id = TypeID}}|_] = OneReward,
    Info = #r_role_bg_alchemy{role_id = RoleID, edit_time = EditTime, lucky = 0, big_reward = TypeID},
    State#r_role{role_bg_alchemy = Info}.


handle({#m_bg_alchemy_draw_tos{}, RoleID, _PID}, State) ->
    do_lucky_draw(RoleID, State).


do_lucky_draw(RoleID, State) ->
    case catch check_can_draw(State) of
        {ok, State2, AssetDoing, BagDoing, PreciousReward, Lucky} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = mod_role_asset:do(AssetDoing, State3),
            common_misc:unicast(RoleID, #m_bg_alchemy_draw_toc{lucky = Lucky, precious_reward = PreciousReward}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bg_alchemy_draw_toc{err_code = ErrCode}),
            State
    end.

check_can_draw(#r_role{role_attr = RoleAttr, role_bg_alchemy = RoleAlchemy} = State) ->
    BgActInfo = world_bg_act_server:get_bg_act(?BG_ACT_ALCHEMY),
    ?IF(BgActInfo#r_bg_act.status =:= ?BG_ACT_STATUS_TWO andalso RoleAttr#r_role_attr.level >= BgActInfo#r_bg_act.min_level, ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    Price = proplists:get_value(price, BgActInfo#r_bg_act.config),
    Asset = proplists:get_value(asset, BgActInfo#r_bg_act.config),
    AssetDoing = mod_role_asset:check_asset_by_type(Asset, Price, ?ASSET_GOLD_REDUCE_FROM_ALCHEMY, State),%优先消耗绑定元宝
    RewardAssetNum = proplists:get_value(btn_number, BgActInfo#r_bg_act.config),
    RewardAsset = proplists:get_value(btn_asset, BgActInfo#r_bg_act.config),
    AssetDoing2 = case RewardAsset of
                      ?ASSET_GOLD ->
                          [{add_gold, ?ASSET_GOLD_ADD_FROM_ALCHEMY, RewardAssetNum, 0}|AssetDoing];
                      ?ASSET_BIND_GOLD ->
                          [{add_gold, ?ASSET_GOLD_ADD_FROM_ALCHEMY, 0, RewardAssetNum}|AssetDoing];
                      _ ->
                          [{add_silver, ?ASSET_SILVER_ADD_FROM_ALCHEMY, RewardAssetNum}|AssetDoing]
                  end,
    MaxLucky = proplists:get_value(max_lucky, BgActInfo#r_bg_act.config),
    OneReward = proplists:get_value(one_reward, BgActInfo#r_bg_act.config),
    case MaxLucky =:= RoleAlchemy#r_role_bg_alchemy.lucky + 1 of
        true ->
            {_, #p_item_i{type_id = TypeID, num = Num, is_bind = IsBind}} = get_reward_by_type(OneReward, RoleAlchemy#r_role_bg_alchemy.big_reward),
            GoodList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(IsBind)}],
            NewLucky = 0,
            NewBigReward = get_next_big_reward(RoleAlchemy#r_role_bg_alchemy.big_reward, OneReward);
        _ ->
            BigReward = get_reward_by_type(OneReward, RoleAlchemy#r_role_bg_alchemy.big_reward),
            TwoReward = proplists:get_value(two_reward, BgActInfo#r_bg_act.config),
            #p_item_i{type_id = TypeID, num = Num, is_bind = IsBind} = lib_tool:get_weight_output([BigReward|TwoReward]),
            GoodList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(IsBind)}],
            {NewLucky, NewBigReward} = case RoleAlchemy#r_role_bg_alchemy.big_reward =:= TypeID of
                                           true ->
                                               {0, get_next_big_reward(RoleAlchemy#r_role_bg_alchemy.big_reward, OneReward)};
                                           _ ->
                                               {RoleAlchemy#r_role_bg_alchemy.lucky + 1, #p_item_i{type_id = 0, num = 0, is_bind = 0}}
                                       end
    end,
    mod_role_bag:check_bag_empty_grid(GoodList, State),
    BagDoing = [{create, ?BAG_ID_BAG, ?ITEM_GAIN_BG_ALCHEMY, GoodList}],
    RoleAlchemy2 = RoleAlchemy#r_role_bg_alchemy{lucky = NewLucky, big_reward = ?IF(NewBigReward#p_item_i.type_id =:= 0, RoleAlchemy#r_role_bg_alchemy.big_reward, NewBigReward#p_item_i.type_id)},
    {ok, State#r_role{role_bg_alchemy = RoleAlchemy2}, AssetDoing2, BagDoing, NewBigReward, NewLucky}.

get_reward_by_type([First|T], BigReward) ->
    get_reward_by_type([First|T], BigReward, First).
get_reward_by_type([], _BigReward, First) ->
    First;
get_reward_by_type([{Rate, PItem}|T], BigReward, First) ->
    case PItem#p_item_i.type_id =:= BigReward of
        true ->
            {Rate, PItem};
        _ ->
            get_reward_by_type(T, BigReward, First)
    end.


get_next_big_reward(BigReward, [First|T]) ->
    {_, Info} = First,
    get_next_big_reward(BigReward, [First|T], Info).


get_next_big_reward(BigReward, [{_Rate, PItem}, {_, PItem2}|T], First) ->
    case PItem#p_item_i.type_id =:= BigReward of
        false ->
            get_next_big_reward(BigReward, T, First);
        _ ->
            PItem2
    end;
get_next_big_reward(_BigReward, _, First) ->
    First.