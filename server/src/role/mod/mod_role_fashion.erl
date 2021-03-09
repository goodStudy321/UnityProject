%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     时装模块
%%% @end
%%% Created : 13. 七月 2017 9:58
%%%-------------------------------------------------------------------
-module(mod_role_fashion).
-author("laijichang").
-include("role.hrl").
-include("marry.hrl").
-include("family.hrl").
-include("proto/mod_role_fashion.hrl").
-include("proto/mod_role_item.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    loop_min/2,
    handle/2
]).

-export([
    use_fashion/3,
    use_time_fashion/4,
    get_chat_skin/1,
    get_chat_skin2/1,
    unload_weapon/1,
    family_title_change/2,
    couple_fashion_suit/1,

    skin_filter/1
]).

-export([
    get_base_skins/1
]).

-export([
    is_fashion_cloth/1,
    get_fashion_suit_props/1
]).

-export([
    gm_fashion_timeout/1
]).

init(#r_role{role_id = RoleID, role_fashion = undefined} = State) ->
    RoleFashion = #r_role_fashion{role_id = RoleID},
    State#r_role{role_fashion = RoleFashion};
init(State) ->
    State.

calc(State) ->
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList, essence_list = EssenceList, suit_list = SuitList} = RoleFashion,
    TypeEssences = get_essence_add(EssenceList),
    CalcAttr = calc2(FashionList, TypeEssences, #actor_cal_attr{}),
    SuitAttr = calc_suit_attr(SuitList, #actor_cal_attr{}),
    Attr = common_misc:sum_calc_attr([CalcAttr, SuitAttr]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_FASHION, Attr).

calc2([], _TypeEssences, CalcAttr) ->
    CalcAttr;
calc2([Fashion|R], TypeEssences, CalcAttr) ->
    #p_fashion_time{fashion_id = FashionID} = Fashion,
    [Config] = lib_config:find(cfg_fashion_star, FashionID),
    #c_fashion_star{
        fashion_type = Type,
        add_hp = AddHp,
        add_attack = AddAttack,
        add_defence = AddDefence,
        add_arp = AddArp
    } = Config,
    CalcAttr2 =
        case lists:keyfind(Type, 1, TypeEssences) of
            {Type, HpRate, AttackRate, DefenceRate,  ArpRate} ->
                #actor_cal_attr{
                    max_hp = {AddHp * (1 + HpRate/?RATE_100), 0},
                    attack = {AddAttack * (1 + AttackRate/?RATE_100), 0},
                    defence = {AddDefence * (1 + DefenceRate/?RATE_100), 0},
                    arp = {AddArp * (1 + ArpRate/?RATE_100), 0}
                };
            _ ->
                #actor_cal_attr{
                    max_hp = {AddHp, 0},
                    attack = {AddAttack, 0},
                    defence = {AddDefence, 0},
                    arp = {AddArp, 0}
                }
        end,
    calc2(R, TypeEssences, common_misc:sum_calc_attr2(CalcAttr, CalcAttr2)).

calc_suit_attr([], AttrAcc) ->
    AttrAcc;
calc_suit_attr([FashionSuit|R], AttrAcc) ->
    #p_fashion_suit{suit_id = SuitID, active_num = ActiveNum} = FashionSuit,
    [Config] = lib_config:find(cfg_fashion_suit, SuitID),
    #c_fashion_suit{suit_props = SuitPropsString} = Config,
    SuitProps = get_fashion_suit_props(SuitPropsString),
    KVList = calc_suit_attr2(SuitProps, ActiveNum, []),
    Attr = common_misc:get_attr_by_kv(KVList),
    calc_suit_attr(R, common_misc:sum_calc_attr2(Attr, AttrAcc)).

calc_suit_attr2([], _ActiveNum, Acc) ->
    Acc;
calc_suit_attr2([{NeedNum, KVList}|R], ActiveNum, Acc) ->
    case ActiveNum >= NeedNum of
        true ->
            calc_suit_attr2(R, ActiveNum, KVList ++ Acc);
        _ ->
            Acc
    end.


get_essence_add(EssenceList) ->
    lists:foldl(
        fun(#p_fashion{type = Type, level = Level}, Acc) ->
            [#c_fashion_essence{
                hp_rate = HpRate,
                attack_rate = AttackRate,
                defence_rate = DefenceRate,
                arp_rate = ArpRate
            }] = lib_config:find(cfg_fashion_essence, {Level, Type}),
            case lists:keyfind(Type, 1, Acc) of
                {Type, OldHpRate, OldAttackRate, OldDefenceRate, OldArpRate} ->
                    Val = {Type, OldHpRate + HpRate, OldAttackRate + AttackRate, OldDefenceRate + DefenceRate, OldArpRate + ArpRate},
                    lists:keyreplace(Type, 1, Acc, Val);
                _ ->
                    [{Type, HpRate, AttackRate, DefenceRate,  ArpRate}|Acc]
            end
        end, [], EssenceList).

online(#r_role{role_id = RoleID, role_fashion = RoleFashion} = State) ->
    #r_role_fashion{
        cur_id_list = CurIDList,
        fashion_list = FashionList,
        essence_list = EssenceList,
        suit_list = SuitList} = RoleFashion,
    DataRecord = #m_fashion_info_toc{
        op_type = ?FASHION_INFO_ONLINE,
        cur_id_list = CurIDList,
        fashion_list = FashionList,
        essence_list = EssenceList,
        suit_list = SuitList},
    common_misc:unicast(RoleID, DataRecord),
    State2 = loop_min(time_tool:now(), State),
    couple_fashion_suit(State2).

loop_min(Now, State) ->
    #r_role{role_id = RoleID, role_fashion = RoleFashion} = State,
    #r_role_fashion{cur_id_list = CurIDList, fashion_list = FashionList} = RoleFashion,
    {FashionList2, DelBaseList} =
        lists:foldl(
            fun(#p_fashion_time{fashion_id = FashionID, end_time = EndTime} = Fashion, {FashionAcc, DelBaseAcc}) ->
              case EndTime > 0 andalso Now >= EndTime of
                  true -> %% 过期
                      common_misc:unicast(RoleID, #m_fashion_del_toc{fashion_id = FashionID}),
                      {FashionAcc, [?GET_BASE_ID(FashionID)|DelBaseAcc]};
                  _ ->
                      {[Fashion|FashionAcc], DelBaseAcc}
              end
          end, {[], []}, FashionList),
    case DelBaseList =/= [] of
        true ->
            CurIDList2 = [ CurID|| CurID <- CurIDList, not lists:member(?GET_BASE_ID(CurID), DelBaseList)],
            RoleFashion2 = RoleFashion#r_role_fashion{cur_id_list = CurIDList2, fashion_list = FashionList2},
            State2 = State#r_role{role_fashion = RoleFashion2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_FASHION_TIMEOUT, lists:nth(1, DelBaseList)),
            common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList2}),
            State4 = ?IF(CurIDList =/= CurIDList2, mod_role_skin:update_skin(State3), State3),
            mod_role_skill:skill_fun_change(?SKILL_FUN_FASHION, get_fashion_skills(State4), State4);
        _ ->
            State
    end.

gm_fashion_timeout(State) ->
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList} = RoleFashion,
    FashionList2 = [ Fashion#p_fashion_time{end_time = ?IF(EndTime > 0, 1, EndTime)}|| #p_fashion_time{end_time = EndTime} = Fashion<- FashionList],
    RoleFashion2 = RoleFashion#r_role_fashion{fashion_list = FashionList2},
    loop_min(time_tool:now(), State#r_role{role_fashion = RoleFashion2}).

get_chat_skin(State) ->
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{cur_id_list = CurIDList} = RoleFashion,
    get_chat_skin2(CurIDList).

get_chat_skin2(CurIDList) ->
    get_chat_skin3(CurIDList, []).

get_chat_skin3([], Acc) ->
    Acc;
get_chat_skin3([FashionID|R], Acc) ->
    case lib_config:find(cfg_fashion_star, FashionID) of
        [#c_fashion_star{fashion_type = FashionType}] ->
            case FashionType =:= ?FASHION_TYPE_HEADER orelse FashionType =:= ?FASHION_TYPE_BUBBLE of
                true ->
                    get_chat_skin3(R, [?GET_BASE_ID(FashionID)|Acc]);
                _ ->
                    get_chat_skin3(R, Acc)
            end;
        _ ->
            get_chat_skin3(R, Acc)
    end.

unload_weapon(State) ->
    #r_role{role_id = RoleID, role_fashion = RoleFashion} = State,
    #r_role_fashion{cur_id_list = CurIDList} = RoleFashion,
    {_WeaponID, CurIDList2} = spilt_weapon(CurIDList),
    RoleFashion2 = RoleFashion#r_role_fashion{cur_id_list = CurIDList2},
    common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList2}),
    State#r_role{role_fashion = RoleFashion2}.

use_fashion(FashionID, UseNum, State) ->
    #r_role{role_id = RoleID, role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList} = RoleFashion,
    case lib_config:find(cfg_fashion_star, FashionID) of
        [#c_fashion_star{} = Config] ->
            {Fashion, FashionList2, OldFashionID} = use_fashion2(FashionID, UseNum, FashionList, []),
            State2 = do_use_fashion(RoleID, Config, UseNum, Fashion, FashionList2, OldFashionID, RoleFashion, State),
            mod_role_skin:update_couple_skin(?DB_ROLE_FASHION_P, ?GET_BASE_ID(FashionID), State2);
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end.

use_fashion2(FashionID, UseNum, [], FashionAcc) ->
    [#c_fashion_star{cost = [_, NeedNum]}] = lib_config:find(cfg_fashion_star, FashionID),
    ?IF(UseNum >= NeedNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    Fashion = #p_fashion_time{fashion_id = FashionID, end_time = 0},
    {Fashion, [Fashion|FashionAcc], 0};
use_fashion2(FashionID, UseNum, [HasFashion|R], FashionAcc) ->
    #p_fashion_time{fashion_id = HasFashionID, end_time = EndTime} = HasFashion,
    case ?GET_BASE_ID(FashionID) =:= ?GET_BASE_ID(HasFashionID) of
        true ->
            HasFashionID2 = ?IF(EndTime > 0, HasFashionID, HasFashionID + 1),
            case lib_config:find(cfg_fashion_star, HasFashionID2) of
                [_Config] ->
                    [#c_fashion_star{cost = [_, NeedNum]}] = lib_config:find(cfg_fashion_star, HasFashionID),
                    ?IF(UseNum >= NeedNum, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                    HasFashion2 = HasFashion#p_fashion_time{fashion_id = HasFashionID2, end_time = 0},
                    {HasFashion2, [HasFashion2|FashionAcc] ++ R, HasFashionID};
                _ ->
                    ?THROW_ERR(?ERROR_ITEM_USE_013)
            end;
        _ ->
            use_fashion2(FashionID, UseNum, R, [HasFashion|FashionAcc])
    end.

use_time_fashion(FashionID, UseNum, EndTime, State) ->
    #r_role{role_id = RoleID, role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList} = RoleFashion,
    case lib_config:find(cfg_fashion_star, FashionID) of
        [#c_fashion_star{} = Config] ->
            {Fashion, FashionList2, OldFashionID} = use_time_fashion2(FashionID, UseNum, EndTime, FashionList, []),
            do_use_fashion(RoleID, Config, UseNum, Fashion, FashionList2, OldFashionID, RoleFashion, State);
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end.

use_time_fashion2(FashionID, _UseNum, EndTime, [], FashionAcc) ->
    Fashion = #p_fashion_time{fashion_id = FashionID, end_time = EndTime},
    {Fashion, [Fashion|FashionAcc], 0};
use_time_fashion2(FashionID, UseNum, EndTime, [HasFashion|R], FashionAcc) ->
    #p_fashion_time{fashion_id = HasFashionID, end_time = OldEndTime} = HasFashion,
    case ?GET_BASE_ID(FashionID) =:= ?GET_BASE_ID(HasFashionID) of
        true ->
            ?IF(OldEndTime > 0, ok, ?THROW_ERR(?ERROR_ITEM_USE_020)),
            HasFashion2 = HasFashion#p_fashion_time{end_time = EndTime},
            {HasFashion2, [HasFashion2|FashionAcc] ++ R, HasFashionID};
        _ ->
            use_time_fashion2(FashionID, UseNum, EndTime, R, [HasFashion|FashionAcc])
    end.


do_use_fashion(RoleID, Config, UseNum, Fashion, FashionList2, OldFashionID, RoleFashion, State) ->
    #c_fashion_star{
        fashion_id = FashionID,
        fashion_name = FashionName,
        fashion_type = FashionType} = Config,
    #r_role_fashion{cur_id_list = CurIDList} = RoleFashion,
    #p_fashion_time{fashion_id = FashionID2} = Fashion,
    log_fashion(OldFashionID, FashionID2, FashionID, UseNum, State),
    CurIDList2 =
        case OldFashionID =:= 0 of
            true ->
                [#c_fashion_base{broadcast_id = BroadcastID}] = lib_config:find(cfg_fashion_base, ?GET_BASE_ID(FashionID)),
                ?IF(BroadcastID > 0,
                    common_broadcast:send_world_common_notice(BroadcastID, [mod_role_data:get_role_name(State), FashionName, lib_tool:to_list(FashionID)]),
                    ok),
                check_can_change2(FashionID2, FashionType, CurIDList, []);
            _ ->
                [ ?IF(?GET_BASE_ID(FashionID2) =:= ?GET_BASE_ID(CurID), FashionID2, CurID) || CurID <- CurIDList]
        end,
    RoleFashion2 = RoleFashion#r_role_fashion{fashion_list = FashionList2, cur_id_list = CurIDList2},
    common_misc:unicast(RoleID, #m_fashion_update_toc{fashion = Fashion}),
    common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList2}),
    State2 = mod_role_fight:calc_attr_and_update(calc(State#r_role{role_fashion = RoleFashion2}), ?POWER_UPDATE_FASHION_STAR, FashionID2),
    State3 = ?IF(FashionType =:= ?FASHION_TYPE_WEAPON, mod_role_god_book:activate_fashion(State2), State2),
    State4 = ?IF(CurIDList =/= CurIDList2, mod_role_skin:update_skin(State3), State3),
    do_fashion_id_skill(OldFashionID, FashionID2, State4).

family_title_change(FamilyTitleID, State) ->
    [FashionBaseID|_] = common_misc:get_global_list(?GLOBAL_FAMILY_POPULAR),
    FashionID = ?GET_NORMAL_ID(FashionBaseID),
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{role_id = RoleID, cur_id_list = CurIDList, fashion_list = FashionList} = RoleFashion,
    {IsExist, FashionList2} = spilt_by_base_id(FashionBaseID, FashionList),
    case FamilyTitleID of
        ?TITLE_POPULAR ->
            case IsExist of
                true ->
                    State;
                _ ->
                    Fashion = #p_fashion_time{fashion_id = FashionID, end_time = 0},
                    FashionList3 = [Fashion|FashionList2],
                    CurIDList2 = change_cur_fashion(FashionID, CurIDList),
                    RoleFashion2 = RoleFashion#r_role_fashion{cur_id_list = CurIDList2, fashion_list = FashionList3},
                    State2 = State#r_role{role_fashion = RoleFashion2},
                    common_misc:unicast(RoleID, #m_fashion_update_toc{fashion = Fashion}),
                    common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList2}),
                    State3 = mod_role_skin:update_skin(State2),
                    mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_FAMILY_TITLE, FashionID)
            end;
        _ ->
            case IsExist of
                true ->
                    RoleFashion2 = RoleFashion#r_role_fashion{cur_id_list = lists:delete(FashionID, CurIDList), fashion_list = FashionList2},
                    State2 = State#r_role{role_fashion = RoleFashion2},
                    common_misc:unicast(RoleID, #m_fashion_del_toc{fashion_id = FashionID}),
                    common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList}),
                    State3 = mod_role_skin:update_skin(State2),
                    mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_FAMILY_TITLE, FashionID);
                _ ->
                    State
            end
    end.

%% 检查仙侣称号
couple_fashion_suit(State) ->
    #r_role{role_id = RoleID, role_fashion = RoleFashion, role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    MySkins = mod_role_skin:get_base_skins_by_state(State),
    CoupleSkins = mod_role_skin:get_base_skins_by_role_id(CoupleID),
    #r_role_fashion{suit_list = SuitList} = RoleFashion,
    {SuitList2, ChangeList} = couple_fashion_suit2(SuitList, MySkins, CoupleSkins, [], []),
    case ChangeList =/= [] of
        true ->
            [ common_misc:unicast(RoleID, #m_fashion_suit_toc{fashion_suit = FashionSuit})|| FashionSuit <- ChangeList],
            RoleFashion2 = RoleFashion#r_role_fashion{suit_list = SuitList2},
            State2 = State#r_role{role_fashion = RoleFashion2},
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_FASHION_SUIT_CHANGE, 0),
            mod_role_skill:skill_fun_change(?SKILL_FUN_FASHION, get_fashion_skills(State3), State3);
        _ ->
            State
    end.

couple_fashion_suit2([], _MySkins, _CoupleSkins, SuitAcc, ChangeAcc) ->
    {SuitAcc, ChangeAcc};
couple_fashion_suit2([FashionSuit|R], MySkins, CoupleSkins, SuitAcc, ChangeAcc) ->
    #p_fashion_suit{suit_id = SuitID, active_num = ActiveNum} = FashionSuit,
    [#c_fashion_suit{
        suit_type = SuitType,
        suit_props = SuitPropString,
        suit_base_list = SuitBaseList}] = lib_config:find(cfg_fashion_suit, SuitID),
    case SuitType of
        ?FASHION_SUIT_TYPE_MARRY ->
            HasNum = check_fashion_suit2(SuitBaseList, MySkins, 0) + check_fashion_suit2(SuitBaseList, CoupleSkins, 0),
            case ActiveNum > HasNum of
                true -> %% 当前激活数量 > 拥有数量，改变
                    ActiveNum2 = couple_fashion_suit3(get_fashion_suit_props(SuitPropString), HasNum, 0),
                    FashionSuit2 = FashionSuit#p_fashion_suit{active_num = ActiveNum2},
                    couple_fashion_suit2(R, MySkins, CoupleSkins, [FashionSuit2|SuitAcc], [FashionSuit2|ChangeAcc]);
                _ ->
                    couple_fashion_suit2(R, MySkins, CoupleSkins, [FashionSuit|SuitAcc], ChangeAcc)
            end;
        _ ->
            couple_fashion_suit2(R, MySkins, CoupleSkins, [FashionSuit|SuitAcc], ChangeAcc)
    end.

couple_fashion_suit3([], _HasNum, AccNum) ->
    AccNum;
couple_fashion_suit3([{NeedNum, _Props}|R], HasNum, AccNum) ->
    case HasNum >= NeedNum of
        true ->
            couple_fashion_suit3(R, HasNum, NeedNum);
        _ ->
            AccNum
    end.

spilt_by_base_id(FashionBaseID, FashionList) ->
    spilt_by_base_id2(FashionBaseID, FashionList, []).

spilt_by_base_id2(_FashionBaseID, [], Acc) ->
    {false, Acc};
spilt_by_base_id2(FashionBaseID, [Fashion|R], Acc) ->
    #p_fashion_time{fashion_id = FashionID} = Fashion,
    case FashionBaseID =:= ?GET_BASE_ID(FashionID) of
        true ->
            {true, R ++ Acc};
        _ ->
            spilt_by_base_id2(FashionBaseID, R, [Fashion|Acc])
    end.

change_cur_fashion(FashionID, CurIDList) ->
    BaseID = ?GET_BASE_ID(FashionID),
    CurIDList2 = [ CurID || CurID <- CurIDList, ?GET_BASE_ID(CurID) =/= BaseID],
    [FashionID|CurIDList2].

spilt_weapon(FashionList) ->
    spilt_weapon2(FashionList, []).

spilt_weapon2([], OtherList) ->
    {0, OtherList};
spilt_weapon2([FashionID|R], OtherList) ->
    [#c_fashion_star{fashion_type = FashionType}] = lib_config:find(cfg_fashion_star, FashionID),
    case FashionType =:= ?FASHION_TYPE_WEAPON of
        true ->
            {FashionID, R ++ OtherList};
        _ ->
            spilt_weapon2(R, [FashionID|OtherList])
    end.

skin_filter(FashionList) ->
    skin_filter2(FashionList, 0, []).

skin_filter2([], WeaponID, OtherList) ->
    {WeaponID, OtherList};
skin_filter2([FashionID|R], WeaponIDAcc, OtherList) ->
    [#c_fashion_star{fashion_type = FashionType}] = lib_config:find(cfg_fashion_star, FashionID),
    if
        FashionType =:= ?FASHION_TYPE_WEAPON ->
            skin_filter2(R, FashionID, OtherList);
        FashionType =:= ?FASHION_TYPE_CLOTH orelse FashionType =:= ?FASHION_TYPE_FOOTPRINT->
            skin_filter2(R, WeaponIDAcc, [FashionID|OtherList]);
        true ->
            skin_filter2(R, WeaponIDAcc, OtherList)
    end.

is_fashion_cloth(FashionID) ->
    case lib_config:find(cfg_fashion_star, FashionID) of
        [#c_fashion_star{fashion_type = ?FASHION_TYPE_CLOTH}] ->
            true;
        _ ->
            false
    end.

get_base_skins(undefined) ->
    [];
get_base_skins(RoleFashion) ->
    #r_role_fashion{fashion_list = FashionList} = RoleFashion,
    [ ?GET_BASE_ID(FashionID)|| #p_fashion_time{fashion_id = FashionID, end_time = EndTime} <- FashionList, EndTime =:= 0].

handle({#m_fashion_change_tos{cur_id = CurID, type = ChangeType}, RoleID, _PID}, State) ->
    do_fashion_change(RoleID, CurID, ChangeType, State);
handle({#m_fashion_decompose_tos{id_list = GoodsIDList}, RoleID, _PID}, State) ->
    do_fashion_decompose(RoleID, GoodsIDList, State);
handle({#m_fashion_suit_tos{suit_id = SuitID, active_num = ActiveNum}, RoleID, _PID}, State) ->
    do_fashion_suit(RoleID, SuitID, ActiveNum, State);
handle({#m_fashion_give_tos{base_id = BaseID}, RoleID, _PID}, State) ->
    do_fashion_give(RoleID, BaseID, State).

do_fashion_change(RoleID, CurID, ChangeType, State) ->
    case catch check_can_change(CurID, ChangeType, State) of
        {ok, IsFashionFirst2, CurIDList2, State2} ->
            common_misc:unicast(RoleID, #m_fashion_change_toc{cur_id_list = CurIDList2}),
            mod_role_skin:update_skin(State2, IsFashionFirst2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fashion_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(CurID, ChangeType, State) ->
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{cur_id_list = CurIDList, fashion_list = FashionList, is_fashion_first = IsFashionFirst} = RoleFashion,
    [#c_fashion_star{fashion_type = FashionType}] = lib_config:find(cfg_fashion_star, CurID),
    if
        ChangeType =:= ?FASHION_CHANGE_LOAD ->
            ?IF(lists:keymember(CurID, #p_fashion_time.fashion_id, FashionList), ok, ?THROW_ERR(?ERROR_FASHION_CHANGE_002)),
            CurIDList2 = check_can_change2(CurID, FashionType, CurIDList, []),
            IsFashionFirst2 = ?IF(FashionType =:= ?FASHION_TYPE_WEAPON, true, IsFashionFirst);
        ChangeType =:= ?FASHION_CHANGE_UNLOAD ->
            ?IF(lists:member(CurID, CurIDList), ok, ?THROW_ERR(?ERROR_FASHION_CHANGE_002)),
            CurIDList2 = lists:delete(CurID, CurIDList),
            IsFashionFirst2 = IsFashionFirst
    end,
    RoleFashion2 = RoleFashion#r_role_fashion{cur_id_list = CurIDList2},
    {ok, IsFashionFirst2, CurIDList2, State#r_role{role_fashion = RoleFashion2}}.

check_can_change2(CurID, _FashionType, [], Acc) ->
    [CurID|Acc];
check_can_change2(CurID, FashionType, [FashionID|R], Acc) ->
    [#c_fashion_star{fashion_type = FashionType2}] = lib_config:find(cfg_fashion_star, FashionID),
    case FashionType =:= FashionType2 of
        true ->
            [CurID|R] ++ Acc;
        _ ->
            check_can_change2(CurID, FashionType, R, [FashionID|Acc])
    end.

%% 时装分解
do_fashion_decompose(RoleID, GoodsIDList, State) ->
    case catch check_fashion_decompose(GoodsIDList, State) of
        {ok, BagDoings, IsLevelUp, ChangeList, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            [ common_misc:unicast(RoleID, #m_fashion_decompose_toc{essence = Essence}) || Essence <- ChangeList],
            ?IF(IsLevelUp, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_FASHION_DECOMPOSE, 0), State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fashion_decompose_toc{err_code = ErrCode}),
            State
    end.

check_fashion_decompose(GoodsIDList, State) ->
    ?IF(GoodsIDList =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList, essence_list = EssenceList} = RoleFashion,
    FullList = get_full_fashions(FashionList, []),
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(GoodsIDList, State),
    AddExpList =
        lists:foldl(
            fun(#p_goods{type_id = TypeID, num = Num}, Acc) ->
                case mod_role_item:get_item_config(TypeID) of
                    #c_item{effect_type = ?ITEM_ADD_FASHION, effect_args = EffectArgs} ->
                        BaseID = ?GET_BASE_ID(lib_tool:to_integer(EffectArgs)),
                        ?IF(lists:member(BaseID, FullList), ok, ?THROW_ERR(?ERROR_FASHION_DECOMPOSE_002)),
                        [#c_fashion_base{type = Type, exp = AddExp}] = lib_config:find(cfg_fashion_base, BaseID),
                        AddExp2 = AddExp * Num,
                        case lists:keyfind(Type, 1, Acc) of
                            {Type, OldExp} ->
                                lists:keyreplace(Type, 1, Acc, {Type, OldExp + AddExp2});
                            _ ->
                                [{Type, AddExp2}|Acc]
                        end;
                    _ ->
                        ?THROW_ERR(?ERROR_FASHION_DECOMPOSE_001)
                end
            end, [], GoodsList),
    BagDoing = [{delete, ?ITEM_REDUCE_FASHION_DECOMPOSE, GoodsIDList}],
    {EssenceList2, IsLevelUp, ChangeList} = get_decompose_level(AddExpList, EssenceList, false, []),
    RoleFashion2 = RoleFashion#r_role_fashion{essence_list = EssenceList2},
    State2 = State#r_role{role_fashion = RoleFashion2},
    {ok, BagDoing, IsLevelUp, ChangeList, State2}.

get_full_fashions([], Acc) ->
    Acc;
get_full_fashions([Fashion|R], Acc) ->
    #p_fashion_time{fashion_id = FashionID, end_time = EndTime} = Fashion,
    case EndTime =< 0 of
        true ->
            case lib_config:find(cfg_fashion_star, FashionID + 1) of
                [_Config] ->
                    get_full_fashions(R, Acc);
                _ ->
                    get_full_fashions(R, [?GET_BASE_ID(FashionID)|Acc])
            end;
        _ ->
            get_full_fashions(R, Acc)
    end.

get_decompose_level([], EssenceList, IsLevelUpAcc, ChangeAcc) ->
    {EssenceList, IsLevelUpAcc, ChangeAcc};
get_decompose_level([{Type, AddExp}|R], EssenceList, IsLevelUpAcc, ChangeAcc) ->
    Essence =
        case lists:keyfind(Type, #p_fashion.type, EssenceList) of
            #p_fashion{} = E ->
                E;
            _ ->
                #p_fashion{type = Type, level = 1, exp = 0}
        end,
    #p_fashion{level = Level, exp = Exp} = Essence,
    case lib_config:find(cfg_fashion_essence, {Level + 1, Type}) of
        [_Config] ->
            {NewLevel, NewExp} = get_decompose_level2(Type, Level, Exp + AddExp),
            Essence2 = Essence#p_fashion{level = NewLevel, exp = NewExp},
            EssenceList2 = lists:keystore(Type, #p_fashion.type, EssenceList, Essence2),
            ChangeAcc2 = lists:keystore(Type, #p_fashion.type, ChangeAcc, Essence2),
            IsLevelUpAcc2 = IsLevelUpAcc orelse (NewLevel =/= Level),
            get_decompose_level(R, EssenceList2, IsLevelUpAcc2, ChangeAcc2);
        _ ->
            ?THROW_ERR(?ERROR_FASHION_DECOMPOSE_003)
    end.

get_decompose_level2(Type, Level, NowExp) ->
    Level2 = Level + 1,
    case lib_config:find(cfg_fashion_essence, {Level2, Type}) of
        [_Config] ->
            [#c_fashion_essence{need_exp = NeedExp}] = lib_config:find(cfg_fashion_essence, {Level, Type}),
            case NowExp >= NeedExp of
                true ->
                    get_decompose_level2(Type, Level2, NowExp - NeedExp);
                _ ->
                    {Level, NowExp}
            end;
        _ ->
            {Level, 0}
    end.

do_fashion_suit(RoleID, SuitID, ActiveNum, State) ->
    case catch check_fashion_suit(SuitID, ActiveNum, State) of
        {ok, FashionSuit, State2} ->
            common_misc:unicast(RoleID, #m_fashion_suit_toc{fashion_suit = FashionSuit}),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_FASHION_SUIT, SuitID),
            do_suit_skill(FashionSuit, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fashion_suit_toc{err_code = ErrCode}),
            State
    end.

check_fashion_suit(SuitID, ActiveNum, State) ->
    #r_role{role_fashion = RoleFashion, role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    #r_role_fashion{suit_list = SuitList} = RoleFashion,
    {FashionSuit, SuitList2} =
        case lists:keytake(SuitID, #p_fashion_suit.suit_id, SuitList) of
            {value, #p_fashion_suit{} = FashionSuitT, SuitListT} ->
                {FashionSuitT, SuitListT};
            _ ->
                {#p_fashion_suit{suit_id = SuitID}, SuitList}
        end,
    #p_fashion_suit{active_num = NowActiveNum} = FashionSuit,
    ?IF(NowActiveNum >= ActiveNum, ?THROW_ERR(?ERROR_FASHION_SUIT_001), ok),
    case lib_config:find(cfg_fashion_suit, SuitID) of
        [Config] ->
            #c_fashion_suit{
                suit_base_list = SuitBaseList,
                suit_type = SuitType,
                suit_props = SuitPropsString,
                suit_skill = SuitSkill} = Config,
            SuitProps = get_fashion_suit_props(SuitPropsString),
            case lists:keyfind(ActiveNum, 1, SuitProps) of
                {ActiveNum, _Props} ->
                    ok;
                _ ->
                    case SuitSkill of
                        [SkillSuitNum|_] ->
                            ?IF(ActiveNum =:= SkillSuitNum, ok, ?THROW_ERR(?ERROR_FASHION_SUIT_002));
                        _ ->
                            ?THROW_ERR(?ERROR_FASHION_SUIT_002)
                    end
            end,
            SkinBaseList = mod_role_skin:get_base_skins_by_state(State),
            HasNum =
                case SuitType of
                    ?FASHION_SUIT_TYPE_NORMAL ->
                        check_fashion_suit2(SuitBaseList, SkinBaseList, 0);
                    ?FASHION_SUIT_TYPE_MARRY ->
                        CoupleSkins = mod_role_skin:get_base_skins_by_role_id(CoupleID),
                        check_fashion_suit2(SuitBaseList, SkinBaseList, 0) + check_fashion_suit2(SuitBaseList, CoupleSkins, 0)
                end,
            ?IF(HasNum >= ActiveNum, ok, ?THROW_ERR(?ERROR_FASHION_SUIT_003)),
            FashionSuit2 = FashionSuit#p_fashion_suit{active_num = ActiveNum},
            SuitList3 = [FashionSuit2|SuitList2],
            RoleFashion2 = RoleFashion#r_role_fashion{suit_list = SuitList3},
            State2 = State#r_role{role_fashion = RoleFashion2},
            {ok, FashionSuit2, State2};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.

check_fashion_suit2([], _SkinBaseList, HasNum) ->
    HasNum;
check_fashion_suit2(_SuitBaseList, [], HasNum) ->
    HasNum;
check_fashion_suit2([SuitBaseID|R], SkinBaseList, HasNum) ->
    case lists:member(SuitBaseID, SkinBaseList) of
        true ->
            check_fashion_suit2(R, lists:delete(SuitBaseID, SkinBaseList), HasNum + 1);
        _ ->
            check_fashion_suit2(R, SkinBaseList, HasNum)
    end.

do_fashion_give(RoleID, BaseID, State) ->
    case catch check_fashion_give(BaseID, State) of
        {ok, CoupleID, LetterInfo, AssetDoings, LogList, IsUpdate, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = ?IF(IsUpdate, mod_role_shop:online(State3), State3),
            common_misc:unicast(RoleID, #m_fashion_give_toc{}),
            mod_role_dict:add_background_logs(LogList),
            common_letter:send_letter(CoupleID, LetterInfo),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fashion_give_toc{err_code = ErrCode}),
            State
    end.

check_fashion_give(BaseID, State) ->
    #r_role{role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_FASHION_GIVE_001)),
    [#c_fashion_base{shop_id = ShopID}] = lib_config:find(cfg_fashion_base, BaseID),
    ItemID =
        case ShopID > 0 andalso lib_config:find(cfg_shop, ShopID) of
            [#c_shop{item_id = ItemIDT}] ->
                ItemIDT;
            _ ->
                ?THROW_ERR(?ERROR_FASHION_GIVE_002)
        end,
    {ok, _ItemID, GoodsList, AssetDoing, LogList, State2, IsUpdate} = mod_role_shop:check_can_buy(ShopID, 1, ItemID, State),
    BaseSkins = mod_role_skin:get_base_skins_by_role_id(CoupleID),
    ?IF(lists:member(BaseID, BaseSkins), ?THROW_ERR(?ERROR_FASHION_GIVE_003), ok),
    #c_item{name = ItemName} = mod_role_item:get_item_config(ItemID),
    RoleName = mod_role_data:get_role_name(State),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_FASHION_GIVE,
        action = ?ITEM_GAIN_FASHION_GIVE,
        goods_list = GoodsList,
        text_string = [RoleName, ItemName]
    },
    {ok, CoupleID, LetterInfo, AssetDoing, LogList, IsUpdate, State2}.

get_fashion_suit_props(SuitPropsString) ->
    [ begin
          [NeedNum, PropStrings] = string:tokens(NumProps, ":"),
          PropList = common_misc:get_string_props(PropStrings),
          {lib_tool:to_integer(NeedNum), PropList}
      end|| NumProps <- string:tokens(SuitPropsString, ";")].

%% 时装激活 or 升星
do_fashion_id_skill(OldFashionID, FashionID, State) ->
    OldSkills = get_fashion_id_skills(OldFashionID),
    NewSkills = get_fashion_id_skills(FashionID),
    case lists:sort(OldSkills) =/= lists:sort(NewSkills) of
        true ->
            mod_role_skill:skill_fun_change(?SKILL_FUN_FASHION, get_fashion_skills(State), State);
        _ ->
            State
    end.

%% 套装激活
do_suit_skill(FashionSuit, State) ->
    ?IF(get_suit_skills(FashionSuit) =/= [], mod_role_skill:skill_fun_change(?SKILL_FUN_FASHION, get_fashion_skills(State), State), State).

get_fashion_skills(State) ->
    #r_role{role_fashion = RoleFashion} = State,
    #r_role_fashion{fashion_list = FashionList, suit_list = SuitList} = RoleFashion,
    Skills1 = [ get_fashion_id_skills(FashionID) || #p_fashion_time{fashion_id = FashionID} <- FashionList],
    Skills2 = [ get_suit_skills(SuitID) || SuitID <- SuitList],
    lists:flatten(Skills1 ++ Skills2).

get_fashion_id_skills(0) ->
    [];
get_fashion_id_skills(FashionID) ->
    [#c_fashion_star{skill_list = SkillList}] = lib_config:find(cfg_fashion_star, FashionID),
    SkillList.

get_suit_skills(FashionSuit) ->
    #p_fashion_suit{suit_id = SuitID, active_num = ActiveNum} = FashionSuit,
    [#c_fashion_suit{suit_skill = SuitSkill}] = lib_config:find(cfg_fashion_suit, SuitID),
    case SuitSkill of
        [SkillSuitNum, SkillID|_] ->
            ?IF(ActiveNum >= SkillSuitNum, [SkillID], []);
        _ ->
            []
    end.

log_fashion(OldFashionID, FashionID2, TypeID, UseNum, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    Log =
    #log_role_fashion{
        role_id = RoleID,
        old_fashion_id = OldFashionID,
        new_fashion_id = FashionID2,
        use_type_id = TypeID,
        use_num = UseNum,
        channel_id = ChannelID,
        game_channel_id = GameChannelID},
    mod_role_dict:add_background_logs(Log).