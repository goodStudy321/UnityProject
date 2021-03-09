BenefitMgr = Super:New{Name = "BenefitMgr"}

local M = BenefitMgr

M.AccuPage = 1   --开服累充
M.CreatePage = 2    --开宗立派
M.BossPage = 3   --猎杀Boss
M.BattlePage = 4  --道庭争霸
M.CollectWord = 5  --集字
M.Couple = 6 -- 神仙眷侣
M.DayTarget = 7  --开服目标

M.Personal = 1  --个人
M.Famlily = 2  --道庭

M.RankList = {} -- 神仙眷侣排行榜列表

M.eUpdateRedPoint = Event()
M.eUpdateData = Event()
M.eUpdataRank = Event()
M.eUpdateCp = Event()
M.eSet = Event()
M.eCoupleRank = Event()

function M:Init()
    self:Reset()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:Reset()
    self.CurPage = 0
    self.type = 0
    self.CoupleAction = false -- 神仙眷侣红点状态
    self.state = {}  --红点状态
    self.benefitData = {} --各模块数据 
    self.rankData = {}  --排行榜信息
    self.spokenList = {} -- 提亲信息
    self:InitData(FamilyCreateRewardCfg, self.CreatePage)
    self:InitData(KillBossRewardCfg, self.BossPage)
    self:InitData(FamilyBattleRewardCfg, self.BattlePage)
end

function M:SetLsnr(func)
    func(23500, self.RespFamilyCreateInfo, self)
    func(23502, self.RespFamilyCreateCondition, self)
    func(23504, self.RespFamilyCreateRewardUpdate, self)
    func(23506, self.RespFamilyCreateReward, self)

    func(23522, self.RespFamilyBattleCondition, self)
    func(23526, self.RespFamilyBattleReward, self)

    func(22960, self.RespHuntBossInfo, self)
    func(22962, self.RespHuntBossReward, self)
    func(22964, self.RespPersonalRankInfo, self)
    func(22966, self.RespFamilyRankInfo, self)

    func(23618,self.RespSpoken,self)
    func(23620,self.RespCouple,self)

    func(23630,self.RespCoupleRank,self)
end

--神仙眷侣提亲情况推送
function M:RespSpoken(msg)
    self.spokenList = msg.act_marry_info
    self.type = msg.marry_three_life_achieve
    table.sort( self.spokenList,M.SortS)
    if #self.spokenList == 3 then
        if self.type ~= 2 then
            self.CoupleAction = true
        end
        self:SetRedPointState(self.Couple, self.CoupleAction)
    end
    M.eUpdateCp()
end

function M.SortS(a,b)
    return a < b
end

-- 神仙眷侣领取发送
function M:ReqCouple()
    local msg = ProtoPool.GetByID(23619)
    ProtoMgr.Send(msg)
end

-- 神仙眷侣领取返回
function M:RespCouple(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
        return
    end
    self.type = 2
    M.eSet()
end

-- 神仙眷侣排行榜
function M:ReqCouplrRank()
    local msg = ProtoPool.GetByID(23629)
    ProtoMgr.Send(msg)
end

--神仙眷侣排行榜返回
function M:RespCoupleRank(msg)
    RankList = {}
    local list = msg.ranks
    --if not list then return end
    for i,v in ipairs(list) do
        local temp = {}
        temp.rank = v.rank
        temp.Mname = v.name_man
        temp.Wname = v.name_woman
        temp.friendly = v.friendly
        RankList[#RankList + 1] = temp
    end
    M.eCoupleRank()
end
function M:GetRankList()
    return RankList
end

--建帮立派信息推送
function M:RespFamilyCreateInfo(msg)
    local cond = msg.conditions
    for i=1,#cond do
        self:UpdateCondition(cond[i].id, cond[i].val, self.CreatePage)
    end

    local reward = msg.reward_list
    for i=1, #reward do
        self:UpdateFamilyCreateReward(reward[i].id, reward[i].val)
    end
    self:SortData(self.CreatePage)
    self:UpdateRedPoint(self.CreatePage)
end

--建帮立派condition更新
function M:RespFamilyCreateCondition(msg)
    local data = msg.condition
    self:UpdateCondition(data.id, data.val, self.CreatePage)
    self:SortData(self.CreatePage) 
    self:UpdateRedPoint(self.CreatePage)
    self.eUpdateData(self.CreatePage)
end

--建帮立派已经领取数量更新
function M:RespFamilyCreateRewardUpdate(msg)
    local data = msg.reward
    self:UpdateFamilyCreateReward(data.id, data.val)
    self:UpdateRedPoint(self.CreatePage)
    self.eUpdateData(self.CreatePage)
end

--建帮立派领取返回
function M:RespFamilyCreateReward(msg)
    if msg.err_code == 0 then
        local data = msg.condition
        self:UpdateCondition(data.id, data.val, self.CreatePage)
        self:SortData(self.CreatePage) 
        self:UpdateRedPoint(self.CreatePage)
        self.eUpdateData(self.CreatePage)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end 
end

--建帮立派奖励领取
function M:ReqFamilyCreateReward(id)
    local msg = ProtoPool.GetByID(23505)
    msg.id = id
    ProtoMgr.Send(msg)
end


--道庭争霸condition更新
function M:RespFamilyBattleCondition(msg)
    local data = msg.condition
    self:UpdateCondition(data.id, data.val, self.BattlePage)
    self:SortData(self.BattlePage) 
    self:UpdateRedPoint(self.BattlePage)
    self.eUpdateData(self.BattlePage)
end

--道庭争霸领取返回
function M:RespFamilyBattleReward(msg)
    if msg.err_code == 0 then
        local data = msg.condition
        self:UpdateCondition(data.id, data.val, self.BattlePage)
        self:SortData(self.BattlePage) 
        self:UpdateRedPoint(self.BattlePage)
        self.eUpdateData(self.BattlePage)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end 
end

--道庭争霸奖励领取
function M:ReqFamilyBattleReward(id)
    local msg = ProtoPool.GetByID(23525)
    msg.id = id
    ProtoMgr.Send(msg)
end





--猎杀Boss信息
function M:RespHuntBossInfo(msg)
    local list = msg.hunt_boss_reward_list
    for i=1,#list do
        self:UpdateCondition(list[i].id, list[i].val, self.BossPage)
    end  
    self:SortData(self.BossPage) 
    self:UpdateRedPoint(self.BossPage)
    self.eUpdateData(self.BossPage)
end

--领取奖励
function M:ReqHuntBossReward(id)
    local msg = ProtoPool.GetByID(22961)
    msg.id = id
    ProtoMgr.Send(msg)
end

--猎杀Boss奖励
function M:RespHuntBossReward(msg)
    if msg.err_code == 0 then
        local data = msg.hunt_boss_reward_list
        self:UpdateCondition(data.id, data.val, self.BossPage)
        self:SortData(self.BossPage) 
        self:UpdateRedPoint(self.BossPage)
        self.eUpdateData(self.BossPage)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end 
end

--请求个人排行榜信息
function M:ReqPersonalRankInfo()
    local msg = ProtoPool.GetByID(22963)
    ProtoMgr.Send(msg)
end

--个人排行榜信息
function M:RespPersonalRankInfo(msg)
    local temp = {}

    local data = msg.ranks
    local len = #data

    local list = {}
    for i=1,len do
        local val = data[i]
        local t =self:SwitchRankData(val.rank, val.name, val.family_name, val.personal_score)
        table.insert(list, t)
    end
    table.sort(list, function(a,b) return a.Value1 < b.Value1 end)

    local val = msg.personal_rank

    temp.rankList = list   
    temp.myData = self:SwitchRankData(val.rank, val.name, val.family_name, val.personal_score)
    temp.titleData = self:SwitchRankData("排名", "角色名称", "道庭", "个人总积分")

    self.rankData[self.Personal] = temp

    self.eUpdataRank(self.Personal)
end

--请求道庭排行榜信息
function M:ReqFamilyRankInfo()
    local msg = ProtoPool.GetByID(22965)
    ProtoMgr.Send(msg)
end

--道庭排行榜信息
function M:RespFamilyRankInfo(msg)
    local temp = {}

    local data = msg.ranks
    local len = #data
    local list = {}
    for i=1,len do
        local val = data[i]
        local t =self:SwitchRankData(val.rank, val.name, val.family_owner_name, val.family_score)
        table.insert(list, t)
    end
    table.sort(list, function(a,b) return a.Value1 < b.Value1 end)

    local val = msg.family_rank

    temp.rankList = list
    temp.myData = self:SwitchRankData(val.rank, val.name, val.family_owner_name, val.family_score)
    temp.titleData =  self:SwitchRankData("排名", "道庭", "庭主", "道庭总积分")

    self.rankData[self.Famlily] = temp

    self.eUpdataRank(self.Famlily)
end


--==============================--

function M:InitData(cfg, tp)
    local list = {}
    local len = #cfg
    for i=1,len do
        local temp = {}
        temp.id = cfg[i].id
        temp.des = cfg[i].des
        temp.totalCount = cfg[i].totalCount or 0
        temp.rewardList = cfg[i].rewardList
        temp.state = 1
        temp.remainCount = temp.totalCount
        table.insert(list, temp)
    end
    self.benefitData[tp] = list
    self:UpdateRedPoint(tp)
end



--==============================--
--转化排行数据结构
function M:SwitchRankData(Value1, Value2, Value3, Value4)
    local t = {}
    t.Value1 = Value1
    t.Value2 = Value2
    t.Value3 = Value3
    t.Value4 = Value4
    return t
end

--更新状态
function M:UpdateCondition(id, val, tp)
    local list = self.benefitData[tp]
    for i=1,#list do
        if list[i].id == id then
            if list[i].totalCount > 0 and val == 2 then        
                list[i].state = list[i].remainCount <=0 and 1 or 2
            else
                list[i].state = val     
            end
            break
        end
    end
end

--更新开宗立派剩余数量
function M:UpdateFamilyCreateReward(id, val)
    local list = self.benefitData[self.CreatePage]
    for i=1,#list do
       if list[i].id == id then
            list[i].remainCount = list[i].totalCount - val         
            if list[i].state == 2 then         
                list[i].state = list[i].remainCount <=0 and 1 or 2
            end
            break
       end
    end
end

--更新红点
function M:UpdateRedPoint(tp)
    local list = self.benefitData[tp]
    if not list then return end
    local state = false
    for i=1, #list do
        if list[i].state == 2 then
            state = true
            break
        end
    end
    self.state[tp] = state
    self.state[4] = false
    self.eUpdateRedPoint(state, tp)
    self:UpdateAllRedPoint()
end

--更新主界面红点
function M:UpdateAllRedPoint()
    local state = false
    for k,v in pairs(self.state) do
        if v then
            state = v
            break
        end
    end
    if state then
        SystemMgr:ShowActivity(ActivityMgr.JZYL)
    else
        SystemMgr:HideActivity(ActivityMgr.JZYL)
    end
end

--设置红点状态
function M:SetRedPointState(key, state)
    self.state[key] = state
    self.eUpdateRedPoint(state, key)
    self:UpdateAllRedPoint()
end

--==============================--

--根据下标去对应数据
function M:GetBenefitData(tp)
    return self.benefitData[tp]
end

--获取红点状态
function M:GetRedPointState(tp)
    return self.state[tp] or false
end


--获取排行信息
function M:GetRankData(type)
    return self.rankData[type]
end




function M:SortData(tp)
    local list = self.benefitData[tp]
    if not list then return end
    table.sort(list, function(a,b) return self:Sort(a,b) end)
end

function M:Sort(a, b)
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


function M:Clear()
    self:Reset()
end

return M