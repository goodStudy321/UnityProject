--[[
    每日累充次信息
]]

EvrDayInfo = Super:New{Name = "EvrDayInfo"}
local My = EvrDayInfo

--当天充值量
My.Recharge = nil

--开服第几天
My.OpenDay = 0

--当天充值的奖励
My.PayAdDic = {}

--充值计数的奖励
My.CountAdDic = {}

function My:Init()

end

--清理缓存
function My:Clear()
    self.Recharge = nil
    self.OpenDay = 0
    self.PayAdDic = {}
    self.CountAdDic = {}
	TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My