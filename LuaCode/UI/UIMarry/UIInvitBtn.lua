--[[
 	authors 	:Liu
 	date    	:2018-12-21 10:00:00
 	descrition 	:请帖(按钮)
--]]

UIInvitBtn = Super:New{Name = "UIInvitBtn"}

local My = UIInvitBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
    -- UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
    self:CreateTimer()
    self:UpRTime()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.eFeastState[func](MarryMgr.eFeastState, self.RespFeastState, self)
end

--响应婚宴状态
function My:RespFeastState(state)
	if state then
		self:UpRTime()
	end
end

--更新宴会的剩余时间
function My:UpRTime()
	local endTime = MarryInfo.feastData.endTime
	if endTime > 0 then
		local sTime = TimeTool.GetServerTimeNow()*0.001
		local leftTime = endTime - sTime
		self:UpTimer(leftTime)
	end
end

--更新计时器
function My:UpTimer(rTime)
	if self.timer == nil then return end
	local timer = self.timer
	timer.seconds = rTime
	timer:Start()
	self:InvCountDown()
end

--创建计时器
function My:CreateTimer()
	if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
	timer.complete:Add(self.EndCountDown, self)
	timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
	if self.timerLab then
		local s = self.timer.remain
		local time = self.timer:GetRestTime()
		self.timerLab.text = s
        self.timerLab.gameObject:SetActive(time > 0)
    end
end

--结束倒计时
function My:EndCountDown()
	if self.timerLab then
		self.timerLab.gameObject:SetActive(false)
	end
end

-- --点击按钮
-- function My:OnClick()
--     UIProposePop:OpenTab(5)
-- end

--清理缓存
function My:Clear()
	self:EndCountDown()
end

--清理计时器
function My:ClearTimer()
	if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
	end
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:ClearTimer()
    self:SetLnsr("Remove")
end

return My