%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 十月 2018 20:14
%%%-------------------------------------------------------------------
-module(mod_role_act_zero_panicbuy).
-author("WZP").

-include("role.hrl").
-include("act.hrl").
-include("proto/mod_role_act_zero_panicbuy.hrl").

-define(GLOBAL_PANIC_BUY, 50).     %% 零元抢购全局

%% API
-export([
    function_open/1,
    online/1,
    handle/2,
    zero/1,
    day_reset/1
]).


%%   id道具ID   val购买时间       type :2 -> 可发放   3 -> 已发放


function_open(#r_role{role_id = RoleID, role_act_zeropanicbuy = undefined} = State) ->
    EndTime = time_tool:midnight() + 604800,
    RoleZeroPanicBuy = #r_role_act_zeropanicbuy{role_id = RoleID, end_time = EndTime},
    common_misc:unicast(RoleID, #m_role_zero_panicbuy_info_toc{end_time = EndTime}),
    State#r_role{role_act_zeropanicbuy = RoleZeroPanicBuy};
function_open(State) ->
    State.



online(#r_role{role_act_zeropanicbuy = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID, role_act_zeropanicbuy = RoleZeroPanicBuy} = State) ->
    case RoleZeroPanicBuy#r_role_act_zeropanicbuy.end_time =< time_tool:now() of
        true ->
            ok;
        _ ->
            SendList = [Info#p_kvt.id || Info <- RoleZeroPanicBuy#r_role_act_zeropanicbuy.buy_list],
            common_misc:unicast(RoleID, #m_role_zero_panicbuy_info_toc{id_list = SendList, end_time = RoleZeroPanicBuy#r_role_act_zeropanicbuy.end_time})
    end,
    State.

zero(#r_role{role_act_zeropanicbuy = undefined} = State) ->
    State;
zero(#r_role{role_act_zeropanicbuy = RoleZeroPanicBuy, role_id = RoleID} = State) ->
    Now = time_tool:now(),
    NewRoleZeroPanicBuy = case Now >= RoleZeroPanicBuy#r_role_act_zeropanicbuy.end_time of
                              true ->
                                  common_misc:unicast(RoleID, #m_role_zero_panicbuy_info_toc{end_time = 0}),
                                  RoleZeroPanicBuy#r_role_act_zeropanicbuy{end_time = 0};
                              _ ->
                                  RoleZeroPanicBuy
                          end,
    State#r_role{role_act_zeropanicbuy = NewRoleZeroPanicBuy}.

day_reset(#r_role{role_act_zeropanicbuy = undefined} = State) ->
    State;
day_reset(#r_role{role_act_zeropanicbuy = RoleZeroPanicBuy, role_id = RoleID} = State) ->
    Now = time_tool:now(),
    NewList = check_can_return(Now, RoleID, RoleZeroPanicBuy#r_role_act_zeropanicbuy.buy_list, []),
    NewRoleZeroPanicBuy = RoleZeroPanicBuy#r_role_act_zeropanicbuy{buy_list = NewList},
    State#r_role{role_act_zeropanicbuy = NewRoleZeroPanicBuy}.

check_can_return(_Now, _RoleID, [], List) ->
    List;
check_can_return(Now, RoleID, [#p_kvt{id = ID, type = Type, val = BuyTime} = Info|T], List) ->
    case lib_config:find(cfg_act_zeropanicbuy, ID) of
        [] ->
            check_can_return(Now, RoleID, T, List);
        [Config] ->
            case Type of
                ?ACT_REWARD_GOT ->
                    check_can_return(Now, RoleID, T, [Info|List]);
                _ ->
                    case Now >= time_tool:midnight(BuyTime) + 86400 * Config#c_act_zeropanicbuy.day of
                        false ->
                            check_can_return(Now, RoleID, T, [Info|List]);
                        _ ->
                            GoodsList = [#p_goods{type_id = Config#c_act_zeropanicbuy.type, num = Config#c_act_zeropanicbuy.price, bind = true}],
                            [ItemConfig] = lib_config:find(cfg_item, ID),
                            LetterInfo = #r_letter_info{
                                template_id = ?LETTER_ZERO_PANIC_BUY_RETURN,
                                text_string = [ItemConfig#c_item.name],
                                action = ?ITEM_GAIN_ACT_ZERO_RETURN,
                                goods_list = GoodsList
                            },
                            common_letter:send_letter(RoleID, LetterInfo),
                            check_can_return(Now, RoleID, T, [Info#p_kvt{type = ?ACT_REWARD_GOT}|List])
                    end
            end
    end.



handle({#m_role_zero_panicbuy_tos{id = ID}, RoleID, _PID}, State) ->
    do_zero_buy(State, RoleID, ID).


do_zero_buy(State, RoleID, ID) ->
    case catch check_can_buy(State, ID) of
        {ok, State2, LetterInfo, AssetDoing, BagDoing, Log} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_letter:send_letter(RoleID, LetterInfo),
            common_misc:unicast(RoleID, #m_role_zero_panicbuy_toc{id = ID}),
            mod_role_dict:add_background_logs(Log),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_zero_panicbuy_toc{err_code = ErrCode}),
            State
    end.

check_can_buy(#r_role{role_act_zeropanicbuy = RoleZeroPanicBuy} = State, ID) ->
    case RoleZeroPanicBuy =:= undefined of
        false ->
            case lists:keyfind(ID, #p_kvt.id, RoleZeroPanicBuy#r_role_act_zeropanicbuy.buy_list) of
                false ->
                    [Config] = lib_config:find(cfg_act_zeropanicbuy, ID),
                    AssetDoing = mod_role_asset:check_asset_by_type(Config#c_act_zeropanicbuy.type, Config#c_act_zeropanicbuy.price, ?ASSET_GOLD_REDUCE_FROM_ACT_ZERO_PANIC_BUY, State),
                    GoodsList = [#p_goods{type_id = ID, num = 1, bind = true}],
                    mod_role_bag:check_bag_empty_grid(GoodsList, State),
                    BagDoings = [{create, ?ITEM_GAIN_ACT_ZERO_PANIC_BUY, GoodsList}],
                    Log = get_log(State, Config#c_act_zeropanicbuy.price),
                    [ItemConfig] = lib_config:find(cfg_item, ID),
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_ZERO_PANIC_BUY,
                        text_string = [ItemConfig#c_item.name, lib_tool:to_list(Config#c_act_zeropanicbuy.day)]
                    },
                    NewRoleZeroPanicBuy = RoleZeroPanicBuy#r_role_act_zeropanicbuy{
                        buy_list = [#p_kvt{id = ID, type = ?ACT_REWARD_CAN_GET, val = time_tool:now()}|RoleZeroPanicBuy#r_role_act_zeropanicbuy.buy_list]},
                    {ok, State#r_role{role_act_zeropanicbuy = NewRoleZeroPanicBuy}, LetterInfo, AssetDoing, BagDoings, Log};
                _ ->
                    ?THROW_ERR(?ERROR_ROLE_ZERO_PANICBUY_001)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)
    end.


get_log(#r_role{role_id = RoleID, role_attr = RoleAttr}, Price) ->
    #log_role_gear{
        role_id = RoleID,
        channel_id = RoleAttr#r_role_attr.channel_id,
        game_channel_id = RoleAttr#r_role_attr.game_channel_id,
        type = ?LOG_GEAR_ZERO_PANIC_BUY,
        gear = Price
    }.




















