SpEquipCell = Super:New{Name = "SpEquipCell"}

local My = SpEquipCell

My.eUpdateAdv = Event()

function My:Ctor()
    self.eClick = Event()
end

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.go = go
    self.name = G(UILabel, trans, "Name")
    self.level = G(UILabel, trans, "Adv")
    self.highlight = FC(trans, "Highlight")
    self.itemRoot = F(trans, "ItemRoot")
    self.red = FC(trans,"red")
    UITool.SetLsnrSelf(go, self.OnClick, self)
end

function My:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateLevel()
    self:UpdateCell()
end

function My:UpdateName()
    self.name.text = self.data.name
end

function My:UpdateLevel()
    self.level.text = string.format("+%s", self.data.level)
end

function My:UpdateCell()
    if not self.cell then
        self.cell = ObjPool.Get(SPCell)
        self.cell:InitLoadPool(self.itemRoot)
    end
    self.cell:UpdateData(self.data)
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:SetHighlight(state)
    if self:IsActive() then
        self.highlight:SetActive(state)
    end
end

function My:SetRed(ac)
    self.red:SetActive(ac)
end

function My:IsActive()
    return self.go.activeSelf
end

function My:OnClick()
    if self.data then
        self.eClick(self.data.id)
        self.eUpdateAdv(self.data)
    end
end

function My:Dispose()
    self.data = nil
    self.eClick:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    TableTool.ClearUserData(self)
end

return My