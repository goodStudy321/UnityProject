--[[
至尊三强
]]
require("UI/UITongtianRank/SupremeCell")
SupremeThree=Super:New{Name="SupremeThree"}
local My = SupremeThree

function My:Init(go)
    if not self.dic then self.dic={} end
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = go.transform
    self.go=go
    U(trans,"Panel/CloseBtn",self.Name,self.OnClose,self)
    self:SetEvent("Add")
end

function My:UpData()
    local TF = TransTool.FindChild
    local trans = self.go.transform
    local list = TongtianRankMgr.bestThreeList
    for i,v in ipairs(list) do
        local rank = v.rank
        local cell = self.dic[tostring(rank)]
        if not cell then 
            local go = TF(trans,"Panel/c"..rank)
            cell = ObjPool.Get(SupremeCell)
            cell:Init(go)
            self.dic[tostring(rank)]=cell
        end
        cell:UpData(v)
    end
end

function My:OnClose()
    UIMgr.Close(UITongtianRank.Name)
	JumpMgr.eOpenJump()
end

function My:SetEvent(fn)
    TongtianRankMgr.eData[fn](TongtianRankMgr.eData,self.UpData,self)
    TongtianRankMgr.eAdmire[fn](TongtianRankMgr.eAdmire,self.OnAdmire,self)
end

function My:OnAdmire( ... )
    for k,v in pairs(self.dic) do
        v:OnAdmire()
    end
end

function My:Open( ... )
    self.go:SetActive(true)
end

function My:Close( ... )
    self.go:SetActive(false)
end

function My:Dispose( ... )
    self:SetEvent("Remove")
    TableTool.ClearDicToPool(self.dic)
end
