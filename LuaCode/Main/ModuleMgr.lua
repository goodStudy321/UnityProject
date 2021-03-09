--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017/5/12 21:14:02
-- 模块管理
-- 模块可有以下接口
-- Init        初始化           (必有)生命周期内仅调用一次
-- Update      更新             (可选)每帧调用
-- Login       登陆成功         (可选/未实现调用)
-- Logout      登出成功         (可选/未实现调用)
-- Clear       清理             (必有)登出/切换账号/断线重连成功后调用
-- Reconnect   重连成功         (可选/未实现调用)
-- Disconnect  断线成功         (可选/未实现调用)
-- BegChgScene 开始切换场景     (可选)
-- EndChgScene 结束切换场景     (可选)
--=============================================================================

ModuleMgr = {Name = "ModuleMgr"}

local My = ModuleMgr

--模块列表
My.mods = {}

--包含Update方法的模块
My.upMods = {}

--mod(table):模块
--fn(string):方法名
--err(boolean):true,方法不存在时输出错误
function My:Chk(mod, fn, err)
  local func = mod[fn]
  if type(func) ~= "function" and err then
    iTrace.Error("Loong", mod.Name, " no function:", fn)
  end
end

--添加模块
--path(string):路径
function My:Add(path)
  local mod = require(path)
  if type(mod) ~= "table" then
    iTrace.Error("Loong", path, " no return mod")
  elseif type(mod.Name) ~= "string" then
    iTrace.Error("Loong", path, " no Name field")
  else
    local show = true
    local Chk = self.Chk
    Chk(self, mod, "Init", show)
    Chk(self, mod, "Login")
    Chk(self, mod, "Logout")
    Chk(self, mod, "Clear", show)
    Chk(self, mod, "Reconnect")
    Chk(self, mod, "Disconnect")
    Chk(self, mod, "BegChgScene")
    Chk(self, mod, "EndChgScene")
    self.mods[#self.mods + 1] = mod
    local upfunc = mod.Update
    if(type(upfunc) == "function") then
      local upMods = My.upMods
      upMods[#upMods + 1] = mod
    end
  end
end

local Add = function(path) My:Add(path) end
Add("Data/Agent/AgentMgr")
Add("Data/Quality/QualityTool");
Add("Data/UserMgr")
Add("Data/AccMgr")
Add("Sdk/SDKFty")
Add("Mail/MailMgr")
Add("Data/Surver/SurverMgr")
Add("Data/Prop/PropMgr")
Add("Data/Prop/EquipMgr")
Add("Adv/MountsMgr")
Add("Adv/ThroneMgr")
Add("Adv/ThroneAppMgr")
Add("Adv/GWeaponMgr")
Add("Adv/MWeaponMgr")
Add("Adv/WingMgr")
Add("Data/TransApp/MountAppMgr")
Add("Data/TransApp/PetAppMgr")
Add("Collection/CollectMgr")
Add("Data/Pet/PetMgr")
Add("Scene/SceneMgr")
Add("Data/Prop/GuardMgr")
Add("Data/LoginScene/LoginSceneMgr")
Add("Data/Copy/CopyMgr")
Add("Data/Open/OpenMgr")
Add("Liveness/ActivStateMgr")
Add("OnlineAward/OnlineAwardMgr")
Add("FamilyAnswer/FamilyAnswerMgr")
Add("FamilyBoss/FamilyBossMgr")
Add("Answer/AnswerMgr")
Add("TopFight/TopFightMgr")
Add("Marry/MarryMgr")
Add("Success/SuccessMgr")
Add("TimeLimitActiv/TimeLimitActivMgr")
Add("TimeLimitActiv/LimitActivMgr")
Add("DiscountGift/DiscountGiftMgr")
Add("FamilyMission/FamilyMissionMgr")
Add("Elixir/ElixirMgr")
Add("Identification/IdentifyMgr")
Add("Rune/RuneMgr")
Add("mod/NavPathMgr")
Add("Data/Open/SystemMgr")
Add("Data/TreaFever/TreaFeverMgr")

Add("Liveness/NewActivMgr");

Add("Data/Open/ActivityMgr")
Add("Data/PicCollect/PicCollectMgr")
Add("Data/SkyBook/SkyBookMgr")
Add("Data/SkyMysterySeal/SMSMgr")
Add("Data/Friend/FriendMgr")
Add("Data/Flowers/FlowersMgr")
Add("Data/Family/FamilyMgr")
Add("Data/Family/FamilyActivityMgr")
Add("Data/Chat/ChatMgr")
Add("Data/QuickUse/QuickUseMgr")
Add("Data/Mission/MissionMgr")
Add("Data/FightTreasure/FightTreasureMgr")
Add("Data/Chapter/ChapterMgr")
Add("Data/MaskWord")
Add("Data/Escort/EscortMgr")
Add("Guide/GuideMgr")
Add("Data/VIP/VIPMgr")
Add("Data/Store/StoreMgr")
Add("Data/Notice/NoticeMgr")
Add("Data/EquipCollectionMgr")
Add("Data/GetPropMgr")
Add("Data/SecretArea/SecretAreaMgr")
Add("Data/LuaDropMgr")
Add("Data/LuaEmoMgr")
Add("Data/GetWayFunc")
Add("Data/Suit/SuitMgr")
Add("Data/KnotMgr")
Add("Data/Arena/Peak")
Add("Data/Map/MapMgr")
Add("Data/Arena/Droiyan")
Add("Data/OLastSceneUI/OLastSceneUI")
Add("Data/Arena/OffLBat")
Add("Data/Setting/SettingMgr")
Add("Data/OffLineReward/OffRwdMgr")
Add("Liveness/LivenessMgr")
Add("ImmortalSoul/ImmortalSoulMgr")
Add("Recharge/RechargeMgr")
Add("Data/VIP/VIPInvestMgr")
Add("Data/VIP/VIPExperienceMgr")
Add("Sign/SignMgr")
Add("LvAward/LvAwardMgr")
Add("ActiveCode/ActiveCodeMgr")
Add("Treasure/TreasureMgr")
Add("RankActiv/RankActivMgr")
Add("Invest/LvInvestMgr")
Add("Data/Rank/ThrUniBattle")
Add("Data/Boss/WBossRecord")
Add("Data/Boss/NetBoss")
Add("UI/UIRevive/ReviveMgr")
Add("Data/Team/TeamMgr")
Add("Data/SevenMgr")
Add("Data/Rebirth/RebirthMsg")
Add("LvAward/GdAwardMgr")
Add("Data/MoneyTree/MoneyTreeMgr")
Add("UI/Base/UIMgr")
Add("Data/Joystick/JoystickMgr")
Add("Data/Hangup/Hangup")
Add("Data/Hangup/UICtrlHgup")
Add("Data/Market/MarketMgr")
Add("Data/Auction/AuctionMgr")
Add("FestivalAct/FestivalActMgr")
Add("Data/OpenService/AccuPayMgr")
Add("Data/OpenService/CollWordsMgr")
-- Add("Ambit/AmbitMgr")
Add("mod/LoadingMgr")
Add("mod/TechBuried")
Add("mod/ScreenMgr")
Add("mod/DeviceEx")
Add("mod/PackCtrl")
Add("mod/NetObserver")
Add("mod/PushMgr")
Add("Title/TitleMgr")
Add("Data/Rank/RankNetMgr")
Add("Data/Role/FightVal")
Add("Data/Role/RoleAssets")
Add("Data/Role/SkillMgr")

Add("Data/Role/InnateMgr")
Add("Data/Role/UnitType")
Add("Data/Arena/RoleSkin")
Add("ActPreview/ActPreviewMgr")
Add("Data/Activity/ActvHelper")
Add("Data/OpenService/EvrDayMgr")
Add("Data/Activity/ActivityMsg")
Add("Invest/InvestMgr")
Add("MonthInvest/MonthInvestMgr")
Add("Data/OpenService/FirstPayMgr")
Add("FamilyWar/FamilyWarMgr")
Add("Data/Fashion/FashionMsg")
Add("Fashion/FashionMgr")
Add("Data/Elves/ElvesExperienceMgr")
Add("Data/Temple/TempleMgr")
Add("Data/Top/TopMgr")
--Add("Upg/UpgPkg")
Add("Data/RoleList/RoleList")
Add("Data/RushBuy/RushBuyMgr")
Add("LvLimitBuy/LvLimitBuyMgr")
Add("Feedback/FeedbackMgr")
Add("Data/Jump/JumpMgr")
Add("Benefit/JourneysMgr")
Add("Benefit/BenefitMgr")
Add("Data/Robbery/RobberyMgr")
Add("Data/Robbery/SpiritGMgr")
Add("Data/Robbery/RobEquipsMgr")
Add("Data/CloudBuy/CloudBuyMgr")
Add("Data/Cross/CrossMgr")
Add("Data/MarriageTree/MarriageTreeMgr")
Add("DayTarget/DayTargetMgr")
Add("Liveness/FindBackMgr")
Add("Data/Pray/PrayMgr")
Add("SoulBearst/SoulBearstMgr")
Add("Data/Rccnt/Rccnt")
Add("Data/Fx/AnimeEffMgr")
Add("Data/Activity/ShieldEntry")
Add("Ares/AresMgr")
Add("Data/TreasureMap/TreasureMapMgr")
Add("Data/MountGuide/MountGuide")
Add("BossReward/BossRewardMgr")
Add("Data/Role/OrnamentMgr")
Add("Data/ElvesNew/ElvesNewMgr")
Add("Demon/DemonMgr")
Add("FamilyEscort/FamilyEscortMgr")
Add("Data/FiveElement/FiveElmtMgr")
Add("Alchemy/AlchemyMgr")
Add("Data/PayMul/PayMulMgr")
Add("Data/OpenService/PayDoubleMgr")
Add("Data/ZaDan/ZaDanMgr")

Add("Data/DrawLots/DrawLotsMgr")
Add("Data/BlackMarket/BlackMarketMgr")
Add("FortuneCat/FortuneCatMgr");
Add("Data/LuckFull/LuckFullMgr")
Add("Data/TongtianRank/TongtianRankMgr")
Add("Data/OutGift/OutGiftMgr")
Add("Data/OutGift/GiftMgr")
Add("Data/EvrBox/EvrBoxMgr")
Add("TongTianTower/TongTianTowerMgr");
Add("Data/HappyChest/HappyChestMgr")
Add("Data/PracticeSec/PracticeSecMgr")
Add("Data/PracticeSec/PracSecMgr")
Add("Data/HeavenLove/HeavenLoveMgr");
Add("Data/Charm/CharmMgr")
Add("Data/LoveAtFirst/LoveAtFirstMgr");
Add("Data/RedPacketActiv/RedPacketActivMgr");
Add("Data/GoodByeSingle/GoodByeSingleMgr")
Add("Data/MoonLove/MoonLoveMgr");
Add("Data/HotLove/HotLoveMgr");
Add("Data/LimitDrop/LimitDropMgr");
Add("Data/OutGift/GuideTimeMgr")
--调用模块方法
function My:Call(fn)
  local func = nil
  for i, v in ipairs(self.mods) do
    func = v[fn]
    if(type(func) == "function") then
      func(v)
    end
  end
end


--初始化
function My:Init()
  self:Call("Init")
end

--登录成功
function My:Login()
  self:Call("Login")
end

--更新
function My:Update()
  for i, v in ipairs(self.upMods) do
    v:Update()
  end
end

function My:LateUpdate()
  for i, v in ipairs(self.upMods) do
    if v.Name == "UIMgr" then
      v:LateUpdate()
    end
  end
end

--登出成功
function My:Logout()
  self:Call("Logout")
end

--清理
function My:Clear(isReconnect)
  UnityEngine.Time.timeScale = 1;
  for i, v in ipairs(self.mods) do
    if(type(v.Clear) == "function") then
      v:Clear(isReconnect)
    end
  end
end



--重连成功
function My:Reconnect()
  self:Call("Reconnect")
end

--断线成功
function My:Disconnect()
  self:Call("Disconnect")
end

--开始切换场景
function My:BegChgScene()
  self:Call("BegChgScene")
end

--结束切换场景
function My:EndChgScene()
  self:Call("EndChgScene")
end


--添加模块列表

return My
