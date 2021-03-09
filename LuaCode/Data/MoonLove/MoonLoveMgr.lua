MoonLoveMgr = Super:New{Name = "MoonLoveMgr"}
local My = MoonLoveMgr
My.eMoonInfo = Event()
My.eMoonReward = Event()
My.eMoonExchange = Event()
My.eAddRecord = Event()
My.eRed = Event()

function My:Init()
    self:SetLsner(ProtoLsnr.Add)
    self:SetLn("Add")
    self:Reset()
end

function My:Reset()
    self.moonInfoTab = {}
    self.btnState = 0
    self.roleId = 0
    self.roleName = 0
    self.roleCharge = 0
end

function My:SetLsner(fun)
    fun(25002,self.ResMoonInfo,self) --天道情缘活动信息推送
    fun(25032,self.ResMoonReward,self)  --月下情缘 奖励抽取返回
    fun(25034,self.ResMoonExchange,self)  --月下情缘兑换返回
    fun(25036,self.ResMoonRecords,self)  --月下情缘日志新增
end

function My:SetLn(func)
    -- NewActivMgr.eUpActivInfo[func](NewActivMgr.eUpActivInfo, self.RespUpActivState, self)
end

function My:IsRed()
    local red = false
    local exCfg = self:GetExchangeRew()
    for i = 1,#exCfg do
        local score = exCfg[i].needScore
        local index = self:IsExChange(score)
        if index == 1 then
            red = true
            break
        end
    end
    return red
end

function My:ResMoonInfo(msg)
    self:ClearInfoTab()
    local moonTab = self.moonInfoTab
    local exTab = msg.pray_exchange_list --已经兑换的积分列表
    moonTab.exchangedTab = {}
    for i = 1,#exTab do
        local exScore = exTab[i]
        moonTab.exchangedTab[exScore] = exScore
    end
    moonTab.curScore = msg.pray_score  --积分
    local recTab = msg.pray_logs  --记录信息
    moonTab.recordTab = {}
    for i = 1,#recTab do
        local info = recTab[i]
        moonTab.recordTab[#moonTab.recordTab+1] = info
    end
    self.moonInfoTab = moonTab
    self.eRed(true,6)
    self.eMoonInfo()
end

function My:ResMoonReward(msg)
    local err = msg.err_code
    if self:CheckErr(err) then return end
    local moonTab = self.moonInfoTab
    if moonTab.rewTypeTab == nil then
        moonTab.rewTypeTab = {}
    end
    if moonTab.rewListTab == nil then
        moonTab.rewListTab = {}
    end
    self:ClearTab(moonTab.rewTypeTab)
    self:ClearTab(moonTab.rewListTab)
    local tab = msg.reward_type_list --抽取获得奖励的类型
    local rwtab = msg.goods_list --道具
    for i = 1,#tab do
        local type = tab[i]
        table.insert(moonTab.rewTypeTab,type)
    end
    for i = 1,#rwtab do
        local info = rwtab[i]
        table.insert(moonTab.rewListTab,info)
    end
    moonTab.curScore = msg.pray_score --积分
    self.moonInfoTab = moonTab
    local red = self:IsRed()
    self.eRed(red,6)
    self.eMoonReward()
end

function My:ResMoonExchange(msg)
    local err = msg.err_code
    if self:CheckErr(err) then return end
    local moonTab = self.moonInfoTab
    local score = msg.pray_score  --积分
    if moonTab.exchangedTab == nil then
        moonTab.exchangedTab = {}
    end
    if moonTab.exchangedTab[score] == nil then
        moonTab.exchangedTab[score] = score
    end
    self.moonInfoTab = moonTab
    local red = self:IsRed()
    self.eRed(red,6)
    self.eMoonExchange()
end

function My:ResMoonRecords(msg)
    local moonTab = self.moonInfoTab
    moonTab.addRecordTab = msg.add_logs
    local recTab = moonTab.addRecordTab
    for i = 1,#recTab do
        local info = recTab[i]
        moonTab.recordTab[#moonTab.recordTab+1] = info
    end
    self.moonInfoTab = moonTab
    self.eAddRecord()
end


--月下情缘 奖励抽取
--times: 次数
function My:ReqMoonTimes(times)
    local msg = ProtoPool.GetByID(25031)
    msg.times = times
	ProtoMgr.Send(msg)
end

--月下情缘兑换
--score: 兑换的积分类型
function My:ReqMoonExchange(scoreType)
    local msg = ProtoPool.GetByID(25033)
    msg.pray_score = scoreType
	ProtoMgr.Send(msg)
end

--是否已经兑换
--score：积分
--index: 1:兑换        2:已兑换        3:未达成
function My:IsExChange(score)
    local tab = self.moonInfoTab
    local curScore = tab.curScore
    local exTab = tab.exchangedTab
    local index = 0
    if exTab == nil or exTab[score] == nil then
        if curScore >= score then
            index = 1
        elseif curScore < score then
            index = 3
        end
    elseif exTab[score] ~= nil then
        index = 2
    end
    return index
end

--获取显示信息
function My:GetRew()
    local acInfo = NewActivMgr:GetActivInfo(2012)
    if not acInfo then
        return
    end
    local configNum = acInfo.configNum
    local cfg = MoonRewCfg
    local showTab = {}
    for i = 1,#cfg do
        local info = cfg[i]
        local type = info.type
        local infoCNum = info.configNum
        if configNum == infoCNum then
            showTab[type] = info
        end
    end
    return showTab
end

--获取兑换显示信息
function My:GetExchangeRew()
    local acInfo = NewActivMgr:GetActivInfo(2012)
    if not acInfo then
        return
    end
    local configNum = acInfo.configNum
    local cfg = MoonExchangeCfg
    local showTab = {}
    for i = 1,#cfg do
        local info = cfg[i]
        local infoCNum = info.configNum
        if configNum == infoCNum then
            table.insert(showTab,info)
        end
    end
    return showTab
end

function My:ClearInfoTab()
    if self.moonInfoTab then
        self.moonInfoTab.exchangedTab = nil
        self.moonInfoTab.curScore = nil
        self.moonInfoTab.recordTab = nil
        self.moonInfoTab.rewTypeTab = nil 
        self.moonInfoTab.rewListTab = nil 
        self.moonInfoTab.addRecordTab = nil
    end
end

function My:ClearTab(tab)
    for k,v in pairs(tab) do
        tab[k] = nil
    end
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Error(err)
	    return true
    end
    return false
end

function My:Clear()
    self:Reset()
end

function My:Dispose()
    self:Reset()
    self:SetLn("Remove")
end

return My