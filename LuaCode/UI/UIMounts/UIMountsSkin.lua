--[[
 	author 	    :Loong
 	date    	:2018-01-11 17:34:14
 	descrition 	:坐骑皮肤
--]]

UIMountsSkin = Super:New{Name = "UIMountsSkin"}
local My = UIMountsSkin

My.model = require("UI/UIMounts/UIMountsSkinMod")

local Ms = MountsSkin

--属性名称列表
My.propNames = {}

function My:Init(root)
  self.root = root
  self.step = self.cntr.step
  self.skill = self.rCntr.skill
  self.prop = self.rCntr.prop
  self.go = root.gameObject
  local des, USBC = self.Name, UITool.SetBtnClick
  USBC(root, "backBtn", name, self.SwitchBasic, self)
  UIMisc.SetSub(self, self.model, "items")

  PropTool.SetNames(MountSkinCfg[1], self.propNames)

  self:AddLsnr()
end

function My.GetCfg()
  local cCfg = Ms.info.cfg
  local nCfg = Ms.info:GetNextCfg()
  return cCfg, nCfg
end

function My:AddLsnr()
  Ms.eRespStep:Add(self.RespStep, self)
end

function My:RemoveLsnr()
  Ms.eRespStep:Remove(self.RespStep, self)
end

function My:SetFight()
  local cfg = Ms.info.cfg
  local ft = PropTool.GetFight(cfg, self.propNames)
  self.cntr:SetFight(ft)
end

--切换皮肤信息
--info(MountsSkinInfo)
function My:Switch(info)
  info = info or Ms.info
  Ms.info = info
  self:SetFight()
  self.cntr:SetName(info.name)
  self.cntr:SetStep(UIMisc.GetStep(info.cfg.st))
  local at = info.lock
  self.rCntr:SetUnlock(at)
  local stAt = not at
  self.step:SetActive(stAt)
  if stAt then self.step:Refresh() end
  self.prop:Refresh()
  self.skill:Refresh(info.skiIDs, Ms.GetSkiLock)
end


--请求幻化改变外观
function My:Change()
  local info = Ms.info
  local id = Ms.info.cfg.id
  if info.lock then
    UITip.Error("未解锁皮肤")
  elseif id == MountsMgr.chgID then
    UITip.Log("已经幻化皮肤")
  else
    self.rCntr:Lock(true)
    MountsMgr.ReqChange(id)
  end
end

--响应升阶
function My:RespStep(err, id, unlock, upstep)
  self.rCntr:Lock(false)
  self.step:RespStep(err, upstep)
  if unlock then self.model:SetLock(id) end
  if not upstep then return end
  self:Switch()
end

function My:ResetProps()
  local prop = self.prop
  prop.GetCfg = self.GetCfg
  prop:SetNames(self.propNames)
  prop:Refresh()
end


function My:SetActive(at, funcName)
  self.go:SetActive(at)
  UIMisc.SetActive(self.model, at)
  local cpui = self.rCntr.cpui
  if cpui == nil then return end
  local ebc = cpui.eBlockClose
  if ebc == nil then return end
  ebc[funcName](ebc, self.SwitchBasic, self)
end

function My:Open()
  self.step.db = Ms
  self:SetActive("Add")
end

function My:Close()
  self:SetActive("Remove")
end

function My:Dispose()
  self:RemoveLsnr()
end

function My:Refresh()
  self.model:Refresh()
end

---[[和坐骑共享组件部分
--切换到基础模块
function My:SwitchBasic()
  self.cntr:Switch(self.cntr.basic)
end
--]]

return My
