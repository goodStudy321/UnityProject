ArenaBtn = Super:New{Name = "ArenaBtn"}

local My = ArenaBtn

local Droiy = Droiyan

local PeakMgr = Peak
local TUB = ThrUniBattle

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    Droiy.eMainRed[func](Droiy.eMainRed, self.RespShowRed, self)
    TUB.eUpTimer[func](TUB.eUpTimer, self.RespUpTimer, self)
	TUB.eEndTimer[func](TUB.eEndTimer, self.RespEndTimer, self)
    PeakMgr.eUpTimer[func](PeakMgr.eUpTimer, self.RespUpTimer, self)
    PeakMgr.eEndTimer[func](PeakMgr.eEndTimer, self.RespEndTimer, self)
    PeakMgr.eBoxRed[func](PeakMgr.eBoxRed, self.RespBoxFlag, self)
end

function My:RespShowRed(isShow)
    if isShow == true then
        SystemMgr:ShowActivity(ActivityMgr.JJD)
    elseif isShow == false then
        SystemMgr:HideActivity(ActivityMgr.JJD)
    end
end

--响应更新倒计时
function My:RespUpTimer(time)
    local time = tonumber(time)
    SystemMgr:ShowActivity(ActivityMgr.JJD)
    self.timerLab.gameObject:SetActive(time > 0)
	self.timerLab.text = DateTool.FmtSec(time, 3, 2)
end

--响应结束倒计时
function My:RespEndTimer()
    SystemMgr:HideActivity(ActivityMgr.JJD)
    self.timerLab.gameObject:SetActive(false)
end

--仙峰论剑宝箱奖励
function My:RespBoxFlag()
    local redTab = PeakMgr.ReBoxRed
    for k,v in pairs(redTab) do
        if redTab[k] ~= nil then
            SystemMgr:ShowActivity(ActivityMgr.JJD)
            break
        end
    end
    SystemMgr:HideActivity(ActivityMgr.JJD)
end

--清理缓存
function My:Clear()
	self.timerLab = nil
end
    
--释放资源
function My:Dispose()
    self:SetLnsr("Remove")
	self:Clear()
end

return My