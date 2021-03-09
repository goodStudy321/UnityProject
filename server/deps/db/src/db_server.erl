%%%--------------------------------------------------------
%%% @author 
%%% @doc
%%%     db_server模块，负责与sql进程交互
%%% @end
%%%--------------------------------------------------------

-module(db_server).
-include("common.hrl").
-behaviour(gen_server).

-export([
    flush/1,
    wait_ready/1,
    server_name/1,
    all_tables/0,
    start/2,
    start_link/2
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    table = undefined,
    loop = 0,
    save_func = undefined,
    insert = [],
    period = undefined,
    period_insert = undefined,
    hot_marker = undefined,
    cooldown = undefined,
    cooldown_check = 0
}).

-define(COOLDWON_CHECK_LOOP, 100). % 每N个循环检查一次缓存冷却
-define(MAX_MSG_Q, 300). % 最多允许消息队列长度

%% 强制写盘, 成功返true
flush(Table) ->
    Name = server_name(Table),
    gen_server:call(Name, flush, infinity).


wait_ready(Table) ->
    Name = server_name(Table),
    gen_server:call(Name, ready, infinity).

all_tables() ->
    Children = supervisor:which_children(db_sup),
    Tables = [Table || {{?MODULE, [Table, _Opts]}, _Pid, _Type, _Module} <- Children],
    Tables.


server_name(Table) ->
    list_to_atom(lists:concat([?MODULE, "_", Table])).

start(Table, Opts) ->
    Name = server_name(Table),
    case erlang:whereis(Name) of
        undefined ->
            db_sup:start_child(?MODULE, [Table, Opts]);
        Pid ->
            ?ERROR_MSG("Table ~p already opened", [Table]),
            {ok, Pid}
    end.

start_link(Table, Opts) ->
    Name = server_name(Table),
    SOpts = [{fullsweep_after, 10}],
    gen_server:start_link({local, Name}, ?MODULE, [Table, Opts], [{spawn_opt, SOpts}]).


init([Table, Opts]) ->
    erlang:process_flag(trap_exit, true),
    {save_func, {M, F, A}} = lists:keyfind(save_func, 1, Opts),
    time_tool:reg(db, [5000]),
    State = #state{table = Table,
        save_func = {M, F, A},
        insert = []},
    State1 = init_cooldown(Opts, State),
    State2 = init_period(Opts, State1),
    case lists:keyfind(init_type, 1, Opts) of
        {init_type, all} ->
            init_all(Table);
        _ ->
            ok
    end,
    {ok, State2}.

init_period(Opts, State) ->
    case proplists:get_value(period, Opts) of
        undefined ->
            State#state{period = undefined};
        Val when Val > 0 ->
            NewPI = new_period_insert(Val),
            State#state{period = Val, period_insert = NewPI}
    end.

new_period_insert(undefined) ->
    undefined;
new_period_insert(Period) ->
    F = fun(Slot, Tree) -> gb_trees:insert(Slot, gb_sets:empty(), Tree) end,
    NewPI = lists:foldl(F, gb_trees:empty(), lists:seq(0, Period - 1)),
    NewPI.


init_cooldown(Opts, State) ->
    case proplists:get_value(cooldown, Opts) of
        undefined ->
            State#state{hot_marker = undefined,
                cooldown = infinity};
        infinity ->
            State#state{hot_marker = undefined,
                cooldown = infinity};
        true ->
            CoolDown = db_lib:get_config(mysql_default_cooldown),
            init_cooldown_1(CoolDown, State);
        CoolDown when is_integer(CoolDown) ->
            init_cooldown_1(CoolDown, State);
        Error ->
            erlang:error({invalid_cooldown, Error})
    end.


init_cooldown_1(CoolDown, #state{table = Table} = State) ->
    CheckPoint = lib_tool:random(0, ?COOLDWON_CHECK_LOOP - 1),
    HotMarker = db_hot:start(Table),
    State#state{hot_marker = HotMarker,
        cooldown = CoolDown,
        cooldown_check = CheckPoint}.

init_all(Table) ->
    List = db_lib:all(Table),
    ets:insert(Table, List).

handle_call(ready, _From, State) ->
    Reply = ok,
    {reply, Reply, State};


handle_call(Req, From, State) ->
    try
        do_call(Req, From, State)
    catch
        Err:Reason ->
            ?ERROR_MSG("~p:~p", [Err, Reason]),
            {reply, error, State}
    end.

handle_cast(Msg, State) ->
    Result =
        try
            do_cast(Msg, State)
        catch
            Err:Reason ->
                ?ERROR_MSG("~w,~w", [Err, Reason]),
                {noreply, State}
        end,
    Result.

handle_info(Info, State) ->
    Result =
        try
            do_info(Info, State)
        catch
            Err:Reason ->
                ?ERROR_MSG("~w,~w,~w", [Info, Err, Reason]),
                {noreply, State}
        end,
    Result.

terminate(_Reason, State) ->
    time_tool:dereg(db, [5000]),
    case do_flush(State) of
        #state{insert = []} ->
            ok;
        #state{insert = Insert} ->
            ?ERROR_MSG("~p items not flushed on terminate !", [length(Insert)])
    end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call(flush, _From, State) ->
    State1 = flush_all_period(State),
    State2 = do_flush(State1),
    Reply =
        case State2 of
            #state{insert = []} ->
                true;
            _ ->
                false
        end,
    {reply, Reply, State2};

do_call(get_state, _From, State) ->
    {reply, State, State};
do_call(clear_bad_insert, _From, State) ->
    #state{insert = Insert} = State,
    Insert2 = [ Key || Key <- Insert, Key =/= undefined],
    State2 = State#state{insert = Insert2},
    {reply, ok, State2};
do_call(_Request, _From, State) ->
    ?ERROR_MSG("unhandle call ~p.", [_Request]),
    Reply = unexpect_call,
    {reply, Reply, State}.


do_cast({hot, Keys}, #state{} = State) ->
    mark_hot(Keys, State),
    {noreply, State};

do_cast({insert, Data}, #state{period = undefined, insert = Buffer} = State) when is_list(Data) ->
    mark_hot(Data, State),
    Buffer1 = Data ++ Buffer,
    {noreply, State#state{insert = Buffer1}};

do_cast({insert, Data}, #state{} = State) when is_list(Data) ->
    mark_hot(Data, State),
    State1 = period_insert(Data, State),
    {noreply, State1};

do_cast(insert_all, #state{table = Table, period = Period} = State) ->
    Keys = all_keys(Table),
    mark_hot(Keys, State),
    NewPI = new_period_insert(Period),
    State1 = State#state{insert = Keys, period_insert = NewPI},
    {noreply, State1};

do_cast({delete, Key},
        #state{period = undefined, insert = Buffer, table = Table} = State) ->
    db_lib:kv_delete(Table, Key),
    Buffer1 = lists:delete(Key, Buffer),
    {noreply, State#state{insert = Buffer1}};

do_cast({delete_many, Keys},
        #state{period = undefined, insert = Buffer, table = Table} = State) ->
    db_lib:kv_delete_many(Table, Keys),
    Buffer1 = lists:foldl(fun lists:delete/2, Buffer, Keys),
    {noreply, State#state{insert = Buffer1}};

do_cast({delete, Key},
        #state{table = Table} = State) ->
    db_lib:kv_delete(Table, Key),
    State1 = period_delete(Key, State),
    {noreply, State1};

do_cast({delete_many, Keys},
        #state{table = Table} = State) ->
    db_lib:kv_delete_many(Table, Keys),
    State1 = lists:foldl(fun period_delete/2, State, Keys),
    {noreply, State1};

do_cast(delete_all,
    #state{table = Table} = State) ->
    db_lib:delete_all(Table),
    State1 = State#state{insert = []},
    {noreply, State1};

do_cast(Msg, #state{} = State) ->
    ?ERROR_MSG("Msg:~w is not match.", [Msg]),
    {noreply, State}.

do_info({loop_msec, NowMs}, #state{loop = Loop} = State) ->
    State1 = State#state{loop = Loop + 1},
    State2 = loop_period(State1),
    State3 = do_loop_flush(State2),
    check_cool(NowMs div 1000, State3),
    {noreply, State3};

do_info({'ETS-TRANSFER', _, _, _}, State) ->
    {noreply, State};

do_info(Info, State) ->
    ?ERROR_MSG("Msg:~w is not match.", [Info]),
    {noreply, State}.

do_loop_flush(State) ->
    receive
        doloop ->
            do_loop_flush(State)
    after
        0 ->
            do_flush(State)
    end.

do_flush(#state{insert = []} = State) ->
    State;
do_flush(#state{save_func = {M, F, A}, insert = Insert} = State) ->
    Insert2 = do_modify_insert(Insert, []),
    case M:F(A, Insert2) of
        true ->
            State#state{insert = []};
        _Err ->
            ?ERROR_MSG("~p items in ~p flush failed: ~p", [length(Insert2), State#state.table, _Err]),
            mark_hot(Insert2, State), % 出错数据要保持热度, 正常数据不需要
            State#state{insert = Insert2}
    end.

do_modify_insert([], Acc) ->
    Acc;
do_modify_insert([undefined|R], Acc) ->
    ?ERROR_MSG("Error: key值为undefined"),
    do_modify_insert(R, Acc);
do_modify_insert([Key|R], Acc) ->
    Acc2 = ?IF(lists:member(Key, Acc), Acc, [Key|Acc]),
    do_modify_insert(R, Acc2).



mark_hot(_, #state{hot_marker = undefined}) ->
    ok;
mark_hot(_, #state{cooldown = infinity}) ->
    ok;
mark_hot(Keys, #state{hot_marker = HotMarker}) ->
    db_hot:raw_mark_hots(HotMarker, Keys).


check_cool(_, #state{hot_marker = undefined}) ->
    ok;
check_cool(_, #state{cooldown = infinity}) ->
    ok;
check_cool(Now, #state{table = Table,
    loop = Loop,
    hot_marker = HotMarker,
    cooldown = CoolDown,
    cooldown_check = CheckPoint}) ->
    case Loop rem ?COOLDWON_CHECK_LOOP of
        CheckPoint ->
            CoolTime = Now - CoolDown,
            db_hot:del_cools(Table, HotMarker, CoolTime);
        _ ->
            ok
    end.

all_keys(Table) ->
    ets:safe_fixtable(Table, true),
    Keys = all_keys(Table, ets:first(Table), []),
    ets:safe_fixtable(Table, false),
    Keys.

all_keys(_Table, '$end_of_table', Acc) ->
    Acc;
all_keys(Table, Key, Acc) ->
    all_keys(Table, ets:next(Table, Key), [Key | Acc]).


period_insert([H | T], #state{period = Period, period_insert = PI} = State) ->
    Slot = get_period_slot(H, Period),
    IDs = gb_trees:get(Slot, PI),
    PI1 = gb_trees:update(Slot, gb_sets:add(H, IDs), PI),
    period_insert(T, State#state{period_insert = PI1});
period_insert([], State) ->
    State.


period_delete(Key, #state{period = Period, period_insert = PI} = State) ->
    Slot = get_period_slot(Key, Period),
    IDs = gb_trees:get(Slot, PI),
    PI1 = gb_trees:update(Slot, gb_sets:delete_any(Key, IDs), PI),
    State#state{period_insert = PI1}.


get_period_slot(Key, Period) when is_integer(Key) ->
    erlang:abs(Key rem Period);
get_period_slot(Key, Period) ->
    erlang:phash2(Key, Period).


loop_period(#state{period = undefined} = State) ->
    State;
loop_period(#state{loop = Loop,
    period = Period,
    insert = Insert,
    period_insert = PI} = State) ->
    Slot = Loop rem Period,
    IDs = gb_sets:to_list(gb_trees:get(Slot, PI)),
    PI1 = gb_trees:update(Slot, gb_sets:empty(), PI),
    State#state{insert = IDs ++ Insert, period_insert = PI1}.

flush_all_period(#state{period = undefined} = State) ->
    State;
flush_all_period(#state{insert = Insert,
    period = Period,
    period_insert = PI} = State) ->
    IDs = lists:append([gb_sets:to_list(V) || {_, V} <- gb_trees:to_list(PI)]),
    NewPI = new_period_insert(Period),
    State#state{insert = IDs ++ Insert, period_insert = NewPI}.