SpiritAdvEquipCell = Super:New{Name = "SpiritAdvEquipCell"}

local My = SpiritAdvEquipCell

function My:Ctor()
    self.eClick =Event()
    self.cellList = {}
end

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.tab = G(UIGrid, trans, "Grid")
    self.prefab = FC(self.tab.transform, "Cell")
    self.prefab:SetActive(false)

    UITool.SetLsnrSelf(go, self.OnClick, self)
end

function My:UpdateData(data)
    self.data = data
    self:UpdateCell()
end

function My:GetEquipData()
    local list = {}
    local conds = self.data.condList
    for i=1,#conds do
        if conds[i].isUse then
            table.insert(list, conds[i].equipData)
        end
    end
    return list
end


function My:UpdateCell()
    local data = self:GetEquipData()
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
            local item = ObjPool.Get(SpEquipCell)
            item:Init(go)
            item.eClick:Add(self.OnEquipCell, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.tab:Reposition()
end

function My:SetSelect(equipId)
    local list = self.cellList
    local len = #list
    for i=1,len do
        if list[i].data.id == equipId then
            list[i]:OnClick()
            return
        end
    end
    if len > 0 then
        list[1]:OnClick()
    end
end

function My:OnEquipCell(id)
    local list = self.cellList
    for i=1,#list do
        list[i]:SetHighlight(list[i].data.id == id)
    end
    SpiritGMgr:SetEquipId(id)
end

function My:OnClick()
    if self.data then
        self.eClick(self.data.id)
    end
end

function My:Reset()
    local list = self.cellList
    for i=1,#list do
        list[i]:SetHighlight(false)
    end
    self:SetHighlight(false)
    self:HideEquip()
end

function My:HideEquip()
    self.tab.gameObject:SetActive(false)
end


function My:SetActive(state)
    self.go:SetActive(state)
end

function My:IsActive()
    return self.go.activeSelf
end


function My:Dispose()
    self.data = nil
    self.eClick:Clear()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return My