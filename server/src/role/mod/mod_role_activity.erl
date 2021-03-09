%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 八月 2017 10:35
%%%-------------------------------------------------------------------
-module(mod_role_activity).
-author("laijichang").
-include("role.hrl").
-include("activity.hrl").
-include("proto/world_activity_server.hrl").

%% API
-export([
    online/1,
    level_up/3,
    family_change/1
]).

-export([
    is_activity_open/2
]).

online(State) ->
    RoleLevel = mod_role_data:get_role_level(State),
    ActivityList =
        [ begin
              #r_activity{id = ID, status = Status, start_time = StartTime, end_time = EndTime} = Activity,
              case Status of
                  ?STATUS_OPEN ->
                      [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ID),
                      ?IF(RoleLevel >= MinLevel, check_is_open(ID, Status, EndTime, State), []);
                  _ ->  %% 部分活动 特殊处理 开始前X分钟发协议给客户端显示活动图标（活动并未开始）
                      Now = time_tool:now(),
                      Minutes = common_misc:get_global_int(?GLOBAL_ACTIVITY_REMIND),
                      case Now >= StartTime - ?ONE_MINUTE * Minutes andalso Now < StartTime of
                          true ->
                              [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ID),
                              ?IF(RoleLevel >= MinLevel andalso lists:member(ID, ?ACTIVITY_LIST), #p_activity{id = ID, status = ?STATUS_BEFORE_MINUTES, end_time = StartTime}, []);
                          _ ->
                              []
                      end
              end
          end || Activity <- world_activity_server:get_all_activity()],
    common_misc:unicast(State#r_role.role_id, #m_activity_info_toc{activity_list = lists:flatten(ActivityList)}),
    State.



level_up(OldLevel, NewLevel, State) ->
    RoleID = State#r_role.role_id,
    ActivityList =
        [ begin
              #r_activity{id = ID, status = Status, end_time = EndTime} = Activity,
              case Status of
                  ?STATUS_OPEN ->
                      [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ID),
                      ?IF(OldLevel < MinLevel andalso MinLevel =< NewLevel, check_is_open(ID, Status, EndTime, State), []);
                  _ ->
                      []
              end
          end || Activity <- world_activity_server:get_all_activity()],
    common_misc:unicast(RoleID, #m_activity_info_toc{activity_list = lists:flatten(ActivityList)}).

family_change(State) ->
    RoleID = State#r_role.role_id,
    #r_activity{id = ID, status = Status, end_time = EndTime} = world_activity_server:get_activity(?ACTIVITY_FAMILY_TD),
    P = check_is_open(ID, Status, EndTime, State),
    common_misc:unicast(RoleID, #m_activity_info_toc{activity_list = [P]}).

%% 部分活动有额外条件
check_is_open(ID, Status, EndTime, State) ->
    Activity = #p_activity{id = ID, status = Status, end_time = EndTime},
    if
        ID =:= ?ACTIVITY_FAMILY_TD ->
            ?IF(mod_role_family_td:check_is_open(State), Activity, Activity#p_activity{status = ?STATUS_CLOSE});
        true ->
            Activity
    end.

is_activity_open(ActivityID, State) ->
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ActivityID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        true ->
            #r_activity{status = Status} = world_activity_server:get_activity(ActivityID),
            Status =:= ?STATUS_OPEN;
        _ ->
            false
    end.