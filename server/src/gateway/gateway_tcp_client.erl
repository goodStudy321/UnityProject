-module(gateway_tcp_client).
-include("proto/gateway.hrl").
-include("gateway.hrl").
-include("global.hrl").

-behaviour(gen_server).

%% API
-export([start_link/3,start/3]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

%% internal API
-export([
    get_socket/0
]).

-export([
    get_map_pid/0,
    get_role_pid/0,
    get_role_id/0,
    get_role_level/0,
    get_role_game_channel_id/0,
    is_gateway_server/0,
    set_last_hb_time/1
]).

-export([
    add_packet_num/1
]).

%% 与error_code区分
-define(GATEWAY_STATE_STAND, stand).
-define(GATEWAY_STATE_LOGIN, login).
-define(GATEWAY_STATE_NORMAL, normal).

%% 每秒钟最多发几个这样的包，其他的丢掉 (目前每秒最多看到20次别人的战斗广播)
-define(LIMITED_RECORD_PER_SECOND, 20).

%% 一个周期的他人广播包量
-define(PASSIVE_MSG_COUNTER, 50).
-define(PASSIVE_LOOP_INTERVAL, 100).
-define(PASSIVE_MSG_MAX_COUNTER, 2000).
-record(state, {gateway_state, err_code, is_trace = false}).
%%%===================================================================
%%% API
%%%===================================================================
start(ClientSocket, GatewayPort, Record) ->
    %% 获取玩家IP地址
    IP =
        case inet:peername(ClientSocket) of
            {ok, {TmpIP, _}} ->
                TmpIP;
            {error, Reason} ->
                ?INFO_MSG("~ts:~w", ["获取玩家IP失败", Reason]),
                "127.0.0.1"
        end,
    {ok, PID} = gateway_tcp_client_sup:start_client(ClientSocket, GatewayPort, lib_tool:ip_to_str(IP)),
    try
        ok = inet:setopts(ClientSocket, [{packet, 4}, binary, {active, false},
                                    {high_watermark, 32 * 1024},
                                    {low_watermark, 24 * 1024},
                                    {nodelay, true}, {delay_send, false}]),
        ok = gen_tcp:controlling_process(ClientSocket, PID),
        erlang:send(PID, work)
    catch
        Err1:Err2 ->
            ?ERROR_MSG("start client err:~w", [{Err1,Err2}]),
            erlang:send(PID, {error_exit, ?ERROR_SYSTEM_ERROR_012})
    end,
    case Record of
        undefined ->
            ignore;
        _ ->
            erlang:send(PID, {inet_async, ClientSocket, ok, {ok, Record}})
    end.

start_link(Socket, GatewayPort, Record) ->
    gen_server:start_link(?MODULE, [Socket, GatewayPort, Record], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================


init([ClientSocket, Port, IP]) ->
    ?INFO_MSG("new_client ~s:~w sock:~w self():~w",[IP,Port,ClientSocket,self()]),
    erlang:process_flag(trap_exit, true),
    set_port(Port),
    set_ip(IP),
    set_socket(ClientSocket),
    set_passive_bins([]),
    set_gateway_server(),
    set_packet_check(#r_packet_check{}),
    {ok, #state{gateway_state=?GATEWAY_STATE_STAND, err_code=0}}.

handle_call(Request, _From, State) ->
    ?INFO_MSG("unknow call:~w ; from:~w ; state:~w", [Request, _From, State]),
    Reply = ok,
    {reply, Reply, State}.

handle_cast(Msg, State) ->
    ?INFO_MSG("unknow msg:~w ; state:~w", [Msg, State]),
    {noreply, State}.

handle_info({error_exit, ErrCode}, State) ->
    ?INFO_MSG("gateway_terminate:~w", [{gateway_terminate, ErrCode, State}]),
    {stop, normal, State#state{err_code=ErrCode}};

handle_info(Info,  #state{gateway_state=GatewayState, is_trace = IsTrace} = State) ->
    case IsTrace of
        true ->
            ?TRY_CATCH(trace(Info), Err1);
        _ ->
            ignore
    end,
    case catch do_handle(Info, GatewayState) of
        ok ->
            {noreply, State};
        {ok, NewGateWayState} ->
            {noreply, State#state{gateway_state=NewGateWayState}};
        Error ->
            ?ERROR_MSG("Error Msg:~w~n Error:~w;~w;", [Info, Error, State]),
            {noreply, State}
    end.


terminate(Reason, #state{gateway_state=GatewayState, err_code=ErrCode}) ->
    do_terminate(Reason, ErrCode, GatewayState),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

-define(LOGIN_MSG_FILTER, [m_role_guide_toc, m_auth_key_toc, m_create_role_toc, m_del_role_toc, m_select_role_toc, m_system_error_toc,
    m_role_reconnect_toc, m_pre_enter_toc, m_map_enter_toc]).
%% 处理服务器对服务器的请求
do_handle(work, ?GATEWAY_STATE_STAND) ->
    case start_role() of
        ok ->
            set_last_hb_time(time_tool:now()),
            time_tool:reg(gate,[1000]),
            {ok, ?GATEWAY_STATE_LOGIN};
        _ ->
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_039),
            ok
    end;
do_handle(Info, ?GATEWAY_STATE_STAND) ->
    ?INFO_MSG("~ts:~w", ["收到意外消息，玩家socket进程强制终止", Info]),
    catch erlang:port_close(get_socket()),
    gateway_misc:exit(?ERROR_SYSTEM_ERROR_040),
    ok;
do_handle(Info, GatewayState) ->
    case Info of
        {inet_async, _ClientSocket, _Ref, {ok, Data}} ->
            do_handle_data(Data);
        {gm_send_data, Data} ->
            do_handle_data(Data);
        {loop_sec, Now} ->
            do_second_loop(Now);
        {inet_async, _ClientSocket, _Ref, {error, closed}} ->
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_007),
            ok;
        {inet_async, _ClientSocket, _Ref, {error, _Reason}} ->
            ?ERROR_MSG("socket error:~w", [_Reason]),
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_011),
            ok;
        {inet_reply, _Sock, ok} ->
            ok;
        {inet_reply, _Sock, _Result} ->
            ?ERROR_MSG("reply error:~w", [_Result]),
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_041),
            ok;
        {tcpdump_trace, Account} ->
            common_debugger:try_tcpdump(Account, get_socket(), 300 ),
            ok;
        _ ->
            do_handle2(Info, GatewayState)
    end.

do_handle2(Info, ?GATEWAY_STATE_LOGIN) ->
    case Info of
        {message, Record} ->
            Element = erlang:element(1, Record),
            case lists:member(Element, ?LOGIN_MSG_FILTER) of
                true ->
                    do_send_message( Record);
                false ->
                    push_cache_records(Record),
                    ok
            end;
        {set_role_id, RoleID} ->
            ?INFO_MSG("test set_role_id:~w", [RoleID]),
            set_role_id(RoleID),
            gateway_misc:register_name(RoleID),
            do_clear_cache_records(),
            prim_inet:async_recv(get_socket(), 0, -1),
            {ok, ?GATEWAY_STATE_NORMAL};
        {set_role_level_and_game_channel_id, RoleLevel,GameChannelID} ->
            set_role_level(RoleLevel),
            set_role_game_channel_idl(GameChannelID),
            ok;
        _Info ->
            ?INFO_MSG("unknow msg:~w", [_Info]),
            ok
    end;
do_handle2(Info, ?GATEWAY_STATE_NORMAL) ->
    case Info of
        passive_loop ->
            do_passive_loop();
        {message, Record} ->
            do_send_message(Record);
        {messages, Records} ->
            do_send_message(Records);
        {binary, Bin} ->
            do_send_binary(Bin);
        {binary_filter, Condition, Bin} ->
            case gateway_misc:is_fit_condition(Condition) of
                true ->
                    do_send_binary(Bin);
                _ -> ok
            end;
        {binary_passive, Bin} ->
            do_send_binary_passive(Bin);
        {binary_limited, RecordName, Bin} ->
            do_send_binary_limited(RecordName, Bin);
        {role_enter_map, MapPID} ->
            set_map_pid(MapPID),
            ok;
        role_leave_map ->
            set_map_pid(undefined),
            ok;
        {set_role_level_and_game_channel_id, RoleLevel, GameChannelID} ->
            set_role_level(RoleLevel),
            set_role_game_channel_idl(GameChannelID),
            ok;
        _Other ->
            ?INFO_MSG("玩家循环中收到未知消息:~w", [_Other]),
            ok
    end.

start_role() ->
    ClientSocket = get_socket(),
    IP = get_ip(),
    %% 异步接收数据包
    prim_inet:async_recv(ClientSocket, 0, -1),
    case role_sup:start_role(self(), IP) of
        {ok, RolePID} ->
            set_role_pid(RolePID),
            ok;
        {error, Reason} ->
            ?INFO_MSG("~ts: IP:~p:~p Reason:~p", ["启动角色进程失败",get_ip(), Reason]),
            error
    end.

do_handle_data(Data)->
    case gateway_packet:unpack(Data) of
        {Record, Router} ->
            prim_inet:async_recv(get_socket(), 0, -1),
            gateway_router:router({Record, Router, get_role_id(), erlang:self()});
        _ ->
            ?ERROR_MSG("数据解析失败: ~p", [Data])
    end,
    add_packet_num(all),
    set_last_hb_time(time_tool:now()),
    ok.

do_terminate(_Reason, ErrCode, GatewayState) ->
    ErrCode2 = ?IF(ErrCode > 0, ErrCode, ?ERROR_SYSTEM_ERROR_001),
    RoleID = get_role_id(),
    Socket = get_socket(),
    ?WARNING_MSG("gateway_terminate ~w,~w,~w,~w,~w", [RoleID, Socket, ErrCode, _Reason, GatewayState]),
    catch erlang:unregister(gateway_misc:get_role_gpname(RoleID)),
    case GatewayState of
        ?GATEWAY_STATE_NORMAL ->
            catch time_tool:dereg(gate,[1000]);
        _ ->
            ignore
    end,
    case erlang:is_port(Socket) of
        true ->
            R = #m_system_error_toc{error_code = ErrCode2, need_reconnect = is_need_reconnect(ErrCode2)},
            gateway_packet:packet_send(Socket, R);
        false ->
            ignore
    end,
    %% 等待1秒钟，尽可能的让socket中的数据发送完成，socket不用关闭了，本进程退出后会自动关闭
    timer:sleep(200),
    ok.

do_second_loop(Now) ->
    time_tool:now_cached(Now),
    do_heartbeat_check(),
    do_packet_check(),
    do_clear_limited_records(),
    do_clear_passive_loop(),
    ok.

do_heartbeat_check() ->
    case lib_config:find(common, hb_check_closed) of
        [true]->
            ignore;
        _ ->
            MapPID = get_map_pid(),
            if
                MapPID =/= undefined ->
                    CheckTime = ?HEART_BEAT_CHECK_TIME;
                true -> %% 地图加载的心跳时间，多加1分钟吧
                    CheckTime = ?HEART_BEAT_CHECK_TIME + ?ONE_MINUTE
            end,
            LastHeartBeatTime = get_last_hb_time(),
            ?IF(time_tool:now() - LastHeartBeatTime > CheckTime, gateway_misc:exit(?ERROR_SYSTEM_ERROR_005), ok)
    end.

do_packet_check() ->
    #r_packet_check{
        loop_counter = LoopCounter,
        counter = Counter,
        blame_list = BlameList,
        record_list = RecordList} = PacketCheck = get_packet_check(),
    case LoopCounter >= ?PROTO_SECOND_COUNTER of
        true ->
            %% 消息队列检测
            case erlang:process_info(self(), message_queue_len) of
                {message_queue_len, QueueLen} when erlang:is_integer(QueueLen) andalso QueueLen > 200 ->
                    ?INFO_MSG("message_queue_len:~p ~p", [get_role_id(), QueueLen]),
                    do_flush_msg(),
                    gateway_misc:exit(?ERROR_SYSTEM_ERROR_014);
                _ ->ignore
            end,
            BlameAdd = get_blame_proto(RecordList, LoopCounter),
            BlameList2 = BlameAdd ++ BlameList,
            Counter2 = Counter + 1,
            RecordList2 = [],
            case Counter2 >= ?PROTO_CHECK_COUNTER of
                true ->
                    do_proto_check2(BlameList2),
                    set_packet_check(#r_packet_check{});
                _ ->
                    PacketCheck2 = PacketCheck#r_packet_check{
                        loop_counter = 0,
                        counter = Counter2,
                        blame_list = BlameList2,
                        record_list = RecordList2
                    },
                    set_packet_check(PacketCheck2)
            end;
        _ ->
            PacketCheck2 = PacketCheck#r_packet_check{loop_counter = LoopCounter + 1},
            set_packet_check(PacketCheck2)
    end.

do_proto_check2([]) ->
    ok;
do_proto_check2(BlameList) ->
    CounterList = get_blame_counter_list(BlameList, []),
    FlagList = [ Counter >= ?PROTO_CHECK_COUNTER - 1|| {_RecordName, Counter} <- CounterList],
    case lists:member(true, FlagList) of
        true ->
            ?ERROR_MSG("发包过快 BlameList:~w, CounterList:~w", [BlameList, CounterList]),
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_042);
        _ ->
            ok
    end.

get_blame_proto(RecordList, LoopCounter) ->
    get_blame_proto2(RecordList, ?PACKET_CHECK_LIST, LoopCounter, []).
get_blame_proto2([], _CheckList, _LoopCounter, Acc) ->
    Acc;
get_blame_proto2([{RecordName, NowVal}|R], CheckList, LoopCounter, Acc) ->
    {value, {RecordName, MaxVal}, CheckList2} = lists:keytake(RecordName, 1, CheckList),
    case NowVal div LoopCounter >= MaxVal of
        true ->
            get_blame_proto2(R, CheckList2, LoopCounter, [{RecordName, NowVal}|Acc]);
        _ ->
            get_blame_proto2(R, CheckList2, LoopCounter, Acc)
    end.

%% 获取计数
get_blame_counter_list([], Acc) ->
    Acc;
get_blame_counter_list([{RecordName, _Val}|R], Acc) ->
    Acc2 =
        case lists:keyfind(RecordName, 1, Acc) of
            {RecordName, OldVal} ->
                lists:keyreplace(RecordName, 1, Acc, {RecordName, OldVal + 1});
            _ ->
                [{RecordName, 1}|Acc]
        end,
    get_blame_counter_list(R, Acc2).

do_flush_msg() ->
    receive
        _R ->
            do_flush_msg()
    after 0 ->
            ok
    end.

do_clear_limited_records() ->
    [begin
         del_limited_record_counter(R)
     end || R <- get_limited_recordname()].

do_clear_passive_loop() ->
    case erlang:length(get_passive_bins()) >0 of
        true ->ignore;
        _ ->del_passive_bin_counter()
    end.

do_passive_loop() ->
    AllList = lists:reverse(get_passive_bins()),
    Len = erlang:length(AllList),
    case Len > ?PASSIVE_MSG_MAX_COUNTER of
        true ->
            set_passive_bins([]),
            ?INFO_MSG("玩家堵塞了 ~p 条消息", [AllList]),
            do_flush_msg(),
            gateway_misc:exit(?ERROR_SYSTEM_ERROR_043);
        false ->
            del_passive_bin_timer(),
            case Len > ?PASSIVE_MSG_COUNTER of
                true ->
                    RemainList = do_passive_loop(AllList,?PASSIVE_MSG_COUNTER),
                    do_send_passive_bin_loop(),
                    set_passive_bins(lists:reverse(RemainList)),
                    ok;
                false ->
                    del_passive_bin_counter(),
                    set_passive_bins([]),
                    [begin
                         gateway_packet:send(get_socket(), Bin)
                     end ||  Bin <- AllList]
            end
    end,
    ok.
do_passive_loop([],_) ->
    [];
do_passive_loop(Remains,0) ->
    Remains;
do_passive_loop([Bin|T],N) ->
    gateway_packet:send(get_socket(), Bin),
    do_passive_loop(T,N-1).

do_send_message(Records) when erlang:is_list(Records) ->
    [begin do_send_message(Record) end || Record <- Records],
    ok;
do_send_message(Record) ->
    gateway_packet:packet_send(get_socket(), Record),
    ok.

do_send_binary(Bin) ->
    gateway_packet:send(get_socket(), Bin),
    ok.

%%别人产生的广播包,每秒发送一定的数目，其他丢掉
do_send_binary_limited(RecordName, Bin) ->
    inc_limited_recordname(RecordName),
    case get_limited_record_counter(RecordName) > ?LIMITED_RECORD_PER_SECOND of
        true ->
            ignore;
        false ->
            inc_limited_record_counter(RecordName),
            gateway_packet:send(get_socket(), Bin)
    end,
    ok.

%% 别人产生的广播包，发送一定的数目，其他的下周期发送
do_send_binary_passive(Bin) ->
    case get_passive_bin_counter() > ?PASSIVE_MSG_COUNTER of
        true ->
            do_send_passive_bin_loop(),
            push_passive_bin(Bin);
        false ->
            inc_passive_bin_counter(),
            gateway_packet:send(get_socket(), Bin)
    end,
    ok.

do_send_passive_bin_loop() ->
    case passive_bin_timer_started() of
        false ->
            Ref = erlang:send_after(?PASSIVE_LOOP_INTERVAL, erlang:self(), passive_loop),
            set_passive_bin_timer(Ref);
        true ->
            ignore
    end.


%%--------------------------------------------------------------------
%% 进程字典内部操作
%%--------------------------------------------------------------------
set_ip(IP) ->
    erlang:put(ip, IP).
get_ip() ->
    erlang:get(ip).

set_port(Port) ->
    erlang:put(port, Port).

set_socket(Socket) ->
    erlang:put(socket, Socket).
get_socket() ->
    erlang:get(socket).

set_map_pid(PID) ->
    erlang:put(map_pid, PID).
get_map_pid()->
    erlang:get(map_pid).

get_role_pid()->
    erlang:get(role_pid).
set_role_pid(RolePID)->
    erlang:put(role_pid,RolePID).

get_role_id() ->
    erlang:get(gw_role_id).
set_role_id(RoleID) ->
    erlang:put(gw_role_id, RoleID).

get_role_level() ->
    case erlang:get(gw_role_lv) of
        RoleLv when erlang:is_integer(RoleLv) ->RoleLv;
        _ ->0
    end.

get_role_game_channel_id() ->
    case erlang:get(gw_role_game_channel_id) of
        RoleLv when erlang:is_integer(RoleLv) ->RoleLv;
        _ ->0
    end.

set_role_game_channel_idl(GameChannelId) ->
    erlang:put(gw_role_game_channel_id, GameChannelId).

set_role_level(RoleLv) ->
    erlang:put(gw_role_lv, RoleLv).


get_last_hb_time() ->
    erlang:get(last_hb_time).
set_last_hb_time(T) ->
    erlang:put(last_hb_time, T).

add_packet_num(RecordName) ->
    #r_packet_check{record_list = RecordList} = PacketCheck = get_packet_check(),
    RecordList2 =
        case lists:keyfind(RecordName, 1, RecordList) of
            {RecordName, Num} ->
                lists:keyreplace(RecordName, 1, RecordList, {RecordName, Num + 1});
            _ ->
                [{RecordName, 1}|RecordList]
        end,
    set_packet_check(PacketCheck#r_packet_check{record_list = RecordList2}).

get_packet_check() ->
    erlang:get({?MODULE, packet_list}).
set_packet_check(Record) ->
    erlang:put({?MODULE, packet_list}, Record).



%%登录时缓存records
push_cache_records(Record) ->
    erlang:put(cache_records, [Record | get_cache_records()]).
get_cache_records() ->
    case erlang:get(cache_records) of
        [_|_]=List -> List;
        _ ->[]
    end.
do_clear_cache_records() ->
    [begin
         do_send_message(R)
     end || R <- lists:reverse(get_cache_records())],
    erlang:erase(cache_records).

%%--------------------------------------------------------------------
%% 广播timer ref
%%--------------------------------------------------------------------
passive_bin_timer_started() ->
    erlang:get(passive_bin_timer) =/= undefined.
set_passive_bin_timer(Ref) ->
    erlang:put(passive_bin_timer, Ref).
del_passive_bin_timer() ->
    erlang:erase(passive_bin_timer).

%%每周期受限的包，之后的下周期发
get_passive_bin_counter() ->
    case erlang:get(passive_bin_counter) of
        C when erlang:is_integer(C) ->C;
        _ ->0
    end.
inc_passive_bin_counter() ->
    erlang:put(passive_bin_counter, get_passive_bin_counter() + 1).
del_passive_bin_counter() ->
    erlang:erase(passive_bin_counter).
get_passive_bins() ->
    case erlang:get(passive_bins) of
        [_|_] =Bins ->Bins;
        _ ->[]
    end.
push_passive_bin(Bin) ->
    erlang:put(passive_bins, [Bin | get_passive_bins()]).
set_passive_bins(Bins) ->
    erlang:put(passive_bins, Bins).

set_gateway_server() ->
    erlang:put(is_gateway, true).
is_gateway_server() ->
    erlang:get(is_gateway) =:= true.

%%每秒受限的包，之后丢掉
inc_limited_recordname(R) ->
    L = get_limited_recordname(),
    case lists:member(R, L) of
        true ->
            ignore;
        false ->
            erlang:put(limited_recordnames,[R | L])
    end.
get_limited_recordname() ->
    case erlang:get(limited_recordnames) of
        [_|_]=List -> List;
        _ ->[]
    end.
get_limited_record_counter(R) ->
    case erlang:get({limited_record_counter, R}) of
        C when erlang:is_integer(C) ->
            C;
        _ -> 0
    end.
del_limited_record_counter(R) ->
    erlang:erase({limited_record_counter, R}).
inc_limited_record_counter(R) ->
    erlang:put({limited_record_counter, R}, get_limited_record_counter(R) + 1).

trace(Info) ->
    case Info of
        {inet_reply, _Port, _Reply} ->
            next;
        {loop_sec, _Sec} ->
            next;
        {inet_async, _ClientSocket, _Ref, _Data} ->
            next;
        _ ->
            ok
    end.

is_need_reconnect(ErrCode) ->
    not lists:member(ErrCode, [
        ?ERROR_SYSTEM_ERROR_001,
        ?ERROR_SYSTEM_ERROR_008,
        ?ERROR_SYSTEM_ERROR_021,
        ?ERROR_SYSTEM_ERROR_026,
        ?ERROR_SYSTEM_ERROR_042
    ]).