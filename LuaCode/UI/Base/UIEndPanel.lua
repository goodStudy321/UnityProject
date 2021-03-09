--region UIEndPanel.lua
--Date
--此文件由[HS]创建生成

UIEndPanel = UIBase:New{Name ="UIEndPanel"}

local M = UIEndPanel
local cMgr = CopyMgr
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
	self:SetEvent("Add")
end

function M:SetEvent(fn)
	cMgr.eUpdateSuccessListEnd[fn](cMgr.eUpdateSuccessListEnd, self.UpdateReward, self)
end

function M:UpdateRewardTitle(str)
	if not str then return end
	self.rewardTitle.text = str
end

function M:UpdateData(value, list)
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
	local isTower = false
	if copy and copy.type == CopyType.Tower then isTower = true end
	local lv = cMgr.CopyEndStar
	self:UpdateBtnStatus(isTower, value)
	self:UpdateDes(lv, copy)
	self:UpdateReward(lv, list)
	self:UpdateEndTimer(lv)
	self:UpdateStarLv(lv)
	self:UpdateStars(lv)
	self:UpdateCDLab(value, isTower)
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

function M:UpdateBtnStatus(isTower, value)
	if self.ExitBtn then
		local ePos = Vector3.New(-106.21,-293.35,0)
		if not isTower or  User.SceneId == 40001 then
			ePos = Vector3.New(0,-293.35,0)
		end
		self.ExitBtn.transform.localPosition = ePos
	end
	if self.RestartBtn then
		self.RestartBtn:SetActive(isTower and User.SceneId ~= 40001)
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
	local hNum,curHonor,maxHonor,isChange = CopyMgr:GetCopyNum(copy)
	if label then
		if name then
			local str = string.format("恭喜通关%s", copy.name)
			if copy.type == 17 then
				str = "突破后可获得以下奖励"
			elseif copy.type == CopyType.Equip or copy.type == CopyType.Loves then
				if hNum <= 0 then
					if curHonor < maxHonor then
						str = string.format("恭喜助战%s成功", copy.name)
					else
						str = string.format("已达到本日助战奖励上限本次不获得奖励")
					end
				end
			end
			-- iTrace.eError("GS","endPanel hNum==",hNum,"  CopyMgr.HaveRwdIndex==",CopyMgr.HaveRwdIndex,"   isChange==",isChange)
			if isChange == true and copy.type == CopyType.Loves then
				CopyMgr:SetHaveRwdIndex(1)
			end
			label.text = str
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

function M:UpdateCDLab(value, isTower)
	if value == 1 and isTower == true and User.SceneId ~= 40001 then
		self.CDLab = self.RestartTime
	else
		self.CDLab = self.ExitTimer
	end
	self.CDLab.text = DateTool.FmtSec(self.CountDown, 3, 0) 
	self:ShowTimer(value, isTower)
end

function M:ShowTimer(value, isTower)
	local active = value == 1 and isTower == true and User.SceneId ~= 40001
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
		self:OnRestartBtn()
	end
end

function M:OnExitBtn(go)
	cMgr:ClearCopyInfo()
	--self:Close()
	SceneMgr:QuitScene()
end

function M:OnRestartBtn(go)
	cMgr:ClearCopyInfo()
	self:Close()
	local screenid = self:GetIndex()
	if screenid then
		if screenid == 0 then return end
		if screenid ~= User.SceneId then
			iTrace.eLog("hs", "进入下一张场景"..screenid)
			SceneMgr:ReqPreEnter(screenid, false)
		else
			iTrace.eLog("hs","进入同一张场景挑战副本："..screenid)
			cMgr:ReqCpoyRestart()
		end
		cMgr:ShowEffect()
	else
		SceneMgr:QuitScene()
	end
end

function M:GetIndex()
	local key = tostring(CopyType.Tower)
	local data = cMgr.Copy[key]
	local list = data.Dic
	local indexOf = data.IndexOf
	local id = cMgr.LimitTower
	local curId = 0
	if id ~= 0 then
		local index = indexOf[tostring(id)]
		if index < 1 then index = 0 end
		index = index + 1
		if list[index] then
			curId = list[index].id
		else
			curId = nil
		end
	else
		curId = list[1].id
	end
	return curId
end

function M:OpenCustom()
	Hangup:SetSituFight(false);
end


function M:ConDisplay()
	do return true end
end

function M:DisposeCustom()
	self:SetEvent("Remove")
	if self.TimerTool then self.TimerTool:AutoToPool() end
	self.TimerTool = nil
	self.CDLab = nil
	TableTool.ClearListToPool(self.Cells)
	TableTool.ClearDic(self.Stars)
end

return M

