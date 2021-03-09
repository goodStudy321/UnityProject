--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-04-21 15:36:13
-- 协议对象池
--=============================================================================

local TypeMgr = ProtoTypeMgr

ProtoPool = {Name = "ProtoPool"}


local My = ProtoPool

--k:协议名,v:对象列表
My.dic = {}

--添加对象
--msg(table):协议实例
function My.Add(msg)
	if msg == nil then return end
	local name = TypeMgr.GetNameByObj(msg)
	My.AddByName(name, msg)
end

--添加对象
--name(string)协议名
--msg(table):协议实例
function My.AddByName(name, msg)
	if msg == nil then return end
	if name == nil then return end
	local list = My.dic[name]
	if list == nil then
		list = {}
		My.dic[name] = {}
	end
	list[#list + 1] = msg
end

--通过协议名获取协议实例
function My.Get(name)
	if name == nil then return end
	local list = My.dic[name]
	local msg = nil
	if list == nil or #list < 1 then
		local obj = TypeMgr.GetType(name)
		if obj then
			msg = obj[name]()
		end
	else
		msg = table.remove(list)
	end
	return msg
end

--通过ID获取对象
--id(number):协议ID
function My.GetByID(id)
	local name = TypeMgr.GetName(id)
	return My.Get(name)
end

--通过类型获取对象
--ty(table):协议类型/模块
function My.GetByType(ty)
	local name = TypeMgr.GetNameByType(ty)
	return My.Get(name)
end

--释放
function My.Dispose()
	local dic = My.dic
	for k, v in pairs(dic) do
		while #v > 0 do
			table.remove(v)
		end
	end
end

return My
