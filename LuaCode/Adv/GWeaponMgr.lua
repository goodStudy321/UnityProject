--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-17 10:45:40
-- 神兵管理器
--==============================================================================

GWeaponMgr = AdvMgr:New{Name = "GWeaponMgr"}
local My = GWeaponMgr
local base = AdvMgr

function My:Init()
  self.iCfg = GWCfg
  self.iLvCfg = GWLvCfg
  self.iSkinCfg = GWSkinCfg
  self.iQualCfg = GWQualCfg
  self.itemIDs = ItemsCfg[1].ids
  self.tcInfoID = 20220
  self.tcSoulID = 20230
  self.tcSkinID = 20222
  self.tcUpgID = 20228
  self.tcChgID = 20224
  self.tsChgID = 20223

  self.Simple = "神兵"
  My.sysID = 4
  base.Init(self)
end

function My:GetFight()
  do return User.MapData:GetFightValue(11) end
end

return My
