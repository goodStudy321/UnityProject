%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     游戏服-太虚通天塔进程
%%% @end
%%% Created : 17. 九月 2019 10:40
%%%-------------------------------------------------------------------
-module(game_universe_server).
-author("laijichang").
-include("global.hrl").
-include("universe.hrl").

%% API
-export([
    start/0,
    start_link/0
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    center_update_data/2
]).

-export([
    node_up/1,

    info/1,
    call/1
]).

-export([
    get_floor/1,
    get_best_three/0,
    get_ranks/0
]).
%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

center_update_data(Key, Value) ->
    info({center_update_data, Key, Value}).

node_up(NodeName) ->
    info({node_up, NodeName}).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).
%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    lib_tool:init_ets(?ETS_UNIVERSE, #r_universe.key),
    {ok, []}.

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
    pname_server:dereg(?MODULE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({node_up, NodeName}) ->
    do_node_up(NodeName);
do_handle(get_center_data) ->
    do_get_center_data();
do_handle({center_send_data, AllData}) ->
    ets:delete_all_objects(?ETS_UNIVERSE),
    do_center_send_data(AllData);
do_handle({center_update_data, Key, Value}) ->
    do_center_update_data(Key, Value);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%% 中央服连接后，要去请求数据
do_node_up(NodeName) ->
    case common_config:get_center_node() =:= NodeName of
        true ->
            set_get_center_data(false),
            info(get_center_data);
        _ ->
            ok
    end.

%% 游戏服去中央服请求数据
do_get_center_data() ->
    case is_get_center_data() of
        true ->
            ok;
        _ ->
            erlang:send_after(30 * 1000, erlang:self(), get_center_data),
            center_universe_server:game_get_center_data(node_misc:get_node_id())
    end.

%% 中央服推送数据下来
do_center_send_data(AllData) ->
    set_data(AllData),
    set_get_center_data(true).

do_center_update_data(Key, Value) ->
    ?INFO_MSG("center_update_data :~w", [{Key, Value}]),
    set_data(Key, Value).
%%%===================================================================
%%% dict
%%%===================================================================
is_get_center_data() ->
    get_data(?UNIVERSE_GET_CENTER_DATA) =:= true.
set_get_center_data(Flag) ->
    set_data(?UNIVERSE_GET_CENTER_DATA, Flag).

get_floor(CopyID) ->
    get_data({?UNIVERSE_KEY_FLOOR, CopyID}).

get_best_three() ->
    get_data(?UNIVERSE_BEST_THREE_INFO).

get_ranks() ->
    case get_data(?UNIVERSE_FLOOR_RANK) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

get_data(Key) ->
    case ets:lookup(?ETS_UNIVERSE, Key) of
        [#r_universe{value = Value}] ->
            Value;
        _ ->
            undefined
    end.
set_data(Key, Value) ->
    set_data(#r_universe{key = Key, value = Value}).
set_data(Data) ->
    ets:insert(?ETS_UNIVERSE, Data).