AvSBCell = Super:New{Name = "AvSBCell"}

local M = AvSBCell

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.go = go
    self.highlight = FC(trans, "Highlight")
end

function M:UpdateData(data)
    self.data = data
    if not self.cell then
        self.cell = ObjPool.Get(SBCell)
        self.cell:InitLoadPool(self.go.transform)
        self.cell:SetTip(false)
        self.cell.eClickCell:Add(self.OnClick, self)
    end
    self.cell:UpdateData(self.data)
    self:SetHighlight(false)
end

function M:OnClick()
    self.isSelect = not self.isSelect
    self:SetHighlight(self.isSelect)
    self.eClick(self.isSelect, self.data)
end

function M:SetHighlight(state)
    self.isSelect = state
    self.highlight:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Dispose()
    self.eClick:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    self.data = nil
    TableTool.ClearUserData(self)
end

return M