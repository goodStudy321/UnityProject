--region UIMainMenu.lua
--控制面板
--此文件由[HS]创建生成
local Ass = Loong.Game.AssetMgr.LoadPrefab
require("Tween/TweenDigtal")
require("UI/UIMainMenu/UIHeadView")
require("UI/UIMainMenu/UIActivityBtnsView")
require("UI/UIMainMenu/UIMiniMapView")
require("UI/UIMainMenu/UISystemView")
require("UI/UIMainMenu/UISceneDes")
require("UI/UIMainMenu/UIStrengthenList")
require("UI/UIMainMenu/UITalkView")
require("UI/UIMainMenu/UILeftView")
require("UI/UIMainMenu/UIBuffTips")
require("UI/UIMainMenu/UILowHpTip")
require("UI/UIMainMenu/UIMainmenuDl")
require("UI/UIMainMenu/UIJoyStick")
-- local ElvesBtn = require("UI/UIElvesBtn/UIElvesBtn")

local Obj = UnityEngine.Object
--local UpLvSound = 109
local base = UIBase

UIMainMenu = UIBase:New{Name = "UIMainMenu"}
local M = UIMainMenu
M.index = 0
M.eOpen = Event()
M.eClose=Event()
M.eHide=Event()
M.eUpdateFight = Event()
M.InitOpen = true

--注册的事件回调函数

function  M:InitCustom()
	self.Persitent = true;
	local name = "lua主界面"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local S = UITool.SetLsnrSelf
	local US = UITool.SetBtnSelf
	--[[
	self.HideRoot = T(trans, "HideRoot")
	if ScreenMgr.orient==ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.HideRoot, nil, nil, false, true)
	end
	]]--
	--后台下载进度
    local dlGo = T(trans,"LeftView/DownLoad")
	self.dl = UIMainmenuDl:Init(dlGo)
	--self.HideBtn = C(UIToggle, trans, "HideRoot/Btn", name, false)

	self.PlayTween = self.gbj:GetComponent("UIPlayTween")
	--HeadView
	self.HeadView = UIHeadView:New(T(trans, "HeadView"))
	--uiToggleView
	--System
	self.SystemView = UISystemView:New(T(trans, "System"))
	--AcivityView
	self.AcivityView = UIActivityBtnsView:New(self, T(trans, "ActivityView"))
	--左边任务队伍窗
	self.LeftView = UILeftView:New(T(trans, "LeftView"))
	--buffcell列表
	self.BuffList = UIBuff:New(T(trans, "BuffList"))
	--buff列表
	self.BuffTips = UIBuffTips:New(T(trans, "BuffTips"))
	--技能
	self.SkillView = UISkill:New(self, T(trans, "SkillView"))
	--MiniMap
	self.MiniMapView = UIMiniMapView:New(T(trans, "MiniMapView"))
	self.MapSystemBtn = ComTool.Get(UIButton, trans, "MiniMapView", name, false)
	--打宝提示
	self.FightTreasureBtn = T(trans, "FightTreasureBtn")
	self.FightTreasureAction = T(trans, "FightTreasureBtn/Action")
	--Right
	--Bottom
	self.AutoToggle = C(UIToggle, trans, "LeftCenter/MoveRoot/AutoToggle", name, false)
	self.AutoLbl = C(UILabel,trans,"LeftCenter/MoveRoot/AutoToggle/lbl",name)
	self.AutoToggle.value = false
	self.AutoEff=T(trans,"LeftCenter/MoveRoot/AutoToggle/Checkmark/Icon/AutoEff",name).gameObject
	self.AutoEff:SetActive(false)
	self.AutoBg = C(UISprite, trans, "LeftCenter/MoveRoot/AutoToggle/Background", name, false)
	--self.AutoFont = C(UISprite, trans, "LeftCenter/MoveRoot/AutoToggle/Background/Sprite", name, false)
	--self.AutoIcon = C(UISprite, trans, "LeftCenter/MoveRoot/AutoToggle/Icon", name, false)
	self.RotaToggle = C(UIToggle, trans, "RotaToggle", name, false)
	self.RotaToggle.value = User.IsLockCameraRota
	--self.RotaToggle.gameObject:SetActive(true)
	--exp
	self.ExpSlider = C(UISlider, trans, "ExpSlider/Slider", name, false)
	self.ExpValueLab = C(UILabel, trans, "ExpSlider/ExpValueLab", name, false)
	--self.ExpEffect1 = T(trans, "ExpSlider/Slider/UI_Level_Exp1")
	self.Particle = C(ParticleSystemMgr, trans, "ExpSlider/Slider/Thumb/UI_Level_Exp2", name, false)
	--JoyStivk
	self.JoyStick = UIJoyStick:New(T(trans, "virtualbox"))
	--VIP or 返利
	self.vipGbj = T(trans,"VIPBtn")
	self.vipAction = T(trans, "VIPBtn/Action")
	self.tipSpr = T(trans, "VIPBtn/tipSpr")
	self.tipLab = C(UILabel, trans, "VIPBtn/tipSpr/lab", name, false)
	self.vipLab = C(UILabel, trans, "VIPBtn/Label", name, false)

	self.DailyBtn = T(trans, "DailyBtn")
	self.DailyBtn:SetActive(false)

	--绝版守护 or 新版精灵
	----------start---------
	-- local elvesGbj = T(trans,"ElvesBtn")
	-- self.elvesBtnClass = ObjPool.Get(ElvesBtn)
	-- self.elvesBtnClass:Init(elvesGbj)
	-----------end----------

	--gm面板打开
	if  GMManager.instance.IsGm==true or App.IsDebug==true  then
		self.gmbtn=C(UIButton,trans,"gmbtn",name)
		self.gmbtn.gameObject:SetActive(true)
		US(self.gmbtn,self.openGM,self)
	end
	--聊天
	self.UITalkView=ObjPool.Get(UITalkView)
	self.UITalkView:Init(T(trans, "BottomView/MoveRoot/TalkView"))
	self.TalkRoot = T(trans, "BottomView/MoveRoot/TalkView/Sprite")

	self.BagBtn = C(UIButton, trans, "BottomView/MoveRoot/BagBtn/Btn", name, false)
	self.BagBtnRed = T(trans,"BottomView/MoveRoot/BagBtn/Btn/red")
	self:ShowBagRed()

	self.BVPlayTween = C(UIPlayTween, trans,"BottomView", name, false)
	self.BVTweenPos = C(TweenPosition, trans,"BottomView/MoveRoot", name, false)

	--低血量提示
	local lowHpTip = T(trans,"LowHpTip")
	UILowHpTip:Init(lowHpTip)

	--挂机
	--self.AutoPathfindingSprite = C(UISprite, trans, "AutoPathfinding", name, false);

	--好友
	UITool.SetBtnClick(trans,"BottomView/MoveRoot/friend",name,self.OpenFriend,self)

	self.SceneDesView = ObjPool.Get(UISceneDes)
	self.SceneDesView:Init(T(trans, "SceneDesView"))

	self.IsZDGJ = T(trans, "FX_hand_up")
	self.IsZDXL = T(trans, "FX_find_way")

	self.EscortIcon = T(trans, "Escort")

	--self.CurLv = User.MapData.Level

	local EH = EventHandler
	self.OnChangeName = EH(self.UpdateName,self);
	self.OnChangeHP = EH(self.UpdateHp, self)
	self.OnEquipFight = EH(self.UpdateFight, self)
	self.OnChangeExp = EH(self.UpdateExp, self)
	--self.OnUpdateBaseProperty = EH(self.UpdateBaseProperty, self)
	self.OnAutoFight = EH(self.SetAutoFighting, self)
	self.OnAutoPathFind = EH(self.SetAutoPathFinding, self)
	self.OnUIMainmenuLeftSetActive = EH(self.UIMainmenuLeftSetActive, self)
	self.OnUIMainmenuBottomSetActive = EH(self.UIMainmenuBottomSetActive, self)
	--self.OnIsShowUIDialog = EH(self.IsShowUIDialog, self)
	self.OnStartPlayFlyFont = function() self:StartPlayFlyFont() end

	--等级限购

	--仙盟聊天
	self.FamilyChatBtn=T(trans,"BottomView/MoveRoot/FamilyChatBtn")
	local fc = self.FamilyChatBtn.transform
	S(fc, self.OpenFamilyChat, self,self.Name);
	self.FamilyChatRed=T(fc,"red")
	self:FamilyChatState()
	-- self.FamilyChatBtn:SetActive(true);

	--坐骑引导
	local mountgd = T(trans,"FX_qcts");
	MountGuide:InitGo(mountgd);


	self:AddEvent()
	self:UpdateData()

	--LvLimitBuyMgr:InitItem(LvLimitBuyMgr.dataList)

	FeedbackMgr:SendStatus()
	
	self.LeftCenter = C(UIWidget, trans, "LeftCenter", name, false)
	self.LCOriLeft = self.LeftCenter.leftAnchor.absolute
	self.LCOriRight = self.LeftCenter.rightAnchor.absolute
	self.LCPlayTween = C(UIPlayTween, trans, "LeftCenter", name, false)
	self.LCTweenPos = C(TweenPosition, trans, "LeftCenter/MoveRoot", name, false)
		
	self.StrengthenListView = UIStrengthenList:New(trans)
--[[
	self.hrWidget = C(UIWidget,trans, "HideRoot",name)
	self.hrOriLeft = self.hrWidget.leftAnchor.absolute
	self.hrOriRight = self.hrWidget.rightAnchor.absolute

	self.atWidget = C(UIWidget,trans, "AutoToggle",name)
	self.atOriLeft = self.atWidget.leftAnchor.absolute
	self.atOriRight = self.atWidget.rightAnchor.absolute
]]--
	self:ScreenChange(ScreenMgr.orient, true)
	ShieldEntry.ShieldGbj(ShieldEnum.VIPIcon,self.vipGbj);
end

function  M:AddEvent()
	local M = EventMgr.Add
	local E = UITool.SetLsnrSelf
	M("OnChangeName",self.OnChangeName)
	M("OnChangeHP", self.OnChangeHP)
	M("OnChangeExp", self.OnChangeExp)
	M("OnAutoFight", self.OnAutoFight)
	M("OnAutoPathFind", self.OnAutoPathFind)
	M("UIMainmenuLeftSetActive", self.OnUIMainmenuLeftSetActive)
	M("UIMainmenuBottomSetActive", self.OnUIMainmenuBottomSetActive)
	FightVal.eChgFv:Add(self.UpdateFightValue, self);
	--M("IsShowUIDialog", self.OnIsShowUIDialog)
	--控件事件
	--[[
	if self.HideBtn then
		E(self.HideBtn, self.ClickHideBtn, self)
	end
	]]--
	if self.BagBtn then
		E(self.BagBtn, self.ClickBagBtn, self)
	end
	if self.AutoToggle then
		E(self.AutoToggle, self.ClickAutoToggle, self)
	end
	if self.RotaToggle then
		E(self.RotaToggle, self.ClickRotaToggle, self)
	end
	--// 链接地图按钮
	if self.MapSystemBtn ~= nil then
		E(self.MapSystemBtn, self.ClickOpenMapSys, self, nil, false)
		--E(self.MapSystemBtn.gameObject).onClick = function (gameObject) self:ClickOpenMapSys(gameObject) end
	end
	--打宝提示
	if self.FightTreasureBtn then
		E(self.FightTreasureBtn, self.ClickFightTreasureBtn, self, nil, false)
	end
	--弹出聊天窗口
	if self.TalkRoot then
		E(self.TalkRoot, self.ClickTalk, self, nil, false)
	end

	if self.EscortIcon then
		E(self.EscortIcon, self.ClickEscortIcon, self)
	end
	if self.LeftView then
		self.LeftView:AddEvent()
	end
	--VIP界面
	UITool.SetLsnrClick(self.root,"VIPBtn",self.Name,self.VIPCb,self)

	self:SetEvent("Add")
end

function  M:RemoveEvent()
	local M = EventMgr.Remove
	M("OnChangeHP", self.OnChangeHP)
	M("OnChangeExp", self.OnChangeExp)
	M("OnAutoFight", self.OnAutoFight)
	M("OnAutoPathFind", self.OnAutoPathFind)
	M("UIMainmenuLeftSetActive", self.OnUIMainmenuLeftSetActive)
	M("UIMainmenuBottomSetActive", self.OnUIMainmenuBottomSetActive)
	FightVal.eChgFv:Remove(self.UpdateFightValue, self);
	--M("IsShowUIDialog", self.OnIsShowUIDialog)
	if self.LeftView then
		self.LeftView:RemoveEvent()
	end
	self:SetEvent("Remove")
end
--打开gm面板
function M:openGM(  )
	UIMgr.Open(UIGM.Name)
end
function  M:SetEvent(fn)
	SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.ChangeSceneEnd, self)
	EscortMgr.eInit[fn](EscortMgr.eInit, self.EscortInit, self)
	EscortMgr.eReceive[fn](EscortMgr.eReceive, self.EscortReceive, self)
	EscortMgr.eComplete[fn](EscortMgr.eComplete, self.EscortComplete, self)
	SystemMgr.eShowActivity[fn](SystemMgr.eShowActivity, self.ShowActivity, self)
	SystemMgr.eHideActivity[fn](SystemMgr.eHideActivity, self.HideActivity, self)
	SystemMgr.eShowSystem[fn](SystemMgr.eShowSystem, self.UpdateSystemAction, self)
	SystemMgr.eHideSystem[fn](SystemMgr.eHideSystem, self.UpdateSystemAction, self)
	VIPMgr.eUpInfo[fn](VIPMgr.eUpInfo, self.UpVIPLv, self)
	Hangup.eUpdateAutoStatus[fn](Hangup.eUpdateAutoStatus, self.UpdateAutoStatus , self)
	
	ScreenMgr.eChange[fn](ScreenMgr.eChange, self.ScreenChange, self)

	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.UpdateLevel ,self)
	RoleAssets.eUpAsset[fn](RoleAssets.eUpAsset, self.PropChg, self);
	OpenMgr.eOpen[fn](OpenMgr.eOpen, self.FamilyChatState, self);
	ChatMgr.eAddChat[fn](ChatMgr.eAddChat, self.OnNewFamilyChat, self);
	UIChat.eOpen[fn](UIChat.eOpen, self.OnHideFamilyChat, self);

	FightTreasureMgr.eChangeStatus[fn](FightTreasureMgr.eChangeStatus, self.UpdateFightTreasureStatus, self)
	EquipCollectionMgr.eRed[fn](EquipCollectionMgr.eRed,self.ShowBagRed,self)
end

function M:BuyLoveCb()
	--todo
	UIMarry:OpenTab(2)
	-- iTrace.Error("XGY","跳转仙侣副本界面")
end

function M:ScreenChange(orient, init)
	local reset = UITool.IsResetOrient(orient)
	rReset = not reset
	UITool.SetLiuHaiAbsolute(self.LeftCenter, true, rReset, self.LCOriLeft,self.LCOriRight, -1)
	--UITool.SetLiuHaiAbsolute(self.hrWidget, true, rReset, self.hrOriLeft,self.hrOriRight, -1)
	--UITool.SetLiuHaiAbsolute(self.atWidget, true, rReset, self.atOriLeft,self.atOriRight, -1)
	if self.SkillView then
		self.SkillView:ScrChg(orient, init)
	end
	if self.LeftView then
		self.LeftView:ScreenChange(orient, init)
	end
	if self.AcivityView then
		self.AcivityView:ScreenChange(orient, init)
	end
	if self.SystemView then
		self.SystemView:ScreenChange(orient, init)
	end
	--[[
	if self.StrengthenListView then
		self.StrengthenListView:ScreenChange(orient, init)
	end
	]]--
end

--仙盟聊天
function M:FamilyChatState()
	local isopen = OpenMgr:IsOpen(31) or false
	self.FamilyChatBtn:SetActive(isopen)
	self:UpdateFightTreasureBtnStatus()
end

function M:OnNewFamilyChat(cTp,maxIndex,chatTb)
	if cTp~=2 then return end
	if UIChat.cTp==2 then return end
	-- self.FamilyChatRed:SetActive(true)
end

function M:OnHideFamilyChat(cTp)
	if cTp~=2 then return end
	-- self.FamilyChatRed:SetActive(false)
end

function M:UpdateFightTreasureStatus()
	self:UpdateFightTreasureBtnStatus()
	local btn = self.FightTreasureBtn
	if btn then
		btn:SetActive(FightTreasureMgr:IsShowIcon() == true and FightTreasureMgr.ReceiveStatus == true)
	end
end

function M:OpenFamilyChat()
	-- self.FamilyChatRed:SetActive(false)
	local isjoin = FamilyMgr:JoinFamily()
	if isjoin==false then 
		local msg = "您还没有加入道庭，是否加入道庭？"
		MsgBox.ShowYesNo(msg,self.JumpFamily)
	else
		--/// LY edit begin ///
		--ChatMgr.OpenChat(2)
		FamilyMgr:OpenFamilyWndTag(1, nil);
		--/// LY edit end ///
	end
end

function M:JumpFamily()
	UIMgr.Open(UIFamilyListWnd.Name)
end

--
function  M:ChangeSceneEnd()
	if self.HeadView then
		self.HeadView:UpdateHead()
	end
	local value = SceneMgr:IsSpecial()
	--[[
	if self.HideRoot then
		self.HideRoot:SetActive(value == true)
	end
	]]--
	local activityView = self.AcivityView
	if activityView then
		activityView:UpdateTween()
	end
	--[[
	if self.MiniMapView then
		self.MiniMapView:UpdateData()
		self.MiniMapView:SetActive(not value)
	end
	if self.AcivityView then
		if User.SceneId == 30008 then
			self.AcivityView:SetActive(false)
		else
			self.AcivityView:SetActive(not value)
		end
	end
	]]--
	if self.SceneDesView then
		self.SceneDesView:UpdateDes()
	end
	if self.BuffTips then
		self.BuffTips:RestBuffsIcon()
	end

	local leftView = self.LeftView
	if leftView then
		leftView.IsOpen = true
	end
end

function  M:EscortInit()
	self:SetEscortIcon(EscortMgr:IsExecute())
	if self.LeftView then
		self.LeftView:UpdateMissionEnd()
	end
end

function  M:EscortReceive()
	self:SetEscortIcon(true)
	if self.LeftView then
		self.LeftView:UpdateMissionEnd()
	end
end

function  M:EscortComplete()
	self:SetEscortIcon(false)
	if self.LeftView then
		self.LeftView:UpdateMissionEnd()
	end
end

function M:ShowActivity(type)
	self:UpdateActivityAction(type, true)
	--// LY add begin
	if type == ActivityMgr.DT then
		self.FamilyChatRed:SetActive(true)
	end
	--// LY add end
end

function M:HideActivity(id)
	self:UpdateActivityAction(id, false)
	--// LY add begin
	if id == ActivityMgr.DT then
		if FamilyMgr:FamilyNeedShowRedP() == false then
			self.FamilyChatRed:SetActive(false);
		end
	end
	--// LY add end
end

function M:UpdateSystemAction(id)
	if self.HeadView then
		self.HeadView:UpdateAction()
	end
end

function  M:SetEscortIcon(value)
	if self.EscortIcon then
		self.EscortIcon:SetActive(value)
	end
end

function M:UpdateActivityAction(id, isAdd)
	if self.AcivityView then
		self.AcivityView:UpdateAction(id, isAdd)
	end
end

--更新好友小图标
function  M:RequestUpdateUI()
	if self.SystemView then
		self.SystemView:RequestUpdateUI()
	end
end

function  M:UpdateData()
	if self.HeadView then self.HeadView:UpdateData() end
	self:UpdateExp()
	self:UpdateFightTreasureBtnStatus()
	self:UpdateLevel()
end

--[[   EventMgr   Begin   ]]--

function  M:UpdateName(name)
	if self.HeadView then self.HeadView:UpdateName() end
end

--更新生命值
function  M:UpdateHp(uid,curHp)
	if self.HeadView then self.HeadView:UpdateHP() end
	UILowHpTip:SetTip();
end

--更新等级
function  M:UpdateLevel()
	local data= User.instance.MapData
	if self.HeadView then self.HeadView:UpdateLevel() end
	--[[
	if self.CurLv <data.Level then
		if self.CurLv and self.CurLv > 0 then
			Ass("UI_HeroLevelUp_Text", GbjHandler(self.LoadEff,self))
		end
		self.CurLv = data.Level
	end
	]]--
	self:UpdateFightTreasureStatus()

	self:UpDailyBtn()
end

function M:UpDailyBtn()
	if User.instance.MapData.Level>=100 and self.isDaily~=true then
		self.DailyBtn:SetActive(true)
		self.isDaily=true
		UITool.SetBtnSelf(self.DailyBtn,self.OnDailyBtn,self,self.Name,false)
	end
end

function M:OnDailyBtn()
	UIMgr.Open(UIEvrDayPay.Name)
end

--更新货币
function M:PropChg(ty)
	local view = self.HeadView
	if not view then return end
	view:UpdateCurrency(ty)
end
--[[
function  M:LoadEff(go)
	go.transform.parent = self.root
	go.transform.localPosition = Vector3.up * 180
	go.transform.localEulerAngles = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	
	Audio:PlayByID(UpLvSound, 1)
end
]]--
--更新经验
function  M:UpdateExp()
	self.ExpSlider.value = User.MapData.ExpRatio
	self.ExpValueLab.text = tostring(User.MapData.Exp).."/"..tostring(User.MapData.LimitExp)
	--local pos = Vector3.right * (1334 * User.MapData.ExpRatio + 4.5)
	--self.ExpEffect1.transform.localPosition = pos
	--self.Particle:SetPos(pos)
	self.Particle:Simulate()
	--self:UpdateLevel()
end

--更新战斗力
function  M:UpdateFightValue()
	if self.HeadView then
		self.HeadView:UpdateFightValue()
	end
end

--设置VIP红点
function M:SetRedDot(state)
	if state==false and VIPMgr.GetVIPLv()==0 and TableTool.GetDicCount(VIPMgr.firstBuy)~=0 then
		state=true
	end
	if self.vipAction then
		self.vipAction:SetActive(state)
	end
end

--更新VIP体验提示
function M:UpVIPTip(state, str)
	if not self.tipSpr then return end
	self.tipSpr:SetActive(state)
	self.tipLab.text = str
end

--更新VIP等级
function M:UpVIPLv()
	local vip = VIPMgr.GetVIPLv()
	local text = "VIP"..vip
	local renew = false
	if VIPMgr.GetVIPLv()==0 and TableTool.GetDicCount(VIPMgr.firstBuy)~=0 then 
		renew=true 
		text="续费"
	elseif vip>0 and vip<4 and #PropMgr.GetItemsByUseEff(91)>0 then
		renew=true
	end
	self.vipLab.text = text
	self:SetRedDot(renew)

end


--[[   EventMgr   End   ]]--

--[[  Click Event  Begin ]]--
--[[
function  M:ClickHideBtn(go)
	local value = self.HideBtn.value
	if self.MiniMapView then
		self.MiniMapView:SetActive(not value)
	end
	if self.AcivityView then
		self.AcivityView:SetActive(not value)
	end
	M.eHide(value)
end
]]--

--隐藏左边的任务
function M:HideLeftView()
	self.LeftView.GO:SetActive(false)
	self.AcivityView.gameObject:SetActive(false)
	self.MiniMapView.gameObject:SetActive(false)
	--self.HideRoot:SetActive(true)
end

--点击打开背包
function  M:ClickBagBtn(gameObject)
	UIRole:SelectOpen(4)
end

function M:ShowBagRed()
	self.BagBtnRed:SetActive(EquipCollectionMgr.collRed)
end

--挂机按钮
function  M:ClickAutoToggle(gameObject)
	if self.AutoToggle.value then
		--self.AutoLbl.text = "取消挂机"
		self.AutoEff:SetActive(true)
		--[[
		self.AutoBg.spriteName = "zj_04"
		self.AutoIcon.spriteName = "guaji-on"
		]]--
	else
		--self.AutoLbl.text = "自动挂机"
		self.AutoEff:SetActive(false)
		--[[
		self.AutoBg.spriteName = "zj_03"
		self.AutoIcon.spriteName = "guaji-off"
		]]--
	end
	self.AutoBg:MakePixelPerfect()
	--self.AutoIcon:MakePixelPerfect()
	--self.AutoFont:MakePixelPerfect()
	if self.LeftView then self.LeftView:UpdateAutoHangup(self.AutoToggle.value) end
	self.eUpdateFight(self.AutoToggle.value)
	local isHgp = Hangup:GetAutoHangup();
	local isStf = Hangup:GetSituFight();
	if isHgp == true or isStf == true then
		Hangup:ClearAutoInfo();
		self:SetAutoFight(false);
		User:StopNavPath();
		return;
	end
	Hangup:SetSituFight(true);
	self:SetAutoFight(true);
	
	if Hangup:IsPause() == true then	
		Hangup:Resume(OpenMgr.FlyIconPause)
		MissionMgr:Execute(false)
	end
end

function  M:ClickRotaToggle(go)
	if not self.RotaToggle then return end
	User.IsLockCameraRota = self.RotaToggle.value
end

function  M:ClickTalk(go)
	UIMgr.Open(UIChat.Name, self.ChatCb,self)
end

function  M:ClickEscortIcon(go)
	MissionMgr:AutoExecuteActionOfType(MissionType.Escort)
end

function M:UpdateBottomStatus(value)
	local delay = 0
	if value == false then
		delay = 0.2
	end
	local tweenPos = self.BVTweenPos
	local playTween = self.BVPlayTween
	if tweenPos then
		tweenPos.delay = delay
	end
	if playTween then
		playTween:Play(value)
	end
	local lcTweenPos = self.LCTweenPos
	local lcPlayTween = self.LCPlayTween
	if lcTweenPos then
		lcTweenPos.delay = delay
	end
	-- if lcPlayTween then
	-- 	lcPlayTween:Play(value)
	-- end
	local jsView = self.JoyStick
	if jsView then
		jsView:UpdateJoyStickStatus(value)
	end
	local skillView = self.SkillView
	if skillView then
		skillView:UpdateSkillViewStatus(value)
	end
end

function M:OpenFriend()
	UIMgr.Open(UIInteractPanel.Name, self.OpenFriendUISucc, self)
end

function M:OpenFriendUISucc(name)
	local ui = UIMgr.Dic[name]
	if not ui then return end
	ui:ShowFirend()
end

function  M:VIPCb()
	local vip = VIPMgr.GetVIPLv()
	if vip == 0 or VIPMgr.isExpire==true then
		UIMgr.Open(UIV4Panel.Name)
		return
	end
	VIPMgr.OpenVIP()
end

function M:InvestCb()
	VIPMgr.OpenVIP(3)
end

function  M:ChatCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		if User.SceneId == 30007 then
			ui:SwatchTg(2)
		else
			ui:SwatchTg(0)
		end
		ui:SetTween(true)
	end
end

--设置自动挂机
function  M:SetAutoFighting(bool)
	self.AutoToggle.value = bool;
	self:SetAutoFight(bool);
end

function  M:SetAutoFight(bool)
	if self.IsZDGJ then
		self.IsZDGJ:SetActive(bool)
	end
	if self.IsZDXL then
		self.IsZDXL:SetActive(false)
	end
end

--设置自动寻路
function  M:SetAutoPathFinding(bool)
 	if self.IsZDXL then
		self.IsZDXL:SetActive(bool)
	end
	local isHgp = Hangup:GetAutoHangup();
	local isStf = Hangup:GetSituFight();
	if self.IsZDGJ then
		local result = false;
		if bool == false then
			if isHgp or isStf then
				result = true;
			end
		end
		if self.IsZDGJ.activeSelf ~= result then
			self.IsZDGJ:SetActive(result)
		end
	end
	if isHgp == true or isStf == true then
		self.AutoToggle.value = true;
	end
	if self.AutoToggle.value then
		--self.AutoLbl.text = "取消挂机"
		self.AutoEff:SetActive(true)
		--[[
		self.AutoBg.spriteName = "zj_04"
		self.AutoIcon.spriteName = "guaji-on"
		self.AutoFont.spriteName = "zj_gj_font_02"
		]]--
	else
		--self.AutoLbl.text = "自动挂机"
	end
	self.AutoBg:MakePixelPerfect()
	--[[
	self.AutoIcon:MakePixelPerfect()
	self.AutoFont:MakePixelPerfect()
	]]--
	if self.LeftView then self.LeftView:UpdateAutoHangup(self.AutoToggle.value) end
end

function M:UIMainmenuLeftSetActive(status)
	local view = self.LeftView
	if view  then
		local value = true
		if status == 0 then value = false end
		view.IsOpen = value
		view:SetActive(value)
	end
end

function M:UIMainmenuBottomSetActive(status)
	local view = self.AcivityView
	if view then
		view.IsBottomStatus = status
		view:ClickSBtn()
	end
end

--更新状态
function M:UpdateAutoStatus()
	local isHgp = Hangup:GetAutoHangup();
	local isStf = Hangup:GetSituFight();
	if isHgp == false and isStf == false then
		self.AutoToggle.value = false;
		--self.AutoLbl.text = "自动挂机"
		self.AutoEff:SetActive(false)
		--[[
		self.AutoBg.spriteName = "zj_03"
		self.AutoIcon.spriteName = "guaji-off"
		self.AutoFont.spriteName = "zj_gj_font"
		]]--
	end
	self.AutoBg:MakePixelPerfect()
	--[[
	self.AutoIcon:MakePixelPerfect()
	self.AutoFont:MakePixelPerfect()
	]]--
end

function M:UpdateFightTreasureBtnStatus()
	local action = self.FightTreasureAction
	if not action then return end
	local isOpen = OpenMgr:IsOpenForType(ActivityMgr.BOSS)
	local status = FightTreasureMgr.ReceiveStatus
	action:SetActive(isOpen == true and status == true)
end

function M:ClickFightTreasureBtn(go)
	UIMgr.Open(UIFightTreasure.Name)
end

--// 点击打开地图系统
function  M:ClickOpenMapSys(gameObject)
	local sId = User.SceneId;
	if sId == nil or sId <= 0 then
		UITip.Log("没有小地图");
		return;
	end

	local sceneInfo = SceneTemp[tostring(sId)];
	if sceneInfo == nil or sceneInfo.maptex == nil or sceneInfo.maptex == "" then
		UITip.Log("当前场景无法使用小地图");
		return;
	end

	iTrace.eLog("LY", "Open map system !!! ");
	UIMgr.Open("UIMapWnd");
end

function M:OpenEquip(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:SwatchTg(1)
	end
end

function M:SetBuffTips()
	if self.BuffTips then
		self.BuffTips:UpdateActive()
	end
end

function  M:OpenCustom()
	if not self.InitOpen then self.InitOpen = false end
	UIMgr.Open(UIFlyPro.Name)
	UIMgr.Open(UIFlyExp.Name)
	UIMgr.Open(FightTip.Name)
	self:UpdateData()
	self:SetEscortIcon(EscortMgr:IsExecute())
	if self.AcivityView then
		self.AcivityView:Open()
	end
	if self.MiniMapView then
		self.MiniMapView:Open()
	end
	if self.StrengthenListView then
		self.StrengthenListView:Open()
	end
	if self.LeftView then
		self.LeftView:Open()
	end
	if self.SkillView then
		self.SkillView:Open()
	end
	if self.BuffList then
		self.BuffList:Open()
	end
	if self.BuffTips then
		self.BuffTips:Open()
	end
	self:UpdateSystemAction()
	self:UpdateFightTreasureStatus()
	if self.LeftView and self.AutoToggle then self.LeftView:UpdateAutoHangup(self.AutoToggle.value) end
	M.eOpen()
end

function  M:HideView()
	local isShow = true
	if GameSceneManager.CurSceneType == SceneType.Copy then
		isShow = false
	end
	if self.SystemView then
		self.SystemView.gameObject:SetActive(isShow)
	end
	if self.BagBtn then
		self.BagBtn.gameObject:SetActive(isShow)
	end
end

function  M:CloseCustom()
	--iTrace.sLog("hs","测试：主界面关闭")
	--self.TipFighting:SetActive(false)
	if self.AcivityView then
		self.AcivityView:Close()
	end
	if self.MiniMapView then
		self.MiniMapView:Close()
	end
	if self.StrengthenListView then
		self.StrengthenListView:Close()
	end
	if self.LeftView then
		self.LeftView:Close()
	end
	if self.SkillView then
		self.SkillView:Close()
	end
	if self.BuffTips then
		self.BuffTips:Close()
	end
	 M.eClose()

end

--重置摇杆
function  M:ResetJoystick()
	local jsView = self.JoyStick
	if jsView then
		jsView:Reset()
	end
end

function  M:DisposeCustom()
	StopCoroutine(self.OnStartPlayFlyFont)
	self:RemoveEvent()
	self:CloseCustom()
	if self.HeadView then
		self.HeadView:Dispose()
	end
	if self.SystemView then
		self.SystemView:Dispose()
	end
	if self.AcivityView then
		self.AcivityView:Dispose()
	end
	if self.MiniMapView then
		self.MiniMapView:Dispose()
	end
	if self.SceneDesView then
		ObjPool.Add(selfself.SceneDesView)
		self.SceneDesView = nil
	end
	if self.StrengthenListView then
		self.StrengthenListView:Dispose()
	end
	if self.LeftView then
		self.LeftView:Dispose()
	end
	if self.SkillView then
		self.SkillView:Dispose()
	end

	if self.UITalkView then
		self.UITalkView:Dispose()
	end

	-- if self.elvesBtnClass then
	-- 	self.elvesBtnClass:Dispose()
	-- 	ObjPool.Add(self.elvesBtnClass)
	-- 	self.elvesBtnClass = nil
	-- end

	TableTool.ClearUserData(self)
end

function  M:Clear(isReconnect)
	if self.HeadView then
		self.HeadView:Clear()
	end
	if self.AcivityView then
		self.AcivityView:Clear(isReconnect)
	end
	if self.SystemView then
		self.SystemView:Clear()
	end
	
	if self.SceneDesView then
		self.SceneDesView:Clear(isReconnect)
	end
	if self.StrengthenListView then
		self.StrengthenListView:Clear()
	end
	if self.SkillView then
		self.SkillView:Clear()
	end
	if self.LeftView then self.LeftView:Clear() end
	if self.UITalkView then
		self.UITalkView:Dispose()
	end
	if self.BuffTips then
		self.BuffTips:Clear()
	end
end

function  M:Update()
	if self.AcivityView then self.AcivityView:Update() end
	if self.MiniMapView then
		self.MiniMapView:Update()
	end
	if self.LeftView then self.LeftView:Update() end

	local jsView = self.JoyStick
	if jsView then
		jsView:Update()
	end
end

return  M

--endregion
