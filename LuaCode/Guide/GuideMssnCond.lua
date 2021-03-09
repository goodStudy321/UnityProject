--[[
 	author 	    :Loong
 	date    	:2018-02-05 19:22:54
 	descrition 	:任务条件
              1,任务的ID等于配置ID时
--]]

GuideMssnCond = GuideCond:New{Name = "GuideMssnCond"}

local My = GuideMssnCond
local base = GuideCond

function My:Init()
  MissionMgr.eCleanMission:Add(self.LsnrMssn, self)
end

--监听任务完成
function My:LsnrMssn(id)
  local k = tostring(id)
  local cfg = self.dic[k]
  self:Trigger(k, cfg)
end

--检查任务是否完成
function My:CheckMssn()
  local tid = self.cfg.tArg
  local suc = MissionMgr:CheckComplete(tid)
  return suc
end


function My:Dispose()
  base.Dispose(self)
  MissionMgr.eCleanMission:Remove(self.LsnrMssn, self)
end


return My
