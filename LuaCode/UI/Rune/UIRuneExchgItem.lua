--[[
 	author 	    :Loong
 	date    	:2018-01-22 12:28:39
 	descrition 	:UI符文兑换条目
--]]
require("UI/Rune/UIRuneItem")

UIRuneExchgItem = UIRuneItem:New{Name = "UIRuneExchgItem"}

local My = UIRuneExchgItem

function My:InitCustom()
  local exchgCfg = self.exchgCfg
  local lvid = exchgCfg.id

  local bid = RuneMgr.GetBaseID(lvid)
  local cfg = RuneCfg[tostring(bid)]
  if cfg == nil then return end
  self.cfg = cfg
  lvCfg = self.lvCfg
  local des = self.Name
  local root = self.root
  local CG = ComTool.Get

  --消耗标签
  self.conLbl = CG(UILabel, root, "con", des)
  self.tipLbl = CG(UILabel, root, "tip", des)
  self:SetConColor()
  --属性标签
  local propLbl = CG(UILabel, root, "prop", des)
  propLbl.text = self:GetPropStr(cfg, lvCfg)

  AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
  self:SetName(cfg.name)
  self:SetQual(cfg.qt)
  self:SetTip(exchgCfg.tID)
  self:SetLv(cfg, lvCfg)
  self:Refresh()
end

function My:SetTip(id)
  local cfg = CopyTemp[tostring(id)]
  if cfg == nil then
    self.tipLbl.text = ""
  else
    local ly = id - 40000
    local pass = CopyMgr:IsFinishCopy(id)
    local cc = nil
    if pass then
      cc = ColorCode.lightYellow
    else
      cc = ColorCode.red
    end
    local str = cc .. "通关九九窥星塔" .. ly .. "层解锁"
    self.tipLbl.text = str
  end
end

function My:SetConColor()
  local cc = nil
  if RuneMgr.piece < self.exchgCfg.con then
    cc = ColorCode.red
  else
    cc = ColorCode.lightYellow
  end
  self.conLbl.text = cc .. self.exchgCfg.con
end

function My:Refresh()
  self:SetConColor()
end

function My:DisposeCustom()
  AssetMgr:Unload(self.cfg.icon, false)
  self.cfg = nil
  self.lvCfg = nil
  self.exchgCfg = nil
end

return My
