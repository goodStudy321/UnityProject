%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 十月 2018 9:40
%%%-------------------------------------------------------------------
-module(robot_manager).
-author("laijichang").

%% API
-behaviour(gen_server).
-include("global.hrl").
-include("robot.hrl").

%% API
-export([
    i/0,
    start/0,
    start_link/0
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

-export([
    start_robot_by_index/2,
    start_robot_by_num/1,
    stop_robot/1
]).

-define(SERVER, ?MODULE).

-record(state, {}).

i() ->
    pname_server:call(?MODULE, i).

start() ->
    robot_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

start_robot_by_index(StartIndex, Type) ->
    pname_server:call(?MODULE, {start_robot_by_index, StartIndex, Type}).

start_robot_by_num(StartArgs) ->
    pname_server:send(?MODULE, {start_robot_by_num, StartArgs}).

stop_robot(StopArgs) ->
    pname_server:send(?MODULE, {stop_robot, StopArgs}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    time_tool:reg(robot, [1000]),
    {ok, #state{}}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop_sec();
do_handle({start_robot_by_index, Index, Type}) ->
    do_start_robot_by_index(Index, Type);
do_handle({start_robot_by_num, StartArgs}) ->
    do_start_robot_by_num(StartArgs);
do_handle({stop_robot, StopArgs}) ->
    do_stop_robot(StopArgs);
do_handle(i) ->
    erlang:get();
do_handle(Info) ->
    ?ERROR_MSG("unknow info : ~w", [Info]).

do_loop_sec() ->
    StartList = get_start_list(),
    StartList2 = do_loop_sec2(StartList, []),
    set_start_list(StartList2).

do_loop_sec2([], Acc) ->
    Acc;
do_loop_sec2([StartArgs|R], Acc) ->
    #r_robot_start{
        robot_type = RobotType,
        sec_start_num = SecStartNum,
        all_sec = AllSec,
        now_counter = NowCounter,
        all_robot_counter = AllRobotCounter,
        start_counter = StartCounter
    } = StartArgs,
    case (AllRobotCounter =:= 0 orelse ((NowCounter rem AllRobotCounter) =:= StartCounter)) of
        true ->
            do_loop_start(SecStartNum, RobotType);
        _ ->
            ok
    end,
    AllSec2 = AllSec - 1,
    NowCounter2 = NowCounter + 1,
    Acc2 = ?IF(AllSec2 > 0, [StartArgs#r_robot_start{all_sec = AllSec2, now_counter = NowCounter2}|Acc], Acc),
    do_loop_sec2(R, Acc2).

do_loop_start(SecStartNum, Type) ->
    IndexList = get_robot_index_list(Type),
    case IndexList =/= [] of
        true ->
            Index = lists:max(IndexList) + 1;
        _ ->
            Index = 1
    end,
    AddList = lists:seq(Index, Index + SecStartNum - 1),
    [ do_start_robot(Index2, Type) || Index2 <- lists:seq(Index, Index + SecStartNum - 1)],
    set_robot_index_list(Type, IndexList ++ AddList).

do_start_robot_by_index(Index, Type) ->
    IndexList = get_robot_index_list(Type),
    case lists:member(Index, IndexList) of
        true ->
            {error, exist};
        _ ->
            do_start_robot(Index, Type)
    end.

do_start_robot_by_num(StartArgs) ->
    add_start_list(StartArgs).

do_stop_robot(StopArgs) ->
    #r_robot_stop{
        stop_robot_type = RobotType,
        stop_num = StopNum
    } = StopArgs,
    if
        RobotType =:= 0 -> %% 所有的都停止
            set_start_list([]),
            [ do_stop_robot2(Type, IndexList, StopNum) || {Type, IndexList} <- get_all_index_list()];
        true ->
            StartList = get_start_list(),
            set_start_list(lists:keydelete(RobotType, #r_robot_start.robot_type, StartList)),
            IndexList = get_robot_index_list(RobotType),
            do_stop_robot2(RobotType, IndexList, StopNum)
    end.

do_stop_robot2(RobotType, IndexList, 0) ->
    set_robot_index_list(RobotType, IndexList);
do_stop_robot2(RobotType, [], _StopNum) ->
    set_robot_index_list(RobotType, []);
do_stop_robot2(RobotType, [Index|R], StopNum) ->
    PName = get_robot_pid_name(get_start_index_by_type(Index, RobotType)),
    ?TRY_CATCH(pname_server:send(PName, exit)),
    do_stop_robot2(RobotType, R, StopNum - 1).


do_start_robot(Index, Type) ->
    StartIndex = get_start_index_by_type(Index, Type),
    case lib_config:find(cfg_robot_ai, connect) of
        [{IP, Port}] ->
            ok;
        _ ->
            IP = "127.0.0.1",
            Port = common_config:get_gateway_port()
    end,
    Account = get_robot_account(StartIndex),
    PIDName = get_robot_pid_name(StartIndex),
    {ok, _PID} = robot_client:start(Account, PIDName, IP, Port, Type),
    add_robot_index(Type, Index),
    ok.

get_start_index_by_type(Index, Type) ->
    Index * 100 + Type.

get_robot_account(StartIndex) ->
    lists:concat([common_config:get_server_id(), StartIndex]).

get_robot_pid_name(StartIndex) ->
    lib_tool:to_atom(get_robot_account(StartIndex)).
%%%===================================================================
%%% 数据操作
%%%===================================================================
add_robot_index(Type, Index) ->
    set_robot_index_list(Type, [Index|get_robot_index_list(Type)]).
set_robot_index_list(Type, List) ->
    AllList = get_all_index_list(),
    AllList2 = lists:keystore(Type, 1, AllList, {Type, List}),
    set_all_index_list(AllList2).
get_robot_index_list(Type) ->
    AllList = get_all_index_list(),
    case lists:keyfind(Type, 1, AllList) of
        {_, List} ->
            List;
        _ ->
            []
    end.

set_all_index_list(List) ->
    erlang:put({?MODULE, robot_index}, List).
get_all_index_list() ->
    case erlang:get({?MODULE, robot_index}) of
        [_|_] = List->
            List;
        _ ->
            []
    end.

add_start_list(StartArgs) ->
    StartList = get_start_list(),
    StartList2 = lists:keystore(StartArgs#r_robot_start.robot_type, #r_robot_start.robot_type, StartList, StartArgs),
    set_start_list(StartList2).
set_start_list(List) ->
    erlang:put({?MODULE, start_list}, List).
get_start_list() ->
    case erlang:get({?MODULE, start_list}) of
        [_|_] = List->
            List;
        _ ->
            []
    end.




