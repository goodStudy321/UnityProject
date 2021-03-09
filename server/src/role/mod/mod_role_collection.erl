%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 七月 2018 10:13
%%%-------------------------------------------------------------------
-module(mod_role_collection).
-author("WZP").
-include("role.hrl").
%% API
-export([
    send_collection_reward/3
]).

-export([
    handle/2
]).


send_collection_reward(RoleID, Type, Num) ->
    case Type =:= 0 of
        true ->
            ok;
        _ ->
            role_misc:info_role(RoleID, mod_role_collection, {send_collection_reward, Type, Num})
    end.


handle({send_collection_reward, TypeID, Num}, State) ->
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = false}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_FAMILY_ANSWER, GoodsList}],
    mod_role_bag:do(BagDoings, State).


