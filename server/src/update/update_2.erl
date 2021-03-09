%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_2).
-author("laijichang").
-include("db.hrl").
-include("all_pb.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_relive/1,
    update_role_treasure/1,
    update_war_spirit/1,
    update_role_world_boss/1,
    update_role_marry/1,
    update_role_guard/1,
    update_role_equip_forge/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_RELIVE_P, update_role_relive},
        {?DB_ROLE_TREASURE_P, update_role_treasure},
        {?DB_ROLE_CONFINE_P, update_war_spirit},
        {?DB_ROLE_WORLD_BOSS_P, update_role_world_boss},
        {?DB_ROLE_MARRY_P, update_role_marry},
        {?DB_ROLE_GUARD_P, update_role_guard},
        {?DB_ROLE_EQUIP_P, update_role_equip_forge}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    ok.

%% 中央服数据更新
update_center() ->
    ok.

update_role_relive(RoleList) ->
    [begin
         case RoleRelive of
             {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS, DestinyID, TalentPoints} ->
                 {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS, DestinyID, TalentPoints, []};
             _ ->
                 RoleRelive
         end
     end || RoleRelive <- RoleList].

update_role_treasure(RoleList) ->
    [begin
         case RoleTreasure of
             {r_role_treasure, ROLE_ID, EQUIP_TIMES, EQUIP_WEIGHT, EQUIP_LOGS, RUNE_FREE_TIME, RUNE_SINGLE_TIMES, RUNE_TIMES} ->
                 {r_role_treasure, ROLE_ID, EQUIP_TIMES, EQUIP_WEIGHT div 50, EQUIP_LOGS, RUNE_FREE_TIME, RUNE_SINGLE_TIMES, RUNE_TIMES, 0, 0, []};
             _ ->
                 RoleTreasure
         end
     end || RoleTreasure <- RoleList].

update_war_spirit(RoleList) ->
    [begin
         case RoleWarSpirit of
             {r_role_confine, ROLE_ID, MISSION_LIST, CONFINE, EXP, WAR_SPIRIT, WarSpiritList, WAR_SPIRIT_CHANGE, COMPLETE_MISSION} ->
                 WarSpiritList2 = update_war_spirit2(WarSpiritList),
                 {r_role_confine, ROLE_ID, MISSION_LIST, CONFINE, EXP, WAR_SPIRIT, WarSpiritList2, WAR_SPIRIT_CHANGE, COMPLETE_MISSION, 0, 1, []};
             _ ->
                 RoleWarSpirit
         end
     end || RoleWarSpirit <- RoleList].

update_war_spirit2(WarSpiritList) ->
    [begin
         case WarSpirit of
             {p_war_spirit, ID, Level, Exp} ->
                 {p_war_spirit, ID, Level, Exp, []};
             _ ->
                 WarSpirit
         end
     end || WarSpirit <- WarSpiritList].

update_role_world_boss(RoleList) ->
    [begin
         case RoleWorldBoss of
             {r_role_world_boss, ROLE_ID, TIMES, ITEM_ADD_TIMES, QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES, MYTHICAL_COLLECT_TIMES,
                 MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST} ->
                 {r_role_world_boss, ROLE_ID, TIMES, ITEM_ADD_TIMES, QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES, MYTHICAL_COLLECT_TIMES,
                     MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST, 0};
             _ ->
                 RoleWorldBoss
         end
     end || RoleWorldBoss <- RoleList].

update_role_marry(RoleMarry) ->
    [begin
         case RoleMarryTable of
             {r_role_marry, ROLE_ID, COUPLE_ID, COUPLE_NAME, KNOT_Id, KNOT_EXP, MARRY_TITLE_IDS} ->
                 {r_role_marry, ROLE_ID, COUPLE_ID, COUPLE_NAME, KNOT_Id, KNOT_EXP, MARRY_TITLE_IDS, [], 0};
             _ ->
                 RoleMarryTable
         end
     end || RoleMarryTable <- RoleMarry].


update_role_guard(RoleGuardList) ->
    [begin
         case RoleGuard of
             {r_role_guard, RoleID , Guard} ->
                 {r_role_guard, RoleID,Guard,-1};
             _ ->
                 RoleGuard
         end
     end || RoleGuard <- RoleGuardList].

update_role_equip_forge(RoleEquip) ->
    [begin
         case RoleEquipTable of
             {r_role_equip, ROLE_ID, FREE_CONCISE_TIMES, EQUIP_LIST} ->
                 NewEquipList = modify_equip_list_forge_soul(EQUIP_LIST),
                 {r_role_equip, ROLE_ID,  FREE_CONCISE_TIMES, NewEquipList};
             _ ->
                 RoleEquipTable
         end
     end || RoleEquipTable <- RoleEquip].

modify_equip_list_forge_soul(EquipList) ->
    [begin
         case RoleEquipTable of
             {p_equip, EQUIP_ID, REFINE_LEVEL, MASTERY, SUIT_LEVEL, STONE_LIST, EXCELLENT_LIST, BIND, CONCISE_NUM, CONCISE_LIST} ->
                 {p_equip, EQUIP_ID, REFINE_LEVEL, MASTERY, SUIT_LEVEL, STONE_LIST, EXCELLENT_LIST, BIND, CONCISE_NUM, CONCISE_LIST, 0, 0};
             _ ->
                 RoleEquipTable
         end
     end || RoleEquipTable <- EquipList].