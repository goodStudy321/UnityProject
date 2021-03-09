SPEquipListCell = Super:New{Name = "SPEquipListCell"}

local My = SPEquipListCell

My.eClick =Event()

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.go = go
    self.name = G(UILabel, trans, "Name")

    S(go, self.OnClick, self)
end


function My:UpdateCell()
    local data = self.data
    if data.isUse then
        if not self.cell then
            self.cell = ObjPool.Get(SPCell)
            self.cell:InitLoadPool(self.go.transform)
            self.cell:SetTip(true, true, false)
        end
        self.cell:UpdateData(data.equipData)
        self.cell:UpdateLab(data.equipData.advVal <= data.equipData.level)
        self:SetActive(true)
    else
        self:SetActive(false)
    end
end

function My:UpdateData(data)
    self.data = data 
    self:UpdateCell()
    -- self:UpdateName()
end

function My:UpdateName()
    self.name.text = self.data.type
end

function My:SetActive(state)
    if self.cell then
        self.cell:SetActive(state)
    end
end


function My:OnClick()
    if self.data and self.data.isUse == false then
        self.eClick(self.data.type, self.data.quality)
    end
end

function My:Dispose()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    self.data = nil
    TableTool.ClearUserData(self)
end

return My