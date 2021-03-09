%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     消息中转进程
%%% @end
%%% Created : 22. 二月 2019 14:25
%%%-------------------------------------------------------------------
-module(node_interchange_server).
-author("laijichang").
-include("node.hrl").

-export([
    start/0,
    start_link/0
]).

%% gen_server API
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    cross_observe/2
]).

-export([
    send_req/1,
    return_req/1
]).

start() ->
    node_sup:start_child(?MODULE, node_misc:get_node_key()).

start_link() ->
    gen_server:start_link({local, node_misc:get_node_key()}, ?MODULE, [], []).

cross_observe(FromRoleID, ToRoleID) ->
    FromNodeKey = node_misc:get_node_key(),
    Args = #r_interchange_args{
        from_node_key = FromNodeKey,
        to_node_key = node_misc:get_node_key_by_role_id(ToRoleID),
        id = ?INTERCHANGE_CROSS_OBSERVE,
        to_args = ToRoleID,
        call_back_args = FromRoleID
    },
    send_req(Args).


send_req(Args) ->
    #r_interchange_args{from_node_key = FromNodeKey} = Args,
    send_req(FromNodeKey, Args).
send_req(ToNodeKey, Args) ->
    info(ToNodeKey, {send_req, Args}).

return_req(Args) ->
    #r_interchange_args{to_node_key = ToNodeKey} = Args,
    return_req(ToNodeKey, Args).
return_req(ToNodeKey, Args) ->
    info(ToNodeKey, {return_req, Args}).

info(NodeKey, Info) ->
    case pname_server:pid(NodeKey) of
        PID when erlang:is_pid(PID) ->
            pname_server:send(PID, Info);
        _ ->
            ?WARNING_MSG("NodeKey not found : ~w", [NodeKey])
    end.
%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    PName = node_misc:get_node_key(),
    pname_server:reg(PName, erlang:self()),
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
do_handle({send_req, Args}) ->
    do_send_req(Args);
do_handle({return_req, Args}) ->
    do_return_req(Args);
do_handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).

do_send_req(Args) ->
    MyNodeKey = node_misc:get_node_key(),
    #r_interchange_args{to_node_key = ToNodeKey} = Args,
    case MyNodeKey =:= ToNodeKey of
        true -> %%
            do_send_req2(Args);
        _ ->
            IsCrossNodeKey = node_misc:is_cross_node_key(MyNodeKey),
            IsCenterNodeKey = node_misc:is_center_node_key(MyNodeKey),
            if
                IsCenterNodeKey -> %% 中央服节点，直接转发
                    send_req(ToNodeKey, Args);
                IsCrossNodeKey -> %% 跨服节点
                    case pname_server:pid(ToNodeKey) of
                        PID when erlang:is_pid(PID) ->
                            send_req(ToNodeKey, Args);
                        _ -> %% 找不到这个跨服连接的节点，发往中央服，让中央服转发
                            send_req(node_misc:get_center_node_key(), Args)
                    end;
                true ->
                    send_req(node_misc:game_get_cross_node_key(), Args)
            end
    end.

do_send_req2(Args) ->
    #r_interchange_args{id = ID} = Args,
    if
        ID =:= ?INTERCHANGE_CROSS_OBSERVE ->
            mod_role_extra:do_cross_observer(Args)
    end.

do_return_req(Args) ->
    MyNodeKey = node_misc:get_node_key(),
    #r_interchange_args{from_node_key = FromNodeKey} = Args,
    case MyNodeKey =:= FromNodeKey of
        true -> %%
            do_return_req2(Args);
        _ ->
            IsCrossNodeKey = node_misc:is_cross_node_key(MyNodeKey),
            IsCenterNodeKey = node_misc:is_center_node_key(MyNodeKey),
            if
                IsCenterNodeKey -> %% 中央服节点，直接转发
                    return_req(FromNodeKey, Args);
                IsCrossNodeKey -> %% 跨服节点
                    case pname_server:pid(FromNodeKey) of
                        PID when erlang:is_pid(PID) ->
                            return_req(FromNodeKey, Args);
                        _ -> %% 找不到这个跨服连接的节点，发往中央服，让中央服转发
                            return_req(node_misc:get_center_node_key(), Args)
                    end;
                true ->
                    return_req(node_misc:game_get_cross_node_key(), Args)
            end
    end.

do_return_req2(Args) ->
    #r_interchange_args{
        id = ID,
        call_back_args = CallBackArgs,
        call_back_info = CallBackInfo
    } = Args,
    if
        ID =:= ?INTERCHANGE_CROSS_OBSERVE ->
            common_misc:unicast(CallBackArgs, CallBackInfo)
    end.

%%%===================================================================
%%% data
%%%===================================================================
