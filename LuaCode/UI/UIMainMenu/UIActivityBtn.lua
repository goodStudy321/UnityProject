--region UIBuffItem.lua
--Date
--此文件由[HS]创建生成

UIActivityBtn = Super:New{Name="UIActivityBtn"}
local M = UIActivityBtn

local aMgr = ActivityMgr

local OnlineA = require("UI/UIOnlineAward/UIOnlineAward")
local DbExp = require("UI.UIDoubleExp.UIDoubleExp")
local CopyDb = require("UI.UICopyDouble.UICopyDouble")
local FanAnswer = require("UI.UIFamilyAnswer.UIFamilyAnswerBtn")
local FanBoss = require("UI.UIFamilyActiv.UIFamilyBossBtn")
local Answer = require("UI.UIAnswer.UIAnswerBtn")
local FamDefendtor = require("UI.UIFamily.UIFamilyDefendtorBtn")
local V4 = require("UI.UIV4Panel.UIV4Btn")
local ElvesBtn = require("UI/UIElvesBtn/UIElvesBtn")
-- local FirstPay = require("UI.UIOpenService.UIFirstPayBtn")
-- local EvrPay = require("UI.UIOpenService.UIEvrPayBtn")
local FWBtn = require("UI/UIFamilyWarBtn/UIFamilyWarBtn")
local TopF = require("UI/UIArena/UITopFightBtn")
local ArenaBtn = require("UI/UIArena/ArenaBtn")
local InvitBtn = require("UI/UIMarry/UIInvitBtn")
local WorldBtn = require("UI/UIBoss/UIWorldBossBtn")
require("UI/UIDemon/UIBtnDemon")
require("UI/UIDiscountGift/UIDiscountGiftBtn")

--注册的事件回调函数

function M:Init(go)
	local name = "UI主界面Buff Item"
	self.Base = nil
	self.GO = go
	local t = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = "ActivityBtn"


	self.Root = t
	self.Widget = self.GO:GetComponent("UIWidget")
	self.BgBox = self.GO:GetComponent("BoxCollider")
	self.Bg = C(UIWidget, t, "Root", name, false)
	self.BgSprite = C(UISprite, t, "Root", name, false)
	self.Icon = C(UISprite, t, "Root/Icon", name, false)
	self.Name = C(UILabel, t, "Root/Label", name, false)
	self.Action = T(t, "Root/Action")
	self.TimerLab = C(UILabel, t, "Root/TimerLab", name, false)
	self.TimerBg = T(t, "Root/TimerLab/Sprite")
	self.Eff = T(t, "Root/Eff")

	self.iTweenColor = ObjPool.Get(TweenColor)
	self.iTweenColor.onValue:Add(self.UpdateColor, self)	
	self.iTweenVector3 = ObjPool.Get(TweenVector3)
	self.iTweenVector3.onValue:Add(self.UpdateVector3, self)

	self.IsClick = false
	self.TweenPos = {}
	self.TweenPos.old = nil
	self.TweenPos.new = nil

	self.CurLayer = nil

	--点击按钮
	UITool.SetLsnrSelf(self.GO, self.ClickItemBtn, self)

	--更新名字
	ActivityMgr.eUpActState:Add(self.UpActState, self)
	FestivalActMgr.eUpBlastName:Add(self.UpBlastName, self)
	TimeLimitActivMgr.eUpName:Add(self.UpActName, self)
	TreaFeverMgr.eUpFeverName:Add(self.UpFeverName, self)
end

function M:UpdateTemp(temp)
	self.Temp = temp
	self.id = temp.id
	local go = self.GO
	go.name = tostring(temp.type)
	self.Icon.spriteName = temp.icon
	--self.Icon:MakePixelPerfect()
	self.Name.text = temp.name
	if temp.layer == 4 or temp.layer == 5 then
		self.Bg.alpha = 1
	end
	
	if temp.id == aMgr.CDGN and self.Menus then
		self.Menus.MenuTips = go:GetComponent("UIMenuTip")
		self.Menus:AddEvent()
	end
	self:UpdateActive()
	self:InitSelfClass(temp.type)
	if temp.layer ~= 0 and temp.layer ~= 7 then
		self:UpdateBGSize(60,60)
	end
end

function M:InitSelfClass(type)
	local class = nil
	if type == aMgr.ZXJL then
		class = OnlineA
	elseif type == aMgr.SBJY then
		class = DbExp
	elseif type == aMgr.FBSB then
		class = CopyDb
	elseif type == aMgr.XLHS then
		EscortMgr:SetTimeLab(self.TimerLab)
	elseif type == aMgr.XMDT then
		class = FanAnswer
	elseif type == aMgr.XMBS then
		class = FanBoss
	elseif type == aMgr.HDDT then
		class = Answer
	elseif type == aMgr.MRLC then
		-- self:InitEvrPayBtn(t)
	elseif type == aMgr.SC then
		-- self:InitFirstPayBtn(t)
	elseif type== aMgr.XMSW then
		class = FamDefendtor
	elseif type == aMgr.BPZ then
		class = FWBtn
	elseif type == aMgr.QYZD then
		class = TopF
	elseif type == aMgr.LYQG then
		-- self:InitRushBuyBtn(t)
	elseif type == aMgr.JJD then
		class = ArenaBtn
	elseif type == aMgr.JHQT then
		class = InvitBtn
	elseif type == aMgr.BOSS then
		class = WorldBtn
	elseif type == aMgr.DemonArea then
		class = UIBtnDemon
	elseif type == aMgr.V4 then
		class = V4
	elseif type == aMgr.YJJBSH then
		class = ElvesBtn
	elseif type == aMgr.THLB then
		class = UIDiscountGiftBtn
	end

	if class then
		self.LuaClass = ObjPool.Get(class)
		if type == aMgr.BOSS then
			self.LuaClass:Init(self.Root, self)
		else
			self.LuaClass:Init(self.Root)
		end
	end
end


--[[点击按钮]]--
function M:ClickItemBtn(go)
	local temp = self.Temp
	if not temp then return end
	local id = temp.type
	if id ~= aMgr.BossReward and aMgr:CheckOpenForLvId(id) == false then
		local str = "系统未开启"
		local k,temp = aMgr:Find(id)
		if temp then
			str = string.format( "%s未开启",temp.name)
		end
		UITip.Error(str)
		return
	end
	self:ClickBtnForKey(id)
end

function M:ClickBtnForKey(key)
	self.IsClick = true
	self:UpdateEff()
	local O = UIMgr.Open
	if key == aMgr.PH then--排行奖励
		O(UIRank.Name)
	elseif key == aMgr.SD then--商城
		StoreMgr.OpenStore(2)
	elseif key == aMgr.FB then--副本
		if MissionMgr:IsExecuteEscort() == true then return end
		O(UICopy.Name)
	elseif key == aMgr.CJHL then--冲级豪礼
		UILvAward:OpenTab(1)
	elseif key == aMgr.ZS then--转生
		O(UIRebirth.Name)
	-- elseif key == aMgr.QD then--签到		
	-- 	O(UISign.Name)
	elseif key == aMgr.BOSS then--世界Boss
		if MissionMgr:IsExecuteEscort() == true then return end
		BossHelp.Open(UIBoss.Name)
    elseif key == aMgr.TTT then--通天塔
		if MissionMgr:IsExecuteEscort() == true then return end
		O(UICopyTowerPanel.Name)
	elseif key == aMgr.HY then--日常活跃
		O(UILiveness.Name)
	elseif key == aMgr.KFCB then--开服冲榜
		UIRankActiv:OpenTab(7)
	elseif key == aMgr.XB then--寻宝
		UITreasure:OpenTab(1)
	elseif key == aMgr.ZZSD then--主宰神殿
		UITemple.OpenCheck()
	elseif key == aMgr.DCWJ then--调查问卷
		SurverMgr:ReqSurverInfo()
	elseif key == aMgr.JJD then--竞技殿
		if MissionMgr:IsExecuteEscort() == true then return end
		UIArena.OpenArena(1)
	elseif key == aMgr.TS then --天书
		if SkyBookMgr:IsOpen(1, true) == false then
			return
		end
		O(UISkyBook.Name)
	elseif key == aMgr.XLHS then--仙灵护送
		EscortMgr:NavEscort()
	elseif key == aMgr.JRHD then --节日活动
		O(UIFestivalAct.Name)
	elseif key == aMgr.JZYL then --福利
		UIBenefit:Show(7)
	elseif key == aMgr.MRLC then --每日累充
		O(UIEvrDayPay.Name)
	elseif key == aMgr.SC then -- 首充有礼
		UIFirstPay:OpenFirsyPay()
	elseif key == aMgr.LYQG then -- 零元抢购
		SystemMgr:HideActivity(aMgr.LYQG)
		O(UIRushBuy.Name)
	elseif key == aMgr.YJJBSH then -- 绝版守护
		SystemMgr:HideActivity(aMgr.YJJBSH)
		O(UIElvesNew.Name)
	elseif key == aMgr.SMRZ then--实名认证
		O(UIIdentification.Name)
	elseif key == aMgr.XMSW then--守卫道庭
		UIMgr.Open(UIFamilyDefendWnd.Name)
	elseif key == aMgr.CZ then --充值
		VIPMgr.OpenVIP(1)
	elseif key == aMgr.PM then--市场
		--O(UIMarketWnd.Name)
		O(UIAuction.Name)
		--O(UITreaFever.Name)
	-- elseif key == aMgr.CJ then --成就
	-- 	O(UISuccess.Name)
	elseif key == aMgr.LT then --论坛
		if Sdk and Sdk:HasUC() then
			Sdk:OpenUserCenter()
		end
	elseif key == aMgr.DJ then--渡劫
		UIRobbery:OpenRobbery(1)
	elseif key == aMgr.XSYG then--限时云购
		O(UICloudBuy.Name)
	elseif key == aMgr.KFHD then--跨服活动
		UICross.OpenCheck()
	-- elseif key == aMgr.QTMB then --七天目标
	-- 	O(UIDayTarget.Name)
	-- elseif key == aMgr.QF then  -- 祈福
	-- 	O(UIPrayPanel.Name)
	elseif key == aMgr.BPZ then --帮派战
		if CustomInfo:IsJoinFamily() then
			O(UIFamilyWar.Name)
		end
	elseif key == aMgr.XYC then--许愿池
		O(UIWish.Name)
	elseif key==aMgr.VIPSC then --VIP商城
		StoreMgr.OpenVIPStore(1)
	elseif	key == aMgr.FBSB then  --副本双倍
		UIFestivalAct:Show(FestivalActMgr.CopyDb)
	elseif key == aMgr.SBJY then --双倍经验
		UIFestivalAct:Show(FestivalActMgr.ExpDB)
	elseif key == aMgr.ZCGF then --8~15天开服活动
		TimeLimitActivMgr.type=10014
		O(UITimeLimitActiv.Name)
		TimeLimitActivMgr:UpNorAction(13)
	elseif key == aMgr.KFFB then --8~15天开服活动
		TimeLimitActivMgr.type=10013
		O(UITimeLimitActiv.Name)
		TimeLimitActivMgr:UpNorAction(12)
	elseif key == aMgr.KFTJ then --8~15天开服活动
		TimeLimitActivMgr.type=10012
		O(UITimeLimitActiv.Name)
		TimeLimitActivMgr:UpNorAction(11)
	elseif key == aMgr.QRTZ then --七日投资
		O(UISevenInvest.Name)
	elseif key == aMgr.XSQG then --限时抢购
		O(UITimeLimitBuy.Name)
	elseif key == aMgr.BossReward then  --Boss悬赏
		O(UIBossReward.Name)
	elseif key ==aMgr.V4 then -- V4
		--O(UIGuideJump.Name)
		local vip = VIPMgr.GetVIPLv()
		if vip < 4 then
			UIMgr.Open(UIV4Panel.Name)
			VIPMgr.ShowV4Red(false)
			return
		end
		VIPMgr.OpenVIP()
	elseif key ==aMgr.LDL then -- 炼丹炉
		O(UIBlastFur.Name)
	elseif key == aMgr.SMBZ then --神秘宝藏
		O(UITreaFever.Name)
	elseif key == aMgr.DemonArea then --魔域禁地
		O(UIDemonArea.Name)
	elseif key == aMgr.JS then
		UIRole:SelectOpen(1)
	elseif key == aMgr.BB then
		UIRole:SelectOpen(4)
	elseif key == aMgr.JN then
		UIRole:SelectOpen(2)
	elseif key == aMgr.YC then
		local open = OpenMgr:IsOpen("3") or false
		if open == true then
			AdvMgr:OpenBySysID(3)
		else
			AdvMgr:OpenBySysID(1)  -- id:养成系统系统id: 1--->坐骑  2--->法宝  3--->宠物  4--->神兵  5--->翅膀
		end
	elseif key == aMgr.LQ then
		if User.instance.MapData.Level<20 then --装备强化所需等级
			UITip.Log("系统暂未开启")
		else
			EquipMgr.OpenEquip(1)--装备
		end
	elseif key == aMgr.FW then
		O(UIRune.Name);--符文
	elseif key == aMgr.TJ then
		--O(UISoulBearst.Name)
		O(UIPicCollect.Name)
	elseif key == aMgr.XH then
		O(UIImmortalSoul.Name)--仙魂
	elseif key == aMgr.XL then
		UIMarry:OpenTab(1)--仙侣
	elseif key == aMgr.DT then --道庭
		if FamilyMgr:JoinFamily() == true then
			O(UIFamilyMainWnd.Name);
		else
			O(UIFamilyListWnd.Name);
		end
	elseif key == aMgr.XMBS then--道庭Boss
		if CustomInfo:IsJoinFamily() then
			UIFamilyBossIt:OpenTab(true)
		end
	elseif key == aMgr.ZXJL then--在线奖励
		UIMgr.Open(UIAwardPopup.Name, self.OpenAwardPopup, self)
	elseif key == aMgr.XMDT then--仙盟答题
		if CustomInfo:IsJoinFamily() then
			UIMgr.Open(UIFamilyAnswerIt.Name)
		end
	elseif key == aMgr.HDDT then--活动答题
		SceneMgr:ReqPreEnter(30006, true, true)
	elseif key == aMgr.QYZD then--青云之巅
		UIMgr.Open(UITopFightIt.Name)
	elseif key == aMgr.JHQT then--结婚请帖
		UIProposePop:OpenTab(5)
	elseif key==aMgr.LB1 then --套装
		SuitMgr.OpenSuit(1)
	elseif key==aMgr.LB3 then --宝石、道具合成
		UICompound:SwitchTg(1)
	-- elseif key==aMgr.DTRW then--道庭任务
	-- 	if CustomInfo:IsJoinFamily() then
	-- 		UIMgr.Open(UIFamilyMission.Name)
	-- 	end
	elseif key == aMgr.Escort then --道庭护送
		if CustomInfo:IsJoinFamily() then
			UIMgr.Open(UIFamilyEscort.Name)
		end
	elseif key == aMgr.ZL then --战灵
		UIRobbery:OpenRobbery(2)
	elseif key == aMgr.DY then--丹药
		UIRole:SelectOpen(5)
	elseif key==aMgr.SSQ then --上上签
		DrawLotsMgr.OpenUI()
	elseif key == aMgr.ZCM then --招财猫
		FortuneCatMgr.OpenUI();
	elseif key == aMgr.XYJB then --幸运鉴宝
		UIMgr.Open("UILuckFull")
	elseif key == aMgr.SCBS then --首充倍送
		UIPayMul:OpenTab(1)
	elseif key == aMgr.JBHL then
		UIOutGift:OpenTab(1)
	elseif key == aMgr.XLMJ then
		UIPracticeSec:OpenTab(1)
	elseif key == aMgr.TTBT then
		TongTianTowerMgr:OpenUI();
    elseif key == aMgr.HLBX then
		UIMgr.Open(UIHappyChest.Name)
	elseif key==aMgr.TDQY then
		HeavenLoveMgr.OpenUI(1)
	else
		local temp = self.Temp
		if StrTool.IsNullOrEmpty(temp.ui) == false then
			if temp then
				UIMgr.Open(temp.ui)
			end
		end
	end
end

--[[点击按钮]]--

function M:ShowOpenEffect()
	local temp = self.Temp
	if not temp then return end
	local class = self.class
	if not class then return end
	local t = temp.type
	if t == aMgr.BOSS then
		class:CheckOpen()
	end
end


--[[红点状态]]--
function M:UpdateActive()
	local state = self:GetActive()
	self.Action:SetActive(state)
	self:UpdateEff() 
	return state
end

function M:GetActive()
	local temp = self.Temp
	local state = false
	if temp.id ~= aMgr.CDGN then
		if temp.type == 713 then
			temp.type = 713
		end
		state = SystemMgr:GetActivity(temp.type)
	else
		if self.Menus then state = self.Menus:GetActivity(temp.type) end
	end
	return state
end
--[[红点状态]]--


--[[显示特效]]--
function M:UpdateEff()
	local status = false
	local isDeploy = self:IsDeploy()
	local isSpecia =  self:IsSpecial()
	if self.Temp and self.Base then
		local isClick = self.IsClick
		local active = self:GetActive()
		local isZoom = self.Temp.zoom and self.Temp.zoom == 1
		local eType = self.Temp.effect
		local curLayer = self.CurLayer
		if curLayer == nil or curLayer < 6 then
			if eType == 1 then
				if not isZoom then
					status = active == true and isDeploy == true
				else
					if isSpecia == false then
						status = active == true
					else
						status = active == true and isDeploy == true
					end
				end
			elseif eType == 2 or eType == 3 then
				if not isZoom then
					status = not isClick and isDeploy == true
				else
					if isSpecia == false then
						status = not isClick
					else
						status = not isClick and isDeploy == true
					end
				end
			elseif eType == 4 then
				status = isDeploy
			end
		else
			if eType == 4 then
				status = true
			end
		end
	end
	self.Eff:SetActive(status)
end
--[[显示特效]]--


--[[检测系统类型]]--
function M:IsCheckType(type)
	if self.Temp and self.Temp.type == type then
		return true
	end
	return false
end
--[[检测系统类型]]--

--更新节日活动按钮
function M:UpActState(type)
	if self.id == 104 then
		-- if type == FestivalActMgr.BZFB then
		-- 	return ;
		-- end
		-- local icon = 0
		-- local iconName = ""
		-- local mgr = FestivalActMgr
		-- --[[
		-- for k,v in pairs(mgr.ActiveInfo) do
		-- 	if tonumber(k) ~= mgr.XYC then
		-- 		icon = v.icon
		-- 		iconName = v.iconName
		-- 		break
		-- 	end
		-- end
		-- ]]--
		-- local info = mgr.ActiveInfo[tostring(type)]
		-- if not info then return end
		-- icon = info.icon
		-- iconName = info.iconName
		-- local cfg = ActIconCfg[icon]
		-- if cfg == nil then return end
		-- if cfg.topId ~= 0 then return end
		-- self.Icon.spriteName = cfg.icon
		-- self.Name.text = iconName

		local icon = 0
		local iconName = ""
		local mgr = FestivalActMgr
		for k,v in pairs(mgr.ActiveInfo) do
			if mgr:IsFesActType(tonumber(k)) then
				icon = v.icon
				iconName = v.iconName
				break
			end
		end
		local cfg = ActIconCfg[icon]
		if cfg == nil then return end
		if cfg.topId ~= 0 then return end
		self.Icon.spriteName = cfg.icon
		self.Name.text = iconName
	end
end

--更新活动名字
function M:UpActName(name, sprName)
	if self.id == 144 then
		self.Name.text = name
		self.Icon.spriteName = sprName
	end
end

--更新炼丹炉名字
function M:UpBlastName(name, sprName)
	if self.id == 150 then
		self.Name.text = name
		self.Icon.spriteName = sprName
	end
end

-- 更新神秘宝藏名字
function M:UpFeverName(name,sprName)
	if self.id == 312 then
		self.Name.text = name
		self.Icon.spriteName = sprName
	end
end

function M:Play(isSpecial)
	local temp = self.Temp
	if not temp then return end
	if temp.zoom == 1 then 
		if temp.layer == 0 then
			self.LuaClass:CheckOpen()
		end
	end
	local bg = self.BgSprite
	if bg then
		local status = false 
		local isDeploy = self:IsDeploy()
		if temp.zoom == 1 then	
			if isSpecial == true then
				if self.CurLayer ~= 6 and self.CurLayer ~= 7 then
					status = isDeploy
				else
					status = true
				end
			else
				status = true
			end
		else
			status = isDeploy
		end
		self:PlayGOColor(status)
		self:PlayGOVector3(status)
	end
	self:UpdateEff()
end

function M:PlayTween(value,changeScene)
	local class = self.LuaClass
	if class and class.Eff then
		class.Eff:SetActive(value)
	end
	self:PlayGOColor(value, changeScene)
	self:PlayGOVector3(value, changeScene)
	self:UpdateEff()
end

function M:PlayGOColor(value, changeScene)
	local itc = self.iTweenColor
	if not itc then return end
	itc:Stop()
	itc:Reset()
	if changeScene == nil then changeScene = false end
	self.TweenTarget = self.Widget
	local from = nil
	local bg = self.BgSprite
	if bg then
		from = bg.color
	end
	if from == nil then return end
	if value == false then
		if from.a == 0 then return end
		if changeScene == false then
			itc:Start(from, Color.New(1,1,1,0), 0.2)
		else
			bg.color = Color.New(1,1,1,0)
		end
		self:UpdateBgBoxStatus(false)
	else
		if from.a == 1 then return end
		if changeScene == false then
			itc:Start(from, Color.New(1,1,1,1), 0.2)
		else
			bg.color = Color.New(1,1,1,1)
		end
		self:UpdateBgBoxStatus(true)
	end
end

function M:UpdateColor(color)
	local bg = self.BgSprite
	if bg then
		bg.color = color
	end
end

function M:UpdateBGSize(w, h)
	local bg = self.BgSprite
	if bg then
		bg.width = w
		bg.height = h
	end
end

function M:PlayGOVector3(value, changeScene)
	local itc = self.iTweenVector3
	if not itc then return end
	itc:Stop()
	itc:Reset()
	if changeScene == nil then changeScene = false end
	local tweenPos = self.TweenPos
	local from = nil
	local go = self.GO
	if go then
		from = go.transform.localPosition
	end
	if from == nil then return end
	if value == true then
		if Vector3.Distance(from, tweenPos.new) == 0 then return end
		if changeScene == false then
			itc:Start(from, tweenPos.new, 0.2)
		else
			go.transform.localPosition = tweenPos.new
		end
	else
		if Vector3.Distance(from, tweenPos.old) == 0 then return end
		if changeScene == false then			
			itc:Start(from, tweenPos.old, 0.2)
		else
			go.transform.localPosition = tweenPos.old
		end
	end
end

function M:UpdateVector3(pos)
	local go = self.GO
	if LuaTool.IsNull(go) == false then
		go.transform.localPosition = pos
	end
end

function M:UpdateBgBoxStatus(value)
	if value == false then
		local temp = self.Temp
		if temp then
			if temp.layer > 5 then 
				return 
			end
		end
	end
	local box = self.BgBox
	if box then
		box.enabled = value
	end
end

--展开状态 
function M:IsDeploy()
	local parent = self.Base
	if parent then
		return parent.IsDeploy
	end
	return false
end

function M:IsSpecial()
	local parent = self.Base
	if parent then
		return parent.IsSpecial
	end
	return false
end

function M:Reset()
	self.CurLayer = nil
	local eff = self.Eff
	local lab = self.Name
	local tLab = self.TimerLab
	local icon = self.Icon
	local action = self.Action
	local class = self.LuaClass
	local root = self.Root
	local bg = self.Bg
	if eff then eff:SetActive(false) end
	if lab then 
		lab.text = "" 
	end
	if tLab then 
		tLab.text = "" 
		tLab.gameObject:SetActive(false)
	end
	if bg then 
		bg.alpha = 1
	 end
	if icon then
		icon.color = Color.white
		icon:SetDimensions(66, 66)
	end
	if action then 
		action:SetActive(false) 
	end
	if root then
		root.localScale = Vector3.one
	end
	if class then 
		class:Dispose()
		class = nil
	end
	local itc = self.iTweenColor
	if itc then
		itc:Stop()
	end
	self:StopTweenVector3()
	local tweenPos = self.TweenPos
	tweenPos.old = nil
	tweenPos.new = nil
	self:UpdateBgBoxStatus(true)
end

function M:StopTweenVector3()
	local itp = self.iTweenVector3
	if itp then
		itp:Stop()
	end
end

function M:Dispose()
	local itc = self.iTweenColor
	if itc then
		itc:Stop()
		itc.onValue:Remove(self.UpdateColor, self)	
		self.iTweenColor:AutoToPool()
	end
	SELF.iTweenColor = nil
	local itc = self.iTweenVector3
	if itc then
		itc:Stop()
		itc.onValue:Remove(self.UpdateVector3, self)	
		self.iTweenVector3:AutoToPool()
	end
	self.iTweenVector3 = nil
	if self.GO then
		self.GO.transform.parent = nil
		Destroy(self.GO)
	end
	ObjPool.Add(self.LuaClass)
	self.LuaClass = nil
	self.GO = nil
	ActivityMgr.eUpActState:Remove(self.UpActState, self)
	TimeLimitActivMgr.eUpName:Remove(self.UpActName, self)
	FestivalActMgr.eUpBlastName:Remove(self.UpBlastName, self)
	TreaFeverMgr.eUpFeverName:Remove(self.UpFeverName, self)
end
--endregion
