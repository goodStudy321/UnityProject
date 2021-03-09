--[[
 	authors 	:Loong
 	date    	:2017-08-23 16:27:56
 	descrition 	:神兵皮肤模块
--]]


UIAdvSkin = Super:New{Name = "UIAdvSkin"}

local My = UIAdvSkin
local pre = "UI/Adv/UIAdv"

--模型模块
My.model = require(pre .. "Mod")
--精炼模块
My.refine = require(pre .. "Refine")


function My:Init(root)
  self.root = root
  self.gbj = root.gameObject
  local CG = ComTool.Get
  local des = self.Name
  local USBC = UITool.SetBtnClick

  local TF = TransTool.Find
  self.prop = self.cntr.prop

  local SetSub = UIMisc.SetSub
  SetSub(self, self.refine, "refine", true)
  self.model.modRoot = self.modRoot
  SetSub(self, self.model, "mods", true)
  self.equipBtn = TF(root,"tranBtn",des)
  self.alFlag = TF(root,"alFlag",des)
  self.skinChangeBox = CG(BoxCollider, root, "tranBtn", des)
  USBC(root, "tranBtn", des, self.ReqChange, self)
  self.tranLbl = CG(UILabel, root, "tranBtn/lbl", des)
  PropMgr.eUpdate:Add(self.AdvStep, self)
end

function My:GetPropCfg ()
  local info, cCfg, nCfg = self.db.info, nil, nil
  if info.lock then
    nCfg = info.sCfg
  else
    cCfg = info.sCfg
    nCfg = info:GetNextCfg()
  end
  return cCfg, nCfg
end

function My.GetPropTitle(cfg)
  return UIMisc.GetStep(cfg.st)
end

--切换到升级界面
function My:SwitchUpg()
  self.cntr:Switch(self.cntr.upg)
end


--进阶/升星
function My:AdvStep()
  local db = self.db
  if db == nil or db.sysID == 2 then
    return
  end
  local icfg = db.iCfg
  local k,it,info = nil,nil,nil
  self.model.skinBtnRed = false
  self.model.isSkinFull = true
  for i, v in pairs(icfg) do
    k = tostring(v.id)
    info = db.dic[k]
    it = self.model.itDic[k]
    if it == nil then
      return
    end
    local bId = v.id
    local propId = AdvMgr.GetPIdByBId(bId)
    local propNum = PropMgr.TypeIdByNum(propId)
    self.model:SetInitAction(v,it,info,propNum)
  end
  db.eSkinRedS(self.model.skinBtnRed)
  db.flag.isFullSkin = self.model.isSkinFull
  db.flag:Update()
  self.refine:AdvStep()
end

--响应精炼
function My:RespRefine(id, unlock)
  self.prop:Refresh()
  self:SetFight()
  self.refine:RespRefine(id, unlock)
  self.model:RespRefine(id, unlock)
  self.rCntr:Lock(false)
  if(unlock == true) then
    local id = AssetTool.GetSexModID(self.db.info.bCfg)
    UIShowGetCPM.OpenCPM(id)
  end
end

--响应幻化
function My:RespChange(err)
  self.rCntr:Lock(false)
  if err > 0 then return end
  self:SetTranLbl()
end

function My:ReqChange()
  local info = self.db.info
  if info.lock then
    UITip.Error("未解锁")
  elseif self:IsChange() == true then
    return
  else
    self.rCntr:Lock(true)
    self.db:ReqChange(info.sCfg.id)
  end
  --print("皮肤模块请求幻化:", self.cfg.id)
end

--设置幻化标签
function My:SetTranLbl()
  local isShow = self:IsChange()
  local str = ((isShow == true) and "已装备" or "幻化")
  self:IsShowAlFlag(isShow)
  self.tranLbl.text = str
end

function My:IsShowAlFlag(isShow)
  self.equipBtn.gameObject:SetActive(not isShow)
  self.alFlag.gameObject:SetActive(isShow)
end

function My:IsChange()
  local db = self.db
  if db.chgID == db.info.sCfg.id then return true end
  return false
end

--切换条目信息
function My:Switch(info)
  local db = self.db
  info = info or db.info
  db.info = info
  local bCfg = info.bCfg
  self.cntr:SetName(bCfg.name)
  local at = ((bCfg == db.upgCfg) and true or false)
  local upg = self.cntr.upg
  if at then
    upg:ResetProps()
    upg:SetFight()
  else
    self:ResetProps()
    self:SetFight()
  end
  local UA = UIMisc.SetActive
  UA(self.refine, not at)
  self:SetTranLbl()
  self.refine:Refresh()
end

function My:Refresh()
  local db = self.db
  self.model:Refresh()
end

--重新设置属性列表
function My:ResetProps()
  local prop = self.prop
  prop.srcObj = self
  prop.GetCfg = self.GetPropCfg
  prop:SetNames(self.db.skinPropNames)
  prop:Refresh()
end

function My:SetFight()
  local cfg = self.db.info.sCfg
  local names = self.prop.names
  local ft = PropTool.GetFight(cfg, names)
  self.cntr:SetFight(ft)
end

function My:Update()

end

function My:SetLsnr(fn)
  local db = self.db
  db.eStep[fn](db.eStep, self.AdvStep, self)
  db.eRespRefine[fn](db.eRespRefine, self.RespRefine, self)
end

function My:Open()
  self:SetActive(true, "Add")
  self:SetLsnr("Add")
end

function My:Close()
  self:SetActive(false, "Remove")
  self:SetLsnr("Remove")
end

function My:Reset()
  self.model:Reset()
end

function My:SetActive(at, funcName)
  local SA = UIMisc.SetActive
  SA(self.model, at)
  SA(self.refine, at)
  self.gbj:SetActive(at)
  self.rCntr:SetTogActive(not at)
  local cpui = self.rCntr.cpui
  if cpui == nil then return end
  local ebc = cpui.eBlockClose
  if ebc == nil then return end
  ebc[funcName](ebc, self.SwitchUpg, self)
end

function My:Dispose()
  PropMgr.eUpdate:Remove(self.AdvStep, self)
  self.model:Dispose()
  self.refine:Dispose()
end

return My
