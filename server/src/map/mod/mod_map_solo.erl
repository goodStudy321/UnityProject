%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     1v1地图处理
%%% @end
%%% Created : 19. 三月 2018 11:19
%%%-------------------------------------------------------------------
-module(mod_map_solo).
-author("laijichang").
-include("global.hrl").
-include("solo.hrl").

%% API
-export([
    i/1,
    init/0,
    loop/1,
    handle/1,
    role_enter_map/1,
    role_leave_map/1,
    role_dead/1
]).

-export([
    role_pos/2
]).

i(ExtraID) ->
    pname_server:call(map_misc:get_map_pname(?MAP_SOLO, ExtraID), {mod, ?MODULE, i}).

role_pos(RoleID, ExtraID) ->
    map_misc:call(map_misc:get_map_pname(?MAP_SOLO, ExtraID), {mod, ?MODULE, {role_pos, RoleID}}).

init() ->
    StartTime = time_tool:now() + ?SOLO_MAP_START_TIME,
    EndTime = time_tool:now() + ?MAP_END_TIME,
    MapCtrl = #r_map_solo{
        status = ?MAP_SOLO_STATUS_PREPARE,
        start_time = StartTime,
        end_time = EndTime,
        shutdown_time = EndTime + ?MAP_END_TIME
    },
    set_map_ctrl(MapCtrl).

loop(Now) ->
    #r_map_solo{
        status = Status,
        start_time = StartTime,
        end_time = EndTime,
        shutdown_time = ShutDownTime,
        role_list = RoleList
    } = MapCtrl = get_map_ctrl(),
    if
        Status =:= ?MAP_SOLO_STATUS_PREPARE andalso Now >= StartTime ->
            InMapRoles = mod_map_ets:get_in_map_roles(),
            [ begin
                  role_misc:remove_buff(RoleID, ?MAP_BUFF_IMPRISON),
                  mod_role_fight:force_change_pk_mode(RoleID, ?PK_MODE_ALL)
              end|| RoleID <- InMapRoles],
            set_map_ctrl(MapCtrl#r_map_solo{status = ?MAP_SOLO_STATUS_START}),
            case InMapRoles of
                [] ->
                    do_time_out(RoleList);
                [InMapRoleID] ->
                    [RoleID1, RoleID2] = mod_map_dict:get_map_params(),
                    do_solo_end(RoleID1, RoleID2, RoleID1 =:= InMapRoleID);
                _ ->
                    ok
            end;
        Now >= EndTime andalso Status =:= ?MAP_SOLO_STATUS_START ->
            do_time_out(RoleList);
        Now >= ShutDownTime andalso Status =:= ?MAP_SOLO_STATUS_END ->
            set_map_ctrl(MapCtrl#r_map_solo{status = ?MAP_SOLO_STATUS_SHUTDOWN}),
            [ mod_role_map:quit_map(RoleID) || RoleID <- mod_map_ets:get_in_map_roles()],
            map_server:delay_shutdown();
        true ->
            ok
    end.

role_enter_map(RoleID) ->
    #r_map_solo{status = Status, role_list = RoleList} = MapCtrl = get_map_ctrl(),
    role_misc:add_buff(RoleID, #buff_args{buff_id = ?MAP_BUFF_IMPRISON, from_actor_id = RoleID}),
    pname_server:send(erlang:self(), {func, fun() -> mod_map_actor:add_hp(RoleID, 9999999999) end}),
    mod_role_fight:force_change_pk_mode(RoleID, ?PK_MODE_PEACE),
    case Status =:= ?MAP_SOLO_STATUS_PREPARE of
        true ->
            RoleList2 = [RoleID|lists:delete(RoleID, RoleList)],
            case erlang:length(RoleList2) >= 2 of
                true -> %% 人到齐了。
                    StartTime = time_tool:now() + ?MAP_PREPARE_TIME,
                    EndTime = StartTime + ?MAP_FIGHT_TIME,
                    ShutDownTime = EndTime + ?MAP_END_TIME,
                    MapCtrl2 = MapCtrl#r_map_solo{start_time = StartTime, end_time = EndTime, shutdown_time = ShutDownTime, role_list = RoleList2};
                _ ->
                    MapCtrl2 = MapCtrl#r_map_solo{role_list = RoleList2}
            end,
            set_map_ctrl(MapCtrl2);
        _ ->
            ok
    end.

role_leave_map(RoleID) ->
    [RoleID1, RoleID2] = mod_map_dict:get_map_params(),
    do_solo_end(RoleID1, RoleID2, RoleID =:= RoleID2).

role_dead(RoleID) ->
    [RoleID1, RoleID2] = mod_map_dict:get_map_params(),
    do_solo_end(RoleID1, RoleID2, RoleID =:= RoleID2).

handle(i) ->
    do_i();
handle({role_pos, RoleID}) ->
    do_role_pos(RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_i() ->
    {get_map_ctrl(), mod_map_dict:get_map_params()}.

do_role_pos(RoleID) ->
    [RoleID1|_] = mod_map_dict:get_map_params(),
    CampID = ?IF(RoleID =:= RoleID1, ?DEFAULT_CAMP_ROLE, ?DEFAULT_CAMP_MONSTER),
    {ok, Pos} = map_misc:get_born_pos(#r_born_args{map_id = map_common_dict:get_map_id(), camp_id = CampID}),
    {CampID, Pos}.

do_time_out([]) ->
    [RoleID1, RoleID2] = mod_map_dict:get_map_params(),
    do_solo_end(RoleID1, RoleID2, true);
do_time_out([RoleID]) ->
    [RoleID1, RoleID2] = mod_map_dict:get_map_params(),
    do_solo_end(RoleID1, RoleID2, RoleID =:= RoleID1);
do_time_out([RoleID1, RoleID2]) ->
    #r_role_attr{power = Power1} = common_role_data:get_role_attr(RoleID1),
    #r_role_attr{power = Power2} = common_role_data:get_role_attr(RoleID2),
    do_solo_end(RoleID1, RoleID2, Power1 >= Power2).

%% solo出结果了
do_solo_end(RoleID1, RoleID2, IsFirstWinner) ->
    #r_map_solo{status = Status} = MapCtrl = get_map_ctrl(),
    case Status =:= ?MAP_SOLO_STATUS_PREPARE orelse Status =:= ?MAP_SOLO_STATUS_START of
        true ->
            {WinnerRoleID, LoseRoleID} = ?IF(IsFirstWinner, {RoleID1, RoleID2}, {RoleID2, RoleID1}),
            Now = time_tool:now(),
            MapCtrl2 = MapCtrl#r_map_solo{
                status = ?MAP_SOLO_STATUS_END,
                end_time = Now,
                shutdown_time = Now + ?MAP_END_TIME},
            set_map_ctrl(MapCtrl2),
            mod_solo:send_map_solo_end(WinnerRoleID, LoseRoleID),
            mod_role_fight:force_change_pk_mode(RoleID1, ?PK_MODE_PEACE),
            mod_role_fight:force_change_pk_mode(RoleID2, ?PK_MODE_PEACE);
        _ ->
            ok
    end.
%%%===================================================================
%%% dict
%%%===================================================================
set_map_ctrl(MapCtrl) ->
    erlang:put({?MODULE, map_ctrl}, MapCtrl).
get_map_ctrl() ->
    erlang:get({?MODULE, map_ctrl}).
