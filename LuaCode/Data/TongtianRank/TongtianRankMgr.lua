require("Data/TongtianRank/TongtianRankNetwork")
TongtianRankMgr={Name="TongtianRankMgr"}
local My = TongtianRankMgr
My.rankList = {}
My.bestThreeList = {}
My.admire_times=0
My.isRed=false
My.network = TongtianRankNetwork
My.eData=Event()
My.eAdmire=Event()

function My.Init( ... )
    My.network.AddLnsr()
end

function My.UpRed()
    local isred=false
    local count = #My.bestThreeList
    if count==0 then
        isred=false 
    elseif count==1 and My.bestThreeList[1].role_id==User.instance.MapData.UIDStr then 
        isred=false
    else
        local temp =GlobalTemp["177"]
        local time = temp.Value3
        isred=My.admire_times<time
    end  
    My.isRed=isred
    CopyMgr:UpdateCopyTowerRedPoint()
end

function My.Clear( ... )
    ListTool.Clear(My.rankList)
    ListTool.Clear(My.bestThreeList)
end

return My