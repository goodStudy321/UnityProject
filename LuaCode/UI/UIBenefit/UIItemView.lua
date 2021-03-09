UIItemView = Super:New{Name = "UIItemView"}

require("UI/UIBenefit/ComCell")

local M = UIItemView

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.go = go
    self.sView = go:GetComponent(typeof(UIScrollView))
    self.grid = G(UIGrid, self.sView.transform, "Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)
end

function M:CreateCell(data)
    local go = Instantiate(self.cell)
    TransTool.AddChild(self.grid.transform, go.transform)
    local cell = ObjPool.Get(ComCell)
    cell:Init(go)
    cell:SetActive(true)
    cell:UpdateData(data)
    table.insert(self.cellList, cell)
end

function M:UpdateData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateCell(data[i])
        end
    end
    self.grid:Reposition()
    self.sView:ResetPosition()
end

function M:SetActive(bool)
    if self.go then
        self.go:SetActive(bool)
    end
end

function M:Dispose()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M