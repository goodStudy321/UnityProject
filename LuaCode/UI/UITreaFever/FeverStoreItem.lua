FeverStoreItem = Super:New{Name = "FeverStoreItem"}
local M = FeverStoreItem

function M:Init(go)
    local US = UITool.SetBtnClick
    local C = ComTool.Get
    local TFC = TransTool.FindChild
    self.go = go
    local trans = go.transform
    local des = self.Name

    US(trans, "btn", des, self.OnBuy, self)

    self.nameLb = C(UILabel,trans,"name",des)
    self.goldLb = C(UILabel,trans,"gold",des)
    self.lmNum=C(UILabel,trans,"lmNum",des)
    self.btnSpr = TFC(trans,"btn",des)

    self.goldSpr = C(UISprite,trans,"gold/Spr",des)

    self.cellRoot = TFC(trans,"cell").transform

    self:SetLsner("Add")
end

function M:SetLsner(func)
    TreaFeverMgr.eUpStore[func](TreaFeverMgr.eUpStore, self.UpBtnState, self)
end

function M:InitItem(data)
    self.data = data
    self.nameLb.text  = data.name
    self.goldLb.text = math.NumToStr(data.price,0)
    local id = data.type_id
    local num = data.num
    if not self.item then
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellRoot,0.8)
    end
    self.item:UpData(id,num)
    self:UpBtnState(self.data.id,self.data)
    self:ShowIconType()
end

function M:UpBtnState(id,data)
    if self.data.id ~= id then return end
    local canBuyNum = data.canBuyNum
    local resBuyNum = data.resBuyNum
    --local resNum = canBuyNum - hasBuyNum
    local nowStr = "[F21919FF]0[-]"
    if resBuyNum == 0 then
        UITool.SetGray( self.btnSpr )
    else
        nowStr=resBuyNum
        UITool.SetNormal( self.btnSpr )
    end
    self.lmNum.text=string.format( "%s/%s",nowStr,canBuyNum )
    -- local box =  self.btnSpr.gameObject:GetComponent(typeof(BoxCollider))
    -- box.enabled=not resBuyNum == 0 
    -- self.btnSpr.spriteName = btnSpr
end

function M:ShowIconType()
    local type = self.data.type
    local iconName = "money_0"..type
    self.goldSpr.spriteName = iconName
end

function M:OnBuy()
    local moneyType = self.data.type
    local newPrice = self.data.price
    if moneyType == 1 then
        if RoleAssets.Silver < newPrice then
            MsgBox.ShowYesNo("银两不足，是否充值？",self.YesJumpCb,self)
            return
        end
    elseif moneyType == 2 then
        if RoleAssets.Gold < newPrice then
            StoreMgr.JumpRechange()
            return
        end
    elseif moneyType==3 then
        if RoleAssets.BindGold < newPrice then
            StoreMgr.JumpRechange()
            return
        end
    end

    local actId = FestivalActMgr.BZSC
    local id = self.data.id
    FestivalActMgr:ReqBgActReward(actId,id)
end

function M:YesJumpCb()
    StoreMgr.OpenVIPStore()
end

function M:Show(value)
    self.go:SetActive(value)
end


function M:Dispose()
    self:SetLsner("Dispose")
    if self.item then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    TableTool.ClearUserData(self)
end

return M