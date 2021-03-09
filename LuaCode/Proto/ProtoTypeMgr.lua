--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-04-20 00:09:28
-- 协议类型管理
--=============================================================================

local StrBuffer = require("Str/StrBuffer")

require("Conf/LuaProtoCfg")

ProtoTypeMgr = {Name = "ProtoTypeMgr"}

local My = ProtoTypeMgr

My.buf = StrBuffer:New()

--k:协议名,v:(table)具有ID,和模块参数)
My.dic = {}


function My.Init()
	local dic = My.dic
	local find = string.find
	local toc, tos = "_toc", "_tos"
	local id, ty = nil, nil
	local GetPath, traceback = My.GetPath, My.traceback
	for i, v in ipairs(LuaProtoCfg) do
		local ty = v.ty
		local path = GetPath(ty)
		local res, mod = xpcall(require, traceback, path)
		if res then
			local tbl = {}
			tbl.mod = mod
			tbl.id = v.id
			dic[ty] = tbl
		end
	end
end

--通过名称获取协议ID
--name(string):协议名
--return(number or nil):返回ID,未获取到时返回nil
function My.GetID(name)
	local info = My.dic[name]
	if info then
		return info.id
	end
end

--通过id获取协议名
--id(number):协议ID
--return(string or nil):返回协议名,未获取到时返回nil
function My.GetName(id)
	local cfg = BinTool.Find(LuaProtoCfg, id)
	if cfg then
		return cfg.ty
	end
end


--通过协议名获取模块路径
--name(string):协议名
--return(string):路径
function My.GetPath(name)
	local buf = My.buf
	buf:Apd("Protol."):Apd(name):Apd("_pb")
	local str = buf:ToStr()
	buf:Dispose()
	return str
end

--通过协议名获取类型
--name(string):协议名
function My.GetType(name)
	if name == nil then return end
	local info = My.dic[name]
	if info == nil then
		iTrace.Error("Loong", "无名为:", name, "的协议")
	else
		return info.mod
	end
end

--通过协议ID获取类型
function My.GetTypeByID(id)
	local name = My.GetName(id)
	return My.GetType(name)
end


--通过协议实例获取协议名
--msg:消息实例
function My.GetNameByObj(msg)
	local mt = getmetatable(msg)
	if mt == nil then return end
	local desc = mt._descriptor
	if desc == nil then return end
	local name = desc.name
	return name
end

--通过协议类型获取协议名称
--ty(table):协议类型/模块
function My.GetNameByType(ty)
	if ty == nil then return end
	local name = ty._NAME
	if name == nil then return end
	local rName = string.sub(name, 8, (-4))
	return rName
end

function My.traceback(msg)
	iTrace.Error("Loong", "加载Lua协议模块错误(确定是否有此lua协议):", msg)
end


return My
