UIFamilyWarBtn = Super:New{Name = "UIFamilyWarBtn"}

local M = UIFamilyWarBtn

function M:Init(root)
    self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
    self.timerLab.gameObject:SetActive(true)
    self:CreateTimer()
end


function M:CreateTimer()
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = FamilyWarMgr.ActivityInfo.eTime - now
    if dValue <= 0 then return end
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
    end
    local timer = self.timer
    timer.seconds = dValue
    timer.fmtOp = 3
    timer.apdOp = 1
    timer.invlCb:Add(self.TimerCb, self)
    timer.complete:Add(self.CompCb, self)
    timer:Start()
    self:TimerCb()
end

function M:TimerCb()
    self.timerLab.text = self.timer.remain
end

function M:CompCb()
    self.timer:Stop()
    self.timerLab.text = "已结束"
end



function M:Dispose()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.timerLab then
        self.timerLab.gameObject:SetActive(false)
    end
    self.timerLab = nil
end

return M
