%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(role_server).
-behaviour(gen_server).
-include("role.hrl").
-include("monster.hrl").
-include("proto/role_login.hrl").

%% API
-export([start_link/2]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    init_role_state/1,
    pre_enter/1,
    dump_table/2,
    dump_data/1
]).

-export([
    execute_state_fun/2
]).

-export([
    kill_monster/4,
    kill_world_boss/2
]).

%% status API
-export([
    i/1,
    i/2,
    calc_i/2,
    dict/1,
    dict/2
]).

%%%===================================================================
%%% API
%%%===================================================================

i(RoleID) ->
    pname_server:call(role_misc:pid(RoleID), {i, all}).
i(RoleID, Key) ->
    pname_server:call(role_misc:pid(RoleID), {i, Key}).

calc_i(RoleID, Key) ->
    pname_server:call(role_misc:pid(RoleID), {calc_i, Key}).

dict(RoleID) ->
    pname_server:call(role_misc:pid(RoleID), {dict, all}).
dict(RoleID, Key) ->
    pname_server:call(role_misc:pid(RoleID), {dict, Key}).

start_link(GatewayPID, IP) ->
    gen_server:start_link(?MODULE, [GatewayPID, IP], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([GatewayPID, IP]) ->
    erlang:monitor(process, GatewayPID),
    erlang:process_flag(trap_exit, true),
    role_login:init_state(),
    mod_role_dict:set_ip(IP),
    mod_role_dict:set_gateway_pid(GatewayPID),
    {ok, #r_role{}}.

handle_call(Request, _From, State) -> %%handle_call
    Return = ?DO_ROLE_HANDLE_CALL(Request, State),
    case Return of
        {Reply, #r_role{} = State2} ->
            ?TRY_CATCH(do_log(), Err2),
            next;
        {Reply, #r_role{} = State2, CallBackList} ->
            ?TRY_CATCH(do_call_back(CallBackList), Err1),
            ?TRY_CATCH(do_log(), Err2);
        _ ->
            ?ERROR_MSG("role_server handle_call error :~w", [Return]),
            reset_log(),
            Reply = error, State2 = State
    end,
    {reply, Reply, State2}.

handle_cast(Info, State) ->
    handle_info(Info, State).

handle_info({'EXIT', _, _Reason}, State) ->
    {stop, normal, State};
handle_info({'DOWN', _, _, _PID, _Reason}, State) ->
    {stop, normal, State};
handle_info(Info, State) ->
    Return = ?DO_ROLE_HANDLE_INFO(Info, State),
    case Return of
        #r_role{} ->
            State2 = Return,
            ?TRY_CATCH(do_log(), Err2);
        {#r_role{} = State2, CallBackList} ->
            ?TRY_CATCH(do_call_back(CallBackList), Err1),
            ?TRY_CATCH(do_log(), Err2);
        _ ->
            ?ERROR_MSG("role_server handle_info:~w error:~w", [Info, Return]),
            reset_log(),
            State2 = State
    end,
    {noreply, State2}.

terminate(_Reason, State) ->
    do_terminate(State),
    do_log(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

init_role_state(RoleID) ->
    State = init_role_state2(RoleID),
    [PreInit] = lib_config:find(cfg_module_etc, role_pre_init_modules),
    [Init] = lib_config:find(cfg_module_etc, role_init_modules),
    [Calc] = lib_config:find(cfg_module_etc, role_calc_modules),
    PreInit2 = [{Mod, pre_init} || Mod <- PreInit],
    Init2 = [{Mod, init} || Mod <- Init],
    Calc2 = [{Mod, calc} || Mod <- Calc],
    State2 = do_execute_mod(PreInit2 ++ Init2 ++ Calc2, State),
    do_day_reset(State2).

init_role_state2(RoleID) ->
    lists:foldl(
        fun(#c_tab{class = Class, tab = Tab}, StateAcc) ->
            case Class of
                {role, Index} ->
                    case db:lookup(Tab, RoleID) of
                        [Val] ->
                            next;
                        [] ->
                            Val = undefined
                    end,
                    erlang:setelement(Index, StateAcc, Val);
                _ ->
                    StateAcc
            end
        end, #r_role{role_id = RoleID}, ?TABLE_INFO).

pre_enter(State) ->
    [PreEnter] = lib_config:find(cfg_module_etc, role_pre_enter_modules),
    PreEnter2 = [{Mod, pre_enter} || Mod <- PreEnter],
    do_execute_mod(PreEnter2, State).

kill_monster(RoleID, TypeID, MonsterLevel, MonsterPos) ->
    role_misc:info_role(RoleID, {hook_role, kill_monster, [TypeID, MonsterLevel, MonsterPos]}).

kill_world_boss(RoleID, TypeID) ->
    role_misc:info_role(RoleID, {hook_role, kill_world_boss, [TypeID]}).


%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle_call({i, Key}, State) ->
    Reply = do_i(Key, State),
    {Reply, State};
do_handle_call({dict, Key}, State) ->
    Reply = do_dict(Key),
    {Reply, State};
do_handle_call({calc_i, Key}, State) ->
    Reply = do_calc_i(Key, State),
    {Reply, State};
do_handle_call({mod, Mod, Info}, State) ->
    Mod:handle(Info, State);
do_handle_call(_Info, State) ->
    {ok, State}.

do_handle_info({mod, Mod, Info}, State) ->
    Mod:handle(Info, State);
do_handle_info({M, F, A}, State) ->
    erlang:apply(M, F, A ++ [State]);
do_handle_info({reverse, M, F, A}, State) ->
    erlang:apply(M, F, [State] ++ A);
do_handle_info(role_first_enter, State) -> %% 验证通过
    do_after_enter(State);
do_handle_info({binary, Bin}, State) ->
    pname_server:send(mod_role_dict:get_gateway_pid(), {binary, Bin}),
    State;
do_handle_info({message, DataRecord}, State) ->
    common_misc:unicast(mod_role_dict:get_gateway_pid(), DataRecord),
    State;
do_handle_info({loop_sec, Now}, State) ->
    time_tool:now_cached(Now),
    do_loop(Now, State);
do_handle_info({?HOUR_CHANGE, Now}, State) ->
    do_hour_change(Now, State);
do_handle_info(?TIME_ZERO, State) ->
    do_zero(State);
do_handle_info(Info, State) ->
    ?ERROR_MSG("Unknow Message:~w", [Info]),
    State.

%% 跨天重置
do_day_reset(State) ->
    case time_tool:timestamp_to_date(State#r_role.role_private_attr#r_role_private_attr.reset_time) =/= time_tool:date() of
        true ->
            [DayReset] = lib_config:find(cfg_module_etc, role_day_reset_modules),
            DayReset2 = [{Mod, day_reset} || Mod <- DayReset],
            #r_role{role_private_attr = PrivateAttr} = State2 = do_execute_mod(DayReset2, State),
            State2#r_role{role_private_attr = PrivateAttr#r_role_private_attr{reset_time = time_tool:now()}};
        _ ->
            State
    end.

%% 进入地图后回调的online方法
do_after_enter(State) ->
    init_timer(),
    [PreOnline] = lib_config:find(cfg_module_etc, role_pre_online_modules),
    PreOnline2 = [{Mod, pre_online} || Mod <- PreOnline],
    [Online] = lib_config:find(cfg_module_etc, role_online_modules),
    Online2 = [{Mod, online} || Mod <- Online],
    State2 = do_execute_mod(PreOnline2, State),
    State3 = do_execute_mod(Online2, State2),
    common_misc:unicast(State#r_role.role_id, #m_role_login_toc{}),
    hook_role:role_online(State3),
    State3.

init_timer() ->
    time_tool:reg(role, [0, hour_change, 1000]),
    Now = time_tool:now(),
    mod_role_dict:set_min_ts(Now + ?ONE_MINUTE),
    mod_role_dict:set_ten_min_ts(Now + ?TEN_MINUTE).

%% 小时数改变
do_hour_change(Now, State) ->
    {_, {Hour, _Min2, _Sec2}} = time_tool:timestamp_to_datetime(Now),
    [HourChange] = lib_config:find(cfg_module_etc, role_hour_change_modules),
    do_hour_change2(HourChange, Hour, State).

do_hour_change2([], _Hour, State) ->
    State;
do_hour_change2([Mod|R], Hour, State) ->
    case ?TRY_CATCH(erlang:apply(Mod, hour_change, [Hour, State])) of
        #r_role{} = State2 ->
            ok;
        Error ->
            ?ERROR_MSG("execute loop error: ~w, ~w", [Mod, Error]),
            State2 = State
    end,
    do_hour_change2(R, Hour, State2).

%% loop回调
do_loop(Now, State) ->
    [Loop] = lib_config:find(cfg_module_etc, role_loop_modules),
    State2 = do_loop2(Loop, Now, State),
    State3 = do_loop_min(Now, State2),
    do_loop_10min(Now, State3).

do_loop2([], _Now, State) ->
    State;
do_loop2([Mod|R], Now, State) ->
    case ?TRY_CATCH(erlang:apply(Mod, loop, [Now, State])) of
        #r_role{} = State2 ->
            ok;
        Error ->
            ?ERROR_MSG("execute loop error: ~w, ~w", [Mod, Error]),
            State2 = State
    end,
    do_loop2(R, Now, State2).

%% 1分钟循环
do_loop_min(Now, State) ->
    case Now >= mod_role_dict:get_min_ts() of
        true ->
            mod_role_dict:set_min_ts(Now + ?ONE_MINUTE),
            [Loop] = lib_config:find(cfg_module_etc, role_loop_min_modules),
            do_loop_min(Loop, Now, State);
        _ ->
            State
    end.

do_loop_min([], _Now, State) ->
    State;
do_loop_min([Mod|R], Now, State) ->
    case ?TRY_CATCH(erlang:apply(Mod, loop_min, [Now, State])) of
        #r_role{} = State2 ->
            ok;
        Error ->
            ?ERROR_MSG("execute loop error: ~w, ~w", [Mod, Error]),
            State2 = State
    end,
    do_loop_min(R, Now, State2).

%% 10分钟循环
do_loop_10min(Now, State) ->
    case Now >= mod_role_dict:get_ten_min_ts() of
        true ->
            mod_role_dict:set_ten_min_ts(Now + ?TEN_MINUTE),
            [Loop] = lib_config:find(cfg_module_etc, role_loop_10min_modules),
            do_loop_10min2(Loop, Now, State);
        _ ->
            State
    end.

do_loop_10min2([], _Now, State) ->
    State;
do_loop_10min2([Mod|R], Now, State) ->
    case ?TRY_CATCH(erlang:apply(Mod, loop_10min, [Now, State])) of
        #r_role{} = State2 ->
            ok;
        Error ->
            ?ERROR_MSG("execute loop error: ~w, ~w", [Mod, Error]),
            State2 = State
    end,
    do_loop_10min2(R, Now, State2).

%% 0点回调
do_zero(State) ->
    State2 = do_day_reset(State),
    [Zero] = lib_config:find(cfg_module_etc, role_zero_modules),
    Zero2 = [{Mod, zero} || Mod <- Zero],
    do_execute_mod(Zero2, State2).

do_execute_mod([], State) ->
    State;
do_execute_mod([{Mod, Fun}|R], State) ->
    case ?TRY_CATCH(erlang:apply(Mod, Fun, [State])) of
        #r_role{} = State2 ->
            ok;
        Error ->
            ?ERROR_MSG("execute mod error: ~w:~w, ~w", [Mod, Fun, Error]),
            State2 = State
    end,
    do_execute_mod(R, State2).

%% terminate dump_data
do_terminate(State) ->
    time_tool:dereg(role, [0, hour_change, 1000]),
    case erlang:is_integer(State#r_role.role_id) of
        true ->
            ?WARNING_MSG("role_server terminate:~w", [{mod_role_dict:get_role_id(), State#r_role.role_map#r_role_map.map_id}]),
            #r_role{role_attr = RoleAttr} = State,
            RoleAttr2 = RoleAttr#r_role_attr{last_offline_time = time_tool:now()},
            State2 = State#r_role{role_attr = RoleAttr2},
            [Offline] = lib_config:find(cfg_module_etc, role_offline_modules),
            Offline2 = [{Mod, offline} || Mod <- Offline],
            State3 = do_execute_mod(Offline2, State2),
            dump_data(State3),
            catch erlang:unregister(role_misc:get_role_pname(mod_role_dict:get_role_id())),
            ?TRY_CATCH(log_role_logout(State3), Err1),
            ?TRY_CATCH(role_login:log_role_status(State3, false), Err2),
            ?TRY_CATCH(mod_role_pf:offline_log(State3), Err3);
        _ ->
            ok
    end,
    role_login:logout_role().

dump_data(#r_role{} = State) ->
    [begin
         Value = erlang:element(Index, State),
         ?IF(Value =/= undefined, db:insert(Tab, Value), ok)
     end || #c_tab{class = {role, Index}, tab = Tab} <- ?TABLE_INFO].

dump_table(Tab, State) ->
    case lists:keyfind(Tab, #c_tab.tab, ?TABLE_INFO) of
        #c_tab{class = {role, Index}} ->
            Value = erlang:element(Index, State),
            ?IF(Value =/= undefined, db:insert(Tab, Value), ok),
            State;
        _ ->
            State
    end.

do_call_back(CallBackList) ->
    [?TRY_CATCH(Fun()) || Fun <- CallBackList].

execute_state_fun([], State) ->
    State;
execute_state_fun([Fun|R], State) ->
    case catch Fun(State) of
        #r_role{} = State2 ->
            execute_state_fun(R, State2);
        Error ->
            FunMsg = ?IF(erlang:is_function(Fun), erlang:fun_info_mfa(Fun), Fun),
            ?ERROR_MSG("execute state fun error:~w~n :~w", [Error, FunMsg]),
            execute_state_fun(R, State)
    end.

do_i(Key, State) ->
    case Key of
        all ->
            State;
        _ ->
            case lib_tool:list_element_index(Key, record_info:fields(r_role)) of
                Index when Index > 0 ->
                    erlang:element(Index + 1, State);
                _ ->
                    State
            end
    end.

do_dict(Key) ->
    case Key of
        all ->
            erlang:get();
        _ ->
            erlang:get(Key)
    end.

do_calc_i(Key, State) ->
    #r_role{calc_list = CalcList} = State,
    lists:keyfind(Key, #r_calc.key, CalcList).

log_role_logout(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{
        account_name = AccountName,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #r_role_private_attr{
        last_login_time = LastLoginTime
    } = PrivateAttr,
    Log = #log_role_logout{
        role_id = RoleID,
        account_name = AccountName,
        online_time = time_tool:now() - LastLoginTime,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

%% role_server进行中，有些出错可能会导致数据的回滚，所以日志在最后写来保证可靠
do_log() ->
    BackGroundLogs = mod_role_dict:get_background_logs(),
    PFGoldLogs = mod_role_dict:get_pf_logs(),
    case BackGroundLogs =/= [] of
        true -> %% 保证顺序
            background_misc:log(lists:reverse(BackGroundLogs));
        _ ->
            ok
    end,
    case PFGoldLogs =/= [] of
        true ->
            common_pf:pf_log(PFGoldLogs);
        _ ->
            ok
    end,
    reset_log().

reset_log() ->
    mod_role_dict:set_background_logs([]),
    mod_role_dict:set_pf_logs([]).