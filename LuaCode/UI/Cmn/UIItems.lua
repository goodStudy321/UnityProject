--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-15 15:13:07
-- 道具列表:通过索引设置消耗列表,需要传入kv接口的列表,k:ID,v:数量
--==============================================================================


UIItems = Super:New{Name = "UIItem"}


local My = UIItems

function My:Ctor()
  --道具kvs列表
  self.kvs = nil
  --道具条目UI列表
  self.items = {}
end

function My:Init(root)
  self.root = root
  local des = self.Name
  --排列表
  -- self.uiTbl = ComTool.GetSelf(UITable, root, des)
  --道具模板
  LoadPrefab("ItemCell",GbjHandler(self.SetItMod, self))
  self:CreateNone()
end

function My:SetItMod(go)
  --物品模板(G)
  self.itMod = go
  go:SetActive(false)
  TransTool.AddChild(self.root, go.transform)
end

function My:CreateNone()
  local go = GameObject.New()
  go.name = "none"
  go:SetActive(false)
  local tran = go.transform
  self.nTran = tran
  TransTool.AddChild(self.root, tran)
end

function My:ClearItems()
  local c, p = nil, self.nTran
  for i, v in ipairs(self.items) do
    c = v.trans
    c.name = "none"
    c.parent = p
  end
  ListTool.ClearToPool(self.items)
end

function My:Refresh(kvs,kn,vn)
  if kvs == nil then return end
  if kvs == self.kvs then return end
  kn = kn or "k"
  vn = vn or "v"
  self.kvs = kvs
  self:ClearItems()
  local nTran, go, c = self.nTran, nil, nil
  local items, itMod = self.items, self.itMod
  -- local uiTblTran, it = self.uiTbl.transform, nil
  local it = nil
  for i, v in ipairs(kvs) do
    c = nTran:Find("none")
    if c then
      go = c.gameObject
    else
      go = Instantiate(itMod)
      c = go.transform
    end
    go.name = tostring(v[kn])
    -- c.parent = uiTblTran
    c.parent = self.root
    c.localPosition = Vector3.zero
    c.localScale = Vector3.one * 0.8
    go:SetActive(true)
    it = ObjPool.Get(UIItemCell)
    it:Init(go)
    it:UpData(v[kn], v[vn], true)
    items[#items + 1] = it
  end
  -- self.uiTbl:Reposition()
end


function My:Switch(it)
  UIMisc.SetSelect(self, it)
end

function My:Dispose()
  self.kvs = nil
  ListTool.ClearToPool(self.items)
end

return My
