RGridItem = Super:New{Name = "RGridItem"}

local M = RGridItem

M.mMaxNum = 3

function M:Ctor()
    self.Cells = {}
end

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local GS = ComTool.GetSelf

    self.mGo = go
    self.mGrid = GS(UIGrid, go)
    self.mPrefab = FC(trans, "Item_99")
    self.mPrefab:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:GetPrice()
    local price = 0
    local list = self.Cells
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() and cell.IsSelect then
            price = price + cell.TotalPrice
        end
    end
    return price
end

function M:UpdateData(data, class)
    if not data then return end
    local len = #data
    local list = self.Cells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:InitItem(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.mPrefab)
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local item = ObjPool.Get(class)
            item:Init(go)
            item:SetActive(true)
            item:InitItem(data[i])
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
end

function M:Dispose()
    TableTool.ClearDicToPool(self.Cells)
    TableTool.ClearUserData(self)
end

return M