%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 八月 2017 10:28
%%%-------------------------------------------------------------------
-module(world_online_server).
-author("laijichang").

-behaviour(gen_server).
-include("global.hrl").

-define(ETS_ROLE_ONLINE, ets_role_online).
-define(LOG_MINUTE, 5 * ?ONE_MINUTE).

%% API
-export([
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
    notify_info/1,
    role_offline/1,
    get_role_info/1,
    get_all_info/0,
    get_online_num/0,
    get_online_role_ids/0
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

notify_info(RoleOnline) ->
    pname_server:send(?MODULE, {notify_info, RoleOnline}).

role_offline(RoleID) ->
    pname_server:send(?MODULE, {role_offline, RoleID}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    ets:new(?ETS_ROLE_ONLINE, [named_table, ordered_set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_role_online.role_id}]),
    erlang:send_after(?LOG_MINUTE * 1000, erlang:self(), log_online),
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
do_handle({notify_info, RoleOnline}) ->
    set_role_info(RoleOnline);
do_handle({role_offline, RoleID}) ->
    del_role_info(RoleID);
do_handle(log_online) ->
    erlang:send_after(?LOG_MINUTE * 1000, erlang:self(), log_online),
    do_log_online();
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_log_online() ->
    {Year, Month, Day} = time_tool:date(),
    %%OnlineNum = ets:info(?ETS_ROLE_ONLINE, size),
    ChannelList = do_get_channel_list(ets:tab2list(?ETS_ROLE_ONLINE), []),
    {LogList, GameChanelList} = lists:foldl(
        fun({GameChannelID, ChannelID, Num} = T, {Acc1, Acc2}) ->
            Log = #log_online{game_channel_id = GameChannelID, channel_id = ChannelID, online_num = Num, year = Year, month = Month, day = Day},
            {[Log|Acc1], [T|Acc2]}
        end, {[], []}, ChannelList),
    background_misc:log(LogList),
    common_pf:online_log(GameChanelList).

do_get_channel_list([], Acc) ->
    Acc;
do_get_channel_list([#r_role_online{game_channel_id = GameChanelID, channel_id = ChannelID}|R], Acc) ->
    case lists:keyfind(GameChanelID, 1, Acc) of
        {GameChanelID, _ChannelID, Num} ->
            Acc2 = lists:keyreplace(GameChanelID, 1, Acc, {GameChanelID, ChannelID, Num + 1});
        _ ->
            Acc2 = [{GameChanelID, ChannelID, 1}|Acc]
    end,
    do_get_channel_list(R, Acc2).

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_role_info(Info) ->
    ets:insert(?ETS_ROLE_ONLINE, Info).
del_role_info(RoleID) ->
    ets:delete(?ETS_ROLE_ONLINE, RoleID).
get_role_info(RoleID) ->
    ets:lookup(?ETS_ROLE_ONLINE, RoleID).
get_all_info() ->
    ets:tab2list(?ETS_ROLE_ONLINE).

get_online_num() ->
    ets:info(?ETS_ROLE_ONLINE, size).
get_online_role_ids() ->
    [ RoleID|| #r_role_online{role_id = RoleID} <- get_all_info()].