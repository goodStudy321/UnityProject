UIBtnDemon = Super:New{Name = "UIBtnDemon"}

local M = UIBtnDemon

function M:Init(root)
    self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
    self:Countdown()
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    DemonMgr.eUpdateDemonState[key](DemonMgr.eUpdateDemonState, self.Countdown, self)
end


function M:Countdown()
    local endTime = DemonMgr:GetEndTime()
    local sec = endTime - TimeTool.GetServerTimeNow()*0.001
    if sec <= 0 then 
        self:StopTimer()
        self:EndCountDown()
        return 
    end
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
        self.timer.fmtOp = 3
        self.timer.apdOp = 1
        self.timer.invlCb:Add(self.InvCountDown, self)
        self.timer.complete:Add(self.EndCountDown, self)
    end
    self.timer.seconds = sec
    self.timer:Start()
    self:SetLabActive(true)
    self:InvCountDown()  
end

function M:InvCountDown()
    self.timerLab.text = self.timer.remain
end

function M:SetLabActive(bool)
    self.timerLab.gameObject:SetActive(bool)
end

function M:EndCountDown()
    self:SetLabActive(false)
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
end

function M:Dispose()
    self:SetLsnr("Remove")
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.timerLab then
        self.timerLab.gameObject:SetActive(false)
    end
    self.timerLab = nil
end

return M