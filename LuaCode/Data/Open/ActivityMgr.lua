--region ActivityMgr.lua
--Date
--此文件由[HS]创建生成

ActivityMgr = {Name="ActivityMgr"}
local M = ActivityMgr
M.eInit = Event()
M.eOpen = Event()
M.eClose = Event()
M.eUpActState = Event()

M.CDGN = 999		--菜单

M.SD = 101		--商城
M.PH = 102 		--排行榜
-- M.QD = 103 		--签到
M.SMRZ = 104 		--实名认证
M.KFCB = 105 		
M.SC = 106 		--首充有礼
M.CZ = 107 		--充值
M.LT = 108
M.LYQG = 109	--零元抢购	
M.QRTZ = 112    --七日投资
M.XSQG = 113    --限时抢购
M.V4 = 114     --V4
-----------------------------------
M.TTT = 201 		--通天塔
M.JJD = 202 		--竞技殿
M.BOSS = 203 		--Boss巢穴
M.ZS = 204 		--转生
M.XB = 205 		--寻宝
M.JZYL = 206 	--开服活动	
M.PM = 207 		--市场
-- M.CJ = 208 		--成就
M.DJ = 209 		--渡劫
M.THLB = 212	--特惠充值礼包
-- M.DTRW = 213	--道庭任务
-----------------------------------
M.JRHD = 301 		
M.ZXJL = 302 		--在线奖励
M.CJHL = 303 		--冲级豪礼
M.DCWJ = 304 		--调查问卷
M.FBSB = 305 		
M.TS = 306 		--天书
M.SBJY = 307 		
M.MRLC = 308 		--每类累充
M.XMSW = 309 		
M.XMBS = 310 		
M.XMDT = 311 		
M.BPZ = 312 		
M.QYZD = 313 		
M.XSYG = 314 --限时云购
M.KFHD = 320 --跨服活动
M.JHQT = 315 --结婚请帖
M.XYC = 318  --许愿池
M.ZCGF = 321 --8~15天开服活动(展翅高飞)
M.KFFB = 222 --法宝
M.KFTJ = 223 --图鉴
M.ZZSD = 322 --主宰神殿
M.XTZL = 324 --仙途之路
M.SMBZ = 330 -- 神秘宝藏
-----------------------------------
M.HY = 401 		--日常活跃
M.FB = 402 		--副本
-----------------------------------
M.XLHS = 501 		
M.HDDT = 502 	

M.QTMB = 316
--M.QF = 317    -- 祈福
M.VIPSC = 319 --VIP商城
M.LDL = 323 -- 炼丹炉

M.BossReward = 110 --Boss悬赏
M.DemonArea = 111  --魔域禁地
M.Escort = 103   --道庭护送

M.YJJBSH = 602 --永久绝版守护
-----------------------------------
M.JS = 701--角色
M.JN = 702--技能
M.YC = 703
M.LQ = 704 --装备
M.FW = 705
M.TJ = 706
M.XH = 707
M.XL = 708
M.DT = 709
M.LB1 = 710 -- 套装
M.LB2 = 711  --装备收集
M.LB3 = 712 --宝石、道具、装备合成
M.TJY = 713 --天机印
M.ZL = 714 --战灵
M.DY = 715--丹药
M.SSQ = 716   --上上签
M.ZCM = 325		--招财猫
M.HSJB=327 --黑市鉴宝
M.ZADAN = 326   --幸运砸蛋
M.Alchemy = 317   --新炼丹炉
M.XYJB =328 --幸运鉴宝
M.SCBS =329 --首充倍送
M.JBHL = 332 --绝版豪礼
M.TTBT = 333 --通天宝塔
M.HLBX = 334 --欢乐宝箱
M.XLMJ = 335 --修炼秘籍
M.TDQY = 336 --天道情缘


function M:Init()
	self.IsClear = false
	self.Info = {}
	self:AddEvent()
end

function M:InitData()
	if GameSceneManager.SceneLoadStateToInt ~= 0 then 
		for k,v in pairs(ActivityTemp) do
			if v.continued then
				self:Add(v, true)
			end
		end
		self.eInit()
	end
end

function M:AddEvent()
	local EH = EventHandler
	self.OnOnChangeScene = EH(self.InitData , self)
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
end

function M:UpdateEvent(e)
	e("OnChangeScene", self.OnOnChangeScene)
end

function M:SetEvent(fn)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.LvEvent, self)
	UserMgr.eLvUpdate[fn](UserMgr.eLvUpdate, self.LvUpdate, self)
	OpenMgr.eOpenActivity[fn](OpenMgr.eOpenActivity, self.AddId, self)
	--SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.InitData, self)
	SurverMgr.eUpdateSurverState[fn](SurverMgr.eUpdateSurverState, self.UpdateSurverState, self)
	OnlineAwardMgr.eUpOnlineInfo[fn](OnlineAwardMgr.eUpOnlineInfo, self.UpdateOnlinState, self)
	ActivStateMgr.eUpActivState[fn](ActivStateMgr.eUpActivState, self.RespUpActivState, self)
	FamilyAnswerMgr.eUpState[fn](FamilyAnswerMgr.eUpState, self.RespUpFamAnswerState, self)
	FamilyBossMgr.eUpState[fn](FamilyBossMgr.eUpState, self.RespUpFamBossState, self)
	AnswerMgr.eUpState[fn](AnswerMgr.eUpState, self.RespUpAnswerState, self)
	-- IdentifyMgr.eUpdateIdentify[fn](IdentifyMgr.eUpdateIdentify, self.UpdateIdentify, self)
	FamilyActivityMgr.eFmlDftState[fn](FamilyActivityMgr.eFmlDftState,self.UpFmlDftState,self);
	FamilyWarMgr.eUpdateFWState[fn](FamilyWarMgr.eUpdateFWState, self.UpdateFWState, self)
	RushBuyMgr.eRushBuyBtn[fn](RushBuyMgr.eRushBuyBtn, self.UpdateRushBtnState, self)
	TopFightMgr.eUpState[fn](TopFightMgr.eUpState, self.RespUpTopFState, self)
	MarryMgr.eFeastState[fn](MarryMgr.eFeastState, self.RespFeastState, self)
	FestivalActMgr.eUpdateActState[fn](FestivalActMgr.eUpdateActState, self.UpdateActState, self)
	TimeLimitActivMgr.eUpState[fn](TimeLimitActivMgr.eUpState,self.UpTLActivState,self)
	BossRewardMgr.eUpdateBtnState[fn](BossRewardMgr.eUpdateBtnState,self.UpdateBossRewardState,self)
	--FestivalActMgr.eUpState[fn](FestivalActMgr.eUpState,self.UpdateBlastState,self)
	-- TreaFeverMgr.eUpState[fn](TreaFeverMgr.eUpState,self.UpdateFeverStatue,self)
	DiscountGiftMgr.eUpState[fn](DiscountGiftMgr.eUpState,self.UpDiscountGiftState,self)
	ElvesNewMgr.eUpState[fn](ElvesNewMgr.eUpState,self.UpElvesNewState,self)
	VIPMgr.eOpenV4Icon[fn](VIPMgr.eOpenV4Icon,self.UpV4State,self)
	--FamilyEscortMgr.eUpdateEscortBtn[fn](FamilyEscortMgr.eUpdateEscortBtn, self.UpdateEscortBtn, self)
	NewActivMgr.eUpActivInfo[fn](NewActivMgr.eUpActivInfo, self.UpdateNewActiv, self);
	-- CrossMgr.eCross[fn](CrossMgr.eCross,self.ReCross,self)
end

-- function M:ReCross( state )
-- 	local k,v = self:Find(self.KFHD)
-- 	if state then
-- 		self:Add(v)
-- 	else
-- 		self:Remove(v)
-- 	end
-- end

--更新8~15天开服状态
function M:UpTLActivState(type,state)
	local id=TimeLimitActivMgr:TypeGetTp(type)
	local k,v = self:Find(id)
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--响应宴会状态
function M:RespFeastState(state)
	local k,v = self:Find(self.JHQT)
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--更新调查问卷状态
function M:UpdateSurverState(state)
	local k,v = self:Find(self.DCWJ)
	if state == true then
		self:Add(v)
	else
		local ui = UIMgr.Get(UISurverPanel.Name)
		if ui then ui:Close() end
		self:Remove(v)
	end
end

-- 更新炼丹炉
function M:UpdateBlastState(state)
	local k,v = self:Find(self.LDL)
	if state == true then
		self:Add(v)
	else
		local ui = UIMgr.Get(UIBlastFur.Name)
		if ui then ui:Close() end
		self:Remove(v)
	end
end

-- 更新神秘宝藏
function M:UpdateFeverStatue(state)
	local k,v = self:Find(self.SMBZ)
	if state == true then
		self:Add(v)
	else
		local ui = UIMgr.Get(UITreaFever.Name)
		if ui then ui:Close() end
		self:Remove(v)
	end
end

--更新特惠礼包
function M:UpDiscountGiftState(state)
	local k,v = self:Find(self.THLB)
	if state == true then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--更新永久绝版守护
function M:UpElvesNewState(state)
	local k,v = self:Find(self.YJJBSH)
	if state == true then
		self:Add(v)
	else
		self:Remove(v)
	end
end

-- 更新V4特权
function M:UpV4State(state)
	local k,v = self:Find(self.V4)
	if state == true then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--更新在线奖励状态
function M:UpdateOnlinState(list)
	local k,v = self:Find(self.ZXJL)
	if not list or #list == 0 then
		self:Remove(v)
	else
		self:Add(v)
	end
end

--响应更新活动状态
function M:RespUpActivState(id)
	local info = LivenessInfo
	local function set(id, btnType)
		local data = info:GetActInfoById(id)
		if data then
			local k,v = self:Find(btnType)
			if data.val == 1 then
				self:Add(v)
			else
				self:Remove(v)
			end
		end
	end
	set(1001, self.CJHL)
	set(1007, self.KFCB)
	set(1012, self.XLHS)
	set(1018, self.JZYL)
	set(1006, self.MRLC)
	set(1004, self.SC)
	set(1016, self.LYQG)
	set(1020,self.XSYG)
	set(1026, self.QRTZ)
	-- set(1027, self.XSQG)
	set(1028, self.XYC)
	set(1032,self.XTZL)
end

--更新新活动
function M:UpdateNewActiv(activId)
	-- local function UpdateActiv(activId, btnType)
	-- 	local data = NewActivMgr:GetActivInfo(activId);
	-- 	if data then
	-- 		local k,v = self:Find(btnType);
	-- 		if data.val == 1 then
	-- 			self:Add(v);
	-- 		else
	-- 			self:Remove(v);
	-- 		end
	-- 	end
	-- end

	--[[
		调用UpdateActiv添加新活动
		activId为活动ID
		btnType为上面添加self里自己添加的与ID对应的键值
	]]
	self:UpdateActiv(2000, self.SCBS);
	self:UpdateActiv(2001, self.ZCM);
	self:UpdateActiv(2003, self.HSJB);
	self:UpdateActiv(2004,self.SSQ)
	self:UpdateActiv(2002,self.ZADAN)
	self:UpdateActiv(2005,self.XYJB)
	self:UpdateActiv(2006,self.JBHL)
	self:UpdateActiv(2009,self.TTBT);
	self:UpdateActiv(2008, self.HLBX)
	self:UpdateActiv(2010, self.XLMJ)
	self:UpdateActiv(2012, self.TDQY)
	self:UpdateActiv(2015, self.XSQG)
end


function M:UpdateActiv(activId, btnType)
	local data = NewActivMgr:GetActivInfo(activId);
	if data == nil then
		local k,v = self:Find(btnType);
		self:Remove(v);
	end
	if data then
		local k,v = self:Find(btnType);
		if data.val == 1 then
			self:Add(v);
		else
			self:Remove(v);
		end
	end
end

function M:UpdateActState(type, state)
	local btn = nil
	local openIndex = self:ElvesAct(type, state)
	if openIndex == 1 then
		return
	end
	if type == 1010 then
		btn = self.SBJY
	elseif type == 1011 then
		btn = self.FBSB
	elseif type == 1003 then
		btn = self.XYC
	-- elseif type == 1012 then
		-- btn = self.YJJBSH
	elseif type == FestivalActMgr.AlchemyStore
	or type == FestivalActMgr.BestAlchemy
	then
		btn = self.Alchemy
	end
	if btn then
		local k,v = self:Find(btn)
		if state then
			self:Add(v)
		else
			self:Remove(v)
		end
	end

	local mgr = FestivalActMgr
	if type ~= mgr.XYC and type ~= mgr.LDL and type ~= mgr.SMBZ and type ~= mgr.BestAlchemy and type ~= mgr.AlchemyStore then
		local b = mgr:IsOpen(mgr.JRHD)
		local k,v = self:Find(self.JRHD)
		
		if b then
			self:Add(v)
		else
			self:Remove(v)
		end
	end

	if type == mgr.SMBZ then
		local state = mgr:IsOpenSMBZ()
		local k,v = self:Find(self.SMBZ)
		if state == true then
			self:Add(v)
		else
			local ui = UIMgr.Get(UITreaFever.Name)
			if ui then ui:Close() end
			self:Remove(v)
		end
	end

	self.eUpActState(type)
end

function M:ElvesAct(type,state)
	local openIndex = 0
	if type == 1012 then
		if state == true then
			openIndex = 1
		else
			openIndex = 2
		end
	end
	return openIndex
end

--响应更新道庭答题状态
function M:RespUpFamAnswerState(state)
	local k,v = self:Find(self.XMDT)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--响应更新道庭Boss状态
function M:RespUpFamBossState(state)
	local k,v = self:Find(self.XMBS)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--响应更新活动答题状态
function M:RespUpAnswerState(state)
	local k,v = self:Find(self.HDDT)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

function M:UpdateTower(state)
	local k,v = self:Find(self.TTT)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--响应更新道庭守卫状态
function M:UpFmlDftState(state)
	local k,v = self:Find(self.XMSW)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--青云之巅
function M:RespUpTopFState(state)
	local k,v = self:Find(self.QYZD)
	if state == 2 then
		self:Add(v)
	else
		self:Remove(v)
	end
end

--等级更新
function M:LvEvent()
	local cur = User.MapData.Level
	self.lv = 0
	if self.lv then
		for k,v in pairs(ActivityTemp) do
			if v.id ~= 104 then
				if v.id == 134 then
					v.id = v.id
				end
				if cur >= self.lv and v.lv <= cur then
					self:Add(v)
				elseif cur < self.lv and v.lv > cur then
					self:Remove(v)
				end
			end
		end
	end
	self.lv = User.MapData.Level
end

function M:LvUpdate()
	--if self.IsClear == false then return end
	self.IsClear = false
	self:LvEvent()
end

function M:UpdateIdentify(state)
	local k,v = self:Find(self.SMRZ)
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end

function M:UpdateFWState(state)
	local k,v = self:Find(self.BPZ)
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end


function M:UpdateEscortBtn()
	local k,v = self:Find(self.Escort)
	local state = FamilyEscortMgr:IsOpen()
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end

function M:UpdateBossRewardState(state)
	local k,v = self:Find(self.BossReward)
	if state then
		self:Add(v)
	else
		self:Remove(v)
	end
end

function M:UpdateRushBtnState(state)
	local k,v = self:Find(self.LYQG)
	if state == true then
		self:Add(v)
	elseif state == false then 
		self:Remove(v)
	end
end

function M:UpdateCardBtnState(state)
	local k,v = self:Find(self.ZK)
	if state == true then
		self:Add(v)
	elseif state == false then 
		self:Remove(v)
	end
end

function M:CheckOpenForLvId(id)
	for k,v in pairs(ActivityTemp) do
		if v.type == id then
			return self:CheckOpen(v)
		end
	end
end

function M:CheckOpen(temp)
	local type = temp.type
	if not temp then return false end
	local info = LivenessInfo
	if type == self.DCWJ then
		return SurverMgr.State
	elseif type == self.JHQT then
		return MarryMgr.State
	elseif type == self.ZXJL then
		return OnlineAwardMgr.State
	elseif type == self.ZCGF or type == self.KFFB or type == self.KFTJ then
		local id=TimeLimitActivMgr:TypeGetId(type)
		return TimeLimitActivMgr.State[tostring(id)]
	elseif type == self.CJHL then
		return info:IsOpen(1001)
	elseif type == self.KFCB then
		return info:IsOpen(1007)
	elseif type == self.QRTZ then
		return info:IsOpen(1026)
	-- elseif type == self.XSQG then
	-- 	return info:IsOpen(1027)
	elseif type == self.ZS then
	elseif type == self.ZZSD then  --主宰神殿开启
		return  OpenMgr:IsOpen(63)
	elseif type == self.SBJY then
		return FestivalActMgr:IsOpenExpDB()
	elseif type == self.FBSB then
		return FestivalActMgr:IsOpenCopyDB()
	elseif type == self.XYC then
		return FestivalActMgr:IsOpen(FestivalActMgr.XYC) or info:IsOpen(1028)
	elseif type == self.LDL then
		return FestivalActMgr.BlastState
	elseif type == self.SMBZ then
		-- return TreaFeverMgr.OpenState
		return FestivalActMgr:IsOpenSMBZ()
	elseif type == self.V4 then
		return VIPMgr.V4State
	elseif type == self.XLHS then
		return info:IsOpen(1012)
	elseif type == self.XMDT then
		return FamilyAnswerMgr.State
	elseif type == self.XMBS then
		return FamilyBossMgr.State
	elseif type == self.HDDT then
		return AnswerMgr.State
	elseif type == self.THLB then
		return DiscountGiftMgr.State
	-- elseif type == self.DTRW then
	-- 	return OpenMgr:IsOpen(33)
	elseif type == self.KFHD then
		return true
	elseif type == self.JZYL then
		return info:IsOpen(1018)
	elseif type == self.XTZL then
		return info:IsOpen(1032)
	elseif type == self.JRHD then
		return FestivalActMgr:IsOpen(FestivalActMgr.JRHD)
	elseif type == self.MRLC then
		return info:IsOpen(1006)
	elseif type == self.SC then
		return info:IsOpen(1004)
	elseif type == self.XSYG then
		return info:IsOpen(1020)
	elseif type == self.SMRZ then
		if Sdk then
			if App.platform == Platform.Android then
				local info = Sdk.realNameInfo
				return not info or (info.state == 3 and not IdentifyMgr.IsAuth)
			else
				return not IdentifyMgr.IsAuth
			end
		else
			return not IdentifyMgr.IsAuth
		end
	elseif type == self.TTT then
		return OpenMgr.IsOpenSystem[tostring(21)] ~= nil
	elseif type == self.XMSW then
		return FamilyActivityMgr.FmlDftState;
	elseif type == self.QYZD then
		return TopFightMgr.State
	elseif type == self.BPZ then
		local info = FamilyWarMgr.ActivityInfo
		return info and info.state
	elseif type == self.LT then
		if Sdk then
			if App.platform == Platform.Android then
				return Sdk:HasUC()
			else
				return false
			end
		else
			return false
		end
	elseif type == self.LYQG then
		if RushBuyDateInfo.RushBuyTime == nil then
			return false
		else
			return true
		end
	elseif type == self.ZK then
	-- if not CardAwardMgr.cardList then return end
	-- local cardList = CardAwardMgr.cardList
	-- if #cardList == 0 then
	-- 	return false
	-- else
	-- 	return true
	-- end
	elseif type == self.BossReward then
		return BossRewardMgr:IsOpen()
	-- elseif type == self.CJ then
	-- 	return (SuccessMgr.Info and SuccessMgr.Info.isOpen == true) or OpenMgr:IsOpenForId(temp.id) == true
	elseif type == self.YJJBSH then
		return ElvesNewMgr.State
	elseif type == self.Escort then
		return FamilyEscortMgr:IsOpen()
	elseif type == self.ZL then --是否开启战灵
		return OpenMgr:IsOpen(68)
	elseif type ==self.LB1 then --套装
		return OpenMgr:IsOpen(701)
	elseif type == self.Alchemy then
		local s1 = FestivalActMgr:GetActInfo(FestivalActMgr.BestAlchemy)
		local s2 = FestivalActMgr:GetActInfo(FestivalActMgr.AlchemyStore)
		return s1 ~= nil or s2 ~= nil
	elseif type==self.HSJB then --黑市鉴宝
		return NewActivMgr:ActivIsOpen(2003);
	elseif type==self.SSQ then --上上签
		return NewActivMgr:ActivIsOpen(2004)
	elseif type==self.ZADAN then --幸运砸蛋
		return NewActivMgr:ActivIsOpen(2002);
	elseif type==self.ZCM then --招财猫
		return NewActivMgr:ActivIsOpen(2001);
	elseif type==self.XYJB then --幸运鉴宝
		return NewActivMgr:ActivIsOpen(2005);
	elseif type==self.SCBS then --首充倍送
		return NewActivMgr:ActivIsOpen(2000);
	elseif type==self.JBHL then --绝版豪礼
		return NewActivMgr:ActivIsOpen(2006);
	elseif type==self.TTBT then --通天宝塔
		return NewActivMgr:ActivIsOpen(2009);
	elseif type==self.XLMJ then --修炼秘籍
		return NewActivMgr:ActivIsOpen(2010);
	elseif type==self.TS then --天书
		return OpenMgr:IsOpen(503)
	elseif type == self.HLBX then --欢乐宝箱
		return NewActivMgr:ActivIsOpen(2008)
	elseif type==self.TDQY then --天道情缘
		return NewActivMgr:ActivIsOpen(2012);
	elseif type==self.XSQG then --限时抢购（改为循环活动）
		return NewActivMgr:ActivIsOpen(2015);
	end

	if not temp.continued then
		return OpenMgr:IsOpenForId(temp.id)
	else
		if temp.lv > User.MapData.Level then
			return false
		end
		if OpenMgr:IsShowEffToActivity(temp.id) == true then
			return OpenMgr:IsOpenForId(temp.id)
		end
	end
	return true
end

function M:AddId(id)
	local temp = ActivityTemp[tostring(id)]
	if temp then 
		self:Add(temp, true) 
	end
end

function M:Add(temp, isInit, isLv)
	if not temp then return end
	local id = temp.id
	if id == self.CDGN then return end
	if not temp then return end
	if self:ShieldBtn(temp.id) then return end
	if isLv == nil then isLv = true end--是否受开放等级影响
	--if temp.layer ~= 7 and User.MapData and User.MapData.Level < temp.lv and isLv then return end
	if not isInit and OpenMgr:IsShowEffToActivity(id) == true then 
		return 
	end --是否播放系统开启动画
	if temp.layer ~= 0 and not self:CheckOpen(temp) and isLv  then return end
	local info = self.Info

	if temp.layer == self.CDGN then
		local t = ActivityTemp[tostring(temp.layer)]
		if t then
			local value = BinTool.FindProName(info[t.layer], t.id, "id")
			if not value then
				if not info[t.layer] then info[t.layer] = {} end
				table.insert(info[t.layer], t)
			end
		end
	end

	local layer = tostring(temp.layer)
	local index = temp.index
	if not info[layer] then info[layer] = {} end
	local value = BinTool.FindProName(info[layer], id, "id")
	if value then return end
	table.insert(info[layer], temp)
	table.sort(info[layer], function(a,b) return a.index < b.index end)
	if not isInit then self.eOpen(temp) end
end

function M:Remove(t)
	if not t then
		iTrace.eError("hs", "传入的系统等级数据不对")
		return
	end
	local info = self.Info
	local layer = nil
	local index = nil
	local temp = nil
	local type = t.type
	local id = t.id
	for k,v in pairs(info) do
		layer = k
		local len = #v
		for i=1, len do
			temp = v[i]
			if temp and temp.type == type and temp.id == id then
				index = i
				break
			end
		end
		if index then break end
	end
	if not temp then return end
	if temp.layer == self.CDGN then
		if #info[layer] == 0 then
		local parent = ActivityTemp[tostring(temp.layer)]
		if parent then
			local value, index = BinTool.FindProName(info[parent.laye], parent.id, "id")
				if value then
					table.remove(info[parent.layer], index)
				end
			end
		end
	end
	if layer and index then
		table.remove(info[layer], index)
		self.eClose(temp)
	end
end

function M:UpdateMenus(menu)
	if not menu then return end
	local list = self.Info[tostring(self.CDGN)]
	if not list then return end
	menu:Clear()
	for i=1, #list do
		local temp = list[i]
		local state = SystemMgr:GetActivity(temp.temp)
		menu:AddItem(temp.name, state)
	end
end

function M:CheckLv(type)
	local k,v = self:Find(type)
	if v then
		if v.lv <= User.MapData.Level then return true end
	end
	return false
end

function M:Find(type)
	for k,v in pairs(ActivityTemp) do
		if v.type == type then
			return k, v
		end
	end
	return nil, nil
end
--[[
--检查打开
function M:CheckOpen(id)
	local btnId = 0
	for k,v in pairs(ActivityTemp) do
		if v.type == id then
			btnId = v.id
			break
		end
	end
	local key = tostring(btnId)
	local cfg = ActivityTemp[key]
	if cfg == nil then return false end
	if cfg.lv > User.MapData.Level then
		return false
	end
	if OpenMgr:IsShowEffToActivity(btnId) == true then
		if not OpenMgr:IsOpenForId(btnId) then
			return false
		end
	end
	return true
end
]]--
--屏蔽按钮
function M:ShieldBtn(id)
	local index = 0
	if id == 129 then
		index = ShieldEnum.RechargeIcon
	elseif id == 128 then
		index = ShieldEnum.Market
	elseif id == 141 then
		index = ShieldEnum.VIPStore
	elseif id == 102 then
		index = ShieldEnum.Rank
	elseif id == 148 then
		index = ShieldEnum.V4
	elseif id == 108 then
		index = ShieldEnum.FirstPayIcon
	end
	return ShieldEntry.IsShield(index)
end

--获取开启状态
function M:OpenState(type)
	local k,v = self:Find(type)
	if v then
		if v.lv <= User.MapData.Level then
			return true, 0
		else
			return false, v.lv
		end
	end
	return false, 0
end

function M:Clear()
	TableTool.ClearDic(self.Info)
	self.IsClear = true
end

function M:Dispose()
	self:RemoveEvent()
end

return M