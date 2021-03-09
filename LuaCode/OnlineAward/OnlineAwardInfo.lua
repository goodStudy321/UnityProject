--[[
 	authors 	:Liu
 	date    	:2018-5-24 12:00:08
 	descrition 	:在线奖励信息
--]]

OnlineAwardInfo = {Name = "OnlineAwardInfo"}

local My = OnlineAwardInfo

function My:Init()
	--已在线时长(秒)
	self.onlineTime = 0
	--在线奖励列表
	self.awardList = {}
	--判断奖励列表是否已领完
	self.isAll = 1 
end

--设置数据
function My:SetData(i, val)
    self.awardList[i] = val
end

--清理缓存
function My:Clear()
	self.onlineTime = 0
	self.awardList = {}
	self.isAll = 1 
	TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
	self:Clear()
end

return My