--[[
 	author 	    :Loong
 	date    	:2018-01-18 19:24:39
 	descrition 	:符文合成面板
--]]
local LST = require("UI/Rune/UIRuneComLst")
local URCI = require("UI/Rune/UIRuneComItem")

UIRuneCompose = Super:New{Name = "UIRuneCompose"}
local My = UIRuneCompose

My.prop = require("UI/Rune/UIRuneProp")

--合成列表(UIRuneComLst)
My.lst = {}

--UIRuneComLstItem
My.cur = nil

--获取符文
My.get = URCI:New()

--消耗符文1
My.con1 = URCI:New()

--消耗符文2
My.con2 = URCI:New()

--符文精粹
My.ess = URCI:New()

My.tip = require("UI/Rune/UIRuneTip")

function My:Init(root)
  local des = self.Name
  self.root = root
  local CG = ComTool.Get
  local TF = TransTool.Find
  local TFC = TransTool.FindChild

  local USBC = UITool.SetBtnClick
  self.fxGo = TFC(root, "UI_Fw", des)
  self.fxGo:SetActive(false)
  USBC(root, "comBtn", des, self.OnClickCom, self)
  self.uiTbl = CG(UITable, root, "scroll/table", des)
  local tblTran = self.uiTbl.transform
  self.tblTran = tblTran

  --列表模板
  self.pMod = TFC(tblTran, "p", des)
  --条目模板
  self.item = TFC(root, "scroll/item", des)
  self.item:SetActive(false)

  --设置消耗符文和获取符文条目
  local getTran = TF(root, "get", des)
  self.get:Init(getTran, self)
  local con1Tran = TF(root, "con1", des)
  self.con1:Init(con1Tran, self)
  local con2Tran = TF(root, "con2", des)
  self.con2:Init(con2Tran, self)

  local propTran = TF(root, "prop", des)
  self.prop:Init(propTran)

  local essTran = TF(root, "essence", des)
  self.ess:Init(essTran, self)

  -- local tipTran = TF(root, "tip", des)
  -- self.tip:Init(tipTran)
  -- self.tip:SetActive(false)

  --self:SetEssence()
  self:SetList()
  self.setFirst = false
  CopyMgr.eUpdateTower:Add(self.UpdateLock, self)
end

--设置属性列表
function My:SetList()
  --红色,5;橙色,4;紫色,3
  local uiTbl = self.uiTbl

  self:Add("橙色双属性", 4)
  self:Add("红色双属性", 5)
  --self:Add("紫色双属性", 4)

  uiTbl:Reposition()
  Destroy(self.pMod)
  Destroy(self.item)
  self.item = nil
  self.pMod = nil
  self.uiTbl = nil
  self.tblTran = nil
end

--it(UIRuneComLst)
function My:Change(it)
  for i,v in ipairs(self.lst) do
    local at = (it==v)
    v:SetSelect(at,true)
  end
end

--添加到合成列表
--title:标题
--qt(资质)
function My:Add(title, qt)
  local tblTran = self.tblTran
  local Inst = GameObject.Instantiate
  local lstMod = Inst(self.pMod)
  local tran = lstMod.transform
  TransTool.AddChild(tblTran, tran)
  local it = ObjPool.Get(LST)
  it.cntr = self
  it:Init(tran, title, qt, self.item)
  self.lst[#self.lst + 1] = it
end

function My:UpdateLock()
  for i,v in ipairs(self.lst) do
    for j,it in ipairs(v.lst) do
      it:SetLockActive()
    end
  end
end

function My:SetFirst()
  self.setFirst = true
  local lst = self.lst
  for i,v in ipairs(lst) do
    if v.firstIt then
      self:Switch(v.firstIt)
      v:SetSelect(true, true)
      return
    end
  end
  local it = lst[1].firstPass
  if it then
      self:Switch(it)
      lst[1]:SetSelect(true, true)
  end
end

--切换合成列表条目
--it(UIRuneComLstItem)
function My:Switch(it)
  if it == nil then return end
  local cur = self.cur
  if cur == it then return end
  if cur then cur:SetSelect(false) end
  it:SetSelect(true)
  self.cur = it
  local comCfg = it.comCfg
  self.prop:RefreshByID(comCfg.id)
  self:SetConGet(comCfg)
  self:SetEssence()
  local ess = self.ess
  if ess.itCfg == nil then
    ess:RefreshByItemID(101)
  end
end

function My:OnClickItem(it)
  self.it=it
  UIMgr.Open(UITreasRuneTip.Name, self.OpenRuneTip, self)
  -- self.tip:Refresh(it.cfg)
  -- self.tip:Open()
end

--符文Tip的回调方法
function My:OpenRuneTip(name)
	local ui = UIMgr.Get(name)
    if(ui)then
		    ui:Refresh(self.it.cfg)
    end
end


--设置消耗和合成符文
function My:SetConGet(comCfg)
  local con1, con2 = self.con1, self.con2
  con1:RefreshByID(comCfg.cid1)
  con1:SetNumber()
  con2:RefreshByID(comCfg.cid2)
  con2:SetNumber()
  self.get:RefreshByID(comCfg.id)
  --self.get:SetMaxNum(con1, con2)
end

--点击合成按钮事件
function My:OnClickCom()
  --print("点击合成按钮事件")
  local cur = self.cur
  if cur == nil then
    local tip = "未选择要合成的符文"
    UITip.Log(tip)
    --MsgBox.ShowYes(tip)
    return
  else
    local own = RuneMgr.essence
    local need = cur.comCfg.con
    if own < need then
      local tip = "缺少" ..  self.ess.itCfg.name
      UITip.Error(tip)
      --MsgBox.ShowYes(tip)
      return
    end
  end
  local comCfg = cur.comCfg
  local con1 = self.con1
  local con2 = self.con2
  if not self:CheckConNum(con1) then return end
  if not self:CheckConNum(con2) then return end
  local bid = comCfg.id
  --EventMgr.Trigger("ReqRuneCompose", bid)
  RuneMgr.ReqCompose(bid)
  self.rCntr:Lock(true)
end

--返回false 条件无法通过
function My:CheckConNum(con)
  local res = con:CheckNumber()
  if not res then
    local tip = "缺少:" .. con.cfg.name
    UITip.Log(tip)
    --MsgBox.ShowYes(tip)
  end
  return res
end


function My:SetEssence()
  local cur = self.cur
  local text = tostring(RuneMgr.essence)
  if cur then
    text = StrTool.Concat(text, "/", cur.comCfg.con)
  end
  self.ess:SetNumLbl(text)
end

function My:RespEssence()
  self:SetEssence()
end

--刷新合成符文数量
function My:SetNumber()
  self.con1:SetNumber()
  self.con2:SetNumber()
  --self.get:SetMaxNum(self.con1, self.con2)
end

function My:RespCom(err)
  self.rCntr:Lock(false)
  if err > 0 then return end
  ParticleUtil.Play(self.fxGo)
  Audio:PlayByID(113)
  local tip = "合成成功"
  UITip.Log(tip)
end

function My:RespBag()
  if not self.cur then return end
  self:SetNumber()
end

function My:Open()
  if not self.setFirst then self:SetFirst() end
end

function My:Close()
  self.fxGo:SetActive(false)
end

function My:Dispose()
  self.cur = nil
  self.cntr = nil
  self.rCntr = nil
  self.get:Dispose()
  self.con1:Dispose()
  self.con2:Dispose()
  self.prop:Dispose()
  self.ess:Dispose()
  ListTool.ClearToPool(self.lst)
  TableTool.ClearUserData(self)
  CopyMgr.eUpdateTower:Remove(self.UpdateLock, self)
end

return My
