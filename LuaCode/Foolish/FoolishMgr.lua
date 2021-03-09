--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 00:23:31
--=========================================================================

require("Foolish/Foolish")
FoolishMgr = Super:New{Name = "FoolishMgr"}

local My = FoolishMgr


function My:Init()
  --元素列表
  self.lst = {}
  self.len = 0
end


function My:Update()
  if self.lst == nil then return end
  self.len = #self.lst
  if self.len == 0 then return end
  for i = self.len, 1, (-1) do
    self.cur = self.lst[i]
    if self.cur.running then
      self.cur:Update()
    else
      ListTool.Remove(self.lst, i)
      if (self.cur.autoPool) then
        ObjPool.Add(self.cur)
      end
      self.cur.isRef = false
    end
  end
end

function My:Add(t)
  if t == nil then return end
  t.running = true
  if t.isRef then return end
  t.isRef = true
  self.lst[#self.lst + 1] = t
end

function My:Clear()
  ListTool.Clear(self.lst)
end

function My:Dispose()
  self:Clear()
end


return My
