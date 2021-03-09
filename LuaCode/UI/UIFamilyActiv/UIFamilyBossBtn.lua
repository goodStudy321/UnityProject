--[[
 	authors 	:Liu
 	date    	:2018-7-23 11:00:00
 	descrition 	:道庭Boss(按钮)
--]]

UIFamilyBossBtn = Super:New{Name = "UIFamilyBossBtn"}

local My = UIFamilyBossBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = FamilyBossMgr
    mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时
function My:RespUpTimer(time)
	self.timerLab.text = DateTool.FmtSec(time, 3, 2)
	self.timerLab.gameObject:SetActive(time > 0)
end

--响应结束倒计时
function My:RespEndTimer()
	local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.XMBS)
	mgr:Remove(v)
end

--清理缓存
function My:Clear()
	
end
    
--释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
end

return My