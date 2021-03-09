--[[
魅力排行奖励
]]
require("UI/UICharm/CharmRewardCell")
UIRankReward=Super:New{Name="UIRankReward"}
local My = UIRankReward


function My:Init(go)
    if not self.cellList then self.cellList={} end
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    self.grid=CG(UIGrid,trans,"bg/Panel/Grid",self.Name,false)
    self.pre=TF(self.grid.transform,"C")
    UITool.SetBtnClick(trans,"CloseBtn",self.Name,self.Close,self)
    self.isfirst=true
end

function My:InitData()
    local pa = self.grid.transform
    for i,v in ipairs(CharmRankData) do
        local go = GameObject.Instantiate(self.pre)
        go:SetActive(true)
        local trans = go.transform
        trans.parent=pa
        trans.localScale=Vector3.one
        trans.localPosition=Vector3.zero
        local cell = ObjPool.Get(CharmRewardCell)
        cell:Init(go)
        cell:UpData(v)
        self.cellList[i]=cell
    end
    self.grid:Reposition()
end

function My:Open( ... )
    self.go:SetActive(true)
    if self.isfirst then self:InitData() end
    self.isfirst=false
end

function My:Close( ... )
    self.go:SetActive(false)
end

function My:Dispose( ... )
    ListTool.ClearToPool(self.cellList)
end