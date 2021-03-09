UIDTItemView = Super:New{Name = "UIDTItemView"}

require("UI/UIDayTarget/DayTargetCell")

local M = UIDTItemView

M.mCells = {}

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get

    self.mScrollView = G(UIScrollView, trans, "ScrollView")
    self.mGrid = G(UIGrid, self.mScrollView.transform, "Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mPrefab:SetActive(false)
end

function M:UpdateData(data)
    local len = #data
    local list = self.mCells
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
            local go = Instantiate(self.mPrefab)
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local cell = ObjPool.Get(DayTargetCell)
            cell:Init(go)
            cell:SetActive(true)
            cell:UpdateData(data[i])
            table.insert(self.mCells, cell)
        end
    end
    self.mGrid:Reposition()
    self.mScrollView:ResetPosition()
end

function M:Dispose()
    TableTool.ClearDicToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M