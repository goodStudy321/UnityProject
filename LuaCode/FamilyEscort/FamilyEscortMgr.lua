FamilyEscortMgr = Super:New{Name = "FamilyEscortMgr"}

local M = FamilyEscortMgr

M.mEscortList = {}   --仙灵数据
M.mLogList = {}   --护送Log信息
M.mRobList = {}  --劫镖列表


M.eUpdateEscort = Event()  --更新护送  1-提升品质 2-最高品质 3-开始护送
M.eUpdateEscortStatus = Event()
M.eUpdateEscortLog = Event()
M.eUpdateRobList = Event()
M.eRefreshRobsData = Event()
M.eRefreshEscortRed = Event()
--M.eUpdateEscortBtn = Event()  --更新主界面按钮

function M:Init()
    self:InitData()
    self:SetLsnr(ProtoLsnr.Add)
    self:SetEvent("Add")
end

function M:InitData()
    self.mEscortRemainTime = 0 --护送剩余次数
    self.mRobRemainTime = 0 --劫镖剩余次数
    self.mCurEscortId = 0  --当前仙灵ID
    self.mEndTime = 0  --护送结束时间戳， 0：未在护送状态
    self.mIsRob = 0  --是否被抢  0-否  1-被抢 2-自己抢回 3-盟友抢回 
    self.mCanGetReward = 0 --是否有可领取奖励   1-是
    self.mIsOpen = false  --是否在活动时间内
    self.mIsSysEscortOpen = false   --道庭护送是否开启
end

function M:SetLsnr(Lsnr)
    Lsnr(26134, self.RespRoleEscortList, self)
    Lsnr(26136, self.RespRoleEscortInfo, self)
    Lsnr(26138, self.RespRoleEscortLog, self)
    Lsnr(26140, self.RespRoleEscort, self)
    Lsnr(26142, self.RespRoleEscortReward, self)
    Lsnr(26144, self.RespRoleEscortRob, self)  
    Lsnr(26150, self.RespRoleEscortRobBack, self)  
    Lsnr(26154, self.RespRoleEscortStatus, self)  
    Lsnr(26156, self.RespRoleEscortUpdate, self)  
    Lsnr(26162, self.RespRoleEscortForHelp, self)  
end

function M:SetEvent(fn)
	SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.ChangeSceneEnd, self)
end

function M:ChangeSceneEnd(isLoad)
	if isLoad then
        local last = SceneMgr.Last
        if not last then return end
        if last ~= 30022 then return end
        if SceneMgr.Last == User.SceneId then return end
        UIMgr.Open(UIFamilyEscort.Name , self.OpenFamilyEscortCb, self)
	end
end

function M:OpenFamilyEscortCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:OpenRobView()
    end
end


function M:RespEscortActiveInfo(p_activity)
    self.mIsOpen = p_activity.status == 2
    self:UpdateRedPoint()
    --self:eUpdateEscortBtn()
end

--// 上线护送数据推送
function M:RespRoleEscortInfo(msg)
    self:MsgLog("RespRoleEscortInfo", msg)
    self:UpdateSysEscort(true)
    self:InitEscortList()
    self:ClearLogsData()
    self:UpdateEscortRemainTime(msg.escort_times)
    self:UpdateRobRemainTime(msg.rob_times)
    self:UpdateEndTime(msg.escort_end_time)
    self:UpdateCurEscortId(msg.type)
    self:UpdateRobStatus(msg.rob)
    self:UpdateCanGetReward(msg.reward)
    local list = msg.log_list
    for i=1,#list do
        self:UpdateLog(list[i])
    end
    --FamilyMgr.eRed(self.mEscortRemainTime > 0 or self.mCanGetReward == 1, 1, 3)
end

--// 请求护送列表
function M:ReqRoleEscortList(id, time)
    local msg = ProtoPool.GetByID(26133)
    msg.id = id or 0
    msg.time = time or 0
    ProtoMgr.Send(msg)
end

--// 护送列表
function M:RespRoleEscortList(msg)
    self:MsgLog("RespRoleEscortList", msg)
    local list = msg.list
    local len = self:GetRobsCount()
    local needUpdateData = len < 5  --是否需要刷新列表， 数据不满一页，需要刷新
    for i=1,#list do
        local unit = self:CreateRobUnit(list[i])
        table.insert(self.mRobList, unit)
    end
    table.sort(self.mRobList, function(a,b) 
        return a.Id < b.Id
    end )
    self.eUpdateRobList(needUpdateData)
end


--// 护送日志更新
function M:RespRoleEscortLog(msg)
    self:MsgLog("RespRoleEscortLog", msg)
    local id = msg.log_list.type
    local texts = msg.log_list.text
    self:UpdateLog(msg.log_list)
    self.eUpdateEscortLog({Id = id, Texts = texts})
end

--// 请求提升护送品质 或 护送
function M:ReqRoleEscort(type)
    local msg = ProtoPool.GetByID(26139)
    msg.type = type --//1-提升品质 2-最高品质 3-开始护送
    ProtoMgr.Send(msg)
end

--// 护送
function M:RespRoleEscort(msg)
   self:MsgLog("RespRoleEscort", msg)
   if UIMisc.CheckErr(msg.err_code) then
        self:UpdateCurEscortId(msg.type_id)
        self:UpdateEscortRemainTime(msg.num)
        self:UpdateEndTime(msg.end_time)
        self.eUpdateEscort(msg.type)
        self.eRefreshEscortRed()
   end
end

--// 请求领取护送奖励
function M:ReqRoleEscortReward()
    local msg = ProtoPool.GetByID(26141)
    ProtoMgr.Send(msg)
end

--// 领取护送奖励
function M:RespRoleEscortReward(msg)
    self:MsgLog("RespRoleEscortReward", msg)
    if UIMisc.CheckErr(msg.err_code) then
        UITip.Log("领取成功")
        self:ClearLogsData()
        self:UpdateCanGetReward(msg.reward)
        self:UpdateCurEscortId(msg.type)
        self:UpdateRobStatus(0)
        self.eUpdateEscortStatus(6, msg.reward)
        self.eUpdateEscortStatus(4)
        self.eUpdateEscortStatus(5)
    end
end

--// 请求劫镖
function M:ReqRoleEscortRob(id)
    local msg = ProtoPool.GetByID(26143)
    msg.id = id
    ProtoMgr.Send(msg)
end

--// 劫镖
function M:RespRoleEscortRob(msg)
    self:MsgLog("RespRoleEscortRob", msg)
    if UIMisc.CheckErr(msg.err_code) then
        local title = "拦截失败"
        local data = {}
        if msg.res then
            title = "拦截成功"          
            table.insert(data, {id=100, val = tonumber(msg.exp)})
            local rewards = msg.reward
            for i=1,#rewards do
                table.insert(data, rewards[i])
            end
            self:UpdateRobRemainTime(msg.rob_times)
        end
        self:SetEndReward(msg.res, data, title)
    elseif msg.err_code == 26144001 
    or msg.err_code == 26150003 
    then
        self:ClearRobsData()
        self:ReqRoleEscortList(0,0)
    end
end

--// 请求夺回劫镖
function M:ReqRoleEscortRobBack(id)
    local msg = ProtoPool.GetByID(26149)
    msg.id = id --//被帮助ID
    ProtoMgr.Send(msg)
end

--// 夺回劫镖
function M:RespRoleEscortRobBack(msg)
    self:MsgLog("RespRoleEscortRobBack", msg)
    if UIMisc.CheckErr(msg.err_code) then
        local title = msg.res and "你已成功夺回奖励" or "夺回奖励失败"
        self:SetEndReward(msg.res, msg.reward, title)
    end
end



--// 护送更新
function M:RespRoleEscortStatus(msg)
    self:MsgLog("RespRoleEscortStatus", msg)
    local list = msg.value
    for i=1,#list do
        local id = list[i].id
        local val = list[i].val
        if id == 1 then
            self:UpdateEscortRemainTime(val)
        elseif id == 2 then
            self:UpdateRobRemainTime(val)
        elseif id == 3 then
            self:UpdateEndTime(val)
        elseif id == 4 then
            self:UpdateCurEscortId(val)
        elseif id == 5 then
            self:UpdateRobStatus(val)
        elseif id == 6 then
            self:UpdateCanGetReward(val)
        end 
        self.eUpdateEscortStatus(id, val)
    end 
end

-- 护送列表推送
function M:RespRoleEscortUpdate(msg)
    self:MsgLog("RespRoleEscortUpdate", msg)
    local list = msg.list
    local robList = self.mRobList
    local needRefresh = false
    for i=1,#list do
        local index = TableTool.Contains(robList, {Id = list[i].id}, "Id")
        if index ~= -1 then
            needRefresh = true
            self:UpdateRobUnit( robList[index], list[i])
        end
    end


    local needUpdateData = false

    list = msg.del_id
    for i=1,#list do
        local index = TableTool.Contains(robList, {Id = list[i].id}, "Id")
        if index ~= -1 then
            needUpdateData = true
            table.remove(robList, index)
        end
    end

    if needUpdateData then
        self.eUpdateRobList(needUpdateData)  --重新加载列表
    elseif needRefresh then
        self.eRefreshRobsData()   --只刷新数据
    end
end

--请求援助
function M:ReqRoleEscortForHelp()
    local msg = ProtoPool.GetByID(26161)
    ProtoMgr.Send(msg)
end

--请求援助返回
function M:RespRoleEscortForHelp(msg)
    self:MsgLog("RespRoleEscortForHelp", msg)
    if UIMisc.CheckErr(msg.err_code) then
        UITip.Log("已请求援助")
    end
end




--Init
function M:InitEscortList()
    for k,v in pairs(EscortTemp) do
        local unit = self:CreateEscortUnit(v)
        self.mEscortList[unit.Quality] = unit
    end
end


--创建EscortUnit
function M:CreateEscortUnit(data)
    local unit = {}
    unit.Id = data.id     --仙灵ID
    unit.Quality = data.quality    --品质
    unit.ModelId = data.modelId    --modelId
    unit.Cost = data.cost      --升到下一阶需要消耗的道具 nil：无法升到下一阶
    unit.PreferPrice = data.preferPrice  --升到最高阶需要的钱  nil：无法升到最高阶
    unit.Seconds = data.minute * 60     --一次护送持续时间 
    unit.expRatio = data.expRatio*0.0001   --经验奖励倍数
    unit.Rewards = {}     --护送完成可得奖励
    table.insert(unit.Rewards, {k=100, v=1})
    local rewards = data.rewards
    for i=1,#rewards do
        table.insert(unit.Rewards, rewards[i])
    end    
    local roleBaseTemp = RoleBaseTemp[tostring(unit.ModelId)]
    unit.Name = roleBaseTemp.name  --仙灵名字
    unit.Prefab = roleBaseTemp.uipath  --prefab路径
    return unit
end

--创建拦截Unit
function M:CreateRobUnit(data)
    local unit = {}
    unit.Id = data.id -- 列表唯一ID(后端需要)
    unit.RoleId = UIMisc.LongToNum(data.role_id)
    unit.EndTime = data.end_time
    unit.Fight = UIMisc.LongToNum(data.fight)
    unit.Name = data.role_name
    unit.ServerName = data.server_name
    unit.Rewards = {}
    local eTemp = EscortTemp[tostring(data.type)]
    unit.expRatio = eTemp.expRatio*0.0001*0.3   --经验奖励倍数
    table.insert(unit.Rewards, {k=100, v=1})
    local rewards = eTemp.rewards
    for i=1,#rewards do
        table.insert(unit.Rewards, {k=rewards[i].k, v=math.ceil(rewards[i].v*0.3)})
    end    
    unit.Seconds = eTemp.minute * 60     --一次护送持续时间 
    unit.Quality = eTemp.quality
    local roleBaseTemp = RoleBaseTemp[tostring(eTemp.modelId)]
    unit.ModelName = roleBaseTemp.name  --仙灵名字
    return unit
end


--Update
--更新拦截Unit
function M:UpdateRobUnit(unit, data)
    unit.Fight = UIMisc.LongToNum(data.fight)
end

--更新护送剩余次数
function M:UpdateEscortRemainTime(remainTime)
    self.mEscortRemainTime = remainTime
    self:UpdateRedPoint()
    --self:eUpdateEscortBtn()
end

--更新劫镖剩余次数
function M:UpdateRobRemainTime(remainTime)
    self.mRobRemainTime = remainTime
    --self:eUpdateEscortBtn()
end

--更新护送结束时间戳   0-不护送
function M:UpdateEndTime(endTime)
    self.mEndTime = endTime
end

--更新护送日志
function M:UpdateLog(p_escort_log)
    local id = p_escort_log.type
    local texts = p_escort_log.text
    table.insert(self.mLogList, {Id = id, Texts = texts})
end

--更新当前护送Id
function M:UpdateCurEscortId(id)
    self.mCurEscortId = id
end

--更新被抢状态  true-被抢
function M:UpdateRobStatus(isRob)
    self.mIsRob = isRob
end

--更新是否有领取的奖励
function M:UpdateCanGetReward(status)
    self.mCanGetReward = status
    if self.mCanGetReward == 1 then
        FamilyMgr.eRed(true, 1, 3)
    end
end

function M:UpdateRedPoint()
    SystemMgr:ChangeActivity(self.mIsOpen and self.mEscortRemainTime > 0, ActivityMgr.Escort)
end

function M:UpdateSysEscort(status)
    self.mIsSysEscortOpen = status
end


--Get
--获取护送剩余次数
function M:GetEscortRemainTime()
    return self.mEscortRemainTime
end

--获取拦截剩余次数
function M:GetRobRemainTime()
    return self.mRobRemainTime
end

--获取奖励领取状态
function M:GetHasRewardStatus()
    return self.mCanGetReward
end

--获取当前仙灵Id
function M:GetCurEscortId()
    return self.mCurEscortId
end

--获取被抢状态
function M:GetRobStatus()
    return self.mIsRob
end

--获取护送结束时间戳
function M:GetEscortEndTime()
    return self.mEndTime - TimeTool.GetServerTimeNow()*0.001
end

--是否在护送中
function M:IsEscorting()
    return self.mEndTime > TimeTool.GetServerTimeNow()*0.001
end

--获取当前仙灵数据
function M:GetCurEscortData()
    local temp = EscortTemp[tostring(self.mCurEscortId)]
    local index =  temp and temp.quality or 1
    return self.mEscortList[index]
end

--获取当前仙灵品质
function M:GetCurEscortQua()
    local temp = EscortTemp[tostring(self.mCurEscortId)]
    return temp and temp.quality or 1
end

--获取仙灵最高品质
function M:GetEscortMaxQua()
    return #self.mEscortList
end

--获取Log
function M:GetEscortLogs()
    return self.mLogList
end

--获取抢劫列表数据
function M:GetRobsData()
    return self.mRobList
end

function M:GetRobsCount()
    return #self.mRobList
end

function M:GetRobDataByIndex(index)
    return self.mRobList[index]
end

--获取所有仙灵数据
function M:GetEscortsData()
    return self.mEscortList
end

--主界面按钮状态
function M:IsOpen()
    return self.mIsOpen and ((self.mEscortRemainTime > 0 and not self:IsEscorting()) or self.mCanGetReward == 1)
end

--活动开启状态
function M:GetOpenStatus()
    return self.mIsOpen
end

--系统是否开启
function M:GetSysEscortStatus()
    return self.mIsSysEscortOpen
end

--获取战斗结果
function M:GetBatResult()
    return self.mIsSuccess or false
end

function M:ClickUrl( ... )
    local arg = { ... }
    local name = arg[1]
    if name == "UIOtherInfoCPM" then
        UserMgr:ReqRoleObserve(tonumber(arg[2]))
        UIMgr.Open(UIOtherInfoCPM.Name)
    elseif name == "夺回奖励" then
        self.mRobUid = tonumber(arg[2])
        MsgBox.ShowYesNo(string.format("是否对名称为[F21919FF]%s[-]玩家发起攻击，讨回失去的奖励？", arg[3]), self.BeatBack, self)
    elseif name == "请求援助" then
        MsgBox.ShowYesNo(string.format("是否请求盟友帮你抢回失去的%s%%护送奖励？",GlobalTemp["150"].Value3), self.RequestHelp, self)
    end
end

function M:RequestHelp()
    self:ReqRoleEscortForHelp()
end

function M:BeatBack()
    self:ReqRoleEscortRobBack(self.mRobUid)
end

function M:MsgLog(name, msg)
    -- iTrace.Error(name, tostring(msg))
end

function M:SetEndReward(isSuccess, rewards, title)
    self.mIsSuccess = isSuccess
    self.mRewards = rewards
    self.mTitie = title
end

function M:OpenEndPanel()
    UIMgr.Open(UIEndPanelT.Name,  self.OpenEndPanelCb, self) 
end

function M:OpenEndPanelCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:UpdateSuccess(self.mIsSuccess)
        ui:UpdateData(self.mRewards)
        ui:UpdateDes(self.mTitie)
        ui:UpdateTimer(10)
    end
end

function M:ClearRobsData()
    TableTool.ClearDic(self.mRobList)
end

function M:ClearLogsData()
    TableTool.ClearDic(self.mLogList)
end

function M:Clear()
    self:InitData()
    self:ClearRobsData()
    self:ClearLogsData()
    TableTool.ClearDic(self.mEscortList)
end

return M