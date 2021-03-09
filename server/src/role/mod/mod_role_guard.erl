%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 七月 2018 17
%%%-------------------------------------------------------------------
-module(mod_role_guard).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("bg_act.hrl").
-include("fight.hrl").
-include("proto/mod_role_guard.hrl").
-include("proto/mod_role_item.hrl").

%%真*精灵 替换 假*精灵 时摧毁 假*精灵
%%-define(BIG_GUARD_OPEN, 0).         %%开启
%%-define(BIG_GUARD_NOT_OPEN, -1).    %%未开启
-define(GUARD, 1).                  %%小精灵
-define(BIG_GUARD, 2).              %%大精灵
-define(GUARD_GLOBAL, 104).         %%全局配置
-define(GUARD_POS, 11).                  %%小精灵   右
-define(BIG_GUARD_POS, 12).              %%小仙女   左
-define(KING_GUARD, 40009).              %%精灵王   左


-define(GURARD_REMIND_TIME, 7200).         %%2小时


%%%% API
-export([
    init/1,
    pre_enter/1,
    online/1,
    loop/2,
    calc/1,
    handle/2,
    king_guard_online/1
]).

-export([
    load_guard/3,
    gm_overdue_guard/3,
    buy_guard/3,
    activate_king_guard/1
]).

-export([
    is_guard_elf_active/1,
    is_guard_fairy_active/1
]).

gm_overdue_guard(#r_role{role_guard = RoleGuard} = State, Num1, Num2) ->
    Now = time_tool:now(),
    case Num1 =:= 1 of
        true ->
            Guard = RoleGuard#r_role_guard.guard#p_goods{end_time = Now + Num2},
            RoleGuard2 = RoleGuard#r_role_guard{guard = Guard};
        _ ->
            BigGuard = RoleGuard#r_role_guard.big_guard#p_goods{end_time = Now + Num2},
            RoleGuard2 = RoleGuard#r_role_guard{big_guard = BigGuard}
    end,
    State2 = State#r_role{role_guard = RoleGuard2},
    send_guard_info(State2),
    State2.


init(#r_role{role_id = RoleID, role_guard = undefined} = State) ->
    RoleGuard = #r_role_guard{role_id = RoleID},
    State#r_role{role_guard = RoleGuard};
init(State) ->
    State.

pre_enter(State) ->
    send_guard_info(State),
    State.

online(#r_role{role_attr = RoleAttr} = State) ->
    king_guard_online(State),
    online_check(time_tool:now(), RoleAttr#r_role_attr.last_offline_time, State).


king_guard_online(#r_role{role_id = RoleID} = State) ->
    case State#r_role.role_guard#r_role_guard.king_guard_buy =/= 2 of
        true ->
            case State#r_role.role_guard#r_role_guard.king_guard_buy =:= 0 of
                false ->
                    ok;
                _ ->
                    case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_KING_GUARD, State) of
                        #r_bg_act{config = Config} ->
                            Price = proplists:get_value(price, Config),
                            common_misc:unicast(RoleID, #m_role_king_guard_toc{type = State#r_role.role_guard#r_role_guard.king_guard_buy, money = Price});
                        _ ->
                            case mod_role_act:is_act_open(?ACT_OTF_BIG_GUARD, State) of
                                true ->
                                    common_misc:unicast(RoleID, #m_role_king_guard_toc{type = State#r_role.role_guard#r_role_guard.king_guard_buy}),
                                    ok;
                                _ ->
                                    ok
                            end
                    end
            end;
        _ ->
            ok
    end.



send_guard_info(State) ->
    #r_role{role_id = RoleID, role_guard = RoleGuard} = State,
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    {TypeID, EndTime} = case Guard =:= undefined of
                            true ->
                                {0, 0};
                            _ ->
                                {Guard#p_goods.type_id, Guard#p_goods.end_time}
                        end,
    {BigTypeID, BigEndTime} = case BigGuard =:= undefined of
                                  true ->
                                      {0, 0};
                                  _ ->
                                      {BigGuard#p_goods.type_id, BigGuard#p_goods.end_time}
                              end,
    common_misc:unicast(RoleID, #m_role_guard_info_toc{guard = TypeID, end_time = EndTime, big_guard = BigTypeID, big_end_time = BigEndTime}).


calc(State) ->
    #r_role{role_guard = RoleGuard} = State,
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    ActorCalAttr = case Guard =:= undefined of
                       true ->
                           #actor_cal_attr{};
                       _ ->
                           [Config] = lib_config:find(cfg_decoration, Guard#p_goods.type_id),
                           ValueList = lib_tool:string_to_intlist(Config#c_decoration.attr, "|", ","),
                           PkvList = trans_to_pkv(ValueList),
                           common_misc:get_attr_by_kv(PkvList)
                   end,
    if
        erlang:is_record(BigGuard, p_goods) ->
            [Config2] = lib_config:find(cfg_decoration, BigGuard#p_goods.type_id),
            ValueList2 = lib_tool:string_to_intlist(Config2#c_decoration.attr, "|", ","),
            PkvList2 = trans_to_pkv(ValueList2),
            BigActorCalAttr = common_misc:get_attr_by_kv(PkvList2),
            ActorCalAttr2 = common_misc:sum_calc_attr2(BigActorCalAttr, ActorCalAttr);
        true ->
            ActorCalAttr2 = ActorCalAttr
    end,
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_GUARD, ActorCalAttr2).


%%分钟检查一次
loop(Now, State) ->
    #r_role{role_id = RoleID, role_guard = RoleGuard} = State,
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    {State2, IsCalc} = case Guard =:= undefined of
                           true ->
                               {State, false};
                           _ ->
                               if
                                   Guard#p_goods.end_time =/= 0 andalso Guard#p_goods.end_time =< Now ->
                                       common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?GUARD, remind = true, overtime = true}),
                                       {do_unload_guard(State, guard), true};
                                   Guard#p_goods.end_time - ?GURARD_REMIND_TIME =:= Now ->
                                       common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?GUARD, remind = true, overtime = false}),
                                       {State, false};
                                   true ->
                                       {State, false}
                               end
                       end,
    {State3, IsCalc2} = case BigGuard =:= undefined of
                            true ->
                                {State2, false};
                            _ ->
                                if
                                    BigGuard#p_goods.end_time =/= 0 andalso BigGuard#p_goods.end_time =< Now ->
                                        common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?BIG_GUARD, remind = true, overtime = true}),
                                        {do_unload_guard(State2, big_guard), true};
                                    BigGuard#p_goods.end_time - ?GURARD_REMIND_TIME =:= Now ->
                                        common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?BIG_GUARD, remind = true, overtime = false}),
                                        {State2, false};
                                    true ->
                                        {State2, false}
                                end
                        end,
    ?IF(IsCalc orelse IsCalc2, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_GUARD_LOAD, 1), State3).

load_guard(Goods, EffectArgs, #r_role{role_guard = RoleGuard} = State) ->
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    [Config2] = lib_config:find(cfg_decoration, Goods#p_goods.type_id),
    {LoadPos, ChangeGuard} = ?IF(Config2#c_decoration.index =:= ?GUARD_POS, {guard, Guard}, {big_guard, BigGuard}),
    if
        not erlang:is_record(ChangeGuard, p_goods) ->
            load_guard2(Goods, EffectArgs, State, LoadPos);
        Goods#p_goods.type_id =/= ChangeGuard#p_goods.type_id ->
            State2 = case ChangeGuard#p_goods.type_id =:= ?FAKE_ELF andalso Goods#p_goods.type_id =:= 40001 of
                         true ->
                             State;
                         _ ->
                             do_unload_guard(State, LoadPos)
                     end,
            load_guard2(Goods, EffectArgs, State2, LoadPos);
        true ->
            NewChangeGuard = ChangeGuard#p_goods{end_time = ChangeGuard#p_goods.end_time + EffectArgs},
            NewRoleGuard = ?IF(LoadPos =:= guard, RoleGuard#r_role_guard{guard = NewChangeGuard}, RoleGuard#r_role_guard{big_guard = NewChangeGuard}),
            State2 = State#r_role{role_guard = NewRoleGuard},
            send_guard_info(State2),
            State2
    end.

load_guard2(Goods, EffectArgs, #r_role{role_guard = RoleGuard} = State2, Type) ->
    {StartTime, EndTime} = if
                               EffectArgs =:= 0 ->
                                   {0, 0};
                               true ->
                                   case Goods#p_goods.start_time =:= 0 of
                                       true ->
                                           {time_tool:now(), time_tool:now() + EffectArgs};
                                       _ ->
                                           {Goods#p_goods.start_time, Goods#p_goods.end_time}
                                   end
                           end,
    Goods2 = Goods#p_goods{end_time = EndTime, start_time = StartTime},
    case Type =:= guard of
        true ->
            NewRoleGuard = RoleGuard#r_role_guard{guard = Goods2},
            State3 = State2#r_role{role_guard = NewRoleGuard};
        _ ->
            NewRoleGuard = RoleGuard#r_role_guard{big_guard = Goods2},
            State3 = State2#r_role{role_guard = NewRoleGuard}
    end,
    send_guard_info(State3),
    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_GUARD_LOAD, Goods2#p_goods.type_id),
    State5 = ?IF(lists:member(Goods2#p_goods.type_id, [40001, 40002]), mod_role_god_book:load_decoration(State4), State4),
    mod_role_day_target:load_guard(State5).


do_unload_guard(#r_role{role_guard = RoleGuard} = State, Type) ->
    case Type =:= guard of
        true ->
            case RoleGuard#r_role_guard.guard =:= undefined of
                true ->
                    State;
                _ ->
                    GoodsList = [RoleGuard#r_role_guard.guard],
                    State2 = role_misc:create_goods(State, ?ITEM_GAIN_EQUIP_REPLACE, GoodsList),
                    NewRoleGuard = RoleGuard#r_role_guard{guard = undefined},
                    State2#r_role{role_guard = NewRoleGuard}
            end;
        _ ->
            case RoleGuard#r_role_guard.big_guard =:= undefined of
                true ->
                    State;
                _ ->
                    GoodsList = [RoleGuard#r_role_guard.big_guard],
                    State2 = role_misc:create_goods(State, ?ITEM_GAIN_EQUIP_REPLACE, GoodsList),
                    NewRoleGuard = RoleGuard#r_role_guard{big_guard = undefined},
                    State2#r_role{role_guard = NewRoleGuard}
            end
    end.



handle({#m_role_open_guard_tos{}, _RoleID, _PID}, State) ->
    State;
handle({#m_role_king_guard_reward_tos{}, RoleID, _PID}, State) ->
    do_get_king_guard(State, RoleID).
%%    do_open_big_guard(RoleID, State).
%%
%%
%%do_open_big_guard(RoleID, State) ->
%%    case catch check_can_open(State) of
%%        {ok, State2, AssetDoings} ->
%%            State3 = mod_role_asset:do(AssetDoings, State2),
%%            common_misc:unicast(RoleID, #m_role_open_guard_toc{}),
%%            State3;
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_role_open_guard_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_can_open(#r_role{role_guard = RoleGuard, role_attr = RoleAttr, role_vip = RoleVip} = State) ->
%%    ?IF(RoleGuard#r_role_guard.big_guard =:= ?BIG_GUARD_NOT_OPEN, ok, ?THROW_ERR(1)),
%%    [OpenConfig] = lib_config:find(cfg_global, ?GUARD_GLOBAL),
%%    [NeedGold, NeedLevel, NeedVip] = OpenConfig#c_global.list,
%%    ?IF(RoleAttr#r_role_attr.level >= NeedLevel orelse RoleVip#r_role_vip.level >= NeedVip, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
%%    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_BIG_GUARD, State),
%%    NewRoleGuard = RoleGuard#r_role_guard{big_guard = ?BIG_GUARD_OPEN},
%%    {ok, State#r_role{role_guard = NewRoleGuard}, AssetDoings}.



trans_to_pkv(ValueList) when is_list(ValueList) ->
    trans_to_pkv(ValueList, []);
trans_to_pkv({Key, Value}) ->
    [#p_kv{id = Key, val = Value}].

trans_to_pkv([], List) ->
    List;
trans_to_pkv([{Key, Value}|T], List) ->
    trans_to_pkv(T, [#p_kv{id = Key, val = Value}|List]).


buy_guard(TypeID, Num, State) ->
    #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
    EffectArgs2 = lib_tool:to_integer(EffectArgs) * Num,
    Goods = #p_goods{type_id = TypeID, num = 1},
    {BagDoing2, RemanentTime2} = case mod_role_bag:get_goods_by_type_id(TypeID, State) of
                                     false ->
                                         {[], 0};
                                     #p_goods{end_time = EndTime} ->
                                         RemanentTime = EndTime - time_tool:now(),
                                         BagDoing = [{decrease, ?ITEM_REDUCE_GUARD, [#r_goods_decrease_info{type_id = TypeID, num = 1}]}],
                                         {BagDoing, RemanentTime}
                                 end,
    BagDoing4 = case 40001 =:= TypeID of
                    true ->
                        case catch mod_role_bag:check_num_by_type_id(?FAKE_ELF, 1, ?ITEM_REDUCE_GUARD, State) of
                            [{decrease, _, _}] = BagDoing3 ->
                                BagDoing3 ++ BagDoing2;
                            _ ->
                                BagDoing2
                        end;
                    _ ->
                        BagDoing2
                end,
    State2 = case BagDoing4 of
                 [] ->
                     State;
                 _ ->
                     mod_role_bag:do(BagDoing4, State)
             end,
    EffectArgs3 = ?IF(RemanentTime2 > 0, RemanentTime2 + EffectArgs2, EffectArgs2),
    load_guard(Goods, EffectArgs3, State2).

%%RoleGuard#r_role_guard.big_guard =:= ?BIG_GUARD_OPEN
%%与loop有重要细微区别  修改需谨慎
online_check(Now, LastOffLineTime, State) ->
    #r_role{role_id = RoleID, role_guard = RoleGuard} = State,
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    {State2, IsCalc} = case Guard =:= undefined of
                           true ->
                               {State, false};
                           _ ->
                               if
                                   Guard#p_goods.end_time =:= 0 ->
                                       {State, false};
                                   Guard#p_goods.end_time =< Now ->
                                       Remind1 = LastOffLineTime < Guard#p_goods.end_time andalso Guard#p_goods.end_time < Now,
                                       common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?GUARD, remind = Remind1, overtime = true}),
                                       {do_unload_guard(State, guard), true};
                                   Guard#p_goods.end_time - ?GURARD_REMIND_TIME < Now andalso LastOffLineTime =< Guard#p_goods.end_time - ?GURARD_REMIND_TIME ->
                                       common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?GUARD, remind = true, overtime = false}),
                                       {State, false};
                                   true ->
                                       {State, false}
                               end
                       end,
    {State3, IsCalc2} = case BigGuard =:= undefined of
                            true ->
                                {State2, false};
                            _ ->
                                if
                                    BigGuard#p_goods.end_time =:= 0 ->
                                        {State2, false};
                                    BigGuard#p_goods.end_time =< Now ->
                                        Remind2 = LastOffLineTime < BigGuard#p_goods.end_time andalso BigGuard#p_goods.end_time < Now,
                                        common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?BIG_GUARD, remind = Remind2, overtime = true}),
                                        {do_unload_guard(State2, guard), true};
                                    BigGuard#p_goods.end_time - ?GURARD_REMIND_TIME < Now andalso LastOffLineTime =< BigGuard#p_goods.end_time - ?GURARD_REMIND_TIME ->
                                        common_misc:unicast(RoleID, #m_role_guard_overtime_toc{type = ?BIG_GUARD, remind = true, overtime = false}),
                                        {State2, false};
                                    true ->
                                        {State2, false}
                                end
                        end,
    ?IF(IsCalc orelse IsCalc2, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_GUARD_LOAD, 1), State3).


activate_king_guard(State) ->
    case State#r_role.role_guard#r_role_guard.king_guard_buy =:= 0 of
        false ->
            State;
        _ ->
            case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_KING_GUARD, State) of
                #r_bg_act{config = Config} ->
                    Price = proplists:get_value(price, Config),
                    RoleGuard = State#r_role.role_guard#r_role_guard{king_guard_buy = 1},
                    common_misc:unicast(State#r_role.role_id, #m_role_king_guard_toc{type = 1, money = Price}),
                    State#r_role{role_guard = RoleGuard};
                _ ->
                    case mod_role_act:is_act_open(?ACT_OTF_BIG_GUARD, State) of
                        true ->
                            RoleGuard = State#r_role.role_guard#r_role_guard{king_guard_buy = 1},
                            common_misc:unicast(State#r_role.role_id, #m_role_king_guard_toc{type = 1}),
                            State#r_role{role_guard = RoleGuard};
                        _ ->
                            State
                    end
            end
    end.


do_get_king_guard(State, RoleID) ->
    case catch check_can_get_king_guard(State) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_role_king_guard_reward_toc{}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_king_guard_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get_king_guard(#r_role{role_guard = RoleGuard} = State) ->
    ?IF(RoleGuard#r_role_guard.king_guard_buy =:= 2, ?THROW_ERR(?ERROR_ROLE_KING_GUARD_REWARD_001), ok),
    ?IF(RoleGuard#r_role_guard.king_guard_buy =:= 0, ?THROW_ERR(?ERROR_ROLE_KING_GUARD_REWARD_002), ok),
    RoleGuard2 = RoleGuard#r_role_guard{king_guard_buy = 2},
    GoodsList = [#p_goods{type_id = ?KING_GUARD, num = 1, bind = true}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_KING_GUARD, GoodsList}],
    {ok, State#r_role{role_guard = RoleGuard2}, BagDoings}.

is_guard_elf_active(State) ->
    #r_role{role_guard = #r_role_guard{guard = Guard}} = State,
    Now = time_tool:now(),
    case Guard of
        #p_goods{end_time = EndTime} ->
            EndTime =:= 0 orelse EndTime >= Now;
        _ ->
            false
    end.

is_guard_fairy_active(State) ->
    #r_role{role_guard = #r_role_guard{big_guard = BigGuard}} = State,
    Now = time_tool:now(),
    case BigGuard of
        #p_goods{end_time = EndTime} ->
            EndTime =:= 0 orelse EndTime >= Now;
        _ ->
            false
    end.