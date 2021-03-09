MountGuide = {Name = "MountGuide"}
local My = MountGuide;

function My:Init()
    self.Id = 1;
    self.IsOpen = false;
end

function My:ChkOpen(id)
    if self.Id ~= id then
        return;
    end
    self.IsOpen = true
end

function My:InitGo(go)
    if go == nil then
        return;
    end
    self.root = go;
end

--开启坐骑引导
function My:Open(id)
    if id == nil then
        return;
    end
    if self.Id ~= id then
        return;
    end
    if self.IsOpen == true then
        return;
    end
    self.IsOpen = true
    self:SetState(true);
    self:AddEvent();
    Hangup:Pause(self.Name);
    self:StartTimer();
end

--关闭坐骑引导
function My:Close()
    self:RemoveEvent();
    self:SetState(false);
    Hangup:Resume(self.Name);
    if self.timer then
        self.timer:Stop();
    end
end

--开始计时
function My:StartTimer()
    if not self.timer then
        self.timer = ObjPool.Get(iTimer);
        self.timer.complete:Add(self.Close, self);
    end
    self.timer.seconds = 3;
    self.timer:Start();
end

--设置状态
function My:SetState(active)
    if self.root == nil then
        return;
    end
    self.root:SetActive(active);
end

function My:AddEvent()
    EventMgr.Add("upSwipe",EventHandler(self.Close,self));
end

function My:RemoveEvent()
    EventMgr.Remove("upSwipe",EventHandler(self.Close,self));
end

function My:Clear()
    self.Id = 1;
    self.IsOpen = false;
    self:Close();
end

function My:Dispose()
    self:Close();
    self.root = nil;
    self.Id = nil;
    self.IsOpen = nil;
end

return My;