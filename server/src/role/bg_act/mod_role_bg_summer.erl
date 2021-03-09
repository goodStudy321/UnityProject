%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 七月 2019 14:25
%%%-------------------------------------------------------------------
-module(mod_role_bg_summer).
-author("WZP").

-include("bg_act.hrl").
-include("common.hrl").
-include("role.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("proto/mod_role_bg_summer.hrl").
%% API

-export([
    pay/2,
    consume/3,
    init_recharge/3,
    init_rank/2,
    recharge_online/2,
    rank_online/2,
    check_can_get_reward/2,
    day_reset_recharge/1,
    consume_rank_update/2
]).




init_recharge(State, EditTime, ConfigList) ->
    SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    List = [#p_kv{id = Sort, val = ?ACT_REWARD_CANNOT_GET} || #bg_act_config_info{sort = Sort} <- ConfigList],
    SummerExtra2 = SummerExtra#r_summer_extra{recharge_reward_list = List, recharge_edit_time = EditTime},
    mod_role_extra:set_data(?EXTRA_KEY_SUMMER_EXTRA, SummerExtra2, State).


recharge_online(State, Info) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    List = [begin
                Status = case lists:keyfind(RBgInfo#bg_act_config_info.sort, #p_kv.id, SummerExtra#r_summer_extra.recharge_reward_list) of
                             false ->
                                 ?ACT_REWARD_CANNOT_GET;
                             #p_kv{val = Val} ->
                                 Val
                         end,
                #p_bg_act_entry{sort = RBgInfo#bg_act_config_info.sort, items = RBgInfo#bg_act_config_info.items, title = RBgInfo#bg_act_config_info.title, status = Status}
            end || RBgInfo <- Info#r_bg_act.config_list],
    {ok, PBgAct#p_bg_act{entry_list = List}}.


pay(State, PayGold) ->
    #r_summer_extra{pay_gold = OldPayGold} = SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    NowPayGold = OldPayGold + PayGold,
    RechargeRewardList2 = get_new_recharge_reward_list(NowPayGold, State),
    SummerExtra2 = SummerExtra#r_summer_extra{recharge_reward_list = RechargeRewardList2, pay_gold = NowPayGold},
    SendList = [#p_kvt{id = ID, type = Val} || #p_kv{id = ID, val = Val} <- RechargeRewardList2],
    common_misc:unicast(State#r_role.role_id, #m_bg_act_reward_condition_toc{id = ?BG_ACT_RECHARGE_REWARD, list = SendList}),
    mod_role_extra:set_data(?EXTRA_KEY_SUMMER_EXTRA, SummerExtra2, State).


day_reset_recharge(State) ->
    #r_summer_extra{pay_gold = OldPayGold} = SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    RechargeRewardList2 = get_new_recharge_reward_list(OldPayGold, State),
    SummerExtra2 = SummerExtra#r_summer_extra{recharge_reward_list = RechargeRewardList2},
    SendList = [#p_kvt{id = ID, type = Val} || #p_kv{id = ID, val = Val} <- RechargeRewardList2],
    common_misc:unicast(State#r_role.role_id, #m_bg_act_reward_condition_toc{id = ?BG_ACT_RECHARGE_REWARD, list = SendList}),
    mod_role_extra:set_data(?EXTRA_KEY_SUMMER_EXTRA, SummerExtra2, State).

get_new_recharge_reward_list(NowPayGold, State) ->
    #r_bg_act{start_date = StartDate, config = Config} = world_bg_act_server:get_bg_act(?BG_ACT_RECHARGE_REWARD),
    Recharge = proplists:get_value(recharge_num, Config),
    NowDay = time_tool:diff_date(time_tool:now(), StartDate) + 1,
    #r_summer_extra{recharge_reward_list = RechargeRewardList} = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    case NowPayGold >= Recharge of
        true ->
            [begin
                 case Pkv#p_kv.id =< NowDay andalso Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                     true ->
                         Pkv#p_kv{val = ?ACT_REWARD_CAN_GET};
                     _ ->
                         Pkv
                 end
             end || Pkv <- RechargeRewardList];
        _ ->
            RechargeRewardList
    end.

check_can_get_reward(State, Entry) ->
    #r_summer_extra{recharge_reward_list = RechargeRewardList} = SummerExtra = mod_role_extra:get_data(?EXTRA_KEY_SUMMER_EXTRA, #r_summer_extra{}, State),
    case lists:keytake(Entry, #p_kv.id, RechargeRewardList) of
        {value, #p_kv{val = ?ACT_REWARD_CAN_GET}, Other} ->
            SummerExtra2 = SummerExtra#r_summer_extra{recharge_reward_list = [#p_kv{id = Entry, val = ?ACT_REWARD_GOT}|Other]},
            State2 = mod_role_extra:set_data(?EXTRA_KEY_SUMMER_EXTRA, SummerExtra2, State),
            GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_RECHARGE_REWARD, Entry),
            BagDoings = [{create, ?ITEM_GAIN_SUMMER_RECHARGE, GoodsList}],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            {ok, BagDoings, State2};
        _ ->
            State
    end.



init_rank(State, EditTime) ->
    BgSummer = mod_role_extra:get_data(?EXTRA_KEY_BG_SUMMER, #r_bg_summer{}, State),
    BgSummer2 = BgSummer#r_bg_summer{rank_edit_time = EditTime, my_use = 0},
    mod_role_extra:set_data(?EXTRA_KEY_BG_SUMMER, BgSummer2, State).



rank_online(State, Info) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
    BgSummer = mod_role_extra:get_data(?EXTRA_KEY_BG_SUMMER, #r_bg_summer{}, State),
    common_misc:unicast(State#r_role.role_id, #m_role_bg_rrank_toc{info = PBgAct, my_use = BgSummer#r_bg_summer.my_use}),
    ok.

consume_rank_update(#r_role{role_id = RoleID} = State, BgInfo) ->
    List = bg_act_misc:trans_to_p_bg_act_entry(BgInfo#r_bg_act.config_list, ?BG_ACT_CONSUME_RANK),
    common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{id = ?BG_ACT_CONSUME_RANK, update_list = List}),
    State.

consume(Consume, RBgInfo, #r_role{role_attr = RoleAttr,role_id = RoleID} = State) ->
    BgSummer = mod_role_extra:get_data(?EXTRA_KEY_BG_SUMMER, #r_bg_summer{}, State),
    BgSummer2 = BgSummer#r_bg_summer{my_use = Consume + BgSummer#r_bg_summer.my_use},
    common_misc:unicast(RoleID, #m_role_bg_rrank_update_toc{my_use = BgSummer2#r_bg_summer.my_use}),
    #r_bg_act{config = Config} = RBgInfo,
    Recharge = proplists:get_value(comsume, Config),
    case Recharge > BgSummer2#r_bg_summer.my_use of
        false ->
            world_bg_act_server:info({func, hook_bg_act, update_consume_rank, [State#r_role.role_id, RoleAttr#r_role_attr.role_name, BgSummer2#r_bg_summer.my_use]});
        _ ->
            ok
    end,
    mod_role_extra:set_data(?EXTRA_KEY_BG_SUMMER, BgSummer2, State).