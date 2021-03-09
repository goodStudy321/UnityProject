CharmNetwork={Name="CharmNetwork"}
local My = CharmNetwork
local GetError = ErrorCodeMgr.GetError

function My.AddLnsr( ... )
    local Add = ProtoLsnr.Add
    Add(25042, My.ResqCharmRank)
end

--"1:男 2:女"
function My.ReqCharmRank(tp) 
    local msg = ProtoPool.GetByID(25041)
    msg.type=tp
    ProtoMgr.Send(msg)
end

--魅力之王排行返回
function My.ResqCharmRank(msgs)
    CharmMgr.Clear()
    local ranks = msgs.ranks
    local tp = msgs.type
    for i,v in ipairs(ranks) do
        local tab = {}
        tab.rank=v.rank
        tab.role_id=v.role_id
        tab.role_name=v.role_name
        tab.category=v.category
        tab.sex=v.sex
        tab.charm=v.charm
        tab.server_name=v.server_name
        CharmMgr.ranks[tab.rank]=tab
    end
    local myCharm = msgs.my_charm
    CharmMgr.myCharm=myCharm
    CharmMgr.tp=tp
    CharmMgr.eRank()
end

return My
