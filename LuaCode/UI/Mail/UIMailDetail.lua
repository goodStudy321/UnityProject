--[[
 	authors 	:Loong
 	date    	:2017-10-13 17:13:27
 	descrition 	:邮件面板详细视图
--]]

UIMailDetail = Super:New{Name = "UIMailDetail"}


local My = UIMailDetail

--附件列表 (UIItemCell)
My.goods = {}

function My:Init(root)
  self.root = root
  local des = self.name
  self.go = root.gameObject
  local CG = ComTool.Get
  local TF = TransTool.Find
  local UL = UILabel
  self.contLbl = CG(UL, root, "cont/lbl", des)
  self.titleLbl = CG(UL, root, "title", des)
  self.contLbl.text = ""
  self.titleLbl.text = ""
  local srcLbl = CG(UL, root, "src", des)
  srcLbl.text = "系统"

  self.btnLbl = CG(UL, root, "getBtn/lbl", des)
  self.uiTbl = CG(UITable, root, "items/Table", des)
  self.tblTran = self.uiTbl.transform
  
  LoadPrefab("ItemCell",GbjHandler(self.SetItMod, self))
  
  local USC = UITool.SetLsnrClick
  USC(root, "getBtn", des, self.OnClick, self)
  USC(root, "cont/lbl", des, self.OnClickCont, self, false)
end

function My:SetItMod(go)
  --物品模板(G)
  self.itMod = go
  go:SetActive(false)
  TransTool.AddChild(self.root, go.transform)
end


--刷新
--it(UIMailItem)
function My:Refresh()
  --if not self.cntr.root.gameObject.activeSelf then return end
  local it = self.rCntr.cur
  if it == nil then return end
  local info = it.info
  self.titleLbl.text = info.title
  self.contLbl.text = info.cont
  self:SetBtnText()
  self:ClearGoods()
  self:SetGoods()
end

--设置点击按钮字符
function My:SetBtnText()
  local cur = self.rCntr.cur
  local str = "无"
  if cur then
    local info = cur.info
    if info then
      local has = info:HasGoods()
      str = has and "领取" or "删除"
    end
  end
  self.btnLbl.text = str
end

--设置物品
function My:SetGoods()
  local cur = self.rCntr.cur
  local data = cur.info.goods
  if data == nil then return end
  local itMod = self.itMod
  local goods = self.goods
  local tblTran = self.tblTran
  local Inst = GameObject.Instantiate
  local TA = TransTool.AddChild
  local go, tran, name = nil
  for i, v in ipairs(data) do
    local it = ObjPool.Get(UIItemCell)
    name = tostring(i)
    tran = tblTran:Find(name)
    if tran == nil then
      go = Inst(itMod)
      tran = go.transform
      TA(tblTran, tran)
      go.name = name
    else
      go = tran.gameObject
    end
    it:Init(go)
    it:TipData(v, v.num)
    go:SetActive(true)
    goods[#goods + 1] = it
    --print("添加物品:", v.type_id, "索引:", i)
  end
  self.uiTbl:Reposition()
end

--清理物品
function My:ClearGoods()
  local goods = self.goods
  while #goods > 0 do
    local it = table.remove(goods)
    local go = it.trans.gameObject
    go:SetActive(false)
    ObjPool.Add(it)
  end
end

--响应提取物品
function My:RespGoods()
  self:ClearGoods()
  self:SetBtnText()
end

--点击按钮事件
function My:OnClick(go)
  local rCntr = self.rCntr
  local cur = rCntr.cur
  if cur == nil then
    MsgBox.ShowYes("没有任何邮件")
    return
  end
  local info = rCntr.cur.info
  if info == nil then
    Destroy(go)
    rCntr.cur = nil
    return
  end
  local has = info:HasGoods()
  local id = info.id
  if has then
    --print("请求领取邮件物品:", id)
    MailMgr.ReqGoods(1, id)
  else
    --print("请求删除单个邮件:", id)
    MailMgr.ReqDel(1, id)
  end
  rCntr:Lock(true)
end

--点击文本
function My:OnClickCont(go)
  local lastPos = UICamera.lastWorldPosition
  local k = self.contLbl:GetUrlAtPosition(lastPos)
  if k then
    local list = StrTool.Split(k, "_")	
    local id = tonumber(list[1])
    if id == 75 or id == 76 then
      FamilyEscortMgr:ClickUrl(list[2], list[3], list[4])
    else
      UITabMgr.OpenByCfg(id)
    end
  end
end

function My:SetActive(at)
  if at == nil then at = false end
  if self.active == at then return end
  if at then
    self:Open()
  else
    self:Close()
  end
end

function My:Open()
  self.active = true
  self.go:SetActive(true)
end

function My:Close()
  self.active = false
  self.go:SetActive(false)
end

function My:Clear()
  self.cur = nil
  ListTool.ClearToPool(self.goods)
end

function My:Dispose()
  self:Clear()
  TableTool.ClearUserData(self)
end

--对附件列表进行排序
function My.CmpID(lhs, rhs)
  local goods = self.goods
  local ln = Mam.Get(lhs.name)
  local rn = Mam.Get(rhs.name)
  local lif = goods[ln]
  local rif = goods[rn]
  local lid = lhs.id
  local rid = rhs.id
  if lid < rid then
    return - 1
  elseif lid > rid then
    return 1
  end
  return 0
end

return My
