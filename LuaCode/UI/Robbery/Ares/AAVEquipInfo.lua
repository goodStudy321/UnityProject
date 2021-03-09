AAVEquipInfo = Super:New{Name = "AAVEquipInfo"}

require("UI/Robbery/Ares/AAVCell")

local M = AAVEquipInfo

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.tab = G(UITable, trans, "ScrollView/Table")
    self.prefab = FC(self.tab.transform, "Cell")
    self.prefab:SetActive(false)
end

function M:Refresh()
    self:UpdateCell()
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
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
            TransTool.AddChild(self.tab.transform, go.transform)
            local item = ObjPool.Get(AAVCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.tab:Reposition()
end

function M:SetSelect(aresId, equipId)
    local list = self.cellList
    local len = #list
    if aresId then
        for i=1,len do
            if list[i].data.id == aresId then 
                list[i]:OnClick()
                list[i]:SetSelect(equipId)
                return
            end
        end
    end
    if len > 0 then
        list[1]:OnClick()
        list[1]:SetSelect()
    end
end


function M:UpdateCellState(data)
    local list = self.cellList
    for i=1,#list do
        if list[i].data.id == data.id then
            list[i]:Switch()
        else
            list[i]:HideEquip()
        end
    end
    self.tab:Reposition()
end

function M:Reset()
    local list = self.cellList
    for i=1,#list do
        list[i]:Reset()
    end
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.cellList)
end

return M
