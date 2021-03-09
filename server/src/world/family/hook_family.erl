%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十月 2017 10:23
%%%-------------------------------------------------------------------
-module(hook_family).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    role_join_family/4,
    role_leave_family/3
]).

-export([
    init/0,
    family_week_refresh/0,
    family_day_refresh/0,
    loop_integer_hour/0
]).

%% 要注意角色是否在线的处理！
role_join_family(RoleID, FamilyID, FamilyName, Title) ->
    FunList =
    [
        fun() ->
            role_misc:info_role(RoleID, {mod, mod_role_family, {join_family, RoleID, FamilyID, FamilyName, Title}}) end
    ],
    [?TRY_CATCH(F()) || F <- FunList].

%% 要注意角色是否在线的处理！
role_leave_family(RoleID, FamilyID, LeaveStatus) ->
    FunList =
    [
        fun() -> role_misc:info_role(RoleID, {mod, mod_role_family, {leave_family, RoleID, FamilyID, LeaveStatus}}) end
    ],
    [?TRY_CATCH(F()) || F <- FunList].



init() ->
    LastTime = world_data:get_family_week_refresh(),
    Now = time_tool:now(),
    case time_tool:is_same_week(LastTime, Now) of
        false ->
%%            mod_family_boss:refresh_boss_times(),
            world_data:set_family_week_refresh(Now);
        _ ->
            ok
    end.

family_week_refresh() ->
    Now = time_tool:now(),
    FunList =
    [
%%        fun() -> mod_family_boss:refresh_boss_times() end
    ],
    [?TRY_CATCH(F()) || F <- FunList],
    world_data:set_family_week_refresh(Now).


family_day_refresh() ->
    FunList =
    [
        fun() -> mod_family_red_packet:delete_overdue_red_packet() end,
        fun() -> mod_family_battle:refresh_salary() end
    ],
    [?TRY_CATCH(F()) || F <- FunList].



loop_integer_hour() ->
    FamilyList = mod_family_data:get_all_family(),
    Now = time_tool:now(),
    FunList =
    [
        fun() -> mod_family_battle:refresh_list() end,
        fun() -> [family_misc:log_family_status(FamilyData) || FamilyData <- FamilyList] end,
        fun() -> [family_misc:owner_transfers(FamilyData,Now) || FamilyData <- FamilyList] end
    ],
    [?TRY_CATCH(F()) || F <- FunList].