%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2018 11:10
%%%-------------------------------------------------------------------
-module(mod_role_immortal_soul).
-author("WZP").
-include("role.hrl").
-include("immortal_soul.hrl").
-include("proto/mod_role_immortal_soul.hrl").


%% API
-export([
    init/1,
    online/1,
    handle/2,
    calc/1,
    level_up/3,
    get_equip_refine_add/1,
    gm_reset_immortal_soul/1,
    gm_print_all_color/1
]).


-export([
    add_immortal_soul_stone/2,
    add_immortal_soul/2,
    get_color_num/2
]).


gm_reset_immortal_soul(#r_role{role_id = RoleID} = State) ->
    ImmortalSoul = #r_role_immortal_soul{role_id = RoleID, auto_bd_type = 2},  %%默认2
    State#r_role{role_immortal_soul = ImmortalSoul}.

gm_print_all_color(#r_role{role_immortal_soul = ImmortalSoul} = State) ->
    List = [begin
                [Config] = lib_config:find(cfg_immortal_soul, Info#p_immortal_soul.immortal_soul_id),
                {Config#c_immortal_soul.color, erlang:length(Config#c_immortal_soul.type)}
            end || Info <- ImmortalSoul#r_role_immortal_soul.bag_list],
    ?ERROR_MSG("----------gm_print_all_color-----------------------~w", [List]),
    State.

init(#r_role{role_id = RoleID, role_immortal_soul = undefined} = State) ->
    ImmortalSoul = #r_role_immortal_soul{role_id = RoleID, auto_bd_type = 2},  %%默认2
    State#r_role{role_immortal_soul = ImmortalSoul};

init(State) ->
    State.


online(#r_role{role_id = RoleID, role_immortal_soul = RoleImmortalSoul, role_attr = RoleAttr} = State) ->
    PosList = get_open_post(RoleAttr#r_role_attr.level),
    common_misc:unicast(RoleID, #m_role_immortal_soul_toc{use_list = RoleImmortalSoul#r_role_immortal_soul.use_list, bag_list = RoleImmortalSoul#r_role_immortal_soul.bag_list,
                                                          dust = RoleImmortalSoul#r_role_immortal_soul.dust, stone = RoleImmortalSoul#r_role_immortal_soul.stone,
                                                          auto_bd_type = RoleImmortalSoul#r_role_immortal_soul.auto_bd_type, open_pos = PosList}),
    State.


level_up(OldLevel, NewLevel, #r_role{role_id = RoleID}) ->
    PosList1 = get_open_post(OldLevel),
    PosList2 = get_open_post(NewLevel),
    AddPos = PosList2 -- PosList1,
    ?IF(AddPos =:= [], ok, common_misc:unicast(RoleID, #m_role_immortal_soul_pos_toc{pos = AddPos})).

add_immortal_soul_stone(0, State) ->
    State;
add_immortal_soul_stone(Num, #r_role{role_id = RoleID, role_immortal_soul = RoleImmortalSoul} = State) ->
    RoleImmortalSoul2 = RoleImmortalSoul#r_role_immortal_soul{stone = Num + RoleImmortalSoul#r_role_immortal_soul.stone},
    common_misc:unicast(RoleID, #m_role_immortal_soul_stone_toc{stone = RoleImmortalSoul2#r_role_immortal_soul.stone}),
    State#r_role{role_immortal_soul = RoleImmortalSoul2}.

get_equip_refine_add(State) ->
    #r_role{role_immortal_soul = RoleImmortalSoul} = State,
    #r_role_immortal_soul{use_list = UseList} = RoleImmortalSoul,
    case UseList =/= [] of
        true ->
            KVList = trans_to_pkv(UseList, []),
            get_equip_refine_add2(KVList, 0);
        _ ->
            0
    end.

get_equip_refine_add2([], Acc) ->
    Acc;
get_equip_refine_add2([#p_kv{id = ID, val = Val}|R], Acc) ->
    if
        ID =:= ?ATTR_EQUIP_REFINE_ADD ->
            get_equip_refine_add2(R, Acc + Val);
        true ->
            get_equip_refine_add2(R, Acc)
    end.

calc(State) ->
    #r_role{role_immortal_soul = RoleImmortalSoul} = State,
    #r_role_immortal_soul{use_list = UseList} = RoleImmortalSoul,
    case UseList =:= [] of
        true ->
            ActorCalAttr = #actor_cal_attr{},
            mod_role_fight:get_state_by_kv(State, ?CALC_IMMORTAL_SOUL, ActorCalAttr);
        _ ->
            PkvList = trans_to_pkv(UseList, []),
            ActorCalAttr = common_misc:get_attr_by_kv(PkvList),
            LevelAttr = mod_role_level:get_level_attr(State),
            ActorCalLevelBaseAttr = role_misc:get_base_attr_by_kv(PkvList, LevelAttr),
            mod_role_fight:get_state_by_kv(State, ?CALC_IMMORTAL_SOUL, common_misc:sum_calc_attr2(ActorCalAttr, ActorCalLevelBaseAttr))
    end.

trans_to_pkv([], List) ->
    List;
trans_to_pkv([Info|T], List) ->
    [LevelConfig] = lib_config:find(cfg_immortal_soul_level, Info#p_immortal_soul.level_id),
    List2 = case LevelConfig#c_immortal_soul_level.attr1 =:= 0 of
                true ->
                    List;
                _ ->
                    [#p_kv{id = LevelConfig#c_immortal_soul_level.attr1, val = LevelConfig#c_immortal_soul_level.val1}|List]
            end,
    List3 = case LevelConfig#c_immortal_soul_level.attr2 =:= 0 of
                true ->
                    List2;
                _ ->
                    [#p_kv{id = LevelConfig#c_immortal_soul_level.attr2, val = LevelConfig#c_immortal_soul_level.val2}|List2]
            end,
    trans_to_pkv(T, List3).

immortal_calc(State) ->
    FuncList = [
        fun(StateAcc) -> ?MODULE:calc(StateAcc) end,
        fun(StateAcc) -> mod_role_equip:immortal_calc_equip_refine(StateAcc) end
    ],
    role_server:execute_state_fun(FuncList, State).


handle({#m_role_immortal_soul_mosaic_tos{bag_id = BagID, pos = Pos}, RoleID, _PID}, State) ->
    do_mosaic(RoleID, BagID, Pos, State);

handle({#m_role_immortal_soul_bd_tos{bag_id = BagIDs}, RoleID, _PID}, State) ->
    do_bd(RoleID, BagIDs, State);

handle({#m_role_immortal_soul_compose_tos{immortal_soul_id = ImmortalSoulID, bag_list = BagList}, RoleID, _PID}, State) ->
    do_compose(RoleID, ImmortalSoulID, BagList, State);

handle({#m_role_immortal_soul_set_tos{bd_type = Type}, RoleID, _PID}, State) ->
    do_set_bd(RoleID, Type, State);

handle({#m_role_immortal_soul_up_tos{pos = Pos}, RoleID, _PID}, State) ->
    do_level_up(RoleID, Pos, State);

handle({#m_role_immortal_soul_down_tos{pos = Pos}, RoleID, _PID}, State) ->
    do_down(RoleID, Pos, State).

%%设置分解类型分解
do_set_bd(RoleID, Type, State) ->
    case catch check_can_set_bd(Type, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_set_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_set_toc{err_code = ErrCode})
    end.

check_can_set_bd(Type, #r_role{role_immortal_soul = ImmortalSoul} = State) ->
    ?IF(Type >= 0 andalso Type < 6, ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_SET_001)),
    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{auto_bd_type = Type},
    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}}.

%%分解
do_bd(RoleID, BagIDs, State) ->
    case catch check_can_bd(BagIDs, State) of
        {ok, State2, DelIDs, HaveChange, Dust, Stone, AddList} ->
            {State3, AddList2} = check_can_return_reserve_bag_list(State2),
            common_misc:unicast(RoleID, #m_role_immortal_soul_bd_toc{dust = Dust, del_list = DelIDs, add_list = AddList ++ AddList2, stone = Stone}),
            State4 = ?IF(HaveChange, mod_role_fight:calc_attr_and_update(immortal_calc(State3), ?POWER_UPDATE_IMMORTAL_SOUL_BD, 0), State3),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_bd_toc{err_code = ErrCode}),
            State
    end.
%%单个分解（存在双属性）
check_can_bd([BagID], #r_role{role_immortal_soul = ImmortalSoul} = State) ->
    SearchList = ?IF(?IMMORTAL_SOUL_IS_RIGHT_POS(BagID), ImmortalSoul#r_role_immortal_soul.use_list, ImmortalSoul#r_role_immortal_soul.bag_list),
    case lists:keytake(BagID, #p_immortal_soul.index, SearchList) of
        {value, Info, OtherList} ->
            [LevelConfig] = lib_config:find(cfg_immortal_soul_level, Info#p_immortal_soul.level_id),
            Dust = LevelConfig#c_immortal_soul_level.dust,
            {AddList2, AddStone2} = case LevelConfig#c_immortal_soul_level.attr2 =/= 0 of
                                        true ->
                                            CanUseID = get_can_use_list(ImmortalSoul#r_role_immortal_soul.bag_list),
                                            ?IF(erlang:length(CanUseID) > 1, ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_DOWN_003)),
                                            ImmortalSoulID = get_level_one_id(Info#p_immortal_soul.level_id),
                                            case lib_config:find(cfg_immortal_soul_mix, ImmortalSoulID) of
                                                [] ->
                                                    MixConfig = ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_BD_002);
                                                [MixConfig] ->
                                                    MixConfig
                                            end,
                                            [AddID1, AddID2|_] = CanUseID,
                                            AddList = [#p_immortal_soul{index = AddID1, immortal_soul_id = MixConfig#c_immortal_soul_mix.consume1, level_id = MixConfig#c_immortal_soul_mix.consume1},
                                                       #p_immortal_soul{index = AddID2, immortal_soul_id = MixConfig#c_immortal_soul_mix.consume2, level_id = MixConfig#c_immortal_soul_mix.consume2}],
                                            AddStone = MixConfig#c_immortal_soul_mix.stone,
                                            {AddList, AddStone};
                                        _ ->
                                            {[], 0}
                                    end,
            case ?IMMORTAL_SOUL_IS_RIGHT_POS(BagID) of
                ture ->
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = AddList2 ++ ImmortalSoul#r_role_immortal_soul.bag_list, dust = Dust + ImmortalSoul#r_role_immortal_soul.dust,
                                                                      stone = AddStone2 + ImmortalSoul#r_role_immortal_soul.stone, use_list = OtherList},
                    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, [BagID], true, ImmortalSoul2#r_role_immortal_soul.dust, ImmortalSoul2#r_role_immortal_soul.stone, AddList2};
                _ ->
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = AddList2 ++ OtherList, dust = Dust + ImmortalSoul#r_role_immortal_soul.dust,
                                                                      stone = AddStone2 + ImmortalSoul#r_role_immortal_soul.stone},
                    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, [BagID], false, ImmortalSoul2#r_role_immortal_soul.dust, ImmortalSoul2#r_role_immortal_soul.stone, AddList2}
            end;
        _ ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_BD_001)
    end;

%%一键分解不存在双属性
check_can_bd(BagIDs, #r_role{role_immortal_soul = ImmortalSoul} = State) ->
    {BagIDList, UseIDList} = select_id(BagIDs),
    {Dust, DelIDs, UseList, HaveChange} = check_can_bd2(ImmortalSoul#r_role_immortal_soul.use_list, UseIDList),
    {Dust2, DelIDs2, BagList, _} = check_can_bd2(ImmortalSoul#r_role_immortal_soul.bag_list, BagIDList),
    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{use_list = UseList, bag_list = BagList, dust = ImmortalSoul#r_role_immortal_soul.dust + Dust + Dust2},
    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, DelIDs ++ DelIDs2, HaveChange, ImmortalSoul2#r_role_immortal_soul.dust, ImmortalSoul2#r_role_immortal_soul.stone, []}.

%%返回仙魂暗背包物品
check_can_return_reserve_bag_list(#r_role{role_immortal_soul = ImmortalSoul} = State) ->
    case ImmortalSoul#r_role_immortal_soul.reserve_bag_list of
        [] ->
            {State, []};
        ReserveBagList ->
            CanUseID = get_can_use_list(ImmortalSoul#r_role_immortal_soul.bag_list),
            {AddList, ReserveBagList2} = return_reserve_bag_list(CanUseID, ReserveBagList, []),
            ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = ImmortalSoul#r_role_immortal_soul.bag_list ++ AddList, reserve_bag_list = ReserveBagList2},
            {State#r_role{role_immortal_soul = ImmortalSoul2}, AddList}
    end.

return_reserve_bag_list([], ReserveBagList, List) ->
    {List, ReserveBagList};
return_reserve_bag_list(_, [], List) ->
    {List, []};
return_reserve_bag_list([UseID|T], [Info|ReserveBagList], List) ->
    return_reserve_bag_list(T, ReserveBagList, [Info#p_immortal_soul{index = UseID}|List]).

check_can_bd2(List, IDList) ->
    check_can_bd2(List, IDList, 0, [], false).

check_can_bd2(List, [], Dust, DelIDs, HaveChange) ->
    {Dust, DelIDs, List, HaveChange};
check_can_bd2(List, [ID|T], Dust, DelIDs, HaveChange) ->
    case lists:keytake(ID, #p_immortal_soul.index, List) of
        {value, Info, OtherList} ->
            [LevelConfig] = lib_config:find(cfg_immortal_soul_level, Info#p_immortal_soul.level_id),
            check_can_bd2(OtherList, T, Dust + LevelConfig#c_immortal_soul_level.dust, [ID|DelIDs], true);
        _ ->
            check_can_bd2(List, T, Dust, DelIDs, HaveChange)
    end.


select_id(BagIDs) ->
    select_id(BagIDs, [], []).

select_id([], BagList, UseList) ->
    {BagList, UseList};

select_id([BagID|T], BagList, UseList) ->
    case ?IMMORTAL_SOUL_IS_RIGHT_POS(BagID) of
        true ->
            select_id(T, BagList, [BagID|UseList]);
        _ ->
            select_id(T, [BagID|BagList], UseList)
    end.

%%卸仙魂
do_down(RoleID, Pos, State) ->
    case catch check_can_down(Pos, State) of
        {ok, State2, Info} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_down_toc{pos = Pos, bag_add = Info}),
            mod_role_fight:calc_attr_and_update(immortal_calc(State2), ?POWER_UPDATE_IMMORTAL_SOUL_DOWN, Info#p_immortal_soul.level_id);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_down_toc{err_code = ErrCode}),
            State
    end.


check_can_down(Pos, #r_role{role_immortal_soul = ImmortalSoul} = State) ->
    ?IF(?IMMORTAL_SOUL_IS_RIGHT_POS(Pos), ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_DOWN_002)),
    case lists:keytake(Pos, #p_immortal_soul.index, ImmortalSoul#r_role_immortal_soul.use_list) of
        {value, Info, Other} ->
            case get_can_use_list(ImmortalSoul#r_role_immortal_soul.bag_list) of
                [ID|_] ->
                    Info2 = Info#p_immortal_soul{index = ID},
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{use_list = Other, bag_list = [Info2|ImmortalSoul#r_role_immortal_soul.bag_list]},
                    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, Info2};
                _ ->
                    ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_DOWN_003)
            end;
        _ ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_DOWN_001)
    end.


%%融合
do_compose(RoleID, ImmortalSoulID, ExpendList, State) ->
    case catch check_can_compose(ExpendList, ImmortalSoulID, State) of
        {ok, State2, AddImmortalSoul, Stone, Dust, DelList, IsCalc, ColorList} ->
            {State3, AddList2} = check_can_return_reserve_bag_list(State2),
            common_misc:unicast(RoleID, #m_role_immortal_soul_compose_toc{del_list = DelList, immortal_soul = AddImmortalSoul, stone = Stone, dust = Dust, add = AddList2}),
            State4 = ?IF(IsCalc, mod_role_fight:calc_attr_and_update(immortal_calc(State3), ?POWER_UPDATE_IMMORTAL_SOUL_UP, 0), State3),
            mod_role_confine:immortal_soul(ColorList, State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_compose_toc{err_code = ErrCode}),
            State
    end.

check_can_compose(ExpendList, ImmortalSoulID, #r_role{role_immortal_soul = ImmortalSoul, role_attr = RoleAttr} = State) ->
    [MixConfig] = lib_config:find(cfg_immortal_soul_mix, ImmortalSoulID),
    ?IF(ImmortalSoul#r_role_immortal_soul.stone >= MixConfig#c_immortal_soul_mix.stone, ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_COMPOSE_001)),
    ?IF(RoleAttr#r_role_attr.level >= MixConfig#c_immortal_soul_mix.level, ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_COMPOSE_003)),
    {UseList, BagList, List, HaveChange} = get_expend_list(ImmortalSoul#r_role_immortal_soul.bag_list, ImmortalSoul#r_role_immortal_soul.use_list, ExpendList),
    case check_expend_enough(List, [MixConfig#c_immortal_soul_mix.consume1, MixConfig#c_immortal_soul_mix.consume2]) of
        false ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_COMPOSE_002);
        _ ->
            case HaveChange =:= [] of  %%镶嵌列表是否有影响
                true ->
                    CanUseID = get_can_use_list(BagList),
                    ?IF(CanUseID =:= [], ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_COMPOSE_004), ok),
                    [PosID|_CanUseID2] = CanUseID,
                    NewImmortalSoul = #p_immortal_soul{index = PosID, immortal_soul_id = ImmortalSoulID, level_id = ImmortalSoulID},
                    {DelIDs, AddDust} = get_delid_and_dust(List),
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = [NewImmortalSoul|BagList], stone = ImmortalSoul#r_role_immortal_soul.stone - MixConfig#c_immortal_soul_mix.stone,
                                                                      dust = AddDust + ImmortalSoul#r_role_immortal_soul.dust},
                    State2 = State#r_role{role_immortal_soul = ImmortalSoul2},
                    {ok, State2, NewImmortalSoul, ImmortalSoul2#r_role_immortal_soul.stone, ImmortalSoul2#r_role_immortal_soul.dust, DelIDs, false, []};
                _ ->
                    [Config] = lib_config:find(cfg_immortal_soul, ImmortalSoulID),
                    {DelIDs, AddDust} = get_delid_and_dust(List),
                    case check_is_the_same_type(UseList, Config#c_immortal_soul.type) of
                        true ->
                            CanUseID = get_can_use_list(BagList),
                            [PosID|_CanUseID2] = CanUseID,
                            NewImmortalSoul = #p_immortal_soul{index = PosID, immortal_soul_id = ImmortalSoulID, level_id = ImmortalSoulID},
                            ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = [NewImmortalSoul|BagList], stone = ImmortalSoul#r_role_immortal_soul.stone - MixConfig#c_immortal_soul_mix.stone,
                                                                              dust = AddDust + ImmortalSoul#r_role_immortal_soul.dust, use_list = UseList},
                            IsCalc = false;
                        _ ->
                            [PosID|_] = HaveChange,
                            NewImmortalSoul = #p_immortal_soul{index = PosID, immortal_soul_id = ImmortalSoulID, level_id = ImmortalSoulID},
                            ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = BagList, stone = ImmortalSoul#r_role_immortal_soul.stone - MixConfig#c_immortal_soul_mix.stone,
                                                                              dust = AddDust + ImmortalSoul#r_role_immortal_soul.dust, use_list = [NewImmortalSoul|UseList]},
                            IsCalc = true
                    end,
                    ColorList = get_color_num(Config#c_immortal_soul.color, ImmortalSoul2#r_role_immortal_soul.use_list),
                    State2 = State#r_role{role_immortal_soul = ImmortalSoul2},
                    {ok, State2, NewImmortalSoul, ImmortalSoul2#r_role_immortal_soul.stone, ImmortalSoul2#r_role_immortal_soul.dust, DelIDs, IsCalc, ColorList}
            end
    end.


get_color_num(Color, UseList) ->
    case Color =:= 4 orelse Color =:= 5 of
        true ->
            [];
        _ ->
            Num = lists:foldl(
                fun(#p_immortal_soul{immortal_soul_id = ImmortalSoulID}, AccNum) ->
                    [Config] = lib_config:find(cfg_immortal_soul, ImmortalSoulID),
                    ?IF(Config#c_immortal_soul.color =:= Color, AccNum + 1, AccNum)
                end,
                0, UseList),
            [{Num, Color}]
    end.


get_delid_and_dust(List) ->
    get_delid_and_dust(List, [], 0).

get_delid_and_dust([], DelList, Dust) ->
    {DelList, Dust};

get_delid_and_dust([#p_immortal_soul{index = DelID, level_id = LevelID}|T], DelList, Dust) ->
    [Config] = lib_config:find(cfg_immortal_soul_level, LevelID),
    [OneConfig] = lib_config:find(cfg_immortal_soul_level, get_level_one_id(LevelID)),
    get_delid_and_dust(T, [DelID|DelList], Dust + Config#c_immortal_soul_level.dust - OneConfig#c_immortal_soul_level.dust).

check_expend_enough(_List, []) ->
    true;
check_expend_enough(List, [Consume|T]) ->
    case Consume =:= 0 of
        true ->
            check_expend_enough(List, T);
        _ ->
            case lists:keyfind(Consume, #p_immortal_soul.immortal_soul_id, List) of
                false ->
                    false;
                _ ->
                    check_expend_enough(List, T)
            end
    end.

get_expend_list(BagList, UseList, ExpendList) ->
    get_expend_list(ExpendList, UseList, BagList, [], []).

get_expend_list([], UseList, BagList, List, HaveChange) ->
    {UseList, BagList, List, HaveChange};
get_expend_list([ID|T], UseList, BagList, List, HaveChange) ->
    case key_take_by_id(ID, UseList, BagList, HaveChange) of
        {value, UseList2, BagList2, Info, HaveChange2} ->
            get_expend_list(T, UseList2, BagList2, [Info|List], HaveChange2);
        _ ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_COMPOSE_002)
    end.

key_take_by_id(ID, UseList, BagList, HaveChange) ->
    case ?IMMORTAL_SOUL_IS_RIGHT_POS(ID) of
        true ->
            case lists:keytake(ID, #p_immortal_soul.index, UseList) of
                {value, Info, OtherList} ->
                    {value, OtherList, BagList, Info, [ID|HaveChange]};
                _ ->
                    false
            end;
        _ ->
            case lists:keytake(ID, #p_immortal_soul.index, BagList) of
                {value, Info, OtherList} ->
                    {value, UseList, OtherList, Info, HaveChange};
                _ ->
                    false
            end
    end.


%%升级
do_level_up(RoleID, Pos, State) ->
    case catch check_can_level_up(Pos, State) of
        {ok, State2, Dust, LevelID} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_up_toc{dust = Dust, level_id = LevelID, pos = Pos}),
            State3 = mod_role_fight:calc_attr_and_update(immortal_calc(State2), ?POWER_UPDATE_IMMORTAL_SOUL_UP, LevelID),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_up_toc{err_code = ErrCode}),
            State
    end.

check_can_level_up(Pos, #r_role{role_immortal_soul = ImmortalSoul} = State) ->
    #r_role_immortal_soul{use_list = UseList} = ImmortalSoul,
    case lists:keytake(Pos, #p_immortal_soul.index, UseList) of
        {value, #p_immortal_soul{level_id = LevelID} = Info, OtherList} ->
            NewLevelId = get_new_level_id(LevelID, 1),
            case lib_config:find(cfg_immortal_soul_level, LevelID) of
                [] ->
                    ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_UP_001);
                [LevelConfig] ->
                    ?IF(LevelConfig#c_immortal_soul_level.up_dust =< ImmortalSoul#r_role_immortal_soul.dust, ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_UP_002)),
                    Info2 = Info#p_immortal_soul{level_id = NewLevelId},
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{use_list = [Info2|OtherList], dust = ImmortalSoul#r_role_immortal_soul.dust - LevelConfig#c_immortal_soul_level.up_dust},
                    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, ImmortalSoul2#r_role_immortal_soul.dust, NewLevelId}
            end;
        _ ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_005)
    end.

%%镶嵌
do_mosaic(RoleID, BagID, Pos, State) ->
    case catch check_can_mosaic(BagID, Pos, State) of
        {ok, State2, LevelID, Info} ->
            {State3, AddList2} = check_can_return_reserve_bag_list(State2),
            common_misc:unicast(RoleID, #m_role_immortal_soul_mosaic_toc{del_id = BagID, use = Info, add = AddList2}),
            mod_role_fight:calc_attr_and_update(immortal_calc(State3), ?POWER_UPDATE_IMMORTAL_SOUL_WEAR, LevelID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_immortal_soul_mosaic_toc{err_code = ErrCode}),
            State
    end.


check_can_mosaic(BagID, Pos, #r_role{role_immortal_soul = ImmortalSoul, role_attr = RoleAttr} = State) ->
    ?IF(?IMMORTAL_SOUL_IS_RIGHT_POS(Pos), ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_004)),
    ?IF(lists:member(Pos, get_open_post(RoleAttr#r_role_attr.level)), ok, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_006)),
    case lists:keytake(Pos, #p_immortal_soul.index, ImmortalSoul#r_role_immortal_soul.use_list) of
        false ->
            case lists:keytake(BagID, #p_immortal_soul.index, ImmortalSoul#r_role_immortal_soul.bag_list) of
                false ->
                    ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_005);
                {value, Info, OtherList} ->
                    [Config] = lib_config:find(cfg_immortal_soul, Info#p_immortal_soul.immortal_soul_id),
                    ?IF(Config#c_immortal_soul.pos =:= 2 andalso Pos =/= 907, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_007), ok),
                    ?IF(Config#c_immortal_soul.pos =:= 1 andalso Pos =:= 907, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_007), ok),
                    ?IF(Config#c_immortal_soul.pos =:= 0, ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_008), ok),
                    ?IF(check_is_the_same_type(ImmortalSoul#r_role_immortal_soul.use_list, Config#c_immortal_soul.type), ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_002), ok),
                    Info2 = Info#p_immortal_soul{index = Pos},
                    ImmortalSoul2 = ImmortalSoul#r_role_immortal_soul{bag_list = OtherList, use_list = [Info2|ImmortalSoul#r_role_immortal_soul.use_list]},
                    {ok, State#r_role{role_immortal_soul = ImmortalSoul2}, Info#p_immortal_soul.level_id, Info2}
            end;
        _ ->
            ?THROW_ERR(?ERROR_ROLE_IMMORTAL_SOUL_MOSAIC_003)
    end.


check_is_the_same_type([], _Type) ->
    false;
check_is_the_same_type([#p_immortal_soul{immortal_soul_id = ID}|T], Type) ->
    [Config] = lib_config:find(cfg_immortal_soul, ID),
    ?IF(check_is_the_same_type2(Config#c_immortal_soul.type, Type), true, check_is_the_same_type(T, Type)).

check_is_the_same_type2([], _List2) ->
    false;
check_is_the_same_type2([Member|T], List2) ->
    case lists:member(Member, List2) of
        true ->
            true;
        _ ->
            check_is_the_same_type2(T, List2)
    end.

%%添加仙魂进入背包
add_immortal_soul([], State) ->
    State;
add_immortal_soul(ImmortalSoulList, #r_role{role_id = RoleID, role_immortal_soul = RoleImmortalSoul} = State) ->
    {BagList, ImmortalSoulList2, AddDust1} = add_immortal_soul2(ImmortalSoulList, RoleImmortalSoul#r_role_immortal_soul.bag_list, RoleImmortalSoul#r_role_immortal_soul.auto_bd_type),
    {ReserveList, _, AddDust2} = add_immortal_soul2(ImmortalSoulList2, RoleImmortalSoul#r_role_immortal_soul.reserve_bag_list, RoleImmortalSoul#r_role_immortal_soul.auto_bd_type),
    NewDust = RoleImmortalSoul#r_role_immortal_soul.dust + AddDust1 + AddDust2,
    OldIndex = get_all_index(RoleImmortalSoul#r_role_immortal_soul.bag_list),
    common_misc:unicast(RoleID, #m_role_immortal_soul_update_toc{update_list = BagList, dust = NewDust, del_list = OldIndex}),
    NewRoleImmortalSoul = RoleImmortalSoul#r_role_immortal_soul{bag_list = BagList, reserve_bag_list = ReserveList, dust = NewDust},
    State#r_role{role_immortal_soul = NewRoleImmortalSoul}.

add_immortal_soul2(ImmortalSoulIDList, BagList, BdType) ->
    CanUseID = get_can_use_list(BagList),
    add_immortal_soul2(ImmortalSoulIDList, BagList, CanUseID, 0, BdType, true).

add_immortal_soul2(ImmortalSoulIDList, BagList, _CanUseID, Dust, _BdType, false) ->
    {BagList, ImmortalSoulIDList, Dust};
add_immortal_soul2([], BagList, _CanUseID, Dust, _BdType, _CanClean) ->
    {BagList, [], Dust};
add_immortal_soul2([{ImmortalSoulID, Num}|T], BagList, CanUseID, Dust, BdType, CanClean) ->
    case lib_config:find(cfg_immortal_soul, ImmortalSoulID) of
        [] ->
            add_immortal_soul2(T, BagList, CanUseID, Dust, BdType, CanClean);
        [#c_immortal_soul{color = Color, type = Type}] ->
            case Num < erlang:length(CanUseID) of
                true ->
                    {_Num2, CanUseID2, AddImmortalSoulList} = create_immortal_soul(ImmortalSoulID, Num, CanUseID),
                    add_immortal_soul2(T, AddImmortalSoulList ++ BagList, CanUseID2, Dust, BdType, CanClean);
                _ ->
                    {BagList2, CanUseID2, Dust2} = clean_bag(BagList, CanUseID, Dust, BdType),
                    case Color > BdType orelse erlang:length(Type) > 1 of
                        true ->
                            {Num2, CanUseID3, AddImmortalSoulList} = create_immortal_soul(ImmortalSoulID, Num, CanUseID2),
                            case Num2 > 0 of
                                true -> %%背包空间不足把所有数量创建
                                    add_immortal_soul2([{ImmortalSoulID, Num2}|T], AddImmortalSoulList ++ BagList2, CanUseID3, Dust2, BdType, false);
                                _ ->
                                    CanClean2 = ?IF(CanUseID3 =:= [], false, true),
                                    add_immortal_soul2(T, AddImmortalSoulList ++ BagList2, CanUseID3, Dust2, BdType, CanClean2)
                            end;
                        _ ->
                            [LevelConfig] = lib_config:find(cfg_immortal_soul_level, ImmortalSoulID),
                            add_immortal_soul2(T, BagList2, CanUseID2, Dust2 + LevelConfig#c_immortal_soul_level.dust * Num, BdType, CanClean)
                    end
            end
    end.


%%创建仙魂模板
create_immortal_soul(ImmortalSoulID, Num, CanUseID) ->
    create_immortal_soul(ImmortalSoulID, Num, CanUseID, []).

create_immortal_soul(_ImmortalSoulID, Num, [], ImmortalSoulList) ->
    {Num, [], ImmortalSoulList};

create_immortal_soul(_ImmortalSoulID, Num, CanUseID, ImmortalSoulList) when Num < 1 ->
    {Num, CanUseID, ImmortalSoulList};

create_immortal_soul(ImmortalSoulID, Num, [ID|T], ImmortalSoulList) ->
    create_immortal_soul(ImmortalSoulID, Num - 1, T, [#p_immortal_soul{index = ID, immortal_soul_id = ImmortalSoulID, level_id = ImmortalSoulID}|ImmortalSoulList]).


%%清理背包   返回{剩余背包,剩余ID,分解得到的仙尘}
%%  MostList    [{ Class , Color , #p_immortal_soul{} = Info}]
clean_bag(BagList, CanUseID, Dust, BdType) ->
    {BagList2, Dust2, DelIDs} = clean_bag(BagList, Dust, BdType, [], [], []),
    {BagList2, CanUseID ++ DelIDs, Dust2}.

clean_bag([], Dust, _BdType, List, MostList, DelID) ->
    MostList2 = [Info || {_Class, _Color, Info} <- MostList],
    {MostList2 ++ List, Dust, DelID};

clean_bag([Info|T], Dust, BdType, List, MostList, DelID) ->
    case lib_config:find(cfg_immortal_soul, Info#p_immortal_soul.immortal_soul_id) of
        [] ->
            clean_bag(T, Dust, BdType, List, MostList, DelID);
        [Config] ->
            if
                erlang:length(Config#c_immortal_soul.type) > 1 ->
                    clean_bag(T, Dust, BdType, [Info|List], MostList, DelID);
                true ->
                    {List2, MostList2, Dust2, DelID2} = check_is_most(MostList, List, DelID, Info, Config, Dust, BdType),
                    clean_bag(T, Dust2, BdType, List2, MostList2, DelID2)
            end
    end.

%%检查是否为最高品质
check_is_most(MostList, List, DelID, Info, Config, Dust, BdType) ->
    case lists:keytake(Config#c_immortal_soul.class, 1, MostList) of
        false ->
            {List, [{Config#c_immortal_soul.class, Config#c_immortal_soul.color, Info}|MostList], Dust, DelID};
        {value, {_Class, Color, Info2}, OtherList} ->
            case Config#c_immortal_soul.color > Color orelse (Info#p_immortal_soul.level_id > Info2#p_immortal_soul.level_id andalso Config#c_immortal_soul.color =:= Color) of
                true ->%%交出最高品质位置
                    case Color > BdType of
                        true -> %%不分解
                            {[Info2|List], [{Config#c_immortal_soul.class, Config#c_immortal_soul.color, Info}|OtherList], Dust, DelID};
                        _ ->
                            [LevelConfig] = lib_config:find(cfg_immortal_soul_level, Info2#p_immortal_soul.level_id),
                            {List, [{Config#c_immortal_soul.class, Config#c_immortal_soul.color, Info}|OtherList], Dust + LevelConfig#c_immortal_soul_level.dust, [Info2#p_immortal_soul.index|DelID]}
                    end;
                _ ->
                    case Config#c_immortal_soul.color > BdType of
                        true -> %%不分解
                            {[Info|List], MostList, Dust, DelID};
                        _ ->
                            [LevelConfig] = lib_config:find(cfg_immortal_soul_level, Info#p_immortal_soul.level_id),
                            {List, MostList, Dust + LevelConfig#c_immortal_soul_level.dust, [Info#p_immortal_soul.index|DelID]}
                    end
            end
    end.


%%开启孔位
get_open_post(RoleLevel) ->
    [Config] = lib_config:find(cfg_global, ?IMMORTAL_SOUL_GLOBAL_POS),
    List = lib_tool:string_to_intlist(Config#c_global.string, ",", ":"),
    [Pos || {Pos, Level} <- List, RoleLevel >= Level].


%%可以使用ID
get_can_use_list(BagList) ->
    IDList = get_all_index(BagList),
    AllList = lists:seq(1, ?IMMORTAL_SOUL_BAG_SIZE),
    AllList -- IDList.

%%可以使用AllID
get_all_index(BagList) ->
    [ID || #p_immortal_soul{index = ID} <- BagList].


%%新等级ID
get_new_level_id(LevelID, AddLevel) ->
    Value = LevelID div 100000,
    Value2 = LevelID rem 100000,
    FirstNum = Value div 100,
    NewLevel = Value rem 100 + AddLevel,
    FirstNum * 10000000 + NewLevel * 100000 + Value2.

%%获取初始等级Level
get_level_one_id(LevelID) ->
    Value = LevelID div 100000,
    Value2 = LevelID rem 100000,
    FirstNum = Value div 100,
    NewLevel = 1,
    FirstNum * 10000000 + NewLevel * 100000 + Value2.

