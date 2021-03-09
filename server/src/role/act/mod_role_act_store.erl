%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 七月 2019 19:28
%%%-------------------------------------------------------------------
-module(mod_role_act_store).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("proto/mod_role_act_store.hrl").


%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    init_data/2
]).



init(#r_role{role_id = RoleID, role_act_store = undefined} = State) ->
    RoleActStore = #r_role_act_store{role_id = RoleID, buy_list = []},
    State#r_role{role_act_store = RoleActStore};
init(State) ->
    State.


init_data(#r_role{role_id = RoleID} = State , StateTime) ->
    RoleActStore = #r_role_act_store{role_id = RoleID, buy_list = [] , start_date = StateTime},
    State#r_role{role_act_store = RoleActStore}.

online(State) ->
    #r_role{role_id = RoleID, role_act_store = RoleActStore} = State,
    case mod_role_act:is_act_open(?ACT_STORE, State) of
        true ->
            common_misc:unicast(RoleID, #m_role_act_store_toc{buy_list = RoleActStore#r_role_act_store.buy_list});
        _ ->
            ok
    end,
    State.






handle({#m_role_act_store_buy_tos{id = ID}, RoleID, _PID}, State) ->
    do_act_store_buy(RoleID, ID, State).

do_act_store_buy(RoleID, ID, State) ->
%%    RoleID, ID, State.
    case catch check_can_buy(ID, State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_role_act_store_buy_toc{id = ID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_act_store_buy_toc{err_code = ErrCode}),
            State
    end.


check_can_buy(ID, #r_role{role_act_store = RoleActStore} = State) ->
    ?IF(mod_role_act:is_act_open(?ACT_STORE, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    [Config] = lib_config:find(cfg_act_store, ID),
    case lists:keytake(ID, #p_kv.id, RoleActStore#r_role_act_store.buy_list) of
        {value, Pkv, Other} ->
            ok;
        _ ->
            Pkv = #p_kv{id = ID, val = 0}, Other = RoleActStore#r_role_act_store.buy_list
    end,
    ?IF(Pkv#p_kv.val < Config#c_act_store.all_num, ok, ?THROW_ERR(?ERROR_ROLE_ACT_STORE_BUY_001)),
    DecreaseList = mod_role_bag:get_decrease_goods_by_num(Config#c_act_store.need_item, Config#c_act_store.need_num, State),
    [TypeID, AddNum] = Config#c_act_store.item,
    GoodsList = [#p_goods{type_id = TypeID, num = AddNum}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoing = [{decrease, ?ITEM_REDUCE_ACT_STORE, DecreaseList}, {create, ?ITEM_GAIN_ACT_STORE, GoodsList}],
    RoleActStore2 = RoleActStore#r_role_act_store{buy_list = [Pkv#p_kv{val = Pkv#p_kv.val + 1}|Other]},
    {ok, BagDoing, State#r_role{role_act_store = RoleActStore2}}.