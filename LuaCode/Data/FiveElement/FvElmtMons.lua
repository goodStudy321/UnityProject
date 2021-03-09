FvElmtMons = Super:New{Name = "FvElmtMons"}
local My = FvElmtMons;
My.eEndBoss=Event();
function My:Ctor()
    self.eInvlTime = Event();
    self.eEndTime = Event();
end

--设置信息
function My:SetInfo(monsId,rfrTime,pos)
    self.monsId = monsId;
    self.rfrTime = rfrTime;
    self.isRefresh = true;
    self:SetMonsInfo(monsId);
    self:SetTime();
    self:SetMonsPos(pos);
end

--设置怪物位置
function My:SetMonsPos(pos)
    if pos == nil then
        return;
    end
    self.pos = pos;
end

--设置怪物信息
function My:SetMonsInfo(monsId)
    monsId = tostring(monsId);
    local info = MonsterTemp[monsId];
    if info == nil then
        iTrace.Error("soon","无此怪物id="..monsId)
        return;
    end
    self.name = info.name;
    self.level = info.level;
    self.icon=info.icon
    if info.type == 3 or info.type == 4 then
        self.isBoss = true;
    else
        self.isBoss = false;
    end
end

--设置时间
function My:SetTime()
    if self.rfrTime == nil then
        self.isRefresh = true;
        return;
    end
    local nowTime = TimeTool.GetServerTimeNow() / 1000;
    local leftTime = self.rfrTime - nowTime;
    if leftTime <= 0 then
        self.isRefresh = true;
    else
        self.isRefresh = false;
        self:SetTimer(leftTime);
    end
end

--设置计时器
function My:SetTimer(time)
    if self.Timer == nil then
	    self.Timer = ObjPool.Get(DateTimer);
        self.Timer.fmtOp = 3;
        self.Timer.apdOp = 1;
        self.Timer.invlCb:Add(self.InvlTime, self);
        self.Timer.complete:Add(self.EndTime, self);
    else
        if self.Timer.running == true then
            self.Timer:Reset();
        end
	end
	self.Timer.seconds = time;
	self.Timer:Start();
end

--计时器间隔回调
function My:InvlTime()
    local remain = self:GetRemain();
    self.eInvlTime(remain);
end

--计时器时间结束
function My:EndTime()
    self.isRefresh = true;
    self.eEndTime();
    My.eEndBoss(self.monsId)
end

--获取剩余时间
function My:GetRemain()
    local timer = self.Timer;
    if timer == nil then
        return 0;
    end
    return timer.remain;
end

--释放计时器
function My:DisPoseTimer()
    if self.Timer == nil then
        return;
    end
    self.Timer:Dispose();
    self.Timer = nil;
end

--释放
function My:Dispose()
    self:DisPoseTimer();
    self.eInvlTime:Clear();
    self.eEndTime:Clear();
end