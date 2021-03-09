TitleType = Super:New{Name = "TitleType"}

require("UI.UITitle.ToggleCell")

local M = TitleType

function M:Init(root)
    self.cellList = {}
    self.eClickToggle = Event()
    self.grid = ComTool.Get(UIGrid, root, "Grid")
    self.cell = TransTool.FindChild(self.grid.transform, "cell")
    self.cell:SetActive(false)
end

function M:CreateCell(data)
    local parent = self.grid.transform
    local cell = self.cell
    local list = self.cellList
    local len = #data
    local AC = TransTool.AddChild

    for i=1,len do
        local go = Instantiate(cell)
        go:SetActive(true)
        AC(parent, go.transform)
        local toggleCell = ObjPool.Get(ToggleCell)
        toggleCell:Init(go)
        toggleCell:SetHandler(self.Handler,self)
        toggleCell:UpdateCell(data[i])
        table.insert(list, toggleCell)
    end
    self.grid:Reposition()
end

function M:Open(id)
    self:Handler(id)
end

function M:SetHighlight(id)
    local list = self.cellList
    local len = #list
    for i=1,len do
        list[i]:SetHighlight(list[i].data.id==id)
    end  
end

function M:Handler(id)
    self:SetHighlight(id)
    self.eClickToggle(id)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    for k,v in pairs(self.cellList) do
        ObjPool.Add(v)
    end
    self.cellList = nil
    self.eClickToggle:Clear()
    self.eClickToggle = nil
end

return M