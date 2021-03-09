--[[
 	authors 	:Liu
 	date    	:2018-12-7 9:40:00
 	descrition 	:结婚信息类
--]]

MarryInfo = {Name = "MarryInfo"}

local My = MarryInfo

function My:Init()
    self.tab1 = {id = 0, name = ""}
    self.pData = {id = 0, name = "", type = 0, time = 0}
    self.pDataList = {}
    self.wishCfg = {}
    self:InitData()
    self:InitFeastData()
    self:InitMapData()
    self:InitWishCfg()

    self.feastTotalTime = 15 * 60
    self.npcSId = 10005
    self.npcId = 100094
    self.copyId = 30019
    self.isAnim = false
    self.isShowAction = false
end

--初始化数据
function My:InitData()
    self.data = {}
    local data = self.data
    data.treeEndTime = 0         --自身姻缘树结束时间
    data.treeIsAward = false     --姻缘树奖励是否可以领取
    data.treeDailyTime = 0       --姻缘树日常的时间
    data.coupleTreeEndTime = 0   --仙侣姻缘树结束时间
    data.knotid = 0              --同心结id
    data.knotExp = 0             --同心结经验
    data.coupleid = 0            --仙侣id
    data.coupleidStr = ""            --仙侣id
    data.titleId = 0             --称号id
    data.marryTime = 0           --结婚时间
    data.count = 0               --能举办婚礼的次数
    data.selectInfo = nil        --当前选中的仙侣信息
    data.coupleInfo = nil        --仙侣信息
end

--初始化宴会数据
function My:InitFeastData()
    self.feastData = {}
    local data = self.feastData
    data.hourDic = {}           
    --预约场次字典
    data.feastTime = 0          --婚礼开始时间
    data.guestNum = 0           --额外增加的宾客数量
    data.isBuyJoin = true       --是否可以购买成为宾客
    data.guestList = {}         --宾客列表
    data.applyGuestList = {}    --申请的宾客列表
    data.feastState = 0         --宴会状态（0结束 1准备 2开始）
    data.endTime = 0            --准备状态结束时间
    data.role1 = nil            --举办婚礼角色1的信息
    data.role2 = nil            --举办婚礼角色2的信息
end

--初始化结婚副本数据
function My:InitMapData()
    self.mapData = {}
    local data = self.mapData
    data.bowSTime = 0            --拜堂开始时间
    data.bowETime = 0            --活动的结束时间
    data.candyTime = 0           --天降喜糖采集结束时间
    data.tasetCount = 0          --当前品尝次数
    data.heat = 0                --热度
    data.remainCount = 0         --热度采集物剩余采集次数
    data.pickCount = 0           --掉落可拾取的次数
    data.wishInfoList = {}       --婚礼祝福信息列表
end

--设置数据
function My:SetData(treeEndTime, treeIsAward, treeDailyTime, coupleTreeEndTime, knotid, knotExp, coupleid, marryTime,coupleidStr)
    local data = self.data
    data.treeEndTime = treeEndTime
    data.treeIsAward = treeIsAward
    data.treeDailyTime = treeDailyTime
    data.coupleTreeEndTime = coupleTreeEndTime
    data.knotid = knotid
    data.knotExp = knotExp
    data.coupleid = coupleid
    data.coupleidStr = coupleidStr
    data.marryTime = marryTime
end

--设置结婚副本数据
function My:SetMapData(bowSTime, bowETime, candyTime, tasetCount, heat, remainCount, pickCount)
    local data = self.mapData
    data.bowSTime = bowSTime
    data.bowETime = bowETime
    data.candyTime = candyTime
    data.tasetCount = tasetCount
    data.heat = heat
    data.remainCount = remainCount
    data.pickCount = pickCount
end

--设置宾客列表
function My:SetGuestList(id, name)
    self.tab1 = {id = id, name = name}
    table.insert(self.feastData.guestList, self.tab1)
end

--设置宾客申请列表
function My:SetApplyGuestList(id, name)
    self.tab1 = {id = id, name = name}
    local list = self.feastData.applyGuestList
    table.insert(list, self.tab1)
end

--删除宾客申请列表
function My:RemoveAGList(id)
    local list = self.feastData.applyGuestList
    for i,v in ipairs(list) do
        if tonumber(v.id) == tonumber(id) then
            table.remove(list, i)
        end
    end
end

--设置提亲数据
function My:SetProposeData(id, name, type, time)
    self.pData = {id = id, name = name, type = type, time = time}
    table.insert(self.pDataList, self.pData)
end

--获取下一个提亲时间
function My:GetNextPTime()
    local list = self.pDataList
    if #list < 1 then return 0 end
    local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
    local endTime = list[1].time
    local leftTime = endTime - sTime
    return leftTime
end

--移除提亲列表信息
function My:RemovePList()
    local list = self.pDataList
    if #list < 1 then return 0 end
    table.remove(list, 1)
    return #list
end

--清空提亲列表信息
function My:ClearPList()
    self.pDataList = {}
end

--清空场次列表
function My:ClearHourList()
    self.feastData.hourDic = {}
end

--清空宾客列表
function My:ClearGuestList()
    self.feastData.guestNum = 0
    self.feastData.guestList = {}
    self.feastData.applyGuestList = {}
end

--判断是否已经结婚
function My:IsMarry()
    if self.data.coupleInfo then
        return true
    end
    return false
end

--判断是否是举办者
function My:IsFeastRole()
    local role1 = self.feastData.role1
    local role2 = self.feastData.role2
    if role1 and role2 then
        if tonumber(User.MapData.UIDStr) == tonumber(role1.id) or tonumber(User.MapData.UIDStr) == tonumber(role2.id) then
            return true
        end
    end
    return false
end

--清空举办者
function My:ClearFeastRole()
    local data = self.feastData
    if data.role1 or data.role2 then
        data.role1 = nil
        data.role2 = nil
    end
end

--判断是否开启
function My:IsOpen()
    local cfg = GlobalTemp["52"]
    if cfg then
        if User.MapData.Level >= cfg.Value3 then
            return true
        end
    end
    return false
end

--获取日期 
function My:GetDate(times, str)
    local val = DateTool.GetDate(times)
    local date = val:ToString(str)
    local time = tonumber(date)
    return time
end

--判断是否已经预约
function My:IsAppoint()
    local times = self.feastData.feastTime
    local leftTime = self:SwitchTime(times)
    local sec = leftTime + self.feastTotalTime
    if sec > 0 then
        return true
    else
        return false
    end
	-- if leftTime < 0 then
	-- 	local sHour = SignInfo:GetTime("HH")
	-- 	local sMinute = SignInfo:GetTime("mm")
	-- 	local time = self:GetDate(times, "HH")
	-- 	if sHour < time then
	-- 		return true
    --     elseif sHour == time then
	-- 		if sMinute <= 15 then
	-- 			return true
	-- 		end
	-- 	end
	-- end
    -- return false
end

--能参加宴会
function My:JoinFeast()
    local info = self.feastData
    -- local times = info.feastTime
    local isOpen = false
    if info.feastState > 0 then
        isOpen = true
    end
    if self:IsAppoint() then
        isOpen = true
    end
    if isOpen then
        UIProposePop:OpenTab(5)
    else
        UITip.Log("当前没有婚礼举行")
    end
end

--获取申请的宾客字典
function My:GetApplyGuestDic()
    local dic = {}
    for i,v in ipairs(self.feastData.applyGuestList) do
        local key = tostring(v.id)
        dic[key] = v
    end
    return dic
end

--获取可邀请的人数
function My:GetInviteCount()
    local cfg = GlobalTemp["61"]
    if cfg then
        local info = self.feastData
        local len = #info.guestList
        local count = cfg.Value2[1] + info.guestNum
        local num = count - len
        return num
    end
    return 0
end

--时间戳转换
function My:SwitchTime(time)
    local sTime = TimeTool.GetServerTimeNow()*0.001
    local leftTime = time - sTime
    return leftTime
end

--获取拜堂时间
function My:GetBowTime()
    local time = self.mapData.bowSTime
    local rTime = self:SwitchTime(time)
    return rTime
end

--获取喜糖时间
function My:GetCandyTime()
    local time = self.mapData.candyTime
    local rTime = self:SwitchTime(time)
    return rTime
end

--初始化结婚祝福配置
function My:InitWishCfg()
    local list1 = {}
    local list2 = {}
    for i,v in ipairs(MarryWishCfg) do
        if v.type == 1 then
            table.insert(list1, v)
        else
            table.insert(list2, v)
        end
    end
    local len = #list1 + #list2
    for i=1, len do
        if list1[i] then
            table.insert(self.wishCfg, list1[i])
        end
        if list2[i] then
            table.insert(self.wishCfg, list2[i])
        end
    end
end

--删除祝福日志
function My:RemoveWishLog()
    local list = self.mapData.wishInfoList
    local max = self:GetWishMax()
    if #list > max then
        table.remove(list, 1)
    end
end

--获取祝福条目的上限
function My:GetWishMax()
    local cfg = GlobalTemp["62"]
    if cfg then
        return cfg.Value3
    end
    return 0
end

--获取热度的上限
function My:GetHeatMax()
    local cfg = GlobalTemp["62"]
    if cfg then
        return cfg.Value2[3]
    end
    return 0
end

--获取购买成为宾客所需元宝
function My:GetInviteBuy()
    local cfg = GlobalTemp["71"]
    if cfg then
        return cfg.Value3
    end
    return 0
end

--判断是否成功购买（优先消耗绑元）
function My:IsSucc(count)
	local info = RoleAssets
    local max = info.BindGold + info.Gold
    if max < count then
        return false
    end
    return true
end

--获取仙侣好感度
function My:GetFriendly()
    local id = self.data.coupleid
    for i,v in ipairs(FriendMgr.FriendList) do
        if id == tonumber(v.ID) then
            return v.Friendly
        end
    end
    return 0
end

--获取同心结等级
function My:GetKnotLv()
    local id = self.data.knotid
    local cfg = KnotData[id+1]
    if cfg == nil then return 1,0 end
    return cfg.rank, cfg.lv
end

--是否已经邀请
function My:IsInvite()
    for i,v in ipairs(self.feastData.guestList) do
        if tonumber(User.MapData.UIDStr) == tonumber(v.id) then
            return true
        end
    end
    return false
end

--判断是否存在申请
function My:IsExistTpply()
    for i,v in ipairs(self.feastData.applyGuestList) do
        return true
    end
    return false
end

--清空仙侣数据
function My:ClearCoupleData()
    self.data.coupleInfo = nil
    self.data.coupleid = 0
    self.data.coupleidStr = ""
    self:ClearSelectData()
end

--清空当前的仙侣数据
function My:ClearSelectData()
    self.data.selectInfo = nil
end

--清理缓存
function My:Clear()
    self:Init()
end

--释放资源
function My:Dispose()

end

return My