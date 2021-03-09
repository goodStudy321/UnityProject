--region UIMask.lua
--Date
--此文件由[HS]创建生成

UIMask = UIBase:New{Name = "UIMask"}

function UIMask:InitCustom()
	self.Persitent = true
	name = "可操作提示面板"
	local trans = self.root
	self.Mask = ComTool.Get(UISprite, trans, "Mask", name, false)
	self.PlayTween = self.Mask:GetComponent("UIPlayTween")
	self.Alpha = self.Mask:GetComponent("TweenAlpha")
	--UITool.SetTex(trans, "Mask", TexTool.Black, name)

	self.OnSetUIMaskAlpha = function (value) self:SetUIMaskAlpha(value) end

	self:AddEvent()
end

function UIMask:AddEvent()
	EventMgr.Add("SetUIMaskAlpha", self.OnSetUIMaskAlpha)
end

function UIMask:RemoveEvent()
	EventMgr.Remove("SetUIMaskAlpha", self.OnSetUIMaskAlpha)
end

--设置遮罩透明度
function UIMask:SetUIMaskAlpha(value)
	if not self.Mask then return end
	self.Mask.color.a = value
end

function UIMask:SetFadeOutData(duration, delay)
	self.Alpha.duration = duration
	self.Alpha.delay = delay
	self.PlayTween:Play(true)
end

function UIMask:SetFadeOut(value)
	if not self.PlayTween then return end
	self.PlayTween:Play(value)
end


function UIMask:OpenCustom()
	
end

function UIMask:CloseCustom()
	self:Clean()
end

function UIMask:Clean()
	if self.Mask then
		if self.Mask.color.a ~= 1 then self.Mask.color.a = 1 end
	end
end

function UIMask:DisposeCustom()
	self:RemoveEvent()
end

function UIMask:Update()
end

return UIMask
--endregion
