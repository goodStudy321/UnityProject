--[[
    开服累冲信息
--]]

AccuPayInfo = Super:New{Name = "AccuPayInfo"}

local My = AccuPayInfo

--个人充值量
My.selfPay = nil

--奖励状态
My.RewardDic = {}

function My:Init()

end

--清理缓存
function My:Clear()
    self.selfPay = nil
    TableTool.ClearDicToPool(self.RewardDic)
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My