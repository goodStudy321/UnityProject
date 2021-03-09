--[[
    每日首冲信息
]]

FirstPayInfo = Super:New{Name = "FirstPayInfo"}
local My = FirstPayInfo

--是否可领状态
My.isGet = nil
My.openServerDay = nil
My.rewardTab = {}
My.curRewardDay = nil

function My:Init()

end

--清理缓存
function My:Clear()
    self.isGet = nil
    self.openServerDay = nil
    My.curRewardDay = nil
    local len = #self.rewardTab
    if len and len > 0 then
        for i = 1,len do
            self.rewardTab[i] = nil
        end
    end
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My