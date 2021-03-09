--[[
 	authors 	:Liu
 	date    	:2018-6-27 11:05:00
 	descrition 	:寻宝活动信息
--]]

TreasureInfo = {Name = "TreasureInfo"}

local My = TreasureInfo

function My:Init()
	--自定义表
	self.tab = {id = 0, name = nil}
	--全服寻宝记录
	self.wTreasLogs = {}
	--个人寻宝记录
	self.sTreasLogs = {}
	--装备寻宝幸运值
	self.equipLuckVal = 0
	--符文寻宝免费时间
	self.freeTime = -1
	--全服巅峰寻宝记录
	self.topWTreasLogs = {}
	--个人巅峰寻宝记录
	self.topSTreasLogs = {}
	--巅峰寻宝幸运值
	self.topLuckVal = 0
	--装备寻宝索引
	self.equip = 1
	--符文寻宝索引
	self.rune = 2
	--化神寻宝索引
	self.top = 3
	--符文展示字典
	self.runeShowDic = {}

	self:SetRuneShowDic()
end

--设置世界寻宝日志
function My:SetWordLogs(itemId, itemName, isFirst, index)
	local list = (index==1) and self.wTreasLogs or self.topWTreasLogs
	self.tab = {id = itemId, name = itemName}
	if isFirst then
		table.insert(list, 1, self.tab)
	else
		table.insert(list, self.tab)
	end
end

--获取配置
function My:GetCfg(index)
    if index == 1 then
        return EquipTreasCfg
    elseif index == 3 then
        return TopTreasCfg
    end
end

--设置符文展示字典
function My:SetRuneShowDic()
	for i,v in ipairs(RuneTreasureCfg) do
		local key = tostring(v.treasureId)
		local list = self.runeShowDic[key]
		if list==nil then
			list = {}
			self.runeShowDic[key] = list
		end
		table.insert(list, v)
	end
end

--获取符文展示字典
function My:GetShowDic()
	return self.runeShowDic
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