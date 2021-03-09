UIThroneBasic = Super:New{Name = "UIThroneBasic"}
local My = UIThroneBasic
local Mm = ThroneMgr
local sMgr = SystemMgr
local sTransMgr = MountAppMgr

My.model = require("UI/UIThrone/UIThroneMod")

My.propNames = {}

function My:Init(root)
  self.root = root
  self.step = self.cntr.step
  self.prop = self.rCntr.prop
  self.skill = self.rCntr.skill

  PropTool.SetNames(MountStepCfg[1], self.propNames)
  local des = self.Name
  local USBC = UITool.SetBtnClick
  local S = UITool.SetLsnrSelf
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
  self.showBtn = TransTool.FindChild(root,"showBtn",des)
  self.showLab = CG(UILabel, root, "showBtn/lbl", des)
  self.isShowTog = CG(UIToggle, root,"isShowTog", des)
  USBC(root, "tranBtn", des, self.Change, self)
  USBC(root, "transBtn", des, self.Skins, self)
  S(self.showBtn,self.OnShow,self)
  local ED = EventDelegate
  local EC = ED.Callback
  local ES = ED.Set
  ES(self.isShowTog.onChange,EC(self.OnIsShow,self))
  self:SetFight()
  self:AddLsnr()
  self:SetFlag(Mm.flag.red)
  self:SetSkinRed()
  self:RespStatus()
  self:RespComposeRed()
  self:RespAdvRed()
  self.isShowComb = false
end

--点击预览效果
function My:OnShow()
  local isShow = self.isShowComb
  local str = ""
  if isShow == false then
    self.rCntr:TransCam(1)
    self.rCntr:CanRotate(false)
    self.model:CombMod()
    isShow = true
    str = "还原"
  else
    self.rCntr:TransCam(2)
    self.rCntr:CanRotate(true)
    self.model:SingleMod()
    isShow = false
    str = "预览"
  end
  self.isShowComb = isShow
  self.showLab.text = str
end

function My:ResetMod(flag)
  self.isShowComb = flag
  self:OnShow()
end

function My:OnIsShow()
  local isShow = self.isShowTog.value
  local index = isShow == false and 1 or 0
  Mm.ReqStatus(index)
end

function My:SelectNext()
  local mod = self.model
  local mid = mod.cur.cfg.id
  local bid = Mm.bid
  local dif = mid - bid
  if dif < 1 then
    mod:SelectNext()
  elseif dif >= 1 then
    UITip.Error("当前宝座还未解锁")
  elseif dif == 0 then
    -- UITip.Error("敬请期待")
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
  local ft = User.MapData:GetFightValue(36)
  self.cntr:SetFight(ft)
end

--设置皮肤按钮红点
function My:SetSkinRed()
  local isShowRed = ThroneAppMgr.isTransRed
  self.skinRed:SetActive(isShowRed)
end

function My:Update()
  self.step:Update()
end

function My:SetProp()
  self:Switch()
  self.prop:Refresh()
end

function My:CloseQual()
  local qual = self.rCntr.qual
  qual:Close()
end

function My:SetUnlock()

end

--切换模型信息
function My:Switch(cfg)
  if cfg == nil then
    cfg = BinTool.Find(ThroneCfg, Mm.bid)
  end
  if cfg==nil  then
    iTrace.Error("Loong","can not find mount baseid:",Mm.bid)
    cfg = ThroneCfg[1]
  end
  local curCfg = Mm.curCfg
  self.cntr:SetName(cfg.name)
  self.cntr:SetStep(curCfg.st)
  local at = ((Mm.bid < cfg.id) and true or false)
  self.rCntr:SetUnlock(at)
  self.step:SetActive(not at)
  self:SetChgLbl(cfg)
end

function My:SetChgLbl(cfg)
  local str = nil
  self:IsShowAlFlag(false)
  local id = cfg.id * 100 + 1
  if id == Mm.chgID then
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
  local sendId = id * 100 + 1
  if id > Mm.bid then
    UITip.Error("未解锁")
  elseif sendId == Mm.chgID then
    UITip.Log("已经幻化")
  else
    self.rCntr:Lock(true)
    Mm.ReqChange(sendId)
  end
end

--皮肤
function My:Skins()
  JumpMgr:InitJump(UIAdv.Name,6)
  UIThroneApp.Show()
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
  Mm.eUpStar[fn](Mm.eUpStar, self.UpStar, self)
  Mm.eRespInfo[fn](Mm.eRespInfo, self.RespInfo, self)
  Mm.eRespStep[fn](Mm.eRespStep, self.RespStep, self)
  Mm.eRespChange[fn](Mm.eRespChange, self.RespChange, self)
  Mm.eRespStatus[fn](Mm.eRespStatus, self.RespStatus, self)
  Mm.eComposeRed[fn](Mm.eComposeRed, self.RespComposeRed, self)
  Mm.eAdvRed[fn](Mm.eAdvRed, self.RespAdvRed, self)
end

--分解按钮红点状态
function My:RespComposeRed()
  local composeRed = Mm.composeRed
  self.step:SetComposeFlag(composeRed)
end

--升级按钮红点状态
function My:RespAdvRed()
  local advRed = Mm.advRed
  self.step:SetBtnFlag(advRed)
end

function My:RespInfo()
  self:SetProp()
  self:RespStep()
end

--响应升阶
function My:RespStep(err)
  err = err or 0
  if err < 1 then
    self.step:SetPro()
    self.rCntr.ThrStep.proSpFx1:SetActive(true)
  end
  self.rCntr:Lock(false)
end

--等阶提升
function My:UpStep()
  self.step:UpStep()
  self.model:SelectCur()
  self.skill:Refresh(Mm.skiIDs, Mm.GetSkiLock)
  local id = self.model.cur.cfg.id
  local sendId = id * 100 + 1
  Mm.ReqChange(sendId)
end

--响应升级
function My:UpStar()
  local curCfg = Mm.curCfg
  self.cntr:SetStep(curCfg.st)
  self:SetProp()
end

--响应幻化
function My:RespChange(err)
  self.rCntr:Lock(false)
  if err == 0 then
    UITip.Log("幻化成功")
    self:SetChgLbl(self.model.cur.cfg)
  end
end

--响应设置状态
function My:RespStatus()
  local index = Mm.status
  local status = false
  if index == 1 then
    status = false
  else
    status = true
  end
  self.isShowTog.value = status
end

function My:ResetProps()
  local prop = self.prop
  prop.GetCfg = self.GetCfg
  prop:SetNames(self.propNames)
  prop:Refresh()
end

function My:Open()
  self:CloseQual()
  self.step.db = Mm
  self.step:Open()
  self:ResetProps()
  self.model:Open()
  self.model:SelectCur()
  self.skill:Open()
  self.skill:Refresh(Mm.skiIDs, Mm.GetSkiLock)
  self.rCntr.ThrStep:SetStarActive(false)
  self.rCntr.ThrStep:SetDesLab("精华")
  self.rCntr:CanRotate(true)
  self.rCntr:TransCam(2)
  FightVal.eChgFv:Add(self.SetFight, self)
--   Mm.flag.eChange:Add(self.SetFlag, self)
  sMgr.eShowActivity:Add(self.SetFlag, self)
  sMgr.eHideActivity:Add(self.SetFlag, self)
end

function My:Close()
  self.step:Close()
  self.model:Close()
  self:CloseQual()
  self.rCntr.ThrStep:SetStarActive(true)
  self.rCntr.ThrStep:SetDesLab("经验")
  self.rCntr:CanRotate(true)
  self.rCntr:TransCam(1)
--   Mm.flag.eChange:Remove(self.SetFlag, self)
  FightVal.eChgFv:Remove(self.SetFight, self)
  sMgr.eShowActivity:Remove(self.SetFlag, self)
  sMgr.eHideActivity:Remove(self.SetFlag, self)
end

function My:Dispose()
  self:RemoveLsnr()
  self.model:Dispose()
  self.isShowComb = false
--   Mm.flag.eChange:Remove(self.SetFlag, self)
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
