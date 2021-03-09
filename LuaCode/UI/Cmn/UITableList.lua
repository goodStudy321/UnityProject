--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong in 2018-05-10 11:32:49
-- 子类型需要重写SetItems
--==============================================================================


UITableList = Super:New{Name = "UITableList"}

local My = UITableList

function My:Ctor()
  --UIListItem子类型列表
  self.lst = {}
  self.select = false
end

--title(string):(标题)
--qt(number):用以分类的品质
--mod(条目游戏对象模板)
function My:Init(root, title, qt, mod)
  if root == nil then return end
  root.name = tostring(qt)
  self.root = root
  local des = self.Name
  local CG = ComTool.Get
  self.uiTbl = CG(UITable, root, "s/table", des)
  self.foldSp = CG(UISprite, root, "fold", des)
  self.titleLbl = CG(UILabel, root, "title", des)
  self.hlSp = ComTool.GetSelf(UISprite, root, des)
  self:SetItems(qt, mod)
  self:SetTitle(title)
  UITool.SetBtnSelf(root, self.Change, self, des, false)
end

--设置标题
function My:SetTitle(title)
  self.titleLbl.text = title or "无"
end

--设置列表
function My:SetItems(qt, mod)

end


--切换条目
--it(UIRuneComLstItem)
function My:Switch(it)
  local cntr = self.cntr
  if cntr == nil then return end
  cntr:Switch(it)
end

function My:Change()
  local cntr = self.cntr
  local nat = not self.select
  if nat then
    if cntr and cntr.Change then
        cntr:Change(self)
    end
  else
    self:SetSelect(false)
  end
end

--设置选择
function My:SetSelect(at)
  self.select = at
  local r, g, b = nil, nil, nil
  if at then
    r = 252 / 255
    g = 245 / 255
    b = 245 / 255
  else
    r = 244 / 255
    g = 221 / 255
    b = 189 / 255
  end
  local color = Color.SetVar(r, g, b)
  self.titleLbl.color = color
  self.foldSp.spriteName = (at and "ty_11" or "ty_13")
  self.hlSp.spriteName = (at and "ty_a15" or "ty_a4")
end


function My:Dispose()
  self.cntr = nil
  self.select = false
  TableTool.ClearUserData(self)
  ListTool.ClearToPool(self.lst)
end

return My
