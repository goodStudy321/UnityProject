%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 一月 2019 16:28
%%%-------------------------------------------------------------------
-module(mod_role_bg_act_store).
-author("WZP").

-include("bg_act.hrl").
-include("role.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("proto/mod_role_bg_act_store.hrl").

%% API
-export([
    init/1
]).

-export([
    init_store/3,
    online_action/2,
    check_can_get_reward/2
]).


init(#r_role{role_bg_act_store = undefined, role_id = RoleID} = State) ->
    RoleBG = #r_role_bg_store{role_id = RoleID},
    State#r_role{role_bg_act_store = RoleBG};
init(State) ->
    State.

init_store(#r_role{role_id = RoleID} = State, ConfigList, EditTime) ->
    BuyList = [begin
                   [{_, ExchangeTimes, _, _}|_] = Info#bg_act_config_info.items,
                   #p_kv{id = Info#bg_act_config_info.sort, val = ExchangeTimes}
               end || Info <- ConfigList],
    RoleActStore = #r_role_bg_store{role_id = RoleID, buy_list = BuyList, store_time = EditTime},
    State#r_role{role_bg_act_store = RoleActStore}.


online_action(#r_role{role_id = RoleID, role_bg_act_store = RoleActStore}, BgInfo) ->
    #p_bg_act{entry_list = EntryList} = PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(BgInfo),
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#p_bg_act_entry.sort, #p_kv.id, RoleActStore#r_role_bg_store.buy_list) of
                false ->
                    EntryInfo;
                RoleEntryInfo ->
                    EntryInfo#p_bg_act_entry{schedule = RoleEntryInfo#p_kv.val}
            end
        end
        || EntryInfo <- EntryList],
    NeedItem = proplists:get_value(exchange, BgInfo#r_bg_act.config),
    PBgAct2 = PBgAct#p_bg_act{entry_list = NewEntryList},
    common_misc:unicast(RoleID, #m_bg_store_toc{info = PBgAct2, item = NeedItem}),
    ok.

check_can_get_reward(#r_role{role_bg_act_store = RoleActStore} = State, Entry) ->
    #r_role_bg_store{buy_list = BuyList} = RoleActStore,
    case lists:keytake(Entry, #p_kv.id, BuyList) of
        {value, #p_kv{val = Val}, Other} ->
            ?IF(Val > 0, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_001)),
            BuyList2 = [#p_kv{id = Entry, val = Val - 1}|Other],
            RoleActStore2 = RoleActStore#r_role_bg_store{buy_list = BuyList2},
            BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_STORE),
            case lists:keyfind(Entry, #bg_act_config_info.sort, BgInfo#r_bg_act.config_list) of
                false ->
                    ?THROW_ERR(?ERROR_BG_ACT_REWARD_003);
                #bg_act_config_info{items = Items, condition = NeedNum} ->
                    GoodsList = [#p_goods{type_id = TypeID, num = 1, bind = Bind} || {TypeID, _, Bind, _} <- Items],
                    mod_role_bag:check_bag_empty_grid(GoodsList, State),
                    BagDoings = [{create, ?ITEM_GAIN_BG_ACT_STORE, GoodsList}],
                    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_STORE),
                    NeedItem = proplists:get_value(exchange, BgInfo#r_bg_act.config),
                    DecreaseList = mod_role_bag:get_decrease_goods_by_num(NeedItem, NeedNum, State),
                    BagDoing2 = [{decrease, ?ITEM_REDUCE_WAR_SPIRIT, DecreaseList}|BagDoings],
                    {ok, BagDoing2, State#r_role{role_bg_act_store = RoleActStore2}}
            end;
        _ ->
            ?THROW_ERR(?ERROR_BG_ACT_REWARD_003)
    end.


















