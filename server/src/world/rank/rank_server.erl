%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十一月 2017 21:15
%%%-------------------------------------------------------------------
-module(rank_server).
-author("laijichang").
-include("global.hrl").
-include("rank.hrl").

%% API
-export([
    start/0,
    start_link/0,
    handle/1
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
    info/1
]).

-export([
    gm_del_rank/1,
    gm_all_rank/0,
    gm_set_heap_size/0
]).

info(Info) ->
    pname_server:send(?MODULE, Info).

gm_all_rank() ->
    pname_server:send(?MODULE, all_rank).

gm_del_rank(RankID) ->
    pname_server:send(?MODULE, {gm_del_rank, RankID}).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

handle(Info) ->
    do_handle(Info).

gm_set_heap_size() ->
    pname_server:send(?MODULE, gm_set_heap_size).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [1000, 0]),
    [init_rank(RankConfig) || RankConfig <- ?RANK_LIST],
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
    time_tool:dereg(world, [1000]),
    do_all_rank(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle(zeroclock) ->
    do_zeroclock();
do_handle({rank_insert_elements, RankID, Elements}) ->
    do_insert_elements(RankID, Elements);
do_handle(all_rank) ->
    do_all_rank();
do_handle({gm_del_rank, RankID}) ->
    do_gm_del_rank(RankID);
do_handle(gm_set_heap_size) ->
    [ erlang:put({heap_max_size, RankID}, MaxNum) || #c_rank_config{rank_id = RankID, max_num = MaxNum} <- ?RANK_LIST];
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

init_rank(RankConfig) ->
    #c_rank_config{rank_id = RankID, mod = Mod, max_num = MaxNum} = RankConfig,
    code:ensure_loaded(Mod),
    case erlang:function_exported(Mod, init_rank, 2) of
        true ->
            Mod:init_rank(RankID, MaxNum);
        _ ->
            ignore
    end.

do_loop(Now) ->
    {_, {_Hour, Min, _Sec}} = time_tool:timestamp_to_datetime(Now),
    case Min rem 10 =:= 0 andalso (not rank_data:has_rank(Min)) of
        true -> %% 10分钟排一次
            rank_data:set_rank_min(Min),
            do_all_rank();
        _ ->
            ignore
    end.

%% 对所有元素进行排行
do_all_rank() ->
    [begin
         #c_rank_config{rank_id = RankID, mod = Mod} = RankConfig,
         case erlang:function_exported(Mod, rank, 1) of
             true ->
                 Mod:rank(RankID);
             _ ->
                 ok
         end
     end || RankConfig <- ?RANK_LIST].

do_gm_del_rank(RankID) ->
    [begin
         #c_rank_config{rank_id = ConfigRankID, mod = Mod, max_num = MaxNum} = RankConfig,
         case ConfigRankID =:= RankID of
             true ->
                 lib_minheap:delete_heap(RankID),
                 db:delete(?DB_RANK_P, RankID),
                 case erlang:function_exported(Mod, init_rank, 2) of
                     true ->
                         Mod:init_rank(RankID, MaxNum);
                     _ ->
                         ignore
                 end;
             _ ->
                 ok
         end
     end || RankConfig <- ?RANK_LIST].


%% 插入元素
do_insert_elements(RankID, Elements) ->
    [lib_minheap:insert_element(RankID, Key, Element) || {Key, Element} <- Elements].


%%零点
do_zeroclock() ->
    rank_misc:do_log(),
    [begin
         #c_rank_config{rank_id = RankID, mod = Mod} = RankConfig,
         case erlang:function_exported(Mod, zero, 1) of
             true ->
                 Mod:zero(RankID);
             _ ->
                 ok
         end
     end || RankConfig <- ?RANK_LIST].