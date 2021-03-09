--[[
 	authors 	:Liu
 	date    	:2019-3-18 17:00:00
 	descrition 	:限时活动管理
--]]

TimeLimitActivMgr = {Name = "TimeLimitActivMgr"}

local My = TimeLimitActivMgr
My.type=0

local Info = require("TimeLimitActiv/TimeLimitActivInfo")

My.State = {}
My.norAction13 = true--8~15天活动默认红点(展翅高飞)
My.norAction12 = true--8~15天活动默认红点(法力无边)
My.norAction11 = true--8~15天活动默认红点(收藏达人)
My.norAction2 = true--七日投资默认红点
My.norAction3 = true--限时抢购默认红点
My.norAction4 = true--许愿池默认红点

function My:Init()
    Info:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eRankInfo = Event()
    self.eUpAward = Event()
    self.eUpState = Event()
    self.eUpName = Event()
    self.eUpSevenAward = Event()
    self.eUpSevenInvest = Event()
    self.eTimeLimitBuy = Event()
    self.eEndActiv = Event()
    --许愿池
    self.eUpWish = Event()
    self.eUpWishAward = Event()
    ActivStateMgr.eUpActivState:Add(self.UpActState, self)
end

--获取开启类型
function My:TypeGetId(tp)
	local id = 0
	if tp==ActivityMgr.ZCGF then
		id=10014
	elseif tp==ActivityMgr.KFFB then
		id=10013
	elseif tp==ActivityMgr.KFTJ then
		id=10012
	end
	return id
end

--获取系统
function My:TypeGetTp(type)
	local id = 0
	if type==10014 then
		id=ActivityMgr.ZCGF
	elseif type==10013 then
		id=ActivityMgr.KFFB
	elseif type==10012 then
		id=ActivityMgr.KFTJ
	end
	return id
end

--更新活动状态
function My:UpActState()
    for i,v in ipairs(Info.idList) do
        local id = Info:GetActivType(v)
        if LivenessInfo:IsOpen(id) then
            return
        end
        local State = false
        local type=v
        My.State[tostring(type)]=State
        self.eUpState(type,State)
    end
end

--设置监听
function My:SetLnsr(func)
    func(26040, self.RespInfo, self)
    func(26042, self.RespChange, self)
    func(26044, self.RespRankAward, self)
    func(26046, self.RespRankInfo, self)
    func(26060, self.RespEndActiv, self)
    --七日投资
    func(26054, self.RespSevenInfo, self)
    func(26056, self.RespSevenInvest, self)
    func(26058, self.RespSevenAward, self)
    --限时抢购
    func(26050, self.RespBuyInfo, self)
    func(26052, self.RespBuy, self)
    --许愿池
    func(26062, self.RespWishInfo, self)
    func(26064, self.RespWish, self)
    func(26066, self.RespWishAward, self)
end

--响应活动信息
function My:RespInfo(msg)
    local list = {}
    local type = msg.type
    local sType=tostring(type)
    local dic1 = Info:ShiftData(msg.rank_reward)
    local dic2 = Info:ShiftData(msg.power_reward)
    local dic3 = Info:ShiftData(msg.mana_reward)
    local dic4 = Info:ShiftData(msg.panic_buy)
    local dic5 = Info:ShiftData(msg.recharge_reward)
    local dic6 = Info:ShiftData(msg.mana_list)
    table.insert(list, dic1)--排名奖励
    table.insert(list, dic2)--战力奖励
    table.insert(list, dic3)--灵力奖励
    table.insert(list, dic4)--抢购次数
    table.insert(list, dic5)--累计充值
    Info:SetData(type, list)
    local key = tostring(Info.manaType)
    Info.dataDic[key] = dic6--灵力条件列表
    self:SetRankInfo(sType,msg.rank_list)
    Info.mana = msg.mana
    Info.recharge = msg.recharge
    Info.isLastDayDic[sType] = msg.is_last_day
    local State = true
    self.eEndActiv(type)
    My.State[tostring(type)]=State
    self.eUpState(type,State)
    --self.eUpName(self:GetActivName(type))
    self:UpAction()
end

--获取活动名字
function My:GetActivName(type)
    local list = Info.idList
    local str1 = "冲榜活动"
    local str2 = "fabao"
    if type == list[1] then
        str1 = "法力无边"
        str2 = "fabao"
    elseif type == list[2] then
        str1 = "展翅高飞"
        str2 = "chibang"
    elseif type == list[3] then
        str1 = "收藏达人"
        str2 = "shenshou"
    end
    return str1, str2
end

--响应活动信息改变
function My:RespChange(msg)
    local type=msg.type
    Info:UpData(type, msg.type_i, msg.change_list)
    Info.mana = msg.mana
    Info.recharge = msg.recharge
    for i,v in ipairs(msg.mana_list) do
        Info:UpSevenData(v.id, Info.manaType, v.val)
    end
    self:UpAction()
end

--请求排行奖励  例：（法宝，排名奖励，配置id）
function My:ReqRankAward(type, index, id)
    local msg = ProtoPool.GetByID(26043)
    msg.type = type
    msg.type_i = index
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应排行奖励
function My:RespRankAward(msg)
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    Info:ChangeData(msg.type, msg.type_i, msg.id)
    self.eUpAward(msg.id)
    self:UpAction()
end

--响应排行榜信息
function My:RespRankInfo(msg)
    local type=msg.type
    self:SetRankInfo(tostring(type),msg.rank_list)
end

--设置排行榜信息
function My:SetRankInfo(sType,list)
    Info:ResetRankData(sType)  --xxxxxxxxxx
    local rList=Info.rankDataDic[sType]
    if not rList then 
        rList={}
        Info.rankDataDic[sType]=rList
    end
    for i,v in ipairs(list) do
        Info:SetRankData(v.rank, v.role_id, v.role_name, v.rank_value,rList)
    end
    self.eRankInfo(sType)
end

--响应活动最后一天  xxxxxxxxxxxxxxxxxxxxx
function My:RespEndActiv(msg)
    local type=tostring(msg.type)
    Info.isLastDayDic[type] = 1
    self.eEndActiv(type)
end

--更新红点
function My:UpAction()
    local dic = self:GetActionListNew(10014)
    local len = TableTool.GetDicCount(dic)
    local actId = ActivityMgr.ZCGF
	if len > 0 or My.norAction13 then
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
    end
    
    dic = self:GetActionListNew(10013)
    len = TableTool.GetDicCount(dic)
    actId = ActivityMgr.KFFB
	if len > 0 or My.norAction12 then
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
    end
    
    dic = self:GetActionListNew(10012)
    len = TableTool.GetDicCount(dic)
    actId = ActivityMgr.KFTJ
	if len > 0 or My.norAction11 then
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
	end
end

--获取红点列表
function My:GetActionListNew(type)
	local dic = {}
	local key = tostring(type)
    local list = Info.activDic[key]
    if list == nil then return dic end
    for i,v in ipairs(list) do
        if Info.isLastDayDic[tostring(type)] == 1 then
            if i == 1 then
                for k1,v1 in pairs(v) do
                    if v1 == 2 then
                        dic[tostring(i)] = i
                    end
                end
            end
        else
            if i ~= 4 then
                for k1,v1 in pairs(v) do
                    if v1 == 2 then
                        dic[tostring(i)] = i
                    end
                end
            end
        end
	end
	return dic
end

--获取红点列表
function My:GetActionList()
	local dic = {}
    local type = Info:GetOpenType()
	local key = tostring(type)
    local list = Info.activDic[key]
    if list == nil then return dic end
    for i,v in ipairs(list) do
        if Info.isLastDayDic[tostring(type)] == 1 then
            if i == 1 then
                for k1,v1 in pairs(v) do
                    if v1 == 2 then
                        dic[tostring(i)] = i
                    end
                end
            end
        else
            if i ~= 4 then
                for k1,v1 in pairs(v) do
                    if v1 == 2 then
                        dic[tostring(i)] = i
                    end
                end
            end
        end
	end
	return dic
end

------------------------------------------


--响应七日投资信息(6)
function My:RespSevenInfo(msg)
    local dic = Info:ShiftData(msg.list)
    local key = tostring(Info.sevenType)
    Info.dataDic[key] = dic
    Info.isInvest = msg.open
    self:UpSevenAction()
end

--请求七日投资奖励
function My:ReqSevenAward(id)
    local msg = ProtoPool.GetByID(26057)
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应七日投资奖励
function My:RespSevenAward(msg)
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    Info:UpSevenData(msg.id, Info.sevenType)
    self.eUpSevenAward(msg.id)
    self:UpSevenAction()
end

--请求七日投资
function My:ReqSevenInvest()
    local msg = ProtoPool.GetByID(26055)
    ProtoMgr.Send(msg)
end

--响应七日投资
function My:RespSevenInvest(msg)
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    local dic = Info:ShiftData(msg.update_list)
    local key = tostring(Info.sevenType)
    Info.dataDic[key] = dic
    Info.isInvest = 1
    self.eUpSevenInvest()
    self:UpSevenAction()
end

--更新七日投资红点
function My:UpSevenAction()
    local isShow = false
    local actId = ActivityMgr.QRTZ
    local dic = Info.dataDic[tostring(Info.sevenType)]
    if dic == nil then return end
    for k,v in pairs(dic) do
        if v == 2 then
            isShow = true
            break
        end
    end
    if isShow or My.norAction2 then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end
------------------------------------------


--响应限时购买信息
function My:RespBuyInfo(msg)
    local dic = Info:ShiftData(msg.list)
    local key = tostring(Info.buyType)
    Info.dataDic[key] = dic
    self:UpBuyAction()
end

--请求购买
function My:ReqBuy(id)
    local msg = ProtoPool.GetByID(26051)
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应购买
function My:RespBuy(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    Info:UpSevenData(msg.id, Info.buyType)
    self.eTimeLimitBuy()
end

--更新限时抢购红点
function My:UpBuyAction()
    local actId = ActivityMgr.XSQG
    if My.norAction3 then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

------------------------------------------


--响应许愿池信息
function My:RespWishInfo(msg)
    local dic = Info:ShiftData(msg.got_reward)
    local key = tostring(Info.wishType)
    Info.dataDic[key] = dic
    Info.score = msg.score
    Info.luckVal = msg.bless
    Info.preciousExist = msg.precious_exist
    Info.notice = msg.notice
    Info.nowDay = msg.config
    self:UpWishAction()
end

--请求许愿
function My:ReqWish(count)
    local msg = ProtoPool.GetByID(26063)
    msg.times = count
    ProtoMgr.Send(msg)
end

--许愿不弹关闭大奖池空提醒
function My:CloseHint(act)
    local msg = ProtoPool.GetByID(26113)
    msg.action = act
    ProtoMgr.Send(msg)
end

--响应许愿
function My:RespWish(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    Info.score = msg.score
    Info.luckVal = msg.bless
    Info.preciousExist = msg.precious_exist
    self.eUpWish(msg.times, msg.reward)
    self:UpWishAction()
end

--请求积分奖励
function My:ReqWishAward(id)
    local msg = ProtoPool.GetByID(26065)
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应积分奖励
function My:RespWishAward(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    local award = msg.reward
    Info:UpSevenData(award.id, Info.wishType, award.val)
    self.eUpWishAward(award.id, award.val)
    self:UpWishAction()
end

--更新许愿池红点
function My:UpWishAction()
    local state = false
    local actId = ActivityMgr.XYC
    local cfg = GlobalTemp["112"]
    if LivenessInfo:IsOpen(1028) then
        local token = ItemTool.GetNum(cfg.Value3)
        local isGet = self:IsGetWishAward()
        if token > 0 or isGet then
            state = true
        end
    end
    if state or My.norAction4 then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

--判断是否能领取许愿池兑换奖励
function My:IsGetWishAward()
    local dic = Info:GetBtnData(Info.wishType)
    if dic == nil then return false end
    for k,v in pairs(dic) do
        if v == 2 then
            return true
        end
    end
    return false
end


--更新默认红点
function My:UpNorAction(index)
    if index == 13 then
        My.norAction13 = false
        self:UpAction()
    elseif index == 12 then
        My.norAction12 = false
        self:UpAction()
    elseif index == 11 then
        My.norAction11 = false
        self:UpAction()
    elseif index == 2 then
        My.norAction2 = false
        self:UpSevenAction()
    elseif index == 3 then
        My.norAction3 = false
        self:UpBuyAction()
    elseif index == 4 then
        My.norAction4 = false
        self:UpWishAction()
    end
end

--清理缓存
function My:Clear()
    Info:Clear()
    TableTool.ClearDic(My.State)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
    ActivStateMgr.eUpActivState:Remove(self.UpActState, self)
end

return My