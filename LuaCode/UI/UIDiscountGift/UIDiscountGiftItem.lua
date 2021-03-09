--[[
 	authors 	:Liu
 	date    	:2019-6-10 15:09:00
 	descrition 	:特惠充值礼包项
--]]

UIDiscountGiftItem = Super:New{Name="UIDiscountGiftItem"}

local My = UIDiscountGiftItem

--初始化奖励物品
function My:Init(root, data)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.cellList = {}
    self.go = root.gameObject
    self.data = data

    self.grid = Find(root, "Scroll View/Grid", des)
    self.priceLab = CG(UILabel, root, "priceLab")
    self.countLab = CG(UILabel, root, "countLab")
    self.timeLab = CG(UILabel, root, "timeLab")
    self.btnLab = CG(UILabel, root, "btn/lab")
    self.desLab = CG(UILabel, root, "lab1")

    SetB(root, "btn", des, self.OnBuy, self)

    self:CreateTimer()
    self:InitCell()
    self:InitLab()
    self:InitTimer()
end

--初始化道具
function My:InitCell()
    for i,v in ipairs(self.data.goodsList) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.9)
        cell:UpData(v.id, v.val)
        table.insert(self.cellList, cell)
    end
end

--初始化文本
function My:InitLab()
    local data = self.data
    local temp = data.limitNum - data.count
    local val = (temp<0) and 0 or temp
    self.priceLab.text = string.format("原价：%s元", data.oldPrice)
    self.countLab.text = string.format("限购次数：%s/%s", val, data.limitNum)
    local price = self:GetPrice()
    if price == nil then return end
    self.btnLab.text = string.format("[682222FF]充值%s元", price)
    self.desLab.text = data.packageName
end

--获取价格
function My:GetPrice()
    local gold = nil
    for i,v in ipairs(RechargeCfg) do
        if v.id == self.data.productId then
            gold = v.gold
        end
    end
    return gold
end

--点击充值
function My:OnBuy()
    RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
end

--编辑器
function My:Func1()
    
end

--Android
function My:Func2()
    RechargeMgr:ReqRecharge(self.data.productId)
end

--IOS
function My:Func3()
    RechargeMgr:ReqRecharge(self.data.productId)
end

--其他
function My:Func4()
    
end

--初始化计时器
function My:InitTimer()
    local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
    local leftTime = self.data.endTime - sTime
	local timer = self.timer
	timer:Stop()
	timer.seconds = leftTime
    timer:Start()
    self:InvCountDown()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    if self.timeLab then
        local remain = self.timer.remain
        self.timeLab.text = string.format("剩余时间：%s", remain)
    end
end

--结束倒计时
function My:EndCountDown()
    self:Hide()
    UIDiscountGift:ItemSort()
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--隐藏
function My:Hide()
    self.go:SetActive(false)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    self:ClearTimer()
    TableTool.ClearListToPool(self.cellList)
end

return My