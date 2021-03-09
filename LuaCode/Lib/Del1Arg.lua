--[[
 	author 	    :Loong
 	date    	:2018-02-07 18:04:09
 	descrition 	:具有一个参数的中间回调类型
              1, 将Execute作为回调方法传给委托/事件
              2, 其中回调方法作为的第一个参数和其它参数都传递给func
--]]
local xpcall = xpcall

DelIm = require("Lib/DelIm")

Del1Arg = DelIm:New{Name = "Del1Arg"}

local My = Del1Arg

function My:Execute(arg)
  local obj = self.obj
  local func = self.func
  local tb = My.Traceback
  local args = self.args
  if obj then
    xpcall(func, tb, obj, arg, unpack(args))
  else
    xpcall(func, tb, arg, unpack(args))
  end
  ObjPool.Add(self)
end


function My.Traceback(msg)
  iTrace.Error("Loong", "错误信息:", msg)
end

return My
