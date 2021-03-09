--[[
掉落物
]]
LuaDropMgr={Name="LuaDropMgr"}
local My = LuaDropMgr

function My.Init()
    local ignoreUFXDic=Loong.Game.DropMgr.ignoreUFXDic
    ignoreUFXDic:Add(20)
    ignoreUFXDic:Add(46)
    ignoreUFXDic:Add(47)
    ignoreUFXDic:Add(86)
    ignoreUFXDic:Add(88)
end

function My.Clear()
    -- body
end

return My