DemonRewardCell = Super:New{Name = "DemonRewardCell"}

local M = DemonRewardCell

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.mGo = go
    self.mCell = ObjPool.Get(UIItemCell)
    self.mCell:InitLoadPool(trans)
    self.mFixed = FC(trans, "Fixed")
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:UpdateData(data, isFixed)
    if not data then return end
    self.data = data
    self.mCell:UpData(data)
    self:UpdateFixed(isFixed)
end

function M:UpdateFixed(bool)
    self.mFixed:SetActive(bool)
end

function M:Dispose()
    self.data = nil
    self.mCell:DestroyGo()
    ObjPool.Add(self.mCell)
    self.mCell = nil
    TableTool.ClearUserData(self)
end

return M