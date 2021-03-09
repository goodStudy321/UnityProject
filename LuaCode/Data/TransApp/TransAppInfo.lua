TransAppInfo = Super:New{Name = "TransAppInfo"}

local My = TransAppInfo

function My:Ctor()
  self:Reset()
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

  self.sCfg = nil
  --基础配置条目
  self.bCfg = nil
  --皮肤配置
  self.skinCfg = nil
end

function My:Dispose()
  self:Reset()
end

return My
