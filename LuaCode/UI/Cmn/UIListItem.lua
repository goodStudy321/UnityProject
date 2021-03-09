--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong in 2018-05-10 11:33:22
-- 继承此类型时,需要重写:SetName,Dispose
--              需要设置idx(索引)属性值,用以区分背景
--==============================================================================


UIListItem = Super:New{Name = "UIListItem"}

local My = UIListItem

function My:Init(root)
  local des = self.Name
  local CG = ComTool.Get
  UITool.SetLsnrSelf(root, self.OnClick, self, des, false)
  self.nameLbl = CG(UILabel, root, "name", des)
  --高亮精灵
  self.hlSp = ComTool.GetSelf(UISprite, root, des)
  UIMisc.SetListItemSp(self, false)
  self:SetName()
end

--点击
function My:OnClick(go)
  local cntr = self.cntr
  if cntr == nil then return end
  cntr:Switch(self)
end

--设置名称
function My:SetName()
  
end

--设置选中
function My:SetSelect(at)
  if at == nil then at = false end
  local color = at and Color.SetVar(1, 0.91, 0.74) or Color.SetVar(0.69, 0.64, 0.58)
  self.nameLbl.color = color
  UIMisc.SetListItemSp(self, at)
end

function My:Dispose()
  self.cntr = nil

end

return My
