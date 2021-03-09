--[[
 	authors 	:Loong
 	date    	:2017-08-17 21:18:41
 	descrition 	:超级类型
--]]

Super = {}

Super.Name = "Super"

--构造方法
function Super:New(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  --自定义构造
  if o.Ctor then
    o:Ctor()
  end
  return o
end
