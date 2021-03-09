PetAppMgr = TransAppMgr:New{Name = "PetAppMgr"}
local My = PetAppMgr
local base = TransAppMgr

function My:Init()
  self.iCfg = PetChangeCfg
  self.iSkinCfg = PetChangeLvCfg
  self.iItemsIds = ItemsCfg[4].ids
  self.tcInfoID = 20286
  self.tcSkinID = 20284
  
  self.tcChgID = 20298
  self.tsChgID = 20297
  self.tcASkinID = 24002
  self.tsASkinID = 24001
  self.tcStepID = 24004
  self.tsStepID = 24003
  self.sysId = 2
  self.chgID = 0
  base.Init(self)
end

function My:GetFight()
  do return User.MapData:GetFightValue(10) end
end

return My
