--[[
 	authors 	:Liu
 	date    	:2019-3-22 16:10:00
 	descrition 	:限时抢购
--]]

UITimeLimitBuy = UIBase:New{Name = "UITimeLimitBuy"}

local My = UITimeLimitBuy

require("UI/UITimeLimitActiv/UITimeLimitBuyIt")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    local str = "Scroll View/Grid"

    for i=1, 2 do
        local tog = Find(root, "togs/tog"..i, des)
        SetS(tog, self.OnTog, self, self.Name)
    end

    self.itList = {}
    self.dataList1 = {}
    self.dataList2 = {}
    self.grid = CG(UIGrid, root, str)
    self.timeLab = CG(UILabel, root, "time")
    self.item = FindC(root, str.."/item", des)

    SetB(root, "close", des, self.Close, self)

    TimeLimitActivMgr:UpNorAction(3)

    self:InitData()
    self:InitItems()
    self:CreateTimer()
    self:InitTimeLab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = TimeLimitActivMgr
    mgr.eTimeLimitBuy[func](mgr.eTimeLimitBuy, self.RespTimeLimitBuy, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10368 then
		self.dic=dic
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应限时购买
function My:RespTimeLimitBuy()
    self:UpBtns()
end

--点击Tog
function My:OnTog(go)
    local num = string.sub(go.name, 4)
    if self.curIndex == num then return end
    if go.name == "tog1" then
        self:SetData(2)
        self.curIndex = 1
    elseif go.name == "tog2" then
        self:SetData(3)
        self.curIndex = 2
    end
    self:UpBtns()
end

--初始化购买项
function My:InitItems()
    local Add = TransTool.AddChild
    local num = self:GetMaxCount()
    local parent = self.item.transform.parent
    for i=1, num do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UITimeLimitBuyIt)
        it:Init(tran)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self:SetData(2)
    self:UpBtns()
end

--设置数据
function My:SetData(type)
    self:HideItems()
    local itList = self.itList
    local list = (type==2) and self.dataList1 or self.dataList2
    for i,v in ipairs(list) do
        itList[i]:UpShow(true)
        itList[i]:UpData(v)
    end
end

--更新按钮
function My:UpBtns()
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.buyType)
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        local count = (dic) and dic[key] or nil
        v:UpBtnState(count)
    end
    self.grid:Reposition()
end

--初始化数据
function My:InitData()
    local cfg = TimeLimitShoppeCfg
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.buyType)
    if dic == nil then return end
    for k,v in pairs(dic) do
        -- local data = cfg[tonumber(k)]
        local data = cfg[k]
        if data == nil then return end
        local type = data.goldType
        if type == 2 then
            table.insert(self.dataList1, data)
        elseif type == 3 then
            table.insert(self.dataList2, data)
        end
    end
end

--获取预制体的最大数量
function My:GetMaxCount()
    local len1 = #self.dataList1
    local len2 = #self.dataList2
    local max = (len1>len2) and len1 or len2
    return max
end

--隐藏购买项
function My:HideItems()
    for i,v in ipairs(self.itList) do
        v:UpShow(false)
    end
end

--初始化时间文本
function My:InitTimeLab()
    local type = 1027
    local isOpen = LivenessInfo:IsOpen(type)
    if isOpen then
        local data = LivenessInfo.xsActivInfo[tostring(type)]
        local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
        local leftTime = data.eTime - sTime
        local dayTime = 24*60*60
        local temp = leftTime - dayTime
        local num = (temp>=0) and temp or leftTime
        self:UpTimer(num)
    end
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
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
    local remain = self.timer.remain
	self.timeLab.text = string.format("[E5B45FFF]活动倒计时:[FFE9BDFF]%s", remain)
end

--结束倒计时
function My:EndCountDown()
	
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    ListTool.ClearToPool(self.itList)
    self.dataList1 = nil
    self.dataList2 = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:ClearTimer()
    self:SetLnsr("Remove")
end

return My