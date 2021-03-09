--[[
 	authors 	:Liu
 	date    	:2018-9-21 11:00:00
 	descrition 	:青云之巅信息
--]]

TopFightInfo = {Name = "TopFightInfo"}

local My = TopFightInfo

function My:Init()
	self.score = 0
	self.rank = 0
	self.useTime = 0
	self.max = 0
end

--设置自身信息
function My:SetSelfInfo(score, rank)
	self.score = score
	self.rank = rank
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