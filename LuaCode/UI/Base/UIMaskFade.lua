--region UIMaskFade.lua
--Date
--此文件由[HS]创建生成

UIMaskFade = UIBase:New{Name = "UIMaskFade"}
local M = UIMaskFade

function M:InitCustom()
	self:SetPersist(true)
	local name = self.Name
	local trans = self.root
	local C = ComTool.Get
	self.Fades =  C(UIPlayTween, trans, "Mask",name)
	self.alpha = C(TweenAlpha, trans, "Mask",name)
	self.timer = iTimer:New()
	self.timer.complete:Add(self.Close,self)
	self:AddEvent()
end

function M:FadeIn()
	self.Fades:Play(true)
end

function M:FadeOut()
	self.Fades:Play(false)
	self.timer:Start(self.alpha.duration)
end

function M:AddEvent()
	local Add,EH = EventMgr.Add, EventHandler
	Add("UIMaskFadeIn", EH(self.FadeIn, self))
	Add("UIMaskFadeOut", EH(self.FadeOut, self))
end

function M:RemoveEvent()
	local Remove,EH = EventMgr.Remove, EventHandler
	Add("UIMaskFadeIn", EH(self.FadeIn, self))
	Add("UIMaskFadeOut", EH(self.FadeOut, self))
end


function M:OpenCustom()
	
end

function M:CloseCustom()
	self:ResetFade()
	self:Clean()
end

function M:ResetFade()
	--local fades = self.Fades
	--fades:ResetToBeginning()
	--fades.enabled = true
end

--是否能被记录
function M:CanRecords()
	do return false end
end

function M:ConDisplay()
	do return true end
end

function M:Clean()
end

function M:DisposeCustom()
	self:RemoveEvent()
end

function M:Update()
end

return M
--endregion
