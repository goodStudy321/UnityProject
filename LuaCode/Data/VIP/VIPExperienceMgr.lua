--[[
 	authors 	:Liu
 	date    	:2018-8-28 15:00:00
 	descrition 	:VIP体验管理
--]]

VIPExperienceMgr = {Name = "VIPExperienceMgr"}

local My = VIPExperienceMgr

function My:Init()
	self.id = 210004
	self:SetLnsr("Add")
	self.isOpen = false
	local EH = EventHandler
	local EA = EventMgr.Add
	self.MssnEnd = EH(self.RespMssnEnd, self)
    EA("MssnEnd", self.MssnEnd)
end

--设置监听
function My:SetLnsr(func)
	VIPMgr.eVIPStart[func](VIPMgr.eVIPStart, self.RespVIPStart, self)
	VIPMgr.eVIPEnd[func](VIPMgr.eVIPEnd, self.RespVIPEnd, self)
	VIPMgr.eBuy[func](VIPMgr.eBuy, self.RespVIPBuy, self)
end

--响应任务结束
function My:RespMssnEnd(id)
	local cfg = GlobalTemp["106"]
	if cfg == nil then return end
	if id == cfg.Value2[2] then
		UIMgr.Open(UIVIPExperience.Name)
	end
end

--响应VIP体验开始
function My:RespVIPStart()
	if not VIPMgr.isExpire then self:HideVipTip() return end
	VIPMgr.eVIPTime:Add(self.UpTimer, self)
end

--更新计时器
function My:UpTimer()
	self:ShowVipTip(true)
end

--响应VIP体验倒计时结束
function My:RespVIPEnd()
	self:HideVipTip()
end

--响应VIP购买
function My:RespVIPBuy()
	if VIPMgr.isExpire or VIPMgr.GetVIPLv() ==0 then return end
	self:HideVipTip()
end

--显示VIP体验提示
function My:ShowVipTip(state)
	local key = tostring(User.SceneId)
	local cfg = SceneTemp[key]
	if cfg == nil then return end
	local isShow = (cfg.maptype==1) and state
	local rTime = VIPMgr.timer:GetRestTime()
	local time = DateTool.FmtSec(rTime, 3, 1)
	local ui = UIMgr.Get(UIMainMenu.Name)
	local str = "[ccbead]VIP体验时间：[e9ac50]"..time.."[-]免费传送  [e9ac50]+30%经验"
    if ui then ui:UpVIPTip(isShow, str) end
end

--隐藏VIP体验提示
function My:HideVipTip()
	VIPMgr.eVIPTime:Remove(self.UpTimer, self)
	self:ShowVipTip(false)
end

--清理缓存
function My:Clear()
	self.isOpen = false
end
    
--释放资源
function My:Dispose()
	self:SetLnsr("Remove")
end

return My