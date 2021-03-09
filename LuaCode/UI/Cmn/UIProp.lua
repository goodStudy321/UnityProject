--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-24 11:08:17
-- UI属性模块
-- 1,属性条目(名称,值)
-- 2,排序按拉丁字母顺序排序
--=============================================================================

local UPI = require("UI/Cmn/UIPropItem")

UIProp = Super:New{Name = "UIProp"}

local My = UIProp

function My:Ctor()
  --条目字典 k:属性字段,v:UIPropItem
  self.itDic = {}
end

function My:Init(root)
  self.go = root.gameObject
  local des = self.Name
  local CG = ComTool.Get
  self.mod = TransTool.FindChild(root, "item", des)
  self.mod:SetActive(false)
  --UITable组件
  self.uiTbl = CG(UITable, root, "Scroll/Table", des)
  self.uiTbl.onReposition = UITable.OnReposition(self.OnReposEnd, self)
  self.tblTran = self.uiTbl.transform
  self.active = true
  self:SetActive(false)
  local go = GameObject.New("none")
  go:SetActive(false)
  self.none = go.transform
  TransTool.AddChild(root,self.none)
  local close = root:Find("close")
  if close then 
    UITool.SetLsnrSelf(close, self.Close, self, des) 
  end
end

function My:SetActive(at)
  if at == nil then at = false end
  if at == self.active then return end
  self.active = at
  self.go:SetActive(at)
end

function My:Open()
  self:SetActive(true)
end

function My:Close()
  self:SetActive(false)
end

--获取名称
--k 属性ID的字符串
function My:GetName(k)
  local p = BinTool.Find(PropName, tonumber(k))
  local name = p and p.name or ("无ID:" .. k)
  return name
end

--添加属性条目
--k 属性ID的字符串
--v 属性值
function My:Add(k, v)
  local go = GameObject.Instantiate(self.mod)
  local tran = go.transform
  TransTool.AddChild(self.tblTran, tran)
  local it = ObjPool.Get(UIPropItem)
  self.itDic[k] = it
  it:Init(tran)
  local name = self:GetName(k)
  local pn = (#k == 1) and k or ("0" .. k)
  it.go.name = pn
  local id = tonumber(k)
  local str = PropTool.GetValByID(id, v)
  it:SetCur(str)
  it:SetName(name)
  it:SetActive(true)
end

--刷新
--属性字典 k:属性ID,v:属性值
function My:Refresh(dic)
  if type(dic) ~= "table" then return end
  local itDic = self.itDic

  local it, cur, str = nil
  local GetValByID = PropTool.GetValByID
  --添加数据字典中没有的字段
  for k, v in pairs(dic) do
    it = itDic[k]
    if it then
      str = GetValByID(tonumber(k), v)
      it:SetCur(str)
      it:SetActive(true)
    else
      self:Add(k, v)
    end
  end

  --隐藏数据字典中没有的字段
  for k, v in pairs(itDic) do
    local db = dic[k]
    if not db then
      v:SetActive(false)
    end
  end

  self.uiTbl:Reposition()
end

--通过列表刷新：条目(table(id,value)
function My:RefreshByList(lst)
  if type(lst) ~= "table" then return end
  local itDic = self.itDic
  local it, cur, str = nil
  local GetValByID = PropTool.GetValByID

  local none = self.none
  for k, v in pairs(itDic) do
      v.go.transform.parent = none
  end

  --添加数据字典中没有的字段
  for i, v in pairs(lst) do
    local k = tostring(v.k)
    it = itDic[k]
    if it then
      str = GetValByID(tonumber(k), v.v)
      it:SetCur(str)
      it:SetActive(true)
      TransTool.AddChild(self.tblTran, it.go.transform)
    else
      self:Add(k, v.v)
    end
  end

  

  self.uiTbl:Reposition()
end
--排序结束
--lst(List<Transform>):变换组件列表
function My:OnReposEnd(lst)
  local count = lst.Count - 1
  if count < 0 then return end
  local itDic = self.itDic
  local SCA = TransTool.SetChildActive
  local tran = nil
  local at = false
  for i = 0, count do
    tran = lst[i]
    SCA(tran, "bg", at)
    at = not at
  end
end

function My:Dispose()
  TableTool.ClearUserData(self)
  TableTool.ClearDicToPool(self.itDic)
end

return My
