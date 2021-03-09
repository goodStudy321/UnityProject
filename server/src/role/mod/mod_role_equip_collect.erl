%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 八月 2019 12:20
%%%-------------------------------------------------------------------
-module(mod_role_equip_collect).
-author("chenqinyong").
-include("db.hrl").
-include("common.hrl").
-include("proto/mod_role_equip_collect.hrl").
-include("proto/mod_role_equip.hrl").
-include("all_pb.hrl").
-include("role.hrl").
-include("equip_collect.hrl").
%% API
-export([
    init/1,
    online/1,
    handle/2,
    calc/1
]).

init(#r_role{role_id = RoleID, role_equip_collect = undefined} = State) ->
    RoleEquipCollect = #r_role_equip_collect{role_id = RoleID},
    State#r_role{role_equip_collect = RoleEquipCollect};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_equip_collect = RoleEquipCollect} = State,
    #r_role_equip_collect{list = List} = RoleEquipCollect,
    DataRecord = #m_equip_collect_info_toc{equip_list = List},
    common_misc:unicast(RoleID, DataRecord),
    State.

calc(State) ->
    #r_role{role_equip_collect = RoleEquipCollect} = State,
    #r_role_equip_collect{list = List} = RoleEquipCollect,
    IdList = [Id||#p_equip_collect{id = Id} <- List],
    SuitList =
    lists:foldl(
        fun(ID, Acc) ->
            case lists:keyfind(ID, #p_equip_collect.id, List) of
                #p_equip_collect{suit_num = SuitNum} ->
                    [{ID, SuitNum}|Acc];
                _ ->
                    Acc
            end
        end, [], IdList),
    CalcAttr = calc_equip_suit_attr(SuitList),
    mod_role_fight:get_state_by_kv(State, ?CALC_EQUIP_COLLECT, CalcAttr).

%% 计算套装
calc_equip_suit_attr(SuitList) ->
    SuitList2 = lists:reverse(lists:keysort(1, SuitList)),
    calc_equip_suit_attr2(SuitList2, #actor_cal_attr{}).

calc_equip_suit_attr2([], Attr) ->
    Attr;
calc_equip_suit_attr2([{ID, NowNum}|R], AttrAcc) ->
    [#c_equip_collect_info{
        suit_num = SuitNum,
        suit_props1 = SuitProps1,
        suit_props2 = SuitProps2,
        suit_props3 = SuitProps3,
        suit_props4 = SuitProps4
    }] = lib_config:find(cfg_equip_collect, ID),
    SuitNumString = string:tokens(SuitNum, "|"),
    SuitNum1 = lib_tool:to_integer(lists:nth(1, SuitNumString)),
    SuitNum2 = lib_tool:to_integer(lists:nth(2, SuitNumString)),
    SuitNum3 = lib_tool:to_integer(lists:nth(3, SuitNumString)),
    SuitNum4 = lib_tool:to_integer(lists:nth(4, SuitNumString)),
    SuitList = [{SuitNum1, SuitProps1}, {SuitNum2, SuitProps2}, {SuitNum3, SuitProps3}, {SuitNum4, SuitProps4}],
    AttrList = calc_equip_suit_attr3(SuitList, NowNum, []),
    Attr = common_misc:sum_calc_attr(lists:flatten(AttrList)),
    calc_equip_suit_attr2(R, common_misc:sum_calc_attr2(AttrAcc, Attr)).

calc_equip_suit_attr3([], _NowNum, AttrListAcc) ->
    AttrListAcc;
calc_equip_suit_attr3([{SuitNum, SuitProps}|R], NowNum, AttrListAcc) ->
    case NowNum >= SuitNum of
        true ->
            Attr = common_misc:get_attr_by_kv(common_misc:get_string_props1(SuitProps)),
            AttrListAcc2 = [Attr|AttrListAcc],
            calc_equip_suit_attr3(R, NowNum, AttrListAcc2);
        _ ->
            AttrListAcc
    end.

handle({#m_suit_active_tos{id = ID, suit_num = SuitNum, ids = IDs}, RoleID, _PID}, State) ->
    do_suit_active(RoleID, ID, SuitNum, IDs, State);
handle({#m_skill_active_tos{id = ID}, RoleID, _PID}, State) ->
    do_skill_active(RoleID, ID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info : ~w", [Info]),
    State.

%% 套装激活
do_suit_active(RoleID, ID, SuitNum, IDs,State) ->
    case catch check_suit_active(ID, SuitNum, IDs, State) of
        {ok, SuitNum, IDs, State2} ->
            common_misc:unicast(RoleID, #m_suit_active_toc{id = ID, suit_num = SuitNum, ids = IDs}),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_COLLECT_EQUIP_SUIT, ID),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_suit_active_toc{err_code = ErrCode}),
            State
    end.

check_suit_active(ID, SuitNum, IDs, State) ->
    #r_role{role_equip = RoleEquip, role_equip_collect = RoleEquipCollect} = State,
    #r_role_equip_collect{list = List} = RoleEquipCollect,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    ?IF(ID > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [#c_equip_collect_info{step = Step, star = Star, quality = Quality}] = lib_config:find(cfg_equip_collect,ID),
    TypeIDs = [TypeID || #p_equip{equip_id = TypeID} <- EquipList],
    IDs2 = [IDs1 || #p_equip_collect{id = ID1, ids = IDs1} <- List, ID1 =:= ID],
    IDs3 = lists:flatten(IDs2),
    TypeIDs1 = lists:foldl(
        fun(TypeID1, Acc) ->
            [#c_equip{index = Index, step = Step1, star = Star1, quality = Quality1}] = lib_config:find(cfg_equip,TypeID1),
            ?IF((Step1 >= Step andalso ((Quality1 > Quality) orelse ((Quality1 =:= Quality) andalso (Star1 >= Star))) andalso not lists:member(Index, IDs3)), [TypeID1|Acc], Acc)
        end, [], TypeIDs),
    ?IF(erlang:length(TypeIDs1) + erlang:length(IDs3) < SuitNum, ?THROW_ERR(?ERROR_SUIT_ACTIVE_002), ok),
    case lists:keyfind(ID, #p_equip_collect.id, List) of
        #p_equip_collect{suit_num = SuitNum0} ->
            ?IF((SuitNum0 >= SuitNum), ?THROW_ERR(?ERROR_SUIT_ACTIVE_001), ok);
        _ ->
            ok
    end,
    List1 = lists:keystore(ID, #p_equip_collect.id, List, #p_equip_collect{id = ID, suit_num = SuitNum, ids = IDs, is_active = false}),
    RoleEquipCollect2 = RoleEquipCollect#r_role_equip_collect{list = List1},
    State2 = State#r_role{role_equip_collect = RoleEquipCollect2},
    {ok, SuitNum, IDs, State2}.

%% 激活技能
do_skill_active(RoleID, ID, State) ->
    case catch check_can_active(ID, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_skill_active_toc{id = ID}),
            State3 = mod_role_skill:skill_fun_change(?SKILL_FUN_EQUIP_COLLECT, get_id_skill(State2), State2),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_skill_active_toc{err_code = ErrCode}),
            State
    end.

check_can_active(ID, State) ->
    #r_role{role_equip = RoleEquip, role_equip_collect = RoleEquipCollect} = State,
    #r_role_equip_collect{list = List} = RoleEquipCollect,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    ?IF(ID > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    case lists:keyfind(ID, #p_equip_collect.id, List) of
        #p_equip_collect{is_active = true} -> ?THROW_ERR(?ERROR_SKILL_ACTIVE_002);
        _ -> ok
    end,
    [#c_equip_collect_info{suit_num = SuitNum2, skill_reward = SkillReward}] = lib_config:find(cfg_equip_collect, ID),
    SuitNumString = string:tokens(SuitNum2, "|"),
    MaxSuitNum = lib_tool:to_integer(lists:last(SuitNumString)),
    SkillString = string:tokens(SkillReward, ":"),
    EquipMaxNum = lib_tool:to_integer(lists:nth(1, SkillString)),
    TypeIDs = [TypeId || #p_equip{equip_id = TypeId} <- EquipList],
    [#c_equip_collect_info{step = Step, star = Star, quality = Quality}] = lib_config:find(cfg_equip_collect,ID),
    IDs2 = [IDs1 || #p_equip_collect{id = ID1, ids = IDs1} <- List, ID1 =:= ID],
    IDs3 = lists:flatten(IDs2),
    TypeIDs1 = lists:foldl(
        fun(TypeID1, Acc) ->
            [#c_equip{index = Index, step = Step1, star = Star1, quality = Quality1}] = lib_config:find(cfg_equip,TypeID1),
            ?IF((Step1 >= Step andalso ((Quality1 > Quality) orelse ((Quality1 =:= Quality) andalso (Star1 >= Star))) andalso not lists:member(Index, IDs3)), [TypeID1|Acc], Acc)
        end, [], TypeIDs),
    SuitNum1 = [SuitNum0 || #p_equip_collect{id = ID0, suit_num = SuitNum0} <- List, ID0 =:= ID],
    ?IF(((lists:nth(1, SuitNum1)) >= MaxSuitNum) andalso (erlang:length(TypeIDs1) + erlang:length(IDs3) >= EquipMaxNum), ok, ?THROW_ERR(?ERROR_SKILL_ACTIVE_001)),
    List1 =
        case lists:keyfind(ID, #p_equip_collect.id, List) of
            #p_equip_collect{suit_num = SuitNum, is_active = false, ids = IDs} ->
                lists:keystore(ID, #p_equip_collect.id, List, #p_equip_collect{id = ID, suit_num = SuitNum, is_active = true, ids = IDs});
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)

        end,
    RoleEquipCollect2 = RoleEquipCollect#r_role_equip_collect{list = List1},
    State2 = State#r_role{role_equip_collect = RoleEquipCollect2},
    {ok, State2}.

get_id_skill(State) ->
    #r_role{role_equip_collect = RoleEquipCollect} = State,
    #r_role_equip_collect{list = List} = RoleEquipCollect,
    SkillList1 = lists:foldl(
        fun(#p_equip_collect{id = ID}, Acc) ->
            [#c_equip_collect_info{skill_reward = SkillReward}] = lib_config:find(cfg_equip_collect, ID),
            Skill = string:tokens(SkillReward, ":"),
            SkillId = lib_tool:to_integer(lists:nth(2, Skill)),
            case lists:keyfind(ID, #p_equip_collect.id, List) of
                #p_equip_collect{is_active = true} ->
                    [SkillId|Acc];
                _ ->
                    Acc
            end
        end, [], List),
    SkillList1.