UIDemonReward = UIBase:New{Name = "UIDemonReward"}

local M = UIDemonReward

M.mInevitableCells = {}
M.mIncidentalCells = {}

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.mBtnClose = FC(trans, "BtnClose")
    self.mGridInevitable = G(UIGrid, trans, "InevitableReward/ScrollView/Grid")
    self.mGridIncidental = G(UIGrid, trans, "IncidentalReward/ScrollView/Grid")
    S(self.mBtnClose, self.Close, self)
    self:UpdateData() 
end

function M:UpdateData()
    self.data = DemonMgr:GetRewardData()
    if not self.data then return end
    self:UpdateCells(self.data.InevitableRewards, self.mGridInevitable, self.mInevitableCells)
    self:UpdateCells(self.data.IncidentalRewards, self.mGridIncidental, self.mIncidentalCells)
end

function M:UpdateCells(data, grid, list)
    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(grid.transform)
        cell:UpData(data[i])
        table.insert(list, cell)
    end
    grid:Reposition()
end

function M:DisposeCustom()
    self.data = nil
    TableTool.ClearListToPool(self.mInevitableCells)
    TableTool.ClearListToPool(self.mIncidentalCells)
end

return M 
