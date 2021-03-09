%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 一月 2019 10:46
%%%-------------------------------------------------------------------
-module(mod_role_mythical_equip).
-author("laijichang").
-include("global.hrl").
-include("role.hrl").
-include("mythical_equip.hrl").
-include("proto/mod_role_mythical_equip.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    handle/2,
    level_up/2
]).

-export([
    add_equips/2,
    is_bag_full/2
]).

init(#r_role{role_id = RoleID, role_mythical_equip = undefined} = State) ->
    RoleMythicalEquip = #r_role_mythical_equip{role_id = RoleID},
    State#r_role{role_mythical_equip = RoleMythicalEquip};
init(State) ->
    State.

calc(State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_list = SoulList} = RoleMythicalEquip,
    CalcAttr = calc_soul_list(SoulList, [], [], []),
    mod_role_fight:get_state_by_kv(State, ?CALC_MYTHICAL_EQUIP, CalcAttr).

calc_soul_list([], ActiveSouls, SelfAdd, AllAdd) ->
    calc_soul_list2(ActiveSouls, SelfAdd, merge_base_add(AllAdd), #actor_cal_attr{});
calc_soul_list([#p_mythical_soul{soul_id = SoulID, status = Status} = MythicalSoul|R], ActiveSouls, SelfAddAcc, AllAddAcc) ->
    case Status =:= ?MYTHICAL_STATUS_ACTIVE of
        true ->
            [#c_mythical_equip_base{base_add1 = BaseAdd1, base_add2 = BaseAdd2}] = Config = lib_config:find(cfg_mythical_equip_base, SoulID),
            {SelfAdd, AllAdd} = get_base_add([BaseAdd1, BaseAdd2], [], []),
            ActiveSouls2 = [{MythicalSoul, Config}|ActiveSouls],
            SelfAddAcc2 = [{SoulID, SelfAdd}|SelfAddAcc],
            AllAddAcc2 = AllAdd ++ AllAddAcc,
            calc_soul_list(R, ActiveSouls2, SelfAddAcc2, AllAddAcc2);
        _ ->
            calc_soul_list(R, ActiveSouls, SelfAddAcc, AllAddAcc)
    end.

calc_soul_list2([], _SelfAdd, _AllAdd, AttrAcc) ->
    AttrAcc;
calc_soul_list2([{MythicalSoul, Config}|R], SelfAddList, AllAdd, AttrAcc) ->
    #p_mythical_soul{soul_id = SoulID, equip_list = EquipList} = MythicalSoul,
    [#c_mythical_equip_base{props = Props}] = Config,
    {PropAdds, SelfAddList2} =
        case lists:keytake(SoulID, 1, SelfAddList) of
            {value, {_, SelfAdd}, SelfAddListT} ->
                {SelfAdd ++ AllAdd, SelfAddListT};
            _ ->
                {AllAdd, SelfAddList}
        end,
    BaseAttr1 = common_misc:get_attr_by_kv([ #p_kv{id = PropID, val = PropValue}|| {PropID, PropValue} <- lib_tool:string_to_intlist(Props)]),
    BaseAttr2 = calc_base_props(BaseAttr1, merge_base_add(PropAdds)),
    Attr2 = calc_equips(EquipList,  #actor_cal_attr{}),
    AttrAcc2 = common_misc:sum_calc_attr([BaseAttr2, Attr2, AttrAcc]),
    calc_soul_list2(R, SelfAddList2, AllAdd, AttrAcc2).

calc_base_props(BaseAttr, []) ->
    BaseAttr;
calc_base_props(BaseAttr, [{PropID, Value}|R]) ->
    #actor_cal_attr{
        max_hp = {MaxHp, MaxHpR},
        attack = {Attack, AttackR},
        defence = {Defence, DefenceR},
        arp = {Arp, ArpR}
    } = BaseAttr,
    BaseAttr2 =
    if
        PropID =:= ?ATTR_RATE_ADD_HP ->
            BaseAttr#actor_cal_attr{max_hp = {lib_tool:ceil(MaxHp * Value/?RATE_10000), MaxHpR}};
        PropID =:= ?ATTR_RATE_ADD_ATTACK ->
            BaseAttr#actor_cal_attr{attack = {lib_tool:ceil(Attack * Value/?RATE_10000), AttackR}};
        PropID =:= ?ATTR_RATE_ADD_DEFENCE ->
            BaseAttr#actor_cal_attr{defence = {lib_tool:ceil(Defence * Value/?RATE_10000), DefenceR}};
        PropID =:=?ATTR_RATE_ADD_ARP ->
            BaseAttr#actor_cal_attr{arp = {lib_tool:ceil(Arp * Value/?RATE_10000), ArpR}};
        true ->
            BaseAttr
    end,
    calc_base_props(BaseAttr2, R).

calc_equips([],  Acc) ->
    Acc;
calc_equips([Equip|R], Acc) ->
    #p_mythical_equip{
        type_id = TypeID,
        refine_level = RefineLevel,
        excellent_list = ExcellentList
    } = Equip,
    [#c_mythical_equip_info{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_defence = AddDefence,
        add_arp = AddArp}] = lib_config:find(cfg_mythical_equip_info, TypeID),
    BaseAttr =
        #actor_cal_attr{
            max_hp = {AddHp, 0},
            attack = {AddAttack, 0},
            defence = {AddDefence, 0},
            arp = {AddArp, 0}
        },
    RefineAttr =
        case RefineLevel > 0 of
            true ->
                [#c_mythical_equip_refine{
                    add_hp = AddHp2,
                    add_attack = AddAttack2,
                    add_defence = AddDefence2,
                    add_arp = AddArp2
                }] = lib_config:find(cfg_mythical_equip_refine, RefineLevel),
                #actor_cal_attr{
                    max_hp = {AddHp2, 0},
                    attack = {AddAttack2, 0},
                    defence = {AddDefence2, 0},
                    arp = {AddArp2, 0}
                };
            _ ->
                #actor_cal_attr{}
        end,
    ExcellentList2 = to_excellent_kv(ExcellentList),
    Acc2 = common_misc:sum_calc_attr([BaseAttr, RefineAttr, common_misc:get_attr_by_kv(ExcellentList2), Acc]),
    calc_equips(R, Acc2).

online(State) ->
    #r_role{role_id = RoleID, role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_num = SoulNum, soul_list = SoulList, bag_list = BagList} = RoleMythicalEquip,
    case SoulNum > 0 of
        true ->
            DataRecord = #m_mythical_equip_info_toc{
                soul_num = SoulNum,
                soul_list = SoulList,
                bag_list = BagList
            },
            common_misc:unicast(RoleID, DataRecord),
            State;
        _ ->
            %% 外网玩家可能已经达到这个等级了
            level_up(mod_role_data:get_role_level(State), State)
    end.

level_up(NewLevel, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_num = SoulNum} = RoleMythicalEquip,
    case is_mythical_open(SoulNum) of
        true ->
            State;
        _ ->
            [#c_mythical_equip_unlock{level = MinLevel}] = lib_config:find(cfg_mythical_equip_unlock, 1),
            case NewLevel >= MinLevel of
                true ->
                    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_num = 1},
                    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
                    online(State2);
                _ ->
                    State
            end
    end.

add_equips([], State) ->
    State;
add_equips(TypeIDs, State) ->
    #r_role{role_id = RoleID, role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{id = IndexID, bag_list = BagList} = RoleMythicalEquip,
    {IndexID2, Equips} =
        lists:foldl(
            fun(TypeID, {IndexAcc, EquipsAcc}) ->
                EquipT = #p_mythical_equip{
                    id = IndexAcc,
                    type_id = TypeID,
                    excellent_list = get_equip_excellent(TypeID)
                },
                {IndexAcc + 1, [EquipT|EquipsAcc]}
            end, {IndexID, []}, TypeIDs),
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{id = IndexID2, bag_list = Equips ++ BagList},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    notify_add_equips(RoleID, Equips),
    Log = [ get_equip_add_log(Equip, State2) || Equip <- Equips],
    mod_role_dict:add_background_logs(Log),
    State2.

get_equip_excellent(TypeID) ->
    [#c_mythical_equip_info{
        blue_props_num = BlueProsNum,
        blue_prop_id = BluePropID,
        purple_props_num = PurplePropsNum,
        purple_prop_id = PurplePropsID
    }] = lib_config:find(cfg_mythical_equip_info, TypeID),
    get_equip_excellent2([{BluePropID, BlueProsNum}, {PurplePropsID, PurplePropsNum}], [], []).

get_equip_excellent2([], _HasProps, ExcellentAcc) ->
    ExcellentAcc;
get_equip_excellent2([{PropID, PropsNum}|R], HasPropsAcc, ExcellentAcc) ->
    case PropsNum > 0 of
        true ->
            [#c_mythical_equip_excellent{
                add_defence = Props1,
                add_hp = Props2,
                add_attack = Props3,
                add_arp = Props4,
                add_hit_rate = Props5,
                add_miss = Props6,
                add_double = Props7,
                add_double_anti = Props8,
                add_defence_rate = Props9,
                add_hp_rate = Props10,
                add_attack_rate = Props11,
                add_arp_rate = Props12,
                add_hit_rate_rate = Props13,
                add_miss_rate = Props14,
                add_double_rate = Props15,
                add_double_anti_rate = Props16
            }] = lib_config:find(cfg_mythical_equip_excellent, PropID),
            List = [{1, Props1}, {2, Props2}, {3, Props3}, {4, Props4}, {5, Props5}, {6, Props6}, {7, Props7},
                {8, Props8}, {9, Props9}, {10, Props10}, {11, Props11}, {12, Props12}, {13, Props13}, {14, Props14},
                {15, Props15}, {16, Props16}],
            List2 = filter_has_list(List, HasPropsAcc, []),
            WeightList = lib_tool:get_list_by_weight(PropsNum, List2),
            {HasProps, ExcellentList} =
                lists:foldl(
                    fun({Index, Key, Val, Score}, {Acc1, Acc2}) ->
                        {[Index|Acc1], [#p_kvt{id = Key, val = Val, type = Score}|Acc2]}
                    end, {[], []}, WeightList),
            get_equip_excellent2(R, HasProps ++ HasPropsAcc, ExcellentList ++ ExcellentAcc);
        _ ->
            get_equip_excellent2(R, HasPropsAcc, ExcellentAcc)
    end.

filter_has_list([], _HasProps, PropsAcc) ->
    PropsAcc;
filter_has_list(PropsList, [], PropsAcc) ->
    PropsList2 = [ {Weight, {Index, Key, Value, Score}}|| {Index, [Weight, Key, Value, Score]} <- PropsList],
    PropsAcc ++ PropsList2;
filter_has_list([{Index, Prop}|R], HasProps, PropsAcc) ->
    case lists:member(Index, HasProps) of
        true ->
            HasProps2 = lists:delete(Index, HasProps),
            filter_has_list(R, HasProps2, PropsAcc);
        _ ->
            PropsAcc2 =
                case Prop of
                    [Weight, Key, Value, Score] ->
                        [{Weight, {Index, Key, Value, Score}}|PropsAcc];
                    _  ->
                        PropsAcc
                end,
            filter_has_list(R, HasProps, PropsAcc2)
    end.

handle({#m_mythical_equip_load_tos{soul_id = SoulID, id = ID}, RoleID, _PID}, State) ->
    do_equip_load(RoleID, SoulID, ID, State);
handle({#m_mythical_equip_unload_tos{soul_id = SoulID, id = ID}, RoleID, _PID}, State) ->
    do_equip_unload(RoleID, SoulID, ID, State);
handle({#m_mythical_equip_status_tos{status = Status, soul_id = SoulID}, RoleID, _PID}, State) ->
    do_equip_status(RoleID, SoulID, Status, State);
handle({#m_mythical_equip_add_num_tos{}, RoleID, _PID}, State) ->
    do_equip_add_num(RoleID, State);
handle({#m_mythical_equip_refine_tos{soul_id = SoulID, id = ID, material_list = MaterialList, is_double = IsDouble}, RoleID, _PID}, State) ->
    do_equip_refine(RoleID, SoulID, ID, MaterialList, IsDouble, State);
handle(modify_mythical_equip, State) ->
    do_modify_mythical_equip(State);
handle(Info, State) ->
    ?ERROR_MSG("unkonw Info : ~w", [Info]),
    State.

%% 穿戴装备
do_equip_load(RoleID, SoulID, ID, State) ->
    case catch check_equip_load(SoulID, ID, State) of
        {ok, AddList, DelIDs, MythicalSoul2, Log, IsCalc, TypeID, State2} ->
            mod_role_dict:add_background_logs(Log),
            DataRecord = #m_mythical_equip_load_toc{soul = MythicalSoul2},
            common_misc:unicast(RoleID, DataRecord),
            notify_del_equips(RoleID, DelIDs),
            notify_add_equips(RoleID, AddList),
            ?IF(IsCalc, mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MYTHICAL_EQUIP_LOAD, TypeID), State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mythical_equip_load_toc{err_code = ErrCode}),
            State
    end.

check_equip_load(SoulID, ID, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_list = SoulList, bag_list = BagList} = RoleMythicalEquip,
    {Equip, BagList2} =
        case lists:keytake(ID, #p_mythical_equip.id, BagList) of
            {value, EquipT, BagListT} ->
                {EquipT, BagListT};
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_LOAD_002)
        end,
    #p_mythical_equip{type_id = TypeID} = Equip,
    [#c_mythical_equip_info{index = Index, quality = Quality}] = lib_config:find(cfg_mythical_equip_info, TypeID),
    ?IF(Index > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {MythicalSoul, BagList3, AddList, ReplaceTypeID} =
        case lists:keyfind(SoulID, #p_mythical_soul.soul_id, SoulList) of
            #p_mythical_soul{equip_list = EquipListT} = MythicalSoulT ->
                case check_same_type(Index, EquipListT, []) of
                    {#p_mythical_equip{} = ReplaceSoul, EquipListT2}  ->
                        {MythicalSoulT#p_mythical_soul{equip_list = EquipListT2}, [ReplaceSoul|BagList2], [ReplaceSoul], ReplaceSoul#p_mythical_equip.type_id};
                    _ ->
                        {MythicalSoulT, BagList2, [], 0}
                end;
            _ ->
                {#p_mythical_soul{soul_id = SoulID, status = ?MYTHICAL_STATUS_NOT}, BagList2, [], 0}
        end,
    #p_mythical_soul{status = Status, equip_list = EquipList} = MythicalSoul,
    [#c_mythical_equip_base{
        level = NeedLevel,
        index_1 = Quality1,
        index_2 = Quality2,
        index_3 = Quality3,
        index_4 = Quality4,
        index_5 = Quality5
    }] = lib_config:find(cfg_mythical_equip_base, SoulID),
    ?IF(mod_role_data:get_role_level(State) >= NeedLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(Quality >= lists:nth(Index, [Quality1, Quality2, Quality3, Quality4, Quality5]), ok, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_LOAD_002)),
    EquipList2 = [Equip|EquipList],
    Status2 = ?IF(is_equip_full(EquipList2) andalso Status =:= ?MYTHICAL_STATUS_NOT, ?MYTHICAL_STATUS_CAN, Status),
    MythicalSoul2 = MythicalSoul#p_mythical_soul{status = Status2, equip_list = EquipList2},
    SoulList2 = lists:keystore(SoulID, #p_mythical_soul.soul_id, SoulList, MythicalSoul2),
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_list = SoulList2, bag_list = BagList3},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    Log = get_replace_log(SoulID, TypeID, ReplaceTypeID, State2),
    {ok, AddList, [ID], MythicalSoul2, Log, Status2 =:= ?MYTHICAL_STATUS_ACTIVE, TypeID, State2}.

check_same_type(_Index, [], _Acc) ->
    ok;
check_same_type(Index, [Equip|R], Acc) ->
    #p_mythical_equip{type_id = TypeID} = Equip,
    [#c_mythical_equip_info{index = DestIndex}] = lib_config:find(cfg_mythical_equip_info, TypeID),
    ?IF(Index =:= DestIndex, {Equip, R ++ Acc}, check_same_type(Index, R, [Equip|Acc])).

%% 卸载装备
do_equip_unload(RoleID, SoulID, ID, State) ->
    case catch check_equip_unload(SoulID, ID, State) of
        {ok, UnloadList, MythicalSoul, Logs, IsStatusChange, State2} ->
            mod_role_dict:add_background_logs(Logs),
            DataRecord = #m_mythical_equip_unload_toc{soul = MythicalSoul},
            common_misc:unicast(RoleID, DataRecord),
            notify_add_equips(RoleID, UnloadList),
            State3 = ?IF(IsStatusChange, do_skill_change(State, mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MYTHICAL_EQUIP_UNLOAD, ID)), State2),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mythical_equip_load_toc{err_code = ErrCode}),
            State
    end.

check_equip_unload(SoulID, ID, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_list = SoulList, bag_list = BagList} = RoleMythicalEquip,
    {UnloadList, MythicalSoul, IsStatusChange} =
        case lists:keyfind(SoulID, #p_mythical_soul.soul_id, SoulList) of
            #p_mythical_soul{status = Status, equip_list = EquipListT} = MythicalSoulT ->
                {UnloadListT, EquipListT3} =
                    case ID of
                        0 ->
                            {EquipListT, []};
                        _ ->
                            case lists:keytake(ID, #p_mythical_equip.id, EquipListT) of
                                {value, Equip, EquipListT2} ->
                                    {[Equip], EquipListT2};
                                _ ->
                                    ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_UNLOAD_002)
                            end
                    end,
                ?IF(is_bag_full2(erlang:length(UnloadListT), erlang:length(BagList)), ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_UNLOAD_003), ok),
                MythicalSoulT2 = MythicalSoulT#p_mythical_soul{status = ?MYTHICAL_STATUS_NOT, equip_list = EquipListT3},
                {UnloadListT, MythicalSoulT2, Status =:= ?MYTHICAL_STATUS_ACTIVE};
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_UNLOAD_001)
        end,
    SoulList2 = ?IF(MythicalSoul#p_mythical_soul.equip_list =:= [],
        lists:keydelete(SoulID, #p_mythical_soul.soul_id, SoulList),
        lists:keystore(SoulID, #p_mythical_soul.soul_id, SoulList, MythicalSoul)
        ),
    BagList2 = UnloadList ++ BagList,
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_list = SoulList2, bag_list = BagList2},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    Logs = [ get_replace_log(SoulID, 0, ReplaceTypeID, State2)|| #p_mythical_equip{type_id = ReplaceTypeID} <- UnloadList],
    Logs2 = ?IF(IsStatusChange, [get_status_log(SoulID, false, State)|Logs], Logs),
    {ok, UnloadList, MythicalSoul, Logs2, IsStatusChange, State2}.


do_equip_status(RoleID, SoulID, Status, State) ->
    case catch check_equip_status(SoulID, Status, State) of
        {ok, Log, State2} ->
            mod_role_dict:add_background_logs(Log),
            DataRecord = #m_mythical_equip_status_toc{soul_id = SoulID, status = Status},
            common_misc:unicast(RoleID, DataRecord),
            do_skill_change(State, mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MYTHICAL_EQUIP_STATUS, SoulID));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mythical_equip_status_toc{err_code = ErrCode}),
            State
    end.

check_equip_status(SoulID, Status, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_num = SoulNum, soul_list = SoulList} = RoleMythicalEquip,
    {MythicalSoul, SoulList2} =
        case lists:keytake(SoulID, #p_mythical_soul.soul_id, SoulList) of
            {value, #p_mythical_soul{} = MythicalSoulT, SoulListT} ->
                {MythicalSoulT, SoulListT};
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_STATUS_001)
        end,
    #p_mythical_soul{status = NowStatus} = MythicalSoul,
    MythicalSoul2 =
    case Status of
        ?MYTHICAL_STATUS_ACTIVE -> %% 激活
            ActiveNum = erlang:length([ TempSoul|| #p_mythical_soul{status = ?MYTHICAL_STATUS_ACTIVE} = TempSoul <- SoulList2]),
            ?IF(ActiveNum >= SoulNum, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_STATUS_002), ok),
            ?IF(NowStatus =:= ?MYTHICAL_STATUS_CAN, ok, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_STATUS_003)),
            MythicalSoul#p_mythical_soul{status = Status};
        _ ->
            ?IF(NowStatus =:= ?MYTHICAL_STATUS_ACTIVE, ok, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_STATUS_003)),
            MythicalSoul#p_mythical_soul{status = Status}
    end,
    SoulList3 = [MythicalSoul2|SoulList2],
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_list = SoulList3},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    Log = get_status_log(SoulID, NowStatus =:= ?MYTHICAL_STATUS_ACTIVE, State2),
    {ok, Log, State2}.

do_equip_add_num(RoleID, State) ->
    case catch check_equip_add_num(State) of
        {ok, SoulNum, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_mythical_equip_add_num_toc{soul_num = SoulNum}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mythical_equip_add_num_toc{err_code = ErrCode}),
            State
    end.

check_equip_add_num(State) ->
    #r_role{role_attr = #r_role_attr{level = Level}, role_mythical_equip = RoleMythicalEquip} = State,
    VipLevel = mod_role_vip:get_vip_level(State),
    #r_role_mythical_equip{soul_num = SoulNum} = RoleMythicalEquip,
    ?IF(is_mythical_open(SoulNum), ok, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_ADD_NUM_001)),
    SoulNum2 = SoulNum + 1,
    Config =
        case lib_config:find(cfg_mythical_equip_unlock, SoulNum2) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_ADD_NUM_002)
        end,
    #c_mythical_equip_unlock{
        level = NeedLevel,
        vip_level = NeedVipLevel,
        item = NeedItem} = Config,
    if
        Level >= NeedLevel ->
            ok;
        VipLevel >= NeedVipLevel andalso NeedVipLevel =/= 0 ->
            ok;
        true ->
            ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_ADD_NUM_003)
    end,
    ItemList = common_misc:get_item_reward(NeedItem),
    BagDoings = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_MYTHICAL_STATUS, State),
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_num = SoulNum2},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    {ok, SoulNum2, BagDoings, State2}.

do_equip_refine(RoleID, SoulID, ID, MaterialList, IsDouble, State) ->
    case catch check_equip_refine(SoulID, ID, MaterialList, IsDouble, State) of
        {ok, DelList, Equip, Log, IsCalc, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            notify_del_equips(RoleID, DelList),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_mythical_equip_refine_toc{soul_id = SoulID, equip = Equip, is_double = IsDouble}),
            ?IF(IsCalc, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MYTHICAL_EQUIP_REFINE, ID), State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mythical_equip_refine_toc{err_code = ErrCode}),
            State
    end.

check_equip_refine(SoulID, ID, MaterialList, IsDouble, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_list = SoulList, bag_list = BagList} = RoleMythicalEquip,
    ?IF(MaterialList =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {MythicalSoul, SoulList2} =
        case lists:keytake(SoulID, #p_mythical_soul.soul_id, SoulList) of
            {value, #p_mythical_soul{} = MythicalSoulT, SoulListT} ->
                {MythicalSoulT, SoulListT};
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_REFINE_001)
        end,
    #p_mythical_soul{status = Status, equip_list = EquipList} = MythicalSoul,
    ?IF(Status =:= ?MYTHICAL_STATUS_ACTIVE, ok, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_REFINE_005)),
    {Equip, EquipList2} =
        case lists:keytake(ID, #p_mythical_equip.id, EquipList) of
            {value, #p_mythical_equip{} = EquipT, EquipListT} ->
                {EquipT, EquipListT};
            _ ->
                ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_REFINE_002)
        end,
    #p_mythical_equip{type_id = TypeID, refine_level = OldLevel, refine_exp = OldExp} = Equip,
    [#c_mythical_equip_info{refine_num = RefineNum}] = lib_config:find(cfg_mythical_equip_info, TypeID),
    ?IF(OldLevel >= RefineNum, ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_REFINE_003), ok),
    {BagList2, DelList, LogGoods, AddExp, DoubleExp} = check_equip_refine2(MaterialList, IsDouble, BagList, [], [], 0, 0),
    {UseGold, AssetDoings} =
        case DoubleExp > 0 of
            true ->
                UseGoldT = lib_tool:ceil(DoubleExp/(common_misc:get_global_int(?GLOBAL_MYTHICAL_REFINE_GOLD) * 100)),
                {UseGoldT, mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, UseGoldT, ?ASSET_GOLD_REDUCE_FROM_MYTHICAL_REFINE, State)};
            _ ->
                {0, []}
        end,
    {NewLevel, NewExp} = get_refine_level(OldLevel, OldExp, AddExp),
    Equip2 = Equip#p_mythical_equip{refine_level = NewLevel, refine_exp = NewExp},
    EquipList3 = [Equip2|EquipList2],
    MythicalSoul2 = MythicalSoul#p_mythical_soul{equip_list = EquipList3},
    SoulList3 = [MythicalSoul2|SoulList2],
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{bag_list = BagList2, soul_list = SoulList3},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    Log = get_refine_log(SoulID, TypeID, AddExp, OldLevel, NewLevel, LogGoods, UseGold, State2),
    IsCalc = OldLevel =/= NewLevel,
    {ok, DelList, Equip2, Log, IsCalc, AssetDoings, State2}.

check_equip_refine2([], _IsDouble, BagList, DelListAcc, LogGoodsAcc, AddExpAcc, DoubleExpAcc) ->
    {BagList, DelListAcc, LogGoodsAcc, AddExpAcc, DoubleExpAcc};
check_equip_refine2([ID|R], IsDouble, BagList, DelListAcc, LogGoodsAcc, AddExpAcc, DoubleExpAcc) ->
    case lists:keytake(ID, #p_mythical_equip.id, BagList) of
        {value, Equip, BagList2} ->
            #p_mythical_equip{
                id = DelID,
                type_id = TypeID,
                refine_level = RefineLevel,
                refine_exp = RefineExp} = Equip,
            DelListAcc2 = [DelID|DelListAcc],
            [#c_mythical_equip_info{add_exp = AddExp}] = lib_config:find(cfg_mythical_equip_info, TypeID),
            {AddExp2, DoubleExpAcc2} =
                case RefineLevel > 0 orelse RefineExp > 0 of
                    true ->
                        AllExp =
                            case RefineLevel > 0 of
                                true ->
                                    [#c_mythical_equip_refine{all_exp = AllExpT}] = lib_config:find(cfg_mythical_equip_refine, RefineLevel),
                                    AllExpT;
                                _ ->
                                    0
                            end,
                        {AllExp + AddExp + RefineExp, DoubleExpAcc};
                    _ ->
                        ?IF(IsDouble, {AddExp + AddExp, DoubleExpAcc + AddExp}, {AddExp, DoubleExpAcc})
                end,
            AddExpAcc2 = AddExpAcc + AddExp2,
            LogGoodsAcc2 =
                case lists:keytake(TypeID, #p_kv.id, LogGoodsAcc) of
                    {value, #p_kv{val = OldVal} = KV, LogGoodsAccT} ->
                        [KV#p_kv{val = OldVal + 1}|LogGoodsAccT];
                    _ ->
                        [#p_kv{id = TypeID, val = 1}|LogGoodsAcc]
                end,
            check_equip_refine2(R, IsDouble, BagList2, DelListAcc2, LogGoodsAcc2, AddExpAcc2, DoubleExpAcc2);
        _ ->
            ?THROW_ERR(?ERROR_MYTHICAL_EQUIP_REFINE_004)
    end.

get_refine_level(Level, Exp, AddExp) ->
    Level2 = Level + 1,
    Exp2 = Exp + AddExp,
    case lib_config:find(cfg_mythical_equip_refine, Level2) of
        [#c_mythical_equip_refine{need_exp = NeedExp}] ->
            case Exp2 >= NeedExp of
                true ->
                    get_refine_level(Level2, Exp2 - NeedExp, 0);
                _ ->
                    {Level, Exp2}
            end;
        _ ->
            {Level, 0}
    end.

do_skill_change(OldState, State) ->
    OldSkills = get_skills(OldState),
    NewSkills = get_skills(State),
    case OldSkills =/= NewSkills of
        true ->
            State2 = mod_role_skill:skill_fun_change(?SKILL_FUN_MYTHICAL, NewSkills, State),
            %% 风刀霜剑这个技能取消，要返还原有的技能风卷残云
            ?IF(lists:member(10301001, OldSkills), mod_role_skill:skill_open(1101001, State2), State2);
        _ ->
            State
    end.

get_skills(State) ->
    #r_role{role_mythical_equip = #r_role_mythical_equip{soul_list = SoulList}} = State,
    lists:sort(lists:flatten([ get_soul_skill(SoulID)|| #p_mythical_soul{soul_id = SoulID, status = ?MYTHICAL_STATUS_ACTIVE} <- SoulList])).

get_soul_skill(SoulID) ->
    [#c_mythical_equip_base{skill_list = SkillList}] = lib_config:find(cfg_mythical_equip_base, SoulID),
    SkillList.

get_base_add([], SelfAddAcc, AllAddAcc) ->
    {SelfAddAcc, AllAddAcc};
get_base_add([[]|R], SelfAddAcc, AllAddAcc) ->
    get_base_add(R, SelfAddAcc, AllAddAcc);
get_base_add([String|R], SelfAddAcc, AllAddAcc) ->
    case string:tokens(String, "|") of
        [Type, Props] ->
            PropsAdd = lib_tool:string_to_intlist(Props),
            case lib_tool:to_integer(Type) of
                ?PROP_TYPE_SELF ->
                    get_base_add(R, PropsAdd ++ SelfAddAcc, AllAddAcc);
                ?PROP_TYPE_ALL ->
                    get_base_add(R, SelfAddAcc, PropsAdd ++ AllAddAcc)
            end;
        _ ->
            ?ERROR_MSG("error String : ~s", [String]),
            get_base_add(R, SelfAddAcc, AllAddAcc)
    end.

is_mythical_open(SoulNum) when erlang:is_integer(SoulNum) ->
    SoulNum > 0;
is_mythical_open(#r_role_mythical_equip{soul_num = SoulNum}) ->
    is_mythical_open(SoulNum);
is_mythical_open(State) ->
    is_mythical_open(State#r_role.role_mythical_equip).

is_bag_full(AddNum, State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{bag_list = BagList} = RoleMythicalEquip,
    is_bag_full2(AddNum, erlang:length(BagList)).

is_bag_full2(AddNum, NowNum) ->
    AddNum + NowNum >= ?MAX_MYTHICAL_BAG_NUM.

is_equip_full(EquipList) ->
    erlang:length(EquipList) >= ?MAX_MYTHICAL_EQUIP_NUM.

notify_add_equips(_RoleID, []) ->
    ok;
notify_add_equips(RoleID, AddEquips) ->
    common_misc:unicast(RoleID, #m_mythical_equip_add_toc{add_list = AddEquips}).

notify_del_equips(_RoleID, []) ->
    ok;
notify_del_equips(RoleID, DelIDs) ->
    common_misc:unicast(RoleID, #m_mythical_equip_del_toc{del_list = DelIDs}).

merge_base_add(BaseAdd) ->
    merge_base_add(BaseAdd, []).

merge_base_add([], Acc) ->
    Acc;
merge_base_add([{PropID, Value}|R], Acc) ->
    case lists:keytake(PropID, 1, Acc) of
        {value, {PropID, OldVal}, Acc2} ->
            merge_base_add(R, [{PropID, OldVal + Value}|Acc2]);
        _ ->
            merge_base_add(R, [{PropID, Value}|Acc])
    end.

get_equip_add_log(Equip, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #p_mythical_equip{
        id = EquipID,
        type_id = TypeID,
        excellent_list = ExcellentList
    } = Equip,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_mythical_equip_add{
        role_id = RoleID,
        equip_id = EquipID,
        type_id = TypeID,
        excellent_string = common_misc:to_kv_string(to_excellent_kv(ExcellentList)),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_replace_log(SoulID, TypeID, ReplaceTypeID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_mythical_equip_replace{
        role_id = RoleID,
        soul_id = SoulID,
        load_type_id = TypeID,
        replace_type_id = ReplaceTypeID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_status_log(SoulID, IsActive, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_mythical_equip_status{
        role_id = RoleID,
        soul_id = SoulID,
        is_active = IsActive,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_refine_log(SoulID, TypeID, AddExp, OldLevel, NewLevel, LogGoods, UseGold, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_mythical_equip_refine{
        role_id = RoleID,
        soul_id = SoulID,
        type_id = TypeID,
        add_exp = AddExp,
        old_level = OldLevel,
        new_level = NewLevel,
        goods_string = common_misc:to_kv_string(LogGoods),
        use_gold = UseGold,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

to_excellent_kv(ExcellentList) ->
    [ #p_kv{id = Key, val = Val}|| #p_kvt{id = Key, val = Val} <- ExcellentList].

do_modify_mythical_equip(State) ->
    #r_role{role_mythical_equip = RoleMythicalEquip} = State,
    #r_role_mythical_equip{soul_list = SoulList, bag_list = BagList} = RoleMythicalEquip,
    RoleLevel = mod_role_data:get_role_level(State),
    {SoulList2, AddEquips} = do_modify_soul_list(SoulList, RoleLevel, [], []),
    BagList2 = do_modify_equip_list(BagList, []),
    RoleMythicalEquip2 = RoleMythicalEquip#r_role_mythical_equip{soul_list = SoulList2, bag_list = AddEquips ++ BagList2},
    State2 = State#r_role{role_mythical_equip = RoleMythicalEquip2},
    State3 = mod_role_fight:calc_attr_and_update(calc(State2)),
    online(State3).

do_modify_soul_list([], _RoleLevel, SoulAcc, AddAcc) ->
    {SoulAcc, AddAcc};
do_modify_soul_list([Soul|R], RoleLevel, SoulAcc, AddAcc) ->
    #p_mythical_soul{soul_id = SoulID, equip_list = EquipList} = Soul,
    [#c_mythical_equip_base{level = NeedLevel}] = lib_config:find(cfg_mythical_equip_base, SoulID),
    EquipList2 = do_modify_equip_list(EquipList, []),
    case RoleLevel >= NeedLevel of
        true ->
            do_modify_soul_list(R, RoleLevel, [Soul#p_mythical_soul{equip_list = EquipList2}|SoulAcc], AddAcc);
        _ ->
            do_modify_soul_list(R, RoleLevel, SoulAcc, EquipList2 ++ AddAcc)
    end.

do_modify_equip_list([], Acc) ->
    Acc;
do_modify_equip_list([Equip|R], Acc) ->
    #p_mythical_equip{type_id = TypeID} = Equip,
    Equip2 = Equip#p_mythical_equip{excellent_list = get_equip_excellent(TypeID)},
    do_modify_equip_list(R, [Equip2|Acc]).