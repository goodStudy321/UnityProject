--[[
 	authors 	:Liu
 	date    	:2019-6-15 17:00:00
 	descrition 	:道庭任务信息类
--]]

FamilyMissionInfo = {Name = "FamilyMissionInfo"}

local My = FamilyMissionInfo

function My:Init()
	--是否能极品刷新
	self.isRefresh = false
	--已帮助加速次数
	self.inspire = 0
	--所有任务中最高星级
	self.maxStar = 0
	--任务列表
	self.missionList = {}
	--求助列表
	self.helpList = {}
	
	self:InitMaxStar()
end

--设置任务数据
function My:SetMissionData(missionId, state, count, startTime, endTime)
	for i,v in ipairs(self.missionList) do
		if v.missionId == missionId	then
			v.state = state
			v.count = count
			v.startTime = startTime
			v.endTime = endTime
			return
		end
	end
	local data = {}
	data.missionId = missionId--任务id
	data.state = state--任务状态(0:可接,1:可请求加速,2:已请求加速,3:待领取奖励,4:放弃)
	data.count = count--已加速次数
	data.startTime = startTime--开始时间戳
	data.endTime = endTime--结束时间戳
	table.insert(self.missionList, data)
end

--移除任务
function My:RemoveMission(missionId)
	local cfg, index = BinTool.Find(self.missionList, missionId, "missionId")
	if cfg then
		table.remove(self.missionList, index)
	end
end

--设置求助列表
function My:SetHelpList(id, name, sex, vip, count, missionId)
	for i,v in ipairs(self.helpList) do
		if v.id == id then
			v.name = name
			v.sex = sex
			v.vip = vip
			v.count = count
			v.missionId = missionId
			return
		end
	end
	local data = {}
	data.id = id--玩家id
	data.name = name--玩家名字
	data.sex = sex--玩家性别
	data.vip = vip--vip等级
	data.count = count--已加速次数
	data.missionId = missionId--任务id
	table.insert(self.helpList, data)
end

--更新求助列表
function My:UpHelpList(id, count, missionId)
	for i,v in ipairs(self.helpList) do
		if v.id == id then
			v.count = v.count + 1
			v.missionId = missionId
			break
		end
	end
end

--根据成员id获取求助信息
function My:GetHelpInfo(id)
	for i,v in ipairs(self.helpList) do
		if v.id == id then
			return v
		end
	end
	return nil
end

--初始化最大星级
function My:InitMaxStar()
	local maxStar = 0
	for i,v in ipairs(FamilyMissionCfg) do
		maxStar = (v.star>maxStar) and v.star or maxStar
	end
	self.maxStar = maxStar
end

--获取刷新权重
function My:GetRefreshWeight()
	-- local list, starList = self:GetWeightList()
	-- if list == nil then return nil end
	-- for i,v in ipairs(list) do
	-- 	if v.v > 0 then
	-- 		return starList[i]
	-- 	end
	-- end

	local lv = VIPMgr.vipLv
	if lv == nil then return nil end
	for i,v in ipairs(FamilyMissionCfg) do
		for i1,v1 in ipairs(v.refreshWeight) do
			if v1.k == lv and v1.v > 0 then
				return v.star
			end
		end
	end
end

-- --获取刷新权重列表
-- function My:GetWeightList()
-- 	local list = {}
-- 	local starList = {}
-- 	local lv = VIPMgr.vipLv
-- 	if lv == nil then return nil end
-- 	for i,v in ipairs(FamilyMissionCfg) do
-- 		for i1,v1 in ipairs(v.refreshWeight) do
-- 			if v1.k == lv then
-- 				table.insert(list, v1)
-- 				table.insert(starList, v.star)
-- 			end
-- 		end
-- 	end
-- 	return list, starList
-- end

--获取刷新消耗的元宝
function My:GetRefreshGold()
	local cfg = GlobalTemp["144"]
	if cfg == nil then return nil end
	return cfg.Value3
end

--获取最大加速次数
function My:GetMaxSpeed(vip)
	local cfg = VIPLv[vip+1]
	if cfg == nil then return end
	return cfg.speedCount
end

--是否达到最大加速次数
function My:IsMaxCount(vip)
    local maxCount = self:GetMaxSpeed(vip)
    return self.inspire >= maxCount
end

--获取道绩（1:单次，2:上限）
function My:GetFamilyScoreVal(index)
	local cfg = GlobalTemp["141"]
	if cfg == nil then return nil end
	local val = (index==1) and cfg.Value2[1] or cfg.Value2[2]
	return val
end

--根据任务id获取配置
function My:GetCfg(id)
	local cfg, index = BinTool.FindProName(FamilyMissionCfg, id)
	return cfg
end

--清理缓存
function My:Clear()
	self.isRefresh = false
	self.inspire = 0
	ListTool.Clear(self.missionList)
	ListTool.Clear(self.helpList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My