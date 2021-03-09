--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-06-21 11:44:53
-- 数字部分会显示 消耗数量/拥有的数量,并且拥有数量不足时显示红色
--=========================================================================


UIItemOwn = UIItemCell:New{Name = "UIItemOwn"}

local My = UIItemOwn


function My:UpLab(num)
  local id = nil
  local idStr = self.type_id
  if idStr then
    id = tonumber(idStr)
  elseif self.item then
    id = self.item.id
  end
  local own = ItemTool.GetNum(id)
  local color = (own < num) and "[e83030]" or "[67cc67]"

  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("[ffe9bd]"):Apd(color):Apd(num)
  sb:Apd("[-]/"):Apd(own)
  local str = sb:ToStr()
  ObjPool.Add(sb)
  self.Lab.text = str
end

return My
