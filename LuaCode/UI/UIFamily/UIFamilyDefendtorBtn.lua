--[[
 	authors 	:Liu
 	date    	:2018-7-23 11:00:00
 	descrition 	:道庭守卫(按钮)
--]]

UIFamilyDefendtorBtn = Super:New{Name = "UIFamilyDefendtorBtn"}

local My = UIFamilyDefendtorBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/TimerLab")
	-- UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = FamilyActivityMgr
    mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时
function My:RespUpTimer(time, sec)
	self.timerLab.text = time
	self.timerLab.gameObject:SetActive(sec > 0)
end

--响应结束倒计时
function My:RespEndTimer()
	local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.XMSW)
	mgr:Remove(v)
end

-- --点击按钮
-- function My:OnClick()
-- 	-- ActvHelper.EnterFmlDft()
-- 	UIMgr.Open(UIFamilyDefendWnd.Name)
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