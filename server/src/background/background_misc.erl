%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 三月 2018 14:43
%%%-------------------------------------------------------------------
-module(background_misc).
-author("laijichang").

%% API
-export([
    log/1,
    cross_log/2
]).

log(Log) ->
    case lib_config:find(common, background_log_open) of
        [true] ->
            background_log_server:log(Log);
        _ ->
            ignore
    end.

%% 跨服写玩家日志，发到本服去写
cross_log(RoleID, Log) ->
    case common_config:is_cross_node() of
        true ->
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, log, [Log]});
        _ ->
            log(Log)
    end.