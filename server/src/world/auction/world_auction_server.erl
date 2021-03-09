%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     拍卖行进程
%%% @end
%%% Created : 17. 六月 2019 11:02
%%%-------------------------------------------------------------------
-module(world_auction_server).
-author("laijichang").
-include("auction.hrl").
-include("global.hrl").

%% API
%% API
-export([
    start/0,
    start_link/0,
    i/0
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
    reload_config/0
]).

-export([
    info/1,
    call/1,
    info_mod/2,
    call_mod/2
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

i() ->
    call(i).

reload_config() ->
    info(reload_config).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

info_mod(Mod, Info) ->
    info({mod, Mod, Info}).

call_mod(Mod, Info) ->
    call({mod, Mod, Info}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    mod_auction_data:init(),
    time_tool:reg(world, [1000]),
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
do_handle(i) ->
    do_i();
do_handle(reload_config) ->
    mod_auction_data:init_sub_class_index();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

%% 每秒检测拍卖行里的道具
do_loop(Now) ->
    LastTime = mod_auction_data:get_last_loop_time(),
    mod_auction_data:set_last_loop_time(Now),
    do_loop2(LastTime + 1, Now).

do_loop2(Time, Now) when Time > Now ->
    ok;
do_loop2(Time, Now) ->
    #r_auction_time_hash{end_time = EndTime, ids = IDs} = mod_auction_data:get_end_time_hash(Time),
    mod_auction_data:del_end_time_hash(EndTime),
    do_goods_end_time(IDs),
    do_loop2(Time + 1, Now).

do_goods_end_time([]) ->
    ok;
do_goods_end_time([ID|R]) ->
    ?TRY_CATCH(mod_auction_goods:goods_end_time(auction_misc:get_auction_goods(ID))),
    do_goods_end_time(R).

do_i() ->
    {mod_auction_data:get_panel_roles()}.



