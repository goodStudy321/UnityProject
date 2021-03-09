%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_8).
-author("laijichang").
-include("db.hrl").
-include("role.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_world_boss/1,
    update_role_copy/1,
    update_role_discount_pay/1,
    update_role_nature/1,
    update_role_extra/1,
    update_role_bless/1,
    update_role_trevi_fountain/1,
    update_role_asset/1,
    update_role_second_act/1,
    update_role_escort/1
]).

-export([
    update_role_cross_data/1
]).
%% List = [{DBName, Fun}|....]

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_WORLD_BOSS_P, update_role_world_boss},
        {?DB_ROLE_COPY_P, update_role_copy},
        {?DB_ROLE_DISCOUNT_PAY_P, update_role_discount_pay},
        {?DB_ROLE_NATURE_P, update_role_nature},
        {?DB_ROLE_EXTRA_P, update_role_extra},
        {?DB_ROLE_BLESS_P, update_role_bless},
        {?DB_ROLE_ASSET_P, update_role_asset},
        {?DB_ROLE_TREVI_FOUNTAIN_P, update_role_trevi_fountain},
        {?DB_ROLE_ESCORT_P, update_role_escort},
        {?DB_ROLE_SECOND_ACT_P, update_role_second_act}
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
    List = [

    ],
    update_common:data_update(?MODULE, List),
    ok.

update_role_world_boss(RoleList) ->
    [begin
         case RoleWorldBoss of
             {r_role_world_boss, ROLE_ID, TIMES, BUY_TIMES, RESUME_TIMES, RESUME_TIME, HP_RECOVER_TIME, CAVE_TIMES, CAVE_ASSIST_TIMES,
              QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES, MYTHICAL_COLLECT_TIMES, MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST, AUTO_CARE_ID, MAX_TYPE_ID, IS_GUIDE, HP_RECOVER_LIST} ->
                 {r_role_world_boss, ROLE_ID, TIMES, BUY_TIMES, RESUME_TIMES, RESUME_TIME, HP_RECOVER_TIME, CAVE_TIMES, CAVE_ASSIST_TIMES, QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES,
                  MYTHICAL_COLLECT_TIMES, MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST, AUTO_CARE_ID, MAX_TYPE_ID, IS_GUIDE, HP_RECOVER_LIST, 1, []};
             _ ->
                 RoleWorldBoss
         end
     end || RoleWorldBoss <- RoleList].

update_role_copy(RoleList) ->
    [begin
         case RoleCopy of
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, CopyList, _CurFiveElement, _FiveElements} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, 1, 1, CopyList, 70101, 1, 0, 0, 0, 0};
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList, _CurFiveElement, _FiveElements} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, ExpMergeTimes, ExpNowTime, CopyList, 70101, 1, 0, 0, 0, 0};
             _ ->
                 RoleCopy
         end
     end || RoleCopy <- RoleList].

update_role_discount_pay(RoleList) ->
    [begin
         case RoleDiscountPay of
             {r_role_discount_pay, RoleID, CUR_PAY_ID, TODAY_DISCOUNTS, FINISH_IDS} ->
                 {r_role_discount_pay, RoleID, CUR_PAY_ID, TODAY_DISCOUNTS, [], FINISH_IDS};
             _ ->
                 RoleDiscountPay
         end
     end || RoleDiscountPay <- RoleList].

update_role_extra(RoleList) ->
    [begin
         case RoleExtra of
             {r_role_extra, RoleID, ExtraList} ->
                 ExtraList2 = update_role_extra2(ExtraList, []),
                 {r_role_extra, RoleID, ExtraList2};
             _ ->
                 RoleExtra
         end
     end || RoleExtra <- RoleList].

update_role_extra2([], Acc) ->
    Acc;
update_role_extra2([{Key, Val}|R], Acc) ->
    case Key of
        10 ->
            Val2 = update_role_resource(Val),
            update_role_extra2(R, [{Key, Val2}|Acc]);
        _ ->
            update_role_extra2(R, [{Key, Val}|Acc])
    end.

update_role_resource(ResourceList) ->
    [begin
         case Resource of
             {r_resource, ResourceID, BaseTimes, ExtraTimes} ->
                 {r_resource, ResourceID, BaseTimes, ExtraTimes, 1};
             _ ->
                 Resource
         end
     end || Resource <- ResourceList].

update_role_nature(RoleList) ->
    [begin
         case RoleNature of
             {r_role_nature, ROLE_ID, NATURE, QUALITY, STAR, CONSUME_MONEY} ->
                 {r_role_nature, ROLE_ID, NATURE, QUALITY, STAR, CONSUME_MONEY, []};
             _ ->
                 RoleNature
         end
     end || RoleNature <- RoleList].


update_role_bless(RoleList) ->
    [begin
         case RoleBless of
             {r_role_bless, RoleId, TodayTimes, Times} ->
                 [#r_role_attr{level = Level, max_power = MaxPower}] = db_lib:kv_lookup(?DB_ROLE_ATTR_P, RoleId),
                 [#r_role_confine{war_spirit_list = WarSpiritList}] = db_lib:kv_lookup(?DB_ROLE_CONFINE_P, RoleId),
                 WarSpiritAdd = mod_role_bless:get_rate(2, erlang:length(WarSpiritList)),
                 PowerAdd = mod_role_bless:get_rate(1, MaxPower div 10000),
                 [LevelConfig] = lib_config:find(cfg_role_level, Level),
                 {r_role_bless, RoleId, TodayTimes, Times, 0, PowerAdd, WarSpiritAdd, LevelConfig#c_role_level.passive_bless_exp, time_tool:now()};
             {r_role_bless, RoleId, TodayTimes, Times, PowerAdd, WarSpiritAdd, LevelAdd, SettleTime} ->
                 {r_role_bless, RoleId, TodayTimes, Times, 0, PowerAdd, WarSpiritAdd, LevelAdd, SettleTime};
             _ ->
                 RoleBless
         end
     end || RoleBless <- RoleList].


update_role_asset(RoleList) ->
    [begin
         case RoleAsset of
             {r_role_asset, RoleId, Silver, Gold, BindGold, ScoreList, DayUseGold} ->
                 {r_role_asset, RoleId, Silver, Gold, BindGold, ScoreList, DayUseGold, 0};
             _ ->
                 RoleAsset
         end
     end || RoleAsset <- RoleList].



update_role_trevi_fountain(RoleList) ->
    [begin
         case RoleTreviFountain of
             {r_role_trevi_fountain, RoleID, EditTime, Reward, Integral, Bless, RewardList} ->
                 {r_role_trevi_fountain, RoleID, EditTime, Reward, Integral, Bless, RewardList, true};
             _ ->
                 RoleTreviFountain
         end
     end || RoleTreviFountain <- RoleList].



update_role_escort(RoleList) ->
    [begin
         case RoleEscort of
             {r_role_escort, RoleId, Name, EscortId, EscortTimes, RobTimes, FairyType, Fight,
              EndTime, Log, RobRoleId, Reward, Help, Family, FamilyTitle} ->
                 {r_role_escort, RoleId, Name, EscortId, EscortTimes, RobTimes, FairyType, Fight,
                  EndTime, Log, RobRoleId, Reward, Help, Family, FamilyTitle, ""};
             _ ->
                 RoleEscort
         end
     end || RoleEscort <- RoleList].

update_role_second_act(RoleList) ->
    [begin
         case RoleSecondAct of
             {r_role_second_act,
              Role_id,
              Oss_rank_type,
              Rank_reward,
              Rank,
              Power_reward,
              Panic_buy,
              Mana,
              Mana_reward,
              Recharge_reward,
              Task_list,
              Recharge,
              Seven_day_invest,
              Seven_day_list,
              Limited_panic_buy,
              Trevi_fountain_bless,
              Trevi_fountain_score,
              Trevi_fountain_reward,
              Trevi_fountain_good_reward} ->
                 {r_role_second_act,
                  Role_id,
                  Oss_rank_type,
                  Rank_reward,
                  Rank,
                  Power_reward,
                  Panic_buy,
                  Mana,
                  Mana_reward,
                  Recharge_reward,
                  Task_list,
                  Recharge,
                  Seven_day_invest,
                  Seven_day_list,
                  Limited_panic_buy,
                  Trevi_fountain_bless,
                  Trevi_fountain_score,
                  Trevi_fountain_reward,
                  Trevi_fountain_good_reward,
                  true};
             _ ->
                 RoleSecondAct
         end
     end || RoleSecondAct <- RoleList].

update_role_cross_data(RoleList) ->
    [begin
         case RoleCrossData of
             {r_role_cross_data, ROLE_ID, ROLE_NAME, SEX, LEVEL, CATEGORY, VIP_LEVEL, SERVER_NAME, SKIN_LIST} ->
                 {r_role_cross_data, ROLE_ID, ROLE_NAME, SEX, LEVEL, CATEGORY, VIP_LEVEL, SERVER_NAME, SKIN_LIST, 0, 0, 0, 0, "", #actor_fight_attr{}};
             _ ->
                 RoleCrossData
         end
     end || RoleCrossData <- RoleList].
