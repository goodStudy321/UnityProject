--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-05 11:54:51
-- UI引导界面
--=========================================================================


UIGuide = UIBase:New{Name = "UIGuide"}

local My = UIGuide
--点击可点击区域事件
My.eOnClickArea = Event()

function My:InitCustom()
  local des = self.Name
  local root = self.root
  local TF, CG = TransTool.Find, ComTool.Get
  self.areaWdg = CG(UIWidget, root, "area", des)
  local rt = self.areaWdg.transform
  self.areaTran = rt
  self.areaGo = self.areaWdg.gameObject
  self.areaGo:SetActive(false)
  local maskTran = TF(rt, "mask", des)
  self.maskGo = maskTran.gameObject
  self.holoTran = TF(rt, "FX_UI_Guide", des)
  self.warnTran = TF(rt, "FX_UI_Guide_01", des)
  self.warnGo = self.warnTran.gameObject
  self.warnGo:SetActive(false)
  self.gestTran = TF(rt, "gesture", des)
  self.msgTran = TF(rt, "msg", des)
  self.blurGo = TransTool.FindChild(rt, "blur", des)
  self.blurGo:SetActive(false)

  --self.holoWdg = CG(UIWidget, rt, "guide", des)
  --self.gestWdg = CG(UIWidget, rt, "gesture", des)
  --self.msgWdg = CG(UISprite, rt, "msg", des)
  self.textLbl = CG(UILabel, rt, "msg/text", des)
  self.maskGo:SetActive(false)
  self.vec = Vector3.zero
  self.tween = ObjPool.Get(TweenWidget)
  self.tween.complete:Add(self.TweenComplete, self)

  self.autoTimer = ObjPool.Get(iTimer)
  self.autoTimer.complete:Add(self.AutoExe, self)

  self.autoOffTimer = ObjPool.Get(iTimer)
  self.autoOffTimer.complete:Add(self.Close, self)

  self.warnTimer = ObjPool.Get(iTimer)
  self.warnTimer.complete:Add(self.DisableWarn, self)
end

function My:GetCfg()
  do return GuideMgr.curCfg end
end

--设置属性
function My:SetProp()
  local cfg = self:GetCfg()
  if cfg == nil then return end
  local vec = Vector3.zero;
  --self:CheckAutoOnMainBottom()
  self:SetArea(cfg)
  self:SetPos(cfg, "msgTran", "textPos")
  self:SetPos(cfg, "warnTran", "holoPos")
  self:SetPos(cfg, "holoTran", "holoPos", true)
  self:SetPos(cfg, "gestTran", "gestPos", true)

  --self:SetAnchor(cfg, "areaWdg", "areaPos")
  --self:SetAnchor(cfg, "holoWdg", "holoPos", true)
  --self:SetAnchor(cfg, "gestWdg", "gestPos", true)
  self.textLbl.text = cfg.text

  local maskAt = (cfg.focus == 1 and true or false)

  self.maskGo:SetActive(maskAt)
  self:Lock(maskAt)
  local audioName = cfg.audio
  if audioName then 
    --Audio:Play(audioName, 1)
    Audio:PlayTheOne(audioName, 1);
  end
  self.areaGo:SetActive(true)
  self:CheckAuto()
  self:CheckAutoClose()
  if maskAt then return end
  LuaUIEvent.euionclick:Add(self.OnClick, self)
end



--检查是否需要自动关闭
function My:CheckAutoClose()
  local cfg = self:GetCfg()
  if cfg==nil then return end
  local tm = cfg.autoOffTm or 0
  if tm < 1 then return end
  tm = tm * 0.001
  local timer = self.autoOffTimer
  timer:Reset()
  timer:Start(tm)
end

--检查是否需要自动执行
function My:CheckAuto()
  local cfg = self:GetCfg()
  if cfg==nil then return end
  local isAuto = cfg.isAuto or 0
  if isAuto < 1 then return end
  local tm = cfg.autoTime or 1000
  tm = tm * 0.001
  local timer = self.autoTimer
  timer:Reset()
  timer:Start(tm)
  --iTrace.Log("Loong","CheckAuto:",cfg.id, " tm:", tm)
end

--自动执行
function My:AutoExe()
  local cfg = self:GetCfg()
  if cfg==nil then return end
  local uiname = cfg.ui
  local ui = UIMgr.Get(uiname)
  if ui == nil then return end
  local path = cfg.autoCom or cfg.areaPath
  local go = TransTool.FindChild(ui.root, path, uiname)
  if go == nil then 
    iTrace.Error("Loong","guide id:", cfg.id, " autoCom:", path, " not find")
  else
    self:Close()
    go:SendMessage("OnClick", SendMessageOptions.DontRequireReceiver)
    --iTrace.Log("Loong","AutoExe:",cfg.id)
  end
end

function My:IsActive(tran)
  local p, at = tran, tran.gameObject.activeSelf
  while true do
    if at == false then
      return false
    else
      p = p.parent
      if p == nil then break end
      at = p.gameObject.activeSelf
    end
  end
  do return true end
end

function My:SetArea(cfg)
  if cfg == nil then return end
  local tuiName = cfg.ui
  local ui = UIMgr.Get(tuiName)
  if ui == nil then return end
  local widget = ComTool.Get(UIWidget, ui.root, cfg.areaPath, tuiName)
  if widget == nil then
    self:Close()
  elseif self:IsActive(widget.transform) == false then
    self:Close()
  else
    local areaWdg = self.areaWdg
    local areaTran = self.areaTran
    local wdgPos = widget.transform.position
    wdgPos.z = areaTran.position.z
    areaTran.position = wdgPos
    if App.IsDebug then
      iTrace.Log("Loong", "widget.pos:", widget.transform.position, ", areaTran.pos:", areaTran.position)
    end
    if cfg.focus == 1 then
      local areaHt = widget.height
      local height = (areaHt%2) ~= 0 and(areaHt + 1) or areaHt
      local width = widget.width
      self.tween:Reset()
      self.tween:Start(width * 20, height * 20, width, height, areaWdg, 0.3)
    end
  end
  --areaWdg.width = widget.width
  --areaWdg.height = height
end

--设置位置
--tranName:变换组件名
--posName:位置字段名
--needAt:无posName的配置时隐藏
function My:SetPos(cfg, tranName, posName, needAt)
  local cfgPos = cfg[posName]
  local tran = self[tranName]
  if cfgPos then
    self.vec.x = cfgPos.x
    self.vec.y = cfgPos.y
    tran.localPosition = self.vec
    if needAt then tran.gameObject:SetActive(true) end
  elseif needAt then
    tran.gameObject:SetActive(false)
  end
end

--设置位置
--widgetName:挂件名
--oName:绝对位置字段名
--needAt:无oName的配置时隐藏
function My:SetAnchor(cfg, widgetName, oName, needAt)
  local obsolute = cfg[oName]
  local widget = self[widgetName]
  if obsolute then
    widget.leftAnchor.absolute = obsolute[1]
    widget.rightAnchor.absolute = obsolute[2]
    widget.bottomAnchor.absolute = obsolute[3]
    widget.topAnchor.absolute = obsolute[4]
    if needAt then widget.gameObject:SetActive(true) end
  elseif needAt then
    widget.gameObject:SetActive(false)
  end
end

function My:OnClick(go)
  local cfg = self:GetCfg()
  if cfg == nil then self:Close() return end
  local pos = UICamera.lastEventPosition
  --local sPos = cam:WorldToScreenPoint(self.areaTran.position)
  local sPos = UIMgr.HCam:WorldToScreenPoint(self.areaTran.position)
  local areaWdg = self.areaWdg
  local activeHeight = UIMgr.uiRoot.activeHeight
  local factor = UnityEngine.Screen.height / activeHeight
  local scale = factor * 0.5
  local contains, w, h = true, areaWdg.width * scale, areaWdg.height * scale

  local posX, posY, sPosX, sPosY = pos.x, pos.y, sPos.x, sPos.y
  if posX < (sPosX - w) then
    contains = false
  elseif posX > (sPosX + w) then
    contains = false
  elseif posY < (sPosY - h) then
    contains = false
  elseif posY > (sPosY + h) then
    contains = false
  end
  if App.IsDebug  or App.isEditor then
    iTrace.sLog("Loong", "[Editor] pos:", pos, " ,sPos:", sPos, " ,w:", w, " ,h:", h, " ,", contains, " ,cfg:", cfg.id," selectObject:", tostring(UICamera.selectedObject))
  end
  if contains == true then
    self:Close()
    My.eOnClickArea(cfg)
  elseif(cfg.focus == 1) then
    if self.warnTimer.running then return end
    self.warnGo:SetActive(true)
    self.warnTimer:Start(2)
  end
end

function My:StopTimer()
  self.tween:Stop()
  self.warnTimer:Stop()
  self.autoTimer:Stop()
  self.autoOffTimer:Stop()
end

function My:TweenComplete()
  LuaUIEvent.euionclick:Add(self.OnClick, self)
  self:Lock(false)
  self.blurGo:SetActive(true)
end

function My:DisableWarn()
  self.warnGo:SetActive(false)
end

--是否能被记录
function My:CanRecords()
  do return false end
end

function My:CheckAutoOnMainBottom()
  local cfg = self:GetCfg()
  if cfg==nil then 
    self:Close()
  else
    local on = cfg.autoOnBottom or 0
    if on == 1 then
      local status = UIActivityLeftBottomBtns:PlayTweenStatus()
      if status then
        UIMainMenu:UIMainmenuBottomSetActive(true)
        UIActivityLeftBottomBtns.ePlayTweenEnd:Add(self.MainBottomTween, self)
      else
        self:SetProp()
      end
    else
      self:SetProp()
    end
  end
end

function My:MainBottomTween(val)
  if val then return end
  self:SetProp()
end

function My:OpenCustom()
  self:RemoveEvent()
  self.blurGo:SetActive(false)
  self:SetAreaZ()
  self:CheckAutoOnMainBottom()
  --iTrace.sLog("Loong", self.Name, "================ open")
end

function My:SetAreaZ()
  local cfg = self:GetCfg()
  if cfg == nil then return end
  if cfg.z == nil then return end
  self.areaTran.localPosition = Vector3.New(0, 0, cfg.z)
end

function My:CloseCustom()
  self:StopTimer()
  self:RemoveEvent()
  self.areaGo:SetActive(false)
  self.maskGo:SetActive(false)
  self.blurGo:SetActive(false)
  self.warnGo:SetActive(false)

  --iTrace.sLog("Loong", self.Name, "================ close")
end

function My:RemoveEvent()
  UIActivityLeftBottomBtns.ePlayTweenEnd:Remove(self.MainBottomTween, self)
  LuaUIEvent.euionclick:Remove(self.OnClick, self)
end

function My:DisposeCustom()
  self:StopTimer()
  self:RemoveEvent()
end

return My
