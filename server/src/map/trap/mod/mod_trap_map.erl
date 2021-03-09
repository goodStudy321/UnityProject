%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2017 19:58
%%%-------------------------------------------------------------------
-module(mod_trap_map).
-author("laijichang").
-include("trap.hrl").

-export([
    trap_born/1,
    trap_leave/1
]).

%% from map
-export([
    summon_trap/1,
    enter_map/1
]).

%%%===================================================================
%%% to map start
%%%===================================================================
trap_born(TrapData) ->
    {MapInfo, Attr} = make_map_info(TrapData),
    mod_map_trap:trap_enter_map(MapInfo, Attr).

make_map_info(TrapData) ->
    #r_trap{
        trap_id = TrapID,
        type_id = TypeID,
        owner_id = OwnerID,
        owner_type = OwnerType,
        owner_level = OwnerLevel,
        fight_attr = FightAttr,
        move_speed = MoveSpeed,
        pos = Pos,
        target_pos = TargetPos,
        pk_mode = PKMode,
        camp_id = CampID} = TrapData,
    MapInfo = #r_map_actor{
        actor_id = TrapID,
        actor_type = ?ACTOR_TYPE_TRAP,
        pos = map_misc:pos_encode(Pos),
        hp = 1,
        max_hp = 1,
        move_speed = MoveSpeed,
        pk_mode = PKMode,
        camp_id = CampID,
        target_pos = map_misc:pos_encode(TargetPos),
        trap_extra = #p_map_trap{type_id = TypeID, owner_id = OwnerID, owner_type = OwnerType, owner_level = OwnerLevel}},
    {MapInfo, FightAttr}.

trap_leave(TrapID) ->
    mod_map_trap:trap_leave_map(TrapID).

%%%===================================================================
%%% from map start
%%%===================================================================
summon_trap(TrapArgs) ->
    mod_trap:init_trap(TrapArgs).

enter_map(TrapID) ->
    TrapData = mod_trap_data:get_trap_data(TrapID),
    mod_trap_data:set_trap_data(TrapID, TrapData#r_trap{state = ?TRAP_STATE_WORK}),
    mod_trap_data:add_counter_trap(TrapID, mod_trap_data:get_loop_counter() + ?TRAP_WORK_COUNTER).

%%%===================================================================
%%% from map end
%%%===================================================================
