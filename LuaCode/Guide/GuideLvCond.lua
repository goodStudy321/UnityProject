--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-05 19:22:37
-- 1，角色等级等于配置等级时
--=========================================================================


GuideLvCond = GuideCond:New{Name = "GuideLvCond"}

local My = GuideLvCond
local base = GuideCond

function My:Init()
  UserMgr.eLvEvent:Add(self.LsnrLv, self)
  SceneMgr.eChangeEndEvent:Add(self.ChkLv, self)
end

--切换场景时监听
function My:ChkLv(isLoad)
  local roleLv = UserMgr:GetRealLv()
  if roleLv == 1 then
    local k = tostring(roleLv)
    local cfg = self.dic[k]
    self:Trigger(k, cfg)
    SceneMgr.eChangeEndEvent:Remove(self.ChkLv, self)
  elseif roleLv > 1 then
    SceneMgr.eChangeEndEvent:Remove(self.ChkLv, self)
  end
end

--角色等级不足时,监听等级变化
function My:LsnrLv()
  local roleLv = UserMgr:GetRealLv()
  local k = tostring(roleLv)
  local cfg = self.dic[k]
  self:Trigger(k, cfg)
end

--检查角色等级是否>=配置等级
function My:CheckLv()
  local roleLv = UserMgr:GetRealLv()
  local lv = self.cfg.tArg or 0
  if lv <= roleLv then
    return true
  else
    return false
  end
end

function My:Dispose()
  base.Dispose(self)
  UserMgr.eLvEvent:Remove(self.LsnrLv, self)
end

return My
