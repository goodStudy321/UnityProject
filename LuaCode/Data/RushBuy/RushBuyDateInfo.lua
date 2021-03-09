--[[
    零元抢购信息
--]]

RushBuyDateInfo = Super:New{Name = "RushBuyDateInfo"}

local My = RushBuyDateInfo

--抢购状态
My.RushBuyList = {}
--抢购剩余时间
My.RushBuyTime = nil

function My:Init()

end

--清理缓存
function My:Clear()
    My.RushBuyTime = nil
    if #self.RushBuyList > 0 then
        for k,v in pairs(self.RushBuyList) do
            self.RushBuyList[k] = nil
        end
    end
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My