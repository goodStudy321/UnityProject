%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 七月 2017 14:54
%%%-------------------------------------------------------------------
-module(mod_role_offline_event).
-author("laijichang").
-include("role.hrl").

%% API
-export([
    online/1
]).

online(#r_role{role_id = RoleID} = State) ->
    List = world_offline_event_server:role_online(RoleID),
    execute_offline_event(List),
    State.

execute_offline_event([]) ->
    ok;
execute_offline_event([{Mod, Fun, Args}|R]) ->
    ?TRY_CATCH(erlang:apply(Mod, Fun, Args)),
    execute_offline_event(R).
