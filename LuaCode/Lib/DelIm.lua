--[[
 	author 	    :Loong
 	date    	:2018-02-07 16:28:39
 	descrition 	:委托的中间类型
 		1,可以添加额外的参数
--]]

DelIm = Super:New{Name = "DelIm"}

local xpcall = xpcall

local My = DelIm

function My:Ctor()
  --参数列表
  self.args = {}
end

--添加参数
--返回自身
function My:Add(arg)
  if arg then
    local args = self.args
    args[#args + 1] = arg
  end
  return self
end

--添加参数
function My:Adds(...)
  local len = select("#", ...)
  if len < 1 then return end
  local args = self.args
  local arg = nil
  for i = 1, len do
    arg = select(i, ...)
    if arg then
      args[#args + 1] = arg
    end
  end
end

--设置方法
--func(function):方法
--obj(table):所在对象
function My:SetFunc(func, obj)
  self.obj = obj
  self.func = func
end

function My:Dispose()
  self.obj = nil
  self.func = nil
  ListTool.Clear(self.args)
end

return My
