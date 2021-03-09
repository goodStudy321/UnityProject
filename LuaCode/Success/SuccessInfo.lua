--[[
 	authors 	:Liu
 	date    	:2018-8-31 15:20:00
 	descrition 	:成就信息
--]]

SuccessInfo = {Name = "SuccessInfo"}

local My = SuccessInfo

function My:Init()
    --当前点击的Tog索引
	self.togIndex = 0
	--当前点击的分页索引
	self.tabIndex = 0
	--已领取的奖励字典
	self.getDic = {}
	--已达成的成就字典
	self.condDic = {}
	--已达成的成就字典（旧）
	self.oldDic = {}
	--根据完成类型转换成ID列表的字典
	self.switchDic = {}
	--成就动画列表
	self.animList = {}
	--已经播放的动画字典
	self.compDic = {}
	--是否打开成就面板
	self.isOpen = false
	--成就母类型数量
	self.typeCount = 0
	--可领取的列表
	self.getList = {}

	self.list1 = {}
	self.list2 = {}

	self:InitSwitchDic()
end

--初始化转换字典
function My:InitSwitchDic()
	local dic = self.switchDic
	local cfg = SuccessCfg
	for k,v in pairs(cfg) do
		local key = tostring(v.compType)
		if dic[key] == nil then
			dic[key] = true
			if v.succType > self.typeCount then
				self.typeCount = v.succType
			end
		end
	end
	for k,v in pairs(dic) do
		local list = {}
		for k1,v1 in pairs(cfg) do
			if v1.compType == tonumber(k) then
				table.insert(list, v1.id)
				dic[k] = list
			end
		end
	end
end

--设置已达成的成就字典
function My:SetCondDic(key, id, val)
	self:SetDic(key, id, val, self.condDic)
end

--设置已达成的成就字典
function My:SetOldDic(key, id, val)
	self:SetDic(key, id, val, self.oldDic)
end

--设置字典
function My:SetDic(key, id, val, succDic)
	local temp = tostring(key)
	local dic = succDic[temp]
	if dic then
		local tempDic = {}
		for i,v in ipairs(dic.idList) do
			local key = tostring(v)
			tempDic[key] = true
		end
		if not tempDic[tostring(id)] then
			table.insert(dic.idList, id)
			table.insert(dic.valList, val)
		else
			for i,v in ipairs(dic.idList) do
				if v == id then
					dic.valList[i] = val
				end
			end
		end
	else
		ListTool.Clear(self.list1)
		ListTool.Clear(self.list2)
		table.insert(self.list1, id)
		table.insert(self.list2, val)

		succDic[temp] = {}
		succDic[temp].idList = {}
		succDic[temp].valList = {}

		for i,v in ipairs(self.list1) do
			table.insert(succDic[temp].idList, v)
		end
		for i,v in ipairs(self.list2) do
			table.insert(succDic[temp].valList, v)
		end
	end
end

--判断是否能领取奖励
function My:IsGet(key)
    local cfg = SuccessCfg
    local id = cfg[key].condId
    local type = cfg[key].compType
	for k,v in pairs(self.condDic) do
		if tonumber(k) == type then
			for i,v1 in ipairs(v.idList) do
				if id == v1  then
					local list = v.valList
					return true, list[i]
				end
			end
        end
    end
    return false, 0
end

--获取总的成就点
function My:GetSuccScore(type)
	local score = 0
	local list = {}
	for k,v in pairs(SuccessCfg) do
		if v.succType == type then
			if type == 1 then
				table.insert(list, v.condition)
			else
				score = score + v.score
			end
		end
	end
	if #list > 0 then table.sort(list) end
	score = (type==1) and list[#list] or score
	return score
end

--获取成就项进度值
function My:GetProgVal(index)
	local list = self:GetProgValList()
	local score = 0
	for i,v in ipairs(list) do
		score = score + list[i]
	end
	local val = (index==1) and score or list[index]
	return val
end

--获取成就项进度值的列表
function My:GetProgValList()
	local List = {}
	local valList = {}
	local cfg = SuccessCfg
	for i=1, self.typeCount do
		local temp = {}
		table.insert(list, temp)
	end
	for k,v in pairs(self.getDic) do
		for i,v1 in ipairs(list) do
			if cfg[k].succType == i then
				table.insert(list[i], cfg[k].score)
			end
		end
	end
	for i,v in ipairs(list) do
		local num = 0
		for i1,v1 in ipairs(list[i]) do
			num = num + v1
		end
		table.insert(valList, num)
	end
	list = {}
	return valList
end

--是否播放动画
function My:IsPlayAnim()
	local list = self.animList
	local key = tostring(list[1])
	self.compDic[key] = true
	table.remove(list, 1)
	return #list > 0
end

--获取动画数据
function My:GetAnimData()
	local cfg = SuccessCfg
	local list = self.animList
	table.sort(list)
	local key = tostring(list[1])
	return cfg[key]
end

--重置动画列表
function My:ResetAnimList()
	self.animList = {}
end

--设置获取列表
function My:SetGetList(val)
	for i,v in ipairs(self.getList) do
		if v == val then
			return
		end
	end
	table.insert(self.getList, val)
end

--获取列表索引
function My:RemoveGetList(key)
	local index = 0
	for i,v in ipairs(self.getList) do
		if key == v then index = i end
	end
	if index == 0 then return end
	table.remove(self.getList, index)
end

--清空列表
function My:ClearList()
	ListTool.Clear(self.getList)
end

--清理缓存
function My:Clear()
	self.togIndex = 0
	self.tabIndex = 0
	TableTool.ClearDic(self.getDic)
	TableTool.ClearDic(self.condDic)
	TableTool.ClearDic(self.oldDic)
	TableTool.ClearDic(self.compDic)
	ListTool.Clear(self.animList)
	self.isOpen = false
	self:ClearList()
end

--释放资源
function My:Dispose()

end

return My