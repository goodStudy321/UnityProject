UILvLimitBuyItem = Super:New{Name="UILvLimitBuyItem"}

local M = UILvLimitBuyItem

local mathToStr = math.NumToStrCtr

function M:Init(go)
    local F = TransTool.FindChild
    local trans = go.transform
    local C = ComTool.Get
    local US = UITool.SetLsnrSelf

    self.go = go

    --//道具名称
    self.nameLb=C(UILabel,trans,"Name/NameLb")
    --//折扣
    self.disCountLb=C(UILabel,trans,"DisCount/Label")
    self.disObj = F(trans,"DisCount")
    --//原价
    self.priceLb=C(UILabel,trans,"Price")
    self.disCLine = F(trans,"Price/Label")
    --//现价
    self.newPriceLb=C(UILabel,trans,"NewPrice")
    --//道具格子
    self.itemCell=F(trans,"GoodSprite")
    --//货币图片

    self.timeLb = C(UILabel,trans,"time")

    self.priceIcon = {}
    self.newPriceIcon = {}
    for i=1,3 do
        local obj1 = F(trans,"Price/Icon"..i)
        local obj2 = F(trans,"NewPrice/Icon"..i)
        self.priceIcon[#self.priceIcon + 1] = obj1
        self.newPriceIcon[#self.newPriceIcon + 1] = obj2
    end

    --//购买按钮物体
    self.buyBtn=F(trans,"BuyBtn")
    self.buyBtnLb=C(UILabel,trans,"BuyBtn/Label")
    US(self.buyBtn,self.Click,self)

    self.dTimer = ObjPool.Get(iTimer)
    self:SetLsnr("Add")
end
function M:SetLsnr(key)
    --LvLimitBuyMgr.eUpdate[key](LvLimitBuyMgr.eUpdate,self.UpdateBtn,self)
end

function M:InitItem(data)
    if data == nil then return end
    self.data = data
    if not self.item then
        self.item=ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.itemCell.transform)
    end
    local item=self.item
    local id = self.data.award.id
    local num = self.data.award.num
    item:UpData(id,num)

    self.nameLb.text = self.data.name
    local dis = self.data.disCNum
    if dis == 0 or not dis then
        self.disObj:SetActive(false)
        self.disCLine:SetActive(false)
    else
        self.disObj:SetActive(true)
        self.disCLine:SetActive(true)
        self.disCountLb.text = StrTool.Concat(dis,"折")
    end
    if dis == 0 and self.data.newPrice == 0 then
        self.disCLine:SetActive(true)
    end
    self.newPriceLb.text = mathToStr(self.data.newPrice)
    self.priceLb.text = mathToStr(self.data.price)

    local eTime = data.time
    self:StartTimer(eTime)

    -- if data.value == 0 then
    --     self:SetBtnStatus(false)
    -- else
    --     self:SetBtnStatus(true)
    -- end
    self:SelMoneyType()
end

function M:StartTimer(eTime)
    if not eTime then return end
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
    end
    local timer = self.timer
    timer:Stop()
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = eTime - now
    if dValue<=0 then
        timer.remain = ""
        self:EndTime()
    else
        timer.seconds=dValue
        timer.fmtOp = 3
        timer.invlCb:Add(self.UpTime,self)
        timer.complete:Add(self.EndTime, self)
        timer:Start()
        self:UpTime()
    end
end

function M:UpTime()
    local time = self.timer.seconds - self.timer.cnt
    -- self.eUpdateTime(time)
    self.timeLb.text = "抢购限时："..self.timer.remain
end

function M:EndTime()
    self:StopTimer()
    LvLimitBuyMgr:UpItem(self.data.id)
    -- self.eOpenOrClose(false)
    --self:SetBtnStatus(false)
    --self.buyBtnLb.text = "已过期"
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
end

-- function M:SetBtnStatus(value)
--     if value == true then
--         self.buyBtnLb.text = "已购买"
--         UITool.SetGray(self.buyBtn)
--     else
--         self.buyBtnLb.text = "我要购买"
--         UITool.SetNormal(self.buyBtn)
--     end
-- end

-- function M:UpdateBtn(id)
--     if self.data.id == id then
--         self.buyBtnLb.text = "已购买"
--         UITool.SetGray(self.buyBtn)
--     end
-- end


function M:Click()
    -- self.add = ObjPool.Get(StrBuffer)
    -- local moneyType=self.data.monType
    -- local newPrice=self.data.newPrice
    -- local oldPrice = self.data.price
    -- local num = self.data.award.num
    -- if moneyType == 1 then
    --     self.add:Apd("您确定花费"):Apd(newPrice):Apd("银两"):Apd("[f21919](原价"):Apd(oldPrice):Apd("银两)[-]购买"):Apd(self.data.name):Apd("*"):Apd(num)
    -- elseif moneyType == 2 then
    --     self.add:Apd("您确定花费"):Apd(newPrice):Apd("元宝"):Apd("[f21919](原价"):Apd(oldPrice):Apd("元宝)[-]购买"):Apd(self.data.name):Apd("*"):Apd(num)
    -- elseif moneyType == 3 then
    --     if RoleAssets.BindGold < newPrice then
    --         local msg = "[f21919](若绑元不足则使用元宝购买)[-]"
    --         self.add:Apd("您确定花费"):Apd(newPrice):Apd("绑元"):Apd("[f21919](原价"):Apd(oldPrice):Apd("绑元)[-]购买"):Apd(self.data.name):Apd("*"):Apd(num):Apd(msg)
    --     else
    --         self.add:Apd("您确定花费"):Apd(newPrice):Apd("绑元"):Apd("[f21919](原价"):Apd(oldPrice):Apd("绑元)[-]购买"):Apd(self.data.name):Apd("*"):Apd(num)
    --     end
    -- end
    -- MsgBox.ShowYesNo(self.add:ToStr(),self.YesCb,self)
    self:YesCb()
end

function M:YesCb()
    local moneyType=self.data.monType
    local newPrice=self.data.newPrice
    if moneyType == 1 then
        if RoleAssets.Silver < newPrice then
            UIMgr.Close(MsgBox.Name)
            self.dTimer:Start(0.1)
            self.dTimer.complete:Add(self.JumpVipStore,self)
        else
            LvLimitBuyMgr:ReqBuy(self.data.id)
        end
    elseif moneyType == 2 then
        if RoleAssets.Gold < newPrice then
            UIMgr.Close(MsgBox.Name)
            self.dTimer:Start(0.1)
            self.dTimer.complete:Add(self.Jump,self)
        else
            LvLimitBuyMgr:ReqBuy(self.data.id)
        end
    elseif moneyType==3 then
        if RoleAssets.BindGold < newPrice then
            if RoleAssets.Gold < newPrice then
                UIMgr.Close(MsgBox.Name)
                self.dTimer:Start(0.1)
                self.dTimer.complete:Add(self.Jump,self)
            else
                LvLimitBuyMgr:ReqBuy(self.data.id)
            end
        else
            LvLimitBuyMgr:ReqBuy(self.data.id)
        end
    end
end

function M:Jump()
    StoreMgr.JumpRechange()
end

function M:JumpVipStore()
    MsgBox.ShowYesNo("银两不足，是否充值？",self.YesJumpCb,self)
end

function M:YesJumpCb()
    StoreMgr.OpenVIPStore()
end

function M:SelMoneyType()
    local type = self.data.monType
    for i=1,3 do
        if type == i then
            self.priceIcon[i]:SetActive(true)
            self.newPriceIcon[i]:SetActive(true)
        else
            self.priceIcon[i]:SetActive(false)
            self.newPriceIcon[i]:SetActive(false)
        end
    end
end

function M:Show(bool)
    self.go:SetActive(bool)
end

function M:Dispose()
    self:SetLsnr("Remove")
    if self.timer then
        self:StopTimer()
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.item ~= nil then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    ObjPool.Add(self.add)
    self.add = nil
    if self.dTimer then
        self.dTimer:AutoToPool()
        self.dTimer = nil
    end
    TableTool.ClearUserData(self)
end

return M