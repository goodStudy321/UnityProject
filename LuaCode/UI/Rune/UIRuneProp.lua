--[[
 	author 	    :Loong
 	date    	:2018-01-25 19:39:36
 	descrition 	:
--]]

local UPI = require("UI/Cmn/UIPropItem")

UIRuneProp = Super:New{Name = "UIRuneProp"}

local My = UIRuneProp

function My:Init(root)
  self.root = root
  local des = self.Name
  local TF = TransTool.Find
  local tran1 = TF(root, "1", des)
  local tran2 = TF(root, "2", des)
  local p1 = ObjPool.Get(UPI)
  local p2 = ObjPool.Get(UPI)
  self.p1 = p1
  self.p2 = p2
  p1:Init(tran1)
  p2:Init(tran2)
  p1:SetActive(false)
  p2:SetActive(false)
end

function My:SetActive(at)
  self.p1:SetActive(at)
  self.p2:SetActive(at)
end

--设置属性
--cfg(RuneCfg条目)
--pn(string):属性 名称 字段
--vn(string):属性  值  字段
function My:SetProp(cfg, pn, vn)
  local lvCfg = self.lvCfg
  local prop = self[pn]
  local pid = cfg[pn]
  if pid then
    prop:SetActive(true)
    local cfg = BinTool.Find(PropName, pid)
    local name = cfg and cfg.name or ("无:" .. tostring(pid))
    prop:SetName(name)
    local val = lvCfg[vn]
    val = PropTool.GetVal(cfg, val)
    prop:SetCur(val)
  else
    prop:SetActive(false)
  end
end

--刷新
--id:基础ID
function My:RefreshByID(id)
  local lvCfg = self.lvCfg
  if lvCfg and (lvCfg.id == id) then return end
  lvCfg = BinTool.Find(RuneLvCfg, id)
  if lvCfg == nil then
    iTrace.Error("Loong", "符文等级表中未配置ID:" .. id)
  else
    local cfg = RuneCfg[tostring(id)]
    if cfg == nil then return end
    self.lvCfg = lvCfg
    self:SetProp(cfg, "p1", "v1")
    self:SetProp(cfg, "p2", "v2")
  end
end


function My:Dispose()
  self.lvCfg = nil
  ObjPool.Add(self.p1)
  ObjPool.Add(self.p2)
  self.p1 = nil
  self.p2 = nil
end

return My
