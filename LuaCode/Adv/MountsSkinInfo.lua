--[[
 	author 	    :Loong
 	date    	:2018-01-11 20:36:46
 	descrition 	:坐骑皮肤信息
--]]

MountsSkinInfo = Super:New{Name = "MountsSkinInfo"}

local My = MountsSkinInfo

function My:Ctor()
  self:Reset()

  --模型ID
  self.uMod = 0
  --名称
  self.name = ""

  --技能ID列表
  self.skiIDs = {}
  --用来判断技能是否解锁
  --k:技能ID,v:模块等级
  self.skiDic = {}
end

--添加技能ID
function My:AddSki(id, skiID)
  if skiID == nil then return end
  self.skiIDs[#self.skiIDs + 1] = skiID
  local k = tostring(skiID)
  self.skiDic[k] = id
end

--获取下一阶配置
function My:GetNextCfg()
  local nID = self.cfg.id + 1
  local nCfg = BinTool.Find(MountSkinCfg, nID)
  nCfg = nCfg or self.cfg
  return nCfg
end

function My:Reset()
  --进阶模块配置
  self.cfg = nil
  --未激活
  self.lock = true
end

function My:Clear()
  self:Reset()
end

function My:Dispose()
  ListTool.Clear(self.skiIDs)
  TableTool.ClearDic(self.skiDic)
end

return My
