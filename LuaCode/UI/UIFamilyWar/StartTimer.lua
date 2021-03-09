StartTimer = Super:New{Name = "StartTimer"}

local M = StartTimer

function M:Init(root)
    self.labTime = ComTool.Get(UILabel, root, "Timer")
end

function M:CreateTimer()
    local readyTime = FamilyWarMgr:GetReadyTime()
    if readyTime > 0 then
        self:SetActive(true)
        self.canFight = false
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
        end
        self.timer.seconds = readyTime
        self.timer.invlCb:Add(self.TimerCb, self)
        self.timer.complete:Add(self.CompleteCb, self)
        self.timer:Start()
        self:TimerCb()
    else
        self:CompleteCb()
    end
end

function M:Update()
    if not self.canFight then
        User:StopNavPath()
        Hangup:SetSituFight(false);
    end
end

function M:SetActive(bool)
    self.labTime.gameObject:SetActive(bool)
end

function M:UpdateFight(value)
    if not self.canFight and value then
        UITip.Log("比赛还没开始，不能自动挂机！")
    end
end

function M:TimerCb()
    self.labTime.text = string.format("开始倒计时：%s", self.timer.remain)
end

function M:CompleteCb()
    self:SetActive(false)
    self.canFight = true
    EventMgr.Trigger("FamilyWarBornChg", false)
    FamilyWarMgr.eReadyTimeEnd()
end

function M:Dispose()
    self.labTime = nil
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
end