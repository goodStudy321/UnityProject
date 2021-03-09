%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%  丹药系统
%%% @end
%%% Created : 22. 七月 2019 10:22
%%%-------------------------------------------------------------------
-module(mod_role_pellet_medicine).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("pellet_medicine.hrl").
-include("mod_role_confine.hrl").
-include("mod_role_pellet_medicine.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    calc/1,               %% 属性统计
    loop_min/2,           %% 分循环
%%    online/1,             %% 上线
    offline/1             %% 下线
]).

-export([handle/2, send/2]).

-export([
    gm_reduce_time/2,
    check_confine_grade/2
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

init(#r_role{role_id = RoleID, role_pellet_medicine = undefined} = State) ->
    RolePelletMedicine = #r_role_pellet_medicine{role_id = RoleID},
    do_pellet_medicine_info(RoleID, State#r_role{role_pellet_medicine = RolePelletMedicine});
init(#r_role{role_id = RoleID} = State) ->
    do_pellet_medicine_info(RoleID, State).

calc(#r_role{role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,

    {BaseAttr1, BaseAttr2} = separate_calc(PelletMedicine),

    mod_role_dict:add_panel_attr(?RECORD_PM_TIME_LIMIT, BaseAttr1),

    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_PELLET_MEDICINE, BaseAttr2).

separate_calc(PelletMedicine) ->
    separate_calc(PelletMedicine, #actor_cal_attr{}, #actor_cal_attr{}).
separate_calc([], ToolAttr1, ToolAttr2) ->
    {ToolAttr1, ToolAttr2};
separate_calc([#r_pellet_medicine{num = 0} | PelletMedicine], ToolAttr1, ToolAttr2) ->
    separate_calc(PelletMedicine, ToolAttr1, ToolAttr2);
separate_calc([#r_pellet_medicine{goods_id = GoodsID, type = ?PELLET_MEDICINE_TYPE} | PelletMedicine], ToolAttr1, ToolAttr2) ->
    #c_pellet_medicine{
        attr1 = Attr1,
        attr2 = Attr2,
        attr3 = Attr3,
        attr4 = Attr4,
        attr5 = Attr5
    } = get_pellet_medicine(GoodsID),

    KVList =
        lists:foldl(fun(Attr, Acc1) ->
            case Attr of
                [] ->
                    Acc1;
                [Key, Val | _] ->
                    [#p_kv{id = Key, val = Val} | Acc1]
            end end, [], [Attr1, Attr2, Attr3, Attr4, Attr5]),

    BaseAttr = common_misc:get_attr_by_kv(KVList),

    separate_calc(PelletMedicine, common_misc:sum_calc_attr([BaseAttr, ToolAttr1]), ToolAttr2);

separate_calc([#r_pellet_medicine{goods_id = GoodsID, num = Count} | PelletMedicine], ToolAttr1, ToolAttr2) ->
    #c_pellet_medicine{
        attr1 = Attr1,
        attr2 = Attr2,
        attr3 = Attr3,
        attr4 = Attr4,
        attr5 = Attr5
    } = get_pellet_medicine(GoodsID),

    KVList =
        lists:foldl(fun(Attr, Acc1) ->
            case Attr of
                [] ->
                    Acc1;
                [Key, Val | _] ->
                    [#p_kv{id = Key, val = Val * Count} | Acc1]
            end end, [], [Attr1, Attr2, Attr3, Attr4, Attr5]),

    BaseAttr = common_misc:get_attr_by_kv(KVList),

    separate_calc(PelletMedicine, ToolAttr1, common_misc:sum_calc_attr([BaseAttr, ToolAttr2])).


%%online(#r_role{role_id = RoleID} = State) ->
%%    do_pellet_medicine_info(RoleID, State).

offline(#r_role{role_id = RoleID, role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,
    case check_time_out(time_tool:now(), PelletMedicine) of
        [_ | _] ->
            State2 = do_pellet_medicine_info(RoleID, State),
            mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_PELLET_MEDICINE_TIME_OUT, 0);
        _ ->
            State
    end.

loop_min(Now, #r_role{role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,
    QuitLists = check_time_out(Now, PelletMedicine),
    lists:foreach(fun({GoodsID, Sec}) ->
        erlang:send_after(Sec * 1000, self(), {mod, ?MODULE, {time_out_quit, GoodsID}}) end, QuitLists),
    State.

handle({#m_role_pellet_medicine_info_tos{}, RoleID, _PID}, State) ->
    do_pellet_medicine_info(RoleID, State);
handle({#m_role_pellet_medicine_use_tos{type_id = TypeID, num = Num}, RoleID, _PID}, State) ->
    do_pellet_medicine_use(TypeID, Num, RoleID, State);
handle({time_out_quit, GoodsID}, State) ->
    do_time_out_quit(GoodsID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc  丹药信息
do_pellet_medicine_info(RoleID, #r_role{role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,

    Now = time_tool:now(),
    Medicine = check_time_limit_pellet_medicine(Now, PelletMedicine),

    NewMedicine = [to_p_pellet_medicine(M) || M <- Medicine],

    DataRecord = #m_role_pellet_medicine_info_toc{medicine = NewMedicine},
    common_misc:unicast(RoleID, DataRecord),
    State#r_role{role_pellet_medicine = RolePelletMedicine#r_role_pellet_medicine{pellet_medicine = Medicine}}.


%% @doc 使用丹药
do_pellet_medicine_use(TypeID, Num, RoleID, State) ->
    case catch check_pellet_medicine_use(TypeID, Num, State) of
        {ok, Medicine, BagDoing, State2} ->
            DataRecord = #m_role_pellet_medicine_use_toc{medicine = [Medicine]},
            common_misc:unicast(RoleID, DataRecord),
            mod_role_bag:do(BagDoing, State2);
        {error, ErrCode} ->
            DataRecord = #m_role_pellet_medicine_use_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_pellet_medicine_use(TypeID, Num, #r_role{role_pellet_medicine = RolePelletMedicine, role_confine = RoleConfine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,
    ?IF(lib_config:find(cfg_pellet_medicine, TypeID) =/= [], ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),

    BagDoing = mod_role_bag:check_num_by_item_list([{TypeID, Num}], ?ITEM_REDUCE_PELLET_MEDICINE, State),

    Now = time_tool:now(),
    #c_pellet_medicine{confine = Confine, type = RetType, effective_time = EffectiveTime, upper_limit = UpperLimit} = get_pellet_medicine(TypeID),
    case lists:keytake(TypeID, #r_pellet_medicine.goods_id, PelletMedicine) of
        {value, #r_pellet_medicine{type = Type, num = Count, stop_time = StopTime} = Tuple, TupleList2} ->
            ?IF(RetType =:= Type, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
            case Type =:= ?PELLET_MEDICINE_TYPE of
                true when StopTime =/= 0 ->
                    Time = erlang:min((StopTime + (EffectiveTime * 60 * Num)) - Now, UpperLimit * ?AN_HOUR),
                    Medicine = Tuple#r_pellet_medicine{num = Count + Num, stop_time = Now + Time},
                    NewPelletMedicine = [Medicine | TupleList2];
                true ->
                    Time = erlang:min(EffectiveTime * 60 * Num, UpperLimit * ?AN_HOUR),
                    Medicine = #r_pellet_medicine{goods_id = TypeID, type = RetType, num = Num, start_time = Now, stop_time = Now + Time},
                    NewPelletMedicine = [Medicine | TupleList2];
                _ ->
                    {_ConfineID, Tote} = check_confine_grade(lib_tool:string_to_intlist(Confine), RoleConfine#r_role_confine.confine),
                    ?IF(Tote =/= 0, ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_UP_003)),
                    ?IF(Tote >= Num + Count, ok, ?THROW_ERR(?ERROR_ROLE_PELLET_MEDICINE_USE_001)),
                    Medicine = Tuple#r_pellet_medicine{num = Count + Num},
                    NewPelletMedicine = [Medicine | TupleList2]
            end;
        _ ->
            case RetType =:= ?PELLET_MEDICINE_TYPE of
                true ->
                    Time = erlang:min(EffectiveTime * 60 * Num, UpperLimit * ?AN_HOUR),
                    Medicine = #r_pellet_medicine{goods_id = TypeID, type = RetType, num = Num, start_time = Now, stop_time = Now + Time},
                    NewPelletMedicine = [Medicine | PelletMedicine];
                _ ->
                    {_ConfineID, Tote} = check_confine_grade(lib_tool:string_to_intlist(Confine), RoleConfine#r_role_confine.confine),
                    ?IF(Tote =/= 0, ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_UP_003)),
                    ?IF(Tote >= Num, ok, ?THROW_ERR(?ERROR_ROLE_PELLET_MEDICINE_USE_001)),
                    Medicine = #r_pellet_medicine{goods_id = TypeID, type = RetType, num = Num, start_time = Now},
                    NewPelletMedicine = [Medicine | PelletMedicine]
            end
    end,

    State2 = State#r_role{role_pellet_medicine = RolePelletMedicine#r_role_pellet_medicine{pellet_medicine = NewPelletMedicine}},
    State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_PELLET_MEDICINE, TypeID),
    {ok, to_p_pellet_medicine(Medicine), BagDoing, State3}.


%% @doc 检测限时的丹药
check_time_limit_pellet_medicine(Now, PelletMedicineLists) ->
    lists:foldl(fun(#r_pellet_medicine{type = Type, stop_time = StopTime} = Medicine, Acc) ->
        case Type =:= ?PELLET_MEDICINE_TYPE of
            true ->
                case StopTime =/= 0 andalso Now >= StopTime of
                    true ->
                        [Medicine#r_pellet_medicine{num = 0, stop_time = 0} | Acc];
                    _ ->
                        [Medicine | Acc]
                end;
            _ ->
                [Medicine | Acc]
        end end, [], PelletMedicineLists).

%% @doc 检测境界等级
check_confine_grade(ConfineLists, ConfineID) ->
    check_confine_grade(ConfineLists, ConfineID, {ConfineID, 0}).
check_confine_grade([], _ConfineID, Sign) ->
    Sign;
check_confine_grade([{RetConfineID, Num} | ConfineLists], ConfineID, Sign) ->
    case RetConfineID < ConfineID of
        true ->
            check_confine_grade(ConfineLists, ConfineID, {RetConfineID, Num});
        _ when RetConfineID =:= ConfineID ->
            {RetConfineID, Num};
        _ ->
            Sign
    end.

%% @doc 检测当前时间结束的限时
check_time_out(Now, PelletMedicine) ->
    check_time_out(PelletMedicine, Now, []).
check_time_out([], _Now, Acc) ->
    Acc;
check_time_out([#r_pellet_medicine{goods_id = GoodsID, type = ?PELLET_MEDICINE_TYPE, stop_time = StopTime} | PelletMedicine], Now, Acc) ->
    {Data, {Hour, Min, Sec1}} = time_tool:timestamp_to_datetime(Now),
    case time_tool:timestamp_to_datetime(StopTime) of
        {Data, {Hour, Min, Sec2}} ->
            check_time_out(PelletMedicine, Now, [{GoodsID, erlang:max(0, Sec2 - Sec1)} | Acc]);
        _ when Now > StopTime andalso StopTime =/= 0 ->
            check_time_out(PelletMedicine, Now, [{GoodsID, 0} | Acc]);
        _ ->
            check_time_out(PelletMedicine, Now, Acc)
    end;
check_time_out([_ | PelletMedicine], Now, Acc) ->
    check_time_out(PelletMedicine, Now, Acc).

%% @doc 限时到时见退出
do_time_out_quit(GoodsID, #r_role{role_id = RoleID, role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,
    DataRecord = #m_role_pellet_medicine_overdue_toc{type_id = GoodsID},
    common_misc:unicast(RoleID, DataRecord),
    Medicine = lists:keyfind(GoodsID, #r_pellet_medicine.goods_id, PelletMedicine),
    NewMedicine = Medicine#r_pellet_medicine{start_time = 0, num = 0, stop_time = 0},
    NewPelletMedicine = lists:keyreplace(GoodsID, #r_pellet_medicine.goods_id, PelletMedicine, NewMedicine),
    NewRolePelletMedicine = RolePelletMedicine#r_role_pellet_medicine{pellet_medicine = NewPelletMedicine},
    State2 = State#r_role{role_pellet_medicine = NewRolePelletMedicine},
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_PELLET_MEDICINE_TIME_OUT, GoodsID).

gm_reduce_time(GoodsID, #r_role{role_id = RoleID, role_pellet_medicine = RolePelletMedicine} = State) ->
    #r_role_pellet_medicine{pellet_medicine = PelletMedicine} = RolePelletMedicine,
    Medicine = #r_pellet_medicine{type = Type} = lists:keyfind(GoodsID, #r_pellet_medicine.goods_id, PelletMedicine),
    ?IF(Type =:= ?PELLET_MEDICINE_TYPE, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    Now = time_tool:now(),
    NewMedicine = Medicine#r_pellet_medicine{stop_time = Now + 70},
    NewPelletMedicine = lists:keyreplace(GoodsID, #r_pellet_medicine.goods_id, PelletMedicine, NewMedicine),
    NewRolePelletMedicine = RolePelletMedicine#r_role_pellet_medicine{pellet_medicine = NewPelletMedicine},
    State2 = State#r_role{role_pellet_medicine = NewRolePelletMedicine},
    do_pellet_medicine_info(RoleID, State2).

to_p_pellet_medicine(PelletMedicine) ->
    #r_pellet_medicine{
        goods_id = GoodsID,
        type = Type,
        num = Num,
        stop_time = StopTime
    } = PelletMedicine,
    #p_pellet_medicine{
        goods_id = GoodsID,
        type = Type,
        num = Num,
        stop_time = StopTime}.


get_pellet_medicine(ID) ->
    [Config] = lib_config:find(cfg_pellet_medicine, ID),
    Config.