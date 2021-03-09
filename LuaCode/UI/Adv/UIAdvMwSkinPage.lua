UIAdvMwSkinPage = Super:New{Name = "UIAdvMwSkinPage"}

local My = UIAdvMwSkinPage

local pre = "UI/Adv/UIAdvMw"

My.mwSkinProp = require(pre .. "Prop")
My.mwLvShow = require(pre .. "LvShow")
My.mwStShow = require(pre .. "StShow")
My.mwCom = require(pre .. "Com")
My.mwMods = require(pre .. "Mods")


function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local modRoot = self.rCntr.modRoot

  local SetSub = UIMisc.SetSub
  SetSub(self, self.mwSkinProp, "mwprops", true)
  SetSub(self, self.mwLvShow, "mwLvShow", true)
  SetSub(self,self.mwStShow,"mwStShow",true)
  SetSub(self,self.mwCom,"mwcom",true)
  SetSub(self,self.mwMods,"mods",true)

  self.modRoot = modRoot
  self.skill = self.cntr.skll
  self.isCanShowPanel = self.cntr.isCanShowPanel
end

--切换item
function My:Switch(info, db)
  local cfg = info.sCfg
  if info.sCfg.type == 1 then
    self:OpenLvMenu()
    local lvCfg = AdvMgr.mwLvSkinCfg or info.sCfg
    local curExp = AdvMgr.mwExp or info.exp
    self.mwCom:UpShow(lvCfg, db, info.lock)
    self.mwSkinProp:UpShow(lvCfg, db, info.lock)
    self.mwLvShow:UpShow(lvCfg, db, info.lock, curExp)
  else
    self:OpenStMenu()
    self.mwCom:UpShow(cfg, db, info.lock)
    self.mwSkinProp:UpShow(cfg, db, info.lock)
    self.mwStShow:UpShow(cfg, db, info.lock)
  end
end

--===================================================================


function My:Update()
  self.mwLvShow:Update()
end

function My:Open()
  self.go:SetActive(true)
  self:SetLsnr("Add")
  self.cntr:UpPageState(false)
  self.rCntr:SetTogActive(false)
  self.rCntr.prop:UpShow(false)
  self.mwMods:Open()
  self.mwCom:Open()
  -- self.mwStShow:Open()
  -- self.mwLvShow:Open()
  self.mwSkinProp:Open()
end

function My:Close()
  self.go:SetActive(false)
  self:SetLsnr("Remove")
  self.cntr:UpPageState(true)
  self.rCntr:SetTogActive(true)
  self.rCntr.prop:UpShow(true)
  self.mwMods:Close()
  self.mwCom:Close()
  self.mwStShow:Close()
  self.mwLvShow:Close()
  self.mwSkinProp:Close()
end

--刷新
function My:Refresh()
  
end

--响应更新数据
function My:RespRefine(id, unlock, exp)
  local db = self.db
  local cfg = BinTool.Find(db.info.skinCfg, id)
  local bid = math.floor(AdvMgr.GetBID(id) * 0.1)
  -- local bCfg = BinTool.Find(MWCfg, tonumber(bid))
  local bCfg = nil
  for i,v in ipairs(MWCfg) do
      if v.id == bid then
          bCfg = v
      end
  end

  if exp then
    AdvMgr.mwExp = exp
    AdvMgr.mwLvSkinCfg = cfg
  end
  if cfg.type == 1 then
    self:OpenLvMenu()
    local lvCfg = AdvMgr.mwLvSkinCfg or cfg
    local curExp = AdvMgr.mwExp or exp
    self.mwCom:UpShow(lvCfg, db, false)
    self.mwSkinProp:UpShow(lvCfg, db, false)
    self.mwLvShow:UpShow(lvCfg, db, false, curExp)
  else
    self:OpenStMenu()
    self.mwCom:UpShow(cfg, db, false)
    self.mwSkinProp:UpShow(cfg, db, false)
    self.mwStShow:UpShow(cfg, db, false)
  end
  self.mwMods:RespRefine(id)
  self.cfg = cfg

  if bCfg and unlock == true then
    local id = AssetTool.GetSexModID(bCfg)
    UIShowGetCPM.OpenCPM(id)
  end
end

function My:OpenLvMenu()
  self.mwStShow:Close()
  self.mwLvShow:Open()
end

function My:OpenStMenu()
  self.mwLvShow:Close()
  self.mwStShow:Open()
end

--响应幻化
function My:RespChange()
  self.mwCom:SetBtnState(false)
end

function My:SetLsnr(fn)
  local db = self.db
  db.eRespRefine[fn](db.eRespRefine, self.RespRefine, self)
  db.eRespChange[fn](db.eRespChange, self.RespChange, self)
  PropMgr.eUpdate[fn](PropMgr.eUpdate, self.RespUpItem, self)
  -- PropMgr.eUpdate:Add(self.RespUpItem, self)
end

function My:RespUpItem()
    self.mwStShow:UpCellCount(false)
    self.mwLvShow:UpCellCount(false)
    if self.cfg then
      self.mwMods:SetAction(self.cfg, false)
      self.cfg = nil
    end
end

function My:Reset()
  self.mwMods:Reset()
end

function My:Dispose()
  -- PropMgr.eUpdate:Remove(self.RespUpItem, self)
  UIMisc.ClearSub(self)

  self.mwMods:Dispose()
  self.mwCom:Dispose()
  self.mwStShow:Dispose()
  self.mwSkinProp:Dispose()
  self.mwLvShow:Dispose()

  TableTool.ClearUserData(self)
end

return My
