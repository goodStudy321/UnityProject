--[[
 	authors 	:Liu
 	date    	:2018-6-19 15:00:00
 	descrition 	:道庭Boss信息
--]]

FamilyBossInfo = {Name = "FamilyBossInfo"}

local My = FamilyBossInfo

function My:Init()
	--世界等级
	self.worldLv = 1

	self:InitData()
	self:InitBuffData()
end

--初始化数据
function My:InitData()
	self.data = {}
	local data = self.data
	data.type = 0--当前的场次
	data.inspire = 0--个人鼓舞次数
	data.allInspire = 0--道庭鼓舞次数
	data.joinCount1 = 0--上半场参加人数
	data.hpValue1 = 0--上半场Boss血量
	data.rank1 = {}--上半场排行榜
	data.joinCount2 = 0--下半场参加人数
	data.hpValue2 = 0--下半场Boss血量
	data.rank2 = {}--下半场排行榜
	data.familyName = ""--自身道庭的名字
end

--初始化鼓舞数据
function My:InitBuffData()
	local cfg = GlobalTemp["24"]
	if cfg == nil then return end

	self.buffData = {}
	local data = self.buffData
	data.gold = cfg.Value1[1].value
	data.inspire = cfg.Value1[2].id
	data.allInspire = cfg.Value1[2].value
	data.atk = cfg.Value3
	data.award = self:GetInspireAward(cfg)
end

--更新排行榜数据
function My:UpRankData(type, rank, name, joinCount, hurtNum)
	local rankList = (type == 1) and self.data.rank1 or self.data.rank2
	for i,v in ipairs(rankList) do
		if v.name == name then
			v.rank = rank
			v.joinCount = joinCount
			v.hurtNum = hurtNum
			return
		end
	end
	local data = {}
	data.rank = rank
	data.name = name
	data.joinCount = joinCount
	data.hurtNum = hurtNum
	table.insert(rankList, data)
end

--根据世界等级获取当前配置
function My:GetCurCfg()
	local wLv = self.worldLv
	for i,v in ipairs(FamilyBossDrop) do
		if wLv >= v.lv[1] and wLv <= v.lv[2] then
			return v
		end
	end
	return FamilyBossDrop[1]
end

--获取鼓舞奖励
function My:GetInspireAward(cfg)
	local list = {}
	for i,v in ipairs(cfg.Value1) do
		if i > 2 then
			table.insert(list, v)
		end
	end
	return list
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