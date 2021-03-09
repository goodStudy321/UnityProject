PetPackCell = Super:New{Name = "PetPackCell"}

local My = PetPackCell

function My:Ctor()
    self.eClick = Event()
end

function My:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.go = go
    self.highlight = FC(trans, "Highlight")
    self.isSelect = false
end

function My:UpdateData(data)
    self.data = data
    if not self.cell then
        self.cell = ObjPool.Get(Cell)
        self.cell:InitLoadPool(self.go.transform)
        self.cell.eClickCell:Add(self.OnClick, self)
    end
    self.cell:UpData(self.data.type_id)
    local itemCfg = ItemData[tostring(self.data.type_id)]
    if itemCfg and itemCfg.uFx == 7 then -- 伙伴吞噬丹
        local count = PropMgr.TypeIdByNum(self.data.type_id)
        self.cell:UpLab(count)
    end
    self:SetHighlight(false)
end

function My:OnClick()
    self.isSelect = not self.isSelect
    self:SetHighlight(self.isSelect)
    self.eClick(self.isSelect, self.data)
end

function My:SetHighlight(state)
    self.isSelect = state
    self.highlight:SetActive(state)
end

function My:IsActive()
    return self.go.activeSelf
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:Dispose()
    self.eClick:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    self.data = nil
    self.isSelect = false
    TableTool.ClearUserData(self)
end

return My