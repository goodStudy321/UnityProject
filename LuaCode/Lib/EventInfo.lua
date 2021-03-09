--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-03 11:28:33
-- :事件信息
-- 1,参数传递没有采用可变参数列表,调用时最多传递8个参数
-- 2,调用时做了保护
--==============================================================================


local xpcall = xpcall
EventInfo = Super:New{Name = "EventInfo"}

local traceback = function(msg)
  iTrace.Error("Loong", "err info:", msg)
end

local My = EventInfo

--调用
My.__call = function (self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  local obj = self.obj
  local func = self.func
  if obj then
    xpcall(func, traceback, obj, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  else
    xpcall(func, traceback, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  end
end

--比较是否相等
My.__eq = function (lhs, rhs)
  if lhs == nil or rhs == nil then return false end
  if lhs.obj == nil or rhs.obj == nil then return false end
  if lhs.func == nil or rhs.func == nil then return false end
  local res = (lhs.func == rhs.func and lhs.obj == rhs.obj)
  return res
end

function My:Dispose()
  self.obj = nil
  self.func = nil
end

return My
