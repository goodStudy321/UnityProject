UIGetWay = UIBase:New{Name = "UIGetWay"}

require("UI/Base/UIGetWayItem")
local M = UIGetWay

M.cellList = {}

function M:InitCustom()
    local root = self.root
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.parent = F(root, "GetWay")
    self.parent.localPosition = self.pos or Vector3.zero

    self.grid = G(UIGrid, self.parent, "ScrollView/Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.title = G(UILabel, self.parent, "Title")
    UITool.SetLsnrSelf(root, self.Close, self, self.Name, false)
end

function M:SetPos(pos)
    self.parent.localPosition = pos or Vector3.zero
end

function M:SetTitle(str)
    self.title.text = str
end

function M:CreateCell(name, func, obj)
    local go = Instantiate(self.cell)
    go:SetActive(true)
    TransTool.AddChild(self.grid.transform, go.transform)
    local item = ObjPool.Get(UIGetWayItem)
    item:Init(go)
    item:UpdateData(name, func, obj)
    table.insert(self.cellList, item)
end


function M:Reposition()
    self.grid:Reposition()
end

function M:DisposeCustom()
    TableTool.ClearDicToPool(self.cellList)
end

return M