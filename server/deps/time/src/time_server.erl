%%%-------------------------------------------------------------------
%%% @doc
%%%-------------------------------------------------------------------
-module(time_server).

-behaviour(gen_server).
-export([
    start/3,
    start_link/2
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(DAY_SECOND, 86400).
-define(ZEROCLOCK_FLAG, zeroclock_flag).
-define(NEXT_MIDNIGHT, next_midnight).
-define(HOUR_CHANGE_FLAG, hour_change_flag).
-define(NEXT_HOUR, next_hour).

%% @doc 启动秒循环的time_XXX_server
start(SupName, PName, LoopMSecs) ->
    [ case (erlang:is_integer(LoopMSec) andalso LoopMSec =< 5000 andalso LoopMSec >=0) orelse LoopMSec =:= hour_change of
          true->
              ok;
          _ ->
              erlang:throw({time_server,illogical_loopms,PName,LoopMSecs})
      end || LoopMSec<-LoopMSecs],
    {ok, _} = supervisor:start_child(SupName, {PName, {?MODULE, start_link, [PName,LoopMSecs]}, transient, 10000, worker, [?MODULE]}).

%%--------------------------------------------------------------------
start_link(PName,LoopMSecs) ->
    gen_server:start_link({local, PName}, ?MODULE, [LoopMSecs], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([LoopMSecs]) ->
    erlang:process_flag(trap_exit, true),
    Now = time_tool:now_os(),
    set_last_time(Now),
    [begin
         if
             LoopMSec =:= 0 ->
                 erlang:put(?NEXT_MIDNIGHT, time_tool:nextnight()),
                 erlang:put(?ZEROCLOCK_FLAG,true);
             LoopMSec =:= hour_change ->
                 erlang:put(?NEXT_HOUR, Now + time_tool:diff_next_hour()),
                 erlang:put(?HOUR_CHANGE_FLAG, true);
             erlang:is_integer(LoopMSec) ->
                 erlang:send_after(LoopMSec,self(),{loop_ms,LoopMSec})
         end
     end || LoopMSec <- LoopMSecs],
    {ok, []}.

handle_call({get_reg_pids,LoopMSec}, _From, State) ->
    case erlang:get({reg_pids,LoopMSec}) of
        [_|_] =
            List ->ignore;
        _ ->
            List =[]
    end,
    {reply, List, State};


handle_call(_Request, _From, State) ->
    {reply, ignore, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% @doc 秒循环
handle_info({loop_ms, 1000}, State) ->
    erlang:send_after(1000, self(), {loop_ms, 1000}),
    LastTime = get_last_time(),
    Now = time_tool:now_os(),
    dispatch(1000, {loop_sec, Now}),
    %%0点处理
    case erlang:get(?ZEROCLOCK_FLAG) of
        true ->
            NextNight = erlang:get(?NEXT_MIDNIGHT),
            case NextNight > LastTime andalso NextNight =< Now of
                true ->
                    erlang:put(?NEXT_MIDNIGHT, NextNight + ?DAY_SECOND),
                    dispatch(0, zeroclock);
                _ ->
                    ignore
            end,
            ok;
        _ ->
            ignore
    end,
    %% 每小时变化通知
    case erlang:get(?HOUR_CHANGE_FLAG) of
        true ->
            NextHourTime = erlang:get(?NEXT_HOUR),
            case NextHourTime > LastTime andalso NextHourTime =< Now of
                true ->
                    erlang:put(next_hour, Now + time_tool:diff_next_hour()),
                    dispatch(hour_change, {hour_change, Now});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end,
    set_last_time(Now),
    {noreply, State};
%%其他毫秒循环
handle_info({loop_ms, LoopMSec}, State) ->
    erlang:send_after(LoopMSec, erlang:self(), {loop_ms, LoopMSec}),
    dispatch(LoopMSec, {loop_msec, time_tool:now_os_ms()}),
    {noreply, State};

handle_info({reg, LoopMSecs, PID}, State) ->
    [begin case erlang:get({reg_pids, LoopMSec}) of
               [_|_] = List ->
                   case lists:member(PID, List) of
                       true ->
                           ignore;
                       _ ->
                           erlang:put({reg_pids, LoopMSec}, [PID|List])
                   end;
               _ ->
                   erlang:put({reg_pids,LoopMSec},[PID])
           end end || LoopMSec <- LoopMSecs],
    {noreply, State};
handle_info({dereg, LoopMSecs, PID}, State) ->
    [begin
         case erlang:get({reg_pids, LoopMSec}) of
        [_|_] = List ->
            erlang:put({reg_pids, LoopMSec},lists:delete(PID, List));
        _ ->
            erlang:put({reg_pids, LoopMSec},[])
    end end || LoopMSec <- LoopMSecs],
    {noreply, State};
handle_info(reset_hour_change, State) ->
    Now = time_tool:now_os(),
    erlang:put(?NEXT_HOUR, Now + time_tool:diff_next_hour()),
    erlang:put(?HOUR_CHANGE_FLAG, true),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_last_time() ->
    case erlang:get({?MODULE, last_time}) of
        LastTime when erlang:is_integer(LastTime) ->
            LastTime;
        _ ->
            0
    end.
set_last_time(TimeStamp) ->
    erlang:put({?MODULE, last_time}, TimeStamp).

%% @doc 向各注册进程分发loop
dispatch(Key, Msg)->
    case erlang:get({reg_pids, Key}) of
        [_|_] = List ->
            NewList =
                lists:foldl(
                    fun(PID, ListT) ->
                        case erlang:is_pid(PID) andalso erlang:is_process_alive(PID) of
                            true ->
                                catch (erlang:send(PID, Msg)),
                                [PID|ListT];
                            _ ->
                                ListT
                        end end,[],List),
            erlang:put({reg_pids, Key}, lists:reverse(NewList)),
            ok;
        _ ->
            ignore
    end.

