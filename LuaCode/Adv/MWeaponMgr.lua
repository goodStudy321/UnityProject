--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-17 10:45:17
-- 法宝管理器
--==============================================================================

MWeaponMgr = AdvMgr:New{Name = "MWeaponMgr"}
local My = MWeaponMgr
local base = AdvMgr

function My:Init()
  self.iCfg = MWCfg
  self.iLvCfg = MWLvCfg
  self.iSkinCfg = MWSkinCfg
  self.iQualCfg = MWQualCfg
  self.itemIDs = ItemsCfg[2].ids
  self.tcInfoID = 20250
  self.tcSoulID = 20258
  self.tcSkinID = 20252
  self.tcUpgID = 20256
  self.tcChgID = 20254
  self.tsChgID = 20253

  self.Simple = "法宝"
  My.sysID = 2

  base.Init(self)
end

function My:GetFight()
  do return User.MapData:GetFightValue(9) end
end

return My
