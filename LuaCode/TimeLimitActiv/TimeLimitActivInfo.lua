--[[
 	authors 	:Liu
 	date    	:2019-3-18 17:00:00
 	descrition 	:限时活动信息
--]]

TimeLimitActivInfo = {Name = "TimeLimitActivInfo"}

local My = TimeLimitActivInfo

function My:Init()
	--活动字典
	self.activDic = {}
	--灵力
	self.mana = {}
	--排行榜数据列表 key:type value:排行榜数据
	self.rankDataDic = {}
	-- self.rankDataList = {}
	--活动id（法宝，翅膀，图鉴）
	self.idList = {10013, 10014, 10012}
	--当前的充值金额
	self.recharge = 0
	--判断是否是最后一天
	self.isLastDayDic = {}

	--数据字典(1026~1028, 10001)
	self.dataDic = {}
	--是否已经投资
	self.isInvest = false

	--七日投资类型
	self.sevenType = 1026
	--限时抢购类型
	self.buyType = 1027
	--许愿池类型
	self.wishType = 1028
	--灵力类型
	self.manaType = 10001

	--许愿池积分
	self.score = 0
	--许愿池幸运值
	self.luckVal = 0

	--大奖是否存在
	self.preciousExist = true;
	--是否提醒大奖
	self.notice = true;
	--通过时间区分奖励
	self.nowDay = 0;
end

--设置数据
function My:SetData(type, list)
	local key = tostring(type)
	self.activDic[key] = list
end

--转换数据
function My:ShiftData(list)
	local dic = {}
	if list == 0 or list == nil then return end
	for i,v in ipairs(list) do
		local key = tostring(v.id)
		dic[key] = v.val
	end
	return dic
end

--更新数据
function My:UpData(type, index, clist)
	if clist == 0 or clist == nil then return end
	local key = tostring(type)
	local list = self.activDic[key]
	for i,v in ipairs(clist) do
		local dic = list[index]
		dic[tostring(v.id)] = v.val
	end
end

--改变数据
function My:ChangeData(type, index, id)
	local key = tostring(type)
	local list = self.activDic[key]
	local dic = list[index]
	if index == 4 then
		dic[tostring(id)] = dic[tostring(id)] + 1
	else
		dic[tostring(id)] = 3
	end
end

--更新七日投资数据
function My:UpSevenData(id, type, val)
	local key = tostring(type)
	local dic = self.dataDic[key]
	if dic == nil then return end
	local index = tostring(id)
	if type == self.buyType then
		dic[index] = dic[index] + 1
	elseif type == self.manaType then
		dic[index] = val
	elseif type == self.wishType then
		dic[index] = val
	else
		dic[index] = 3
	end
end

--设置排行榜数据
function My:SetRankData(rank, roleId, roleName, val,list)
    self.data = {}
    local data = self.data
    data.rank = rank
	data.roleId = roleId
	data.roleName = roleName
	data.val = val
	table.insert(list, data)
end

--获取按钮数据状态
function My:GetBtnState(index)
	local type = self:GetOpenType()
	if type == 0 then return nil end
	local key = tostring(type)
	local list = self.activDic[key]
	if list == nil then return nil end
	return list[index]
end

--获取按钮数据
function My:GetBtnData(type)
	local key = tostring(type)
	local dic = self.dataDic[key]
	return dic
end

--获取开启类型
function My:GetOpenType()
	-- local type = 0
	-- for k,v in pairs(self.activDic) do
	-- 	type = tonumber(k)
	-- end
	-- return type
	return TimeLimitActivMgr.type
end

--获取活动类型
function My:GetActivType(type)
	local id = 0
	if not type then 
		type=self:GetOpenType() 
	end
	if type == self.idList[1] then
		id = 1024
	elseif type == self.idList[2] then
		id = 1023
	elseif type == self.idList[3] then
		id = 1025
	end
	return id
end

--获取配置列表
function My:GetCfgList(cfg)
	local list = {}
	local type = self:GetOpenType()
	for i,v in ipairs(cfg) do
		if v.type == type then
			table.insert(list, v)
		end
	end
	return list
end

--获取迷你排行榜
function My:GetMiniRank()
	local miniList = {}
	local type=TimeLimitActivMgr.type
	local list = self.rankDataDic[tostring(type)]
	if list and #list>1 then 
		table.sort(list, function(a,b) return a.rank < b.rank end)
	end
	if list then 
		for i,v in ipairs(list) do
			if i <= 6 then
				table.insert(miniList, v)
			end
		end
	end
	return miniList
end

--获取自身的排行信息
function My:GetMyRank()
	local type=TimeLimitActivMgr.type
	local list=self.rankDataDic[tostring(type)]
	if list then 
		for i,v in ipairs(list) do
			if tostring(v.roleId) == tostring(User.MapData.UID) then
				return v
			end
		end
	end
	return nil
end

--重置排行榜列表
function My:ResetRankData(sType)
	self.rankDataDic[sType] = {}
end

--清理缓存
function My:Clear()
	self:Init()
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My