--[[
上上签数据管理
]]
require("Data/DrawLots/DrawLotsNetwork")
local network = DrawLotsNetwork
DrawLotsMgr={Name="DrawLotsMgr"}
local My = DrawLotsMgr
My.eUp=Event()
My.eTime=Event()


function My.Init( ... )
    network.AddLnsr()
end






function My.OpenUI()
    local isopen = NewActivMgr:ActivIsOpen(2004) or false
    if isopen==false then UITip.Log("活动暂未开启") return end
    UIMgr.Open(UIDrawLots.Name)
end

function My.Clear( ... )
    -- body
end

return My