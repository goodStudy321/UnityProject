--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 00:24:04
--=========================================================================

Foolish = Super:New{Name = "Foolish"}

local My = Foolish

function My:Ctor()
  self:Clear()
end

function My:Reset()

end

function My:Clear()
  self:Reset()
  --true:在管理中
  self.isRef = false
  --true:运行中
  self.running = false
  --true:自动放入对象池
  self.autoPool = false
end

function My:Update()

end


function My:Dispose()
  self:Clear()
end


function My:AutoToPool()
  if self.isRef then
    self.autoPool = true
  else
    ObjPool.Add(self)
  end
end

return My
