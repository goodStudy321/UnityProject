--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-31 17:13:49
-- 1, 错误输出一定有lua堆栈
-- 2, 编辑器内方法以e开头
-- 3, s开头的可以输出lua堆栈
-- 4, id之外的参数是可变长的
--==============================================================================

require("Tool.ObjPool")
require("Str.StrBuffer")
require("Str.StrBuffer")

iTrace = {Name = "iTrace"}

local Debug = Debugger
local traceback = debug.traceback

local My = iTrace
local editStr = "<b><i>[Editor]</i></b>"

--格式化
--stack(boolean):true 包含堆栈
function My.Format(id, stack, ...)
  id = id or "无名"
  local str = nil
  local isEditor, str = App.isEditor, nil
  local sb = ObjPool.Get(StrBuffer)
  if isEditor then sb:Apd("<b><i>") end
  sb:Apd(id):Apd(": [LUA] ")
  if isEditor then sb:Apd("</i></b> ") end
  local len = select('#', ...)
  if len > 0 then
    for i = 1, len do
      str = select(i, ...)
      sb:Apd(str)
    end
  end
  if stack == nil then stack = false end
  if stack then
    local stackStr = traceback()
    sb:Apd("\n"):Apd(stackStr)
  end
  local res = sb:ToStr()
  ObjPool.Add(sb)
  return res
end

local Format = My.Format

--普通输出/无lua堆栈
function My.Log(id, ...)
  Debug.Log(Format(id, false, ...))
end

--错误输出
function My.Error(id, ...)
  Debug.LogError(Format(id, true, ...))
end

--警告输出/无堆栈
function My.Warning(id, ...)
  Debug.LogWarning(Format(id, false, ...))
end

--编辑器普通输出/无堆栈
function My.eLog(id, ...)
  if App.isEditor then
    Debug.Log(Format(id, false, editStr, ...))
  end
end

--编辑器错误输出/有堆栈
function My.eError(id, ...)
  if App.isEditor then
    Debug.LogError(Format(id, true, editStr, ...))
  end
end

--编辑器警告输出/无堆栈
function My.eWarning(id, ...)
  if App.isEditor then
    Debug.LogWarning(Format(id, false, editStr, ...))
  end
end

--普通输出/有堆栈
function My.sLog(id, ...)
  Debug.Log(Format(id, true, ...))
end

--警告输出/有堆栈
function My.sWarning(id, ...)
  Debug.LogWarning(Format(id, true, ...))
end

return My
