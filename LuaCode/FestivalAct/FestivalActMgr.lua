FestivalActMgr = {Name = "FestivalActMgr"}

local M = FestivalActMgr

local Info = require("FestivalAct/FestivalActInfo")

M.LJXF = 1007  --累计消费
M.LJCZ = 1009  --累计充值
M.ExpDB = 1010   --双倍经验
M.CopyDb = 1011   --副本双倍
M.JRHD = 1013  --容器， 节日活动
M.CZYL = 1000--充值有礼
M.NNWN = 1001--你侬我侬
M.QMSD = 1002--亲密商店
M.XYC = 1003--许愿池
M.LDL = 1004 --炼丹炉
M.BossDrop = 1021   --Boss掉落
M.DLYL = 1014  --登录有礼
M.LCLP = 1005   --累充轮盘
M.HYLP = 1006   --活跃轮盘
M.SHJL = 1012   --守护精灵
M.LCDL = 1022--累充大礼
M.CZSB = 1024--充值双倍
M.YJQX = 1025--一见倾心

M.SMBZ = 1015 --神秘宝藏
M.BZFB = 1016 -- 宝藏副本
M.BZSC = 1017  -- 宝藏商城

M.BestAlchemy = 1018  --仙品炼丹
M.CommonAlchemy = 1019  --凡品炼丹
M.AlchemyStore = 1020   --炼丹商店

M.XFPH = 1023 --消费排行榜
M.DCDL = 1026 --单充大礼

M.InitAction = true--许愿池初始红点
M.ActiveInfo = {}
M.RedPointState = {}
--消费排行红点
M.XFPHRedState = true;

--初始化默认红点
M.isInitAction = true

M.eUpdateActState = Event()
M.eUpdateActTime = Event()
M.eUpdateActDisplay = Event()
M.eUpdateActItemList = Event()
M.eUpdateItemRemainCount = Event()
M.eUpdateActImg = Event()
M.eUpdateActSort = Event()
M.eUpdateRedPoint = Event()
M.eWishAward = Event()
M.eUpdateModel = Event()
M.eUpdateBlastInfo = Event()
M.eUpState = Event()
M.eUdBlaetBtn = Event()
M.eUpBlastName = Event()
M.eUpLCLP = Event()
M.eUpHYLP = Event()
M.eUpAwardCount = Event()
M.eFestivalInfo = Event()
--玩家自己的消费元宝更新事件
M.eUpCostGold = Event();
M.BlastState = false

M.BestAlchemyInitRedPoint = false
M.AlchemyStoreInitRedPoint = true

function M:Init()
    Info:Init()
    self:SetLnsr(ProtoLsnr.Add)
    PropMgr.eAdd:Add(self.RespAdd, self)
    PropMgr.eUpdate:Add(self.RespUpdate, self)
end

function M:SetLnsr(func)
    func(23036, self.RespBgActClose, self)
    func(23038, self.RespBgActUpdate, self)
    func(23040, self.RespBgActTimeUpdate, self)
    func(23042, self.RespBgActDisplayUpdate, self)
    func(23044, self.RespBgActEntryUpdate, self)
    func(23046, self.RespBgActReward, self)
    func(23048, self.RespBgActRewardNum, self)
    func(23050, self.RespBgActRewardCondition, self)
    func(23052, self.RespBgActDisplayImg, self)
    func(23056, self.RespBgActSort, self)
    func(23066, self.RespRecharge, self)
    func(23068, self.RespStore, self)
    func(23064, self.RespBgDrop, self)
    func(23070, self.RespMission, self)
    func(23072, self.RespUpMission, self)
    func(26012, self.RespWish, self)
    func(26014, self.RespWishAward, self)
    func(26084,self.RespBlastInfo,self)
    func(26086,self.RespBlast,self)
    func(26088,self.RespLCLPInfo,self)
    func(26090,self.RespLCLP,self)
    func(26094,self.RespHYLP,self)
    func(26096,self.RespHYLPInfo,self)
    func(26098,self.RespUpRechargeInfo,self)
    func(26500,self.RespXFPHInfo,self)
    func(26502,self.RespXFPHMyCost,self)
    func(26504,self.RespYJQXInfo,self)
end

--响应添加物品
function M:RespUpdate()
    if Info.itemId == nil then return end
	self:UpStoreAction()
end

--响应道具获得
function M:RespAdd(tb)
	local id = tb.type_id
    if id == Info.wishData.itemId then
        self:UpWishAction()
    end
end

--响应累充轮盘信息
function M:RespLCLPInfo(msg)
    self:SetData(msg)
    local data = Info.lclpData
    for i,v in ipairs(msg.gold) do
        table.insert(data.goldList, v)
    end
    for i,v in ipairs(msg.rate) do
        table.insert(data.rateList, v)
    end
    data.recharge = msg.recharge
    data.count = msg.times
end

--请求累充轮盘
function M:ReqLCLP()
    local msg = ProtoPool.GetByID(26089)
    ProtoMgr.Send(msg)
end

--响应累充轮盘
function M:RespLCLP(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local index1 = Info:GetLCLPIndex(1, msg.gold)
    local index2 = Info:GetLCLPIndex(2, msg.rate)
    local list = {}
    local award = {}
    award.b = 1
    award.k = 3
    award.v = msg.gold * msg.rate
    table.insert(list, award)
    self.eUpLCLP(index1, index2, list)
end

--增加轮盘次数
function M:PlusCount(type, num)
    if type == self.LCLP then
        Info:PlusCount(1, num)
    elseif type == self.HYLP then
        Info:PlusCount(2, num)
    end
    self.eUpAwardCount()
end

--响应更新充值信息
function M:RespUpRechargeInfo(msg)
    local data = Info.lclpData
    data.recharge = msg.val
end

--响应活跃轮盘信息
function M:RespHYLPInfo(msg)
    self:SetData(msg)
    local data = Info.hylpData
    for i,v in ipairs(msg.reward) do
        Info:SetAwardList(data.award, v.type_id, v.num, v.is_bind, v.special_effect)
    end
    for i,v in ipairs(msg.got_reward) do
        local index = Info:GetHYLPIndex(v.type_id, v.num)
        if index then Info:SetLPList(index) end
    end
    data.count = msg.times
end

--请求活跃轮盘
function M:ReqHYLP()
    local msg = ProtoPool.GetByID(26093)
    ProtoMgr.Send(msg)
end

--响应活跃轮盘
function M:RespHYLP(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local data = msg.reward
    local index = Info:GetHYLPIndex(data.type_id, data.num)
    local list = {}
    local award = {}
    award.b = data.is_bind
    award.k = data.type_id
    award.v = data.num
    table.insert(list, award)
    self.eUpHYLP(index, list)
end

--更新许愿池红点
function M:UpWishAction()
    local state = false
    local actId = ActivityMgr.XYC
    if self:IsOpen(self.XYC) then
        local itemId = Info.wishData.itemId
        local token = ItemTool.GetNum(itemId)
        local isGet = self:IsGetWishAward()
        if token > 0 or isGet then
            state = true
        end
    end
    if state or self.InitAction then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

--判断是否能领取许愿池兑换奖励
function M:IsGetWishAward()
    local info = self.ActiveInfo[tostring(self.XYC)]
    if not info or not info.itemList then return end
    for i,v in ipairs(info.itemList) do
        if v.state == 2 then
            return true
        end
    end
    return false
end

-- 响应炼丹炉信息
function M:RespBlastInfo(msg)
    self:SetData(msg)
    local data = Info.blastData
    data.price = msg.price
    data.money = msg.money
    data.lucky = msg.lucky
    data.tollucky = msg.full_lucky
    data.des = msg.tips
    data.picDes = msg.picture_tips
    data.award2 = msg.precious_reward
    for i,v in ipairs(msg.common_reward) do
        Info:SetAwardList(data.award1, v.type_id, v.num, v.is_bind, v.special_effect)
    end
    M.BlastState = true
    self.eUpState(M.BlastState)
    local id = msg.info.icon
    local img = ActIconCfg[id].icon
    self.eUpBlastName(msg.info.icon_name,img)
end

-- 请求炼丹
function M:ReqsBlast()
    local msg = ProtoPool.GetByID(26085)
    ProtoMgr.Send(msg)
end

-- 响应炼丹返回信息
function M:RespBlast(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local data = Info.blastData
    local bigData = msg.precious_reward
    data.lucky = msg.lucky
    if bigData.type_id ~= 0 then
        data.award2 = bigData
        self.eUpdateModel()
        self.eUdBlaetBtn(true)
    end
    self.eUpdateBlastInfo()
end

--响应许愿池
function M:RespWish(msg)
    self:SetData(msg)
    local data = Info.wishData
    data.itemId = msg.consume_item
    data.unitPrice = msg.unit_price
    data.fullPrice = msg.full_price
    data.integral = msg.integral
    data.luckVal = msg.bless
    data.preciousExist = msg.precious_exist
    data.notice = msg.notice
    for i,v in ipairs(msg.precious_reward) do
        Info:SetAwardList(data.awardList1, v.type_id, v.num, v.is_bind, v.special_effect)
    end
    for i,v in ipairs(msg.common_reward) do
        Info:SetAwardList(data.awardList2, v.type_id, v.num, v.is_bind, v.special_effect)
    end
    self:UpWishAction()
end

--请求许愿
function M:ReqWish(count)
    local msg = ProtoPool.GetByID(26013)
    msg.times = count
    ProtoMgr.Send(msg)
end

--响应许愿奖励
function M:RespWishAward(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local count = msg.times
    local data = Info.wishData
    local awardList = msg.reward
    data.integral = msg.integral
    data.luckVal = msg.bless
    data.preciousExist = msg.precious_exist
    -- msg.reward 获得的奖励
    data.updateList = {}
    for i,v in ipairs(msg.update_list) do
        Info:SetUpdataList(data.updateList, v.id, v.val, v.type)
    end
    self.eWishAward(count, awardList)
    self:UpWishAction()
end

--响应充值有礼
function M:RespRecharge(msg)
    Info:InitRechargeData()
    self:SetData(msg)
    local data = Info.rechargeData
    data.modelId = msg.model
    data.fight = msg.fight
    data.sigh_title = msg.sigh_title
    data.modelImg = msg.mod_img
end

--响应亲密商店
function M:RespStore(msg)
    self:SetData(msg)
    Info.itemId = msg.item
    self:UpStoreAction()
end

--更新亲密商店红点
function M:UpStoreAction()
    local info = self.ActiveInfo[tostring(self.QMSD)]
    if not info or not info.itemList then return end
    local id = Info.itemId
    local count = ItemTool.GetNum(id)
    local itemList = info.itemList
    for i,v in ipairs(itemList) do
        if v.schedule > 0 and count >= v.remainCount then
            v.state = 2
        else
            v.state = 3
        end
    end
    self:UpdateRedPoint(self.QMSD)
end

--响应你侬我侬
function M:RespMission(msg)
    self:SetData(msg)
    for i,v in ipairs(msg.list) do
        self.listInfo = {}
        local data = self.listInfo
        data.id = v.id
        data.des = v.word
        data.count = v.times
        data.allCount = v.all_times
        data.jumpType = v.jump_type
        table.insert(Info.condList, data)
    end

    Info.money = msg.money
    Info.keyword = msg.keyword
end

--响应更新你侬我侬
function M:RespUpMission(msg)
    for i,v in ipairs(msg.list) do
        for i1,v1 in ipairs(Info.condList) do
            if v1.id == v.id then
                v1.count = v.val
                break
            end
        end
    end
    Info.money = msg.money
    --更新红点
    local info = self:CreateActInfo(self.NNWN)
    local itemList = info.itemList
    for i,v in ipairs(itemList) do
        if Info.money >= v.target then
            if v.state == 1 then
                v.state = 2
            end
        end
    end
    self:UpdateRedPoint(self.NNWN)
end

--响应一见倾心
function M:RespYJQXInfo(msg)
    -- iTrace.Error("msg = "..tostring(msg))
    self:SetData(msg)
    local data = Info.yjqxData
    data.price = msg.price
    data.itemId = msg.item
    for i,v in ipairs(msg.list) do
        Info:SetAwardList(data.itemList, v.type_id, v.num, v.is_bind, v.special_effect)
    end
end

--设置数据
function M:SetData(msg)
    local info = msg.info
    local type = info.id
    self:UpdateActiveInfo(info)
    self:SortItemList(type)
    self:UpdateRedPoint(type)
    self.eUpdateActState(type, true)
end

function M:RespBgActSort(msg)
    local list = msg.list
    for i=1,#list do
        self:UpdateActSort(list[i].id, list[i].val)
    end
    self.eUpdateActSort()
end

function M:RespBgActClose(msg)
    local type = msg.act_id
    self:ClearActInfo(type)
    self:UpdateRedPointState(type, false)
    self.eUpdateActState(type, false)
end

function M:RespBgDrop(msg)
    local info = msg.info
    local type = info.id
    self:UpdateActiveInfo(info)
    self:UpdateDropItem(type, msg.drop)
    self:UpdateRedPoint(type)
    self.eUpdateActState(type, true)
end


-- M.SMBZ = 1015 --神秘宝藏
-- M.BZFB = 1016 -- 宝藏副本
-- M.BZSC = 1017  -- 宝藏商城

-- M.XYC = 1003--许愿池
-- M.LDL = 1004 --炼丹炉
function M:RespBgActUpdate(msg)
    self:MsgLog("RespBgActUpdate", tostring(msg))
    local list = msg.act_list
    local tempTab = {}
    for i=1,#list do
        local type = list[i].id
        if type ~= self.SMBZ or type ~= self.BZFB or tab ~= self.BZSC
        or type ~= self.XYC or type ~= self.LDL then
            table.insert(tempTab,type)
        end
        self:ClearActInfo(type)
        self:UpdateActiveInfo(list[i])
        self:SortItemList(type)
        self:UpdateRedPoint(type)
        self.eUpdateActState(type, true)
        self.eUpdateActItemList(type)
    end
    local len = #tempTab
    self.eFestivalInfo(len > 0)
end

--消费排行信息初始化
function M:RespXFPHInfo(msg)
    local bgAct = msg.info
    local type = bgAct.id
    local costGold = msg.my_use
    self:UpdateActiveInfo(bgAct)
    self:SortItemList(type)
    self:SetCostGold(type,costGold)
    self:UpdateRedPoint(type)
    self.eUpdateActState(type, true)
end

--设置消费元宝
function M:SetCostGold(type,costGold)
    local info = self:CreateActInfo(type);
    info.costGold = costGold;
    M.eUpCostGold();
end

--消费排行我的消费元宝
function M:RespXFPHMyCost(msg)
    local type = M.XFPH;
    local costGold = msg.my_use;
    self:SetCostGold(type,costGold);
end

function M:RespBgActTimeUpdate(msg)
    local type = msg.id
    self:UpdateActTime(type, msg.start_time, msg.end_time, msg.start_date, msg.end_date)
    self.eUpdateActTime(type)
end

function M:RespBgActDisplayUpdate(msg)
    local type = msg.id
    self:UpdateActDisplay(type, msg.icon, msg.icon_name, msg.title, msg.explain, msg.template)
    self.eUpdateActDisplay(type)
end

function M:RespBgActEntryUpdate(msg)
    self:MsgLog("RespBgActEntryUpdate", tostring(msg))
    local type = msg.id
    self:DeleteItemList(type, msg.del_list)
    self:AddItemList(type, msg.add_list)
    self:UpdateItemList(type, msg.update_list)
    self:SortItemList(type)
    self:UpdateRedPoint(type)
    self.eUpdateActItemList(type)
end

function M:RespBgActReward(msg)
    self:MsgLog("RespBgActReward", tostring(msg))
    if self:CheckErr(msg.err_code) then
        local type = msg.id
        if type == M.BZSC then
            TreaFeverMgr:UpStoreData(msg.entry,msg.num)
            return
        end
        self:PlusCount(type, msg.num)
        self:UpdateItemState(type, msg.entry)
        -- self:UpdateItemRemainCount(type, msg.entry, msg.num)
        self:SortItemList(type)
        self:UpdateRedPoint(type)
        self:UpStoreAction()
        self.eUpdateActItemList(type)
    end
end

--type， 活动类型
function M:ReqBgActReward(type, id)
    local msg = ProtoPool.GetByID(23045)
    msg.id = type
    msg.entry = id
    ProtoMgr.Send(msg)
end

--请求数量
function M:ReqBgActRewardNum(type)
    local msg = ProtoPool.GetByID(23047)
    msg.id = type
    ProtoMgr.Send(msg)
end

function M:RespBgActRewardNum(msg)
    self:MsgLog("RespBgActRewardNum", tostring(msg))
    local type = msg.id
    local list = msg.list
    for i=1,#list do
        self:UpdateItemRemainCount(type, list[i].id, list[i].val)
    end
    self.eUpdateItemRemainCount(type)
end

function M:RespBgActRewardCondition(msg)
    self:MsgLog("RespBgActRewardCondition", tostring(msg))
    local type = msg.id
    local list = msg.list
    for i=1,#list do
        self:UpdateItemCondition(type, list[i].id, list[i].val, list[i].type)
    end
    self:SortItemList(type)
    self:UpdateRedPoint(type)
    self.eUpdateActItemList(type)
end

function M:RespBgActDisplayImg(msg)
    local type = msg.id
    self:UpdateActImg(type, msg.bg_img)
    self.eUpdateActImg(type)
end


--==============================--

--根据活动类型更新数据
function M:UpdateActiveInfo(data)
    local type = data.id
    self:UpdateActSort(type, data.sort)
    self:UpdateActTime(type, data.start_time, data.end_time, data.start_date, data.end_date)
    self:UpdateActDisplay(type, data.icon, data.icon_name, data.title, data.explain, data.template)
    self:UpdateActImg(type, data.bg_img)
    self:AddItemList(type, data.entry_list)
end

function M:UpdateActSort(type, sort)
    local info = self:CreateActInfo(type)
    info.type = type
    info.sort = sort
end

function M:UpdateActTime(type, sTime, eTime, sDate, eDate)
    local info = self:CreateActInfo(type)
    info.sTime = sTime
    info.eTime = eTime
    info.sDate = sDate
    info.eDate = eDate
end

function M:UpdateActDisplay(type, icon, iconName, title, explain, template)
    local info = self:CreateActInfo(type)
    info.icon = icon
    info.iconName = iconName
    info.title = title
    info.explain = explain
    info.template = template
end

function M:UpdateActImg(type, texPath)
    local info = self:CreateActInfo(type)
    info.texPath = texPath
end

--删除ItemList条目
function M:DeleteItemList(type, list)
    local len = #list
    if len == 0 then return end
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    for i=1,len do
        TableTool.Remove(itemList, {id = list[i]}, "id")
    end
end

--添加ItemList条目
function M:AddItemList(type, list)
    local len = #list
    if len == 0 then return end
    local info = self:CreateActInfo(type)
    if not info.itemList then
        info.itemList = {}
    end
    local itemList = info.itemList
    for i=1,len do
        local item = {}
        self:UpdateItem(item, list[i], type)
        table.insert(itemList, item)
    end
end

--更新itemlist条目数据
function M:UpdateItemList(type, list)
    local len = #list
    if len == 0 then return end
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    if itemList == nil or #itemList < 1 then return end
    for i=1,len do
        local index = TableTool.Contains(itemList, {id = list[i].sort}, "id")
        local item = itemList[index]
        if item then
            TableTool.ClearDic(item)
            self:UpdateItem(item, list[i], type)
        end
    end
end

function M:UpdateItem(item, data, type)
    item.type = type
    item.id = data.sort
    item.des = data.title
    item.state = data.status
    item.schedule = data.schedule
    item.target = data.target
    item.remainCount = data.num
    if item.rewardList then
        TableTool.ClearDic(item.rewardList)
    else
        item.rewardList = {}
    end
    local rewardList = item.rewardList
    local items = data.items
    for i=1,#items do
        local reward = {}
        self:UpdateReward(reward, items[i])
        table.insert(rewardList, reward)
    end
end


function M:UpdateReward(reward,data)
    reward.id = data.type_id
    reward.num = data.num
    reward.bind = data.is_bind
    reward.effNum = data.special_effect
end

--更新item领取状态
function M:UpdateItemState(type, id)
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    if itemList then
        for i=1,#itemList do
            local it = itemList[i]
            if it.id == id then
                if type == self.QMSD then
                    it.schedule = it.schedule - 1
                elseif type ~= self.AlchemyStore and type  ~= self.DCDL then
                    it.state = 3
                end
                break
            end
        end
    end
end

--更新item剩余数量
function M:UpdateItemRemainCount(type, id, num)
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    if itemList then
        for i=1,#itemList do
            if itemList[i].id == id then
                itemList[i].remainCount = num
                break
            end
        end
    end
end

--更新item条件
function M:UpdateItemCondition(type, id, schedule, state)
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    if itemList then
        for i=1,#itemList do
            if itemList[i].id == id then
                itemList[i].schedule = schedule
                itemList[i].state = state
                break
            end
        end
    end
end

--设置默认红点
function M:SetNorAction(type)
    if self.isInitAction == false then return end
    -- if type == self.XYC or type == self.LDL
    -- or type == self.SMBZ or type == self.BZFB
    -- or type == self.BZSC then return end

    --if self:IsFesActType(type) == false then return; end
    local key = tostring(type)
    if self.norActionDic == nil then self.norActionDic = {} end
    self.norActionDic[key] = true
end

--更新默认红点
function M:UpNorAction(type)
    local key = tostring(type)
    self.norActionDic[key] = false
end

--隐藏默认红点
function M:HideNorAction()
    self.isInitAction = false
end

--更新红点
function M:UpdateRedPoint(type)
    self:SetNorAction(type)
    local info = self:CreateActInfo(type)
    local itemList = info.itemList
    if itemList then
        for i=1,#itemList do
            if itemList[i].state == 2 then
                self:UpdateRedPointState(type, true)
                return
            else
                if type == self.LCLP then
                    local isShow = Info.lclpData.count > 0
                    self:UpdateRedPointState(type, isShow)
                    return
                elseif type == self.HYLP then
                    local isShow = Info.hylpData.count > 0
                    self:UpdateRedPointState(type, isShow)
                    return
                elseif type == self.XFPH then
                    self:UpdateXFPHRedState();
                    return
                end
            end
        end
    end
    self:UpdateRedPointState(type, false)
    self:UpdateAlchemyStoreRedPoint(type)
end

function M:UpdateRedPointState(type, state)
    self.RedPointState[tostring(type)] = state
    self:UpdateAllRedPoint()
    self.eUpdateRedPoint(state, type)
end

function M:UpdateAllRedPoint()

    local state = false
    for k,v in pairs(self.RedPointState) do
        if tonumber(k) ~= self.BZSC then
            if v then
                state = true
                break
            end
        end
    end
    for k,v in pairs(self.norActionDic) do
        local vul = 0;
        if v then
            
            if self:IsFesActType(tonumber(k)) == true then 
                state = true
                break 
            end
        end
    end
    if state then
        SystemMgr:ShowActivity(ActivityMgr.JRHD)
    else
        SystemMgr:HideActivity(ActivityMgr.JRHD)
    end
end

function M:UpdateAlchemyStoreRedPoint(type)
    if type ~= self.AlchemyStore then return end
    SystemMgr:ChangeActivity(self.AlchemyStoreInitRedPoint, ActivityMgr.Alchemy, 2)
end


--更新Boss掉落道具
function M:UpdateDropItem(type, dropList)
    local info = self:CreateActInfo(type)
    info.dropList = dropList
end

--更新消费排行红点
function M:UpdateXFPHRedState()
    local type = self.XFPH;
    local red = M.XFPHRedState
    self:UpdateRedPointState(type, red)
end

--set
function M:SetAlchemyStoreRedPoint(bool)
    self.AlchemyStoreInitRedPoint = bool
    SystemMgr:ChangeActivity(self.AlchemyStoreInitRedPoint, ActivityMgr.Alchemy, 2)
end


--==============================--

function M:GetRedPointState(type)
    local key = tostring(type) 
    if not self.RedPointState[key] then
        self.RedPointState[key] = false
    end
    return self.RedPointState[key]
end



--创建对应类型的字典
function M:CreateActInfo(type)
    local key = tostring(type) 
    if not self.ActiveInfo[key] then
        self.ActiveInfo[key] = {}
    end
    return self.ActiveInfo[key]
end

--根据活动类型获取活动数据
function M:GetActInfo(type)
    return self.ActiveInfo[tostring(type)]
end

--获取活动结束时间戳
function M:GetActEndTime(type)
    local info = self:GetActInfo(type)
    return info and info.eDate or 0
end


function M:SortItemList(type)
    local info = self:CreateActInfo(type)
    if info.itemList then
        table.sort(info.itemList, function(a,b) return self:Sort(a,b) end)
    end
end

function M:Sort(a,b)
    if a.state == b.state then
        return a.id < b.id
    elseif a.state == 2 then
        return true
    elseif b.state == 2 then
        return false
    else
        return a.state < b.state
    end
end


function M:GetToggleInfo()
    local info = self.ActiveInfo
    local list = {}
    for k,v in pairs(info) do
        local type = v.type
        if type ~= self.XYC 
        and type ~= self.AlchemyStore
        and type ~= self.BestAlchemy
        and type ~= self.CommonAlchemy
        then
            local temp = {}
            temp.type = v.type
            temp.sort = v.sort
            temp.name = v.title
            table.insert(list, temp)
        end
    end
    table.sort(list, function(a,b) return a.sort < b.sort end)

    return list
end

--该类型活动是否开启
function M:IsOpen(type)
    if type ~= self.JRHD then
        local info = self.ActiveInfo[tostring(type)]
        return info ~= nil
    else
        local len = 0
        for k,v in pairs(self.ActiveInfo) do
            local id = tonumber(k)
            if id ~= self.XYC and id ~= self.LDL and id ~= self.SMBZ
            and id ~= self.BZFB and id ~= self.BZSC and id ~= self.SHJL
            and id ~= self.BestAlchemy and id ~= self.AlchemyStore
            then
                len = len + 1
            end
        end
        -- local count = TableTool.GetDicCount(self.ActiveInfo)
        return len > 0
    end
end

--双倍经验是否开启
function M:IsOpenExpDB()
    local isOpen = false
    local info = self:GetActInfo(self.ExpDB)
    if not info then return false end
    local startTime = info.sTime
    local endTime = info.eTime
    local severTime = TimeTool.GetServerTimeNow()*0.001
    if severTime >= startTime and severTime < endTime then
        isOpen = true
    end
    return isOpen
end


--双培副本是否开启
function M:IsOpenCopyDB()
    local isOpen = false
    local info = self:GetActInfo(self.CopyDb)
    if not info then return false end
    local startTime = info.sTime
    local endTime = info.eTime
    local severTime = TimeTool.GetServerTimeNow()*0.001
    if severTime >= startTime and severTime < endTime then
        isOpen = true
    end
    return isOpen
end


-- M.SMBZ = 1015 --神秘宝藏
-- M.BZFB = 1016 -- 宝藏副本
-- M.BZSC = 1017  -- 宝藏商城
--神秘宝藏是否开启
function M:IsOpenSMBZ()
    local isOpen = true
    local info = self:GetActInfo(self.SMBZ)
    if not info then return false end
    return isOpen
end


function M:ClearActInfo(type)
    self.ActiveInfo[tostring(type)] = nil
end

function M:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return false
    end
    return true
end

function M:MsgLog(name, msg)
    -- iTrace.Error(name, tostring(msg))
end

function M:Clear()
    M.BlastState = false
    M.BestAlchemyInitRedPoint = false
    M.AlchemyStoreInitRedPoint = true
    self.eUpState(M.BlastState)
    TableTool.ClearDic(self.ActiveInfo)
    TableTool.ClearDic(self.RedPointState)
    Info:Init()
end

function M:IsFesActType(typeId)
    if typeId == M.XYC
        or typeId == M.SMBZ
        or typeId == M.BZFB
        or typeId == M.BZSC
        or typeId == M.BestAlchemy
        or typeId == M.AlchemyStore
    then
        return false;
    end

    return true;
end

return M
