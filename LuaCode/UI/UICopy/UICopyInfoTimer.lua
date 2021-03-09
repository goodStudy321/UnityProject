UICopyInfoTimer = UIBase:New{ Name = "UICopyInfoTimer"}
local M = UICopyInfoTimer

M.eStart = Event()
M.eClose = Event()

--构造函数
function M:InitCustom()
	local C = ComTool.Get
	local trans = self.root
	local name = self.Name

	self.ATime = C(UILabel, trans, "AllTime", name, false)
	self.STime = C(UILabel, trans, "StartTime", name, false)
	self.ITime = C(UILabel, trans, "InteTime", name, false)
	self.WTime = C(UILabel, trans, "EndTime", name, false)

	self.Button = TransTool.FindChild(trans, "Button")
	UITool.SetLsnrSelf(self.Button, self.Quit, self)

	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.invlCb:Add(self.InvCountDown, self)
    self.TimerTool.complete:Add(self.EndCountDown, self)

	self.IsStart = true

	self.AllTime = nil
	self.StartTime = nil
	self.InvlTime = nil
	self.WaitTime = nil
	self.Time = nil

	self.IsCopyStart = false

	self:InitData()
	self:SetLsnr("Add")
end

function M:SetLsnr(fn)
	local mgr = CopyMgr
	mgr.eUpdateCopyInfo[fn](mgr.eUpdateCopyInfo, self.InitData, self)
	mgr.eUpdateCopyStatus[fn](mgr.eUpdateCopyStatus, self.UpdateCopyStatus, self)
	mgr.eUpdateCopyATime[fn](mgr.eUpdateCopyATime, self.UpdateCopyATime, self)
	mgr.eUpdateCopyITime[fn](mgr.eUpdateCopyITime, self.UpdateCopyITime, self)
	UIMainMenu.eHide[fn](UIMainMenu.eHide, self.SetMenuStatus, self)
end

function M:InitData()
	local info = CopyMgr.CopyInfo
	local isGuide = self:IsGuide()
	self:SetMenuStatus(isGuide)
	if not info then return end
	local temp = CopyTemp[tostring(User.SceneId)]
	if temp == nil then return end
	self:UpdateCopyATime(info.ATime, info.st)
	local cTemp = CopyMgr:GetChilTemp(temp, info)
    if cTemp then self:UpdateCopyITime(cTemp.interval) end
end

function M:SetMenuStatus(value)
	local isGuide = self:IsGuide()
	if isGuide == false then
		value = isGuide
	end
	self.Button:SetActive(value)
end

function M:IsGuide()
	local info = CopyMgr.CopyInfo
	local expInfo = CopyMgr.Copy[CopyMgr.Exp]
	if expInfo.FinishTimes and info.mapid == 20001 then
		local value = GlobalTemp["133"].Value3
		if expInfo.FinishTimes < value then
			return false
		else
			return true
		end
	else
		return true
	end
	
end

--更新副本状态
function M:UpdateCopyStatus(time)
	self:UpdateCopyWTime(time)
end

function M:Quit()
	local temp = CopyTemp[tostring(User.SceneId)]
	if temp and temp.type == CopyType.ZHTower then
		local info = CopyMgr.CopyInfo
		if info.IsEnd == 0 then
			local data, isOpen, floor = CopyMgr:GetCurCopy(CopyType.ZHTower)
			if floor == 1 then
				MsgBox.ShowYesNo("退出将无法获取任何奖励，是否退出？", self.OKCb, self) 
			else
				MsgBox.ShowYesNo("退出后只可获得上层镇魂塔的三星奖励，是否确认退出？", self.OKCb, self) 
			end
		else
			MsgBox.ShowYesNo("确定要离开副本吗？", self.OKCb, self) 
		end
	else
		MsgBox.ShowYesNo("确定要离开副本吗？", self.OKCb, self) 
	end
end

function M:OKCb()
	SceneMgr:QuitScene()
	CopyMgr:ClearCopyInfo()
	self.eClose()
	self:Close()
end

--更新持续时间
function M:UpdateCopyATime(time, sTime)
	self.StartTime = sTime
	self:UpdateTimeVlaue(self.STime, self.StartTime, true)
	if sTime > 0 then
		self.IsStart = true
	end
	
	self.AllTime = time 
	if not self.Time then
		self.Time = time
	end
	self:UpdateTimeVlaue(self.ATime, self.AllTime, true)
	if self.IsCopyStart == true then
		self.TimerTool.seconds = time + sTime 
		self.TimerTool:Reset()
		return 
	end
	self.IsCopyStart = true
	self.TimerTool.seconds = time + sTime 
    self.TimerTool:Start()
end

--更新刷怪间隔时间
function M:UpdateCopyITime(time)
	if not time or time == 0 then return end
	self.InvlTime = time
	self:UpdateTimeVlaue(self.ITime, self.InvlTime, true)
end

--更新结束延迟时间
function M:UpdateCopyWTime(time)
	self.WaitTime = time
	self:UpdateTimeVlaue(self.WTime, self.WaitTime, true)
	if self.TimerTool then
		self.TimerTool.cnt = 0
		self.TimerTool.seconds = time
	end
end

--倒计时间隔回调
function M:InvCountDown()
	self.StartTime = self:GetTime(self.StartTime)
	self:UpdateTimeVlaue(self.STime, self.StartTime, true)
	if self.StartTime <= 0 then
		if self.IsStart then
			self.IsStart = false
			self.eStart()
		end
		self.AllTime = self:GetTime(self.AllTime)
		if self.Time then
			CopyMgr.CopyEndTime = self.Time - self.AllTime
		end
		self:UpdateTimeVlaue(self.ATime, self.AllTime, true)
		CopyMgr:CopyInfoCountDown(self.AllTime)
	end

	if  self.InvlTime and  self.InvlTime >= 0 then
		self.InvlTime = self:GetTime(self.InvlTime)
		self:UpdateTimeVlaue(self.ITime, self.InvlTime, true)
	end

	if self.WaitTime and self.WaitTime >= 0 then
		self.WaitTime = self:GetTime(self.WaitTime)
		self:UpdateTimeVlaue(self.WTime, self.WaitTime, true)
	end
end

--更新文本
function M:UpdateTimeVlaue(label, time, format)
	if not label then return end
	if not time then return end
	label.gameObject:SetActive(time > 0)
	if not format then
		label.text = math.floor(time)
	else
		label.text = DateTool.FmtSec(time, 3, 1)
	end 
end

--获取时间
function M:GetTime(time)
	if time  and time > 0 then
		time = time - self.TimerTool.invlCnt
		return time
	end
	return 0
end

--倒计时结束回调
function M:EndCountDown()
	self:InvCountDown()
	self:Clean()
	local info = CopyMgr.CopyInfo
	if not info or info and info.IsEnd and info.IsEnd ~= 0 then
		CopyMgr:OpenEndPanel()
	end
end


function M:CloseTime()
	self.InvlTime = 0
	self.WaitTime = 0
end

--清楚数据
function M:Clean()
	if self.Time and self.AllTime then
		CopyMgr.CopyEndTime = self.Time - self.AllTime
	end
	self.IsCopyStart = false
	if self.TimerTool then 
		self.TimerTool:Stop()
	end
	self.AllTime = nil
	self.InvlTime = nil
	self.StartTime = nil
	self.WaitTime = nil
	self.Time = nil
	self:SetActive(self.ATime) 
	self:SetActive(self.STime) 
	self:SetActive(self.ITime) 
	self:SetActive(self.WTime) 
end

function M:SetActive(label)
	if label then 
		label.text = ""
		label.gameObject:SetActive(false)
	end
end

function M:ConDisplay()
	do return true end
end

function M:Clear()
	self.IsStart = true
end

--释放或销毁
function M:DisposeCustom()
	self:SetLsnr("Remove")
	if self.TimerTool then 
		self.TimerTool:AutoToPool() 
		self.TimerTool = nil
	end
	self.AllTime = nil
	self.StartTime = nil
	self.InvlTime = nil
	self.WaitTime = nil
	self.Time = nil
	self.IsCopyStart = false
end

return M

