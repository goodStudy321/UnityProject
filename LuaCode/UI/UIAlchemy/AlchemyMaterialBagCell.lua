AlchemyMaterialBagCell = Super:New{Name = "AlchemyMaterialBagCell"}

local M = AlchemyMaterialBagCell

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go, index)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.mGo = go
    self.mTrans = trans
    self.mSelect = FC(trans, "Select")
    self.mSelect:SetActive(false)
    self.mIsSelect = false
    self.mIndex = index
end

function M:SetActive(bool)
   self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:NotSelect()
    return not self.mIsSelect
end

function M:UpdateSelect(bool)
    self.mIsSelect = bool
    self.mSelect:SetActive(bool)
end

function M:UpdateData(data)
    if not data then return end
    self.Data = data
    if not self.mCell then
        self.mCell = ObjPool.Get(Cell)
        self.mCell:InitLoadPool(self.mTrans)
        self.mCell.eClickCell:Add(self.OnClick, self)
    end
    self.mCell:UpData(data.TypeId, data.Num)
    self:UpdateSelect(false)
end

function M:OnClick()
    if not self.Data then return end
    self.mIsSelect = not self.mIsSelect
    self:UpdateSelect(self.mIsSelect)
    self.eClick(self.mIsSelect, self.mIndex)
end

function M:Dispose()
    self.mIndex = nil
    self.Data = nil
    self.mIsSelect = false
    self.eClick:Clear()
    if self.mCell then
        self.mCell:DestroyGo()
        ObjPool.Add(self.mCell)
        self.mCell = nil
    end
    TableTool.ClearUserData(self)
end

return M