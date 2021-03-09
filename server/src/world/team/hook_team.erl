%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十月 2017 20:34
%%%-------------------------------------------------------------------
-module(hook_team).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    role_join_team/3,
    role_leave_team/2
]).

%% 要注意角色是否在线的处理！
role_join_team(RoleID, TeamID, TeamData) ->
    FunList =
        [
            fun() -> role_misc:info_role(RoleID, {mod, mod_role_team, {join_team, RoleID, TeamID, TeamData}}) end
        ],
    [?TRY_CATCH(F()) || F <- FunList].

%% 要注意角色是否在线的处理！
role_leave_team(RoleID, TeamID) ->
    FunList =
        [
            fun() -> role_misc:info_role(RoleID, {mod, mod_role_team, {leave_team, RoleID, TeamID}}) end
        ],
    [?TRY_CATCH(F()) || F <- FunList].
