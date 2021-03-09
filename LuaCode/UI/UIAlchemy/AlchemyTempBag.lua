AlchemyTempBag = Super:New{Name = "AlchemyTempBag"}

local M = AlchemyTempBag

M.mCells = {}
M.mMax = 200

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    self.mGo = go
    self.mGrid = G(UIGrid, trans, "Container/ScrollView/Grid")
    self.mBtnTakeOut = FC(trans, "BtnTakeOut")
    self.mBtnClose = FC(trans, "BtnClose")
    
    S(self.mBtnTakeOut, self.OnTakeOut, self)
    S(self.mBtnClose, self.Close, self)
end

function M:OnTakeOut()
    TreasureMgr:ReqSortOutAll(6)
end


function M:UpdateData()
    local data = AlchemyMgr:GetTempBagData()
    local len = #data
    if len > M.mMax then
        len = M.mMax
    end
    local list = self.mCells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:TipData(data[i], data[i].num, {"GetOut"})
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.mGrid.transform)
            item:TipData(data[i], data[i].num, {"GetOut"})
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
end


function M:Open()
    self:SetActive(true)
    self:UpdateData()
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end


function M:Dispose()
    TableTool.ClearListToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M