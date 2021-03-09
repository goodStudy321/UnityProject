%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 十二月 2018 10:23
%%%-------------------------------------------------------------------
-module(mod_role_resource).
-author("laijichang").
-include("fairy.hrl").
-include("offline_solo.hrl").
-include("activity.hrl").
-include("copy.hrl").
-include("mission.hrl").
-include("role.hrl").
-include("role_extra.hrl").
-include("resource_retrieve.hrl").
-include("proto/mod_role_resource.hrl").

%%%% API
-export([
    day_reset/1,
    zero/1,
    online/1,
    handle/2
]).

-export([
    add_offline_solo_times/1,
    add_escort_times/1,
    add_family_mission_times/1,
    add_world_boss_times/2
]).

-export([
    gm_add_times/4,
    get_activity_times/3
]).

%% gen_cfg_module已经保证这个是最早执行
day_reset(State) ->
    ResourceList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_LIST, [], State),
    Level = mod_role_data:get_role_level(State),
    ConfigList = cfg_resource_retrieve:list(),
    ResourceList2 = get_new_resource(ConfigList, Level, ResourceList, State),
    ResourceList3 = [ Resource|| #r_resource{base_times = BaseTime, extra_times = ExtraTime} = Resource <- ResourceList2,
        BaseTime =/= 0 orelse ExtraTime =/= 0],
    State2 = mod_role_extra:set_data(?EXTRA_KEY_RESOURCE_LIST, ResourceList3, State),
    mod_role_extra:set_data(?EXTRA_KEY_RESOURCE_TIMES, [], State2).

zero(State) ->
    online(State).

online(State) ->
    ResourceList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_LIST, [], State),
    List = [ trans_to_p_resource(Resource) || #r_resource{} = Resource <- ResourceList],
    common_misc:unicast(State#r_role.role_id, #m_resource_info_toc{resource_list = List}),
    State.

gm_add_times(ResourceID, AddBaseTimes, AddExtraTimes, State) ->
    ResourceList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_LIST, [], State),
    case lists:keytake(ResourceID, #r_resource.resource_id, ResourceList) of
        {value, #r_resource{} = Resource, ResourceList2} ->
            ok;
        _ ->
            Resource = #r_resource{resource_id = ResourceID},
            ResourceList2 = ResourceList
    end,
    #r_resource{base_times = BaseTimes, extra_times = ExtraTimes} = Resource,
    Resource2 = Resource#r_resource{base_times = BaseTimes + AddBaseTimes, extra_times = ExtraTimes + AddExtraTimes},
    ResourceList3 = [Resource2|ResourceList2],
    State2 = mod_role_extra:set_data(?EXTRA_KEY_RESOURCE_LIST, ResourceList3, State),
    online(State2).

add_offline_solo_times(State) ->
    add_times(?RETRIEVE_TIMES_OFFLINE_SOLO, State).

add_escort_times(State) ->
    add_times(?RETRIEVE_TIMES_FAMILY_ESCORT, State).

add_family_mission_times(State) ->
    add_times(?RETRIEVE_TIMES_FAMILY_MISSION, State).

add_world_boss_times(AddTimes, State) ->
    add_times(?RETRIEVE_TIMES_WORLD_BOSS_TIMES, AddTimes, State).

add_times(Type, State) ->
    add_times(Type, 1, State).
add_times(Type, AddTimes, State) ->
    TimesList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_TIMES, [], State),
    TimesList2 =
        case lists:keytake(Type, #p_kv.id, TimesList) of
            {value, #p_kv{val = OldTimes} = KV, TimesListT} ->
                [KV#p_kv{val = OldTimes + AddTimes}|TimesListT];
            _ ->
                [#p_kv{id = Type, val = AddTimes}|TimesList]
        end,
    mod_role_extra:set_data(?EXTRA_KEY_RESOURCE_TIMES, TimesList2, State).

get_times(Type, TimesList) ->
    case lists:keyfind(Type, #p_kv.id, TimesList) of
        #p_kv{val = Times} ->
            Times;
        _ ->
            0
    end.

handle({#m_resource_retrieve_tos{resource_id = ResourceID, type = Type, times = Times}, RoleID, _PID}, State) ->
    do_resource_retrieve(RoleID, ResourceID, Type, Times, State);
handle(Info, State) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]),
    State.

do_resource_retrieve(RoleID, ResourceID, Type, Times, State) ->
    case catch check_resource_retrieve(ResourceID, Type, Times, State) of
        {ok, AssetDoing, GoodsList, Func, Rate, Resource, State2} ->
            common_misc:unicast(RoleID, #m_resource_retrieve_toc{resource = trans_to_p_resource(Resource)}),
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = role_misc:create_goods(State3, ?ITEM_GAIN_RESOURCE_RETRIEVE, GoodsList),
            State5 = ?IF(Rate > 0, mod_role_level:do_add_level_exp(Rate, 1, ?EXP_ADD_FROM_RESOURCE_RETRIEVE, State4), State4),
            Func(State5);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_resource_retrieve_toc{err_code = ErrCode}),
            State
    end.

check_resource_retrieve(ResourceID, Type, Times, State) ->
    ?IF(Times > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ResourceList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_LIST, [], State),
    case lists:keytake(ResourceID, #r_resource.resource_id, ResourceList) of
        {value, #r_resource{} = Resource, ResourceList2} ->
            ok;
        _ ->
            Resource = ResourceList2 = ?THROW_ERR(?ERROR_RESOURCE_RETRIEVE_001)
    end,
    #r_resource{
        base_times = BaseTimes,
        extra_times = ExtraTimes,
        copy_extra_buy_times = CopyExtraBuyTimes
    } = Resource,
    [#c_resource_retrieve{
        times_type = TimesType,
        level_exp_rate = Rate,
        base_rewards = BaseRewards,
        copy_id = CopyID,
        need_silver = NeedSilver,
        need_base_gold = NeedBaseGold,
        need_extra_gold_list = NeedExtraGoldList
    }] = lib_config:find(cfg_resource_retrieve, ResourceID),
    if
        Type =:= ?RETRIEVE_TYPE_GOLD ->
            mod_role_vip:is_resource_retrieve(State),
            ?IF(mod_role_data:get_role_level(State) >= common_misc:get_global_int(?GLOBAL_RESOURCE_RETRIEVE), ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
            ?IF(BaseTimes + ExtraTimes >= Times, ok, ?THROW_ERR(?ERROR_RESOURCE_RETRIEVE_001)),
            {NeedGold, Resource2} =
                case BaseTimes >= Times of
                    true -> %% 只需要扣除对应的基础次数
                        ResourceT = Resource#r_resource{base_times = BaseTimes - Times},
                        {NeedBaseGold * Times, ResourceT};
                    _ ->
                        NeedExtraTimes = Times - BaseTimes,
                        ExtraGold = get_extra_gold(CopyExtraBuyTimes, NeedExtraTimes, NeedExtraGoldList),
                        NeedGoldT = NeedBaseGold * BaseTimes + ExtraGold,
                        ResourceT = Resource#r_resource{base_times = 0, extra_times = ExtraTimes - NeedExtraTimes, copy_extra_buy_times = CopyExtraBuyTimes + NeedExtraTimes},
                        {NeedGoldT, ResourceT}
                end,
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_RESOURCE_RETRIEVE, State),
            {GoodsList, Rate2, Func} = get_retrieve_rewards(TimesType, BaseRewards, CopyID, Times, 1, Rate, State);
        Type =:= ?RETRIEVE_TYPE_SILVER ->
            ?IF(NeedSilver > 0, ok, ?THROW_ERR(?ERROR_RESOURCE_RETRIEVE_004)),
            ?IF(Times > BaseTimes, ?THROW_ERR(?ERROR_RESOURCE_RETRIEVE_001), ok),
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_SILVER, NeedSilver * Times, ?ASSET_SILVER_REDUCE_RESOURCE_RETRIEVE, State),
            RateT = (Rate * Times) div 2,
            {GoodsList, Rate2, Func} = get_retrieve_rewards(TimesType, BaseRewards, CopyID, Times, 2, RateT, State),
            Resource2 = Resource#r_resource{base_times = BaseTimes - Times}
    end,
    #r_resource{base_times = B, extra_times = E} = Resource2,
    ResourceList3 = ?IF(B > 0 orelse E > 0, [Resource2|ResourceList2], ResourceList2),
    State2 = mod_role_extra:set_data(?EXTRA_KEY_RESOURCE_LIST, ResourceList3, State),
    {ok, AssetDoing, GoodsList, Func, Rate2, Resource2, State2}.

get_retrieve_rewards([?RETRIEVE_TIMES_COPY, ?COPY_EXP], _BaseRewards, _CopyID, Times, _Reduce, _RateT, _State) ->
    {[], 0, fun(StateAcc) -> mod_role_copy:add_copy_times(?COPY_EXP, Times, StateAcc) end};
get_retrieve_rewards([?RETRIEVE_TIMES_BLESS], _BaseRewards, _CopyID, Times, _Reduce, _RateT, _State) ->
    {[], 0, fun(StateAcc) -> mod_role_bless:add_times(Times, StateAcc) end};
get_retrieve_rewards([?RETRIEVE_TIMES_WORLD_BOSS_TIMES], _BaseRewards, _CopyID, Times, _RateT, _Reduce, _State) ->
    {[], 0, fun(StateAcc) -> mod_role_world_boss:add_item_times(Times, StateAcc) end};
get_retrieve_rewards(_TimesType, BaseRewards, CopyID, Times, Reduce, Rate, State) ->
    GoodsList1 = [ #p_goods{
        type_id = TypeID,
        num = (Times * Num) div Reduce,
        bind = ?IS_BIND(IsBind)} || {TypeID, Num, IsBind} <- common_misc:get_item_reward(BaseRewards)],
    case CopyID > 0 of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, CopyID),
            CopyID2 = mod_role_copy:get_copy_max_id(CopyType, CopyID, State),
            [#c_copy{resource_reward = ResourceReward}] = lib_config:find(cfg_copy, CopyID2),
            GoodsList2 = get_retrieve_rewards2(common_misc:get_item_reward(ResourceReward), Times, Reduce, []),
            {GoodsList1 ++ GoodsList2, Rate, fun(StateAcc) -> StateAcc end};
        _ ->
            {GoodsList1, Rate, fun(StateAcc) -> StateAcc end}
    end.

get_retrieve_rewards2([], _Times, _Reduce, Acc) ->
    Acc;
get_retrieve_rewards2([ItemReward|R], Times, Reduce, Acc) ->
    {TypeID, Num, IsBind} =
        case ItemReward of
            {TypeIDT, NumT, IsBindT} ->
                {TypeIDT, NumT, IsBindT};
            {TypeIDT, NumT} ->
                {TypeIDT, NumT, true}
        end,
    #c_item{effect_type = EffectType, effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
    Multi = (Times * Num) div Reduce,
    case EffectType of
        ?ITEM_EQUIP_DROPS ->
            List = [  lib_tool:to_integer(DropIDString)|| DropIDString <- string:tokens(EffectArgs, ",")],
            GoodsList = get_retrieve_rewards3(lists:flatten(lists:duplicate(Multi, List)), []),
            get_retrieve_rewards2(R, Times, Reduce, GoodsList ++ Acc);
        _ ->
            Goods = #p_goods{
                type_id = TypeID,
                num = (Times * Num) div Reduce,
                bind = ?IS_BIND(IsBind)},
            get_retrieve_rewards2(R, Times, Reduce, [Goods|Acc])
    end.

get_retrieve_rewards3([], Acc) ->
    Acc;
get_retrieve_rewards3([DropID|R], Acc) ->
    GoodsList = [ #p_goods{type_id = TypeID, num = Num, bind = IsBind} || {TypeID, Num, IsBind} <- mod_map_drop:get_drop_item_list2(DropID)],
    get_retrieve_rewards3(R, GoodsList ++ Acc).

get_new_resource(ConfigList, Level, ResourceList, State) ->
    #r_role{role_private_attr = PrivateAttr, role_copy = RoleCopy} = State,
    #r_role_private_attr{reset_time = LastRestTime} = PrivateAttr,
    Now = time_tool:now(),
    case LastRestTime > 0 andalso Now > LastRestTime andalso (not time_tool:is_same_date(Now, LastRestTime)) of %% 活动测试服处理时间会倒转
        true ->
            #r_role_copy{copy_list = CopyList} = RoleCopy,
            MapList = mod_role_extra:get_data(?EXTRA_KEY_ACTIVITY_MAP, [], State),
            Days = time_tool:diff_date(Now, LastRestTime) - 1,
            TimesList = mod_role_extra:get_data(?EXTRA_KEY_RESOURCE_TIMES, [], State),
            get_new_resource2(ConfigList, LastRestTime, Days, Level, ResourceList, CopyList, MapList, TimesList, State, []);
        _ ->
            ResourceList
    end.

get_new_resource2([], _LastRestTime, _Days, _Level, _ResourceList, _CopyList, _MapList, _TimesList, _State, Acc) ->
    Acc;
get_new_resource2([{ResourceID, Config}|R], LastRestTime, Days, Level, ResourceList, CopyList, MapList, TimesList, State, Acc) ->
    #c_resource_retrieve{
        times_type = TimeType,
        base_times = MaxBaseTimes,
        extra_days = ExtraDays,
        copy_id = CopyID
    } = Config,
    {Resource2, ResourceList2} =
        case lists:keytake(ResourceID, #r_resource.resource_id, ResourceList) of
            {value, #r_resource{} = ResourceT, ResourceListT} ->
                {ResourceT, ResourceListT};
            _ ->
                {#r_resource{resource_id = ResourceID}, ResourceList}
        end,
    Acc2 =
        case TimeType of
            [?RETRIEVE_TIMES_COPY, CopyType] ->
                get_copy_resource(CopyID, CopyType, CopyList, Level, Resource2, Days, MaxBaseTimes, ExtraDays, Acc, State);
            [?RETRIEVE_TIMES_MISSION, DailyType] ->
                get_mission_resource(DailyType, Resource2, Days, MaxBaseTimes, Acc, State);
            [?RETRIEVE_TIMES_ACTIVITY, ActivityID] ->
                get_activity_resource(ActivityID, MapList, Level, Resource2, LastRestTime, Days, MaxBaseTimes, Acc);
            [?RETRIEVE_TIMES_OFFLINE_SOLO] ->
                get_offline_solo_resource(Resource2, Days, MaxBaseTimes, TimesList, Acc, State);
            [?RETRIEVE_TIMES_FAMILY_ESCORT] ->
                get_family_escort_source(Resource2, Days, MaxBaseTimes, TimesList, Acc, State);
            [?RETRIEVE_TIMES_BLESS] ->
                get_bless_source(Resource2, Days, MaxBaseTimes, TimesList, Acc, State);
            [?RETRIEVE_TIMES_WORLD_BOSS_TIMES] ->
                get_world_boss_source(Resource2, Days, MaxBaseTimes, TimesList, Acc, State);
%%            [?RETRIEVE_TIMES_FAMILY_MISSION, MaxTimes] ->
%%                get_family_mission_source(Resource2, Days, MaxBaseTimes, MaxTimes, TimesList, Acc, State);
            _ ->
                Acc
        end,
    get_new_resource2(R, LastRestTime, Days, Level, ResourceList2, CopyList, MapList, TimesList, State, Acc2).

get_copy_resource(CopyID, CopyType, CopyList, Level, Resource, Days, MaxBaseTimes, ExtraDays, Acc, State) ->
    [#c_copy{enter_level = EnterLevel, times = ConfigTimes}] = lib_config:find(cfg_copy, CopyID),
    case Level >= EnterLevel of
        true ->
            #r_resource{base_times = NowBaseTimes, extra_times = NowExtraTimes} = Resource,
            VipBuyTimes = mod_role_vip:get_vip_buy_times(CopyType, State),
            MaxExtraTimes = VipBuyTimes * ExtraDays,
            case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
                #r_role_copy_item{enter_times = EnterTimes, buy_times = BuyTimes} ->
                    RemainTimes = erlang:max(0, ConfigTimes - EnterTimes),
                    RemainBuyTimes = erlang:max(0, VipBuyTimes - BuyTimes),
                    CopyExtraBuyTimes = BuyTimes + 1;
                _ ->
                    RemainTimes = ConfigTimes,
                    RemainBuyTimes = VipBuyTimes,
                    CopyExtraBuyTimes = 1
            end,
            AddTimes = (RemainTimes + Days * ConfigTimes),
            %% 经验副本，只取昨天的
            ExtraTimes =
                case CopyType of
                    ?COPY_EXP ->
                        RemainBuyTimes;
                    _ ->
                        erlang:min(NowExtraTimes + RemainBuyTimes + Days * VipBuyTimes, MaxExtraTimes)
                end,
            Resource2 = Resource#r_resource{
                base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes),
                extra_times = ExtraTimes,
                copy_extra_buy_times = CopyExtraBuyTimes
            },
            [Resource2|Acc];
        _ ->
            Acc
    end.

get_mission_resource(DailyType, Resource, Days, MaxBaseTimes, Acc, State) ->
    #r_resource{base_times = NowBaseTimes} = Resource,
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    [MissionTimes] = lib_config:find(cfg_mission, {daily_times, DailyType}),
    case lists:keyfind(DailyType, #r_mission_done.type, DoneList) of
        #r_mission_done{times = FinishTimes} ->
            AddTimes = MissionTimes - FinishTimes + (MissionTimes * Days),
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            case lists:keymember(DailyType, #r_mission_doing.type, DoingList) of
                true ->
                    AddTimes = MissionTimes * (Days + 1),
                    Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
                    [Resource2|Acc];
                _ ->
                    Acc
            end
    end.

get_activity_resource(ActivityID, MapList, Level, Resource, LastRestTime, Days, MaxBaseTimes, Acc) ->
    [#c_activity{min_level = MinLevel, day_list = DayList}] = lib_config:find(cfg_activity, ActivityID),
    case Level >= MinLevel of
        true ->
            #r_resource{base_times = NowBaseTimes} = Resource,
            #c_activity_mod{map_id = MapID} = lists:keyfind(ActivityID, #c_activity_mod.activity_id, ?ACTIVITY_MOD_LIST),
            WeekDay = time_tool:weekday(LastRestTime),
            {FirstDay, Days2} =
                case lists:keyfind(MapID, #p_kv.id, MapList) of
                    #p_kv{val = StartTime} ->
                        ?IF(time_tool:is_same_date(StartTime, LastRestTime), {WeekDay + 1, Days}, {WeekDay, Days + 1});
                    _ ->
                        {WeekDay, Days + 1}
                end,
            AddTimes = get_activity_times(FirstDay, Days2, DayList),
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            Acc
    end.

get_activity_times(FirstDay, Days, DayList) ->
    %% 7天以内
    if
        Days > 7 ->
            FirstTimes = (Days div 7) + erlang:length(DayList),
            SecondTimes = get_activity_times2(FirstDay, Days, DayList, 0),
            FirstTimes + SecondTimes;
        true ->
            get_activity_times2(FirstDay, Days, DayList, 0)
    end.

get_activity_times2(_Day, 0, _DayList, Acc) ->
    Acc;
get_activity_times2(Day, Days, DayList, Acc) ->
    Acc2 = ?IF(lists:member(Day, DayList), Acc + 1, Acc),
    get_activity_times2(Day, Days - 1, DayList, Acc2).

get_offline_solo_resource(Resource, Days, MaxBaseTimes, TimesList, Acc, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_OFFLINE_SOLO, State) of
        true ->
            #r_resource{base_times = NowBaseTimes} = Resource,
            SoloTimes = get_times(?RETRIEVE_TIMES_OFFLINE_SOLO, TimesList),
            AddTimes = erlang:max(0, ?DEFAULT_CHALLENGE_TIMES - SoloTimes) + ?DEFAULT_CHALLENGE_TIMES * Days,
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            Acc
    end.

get_family_escort_source(Resource, Days, MaxBaseTimes, TimesList, Acc, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_FAIRY, State) of
        true ->
            #r_resource{base_times = NowBaseTimes} = Resource,
            FinishTimes = get_times(?RETRIEVE_TIMES_FAMILY_ESCORT, TimesList),
            Times = mod_role_escort:get_escort_config_times(),
            AddTimes = erlang:max(0, Times - FinishTimes) + Times * Days,
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            Acc
    end.

get_bless_source(Resource, Days, MaxBaseTimes, _TimesList, Acc, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_BLESS, State) of
        true ->
            #r_resource{base_times = NowBaseTimes} = Resource,
            AddTimes = erlang:max(0, mod_role_bless:get_resource_retrieve_times(State)) + mod_role_bless:get_base_times() * Days,
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            Acc
    end.

get_world_boss_source(Resource, Days, MaxBaseTimes, TimesList, Acc, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_WORLD_BOSS, State) of
        true ->
            #r_resource{base_times = NowBaseTimes} = Resource,
            FinishTimes = get_times(?RETRIEVE_TIMES_WORLD_BOSS_TIMES, TimesList),
            Times = mod_role_world_boss:get_first_boss_default_times(),
            AddTimes = erlang:max(0, Times - FinishTimes) + Times * Days,
            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
            [Resource2|Acc];
        _ ->
            Acc
    end.

%%get_family_mission_source(Resource, Days, MaxBaseTimes, MaxTimes, TimesList, Acc, State) ->
%%    case catch mod_role_function:is_function_open(?FUNCTION_FAMILY_MISSION, State) of
%%        true ->
%%            #r_resource{base_times = NowBaseTimes} = Resource,
%%            FinishTimes = get_times(?RETRIEVE_TIMES_FAMILY_MISSION, TimesList),
%%            AddTimes = erlang:max(0, MaxTimes - FinishTimes) + MaxTimes * Days,
%%            Resource2 = Resource#r_resource{base_times = erlang:min(NowBaseTimes + AddTimes, MaxBaseTimes)},
%%            [Resource2|Acc];
%%        _ ->
%%            Acc
%%    end.


get_extra_gold(CopyExtraBuyTimes, ExtraTimes, NeedExtraGoldList) ->
    case NeedExtraGoldList of
        [Gold] ->
            ExtraTimes * Gold;
        [_Gold1, _Gold2|_] -> %% 多个元素
            CopyExtraBuyTimes2 = erlang:max(1, CopyExtraBuyTimes),
            get_extra_gold2(lists:seq(CopyExtraBuyTimes2, CopyExtraBuyTimes2 + ExtraTimes - 1), NeedExtraGoldList, 0);
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end.

get_extra_gold2([], _NeedGoldList, NeedGoldAcc) ->
    NeedGoldAcc;
get_extra_gold2([BuyTimes|R], NeedGoldList, NeedGoldAcc) ->
    AddGold = ?IF(BuyTimes > erlang:length(NeedGoldList), lists:nth(1, lists:reverse(NeedGoldList)), lists:nth(BuyTimes, NeedGoldList)),
    get_extra_gold2(R, NeedGoldList, NeedGoldAcc + AddGold).

trans_to_p_resource(Resource) ->
    #r_resource{
        resource_id = ResourceID,
        base_times = BaseTimes,
        extra_times = ExtraTimes,
        copy_extra_buy_times = CopyExtraBuyTimes
    } = Resource,
    #p_resource{
        resource_id = ResourceID,
        base_times = BaseTimes,
        extra_times = ExtraTimes,
        copy_extra_buy_times = CopyExtraBuyTimes
    }.