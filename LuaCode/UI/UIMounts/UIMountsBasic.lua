--[[
 	author 	    :Loong
 	date    	:2018-01-12 10:54:10
 	descrition 	:坐骑基础模块
--]]

UIMountsBasic = Super:New{Name = "UIMountsBasic"}
local My = UIMountsBasic
local Mm = MountsMgr
local sMgr = SystemMgr
local sTransMgr = MountAppMgr

local pre = "UI/UIMounts/UIMounts"

My.model = require("UI/UIMounts/UIMountsMod")

My.propNames = {}

function My:Init(root)
  self.root = root
  self.step = self.cntr.step
  self.prop = self.rCntr.prop
  self.skill = self.rCntr.skill

  PropTool.SetNames(MountStepCfg[1], self.propNames)
  local des = self.Name
  local USBC = UITool.SetBtnClick
  local model = self.model
  USBC(root, "lefBtn", des, model.SelectLast, model)
  USBC(root, "rigBtn", des, self.SelectNext, self)
  local mr = self.rCntr.modRoot
  model.rCntr = self.rCntr
  model.cntr = self
  model:Init(mr)
  --USBC(root, "skinBtn", des, self.SwitchSkin, self)
  local USC = UITool.SetLsnrClick
  local CG = ComTool.Get
  self.changBox = CG(BoxCollider, root, "tranBtn", des)
  self.chgLbl = CG(UILabel, root, "tranBtn/lbl", des)
  self.skinRed = TransTool.FindChild(root,"transBtn/red",des)
  self.equipBtn = TransTool.FindChild(root,"tranBtn",des)
  self.alFlag = TransTool.FindChild(root,"alFlag",des)
  USBC(root, "tranBtn", des, self.Change, self)
  USBC(root, "transBtn", des, self.Skins, self)
  self:SetFight()
  self:AddLsnr()
  self:SetFlag(Mm.flag.red)
  self:SetSkinRed()
end

function My:SelectNext()
  local mod = self.model
  local mid = mod.cur.cfg.id
  local bid = MountsMgr.bid
  local dif = mid - bid
  if dif < 1 then
    mod:SelectNext()
  elseif dif >= 1 then
    mod:SelectNext()
    -- UITip.Error("该阶坐骑还未解锁")
  -- elseif dif == 0 then
  --   UITip.Error("敬请期待")
  end
end

function My.GetCfg()
  local cCfg = Mm.curCfg
  local nID = cCfg.id + 1
  local nCfg = Mm.GetCfg(nID)
  nCfg = nCfg or cCfg
  return cCfg, nCfg
end

function My.GetPropTitle(cfg)
  local str = UIMisc.GetStep(cfg.st)
  return str
end

--设置战斗力
function My:SetFight()
  local ft = User.MapData:GetFightValue(8)
  self.cntr:SetFight(ft)
end

--设置皮肤按钮红点
function My:SetSkinRed()
  local isShowRed = MountAppMgr.isTransRed
  self.skinRed:SetActive(isShowRed)
end

function My:Update()
  self.step:Update()
end

function My:SetProp()
  self:Switch()
  self.prop:Refresh()
end

--打开资质面板
function My:OpenQual()
  local qual = self.rCntr.qual
  qual:Open()
  qual:Refresh(MountQualCfg, Mm.qualDic,Mm.flag)
end

function My:SetUnlock()

end

--切换模型信息
function My:Switch(cfg)
  if cfg == nil then
    cfg = BinTool.Find(MountCfg, Mm.bid)
  end
  if cfg==nil  then
    iTrace.Error("Loong","can not find mount baseid:",Mm.bid)
    cfg = MountCfg[1]
  end
  self.cntr:SetName(cfg.name)
  self.cntr:SetStep(cfg.st)
  local at = ((Mm.bid < cfg.id) and true or false)
  self.rCntr:SetUnlock(at)
  self.step:SetActive(not at)
  self:SetChgLbl(cfg)
end

function My:SetChgLbl(cfg)
  local str = nil
  self:IsShowAlFlag(false)
  if cfg.id == Mm.chgID then
    str = "已幻化"
    self:IsShowAlFlag(true)
  else
    str = "幻化"
  end
  self.chgLbl.text = str
end

function My:IsShowAlFlag(isShow)
  self.equipBtn:SetActive(not isShow)
  self.alFlag:SetActive(isShow)
end

function My:SetFlag(red)
  -- local value = SystemMgr:GetSystemIndex(6, Mm.sysID)
  local value = SystemMgr:GetActivityPage(ActivityMgr.YC,Mm.sysID)
  self.rCntr:SetFlag(Mm.sysID, value)
end

--幻化按钮点击事件
function My:Change(go)
  local id = self.model.cur.cfg.id
  if id > Mm.bid then
    UITip.Error("未解锁")
  elseif id == Mm.chgID then
    UITip.Log("已经幻化")
  else
    self.rCntr:Lock(true)
    MountsMgr.ReqChange(id)
  end
end

--皮肤
function My:Skins()
  JumpMgr:InitJump(UIAdv.Name,1)
  UITransApp.OpenTransApp(1)
end

function My:AddLsnr()
  self:SetLsnr("Add")
end

function My:RemoveLsnr()
  self:SetLsnr("Remove")
end

--设置监听
--fn(string):注册/注销名
function My:SetLsnr(fn)
  Mm.eUpStep[fn](Mm.eUpStep, self.UpStep, self)
  Mm.eUpStep[fn](Mm.eUpStar, self.UpStar, self)
  Mm.eRespInfo[fn](Mm.eRespInfo, self.RespInfo, self)
  Mm.eRespStep[fn](Mm.eRespStep, self.RespStep, self)
  Mm.eRespQual[fn](Mm.eRespQual, self.RespQual, self)
  Mm.eRespChange[fn](Mm.eRespChange, self.RespChange, self)
  MountAppMgr.eRespRed[fn](MountAppMgr.eRespRed, self.SetSkinRed, self)
  PropMgr.eUpdate[fn](PropMgr.eUpdate, self.UpdateProp, self)
end

function My:UpdateProp()
  self.step:ShowCostNum()
end

function My:RespInfo()
  self:SetProp()
  self:RespQual()
  self:RespStep()
end

--响应升阶
function My:RespStep(err)
  err = err or 0
  if err < 1 then
    self.step:RespStep()
  end
  self.rCntr:Lock(false)
end

--等阶提升
function My:UpStep()
  self.step:UpStep()
  self.model:SelectCur()
  self.skill:Refresh(Mm.skiIDs, Mm.GetSkiLock)
  local id = self.model.cur.cfg.id
  MountsMgr.ReqChange(id)
end

function My:UpStar()
  self.step:SetStar()
end

--响应资质提升
function My:RespQual()
  self:Switch()
  self.rCntr.qual:RespUpg()
  self.prop:Refresh()
  self.rCntr:Lock(false)
end

--响应幻化
function My:RespChange(err)
  if self.model.cur == nil then
    return
  end
  self.rCntr:Lock(false)
  if err == 0 then
    UITip.Log("幻化成功")
    self:SetChgLbl(self.model.cur.cfg)
  end
end

function My:ResetProps()
  local prop = self.prop
  prop.GetCfg = self.GetCfg
  prop.quaDic = Mm.qualDic
  prop.quaCfg = MountQualCfg
  prop:SetNames(self.propNames)
  prop:Refresh()
end

function My:Open()
  self:OpenQual()
  self.step.db = Mm
  self.step:Open()
  self:ResetProps()
  self.model:Open()
  self.model:SelectCur()
  self.skill:Open()
  self.skill:Refresh(Mm.skiIDs, Mm.GetSkiLock)
  FightVal.eChgFv:Add(self.SetFight, self)
  Mm.flag.eChange:Add(self.SetFlag, self)
  sMgr.eShowActivity:Add(self.SetFlag, self)
  sMgr.eHideActivity:Add(self.SetFlag, self)
end

function My:Close()
  self.step:Close()
  self.model:Close()
  self.rCntr.qual:Close()
  Mm.flag.eChange:Remove(self.SetFlag, self)
  FightVal.eChgFv:Remove(self.SetFight, self)
  sMgr.eShowActivity:Remove(self.SetFlag, self)
  sMgr.eHideActivity:Remove(self.SetFlag, self)
end

function My:Dispose()
  self:RemoveLsnr()
  self.model:Dispose()
  Mm.flag.eChange:Remove(self.SetFlag, self)
  FightVal.eChgFv:Remove(self.SetFight, self)
  sMgr.eShowActivity:Remove(self.SetFlag, self)
  sMgr.eHideActivity:Remove(self.SetFlag, self)
end

---[[和皮肤共享组件部分
--刷新
function My:Refresh()
  self:SetFight()
  self:ResetProps()
  self.step:Refresh()
  self.skill:Refresh(Mm.skiIDs, Mm.GetSkiLock)
end

--切换到皮肤模块
function My:SwitchSkin()
	self.cntr:Switch(self.cntr.skin)
end
--]]

return My
