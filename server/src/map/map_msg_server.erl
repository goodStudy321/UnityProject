%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 五月 2017 10:40
%%%-------------------------------------------------------------------
-module(map_msg_server).
-behaviour(gen_server).

-include("global.hrl").

%% API
-export([start_link/2]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state, {map_pname}).
-define(BINARY_LIMITED_RECORDS,[]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
start_link(MapPName, WorkerID) ->
    Name = lib_tool:list_to_atom(lists:concat([lib_tool:to_list(MapPName),"_msg_", WorkerID])),
    gen_server:start_link({local,Name},?MODULE, [MapPName], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
%%--------------------------------------------------------------------
init([MapPName]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{map_pname=MapPName}}.

%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request, State),
    {reply, Reply, State}.
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info({'EXIT', PID, _Reason}, #state{map_pname=MapPName} = State) ->
    ?INFO_MSG("map msg server receive exit msg from ~p, resaon: ~p", [PID, _Reason]),
    case erlang:whereis(MapPName) =:= PID of
        true ->
            {stop, normal, State};
        false ->
            {noreply, State}
    end;
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(normal, _State) ->
    ok;
terminate(shutdown, _State) ->
    ok;
terminate({shutdown, Reason}, State) ->
    ?INFO_MSG("Map broadcasting service is down, Reason: ~p, State: ~p, StackTrace: ~p",
        [Reason, State, erlang:get_stacktrace()]),
    ok;
terminate(Reason, State) ->
    ?ERROR_MSG("Map broadcasting service is down and it is very serious, Reason: ~p, State: ~p, StackTrace: ~p",
        [Reason, State, erlang:get_stacktrace()]),
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%% Internal functions
%%%===================================================================


do_handle({reg_role, Role}) ->
    do_reg_role(Role);
do_handle({dereg_role, RoleID}) ->
    do_dereg_role(RoleID);
do_handle({send_all_role, DataRecord}) ->
    do_send_all_role(DataRecord);
do_handle({send_all_gateway, DataRecord}) ->
    do_send_all_gateway(DataRecord);
do_handle({send_gateway_by_roleid, RoleIDs, DataRecord}) ->
    do_send_gateway_by_roleid(RoleIDs, DataRecord);
do_handle({send_gateway_by_rolegpid, RoleGPIDs, DataRecord}) ->
    do_send_gateway_by_rolegpid(RoleGPIDs, DataRecord);
do_handle({bc_msg_to_map, Msg})->
    do_bc_msg_to_map(Msg);
do_handle({bc_msg_to_map_roles, Rolelists, Msg})->
    do_bc_msg_to_map_roles(Rolelists, Msg);
do_handle({send_role_by_roleid, RoleIDs, Info}) ->
    do_send_role_by_roleid(RoleIDs, Info);
do_handle({func, F}) ->
    F();
do_handle(Info) ->
    ?ERROR_MSG("Unknow Info ~p", [Info]).

do_reg_role({RoleID,RolePID,RoleGPID}) ->
    Roles = get_roles(),
    case lists:member(RoleID, Roles) of
        true ->
            ignore;
        _ ->
            set_roles([RoleID|Roles]),
            set_role_pid(RoleID, RolePID, RoleGPID)
    end.
do_dereg_role(RoleID) ->
    Roles = get_roles(),
    case lists:member(RoleID, Roles) of
        true ->
            set_roles(lists:delete(RoleID, Roles)),
            erase_role_pid(RoleID);
        _ ->ignore
    end.

do_send_all_role(Record)->
    [begin
         case get_role_pid(RoleID) of
             {RoleID, RolePID, _RoleGPID} ->
                 pname_server:send(RolePID, Record);
             _ ->
                 ignore
         end,
         ok
     end || RoleID <- get_roles()],
    ok.

do_send_all_gateway(Record) ->
    Data = limit_record(Record),
    [begin
         case get_role_pid(RoleID) of
             {RoleID, _, RoleGPID} ->
                 pname_server:send(RoleGPID, Data);
             _ ->
                 ignore
         end,
         ok
     end || RoleID <- get_roles()],
    ok.
do_send_gateway_by_roleid([], _Record) ->
    ignore;
do_send_gateway_by_roleid(RoleIDs, Record) ->
    Data = limit_record(Record),
    [begin
         case get_role_pid(RoleID) of
             {RoleID,_,RoleGPID} ->
                 pname_server:send(RoleGPID, Data);
             _ ->ignore
         end
     end || RoleID <- RoleIDs],
    ok.

do_send_gateway_by_rolegpid([], _Record) ->
    ignore;
do_send_gateway_by_rolegpid(RoleGPIDs, Record) ->
    Data = limit_record(Record),
    [begin pname_server:send(RoleGPID, Data),ok end || RoleGPID <- RoleGPIDs],
    ok.

limit_record(Record)->
    Binary = gateway_packet:packet(Record),
    RecordName = erlang:element(1,Record),
    case lists:member(RecordName, ?BINARY_LIMITED_RECORDS) of
        true ->
            {binary_limited, RecordName, Binary};
        _ ->
            {binary, Binary}
    end.

do_bc_msg_to_map(Msg) when erlang:is_tuple(Msg) ->
    case Msg of
        {filter,Filter, Record} ->
            Data = {binary_filter, Filter, gateway_packet:packet(Record)};
        _ ->
            Data = {binary, gateway_packet:packet(Msg)}
    end,
    [begin
         gateway_misc:send(RoleID, Data)
     end || RoleID <- get_roles()].

do_bc_msg_to_map_roles(Rolelists,Msg) when erlang:is_list(Rolelists), erlang:is_tuple(Msg)->
    case Msg of
        {filter,Filter,Record} ->
            Data = {binary_filter, Filter, gateway_packet:packet(Record)};
        _ ->
            Data = {binary, gateway_packet:packet(Msg)}
    end,
    [ gateway_misc:send(RoleID, Data) || RoleID <- Rolelists];
do_bc_msg_to_map_roles(_, _Msg) ->
    ignore.

do_send_role_by_roleid(RoleIDs, Info) ->
    [begin
         case get_role_pid(RoleID) of
             {RoleID, RolePID, _RoleGPID} ->
                 pname_server:send(RolePID, Info);
             _ ->ignore
         end
     end || RoleID <- RoleIDs].
%%%===================================================================
%%% 数据操作
%%%===================================================================
set_roles(Roles) ->
    erlang:put(all_roles, Roles).
get_roles() ->
    case erlang:get(all_roles) of
        [_RoleID|_] = Roles ->
            Roles;
        _ ->[]
    end.

set_role_pid(RoleID, RolePID, RoleGPID) ->
    erlang:put({role_pid, RoleID}, {RoleID, RolePID, RoleGPID}).
get_role_pid(RoleID) ->
    erlang:get({role_pid, RoleID}).
erase_role_pid(RoleID) ->
    erlang:erase({role_pid, RoleID}).