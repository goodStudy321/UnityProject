--[[
 	authors 	:Liu
 	date    	:2018-8-31 10:25:00
 	descrition 	:成就展示界面
--]]

UISuccessShow = UIBase:New{Name = "UISuccessShow"}

local My = UISuccessShow

-- 重写基类的初始化方法
function My:InitCustom()
	local root, des = self.root, self.Name
	local CG, ED = ComTool.Get, EventDelegate
	
	self.tween = CG(TweenAlpha, root, "bg4")
	self.alpha = CG(UISprite, root, "bg4")
	self.scoreLab = CG(UILabel, root, "bg4/lab1")
	self.nameLab = CG(UILabel, root, "bg4/lab3")

	ED.Add(self.tween.onFinished, ED.Callback(self.Complete, self))
	self:Begin()
end

--开始播放动画
function My:Begin()
	self.tween.delay = 0
	self.tween:PlayForward()
	self:SetLab()
end

--动画播放完成
function My:Complete()
	if self.alpha.color.a >= 0.95 then
		self.tween.delay = 0.3
		self.tween:PlayReverse()
	else
		self:IsPlayEnd()
	end
end

--是否播放结束
function My:IsPlayEnd()
	if SuccessInfo:IsPlayAnim() then
		self:Begin()
	else
		self:Close()
	end
end

--设置文本
function My:SetLab()
	local cfg = SuccessInfo:GetAnimData()
	if cfg == nil then
		iTrace.Error("成就配置错误")
		return
	end
	self.nameLab.text = cfg.name
	self.scoreLab.text = cfg.score
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清理缓存
function My:Clear()

end

--重写释放资源
function My:DisposeCustom()
	local ED = EventDelegate
	ED.Remove(self.tween.onFinished, ED.Callback(self.Complete, self))
	SuccessInfo:ResetAnimList()
	self:Clear()
end

return My