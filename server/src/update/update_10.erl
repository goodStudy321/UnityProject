%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 九月 2019 17:04
%%%-------------------------------------------------------------------
-module(update_10).
-author("huangxiangrui").
-include("db.hrl").
-include("role.hrl").
-include("act.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_solo/1,
    update_role_fashion/1,
    update_role_copy/1,
    update_mining_role_p/1,
    update_role_addict/1,

    update_accrecharge/1,
    update_act_store/1,
    update_act_day_box/1
]).

-export([
    update_center_addict/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_SOLO_P, update_role_solo},
        {?DB_ROLE_FASHION_P, update_role_fashion},
        {?DB_ROLE_COPY_P, update_role_copy},
        {?DB_MINING_ROLE_P, update_mining_role_p},
        {?DB_ROLE_ADDICT_P, update_role_addict},

        {?DB_ROLE_ACT_ACCRECHARGE_P, update_accrecharge},
        {?DB_ROLE_ACT_STORE_P, update_act_store},
        {?DB_ROLE_DAY_BOX_P, update_act_day_box}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [
        {?DB_ROLE_SOLO_P, update_role_solo}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [
        {?DB_ROLE_SOLO_P, update_role_solo},
        {?DB_CENTER_ADDICT_P, update_center_addict}
    ],
    update_common:data_update(?MODULE, List),
    ok.

update_role_solo(RoleSoloList) ->
    [begin
         case RoleSolo of
             {r_role_solo, ROLE_ID, SCORE, RANK, EXTRA_ID, IS_MATCHING, IS_FIGHTING, SEASON_WIN_TIMES,
              SEASON_ENTER_TIMES, EXP, ENTER_TIMES, COMBO_WIN, ENTER_REWARD_LIST, STP_REWARD_LIST} ->
                 {r_role_solo, ROLE_ID, 0, SCORE, RANK, EXTRA_ID, IS_MATCHING, IS_FIGHTING, SEASON_WIN_TIMES,
                  SEASON_ENTER_TIMES, EXP, ENTER_TIMES, COMBO_WIN, ENTER_REWARD_LIST, STP_REWARD_LIST};
             _ ->
                 RoleSolo
         end
     end || RoleSolo <- RoleSoloList].

update_role_fashion(RoleFashionList) ->
    [begin
         case RoleFashion of
             {r_role_fashion, RoleID, IS_FASHION_FIRST, CUR_ID_LIST, FashionList, ESSENCE_LIST, _SUIT_ID_LIST} ->
                 {r_role_fashion, RoleID, IS_FASHION_FIRST, CUR_ID_LIST, update_role_fashion2(FashionList, []), ESSENCE_LIST, []};
             _ ->
                 RoleFashion
         end
     end || RoleFashion <- RoleFashionList].

update_role_fashion2([], Acc) ->
    Acc;
update_role_fashion2([Fashion|R], Acc) ->
    Fashion2 =
    case erlang:is_integer(Fashion) of
        true ->
            {p_fashion_time, Fashion, 0};
        _ ->
            Fashion
    end,
    update_role_fashion2(R, [Fashion2|Acc]).

update_role_copy(RoleCopyList) ->
    [begin
         case RoleCopy of
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList,
              CUR_FIVE_ELEMENTS, UNLOCK_FLOOR, LAST_ADD_TIME, ILLUSION, BUY_ILLUSION_TIMES, NAT_INTENSIFY} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList,
                  CUR_FIVE_ELEMENTS, UNLOCK_FLOOR, LAST_ADD_TIME, ILLUSION, BUY_ILLUSION_TIMES, NAT_INTENSIFY, 0, 0};
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList,
              CUR_FIVE_ELEMENTS, UNLOCK_FLOOR, LAST_ADD_TIME, ILLUSION, BUY_ILLUSION_TIMES, NAT_INTENSIFY, MaxUniverse} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList,
                  CUR_FIVE_ELEMENTS, UNLOCK_FLOOR, LAST_ADD_TIME, ILLUSION, BUY_ILLUSION_TIMES, NAT_INTENSIFY, MaxUniverse, 0};
             _ ->
                 RoleCopy
         end
     end || RoleCopy <- RoleCopyList].

update_mining_role_p(RoleList) ->
    [begin
         case MingRole of
             {r_mining_role, ROLE_ID, ROLE_NAME, CATEGORY, SEX, FAMILY_ID, POWER, POS, GATHER_NUM, GATHER_STOP, SHIFT_NUM, INSPIRE, SHIFT_HISTORY, PLUNDER_HISTORY, GOODS_LIST} ->
                 {r_mining_role, ROLE_ID, ROLE_NAME, CATEGORY, SEX, FAMILY_ID, POWER, POS, GATHER_NUM, GATHER_STOP, SHIFT_NUM, INSPIRE, SHIFT_HISTORY, PLUNDER_HISTORY, GOODS_LIST, false};
             _ ->
                 MingRole
         end
     end || MingRole <- RoleList].

update_role_addict(RoleList) ->
    [begin
         case RoleAddict of
             {r_role_addict, ROLE_ID, IS_AUTH, IS_PASSED, LAST_REMAIN_MIN, REDUCE_RATE} ->
                 {r_role_addict, ROLE_ID, IS_AUTH, IS_PASSED, LAST_REMAIN_MIN, REDUCE_RATE, ?IF(IS_PASSED, 18, ?IF(IS_AUTH, 14, 0))};
             _ ->
                 RoleAddict
         end
     end || RoleAddict <- RoleList].

update_center_addict(List) ->
    [begin
         case CenterAddict of
             {r_center_addict, Key, IS_AUTH, IS_PASSED} ->
                 {r_center_addict, Key, IS_AUTH, IS_PASSED, ?IF(IS_PASSED, 18, ?IF(IS_AUTH, 14, 0))};
             _ ->
                 CenterAddict
         end
     end || CenterAddict <- List].

update_accrecharge(RoleAccrechargeList) ->
    [begin
         case RoleAccrecharge of
             {r_role_act_accrecharge, Role_id, Status, Recharge, Reward} ->
                 {r_role_act_accrecharge, Role_id, 0, Status, Recharge, Reward};
             _ ->
                 RoleAccrecharge
         end
     end || RoleAccrecharge <- RoleAccrechargeList].

update_act_store(RoleActStoreList) ->
    [begin
         case RoleActStore of
             {r_role_act_store, Role_id, Buy_list} ->
                 {r_role_act_store, Role_id, Buy_list, 0};
             _ ->
                 RoleActStore
         end
     end || RoleActStore <- RoleActStoreList].


update_act_day_box(RoleActBoxList) ->
    [begin
         case RoleActBox of
             {r_role_day_box, Role_id, List} ->
                 {r_role_day_box, Role_id, 0, List};
             _ ->
                 RoleActBox
         end
     end || RoleActBox <- RoleActBoxList].


