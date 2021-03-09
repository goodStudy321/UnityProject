--[[
  AU  : Loong
  TM  : 2017-11-09T08:55:58.649Z
  DES : 刷新界面
--]]

UIRefresh = UIBase:New{Name = "UIRefresh"}
AM = Loong.Game.AssetMgr

local My = UIRefresh

My.manual = false

function My:InitCustom()
  self.circleGo = TransTool.FindChild(self.root, "circle", self.Name)
  self.circleGo:SetActive(false)
end

function My:CanRecords()
  do return false end
end

function My:SetCircleActive(at)
  at = at or false
  self.circleGo:SetActive(at)
end

--全局初始化
function My.gInit()
  AssetTool.eStart:Add(My.gOpen)
  AssetTool.eComplete:Add(My.gClose)
end

--全局开关
function My.gOpen()
  if My.manual then return end
  local uat = UILoading.active
  if uat and (uat == 1) then return end
  UIMgr.Open(My.Name)
end

--全局关闭
function My.gClose()
  if My.manual then return end
  UIMgr.Close(My.Name)
end

return My
