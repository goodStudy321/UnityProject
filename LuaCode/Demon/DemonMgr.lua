DemonMgr = Super:New{Name = "DemonMgr"}

local M = DemonMgr

M.RoomName = {"哀嚎堡垒", "黑暗沼泽", "绝望深渊"}

M.mDemonData = {}   --UI界面数据
M.mDemonData.mRoomList = {} --房间数据
M.mDemonData.mIsOpen = false   --活动是否开启
M.mDemonData.mEndTime = 0  --活动结束时间戳
M.mDemonData.mWorldLevel = 0 --世界等级


M.mDemonInfo = {}   --当前魔域房间信息
M.mDemonInfo.mRankList = {} --房间排行信息
M.mDemonInfo.mCurOccupyUnit = nil   --当前占领者
M.mDemonInfo.mCheerTimes = 0 --//魔域boss总共可鼓舞次数
M.mDemonInfo.mAddbuffTime = 0 --//魔域boss已经鼓舞的次数
M.mDemonInfo.mRewardData = {}  --魔域血量奖励

M.eUpdateRoom = Event()
M.eUpdateRoomState = Event()


M.eUpdateCurOccupy = Event()
M.eUpdateRank = Event()
M.eUpdateCheer = Event()
M.eUpdateDemonState = Event()  --活动开启关闭
M.eUpdateBossHpRewardStatus = Event()  --更新boss hp 奖励状态

local DateTime = System.DateTime

function M:Init()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:SetLsnr(Lsnr)
    Lsnr(24500, self.RespDemonBossInfo, self)
    Lsnr(24502, self.RespDemonBossInfoUpdate, self)
    Lsnr(24504, self.RespDemonBossEnter, self)
    Lsnr(24510, self.RespDemonBossOccupy, self)
    Lsnr(24512, self.RespDemonBossRank, self)
    Lsnr(24520, self.RespDemonBossCheerTimes, self)
    Lsnr(24522, self.RespDemonBossCheer, self)  
    Lsnr(24600, self.RespBossEndPanel, self)  
    Lsnr(24526, self.RespDemonBossHpRewardStatus, self)
    Lsnr(24528, self.RespDemonBossHpReward, self)
end

--房间协议
--// 魔域boss信息推送
function M:RespDemonBossInfo(msg)
    TableTool.ClearDic(self.mDemonData.mRoomList)
    self.mDemonData.mWorldLevel = msg.level
    local rooms = msg.rooms
    for i=1,#rooms do
        self:CreateRoomUnit(rooms[i], msg.level)
    end 
    table.sort(self.mDemonData.mRoomList, function(a,b) return a.Id < b.Id end)
    self:UpdateRedPoint()
    self.eUpdateRoom()
end

--// 魔域boss房间信息更新
function M:RespDemonBossInfoUpdate(msg)
    self:UpdateRoomUnit(msg.room)
    self:UpdateRedPoint()
    self.eUpdateRoomState(msg.room.room_id)
end


--副本协议
--// 魔域boss进入场景推送
function M:RespDemonBossEnter(msg)
    self:ClearDemonInfo()
    self:InitDemonBossHpRewardData()
    self:UpdateRankList(msg.rank_roles)
    self:UpdateCurOccupyUnit(msg.occupy_role)
    self:UpdateCheer(msg.cheer_times, msg.add_buff_times)
    self:SortRankList()
    self:OpenUIDemonInfo()
end

--// 魔域boss占领玩家的信息
function M:RespDemonBossOccupy(msg)
    self:UpdateCurOccupyUnit(msg.occupy_role)
    self.eUpdateCurOccupy()
end

--// 魔域boss排行玩家的信息
function M:RespDemonBossRank(msg)
    self:UpdateRankList(msg.rank_roles)
    self:SortRankList()
    self.eUpdateRank()
end


--// 魔域boss鼓舞次数推送
function M:RespDemonBossCheerTimes(msg)
    self:UpdateCheer(msg.cheer_times, msg.add_buff_times)
    self.eUpdateCheer()
end

--// 魔域boss地图鼓舞返回
function M:RespDemonBossCheer(msg)
    if UIMisc.CheckErr(msg.err_code) then
        UITip.Log("购买复仇Buff成功")
    end
end

--请求鼓舞
function M:ReqDemonBossEnterSafe()
    local msg = ProtoPool.GetByID(24523)
    ProtoMgr.Send(msg)
end

--请求鼓舞
function M:ReqDemonBossCheer()
    local msg = ProtoPool.GetByID(24521)
    ProtoMgr.Send(msg)
end

--// 魔域boss血量奖励信息，进入地图增量更新 推送
function M:RespDemonBossHpRewardStatus(msg)
    local list = msg.hp_reward_status
    for i=1,#list do
        self:UpdateBossHpRewardStatus(list[i].id, list[i].val)
    end
    self.eUpdateBossHpRewardStatus()
end

--// 领取奖励返回 
function M:RespDemonBossHpReward(msg)
    if UIMisc.CheckErr(msg.err_code) then
        local data = msg.hp_reward_status
        self:UpdateBossHpRewardStatus(data.id, data.val)
        self.eUpdateBossHpRewardStatus(data.id)
    end
end

--// 领取奖励
function M:ReqDemonBossHpReward(reward_id)
    local msg = ProtoPool.GetByID(24527)
    msg.reward_id = reward_id
    ProtoMgr.Send(msg)
end

function M:RespDemonActiveInfo(p_activity)
    self.mDemonData.mIsOpen = p_activity.status == 2
    self.mDemonData.mEndTime = p_activity.end_time
    self:UpdateRedPoint()
    self.eUpdateDemonState(self.mDemonData.mIsOpen)
end


function M:RespBossEndPanel(msg)
    self.mOwerName = msg.role_name
    self.rewardList = msg.goods
    if not self.timer then
        self.timer=ObjPool.Get(iTimer)
        self.timer.complete:Add(self.OnEnd,self)
        local s = GlobalTemp["132"].Value3
        if not s then iTrace.Log("lzd:", "全局配置表 id:132 数据错误") end
        self.timer.seconds = s or 3
    end
    self.timer:Start()
end

function M:OnEnd()
    UIMgr.Open(UIEndPanelT.Name, self.OpenEndPanelTCb, self)
end

function M:OpenEndPanelTCb(name)
    local ui = UIMgr.Get(name)
    if not ui then return end
    ui:UpdateData(self.rewardList)
    local str = ""
    local time = nil
    local temp = SceneTemp[tostring(User.SceneId)]
    if temp then
        local mapchildtype = temp.mapchildtype
        if mapchildtype == 18 then
            str = string.format("BOSS归属者：%s", self.mOwerName)
            ui:UpdateSuccess(self.mOwerName == User.MapData.Name)
        elseif mapchildtype == 1 or mapchildtype == 19 then
            str = string.format("BOSS归属者：%s\n（BOSS归属者可额外获得BOSS归属奖励）", self.mOwerName)
        end
        time = temp.endTime
    end
    ui:UpdateDes(str)
    ui:UpdateTimer(time)
end



function M:OpenUIDemonInfo()
    local active = UIMgr.GetActive(UIDemonInfo.Name)
    if active <= 0 then
        UIMgr.Open(UIDemonInfo.Name)		
    end
end


--Update

--Room

--创建房间单元
function M:CreateRoomUnit(data, worldLevel)
    local unit = {}
    unit.Id = data.room_id   --房间ID
    unit.CanEnter = data.is_alive   --是否可进入
    unit.WorldLevel = worldLevel  --房间世界等级
    unit.LastOwnerName = data.role_name  --上一次归属者
    unit.OwnerRewards = data.panel_goods --上一次归属者获得的奖励
    unit.Name = self.RoomName[unit.Id] or "魔域禁地"
    local cfg = self:GetRoomRewardData(worldLevel)
    unit.InevitableRewards = cfg.InevitableRewards
    unit.IncidentalRewards = cfg.IncidentalRewards
    table.insert(self.mDemonData.mRoomList, unit)
end

--更新房间数据
function M:UpdateRoomUnit(data)
    local list = self.mDemonData.mRoomList
    for i=1,#list do
        local unit = list[i]
        if unit.Id == data.room_id then
            unit.CanEnter = data.is_alive
            unit.LastOwnerName = data.role_name
            unit.OwnerRewards = data.panel_goods
            break
        end
    end
end

function M:UpdateRedPoint()
    local hadKill = self:HadkillAllBoss()
    local isOpen = self:IsOpen()
    SystemMgr:ChangeActivity(isOpen and not hadKill, ActivityMgr.DemonArea)
end


--Rank
--创建排行榜数据单元
function M:CreateRankUnit(data)
    local unit = {}
    self:UpdateRankUnit(unit, data)
    return unit
end

--更新rankUnit
function M:UpdateRankUnit(unit, data)
    unit.RoleId = UIMisc.LongToNum(data.role_id)
    unit.Name = data.role_name
    unit.Sex = data.sex
    unit.Category = data.category
    unit.OccupyTime = data.occupy_time
    unit.Time = data.time
    unit.CurOccupyTime = data.cur_occupy_time
    unit.Rank = 0
end


--创建Boss HP 奖励单元
function M:InitDemonBossHpRewardData()
    local data = DemonPartakeCfg
    local list = self.mDemonInfo.mRewardData
    for i=1,#data do
        local temp = data[i]
        local unit = {}
        unit.Id = temp.Id
        unit.HpPer = temp.HpPer
        unit.Rewards = temp.Rewards
        unit.HadGet = 0  --  0不能领取奖励 1可以领取奖励 2:已经领取奖励    
        list[i] = unit
    end
end


--更新Boss HP 奖励领取状态
function M:UpdateBossHpRewardStatus(id, status)
    local list = self.mDemonInfo.mRewardData
    list[id].HadGet = status
end


--更新副本鼓舞
function M:UpdateCheer(cheer_times, add_buff_times)
    self.mDemonInfo.mCheerTimes = cheer_times --//魔域boss总共可鼓舞次数
    self.mDemonInfo.mAddbuffTime = add_buff_times --//魔域boss已经鼓舞的次数
end

--更新排行榜
function M:UpdateRankList(data)
    TableTool.ClearDic(self.mDemonInfo.mRankList)
    for i=1,#data do
        local unit = self:CreateRankUnit(data[i])
        table.insert(self.mDemonInfo.mRankList, unit)
    end
end


--更新当前占领者
function M:UpdateCurOccupyUnit(data)
    local uid = tonumber(data.role_id)
    local list = self.mDemonInfo.mRankList
    local unit = self.mDemonInfo.mCurOccupyUnit
    if uid == 0 then   --没有占领者
        self.mDemonInfo.mCurOccupyUnit = nil
        if unit and unit.OccupyTime > 0 then
            local index = TableTool.Contains(list, {RoleId = unit.RoleId}, "RoleId")
            if index == -1 then
                table.insert(list, unit)
                self:SortRankList()
                self.eUpdateRank()
            end          
        end   
    else 
        if unit and unit.RoleId ~= uid and unit.OccupyTime > 0 then  --上一秒的占领者
            local index = TableTool.Contains(list, {RoleId = unit.RoleId}, "RoleId")
            if index == -1 then
                table.insert(list, unit)
            end
        end
        self.mDemonInfo.mCurOccupyUnit = self:CreateRankUnit(data)
        local index = TableTool.Contains(list, {RoleId = uid}, "RoleId")
        if index ~= -1 then --当前占领者在排行榜
            table.remove(list, index)
        end
        self:SortRankList()
        self.eUpdateRank()
    end
end


function M:SortRankList()
    local list = self.mDemonInfo.mRankList  
    local curOccupy = self.mDemonInfo.mCurOccupyUnit
    table.sort(list, function(a, b) return self:Sort(a, b) end )
    if not curOccupy then  
        for i=1,#list do
            list[i].Rank = i
        end
    else
        local isSet = false
        for i=1,#list do
            if self:Sort(list[i], curOccupy) then
                list[i].Rank = i
            else
                if not isSet then
                    isSet = true
                    curOccupy.Rank = i
                end
                list[i].Rank = i+1
            end
        end
        if not isSet then
            curOccupy.Rank = #list + 1
        end
    end
end

function M:Sort(a, b)
    if a.OccupyTime == b.OccupyTime then
        return a.Time < b.Time
    else
        return a.OccupyTime > b.OccupyTime
    end
end


--get
--获取房间数据
function M:GetRoomData()
    return self.mDemonData.mRoomList
end

--获取当前世界等级对应的奖励
function M:GetRoomRewardData(lv)
    local len = #DemonCfg
    local data = DemonCfg[len]
    for i=1,len do
        if lv <= DemonCfg[i].Lv then
            data = DemonCfg[i]
            break
        end
    end
    return data
end


--获取排行榜数据(不包含占领者)
function M:GetRankInfo()
    return self.mDemonInfo.mRankList
end

--获取boss hp 奖励数据
function M:GetBossHpRewardData()
    return self.mDemonInfo.mRewardData
end

function M:HasBossHpReward()
    local list = self.mDemonInfo.mRewardData
    local hasReward = false
    for i=1,#list do
        if list[i].HadGet == 1 then
            hasReward = true
            break
        end
    end
    return hasReward
end

--获取当前地图奖励数据
function M:GetRewardData()
    return self:GetRoomRewardData(self.mDemonData.mWorldLevel)
end

--获取当前占领者数据   nil 表示没有占领者
function M:GetCurOccupyData()
    return self.mDemonInfo.mCurOccupyUnit
end

--获取活动结束时时间戳
function M:GetEndTime()
    return self.mDemonData.mEndTime
end


--是否还有复仇buff购买次数
function M:CanBuyBuff()
    return self.mDemonInfo.mCheerTimes > self.mDemonInfo.mAddbuffTime
end

--获取当前是第几次购买buff
function M:GetAddbuffTime()
    return self.mDemonInfo.mAddbuffTime+1
end

--获取下次活动开启时间
function M:GetCD()
    local now = DateTime.Now
    local cfg = ActiveInfo["10011"]
    local begTimes = cfg.begTime
    local beg = TimeTool.Beg
    local cur =  TimeTool.GetServerTimeNow()*0.001
    local sec = nil
    for i=1,#begTimes do
        local temp = begTimes[i]
        local time = DateTime.New(now.Year, now.Month, now.Day, temp.k, temp.v, 0)
        local target = UIMisc.LongToNum((time.Ticks-beg.Ticks)/10000)*0.001
        if target > cur then
            sec = target - cur
            break
        end
    end

    if not sec then
        local temp = begTimes[1]
        local time = DateTime.New(now.Year, now.Month, now.Day, temp.k, temp.v, 0)
        local target = UIMisc.LongToNum((time.Ticks-beg.Ticks)/10000)*0.001
        sec = target + 3600*24 - cur
    end
    return sec
end

function M:GetUnitHp(uid)
    local curHp, maxHp = 0, 0
    local temp = User:GetUnit(uid)
    if temp then 
        curHp = UIMisc.LongToNum(temp.HP)
        maxHp = UIMisc.LongToNum(temp.MaxHP)
    end
    return curHp, maxHp
end

--活动是否开启
function M:IsOpen()
    return self.mDemonData.mIsOpen
end

--是否所有boss已被击败
function M:HadkillAllBoss()
    local list = self.mDemonData.mRoomList
    local state = true
    for i=1,#list do
        local canEnter = list[i].CanEnter
        if canEnter == true then
            state = false
            break
        end
    end
    return state
end

--是否是队友或盟友
function M:IsTeamOrFamily(uid)
    if uid == UIMisc.LongToNum(User.MapData.UID) then return false end
    local unit = User:GetUnit(uid)
    if not unit then return false end
    if  unit.TeamId ~= 0 and unit.TeamId == User.MapData.TeamID then
        return true
    elseif UIMisc.LongToNum(unit.FamilyId) ~= 0 and UIMisc.LongToNum(unit.FamilyId) == UIMisc.LongToNum(User.MapData.FamilyID) then
        return true
    end
    return false
end


--clear
function M:ClearDemonInfo()
    TableTool.ClearDic(self.mDemonInfo.mRankList)
    TableTool.ClearDic(self.mDemonInfo.mRewardData)
    self.mDemonInfo.mCurOccupyUnit = nil   --活动是否开启
    self.mDemonInfo.mCheerTimes = 0  --//魔域boss总共可鼓舞次数
    self.mDemonInfo.mAddbuffTime = 0 --//魔域boss已经鼓舞的次数
end

function M:ClearDemonData()
    TableTool.ClearDic(self.mDemonData.mRoomList)
    self.mDemonData.mIsOpen = false   --活动是否开启
    self.mDemonData.mEndTime = 0  --活动结束时间戳
    self.mDemonData.mWorldLevel = 0
end


function M:Clear()
    self:ClearDemonInfo()
    self:ClearDemonData()
    if self.timer then self.timer:AutoToPool() self.timer = nil end
end

return M
