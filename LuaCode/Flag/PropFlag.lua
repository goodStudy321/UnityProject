--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-08-11 15:42:22
-- 根据道具ID列表返回flag
--=========================================================================
require("Flag/Flag")
PropFlag = Flag:New{Name = "PropFlag"}

local My,base= PropFlag,Flag

--ids:道具ID
function My:Init(id)
  self.id = id
  base.Init(self)
  PropMgr.eUpdate:Add(self.Update, self)
end

function My:Update()
  if self.id == nil then return end
  local num = ItemTool.GetNum(self.id)
  num = num or 0
  if num > 0 then
    self.red = true
  else
    self.red = false
  end
  self.eChange(self.red)
end


function My:Dispose()
  base.Dispose(self)
  self.ids = nil
end

return My
