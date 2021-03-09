%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十月 2019 11:34
%%%-------------------------------------------------------------------
-module(mod_role_cycle_act_misc).
-author("WZP").
-include("role.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_cycle_act_misc.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).


-export([
    init_tower_data/2,
    tower_online/1,
    set_data/3,
    get_data/3
]).

-export([
    gm_tower_set/3
]).



init(#r_role{role_id = RoleID, role_cycle_act_misc = undefined} = State) ->
    RoleCycleMisc = #r_role_cycle_misc{role_id = RoleID},
    State#r_role{role_cycle_act_misc = RoleCycleMisc};
init(State) ->
    State.


online(State) ->
    tower_online(State).


handle({#m_cycle_tower_draw_tos{}, RoleID, _PID}, State) ->
    do_tower_draw(RoleID, State).


%%%===================================================================
%%% 通天宝塔   start
%%%===================================================================

gm_tower_set(State, Layer, Pool) ->
    case get_data(?CYCLE_MISC_TOWER, false, State) of
        #r_role_cycle_tower{} = RoleCycleTower ->
            RoleCycleTower2 = RoleCycleTower#r_role_cycle_tower{layer = Layer, pool = Pool},
            send_online_info(State#r_role.role_id, RoleCycleTower2),
            State2 = set_data(?CYCLE_MISC_TOWER, RoleCycleTower2, State),
            State2;
        _ ->
            State
    end.

init_tower_data(State, StartTime) ->
    RoleCycleTower = #r_role_cycle_tower{start_time = StartTime},
    send_online_info(State#r_role.role_id, RoleCycleTower),
    State2 = set_data(?CYCLE_MISC_TOWER, RoleCycleTower, State),
    State2.

send_online_info(RoleID, RoleCycleTower) ->
    common_misc:unicast(RoleID, #m_cycle_tower_toc{layer = RoleCycleTower#r_role_cycle_tower.layer, pool = RoleCycleTower#r_role_cycle_tower.pool}).

tower_online(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TOWER, State) of
        true ->
            case get_data(?CYCLE_MISC_TOWER, false, State) of
                #r_role_cycle_tower{} = RoleCycleTower ->
                    send_online_info(State#r_role.role_id, RoleCycleTower);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    State.


do_tower_draw(RoleID, State) ->
    case catch check_can_draw(State) of
        {ok, State2, BagDoing, AssetDoing, Layer, Pool, ID} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = mod_role_asset:do(AssetDoing, State3),
            common_misc:unicast(RoleID, #m_cycle_tower_draw_toc{layer = Layer, pool = Pool, id = ID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_tower_draw_toc{err_code = ErrCode}),
            State
    end.

check_can_draw(State) ->
    case mod_role_cycle_act:is_act_open_i(?CYCLE_ACT_TOWER, State) of
        {ok, ConfigNum} ->
            case mod_role_cycle_act_misc:get_data(?CYCLE_MISC_TOWER, false, State) of
                #r_role_cycle_tower{} = RoleCycleTower ->
                    [GlobalConfig] = lib_config:find(cfg_global, ?GLOBAL_CYCLE_TOWER),
                    [AddSilver|_] = GlobalConfig#c_global.list,
                    Price = GlobalConfig#c_global.int,
                    NewTimes = RoleCycleTower#r_role_cycle_tower.times + 1,
                    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Price, ?ASSET_GOLD_REDUCE_FROM_CYCLE_TOWER, State),
                    AssetDoing2 = [mod_role_asset:add_asset_by_type(?ASSET_SILVER, AddSilver, ?ASSET_GOLD_ADD_FROM_CYCLE_TOWER)|AssetDoing],
                    DrawList = [
                        begin
                            Weight = case Config#c_cycle_tower.type =:= 1 of
                                         true ->
                                             get_weight(Config#c_cycle_tower.weight, NewTimes);
                                         _ ->
                                             lib_tool:to_integer(Config#c_cycle_tower.weight)
                                     end,
                            {Weight, Config}
                        end || {_, Config} <- lib_config:list(cfg_cycle_tower), Config#c_cycle_tower.config_num =:= ConfigNum,
                        Config#c_cycle_tower.pool_id =:= RoleCycleTower#r_role_cycle_tower.pool, Config#c_cycle_tower.layer =:= RoleCycleTower#r_role_cycle_tower.layer],
                    ?IF(DrawList =:= [], ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),
                    OutPutConfig = lib_tool:get_weight_output(DrawList),
                    if

                        OutPutConfig#c_cycle_tower.type =:= 1 ->
                            NewPool = RoleCycleTower#r_role_cycle_tower.pool,
                            NewLayer = RoleCycleTower#r_role_cycle_tower.layer + 1,
                            NewTimes2 = 0;
                        OutPutConfig#c_cycle_tower.type =:= 2 ->
                            NewPool = get_new_pool_id(RoleCycleTower#r_role_cycle_tower.pool, ConfigNum),
                            NewLayer = 1,
                            NewTimes2 = 0;
                        true ->
                            NewPool = RoleCycleTower#r_role_cycle_tower.pool,
                            NewLayer = RoleCycleTower#r_role_cycle_tower.layer,
                            NewTimes2 = NewTimes
                    end,
                    RoleCycleTower2 = RoleCycleTower#r_role_cycle_tower{pool = NewPool, layer = NewLayer, times = NewTimes2},
                    State2 = set_data(?CYCLE_MISC_TOWER, RoleCycleTower2, State),
                    GoodList = [#p_goods{type_id = OutPutConfig#c_cycle_tower.item, num = OutPutConfig#c_cycle_tower.num}],
                    mod_role_bag:check_bag_empty_grid(?BAG_ID_CYCLE_TOWER, GoodList, State2),
                    BagDoing = [{create, ?BAG_ID_CYCLE_TOWER, ?ITEM_GAIN_TOWER, GoodList}],
                    {ok, State2, BagDoing, AssetDoing2, NewLayer, NewPool, OutPutConfig#c_cycle_tower.id};
                _ ->
                    ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)
    end.

get_new_pool_id(Pool, ConfigNum) ->
    List = lib_config:list(cfg_cycle_tower),
    get_new_pool_id(List, Pool + 1, ConfigNum).

get_new_pool_id([], _Pool, _ConfigNum) ->
    1;
get_new_pool_id([{_, Config}|T], Pool, ConfigNum) ->
    case Config#c_cycle_tower.pool_id =:= Pool andalso Config#c_cycle_tower.config_num =:= ConfigNum of
        true ->
            Pool;
        _ ->
            get_new_pool_id(T, Pool, ConfigNum)
    end.



get_weight(WeightString, Times) ->
    WeightList = lib_tool:string_to_intlist(WeightString),
    get_weight(WeightList, Times, 10000000).

get_weight([], _Times, MinWeight) ->
    MinWeight;
get_weight([{NeedTimes, Weight}|T], Times, MinWeight) ->
    case NeedTimes >= Times andalso Weight < MinWeight of
        true ->
            get_weight(T, Times, Weight);
        _ ->
            get_weight(T, Times, MinWeight)
    end.

%%%===================================================================
%%% 通天宝塔   end
%%%===================================================================


%%%===================================================================
%%% 数据操作
%%%===================================================================
set_data(Key, Value, State) ->
    #r_role{role_cycle_act_misc = RoleCycleMisc} = State,
    #r_role_cycle_misc{data = Data} = RoleCycleMisc,
    Data2 = lists:keystore(Key, 1, Data, {Key, Value}),
    RoleCycleMisc2 = RoleCycleMisc#r_role_cycle_misc{data = Data2},
    State#r_role{role_cycle_act_misc = RoleCycleMisc2}.

get_data(Key, Default, State) ->
    #r_role{role_cycle_act_misc = #r_role_cycle_misc{data = Data}} = State,
    case lists:keyfind(Key, 1, Data) of
        {_, Value} ->
            Value;
        _ ->
            Default
    end.
