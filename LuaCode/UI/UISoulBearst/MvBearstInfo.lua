MvBearstInfo = Super:New{Name = "MvBearstInfo"}

local M = MvBearstInfo

M.eClick = Event()

function M:Ctor()
    self.cellList = {}
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
            TransTool.AddChild(self.grid.transform, go.transform)
            local item = ObjPool.Get(MvBearstCell)
            item:Init(go)
            item.eClick:Add(self.OnBearstCell, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function M:Refresh()
    self:UpdateCell()
end


function M:OnBearstCell(data)
    self.eClick(data)
    self:SetHighlight(data.id)
    SoulBearstMgr:SetCurSBId(data.id)
end

function M:SetHighlight(id)
    local list = self.cellList
    for i=1, #list do 
        list[i]:SetHighlight(list[i].data.id==id)
    end
end

function M:Switch(id)
    local list = self.cellList   
    local len = #list
    if id then
        for i=1,len do
            if list[i].data.id == id then
                self:OnBearstCell(list[i].data)
                return
            end
        end
    end
    self:SetDef()
end

function M:SetDef()
    local list = self.cellList   
    if #list > 0 then
        self:OnBearstCell(list[1].data)
    end
end


function M:Dispose()
    self.data = nil
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M