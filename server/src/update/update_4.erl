%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_4).
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
    update_role_equip_stone_and_grain/1,
    update_role_fashion/1,
    update_role_confine/1,
    update_role_invest/1,
    update_role_cross_data/1,
    update_role_oss/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_EQUIP_P, update_role_equip_stone_and_grain},
        {?DB_ROLE_FASHION_P, update_role_fashion},
        {?DB_ROLE_CONFINE_P, update_role_confine},
        {?DB_ROLE_INVEST_P, update_role_invest},
        {?DB_ROLE_SECOND_ACT_P, update_role_oss}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [
        {?DB_ROLE_CROSS_DATA_P, update_role_cross_data}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    ok.

update_role_equip_stone_and_grain(RoleEquip) ->
    [begin
         case RoleEquipTable of
             {r_role_equip, ROLE_ID, FREE_CONCISE_TIMES, EQUIP_LIST} ->
                 EquipList2 = modify_equip_stone_and_grain(EQUIP_LIST),
                 {r_role_equip, ROLE_ID, FREE_CONCISE_TIMES, EquipList2};
             _ ->
                 RoleEquipTable
         end
     end || RoleEquipTable <- RoleEquip].

modify_equip_stone_and_grain(EquipList) ->
    [begin
         case Equip of
             {p_equip, EQUIP_ID, REFINE_LEVEL, MASTERY, SUIT_LEVEL, STONE_LIST, EXCELLENT_LIST, BIND, CONCISE_NUM, CONCISE_LIST, ForgeSoul, ForgeSoulC} ->
                 {p_equip, EQUIP_ID, REFINE_LEVEL, MASTERY, SUIT_LEVEL, STONE_LIST, EXCELLENT_LIST, BIND, CONCISE_NUM, CONCISE_LIST, ForgeSoul, ForgeSoulC, [], []};
             _ ->
                 Equip
         end
     end || Equip <- EquipList].

update_role_fashion(RoleFashionList) ->
    [begin
         case RoleFashion of
             {r_role_fashion, ROLE_ID, IS_FASHION_FIRST, CUR_ID_LIST, FASHION_LIST, ESSENCE_LIST} ->
                 {r_role_fashion, ROLE_ID, IS_FASHION_FIRST, CUR_ID_LIST, FASHION_LIST, ESSENCE_LIST, []};
             _ ->
                 RoleFashion
         end
     end || RoleFashion <- RoleFashionList].

update_role_confine(RoleList) ->
    [begin
         case RoleConfine of
             {r_role_confine, ROLE_ID, MISSION_LIST, CONFINE, EXP, WAR_SPIRIT, WarSpiritList, WAR_SPIRIT_CHANGE, COMPLETE_MISSION, RefineAllExp, BagID, BagList} when erlang:is_integer(BagID) ->
                 {r_role_confine, ROLE_ID, MISSION_LIST, CONFINE, EXP, WAR_SPIRIT, WarSpiritList, WAR_SPIRIT_CHANGE, COMPLETE_MISSION, RefineAllExp, BagID, BagList, [], []};
             _ ->
                 RoleConfine
         end
     end || RoleConfine <- RoleList].

update_role_invest(RoleInvestList) ->
    [begin
         case RoleInvest of
             {r_role_invest, ROLE_ID, INVEST_GOLD, INVEST_REWARD_LIST, IS_MONTH_CARD_REWARD, IS_PRINCIPAL_REWARD, MONTH_CARD_DAYS,
              IS_VIP_INVEST_REWARD, VIP_INVEST_LEVEL, VIP_INVEST_DAYS, IS_VIP_FIRST_ADD} ->
                 {r_role_invest, ROLE_ID, INVEST_GOLD, INVEST_REWARD_LIST, IS_MONTH_CARD_REWARD, IS_PRINCIPAL_REWARD, MONTH_CARD_DAYS,
                  IS_VIP_INVEST_REWARD, VIP_INVEST_LEVEL, VIP_INVEST_DAYS, IS_VIP_FIRST_ADD, 0, []};
             _ ->
                 RoleInvest
         end
     end || RoleInvest <- RoleInvestList].


update_role_cross_data(RoleCrossDataList) ->
    [begin
         case RoleCrossData of
             {r_role_cross_data, ROLE_ID, ROLE_NAME, SEX, LEVEL, CATEGORY, VIP_LEVEL, SERVER_NAME} ->
                 {r_role_cross_data, ROLE_ID, ROLE_NAME, SEX, LEVEL, CATEGORY, VIP_LEVEL, SERVER_NAME, []};
             _ ->
                 RoleCrossData
         end
     end || RoleCrossData <- RoleCrossDataList].

update_role_oss(List) ->
    [begin
         case RoleOss of
             {r_role_second_act, ROLE_ID, OSS_RANK_TYPE, RANK_REWARD, RANK, PANIC_BUY, MANA, MANA_REWARD, RECHARGE_REWARD, TASK_LIST, RECHARGE, SEVEN_DAY_INVEST, SEVEN_DAY_LIST,
              LIMITED_PANIC_BUY, TREVI_FOUNTAIN_SCORE, TREVI_FOUNTAIN_REWARD} ->
                 {r_role_second_act, ROLE_ID, OSS_RANK_TYPE, RANK_REWARD, RANK, [], PANIC_BUY, MANA, MANA_REWARD, RECHARGE_REWARD, TASK_LIST, RECHARGE, SEVEN_DAY_INVEST, SEVEN_DAY_LIST,
                  LIMITED_PANIC_BUY, TREVI_FOUNTAIN_SCORE, TREVI_FOUNTAIN_REWARD};
             _ ->
                 RoleOss
         end
     end || RoleOss <- List].