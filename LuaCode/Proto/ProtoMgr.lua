--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-04-19 17:25:34
--=============================================================================

local TypeMgr = require("Proto/ProtoTypeMgr")
local ProtoPool = require("Proto/ProtoPool")
local ProtoLsnr = require("Proto/ProtoLsnr")
local LuaNetBridge = Loong.Game.LuaNetBridge
local CS_Send = LuaNetBridge.Send

ProtoMgr = {Name = "ProtoMgr"}

local My = ProtoMgr

function My.Init()
	TypeMgr.Init()
	ProtoLsnr.Init()
end

--发送消息
function My.Send(msg)
	if msg == nil then return end
	local name = TypeMgr.GetNameByObj(msg)
	--Todo 获取ID
	local id = TypeMgr.GetID(name)
	if id == nil then
		iTrace.Error("Loong", "Lua协议未发现名为:", name, "的配置")
	else
		local data = msg:SerializeToString()
		LuaNetBridge.sendBytes = data
		ProtoPool.AddByName(name, msg)
		msg:Clear()
		CS_Send(id)
	end
end

--创建类型的实例
--ty(table):lua协议类型或者模块
function My.Create(ty)
	local name = My.GetNameByType(ty)
	local obj = ty[name]()
	return obj
end

--错误码检测
function My.CheckErr(err)
  if not err then return true end
	--输出错误码
	if (err>0) then
		iTrace.eError("hs",ErrorCodeMgr.GetError(err))
		return false
	end
	return true
end
