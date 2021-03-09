--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/9/10 下午12:02:25
--=============================================================================


UIItemsTable = Super:New{ Name = "UIItemsTable" }

local My = UIItemsTable


----BEG PUBLIC

function My:Init(tbl)
  self.tbl = tbl
  self.root = tbl.transform
end

----END PUBLIC
function My:Ctor()
  --道具kvs列表
  self.kvs = nil
  --道具条目UI列表
  self.items = {}
end

--kn(string):id字段名称
--vn(string):数量字段名称
--qn(string):特效字段名称
--bn(string):绑定字段名称
function My:Refresh(kvs, kn, vn, qn, bn, scale)
    if kvs == nil then return end
    if kvs == self.kvs then return end
    kn = kn or "k"
    vn = vn or "v"
    qn = qn or "q"
    self.kvs = kvs
    self.scale = scale
    local tbl ,items = self.tbl, self.items
    local id, num,isQua= nil, nil, nil
    for i, v in ipairs(kvs) do
      self.cur = v
      local it = ObjPool.Get(UIItemCell)
      it:InitLoadPool(self.root, scale)
      id = v[kn]
      num = v[vn] or 1
      qn = v[qn]
      isQua = (qn and (qn==1) or false)
      it:UpData(id, num, isQua)
      if bn then
        local ib = (v[bn] == 1)
        it:UpBind(ib)
      end
      items[#items + 1] = it
    end
    self.tbl:Reposition()
end


function My:Dispose()
    self.kvs = nil
    ItemTool.Clear(self.items)
end


return My