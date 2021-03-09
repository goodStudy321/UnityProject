%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 四月 2018 11:22
%%%-------------------------------------------------------------------
-module(mod_role_summit_tower).
-author("laijichang").
-include("global.hrl").
-include("summit_tower.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_summit_tower.hrl").
-include("daily_liveness.hrl").

%% API
-export([
    handle/2
]).

-export([
    is_able/1,
    check_role_pre_enter/2
]).

-export([
    next_summit_tower/2,
    summit_tower_finish/1
]).

is_able(State) ->
    #r_role{role_id = RoleID, role_map = #r_role_map{map_id = MapID}} = State,
    case mod_summit_tower:is_activity_open() of
        true ->
            [#r_role_summit{map_id = DestMapID, extra_id = ExtraID}] = mod_summit_tower:role_get_summit_tower(RoleID),
            DestMapID =:= MapID andalso ExtraID > 0;
        _ ->
            false
    end.

check_role_pre_enter(RoleID, _MapID) ->
    case mod_summit_tower:is_activity_open() of
        true ->
            {DestMapID, ExtraID, ServerID} =
                case catch mod_summit_tower:role_pre_enter(RoleID) of
                    {ok, DestMapIDT, ExtraIDT, ServerIDT} ->
                        {DestMapIDT, ExtraIDT, ServerIDT};
                    {error, ErrCode} ->
                        ?THROW_ERR(ErrCode)
                end,
            [PointList] = map_base_data:get_born_points(DestMapID),
            #c_born_point{mx = Mx, my = My, mdir = MDir, camp_id = CampID} = lib_tool:random_element_from_list(PointList),
            BornPos = map_misc:get_pos_by_meter(Mx, My, MDir),
            mod_role_daily_liveness:trigger_daily_liveness(RoleID, ?LIVENESS_SUMMIT_TOWER),
            {DestMapID, ExtraID, ServerID, CampID, BornPos};
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_011)
    end.

next_summit_tower(RoleID, MapID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {next_summit_tower, MapID}}).

summit_tower_finish(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, summit_tower_finish}).

handle({next_summit_tower, MapID}, State) ->
    mod_role_map:do_pre_enter(State#r_role.role_id, MapID, State);
handle(summit_tower_finish, State) ->
    do_summit_tower_finish(State);
handle(quit_summit_tower, State) ->
    do_quit_summit_tower(State).

%% 完成了要移动位置，并且加buff，30秒后要退出
do_summit_tower_finish(State) ->
    ?WARNING_MSG("test: summit_tower_finish"),
    #r_role{role_id = RoleID} = State,
    role_misc:info_role_after(1000 * ?ONE_MINUTE div 2, erlang:self(), {mod, ?MODULE, quit_summit_tower}),
    role_misc:add_buff(RoleID, #buff_args{buff_id = ?MAP_BUFF_IMPRISON, from_actor_id = RoleID}),
    {ok, RecordPos} = map_misc:get_born_pos(?MAP_LAST_SUMMIT_TOWER),
    mod_map_role:role_change_pos(mod_role_dict:get_map_pid(), RoleID, RecordPos, map_misc:pos_encode(RecordPos), ?ACTOR_MOVE_NORMAL, 0),
    State.

do_quit_summit_tower(State) ->
    #r_role{role_map = #r_role_map{map_id = MapID}} = State,
    case ?IS_MAP_SUMMIT_TOWER(MapID) of
        true ->
            mod_role_map:do_quit_map(State);
        _ ->
            State
    end.