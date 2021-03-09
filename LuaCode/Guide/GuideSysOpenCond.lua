--[[
 	author 	    :Loong
 	date    	:2018-02-05 19:23:12
 	descrition 	:系统开启条件
              1，指定系统开启时,达成条件
--]]

GuideSysOpenCond = GuideCond:New{Name = "GuideSysOpenCond"}

local My = GuideSysOpenCond
local base = GuideCond

function My:Init()
  OpenMgr.eOpenFxComplete:Add(self.LsnrOpen, self)
end

--监听系统开启
--id:开放系统ID
--t:0上线推送,1:更新推送
function My:LsnrOpen(id)
  local k = tostring(id)
  local cfg = self.dic[k]
  self:Trigger(k, cfg)
end

--检查是否开启
function My:CheckOpen()
  local k = tostring(self.cfg.tArg)
  local suc = OpenMgr:IsOpen(k)
  return suc
end

function My:Dispose()
  base.Dispose(self)
  OpenMgr.eOpen:Remove(self.LsnrOpen, self)
end


return My
