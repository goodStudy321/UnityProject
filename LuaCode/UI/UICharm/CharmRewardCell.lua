--[[
魅力排行榜奖励格子
]]

CharmRewardCell=Super:New{Name="CharmRewardCell"}
local My = CharmRewardCell

function My:Init(go)
    if not self.cellList then self.cellList={} end
    local trans = go.transform
    local CG = ComTool.Get
    self.rankLab=CG(UILabel,trans,"rankLab",self.Name,false)
    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    self.str=ObjPool.Get(StrBuffer)
end

function My:UpData(temp)
    local pa = self.grid.transform
    local giftList = temp.giftList --道具，数量，特效
    local rank = temp.rank
    for i,v in ipairs(giftList) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(pa,0.9)
        cell:UpData(v.n1,v.n2)
        self.cellList[i]=cell
    end
    self.str:Dispose()
    self.str:Apd("排名 ")
    self.str:Apd(rank[1])
    if rank[1]~= rank[2] then 
        self.str:Apd("-"):Apd(rank[2]) 
    end
    self.rankLab.text=self.str:ToStr()
end

function My:Dispose( ... )
    while #self.cellList>0 do
        local cell = self.cellList[#self.cellList]
        cell:DestroyGo()
        ObjPool.Add(cell)
        self.cellList[#self.cellList]=nil
    end
end