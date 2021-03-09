%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 八月 2018 16:29
%%%-------------------------------------------------------------------
-module(world_notice_server).
-author("laijichang").
-include("global.hrl").
-include("broadcast.hrl").

%% API
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
    i/0,
    info/1,
    call/1
]).

-export([
    send_notice/6,
    del_notice/1
]).

i() ->
    call(i).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

send_notice(NoticeID, DataRecord, Interval, StartTime, EndTime, GameChannelList) ->
    NoticeList = [#r_notice{
        key = {NoticeID, GameChannelID},
        send_time = 0,
        start_time = StartTime,
        end_time = EndTime,
        record = DataRecord,
        %% 控制一下间隔，最低10秒
        interval = erlang:max(10, Interval)
    } || GameChannelID <- GameChannelList],
    info({send_notice, NoticeList}).

del_notice(Key) ->
    info({del_notice, Key}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [1000]),
    set_notice_list(world_data:get_notice_list()),
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
    world_data:set_notice_list(get_notice_list()),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle({send_notice, NoticeList}) ->
    add_notice(NoticeList);
do_handle({del_notice, Key}) ->
    delete_notice(Key);
do_handle(i) ->
    get_notice_list();
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_loop(Now) ->
    NoticeList = get_notice_list(),
    case NoticeList =/= [] of
        true ->
            GameChannelRoles = get_game_channel_roles(),
            NoticeList2 = do_send_notice(NoticeList, Now, GameChannelRoles, []),
            set_notice_list(NoticeList2);
        _ ->
            ok
    end.

do_send_notice([], _Now, _GameChannelRoles, NoticeAcc) ->
    lists:reverse(NoticeAcc);
do_send_notice([Notice|R], Now, GameChannelRoles, NoticeAcc) ->
    #r_notice{
        key = {_ID, GameChannelID},
        send_time = SendTime,
        record = DataRecord,
        interval = Interval,
        start_time = StartTime,
        end_time = EndTime
    } = Notice,
    if
        Now > EndTime -> %% 结束了
            do_send_notice(R, Now, GameChannelRoles, NoticeAcc);
        Now >= SendTime andalso Now >= StartTime -> %% 可以推送了
            Roles = get_roles_by_game_channel_id(GameChannelID, GameChannelRoles),
            common_broadcast:bc_record_to_roles(Roles, DataRecord),
            Notice2 = Notice#r_notice{send_time = Now + Interval},
            do_send_notice(R, Now, GameChannelRoles, [Notice2|NoticeAcc]);
        true ->
            do_send_notice(R, Now, GameChannelRoles, [Notice|NoticeAcc])
    end.

get_roles_by_game_channel_id(GameChannelID, GameChannelRoles) ->
    case lists:keyfind(GameChannelID, 1, GameChannelRoles) of
        {_, Roles} ->
            Roles;
        _ ->
            []
    end.

get_game_channel_roles() ->
    Roles = world_online_server:get_all_info(),
    lists:foldl(
        fun(#r_role_online{role_id = RoleID, game_channel_id = GameChannelID}, Acc) ->
            case lists:keytake(GameChannelID, 1, Acc) of
                {value, {GameChannelID, OldRoles}, Acc2} ->
                    [{GameChannelID, [RoleID|OldRoles]}|Acc2];
                _ ->
                    [{GameChannelID, [RoleID]}|Acc]
            end
        end, [], Roles).
%%%===================================================================
%%% 数据操作
%%%===================================================================
add_notice(AddNoticeList) ->
    NoticeList = get_notice_list(),
    NoticeList2 = add_notice2(AddNoticeList, NoticeList),
    set_notice_list(NoticeList2).

add_notice2([], NoticeList) ->
    NoticeList;
add_notice2([Notice|R], NoticeList) ->
    NoticeList2 = lists:keystore(Notice#r_notice.key, #r_notice.key, NoticeList, Notice),
    add_notice2(R, NoticeList2).

delete_notice(KeyList) ->
    NoticeList = get_notice_list(),
    NoticeList2 = delete_notice2(KeyList, NoticeList),
    set_notice_list(NoticeList2).

delete_notice2([], NoticeList) ->
    NoticeList;
delete_notice2([Key|R], NoticeList) ->
    NoticeList2 = lists:keydelete(Key, #r_notice.key, NoticeList),
    delete_notice2(R, NoticeList2).

set_notice_list(List) ->
    erlang:put({?MODULE, notice_list}, List).
get_notice_list() ->
    erlang:get({?MODULE, notice_list}).