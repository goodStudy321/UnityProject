--region UIEndPanelTX.lua
--Date
--此文件由[HS]创建生成

UIEndPanelTX = UIBase:New{Name ="UIEndPanelTX"}

local M = UIEndPanelTX
local cMgr = CopyMgr
local ctMgr = CopyTowerMgr
M.CountDown = 10
local SucSound = 107

M.Cells = {}
M.Stars = {}

function M:InitCustom()
	local name = "结算信息面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local E = UITool.SetLsnrSelf

	self.SuccessRoot = T(trans, "Success")
	self.STitle = T(trans, "Success/Title")
	self.SBg = T(trans, "Success/Bg")
	self.StarLv = C(UISprite, trans, "Success/StarLv", name, false)
	self.Des = C(UILabel, trans, "Success/Des", name, false)
	self.ProwerDes = C(UILabel, trans, "Success/ProwerDes", name, false)
	self.ProwerEff1=T(trans, "Success/ProweEff/FX_zuikuai_003")
	self.ProwerEff2=T(trans, "Success/ProweEff/FX_zuikuai_001")
	self.ProwerEff3=T(trans, "Success/ProweEff/FX_zuikuai_002")
	self.EndTimer = C(UILabel, trans, "Success/Timer", name, false)
	self.FailRoot = T(trans, "Fail")
	self.FTitle = T(trans, "Fail/Title")
	self.FBg = T(trans, "Fail/Bg")

	self.sView = TransTool.Find(trans, "ScrollView")
	self.Grid = C(UIGrid, trans, "ScrollView/Reward", name, false)
	self.PosTween = C(TweenPosition, trans, "ScrollView/Reward", name, false)

	self.ExitBtn =  T(trans, "ExitBtn")
	self.ExitTimer = C(UILabel, trans, "ExitBtn/ETimer", name, false)
	self.RestartBtn =  T(trans, "RestartBtn")
	self.RestartLab = C(UILabel, trans, "RestartBtn/Label")
	self.RestartTime = C(UILabel, trans, "RestartBtn/RTimer", name, false)

	self.rewardTitle = C(UILabel, trans, "Success/Bg/Label")

	self.StarList = T(trans, "Success/StarList")

	for i=1,3 do
		local star = T(self.StarList.transform, "Star"..i)
		table.insert(self.Stars, star)
	end

	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.invlCb:Add(self.InvCountDown, self)
	self.TimerTool.complete:Add(self.EndCountDown, self)

	E(self.ExitBtn, self.OnExitBtn, self)
	E(self.RestartBtn, self.OnRestartBtn, self)

	self.CDLab = nil
	self.EndStatus= nil
	self:SetEvent("Add")
end

function M:SetEvent(fn)
	cMgr.eUpdateSuccessListEnd[fn](cMgr.eUpdateSuccessListEnd, self.UpdateReward, self)
	cMgr.eUpdateCopyEndStatus[fn](cMgr.eUpdateCopyEndStatus, self.UpdateCopyEndStatus, self)
end

function M:UpdateRewardTitle(str)
	if not str then return end
	self.rewardTitle.text = str
end

function M:UpdateData(value, list)
	self.EndStatus= value
	local title = nil
	local bg = nil
	local starLv = nil
	local reward = nil
	if value == 1 then
    	self.FailRoot:SetActive(false)
		self.SuccessRoot:SetActive(true)
		Audio:PlayByID(SucSound, 1)
		title = self.STitle
		bg = self.SBg
		starLv = self.StarLv
		reward = self.Grid
	else
    	self.SuccessRoot:SetActive(false)
		self.FailRoot:SetActive(true)
		title = self.FTitle
		bg = self.FBg
	end
	local key = tostring(User.SceneId)
	local copy = CopyTemp[key]
	local lv = cMgr.CopyEndStar
	self:UpdateBtnStatus(value)
	self:UpdateDes(lv, copy)
	self:UpdateReward(lv, list)
	self:UpdateEndTimer(lv)
	self:UpdateStarLv(lv)
	self:UpdateStars(lv)
	self:UpdateCDLab(value)
	self:UpdateCopyEndStatus()
	if self.TimerTool then 
		self.TimerTool.seconds = self.CountDown
		self.TimerTool:Start()
	end
	if title then title:SetActive(true) end
	if bg then bg:SetActive(true) end
	if starLv then 
		local state = copy.type ~= CopyType.ZHTower 
		starLv.gameObject:SetActive(state) 
		self.StarList:SetActive(not state)
	end
	if reward then reward.gameObject:SetActive(true) end
end

function M:UpdateStars(lv)
	lv = lv or 0
	local list = self.Stars
	for i=1,#list do
		list[i]:SetActive(i<=lv)
	end
end

function M:UpdateBtnStatus(value)
	if self.ExitBtn then
		self.ExitBtn.transform.localPosition = Vector3.New(-106.21,-293.35,0)
	end
	if self.RestartBtn then
		self.RestartBtn:SetActive(true)
	end
	if self.RestartLab then
		local str = "继续挑战"
		if value ~= 1 then
			str = "重新挑战"
		end
		self.RestartLab.text = str
	end
end

function M:UpdateDes(lv, copy)
	local label = self.Des
	local name = ""
	if copy then name = copy.name end
	if LuaTool.IsNull(label) == false then
		if StrTool.IsNullOrEmpty(name) then
			str = string.format("恭喜通关%s", copy.name)
		end
	end
end

function M:UpdateEndTimer(lv)
	if self.EndTimer then
		self.EndTimer.gameObject:SetActive(lv ~= nil)
		local time = cMgr.CopyEndTime
		if not time then return end
		self.EndTimer.text = DateTool.FmtSec(time, 0, 1) 
	end
end

function M:UpdateStarLv(lv)
	if self.StarLv then
		self.StarLv.gameObject:SetActive(lv ~= nil)	
		local name = ""
		if lv then name = string.format("star%s",lv) end
		self.StarLv.spriteName = name
	end
end

function M:UpdateCDLab(value)
	if value == 1 then
		self.CDLab = self.RestartTime
	else
		self.CDLab = self.ExitTimer
	end
	self.CDLab.text = DateTool.FmtSec(self.CountDown, 3, 0) 
	self:ShowTimer(value)
end

function M:ShowTimer(value)
	local active = value == 1
	if self.RestartTime then
		self.RestartTime.gameObject:SetActive(active)
	end
	if self.ExitTimer then
		self.ExitTimer.gameObject:SetActive(not active)
	end
end

function M:UpdateReward(lv, list)
	local grid = self.Grid
	if not list then return end
	if #self.Cells > 0 then return end
	local len = #list 
	if len == 0 then
		self:UpdateRewardTitle("")
	end
	if not lv then
		local x = -3
		if len <= 4 then
			x = 157 - 40*len			
		end
		self.sView.localPosition = Vector3(x, -180, 0)
	else
		self.sView.localPosition = Vector3(70, -180, 0)
	end

	for i=1,len do
		local info = list[i]
		if info then
			local cell = ObjPool.Get(UIItemCell)
			cell:InitLoadPool(grid.transform)
			cell:UpData(info.k, info.v)
			table.insert(self.Cells, cell)
		end
	end
	grid:Reposition()
end

function M:UpdateCopyEndStatus()
	local status = cMgr.TxTowerEndStatus
	local label = self.Des
	local pLabel = self.ProwerDes
	local eff1 = self.ProwerEff1
	local eff2 = self.ProwerEff2
	local eff3 = self.ProwerEff3
	local str = nil
	label.gameObject:SetActive(status == 0)
	pLabel.gameObject:SetActive(status ~= 0)
	eff1:SetActive(status == 1)
	eff2:SetActive(status == 2)
	eff3:SetActive(status == 3)
	if status ~= 0 then
		if status == 1 then
			str = "恭喜你成为本层最低战斗力通关者"
		elseif status == 2 then
			str = "恭喜你成为本层最快通关者"
		elseif status == 3 then
			str = "恭喜你成为本层最低战斗力且最快通关者"
		end
		pLabel.text = str
	else
		local index = cMgr:GetTxIndex(User.SceneId)
		str = string.format("恭喜您通关%s层", index)
		label.text = str
	end
end


--倒计时间隔回调
function M:InvCountDown()
	if self.CDLab  then
		self.CDLab.text = DateTool.FmtSec(self.TimerTool:GetRestTime(), 3, 0)
	end
end

--倒计时结束回调
function M:EndCountDown()
	local lab = self.CDLab
	if lab.name == self.ExitTimer.name then
		self:OnExitBtn()
	elseif lab.name == self.RestartTime.name then
		self:Restart()
	end
end

function M:OnExitBtn(go)
	cMgr:ClearCopyInfo()
	--self:Close()
	SceneMgr:QuitScene()
end

function M:OnRestartBtn(go)
	self.TimerTool:Dispose()
	if self.EndStatus ~= 1 then
		cMgr:ReqCpoyRestart()
	else
		self:Restart()
	end
	self:Close()
	cMgr:ClearCopyInfo()
end

function M:Restart()
	self:Close()
	local screenid = ctMgr:GetIndex()
	if screenid then
		if screenid == 0 then return end
		if screenid ~= User.SceneId then
			ctMgr:StartFlowChart()
		else
			iTrace.eLog("hs","进入同一张场景挑战副本："..screenid)
			cMgr:ReqCpoyRestart()
		end
	else
		SceneMgr:QuitScene()
	end
end

function M:OpenCustom()
	UIMgr.Close(UICopyInfoPub.Name)
	Hangup:SetSituFight(false);
end

function M:ConDisplay()
	do return true end
end

function M:DisposeCustom()
	self:SetEvent("Remove")
	if self.TimerTool then self.TimerTool:AutoToPool() end
	local itc = self.iTweenVector3
	if itc then
		itc:Stop()
		itc.complete:Remove(self.TweenComplete, self)	
		itc.onValue:Remove(self.UpdateVector3, self)	
		self.iTweenVector3:AutoToPool()
	end
	self.TimerTool = nil
	self.CDLab = nil
	self.EndStatus = nil
	TableTool.ClearListToPool(self.Cells)
	TableTool.ClearDic(self.Stars)
end

return M

