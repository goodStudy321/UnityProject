--[[
	AU:Loong
	TM:2017.6.27
	BG:事件工具
--]]

EventTool = {}
local My = EventTool

--调用简单事件
--et:(table) 是一个方法的字典,k:键值,v:方法
--arg: 参数列表
function My.Call(et, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
	if type(et) ~= "table" then return end
	local tn = nil
	for k, v in pairs(et) do
		tn = type(v)
		if tn == "function" then
			v(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
		end
	end
end

--C# 注册事件
--self:C#对象
--eName(string):事件名称
--func(function):方法
function My.Add(self, eName, func)
	if self == nil then return end
	if type(func) ~= "function" then return end
	if self[eName] == nil then
		self[eName] = func
	else
		self[eName] = self[eName] + func
	end
end

--C# 注销事件
--参数同Add
function My.Rmv(self, eName, func)
	if self == nil then return end
	if type(func) ~= "function" then return end
	if self[eName] == nil then return end
	self[eName] = self[eName] - func
end
