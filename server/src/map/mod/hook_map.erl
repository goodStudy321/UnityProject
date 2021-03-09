-module(hook_map).
-include("global.hrl").
%% API
-export([
    init/0,
    loop/1,
    terminate/0
]).

-export([
    role_enter_map/1,
    role_leave_map/3,
    role_reduce_hp/2,
    role_dead/3,
    role_relive/3
]).

-export([
    monster_enter_map/1,
    monster_reduce_hp/3,
    monster_dead/2
]).

-export([
    collection_leave_map/3
]).

init() ->
    MapID = map_common_dict:get_map_id(),
    FuncList = [
        fun() -> mod_map_slice:map_server_init() end,
        fun() -> mod_map_drop:init(MapID) end,
        fun() -> copy_common:first_init(MapID) end,
        fun() -> ?IF(common_config:is_cross_node(), pname_server:reg(map_common_dict:get_map_pname(), map_common_dict:get_map_pid()), ok) end,
        fun() -> ?IF(?IS_MAP_BATTLE(MapID), mod_map_battle:init(), ok) end,
        fun() -> ?IF(?IS_MAP_SOLO(MapID), mod_map_solo:init(), ok) end,
        fun() -> ?IF(?IS_MAP_FAMILY_TD(MapID), mod_map_family_td:init(), ok) end,
        fun() -> ?IF(?IS_MAP_SUMMIT_TOWER(MapID), mod_map_summit_tower:init(), ok) end,
        fun() -> ?IF(?IS_MAP_ANSWER(MapID), mod_map_answer:init(), ok) end,
        fun() -> ?IF(?IS_MAP_FAMILY_AS(MapID), mod_map_family_as:init(), ok) end,
        fun() -> ?IF(?IS_MAP_FAMILY_BT(MapID), mod_map_family_bt:init(), ok) end,
        fun() -> ?IF(?IS_MAP_MARRY_FEAST(MapID), mod_map_marry:init(), ok) end,
        fun() -> ?IF(map_misc:is_world_boss_tired_map(MapID), mod_map_world_boss:init_first_boss(MapID), ok) end,
        fun() -> ?IF(?IS_MAP_DEMON_BOSS(MapID), mod_map_demon_boss:init(), ok) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

%%地图每秒钟的循环
loop(Now) ->
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    FuncList = [
        fun() -> copy_common:loop(Now) end,
        fun() -> mod_map_drop:loop(Now) end,
        fun() ->
            if
                SubType =:= ?SUB_TYPE_FAMILY_TD ->
                    mod_map_family_td:loop(Now);
                SubType =:= ?SUB_TYPE_FAMILY_BATTLE ->
                    mod_map_family_bt:loop(Now);
                SubType =:= ?SUB_TYPE_MYTHICAL_BOSS ->
                    mod_map_world_boss:mythical_loop(Now);
                true ->
                    ok
            end
        end,
        fun() ->
            if
                ?IS_MAP_SOLO(MapID) ->
                    mod_map_solo:loop(Now);
                ?IS_MAP_SUMMIT_TOWER(MapID) ->
                    mod_map_summit_tower:loop(Now);
                ?IS_MAP_FAMILY_AS(MapID) ->
                    mod_map_family_as:loop(Now);
                ?IS_MAP_MARRY_FEAST(MapID) ->
                    mod_map_marry:loop(Now);
                ?IS_MAP_DEMON_BOSS(MapID) ->
                    mod_map_demon_boss:loop(Now);
                ?IS_MAP_FAMILY_GOD_BEAST(MapID) ->
                    mod_map_family_god_beast:loop(Now);
                true ->
                    ok
            end
        end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    ok.

terminate() ->
    MapID = map_common_dict:get_map_id(),
    _ExtraID = map_common_dict:get_map_extra_id(),
    FuncList =
    [
        fun() -> ?IF(common_config:is_cross_node(), pname_server:dereg(map_common_dict:get_map_pname()), ok) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    case MapID of
        ?MAP_FAMILY_BT ->
            mod_map_family_bt:terminate();
        _ ->
            ok
    end,
    ok.

%%%===================================================================
%%% map_role hook start
%%%===================================================================
role_enter_map(RoleID) ->
    MapID = map_common_dict:get_map_id(),
    ExtraID = map_common_dict:get_map_extra_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    FuncList = [
        fun() -> ?IF(map_misc:is_copy_front(MapID), mod_map_monster:delete_monsters(), ok) end,
        fun() -> copy_common:role_enter(RoleID) end,
        fun() -> ?IF(map_branch_manager:is_branch_map(MapID), map_branch_worker:role_enter_map(MapID, ExtraID), ok) end,
        fun() ->
            if
                ?IS_MAP_BATTLE(MapID) -> mod_battle:role_enter_map(RoleID);
                ?IS_MAP_SOLO(MapID) -> mod_map_solo:role_enter_map(RoleID);
                ?IS_MAP_FAMILY_TD(MapID) -> mod_map_family_td:role_enter_map(RoleID);
                ?IS_MAP_ANSWER(MapID) -> mod_map_answer:role_enter_map(RoleID);
                ?IS_MAP_FAMILY_AS(MapID) -> mod_map_family_as:role_enter_map(RoleID);
                ?IS_MAP_SUMMIT_TOWER(MapID) -> mod_summit_tower:role_enter_map(RoleID, MapID, ExtraID);
                ?IS_MAP_FAMILY_BT(MapID) -> mod_map_family_bt:role_enter_map(RoleID);
                ?IS_MAP_MARRY_FEAST(MapID) -> mod_map_marry:role_enter_map(RoleID);
                ?IS_MAP_DEMON_BOSS(MapID) -> mod_map_demon_boss:role_enter_map(RoleID);
                ?IS_MAP_FAMILY_GOD_BEAST(MapID) -> mod_map_family_god_beast:role_enter_map(RoleID);
                true -> ok
            end
        end,
        fun() ->
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_1 ->
                    world_boss_server:role_first_boss_enter(RoleID, mod_map_world_boss:get_first_boss_type_id());
                true ->
                    ok
            end
        end,
        fun() -> ?IF(?IS_WORLD_BOSS_SUB_TYPE(SubType), world_boss_server:role_enter_boss(RoleID, MapID), ok) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

role_leave_map(RoleID, IsOnline, SkinList) ->
    MapID = map_common_dict:get_map_id(),
    ExtraID = map_common_dict:get_map_extra_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    FuncList = [
        fun() -> copy_common:role_leave(RoleID, IsOnline) end,
        fun() -> ?IF(map_branch_manager:is_branch_map(MapID), map_branch_worker:role_leave_map(MapID, ExtraID), ok) end,
        fun() ->
            if
                ?IS_MAP_BATTLE(MapID) -> mod_battle:role_leave_map(RoleID);
                ?IS_MAP_SOLO(MapID) -> mod_map_solo:role_leave_map(RoleID);
                ?IS_MAP_ANSWER(MapID) -> mod_map_answer:role_leave_map(RoleID);
                ?IS_MAP_SUMMIT_TOWER(MapID) -> mod_summit_tower:role_leave_map(RoleID, MapID, ExtraID);
                ?IS_MAP_FAMILY_BT(MapID) -> mod_map_family_bt:role_leave_map(RoleID);
                ?IS_MAP_MARRY_FEAST(MapID) -> mod_map_marry:role_leave_map(RoleID, SkinList);
                ?IS_MAP_DEMON_BOSS(MapID) -> mod_map_demon_boss:role_leave_map(RoleID, IsOnline);
                true -> ok
            end
        end,
        fun() -> mod_map_collection:role_leave_map(RoleID) end,
        fun() ->
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_1 ->
                    world_boss_server:role_first_boss_leave(RoleID, mod_map_world_boss:get_first_boss_type_id()),
                    mod_map_monster:role_first_boss_leave(RoleID);
                true ->
                    ok
            end
        end,
        fun() -> ?IF(?IS_WORLD_BOSS_SUB_TYPE(SubType), world_boss_server:role_leave_boss(RoleID, MapID), ok) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

role_reduce_hp(RoleID, ReduceSrc) ->
    MapID = map_common_dict:get_map_id(),
    FuncList = [
        fun() -> mod_map_collection:role_reduce_hp(RoleID, ReduceSrc) end,
        fun() -> ?IF(?IS_MAP_BATTLE(MapID), mod_map_battle:role_reduce_hp(RoleID, ReduceSrc), ok) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

role_dead(RoleID, SrcID, SrcType) ->
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    FuncList = [
        fun() -> copy_common:role_dead(RoleID, SrcID, SrcType) end,
        fun() ->
            if
                ?IS_MAP_BATTLE(MapID) -> mod_map_battle:role_be_killed(RoleID, SrcID);
                ?IS_MAP_SOLO(MapID) -> mod_map_solo:role_dead(RoleID);
                ?IS_MAP_SUMMIT_TOWER(MapID) -> mod_map_summit_tower:role_dead(RoleID, SrcID, SrcType);
                ?IS_MAP_FAMILY_BT(MapID) -> mod_map_family_bt:role_dead(RoleID, SrcID);
                ?IS_MAP_DEMON_BOSS(MapID) -> mod_map_demon_boss:role_dead(RoleID, SrcID, SrcType);
                ?IS_MAP_TREASURE_SECRET(MapID) -> copy_treasure_secret:role_dead({RoleID, SrcID, SrcType});
                true -> ok
            end
        end,
        fun() ->
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_1 ->
                    mod_map_monster:role_first_boss_dead(RoleID, SrcID, SrcType);
                true ->
                    ok
            end
        end,
        fun() -> mod_map_collection:role_dead(RoleID) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

role_relive(RoleID, OpType, BornPos) ->
    MapID = map_common_dict:get_map_id(),
    FuncList = [
        fun() ->
            if
                ?IS_MAP_FAMILY_BT(MapID) ->
                    ?IF(OpType =:= ?RELIVE_TYPE_FEE, mod_map_family_bt:role_relive_type_fee(RoleID, BornPos), ok);
                ?IS_MAP_DEMON_BOSS(MapID) ->
                    ?IF(OpType =/= ?RELIVE_TYPE_FEE, mod_map_demon_boss:role_relive_normal(RoleID), ok);
                true ->
                    ok
            end
        end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.


%%%===================================================================
%%% map_role hook end
%%%===================================================================


%%%===================================================================
%%% monster hook start
%%%===================================================================
monster_enter_map(MonsterID) ->
    MapID = map_common_dict:get_map_id(),
    MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    FuncList = [
        fun() -> copy_common:monster_enter(MapInfo) end,
        fun() ->
            if
                ?IS_MAP_DEMON_BOSS(MapID) ->
                    mod_map_demon_boss:monster_enter_map(MapInfo);
                ?IS_MAP_FAMILY_BOSS(MapID) ->
                    mod_map_family_god_beast:set_boss_id(MonsterID);
                true ->
                    ok
            end
        end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.

monster_reduce_hp(MonsterID, ReduceSrc, ReduceHp) ->
    MapID = map_common_dict:get_map_id(),
    MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    FuncList = [
        fun() ->
            if
                ?IS_MAP_FAMILY_TD(MapID) ->
                    mod_map_family_td:monster_reduce_hp(MapInfo, ReduceSrc, ReduceHp);
                ?IS_MAP_DEMON_BOSS(MapID) ->
                    mod_map_demon_boss:monster_reduce_hp(MapInfo, ReduceSrc, ReduceHp);
                true ->
                    ok
            end
        end,
        fun() -> copy_common:monster_reduce_hp(MapInfo, ReduceSrc, ReduceHp) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.


monster_dead(MonsterID, DeadArgs) ->
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    #r_actor_dead{src_id = SrcID, src_type = SrcType, extra_args = ExtraArgs} = DeadArgs,
    FuncList = [
        fun() -> copy_common:monster_dead(MapInfo, SrcID, SrcType) end,
        fun() ->
            if
                ?IS_MAP_FAMILY_TD(MapID) -> mod_map_family_td:monster_dead(MapInfo);
                ?IS_MAP_SUMMIT_TOWER(MapID) -> mod_map_summit_tower:monster_dead(MapInfo, SrcID, SrcType);
                ?IS_MAP_DEMON_BOSS(MapID) -> mod_map_demon_boss:monster_dead(MapInfo, SrcID, SrcType);
                ?IS_MAP_FAMILY_GOD_BEAST(MapID) -> mod_map_family_god_beast:boss_killed();
                ?IS_MAP_TREASURE_SECRET(MapID) -> copy_treasure_secret:boss_killed();
                true -> ok
            end
        end,
        fun() -> mod_map_world_boss:monster_dead(MapID, SubType, MapInfo, ExtraArgs) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.
%%%===================================================================
%%% monster hook end
%%%===================================================================

%%%===================================================================
%%% collection hook start
%%%===================================================================
collection_leave_map(_ActorID, TypeID, IsCollect) ->
    MapID = map_common_dict:get_map_id(),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    FuncList = [
        fun() -> mod_map_world_boss:collection_leave_map(MapID, SubType, TypeID, IsCollect) end
    ],
    [begin
         ?TRY_CATCH(F())
     end || F <- FuncList],
    ok.
%%%===================================================================
%%% collection hook end
%%%===================================================================