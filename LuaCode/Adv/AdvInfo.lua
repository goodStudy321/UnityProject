--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-24 16:03:20
-- 养成信息
--==============================================================================

AdvInfo = Super:New{Name = "AdvInfo"}

local My = AdvInfo

function My:Ctor()
  self:Reset()
end

--获取法宝下一阶配置
function My:GetMwNextCfg(sCfg, skinCfg, num)
  local plus = num or 1
  local nID = sCfg.id + plus
  local nCfg = BinTool.Find(skinCfg, nID)
  nCfg = nCfg or sCfg
  local val = (nCfg.type==1) and nCfg.lv or nCfg.step
  local lv = (nCfg.id==sCfg.id) and val or val
  local isFull = (nCfg.id==sCfg.id) and true or false
  return nCfg, lv,isFull
end

--获取下一阶配置
function My:GetNextCfg()
  local nID = self.sCfg.id + 1
  local nCfg = BinTool.Find(self.skinCfg, nID)
  nCfg = nCfg or self.sCfg
  return nCfg
end

function My:Reset()
  --当前经验
  self.exp = 0
  --true:未解锁
  self.lock = true
end

function My:Dispose()
  self:Reset()
  --皮肤配置条目
  self.sCfg = nil
  --基础配置条目
  self.bCfg = nil
  --皮肤配置
  self.skinCfg = nil
end

return My
