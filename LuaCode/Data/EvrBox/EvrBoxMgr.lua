EvrBoxMgr = Super:New{Name = "EvrBoxMgr"}
local My = EvrBoxMgr

My.eInfo = Event()
My.eRecharge = Event()
My.eReward = Event()

function My:Init()
    self:SetLsner(ProtoLsnr.Add)
    self:SetLn("Add")
    self:Reset()
end

function My:Reset()
    self.isRed = true
    self.dbTab = {}
end

function My:SetLsner(fun)
    fun(26472,self.ResInfo,self) --多种信息
    fun(26474,self.ResCharge,self) --充值信息
    fun(26476,self.ResReward,self) --领取奖励
end
function My:SetLn(func)
    NewActivMgr.eUpActivInfo[func](NewActivMgr.eUpActivInfo, self.RespUpActivState, self)
end

function My:RespUpActivState(actionId)
    self:ActionRed(1,actionId)
end

function My:ActionRed(index,actionId)
    local isReds = self.isRed 
    local isRewRed = self:IsShowRed(index)
    local tab = self.dbTab
    local day = tab.day
    if index == 1 then
        local id = actionId
        local isOpen = self:IsOpen()
        if id and id == 2007 and isOpen and isReds then
            self.isRed = false
            LvAwardMgr:UpAction(8,isReds)
        elseif id == nil and isOpen then
            if day == nil then
                self.isRed = false
                LvAwardMgr:UpAction(8,isReds)
            else
                LvAwardMgr:UpAction(8,isRewRed)
            end
        end
    elseif index == 2 then
        LvAwardMgr:UpAction(8,isRewRed)
    end
end

function My:IsShowRed(index)
    local isShow = false
    local dTab = self.dbTab
    local list = dTab.list
    if list then
        if index == 1 then --上线
            local times = 0
            isShow = true
            for k,v in pairs(list) do
                if v.val == 3 and v.id <= 3 then
                    times = times + 1
                end
            end
            if times >= 3 then
                isShow = false
            end
        else ----在线更新
            for k,v in pairs(list) do
                if v.val == 2 and v.id <= 3 then
                    isShow = true
                    break
                end
            end
        end
    end
    return isShow
end

function My:ResInfo(msg)
    local tab = self.dbTab
    tab.day = msg.day
    tab.list = {}
    -- tab.list[1].id = 0
    -- tab.list[1].val = 0
    local list = msg.list
    local len = #list
    for i = 1,len do
        local info = list[i]
        local id = info.id --充值次数
        local val = info.val --奖励状态 1-不能领 2-可领 3-已领
        tab.list[id] = {}
        tab.list[id].id = id
        tab.list[id].val = val
    end
    self.dbTab = tab
    self:ActionRed(1)
    self.eInfo()
end

function My:ResCharge(msg)
    local tab = self.dbTab
    local id = msg.id --充值次数    奖励置换可领取状态
    if id > 3 then return end
    if tab.list[id] == nil then
        tab.list[id] = {}
        tab.list[id].id = id
        tab.list[id].val = 2
    else
        tab.list[id].id = id
        tab.list[id].val = 2
    end
    self.dbTab = tab
    self:ActionRed(2)
    self.eRecharge()
end

function My:ResReward(msg)
    local err = msg.err_code
    local id = msg.id
    if self:CheckErr(err) then return end
    local tab = self.dbTab
    tab.list[id].id = id
    tab.list[id].val = 3
    self.dbTab = tab
    self:ActionRed(2)
    self.eReward()
end

--请求领取奖励
--id 充值次数
function My:ReqReward(id)
    if id == nil or id == 0 then
        return
    end
    local msg = ProtoPool.GetByID(26475)
	msg.id = id
    ProtoMgr.Send(msg)
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Error(err)
	    return true
    end
    return false
end

--获取需要显示的奖励信息
function My:GetShowCfg()
    if not self:IsOpen() then return end
    local info = NewActivMgr:GetActivInfo(2007)
    if not info then return end
    local configNum = info.configNum
    local dTab = self.dbTab
    local cDay = dTab.day
    if cDay == nil or cDay == 0 then iTrace.eError("GS","获取当前天数：",cDay) end
    if configNum == nil or configNum == 0 then iTrace.eError("GS","获取套序号：",configNum) end
    local tab = {}
    for i = 1,#EvrBoxCfg do
        local cfg = EvrBoxCfg[i]
        local day = cfg.day
        local num = cfg.num
        if cDay and cDay == day and configNum and configNum == num then
            table.insert(tab,cfg)
        end
    end
    return tab
end

--获取当前可领取次数
--index:1,2,3
function My:GetCurRewTimes(index)
    local times = 0
    local index = index
    local dTab = self.dbTab
    local list = dTab.list
    for k,v in pairs(list) do
        if v.val > 1 then
            times = times + 1
        end
    end
    if times >= index then
        times = index
    end
    return times
end

function My:IsOpen()
    local isOpen = NewActivMgr:ActivIsOpen(2007) --每日宝箱是否开启
    return isOpen
end

function My:Clear()
    self:Reset()
end

function My:Dispose()
    self:Reset()
    self:SetLn("Remove")
end

return My