UIDftItem = {Name = "UIDftItem"}
local My = UIDftItem;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--开始计时
function My:StartTimer()
    if self.timer == nil then
        self.timer = ObjPool.Get(iTimer);
    end
    if self.timer.running then
        self.timer.cnt = 0;
        return;
    end
    self.timer.seconds = 3;
    self.timer:Start();
end

--受击时间结束
function My:HitTimeCount()
    if self.BehitG == nil then
        return;
    end
    if self.BehitG.activeSelf == false then
        return;
    end
    self.BehitG:SetActive(false);
end

return My;