%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     内部号
%%% @end
%%% Created : 05. 十一月 2018 16:42
%%%-------------------------------------------------------------------
-module(mod_role_insider).
-author("laijichang").
-include("role.hrl").
-include("pay.hrl").

%% API
-export([
    mark_insider/3
]).

-export([
    use_pay_item/4,

    is_insider/1
]).

-export([
    handle/2
]).

mark_insider(RoleID, IsInsider, InsiderTime) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {mark_insider, IsInsider, InsiderTime}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, mark_insider, [RoleID, IsInsider, InsiderTime]})
    end.

use_pay_item(_TypeID, ProductID, Num, State) ->
    [#c_pay{
        add_gold = AddGold,
        package_type = PackageType
    }] = lib_config:find(cfg_pay, ProductID),
    State2 =
        case PackageType of
            ?PAY_PACKAGE_DISCOUNT -> %% 特惠礼包
                mod_role_discount_pay:check_pay(ProductID, State);
            ?KING_GUARD ->
                State;
            _ -> %% 正常充值
                #r_role{role_private_attr = PrivateAttr} = State,
                #r_role_private_attr{insider_gold = InsiderGold} = PrivateAttr,
                InsiderGold2 = InsiderGold + AddGold * Num,
                PrivateAttr2 = PrivateAttr#r_role_private_attr{insider_gold = InsiderGold2},
                State#r_role{role_private_attr = PrivateAttr2}
        end,
    FunList = [ fun(StateAcc) -> mod_role_pay:gm_product_id(ProductID, StateAcc) end || _Index <- lists:seq(1, Num)],
    % FunList2 = [
    %     fun(StateAcc) -> do_item_use_mark(TypeID, StateAcc) end
    % ],
    role_server:execute_state_fun(FunList, State2).

is_insider(State) ->
    #r_role{role_private_attr = RolePrivateAttr} = State,
    RolePrivateAttr#r_role_private_attr.is_insider =:= true.

handle({mark_insider, IsInsider, InsiderTime}, State) ->
    do_mark_insider(IsInsider, InsiderTime, State).

do_mark_insider(IsInsider, InsiderTime, State) ->
    #r_role{role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{is_insider = OldIsInsider} = PrivateAttr,
    case IsInsider =/= OldIsInsider of
        true ->
            do_mark_insider2(IsInsider, InsiderTime, PrivateAttr, State);
        _ ->
            State
    end.

do_mark_insider2(IsInsider, InsiderTime, PrivateAttr, State) ->
    PrivateAttr2 = PrivateAttr#r_role_private_attr{is_insider = IsInsider, insider_time = InsiderTime},
    State2 = State#r_role{role_private_attr = PrivateAttr2},
    role_login:log_role_status(State2),
    State2.

% do_item_use_mark(TypeID, State) ->
%     #r_role{role_private_attr = PrivateAttr} = State,
%     #r_role_private_attr{is_insider = OldIsInsider} = PrivateAttr,
%     case OldIsInsider of
%         true ->
%             State;
%         _ ->
%             erlang:spawn(fun() -> do_send_web(TypeID, State) end),
%             do_mark_insider2(true, time_tool:now(), PrivateAttr, State)
%     end.

% do_send_web(TypeID, State) ->
%     #r_role{role_id = RoleID} = State,
%     URL = web_misc:get_web_url(become_insider_url),
%     Time = time_tool:now(),
%     Ticket = web_misc:get_key(Time),
%     Body = [{role_id, RoleID}, {type_id, TypeID}, {time, Time}, {ticket, Ticket}],
%     case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
%         {ok, "200", _Headers2, Body2} ->
%             {_, Obj2} = mochijson2:decode(Body2),
%             {_, Status} = proplists:get_value(<<"status">>, Obj2),
%             Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
%             case Code of
%                 10200 ->
%                     ok;
%                 _ ->
%                     ?ERROR_MSG("Code : ~w", [Code]),
%                     ok
%             end;
%         Error ->
%             ?ERROR_MSG("Error:~p", [Error]),
%             ok
%     end.