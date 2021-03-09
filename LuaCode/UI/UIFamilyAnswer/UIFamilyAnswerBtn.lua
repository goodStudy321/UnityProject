--[[
 	authors 	:Liu
 	date    	:2018-7-23 11:00:00
 	descrition 	:道庭答题(按钮)
--]]

UIFamilyAnswerBtn = Super:New{Name = "UIFamilyAnswerBtn"}

local My = UIFamilyAnswerBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
	-- UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = FamilyAnswerMgr
	mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时
function My:RespUpTimer(remain, time)
	self.timerLab.text = remain
	self.timerLab.gameObject:SetActive(time > 0)
end

--响应结束倒计时
function My:RespEndTimer()
	local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.XMDT)
	mgr:Remove(v)
end

-- --点击按钮
-- function My:OnClick()
-- 	if CustomInfo:IsJoinFamily() then
--         UIMgr.Open(UIFamilyAnswerIt.Name)
--     end
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