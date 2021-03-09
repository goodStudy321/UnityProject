UIEscortQualityView = Super:New{Name = "UIEscortQualityView"}

require("UI/UIFamilyEscort/UIEscortQuaCell")

local M = UIEscortQualityView

M.mCellList = {}

M.mDiscount = 0.7

M.eSelectEscort = Event()

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.mGo = go

    self.mSingle = FC(trans, "SinglePrice")
    self.mSingleIR = F(self.mSingle.transform, "ItemRoot")
    self.mSinglePrice = G(UILabel, self.mSingle.transform, "Price")

    self.mTotal = FC(trans, "TotalPrice")
    self.mTotalIR = F(self.mTotal.transform, "ItemRoot")
    self.mTotalPrice = G(UILabel, self.mTotal.transform, "Price")
    self.mCurPrice = G(UILabel, self.mTotal.transform, "CurPrice")

    self.mBtnAdvBest = FC(trans, "BtnAdvBest")
    self.mBtnAdvQua = FC(trans, "BtnAdvQua")

    self.mFxAdv = FC(trans, "UI_niu_B")
    self.mFxSelect = FC(trans, "UI_niu_xz")

    S(self.mBtnAdvBest, self.OnAdvBest, self)
    S(self.mBtnAdvQua, self.OnAdvQua, self)

    self:InitCells(trans)
end

function M:InitCells(trans)
    local parent = TransTool.Find(trans, "Cells")
    local data = FamilyEscortMgr:GetEscortsData()
    for i=1,#data do
        local go =  TransTool.FindChild(parent, tostring(i))
        local cell = ObjPool.Get(UIEscortQuaCell)
        cell:Init(go, function() self:OnSelectCell(data[i]) end)
        cell:UpdateData(data[i])
        M.mCellList[i] = cell
    end
end

function M:Open()
    self:Refresh()
    self:SetActive(true)
end

function M:Refresh()
    local data = FamilyEscortMgr:GetCurEscortData()
    if not data then return end
    self.mData = data
    self:UpdateSinglePrice()
    self:UpdateTotalPrice()
    self:UpdateBtnAdvQua()
    self:UpdateBtnAdvBest()
    self:UpdateCells()
    self:UpdateSelect()
end

function M:UpdateCells()
    local cells = M.mCellList
    for i=1, #cells do
        cells[i]:UpdateTarget()
    end
end

function M:Close()
    self:SetActive(false)
end

function M:UpdateSelect()
    self:OnSelectCell(self.mData)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:OnAdvBest()
    if not self.mData then return end
    local cost = self.mData.Cost
    if not cost then return end
    local preferPrice = self.mData.PreferPrice
    if not preferPrice then return end
    local need= math.ceil(preferPrice * M.mDiscount)
    local num = PropMgr.TypeIdByNum(cost.k)
    if num >= need then
        FamilyEscortMgr:ReqRoleEscort(2)
    else
        self:OpenMsxBox(cost.k, need, num, 2)
    end
end

function M:OnAdvQua()
    if not self.mData then return end
    local cost = self.mData.Cost
    if not cost then return end
    local num = PropMgr.TypeIdByNum(cost.k)
    local need = cost.v
    if num >= need then
        FamilyEscortMgr:ReqRoleEscort(1)
    else
        self:OpenMsxBox(cost.k, need, num, 1)
    end
end

function M:OpenMsxBox(id, need, num, type)
    self.mNeedNum = need - num
    self.mType = type
    local price = StoreMgr.GetTotalPrice(id, self.mNeedNum)
    MsgBox.ShowYesNo(string.format("是否消耗%s绑元/元宝(绑元优先)购买%s个护花令,并提升护送品质", price, self.mNeedNum), self.YesCb, self)
end

function M:YesCb()
    if self.mData and self.mData.Cost then
        StoreMgr.TypeIdBuy(self.mData.Cost.k, self.mNeedNum, false)
    end
end

function M:BuyResp(typeId)
    if not self.mData then return end
    local cost = self.mData.Cost
    if not cost then return end
    if not self.mType then return end
    if typeId == cost.k then
        FamilyEscortMgr:ReqRoleEscort(self.mType)
    end
end

function M:OnSelectCell(data)
    if not data then return end
    if self.mIndex and self.mIndex == data.Quality then return end
    if self.mIndex then
        M.mCellList[self.mIndex]:UpdateSelect(false)
    end
    self.mIndex = data.Quality
    local cell = M.mCellList[self.mIndex]
    cell:UpdateSelect(true)  
    cell:SetSelectFx(self.mFxSelect)
    self.eSelectEscort(data)
end

function M:SetAdvFx()
    self:StopTimer()
    local curEscortId = FamilyEscortMgr:GetCurEscortId()
    local list = self.mCellList
    for i=1,#list do
        if list[i].Data.Id == curEscortId then
            list[i]:SetAdvFx(self.mFxAdv)
            self:StartTimer()
            break
        end
    end
end

function M:StopTimer()
    if self.mTimer then
        self.mTimer:Stop()
    end
end

function M:StartTimer()
    if not self.mTimer then
        self.mTimer = ObjPool.Get(iTimer)
        self.mTimer.seconds = 0.5
        self.mTimer.complete:Add(self.CompleteCb, self)
    end
    self.mTimer:Start()
end

function M:CompleteCb()
    if not self.mFxAdv then return end
    self.mFxAdv:SetActive(false)
end

function M:UpdateSinglePrice()
    local cost = self.mData.Cost
    if not cost then
        self.mSingle:SetActive(false)
        return
    end
    self.mSingle:SetActive(true)
    if not self.mSingleCell then
        self.mSingleCell = ObjPool.Get(UIItemCell)
        self.mSingleCell:InitLoadPool(self.mSingleIR, 0.35)
        self.mSingleCell:UpData(cost.k)
    end
    self.mSinglePrice.text = ItemTool.GetConsumeOwn(cost.k, cost.v)
end

function M:UpdateTotalPrice()
    local need = self.mData.PreferPrice
    if not need then 
        self.mTotal:SetActive(false)
        return 
    end
    self.mTotal:SetActive(true)
    local cost = self.mData.Cost
    if not self.mTotalCell then
        self.mTotalCell = ObjPool.Get(UIItemCell)
        self.mTotalCell:InitLoadPool(self.mTotalIR, 0.35)
        self.mTotalCell:UpData(cost.k)
    end
    local num = PropMgr.TypeIdByNum(cost.k)
    local need = self.mData.PreferPrice
    local cur = math.ceil(need * M.mDiscount)
    local color = num >= cur and "[00FF00FF]" or "[CC2500FF]"
    self.mTotalPrice.text = string.format("%s%s/[s]%s", color, num, need)
    self.mCurPrice.text = string.format("%s%s", color, cur)
end

function M:UpdateBtnAdvQua()
    local qua = FamilyEscortMgr:GetCurEscortQua()
    local maxQua = FamilyEscortMgr:GetEscortMaxQua()  
    if qua < maxQua then
        UITool.SetNormal(self.mBtnAdvQua)
    else
        UITool.SetGray(self.mBtnAdvQua)
    end
end

function M:UpdateBtnAdvBest()
    local qua = FamilyEscortMgr:GetCurEscortQua()
    local maxQua = FamilyEscortMgr:GetEscortMaxQua()  
    if maxQua - qua <= 1 then
        UITool.SetGray(self.mBtnAdvBest)
    else
        UITool.SetNormal(self.mBtnAdvBest)
    end
end

function M:Dispose()
    self.mIndex = nil
    self.mData = nil
    self.mType = nil
    self.mNeedNum = nil
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    if self.mSingleCell then
        self.mSingleCell:DestroyGo()
        ObjPool.Add(self.mSingleCell)
        self.mSingleCell = nil
    end
    if self.mTotalCell then
        self.mTotalCell:DestroyGo()
        ObjPool.Add(self.mTotalCell)
        self.mTotalCell = nil
    end
    TableTool.ClearDicToPool(M.mCellList)
    TableTool.ClearUserData(self)
end

return M