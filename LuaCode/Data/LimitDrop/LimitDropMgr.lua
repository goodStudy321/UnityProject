--[[
    情缘活动，限时掉落管理
]]
LimitDropMgr = Super:New{Name = "LimitDropMgr"}
local My = LimitDropMgr;

function My:Init()
    self:SetLsnr(ProtoLsnr.Add);
end

function My:SetLsnr(fn)
    
end

function My:Clear()
    self:SetLsnr(ProtoLsnr.Remove);
end

return My;