DayTargetMgr = {Name = "DayTargetMgr"}

local M = DayTargetMgr

M.DayTargetDic = {} --key：ID
M.DayTargetInfo = {} --Key: 天数
M.RedPointState = {}  --key:day
M.ProRewardInfo = {}

M.ProRedPointState = false  --进度红点
M.StartTime = 0
M.CurProgress = 0
M.TotalPro = 0

M.eUpdateDTInfo = Event()
M.eUpdateDTPro = Event()
M.eUpdateDTProReward = Event()
M.eUpdateRedPoint = Event()


M.eClickProCell = Event()


function M:Init()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:SetLsnr(fn)
    fn(23800, self.RespDayTargetInfo, self)
    fn(23802, self.RespDayTargetCondition, self)
    fn(23804, self.RespDayTargetReward, self)
    fn(23806, self.RespDayTargetProgress, self)
end

function M:RespDayTargetInfo(msg)
    self:ClearDic()
    self:InitData()

    local list = msg.reward_list
    local len = #list 
    for i=1, len do
        self:UpdateReward(list[i])    
        self:UpdatePro(list[i])
    end
    
    local conds = msg.conditions
    for i=1,#conds do
        self:UpdateCondition(conds[i].id, conds[i].val)
    end

    local pros = msg.progress_reward_list
    for i=1,#pros do
        self:UpdateProgressReward(pros[i])
    end    
    self:UpdateRedPoint()      
    self:SortDTInfo()    
end

function M:RespDayTargetCondition(msg)
    local conds = msg.condition
    for i=1,#conds do
        self:UpdateCondition(conds[i].id, conds[i].val)
    end
    self:UpdateRedPoint()
    self:SortDTInfo()  
    self.eUpdateDTInfo()
end

function M:RespDayTargetReward(msg)
    if msg.err_code == 0 then
        self:UpdateReward(msg.id)
        self:UpdatePro(msg.id)
        self:UpdateRedPoint()
        self:SortDTInfo() 
        self.eUpdateDTInfo()
        self.eUpdateDTPro()
	else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--领取奖励
function M:ReqDayTargetReward(id)
    local msg = ProtoPool.GetByID(23803)
	msg.id = id
    ProtoMgr.Send(msg)
end

function M:RespDayTargetProgress(msg)
    if msg.err_code == 0 then
        self:UpdateProgressReward(msg.progress)
        self:UpdateRedPoint()
        self.eUpdateDTProReward()
	else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--7天目标 进度奖励领取
function M:ReqDayTargetProgress(id)
    local msg = ProtoPool.GetByID(23805)
	msg.progress = id
    ProtoMgr.Send(msg)
end


--*************************--


function M:InitData()
    local cfg = DayTargetCfg
    local len = #cfg
    local totatPro = 0
    for i=1,len do
        local data = cfg[i]
        local day = tostring(data.day)
        if not self.DayTargetInfo[day] then
            self.DayTargetInfo[day] = {}
        end
        local t = self:SwitchData(data)
        table.insert(self.DayTargetInfo[day], t)
        self.DayTargetDic[tostring(data.id)] = t
        totatPro = totatPro + data.pro
    end

    self.TotalPro = totatPro
    self.CurProgress = 0

    self:InitProRewardInfo()
end

function M:InitProRewardInfo()
    local cfg = DTProgressCfg
    local list = self.ProRewardInfo
    for i=1,#cfg do
        local t = {}
        t.id = cfg[i].id
        t.reward = cfg[i].reward
        t.icon = cfg[i].icon
        t.mMod = cfg[i].mMod
        t.wMod = cfg[i].wMod
        t.pos = cfg[i].pos
        t.euler = cfg[i].euler
        t.state = 1
        table.insert(list, t)
    end
end

function M:SwitchData(data)
    local t = {}
    t.id = data.id
    t.des = data.des
    t.day = data.day
    t.tParam = data.tParam
    t.rewardList = data.rewardList
    t.diff = data.diff
    t.pro = data.pro
    t.getWay = data.getWay
    t.activeType = data.activeType
    t.state = 1
    t.condition = 0
    return t
end


--更新进度条数据
function M:UpdatePro(id)
    local pro = self.DayTargetDic[tostring(id)].pro
    self.CurProgress = self.CurProgress + pro
    self:UpdateProRewardState()
end

--根据id更新数据
function M:UpdateCondition(id, val)
    local dic = self.DayTargetDic
    local data = dic[tostring(id)]
    if not data then return end
    val = tonumber(val)
    data.condition = val
    if data.state~=3 then
        data.state = data.tParam<=val and 2 or 1
    end
end

--更新已经领取的奖励
function M:UpdateReward(id)
    local dic = self.DayTargetDic
    local data = dic[tostring(id)]
    if data then
        data.state = 3
    end
end

--已经领取的进度奖励
function M:UpdateProgressReward(id)
    local list = self.ProRewardInfo
    for i=1,#list do
        if list[i].id == id then
            list[i].state = 3
            break
        end
    end
end

function M:UpdateProRewardState()
    local list = self.ProRewardInfo
    for i=1,#list do
        if list[i].state == 1 and list[i].id <= self.CurProgress then
            list[i].state = 2
        end
    end
end


--更新红点状态
function M:UpdateRedPoint()
    local info = self.DayTargetInfo
    local stateDic = self.RedPointState
    local tState = false

    for k,list in pairs(info) do
        stateDic[k] = false
        for i=1,#list do
            if list[i].state == 2 then
                stateDic[k] = true
                tState = true
                break
            end
        end
        self.eUpdateRedPoint(stateDic[k], k)
    end

    M.ProRedPointState = false
    local pInfo = self.ProRewardInfo
    for i=1,#pInfo do
        if pInfo[i].state == 2 then
            M.ProRedPointState = true
            tState = true
            break
        end
    end

    BenefitMgr:SetRedPointState(BenefitMgr.DayTarget, tState)
end


function M:GetEndTime()
    local info = LivenessInfo:GetActInfoById(1036)
    return info and info.eDate or 0
end


--通过天数获取对应数据
function M:GetDTDataByDay(day)
    if not day then return end
    local data = self.DayTargetInfo[day]
    if data then       
        return data
    else
        iTrace.Error("XGY", string.format("不存在第%s天的数据", day))
    end
end

--获取当前天数
function M:GetCurDay()
    local day = 0
    local info = LivenessInfo:GetActInfoById(1036)
    local sData =info and info.sDate or 0
    if sData >0 then
        local d = DateTool.GetDate(sData)
        local val = d.TimeOfDay.TotalSeconds
        local t = DateTool.GetDay(TimeTool.GetServerTimeNow()*0.001 - sData + val)
        day = t + 1
    end
    return day
end

--获取当前进度
function M:GetCurPro()
    return self.CurProgress
end
--获取总进度
function M:GetTotalPro()
    -- return self.TotalPro
    local list = self.ProRewardInfo
    return list[#list].id
end

function M:GetProRewardInfo()
    return self.ProRewardInfo
end

function M:GetRedPointStateByDay(day)
    local s = self.RedPointState[day]
    local state = false
    if s ~= nil then
        state = s
    end
    return state
end

--获取当前展示模型
function M:GetCurModel()
    local list = self.ProRewardInfo
    local modelId = nil
    local icon = nil
    local pos = nil
    local euler = nil
    local score = nil
    local index = nil
    local key = User.MapData.Sex == 1 and "mMod" or "wMod"
    for i=1,#list do
        local temp = list[i]
        if temp[key] then
            modelId = temp[key]
            icon = temp.icon
            pos = temp.pos
            euler = temp.euler
            score = temp.id
            index = i
            if temp.state < 3 then break end
        end
    end

    if modelId then
        local info = RoleBaseTemp[modelId]
        if not info then return end
        return info.uipath, icon, pos, euler, score, index
    end
end


function M:GetModel(index, isLeft)
    if not index then return end
    local list = self.ProRewardInfo
    local len = #list
    local sIndex = index + 1
    local int = 1
    if isLeft then
        len = 1
        sIndex = index-1
        int = -1
    end
    local modelId = nil
    local icon = nil
    local pos = nil
    local euler = nil
    local score = nil
    local index = nil
    local key = User.MapData.Sex == 1 and "mMod" or "wMod"
    for i=sIndex, len , int do
        local temp = list[i]
        if temp[key] then
            modelId = temp[key]
            icon = temp.icon
            pos = temp.pos
            euler = temp.euler
            score = temp.id
            index = i
            break
        end
    end

    if modelId then
        local info = RoleBaseTemp[modelId]
        if not info then return end
        return info.uipath, icon, pos, euler, score, index
    end
end


--指定天数是否已经开启
function M:IsOpen(day)
    day = tonumber(day)
    local cur = self:GetCurDay()
    if cur > 0 then
        if day <= cur then
            return true
        else
            return false, day 
        end
    else
        return false
    end
end


function M:SortDTInfo()
    local dic = self.DayTargetInfo
    for _,list in pairs(dic) do
        table.sort(list, function(a,b) return self:Sort(a, b) end)
    end
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

function M:ClearDic()
    TableTool.ClearDic(self.DayTargetDic)
    TableTool.ClearDic(self.DayTargetInfo)
    TableTool.ClearDic(self.ProRewardInfo)
    TableTool.ClearDic(self.RedPointState)
end


function M:Clear()
    self:ClearDic()
    self.CurProgress = 0
    self.StartTime = 0
    M.ProRedPointState = false
    -- self:InitData()
end

return M