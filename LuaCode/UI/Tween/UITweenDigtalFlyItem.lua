--[[
 	authors 	:Loong
 	date    	:2017-08-25 17:50:11
 	descrition 	:飘字条目
--]]

UITweenDigtalFlyItem = Super:New{Name = "UITweenDigtalFlyItem"}

local My = UITweenDigtalFlyItem

My.go = nil

--容器
My.cntr = nil

--动画播放器
My.tween = nil

--标签
My.lbl = nil

function My:Init()
  local go = self.go
  self.tween = go:GetComponent(typeof(UIPlayTween))
  self.lbl = go:GetComponent(typeof(UILabel))
  self.PlayCbFunc = function() self:PlayCb() end
  local EC = EventDelegate.Callback
  EventDelegate.Add(self.tween.onFinished, EC(self.PlayCbFunc))
end

function My:Launch(arg)
  self.go:SetActive(true)
  self.tween:Play(true)
  self.go.name = "used"
  self.lbl.text = "+" .. arg
end

function My:PlayCb()
  self.go:SetActive(false)
  self.go.name = "unUsed"
  table.insert(self.cntr.items, self)
end
