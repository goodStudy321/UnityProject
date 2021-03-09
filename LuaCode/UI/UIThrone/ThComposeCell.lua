ThComposeCell = Super:New{Name = "ThComposeCell"}

local My = ThComposeCell

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
    local num = PropMgr.TypeIdByNum(self.data)
    self.cell:UpData(self.data,num)
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