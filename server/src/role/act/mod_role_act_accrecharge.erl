%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 六月 2018 9:40
%%%-------------------------------------------------------------------
-module(mod_role_act_accrecharge).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("red_packet.hrl").
-include("proto/mod_role_act_accrecharge.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2,
    zero/1
]).

-export([
    do_recharge/2,
    level_up/3
]).

-export([
    act_accrecharge_repair_i/1,
    act_accrecharge_repair/1
]).

act_accrecharge_repair(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {?MODULE, act_accrecharge_repair_i, []});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, act_accrecharge_repair, [RoleID]})
    end.

act_accrecharge_repair_i(#r_role{role_act_accrecharge = RoleAccrecharge, role_pay = RolePay} = State) ->
    Num = RolePay#r_role_pay.total_pay_gold - RoleAccrecharge#r_role_act_accrecharge.recharge,
    do_recharge(State, Num).



init(#r_role{role_id = RoleID, role_act_accrecharge = undefined} = State) ->
    Reward = init_reward(),
%%    #r_act{status = Status} = world_act_server:get_act(?ACT_ACCRECHARGE_ID),
    Status = ?IF(mod_role_act:is_act_open2(?ACT_ACCRECHARGE_ID, State) =:= true, ?ACT_STATUS_OPEN, ?ACT_STATUS_CLOSE),
    ActAccRecharge = #r_role_act_accrecharge{role_id = RoleID, recharge = 0, reward = Reward, status = Status},
    State#r_role{role_act_accrecharge = ActAccRecharge};
init(State) ->
    State.

%%
%%init_data(#r_role{role_id = RoleID} = State, StartTime) ->
%%    Reward = init_reward(),
%%    #r_act{status = Status} = world_act_server:get_act(?ACT_ACCRECHARGE_ID),
%%    ActAccRecharge = #r_role_act_accrecharge{role_id = RoleID, recharge = 0, reward = Reward, status = Status, start_time = StartTime},
%%    State#r_role{role_act_accrecharge = ActAccRecharge}.


online(#r_role{role_id = RoleID, role_act_accrecharge = ActAccRecharge} = State) ->
    case mod_role_act:is_act_open2(?ACT_ACCRECHARGE_ID, State) of
        true ->
            common_misc:unicast(RoleID, #m_act_accrecharge_toc{recharge = ActAccRecharge#r_role_act_accrecharge.recharge, reward = ActAccRecharge#r_role_act_accrecharge.reward});
        _ ->
            State
    end,
    State.

zero(#r_role{role_act_accrecharge = undefined} = State) ->
    State;
zero(State) ->
    online(State).

handle({#m_act_accrecharge_reward_tos{key = Key}, RoleID, _PID}, State) ->
    do_get_reward(State, RoleID, Key).



init_reward() ->
    List = cfg_act_accrecharge:list(),
    lists:foldl(
        fun({_, {_, Quota, _}}, Rewards) ->
            [#p_kv{id = Quota, val = ?ACT_REWARD_CANNOT_GET}|Rewards]
        end, [], List).


do_recharge(#r_role{role_id = RoleID, role_act_accrecharge = ActAccRecharge} = State, RechargeNum) ->
    case mod_role_act:is_act_open3(?ACT_ACCRECHARGE_ID, State) of
        true ->
            ActAccRecharge2 = do_recharge2(ActAccRecharge, RechargeNum),
            [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(?ACT_ACCRECHARGE_ID),
            ?IF(mod_role_data:get_role_level(State) >= MinLevel,
                common_misc:unicast(RoleID, #m_act_accrecharge_toc{recharge = ActAccRecharge2#r_role_act_accrecharge.recharge, reward = ActAccRecharge2#r_role_act_accrecharge.reward}), ok),
            State#r_role{role_act_accrecharge = ActAccRecharge2};
        _ ->
            State
    end.

do_recharge2(ActAccRecharge, RechargeNum) ->
    NewRecharge = ActAccRecharge#r_role_act_accrecharge.recharge + RechargeNum,
    NewAccReward = lists:foldl(
        fun(Pkv, AccReward) ->
            case Pkv#p_kv.id =< NewRecharge andalso Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                true ->
                    [Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}|AccReward];
                _ ->
                    [Pkv|AccReward]
            end
        end, [], ActAccRecharge#r_role_act_accrecharge.reward),
    ActAccRecharge#r_role_act_accrecharge{reward = NewAccReward, recharge = NewRecharge}.


do_get_reward(State, RoleID, Key) ->
    case catch check_can_get(State, Key) of
        {ok, State2, Log} ->
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_act_accrecharge_reward_toc{reward_key = Key}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_accrecharge_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_act_accrecharge = ActAccRecharge} = State, Key) ->
    case lists:keytake(Key, #p_kv.id, ActAccRecharge#r_role_act_accrecharge.reward) of
        {value, Pkv, OtherReward} ->
            ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET, ?THROW_ERR(?ERROR_ACT_ACCRECHARGE_REWARD_002), ok),
            ?IF(Pkv#p_kv.val =:= ?ACT_REWARD_GOT, ?THROW_ERR(?ERROR_ACT_ACCRECHARGE_REWARD_001), ok),
            [Config] = lib_config:find(cfg_act_accrecharge, Key),
            RewardList = lib_tool:string_to_intlist(Config#c_act_accrecharge.reward),
            NewActAccRecharge = ActAccRecharge#r_role_act_accrecharge{reward = [Pkv#p_kv{val = ?ACT_REWARD_GOT}|OtherReward]},
            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num, _Bind} <- RewardList],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoing = [{create, ?ITEM_GAIN_ACT_ACCREECHARGE, GoodsList}],
            State2 = State#r_role{role_act_accrecharge = NewActAccRecharge},
            State3 = mod_role_bag:do(BagDoing, State2),
            Log = get_log(Key, State3),
            {ok, State3, Log};
        _ ->
            ?THROW_ERR(?ERROR_ACT_ACCRECHARGE_REWARD_003)
    end.


level_up(OldLevel, NewLevel, State) ->
    case mod_role_act:is_act_open2(?ACT_ACCRECHARGE_ID,State) of
        true ->
            [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(?ACT_ACCRECHARGE_ID),
            case MinLevel > OldLevel andalso MinLevel =< NewLevel of
                true ->
                    #r_role{role_id = RoleID, role_act_accrecharge = ActAccRecharge} = State,
                    common_misc:unicast(RoleID, #m_act_accrecharge_toc{recharge = ActAccRecharge#r_role_act_accrecharge.recharge, reward = ActAccRecharge#r_role_act_accrecharge.reward});
                _ ->
                    ok
            end;
        _ ->
            ok
    end.





get_log(Key, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #log_role_gear{
        role_id = RoleID,
        type = ?LOG_GEAR_ACC_RECHARGE,
        game_channel_id = RoleAttr#r_role_attr.game_channel_id,
        channel_id = RoleAttr#r_role_attr.channel_id,
        gear = Key
    }.