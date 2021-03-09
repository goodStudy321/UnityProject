%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     开服冲榜活动
%%% @end
%%% Created : 12. 六月 2018 16:44
%%%-------------------------------------------------------------------
-module(mod_role_act_rank).
-author("laijichang").
-include("role.hrl").
-include("role_extra.hrl").
-include("act.hrl").
-include("proto/mod_role_act_rank.hrl").


-export([
    hour_change/2,
    day_reset/1,
    online/1,
    handle/2
]).

%% API
-export([
    copy_five_elements/1,
    level_up/1,
    mount_step/1,
    suit_power/1,
    pet_step/1,
    nature_power/1,
    power_change/1
]).

copy_five_elements(State) ->
    condition_update(?ACT_FIVE_ELEMENTS, State).

level_up(State) ->
    condition_update(?ACT_RANK_LEVEL, State).

mount_step(State) ->
    condition_update(?ACT_RANK_MOUNT, State).

suit_power(State) ->
    condition_update(?ACT_RANK_SUIT, State).

pet_step(State) ->
    condition_update(?ACT_RANK_PET, State).

nature_power(State) ->
    condition_update(?ACT_RANK_NATURE, State).

power_change(State) ->
    condition_update(?ACT_RANK_POWER, State).

condition_update(ID, State) ->
    case world_act_server:is_act_open(?ACT_RANK) of
        true ->
            RankStatus = get_rank_status(ID),
            case  RankStatus =:= ?ACT_RANK_STATUS_RANKING of %% 排行中的时候，更新
                true ->
                    RoleID = State#r_role.role_id,
                    [#c_act_rank{
                        base_condition = BaseCondition,
                        base_condition2 = BaseCondition2,
                        base_condition3 = BaseCondition3,
                        base_condition4 = BaseCondition4,
                        base_condition5 = BaseCondition5,
                        rank_condition = RankCondition}] = lib_config:find(cfg_act_rank, ID),
                    {NowCondition, RankArgs} = get_condition_by_id(ID, State),
                    ?IF(NowCondition >= RankCondition, world_act_server:update_act_rank(RoleID, ID, RankArgs), ok),
                    ConditionList = [BaseCondition, BaseCondition2, BaseCondition3, BaseCondition4, BaseCondition5],
                    {IsBaseUpdate, State2} = base_condition_update(NowCondition, ID, ConditionList, State),
                    ?IF(IsBaseUpdate, online(State2), ok),
                    State2;
                _ ->
                    State
            end;
        _ ->
            State
    end.

base_condition_update(NowCondition, ID, BaseConfigList, State) ->
    #r_act_rank_reward{base_list = BaseList} = ActReward = get_act_reward(ID, State),
    {IsUpdate, BaseList2, _ID} =
        lists:foldl(
            fun(BaseCondition, {IsUpdateAcc, BaseAcc, BaseID}) ->
                BaseID2 = BaseID + 1,
                case lists:keyfind(BaseID, #r_act_rank_base.id, BaseAcc) of
                    #r_act_rank_base{is_condition = IsCondition} = Base ->
                        case IsCondition of
                            true -> %% 满足条件
                                {false, BaseAcc, BaseID2};
                            _ ->
                                IsChange = NowCondition >= BaseCondition,
                                BaseAcc2 = lists:keystore(BaseID, #r_act_rank_base.id, BaseAcc, Base#r_act_rank_base{is_condition = IsChange}),
                                {IsChange orelse IsUpdateAcc, BaseAcc2, BaseID2}
                        end;
                    _ ->
                        IsChange = NowCondition >= BaseCondition,
                        BaseAcc2 = [#r_act_rank_base{id = BaseID, is_condition = IsChange, is_reward = false}|BaseAcc],
                        {IsChange orelse IsUpdateAcc, BaseAcc2, BaseID2}
                end
            end, {false, BaseList, 1}, BaseConfigList),
    ActReward2 = ActReward#r_act_rank_reward{base_list = BaseList2},
    State2 = set_act_reward(ActReward2, State),
    {IsUpdate, State2}.

hour_change(Hour, State) ->
    case world_act_server:is_act_open(?ACT_RANK) of
        true ->
            List = lib_config:list(cfg_act_rank),
            OpenDays = common_config:get_open_days(),
            hour_change2(List, OpenDays, Hour, State);
        _ ->
            State
    end.

hour_change2([], _OpenDays, _Hour, State) ->
    State;
hour_change2([{_ID, Config}|R], OpenDays, Hour, State) ->
    #c_act_rank{rank_time = [RankDays, RankHour]} = Config,
    case OpenDays =:= RankDays andalso Hour =:= RankHour of
        true ->
            online(State);
        _ ->
            hour_change2(R, OpenDays, Hour, State)
    end.

day_reset(State) ->
    case world_act_server:is_act_open(?ACT_RANK) of
        true ->
            List = lib_config:list(cfg_act_rank),
            OpenDays = common_config:get_open_days(),
            day_reset2(List, OpenDays, State);
        _ ->
            State
    end.

day_reset2([], _OpenDays, State) ->
    State;
day_reset2([{_ID, Config}|R], OpenDays, State) ->
    #c_act_rank{id = ID, rank_time = [RankDays|_]} = Config,
    case OpenDays =:= RankDays of
        true ->
            condition_update(ID, State);
        _ ->
            day_reset2(R, OpenDays, State)
    end.

online(State) ->
    case world_act_server:is_act_open(?ACT_RANK) of
        true ->
            StatusList =
                lists:flatten(
                    [begin
                         RankRewardStatus = get_rank_reward_status(ID, State),
                         RankRewardStatus2 = RankRewardStatus =:= ?REWARD_STATUS_OK,
                         case RankRewardStatus2 orelse get_base_is_red(ID, State) of
                             true ->
                                 #p_kb{id = ID, val = true};
                             _ ->
                                 []
                         end
                     end || {ID, _Config} <- lib_config:list(cfg_act_rank)]),
            ?IF(StatusList =/= [], common_misc:unicast(State#r_role.role_id, #m_act_rank_status_toc{status_list = StatusList}), ok);
        _ ->
            ok
    end,
    State.


handle({#m_act_rank_info_tos{id = ID}, RoleID, _PID}, State) ->
    do_rank_info(RoleID, ID, State);
handle({#m_act_rank_reward_tos{id = ID, type = Type}, RoleID, _PID}, State) ->
    do_rank_reward(RoleID, ID, Type, State);
handle({#m_act_rank_rank_tos{id = ID}, RoleID, _PID}, State) ->
    do_rank_rank(RoleID, ID, State);
handle({#m_act_rank_buy_tos{id = ID, type_id = TypeID}, RoleID, _PID}, State) ->
    do_rank_buy(RoleID, ID, TypeID, State).

do_rank_info(RoleID, ID, State) ->
    case catch check_rank_info(ID, State) of
        {ok, Status, Condition, MyRank, RankStatus, BaseRewardStatus, BuyList} ->
            DataRecord = #m_act_rank_info_toc{
                id = ID,
                condition = Condition,
                status = Status,
                my_rank = MyRank,
                rank_reward_status = RankStatus,
                base_reward_list = BaseRewardStatus,
                buy_list = BuyList
            },
            common_misc:unicast(RoleID, DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_rank_info_toc{err_code = ErrCode, id = ID})
    end,
    State.

check_rank_info(ID, State) ->
    world_act_server:is_act_open(?ACT_RANK),
    RoleID = State#r_role.role_id,
    Status = get_rank_status(ID),
    {_NowCondition, ConditionArgs} = get_condition_by_id(ID, State),
    ?IF(Status =/= ?ACT_RANK_STATUS_NOT_OPEN, ok, ?THROW_ERR(?ERROR_ACT_RANK_INFO_001)),
    MyRank = ?IF(is_fit_rank_condition(ID, State), world_act_server:get_role_act_rank(RoleID, ID), 0),
    RankStatus = get_rank_reward_status(ID, State),
    BaseRewardStatus = get_base_reward_status(ID, State),
	#r_act_rank_reward{buy_list = BuyList} = get_act_reward(ID, State),
    {ok, Status, ConditionArgs, MyRank, RankStatus, BaseRewardStatus, BuyList}.

do_rank_reward(RoleID, ID, Type, State) ->
    case catch check_rank_reward(ID, Type, State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            DataRecord = #m_act_rank_reward_toc{
                id = ID,
                type = Type,
                rank_reward_status = get_rank_reward_status(ID, State3),
                base_reward_list = get_base_reward_status(ID, State3)
            },
            common_misc:unicast(RoleID, DataRecord),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_rank_reward_toc{err_code = ErrCode}),
            State
    end.

check_rank_reward(ID, Type, State) ->
    world_act_server:is_act_open(?ACT_RANK),
    RoleID = State#r_role.role_id,
    #r_act_rank_reward{is_reward = IsRankReward, base_list = BaseList} = RankReward = get_act_reward(ID, State),
    [#c_act_rank{
        rank_1 = Rank1,
        rank_1_reward = Rank1Reward,
        rank_2 = Rank2,
        rank_2_reward = Rank2Reward,
        rank_3 = Rank3,
        rank_3_reward = Rank3Reward,
        rank_4 = Rank4,
        rank_4_reward = Rank4Reward,
        base_reward = BaseReward,
        base_reward2 = BaseReward2,
        base_reward3 = BaseReward3,
        base_reward4 = BaseReward4,
        base_reward5 = BaseReward5}] = lib_config:find(cfg_act_rank, ID),
    {GoodsList, State2} =
        if
            Type =:= ?ACT_REWARD_RANK -> %% 排行奖励
                ?IF(get_rank_status(ID) =:= ?ACT_RANK_STATUS_REWARD, ok, ?THROW_ERR(?ERROR_ACT_RANK_REWARD_001)),
                ?IF(IsRankReward, ?THROW_ERR(?ERROR_ACT_RANK_REWARD_002), ok),
                ?IF(is_fit_rank_condition(ID, State), ok, ?THROW_ERR(?ERROR_ACT_RANK_REWARD_003)),
                Rank = world_act_server:get_role_act_rank(RoleID, ID),
                RewardString = get_reward_by_rank(Rank, [{Rank1, Rank1Reward}, {Rank2, Rank2Reward}, {Rank3, Rank3Reward}, {Rank4, Rank4Reward}]),
                GoodsListAcc = [ #p_goods{type_id = TypeID, num = Num} || {TypeID, Num, _IsShine} <- common_misc:get_item_reward(RewardString)],
                StateAcc = set_act_reward(RankReward#r_act_rank_reward{is_reward = true}, State),
                {GoodsListAcc, StateAcc};
            true -> %% 基础奖励
                BaseID = Type - 1,
                case lists:keytake(Type - 1, #r_act_rank_base.id, BaseList) of
                    {value, Base, BaseList2} ->
                        #r_act_rank_base{is_condition = IsCondition, is_reward = IsBaseReward} = Base,
                        ?IF(IsBaseReward, ?THROW_ERR(?ERROR_ACT_RANK_REWARD_002), ok),
                        ?IF(IsCondition, ok, ?THROW_ERR(?ERROR_ACT_RANK_REWARD_003)),
                        ConfigList = [BaseReward, BaseReward2, BaseReward3, BaseReward4, BaseReward5],
                        GoodsListAcc = common_misc:get_reward_p_goods(common_misc:get_item_reward(lists:nth(BaseID, ConfigList))),
                        BaseList3 = [Base#r_act_rank_base{is_reward = true}|BaseList2],
                        RankReward2 = RankReward#r_act_rank_reward{base_list = BaseList3},
                        StateAcc = set_act_reward(RankReward2, State),
                        {GoodsListAcc, StateAcc};
                    _ ->
                        ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
                end
        end,
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_RANK, GoodsList}],
    {ok, BagDoings, State2}.

do_rank_rank(RoleID, ID, State) ->
    Ranks = world_data:get_act_ranks(ID),
    RankList =
        [ begin
              #p_act_rank{
                  rank = Rank,
                  role_id = RankRoleID,
                  role_name = common_role_data:get_role_name(RankRoleID),
                  rank_value = Condition}
          end ||  #r_act_rank{rank = Rank, role_id = RankRoleID, condition = Condition} <- Ranks],
    common_misc:unicast(RoleID, #m_act_rank_rank_toc{ranks = RankList}),
    State.

do_rank_buy(RoleID, ID, IndexID, State) ->
    case catch check_rank_buy(ID, IndexID, State) of
        {ok, AssetDoings, BagDoings, KV, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = mod_role_bag:do(BagDoings, State3),
            common_misc:unicast(RoleID, #m_act_rank_buy_toc{id = ID, buy_info = KV}),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:act_rank_buy(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_rank_buy_toc{err_code = ErrCode}),
            State
    end.

check_rank_buy(ID, IndexID, State) ->
    ?IF(get_rank_status(ID) =:= ?ACT_RANK_STATUS_RANKING, ok, ?THROW_ERR(?ERROR_ACT_RANK_BUY_001)),
    #r_act_rank_reward{buy_list = BuyList} = ActReward = get_act_reward(ID, State),
    {KV, BuyList2} =
        case lists:keytake(IndexID, #p_kv.id, BuyList) of
            {value, KVT, BuyListT} ->
                {KVT, BuyListT};
            _ ->
                {#p_kv{id = IndexID, val = 0}, BuyList}
        end,
    #p_kv{val = BuyNum} = KV,
    [#c_act_rank{buy_goods = BuyString}] = lib_config:find(cfg_act_rank, ID),
    BuyConfig = lib_tool:string_to_intlist(BuyString),
    case lists:keyfind(IndexID, 1, BuyConfig) of
        {IndexID, TypeID, CreateNum, AssetType, _OldValue, AssetValue, _Discount, LimitNum} ->
            ?IF(BuyNum >= LimitNum, ?THROW_ERR(?ERROR_ACT_RANK_BUY_003), ok),
            GoodsList = [#p_goods{type_id = TypeID, num = CreateNum, bind = true}],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            AssetDoings = mod_role_asset:check_asset_by_type(AssetType, AssetValue, ?ASSET_GOLD_REDUCE_FROM_ACT_RANK_BUY, State),
            BagDoings = [{create, ?ITEM_GAIN_ACT_RANK_BUY, GoodsList}],
            KV2 = KV#p_kv{val = BuyNum + 1},
            BuyList3 = [KV2|BuyList2],
            ActReward2 = ActReward#r_act_rank_reward{buy_list = BuyList3},
            State2 = set_act_reward(ActReward2, State),
            {ok, AssetDoings, BagDoings, KV2, State2};
        _ ->
            ?THROW_ERR(?ERROR_ACT_RANK_BUY_002)
    end.

%% 获取当前活动的状态
get_rank_status(ID) ->
    [#c_act_rank{open_days = ConfigOpenDays, rank_time = [RankDays, RankHour]}] = lib_config:find(cfg_act_rank, ID),
    OpenDays = common_config:get_open_days(),
    {Hour, _Min, _Sec} = erlang:time(),
    if
        OpenDays > RankDays orelse (OpenDays =:= RankDays andalso Hour >= RankHour) ->
            ?ACT_RANK_STATUS_REWARD;
        OpenDays >= ConfigOpenDays ->
            ?ACT_RANK_STATUS_RANKING;
        true ->
            ?ACT_RANK_STATUS_NOT_OPEN

    end.

get_base_is_red(ID, State) ->
    #r_act_rank_reward{
        base_list = BaseList
    } = get_act_reward(ID, State),
    get_base_is_red2(BaseList).

get_base_is_red2([]) ->
    false;
get_base_is_red2([#r_act_rank_base{is_reward = IsReward, is_condition = IsCondition}|R]) ->
    ?IF(not IsReward andalso IsCondition, true, get_base_is_red2(R)).

%% 获取排行奖励的状态
get_rank_reward_status(ID, State) ->
    #r_act_rank_reward{is_reward = IsReward} = get_act_reward(ID, State),
    case IsReward of
        true ->
            ?REWARD_STATUS_GET;
        _ ->
            RoleID = State#r_role.role_id,
            case get_rank_status(ID) =:= ?ACT_RANK_STATUS_REWARD andalso world_act_server:get_role_act_rank(RoleID, ID) of
                Rank when erlang:is_integer(Rank) andalso Rank > 0 ->
                    ?REWARD_STATUS_OK;
                _ ->
                    ?REWARD_STATUS_NOT
            end
    end.

%% 获取基础奖励的状态
get_base_reward_status(ID, State) ->
    #r_act_rank_reward{base_list = BaseList} = get_act_reward(ID, State),
    case get_rank_status(ID) of
        ?ACT_RANK_STATUS_NOT_OPEN -> %% 还未开始不能领取奖励
            [ #p_kv{id = BaseID, val = ?REWARD_STATUS_NOT}|| #r_act_rank_base{id = BaseID} <- BaseList];
        _ ->
            get_base_reward_status2(BaseList, [])
    end.

get_base_reward_status2([], Acc) ->
    Acc;
get_base_reward_status2([Base|R], Acc) ->
    #r_act_rank_base{id = BaseID, is_reward = IsReward, is_condition = IsCondition} = Base,
    Val =
        if
            IsReward ->
                ?REWARD_STATUS_GET;
            IsCondition ->
                ?REWARD_STATUS_OK;
            true ->
                ?REWARD_STATUS_NOT
        end,
    get_base_reward_status2(R, [#p_kv{id = BaseID, val = Val}|Acc]).

get_reward_by_rank(Rank, [{[MinRank, MaxRank], RewardString}|R]) ->
    ?IF(MinRank =< Rank andalso Rank =< MaxRank, RewardString, get_reward_by_rank(Rank, R));
get_reward_by_rank(Rank, [{NeedRank, RewardString}|R]) ->
    ?IF(Rank =:= NeedRank, RewardString, get_reward_by_rank(Rank, R)).

is_fit_rank_condition(ID, State) ->
    [#c_act_rank{rank_condition = RankCondition}] = lib_config:find(cfg_act_rank, ID),
    is_fit_condition(ID, RankCondition, State).

is_fit_condition(ID, Condition, State) ->
    {NowCondition, _ConditionArgs} = get_condition_by_id(ID,  State),
    NowCondition >= Condition.

get_condition_by_id(ID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{level = Level, power = Power} = RoleAttr,
    if
        ID =:= ?ACT_FIVE_ELEMENTS ->
            CopyID = mod_role_copy:get_cur_five_elements(State),
            {CopyID, CopyID};
        ID =:= ?ACT_RANK_LEVEL ->
            {Level, Level};
        ID =:= ?ACT_RANK_MOUNT ->
            MountID = mod_role_mount:get_mount_id(State),
            {MountID, MountID};
        ID =:= ?ACT_RANK_SUIT ->
            SuitPower = mod_role_fight:get_power(?CALC_KEY_SUIT, State),
            {SuitPower, SuitPower};
        ID =:= ?ACT_RANK_PET ->
            PetID = mod_role_pet:get_pet_id(State),
            {PetID, PetID};
        ID =:= ?ACT_RANK_NATURE ->
            NaturePower = mod_role_fight:get_power(?CALC_KEY_NATURE, State),
            {NaturePower, NaturePower};
        ID =:= ?ACT_RANK_POWER ->
            {Power, Power}
    end.

%%%===================================================================
%%% 数据操作
%%%===================================================================
get_act_reward(ID, State) ->
    RewardList = mod_role_extra:get_data(?KEY_ACT_RANK, [], State),
    case lists:keyfind(ID, #r_act_rank_reward.id, RewardList) of
        #r_act_rank_reward{} = RankReward ->
            RankReward;
        _ ->
            #r_act_rank_reward{id = ID}
    end.

set_act_reward(RankReward, State) ->
    RewardList = mod_role_extra:get_data(?KEY_ACT_RANK, [], State),
    #r_act_rank_reward{id = ID} = RankReward,
    RewardList2 = lists:keystore(ID, #r_act_rank_reward.id, RewardList, RankReward),
    mod_role_extra:set_data(?KEY_ACT_RANK, RewardList2, State).