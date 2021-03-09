UIEscortItemCell = Super:New{Name = "UIEscortItemCell"}

local M = UIEscortItemCell

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    
    self.mGo = go
    self.mReduce = G(UILabel, trans, "Reduce")
    self.mCell = ObjPool.Get(UIItemCell)
    self.mCell:InitLoadPool(trans)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:UpdateCell()
    self:UpdateReduce()
end

function M:UpdateCell()
    self.mCell:UpData(self.mData.k, self.mData.v)
end

function M:UpdateReduce()
    local rob = FamilyEscortMgr:GetRobStatus()
    self.mReduce.gameObject:SetActive(rob == 1)
    self.mReduce.text = string.format("-%s%%", GlobalTemp["150"].Value3)
end

function M:Dispose()
    self.mData = nil
    if self.mCell then
        self.mCell:DestroyGo()
        ObjPool.Add(self.mCell)
        self.mCell = nil
    end
    TableTool.ClearUserData(self)
end

return M