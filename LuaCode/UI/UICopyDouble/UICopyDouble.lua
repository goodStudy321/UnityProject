UICopyDouble = Super:New{Name = "UICopyDouble"}

local My = UICopyDouble

function My:Init(root)
    self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
    self.timerLab.gameObject:SetActive(true)
    self:Countdown()
end

function My:Countdown()
    local info = FestivalActMgr:GetActInfo(FestivalActMgr.CopyDb)
    if not info then return end
    local startTime = 0
    local endTime = 0
    local severTime = 0
    local seconds = 0
    startTime = info.sTime
    endTime = info.eTime
    severTime = TimeTool.GetServerTimeNow()*0.001
    seconds = info.eTime - severTime
    local isOpen = FestivalActMgr:IsOpenCopyDB()
    if endTime == 0 then
        self.timerLab.gameObject:SetActive(false)
    end
    if isOpen and seconds > 0 then
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.fmtOp = 3
            self.timer.apdOp = 2
            self.timer.invlCb:Add(self.InvCountDown, self)
            self.timer.complete:Add(self.EndCountDown, self)
        end
        self.timer.seconds = seconds
        self.timer:Stop()
        self.timer:Start()
        self:InvCountDown()
    else
        self:EndCountDown()
    end
end

function My:InvCountDown()
    self.timerLab.text = self.timer.remain
end

function My:EndCountDown()
    self.timerLab.gameObject:SetActive(false)
    self.timerLab.text = ""
    if self.timer then
        self.timer:Stop()
    end
end


function My:Click()
    UIFestivalAct:Show(FestivalActMgr.CopyDb)
end

function My:Dispose()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.timerLab then
        self.timerLab.gameObject:SetActive(false)
    end
    self.timerLab = nil
end

return My