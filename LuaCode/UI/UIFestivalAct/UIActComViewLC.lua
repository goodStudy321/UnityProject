--[[
 	authors 	:Liu
 	date    	:2019-4-29 10:00:00
 	descrition 	:累充轮盘模块
--]]

UIActComViewLC = Super:New{Name = "UIActComViewLC"}

local My = UIActComViewLC

require("UI/UIFestivalAct/UIActComViewLCIt")

function My:Init(go)
    local root = go.transform
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.go = go
    self.count = 8--轮盘的格子数量
    self.itDic = {}
    self.labList = {}
    self.rateLabList = {}
    self.maskList = {}
    self.angleData = {}
    self.angleList = {}
    self.rateAngleList = {}
    self.isStart = false
    self.speed = 50
    self.speed1 = 40
    self.len = 0
    self.len1 = 0
    self.maxLen = 0
    self.maxLen1 = 0
    self.offset = 0
    self.offset1 = 0
    self.isShow = true

    self.grid = CG(UIGrid, root, "Container/Scroll View/Grid")
    self.lab1 = CG(UILabel, root, "Img/lab1")
    self.countDown = CG(UILabel, root, "Countdown")
    self.lab = CG(UILabel, root, "Img/Container2/goldSpr/lab")
    self.pointer = Find(root, "Img/Container2/pointer3", des)
    self.pointer1 = Find(root, "Img/Container2/pointer2", des)
    self.item = FindC(root, "Container/Scroll View/Grid/item", des)
    self.container = FindC(root, "Img/Container2", des)
    self.btn = FindC(root, "Img/btn", des)

    for i=1, 8 do
        local lab = CG(UILabel, root, "Img/Container2/awards/item"..i.."/lab")
        local rate = CG(UILabel, root, "Img/Container2/labs/lab"..i)
        local mask = FindC(root, "Img/maskBg/mask"..i, des)
        table.insert(self.maskList, mask)
        table.insert(self.rateLabList, rate)
        table.insert(self.labList, lab)
    end

    SetB(root, "Img/btn", des, self.OnBtn, self)

    self:SetLnsr("Add")

    self:InitAngleData()
    self:InitGoldLab()
end

--设置监听
function My:SetLnsr(func)
    local mgr = FestivalActMgr
    mgr.eUpLCLP[func](mgr.eUpLCLP, self.RespUpLCLP, self)
    mgr.eUpAwardCount[func](mgr.eUpAwardCount, self.RespUpAwardCount, self)
end

--响应更新充值项
function My:UpdateItemList()
    self:UpBtnState()
end

--响应更新抽奖次数
function My:RespUpAwardCount()
    self:UpCountLab()
end

--响应更新累充轮盘
function My:RespUpLCLP(index1, index2, award)
    if index1 == nil or index2 == nil then
        iTrace.Error("前后端数据不一致")
        return
    end
    self:SetAngleData(index1, self.angleList, self.speed)
    self:SetAngleData1(index2, self.rateAngleList, self.speed1)
    self.award = award
    self.isStart = true
    FestivalActInfo:LowCount(1)
    self:UpCountLab()
end

--更新数据
function My:UpdateData(data)
    self:InitData()
    self:InitItem()
    self:UpRechargeLab()
    self:UpCountLab()
    self:UpRateLab()
    self:UpActTime()
    self:UpBtnState()
    self.isShow = true
end

--点击抽奖
function My:OnBtn()
    if self.isStart then
        UITip.Log("正在抽奖，请勿重复点击")
        return
    end
    local data = FestivalActInfo.lclpData
    if data == nil then return end
    if data.count < 1 then
        UITip.Log("抽奖次数不足")
    else
        FestivalActMgr:ReqLCLP()
    end
end

--指针旋转
function My:Update()
    self:UpAngle()
end

--更新角度
function My:UpAngle()
    if self.isStart then
        self.len = self.len + 1
        self.len1 = self.len1 + 1
        local len = self.len + self.len1
        local maxLen = self.maxLen + self.maxLen1
        if len > maxLen then
            self.len = 0
            self.len1 = 0
            self.isStart = false
            if self.award then UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self) end
            return
        end
        self:SetAngle(self.len, self.angleList, 1)
        self:SetAngle(self.len1, self.rateAngleList, 2)
    end
end

--设置角度
function My:SetAngle(len, list, idx)
    local maxLen = (idx==1) and self.maxLen or self.maxLen1
    local offset = (idx==1) and self.offset or self.offset1
    local pointer = (idx==1) and self.pointer or self.pointer1
    if len > maxLen then return end
    local angle = list[len] - len * offset
    if angle == nil then return end
    pointer.localEulerAngles = Vector3(0, 0, angle)
    if idx == 1 and self.isShow then
        local index = self:GetMaskIndex(angle)
        self:UpShowMask(index)
    end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.award)
	end
end

--设置角度数据（外层转盘）
function My:SetAngleData(index, list, speed)
    local maxLen, offset = self:AddOffsetAngle(index, speed)
    self.maxLen = maxLen
    self.offset = offset
    self:AddAngleData(list, speed)
end

--设置角度数据（里层转盘）
function My:SetAngleData1(index, list, speed)
    local maxLen, offset = self:AddOffsetAngle(index, speed)
    self.maxLen1 = maxLen
    self.offset1 = offset
    self:AddAngleData(list, speed)
end

--添加偏移角度
function My:AddOffsetAngle(index, spd)
    local maxLen = 0
    local offset = 0
    local timer = 0
    local speed = 0
    local plusAngle = 0
    while speed >= 0 do
        speed = spd
        timer = timer + 0.03
        speed = speed - timer*(speed/4)
        if speed < 0 then break end
        if plusAngle <= -360 then plusAngle = 0 end
        plusAngle = plusAngle - speed
        maxLen = maxLen + 1
    end
    local lastAngle = self:GetLastAngle(index)
    if lastAngle == nil then return end
    local num = math.abs(lastAngle) - math.abs(plusAngle)
    offset = (num >= 0) and num/maxLen or (num + 360) / maxLen
    return maxLen, offset
end

--添加角度数据
function My:AddAngleData(list, spd)
    ListTool.Clear(list)
    local timer = 0
    local speed = 0
    local plusAngle = 0
    local angle = 0
    local len = 0
    while speed >= 0 do
        speed = spd
        timer = timer + 0.03
        speed = speed - timer*(speed/4)
        if speed < 0 then break end
        if plusAngle <= -360 then plusAngle = 0 end
        len = len + 1
        plusAngle = plusAngle - speed
        table.insert(list, plusAngle)
    end
end

--初始化数据
function My:InitAngleData()
    local angle = 360 / self.count
    local startAngle = angle / 2
    local info = {}
    info.a = startAngle
    info.b = info.a - angle

    for i=1, self.count do
        local list = self.angleData
        if #list < 1 then
            table.insert(self.angleData, info)
        else
            local temp = {}
            temp.a = list[i-1].b
            
            temp.b = list[i-1].b - angle
            if temp.b < -360 then temp.b = math.abs(temp.b) - 360 end
            table.insert(self.angleData, temp)
        end
    end
end

--获取遮罩索引
function My:GetMaskIndex(angle)
    local list = self.angleData
    local maxAngle = list[#list].b
    local num = (angle < maxAngle) and angle + 360 or angle
    for i,v in ipairs(list) do
        if num <= v.a and num > v.b then
            return i
        end
    end
    return nil
end

--获取最终角度
function My:GetLastAngle(index)
    for i,v in ipairs(self.angleData) do
        if i == index then
            return (v.a + v.b) / 2
        end
    end
    return nil
end

--更新显示遮罩
function My:UpShowMask(index)
    for i,v in ipairs(self.maskList) do
        if index == i then
            v:SetActive(true)
        else
            v:SetActive(false)
        end
    end
end

--初始化累充项
function My:InitItem()
    local len = TableTool.GetDicCount(self.itDic)
    if len > 0 then return end
    if self.data == nil then return end
    local Add = TransTool.AddChild
    local parent = self.item.transform.parent
    for i,v in ipairs(self.data.itemList) do
        local go = Instantiate(self.item)
        local tran = go.transform
        go:SetActive(true)
        Add(parent, tran)
        local it = ObjPool.Get(UIActComViewLCIt)
        it:Init(tran, v)
        local key = tostring(v.id)
        self.itDic[key] = it
    end
    self:UpBtnState()
    self.item:SetActive(false)
end

--更新按钮状态
function My:UpBtnState()
    if self.data == nil then return end
    for i,v in ipairs(self.data.itemList) do
        local key = tostring(v.id)
        self.itDic[key]:UpBtnState(v.state)
    end
    self.grid:Reposition()
end

--更新倍率文本
function My:UpRateLab()
    local data = FestivalActInfo.lclpData
    if data == nil then return end
    for i,v in ipairs(data.rateList) do
        local it = self.rateLabList[i]
        if it then
            it.text = v.."倍"
        end
    end
end

--更新抽奖次数文本
function My:UpCountLab()
    local data = FestivalActInfo.lclpData
    if data == nil then return end
    self.lab1.text = data.count
end

--更新充值文本
function My:UpRechargeLab()
    local data = FestivalActInfo.lclpData
    if data == nil then return end
    local str = string.format("累计充值%s", data.recharge)
    self.lab.text = str
end

--初始化元宝数量
function My:InitGoldLab()
    local list = self.labList
    local data = FestivalActInfo.lclpData
    if data == nil then return end
    for i,v in ipairs(data.goldList) do
        if list[i] then
            list[i].text = v
        end
    end
end

--初始化数据
function My:InitData()
    self.data = FestivalActMgr:GetActInfo(FestivalActMgr.LCLP)
end

--更新活动时间
function My:UpActTime()
    if self.data == nil then return end
    local eDate = self.data.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    -- seconds = seconds % (24*60*60)
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("[F4DDBDFF]活动结束倒计时:[00FF00FF]%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

--打开
function My:Open(data)
    self:SetActive(true)
    self:UpdateData(data)
end

--关闭
function My:Close()
    self:SetActive(false)
    self.isShow = false
end

--更新显示累充项
function My:UpShowItems(state)
    for k,v in pairs(self.itDic) do
        v.go:SetActive(state)
    end
    self.grid:Reposition()
end

--设置状态
function My:SetActive(state)
    self.go:SetActive(state)
    self.container:SetActive(state)
    self:UpShowItems(state)
    self.countDown.gameObject:SetActive(state)
    self.lab1.gameObject:SetActive(state)
    self.grid.gameObject:SetActive(state)
    self.btn:SetActive(state)
    self:UpShowMask(0)
    self:ResetPos()
end

--重置指针位置
function My:ResetPos()
    self.pointer.transform.localEulerAngles = Vector3.zero
    self.pointer1.transform.localEulerAngles = Vector3.zero
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
    TableTool.ClearDicToPool(self.itDic)
    self:SetLnsr("Remove")
    self:ClearTimer()
end

-- 释放资源
function My:Dispose()
    self:Clear()
end

return My