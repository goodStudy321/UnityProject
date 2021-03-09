--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-15 15:13:07
-- 固定数量,固定位置道具列表:通过索引设置消耗列表
--==============================================================================


UISolidItems = Super:New{Name = "UIItem"}

local UIItem = require("UI/Cmn/UIItem")

local My = UISolidItems

function My:Ctor()
  --道具ID列表
  self.ids = nil
  --道具条目UI列表
  self.items = {}
end

function My:Init(root)
  self.root = root
  self:AddLsnr()
end

function My:Refresh(ids)
  if ids == nil then return end
  if ids == self.ids then return end
  local items, it = self.items, nil
  local cur = self.cur
  self.cur = nil
  if cur then cur:SetSelect(false) end
  self.ids = ids
  if #items < 1 then
    local TF, des, root = TransTool.Find, self.Name, self.root
    local GC, tran, cpath = ItemTool.GetCfg, nil, nil
    for i, v in ipairs(ids) do
      it = ObjPool.Get(UIItem)
      cpath = "icon" .. i
      tran = TF(root, cpath, des)
      it.cfg = GC(v)
      it.cntr = self
      it:Init(tran)
      items[i] = it
    end
  else
    for i, v in ipairs(ids) do
      it = items[i]
      it:RefreshByID(v)
    end
  end

  local num = 0
  local GetNum = ItemTool.GetNum
  for i, v in ipairs(ids) do
    num = GetNum(v)
    if self.cur == nil and num > 0 then
      self:Switch(items[i])
    end
  end
  if self.cur == nil then
    self:Switch(items[1])
  end
end
--设置道具数量
function My:SetNums()
  for i, v in pairs(self.items) do
    v:Refresh()
  end
end

function My:Switch(it)
  if it == self.cur then
    PropTip.pos = it.root.transform.position
		PropTip.width = it.qtSp.width
    UIMgr.Open("PropTip", self.ShowTip, self)
  end
  UIMisc.SetSelect(self, it)
end

function My:ShowTip(name)
  local ui = UIMgr.Get(name)
  local id = self.cur.cfg.id
  ui:UpData(id)
end

function My:AddLsnr()
  PropMgr.eUpdate:Add(self.SetNums, self)
end

function My:RmvLsnr()
  PropMgr.eUpdate:Remove(self.SetNums, self)
end

--清除神兵升级消耗texture
function My:ClearIcon()
  if self.items then
    for k,v in pairs(self.items) do
      -- v.cfg = nil
      -- v.cntr = nil
      v:ClearIcon()
    end
  end
  self.ids = nil
end

--将item放入对象池
function My:ItemToPool()
  local len = #self.items
  while len > 0 do
    local item = self.items[len]
    if item then
      item.cfg = nil
      item.cntr = nil
      table.remove(self.items, len)
      ObjPool.Add(item)
    end
    len = #self.items
  end
end

function My:Dispose()
  self:ClearIcon()
  self:ItemToPool()
  self.cur = nil
  self.ids = nil
  self:RmvLsnr()
  -- if #self.items > 0 then
  --   for k,v in pairs(self.items) do
	-- 		AssetTool.UnloadTexture(v.iconTex)
	-- 		self.items[k] = nil
	-- 		ObjPool.Add(v)
	-- 	end
  -- end
  -- TableTool.ClearListToPool(self.items)
  -- ListTool.ClearToPool(self.items)
end

return My
