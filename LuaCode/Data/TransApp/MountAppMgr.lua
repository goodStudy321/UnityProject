MountAppMgr = TransAppMgr:New{Name = "MountAppMgr"}
local My = MountAppMgr
local base = TransAppMgr

function My:Init()
  self.iCfg = MountChangeCfg
  self.iSkinCfg = MountChangeLvCfg
  self.iItemsIds = ItemsCfg[5].ids
  self.tcInfoID = 20270
  -- self.tcSkinID = 20284111
  self.tcChgID = 20276
  self.tsChgID = 20275

  -- self.tcChgID = 20298
  -- self.tsChgID = 20297
  self.tcASkinID = 24052
  self.tsASkinID = 24051
  self.tcStepID = 24054
  self.tsStepID = 24053
  self.sysId = 1
  self.chgID = 0
  base.Init(self)
end

function My:GetFight()
  do return User.MapData:GetFightValue(8) end
end

return My
