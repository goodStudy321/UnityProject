--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/8/17 下午5:02:42
--=============================================================================

if not UApp.isEditor then return end

if CSApp.LuaDebug then
	local name = jit and "LuaDebugjit" or "LuaDebug"
    local breakSocketHandle, debugXpCall = require(name)("localhost", 7003)
else
    require("debug/debug_emmy")
end
