--[[
 	authors 	:Loong
 	date    	:2017-10-11 10:17:31
 	descrition 	:邮件界面
--]]

UIMail = UIBase:New{Name = "UIMail"}

local My = UIMail
local Mm = MailMgr

local UMI = require("UI/Mail/UIMailItem")
My.detail = require("UI/Mail/UIMailDetail")

--条目列表
My.items = {}

--条目字典
My.itDic = {}

function My:Init(root)
  --当前选择的ID
  self.curID = 0
  local des = self.Name
  self.root = root
  local CG = ComTool.Get
  local TFC = TransTool.FindChild
  local USBC = UITool.SetBtnClick

  USBC(root, "akeyGetBtn", des, self.AKeyGet, self)
  USBC(root, "delReadBtn", des, self.ReqDels, self)

  local SetSub = UIMisc.SetSub
  SetSub(self, self.detail, "detail")

  --UI排列表
  self.tbl = CG(UITable, root, "items/Table", des)
  self.tblTran = self.tbl.transform
  --条目模板
  self.itMod = TFC(root, "items/item", des)
  self.tbl.onCustomSort = self.CmpTran
  self.itMod:SetActive(false)

  self:AddLnsr()

end

--排序变换组件:参数(Transform)
function My.CmpTran(lhs, rhs)
  local lt = Mm.Get(lhs.name)
  local rt = Mm.Get(rhs.name)
  --print("lt:", lt, "lhs.name:", lhs.name, "rt:", rt, "rhs.name:", rhs.name)
  local res = Mm.Compare(lt, rt)
  if rt == nil then return 0 end
  return res
end

--排序邮件条目:参数(UIMailItem)
function My.CmpInfo(lhs, rhs)
  local li = lhs.info
  local ri = rhs.info
  local res = Mm.Compare(li, ri)
  if res < 0 then
    return true
  else
    return false
  end
end

--通过邮件索引设置下个邮件ID
--idx:(number)索引
function My:SetNextIDByIdx(idx)
  local its = self.items
  local len = #its
  if len < 1 then self.nID = 0 return end
  local nIdx = idx + 1
  if nIdx > len then
    self.nID = its[idx].info.id
  else
    self.nID = its[nIdx].info.id
  end
  --print("通过邮件索引设置下个邮件ID:", self.nID)
end

--通过邮件ID设置下个邮件ID
--idx:(number)索引
function My:SetNextIDByID(id)
  local it = self.itDic[tostring(id)]
  --print("通过邮件ID设置下个邮件ID ,当前邮件ID:", id)
  if it == nil then return end
  self:SetNextIDByIdx(it.idx)
end

--添加邮件
function My:Add(info)
  local k = tostring(info.id)
  local it = self.itDic[k]
  if it then return end
  local items = self.items
  it = ObjPool.Get(UMI)
  local tblTran = self.tblTran
  local tran = tblTran:Find("none")
  local k = tostring(info.id)
  local go = nil
  if tran == nil then
    go = Instantiate(self.itMod)
    tran = go.transform
    TransTool.AddChild(tblTran, tran)
  else
    go = tran.gameObject
  end
  go.name = k
  go:SetActive(true)
  it.info = info
  it.cntr = self
  it:Init(tran)
  items[#items + 1] = it
  self.itDic[k] = it
end

--移除所有数据中不存在的条目
function My:Removes()
  local dic = MailMgr.dic
  local itDic = self.itDic
  for k, v in pairs(itDic) do
    local info = dic[k]
    if info == nil then
      self:Remove(k)
    end
  end
end

--移除指定ID的条目
--id(number):邮件ID
function My:Remove(id)
  local itDic = self.itDic
  local k = tostring(id)
  local v = itDic[k]
  if v == nil then return end
  v:SetActive(false)
  v.go.name = "none"
  ObjPool.Add(v)
  itDic[k] = nil
  if self.curID ~= tonumber(k) then return end
  self.cur = nil
  self.curID = (-1)
end

--切换邮件
--it(UIMailItem)
function My:Switch(it)
  if it == nil then return end
  --print("切换邮件:", it.info.id)
  local cur = self.cur
  if cur == it then return end
  if cur then cur:SetSelect(false) end
  self.cur = it
  local curID = it.info.id
  self.curID = curID
  it:SetSelect(true)
  self.detail:Refresh()
  self:SetNextIDByID(curID)
end


--切换到下个邮件
function My:SwitchNext()
  local nID = self.nID
  if nID == 0 then return end
  local it = self.itDic[tostring(nID)]
  self:Switch(it)
end


--一键领取附件
function My:AKeyGet()
  local hasGoods = MailMgr.HasGoods()
  if hasGoods then
    MailMgr.ReqGoods(0)
    self:Lock(true)
  else
    UITip.Log("没有附件需要领取")
  end
end

--请求删除已读
function My:ReqDels()
  local readedNoGoods = MailMgr.ReadedNoGoods()
  if readedNoGoods then
    self:Lock(true)
    MailMgr.ReqDel(0)
  else
    UITip.Log("没有需要删除的邮件")
  end
end

--响应打开邮件
function My:RespOpen(err, idStr)
  self:Lock(false)
  if err > 0 then return end
  local it = self.itDic[idStr]
  if it == nil then return end
  --self:Resort()
  --self:SwitchNext()
  it:SetState()
end

--响应删除
--op:0删除所有已读无附件 1:删除指定ID邮件
--id(number):op为1时ID
function My:RespDel(err, op)
  self:Lock(false)
  if err > 0 then return end
  self:Removes()
  self:Resort()
  self:CheckNone()
  --MsgBox.ShowYes("删除成功")
  if op == 1 then self:SwitchNext() end
end

--响应获取附件
--op:0领取所有附件 1:领取指定ID附件
--id(number):op为1时ID,0时为nil
function My:RespGoods(err, op, id)
  self:Lock(false)
  if err > 0 then return end
  local itDic = My.itDic
  if op == 0 then
    for k, v in pairs(itDic) do
      v:SetState()
    end
  else
    k = tostring(id)
    local info = itDic[k]
    info:SetState()
  end
  --self:Resort()
  self.detail:RespGoods()
  UITip.Log("已获取附件")
  --if op == 1 then self:SwitchNext() end
end

--结束接收邮件
function My:EndGet(op)
  self:Resort()
  self:CheckNone()
  if self.cur then self.detail:Refresh() end
  for k, v in pairs(My.itDic) do v:SetState() end
end

--重新排列
function My:Resort()
  local items = self.items
  ListTool.Clear(items)
  local itDic = self.itDic
  for k, v in pairs(itDic) do
    items[#items + 1] = v
  end
  table.sort(items, self.CmpInfo)
  local cur = self.cur
  for i, v in ipairs(items) do
    v.idx = i
    v:SetSelect((v == cur))
  end
  --self.tbl:Reposition()
  self.tbl.repositionNow = true
end

--检查是否无邮件
function My:CheckNone()
  if #self.items > 0 then
    self.detail:Open()
    if self.cur == nil then
      local it = self.items[1]
      self:Switch(it)
      it:ReqOpen()
    end
  else
    self.detail:Close()
  end
end

--添加事件
function My:AddLnsr()
  self:SetLsnr("Add")
end

--移除事件
function My:RemoveLsnr()
  self:SetLsnr("Remove")
end

--设置监听
--fn(string):注册/注销名
function My:SetLsnr(fn)
  Mm.eAdd[fn](Mm.eAdd, self.Add, self)
  Mm.eEndGet[fn](Mm.eEndGet, self.EndGet, self)
  Mm.eOpen[fn](Mm.eOpen, self.RespOpen, self)
  Mm.eRespDel[fn](Mm.eRespDel, self.RespDel, self)
  Mm.eRespGoods[fn](Mm.eRespGoods, self.RespGoods, self)
end

function My:Open()
  self:Adds()
  self:Resort()
  --self:CheckNone()
  if Mm.ownNew then
    MailMgr.ReqGet()
  else
    MailMgr.FirstReq()
    self:CheckNone()
  end
end

function My:Adds()
  for k,v in pairs(MailMgr.dic) do
    self:Add(v)
  end
end

function My:Close()
  self.IsOpen = false
  self.nID = 0
  self.cur = nil
  self.curID = 0
end

function My:Clear()
  self.nID = 0
  self.cur = nil
  self.curID = 0
  self.detail:Clear()
  ListTool.Clear(self.items)
  TableTool.ClearDicToPool(self.itDic)
end

function My:Dispose()
  self:Clear()
  self:RemoveLsnr()
end

return My
