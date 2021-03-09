--[[
 	author 	    :Loong
 	date    	:2018-01-22 16:45:02
 	descrition 	:符文镶嵌背包
--]]


UIRuneEmbedBag = Super:New{Name = "UIRuneEmbedBag"}

local My = UIRuneEmbedBag

function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local des = self.Name
  local USBC = UITool.SetBtnClick
  local CG = ComTool.Get

  --锚点变换组件
  self.anchor = TransTool.Find(root, "Scroll/anchor", des)
  self.sPanel = CG(UIPanel, root, "Scroll", des)
  self.sPanelY = self.sPanel.transform.localPosition.y
  self.sPanelOffsetY = self.sPanel.clipOffset.y
  --容量标签
  self.capLbl = CG(UILabel, root, "cap", des)
  --替换按钮标签
  self.repLbl = CG(UILabel, root, "repBtn/lbl", des)
  USBC(root, "close", des, self.Close, self)
  USBC(root, "repBtn", des, self.OnClickRep, self)
  USBC(root, "getBtn", des, self.OnClickGet, self)
  self:SetCapacity()
end

--设置容量
function My:SetCapacity()
  local cnt ,IsExp= 0,RuneMgr.IsExp
  for k,v in pairs(RuneMgr.bagDic) do
    if not IsExp(v.cfg) then
      cnt = cnt + 1
    end
  end
  local str = tostring(cnt)
  self.capLbl.text = str
end

--检查同类型的符文
function My:CheckType()

end

function My:OnClickGet()
  local isOpen = UITabMgr.IsOpen(ActivityMgr.TTT)
	if isOpen then
    JumpMgr:InitJump("UIRune", 1)
    UIMgr.Open("UICopyTowerPanel")
	else
		UITip.Log("系统未开启")
	end
end

--点击替换按钮事件
function My:OnClickRep()
  --print("镶嵌背包替换按钮")
  local cur = self.cntr.bag.realBag.cur
  if cur == nil then
    UITip.Error("没有选中任何符文")
    return
  end
  local info = cur.info
  if info == nil then return end
  local slot = self.cntr.slot
  local idx = slot.cur.idx
  if info.cfg == nil then 
    UITip.Error("发生意外错误,建议重启游戏")
    return
  end
  local hasSame = slot:HasSame(idx, info.cfg.ty)
  if hasSame then
    UITip.Error("无法重复镶嵌此类型的符文")
  else
    local uid = info.uid
    --EventMgr.Trigger("ReqRuneEquip", uid, idx)
    RuneMgr.ReqEquip(uid, idx)
    self.rCntr:Lock(true)
  end
end

--设置替换按钮文本
function My:SetRepLbl()
  local it = self.cntr.slot.cur
  if it == nil then return end
  local embed = it:IsEmbedded()
  local text = embed and "替换" or "佩戴"
  self.repLbl.text = text
end

--响应背包更新
function My:RespBag()
  self:SetCapacity()
end

function My:Open()
  -- local count = TableTool.GetDicCount(RuneMgr.bagDic)
  -- if count < 1 then 
  --   UITip.Error("当前背包内没有符文") 
  -- else
    self.go:SetActive(true)
    local realBag = self.realBag
    realBag:SetGrid(self.anchor, 2, 369)
    realBag:SetScrollPanel(self.sPanel, self.sPanelY, self.sPanelOffsetY)
    realBag:SetMultiSelect(false)
    realBag:SetAllExpHasdActive(false, true)
    realBag:Open()
    self:SetRepLbl()
  -- end
end

function My:Close()
  self.go:SetActive(false)
  self.realBag:SetAllSelect(false)
end

function My:Dispose()
  self.realBag = nil
  TableTool.ClearUserData(self)
end


return My
