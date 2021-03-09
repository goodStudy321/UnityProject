--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-04-20 01:08:53
-- 协议监听
--=============================================================================

require("Lib/Event")
local LuaNetBridge = Loong.Game.LuaNetBridge
local TypeMgr = require("Proto/ProtoTypeMgr")

ProtoLsnr = {Name = "ProtoLsnr"}

local My = ProtoLsnr

--事件字典,k:协议ID字符串,v:Event实例
My.eDic = {}

function My.Init()
	EventMgr.Add("RecvLuaData", My.Trigger)
end

--添加监听
--id(number):协议ID
--func(function):方法
--obj(table):对象
function My.Add(id, func, obj)
	if type(id) ~= "number" then return end
	--Todo检查是否存在ID配置
	local k = tostring(id)
	local eDic = My.eDic
	local e = eDic[k]
	if e == nil then
		e = Event()
		eDic[k] = e
	end
	e:Add(func, obj)
end

--添加监听
--name(string):协议名
function My.AddByName(name, func, obj)
	local id = TypeMgr.GetID(name)
	if id == nil then return end
	My.Add(id, func, obj)
end

--移除监听
--id(number):协议ID
--func(function):方法
--obj(table):对象
function My.Remove(id, func, obj)
	if type(id) ~= "number" then return end
	if func == nil then return end
	local k = tostring(id)
	local eDic = My.eDic
	local e = eDic[k]
	if e == nil then return end
	e:Remove(func, obj)
end

--移除监听
function My.RemoveByName(name, func, obj)
	local id = TypeMgr.GetID(name)
	if id == nil then return end
	My.Remove(id, func, obj)
end


--触发监听
--id(number):协议ID
function My.Trigger(id)
	My.curID = id
	xpcall(My.Call, My.traceback, id)
end

function My.traceback(msg)
	iTrace.Error("Loong","trigger proto id:", My.curID,", err:", msg)
end

--安全调用
function My.Call(id)
	local k = tostring(id)
	local e = My.eDic[k]
	if e == nil then return end
	local name = TypeMgr.GetName(id)
	local msg = ProtoPool.Get(name)
	local data = LuaNetBridge.recvBytes
	msg:ParseFromString(data)
	e(msg)
	ProtoPool.Add(name, msg)
end

function My.Dispose()
	TableTool.ClearDicToPool(my.eDic)
end


return My
