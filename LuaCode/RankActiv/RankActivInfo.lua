--[[
 	authors 	:Liu
 	date    	:2018-7-26 10:00:00
 	descrition 	:开服活动信息
--]]

RankActivInfo = {Name = "RankActivInfo"}

local My = RankActivInfo

function My:Init()
	--购买记录
	self.buyList = {}
	--排行榜数据列表
	self.rankDataList = {}
	--奖励状态字典
	self.stateDic = {}
	--红点字典
	self.actionDoc = {}
end

--设置红点字典
function My:SetActionDic(id, isShow)
	local key = tostring(id)
	self.actionDoc[key] = isShow
end

--设置奖励状态字典（当前分页）
function My:SetAwardStateDic(id, val)
	local key = tostring(id)
	self.stateDic[key] = val
end

--设置排行榜列表
function My:SetRankList(rank, roleId, roleName, val)
    self.data = {}
    local data = self.data
    data.rank = rank
	data.roleId = roleId
	data.roleName = roleName
	data.val = val
	table.insert(self.rankDataList, data)
end

--设置购买列表
function My:SetBuyList(item)
	for i,v in ipairs(self.buyList) do
		if v.id == item.id then
			v.val = item.val
			return
		end
	end
	local data = {}
	data.id = item.id
	data.val = item.val
	table.insert(self.buyList, data)
end

--清空购买列表
function My:ClearBuyList()
	ListTool.Clear(self.buyList)
end

--清空排行榜列表
function My:ClearRankList()
	ListTool.Clear(self.rankDataList)
end

--清理状态字典
function My:ClearStateDic()
	TableTool.ClearDic(self.stateDic)
end

--清理缓存
function My:Clear()
	self:ClearBuyList()
	self:ClearRankList()
	self:ClearStateDic()
	TableTool.ClearDic(self.actionDoc)
end

--释放资源
function My:Dispose()
	self:Clear()
end

return My