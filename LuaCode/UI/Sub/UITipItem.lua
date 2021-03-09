--[[
 	author 	    :Loong
 	date    	:2018-04-26 11:25:19
 	descrition 	:通用tips条目
--]]

UITipItem = Super:New{Name = "UITipItem"}


local My = UITipItem


function My:Init(go)
  self.go = go
  local root = go.transform
  self.root = root
  local des = self.Name
  self.alpha = ComTool.GetSelf(TweenAlpha, go, des)
  self.tipLbl = ComTool.Get(UILabel, root, "msg", des)
  TransTool.AddChild(UITip.none, root)
  local ED = EventDelegate
  local cb = ED.Callback(self.Complete, self)
  ED.Add(self.alpha.onFinished, cb)
end

--发射消息
function My:Launch(msg,time)
  self.root.parent = UITip.grid
  self.go:SetActive(true)
  self.alpha:ResetToBeginning()
  self.alpha:PlayForward()
  self.alpha.duration=time or 0.5 ;
  self.tipLbl.text = msg
end

--效果结束
function My:Complete()
  local spring = self.spring
  if spring == nil then
    spring = ComTool.GetSelf(SpringPosition, self.go, self.Name)
    self.spring = spring
  end
  if spring then
    spring.target = Vector3.zero
  end
  UITip.Add(self)
end

function My:SetActive(at)
  self.go:SetActive(at)
end

function My:Dispose()
  TableTool.ClearUserData(self)
end

return My
