UICmmView = Super:New{Name = "UICmmView"}

require("UI/UIBenefit/UIItemView")
require("UI/UIBenefit/UIDesView")
require("UI/UIBenefit/UIRankView")

local M = UICmmView

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.go = go

    self.desView = ObjPool.Get(UIDesView)
    self.desView:Init(FC(trans, "DesView"), function(data) self:Handler(data) end)

    self.itemView = ObjPool.Get(UIItemView)
    self.itemView:Init(FC(trans, "ItemView"))

    self.rankView = ObjPool.Get(UIRankView)
    self.rankView:Init(FC(trans, "RankView"))
end


function M:Handler(type)
    if self.rankView:ActiveSelf() then
        if self.type == type then
            self:ShowReward()
        else
            self:ReqRankInfo(type)
        end
    else        
        self:ReqRankInfo(type)
    end
end

function M:ShowReward()
    self.type = nil
    self.rankView:SetActive(false)
    self.itemView:SetActive(true)
end

function M:ReqRankInfo(type)
    if type == BenefitMgr.Personal then         
        BenefitMgr:ReqPersonalRankInfo()
    elseif type == BenefitMgr.Famlily then
        BenefitMgr:ReqFamilyRankInfo()
    end
end


function M:UpdateRankView(type)
    if not type then return end
    local data = BenefitMgr:GetRankData(type)
    if not data then return end
    self.type = type
    self.rankView:UpdateData(data)
    self.itemView:SetActive(false)
    self.rankView:SetActive(true)
end


function M:UpdateData(data)
    if not data  then return end
    self.itemView:UpdateData(data)
    self.itemView:SetActive(true)
    self.desView:UpdateData()
    self:ShowReward()
    self:SetActive(true)
end

function M:SetActive(bool)
    if self.go then
        self.go:SetActive(bool)
    end
end

function M:Dispose()
    TableTool.ClearUserData(self)
    ObjPool.Add(self.desView)
    ObjPool.Add(self.itemView)
    ObjPool.Add(self.rankView)
    self.desView = nil
    self.itemView = nil
    self.rankView = nil
    self.type = nil
end

return M