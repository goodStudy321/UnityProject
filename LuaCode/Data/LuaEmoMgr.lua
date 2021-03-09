--[[
表情
]]
LuaEmoMgr={Name="LuaEmoMgr"}
local My = LuaEmoMgr

function My.Init()
    local AtlasDic=EmoMgr.AtlasDic
    for i=1,28 do
        local name = i<10 and "#0"..i or "#"..i
        AtlasDic:Add(name)
    end
end

function My.Clear()
    -- body
end

return My