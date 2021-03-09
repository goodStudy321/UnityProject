--[[
 	author 	    :Loong
 	date    	:2018-01-18 19:22:54
 	descrition 	:符文分解面板
--]]

UIRuneDecompose = Super:New{Name = "UIRuneDecompose"}

local My = UIRuneDecompose

--过滤符文字典,k:品质,v:UID
My.filterDic = {}

function My:Init(root)
  self.root = root
  local des = self.Name
  local CG = ComTool.Get
  local TF = TransTool.Find
  local USBC = UITool.SetBtnClick
  self.anchor = TF(root, "Scroll/anchor", des)
  self.sPanel = CG(UIPanel, root, "Scroll", des)
  self.sPanelY = self.sPanel.transform.localPosition.y
  self.sPanelOffsetY = self.sPanel.clipOffset.y

  local tog = TF(root, "tog", des)
  self.blueTog = CG(UIToggle, tog, "2", des)
  self.whiteTog = CG(UIToggle, tog, "1", des)
  self.purpleTog = CG(UIToggle, tog, "3", des)
  self.orangeTog = CG(UIToggle, tog, "4", des)
  self.purpleTog.value = false
  self.orangeTog.value = false

  local ED = EventDelegate
  local EC = ED.Callback
  local ES = ED.Set
  ES(self.blueTog.onChange, EC(self.OnBlueChange, self))
  ES(self.whiteTog.onChange, EC(self.OnWhiteChange, self))
  ES(self.purpleTog.onChange, EC(self.OnPurpleChange, self))
  ES(self.orangeTog.onChange, EC(self.OnOrangeChange, self))

  USBC(root, "onekeyBtn", des, self.OnClickOnekey, self)

  self.fxGo = TransTool.FindChild(root, "FX_fenjie", des)
  self.fxGo:SetActive(false)
  self.expLbl = CG(UILabel, root, "exp", des)
  self:SetExp()
  self.bag = self.cntr.bag
  if self.ids == nil then self.ids = {} end
  RuneMgr.decomFlag.eChange:Add(self.SetFlagActive, self)
  self.expTex = CG(UITexture, root, "tip/icon", des)
  self:LoadExpTex()
  self:SetOrangeTogActive()
  TableTool.ClearDic(self.filterDic)
end

function My:LoadExpTex()
  local cfg = ItemData["14"]
  if cfg == nil then return end
  AssetMgr:Load(cfg.icon, ObjHandler(self.SetExpTex, self))
end

function My:SetExpTex(tex)
  self.expTex.mainTexture = tex
end

function My:UnloadExpTex()
  local cfg = ItemData["14"]
  if cfg == nil then return end
  AssetMgr:Unload(cfg.icon, false)
end

function My:SetFlagActive(at)
  self.flagGo:SetActive(at)
end

--蓝色配置选项发生改变
function My:OnBlueChange()
  self:SetTogChange(2, self.blueTog.value)
end

--白色品质选项发生改变
function My:OnWhiteChange()
  self:SetTogChange(1, self.whiteTog.value)
end

--紫色品质选项发生改变
function My:OnPurpleChange()
  self:SetTogChange(3, self.purpleTog.value)
end

--紫色品质选项发生改变
function My:OnOrangeChange()
  self:SetTogChange(4, self.orangeTog.value)
end

function My:SetTogChange(qt, at)
  self:SetQualSelect(qt, at)
  if self.active == true then self:SetedExp() end
end

--设置某品质全部被选中
--qt(number):品质
--at(boolean):选中状态
function My:SetQualSelect(qt, at)
  local IsExp = RuneMgr.IsExp
  local dic, cfg = self.bag.dic, nil
  local exp = false
  for k, v in pairs(dic) do
    cfg = v.info.cfg
    exp = IsExp(cfg)
    if exp == true then
      v:SetSelect(true)
    elseif cfg ~= nil then
      if cfg.qt == qt then
        v:SetSelect(at)
      end
    end
  end
end

--设置经验符文选中状态
function My:SetExpSelect()
  local IsExp = RuneMgr.IsExp
  local dic, cfg = self.bag.dic, nil
  for k, v in pairs(dic) do
    cfg = v.info.cfg
    if IsExp(cfg) then
      v:SetSelect(true)
    end
  end
end

--背包条目选择/取消时
function My:Switch(it)
  self:SetedExp()
end

--获取可分解经验
function My:GetedExp()
  local geted, lvCfg = 0
  for k, v in pairs(self.bag.dic) do
    if v.isSelect then
      lvCfg = v.info.lvCfg
      if lvCfg then
        geted = geted + lvCfg.deExp
      end
    end
  end
  return geted
end

--设置可分解经验
function My:SetedExp()
  local geted = self:GetedExp()
  self:SetExp(geted)
end

--响应经验更新
function My:SetExp(geted)
  geted = geted or 0
  local exp = RuneMgr.exp
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd(exp):Apd("[00ff00] +"):Apd(geted)
  self.expLbl.text = sb:ToStr()
  ObjPool.Add(sb)
end

function My:RespExp()
  self:SetedExp()
  ParticleUtil.Play(self.fxGo)
end

--点击一键分解按钮
function My:OnClickOnekey()
  local filterDic = self.filterDic
  TableTool.ClearDic(filterDic)
  local ids = self.ids
  local dic = self.bag.dic
  ListTool.Clear(ids)
  local isFilter = nil
  local cfg, qt, info, uid
  local IsExp = RuneMgr.IsExp
  local IsEmbed = RuneMgr.IsEmbed
  for k, v in pairs(dic) do
    isFilter = false
    if v.isSelect then
      info = v.info
      uid = info.uid
      cfg = info.cfg
      qt = cfg.qt
      if qt > 3 then
        if not IsExp(cfg) then
          local k = tostring(qt)
          local fuid = filterDic[k]
          if fuid == nil then
            if IsEmbed(cfg) == false then
              filterDic[k] = uid
              isFilter = true
            end
          end
        end
      end
      if isFilter == false then ids[#ids + 1] = uid end
    end
  end

  local filterCnt = TableTool.GetDicCount(filterDic)
  if filterCnt > 0 then
    local msg = "选中符文中,存在" .. ColorCode.green .."橙色级别及以上的【未装备属性】的符文[-]" .. "是否各保留一个后分解"
    MsgBox.ShowYesNo(msg, self.ReqDecom, self, "保留分解", self.DirectDecom, self, "直接分解")
  else
    self:ReqDecom()
  end
end

function My:DirectDecom()
  local ids = self.ids
  for k, v in pairs(self.filterDic) do
    ids[#ids + 1] = v
  end
  self:ReqDecom()
end

--请求分解
function My:ReqDecom()
  local ids = self.ids
  if #ids < 1 then
    UITip.Log("无可分解符文")
  else
    self.rCntr:Lock(true)
    RuneMgr.ReqDecompose(ids)
  end
end

--响应分解
function My:RespDecom(err)
  self.rCntr:Lock(false)
  if err > 0 then return end
  local add = RuneMgr.exp - RuneMgr.lastExp
  local tip = "分解成功,获得" .. add .. "经验"
  UITip.Log(tip)
  self:SetedExp()
  --MsgBox.ShowYes(tip)
  --self.bag:SetGridPos(self.anchor.position)
end

function My:SetOrangeTogActive()
  local lv = UserMgr:GetRealLv()
  local at = (lv > 399)
  self.orangeTog.gameObject:SetActive(at)
  local fn = (at and "Remove" or "Add")
  UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.SetOrangeTogActive, self)
end

function My:Open()
  self.active = true
  local bag = self.bag
  bag:SetGrid(self.anchor, 2, 369)
  bag:SetScrollPanel(self.sPanel, self.sPanelY, self.sPanelOffsetY)
  self.blueTog.value = true
  self.whiteTog.value = true
  self.purpleTog.value = false
  self.orangeTog.value = false
  self:SetExpSelect()
  self:SetedExp()
  bag:SetMultiSelect(true)
  bag:SetAllExpHasdActive(true)
  bag:Open()
  self.fxGo:SetActive(false)
end

function My:Close()
  self.active = false
  self.blueTog.value = false
  self.whiteTog.value = false
  self.bag:Close()
  self.fxGo:SetActive(false)
  TableTool.ClearDic(self.filterDic)
end

function My:Dispose()
  self.bag = nil
  self:UnloadExpTex()
  ListTool.Clear(self.ids)
  TableTool.ClearUserData(self)
  UserMgr.eLvEvent:Remove(self.SetOrangeTogActive, self)
  RuneMgr.decomFlag.eChange:Remove(self.SetFlagActive, self)
end

return My
