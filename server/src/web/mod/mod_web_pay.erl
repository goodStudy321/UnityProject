%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2018 10:14
%%%-------------------------------------------------------------------
-module(mod_web_pay).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    pay/1,
    gm_pay_gold/1,
    simulate_pay/1
]).

pay(Req) ->
    Post = Req:parse_post(),
    OrderID = web_tool:get_int_param("order_id", Post),
    PFOrderID = lib_tool:to_list(web_tool:get_string_param("platform_order_id", Post)),
    RoleID = web_tool:get_int_param("role_id", Post),
    ProductID = web_tool:get_int_param("product_id", Post),
    TotalFee = web_tool:get_int_param("total_fee", Post),
    PayArgs = #r_pay_args{
        order_id = OrderID,
        pf_order_id = PFOrderID,
        role_id = RoleID,
        product_id = ProductID,
        total_fee = TotalFee},
    world_pay_server:pay(PayArgs).

gm_pay_gold(Req) ->
    Post = Req:parse_post(),
    RoleIDs = web_tool:get_integer_list("role_ids", Post),
    AddGold = web_tool:get_int_param("gold_number", Post),
    MFA = {mod_role_pay, gm_pay, [AddGold]},
    [begin
         case db:lookup(db_role_attr_p, RoleID) of
             [_Attr] ->
                 case role_misc:is_online(RoleID) of
                     true ->
                         role_misc:info_role(RoleID, MFA);
                     _ ->
                         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [MFA]})
                 end;
             _ ->
                ?ERROR_MSG("RoleID:~w  不存在", [RoleID])
         end
     end|| RoleID <- RoleIDs],
    ok.

simulate_pay(Req) ->
    Post = Req:parse_post(),
    RoleID = web_tool:get_int_param("role_id", Post),
    TotalFee = web_tool:get_int_param("total_fee", Post),
    case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
        [_RoleAttr] ->
            case mod_role_pay:get_product_id_by_pay_fee(TotalFee) of
                ProductID when ProductID > 0 ->
                    case role_misc:is_online(RoleID) of
                        true ->
                            role_misc:info_role(RoleID, {mod_role_pay, gm_product_id, [ProductID]});
                        _ ->
                            world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_pay, gm_product_id, [ProductID]}]})
                    end,
                    ok;
                _ ->
                    {error, "fee not found"}
            end;
        _ ->
            {error, "role_id not found"}
    end.