PracSecMgr = Super:New{Name = "PracSecMgr"}
local My = PracSecMgr
My.ePracInfo = Event()
My.eUpUI = Event()
My.ePracMisInfo = Event()
My.ePracInfoGotRew = Event()
My.ePracMisGotRew = Event()
My.ePracMisChange = Event()
My.ePracCharge = Event()
My.ePracBackExp = Event()

function My:Init()
    self:SetLsner(ProtoLsnr.Add)
    self:SetLn("Add")
    self:Reset()
end

function My:Reset()
    self.pracInfoTab = {}
    self.btnState = 0
    self.roleId = 0
    self.roleName = 0
    self.roleCharge = 0
end

function My:SetLsner(fun)
    fun(27122,self.ResPracInfo,self) --返回修炼秘籍系统信息
    fun(27124,self.ResPracMisInfo,self)  --返回修炼秘籍系统任务
    fun(27126,self.ResPracReward,self)  --返回修炼秘籍系统奖励领取
    fun(27128,self.ResPracMisRew,self)  --返回修炼秘籍系统任务经验领取
    fun(27130,self.ResPracMisChange,self)  --返回修炼秘籍系统任务信息变化
    fun(27132,self.ResPracCharge,self)  --充值解锁返回
    fun(27134,self.ResPracExpBack,self)  --返回修炼秘籍系统仙找回修炼点
end

function My:SetLn(func)
    -- NewActivMgr.eUpActivInfo[func](NewActivMgr.eUpActivInfo, self.RespUpActivState, self)
end

--index:1 奖励  
function My:RewAcRed()
    local isRed = false
    local pracTab = self.pracInfoTab
    local curLv = pracTab.pracLv
    local cfgTab = self:GetRew()
    if cfgTab == nil then
        return
    end
    local isCharge = self:IsRecharge()
    for i = 1,#cfgTab do
        local info = cfgTab[i]
        local lv = info.lv
        if curLv >= lv then
            if pracTab.gotRewTab == nil or pracTab.gotRewTab[1] == nil or pracTab.gotRewTab[1][lv] == nil or not(pracTab.gotRewTab[1][lv].isGot) then
                isRed = true
                break
            end

            if (pracTab.gotRewTab == nil or pracTab.gotRewTab[2] == nil or pracTab.gotRewTab[2][lv] == nil or not(pracTab.gotRewTab[2][lv].isGot)) and isCharge then
                isRed = true
                break
            end

        end
        -- if pracTab.gotRewTab ~= nil and pracTab.gotRewTab[1] ~= nil then
        --     local comIsGot = pracTab.gotRewTab[1][lv].isGot
        --     if (not comIsGot) and curLv >= lv then
        --         isRed = true
        --         break
        --     end
        -- end
        -- if pracTab.gotRewTab ~= nil and pracTab.gotRewTab[2] ~= nil then
        --     local spcIsGot = pracTab.gotRewTab[2][lv].isGot
        --     if (not spcIsGot) and isCharge and curLv >= lv then
        --         isRed = true
        --         break
        --     end
        -- end
    end
    PracticeSecMgr:UpAction(1,isRed)
end

--2 任务    
function My:MisAcRed()
    local isRed = false
    local pracTab = self.pracInfoTab
    local misTab = pracTab.missionTab
    if misTab == nil then
        return
    end
    for i = 1,#misTab do
        local misInfo = misTab[i]
        local misId = misInfo.mission_id
        local misState = self:PrasMisState(misId)
        if misState == 2 then
            isRed = true
            break
        end
    end
    PracticeSecMgr:UpAction(2,isRed)
end

function My:ResPracInfo(msg)
    self:ClearPracInfoTab()
    local pracTab = self.pracInfoTab
    pracTab.pracLv = msg.training_grade  --修炼等级
    pracTab.pracExp = msg.experience  --经验
    pracTab.praceBackExp = msg.retrieve  --可以找回的修炼点
    local gotComTab = msg.ordinary_grade  --已经领取奖励凡等级
    local gotSpeTab = msg.celestial_grade  --已经领取奖励仙等级
    pracTab.gotRewTab = {}
    for i = 1,#gotComTab do
        local lv = gotComTab[i]
        if pracTab.gotRewTab[1] == nil then
            pracTab.gotRewTab[1] = {} --1：凡，仙：2 "
        end
        if pracTab.gotRewTab[1][lv] == nil then
            pracTab.gotRewTab[1][lv] = {}
        end
        pracTab.gotRewTab[1][lv].lv = lv
        pracTab.gotRewTab[1][lv].isGot = true
    end
    for i = 1,#gotSpeTab do
        local lv = gotSpeTab[i]
        if pracTab.gotRewTab[2] == nil then
            pracTab.gotRewTab[2] = {} --1：凡，仙：2 "
        end
        if pracTab.gotRewTab[2][lv] == nil then
            pracTab.gotRewTab[2][lv] = {}
        end
        pracTab.gotRewTab[2][lv].lv = lv
        pracTab.gotRewTab[2][lv].isGot = true
    end
    pracTab.charIndex = msg.is_activate  --仙，1：激活；0：否
    self.pracInfoTab = pracTab
    self:RewAcRed()
    self.ePracInfo()
    --self.eUpUI()
end

function My:ResPracMisInfo(msg)
    self:ClearPracMisTab()
    local pracTab = self.pracInfoTab
    local misTab = msg.task_list
    pracTab.missionTab = misTab
    pracTab.misStateTab = {}
    for i = 1,#misTab do
        local misInfo = misTab[i]
        local misId = misInfo.mission_id
        local misCompTimes = misInfo.expedite
        local misIsGotRew = misInfo.is_reward
        pracTab.misStateTab[misId] = {}
        pracTab.misStateTab[misId].misId = misId
        pracTab.misStateTab[misId].misCompTimes = misCompTimes
        pracTab.misStateTab[misId].misIsGotRew = misIsGotRew
    end
    self.pracInfoTab = pracTab
    self:MisAcRed()
    self.ePracMisInfo()
end

function My:ResPracReward(msg)
    local err = msg.err_code
    if self:CheckErr(err) then return end
    local pracTab = self.pracInfoTab
    local id = msg.training_id --领取id
    local cfg = BinTool.Find(PracticeRewCfg,id,"id")
    local lv = cfg.lv
    local type = msg.type --"1：凡，仙：2 "
    if pracTab.gotRewTab == nil then
        pracTab.gotRewTab = {}
    end
    if pracTab.gotRewTab[type] == nil then
        pracTab.gotRewTab[type] = {}
    end
    if pracTab.gotRewTab[type][lv] == nil then
        pracTab.gotRewTab[type][lv] = {}
    end
    pracTab.gotRewTab[type][lv].lv = lv
    pracTab.gotRewTab[type][lv].isGot = true
    self.pracInfoTab = pracTab
    self:RewAcRed()
    self.ePracInfoGotRew()
end

function My:ResPracMisRew(msg)
    local err = msg.err_code
    if self:CheckErr(err) then return end
    local pracTab = self.pracInfoTab
    local pracLv = msg.training_grade  --修炼等级
    local pracExp = msg.experience  --经验
    local misId = msg.mission_id  --任务id
    pracTab.pracLv = pracLv
    pracTab.pracExp = pracExp
    pracTab.misStateTab[misId].misId = misId
    pracTab.misStateTab[misId].misIsGotRew = true
    self.pracInfoTab = pracTab
    self:RewAcRed()
    self:MisAcRed()
    self.ePracMisGotRew()
end

function My:ResPracMisChange(msg)
    local pracTab = self.pracInfoTab
    local misInfo = msg.task
    local misId = misInfo.mission_id
    local misTimes = misInfo.expedite
    pracTab.misStateTab[misId].misId = misId
    pracTab.misStateTab[misId].misCompTimes = misTimes
    self.pracInfoTab = pracTab
    self:MisAcRed()
    self.ePracMisChange()
end

function My:ResPracCharge()
    local pracTab = self.pracInfoTab
    pracTab.charIndex = 1
    self.pracInfoTab = pracTab
    self:RewAcRed()
    self.ePracCharge()
end

function My:ResPracExpBack(msg)
    local err = msg.err_code
    if self:CheckErr(err) then return end
    local pracTab = self.pracInfoTab
    local pracLv = msg.training_grade  --修炼等级
    local pracExp = msg.experience  --经验
    local praceBackExp = msg.training_point  --剩余可找回的修炼点
    pracTab.pracLv = pracLv
    pracTab.pracExp = pracExp
    pracTab.praceBackExp = praceBackExp
    self.pracInfoTab = pracTab
    self:RewAcRed()
    self.ePracBackExp()
end

-- --修炼秘籍系统信息
-- function My:ReqPracInfo()
--     local msg = ProtoPool.GetByID(27121)
-- 	ProtoMgr.Send(msg)
-- end

-- --修炼秘籍系统任务
-- function My:ReqPracMisInfo()
--     local msg = ProtoPool.GetByID(27123)
-- 	ProtoMgr.Send(msg)
-- end

--修炼秘籍系统奖励领取
--id: 领取id
--type: 1：凡，  2:仙
function My:ReqPracReward(id,type)
    local msg = ProtoPool.GetByID(27125)
    msg.training_id = id
    msg.type = type
	ProtoMgr.Send(msg)
end

--修炼秘籍系统任务经验领取
--id: 任务id
function My:ReqPracMisReward(id)
    local msg = ProtoPool.GetByID(27127)
    msg.mission_id = id
	ProtoMgr.Send(msg)
end

--修炼秘籍系统仙找回修炼点
--num: 要找回的修炼点
function My:ReqPracExpBack(num)
    local msg = ProtoPool.GetByID(27133)
    msg.training_point = num
	ProtoMgr.Send(msg)
end

function My:IsOpen()
    local isOpen = NewActivMgr:ActivIsOpen(2010) --是否开启
    return isOpen
end

--type:1：凡，仙：2 "
--lv 等级
--奖励是否可领取
--index : 0:不可领   1：凡品可领  2：仙品可领但未充值  3：仙品可领  4:已领
function My:IsCanRew(type,lv)
    local index = 0
    local pracTab = self.pracInfoTab
    local curLv = pracTab.pracLv
    local isCharge = self:IsRecharge()
    local isGot = self:IsGotRew(type,lv)
    if type == 1 and curLv >= lv and isGot == false then
        index = 1
    elseif type == 2 and curLv >= lv and isCharge == false and isGot == false then
        index = 2
    elseif type == 2 and curLv >= lv and isCharge == true and isGot == false then
        index = 3
    elseif isGot == true then
        index = 4
    end
    return index
end

--type:1：凡，仙：2 "
--lv 等级
--奖励是否已经领取
function My:IsGotRew(type,lv)
    local isGot = false
    local pracTab = self.pracInfoTab
    if pracTab.gotRewTab == nil or pracTab.gotRewTab[type] == nil or pracTab.gotRewTab[type][lv] == nil then
        return false
    end
    local info = pracTab.gotRewTab[type][lv]
    if info.isGot then
        isGot = true
    end
    return isGot
end

--是否充值
function My:IsRecharge()
    local pracTab = self.pracInfoTab
    local index = pracTab.charIndex
    if index == nil or index == 0 then
        return false
    end
    return true
end

--任务状态 1：前往  2：领取   3：已完成
--misId:任务id
function My:PrasMisState(misId)
    local state = 0
    local pracTab = self.pracInfoTab
    local misInfo = pracTab.misStateTab[misId]
    if misInfo == nil then
        return 1
    end
    local misCfg = PracticeMisCfg[misId]
    local cfgArg = misCfg.condArg
    local misId = misInfo.misId
    local times = misInfo.misCompTimes
    local isGotRew = misInfo.misIsGotRew
    if isGotRew then
        state = 3
    elseif times >= cfgArg then
        state = 2
    elseif times < cfgArg then
        state = 1
    end
    return state
end

--获取显示信息
function My:GetRew()
    local acInfo = NewActivMgr:GetActivInfo(2010)
    if not acInfo then
        return
    end
    local configNum = acInfo.configNum
    local cfg = PracticeRewCfg
    local showTab = {}
    for i = 1,#cfg do
        local info = cfg[i]
        local id = info.id
        local infoCNum = info.flagId
        if configNum == infoCNum then
            table.insert(showTab,info)
        end
    end
    return showTab
end

--展示道具为仙品秘籍配置的奖励总和（相同道具则叠加数量）
function My:GetShowRew()
    local acInfo = NewActivMgr:GetActivInfo(2010)
    local configNum = acInfo.configNum
    local cfg = PracticeRewCfg
    local showTab = {}
    for i = 1,#cfg do
        local info = cfg[i]
        local id = info.id
        local infoCNum = info.flagId
        if configNum == infoCNum then
            local spcRewTab = info.specRew
            for j = 1,#spcRewTab do
                local reInfo = spcRewTab[j]
                local id = reInfo.k
                local num = reInfo.v
                if showTab[id] == nil then
                    showTab[id] = {}
                end
                if showTab[id].id == nil then
                    showTab[id].id = id
                    showTab[id].num = num
                elseif showTab[id].id == id then
                    showTab[id].id = id
                    showTab[id].num = showTab[id].num + num
                end
            end
        end
    end
    return showTab
end

function My:ClearPracInfoTab()
    if self.pracInfoTab then
        self.pracInfoTab.charIndex = 0
        self.pracInfoTab.pracExp = 0
        self.pracInfoTab.pracLv = 0
        self.pracInfoTab.praceBackExp = 0
        self:ClearPracTab(1,self.pracInfoTab.gotRewTab)
        self:ClearPracTab(2,self.pracInfoTab.gotRewTab)
    end
end

function My:ClearPracMisTab()
    if self.pracInfoTab and self.pracInfoTab.misStateTab then
        for k,v in pairs(self.pracInfoTab.misStateTab) do
            self.pracInfoTab.misStateTab[k].misId = 0
            self.pracInfoTab.misStateTab[k].misCompTimes = 0
            self.pracInfoTab.misStateTab[k].misIsGotRew = false
            self.pracInfoTab.misStateTab[k] = nil
        end
    end
    if self.pracInfoTab and self.pracInfoTab.missionTab then
        self:ClearTab(self.pracInfoTab.missionTab)
    end
end

function My:ClearPracTab(index,tab)
    if tab and tab[index] then
        self:ClearTab(tab[index])
        tab[index] = nil
    end
end

function My:ClearTab(tab)
    if tab then
        for k,v in pairs(tab) do
            if tab[k].lv or tab[k].isGot then
                tab[k].lv = 0
                tab[k].isGot = false
            end
            tab[k] = nil
        end
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