--[[
 	authors 	:Liu
 	date    	:2018-7-23 11:00:00
 	descrition 	:活动答题(按钮)
--]]

UIAnswerBtn = Super:New{Name = "UIAnswerBtn"}

local My = UIAnswerBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
	-- UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = AnswerMgr
	mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时
function My:RespUpTimer(time)
	local times = AnswerMgr.timer:GetRestTime()
	self.timerLab.text = DateTool.FmtSec(times, 3, 2)
	self.timerLab.gameObject:SetActive(times > 0)
end

--响应结束倒计时
function My:RespEndTimer()
	local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.HDDT)
	mgr:Remove(v)
end

-- --点击按钮
-- function My:OnClick()
--     SceneMgr:ReqPreEnter(30006, true, true)
-- end

--清理缓存
function My:Clear()
	
end
    
--释放资源
function My:Dispose()
	self:SetLnsr("Remove")
	self:Clear()
end

return My