AMVSuitList = Super:New{Name = "AMVSuitList"}

require("UI/Robbery/Ares/AMVCell")

local M = AMVSuitList

function M:Ctor()
    self.cellList = {}
    self.eClickCell = Event()
end

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get

    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateCell()
end

function M:Refresh()
    self:UpdateCell()
end

function M:UpdateCell()
    local data = self.data
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
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform, go.transform)
            local item = ObjPool.Get(AMVCell)
            item:Init(go)
            item.eClick:Add(self.OnAMVCell, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end


--战神套装选择
function M:SetDefSelect(index)
    if index == nil or index == 0 then
        index = 1
    end
    if self.cellList[index] then
        self.cellList[index]:OnClick()
    end
end

function M:OnAMVCell(data)
    if self.curId and self.curId == data.id then return end
    self.curId = data.id
    local list = self.cellList
    for i=1,#list do
        list[i]:UpdateHighlight(list[i].data.id == data.id)
    end
    self.eClickCell(data)
end

function M:Clear()
    self.curId = nil
end

function M:Dispose()
    self.data = nil
    self.curId = nil
    self.eClickCell:Clear()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M