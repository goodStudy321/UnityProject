%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_5).
-author("laijichang").
-include("db.hrl").
-include("all_pb.hrl").
-include("common.hrl").
-include("proto/mod_role_bag.hrl").


%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_world_boss/1,
    update_role_fight/1,
    update_role_skill/1,
    update_role_copy/1,
    update_role_bag/1,
    update_role_letter/1,
    update_world_letter/1,
    update_role_guard/1,
    update_family/1,
    update_confine/1,
    update_function/1,
    update_guard/1,
    update_day_recharge/1,
    update_bless/1,
    update_second_act/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_WORLD_BOSS_P, update_role_world_boss},
        {?DB_ROLE_FIGHT_P, update_role_fight},
        {?DB_ROLE_SKILL_P, update_role_skill},
        {?DB_ROLE_COPY_P, update_role_copy},
        {?DB_ROLE_FUNCTION_P, update_function},
        {?DB_ROLE_BAG_P, update_role_bag},
        {?DB_ROLE_LETTER_P, update_role_letter},
        {?DB_WORLD_LETTER_P, update_world_letter},
        {?DB_ROLE_GUARD_P, update_role_guard},
        {?DB_FAMILY_P, update_family},
        {?DB_ROLE_CONFINE_P, update_confine},
        {?DB_ROLE_GUARD_P, update_guard},
        {?DB_ROLE_ACT_DAYRECHARGE_P, update_day_recharge},
        {?DB_ROLE_BLESS_P, update_bless},
        {?DB_ROLE_SECOND_ACT_P, update_second_act}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    ok.

%% 中央服数据更新
update_center() ->
    ok.

update_role_world_boss(RoleList) ->
    [begin
         case RoleWorldBoss of
             {r_role_world_boss, ROLE_ID, TIMES, BUY_TIMES, RESUME_TIMES, RESUME_TIME, HP_RECOVER_TIME, CAVE_TIMES, CAVE_ASSIST_TIMES,
              QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES, MYTHICAL_COLLECT_TIMES,
              MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST, AUTO_CARE_ID, MAX_TYPE_ID, IS_GUIDE} ->
                 {r_role_world_boss, ROLE_ID, TIMES, BUY_TIMES, RESUME_TIMES, RESUME_TIME, HP_RECOVER_TIME, CAVE_TIMES, CAVE_ASSIST_TIMES, QUIT_TIME, MYTHICAL_TIMES, MYTHICAL_ITEM_TIMES,
                  MYTHICAL_COLLECT_TIMES, MYTHICAL_COLLECT2_TIMES, COLLECT_OPEN_LIST, CARE_LIST, AUTO_CARE_ID, MAX_TYPE_ID, IS_GUIDE, []};
             _ ->
                 RoleWorldBoss
         end
     end || RoleWorldBoss <- RoleList].

update_role_fight(RoleList) ->
    [begin
         case RoleFight of
             {r_role_fight, RoleID, BaseAttr, FightAttr} ->
                 BaseAttr2 = update_role_fight2(BaseAttr),
                 FightAttr2 = update_role_fight2(FightAttr),
                 {r_role_fight, RoleID, BaseAttr2, FightAttr2};
             _ ->
                 RoleFight
         end
     end || RoleFight <- RoleList].

update_role_fight2(Attr) ->
    case Attr of
        {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
         DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
         BOSS_HURT_ADD, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, DIZZY_RATE, PROP_EFFECTS} ->
            {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
             DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
             BOSS_HURT_ADD, 0, 0, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, 0, 0, DIZZY_RATE, 0, 0, 0, 0, PROP_EFFECTS};
        {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
         DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
         BOSS_HURT_ADD, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd, DIZZY_RATE, Min, Max, DoubleMiss, DoubleDamage, PROP_EFFECTS} ->
            {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
             DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
             BOSS_HURT_ADD, 0, 0, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd, DIZZY_RATE, Min, Max, DoubleMiss, DoubleDamage, PROP_EFFECTS};
        _ ->
            Attr
    end.

update_role_skill(RoleList) ->
    [begin
         case RoleSkill of
             {r_role_skill, RoleID, AttackList, PassiveList} ->
                 AttackList2 = update_role_skill2(AttackList),
                 PassiveList2 =
                 [begin
                      case Passive of
                          {p_kvl, ID, SkillList} ->
                              {p_kvl, ID, update_role_skill2(SkillList)};
                          _ ->
                              Passive
                      end
                  end || Passive <- PassiveList],
                 {r_role_skill, RoleID, AttackList2, PassiveList2, []};
             _ ->
                 RoleSkill
         end
     end || RoleSkill <- RoleList].

update_role_skill2(SkillList) ->
    [begin
         case Skill of
             {p_skill, SkillID, Time} ->
                 {p_skill, SkillID, Time, 0};
             _ ->
                 Skill
         end
     end || Skill <- SkillList].

update_role_copy(RoleList) ->
    [begin
         case RoleCopy of
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, COPY_LIST} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, 2, 2, COPY_LIST};
             _ ->
                 RoleCopy
         end
     end || RoleCopy <- RoleList].

%%  开 ------------------------------------------------------------  更改p_goods   ---------------------------------------------------------------  开 %%
update_role_bag(RoleBagList) ->
    [begin
         case RoleBag of
             {r_role_bag, ROLE_ID, BagList} ->
                 BagList2 = [
                     begin
                         GoodList2 = update_p_goods(GoodList),
                         {p_bag_content, BagID, BagGrid, GoodList2}
                     end
                     || {p_bag_content, BagID, BagGrid, GoodList} <- BagList],
                 {r_role_bag, ROLE_ID, BagList2};
             _ ->
                 RoleBag
         end
     end || RoleBag <- RoleBagList].



update_role_letter(RoleList) ->
    [begin
         case RoleLetter of
             {r_role_letter, RoleID, Counter, ReceiveBox, GM_ID_LIST} ->
                 ReceiveBox2 = [
                     begin
                         case Letter of
                             {r_letter, ID, LetterState, SendTime, EndTime, TemplateId, Condition, Action, GoodList, TitleString, TextString} ->
                                 GoodList2 = update_p_goods(GoodList),
                                 {r_letter, ID, LetterState, SendTime, EndTime, TemplateId, Condition, Action, GoodList2, TitleString, TextString};
                             _ ->
                                 Letter
                         end
                     end
                     || Letter <- ReceiveBox],
                 {r_role_letter, RoleID, Counter, ReceiveBox2, GM_ID_LIST};
             _ ->
                 RoleLetter
         end
     end || RoleLetter <- RoleList].



update_world_letter(WorldLetters) ->
    [begin
         case WorldLetter of
             {r_world_letter, RoleID, Counter, ReceiveBox} ->
                 ReceiveBox2 = [
                     begin
                         case Letter of
                             {r_letter, ID, LetterState, SendTime, EndTime, TemplateId, Condition, Action, GoodList, TitleString, TextString} ->
                                 GoodList2 = update_p_goods(GoodList),
                                 {r_letter, ID, LetterState, SendTime, EndTime, TemplateId, Condition, Action, GoodList2, TitleString, TextString};
                             _ ->
                                 Letter
                         end
                     end
                     || Letter <- ReceiveBox],
                 {r_world_letter, RoleID, Counter, ReceiveBox2};
             _ ->
                 WorldLetter
         end
     end || WorldLetter <- WorldLetters].



update_role_guard(RoleList) ->
    Now = time_tool:now(),
    [begin
         case RoleGuard of
             {r_role_guard, ROLE_ID, Guard, BigGuard} ->
                 Guard2 = case Guard of
                              {p_goods, ID, TypeID, Bind, Num, ExcellentList, StartTime, EndTime} ->
                                  {p_goods, ID, TypeID, Bind, Num, ExcellentList, StartTime, EndTime, Now};
                              _ ->
                                  Guard
                          end,
                 BigGuard2 = case BigGuard of
                                 {p_goods, ID2, TypeID2, Bind2, Num2, ExcellentList2, StartTime2, EndTime2} ->
                                     {p_goods, ID2, TypeID2, Bind2, Num2, ExcellentList2, StartTime2, EndTime2, Now};
                                 _ ->
                                     BigGuard
                             end,
                 {r_role_guard, ROLE_ID, Guard2, BigGuard2};
             _ ->
                 RoleGuard
         end
     end || RoleGuard <- RoleList].


update_family(FamilyList) ->
    [begin
         case Family of
             {p_family, FamilyID, FamilyName, Level, Money, BossGrain, BossTimes, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice,
              RedPacket, RedPacketLog, PacketId, Members, ApplyList, Depot, DepotLog} ->
                 Depot2 = update_p_goods(Depot),
                 {p_family, FamilyID, FamilyName, Level, Money, BossGrain, BossTimes, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice,
                  RedPacket, RedPacketLog, PacketId, Members, ApplyList, Depot2, DepotLog};
             _ ->
                 Family
         end
     end || Family <- FamilyList].

update_p_goods(GoodsList) ->
    Now = time_tool:now(),
    [begin
         case Goods of
             {p_goods, ID, TypeID, Bind, Num, ExcellentList, StartTime, EndTime} ->
                 {p_goods, ID, TypeID, Bind, Num, ExcellentList, StartTime, EndTime, Now};
             _ ->
                 Goods
         end
     end || Goods <- GoodsList].


%%   闭 ------------------------------------------------------------  更改p_goods   ---------------------------------------------------------------  闭  %%


update_confine(RoleList) ->
    [begin
         case RoleConfine of
             {r_role_confine, RoleId, MissionList, Confine, _Exp, WarSpirit, WarSpiritList, WarSpiritChange, _CompleteMission, RefineAllExp, BagId, BagList, WarGodList, WarGodPieces} ->
                 {r_role_confine, RoleId, MissionList, Confine, WarSpirit, WarSpiritList, WarSpiritChange, RefineAllExp, BagId, BagList, WarGodList, WarGodPieces, []};
             _ ->
                 RoleConfine
         end
     end || RoleConfine <- RoleList].


update_function(List) ->
    [begin
         case RoleFunction of
             {r_role_function, RoleId, IDList, RewardList} ->
                 {r_role_function, RoleId, IDList, RewardList, false};
             _ ->
                 RoleFunction
         end
     end || RoleFunction <- List].


%%   闭 ------------------------------------------------------------  更改p_goods   ---------------------------------------------------------------  闭  %%


update_guard(GuardList) ->
    [begin
         case RoleGuard of
             {r_role_guard, RoleID, Guard, BigGuard} when erlang:is_integer(BigGuard) ->
                 {r_role_guard, RoleID, Guard, undefined};
             _ ->
                 RoleGuard
         end
     end || RoleGuard <- GuardList].


update_day_recharge(RoleList) ->
    [begin
         case ActDayRecharge of
             {r_role_act_dayrecharge, RoleId, Recharge, DayReward, CountReward, HaveCount, CountRecharge} ->
                 {r_role_act_dayrecharge, RoleId, Recharge, DayReward, CountReward, HaveCount, CountRecharge, 1};
             _ ->
                 ActDayRecharge
         end
     end || ActDayRecharge <- RoleList].


update_bless(RoleList) ->
    [begin
         case RoleBless of
             {r_role_bless, RoleID, _, _, _} ->
                 {r_role_bless, RoleID, 0, 0};
             _ ->
                 RoleBless
         end
     end || RoleBless <- RoleList].

%%db_role_second_act_p
update_second_act(RoleList) ->
    [begin
         case RoleSecondAct of
             {r_role_second_act, OssRankType, RankReward, Rank, PowerReward, PanicBuy, Mana, ManaReward, RechargeReward, TaskList, Recharge, SevenDayInvest,
              SevenDayList, LimitedPanicBuy, TreviFountainScore, TreviFountainReward} ->
                 {r_role_second_act, OssRankType, RankReward, Rank, PowerReward, PanicBuy, Mana, ManaReward, RechargeReward, TaskList, Recharge, SevenDayInvest,
                  SevenDayList, LimitedPanicBuy, 0, TreviFountainScore, TreviFountainReward,[]};
             _ ->
                 RoleSecondAct
         end
     end || RoleSecondAct <- RoleList].


