MonthInvestMgr = Super:New{Name = "MonthInvestMgr"}

local M = MonthInvestMgr

function M:Init()
    self.eUpdateMonth = Event()
    self.eGetReward = Event()
    self:Reset()
    self:SetLnsr(ProtoLsnr.Add)
end

function M:Reset()
    self.rewardDic = {}
    self.monthCardData = {}
    self.remainDay = 0
    self.corpus = true

    local cfg = MonthCardCfg
    local len = #cfg
    local data = {}
    for i=1,len do
        local temp = {}
        temp.day = cfg[i].id
        temp.count = cfg[i].count
        temp.hadGet = 0
        table.insert(data, temp)
    end
    self.monthCardData = data
end

function M:SetLnsr(fn)
    fn(22560, self.RespMonthCardInfo, self)
    fn(22562, self.RespMonthCardBuy, self)
    fn(22564, self.RespMonthCardReward, self)
end

--月卡信息返回
function M:RespMonthCardInfo(msg)
    self:UpdateMonthCardData(msg)
end

--月卡购买返回
function M:RespMonthCardBuy(msg)
    if msg.err_code == 0 then
        self:UpdateMonthCardData(msg)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--月卡获得奖励返回
function M:RespMonthCardReward(msg)
    if msg.err_code == 0 then
        self:UpdateMonthCardData(msg)
        self:UpdateReward(msg.add_gold)
        self.eGetReward()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--购买月卡
function M:ReqMonthCardBuy()
    local msg = ProtoPool.GetByID(22561)
    ProtoMgr.Send(msg)
end

--领取月卡奖励
function M:MonthCardReward(day)
    local msg = ProtoPool.GetByID(22563)
    msg.days = day
    ProtoMgr.Send(msg)
end

--==============================--

function M:UpdateMonthCardData(msg)
    local hadGet = msg.is_reward
    local remainDay = msg.remain_days
    local corpus = msg.is_principal_reward
    local data = self.monthCardData
    local len = #data
    local getDay = len - remainDay - 1

    table.sort(data, function(a,b) return a.day < b.day end)

    for i=1,len do
        data[i].hadGet = data[i].day<=getDay and 2 or 0
    end

    if not corpus then
        data[1].hadGet = 1
    end

    if not hadGet then
        data[getDay+2].hadGet = 1
    end
    self:UpdateRemainDay(remainDay)
    self:UpdateCorpus(corpus)
    self:UpdateRedPoint()
    table.sort(data, function(a, b) return self:Sort(a, b) end)
    self.eUpdateMonth()
end

function M:UpdateRedPoint()
    local data = self.monthCardData
    local len = #data
    local state = false
    for i=1,len do
        if data[i].hadGet == 1 then
            state = true
            break
        end
    end
    VIPMgr.UpAction("2", state)
end

function M:UpdateRemainDay(remainDay)
    self.remainDay = remainDay
end

function M:UpdateCorpus(corpus)
    self.corpus = corpus
end

function M:UpdateReward(count)
    self.rewardList = {}
    local temp = {}
    temp.k = 3
    temp.v = count
    table.insert(self.rewardList, temp)
end

function M:GetReward()
    return self.rewardList
end

function M:GetRemainDay()
    return self.remainDay
end

function M:CanBuy()
    return self.remainDay == 0 and self.corpus
end

function M:GetMonthCardData()
    return self.monthCardData
end

function M:Sort(a, b)
    if a.hadGet == 2 and b.hadGet == 2 then
        return a.day < b.day
    elseif a.hadGet == 2 then
        return false
    elseif b.hadGet == 2 then
        return true
    else
        return a.day < b.day
    end
end

function M:Clear()
    self:Reset()
end

return M