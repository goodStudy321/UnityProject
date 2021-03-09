require("Data/Charm/CharmNetwork")
local network = CharmNetwork
CharmMgr={Name="CharmMgr"}
local My = CharmMgr

My.eRank=Event()
My.myCharm=nil
My.ranks={}
My.tp=nil


function My.Init( ... )
    network.AddLnsr()
end

function My.Clear( ... )
    ListTool.Clear(My.ranks)
    My.myCharm=nil
end

return My