%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 秘境探索（挖矿）服务
%%% @end
%%% Created : 27. 七月 2019 12:18
%%%-------------------------------------------------------------------
-module(world_mining_server).
-author("huangxiangrui").
-include("db.hrl").
-include("mining.hrl").
-include("common.hrl").
-include("global.hrl").
-include("activity.hrl").
-include("proto/mod_role_mining.hrl").
-include("proto/world_mining_server.hrl").

%% API
-export([
    i/0,
    init/1,
    start/0,
    start_link/0
]).

-export([
    handle/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).


-export([
    send/1,
    call/1,
    info_mining/1,
    call_mining/1,
    is_mining_server/0,
    round_pos_list/4,
    get_9_pos_list/3,
    in_range/5,
    calc_dir/4
]).

-export([
    send_activity_prepare/0,
    send_activity_start/0,
    send_activity_end/0
]).

-export([
    do_mining_role_info/1,
    gm_reduce_time/1,
    gm_change_seat/1,
    gm_add_plunder/1,
    gm_add_shift/2
]).

-export([
    set_mining_lattice_info/1,
    del_mining_lattice_info/1,
    del_all_mining_lattice_info/0,
    get_all_mining_lattice_info/0,
    get_mining_lattice_info/1,
    set_mining_role_info/1,
    del_mining_role_info/1,
    del_all_mining_role/0,
    get_all_mining_role/0,
    get_mining_role_info/1,
    set_mining_status/1,
    get_mining_status/0,
    call_mining_shift/3,
    send_mining_role_info/1,
    online_info/2,
    call_mining_plunder/2,
    call_mining_inspire/2,
    call_mining_take_out_goods/1,
    send_role_join_family/2,
    send_role_leave_family/2,
    send_update_role_rename/2,
    send_update_role_power/2,
    send_mining_lattice_resetting/1,
    send_mining_gather_end/1
]).

-record(state, {}).

%% @doc 调试打印
i() ->
    [].

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

is_mining_server() ->
    erlang:get(is_mining_server) =:= true.

%% @doc 初始化
init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:put(is_mining_server, true),
    time_tool:reg(world, [1000, 0]),
    ?TRY_CATCH(do_init_loop_lattices()),
    {ok, #state{}}.

handle(Info) ->
    do_handle(Info).

%% @doc handle_call回调函数
handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

%% @doc handle_cast回调函数
handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @doc handle_info回调函数
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @doc terminate回调函数
terminate(_Reason, _State) ->
    ok.

%% @doc code_change回调函数
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% @doc 活动准备
send_activity_prepare() ->
    info_mining(activity_prepare).
%% @doc 活动开始
send_activity_start() ->
    info_mining(activity_start).
%% @doc 活动开始
send_activity_end() ->
    info_mining(activity_end).
%% @doc 采集时间结束
send_mining_gather_end(RoleID) ->
    info_mining({mining_gather_end, RoleID}).
%% @doc 格子重置时间结束
send_mining_lattice_resetting(Pos) ->
    info_mining({mining_lattice_resetting, Pos}).
%% @doc 移动
call_mining_shift(NewX, NewY, RoleID) ->
    call_mining({mining_shift, NewX, NewY, RoleID}).
%% @doc 发送九宫格玩家信息
send_mining_role_info(MiningRole) ->
    info_mining({mining_role_info, MiningRole}).
online_info(RoleID, Power) ->
    info_mining({online_info, RoleID, Power}).
%% @doc 掠夺
call_mining_plunder(RoleID, ObjectID) ->
    call_mining({mining_plunder, RoleID, ObjectID}).
%% @doc 鼓舞
call_mining_inspire(RoleID, Power) ->
    call_mining({mining_inspire, RoleID, Power}).
%% @doc 获取出资源
call_mining_take_out_goods(RoleID) ->
    call_mining({mining_take_out_goods, RoleID}).
%% @doc 角色加入公会
send_role_join_family(RoleID, FamilyID) ->
    info_mining({role_join_family, RoleID, FamilyID}).
%% @doc 角色脱离入公会
send_role_leave_family(RoleID, FamilyID) ->
    info_mining({role_leave_family, RoleID, FamilyID}).
%% @doc 角色修改名字
send_update_role_rename(RoleID, RoleName) ->
    info_mining({update_role_rename, RoleID, RoleName}).
%% @doc 更新最大战力
send_update_role_power(RoleID, MaxPower) ->
    info_mining({update_role_power, RoleID, MaxPower}).

gm_reduce_time(RoleID) ->
    info_mining({gm_reduce_time, RoleID}).
gm_change_seat(RoleID) ->
    info_mining({gm_change_seat, RoleID}).
gm_add_plunder(RoleID) ->
    info_mining({gm_add_plunder, RoleID}).
gm_add_shift(RoleID, AddNum) ->
    info_mining({gm_add_shift, RoleID, AddNum}).

do_handle({gm_reduce_time, RoleID}) ->
    do_gm_reduce_time(RoleID);
do_handle({gm_change_seat, RoleID}) ->
    do_gm_change_seat(RoleID);
do_handle({gm_add_plunder, RoleID}) ->
    do_gm_add_plunder(RoleID);
do_handle({gm_add_shift, RoleID, AddNum}) ->
    do_gm_add_shift(RoleID, AddNum);
do_handle({update_role_power, RoleID, MaxPower}) ->
    do_update_role_power(RoleID, MaxPower);
do_handle({update_role_rename, RoleID, RoleName}) ->
    do_update_role_rename(RoleID, RoleName);
do_handle({role_leave_family, RoleID, FamilyID}) ->
    do_role_leave_family(RoleID, FamilyID);
do_handle({role_join_family, RoleID, FamilyID}) ->
    do_role_join_family(RoleID, FamilyID);
do_handle({mining_take_out_goods, RoleID}) ->
    do_mining_take_out_goods(RoleID);
do_handle({mining_inspire, RoleID, Power}) ->
    do_mining_inspire(RoleID, Power);
do_handle({mining_plunder, RoleID, ObjectID}) ->
    do_mining_plunder(RoleID, ObjectID);
do_handle({mining_role_info, MiningRole}) ->
    do_mining_role_info(MiningRole);
do_handle({online_info, RoleID, Power}) ->
    do_online_info(RoleID, Power);
do_handle({mining_shift, NewX, NewY, RoleID}) ->
    do_mining_shift(NewX, NewY, RoleID);
do_handle({mining_lattice_resetting, Pos}) ->
    do_mining_lattice_resetting(Pos);
do_handle({mining_gather_end, RoleID}) ->
    do_mining_gather_end(RoleID);
do_handle(activity_prepare) ->
    do_activity_prepare();
do_handle(activity_start) ->
    do_activity_start();
do_handle(activity_end) ->
    do_activity_end();
%% @doc mod调用
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
%% @doc 用参数调用模块的函数
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
%% @doc 调用函数
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
%% @doc 秒循环
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
%% @doc 零点
do_handle(?TIME_ZERO) ->
    do_zeroclock(),
    ok;
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

send(Msg) ->
    info_mining({mod, ?MODULE, Msg}).
call(Msg) ->
    call_mining({mod, ?MODULE, Msg}).

info_mining(Info) ->
    case is_mining_server() of
        true ->
            handle(Info);
        _ ->
            pname_server:send(?MODULE, Info)
    end.

call_mining(Info) ->
    case is_mining_server() of
        true ->
            handle(Info);
        _ ->
            pname_server:call(?MODULE, Info)
    end.

do_init_loop_lattices() ->
    PosList = [ Pos|| #r_mining_lattice{pos = Pos, mining_role_id = MiningRoleID, renovate_time = RenovateTime} <- get_all_mining_lattice_info(),
        ?IS_ROLE_MINING(MiningRoleID) orelse RenovateTime =/= 0],
    set_loop_lattices(PosList).

do_loop(Now) ->
    do_loop_check_data(Now),
    do_loop_check_activity(Now).

do_zeroclock() ->
    Num = common_misc:get_global_int(?GLOBAL_MINING_SHIFT_NUM),
    AllList = get_all_mining_lattice_info(),
    lists:foreach(
        fun(#r_mining_lattice{mining_role_id = MiningRoleID} = MiningLattice) ->
            case ?IS_ROLE_MINING(MiningRoleID) of
                true ->
                    #r_mining_role{shift_num = ShiftNum} = MiningRole = get_mining_role_info(MiningRoleID),
                    MiningRole2 = MiningRole#r_mining_role{shift_num = ShiftNum + Num, inspire = 0},
                    set_mining_role_info(MiningRole2),
                    update_role_mining(MiningRole2, [?UPDATE_SHIFT]),
                    common_misc:unicast(MiningRoleID, #m_role_mining_inspire_toc{inspire = 0, type = ?INSPIRE_UPDATE_TYPE_RESET}),
                    update_mining_lattice(MiningLattice);
                _ ->
                    ok
            end
        end, AllList).

%% @doc 活动准备
do_activity_prepare() ->
    #r_mining_status{status = Status} = MiningStatus = get_mining_status(),
    case Status =:= ?STATUS_CLOSE of
        true ->
            set_mining_status(MiningStatus#r_mining_status{status = ?STATUS_PREPARE, stop_time = 0}),
            del_all_mining_role(),
            del_all_mining_lattice_info(),
            set_loop_lattices([]),
            AllList = [{Chance, ID} || {ID, #c_mining_lattice{chance = Chance}} <- lib_config:list(cfg_mining_lattice), Chance > 0],
            [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
            lists:foreach(fun(Y) ->
                lists:foreach(fun(X) ->
                    TypeID = lib_tool:get_weight_output(AllList),
                    #c_mining_lattice{id = TypeID, collection_num = GatherNum} = get_mining_lattice(TypeID),
                    MiningLattice = #r_mining_lattice{pos = {X, Y}, type_id = TypeID, gather_num = GatherNum},
                    set_mining_lattice_info(MiningLattice) end, lists:seq(1, WidthX)) end, lists:seq(1, HeightY));
        _ ->
            ?NONE
    end.

%% @doc 活动开始
do_activity_start() ->
    #r_mining_status{status = Status} = MiningStatus = get_mining_status(),
    case Status =:= ?STATUS_PREPARE of
        true ->
            set_mining_status(MiningStatus#r_mining_status{status = ?STATUS_OPEN});
        _ ->
            ?NONE
    end.

%% @doc 活动结束
do_activity_end() ->
    New = time_tool:now(),
    #r_mining_status{status = Status, stop_time = StopTime} = MiningStatus = get_mining_status(),
    case Status =:= ?STATUS_OPEN orelse (StopTime > 0 andalso New >= StopTime) of
        true ->
            AllList = get_all_mining_lattice_info(),
            lists:foreach(
                fun(#r_mining_lattice{type_id = TypeID, mining_role_id = MiningRoleID}) ->
                    case MiningRoleID =/= undefined of
                        true ->
                            #r_mining_role{gather_num = RoleGatherNum, goods_list = GoodsList} = get_mining_role_info(MiningRoleID),
                            #c_mining_lattice{type = Type, resource = Resource} = get_mining_lattice(TypeID),
                            NewGoodsList =
                                case Type =:= ?MINING_TYPE_PLAIN of
                                    true when RoleGatherNum > 0 ->
                                        get_gather_goods(GoodsList, lib_tool:string_to_intlist(Resource), RoleGatherNum + 1);
                                    _ ->
                                        GoodsList
                                end,
                            case NewGoodsList of
                                [_|_] ->
                                    FromLetterInfo = #r_letter_info{
                                        template_id = ?LETTER_MINING_REWARD,
                                        goods_list = [#p_goods{type_id = GoodsID, num = Consume} || #p_kv{id = GoodsID, val = Consume} <- NewGoodsList],
                                        action = ?ITEM_GAIN_MINING_GOODS
                                    },
                                    common_letter:send_letter(MiningRoleID, FromLetterInfo);
                                _ ->
                                    ?NONE
                            end;
                        _ ->
                            ok
                    end
                end, AllList),
            del_all_mining_role(),
            del_all_mining_lattice_info(),
            set_loop_lattices([]),
            set_mining_status(MiningStatus#r_mining_status{status = ?STATUS_CLOSE});
        _ ->
            ?NONE
    end.

%% 前端请求玩家信息
do_mining_role_info(MiningRole) ->
    #r_mining_status{status = Status} = get_mining_status(),
    #r_mining_role{role_id = RoleID} = MiningRole,
    case Status =:= ?STATUS_OPEN of
        true ->
            case get_mining_role_info(RoleID) of
                #r_mining_role{} = MiningRoleT ->
                    do_send_role_info(MiningRoleT);
                _ ->
                    case catch enter_mining_lattice(MiningRole) of
                        #r_mining_role{} = MiningRoleT ->
                            do_send_role_info(MiningRoleT);
                        _ ->
                            DataRecord = #m_mining_role_info_toc{err_code = ?ERROR_MINING_ROLE_INFO_002},
                            common_misc:unicast(RoleID, DataRecord)
                    end
            end;
        _ ->
            DataRecord = #m_mining_role_info_toc{err_code = ?ERROR_MINING_ROLE_INFO_001},
            common_misc:unicast(RoleID, DataRecord)
    end.

do_online_info(RoleID, Power) ->
    case get_mining_role_info(RoleID) of
        #r_mining_role{} = MiningRole ->
            #r_mining_status{status = Status} = get_mining_status(),
            case Status =:= ?STATUS_OPEN of
                true ->
                    MiningRole2 = MiningRole#r_mining_role{power = Power},
                    set_mining_role_info(MiningRole2),
                    do_send_role_info(MiningRole2);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

do_send_role_info(RMiningRole) ->
    #r_mining_role{
        role_id = RoleID,
        pos = Pos,
        gather_num = GatherNum,
        gather_stop = GatherStop,
        shift_num = ShiftNum,
        inspire = Inspire,
        shift_history = ShiftHistory,
        plunder_history = PlunderHistory,
        goods_list = GoodsList} = RMiningRole,
    RetShiftHistory = [
        begin
            #r_mining_lattice{type_id = TypeID, gather_num = LatticeGatherNum} = get_mining_lattice_info({X, Y}),
            #p_mining_shift{x = X, y = Y, type_id = TypeID, surplus_num = LatticeGatherNum}
        end || {X, Y} <- ShiftHistory],

    [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
    MiningLattices =
        lists:foldl(
            fun({X, Y}, Acc) ->
                MiningLattice = get_mining_lattice_info({X, Y}),
                [to_p_mining_lattice(MiningLattice)|Acc]
            end, [], get_9_pos_list(Pos, WidthX, HeightY)),

    DataRecord = #m_mining_role_info_toc{
        gather_num = GatherNum,
        gather_stop_time = GatherStop,
        shift_num = ShiftNum,
        inspire = Inspire,
        shift_history = RetShiftHistory,
        plunder_history = PlunderHistory,
        goods_list = GoodsList,
        lattice_list = MiningLattices
    },
    common_misc:unicast(RoleID, DataRecord).

%% @doc 分配格子
enter_mining_lattice(MiningRole) ->
    AllInfo = get_all_mining_lattice_info(),
    FirstPosList = [Pos || #r_mining_lattice{pos = Pos, gather_num = GatherNum, mining_role_id = MiningRoleID} <- AllInfo, GatherNum =/= 0, not ?IS_ROLE_MINING(MiningRoleID)],
    case FirstPosList =/= [] of
        true -> %% 优先获取有采集数量的
            Pos = lib_tool:random_element_from_list(FirstPosList),
            enter_mining_lattice2(MiningRole, Pos);
        _ -> %%
            SecondPosList = [Pos || #r_mining_lattice{pos = Pos, mining_role_id = MiningRoleID} <- AllInfo, not ?IS_ROLE_MINING(MiningRoleID)],
            case SecondPosList =/= [] of
                true ->
                    Pos = lib_tool:random_element_from_list(SecondPosList),
                    enter_mining_lattice2(MiningRole, Pos);
                _ ->
                    ?ERROR_MSG("remain 0"),
                    erlang:throw(empty_lattice)
            end
    end.

enter_mining_lattice2(MiningRole, Pos) ->
    #r_mining_role{role_id = RoleID, family_id = FamilyID, inspire = Inspire, power = RolePower} = MiningRole,
    Now = time_tool:now(),
    ShiftNum = common_misc:get_global_int(?GLOBAL_MINING_START_NUM),
    NewRolePower = get_inspire_power(RolePower, Inspire),
    #r_mining_lattice{type_id = TypeID, gather_num = GatherNum} = MiningLattice = get_mining_lattice_info(Pos),
    {IsFamilyAdd, GatherStop} =
        case GatherNum > 0 of
            true ->
                {IsFamilyAddT, GatherStopT} = get_gather_stop_time(RoleID, TypeID, NewRolePower, FamilyID, Pos, Now),
                get_mining_role_log(RoleID, TypeID, GatherStopT - Now, Pos, ShiftNum, NewRolePower),
                {IsFamilyAddT, GatherStopT};
            _ ->
                {false, 0}
        end,
    NewMiningRole = MiningRole#r_mining_role{
        pos = Pos,
        shift_num = ShiftNum,
        gather_stop = GatherStop,
        is_family_add = IsFamilyAdd
    },
    set_mining_lattice_info(MiningLattice#r_mining_lattice{mining_role_id = RoleID}),
    add_loop_lattice(Pos),
    set_mining_role_info(NewMiningRole),
    NewMiningRole.

%% @doc 检查
do_loop_check_data(Now) ->
    case get_mining_status() of
        #r_mining_status{status = ?STATUS_OPEN} ->
            PosList = get_loop_lattices(),
            lists:foreach(
                fun(Pos) ->
                    #r_mining_lattice{
                        gather_num = GatherNum,
                        renovate_time = RenovateTime,
                        mining_role_id = MiningRoleID} = MiningLattice = get_mining_lattice_info(Pos),
                    case GatherNum > 0 of
                        true ->
                            case ?IS_ROLE_MINING(MiningRoleID) of
                                true -> %% 检查是否可以发放奖励
                                    #r_mining_role{gather_stop = GatherStop} = get_mining_role_info(MiningRoleID),
                                    ?IF(Now >= GatherStop, do_mining_gather_end(MiningRoleID, Now), ok);
                                _ ->
                                    del_loop_lattice(Pos)
                            end;
                        _ when RenovateTime =/= 0 andalso Now >= RenovateTime ->
                            do_mining_lattice_resetting(MiningLattice, Now);
                        _ ->
                            ?NONE
                    end
                end, PosList);
        _ ->
            ?NONE
    end.

do_loop_check_activity(Now) ->
    #r_mining_status{status = Status, stop_time = StopTime} = MiningStatus = get_mining_status(),
    if
        Status =:= ?STATUS_OPEN andalso StopTime > 0 andalso Now >= StopTime ->
            do_activity_end();
        Status =:= ?STATUS_OPEN andalso StopTime =:= 0 ->
            [Config] = lib_config:find(cfg_activity, ?ACTIVITY_LATTICE_MINING),
            #c_activity{day_list = [WeekDay | _], last_time = LastTime, time_list = TimeString} = Config,
            [{Hour, Min} | _] =
                [begin
                     [Hour1, Min1] = string:tokens(TimeString2, ","),
                     {lib_tool:to_integer(Hour1), lib_tool:to_integer(Min1)}
                 end || TimeString2 <- string:tokens(TimeString, ";")],

            StartTime = time_tool:weekday_timestamp(WeekDay, Hour, Min),
            if
                StartTime =< Now andalso (Now - StartTime < LastTime) ->
                    StopTime1 = Now + 15 + (LastTime - (Now - StartTime)),
                    set_mining_status(MiningStatus#r_mining_status{stop_time = StopTime1});
                true ->
                    ?NONE
            end;
        true ->
            ?NONE
    end.

%% 单次采集结束
do_mining_gather_end(RoleID) ->
    case get_mining_status() of
        #r_mining_status{status = ?STATUS_OPEN} ->
            Now = time_tool:now(),
            do_mining_gather_end(RoleID, Now);
        _ ->
            ok
    end.
do_mining_gather_end(RoleID, Now) ->
    #r_mining_role{
        pos = Pos,
        gather_num = RoleGatherNum,
        power = RolePower,
        shift_num = ShiftNum,
        family_id = FamilyID,
        inspire = Inspire,
        goods_list = GoodsList} = MiningRole = get_mining_role_info(RoleID),
    #r_mining_lattice{
        type_id = TypeID,
        gather_num = LatticeGatherNum,
        gather_history = GatherHistory} = MiningLattice = get_mining_lattice_info(Pos),
    [{Chance}, _ | _] = common_misc:get_global_string_list(?GLOBAL_MINING_MINING_INSPIRE),
    NewRolePower = (RolePower + (lib_tool:ceil((Chance / 100) * RolePower) * Inspire)),

    LatticeGatherNum2 = LatticeGatherNum - 1,
    RoleGatherNum2 = RoleGatherNum + 1,
    case LatticeGatherNum2 =< 0 of
        true -> %% 采集结束
            #c_mining_lattice{resource = Resource} = get_mining_lattice(TypeID),
            NewGoodsList = get_gather_goods(GoodsList, lib_tool:string_to_intlist(Resource), RoleGatherNum2),
            BreakTime = common_misc:get_global_int(?GLOBAL_MINING_LATTICE_RENOVATE),

            NewMiningRole = MiningRole#r_mining_role{
                gather_stop = 0,
                gather_num = RoleGatherNum + 1,
                shift_num = ShiftNum + 1,
                goods_list = NewGoodsList,
                is_family_add = false},
            MiningLattice2 = MiningLattice#r_mining_lattice{
                gather_num = LatticeGatherNum2,
                renovate_time = BreakTime + Now,
                gather_history = get_max_gather([{RoleID, TypeID} | GatherHistory])},
            set_mining_role_info(NewMiningRole),
            get_mining_role_log(RoleID, TypeID, 0, RoleGatherNum2, ShiftNum + 1, NewRolePower, Pos),
            set_mining_lattice_info(MiningLattice2),
            update_role_mining(NewMiningRole, [?UPDATE_GATHER, ?UPDATE_SHIFT, ?UPDATE_GOODS]),
            update_mining_lattice(MiningLattice2);
        _ ->
            {IsFamilyAdd, GatherStop} = get_gather_stop_time(RoleID, TypeID, NewRolePower, FamilyID, Pos, Now),
            NewMiningRole = MiningRole#r_mining_role{
                gather_stop = GatherStop,
                gather_num = RoleGatherNum2,
                is_family_add = IsFamilyAdd
            },
            MiningLattice2 = MiningLattice#r_mining_lattice{gather_num = LatticeGatherNum2},
            set_mining_role_info(NewMiningRole),
            set_mining_lattice_info(MiningLattice2),
            get_mining_role_log(RoleID, TypeID, GatherStop - Now, RoleGatherNum2, ShiftNum, NewRolePower, Pos),
            update_role_mining(NewMiningRole, [?UPDATE_GATHER]),
            update_mining_lattice(MiningLattice2)
    end.

%% @doc 格子重置时间结束
do_mining_lattice_resetting(Pos) ->
    case get_mining_status() of
        #r_mining_status{status = ?STATUS_OPEN} ->
            Now = time_tool:now(),
            do_mining_lattice_resetting(get_mining_lattice_info(Pos), Now);
        _ ->
            ok
    end.
do_mining_lattice_resetting(MiningLattice, Now) ->
    #r_mining_lattice{pos = Pos, mining_role_id = MiningRoleID} = MiningLattice,
    TypeID = get_new_lattice_type_id(),
    #c_mining_lattice{collection_num = GatherNum} = get_mining_lattice(TypeID),
    MiningLattice2 = MiningLattice#r_mining_lattice{type_id = TypeID, gather_num = GatherNum, renovate_time = 0},
    set_mining_lattice_info(MiningLattice2),
    case ?IS_ROLE_MINING(MiningRoleID) of
        true ->
            #r_mining_role{
                power = RolePower,
                family_id = FamilyID,
                inspire = Inspire,
                role_id = RoleID,
                shift_num = ShiftNum} = MiningRole = get_mining_role_info(MiningRoleID),
            NewRolePower = get_inspire_power(RolePower, Inspire),
            {IsFamilyAdd, GatherStop} = get_gather_stop_time(RoleID, TypeID, NewRolePower, FamilyID, Pos, Now),

            MiningRole2 = MiningRole#r_mining_role{
                gather_stop = GatherStop,
                gather_num = 0,
                is_family_add = IsFamilyAdd
            },
            set_mining_role_info(MiningRole2),
            get_mining_role_log(RoleID, TypeID, GatherStop - Now, GatherNum + 1, ShiftNum + 1, NewRolePower, Pos),
            update_role_mining(MiningRole2, [?UPDATE_GATHER]);
        _ -> %% 恢复的时候，没人在这采集
            del_loop_lattice(Pos)
    end,
    update_mining_lattice(MiningLattice2).


%% @doc 移动
do_mining_shift(NewX, NewY, RoleID) ->
    case catch check_mining_shift(NewX, NewY, RoleID) of
        {ok, MiningRole, UpdateList, UpdateShifts, OldMiningLattice, NewMiningLattice} ->
            set_mining_role_info(MiningRole),
            set_mining_lattice_info(OldMiningLattice),
            set_mining_lattice_info(NewMiningLattice),
            update_role_mining(MiningRole, UpdateList),
            update_role_shift(RoleID, UpdateShifts),
            update_mining_lattice(OldMiningLattice, [RoleID]),
            update_mining_lattice(NewMiningLattice, [RoleID]),
            update_9_lattice(RoleID, {NewX, NewY}),
            add_loop_lattice({NewX, NewY}),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_mining_shift(NewX, NewY, RoleID) ->
    #r_mining_status{status = Status} = get_mining_status(),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),
    MiningRole = get_mining_role_info(RoleID),
    ?IF(MiningRole =/= ?NULL, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),

    #r_mining_role{
        power = RolePower,
        inspire = Inspire,
        family_id = FamilyID,
        shift_num = ShiftNum,
        pos = Pos = {X, Y},
        shift_history = ShiftHistory,
        gather_num = RoleGatherNum,
        goods_list = GoodsList} = MiningRole,
    ?IF(ets:member(?DB_MINING_LATTICE_P, Pos), ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),
    ?IF(ShiftNum > 0, ok, ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_002)),
    [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
    ?IF(in_range(X, Y, NewX, NewY, [WidthX, HeightY]), ok, ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_001)),
    NewPos = {NewX, NewY},
    #r_mining_lattice{
        type_id = NewTypeID,
        mining_role_id = MiningRoleID,
        gather_num = NewGatherNum} = NewMiningLattice = get_mining_lattice_info(NewPos),
    ?IF(?IS_ROLE_MINING(MiningRoleID), ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_003), ok),
    ?IF(lists:member(calc_dir(X, Y, NewX, NewY), ?TODAY_APPLY), ok, ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_001)),
    #r_mining_lattice{
        gather_num = GatherNum,
        type_id = OldTypeID,
        gather_history = OldGatherHistory
    } = OldMiningLattice = get_mining_lattice_info(Pos),
    #c_mining_lattice{resource = OldResource} = get_mining_lattice(OldTypeID),
    Now = time_tool:now(),
    NewRolePower = get_inspire_power(RolePower, Inspire),
    {UpdateList1, NewGoodsList} =
        case GatherNum > 0 andalso RoleGatherNum > 0 of
            true ->
                GoodsListT = get_gather_goods(GoodsList, lib_tool:string_to_intlist(OldResource), RoleGatherNum),
                {[?UPDATE_GOODS], GoodsListT};
            _ ->
                {[], GoodsList}
        end,
    {UpdateList2, {IsFamilyAdd, GatherStop}, ShiftNum2} =
        case NewGatherNum > 0 of
            true ->
                {[?UPDATE_GATHER, ?UPDATE_SHIFT] ++ UpdateList1, get_gather_stop_time(RoleID, NewTypeID, NewRolePower, FamilyID, NewPos, Now), ShiftNum - 1};
            _ ->
                {[?UPDATE_GATHER|UpdateList1], {false, 0}, ShiftNum}
        end,
    UpdateShifts = get_9_pos_list(Pos) -- ShiftHistory,
    MiningRole2 = MiningRole#r_mining_role{
        shift_num = ShiftNum2,
        pos = NewPos,
        shift_history = UpdateShifts ++ ShiftHistory,
        gather_num = 0,
        gather_stop = GatherStop,
        goods_list = NewGoodsList,
        is_family_add = IsFamilyAdd
    },
    OldMiningLattice2 =  OldMiningLattice#r_mining_lattice{mining_role_id = ?UNDEFINED, gather_history = get_max_gather([{RoleID, OldTypeID} | OldGatherHistory])},
    NewMiningLattice2 = NewMiningLattice#r_mining_lattice{mining_role_id = RoleID},
    ?TRY_CATCH(do_shift_log(RoleID, ShiftNum2, NewTypeID, ?IF(GatherStop > 0, GatherStop, GatherStop - Now), NewRolePower, NewPos, Pos)),
    {ok, MiningRole2, UpdateList2, UpdateShifts, OldMiningLattice2, NewMiningLattice2}.

%% @doc 掠夺
do_mining_plunder(RoleID, ObjectID) ->
    case catch check_mining_plunder(RoleID, ObjectID) of
        {ok, ?MINING_PLUNDER_SUCCESS, MiningRole, UpdateList, UpdateShifts1, ObjectMiningRole, UpdateList2, UpdateShifts2,
            OldMiningLattice, NewMiningLattice, LetterInfo, AddHistory} ->
            set_mining_role_info(MiningRole),
            set_mining_role_info(ObjectMiningRole),
            set_mining_lattice_info(OldMiningLattice),
            set_mining_lattice_info(NewMiningLattice),
            update_role_shift(RoleID, UpdateShifts1),
            update_role_shift(ObjectID, UpdateShifts2),
            update_role_mining(MiningRole, UpdateList),
            update_role_mining(ObjectMiningRole, UpdateList2),
            update_mining_lattice(OldMiningLattice, [RoleID, ObjectID]),
            update_mining_lattice(NewMiningLattice, [RoleID, ObjectID]),
            update_9_lattice(RoleID, NewMiningLattice#r_mining_lattice.pos),
            update_9_lattice(ObjectID, OldMiningLattice#r_mining_lattice.pos),
            common_letter:send_letter(ObjectID, LetterInfo),
            common_misc:unicast(ObjectID, #m_world_mining_plunder_update_toc{add_plunder_history = AddHistory}),
            {ok, ?MINING_PLUNDER_SUCCESS, MiningRole#r_mining_role.shift_num};
        {ok, ?MINING_PLUNDER_FAIL, MiningRole2} ->
            set_mining_role_info(MiningRole2),
            {ok,?MINING_PLUNDER_FAIL, MiningRole2#r_mining_role.shift_num};
        {error, ErrCode} ->
            ErrCode
    end.

check_mining_plunder(RoleID, ObjectID) ->
    #r_mining_status{status = Status} = get_mining_status(),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),
    MiningRole = get_mining_role_info(RoleID),
    ?IF(MiningRole =/= ?NULL, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),
    #r_mining_role{plunder_history = PlunderHistory} = ObjectMiningRole = get_mining_role_info(ObjectID),
    ?IF(ObjectMiningRole =/= ?NULL, ok, ?THROW_ERR(?ERROR_ROLE_MINING_PLUNDER_001)),
    #r_mining_role{pos = Pos = {X0, Y0}, shift_num = ShiftNum, inspire = Inspire, power = RolePower, role_name = RoleName} = MiningRole,
    #r_mining_role{pos = ObjPos = {X, Y}, power = ObjRolePower, inspire = ObjInspire} = ObjectMiningRole,

    ?IF(ShiftNum > 0, ok, ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_002)),
    [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
    ?IF(in_range(X0, Y0, X, Y, [WidthX, HeightY]), ok, ?THROW_ERR(?ERROR_ROLE_MINING_PLUNDER_002)),
    ?IF(lists:member(calc_dir(X0, Y0, X, Y), ?TODAY_APPLY), ok, ?THROW_ERR(?ERROR_ROLE_MINING_SHIFT_001)),
    NewRolePower = get_inspire_power(RolePower, Inspire),
    NewObjRolePower = get_inspire_power(ObjRolePower, ObjInspire),
    #r_mining_lattice{type_id = OldTypeID, gather_history = OldGatherHistory} = OldMiningLattice = get_mining_lattice_info(Pos),
    #r_mining_lattice{type_id = NewTypeID, gather_history = NewGatherHistory} = NewMiningLattice = get_mining_lattice_info(ObjPos),
    Now = time_tool:now(),
    case NewRolePower >= NewObjRolePower of
        true -> %% 掠夺成功，各自结算，互换位置
            {MiningRole2, UpdateList, UpdateShifts1} = check_mining_plunder2(MiningRole, Now, NewRolePower, OldMiningLattice, NewMiningLattice, true),
            {ObjectMiningRole2, UpdateList2, UpdateShifts2} = check_mining_plunder2(ObjectMiningRole, Now, NewObjRolePower, NewMiningLattice, OldMiningLattice, false),
            OldMiningLattice2 = OldMiningLattice#r_mining_lattice{mining_role_id = ObjectID, gather_history = get_max_gather([{RoleID, OldTypeID}|OldGatherHistory])},
            NewMiningLattice2 = NewMiningLattice#r_mining_lattice{mining_role_id = RoleID, gather_history = get_max_gather([{ObjectID, NewTypeID}|NewGatherHistory])},
            #r_mining_role{gather_stop = GatherStop} = MiningRole2,
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_MINING_PLUNDER,
                text_string = [RoleName]
            },
            AddHistory = #p_ks{id = Now, str = RoleName},
            ObjectMiningRole3 = ObjectMiningRole2#r_mining_role{plunder_history = [AddHistory|PlunderHistory]},
            get_mining_role_log(RoleID, ShiftNum - 1, NewTypeID, ?IF(GatherStop > 0, GatherStop - 1, 0), ObjectID, NewRolePower, NewObjRolePower, 1, {X, Y}, Pos),
            {ok, ?MINING_PLUNDER_SUCCESS, MiningRole2, UpdateList, UpdateShifts1, ObjectMiningRole3, UpdateList2, UpdateShifts2,
                OldMiningLattice2, NewMiningLattice2, LetterInfo, AddHistory};
        _ ->
            MiningRole2 = MiningRole#r_mining_role{shift_num = ShiftNum - 1},
            get_mining_role_log(RoleID, ShiftNum - 1, OldTypeID, 0 , ObjectID, NewRolePower, NewObjRolePower, 2, {X, Y}, Pos),
            {ok, ?MINING_PLUNDER_FAIL, MiningRole2}
    end.

check_mining_plunder2(MiningRole, Now, NewRolePower, FromMiningLattice, ToMiningLattice, IsSrc) ->
    #r_mining_role{
        role_id = RoleID,
        shift_num = ShiftNum,
        gather_num = RoleGatherNum,
        goods_list = GoodsList,
        shift_history = ShiftHistory,
        family_id = FamilyID} = MiningRole,
    #r_mining_lattice{pos = FromPos, gather_num = GatherNum, type_id = OldTypeID} = FromMiningLattice,
    #r_mining_lattice{
        pos = ToPos,
        type_id = NewTypeID,
        gather_num = ToGatherNum} = ToMiningLattice,
    #c_mining_lattice{resource = OldResource} = get_mining_lattice(OldTypeID),
    {UpdateList1, NewGoodsList} =
        if
            GatherNum > 0 andalso RoleGatherNum > 0 ->
                GoodsListT = get_gather_goods(GoodsList, lib_tool:string_to_intlist(OldResource), RoleGatherNum),
                {[?UPDATE_GOODS], GoodsListT};
            true ->
                {[], GoodsList}
        end,
    ShiftNum2 =
        if
            IsSrc -> %% 发起者
                ShiftNum - 1;
            ToGatherNum =< 0 -> %% 被掠夺者
                ShiftNum + 1;
            true -> %% 被掠夺者
                ShiftNum
        end,
    UpdateList2 = ?IF(ShiftNum =/= ShiftNum2, [?UPDATE_SHIFT|UpdateList1], UpdateList1),
    {IsFamilyAdd, GatherStop} = ?IF(ToGatherNum > 0, get_gather_stop_time(RoleID, NewTypeID, NewRolePower, FamilyID, ToPos, Now), {false, 0}),
    UpdateList = [?UPDATE_GATHER|UpdateList2],
    UpdateShifts = get_9_pos_list(FromPos) -- ShiftHistory,
    MiningRole2 = MiningRole#r_mining_role{
        shift_num = ShiftNum2,
        pos = ToPos,
        shift_history = UpdateShifts ++ ShiftHistory,
        gather_num = 0,
        gather_stop = GatherStop,
        goods_list = NewGoodsList,
        is_family_add = IsFamilyAdd
    },
    {MiningRole2, UpdateList, UpdateShifts}.

%% @doc 鼓舞
do_mining_inspire(RoleID, Power) ->
    case catch check_mining_inspire(RoleID, Power) of
        {ok, Inspire, MiningLattice, ObjLatticeRole} ->
            set_mining_role_info(ObjLatticeRole),
            update_mining_lattice(MiningLattice),
            {ok, Inspire};
        {error, ErrCode} ->
            ErrCode
    end.

check_mining_inspire(RoleID, Power) ->
    #r_mining_status{status = Status} = get_mining_status(),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),

    ObjLatticeRole = get_mining_role_info(RoleID),
    ?IF(ObjLatticeRole =/= ?NULL, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),

    #r_mining_role{inspire = Inspire, pos = Pos} = ObjLatticeRole,
    [_Chance, {MaxInspire} | _] = common_misc:get_global_string_list(?GLOBAL_MINING_MINING_INSPIRE),
    ?IF(MaxInspire > Inspire, ok, ?THROW_ERR(?ERROR_ROLE_MINING_INSPIRE_001)),
    MiningLattice = get_mining_lattice_info(Pos),
    {ok, Inspire + 1, MiningLattice, ObjLatticeRole#r_mining_role{inspire = Inspire + 1, power = Power}}.

%% @doc 获取出资源
do_mining_take_out_goods(RoleID) ->
    case catch check_mining_take_out_goods(RoleID) of
        {ok, PGoodsList, ObjLatticeRole} ->
            set_mining_role_info(ObjLatticeRole),
            {ok, PGoodsList};
        {error, ErrCode} ->
            ErrCode
    end.

check_mining_take_out_goods(RoleID) ->
    #r_mining_status{status = Status} = get_mining_status(),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),

    ObjLatticeRole = get_mining_role_info(RoleID),
    ?IF(ObjLatticeRole =/= ?NULL, ok, ?THROW_ERR(?ERROR_MINING_ROLE_INFO_001)),

    #r_mining_role{goods_list = GoodsList} = ObjLatticeRole,
    ?IF(GoodsList =/= [], ok, ?THROW_ERR(?ERROR_ROLE_MINING_TAKE_OUT_GOODS_001)),

    PGoodsList = [#p_goods{type_id = GoodsID, num = Count} || #p_kv{id = GoodsID, val = Count} <- GoodsList],

    {ok, PGoodsList, ObjLatticeRole#r_mining_role{goods_list = []}}.

%% @doc 角色加入公会
do_role_join_family(RoleID, FamilyID) ->
    case get_mining_role_info(RoleID) of
        ?NULL ->
            ?NONE;
        #r_mining_role{pos = Pos} = ObjLatticeRole ->
            set_mining_role_info(ObjLatticeRole#r_mining_role{family_id = FamilyID}),
            case ets:member(?DB_MINING_LATTICE_P, Pos) andalso get_mining_status() of
                #r_mining_status{status = Status} when Status =/= ?STATUS_CLOSE ->
                    update_mining_lattice(get_mining_lattice_info(Pos));
                _ ->
                    ?NONE
            end
    end.

%% @doc 角色离开公会
do_role_leave_family(RoleID, FamilyID) ->
    case get_mining_role_info(RoleID) of
        ?NULL ->
            ?NONE;
        #r_mining_role{pos = Pos} = ObjLatticeRole ->
            set_mining_role_info(ObjLatticeRole#r_mining_role{family_id = FamilyID}),
            case ets:member(?DB_MINING_LATTICE_P, Pos) andalso get_mining_status() of
                #r_mining_status{status = Status} when Status =/= ?STATUS_CLOSE ->
                    update_mining_lattice(get_mining_lattice_info(Pos));
                _ ->
                    ?NONE
            end
    end.

%% @doc 修改名字
do_update_role_rename(RoleID, RoleName) ->
    case get_mining_role_info(RoleID) of
        ?NULL ->
            ?NONE;
        #r_mining_role{pos = Pos} = ObjLatticeRole ->
            set_mining_role_info(ObjLatticeRole#r_mining_role{role_name = RoleName}),
            case ets:member(?DB_MINING_LATTICE_P, Pos) andalso get_mining_status() of
                #r_mining_status{status = Status} when Status =/= ?STATUS_CLOSE ->
                    update_mining_lattice(get_mining_lattice_info(Pos));
                _ ->
                    ?NONE
            end
    end.

%% @doc 更新战力
do_update_role_power(RoleID, Power) ->
    case get_mining_role_info(RoleID) of
        ?NULL ->
            ?NONE;
        #r_mining_role{pos = Pos} = ObjLatticeRole ->
            set_mining_role_info(ObjLatticeRole#r_mining_role{power = Power}),
            case ets:member(?DB_MINING_LATTICE_P, Pos) andalso get_mining_status() of
                #r_mining_status{status = Status} when Status =/= ?STATUS_CLOSE ->
                    update_mining_lattice(get_mining_lattice_info(Pos));
                _ ->
                    ?NONE
            end
    end.

%% @doc 获取当次采集结束时间
get_gather_stop_time(RoleID, TypeID, RolePower, FamilyID, Pos, Now) ->
    #c_mining_lattice{type = Type, collection_time = CollectionMin, power = RPower, family_addition = FamilyAddition} = get_mining_lattice(TypeID),
    [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
    RetMin =
    case Type =:= ?MINING_TYPE_PLAIN of
        true ->
            CollectionMin;
        _ ->
            [Power, Time] = RPower,
            ?IF(RolePower >= Power, (CollectionMin - Time), CollectionMin)
    end,
    RetTime = RetMin * ?ONE_MINUTE,

    case FamilyID =/= 0 andalso lists:any(fun({X, Y}) ->
        #r_mining_lattice{mining_role_id = MiningRoleID} = get_mining_lattice_info({X, Y}),
        case RoleID =/= MiningRoleID andalso ?IS_ROLE_MINING(MiningRoleID) of
            true ->
                #r_mining_role{family_id = MiningFamilyID} = get_mining_role_info(MiningRoleID),
                MiningFamilyID =/= 0 andalso MiningFamilyID =:= FamilyID;
            _ ->
                false
        end end, round_pos_list(Pos, WidthX, HeightY)) of
        true ->
            {true, Now + (RetTime - lib_tool:ceil((FamilyAddition / ?RATE_100) * RetTime))};
        _ ->
            {false, Now + RetTime}
    end.

do_gm_reduce_time(ObjRoleID) ->
    Now = time_tool:now(),
    #r_mining_role{} = MiningRole = get_mining_role_info(ObjRoleID),
    set_mining_role_info(MiningRole#r_mining_role{gather_stop = Now + 5}),
    do_mining_role_info(MiningRole).

do_gm_change_seat(RoleID) ->
    case get_mining_role_info(RoleID) of
        #r_mining_role{pos = Pos} ->
            #r_mining_role{pos = Pos} = get_mining_role_info(RoleID),
            [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
            RoundList =
                lists:foldl(
                    fun({X, Y}, Acc) ->
                        #r_mining_lattice{mining_role_id = MiningRoleID} = get_mining_lattice_info({X, Y}),
                        ?IF(?IS_ROLE_MINING(MiningRoleID), Acc, [{X, Y}|Acc])
                    end, [], round_pos_list(Pos, WidthX, HeightY)),
            case RoundList of
                [{X, Y} | _] ->
                    AllList = get_all_mining_lattice_info(),
                    case lib_tool:foldl(fun(#r_mining_lattice{mining_role_id = MiningRoleID, pos = Pos1}, Acc) ->
                        case ?IS_ROLE_MINING(MiningRoleID) andalso MiningRoleID =/= RoleID andalso {X, Y} =/= Pos1 of
                            true ->
                                {return, [MiningRoleID, Pos1]};
                            _ ->
                                Acc
                        end end, [], AllList) of
                        [ObjRoleID, Pos2 | _] ->
                            #r_mining_lattice{} = MiningLattice = get_mining_lattice_info({X, Y}),
                            #r_mining_lattice{} = DestMiningLattice = get_mining_lattice_info(Pos2),
                            DestMiningLattice2 = DestMiningLattice#r_mining_lattice{mining_role_id = ?UNDEFINED},
                            set_mining_lattice_info(MiningLattice#r_mining_lattice{mining_role_id = ObjRoleID}),
                            set_mining_lattice_info(DestMiningLattice2),
                            #r_mining_role{shift_history = ShiftHistory} = ObjMiningRole = get_mining_role_info(ObjRoleID),
                            set_mining_role_info(ObjMiningRole#r_mining_role{pos = {X, Y}, shift_history = [Pos2 | ShiftHistory]}),
                            add_loop_lattice({X, Y}),
                            update_mining_lattice(DestMiningLattice2);
                        _ ->
                            ?NONE
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

do_gm_add_plunder(RoleID) ->
    case get_mining_role_info(RoleID) of
        #r_mining_role{role_name = RoleName, plunder_history = PlunderHistory} = MiningRole ->
            Now = time_tool:now(),
            AddHistory = #p_ks{id = Now, str = RoleName},
            common_misc:unicast(RoleID, #m_world_mining_plunder_update_toc{add_plunder_history = AddHistory}),
            PlunderHistory2 = get_max_plunder_len([AddHistory|PlunderHistory]),
            set_mining_role_info(MiningRole#r_mining_role{plunder_history = PlunderHistory2});
        _ ->
            ok
    end.

do_gm_add_shift(RoleID, AddNum) ->
    case get_mining_role_info(RoleID) of
        #r_mining_role{shift_num = ShiftNum} = MiningRole ->
            MiningRole2 = MiningRole#r_mining_role{shift_num = ShiftNum + AddNum},
            set_mining_role_info(MiningRole2),
            update_role_mining(MiningRole2, [?UPDATE_SHIFT]);
        _ ->
            ok
    end.


%% @doc 获取某个位置周围有效节点列表
round_pos_list({X, Y}, Xn, Yn) ->
    round_pos_list(X, Y, Xn, Yn).
round_pos_list(X, Y, Xn, Yn) ->
    XL = X - 1,
    XR = X + 1,
    YT = Y - 1,
    YB = Y + 1,

    New_XL = ?IF(XL =:= 0, Xn, XL),
    New_YB = ?IF(YB > Yn, 1, YB),
    New_XR = ?IF(XR > Xn, 1, XR),
    New_YT = ?IF(YT =:= 0, Yn, YT),

    InitPosList =
            [{New_XL, New_YB}, {X, New_YB}, {New_XR, New_YB},
            {New_XL, Y},                         {New_XR, Y},
            {New_XL, New_YT}, {X, New_YT}, {New_XR, New_YT}],
    [{X0, Y0} || {X0, Y0} <- InitPosList, X0 > 0, X0 =< Xn, Y0 > 0, Y0 =< Yn].

get_9_pos_list(Pos) ->
    [WidthX, HeightY | _] = common_misc:get_global_list(?GLOBAL_MINING_LATTICE_WIDTH_HEIGHT),
    get_9_pos_list(Pos, WidthX, HeightY).
get_9_pos_list({X, Y}, MaxX, MaxY) ->
    XL = X - 1,
    XR = X + 1,
    YT = Y - 1,
    YB = Y + 1,

    New_XL = ?IF(XL =:= 0, MaxX, XL),
    New_XR = ?IF(XR > MaxX, 1, XR),
    New_YB = ?IF(YB > MaxY, 1, YB),
    New_YT = ?IF(YT =:= 0, MaxY, YT),
    [
        {New_XL, New_YB}, {X, New_YB}, {New_XR, New_YB},
        {New_XL, Y}, {X, Y}, {New_XR, Y},
        {New_XL, New_YT}, {X, New_YT}, {New_XR, New_YT}
    ].



%% @doc 判断X，Y是否位于以X0,Y0为中心的Range范围内
in_range(X0, Y0, X, Y, [Width, Height]) ->
    do_in_range(X0, Y0, X, Y, Width, Height);
in_range(X0, Y0, X, Y, {Width, Height}) ->
    do_in_range(X0, Y0, X, Y, Width, Height);
in_range(X0, Y0, X, Y, Range) when is_integer(Range) ->
    do_in_range(X0, Y0, X, Y, Range, Range).
do_in_range(X0, Y0, X, Y, Width, Height) ->
    Lists = round_pos_list(X0, Y0, Width, Height),
    lists:member({X, Y}, Lists).

%% @doc 判断X，Y相对于X0，Y0的方位
%% -------------> x坐标
%% |
%% |    (x0,y0)
%% |
%% v
%% y坐标
calc_dir(X0, Y0, X, Y) ->
    if
        X =:= X0 ->
            if
                Y > Y0 ->
                    ?DIR_BOTTOM;
                Y < Y0 ->
                    ?DIR_TOP;
                true ->
                    ?DIR_SAME
            end;
        Y =:= Y0 ->
            if
                X < X0 ->
                    ?DIR_LEFT;
                X > X0 ->
                    ?DIR_RIGHT
            end;
        X < X0 ->
            if
                Y < Y0 ->
                    ?DIR_TOPLEFT;
                Y > Y0 ->
                    ?DIR_BOTTOMLEFT
            end;
        X > X0 ->
            if
                Y < Y0 ->
                    ?DIR_TOPRIGHT;
                Y > Y0 ->
                    ?DIR_BOTTOMRIGHT
            end;
        true ->
            ?DIR_NONE
    end.

%% 更新角色部分数据
update_role_mining(MiningRole, UpdateList) ->
    #r_mining_role{
        role_id = RoleID,
        shift_num = ShiftNum,
        goods_list = GoodsList,
        gather_num = GatherNum,
        gather_stop = GatherStop,
        is_family_add = IsFamilyAdd} = MiningRole,
    [begin
         if
             UpdateKey =:= ?UPDATE_GATHER ->
                 common_misc:unicast(RoleID, #m_mining_gather_update_toc{gather_num = GatherNum, gather_stop_time = GatherStop, is_family_add = IsFamilyAdd});
             UpdateKey =:= ?UPDATE_SHIFT ->
                 common_misc:unicast(RoleID, #m_mining_shift_num_update_toc{shift_num = ShiftNum});
             UpdateKey =:= ?UPDATE_GOODS ->
                 common_misc:unicast(RoleID, #m_mining_goods_update_toc{goods_list = GoodsList})
         end
     end || UpdateKey <- UpdateList].

update_role_shift(_RoleID, []) ->
    ok;
update_role_shift(RoleID, UpdateShifts) ->
    HistoryList = [
        begin
            #r_mining_lattice{
                type_id = TypeID,
                pos = {X, Y},
                gather_num = GatherNum
            } = get_mining_lattice_info({X, Y}),
            #p_mining_shift{x = X, y = Y, type_id = TypeID, surplus_num = GatherNum}
        end || {X, Y} <- UpdateShifts],
    common_misc:unicast(RoleID, #m_mining_shift_history_update_toc{shift_history = HistoryList}).

%% 更新单个格子
update_mining_lattice(MiningLattice) ->
    update_mining_lattice(MiningLattice, []).
update_mining_lattice(MiningLattice, RoleIDList) ->
    #r_mining_lattice{pos = Pos} = MiningLattice,
    RoleList =
        lists:foldl(
            fun(PosKey, RoleAcc) ->
                case get_mining_lattice_info(PosKey) of
                    #r_mining_lattice{mining_role_id = MiningRoleID} when ?IS_ROLE_MINING(MiningRoleID) ->
                        [MiningRoleID|RoleAcc];
                    _ ->
                        RoleAcc
                end
            end, [], get_9_pos_list(Pos)),
    RoleList2 = RoleList -- RoleIDList,
    case RoleList2 =/= [] of
        true ->
            DataRecord = #m_mining_one_lattice_update_toc{lattice = to_p_mining_lattice(MiningLattice)},
            common_broadcast:bc_record_to_roles(RoleList -- RoleIDList, DataRecord);
        _ ->
            ok
    end.

update_9_lattice(RoleID, Pos) ->
    List =
        lists:foldl(
            fun(PosKey, MiningAcc) ->
                case get_mining_lattice_info(PosKey) of
                    #r_mining_lattice{} = MiningLattice ->
                        [to_p_mining_lattice(MiningLattice)|MiningAcc];
                    _ ->
                        MiningAcc
                end
            end, [], get_9_pos_list(Pos)),
    common_misc:unicast(RoleID, #m_mining_lattice_update_toc{lattice = List}).

to_p_mining_lattice(MiningLattice) ->
    #r_mining_lattice{
        pos = {X, Y},
        type_id = TypeID,
        gather_num = GatherNum,
        renovate_time = RenovateTime,
        mining_role_id = MiningRoleID} = MiningLattice,
    MiningPRole = ?IF(?IS_ROLE_MINING(MiningRoleID), to_p_mining_role(get_mining_role_info(MiningRoleID)), ?UNDEFINED),
    #p_mining_lattice{
        x = X,
        y = Y,
        type_id = TypeID,
        surplus_num = GatherNum,
        renovate_time = RenovateTime,
        mining_role = MiningPRole
    }.

to_p_mining_role(MiningRole) ->
    #r_mining_role{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        family_id = FamilyID,
        power = RolePower,
        inspire = Inspire,
        pos = {X, Y},
        is_family_add = IsFamilyAdd} = MiningRole,
    #r_mining_lattice{type_id = TypeID} = get_mining_lattice_info({X, Y}),
    [{Chance}, _ | _] = common_misc:get_global_string_list(?GLOBAL_MINING_MINING_INSPIRE),
    Power = (RolePower + (lib_tool:ceil((Chance / 100) * RolePower) * Inspire)),
    #p_mining_role{
        x = X,
        y = Y,
        type_id = TypeID,
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        family_id = FamilyID,
        power = Power,
        is_family_add = IsFamilyAdd
    }.

get_new_lattice_type_id() ->
    AllList = [{Chance, ID} || {ID, #c_mining_lattice{chance = Chance}} <- lib_config:list(cfg_mining_lattice), Chance > 0],
    lib_tool:get_weight_output(AllList).

%% 出生
get_mining_role_log(RoleID, TypeID, UseTime, {X, Y}, ShiftNum, Power) ->
    Pos = unicode:characters_to_binary(integer_to_list(X) ++ "," ++ integer_to_list(Y)),
    #r_role_attr{channel_id = ChannelID,
        game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log = #log_mining_role{role_id = RoleID, type = 1, type_id = TypeID, old_pos = unicode:characters_to_binary(""), gather_num = 0,
        shift_num = ShiftNum, plunder_id = 0, plunder_power = 0, power = Power, is_success = 0 ,
        use_time = UseTime, pos = Pos, channel_id = ChannelID, game_channel_id = GameChannelID},
    background_misc:cross_log(RoleID, Log).


%% 掠夺
get_mining_role_log(RoleID, ShiftNum, TypeID, UseTime, PlunderID, Power, PlunderPower, IsSuccess, {X, Y}, {OldX, OldY}) ->
    Pos = unicode:characters_to_binary(integer_to_list(X) ++ "," ++ integer_to_list(OldY)),
    OldPos = unicode:characters_to_binary(integer_to_list(OldX) ++ "," ++ integer_to_list(Y)),
    #r_role_attr{channel_id = ChannelID,
        game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log = #log_mining_role{
        role_id = RoleID,
        type = 3,
        type_id = TypeID,
        use_time = UseTime,
        pos = Pos,
        old_pos = OldPos,
        shift_num = ShiftNum,
        plunder_id = PlunderID,
        gather_num = 0,
        plunder_power = PlunderPower,
        power = Power,
        is_success = IsSuccess, channel_id = ChannelID, game_channel_id = GameChannelID},
    background_misc:cross_log(RoleID, Log).

%% 采集
get_mining_role_log(RoleID, TypeID, UseTime, GatherNum, ShiftNum, RolePower, {X, Y}) when is_integer(RolePower) ->
    Pos = unicode:characters_to_binary(integer_to_list(X) ++ "," ++ integer_to_list(Y)),
    #r_role_attr{channel_id = ChannelID,
        game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log = #log_mining_role{

        old_pos = unicode:characters_to_binary(""), shift_num = ShiftNum, plunder_id = 0, plunder_power = 0, power = RolePower, is_success = 0,
        role_id = RoleID, type = 4, type_id = TypeID, gather_num = GatherNum, use_time = UseTime, pos = Pos, channel_id = ChannelID, game_channel_id = GameChannelID},
    background_misc:cross_log(RoleID, Log).

%% 移动
do_shift_log(RoleID, ShiftNum, TypeID, UseTime, RolePower, {X, Y}, {OldX, OldY}) ->
    Pos = unicode:characters_to_binary(integer_to_list(X) ++ "," ++ integer_to_list(OldY)),
    OldPos = unicode:characters_to_binary(integer_to_list(OldX) ++ "," ++ integer_to_list(Y)),
    #r_role_attr{channel_id = ChannelID,
        game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log = #log_mining_role{role_id = RoleID, type = 2, type_id = TypeID, use_time = UseTime, pos = Pos, old_pos = OldPos,
        gather_num = 0, plunder_id = 0, plunder_power = 0, power = RolePower, is_success = 0,
        shift_num = ShiftNum, channel_id = ChannelID, game_channel_id = GameChannelID},
    background_misc:cross_log(RoleID, Log).

get_mining_lattice(ID) ->
    [Config] = lib_config:find(cfg_mining_lattice, ID),
    Config.

get_max_plunder_len(List) ->
    lists:sublist(List, ?MINING_MAX_LEN).

get_max_gather(List) ->
    lists:sublist(List, ?MINING_MAX_LEN).

get_inspire_power(RolePower, Inspire) ->
    [{Chance}, _ | _] = common_misc:get_global_string_list(?GLOBAL_MINING_MINING_INSPIRE),
    RolePower + (lib_tool:ceil((Chance / ?RATE_100) * RolePower) * Inspire).

get_gather_goods(GoodsList, ConfigList, RoleGatherNum) ->
    lists:foldl(
        fun({GoodsID, Num}, Acc) ->
            case lists:keytake(GoodsID, #p_kv.id, Acc) of
                {value, #p_kv{id = GoodsID, val = Count}, TupleList2} ->
                    [#p_kv{id = GoodsID, val = Count + (Num * (RoleGatherNum))} | TupleList2];
                _ ->
                    [#p_kv{id = GoodsID, val = (Num * (RoleGatherNum))} | Acc]
            end end, GoodsList, ConfigList).
%% ------------------------db-----------------------------
set_mining_lattice_info(MiningLattice) ->
    db:insert(?DB_MINING_LATTICE_P, MiningLattice).
del_mining_lattice_info(Pos) ->
    db:delete(?DB_MINING_LATTICE_P, Pos).
del_all_mining_lattice_info() ->
    db:delete_all(?DB_MINING_LATTICE_P).
get_all_mining_lattice_info() ->
    db:table_all(?DB_MINING_LATTICE_P).
get_mining_lattice_info(Pos) ->
    case ets:lookup(?DB_MINING_LATTICE_P, Pos) of
        [#r_mining_lattice{} = MiningLattice] ->
            MiningLattice;
        _ ->
            #r_mining_lattice{pos = Pos}
    end.

set_mining_role_info(MiningRole) ->
    db:insert(?DB_MINING_ROLE_P, MiningRole).
del_mining_role_info(RoleID) ->
    db:delete(?DB_MINING_ROLE_P, RoleID).
del_all_mining_role() ->
    db:delete_all(?DB_MINING_ROLE_P).
get_all_mining_role() ->
    db:table_all(?DB_MINING_ROLE_P).
get_mining_role_info(RoleID) ->
    case ets:lookup(?DB_MINING_ROLE_P, RoleID) of
        [#r_mining_role{} = MiningRole] ->
            MiningRole;
        _ ->
            ?NULL
    end.

set_mining_status(MiningStatus) ->
    world_data:set_mining_status(MiningStatus).
get_mining_status() ->
    world_data:get_mining_status().

add_loop_lattice(Pos) ->
    List = get_loop_lattices(),
    case lists:member(Pos, List) of
        true ->
            ok;
        _ ->
            set_loop_lattices([Pos|List])
    end.
del_loop_lattice(Pos) ->
    List = get_loop_lattices(),
    case lists:member(Pos, List) of
        true ->
            set_loop_lattices(lists:delete(Pos, List));
        _ ->
            ok
    end.
set_loop_lattices(List) ->
    erlang:put({?MODULE, loop_lattices}, List).
get_loop_lattices() ->
    erlang:get({?MODULE, loop_lattices}).