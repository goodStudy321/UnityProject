--[[
  authors 	:Loong
 	date    	:2017-11-06 17:55:47
 	descrition 	:养成(神兵，坐骑，宠物，法宝，翅膀)系统界面
--]]
require("UI/Cmn/UISolidItems")
require("UI/Adv/UIAdvPage")
require("UI/Adv/UIAdvProp")
require("UI/UIMounts/UIMounts")
require("UI/UIThrone/UIThrone")
require("UI/Base/UIPet")

require("UI/Adv/AdvGetWayCfg")

UIAdv = UIBase:New {Name = "UIAdv"}

local My = UIAdv

--分页列表
My.tabs = {}

--分页字典
--k:选项按钮名,v:分页
My.dic = {}

--选项按钮字典
--k:系统ID,v:UIToggle
My.togDic = {}

--k:系统ID,v:GameObject
My.flagDic = {}

--开放系统字典
--k:系统ID,v:分页
My.openDic = {}

--获取途径
My.advGetWay = require("UI/Adv/UIAdvGetWay")

--属性模块
My.prop = UIAdvProp:New()--UIProps:New{}

--资质.丹药分页
My.qual = require("UI/Adv/UIAdvQual")

--技能模块
My.skill = require("UI/Adv/UIAdvSkill")

--技能提示
My.skiTip = require("UI/Cmn/UICmnSkiTip")

--资质.丹药提示
My.qualTip = require("UI/Adv/UIAdvQualTip")

My.Step = require("UI/Adv/UIAdvStep")

My.ThrStep = require("UI/Adv/UIAdvThrStep")

--跳转皮肤界面
--0：当前界面  1：皮肤界面
My.SecondId = 0

--静态系统ID,主动设置时第一次打开将开启对应分页
--My.sID = 1

function My:InitCustom()
  local root = self.root
  local des = self.Name
  local CG = ComTool.Get
  ListTool.Clear(tabs)
  local TF = TransTool.Find
  self.modRoot = TF(root, "modRoot", des)
  self.modBox = CG(BoxCollider, root, "rotate", des)
  self.modAnchor = TF(root, "modAnchor", des)
  self.modCam = CG(Camera, root, "modCam", des)
  self.togTbl = CG(UITable, root, "tog", des)

  local loadLab = CG(UILabel, root, "loadLab", des)
  loadLab.text = "[67cc67][u]资源下载中[-][-]"
  --true:已经激活一个分页
  self.oneOpen = false
  local SetSub = UIMisc.SetSub
  SetSub(self, self.qual, "qual")
  SetSub(self, self.skill, "skill")
  SetSub(self, self.skiTip, "skiTip")
  SetSub(self, self.qualTip, "qualTip")
  SetSub(self, self.Step, "Step")
  SetSub(self, self.ThrStep, "ThrStep")
  self.prop.root = TF(root, "props", des)
  self.prop:Init()
  
  --是否直接关闭界面（处于皮肤界面时）
  self.isClose = false

  self.unlock = true
  self:SetUnlock(false)
  local TFC = TransTool.FindChild
  --选项按钮根游戏对象
  
  self.getBtnGo = TFC(root, "getBtn", des)
  self.loadLabR = TFC(root, "loadLab", des)
  self.loadLabR:SetActive(false)
  self.loadLabBox = CG(BoxCollider, root, "loadLab", des)
  self.getWay = TF(root, "getWay", des)
  UITool.SetBtnClick(root, "getBtn", name, self.GetBtnClick, self)
  self.getBtnGo:SetActive(false)

  self.togGo = TFC(root, "tog", des)
  --fx
  self.fxLvGo = TFC(root, "FX_Immortals_Levelup", des)
  self.fxLvSucGo = TFC(root, "fx/FX_shengji_Succeed", des)
  self.fxStepSucGo = TFC(root, "fx/FX_Immortals_Succeed", des)
  ---[[ 添加分页
  self:Add(UIPet, "Cw",3)
  self:Add(UIMounts, "Zq",1)
  self:Add(UIThrone, "Bz",6)
	self:Add(UIAdvPage, "Sb",4)
  --法宝
	self:Add(UIAdvPage, "Fb",2, false)
  --翅膀
	self:Add(UIAdvPage, "Cb",5, false)
	--]]

  -- self:SetOpen()

  self:AddLsnr()

  local sys = GWeaponMgr
  self:SetFlag(sys.sysID, sys.flag.red)
  sys = MWeaponMgr
  self:SetFlag(sys.sysID, sys.flag.red)
  sys = WingMgr
  self:SetFlag(sys.sysID, sys.flag.red)
  sys = PetMgr
  self:SetFlag(sys.SysID, sys.flag.red)
  UITool.SetLiuHaiAnchor(root, "left_bg", des)

  self:TransCam(1)

  --关闭按钮
  UITool.SetBtnClick(root, "closeBtn", name, self.CloseClick, self)
  -- self.togDic["4"].gameObject:SetActive(false)
  UITool.SetLsnrSelf(self.loadLabBox, self.OnLoadClick, self)
end

--邮件链接入口
function My:OpenTabByIdx(t1, t2, t3, t4)
  self:SwtichBySysID(t1)
end

function My:GetBtnClick()
  self.advGetWay:Open()
end

function My:OnLoadClick()
  self:Close()
  UIMgr.Open("UIDownload")
end

--关闭
function My:CloseClick(go)
  local cntr = UIAdvPage
  if cntr.isCanShowPanel and not self.isClose then
    cntr:Switch(cntr.upg)
    local v1 = Vector3.New(-465.2,244.1,0)
    local v2 = Vector3.New(-504,244.2,0)
    cntr:SetFitPos(v1,v2)
    self.modRoot.transform.localPosition = Vector3(-400,0,1300)
  else
    self:Close()
    TopMgr.eCloseTop()
    JumpMgr.eOpenJump()
  end
end

--设置关闭状态
function My:SetIsClose(state)
  self.isClose = state
end

--播放升级特效
function My:PlayLvFx(pos)
  ParticleUtil.PlayOnPos(self.fxLvGo, pos)
  Audio:PlayByID(112)
end

--设置开放系统字典
function My:SetOpen()
  local open = false
  local togDic = self.togDic
  for k, v in pairs(togDic) do
    v.gameObject:SetActive(false)
  end
  -- if self.sID then
  --   self:SwtichBySysID(self.sID)
  -- end
  for k, v in pairs(togDic) do
    open = OpenMgr:IsOpen(k)
    if open then
      local it = self.openDic[k]
      -- if not self.sID then
      --   self:SetFirstOpen(it, v)
      -- end
      v.gameObject:SetActive(open)
    end
    -- if k == "6" then
    --   v.gameObject:SetActive(true)
    -- end
  end
  self.togTbl.repositionNow = true
  self:SetUnlock(not self.oneOpen)
end

--响应系统开放
--id:开放系统ID
function My:RespOpen(id)
  local k = tostring(id)
  local it = self.openDic[k]
  if it == nil then return end
  local uiTog = self.togDic[k]
  uiTog.gameObject:SetActive(true)
  self:SetUnlock(false)
  self:SetFirstOpen(it, uiTog)
  self.togTbl.repositionNow = true
end

--设置第一个开启的分页
function My:SetFirstOpen(v, uiTog)
  if self.oneOpen then return end
  uiTog.value = true
  self:SwtichByItem(v, uiTog.name)
  self.oneOpen = true
end

--添加分页
--tab(table):分页类型
--rn(string):根结点名称
--id(number):系统id
--added(boolean):true已添加分页
function My:Add(tab, rn, id, added)
  if added == nil then added = true end
  local des, tabs = self.Name, self.tabs
  local root, TF = self.root, TransTool.Find
  local tr = self.togTbl.transform
  local uiTog = ComTool.Get(UIToggle, tr, rn, des)
  local tt = uiTog.transform
  tab.cntr = self
  tab.rCntr = self
  self.dic[rn] = tab

  if id ~= nil then
    local k = tostring(id)
    local flagGo = TransTool.FindChild(tt, "flag", des)
    self.togDic[k] = uiTog
    self.flagDic[k] = flagGo
    self.openDic[k] = tab
  end

  if added then
    local pr = TF(root, rn, name)
    tab:Init(pr)
    tabs[#tabs + 1] = tab
  end
  UITool.SetLsnrSelf(tt, self.Switch, self, des)
end

--设置标记
--id(string):系统ID
--red(boolean):true激活
function My:SetFlag(id, red)
  local k = tostring(id)
  local go = self.flagDic[k]
  if go == nil then return end
 -- if red == nil then red = false end
  -- local value = SystemMgr:GetSystemIndex(6, id)
  local value = SystemMgr:GetActivityPage(ActivityMgr.YC,id)
  --1--->坐骑  2--->法宝  3--->宠物  4--->神兵  5--->翅膀
  go:SetActive(value)
end

--切换分页
function My:Switch(go)
  local k = go.name
  local tabs = self.dic[k]
  self:SwtichByItem(tabs, k)
end

--通过系统ID切换并同时高亮选项按钮
function My:SwtichBySysID(id,secondId,propId)
  local scId = secondId
  local pid = propId
  if scId == nil or scId < 1 then
    scId = 0
  end
  if pid == nil or pid < 1 then
    pid = 0
  end
  self.SecondId = scId --跳转养成皮肤界面标识
  self.QPropId = pid -- 默认选中道具标识
  self:SetOpen()
  local k = tostring(id)
  local tab = self.openDic[k]
  local tog = self.togDic[k]
  tog.value = true
  self:SwtichByItem(tab, tog.name)
end

function My:SetFxAllActive(at)
  self.fxLvGo:SetActive(at)
  self.fxLvSucGo:SetActive(at)
  self.fxStepSucGo:SetActive(at)
end

--通过分页进行切换
--tab:分页
--k(string):分页键值
function My:SwtichByItem(tab, k)
  if tab == nil then return end
  local curK, cur = self.curK, self.cur
  if curK and (curK == k) then return end
  if cur then cur:Close() end
  self.cur, cur, self.curK = tab, tab, k
  local getWayDate = nil
  if k == "Fb" then
    cur:SetDB(MWeaponMgr)
  elseif k == "Sb" then
    cur:SetDB(GWeaponMgr)
  elseif k == "Cb" then
    cur:SetDB(WingMgr)
  end
  self:SetFxAllActive(false)
  UIAdvPage.proSpFx1:SetActive(false)
  cur:Open()
  self:SetTopTitle(k)
end

function My:SetTopTitle(k)
  local cfg = self.cfg
  if cfg == nil then return end
  local top = UIMgr.Get(cfg.cp)
  if top == nil then
    top = UIFty.Get(cfg.cp)
  end
  if top == nil then return end
  local spn = nil
  if k == "Sb" then
    spn = "神兵"
  elseif k == "Fb" then
    spn = "法宝"
  elseif k == "Cb" then
    spn = "翅膀"
  elseif k == "Zq" then
    spn = "坐骑"
  elseif k == "Cw" then
    spn = "宠物"
  elseif k == "Bz" then
    spn = "宝座"
  end
  -- top:SetTitle(spn)
end

--设置选项按钮的激活
function My:SetTogActive(at)
  self.togGo:SetActive(at)
  if self.isShowGetWay == false then
    -- self.getBtnGo:SetActive(false)
    return
  end
  -- self.getBtnGo:SetActive(at)
end

function My:IsShowAssTip(isShowTip)
  self:Lock(false)
  local mountBox = UIMounts.basic.changBox
  local skinBox = UIAdvPage.skin.skinChangeBox
  local petBox = UIPet.changeBox
  local throneBox = UIThrone.basic.changBox
  mountBox.enabled = not isShowTip
  skinBox.enabled = not isShowTip
  petBox.enabled = not isShowTip
  throneBox.enabled = not isShowTip
  self.loadLabR:SetActive(isShowTip)
end

function My:Update()
  if self.cur == nil then return end
  if self.cur.Update then self.cur:Update() end
end

--index：1 ---> 默认状态
--index：2 ---> 宝座模型
function My:TransCam(index)
  local pos = nil
  local rotate = nil
  local skillPos = nil
  if index == 1 then
    pos = Vector3.New(0,0,-718)
    rotate = Vector3.New(0,0,0)
    skillPos = Vector3.New(-151,-270,1500)
  elseif index == 2 then
    pos = Vector3.New(-267,576,514)
    rotate = Vector3.New(35,0,0)
    skillPos = Vector3.New(-190,-270,1500)
  end
  self.modCam.transform.localPosition = pos
  self.modCam.transform.localEulerAngles = rotate
  self.skill.root.transform.localPosition = skillPos
end

--是否可以旋转模型
function My:CanRotate(state)
  self.modBox.enabled = state
end

--isShowMod:是否显示模型
function My:TranCPMUI(isShowMod)
  self.modRoot.gameObject:SetActive(isShowMod)
end

function My:AddLsnr()
  OpenMgr.eOpen:Add(self.RespOpen, self)
  AdvMgr.eGetCPM:Add(self.TranCPMUI, self)
end

function My:RemoveLsnr()
  OpenMgr.eOpen:Remove(self.RespOpen, self)
  AdvMgr.eGetCPM:Remove(self.TranCPMUI, self)
end

function My:OpenCustom()

end

function My:CloseCustom()
  self.qual:Close()
  local cur = self.cur
  if cur == nil then return end
  if cur.Close then cur:Close() end
end

function My:DisposeCustom()
  self.cur = nil
  self.curK = nil
  self.oneOpen = false
  self.isShowGetWay = nil
  self.SecondId = nil
  self.isClose = false
  self:RemoveLsnr()
  self.qual:Dispose()
  self.prop:Dispose()
  self.skill:Dispose()
  self.skiTip:Dispose()
  self.qualTip:Dispose()
  self.Step:Dispose()
  self.ThrStep:Dispose()
  self.advGetWay:Dispose()
  AssetTool.Unload(self.modRoot.transform)
  local tabs = self.tabs
  for i, v in ipairs(tabs) do v:Dispose() end
  ListTool.Clear(tabs)
  TableTool.ClearDic(self.dic)
  TableTool.ClearDic(self.flagDic)
  My.sID = nil
end

--设置未解锁活动状态
function My:SetUnlock(at)
  if at == nil then at = false end
  self.unlock = at
end

return My
