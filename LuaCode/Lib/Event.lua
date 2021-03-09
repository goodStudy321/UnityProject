--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-03 11:27:08
-- :事件
-- 1,创建:Event() or Event:New()
--==============================================================================

local EI = require("Lib/EventInfo")

Event = Super:New{Name = "Event"}

local My = Event

function Event()
  return ObjPool.Get(My)
  --return My:New()
end

My.__call = function(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  local dic = self.dic
  for k, v in pairs(dic) do
    v(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  end
end

function My:Ctor()
  --k=tostring(func)..tostring(obj) ,v:EventInfo
  self.dic = {}
  --拥有的事件数量
  self.size = 0
end


--添加/注册
--func(function):方法
--obj(table):对象
function My:Add(func, obj)
  if type(func) ~= "function" then
    iTrace.Error("Loong", "注册事件第一个参数必须是方法")
    return
  end
  local k = self:GetKey(func, obj)
  local dic = self.dic
  local e = dic[k]
  if e then return end
  self.size = self.size + 1
  e = ObjPool.Get(EI)
  e.func = func
  e.obj = obj
  dic[k] = e
end

--移除/注销
--func(function):方法
--obj(table):对象
function My:Remove(func, obj)
  local k = self:GetKey(func, obj)
  local dic = self.dic
  local e = dic[k]
  if not e then return end
  self.size = self.size - 1
  ObjPool.Add(e)
  dic[k] = nil
end

--获取键值
function My:GetKey(func, obj)
  local funcStr = tostring(func)
  local k = funcStr
  if obj then
    k = k .. tostring(obj)
  end
  return k
end

function My:Clear()
  self.size = 0
  TableTool.ClearDicToPool(self.dic)
end

function My:Dispose()
  self:Clear()
end

return My
