UICopyQuickBuy = Super:New{Name = "UICopyQuickBuy"}

local M = UICopyQuickBuy

function M:Init(go)
    local trans = go.transform
    local F = TransTool.Find
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick

    self.go = go
    self.itemRoot = F(trans, "ItemRoot")
    self.name = G(UILabel, self.itemRoot, "Name")
    self.count = G(UILabel, trans, "Count")
    self.price = G(UILabel, trans, "Price")
    self.icon = G(UISprite, self.price.transform, "Icon")

    SC(trans, "BtnClose", self.Name, self.Close, self, false)
    SC(trans, "BtnMinus", self.Name, self.OnMinus, self, false)
    SC(trans, "BtnAdd", self.Name, self.OnAdd, self, false)
    SC(trans, "BtnBuy", self.Name, self.OnBuy, self, false)
    SC(trans, "Count", self.Name, self.OnCount, self, false)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    PricePanel.eConfirm[key](PricePanel.eConfirm, self.OnConfirm, self)
end

function M:OnConfirm(num)
    self.num = num
    if self.num > 99 then
        self.num = 99 
    end
    self:UpdateCountCost()
end

function M:Open(data)
    self.data = data
    self.num = 1
    self:SetActive(true)
    self:UpdateIcon()
    self:UpdateItem()
    self:UpdateCountCost()
end

function M:Close()
    self:SetActive(false)
end

function M:OnCount()
    UIMgr.Open(PricePanel.Name)
end

function M:OnMinus()
    self.num = self.num - 1
    if self.num <= 0 then
        self.num = 0
    end
    self:UpdateCountCost()
end

function M:OnAdd()  
    self.num = self.num+1
    if self.num >= 99 then
        self.num = 99
    end 
    self:UpdateCountCost()
end

function M:OnBuy()
    if self.data then
        if self.num > 0 then
            StoreMgr.TypeIdTpBuy(self.data.arg1 ,self.data.itemId, self.num)
            self:Close()
        else
            UITip.Log("请输入购买数量")
        end
    end
end

function M:UpdateItem()
    if not self.cell then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.itemRoot)
        self.cell:UpData(self.data.itemId)
        self.name.text = ItemData[tostring(self.data.itemId)].name
    end
end

function M:UpdateIcon()
    local arg2 = self.data.arg2
    if not arg2 then return end
    local spriteName = "money_02"
    if arg2 == 3 then
        spriteName = "money_03"
    elseif arg2 == 11 then
        spriteName = "money_11"
    end
    self.icon.spriteName = spriteName
end

function M:UpdateCountCost()
    if not self.data then return end
    self.count.text = self.num
    local cost = StoreMgr.GetTotalPriceByShopType(self.data.arg1, self.data.itemId, self.num)
    local color = RoleAssets.IsEnoughAsset(self.data.arg2, cost) and "[F4DDBDFF]" or "[F21919FF]"
    self.price.text = string.format("%s%s", color, cost)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:ClearNum()
    self.num = 1
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.data = nil
    self:ClearNum()
    TableTool.ClearUserData(self)
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return M