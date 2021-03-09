RItem4 = Super:New{Name = "RItem4"}

local M = RItem4

M.eUpdatePrice = Event()

function M:Ctor()
    self.TotalPrice = 0
    self.CurNum = 0
    self.IsSelect = true
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local S = UITool.SetLsnrSelf

    self.mGo = go
    self.mItemRoot = F(trans, "cell")
    self.mName = G(UILabel, trans, "name")
    self.mSinglePrice = G(UILabel, trans, "SinglePrice")
    self.mTotalPrice = G(UILabel, trans, "TotalPrice")
    self.mCount = G(UILabel, trans, "Count")
    self.mHighlight = FC(trans, "Highlight")

    SC(trans, "BtnAdd", self.Name, self.OnAdd, self)
    SC(trans, "BtnReduce", self.Name, self.OnReduce, self)
   
    S(self.mCount, self.OnInput, self, self.Name, false)
    S(go, self.OnSelect, self, self.Name, false)

    -- self:SetLsnr("Add")
end

function M:SetLsnr(key)
    PricePanel.eConfirm[key](PricePanel.eConfirm, self.OnConfirm, self)
    PricePanel.eNum[key](PricePanel.eNum, self.OnNum, self)
    PricePanel.eClear[key](PricePanel.eClear, self.OnClear, self)
end

function M:OnSelect()
    UIAuctionR4:SetIsSelect(self.Data.id)
    self.IsSelect = not self.IsSelect
    self:UpdateHighlight()
    self.eUpdatePrice()
end

function M:OnInput()
    self:SetLsnr("Add")
    self.mNunStr = "0"
    UIMgr.Open(PricePanel.Name)
end

function M:OnConfirm(num)
    self:SetLsnr("Remove")
    if num > self.Data.num then
        self.CurNum = self.Data.num
    elseif num > 0 then
        self.CurNum = num
    else
        self.CurNum = 1
    end
    self:UpdatePriceCount()
end

function M:OnNum(num)
    self.mNunStr = self.mNunStr .. num
    local num = tonumber(self.mNunStr)
    if num > self.Data.num then
        self.CurNum = self.Data.num
    elseif num > 0 then
        self.CurNum = num
    else
        self.CurNum = 1
    end
    self:UpdatePriceCount()
end

function M:OnClear()
    self.CurNum = 1
    self:UpdatePriceCount()
end
    

function M:OnAdd()
    self.CurNum = self.CurNum + 1
    if self.CurNum > self.Data.num then
        self.CurNum = self.Data.num
    end
    self:UpdatePriceCount()
end

function M:OnReduce()
    self.CurNum = self.CurNum - 1
    if self.CurNum < 1 then
        self.CurNum = 1
    end
    self:UpdatePriceCount()
end

function M:UpdatePriceCount()
    UIAuctionR4:ChangeNum(self.Data.id,self.CurNum);
    self:UpdateCount()
    self:UpdateTotalPrice()
    self.eUpdatePrice()
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end


function M:InitItem(data)
    if not data then return end
    self.Data = data
    self.mTemp = ItemData[tostring(data.type_id)]
    self.CurNum = data.num
    self:UpdateCell()
    self:UpdateName()
    self:UpdatePrice()
    self:UpdateTotalPrice()
    self:UpdateCount()
    self:UpdateHighlight()
end

function M:UpdateHighlight()
    local select = UIAuctionR4:GetIsSelect(self.Data.id);
    self.mHighlight:SetActive(select);
end

function M:UpdateCell()
    if not self.mCell then
        self.mCell = ObjPool.Get(UIItemCell)
        self.mCell:InitLoadPool(self.mItemRoot)
    end
    self.mCell:UpData(self.Data.type_id)
end

function M:UpdateName()
    self.mName.text = self.mTemp.name
end

function M:UpdatePrice()
    self.mSinglePrice.text = self.mTemp.startPrice
end

function M:UpdateTotalPrice()
    local total = self.mTemp.startPrice * self.CurNum
    self.TotalPrice = total
    self.mTotalPrice.text = total
end

function M:UpdateCount()
    self.mCount.text = self.CurNum
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.Data = nil
    self.mTemp = nil
    self.TotalPrice = 0
    self.CurNum = 0
    self.IsSelect = true
    if self.mCell then
        self.mCell:DestroyGo()
        ObjPool.Add(self.mCell)
        self.mCell = nil
    end
    TableTool.ClearUserData(self)
end

return M