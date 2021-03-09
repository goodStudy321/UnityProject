--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-17 14:39:34
-- 翅膀管理器
--==============================================================================

WingMgr = AdvMgr:New{Name = "WingMgr"}
local My = WingMgr
local base = AdvMgr

function My:Init()
  self.iCfg = WingCfg
  self.iLvCfg = WingLvCfg
  self.iSkinCfg = WingSkinCfg
  self.iQualCfg = WingQualCfg
  self.itemIDs = ItemsCfg[3].ids
  self.tcInfoID = 20240
  self.tcSoulID = 20248
  self.tcSkinID = 20242
  self.tcUpgID = 20246
  self.tcChgID = 20244
  self.tsChgID = 20243

  self.Simple = "翅膀"
  My.sysID = 5

  base.Init(self)
end

function My:GetFight()
  do return User.MapData:GetFightValue(12) end
end

return My
