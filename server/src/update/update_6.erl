%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_6).
-author("laijichang").
-include("db.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_first_charge/1,
    update_role_skill/1,
    update_role_copy/1,
    update_role_vip/1,
    update_role_relive/1,
    update_role_pet/1,
    update_role_confine/1,
    update_role_fight/1,
    update_family/1,
    update_role_asset/1,
    update_role_trevi_fountain/1,
    update_role_nature/1
]).

%% List = [{DBName, Fun}|....]

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_ACT_FIRSTRECHARGE_P, update_role_first_charge},
        {?DB_ROLE_SKILL_P, update_role_skill},
        {?DB_ROLE_COPY_P, update_role_copy},
        {?DB_ROLE_VIP_P, update_role_vip},
        {?DB_ROLE_PET_P, update_role_pet},
        {?DB_ROLE_CONFINE_P, update_role_confine},
        {?DB_ROLE_FIGHT_P, update_role_fight},
        {?DB_FAMILY_P, update_family},
        {?DB_ROLE_ASSET_P, update_role_asset},
        {?DB_ROLE_TREVI_FOUNTAIN_P, update_role_trevi_fountain},
        {?DB_ROLE_NATURE_P, update_role_nature}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [

    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [

    ],
    update_common:data_update(?MODULE, List),
    ok.

update_role_first_charge(RoleList) ->
    [begin
         case RoleFirstCharge of
             {r_role_act_firstrecharge, RoleID, _Status, Reward} when erlang:is_integer(Reward) ->
                 {r_role_act_firstrecharge, RoleID, 0, []};
             _ ->
                 RoleFirstCharge
         end
     end || RoleFirstCharge <- RoleList].

update_role_skill(RoleList) ->
    [begin
         case RoleSkill of
             {r_role_skill, RoleID, AttackList, PassiveList, SealList} ->
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
                 {r_role_skill, RoleID, AttackList2, PassiveList2, SealList};
             _ ->
                 RoleSkill
         end
     end || RoleSkill <- RoleList].

update_role_skill2(SkillList) ->
    [begin
         case Skill of
             {p_skill, SkillID, Time, SealID} ->
                 {p_skill, SkillID, Time, SealID, [SealID]};
             _ ->
                 Skill
         end
     end || Skill <- SkillList].

update_role_copy(RoleList) ->
    [begin
         case RoleCopy of
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, CopyList} ->
                 CopyList2 = update_role_copy2(CopyList),
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, CopyList2, []};
             {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, CopyList, FiveElements} ->
                 {r_role_copy, ROLE_ID, TOWER_ID, TOWER_REWARD_LIST, ExpFinishTimes, ExpEnterTimes, CopyList, 0, FiveElements};
             _ ->
                 RoleCopy
         end
     end || RoleCopy <- RoleList].

update_role_copy2(CopyList) ->
    [begin
         case CopyItem of
             {r_role_copy_item, COPY_TYPE, ENTER_TIMES, BUY_TIMES, ITEM_ADD_TIMES, CAN_ENTER_TIME, STAR_LIST} ->
                 {r_role_copy_item, COPY_TYPE, ENTER_TIMES, BUY_TIMES, ITEM_ADD_TIMES, CAN_ENTER_TIME, 0, STAR_LIST};
             _ ->
                 CopyItem
         end
     end || CopyItem <- CopyList].

update_role_vip(RoleList) ->
    [begin
         case RoleVip of
             {r_role_vip, ROLE_ID, EXPIRE_TIME, LEVEL, EXP, IS_VIP_EXPERIENCE, FIRST_BUY_LIST, DAY_GIFT_TIME, GIFT_LIST} ->
                 {r_role_vip, ROLE_ID, EXPIRE_TIME, LEVEL, EXP, IS_VIP_EXPERIENCE, FIRST_BUY_LIST, DAY_GIFT_TIME, GIFT_LIST, 0};
             _ ->
                 RoleVip
         end
     end || RoleVip <- RoleList].

update_role_relive(RoleList) ->
    [begin
         case RoleRelive of
             {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS, DESTINY_ID, TALENT_POINTS, TALENT_SKILLS} ->
                 case TALENT_SKILLS of
                     [First|_] when erlang:is_integer(First) ->
                         {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS, DESTINY_ID, TALENT_POINTS, []};
                     _ ->
                         RoleRelive
                 end;
             _ ->
                 RoleRelive
         end
     end || RoleRelive <- RoleList].

update_role_pet(RoleList) ->
    [begin
         case RolePet of
             {r_role_pet, ROLE_ID, _LEVEL, _EXP, STEP_EXP, CUR_ID, PET_ID, PET_SPIRITS, SURFACE_LIST} ->
                 {r_role_pet, ROLE_ID, 0, STEP_EXP, CUR_ID, PET_ID, PET_SPIRITS, SURFACE_LIST};
             _ ->
                 RolePet
         end
     end || RolePet <- RoleList].

update_role_confine(RoleList) ->
    [begin
         case RoleConfine of
             {r_role_confine, RoleID, MissionList, Confine, WarSpirit, WarSpiritList, WarSpiritChange, RefineAllExp, BagId, BagList, WarGodList, WarGodPieces, ConfineReward} ->
                 WarSpiritList2 = update_role_confine2(WarSpiritList),
                 {r_role_confine, RoleID, MissionList, Confine, WarSpirit, WarSpiritList2, WarSpiritChange, RefineAllExp, BagId, BagList, WarGodList, WarGodPieces, ConfineReward};
             _ ->
                 RoleConfine
         end
     end || RoleConfine <- RoleList].

update_role_confine2(WarSpiritList) ->
    [begin
         case WarSpirit of
             {p_war_spirit, ID, Level, Exp, EquipList} ->
                 {p_war_spirit, ID, Level, Exp, EquipList, []};
             _ ->
                 WarSpirit
         end
     end || WarSpirit <- WarSpiritList].


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
         BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd, DIZZY_RATE, Min, Max, DoubleMiss, DoubleDamage, PROP_EFFECTS} ->
            {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
             DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, 0, ROLE_HURT_REDUCE,
             BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd, 0, 0, 0, 0, 0, 0, 0, DIZZY_RATE, Min, Max, DoubleMiss,
             DoubleDamage, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, PROP_EFFECTS};
        {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
         DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
         BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd, DIZZY_RATE, Min, Max, DoubleMiss,
         DoubleDamage, Metal, Wood, Water, Fire, Earth, MetalA, WoodA, WaterA, FireA, EarthA, Block1, Block2, Block3, Block4, HpRecoverRate, PROP_EFFECTS} ->
            {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
             DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, 0, ROLE_HURT_REDUCE,
             BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd,
             0, 0, 0, 0, 0, 0, 0, DIZZY_RATE, Min, Max, DoubleMiss,
             DoubleDamage, Metal, Wood, Water, Fire, Earth, MetalA, WoodA, WaterA, FireA, EarthA, Block1, Block2, Block3, Block4, HpRecoverRate, PROP_EFFECTS};
        {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
            DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, ROLE_HURT_REDUCE,
            BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd,
            A, B, C, D, E, F, G, DIZZY_RATE, Min, Max, DoubleMiss,
            DoubleDamage, Metal, Wood, Water, Fire, Earth, MetalA, WoodA, WaterA, FireA, EarthA, Block1, Block2, Block3, Block4, HpRecoverRate, PROP_EFFECTS} ->
            {actor_fight_attr, MAX_HP, ATTACK, DEFENCE, ARP, HIT_RATE, MISS, DOUBLE, DOUBLE_ANTI, HURT_RATE, HURT_DERATE, DOUBLE_RATE,
                DOUBLE_MULTI, MISS_RATE, DOUBLE_ANTI_RATE, ARMOR, SKILL_HURT, SKILL_HURT_ANTI, SKILL_DPS, SKILL_EHP, 0, ROLE_HURT_REDUCE,
                BOSS_HURT_ADD, BossHurtReduce, Drain, REBOUND, MONSTER_HURT_ADD, MOVE_SPEED, MONSTER_EXP_ADD, IMPRISON_HURT_ADD, SILENT_HURT_ADD, PoisonAdd, BurnHurtAdd,
                A, B, C, D, E, F, G, DIZZY_RATE, Min, Max, DoubleMiss,
                DoubleDamage, Metal, Wood, Water, Fire, Earth, MetalA, WoodA, WaterA, FireA, EarthA, Block1, Block2, Block3, Block4, HpRecoverRate, PROP_EFFECTS};
        _ ->
            Attr
    end.

update_family(FamilyList) ->
    [begin
         case Family of
             {p_family, FamilyID, FamilyName, Level, Money, _BossGrain, _BossTimes, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket, RedPacketLog, PacketId, Members, ApplyList, Depot, _DepotLog} when erlang:is_list(Depot) ->
                 Members2 = update_family_members(Members),
                 RedPacket2 = update_family_red_packet(RedPacket),
                 {p_family, FamilyID, FamilyName, Level, Money, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket2, RedPacketLog, PacketId, Members2, ApplyList};
             {p_family, FamilyID, FamilyName, Level, Money, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket, RedPacketLog, PacketId, Members2, ApplyList} ->
                 RedPacket2 = update_family_red_packet(RedPacket),
                 {p_family, FamilyID, FamilyName, Level, Money, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket2, RedPacketLog, PacketId, Members2, ApplyList};
             _ ->
                 Family
         end
     end || Family <- FamilyList].


update_family_members(Members) ->
    update_family_members(Members, []).

update_family_members([], List) ->
    List;
update_family_members([Member|T], List) ->
    Member2 = case Member of
                  {p_family_member, RoleId, RoleName, RoleLevel, Category, Title, Sex, Salary, _Active, _integral, Power, IsOnline, Last_offline_time} ->
                      {p_family_member, RoleId, RoleName, RoleLevel, Category, Title, Sex, Salary, Power, IsOnline, Last_offline_time};
                  _ ->
                      Member
              end,
    update_family_members(T, [Member2|List]).

update_family_red_packet(RedPacketList) ->
    [begin
         case RedPacket of
             {p_red_packet, ID, ICON, SENDER_NAME, CONTENT, TIME, AMOUNT, PIECE, BIND, SENT_NUM, PACKET_LIST} ->
                 {p_red_packet, ID, ICON, SENDER_NAME, CONTENT, TIME, AMOUNT, PIECE, BIND, SENT_NUM, PACKET_LIST, []};
             _ ->
                 RedPacket
         end
     end || RedPacket <- RedPacketList].



update_role_asset(RoleList) ->
    [begin
         case RoleAsset of
             {r_role_asset, RoleID, Silver, Gold, BindGold, ScoreList} ->
                 {r_role_asset, RoleID, Silver, Gold, BindGold, ScoreList, 0};
             _ ->
                 RoleAsset
         end
     end || RoleAsset <- RoleList].


update_role_trevi_fountain(RoleList) ->
    [begin
         case RoleTreviFountain of
             {r_role_trevi_fountain, RoleID, EdiTime, Reward, Integral} ->
                 {r_role_trevi_fountain, RoleID, EdiTime, Reward, Integral, 0, []};
             _ ->
                 RoleTreviFountain
         end
     end || RoleTreviFountain <- RoleList].

update_role_nature(RoleList) ->
    [begin
         case RoleNature of
             {r_role_nature, RoleID, Nature, _Quality, _Star, ConsumeMoney} ->
                 {r_role_nature, RoleID, Nature, 0, 0, ConsumeMoney};
             _ ->
                 RoleNature
         end
     end || RoleNature <- RoleList].