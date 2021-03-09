--[[
 	authors 	:Liu
 	date    	:2019-6-10 15:00:00
 	descrition 	:特惠充值礼包管理
--]]

DiscountGiftMgr = {Name = "DiscountGiftMgr"}

local My = DiscountGiftMgr

My.State = false
My.isAction = true

function My:Init()
    self:ResetData()
    self.dataTab = {}
    self.dataList = {}
    self.giftList = {}

    self:SetLnsr(ProtoLsnr.Add)
    self.eUpState = Event()
    self.eUpData = Event()
    self.eUpTimer = Event()
    self.eEndTimer = Event()
    self.eGetAward = Event()

    self:CreateTimer()
    LivenessMgr.eUpLiveness:Add(self.RespUpLiveness, self)
    OLastSceneUI.OpenOEvent:Add(self.ShowNewGiftBox, self)
    self.eUpState:Add(self.ResetTabData, self)
    --EventMgr.Add("OnChangeScene", EventHandler(self.ShowNewGiftBox, self))
end

function My:ResetTabData(state)
    if not state then
        TableTool.ClearDic(self.dataTab)
    end
end

--设置监听
function My:SetLnsr(func)
    func(24650, self.RespInfo, self)
    func(24656, self.RespGetAward, self)
end

--响应信息
function My:RespInfo(msg)
    -- iTrace.Error("msg = "..tostring(msg))
    ListTool.Clear(self.dataList)
    ListTool.Clear(self.giftList)
    for i,v in ipairs(msg.pay_list) do
        self:SetData(v.id, v.buy_num, v.end_time, v.product_id, v.old_price, v.now_price, v.limit_num, v.package_name, v.goods_list)
    end
    for i,v in ipairs(msg.daily_gift) do
        self:SetGiftData(v.id, v.package_name, v.is_reward, v.need_active, v.old_price, v.goods_list)
        print(v.package_name)
    end
    
    My.State = #self.dataList > 0 or self:CheckReward(); --为false关闭  true打开
    self.eUpState(My.State)
    self.eUpData()

    local ui = UIMgr.Get(UIDiscountGift.Name)
    if ui and ui.active==1 then
        if My.State == false then
            ui:Close()
        end
    end

    local leftTime = self:GetLeftTime()
    self:UpTimer(leftTime)
    self:UpAction()
    self:ShowNewGiftBox()
end

function My:CheckReward()
    local len = #self.giftList

    for i=1,len do
        if (self.giftList[i].isGet == false) then
            
            return true;

        end 

        return fasle;
    end
    
end

--请求获取奖励
function My:ReqGetAward(id)
	local msg = ProtoPool.GetByID(24655)
	msg.daily_gift_id = id
	ProtoMgr.Send(msg)
end

--响应获取奖励
function My:RespGetAward(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local info = msg.daily_gift
    self:SetGiftData(info.id, info.package_name, info.is_reward, info.need_active, info.old_price, info.goods_list)
    self.eGetAward(info.id)
    self:UpAction()
    
    My.State = #self.dataList > 0 or self:CheckReward(); --为false关闭  true打开
    self.eUpState(My.State)
end

--设置数据
function My:SetData(id, count, endTime, productId, oldPrice, nowPrice, limitNum, packageName, goodsList)
    local data = {}
    data.id = id
    data.count = count
    data.endTime = endTime
    data.productId = productId
    data.oldPrice = oldPrice
    data.nowPrice = nowPrice
    data.limitNum = limitNum
    data.packageName = packageName
    data.goodsList = goodsList
    if not self.isInitInfo then
        self:AddTabGift(data)
    end
    table.insert(self.dataList, data)
end

--设置活跃礼包数据
function My:SetGiftData(id, packageName, isGet, liveness, oldPrice, goodsList)
    for i,v in ipairs(self.giftList) do
        if v.id == id then
            v.packageName = packageName
            v.isGet = isGet
            v.liveness = liveness
            v.oldPrice = oldPrice
            v.goodsList = goodsList
            return
        end
    end
    local data = {}
    data.id = id
    data.packageName = packageName
    data.isGet = isGet
    data.liveness = liveness
    data.oldPrice = oldPrice
    data.goodsList = goodsList
    table.insert(self.giftList, data)
end

function My:AddTabGift(data)
    local id = data.id
    self.dataTab[id] = data
end

--增加新的礼包
function My:ShowNewGiftBox()
    if self.isInitInfo then
        local sceneId = User.SceneId
        sceneId = tostring(sceneId)
        local sceneInfo = SceneTemp[sceneId]
        local mapchildtype = sceneInfo.mapchildtype
        if mapchildtype == 20 then --五行秘境
            return
        end
        local addGiftInfo = self:GetAddGiftInfo()
        if addGiftInfo then
            local id = addGiftInfo.id
            if id == 368 or id == 369 then
                return
            end
            self.addGiftInfo = addGiftInfo
            MsgBox.ShowYesNo(string.format("惊现限时%s,是否前往查看",addGiftInfo.packageName),self.OKBtn,self,"前往", nil ,self, "狠心拒绝", 10)
        end
    end
    self.isInitInfo = true
end

--获取新增的礼包
function My:GetAddGiftInfo()
    local dataList = self.dataList
    local dataTab = self.dataTab
    local len = #dataList
    local addInfo = nil
    for i = 1,len do
        local listInfo = dataList[i]
        local listInfoId = listInfo.id
        if dataTab[listInfoId] == nil then
            addInfo = listInfo
            self:AddTabGift(addInfo)
            break
        end
    end
    return addInfo
end

function My:OKBtn()
    local addGiftInfo = self.addGiftInfo
    if addGiftInfo then
        self:OpenByGiftId(addGiftInfo.id)
        self.addGiftInfo = nil
    end
end

function My:OpenByGiftId(giftId)
    UIDiscountGift.OpenGiftId = giftId
    UIMgr.Open(UIDiscountGift.Name)
end

--判断礼包是否存在
--青竹院特惠礼包id: 364
--渡劫礼包id: 370
function My:IsExitGift(giftId)
    local listTab = self.dataTab
    local isExit = false
    if listTab[giftId] then
        isExit = true
    end
    return isExit
end

--像服务端请求渡劫礼包
function My:SendRobberyGift()
    local msg = ProtoPool.GetByID(23037)
    ProtoMgr.Send(msg)
end

--更新红点
function My:UpAction()
    local actId = ActivityMgr.THLB
    local isShow = self:IsShowAction()
    if My.isAction or isShow then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

--是否显示红点
function My:IsShowAction()
    local isShow = false
    local liveness = LivenessInfo.liveness
    for i,v in ipairs(self.giftList) do
        if (liveness >= v.liveness) and (v.isGet == false) then
            isShow = true
            break
        end
    end

    return isShow
end

--隐藏默认红点
function My:HideAction()
    if My.isAction == false then return end
    My.isAction = false
    SystemMgr:HideActivity(ActivityMgr.THLB)
end

--响应更新活跃度
function My:RespUpLiveness()
    self:UpAction()
end

--移除按钮
function My:RemoveBtn()
    My.State = false
    self.eUpState(My.State) 
end

--获取最短的时间
function My:GetLeftTime()
    local list = {}
    for i,v in ipairs(self.dataList) do
        local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
        local leftTime = v.endTime - sTime
        if leftTime > 0 then
            table.insert(list, leftTime)
        end
    end
    if #list < 1 then return 0 end
    table.sort(list, function(a,b) return a < b end)
    return list[1]
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
    timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    self.eUpTimer(self.timer.remain, time)
end

--结束倒计时
function My:EndCountDown()
    local leftTime = self:GetLeftTime()
    if leftTime > 0 then
        self:UpTimer(leftTime)
    else
        -- self.eEndTimer()
       -- if self.giftList==nil or #self.giftList == 0 then
        if self.giftList == nil --and  self:CheckReward()==false  
        then
        self:RemoveBtn()
     end
    end
end

function My:ResetData()
    self.isInitInfo = false
end

--清理缓存
function My:Clear()
    self:ResetData()
    if self.timer then self.timer:Stop() end
end
    
--释放资源
function My:Dispose()
    self:ResetData()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
end

return My