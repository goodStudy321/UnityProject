ADVCell = Super:New{Name = "ADVCell"}

local M = ADVCell

M.eClick = Event()

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    
    self.go = go
    self.select = FC(trans, "Select")
    self.cell = ObjPool.Get(Cell)
    self.cell:InitLoadPool(trans)   
    self.cell.eClickCell:Add(self.OnClick, self)
end

function M:UpdateData(data)
    self.data = data
    self.cell:UpData(data.id, data.num)
    self:SetHighlight(false)
end

function M:OnClick()
    if self.data then
        self:SetSelectState()
    end
end

function M:SetSelectState(state)
    if state ~= nil then
        self.select:SetActive(state)
    else
        self.select:SetActive(not self.select.activeSelf)
    end
    M.eClick(self.select.activeSelf, self.data.id, self.data.num)
end

function M:SetHighlight(state)
    self.select:SetActive(state)
end

function M:SetActive(state)
    if state == true then
        self.go:SetActive(state)
    else
        self.data = nil
    end
    if self.cell then
        self.cell:SetActive(state)
    end
end

function M:IsActive()
    return self.go.activeSelf
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return M