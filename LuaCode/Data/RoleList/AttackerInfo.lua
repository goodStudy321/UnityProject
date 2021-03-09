AttackerInfo = Super:New{Name="AttackerInfo"}
local My = AttackerInfo;
function My:Ctor()
    self.id = nil;
    self.timer = nil;
end

--设置攻击者信息
function My:SetAtkInfo(atkId)
    self.id = atkId;
    self:StartTimer();
end

--开始计时器
function My:StartTimer()
    if self.timer == nil then
        self.timer = ObjPool.Get(iTimer);
        self.timer.complete:Add(self.RmAtker, self)
    end
    if self.timer.running then
        self.timer:Stop();
    end
    self.timer.seconds = 5;
    self.timer:Start();
end

--移除攻击者
function My:RmAtker()
    AtkInfoMgr:RmAtkInfo(self.id);
end

--释放信息
function My:Dispose()
    if self.timer ~= nil then
        self.timer:AutoToPool();
        self.timer = nil;
    end
    self.id = nil;
end

function My:Clear()
    self:RMAtker();
end