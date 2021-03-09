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
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
    terminate/2, code_change/3]).

-record(state, {}).

-define(DAY_SECOND,86400).

-type child() :: 
        'undefined' | pid().
-type startchild_err() ::
        'already_present'
        | {'already_started', Child :: child()}
        | term().
-type startchild_ret() ::
        {'ok', Child :: child()} 
        | {'ok', Child :: child(), Info :: term()}
        | {'error', startchild_err()}.


-spec start(SupName, PName, LoopMSecs) -> startchild_ret() when
      SupName :: atom(),
      PName :: atom(),
      LoopMSecs :: [pos_integer()].
%% @doc 启动秒循环的mtime_XXX_server
start(SupName,PName,LoopMSecs) ->
    [ case erlang:is_integer(LoopMSec) andalso LoopMSec =< 2000 andalso LoopMSec >=0 of
          true->ok;
          false->erlang:throw({time_server,illogical_loopms,PName,LoopMSecs})
      end  ||LoopMSec<-LoopMSecs],
    {ok, _} = supervisor:start_child(
        SupName,
        {PName, {?MODULE, start_link, [PName,LoopMSecs]}, transient, 10000, worker, [?MODULE]}).

%%--------------------------------------------------------------------
start_link(PName,LoopMSecs) ->
    gen_server:start_link({local, PName}, ?MODULE, [LoopMSecs], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
init([LoopMSecs]) ->
    erlang:process_flag(trap_exit, true),
    set_lastnow(time_tool:now_os()),
    erlang:put(next_midnight, time_tool:nextnight()),
    [begin
         case LoopMSec =:= 0 of
             true ->erlang:put(zeroclock_flag,true);
             _ -> erlang:send_after(LoopMSec,self(),{loop_ms,LoopMSec})
         end
     end || LoopMSec <- LoopMSecs],
    {ok, #state{}}.

handle_call({get_reg_pids,LoopMSec}, _From, State) ->
    case erlang:get({reg_pids,LoopMSec}) of
        [_|_] = List ->ignore;
        _ ->List =[]
    end,
    {reply, List, State};
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    {reply, ignore, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @doc 秒循环
handle_info({loop_ms,1000}, State) ->
    erlang:send_after(1000,self(),{loop_ms,1000}),
    Now = time_tool:now_os(),
    dispatch(1000,{loop_sec,Now}),
    %%0点处理
    case erlang:get(zeroclock_flag) of
        true ->
            NextNight = erlang:get(next_midnight),
            LastNow = get_lastnow(),
            case NextNight > LastNow andalso NextNight =< Now of
                true ->
                    erlang:put(next_midnight,NextNight+?DAY_SECOND),
                    dispatch(0,zeroclock);
                _ ->ignore
            end,
            ok;
        _ ->ignore
    end,
    set_lastnow(Now),
    {noreply, State};
%%其他毫秒循环
handle_info({loop_ms,LoopMSec}, State) ->
    erlang:send_after(LoopMSec,self(),{loop_ms, LoopMSec}),
    dispatch(LoopMSec,{loop_msec, time_tool:now_os_ms()}),
    {noreply, State};

handle_info({reg,LoopMSecs,PID}, State) ->
    [begin case erlang:get({reg_pids,LoopMSec}) of
               [_|_] = List ->
                   case lists:member(PID, List) of
                       true ->ignore;
                       _ ->
                           erlang:put({reg_pids,LoopMSec},[PID|List])
                   end;
               _ ->
                   erlang:put({reg_pids,LoopMSec},[PID])
           end end || LoopMSec <- LoopMSecs],
    {noreply, State};
handle_info({dereg,LoopMSecs,PID}, State) ->
    [begin
         case erlang:get({reg_pids,LoopMSec}) of
        [_|_] = List ->
            erlang:put({reg_pids,LoopMSec},lists:delete(PID, List));
        _ ->
            erlang:put({reg_pids,LoopMSec},[])
    end end || LoopMSec <- LoopMSecs],
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_lastnow() ->
    case erlang:get(last_now) of
        LastNow when erlang:is_integer(LastNow) ->
            LastNow;
        _ ->0
    end.
set_lastnow(TimeStamp) ->
    erlang:put(last_now,TimeStamp).

%% @doc 向各注册进程分发loop
dispatch(Key,Msg)->
    case erlang:get({reg_pids,Key}) of
        [_|_] = List ->
            NewList =  lists:foldl(fun(PID,ListT) ->
                case erlang:is_pid(PID) andalso erlang:is_process_alive(PID) of
                    true ->
                        catch (erlang:send(PID,Msg)),
                        [PID|ListT];
                    _ ->
                        ListT
                end end,[],List),
            erlang:put({reg_pids,Key},lists:reverse(NewList)),
            ok;
        _ ->
            ignore
    end.

