BaseToggle = Super:New{Name = "BaseToggle"}

local M = BaseToggle

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go, index)
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local trans = go.transform

    self.go = go
    self.Index = index
    self.tgName = G(UILabel, trans, "Name")
    self.highlight = FC(trans, "Highlight")
    self.redPoint = FC(trans, "RedPoint")
    UITool.SetLsnrSelf(go, self.OnClick, self, self.Name, false)
    
    self:InitCustom()
end

function M:InitCustom()
end

function M:OnClick(go)
    self.eClick(go.name)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:SetName(value)
    self.tgName.text = value
end

function M:SetHighlight(state)
    if not self:IsActive() then return end
    self.highlight:SetActive(state)
end

function M:SetRedPoint(state)
    self.redPoint:SetActive(state)
end

function M:GetGoName()
    return self.go.name
end

function M:DisposeCustom()
end

function M:Dispose()
    self.Index = nil
    self:DisposeCustom()
    self.eClick:Clear()
    TableTool.ClearUserData(self)
end

return M