--region UIMainMenuLeft.lua
--Date 主界面右边面板 任务和队伍小窗口
--此文件由[HS]创建生成
require("UI/UIMission/UIMissionView")
require("UI/UIMission/UIMissionItem")
require("UI/UIMainMenu/UITeamSmallView")

UILeftView = {}
local M = UILeftView
local tMgr = TeamMgr
local mMgr = MissionMgr
local sMgr = SceneMgr
local cMgr = ChapterMgr
local MissSound = 110


function M:New(go)
	local name = "主界面右边面板，任务和队伍小窗口"
	self.GO = go
	self.anchor = ComTool.GetSelf(UIWidget, go, des)
	self.oriLeft = self.anchor.leftAnchor.absolute
	self.oriRight = self.anchor.rightAnchor.absolute
	local trans = go.transform
	local C = ComTool.Get
	-- local CS = ComTool.GetSelf
	local T = TransTool.FindChild
	self.MissionToggle = C(UIToggle, trans, "Btn/Mission", name, false)
	self.TeamToggle = C(UIToggle, trans, "Btn/Team", name, false)
	self.box = C(BoxCollider, trans, "Btn/Team/box", name, false)
	self.box.enabled = false
	self.MissionView = UIMissionView:New(T(trans, "Mission"))
	self.UITeamSmallView=ObjPool.Get(UITeamSmallView)
	self.utsvTeam = self.UITeamSmallView:New1(T(trans, "Team"))
	self.TeamView = self.utsvTeam
	self.Line = T(trans, "Line")
	self.EffectRoot = T(trans, "EffectRoot")
	self.AcceptEff = T(trans, "EffectRoot/Panel/UI_Task_Accept")
	self.FinishEff = T(trans, "EffectRoot/Panel/UI_Task_Finish")
	self.CurToggle = nil
	self.IsOpen = true
	return self
end

function M:AddEvent()
	self:UpdateEvent(EventMgr.Add)
	local E = UITool.SetLsnrSelf
	if self.MissionToggle then
		E(self.MissionToggle, self.OnToggleChange, self)
	end
	if self.TeamToggle then
		E(self.TeamToggle, self.OnToggleChange, self)
	end
	--用来判读是否可以切换到队伍标签
	if self.box then
		-- E(self.box, self.OnBoxClick, self)
	end
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	tMgr.eUpdateTempData[fn](tMgr.eUpdateTempData, self.UpdateTeamInfo, self)
	tMgr.eUpdateCaptID[fn](tMgr.eUpdateCaptID, self.UpdateTeamInfo, self)

	mMgr.eEndUpdateMission[fn](mMgr.eEndUpdateMission, self.UpdateMissionEnd, self)
	mMgr.eCleanMission[fn](mMgr.eCleanMission, self.CleanMissionUI, self)
	mMgr.eCleanAllMission[fn](mMgr.eCleanAllMission, self.CleanAllMissionUI, self)
	mMgr.ePlayMissionEffect[fn](mMgr.ePlayMissionEffect, self.PlayMissionEffect, self)
	sMgr.eChangeEndEvent[fn](sMgr.eChangeEndEvent, self.ChangeEndEvent, self)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.OnLvEvent, self)
	cMgr.InitChapter[fn](cMgr.InitChapter, self.UpdateChapter, self)
	cMgr.UpdateChapter[fn](cMgr.UpdateChapter, self.UpdateChapter, self)
end

function M:UpdateEvent(M)
	local EH = EventHandler
	M("OnChangeScene", EH(self.UpdateTeamData, self))
	M("OnChangeLevel", EH(self.UpdateLv, self))
	M("OnChangeExp",  EH(self.UpdateExp, self))
end


--==============================--

function M:UpdateMissionEnd()
	if self.MissionView then
		self.MissionView:UpdateMission()
	end
	self:UpdateChapter()
	self:OnUpdateToggleChagen()
end

function M:CleanMissionUI(id)
	if self.MissionView then
		self.MissionView:CleanMission(id)
	end
	self:OnUpdateToggleChagen()
end

function M:CleanAllMissionUI()
	if self.MissionView then
		self.MissionView:CleanAllMission(id)
	end
end

function M:ChangeEndEvent(isLoad)
	self:NotOpen()
	if self.TeamView then
		self.TeamView:UpdateIcon()
	end
end

function M:OnLvEvent()
	if self.MissionView then
		self.MissionView:UpdateLv()
	end
end

function M:UpdateTeamInfo()
		--self.TeamToggle:Start()
	if self.TeamView then self.TeamView:UpdateView() end
	tMgr.eUpdateBuff()
	self:OnUpdateToggleChagen()
end

function M:UpdateTeamData()
	if self.TeamView then self.TeamView:UpdateView() end
	tMgr.eUpdateBuff()
end

function M:UpdateLv()
	if self.MissionView then self.MissionView:UpdateLv() end
	if self.TeamView then self.TeamView:UpdateView() end
	tMgr.eUpdateBuff()
	self:OnUpdateToggleChagen()
end

function M:UpdateExp()
	self:UpdateLv()
end

function M:UpdateChapter(id)
	if self.MissionView then
		self.MissionView:UpdateChapter(id)
	end
	self:OnUpdateToggleChagen()
end

function M:ScreenChange(orient, init)
	local reset = UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, true, reset, self.oriLeft,self.oriRight)
end

--更新特效
function M:PlayMissionEffect(status)
	--local path = ""
	if status == 2 then
		--path = "UI_Task_Accept"
		--return
		--self.AcceptEff:SetActive(true)
	elseif status == 4 then
		--path = "UI_Task_Finish"
		self.FinishEff:SetActive(true)
	end
	--if StrTool.IsNullOrEmpty(path) then return end
	--Loong.Game.AssetMgr.LoadPrefab(path, GbjHandler(self.LoadEffectComplete,self))
end

function M:LoadEffectComplete(go)
	go.transform.parent = self.EffectRoot.transform
	go.transform.localPosition = Vector3.up * 100
	go.transform.localEulerAngles = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	
	Audio:PlayByID(MissSound, 1)
end

function M:OnUpdateToggleChagen()
	if self.MissionToggle and self.MissionToggle.value == true then
		self:OnToggleChange(self.MissionToggle, false)
		self.MissionView:Reposition()
	elseif self.TeamToggle and self.TeamToggle.value == true then
		self:OnToggleChange(self.TeamToggle, false)
		--self.TeamView:Reposition()
	end
end

function M:OnBoxClick()
	local userLv = User.MapData.Level
	local copyLv = CopyTemp["20201"].lv
	if userLv < copyLv then
		self.box.enabled = true
		UITip.Log("队伍功能暂未开放")
	else
		self.box.enabled = false
		self.TeamToggle.value = true
	end
end

function M:OnToggleChange(go, openui)
	if openui == nil then openui = true end
	local userLv = User.MapData.Level
	local copyLv = CopyTemp["20201"].lv
	local name  = go.name
	local h = 205
	if name == self.MissionToggle.name then
		if openui == true and self.CurToggle and self.CurToggle.name == name then
			UIMgr.Open(UIMission.Name)
		end
		local mView = self.MissionView
		if mView then
			h = h - mView:GetHeight()
		end
	elseif name == self.TeamToggle.name then
			h = h - self.TeamView:GetHeight()
	end
	if h < -92 then
		h = - 92
	end
	if self.Line then
		self.Line.transform.localPosition = Vector3.New(0,h,0)
	end
	self.CurToggle = go
end

function M:UpdateAutoHangup(value)
	if self.MissionView then self.MissionView:UpdateAutoHangup(value) end
end

--==============================--

function M:Update()
	if self.MissionView then self.MissionView:Update() end
end

function M:Open()
	self:NotOpen()
	self:OnLvEvent()
	self:OnUpdateToggleChagen()
end

function M:Close()
	-- self.box.enabled = true
end

function M:Clear()
	if self.MissionView then self.MissionView:Clear() end
end

function M:Dispose()
	self.CurToggle = nil
	if self.MissionView then
		self.MissionView:Dispose()
	end
	self.MissionView = nil
	if self.TeamView then
		self.TeamView:Dispose()
	end
	self.TeamView = nil
	self.MissionToggle = nil
	self.TeamToggle = nil
end

function M:NotOpen()
	--[[
	local temp = CopyTowerTemp[tostring(User.SceneId)]
	if temp then
		self:Close()
	end
	]]--
	if self.IsOpen == false then
		return 
	end

	local value = SceneMgr:IsCopy()
	
	self:SetActive(not value)
end

function M:SetActive(value)
	if self.GO then
		self.GO:SetActive(value)
	end
end

--endregion
