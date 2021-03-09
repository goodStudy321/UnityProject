DemonRewardView = Super:New{Name = "DemonRewardView"}

require("UI/UIDemon/DemonProCell")
require("UI/UIDemon/DemonProRewardCell")

local M = DemonRewardView

M.mProCells = {}
M.mRewardCells = {}

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local G = ComTool.Get

    self.mGo = go
    self.mSlider = G(UISlider, trans, "Progress")
    self.mGrid = F(trans, "Grid")

    for i=1,4 do
        local path = tostring(i)
        local cell = ObjPool.Get(DemonProCell)
        cell:Init(FC(self.mSlider.transform, path))
        self.mProCells[i] = cell

        cell = ObjPool.Get(DemonProRewardCell)
        cell:Init(FC(self.mGrid, path))
        self.mRewardCells[i] = cell
    end

    UITool.SetLsnrClick(trans, "BtnClose", self.Name, self.Close, self)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:UpdateBossHpRewardStatus(id)
    if self.mProCells[id] then
        self.mProCells[id]:UpdateMask()
    end
    if self.mRewardCells[id] then
        self.mRewardCells[id]:UpdateBtnStatus()
    end
    self:UpdateSlider()
end

function M:UpdateData()
    local data = DemonMgr:GetBossHpRewardData()
    if not data then return end
    self.mData = data
    self:UpdateCells(self.mProCells, data)
    self:UpdateCells(self.mRewardCells, data)
    self:UpdateSlider()
end

function M:UpdateSlider()
    if not self.mData then return end
    local data = self.mData
    local index = 1
    for i=1,#data do
        if data[i].HadGet > 0 then
            index = i
        end
    end
    self.mSlider.value = (index-1)/3
end

function M:UpdateCells(list, data)
    for i=1,#list do
        list[i]:UpdateData(data[i])
    end
end

function M:Open()
    self:UpdateData()
    self:SetActive(true)
end

function M:Close()
    self:SetActive(false)
end

function M:Dispose()
    self.mData = nil
    TableTool.ClearDicToPool(self.mProCells)
    TableTool.ClearDicToPool(self.mRewardCells)
    TableTool.ClearUserData(self)
end

return M