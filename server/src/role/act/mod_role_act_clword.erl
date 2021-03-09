%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 六月 2018 10:34
%%%-------------------------------------------------------------------
-module(mod_role_act_clword).
-author("WZP").

-include("role.hrl").
-include("act.hrl").
-include("proto/gateway.hrl").
-include("proto/mod_role_act_clword.hrl").


%% API
-export([
    init/1,
    online/1,
    handle/2,
    day_reset/1,
    init_reward/0,
    init_data/2
]).

init(#r_role{role_id = RoleId, role_clword = undefined} = State) ->
    Reward = init_reward(),
    RoleClword = #r_role_clword{role_id = RoleId, list = Reward},
    State#r_role{role_clword = RoleClword};
init(State) ->
    State.

init_data(#r_role{role_id = RoleId} = State, StartDate) ->
    Reward = init_reward(),
    RoleClword = #r_role_clword{role_id = RoleId, list = Reward, start_date = StartDate},
    State#r_role{role_clword = RoleClword}.

init_reward() ->
    List = cfg_act_clword:list(),
    lists:foldl(
        fun({_, Config}, Rewards) ->
            case Config#c_act_clword.type of
                ?ACT_CLWORD_ROLE ->
                    [#p_kv{id = Config#c_act_clword.id, val = Config#c_act_clword.num}|Rewards];
                _ ->
                    Rewards
            end
        end, [], List).

day_reset(#r_role{role_id = RoleId} = State) ->
    Reward = init_reward(),
    RoleClword = #r_role_clword{role_id = RoleId, list = Reward},
    State#r_role{role_clword = RoleClword}.


online(#r_role{role_id = RoleId, role_clword = RoleClword} = State) ->
    List2 = case world_act_server:call({mod, act_clword, clword_reword_info}) of
                {ok, List} ->
                    List;
                _ ->
                    []
            end,
    Rewards2 = lists:foldl(
        fun({Id, Num}, Rewards) ->
            [#p_kv{id = Id, val = Num}|Rewards]
        end, [], List2),
    Rewards3 = RoleClword#r_role_clword.list ++ Rewards2,
    common_misc:unicast(RoleId, #m_act_clword_toc{reward = Rewards3}),
    State.




handle({#m_act_clword_reward_tos{reward = Id}, _RoleID, _PID}, State) ->
    do_get_reward(State, Id);
handle({#m_act_clword_tos{}, _RoleID, _PID}, State) ->
    do_get_reward_info(State).


do_get_reward(#r_role{role_id = RoleId} = State, Id) ->
    case catch check_can_get(State, Id) of
        {ok, State2, BagDoing1, BagDoing2} ->
            State3 = mod_role_bag:do(BagDoing1, State2),
            State4 = mod_role_bag:do(BagDoing2, State3),
            common_misc:unicast(RoleId, #m_act_clword_reward_toc{}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleId, #m_act_clword_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_clword = RoleClword} = State, Id) ->
    [Config] = lib_config:find(cfg_act_clword, Id),
    {ConfigNeedItem, ConfigGetItem, ConfigNum, ConfigType} = case common_config:is_merge() of
                                                                 true ->
                                                                     {Config#c_act_clword.merge_need_item, Config#c_act_clword.merge_get_item, Config#c_act_clword.merge_num,
                                                                      Config#c_act_clword.merge_type};
                                                                 _ ->
                                                                     {Config#c_act_clword.need_item, Config#c_act_clword.get_item, Config#c_act_clword.num, Config#c_act_clword.type}
                                                             end,

    NeedList = lib_tool:string_to_intlist(ConfigNeedItem),
    GetItem = lib_tool:string_to_intlist(ConfigGetItem),
    Goods = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- GetItem],
    mod_role_bag:check_bag_empty_grid(Goods, State),
    case check_item_enough(NeedList, [], State) of
        {ok, DecreaseList} ->
            BagDoing1 = [{decrease, ?ITEM_REDUCE_ACT_CLWORD, DecreaseList}],
            State2 = case ConfigNum =:= 0 of
                         false ->
                             case ConfigType of
                                 ?ACT_CLWORD_SERVER ->
                                     case world_act_server:call({mod, act_clword, {clword_get_reword, Id}}) of
                                         ok ->
                                             State;
                                         {error, ErrCode} ->
                                             ?THROW_ERR(ErrCode);
                                         _ ->
                                             ?THROW_ERR(?ERROR_SYSTEM_ERROR_004)
                                     end;
                                 _ ->
                                     {value, Pkv, OtherList} = lists:keytake(Id, #p_kv.id, RoleClword#r_role_clword.list),
                                     case Pkv#p_kv.val > 0 of
                                         false ->
                                             ?THROW_ERR(?ERROR_ACT_CLWORD_REWARD_002);
                                         _ ->
                                             NewRoleClword = RoleClword#r_role_clword{list = [Pkv#p_kv{val = Pkv#p_kv.val - 1}|OtherList]},
                                             State#r_role{role_clword = NewRoleClword}
                                     end
                             end;
                         _ ->
                             State
                     end,
            BagDoing2 = [{create, ?ITEM_GAIN_ACT_CLWORD, Goods}],
            {ok, State2, BagDoing1, BagDoing2};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_item_enough([], DecreaseList, _State) ->
    {ok, DecreaseList};
check_item_enough([{Id, NeedNum}|T], DecreaseList, State) ->
    Num = mod_role_bag:get_num_by_type_id(Id, State),
    case NeedNum > Num of
        true ->
            {error, ?ERROR_ACT_CLWORD_REWARD_001};
        _ ->
            check_item_enough(T, [#r_goods_decrease_info{type = first_bind, type_id = Id, num = NeedNum}|DecreaseList], State)
    end.


do_get_reward_info(#r_role{role_id = RoleId, role_clword = RoleClword} = State) ->
    case world_act_server:call({mod, act_clword, clword_reword_info}) of
        {ok, List} ->
            Rewards2 = lists:foldl(
                fun({Id, Num}, Rewards) ->
                    [#p_kv{id = Id, val = Num}|Rewards]
                end, [], List),
            Rewards3 = Rewards2 ++ RoleClword#r_role_clword.list,
            common_misc:unicast(RoleId, #m_act_clword_toc{reward = Rewards3});
        {error, ErrCode} ->
            common_misc:unicast(RoleId, #m_act_clword_toc{err_code = ErrCode})
    end,
    State.