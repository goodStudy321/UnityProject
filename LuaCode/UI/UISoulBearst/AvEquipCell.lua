AvEquipCell = Super:New{Name = "AvEquipCell"}

local M = AvEquipCell

M.eClick = Event()

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.go = go
    self.name = G(UILabel, trans, "Name")
    self.level = G(UILabel, trans, "Adv")
    self.highlight = FC(trans, "Highlight")
    self.itemRoot = F(trans, "ItemRoot")
    UITool.SetLsnrSelf(go, self.OnClick, self, self.Name, false)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateLevel()
    self:UpdateCell()
end

function M:UpdateName()
    self.name.text = self.data.name
end

function M:UpdateLevel()
    self.level.text = string.format("+%s", self.data.level)
end

function M:UpdateCell()
    if not self.cell then
        self.cell = ObjPool.Get(SBCell)
        self.cell:InitLoadPool(self.itemRoot)
    end
    self.cell:UpdateData(self.data)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:SetHighlight(state)
    if self:IsActive() then
        self.highlight:SetActive(state)
    end
end

function M:IsActive()
    return self.go.activeSelf
end

function M:OnClick()
    if self.data then
        M.eClick(self.data)
    end
end

function M:Dispose()
    self.data = nil
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    TableTool.ClearUserData(self)
end

return M