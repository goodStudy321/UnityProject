FamWarEndCell = Super:New{Name = "FamWarEndCell"}

local M = FamWarEndCell

function M:Init(go)
    self.cellList = {}
    self:InitUserData(go) 
end

function M:InitUserData(go)
    local trans = go.transform
    local G = ComTool.Get

    self.rank = G(UILabel, trans, "Rank")
    self.familyName = G(UILabel, trans, "FamilyName")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.grid = G(UIGrid, trans, "Grid")
end


function M:UpdateData(data)
    if not data then return end
    self.rank.text = data.rank
    self.name.text = data.name
    self.score.text = data.score
    self.familyName.text = data.familyName
    self:UpdateCell(data.rewardList)
end

function M:UpdateCell(data)
    if not data then return end
    local parent = self.grid.transform
    local cellList = self.cellList
    local len = #data
    for i=1,len do
        local itemCell = ObjPool.Get(UIItemCell)
        itemCell:InitLoadPool(parent, 0.7)
        itemCell:UpData(data[i].k, data[i].v)
        table.insert(cellList, itemCell)
    end
    self.grid:Reposition()
end

function M:Dispose()
    TableTool.ClearUserData(self)
    TableTool.ClearListToPool(self.cellList)
end

return M