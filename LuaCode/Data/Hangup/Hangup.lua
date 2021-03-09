require("Data/Hangup/HgPoint")
Hangup = {Name = "Hangup"}
local My = Hangup;
local HgMgr = HangupMgr.instance;

My.PauseList = {}

My.eUpdateAutoStatus = Event()
My.eClearAutoStatus = Event()

function My:Init()
    HgPoint:AddEvent();
    My.PauseList = {}
end

--获取自动挂机状态
function My:GetAutoHangup()
    return HgMgr.IsAutoHangup;
end

--设置自动挂机状态
function My:SetAutoHangup(atHg)
    if atHg == nil then
        return;
    end
    HgMgr.IsAutoHangup = atHg;
    self.eUpdateAutoStatus()
    --iTrace.sLog("IsAutoHangup--->",atHg)
end

--获取自动技能状态
function My:GetAutoSkill()
    return HgMgr.IsAutoSkill;
end

--设置自动技能状态
function My:SetAutoSkill(atSk)
    if atSk == nil then
        return;
    end
    HgMgr.IsAutoSkill = atSk;
    --iTrace.sLog("IsAutoSkill--->",atSk)
end

--获取原地战斗状态
function My:GetSituFight()
    return HgMgr.IsSituFight;
end

--设置原地战斗状态
function My:SetSituFight(stFt)
    if stFt == nil then
        return;
    end
    HgMgr.IsSituFight = stFt;
    self.eUpdateAutoStatus()
    --iTrace.sLog("IsSituFight--->",stFt)
end

--清除自动挂机信息
function My:ClearAutoInfo()
    HgMgr:ClearAutoInfo();
    self.eClearAutoStatus()
    --iTrace.sLog("ClearAutoInfo--->","")
end

--任务更新
function My:MissionUpdate(msnId,nxtSt)
    HgMgr:MissionUpdate(msnId, nxtSt)
end

--是否暂停状态
function My:IsPause()
    return HgMgr.IsPause;
end

--暂停挂机
function My:Pause(uiName)
    if App.IsDebug == true  then
        iTrace.sLog("-------------------->> ","测试：暂停挂机: "..uiName)
    end
    local canPause = self:Check();
    if canPause == false then
        return;
    end
    HgMgr.IsPause = true;
    User:StopNavPath();
    self:AddPauseUI(uiName);
end

--恢复挂机
function My:Resume(uiName)
    if App.IsDebug == true  then
        iTrace.sLog("-------------------->> ","测试：恢复挂机: "..uiName)
    end
    local rmvAll = self:RemovePauseUI(uiName);
    if rmvAll == false then
        return;
    end
    HgMgr.IsPause = false;
    User.MissionState = false;
end

--添加暂停UI
function My:AddPauseUI(uiName)
    local name = My.PauseList[uiName];
    if name ~= nil then
        return;
    end
    My.PauseList[uiName] = 1;
end

--检查过滤
function My:Check()
    local sceneId = tostring(User.SceneId);
    if sceneId == nil then
        return false;
    end
    local info = CopyExpTemp[sceneId];
    if info ~= nil then
        return false;
    end
    return true;
end

-- 移除
function My:RemovePauseUI(uiName)
    local name = My.PauseList[uiName];
    if name ~= nil then
        My.PauseList[uiName] = nil;
    end
    for k,v in pairs(My.PauseList) do
        if v ~= nil then
            if App.IsDebug == true  then
                iTrace.sLog("-------------------->> ","测试：还有暂停UI: "..k)
            end
            return false;
        end
    end
    return true;
end

function My:Clear()
    My.PauseList = {}
    HgPoint.ClearTimer();
end

function My:Dispose()
    My.PauseList = nil;
end

return My;