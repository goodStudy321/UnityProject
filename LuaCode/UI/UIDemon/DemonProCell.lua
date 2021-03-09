DemonProCell = Super:New{Name = "DemonProCell"}

local M = DemonProCell

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get

    self.mMask = FC(trans, "Mask")
    self.mPer = G(UILabel, trans, "Per")
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:UpdateMask()
    self:UpdatePer()
end

function M:UpdatePer()
    self.mPer.text = string.format("%s%%", self.mData.HpPer)
end

function M:UpdateMask()
    self.mMask:SetActive(self.mData.HadGet == 0)
end

function M:Dispose()
    self.mData = nil
    TableTool.ClearUserData(self)
end

return M