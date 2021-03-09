InvestMgr = Super:New{Name = "InvestMgr"}

local M = InvestMgr

function M:Init()
    self.eUpdateInvest = Event()
    self.eGetReward = Event()
    self.eRespInfo = Event()
    self.eUpInvest = Event()

    self:Reset()
    self:SetLsnr(ProtoLsnr.Add)
    self:SetEvent()
end

function M:Reset()
    self.rewardList = {}
    self.curInvest = 0
    self.investData = {}

    local data = GlobalTemp["31"].Value2
    local len = #data 
    local cfg = InvestCfg
    local count = #cfg
    local list = {}
    local dic = {}
    for j=1,len do
        local invest = tostring(data[j])
        dic[invest] = {}
        local _data = {}
        local index = self:GetInvertIndex(data[j]) or 1
        for i=1,count do              
            local t= {}
            local c = cfg[i]
            t.level = c.level
            t.count = c.list[index]
            t.hadGet = 0
            t.invest = data[j]
            --t.investIndex = j
            table.insert(_data, t)
            dic[invest][tostring(c.level)] = t
        end
        list[invest] = _data
    end
    self.investData.list = list
    self.investData.dic = dic
end

function M:SetLsnr(fn)
    fn(22550, self.RespInvestGoldInfo, self)
    fn(22552, self.RespInvestGoldBuy, self)
    fn(22554, self.RespInvestGoldReward, self)
end

function M:SetEvent()
    EventMgr.Add("OnChangeLv", EventHandler(self.OnChangeLv, self))
end

--投资计划信息返回
function M:RespInvestGoldInfo(msg)
    self:UpdateCurInvest(msg.invest_gold)
    self:UpdateRewardList(msg.reward_list)
    self:UpdateRedPoint()
    self.eRespInfo()
end

--投资计划购买返回
function M:RespInvestGoldBuy(msg)
    if msg.err_code == 0 then
        self:UpdateCurInvest(msg.invest_gold)
        self:UpdateOtherInvest()
        self:UpdateRedPoint()
        self.eUpdateInvest()
        self.eUpInvest()
        -- self:CloseBtn()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--投资计划获得奖励返回
function M:RespInvestGoldReward(msg)
    if msg.err_code == 0 then
        self:UpdateReward(msg.reward)
        self:UpdateGetReward(msg.add_gold)
        self:UpdateRedPoint()
        self:SortCurInvest()
        self.eUpdateInvest()
        self.eUpInvest()
        self.eGetReward()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

function M:ReqInvestGoldBuy(invest_gold)
    local msg = ProtoPool.GetByID(22551)
    msg.invest_gold = invest_gold
    ProtoMgr.Send(msg)
end

function M:ReqInvestGoldReward(level)
    local msg = ProtoPool.GetByID(22553)
    msg.level = level
    ProtoMgr.Send(msg)
end


--==============================--

--更新当前投资档次
function M:UpdateCurInvest(investGold)
    self.curInvest = investGold
    self:UpdateCurInvestData()
end

--更新已经领取的奖励
function M:UpdateRewardList(list)
    local len = #list
    for i=1,len do
        self:UpdateReward(list[i])
    end
    self:SortCurInvest()
end

--更新已经领取的奖励的状态
function M:UpdateReward(reward)
    local dic = self.investData.dic
    dic[tostring(reward.val)][tostring(reward.id)].hadGet = 2
end

--更新当前档次领取状态
function M:UpdateCurInvestData()
    if self.curInvest > 0 then
        local dic = self.investData.dic[tostring(self.curInvest)]
        for k,v in pairs(dic) do
            if v.level <= User.MapData.Level and v.hadGet == 0 then
                v.hadGet = 1
            end
        end
    end
end

--更新红点
function M:UpdateRedPoint()
    local state = false
    if self.curInvest ~= 0 then
        local dic = self.investData.dic[tostring(self.curInvest)]
        for k,v in pairs(dic) do
            if v.hadGet == 1 then
                state = true
                break
            end
        end
    end
    VIPMgr.UpAction("3", state)
end

--刷新其他档次的数据
function M:UpdateOtherInvest()
    local list = GlobalTemp["31"].Value2
    local len = #list
    for i=1,len do
        if list[i] ~= self.curInvest then
            local dic = self.investData.dic[tostring(list[i])]
            for k,v in pairs(dic) do
                if v.hadGet == 1 then
                    v.hadGet = 0
                end
            end
        end
    end
end

function M:UpdateGetReward(count)
    self.rewardList = {}
    local temp = {}
    temp.k = 3
    temp.v = count
    table.insert(self.rewardList, temp)
end

function M:GetReward()
    return self.rewardList
end

function M:OnChangeLv()
    self:UpdateCurInvestData()
    self:UpdateRedPoint()
    self.eUpdateInvest()
end


--获取投资档次index
function M:GetInvertIndex(invest)
    local list = GlobalTemp["31"].Value2
    local len = #list
    for i=1,len do
        if list[i] == invest then
            return i
        end
    end
    iTrace.sLog("XGY", string.format("不存在价格为%d的充值档次",invest))
end

--获取对应档次的数据
function M:GetInvestData(invest)
    return self.investData.list[tostring(invest)] 
end

--获取对应档次等级的数据
function M:GetInvestLevelData(invest, level)
    return self.investData.dic[tostring(invest)][tostring(level)] or nil
end

--获取当前档次的对应的等级还可以领取的元宝
function M:GetRewardDvalue(invest,level)
    local dic = self.investData.dic
    local index = tostring(level)
    local count = dic[tostring(invest)][index].count
    local list = GlobalTemp["31"].Value2
    local len = #list 
    for i=len, 1, -1 do
        if list[i] < invest then
            local key = tostring(list[i])
            if dic[key][index].hadGet == 2 then
                count = count - dic[key][index].count
                break
            end
        end
    end
    return count
end

--获取当前档次
function M:GetCurInvest()
    return self.curInvest
end

--获取档次
function M:GetInvest(index)
    local data = GlobalTemp["31"].Value2
    return data[index] or nil
end


function M:SortCurInvest()
    if self.curInvest == 0 then return end
    table.sort(self.investData.list[tostring(self.curInvest)], function(a, b) return self:Sort(a,b) end)
end

function M:Sort(a,b)
    if a.hadGet == 2 and b.hadGet == 2 then
        return a.level < b.level
    elseif a.hadGet == 2 then
        return false
    elseif b.hadGet == 2 then
        return true
    else
        return  a.level < b.level
    end
end

--关闭返利按钮
function M:CloseBtn()
	local ui = UIMgr.Get(UIMainMenu.Name)
	if ui then ui:IsOpenBtn() end
end

function M:Clear()
    self:Reset()
end

return M