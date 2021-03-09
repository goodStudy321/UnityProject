%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十一月 2018 11:02
%%%-------------------------------------------------------------------
-module(mod_role_act_family).
-author("laijichang").
-include("act.hrl").
-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_act_family.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    family_vice/2,
    family_member_trigger/2,
    family_level_trigger/2,
    family_create_trigger/2
]).

-export([
    family_create/1,
    family_join/1,
    family_title_change/2,

    family_change/1
]).

-export([
    act_update/1
]).

init(#r_role{role_id = RoleID, role_act_family = undefined} = State) ->
    RoleFamily = #r_role_act_family{role_id = RoleID},
    State#r_role{role_act_family = RoleFamily};
init(State) ->
    State.

online(State) ->
    case is_create_open(State) of
        true ->
            #r_role{role_id = RoleID, role_act_family = RoleActFamily} = State,
            #r_role_act_family{create_condition_list = CreateConditions, battle_condition = BattleCondition} = RoleActFamily,
            DataRecord1 = #m_act_family_create_info_toc{conditions = CreateConditions, reward_list = world_data:get_act_family_create_reward()},
            common_misc:unicast(RoleID, DataRecord1),
            ?IF(erlang:is_record(BattleCondition, p_kv), common_misc:unicast(RoleID, #m_act_family_battle_condition_toc{condition = BattleCondition}), ok),
            State2 = family_join(State),
            State3 = family_title_change(mod_role_family:get_family_title_id(RoleID), State2),
            State4 = family_battle_condition(State3),
            State5 = family_change(State4),
            State5;
        _ ->
            State
    end.

act_update(_State) ->
    role_misc:info_role(erlang:self(), {?MODULE, online, []}).

family_vice(RoleID, ViceNum) ->
    family_common_trigger(RoleID, [?ACT_FAMILY_CREATE_VICE], ViceNum).

family_member_trigger(RoleID, MemberNum) ->
    family_common_trigger(RoleID,  [?ACT_FAMILY_CREATE_MEMBER, ?ACT_FAMILY_CREATE_MEMBER2], MemberNum).

family_level_trigger(RoleID, FamilyLevel) ->
    family_common_trigger(RoleID,  [?ACT_FAMILY_CREATE_LEVEL, ?ACT_FAMILY_CREATE_LEVEL2], FamilyLevel).

family_common_trigger(_RoleID, [], _Args) ->
    ok;
family_common_trigger(RoleID, [ID|R], Args) ->
    [#c_act_family_create{args = NeedNum}] = lib_config:find(cfg_act_family_create, ID),
    ?IF(NeedNum =:= Args, family_create_trigger(RoleID, ID), ok),
    family_common_trigger(RoleID, R, Args).

family_create_trigger(RoleID, ID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {family_create_trigger, ID}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, family_create_trigger, [RoleID, ID]})
    end.

handle({family_create_trigger, ID}, State) ->
    do_family_create_trigger(ID, State);
handle(family_battle_condition, State) ->
    family_battle_condition(State);
handle({#m_act_family_create_reward_tos{id = IndexID}, RoleID, _PID}, State) ->
    do_create_reward(RoleID, IndexID, State);
handle({#m_act_family_battle_reward_tos{id = IndexID}, RoleID, _PID}, State) ->
    do_battle_reward(RoleID, IndexID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info : ~w", [Info]),
    State.

%%%===================================================================
%%% 开宗立派
%%%===================================================================
%% 创建仙盟
family_create(State) ->
    ?IF(is_create_open(State), do_family_create_trigger(?ACT_FAMILY_CREATE_CREATE, State), State).

%% 加入仙盟
family_join(State) ->
    ?IF(is_create_open(State), family_create_join(State), State).

family_create_join(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}, role_act_family = RoleActFamily} = State,
    #r_role_act_family{create_condition_list = CreateConditions} = RoleActFamily,
    #p_kv{id = ID, val = Status} = KV = get_create_condition(?ACT_FAMILY_CREATE_JOIN, CreateConditions),
    case FamilyID > 0 andalso Status =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            KV2 = KV#p_kv{val = ?ACT_REWARD_CAN_GET},
            common_misc:unicast(RoleID, #m_act_family_create_condition_toc{condition = KV2}),
            CreateConditions2 = lists:keystore(ID, #p_kv.id, CreateConditions, KV2),
            RoleActFamily2 = RoleActFamily#r_role_act_family{create_condition_list = CreateConditions2},
            State#r_role{role_act_family = RoleActFamily2};
        _ ->
            State
    end.

%% 仙盟称号改变
family_title_change(TitleID, State) ->
    ?IF(is_create_open(State), family_title_change2(TitleID, State), State).

family_title_change2(TitleID, State) ->
    #r_role{role_id = RoleID, role_act_family = RoleActFamily} = State,
    #r_role_act_family{create_condition_list = CreateConditions} = RoleActFamily,
    {CreateConditions2, UpdateList} = family_title_change3([], TitleID, CreateConditions, []),
%%    {CreateConditions2, UpdateList} = family_title_change3([?ACT_FAMILY_CREATE_TITLE_ELDER, ?ACT_FAMILY_CREATE_TITLE_VICE], TitleID, CreateConditions, []),
    case UpdateList =/= [] of
        true ->
            [ common_misc:unicast(RoleID, #m_act_family_create_condition_toc{condition = UpdateKV}) || UpdateKV <- UpdateList],
            RoleActFamily2 = RoleActFamily#r_role_act_family{create_condition_list = CreateConditions2},
            State#r_role{role_act_family = RoleActFamily2};
        _ ->
            State
    end.

family_title_change3([], _TitleID, CreateConditions, UpdateAcc) ->
    {CreateConditions, UpdateAcc};
family_title_change3([ID|R], TitleID, CreateConditions, UpdateAcc) ->
    [#c_act_family_create{args = Args}] = lib_config:find(cfg_act_family_create, ID),
    #p_kv{id = ID, val = Status} = KV = get_create_condition(ID, CreateConditions),
    if
        Status =:= ?ACT_REWARD_CANNOT_GET andalso TitleID =:= Args  -> %% 未触发满足条件
            KV2 = KV#p_kv{val = ?ACT_REWARD_CAN_GET},
            CreateConditions2 = lists:keystore(ID, #p_kv.id, CreateConditions, KV2),
            family_title_change3(R, TitleID, CreateConditions2, [KV2|UpdateAcc]);
        Status =:= ?ACT_REWARD_CAN_GET andalso TitleID =/= Args -> %% 称号变了，修改
            KV2 = KV#p_kv{val = ?ACT_REWARD_CANNOT_GET},
            CreateConditions2 = lists:keystore(ID, #p_kv.id, CreateConditions, KV2),
            family_title_change3(R, TitleID, CreateConditions2, [KV2|UpdateAcc]);
        true ->
            family_title_change3(R, TitleID, CreateConditions, UpdateAcc)
    end.

%% 其他trigger（不会重复改变状态，只会从 不能领取 -> 可领取）
do_family_create_trigger(ID, State) ->
    ?IF(is_create_open(State), do_family_create_trigger2(ID, State), State).

do_family_create_trigger2(ID, State) ->
    #r_role{role_id = RoleID, role_act_family = RoleActFamily} = State,
    #r_role_act_family{create_condition_list = CreateConditions} = RoleActFamily,
    #p_kv{id = ID, val = Status} = KV = get_create_condition(ID, CreateConditions),
    case Status =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            KV2 = KV#p_kv{val = ?ACT_REWARD_CAN_GET},
            common_misc:unicast(RoleID, #m_act_family_create_condition_toc{condition = KV2}),
            CreateConditions2 = lists:keystore(ID, #p_kv.id, CreateConditions, KV2),
            RoleActFamily2 = RoleActFamily#r_role_act_family{create_condition_list = CreateConditions2},
            State#r_role{role_act_family = RoleActFamily2};
        _ ->
            State
    end.

do_create_reward(RoleID, IndexID, State) ->
    case catch check_create_reward(IndexID, State) of
        {ok, Condition, Config, BagDoings, State2} ->
            case Config#c_act_family_create.num =:= 0 orelse act_family:create_reward(Config) of
                true ->
                    common_misc:unicast(RoleID, #m_act_family_create_reward_toc{condition = Condition}),
                    mod_role_bag:do(BagDoings, State2);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_act_family_create_reward_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_family_create_reward_toc{err_code = ErrCode}),
            State
    end.

check_create_reward(IndexID, State) ->
    #r_role{role_act_family = RoleActFamily} = State,
    #r_role_act_family{create_condition_list = CreateConditions} = RoleActFamily,
    case lists:keytake(IndexID, #p_kv.id, CreateConditions) of
        {value, #p_kv{} = Condition, CreateConditions2} ->
            ok;
        _ ->
            CreateConditions2 = Condition = ?THROW_ERR(?ERROR_ACT_FAMILY_CREATE_REWARD_001)
    end,
    #p_kv{val = Status} = Condition,
    ?IF(Status =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_ACT_FAMILY_CREATE_REWARD_002)),
    [Config] = lib_config:find(cfg_act_family_create, IndexID),
    #c_act_family_create{reward = Reward} = Config,
    GoodsList = [ #p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(Reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_FAMILY_CREATE, GoodsList}],
    Condition2 = Condition#p_kv{val = ?ACT_REWARD_GOT},
    CreateConditions3 = [Condition2|CreateConditions2],
    RoleActFamily2 = RoleActFamily#r_role_act_family{create_condition_list = CreateConditions3},
    State2 = State#r_role{role_act_family = RoleActFamily2},
    {ok, Condition2, Config, BagDoings, State2}.

%%%===================================================================
%%% 仙盟争霸
%%%===================================================================
family_battle_condition(State) ->
    case is_battle_open(State) of
        true ->
            #r_act_family_battle{is_end = IsEnd, condition_list = ConditionList} = world_data:get_act_family_battle(),
            #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}, role_act_family = RoleActFamily} = State,
            #r_role_act_family{battle_condition = BattleCondition} = RoleActFamily,
            case BattleCondition =:= undefined andalso IsEnd of
                true ->
                    BattleCondition2 =
                        case lists:keyfind(RoleID, #p_dkv.id, ConditionList) of
                            #p_dkv{val = ID} ->
                                #p_kv{id = ID, val = ?ACT_REWARD_CAN_GET};
                            _ ->
                                Status = ?IF(?HAS_FAMILY(FamilyID), ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET),
                                #p_kv{id = ?ACT_FAMILY_BATTLE_OTHER_MEMBER, val = Status}
                        end,
                    common_misc:unicast(RoleID, #m_act_family_battle_condition_toc{condition = BattleCondition2}),
                    RoleActFamily2 = RoleActFamily#r_role_act_family{battle_condition = BattleCondition2},
                    State#r_role{role_act_family = RoleActFamily2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

family_change(State) ->
    case is_battle_open(State) of
        true ->
            #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}, role_act_family = RoleActFamily} = State,
            #r_role_act_family{battle_condition = BattleCondition} = RoleActFamily,
            case BattleCondition of
                #p_kv{id = ?ACT_FAMILY_BATTLE_OTHER_MEMBER, val = Status} ->
                    HasFamily = ?HAS_FAMILY(FamilyID),
                    if
                        Status =:= ?ACT_REWARD_CANNOT_GET andalso HasFamily -> %% 未领取
                            Status2 = ?ACT_REWARD_CAN_GET;
                        Status =:= ?ACT_REWARD_CAN_GET andalso not HasFamily ->
                            Status2 = ?ACT_REWARD_CANNOT_GET;
                        true ->
                            Status2 = Status
                    end,
                    case Status2 =/= Status of
                        true ->
                            BattleCondition2 = BattleCondition#p_kv{val = Status2},
                            common_misc:unicast(RoleID, #m_act_family_battle_condition_toc{condition = BattleCondition2}),
                            RoleActFamily2 = RoleActFamily#r_role_act_family{battle_condition = BattleCondition2},
                            State#r_role{role_act_family = RoleActFamily2};
                        _ ->
                            State
                    end;
                _ ->
                    State
            end;
        _ ->
            State
    end.

do_battle_reward(RoleID, _IndexID, State) ->
    case catch check_battle_reward(State) of
        {ok, Condition, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_act_family_battle_reward_toc{condition = Condition}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_family_battle_reward_toc{err_code = ErrCode}),
            State
    end.

check_battle_reward(State) ->
    #r_role{role_act_family = RoleActFamily} = State,
    #r_role_act_family{battle_condition = Condition} = RoleActFamily,
    ?IF(erlang:is_record(Condition, p_kv), ok, ?THROW_ERR(?ERROR_ACT_FAMILY_CREATE_REWARD_001)),
    #p_kv{id = IndexID, val = Status} = Condition,
    ?IF(Status =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_ACT_FAMILY_CREATE_REWARD_002)),
    [#c_act_family_battle{reward = Reward}] = lib_config:find(cfg_act_family_battle, IndexID),
    GoodsList = [ #p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(Reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_FAMILY_BATTLE, GoodsList}],
    Condition2 = Condition#p_kv{val = ?ACT_REWARD_GOT},
    RoleActFamily2 = RoleActFamily#r_role_act_family{battle_condition = Condition2},
    State2 = State#r_role{role_act_family = RoleActFamily2},
    {ok, Condition2, BagDoings, State2}.


%%%===================================================================
%%% 数据操作
%%%===================================================================
is_create_open(State) ->
    mod_role_act:is_act_open(?ACT_FAMILY_CREATE, State).

get_create_condition(ID, CreateConditions) ->
    case lists:keyfind(ID, #p_kv.id, CreateConditions) of
        #p_kv{} = KV ->
            KV;
        _ ->
            #p_kv{id = ID, val = ?ACT_REWARD_CANNOT_GET}
    end.

is_battle_open(State) ->
    mod_role_act:is_act_open(?ACT_FAMILY_BATTLE, State).



