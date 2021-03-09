--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-06-21 01:07:54
--=========================================================================
require("UI/Cmn/UIItem")
UIAdvQualItem = UIItem:New{Name = "UIAdvQualItem"}

local My = UIAdvQualItem
local base = UIItem

function My:Init(root)
  self.useGo = TransTool.FindChild(root, "use", self.Name)
  self.useLab = ComTool.Get(UILabel, root, "useLab")
  self.useGoAt = true
  self:SetUseGoActive(false)
  base.Init(self, root)
end

function My:SetUseGoActive(at)
  if at == self.useGoAt then return end
  self.useGo:SetActive(at)
  self.useGoAt = at
end

function My:SetNumber()
  local id = self.cfg.id
  local k = tostring(id)
  local used = self.qualDic[k]
  local maxNum = self.qualMaxNum
  local canUsed = ""
  used = used or 0
  self.numLbl.text = tostring(used)
  local own = ItemTool.GetNum(id)
  if own > 0 and used < maxNum then
    canUsed = string.format( "+%s",own)
    self:SetUseGoActive(true)
  elseif own > 0 and used >= maxNum then
    self:SetUseGoActive(false)
  elseif own <= 0 then
    self:SetUseGoActive(false)
  end
  self.useLab.text = canUsed
end


function My:Dispose()
  base.Dispose(self)
  self.qualDic = nil
  self.useGoAt = false
  self.useGo = nil
end


return My
