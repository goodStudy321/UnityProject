--[[
 	authors 	:Liu
 	date    	:2018-5-22 21:48:08
 	descrition 	:等级奖励信息
--]]

LvAwardInfo = Super:New{Name = "LvAwardInfo"}

local My = LvAwardInfo

function My:Init()
	--已领取的等级奖励列表
	self.selfDic = {}
	--已领取的限制奖励列表
	self.worldDic = {}
end

--获取限制奖励数量
function My:GetWordAward(cfg)
    local key = tostring(cfg.id)
    if self.worldDic[key] then
        local temp = cfg.count - self.worldDic[key]
        local count = (temp > 0) and temp or 0
        return count
    else
        return cfg.count
    end
end

--清理缓存
function My:Clear()
	self.selfDic = {}
	self.worldDic = {}
end

--释放资源
function My:Dispose()
	self:Clear()
end

return My