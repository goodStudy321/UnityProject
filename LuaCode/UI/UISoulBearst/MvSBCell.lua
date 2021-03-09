MvSBCell = Super:New{Name = "MvSBCell"}

local M = MvSBCell

M.eClick =Event()

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    self.go = go
    self.name = G(UILabel, trans, "Name")
    self.redPoint = FC(trans, "RedPoint")

    S(go, self.OnClick, self)
end


function M:UpdateCell()
    if self.data.isUse then
        if not self.cell then
            self.cell = ObjPool.Get(SBCell)
            self.cell:InitLoadPool(self.go.transform)
            self.cell:SetTip(true, true, false)
        end
        self.cell:UpdateData(self.data.equipData)
        self:SetActive(true)
    else
        self:SetActive(false)
    end
end

function M:UpdateData(data)
    self.data = data 
    self:UpdateCell()
    self:UpdateName()
    self:UpdateRedPoint()
end

function M:UpdateRedPoint()
    self.redPoint:SetActive(self.data.redPointState)
end

function M:UpdateName()
    self.name.text = self.data.typeName
end

function M:SetActive(state)
    if self.cell then
        self.cell:SetActive(state)
    end
end


function M:OnClick()
    if self.data and self.data.isUse == false then
        self.eClick(self.data.type, self.data.quality)
    end
end

function M:Dispose()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    self.data = nil
    TableTool.ClearUserData(self)
end

return M