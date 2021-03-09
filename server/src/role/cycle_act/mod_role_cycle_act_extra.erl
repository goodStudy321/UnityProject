%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 九月 2019 19:19
%%%-------------------------------------------------------------------
-module(mod_role_cycle_act_extra).
-author("WZP").
-include("role.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_cycle_act_extra.hrl").
%% API
-export([
    init/1,
    day_reset/1,
    online/1,
    handle/2,
    loop_min/2
]).

-export([
    init_egg/3,
    do_egg_end/1
]).


-export([
    get_egg_list_by_num/1,
    get_egg_rewards_by_num/1,
    get_egg_weight_list/1
]).

init(#r_role{role_id = RoleID, role_cycle_act_extra = undefined} = State) ->
    RoleCActExtra = #r_role_cycle_act_extra{role_id = RoleID},
    State#r_role{role_cycle_act_extra = RoleCActExtra};
init(State) ->
    State.

online(#r_role{role_cycle_act_extra = RoleCActExtra, role_id = RoleID} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State) of
        true ->
            {RareLogs, NormalLogs} = world_data:get_egg_log(),
            common_misc:unicast(RoleID, #m_cycle_egg_toc{eggs = RoleCActExtra#r_role_cycle_act_extra.egg_list,
                can_refresh = RoleCActExtra#r_role_cycle_act_extra.egg_refresh > 0, open_times =
                                                         RoleCActExtra#r_role_cycle_act_extra.egg_times, list = RoleCActExtra#r_role_cycle_act_extra.egg_reward, a_log = NormalLogs, b_log = RareLogs}),
            State;
        _ ->
            case RoleCActExtra#r_role_cycle_act_extra.egg_reward =:= [] of
                false ->
                    State;
                _ ->
                    do_egg_end(State)
            end
    end.


day_reset(#r_role{role_cycle_act_extra = RoleCActExtra} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State) of
        true ->
            RoleCActExtra2 = RoleCActExtra#r_role_cycle_act_extra{today_add_refresh_time = 0},
            add_egg_times(State#r_role{role_cycle_act_extra = RoleCActExtra2});
        _ ->
            State
    end.


loop_min(Now, #r_role{role_cycle_act_extra = RoleCActExtra} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State) andalso (Now - RoleCActExtra#r_role_cycle_act_extra.egg_refresh_time) > ?AN_HOUR * 6
         andalso RoleCActExtra#r_role_cycle_act_extra.today_add_refresh_time < 2 of
        true ->
            add_egg_times(State#r_role{role_cycle_act_extra = RoleCActExtra});
        _ ->
            State
    end.



add_egg_times(#r_role{role_cycle_act_extra = RoleCActExtra, role_id = RoleID} = State) ->
    RoleCActExtra2 = RoleCActExtra#r_role_cycle_act_extra{today_add_refresh_time = RoleCActExtra#r_role_cycle_act_extra.today_add_refresh_time + 1,
                                                          egg_refresh = RoleCActExtra#r_role_cycle_act_extra.egg_refresh + 1, egg_refresh_time = time_tool:now()},
    common_misc:unicast(RoleID, #m_cycle_egg_update_a_toc{}),
    State#r_role{role_cycle_act_extra = RoleCActExtra2}.


init_egg(#r_role{role_cycle_act_extra = RoleCActExtra} = State, StartTime, ConfigNum) ->
    {_Inevitable, _ConfigID, EggConfigList} = get_egg_list_by_num(ConfigNum),
    RewardList = get_egg_rewards_by_num(ConfigNum),
    WeightList = get_egg_weight_list(EggConfigList),
    EggList = [begin
                   {EggType, ConfigID} = lib_tool:get_weight_output(WeightList),
                   #p_egg{id = PosID, egg_id = ConfigID, egg_type = EggType} end || PosID <- lists:seq(1, 8)],
    RoleCActExtra2 = RoleCActExtra#r_role_cycle_act_extra{start_egg_time = StartTime, egg_refresh = 1, egg_refresh_time = time_tool:now(), egg_times = 0,
                                                          egg_list = EggList, egg_reward = RewardList, egg_weight_times = 0, today_add_refresh_time = 1},
    online(State#r_role{role_cycle_act_extra = RoleCActExtra2}).


get_egg_rewards_by_num(Num) ->
    List = cfg_egg_reward:list(),
    [#p_kv{id = Config#c_egg_reward.id, val = ?ACT_REWARD_CANNOT_GET} || {_, #c_egg_reward{config_num = ConfigNum} = Config} <- List,Num =:= ConfigNum].

get_egg_weight_list(EggConfigList) ->
    [{Weight, {Type, ID}} || #c_egg{id = ID, egg_type = Type, egg_weight = Weight} <- EggConfigList].

get_egg_list_by_num(Num) ->
    List = cfg_egg:list(),
    List2 = [Config || {_, #c_egg{config_num = ConfigNum} = Config} <- List,Num =:= ConfigNum],
    {Inevitable, ID} = get_egg_list_by_num_i(List2),
    {Inevitable, ID, List2}.

get_egg_list_by_num_i([]) ->
    {15, 3};
get_egg_list_by_num_i([#c_egg{inevitable = Inevitable, id = ID}|T]) ->
    case Inevitable > 0 of
        true ->
            {Inevitable, ID};
        _ ->
            get_egg_list_by_num_i(T)
    end.

handle({#m_cycle_egg_do_tos{num = PosID}, RoleID, _PID}, State) ->
    do_egg_do(RoleID, PosID, State);
handle({#m_cycle_egg_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, ID, State);
handle({#m_cycle_egg_refresh_tos{}, RoleID, _PID}, State) ->
    do_egg_refresh(RoleID, State).

do_egg_refresh(RoleID, State) ->
    case catch check_can_egg_refresh(State) of
        {ok, State2, Eggs, AssetDoing, CanRefresh} ->
            State3 = ?IF(AssetDoing =:= [], State2, mod_role_asset:do(AssetDoing, State2)),
            common_misc:unicast(RoleID, #m_cycle_egg_refresh_toc{eggs = Eggs, can_refresh = CanRefresh}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_egg_refresh_toc{err_code = ErrCode}),
            State
    end.


check_can_egg_refresh(#r_role{role_cycle_act_extra = RoleCActExtra} = State) ->
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    case RoleCActExtra#r_role_cycle_act_extra.egg_refresh > 0 of
        true ->
            RoleCActExtra2 = refresh_egg(RoleCActExtra),
            RoleCActExtra3 = RoleCActExtra2#r_role_cycle_act_extra{egg_refresh = RoleCActExtra#r_role_cycle_act_extra.egg_refresh - 1},
            {ok, State#r_role{role_cycle_act_extra = RoleCActExtra3}, RoleCActExtra3#r_role_cycle_act_extra.egg_list, [], RoleCActExtra3#r_role_cycle_act_extra.egg_refresh > 0};
        _ ->
            [GlobalConfig] = lib_config:find(cfg_global, ?GLOBAL_EGG),
            [_Price, _NeedItem, _NeedNum, RefreshPrice|_] = GlobalConfig#c_global.list,
            UnOpenList = [Egg || #p_egg{type_id = TypeID} = Egg <- RoleCActExtra#r_role_cycle_act_extra.egg_list, TypeID =:= 0],
            NeedGold = RefreshPrice * erlang:length(UnOpenList),
            AssetDoing = ?IF(NeedGold =:= 0, [], mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, RefreshPrice * erlang:length(UnOpenList), ?ASSET_GOLD_REDUCE_FROM_REFRESH_EGG, State)),
            RoleCActExtra2 = refresh_egg(RoleCActExtra),
            {ok, State#r_role{role_cycle_act_extra = RoleCActExtra2}, RoleCActExtra2#r_role_cycle_act_extra.egg_list, AssetDoing, RoleCActExtra2#r_role_cycle_act_extra.egg_refresh > 0}
    end.

refresh_egg(RoleCActExtra) ->
    ConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_EGG),
    {Inevitable, ConfigID, EggConfigList} = get_egg_list_by_num(ConfigNum),
    [GlobalConfig] = lib_config:find(cfg_global, ?GLOBAL_EGG),
    [_Price, _NeedItem, _NeedNum, _RefreshPrice, OpenInevitable|_] = GlobalConfig#c_global.list,
    WeightList = get_egg_weight_list(EggConfigList),
    {GoodEgg, RefreshList} = division(RoleCActExtra#r_role_cycle_act_extra.egg_list, [], []),
    {List, WeightTimes, OpenWeightTimes} = refresh_egg(RefreshList, RoleCActExtra#r_role_cycle_act_extra.egg_weight_times, RoleCActExtra#r_role_cycle_act_extra.open_egg_weight_times, WeightList, [], Inevitable, OpenInevitable, ConfigID),
    RoleCActExtra#r_role_cycle_act_extra{egg_list = List ++ GoodEgg, egg_weight_times = WeightTimes, open_egg_weight_times = OpenWeightTimes}.

refresh_egg([], WeightTimes, OpenWeightTimes, _WeightList, EggList, _Inevitable, _OpenInevitable, _ConfigID) ->
    {EggList, WeightTimes, OpenWeightTimes};
refresh_egg([ID|T], WeightTimes, OpenWeightTimes, WeightList, EggList, Inevitable, OpenInevitable, ConfigID) ->
    case WeightTimes >= Inevitable orelse OpenWeightTimes >= OpenInevitable of
        true ->
            WeightTimes2 = 0,
            OpenWeightTimes2 = 0,
            Egg = #p_egg{id = ID, egg_type = ?C_ACT_BEST_EGG_TYPE, egg_id = ConfigID};
        _ ->
            {EggType, ConfigID2} = lib_tool:get_weight_output(WeightList),
            Egg = #p_egg{id = ID, egg_type = EggType, egg_id = ConfigID2},
            {WeightTimes2, OpenWeightTimes2} = ?IF(EggType =:= ?C_ACT_BEST_EGG_TYPE, {0, 0}, {WeightTimes + 1, OpenWeightTimes})
    end,
    refresh_egg(T, WeightTimes2, OpenWeightTimes2, WeightList, [Egg|EggList], Inevitable, OpenInevitable, ConfigID).
division([], GoodEgg, RefreshList) ->
    {GoodEgg, RefreshList};
division([Egg|T], GoodEgg, RefreshList) ->
    case Egg#p_egg.type_id =:= 0 andalso (Egg#p_egg.egg_type =:= ?C_ACT_BETTER_EGG_TYPE orelse Egg#p_egg.egg_type =:= ?C_ACT_BEST_EGG_TYPE) of
        true ->
            division(T, [Egg|GoodEgg], RefreshList);
        _ ->
            division(T, GoodEgg, [Egg#p_egg.id|RefreshList])
    end.




do_get_reward(RoleID, ID, State) ->
    case catch check_can_reward(State, ID) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_cycle_egg_reward_toc{id = ID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_egg_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_reward(#r_role{role_cycle_act_extra = RoleCActExtra} = State, ID) ->
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    case lists:keytake(ID, #p_kv.id, RoleCActExtra#r_role_cycle_act_extra.egg_reward) of
        {value, Pkv, Other} ->
            ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_CYCLE_EGG_REWARD_001)),
            [RewardConfig] = lib_config:find(cfg_egg_reward, ID),
            GoodList = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind, _} <- lib_tool:string_to_intlist(RewardConfig#c_egg_reward.reward)],
            mod_role_bag:check_bag_empty_grid(GoodList, State),
            BagDoing = [{create, ?ITEM_GAIN_EGG_REWARD, GoodList}],
            RoleCActExtra2 = RoleCActExtra#r_role_cycle_act_extra{egg_reward = [#p_kv{id = ID, val = ?ACT_REWARD_GOT}|Other]},
            {ok, State#r_role{role_cycle_act_extra = RoleCActExtra2}, BagDoing};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.




do_egg_do(RoleID, PosID, State) ->
    case catch check_can_do(State, PosID) of
        {ok, State2, BagDoing, UpdateEggs, OpenTimes, AssetDoing, CanRefresh, RareLogs, NormalLogs} ->
            State3 = ?IF(BagDoing =:= [], State2, mod_role_bag:do(BagDoing, State2)),
            State4 = ?IF(AssetDoing =:= [], State3, mod_role_asset:do(AssetDoing, State3)),
            common_misc:unicast(RoleID, #m_cycle_egg_do_toc{eggs = UpdateEggs, open_times = OpenTimes, can_refresh = CanRefresh}),
            world_cycle_act_server:info({add_egg_log, RareLogs, NormalLogs}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_egg_do_toc{err_code = ErrCode}),
            State
    end.

check_can_do(#r_role{role_cycle_act_extra = RoleCActExtra} = State, PosID) ->
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_EGG, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    {OpenEggList, OtherList} = case PosID >= 1 andalso PosID =< 8 of
                                   true ->
                                       case lists:keytake(PosID, #p_egg.id, RoleCActExtra#r_role_cycle_act_extra.egg_list) of
                                           {value, Egg, Other} ->
                                               ?IF(Egg#p_egg.type_id =:= 0, ok, ?THROW_ERR(?ERROR_CYCLE_EGG_DO_001)),
                                               {[Egg], Other};
                                           _ ->
                                               ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)
                                       end;
                                   _ ->
                                       {[Egg || #p_egg{type_id = TypeID} = Egg <- RoleCActExtra#r_role_cycle_act_extra.egg_list, TypeID =:= 0],
                                        [Egg || #p_egg{type_id = TypeID} = Egg <- RoleCActExtra#r_role_cycle_act_extra.egg_list, TypeID =/= 0]}
                               end,
    OpenNum = erlang:length(OpenEggList),
    [GlobalConfig] = lib_config:find(cfg_global, ?GLOBAL_EGG),
    [Price, NeedItem, NeedNum, _RefreshPrice|_] = GlobalConfig#c_global.list,
    NeedItemNum = mod_role_bag:get_num_by_type_id(NeedItem, State),
    NeedNum2 = NeedNum * OpenNum,
    {BagDoing2, AssetDoing2} = case NeedItemNum > 0 of
                                   false ->
                                       AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedNum2 * Price, ?ASSET_GOLD_REDUCE_FROM_EGG, State),
                                       {[], AssetDoing};
                                   _ ->
                                       case NeedItemNum > NeedNum2 of
                                           false ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_EGG, [#r_goods_decrease_info{type_id = NeedItem, num = NeedItemNum}]}],
                                               AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, (NeedNum2 - NeedItemNum) * Price, ?ASSET_GOLD_REDUCE_FROM_EGG, State),
                                               {BagDoing, AssetDoing};
                                           _ ->
                                               BagDoing = [{decrease, ?ITEM_REDUCE_EGG, [#r_goods_decrease_info{type_id = NeedItem, num = NeedNum2}]}],
                                               {BagDoing, []}
                                       end
                               end,
    {NewEggs, GoodList, RareLogs, NormalLogs} = open_eggs(OpenEggList, mod_role_data:get_role_name(State)),
    mod_role_bag:check_bag_empty_grid(GoodList, State),
    BagDoing3 = [{create, ?ITEM_GAIN_EGG_REWARD, GoodList}|BagDoing2],
%%    NewEggs2 = NewEggs ++ OtherList,
%%    NewUnOpenList = [Egg || #p_egg{type_id = TypeID} = Egg <- NewEggs2, TypeID =:= 0],
%%    EggRefresh2 = ?IF(erlang:length(NewUnOpenList) =:= 0, RoleCActExtra#r_role_cycle_act_extra.egg_refresh + 1, RoleCActExtra#r_role_cycle_act_extra.egg_refresh),
    EggTimes2 = RoleCActExtra#r_role_cycle_act_extra.egg_times + erlang:length(NewEggs),
    EggReward2 = check_reward(EggTimes2, RoleCActExtra#r_role_cycle_act_extra.egg_reward, []),
    OpenWeightTimes = RoleCActExtra#r_role_cycle_act_extra.open_egg_weight_times + OpenNum,
    RoleCActExtra2 = RoleCActExtra#r_role_cycle_act_extra{egg_list = NewEggs ++ OtherList, egg_times = EggTimes2, egg_reward = EggReward2, open_egg_weight_times = OpenWeightTimes},
    State2 = State#r_role{role_cycle_act_extra = RoleCActExtra2},
    {ok, State2, BagDoing3, NewEggs, EggTimes2, AssetDoing2, RoleCActExtra2#r_role_cycle_act_extra.egg_refresh > 0, RareLogs, NormalLogs}.

check_reward(_EggTimes, [], List) ->
    List;
check_reward(EggTimes, [Pkv|T], List) ->
    case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            [Config] = lib_config:find(cfg_egg_reward, Pkv#p_kv.id),
            case EggTimes >= Config#c_egg_reward.need_num of
                true ->
                    check_reward(EggTimes, T, [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|List]);
                _ ->
                    check_reward(EggTimes, T, [Pkv|List])
            end;
        _ ->
            check_reward(EggTimes, T, [Pkv|List])
    end.

open_eggs(OpenEggList, Name) ->
    open_eggs(OpenEggList, Name, [], [], [], []).

open_eggs([], _Name, OpenEggList, RareLogs, NormalLogs, GoodList) ->
    {OpenEggList, GoodList, RareLogs, NormalLogs};
open_eggs([Egg|T], Name, OpenEggList, RareLogs, NormalLogs, GoodList) ->
    [Config] = lib_config:find(cfg_egg, Egg#p_egg.egg_id),
    List = [{Weight, {ItemID, Num, Bind, IsLog}} || {ItemID, Num, Bind, Weight, IsLog} <- lib_tool:string_to_intlist(Config#c_egg.reward)],
    {ItemID2, Num2, Bind2, IsLog2} = lib_tool:get_weight_output(List),
    case IsLog2 =:= 1 of
        true ->
            open_eggs(T, Name, [Egg#p_egg{type_id = ItemID2, num = Num2, is_bind = Bind2}|OpenEggList], [#p_kvs{id = Egg#p_egg.egg_type, text = Name, val = ItemID2}|RareLogs],
                      [#p_kvs{id = Egg#p_egg.egg_type, text = Name, val = ItemID2}|NormalLogs], [#p_goods{type_id = ItemID2, num = Num2, bind = ?IS_BIND(Bind2)}|GoodList]);
        _ ->
            open_eggs(T, Name, [Egg#p_egg{type_id = ItemID2, num = Num2, is_bind = Bind2}|OpenEggList], RareLogs,
                      [#p_kvs{id = Egg#p_egg.egg_type, text = Name, val = ItemID2}|NormalLogs], [#p_goods{type_id = ItemID2, num = Num2, bind = ?IS_BIND(Bind2)}|GoodList])
    end.


%%
do_egg_end(#r_role{role_cycle_act_extra = RoleCActExtra, role_id = RoleID} = State) ->
    Reward = lists:foldl(
        fun(Pkv, AccList) ->
            case Pkv#p_kv.val =:= ?ACT_REWARD_CAN_GET of
                true ->
                    [Config] = lib_config:find(cfg_egg_reward, Pkv#p_kv.id),
                    GoodList = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind, _} <- lib_tool:string_to_intlist(Config#c_egg_reward.reward)],
                    GoodList ++ AccList;
                _ ->
                    AccList
            end
        end, [], RoleCActExtra#r_role_cycle_act_extra.egg_reward),
    case Reward =/= [] of
        true ->
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_EGG_REWARD,
                text_string = [],
                action = ?ITEM_GAIN_EGG_REWARD,
                goods_list = Reward},
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            ok
    end,
    State#r_role{role_cycle_act_extra = RoleCActExtra#r_role_cycle_act_extra{egg_reward = []}}.



