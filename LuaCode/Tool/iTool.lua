--[[
 	authors 	:Loong
 	date    	:2017-08-31 21:31:46
 	descrition 	:Commen Tool
--]]

iTool = {}

local My = iTool

--在面向对象类型中添加使用非面向对象方法
function My.SetFunc(self, name)
  local nName = "f" .. name
  local f = self[nName]
  if f then return end
  self[nName] = function(...) self[name](self, ...) end
end
