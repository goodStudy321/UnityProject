--[[
 	author 	    :Loong
 	date    	:2018-01-16 17:38:23
 	descrition 	:神兵升级模块
--]]

UIAdvUpg = Super:New{Name = "UIAdvUpg"}

local My = UIAdvUpg
local sMgr = SystemMgr

--升级消耗列表
My.items = UISolidItems:New()


function My:Init(root)
  self.root = root
  self.active = true
  self.gbj = root.gameObject
  local des = self.Name
  local CG = ComTool.Get
  local TF = TransTool.Find
  local USBC = UITool.SetBtnClick

  self.prop = self.cntr.prop
  self.skill = self.rCntr.skill

  USBC(root, "upgBtn", des, self.ReqUpg, self)
  USBC(root, "akeyBtn", des, self.AkeyUpg, self)

  USBC(root, "skinBtn", name, self.OpenSkin, self)
  self.lvLbl = CG(UILabel, root, "lv", des)

  self.action = TF(root, "skinBtn/action", des)
  self.btnRed = TF(root, "upgBtn/red", des)

  local items = self.items
  local itRoot = TF(root, "icons", des)
  items:Init(itRoot)
end

--是否显示皮肤按钮的红点
function My:IsShowAc(ac, isMw)
  local ac = isMw or self.cntr.skin.model.skinBtnRed
  self.action.gameObject:SetActive(ac)
end

function My:LoadMod()
  local name = AssetTool.GetSexModName(self.db.upgCfg)
  local scName = AssetTool.GetSexScModName(self.db.upgCfg)
  if name == nil then return end
  if scName == nil then return end
  local tran = self.modRoot:Find(name)
  if tran then
    self.mod = tran.gameObject
    self.mod:SetActive(true)
    self.rCntr.loadLabR:SetActive(false)
    self.rCntr:IsShowAssTip(false)
  else
    local secId = self.cntr.SecondId
    if secId >= 1 then
      return
    end
    local isExist = AssetTool.IsExistAss(name)
    local isScExist = AssetTool.IsExistAss(scName)
    if isExist == false or isScExist == false then
      self.rCntr:IsShowAssTip(true)
      return
    elseif isExist == true and isScExist == true then
      self.rCntr:IsShowAssTip(false)
    end
    local GH = GbjHandler(self.LoadModCb, self)
    Loong.Game.AssetMgr.LoadPrefab(name, GH)
  end
end

function My:LoadModCb(go)
  local modRoot = self.modRoot
  if LuaTool.IsNull(modRoot) then
    Destroy(go)
  else
    self.mod = go
    go:SetActive(true)
    local tran = go.transform
    tran.parent = modRoot
    tran.localPosition = Vector3.zero
  end
end

--设置战斗力
function My:SetFight()
  local ft = self.db:GetFight()
  local str = tostring(ft)
  self.cntr:SetFight(str)
end

function My:SetName ()
  local name = self.db.upgCfg.name
  self.cntr:SetName(name)
end

--返回属性配置
function My:GetPropCfg()
  local db = self.db
  local lv = db.lv
  local BF = BinTool.Find
  local str = "lv"
  local cCfg = BF(db.iLvCfg, lv, str)
  local nLv = lv + 1
  local nCfg = BF(db.iLvCfg, nLv, str)
  if nCfg == nil then nCfg = cCfg end
  return cCfg, nCfg
end

--打开皮肤模块
function My:OpenSkin()
  local sysId = self.db.sysID
  local cntr = self.cntr
  local skin = (sysId==2) and cntr.mwSkin or cntr.skin
  cntr:Switch(skin)
  local v1 = Vector3.New(-122.5,234.53,0)
  local v2 = Vector3.New(-178.7,235.7,0)
  self.cntr:SetFitPos(v1,v2)
  if sysId == 4 then
    self.modRoot.transform.localPosition = Vector3(-400,0,1300)
  else
    self.modRoot.transform.localPosition = Vector3(-300,0,1300)
  end
end

--设置基础组件
function My:SetProp()
  self:SetPro()
  self:SetName()
  self:SetFight()
  self.lvLbl.text = tostring(self.db.lv) .. "级"
end

--设置进度
function My:SetPro()
  local db = self.db
  if db.lvCfg then
    local total = db.lvCfg.costexp * 1.0
    local pro = db.lvExp / total
    self.cntr:SetPro(pro)
  end
end

function My:ChkUpg()
  local db = self.db
  local lv = db.lv
  if lv < 1 then
    UITip.Error("未解锁") return false
  end
  if lv == db.maxLv then
    UITip.Error("已满级") return false
  end
  return true
end

--请求升级
function My:ReqUpg()
  if not self:ChkUpg() then return end
  if self.items.cur == nil then
    UITip.Log("未选择使用道具")
  else
    local db = self.db
    local cfg = self.items.cur.cfg
    local id, num = cfg.id, 1
    local res = ItemTool.NumCond(id, num,false)
    self.sysId = db.sysID
    if not res then self:JumpOpen() return end
    self.rCntr:Lock(true)
    local uid = PropMgr.TypeIdById(id)
    PropMgr.ReqUse(uid, num)
  end
end

function My:JumpOpen()
  local itID = self.items.cur.cfg.id
  local isSkin = false
  local sysId = self.sysId
  GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID,isSkin)

  -- if self.sysId == 2 then --法宝
  --   UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
  -- elseif self.sysId == 5 then --翅膀
  --   UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
  -- end
end

--获取途径界面回调
function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(85,-110,0))
	local petGetWay = AdvGetWayCfg[self.sysId].wayDic
	local len = #petGetWay
	for i = 1,len do
		local wayName = petGetWay[i].v
		ui:CreateCell(wayName, self.OnClickGetWayItem, self)
	end
end

function My:OnClickGetWayItem(name)
	if name == "逍遥神坛" then
		self.db:JumpTopFight()
	elseif name == "仙峰论剑" then
    self.db:JumpArena()
  elseif name == "诛仙战场" then
    self.db:JumpWar()
	end
end

--一键升级
function My:AkeyUpg()
  if not self:ChkUpg() then return end
  local total, ids = 0, self.db.itemIDs
  local GetNum = ItemTool.GetNum
  for i, v in ipairs(ids) do
    total = total + GetNum(v)
  end
  if total < 1 then
    -- UITip.Error("无可使用道具")
    self:JumpOpen()
  else
    for i, v in ipairs(ids) do
      local num = GetNum(v)
      if num > 0 then
        PropMgr.ReqUse(v, num, 1)
      end
    end
  end
end

--响应升级
--lvChg:true:等级发生改变
function My:RespUpg(err, lvChg)
  if err == 0 then
    local proSpFx1 = self.cntr.proSpFx1
    proSpFx1:SetActive(true)
    local db = self.db
    --self:SetFight()
    local lv = db.lv
    local str = tostring(lv) .. "级"
    self.lvLbl.text = str
    local exp, expUp = self.db.lvExp, 0
    if lvChg then
      self:ResetSkill()
      self.prop:Refresh()
      if lv < db.maxLv then
        UITip.Log(db.Simple .. "等级提升至"..str)
      else
        db.flag.isFullStep = true
        UITip.Log("已达到最大等级")
      end
    else
      expUp = exp - db.lastLvExp
      UITip.Log(db.Simple .."经验+" .. expUp)
    end
    local rCntr = self.rCntr
    ParticleUtil.Play(rCntr.fxLvSucGo)
    local pos = self.items.cur.root.position
    rCntr:PlayLvFx(pos)
    self:SetPro()
  end
  self:SetUnlock()
  self.rCntr:Lock(false)
end

function My:SetFlag(red,index)
  local isRed = red
  if self.items == nil or self.items.cur == nil then
    return
  end
  local cfg = self.items.cur.cfg
  local id = cfg.id
  local res = ItemTool.GetNum(id)
  if res > 0 and self.db.flag.isFullStep == false and index == 1 then
    isRed = true
  else
    isRed = false
  end
  -- local value = SystemMgr:GetSystemIndex(6, self.db.sysID)
  local value = SystemMgr:GetActivityPage(ActivityMgr.YC,self.db.sysID)
  self.rCntr:SetFlag(self.db.sysID, value)
  if index == nil then
    return
  end
  if index == 1 then
    self.btnRed.gameObject:SetActive(isRed)
  end

end

--设置未解锁
function My:SetUnlock()
  local lt = (self.db.lv < 1) and true or false
  self.rCntr:SetUnlock(lt)
end

--打开器魂面板
function My:OpenSoul()
  local qual = self.rCntr.qual
  qual:Open()
  qual:Refresh(self.db.iQualCfg, self.db.soulDic)
end

--响应器魂
function My:RespSoul()
  --self:SetFight()
  self.rCntr.qual:RespUpg()
end

--返回属性标题
function My.GetPropTitle(cfg)
  local str = tostring(cfg.lv) .. "级"
  return str
end

function My:Refresh()
  self:SetProp()
  local db = self.db
  self.skill:Refresh(db.skiIDs, db.GetLvSkiLock, db)
end

--重新设置属性列表
function My:ResetProps()
  local db = self.db
  local prop = self.prop
  prop.srcObj = self
  prop.GetCfg = self.GetPropCfg
  prop.quaDic = db.soulDic
  prop.quaCfg = db.iQualCfg
  prop:SetNames(db.lvPropNames)
  prop:Refresh()

end

--重新设置技能列表
function My:ResetSkill()
  local db = self.db
  self.skill:Refresh(db.skiIDs, db.GetLvSkiLock, db)
  self.skill:Open()
end


function My:Open()
  self:SetProp()
  self:LoadMod()
  self:OpenSoul()
  self:SetUnlock()
  self.prop:Open()
  self:ResetProps()
  self:ResetSkill()
  self:IsShowAc()
  self.active = true
  self.gbj:SetActive(true)
  self.items:Refresh(self.db.itemIDs)
  self:SetFlag(self.db.flag.red,1)
  FightVal.eChgFv:Add(self.SetFight, self)
  self.db.flag.eChange:Add(self.SetFlag, self)
  sMgr.eShowActivity:Add(self.SetFlag, self)
  sMgr.eHideActivity:Add(self.SetFlag, self)
  -- self.db.eSkinRedS:Add(self.IsShowAc,self)
  if self.db.sysID == 2 then
    self:IsShowAc(nil, AdvMgr:UpMwAction())
  end
end


function My:Close()
  self.skill:Close()
  self.active = false
  self.gbj:SetActive(false)
  self.rCntr.qual:Close()
  if self.mod then self.mod:SetActive(false) end
  -- self.items:ClearIcon()
  FightVal.eChgFv:Remove(self.SetFight, self)
  self.db.flag.eChange:Remove(self.SetFlag, self)
  sMgr.eShowActivity:Remove(self.SetFlag, self)
  sMgr.eHideActivity:Remove(self.SetFlag, self)
  -- self.db.eSkinRedS:Remove(self.IsShowAc,self)
end


function My:Dispose()
  self.prop:Dispose()
  self.rCntr.qual:Dispose()
  self.items:Dispose()
  FightVal.eChgFv:Remove(self.SetFight, self)
  if self.db == nil then return end
  self.db.flag.eChange:Remove(self.SetFlag, self)
  sMgr.eShowActivity:Remove(self.SetFlag, self)
  sMgr.eHideActivity:Remove(self.SetFlag, self)
  TableTool.ClearUserData(self)
  -- self.db.eSkinRedS:Remove(self.IsShowAc,self)
end

return My
