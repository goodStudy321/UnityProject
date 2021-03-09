%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 八月 2019 16:43
%%%-------------------------------------------------------------------
-module(mod_role_bg_extra).
-author("WZP").

-include("role.hrl").
-include("bg_act.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("proto/mod_role_bg_extra.hrl").

%% API
-export([
    pay/3,
    online_qinxin/2,
    check_can_get_a/2,
    check_can_get_b/1,
    init_recharge_package/3,
    online_recharge_package/2
]).


%%------------------------充值礼包  start --------------------

%%  val  可领次数    type  可冲次数
init_recharge_package(#r_role{role_pay = RolePay} = State, EditTime, ConfigList) ->
    RoleRecharge = mod_role_extra:get_data(?EXTRA_KEY_BG_WEEK_TWO, #r_role_bg_recharge_package{}, State),
    List = [#p_kvt{id = Sort, val = 0, type = 3} || #bg_act_config_info{sort = Sort} <- ConfigList],
    RoleRecharge2 = RoleRecharge#r_role_bg_recharge_package{edit_time = EditTime, list = List},
    State2 = mod_role_extra:set_data(?EXTRA_KEY_BG_WEEK_TWO, RoleRecharge2, State),
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_RECHARGE_PACKET),
    pay(State2, BgInfo, RolePay#r_role_pay.today_pay_gold).


online_recharge_package(State, BgInfo) ->
    #r_role_bg_recharge_package{list = List} = mod_role_extra:get_data(?EXTRA_KEY_BG_WEEK_TWO, #r_role_bg_recharge_package{}, State),
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#bg_act_config_info.sort, #p_kvt.id, List) of
                false ->
                    EntryInfo;
                RoleEntryInfo ->
                    Status = case RoleEntryInfo#p_kvt.val > 0 of
                                 true ->
                                     ?ACT_REWARD_CAN_GET;
                                 _ ->
                                     case RoleEntryInfo#p_kvt.type > 0 of
                                         true ->
                                             ?ACT_REWARD_CANNOT_GET;
                                         _ ->
                                             ?ACT_REWARD_GOT
                                     end
                             end,
                    #p_bg_act_entry{status = Status, sort = EntryInfo#bg_act_config_info.sort, title = EntryInfo#bg_act_config_info.title,
                                    schedule = RoleEntryInfo#p_kvt.val,
                                    items = EntryInfo#bg_act_config_info.items, num = -1}
            end
        end
        || EntryInfo <- BgInfo#r_bg_act.config_list],
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(BgInfo),
    {ok, PBgAct#p_bg_act{entry_list = NewEntryList}}.


check_can_get_a(State, Entry) ->
    RoleRecharge = mod_role_extra:get_data(?EXTRA_KEY_BG_WEEK_TWO, #r_role_bg_recharge_package{}, State),
    case lists:keytake(Entry, #p_kvt.id, RoleRecharge#r_role_bg_recharge_package.list) of
        {value, #p_kvt{} = Pkvt, Other} ->
            ?IF(Pkvt#p_kvt.val > 0, ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),
            Pkvt2 = Pkvt#p_kvt{id = Entry, val = Pkvt#p_kvt.val - 1},
            List = [Pkvt2|Other],
            RoleRecharge2 = RoleRecharge#r_role_bg_recharge_package{list = List},
            State2 = mod_role_extra:set_data(?EXTRA_KEY_BG_WEEK_TWO, RoleRecharge2, State),
            GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_RECHARGE_PACKET, Entry),
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_BG_WEEK_TWO, GoodsList}],
            Status = case Pkvt2#p_kvt.val > 0 of
                         true ->
                             ?ACT_REWARD_CAN_GET;
                         _ ->
                             case Pkvt2#p_kvt.type > 0 of
                                 true ->
                                     ?ACT_REWARD_CANNOT_GET;
                                 _ ->
                                     ?ACT_REWARD_GOT
                             end
                     end,
            common_misc:unicast(State#r_role.role_id, #m_bg_act_reward_condition_toc{id = ?BG_ACT_RECHARGE_PACKET,
                                                                                     list = [#p_kvt{id = Entry, type = Status, val = Pkvt2#p_kvt.val}]}),
            {ok, BagDoings, State2};
        false ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
    end.


pay(State, BgInfo, PayGold) ->
    case lists:keyfind(PayGold, #bg_act_config_info.condition, BgInfo#r_bg_act.config_list) of
        #bg_act_config_info{sort = Sort} ->
            RoleRecharge = mod_role_extra:get_data(?EXTRA_KEY_BG_WEEK_TWO, #r_role_bg_recharge_package{}, State),
            case lists:keytake(Sort, #p_kvt.id, RoleRecharge#r_role_bg_recharge_package.list) of
                {value, #p_kvt{} = Pkvt, Other} ->
                    case Pkvt#p_kvt.type > 0 of
                        true ->
                            List = [Pkvt#p_kvt{val = Pkvt#p_kvt.val + 1, type = Pkvt#p_kvt.type - 1}|Other],
                            RoleRecharge2 = RoleRecharge#r_role_bg_recharge_package{list = List},
                            common_misc:unicast(State#r_role.role_id, #m_bg_act_reward_condition_toc{id = ?BG_ACT_RECHARGE_PACKET,
                                                                                                     list = [#p_kvt{id = Sort, type = ?ACT_REWARD_CAN_GET, val = Pkvt#p_kvt.val + 1}]}),
                            mod_role_extra:set_data(?EXTRA_KEY_BG_WEEK_TWO, RoleRecharge2, State);
                        _ ->
                            State
                    end;
                false ->
                    State
            end;
        _ ->
            State
    end.

%%------------------------充值礼包  end --------------------


%%-------------------------------   一见倾心   start ---------------------------------
online_qinxin(#r_role{role_id = RoleID}, Info) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    Price = proplists:get_value(price, Info#r_bg_act.config),
    Package = proplists:get_value(package, Info#r_bg_act.config),
    List = [PItems || #bg_act_config_info{items = PItems} <- Info#r_bg_act.config_list],
    List2 = lists:flatten(List),
    common_misc:unicast(RoleID, #m_role_bg_package_toc{info = PBgAct#p_bg_act{entry_list = []}, price = Price, item = Package, list = List2}),
    ok.


check_can_get_b(State) ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_QINGXIN),
    Price = proplists:get_value(price, BgInfo#r_bg_act.config),
    Exchange = proplists:get_value(exchange, BgInfo#r_bg_act.config),
    ExchangeNum = proplists:get_value(exchange_num, BgInfo#r_bg_act.config),
    Package = proplists:get_value(package, BgInfo#r_bg_act.config),
    PackageNum = proplists:get_value(package_num, BgInfo#r_bg_act.config),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Price, ?ASSET_GOLD_REDUCE_FROM_BG_QINXIN, State),
    GoodsList = [#p_goods{type_id = Exchange, num = ExchangeNum}, #p_goods{type_id = Package, num = PackageNum}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_BG_QINXIN, GoodsList}],
    {ok, State, BagDoings, AssetDoing, -1}.
%%-------------------------------   一见倾心   end   ---------------------------------


%%---------------------------  数据操作 -------------

%%set_data(Key, Value, State) ->
%%    #r_role{role_bg_extra = RoleBgExtra} = State,
%%    #r_role_bg_extra{data = Data} = RoleBgExtra,
%%    Data2 = lists:keystore(Key, 1, Data, {Key, Value}),
%%    RoleBgExtra2 = RoleBgExtra#r_role_bg_extra{data = Data2},
%%    State#r_role{role_bg_extra = RoleBgExtra2}.
%%
%%get_data(Key, Default, State) ->
%%    #r_role{role_extra = #r_role_bg_extra{data = Data}} = State,
%%    case lists:keyfind(Key, 1, Data) of
%%        {_, Value} ->
%%            Value;
%%        _ ->
%%            Default
%%    end.

%%---------------------------  数据操作 -------------