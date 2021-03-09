UIDftRfMons = {Name="UIDftRfMons"}
local My = UIDftRfMons;

function My:Init(root)
    self.root = root;
    self.root:SetActive(false);
    local trans = root.transform;
	local name = "刷怪前提示";
    local CG = ComTool.Get;
    self.TimeLbl = CG(UILabel,trans,"TimeCount",name,false);
    self:Open();
end

--初始化计时器
function My:InitTime()
    if self.timer ~= nil then
        return;
    end
    self.timer = ObjPool.Get(iTimer);
    self.timer.invlCb:Add(self.Tick,self);
    self.timer.complete:Add(self.TimeDone,self);
end

--打开刷怪前倒计时
function My:Open()
    self:InitTime();
    local time = FamilyActivityMgr.GetRfMonsTime();
    if time == 0 then
        return;
    end
    if self.timer.running == true then
        self.timer:Stop();
    end
    self.timer.seconds = time;
    self.timer:Start();
end

--间隔计时
function My:Tick()
    if self.root == nil then
        return;
    end
    if self.timer == nil then
        return;
    end
    local time = self.timer:GetRestTime();
    if time > 120 then
        return;
    end
    time = math.floor(time + 0.5);
    if time > 1 then
        if self.root.activeSelf == false then
            self.root:SetActive(true);
        end
    end
    if self.TimeLbl == nil then
        return;
    end
    local waveNum = FamilyActivityMgr.GetCurWave()
    local tip = ""
    if waveNum == 0 then
        if time < 1 then
            tip = string.format("战斗开始");
        else
            tip = string.format("%d秒战斗开启",time);
        end
    else
        tip = string.format("下一波怪物: %d",time);
    end
    self.TimeLbl.text = tip
end

--刷怪前倒计时完成
function My:TimeDone()
    if self.root == nil then
        return;
    end
    self.root:SetActive(false);
end

function My:Clear()
    if self.timer == nil then
        return;
    end
    self.timer:Stop();
end

function My:Dispose()
    if self.timer == nil then
        return;
    end
    self.timer:AutoToPool();
    self.timer = nil
    TableTool.ClearUserData(self);
end