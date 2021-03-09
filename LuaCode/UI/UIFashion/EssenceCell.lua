EssenceCell = Cell:New{Name = "EssenceCell"}

local M = EssenceCell

function M:CreateCell(go, scale)
    self:InitUserData(go)
    self:InitLoadPool(go.transform, scale) 
    self:SetActive(true)
end

function M:UpdateCell(data)
    self.data = data 
    self.isSelect = false
    self.select:SetActive(false)
    self:UpData(data.type_id)
end


function M:InitUserData(go)
    local FG = TransTool.FindChild
    local trans = go.transform

    self.go = go
    self.select = FG(trans, "Select")
end

function M:OnClick(go)
    self:UpdateSelect()
end

function M:SetHandler(func, handler)
    self.func = func
    self.handler = handler
end

function M:UpdateSelect(bool)
    if bool == nil then
        self.isSelect = not self.isSelect
        self.func(self.handler, self.data, self.isSelect)
    elseif self.isSelect ~= bool then
        self.isSelect = bool
        self.func(self.handler, self.data, self.isSelect)
    end
    self.select:SetActive(self.isSelect)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:ActiveSelf()
    return self.go.activeSelf
end

function M:DisposeCus()
    self.func = nil
    self.handler = nil
    self.data = nil
    self.isSelect = nil
end

return M