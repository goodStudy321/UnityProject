%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 五月 2017 15:45
%%%-------------------------------------------------------------------
-module(mod_map_role_auth).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    auth_enter/2
]).

auth_enter(RoleID, MapPName) ->
    case map_server:is_map_process() of
        true ->
            do_auth_enter(RoleID);
        _ ->
            Func = fun() -> ?MODULE:auth_enter(RoleID, MapPName) end,
            map_misc:call(MapPName, Func)
    end.

do_auth_enter(_RoleID) ->
    case erlang:length(mod_map_ets:get_in_map_roles()) < ?MAP_MAX_ROLE_NUM of
        true ->
            true;
        _ ->
            {error, ?ERROR_PRE_ENTER_022}
    end.
