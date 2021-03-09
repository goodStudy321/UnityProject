--[[
 	author 	    :Loong
 	date    	:2018-01-19 16:34:04
 	descrition 	:符文信息
--]]

RuneInfo = Super:New{Name = "RuneInfo"}

local My = RuneInfo

function My:Ctor()
  --唯一ID
  self.uid = 0

  --等级配置id
  self.lvid = 0

  --槽位
  self.sIdx = 0

  --等级配置
  self.lvCfg = nil

end

function My:SetLvID(id, bid)
  self.lvid = id
  self.lvCfg = BinTool.Find(RuneLvCfg, id)
  if bid == nil then return end
  self.cfg = RuneCfg[tostring(bid)]
end


function My:Dispose()
  self.uid = 0
  self.lvid = 0
  self.sIdx = 0
  self.cfg = nil
  self.lvCfg = nil
end

return My
