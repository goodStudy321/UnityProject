--[[
 	authors 	:Liu
 	date    	:2019-6-24 20:00:00
 	descrition 	:特惠礼包(按钮)
--]]

UIDiscountGiftBtn = Super:New{Name = "UIDiscountGiftBtn"}

local My = UIDiscountGiftBtn

function My:Init(root)
	self.timerLab = ComTool.Get(UILabel, root, "Root/ActTimerLab")
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = DiscountGiftMgr
	mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	-- mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时
function My:RespUpTimer(remain, time)
	self.timerLab.text = remain
	self.timerLab.gameObject:SetActive(time > 0)
end

-- --响应结束倒计时
-- function My:RespEndTimer()
-- 	local mgr = ActivityMgr
-- 	local k,v = mgr:Find(mgr.THLB)
-- 	mgr:Remove(v)
-- end

--清理缓存
function My:Clear()
	
end
    
--释放资源
function My:Dispose()
    self.timerLab.gameObject:SetActive(false)
	self:SetLnsr("Remove")
	self:Clear()
end

return My