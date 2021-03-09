RItem12 = Super:New{Name = "RItem12"}

local M = RItem12

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.isStart = false

    self.cellRoot = T(trans,"cell").transform
    self.name = C(UILabel,trans,"name",tip,false)
    self.curPriceLb = C(UILabel,trans,"price",tip,false)
    self.timeLb = C(UILabel,trans,"timeLb",tip,false)
    self.statusLb = C(UILabel,trans,"statusLb",tip,false)

    self.selfTipObj = T(trans,"selfTip")
    self.familyTipObj = T(trans,"familyTip")

    self.fixPriceLb = C(UILabel,trans,"oneBtn/price",tip,false)
    self.startPriceLb = C(UILabel,trans,"twoBtn/price",tip,false) 

    US(trans, "oneBtn", tip, self.OnBuyNow, self)
    US(trans, "twoBtn", tip, self.OnBid, self)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    AuctionMgr.eUpCurPrice[key](AuctionMgr.eUpCurPrice,self.UpItem,self)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:UpItem(data)
    if self.data.id == data.id then
        self:InitItem(data)
    end
end

function M:InitItem(data)
    if data == nil then return end
    self.data = data
    if not self.item then
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellRoot)
    end
    local item = self.item
    local id = self.data.type_id
    local num = self.data.num
    item.isCompare = true
    item:UpData(id,num)
    
    self.name.text = self.data.name
  
    local status = self.data.aucId
    self.statusLb.gameObject:SetActive(status ~= "0")

    local ratio = GlobalTemp["151"].Value3 *0.0001
    self.startPrice = ratio * self.data.cur_gold
    local type_id = self.data.type_id
    local itemData = ItemData[tostring(type_id)]
    self.curPriceLb.text = self.data.cur_gold
    if status == "0" then
        self.startPrice = itemData.startPrice * num
        self.curPriceLb.text = 0
    end
    self.fixPrice = itemData.fixedPrice * num

    self.startPrice = math.ceil(self.startPrice)
    if self.startPrice >= self.fixPrice then
        self.startPrice = self.fixPrice
    end

    self.fixPriceLb.text = self.fixPrice
    self.startPriceLb.text = self.startPrice

    self.selfTipObj:SetActive(false)
    self.familyTipObj:SetActive(false)

    local fromType = self.data.from_type
    local formId = self.data.from_id
    local uid = FamilyMgr:GetPlayerRoleId()
    if fromType == 0 then
        if formId == tostring(uid) then
            self.selfTipObj:SetActive(true)
        else
            self.selfTipObj:SetActive(false)
        end
    else
        local isJoin = FamilyMgr:JoinFamily()
        if isJoin then
            local familyData = FamilyMgr:GetFamilyData()
            if formId == tostring(familyData.Id) then
                self.familyTipObj:SetActive(true)
            else
                self.familyTipObj:SetActive(false)
            end
        end
    end
    self:ShowTime()
end

function M:ShowTime()
    local now = TimeTool.GetServerTimeNow()*0.001
    local endWaitTime = self.data.auction_time
    local endTime = self.data.end_time
    local lerp = endWaitTime - now
    if lerp <= 0 then
        lerp = endTime - now
        self.isStart = true
    else
        self.isStart = false
    end
    self:StartTime(lerp)
end

function M:StartTime(dValue)
    if not dValue then return end
    if not self.timer then
        self.timer=ObjPool.Get(DateTimer)
    end
    local timer=self.timer
    timer:Stop()
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
    local lab = ""
    if self.isStart == true then
        lab = "[00FF00]"..self.timer.remain.."后结束"
    else
        lab = "[FF0000]"..self.timer.remain.."后开始"
    end
    self.timeLb.text = lab
end

function M:EndTime()
    if self.isStart == true then
        self.timer:Stop()
    else
        self:ShowTime()
    end
end

function M:Show(value)
	self.go:SetActive(value)
end

-- 一口价
function M:OnBuyNow()
    local id = self.data.id
    local curPrice = self.data.cur_gold
    AuctionMgr:ReqBuy(1,id,curPrice)
end

-- 竞价
function M:OnBid()
    local id = self.data.id
    local curPrice = self.data.cur_gold
    if self.startPrice >= self.fixPrice then
        AuctionMgr:ReqBuy(1,id,curPrice)
    end
    AuctionMgr:ReqBuy(2,id,curPrice)
end

function M:Dispose()
    self:SetLsner("Remove")
    self.data = nil
    if self.item ~= nil then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    self.isStart = false
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
	end
    TableTool.ClearUserData(self)
end

return M