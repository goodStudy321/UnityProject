HgPoint = {Name = "HgPoint"}
local My = HgPoint;
--挂机点挂机计时器
My.HgPtTimer = nil;
local HgMgr = HangupMgr.instance;

function My:AddEvent()
    EventMgr.Add("HgupPointHgup",EventHandler(self.HgupPoint,self));
end

--挂机点挂机
function My:HgupPoint()
    local filted = My.FiltedScene();
    if filted == true then
        return;
    end
    local result = MissionMgr:CheckExecuteMainOrTurn();
    if result == true then
        return;
    end
    local time = 5;
    self:SetHgPointTimer(time);
    local yesStr = string.format( "确定(%ds)",time);
    local desc = "是否要去挂机点挂机？";
    MsgBox.CloseOpt = MsgBoxCloseOpt.No
    MsgBox.ShowYesNo(desc, self.YesCb,self, yesStr,self.NoCb, self, "取消");
end

--过滤场景(过滤不是野外场景)
function My.FiltedScene()
    local key = tostring(User.SceneId);
    if key == "30019" then --结婚场景（使用的是野外场景）
        return true;
    end
    local scene = SceneTemp[key];
    if scene == nil then
        return true;
    end
    if scene.maptype == SceneType.Copy then
        return true;
    end
    local subType = scene.mapchildtype;
    if subType == nil or subType == 0 then
        return false;
    end
    return true;
end

--设置挂机点挂机计时器
function My:SetHgPointTimer(time)
    local timer = My.HgPtTimer;
    if timer == nil then
        timer = ObjPool.Get(iTimer);
        timer.invlCb:Add(self.InvlCb,self);
        timer.complete:Add(self.YesCb, self);
        My.HgPtTimer = timer;
    end
    if timer.running then
        timer:Reset();
    end
    timer.seconds = time;
    timer:Start();
end

--间隔回调
function My.InvlCb()
    local leftTime = 0;
    local timer = My.HgPtTimer;
    if timer ~= nil then
        leftTime = timer:GetRestTime();
    end
    local yesStr = string.format( "确定(%ds)",leftTime);
    MsgBox.yesStr = yesStr;
    MsgBox.ShowYesNoCb(MsgBox.Name);
end

--确定挂机点挂机回调
function My.YesCb()
    My.ClearTimer();
    UIMgr.Close(MsgBox.Name);
    My.SetHgupPoint(true);
    LivenessMgr:AutoHangup();
end

--取消回调
function My.NoCb()
    My.ClearTimer();
end

--清除计时器
function My.ClearTimer()
    if My.HgPtTimer == nil then
        return;
    end
    My.HgPtTimer:AutoToPool();
    My.HgPtTimer = nil;
end

--设置挂机点挂机
function My.SetHgupPoint(hguppoint)
    HgMgr:SetHgupPoint(hguppoint);
end