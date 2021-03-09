--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-24 11:08:36
--=============================================================================

UIPropItem = Super:New{Name = "UIPropItem"}

local My = UIPropItem

function My:Init(root)
  self.go = root.gameObject
  local des = self.Name
  local CG = ComTool.Get
  --当前值
  self.curLbl = CG(UILabel, root, "cur", des)
  --名称
  self.nameLbl = CG(UILabel, root, "name", des)
  self.active = false
  self:SetActive(true)
end

--设置当前值
function My:SetCur(val)
  self.curLbl.text = tostring(val)
end

--设置名称
function My:SetName(name)
  self.nameLbl.text = name
end

function My:SetActive(at)
  if at == nil then at = false end
  if at == self.active then return end
  self.active = at
  self.go:SetActive(at)
end

--pid(number):属性ID
--val(number):属性值
function My:SetByCfg(pid,val)
  local pCfg = BinTool.Find(PropName, pid)
  local pName = pCfg and pCfg.name or "无" .. pid
  local pStr = PropTool.GetVal(pCfg, val)
  self.nameLbl.text = pName
  self.curLbl.text = pStr
end

function My:Dispose()
  TableTool.ClearUserData(self)
end

return My
