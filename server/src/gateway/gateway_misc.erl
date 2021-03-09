-module(gateway_misc).
-include("proto/gateway.hrl").


-include("global.hrl").

%% API
-export([
    pid/1,
    register_name/1,
    get_role_gpname/1,
    role_level_and_game_channel_id/3,
    exit/2,
    exit/1,
    is_fit_condition/1,
    is_fit_condition2/4,
    stop_prepare/0,
    set_stop_fast/0
]).

-export([
    send/2
]).

%%--------------------------------------------------------------------
%% External APIs
%%--------------------------------------------------------------------

%% @doc 判断指定的网关tcp_client进程名是否存在
pid(RoleID) when erlang:is_integer(RoleID) ->
    erlang:whereis(get_role_gpname(RoleID));
pid(Name) when erlang:is_atom(Name) ->
    erlang:whereis(Name);
pid(PID) when erlang:is_pid(PID) ->
    PID.

register_name(RoleID) ->
    RegName = get_role_gpname(RoleID),
    erlang:register(RegName, erlang:self()).

get_role_gpname(RoleID) ->
    lib_tool:list_to_atom(lists:concat(["gate_", RoleID])).

role_level_and_game_channel_id(GatewayPID, RoleLv, GameChannelID) ->
    erlang:send(GatewayPID, {set_role_level_and_game_channel_id, RoleLv, GameChannelID}).



send(undefined, _Msg) ->
    ignore;
send(RoleID, Msg) when erlang:is_integer(RoleID) ->
    case gateway_misc:pid(RoleID) of
        PID when erlang:is_pid(PID) ->
            erlang:send(PID, Msg);
        _ ->
            error
    end;
send(PID, Msg) when erlang:is_pid(PID) ->
    erlang:send(PID, Msg).

exit(Error) ->
    case gateway_tcp_client:is_gateway_server() of
        true ->
            erlang:send(erlang:self(), {error_exit, Error});
        _ ->
            case mod_role_dict:get_gateway_pid() of
                GateWayPID when erlang:is_pid(GateWayPID) ->
                    gateway_misc:exit(GateWayPID, Error);
                _ ->
                    error
            end
    end.


exit(GatewayPID, Error) ->
    erlang:send(GatewayPID, {error_exit, Error}).

is_fit_condition(Condition) ->
    RoleID = gateway_tcp_client:get_role_id(),
    RoleLevel = gateway_tcp_client:get_role_level(),
    RoleGameChannelId = gateway_tcp_client:get_role_game_channel_id(),
    is_fit_condition2(Condition, RoleID, RoleLevel,RoleGameChannelId).

is_fit_condition2(#r_broadcast_condition{ignore_ids = IgnoreIDs, min_level = MinLevel, max_level = MaxLevel, game_channel_id = GameChannelId}, RoleID, RoleLevel, RoleGameChannelId) ->
    (not lists:member(RoleID, IgnoreIDs)) andalso (MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel) andalso (GameChannelId =:= undefined orelse GameChannelId =:= RoleGameChannelId);
is_fit_condition2(_Condition, _RoleID, _RoleLevel,_RoleGameChannelId) ->
    true.


%% 关闭网关的阻塞以及通知
stop_prepare() ->
    PrepareTime = get_prepare_time(),
    case common_config:is_game_node() of
        true ->
            [begin
                 if
                     N > 60 andalso (N rem 15) =:= 0 -> %% 15s提醒一次
                         catch common_broadcast:send_world_common_notice(?NOTICE_STOP_SERVER, [lib_tool:to_list(N)]);
                     N > 10 andalso N =< 60 andalso (N rem 10) =:= 0 -> %% 10s提醒一次
                         catch common_broadcast:send_world_common_notice(?NOTICE_STOP_SERVER, [lib_tool:to_list(N)]);
                     N >= 0 andalso N =< 10 -> %% 1s提醒一次
                         catch common_broadcast:send_world_common_notice(?NOTICE_STOP_SERVER, [lib_tool:to_list(N)]);
                     true ->
                         ok
                 end,
                 timer:sleep(1000)
             end || N <- lists:reverse(lists:seq(1, PrepareTime))];
        _ ->
            ok
    end,
    ok.

get_prepare_time() ->
    case common_config:is_debug() orelse common_config:is_lite() of
        true ->
            3;
        _ ->
            ?IF(is_stop_fast(), 10, 30)
    end.

is_stop_fast() ->
    erlang:erase({?MODULE, fast_stop}) =:= true.


set_stop_fast() ->
    erlang:put({?MODULE, fast_stop}, true).
%% ?INFO_MSG("set urgent, stop fast", []),
%% try %% 只能放在内存，不能写文件
%%     {Mod, Code} = dynamic_compile:from_string("-module(stop_fast). -export([is_stop_fast/0]). is_stop_fast() -> true.\n"),
%%     code:load_binary(Mod, "stop_fast.erl", Code)
%% catch
%%     _E1:_E2 -> ?ERROR_MSG("can not stop fast:~w :~w", [_E1,_E2])
%% end,
%% ok.