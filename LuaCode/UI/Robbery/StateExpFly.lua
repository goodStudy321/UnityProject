StateExpFly = Super:New{Name = "StateExpFly"}
local My = StateExpFly

function My:Init(go)
	self.Root = go
	local trans = go.transform
	local CG = ComTool.Get
	local TFC = TransTool.FindChild
	self.tweenPos = CG(TweenPosition,trans,"Exp")
	self.expLab = CG(UILabel, trans,"Exp")
	self:SetTweenCall()
end

function My:SetTweenCall()
    self.OnPlayTweenCallback = EventDelegate.Callback(self.OnTweenFinished, self)
	EventDelegate.Add(self.tweenPos.onFinished, self.OnPlayTweenCallback)
end

function My:OnTweenFinished()
	self.expLab.gameObject:SetActive(false)
end

function My:ForwardPos()
	self:UpdateFlyExp()
	self.expLab.gameObject:SetActive(true)
	self.tweenPos:PlayForward()
end


function My:ReverPos()
	self.tweenPos:ResetToBeginning()
	-- self.expLab.gameObject:SetActive(false)
end

function My:UpdateFlyExp()
	-- local exp = PrayMgr.curCloseExp
	local exp = PrayMgr:GetTotalExp()
	if exp == nil then
		exp = 0
	end
	local tAdd = PrayMgr.totalAdd
	self.expLab.text = string.format("经验 +%s (+%s%s)",exp,tAdd,"%")
end

function My:Dispose()
	if self.OnPlayTweenCallback then
        EventDelegate.Remove(self.tweenPos.onFinished, self.OnPlayTweenCallback)
        self.OnPlayTweenCallback = nil
    end
	TableTool.ClearUserData(self)
end
